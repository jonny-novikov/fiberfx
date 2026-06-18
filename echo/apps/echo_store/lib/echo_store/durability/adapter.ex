defmodule EchoStore.Durability.Adapter do
  @moduledoc """
  The pluggable-durability contract — the outbox-beside-the-volatile-bus behaviour every
  journal backend implements. An adapter is an outbox standing beside the bus (D-2 holds:
  the durable write never enters the enqueue hot path). The verbs mirror the shipped
  `EchoStore.Journal`: an atomic intent-plus-enqueue, the two edges, batch record, replay
  for the crash window, and coverage-based compaction.

  ## Plugin isolation (no dependency bloat)

  Core `echo_store` ships only the backends that need no extra dependency: `SQLite` (the
  shipped `EchoStore.Journal` over `exqlite`) and `Memory` (ETS, tests). A backend that
  needs its own dependency — `Postgres` (`ecto_sql` + `postgrex`, riding a host's own
  `Repo.transaction/1`), or the EchoMQ 4+ `Graft` commit-log-as-outbox — is a
  **bring-your-own plugin**: a host implements this behaviour in its own app and brings the
  dependency there, so `echo_store` never carries it. The behaviour is the seam.

      config :echo_store, EchoStore.Durability,
        adapter: MyApp.PostgresJournal,
        repo: MyApp.Repo            # adapter-specific opts pass through
  """
  @type journal :: term()
  @type conn :: GenServer.server()
  @type job_id :: binary()
  @type name_id :: binary()
  @type version :: non_neg_integer()

  @doc "Supervisor child spec for the adapter's journal process(es), from config opts."
  @callback child_spec(keyword()) :: Supervisor.child_spec()

  @doc "Atomic outbox-in-one-verb: record the intent, enqueue to the bus, mark covered."
  @callback intend_and_enqueue(journal, conn, name_id, version) ::
              {:ok, job_id} | {:error, term()}

  @callback record(journal, job_id, name_id, version) :: :ok | {:error, term()}
  @callback mark_enqueued(journal, job_id) :: :ok | {:error, term()}
  @callback record_many(journal, [{job_id, name_id, version}]) :: :ok | {:error, term()}

  @doc "Re-enqueue every intent not yet covered, reusing recorded ids (bus dedup absorbs dups)."
  @callback replay(journal, conn) :: {:ok, replayed :: non_neg_integer()} | {:error, term()}
  @callback compact(journal) :: {:ok, retired :: non_neg_integer()} | {:error, term()}
  @callback last_applied(journal, name_id) :: version | nil
  @callback stats(journal) :: map()

  @optional_callbacks record_many: 2, last_applied: 2, stats: 1
end
