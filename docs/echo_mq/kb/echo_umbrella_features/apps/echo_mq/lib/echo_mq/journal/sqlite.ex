defmodule EchoMQ.Journal.SQLite do
  @moduledoc """
  Local-development durability: the shipped `EchoStore.Journal` (per-group exqlite, WAL,
  one owner). Zero infrastructure — a file per group on disk — so `mix test` and a laptop
  run get the full transactional-enqueue guarantee with nothing to provision. This is the
  default adapter. In v4 it remains the **rebuildable local working set**; `store.design.md`
  schedules `exqlite` to fold into CubDB (the `Graft` adapter), at which point this stays
  the dev convenience, not a durable store.
  """
  @behaviour EchoMQ.Journal.Adapter
  alias EchoStore.Journal

  @impl true
  def child_spec(opts), do: Journal.child_spec(opts)

  @impl true
  def intend_and_enqueue(j, conn, name_id, version),
    do: Journal.intend_and_enqueue(j, conn, name_id, version)

  @impl true
  def record(j, job_id, name_id, version), do: Journal.record(j, job_id, name_id, version)
  @impl true
  def mark_enqueued(j, job_id), do: Journal.mark_enqueued(j, job_id)
  @impl true
  def record_many(j, triples), do: Journal.record_many(j, triples)
  @impl true
  def replay(j, conn), do: Journal.replay(j, conn)
  @impl true
  def compact(j), do: Journal.compact(j)
  @impl true
  def last_applied(j, name_id), do: Journal.last_applied(j, name_id)
  @impl true
  def stats(j), do: Journal.stats(j)
end
