defmodule EchoStore.Durability.Adapter do
  @moduledoc """
  The durability contract: the lane that remembers, behind one behaviour so the backend is a
  config choice rather than a rewrite.

  Every adapter is the same transactional outbox at the two edges where durability is cheap and
  true — the writer's *intent* before the enqueue, and the applier's *memory* after the apply —
  and they all agree on newer-wins by branded-id order: a version is a 14-byte branded id, and
  the newer of two is the one whose trailing 11-character payload sorts higher
  (`EchoStore.Coherence.newer?/2`; in SQL, `substr(version, 4)`). Recovery is replay:
  re-enqueue every intent not yet covered by the applied memory, reusing the recorded job ids so
  the bus's admission dedup absorbs the ones it still holds. Compaction is coverage, not
  acknowledgment: retire every intent whose name carries an applied version at least as new, so
  the hot path pays no per-intent completion write.

  ## Plugin isolation (no dependency bloat)

  Core ships only the adapters that need no extra dependency — `EchoStore.Journal` (the shipped
  SQLite adapter over `exqlite`) and `EchoStore.Durability.Memory` (ETS, for tests). An adapter
  that needs its own dependency — `EchoStore.Durability.Postgres` (`ecto_sql` + `postgrex`) or
  the EchoMQ 4+ `EchoStore.Durability.Graft` commit-log-as-outbox — is a bring-your-own plugin a
  host provides in its own app, so core never carries the dependency. Both implement this
  behaviour, so a deployment swaps `SQLite → Postgres → Graft` by configuration.

  ## The contract

  The first argument `t` is the backend handle: a pid or registered name for the GenServer-backed
  SQLite/Memory adapters, a config struct for the Repo-backed Postgres adapter, a config struct
  for the Volume-backed Graft adapter. `name`, `version`, and `job_id` are 14-byte branded ids;
  `conn` is the EchoMQ connector; `table` is an `EchoStore.Table` server.
  """

  @type t :: term()
  @type conn :: GenServer.server()
  @type table :: GenServer.server()
  @type job_id :: EchoData.BrandedId.t()
  @type name :: EchoData.BrandedId.t()
  @type version :: EchoData.BrandedId.t()
  @type seq :: non_neg_integer() | term()
  @type verdict :: term()
  @type counts :: %{replayed: non_neg_integer(), deduplicated: non_neg_integer()}

  @doc "The writer's first edge: record the intent before the bus hears it. Returns its seq."
  @callback record(t(), job_id(), name(), version()) :: {:ok, seq()} | {:error, term()}

  @doc "The writer's second edge: the bus accepted this intent."
  @callback mark_enqueued(t(), job_id()) :: :ok | {:error, term()}

  @doc """
  The outbox in one verb: mint a job id, record the intent, enqueue on the bus, mark it enqueued.
  The crash windows between the steps are covered by replay plus dedup plus newer-wins.
  """
  @callback intend_and_enqueue(t(), conn(), name(), version()) :: {:ok, job_id()} | {:error, term()}

  @doc "The memory: the newest version this lane has applied for a name, or nil."
  @callback last_applied(t(), name()) :: version() | nil

  @doc """
  Apply with memory: a version stale against the applied memory answers `{:ok, :remembered_stale}`
  without touching the cache; otherwise the table applies and the memory remembers the version.
  """
  @callback apply_and_remember(t(), table(), name(), version()) :: {:ok, verdict()}

  @doc """
  Recovery beside the bus: re-enqueue every intent not covered by the applied memory, in order,
  reusing recorded job ids so the bus's admission dedup absorbs whatever it still holds.
  """
  @callback replay(t(), conn()) :: {:ok, counts()} | {:error, term()}

  @doc "Retire every intent whose name carries an applied version at least as new. Returns the count."
  @callback compact(t()) :: {:ok, non_neg_integer()} | {:error, term()}

  @doc "Operational counts (intents, pending enqueue, remembered, and backend specifics)."
  @callback stats(t()) :: map()

  @doc "Start an owner process, for adapters that need one (SQLite/Memory). Repo/Volume adapters may return `:ignore`."
  @callback start_link(keyword()) :: GenServer.on_start()

  @doc "Group commit at the writer's edge: record a batch of intents in one transaction."
  @callback record_many(t(), [{job_id(), name(), version()}]) :: {:ok, [seq()]} | {:error, term()}

  @doc "A consumer handler wiring the job lane through the adapter's memory."
  @callback handler(t(), table()) :: (map() -> :ok)

  @doc "Release the backend (close files / stop the owner). No-op for stateless adapters."
  @callback stop(t()) :: :ok

  @optional_callbacks start_link: 1, record_many: 2, handler: 2, stop: 1
end
