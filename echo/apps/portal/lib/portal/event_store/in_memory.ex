defmodule Portal.EventStore.InMemory do
  @moduledoc """
  The in-memory `Portal.EventStore` adapter (F5.8) — an `Agent` keyed by stream,
  for dev and tests. The dev/test counterpart of `Portal.EventStore.Postgres`,
  interchangeable by `config :portal, :event_store` (F5.8-INV4).

  State is `%{stream => [event]}` in append order, so the engine's `read_stream/1`
  feeds `Portal.Engine.Core.replay/1` unchanged. `append/2` is total here (the
  Agent update cannot fail) but returns the success arm of the fallible behaviour
  signature; the fallible path is exercised by `Portal.EventStore.Postgres` (and a
  stub in tests). In-memory ⇒ it empties on a full app restart, so durability
  across a full-VM restart is the F6.3 Postgres concern; an engine-process restart
  re-reads this surviving Agent (F5.8-D8).
  """
  use Agent
  @behaviour Portal.EventStore

  def start_link(_opts), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  @impl Portal.EventStore
  def read_stream(stream) when is_binary(stream) do
    {:ok, Agent.get(__MODULE__, &Map.get(&1, stream, []))}
  end

  @impl Portal.EventStore
  def append(stream, events) when is_binary(stream) and is_list(events) do
    Agent.update(__MODULE__, fn streams ->
      Map.update(streams, stream, events, &(&1 ++ events))
    end)
  end

  @doc "Clear every stream (test isolation only) — mirrors `Portal.EventLog.reset/0`."
  @spec reset() :: :ok
  def reset, do: Agent.update(__MODULE__, fn _ -> %{} end)
end
