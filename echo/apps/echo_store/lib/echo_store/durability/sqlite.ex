defmodule EchoStore.Durability.SQLite do
  @moduledoc """
  Local-development & default durability: the shipped `EchoStore.Journal` (per-group
  `exqlite`, WAL, one owner). Zero infrastructure — a file per group on disk — so `mix
  test` and a laptop run get the full transactional-enqueue guarantee with nothing to
  provision. This is the default adapter. In EchoMQ 4+ it remains the **rebuildable local
  working set**; `store.design.md` schedules `exqlite` to fold into CubDB (the `Graft`
  adapter), at which point this stays the dev convenience, not a durable store.
  """
  @behaviour EchoStore.Durability.Adapter
  alias EchoStore.Journal

  @impl EchoStore.Durability.Adapter
  def child_spec(opts), do: Journal.child_spec(opts)

  @impl EchoStore.Durability.Adapter
  def intend_and_enqueue(j, conn, name_id, version),
    do: Journal.intend_and_enqueue(j, conn, name_id, version)

  @impl EchoStore.Durability.Adapter
  def record(j, job_id, name_id, version), do: Journal.record(j, job_id, name_id, version)
  @impl EchoStore.Durability.Adapter
  def mark_enqueued(j, job_id), do: Journal.mark_enqueued(j, job_id)
  @impl EchoStore.Durability.Adapter
  def record_many(j, triples), do: Journal.record_many(j, triples)
  @impl EchoStore.Durability.Adapter
  def replay(j, conn), do: Journal.replay(j, conn)
  @impl EchoStore.Durability.Adapter
  def compact(j), do: Journal.compact(j)
  @impl EchoStore.Durability.Adapter
  def last_applied(j, name_id), do: Journal.last_applied(j, name_id)
  @impl EchoStore.Durability.Adapter
  def stats(j), do: Journal.stats(j)
end
