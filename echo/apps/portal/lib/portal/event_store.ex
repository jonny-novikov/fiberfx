defmodule Portal.EventStore do
  @moduledoc """
  The driven port for durable, append-only event storage (F5.8).

  A behaviour the core appends to and reads from, generalizing the as-built
  `Portal.EventLog` surface (`append/1`, `all/0`) it supersedes: a `stream` key is
  added, and `append/2` gains a **fallible** `{:error, term}` return the in-process,
  total `Portal.EventLog.append/1` never had (event_log.ex:35 returns `:ok`
  unconditionally). The fallible append is why the engine inverts its command order
  to append-before-evolve (F5.8-INV5): a failed append aborts the command and the
  fold never leads durable storage.

  Two adapters satisfy this port interchangeably — `Portal.EventStore.InMemory`
  (an Agent, for dev and tests) and `Portal.EventStore.Postgres` (Ecto, for
  production; a signature-only stub at this rung, body deferred to F6.3) — selected
  by `config :portal, :event_store` and resolved by `adapter/0` (F5.8-INV4). The
  core names only this behaviour, never a concrete adapter (F5.8-INV1).
  """

  @doc """
  Append `events` (in order) to `stream`. Fallible: `{:error, term}` for a Postgres
  failure, which aborts the command at the engine (F5.8-INV5).
  """
  @callback append(stream :: String.t(), events :: [struct]) :: :ok | {:error, term}

  @doc "Read every event recorded on `stream`, oldest first, for the engine's replay fold."
  @callback read_stream(stream :: String.t()) :: {:ok, [struct]} | {:error, term}

  @doc """
  The configured adapter module — `config :portal, :event_store` (F5.8-INV4).

  Swapping the value between `InMemory` and `Postgres` changes no caller: the
  engine and the supervision tree name `adapter()`, never a concrete adapter.
  """
  @spec adapter() :: module()
  def adapter, do: Application.fetch_env!(:portal, :event_store)
end
