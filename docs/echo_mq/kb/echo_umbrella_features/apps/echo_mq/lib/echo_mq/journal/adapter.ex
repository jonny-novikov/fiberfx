defmodule EchoMQ.Journal.Adapter do
  @moduledoc """
  The pluggable-durability contract for EchoMQ — the "plug" every journal backend
  implements. An adapter is an outbox beside the volatile bus (D-2 holds: the durable
  write never enters the enqueue hot path). The verbs mirror the as-built
  `EchoStore.Journal`: an atomic intent-plus-enqueue, the two edges, batch record,
  replay for the crash window, and coverage-based compaction.

  Select one in config:

      config :echo_mq, EchoMQ.Journal,
        adapter: EchoMQ.Journal.Postgres,
        repo: MyApp.Repo            # adapter-specific opts pass through

  Ships: `SQLite` (local dev, the shipped exqlite journal), `Postgres` (BYO-Postgres
  outbox riding the host's own `Repo.transaction/1`), `Graft` (the EchoMQ 4+ commit-log-
  as-outbox, ADR-A), and `Memory` (tests).
  """
  @type journal :: term()
  @type conn :: GenServer.server()
  @type job_id :: EchoData.BrandedId.t()
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
