defmodule Portal.EventLog do
  @moduledoc """
  The in-memory append-only event log — the source of truth the engine folds.

  A SEPARATE process from `Portal.Engine`, started before it, so an Engine crash
  is recovered by re-reading the CURRENT log (not a boot-time snapshot): a
  supervisor evaluates a child's args once, so a static `{Portal.Engine, events}`
  arg would re-fold a stale log. `all/0` returns the events in append order;
  `append/1` adds events on each successful command. In-memory ⇒ it empties on a
  full app restart; F5.8 swaps in the durable, swappable `Portal.EventStore` port
  behind this same surface (the web never sees it — master invariant).
  """
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @doc "Every recorded event, oldest first."
  @spec all() :: [Portal.Engine.Core.event()]
  def all, do: GenServer.call(__MODULE__, :all)

  @doc "Append events (in order) to the log."
  @spec append([Portal.Engine.Core.event()]) :: :ok
  def append(events) when is_list(events), do: GenServer.call(__MODULE__, {:append, events})

  @doc "Clear the log (test isolation only)."
  @spec reset() :: :ok
  def reset, do: GenServer.call(__MODULE__, :reset)

  # log :: [event] in append (fold) order, so `Core.replay(all())` is correct.
  @impl true
  def init(log), do: {:ok, log}

  @impl true
  def handle_call(:all, _from, log), do: {:reply, log, log}
  def handle_call({:append, events}, _from, log), do: {:reply, :ok, log ++ events}
  def handle_call(:reset, _from, _log), do: {:reply, :ok, []}
end
