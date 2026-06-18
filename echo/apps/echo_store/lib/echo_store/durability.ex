defmodule EchoStore.Durability do
  @moduledoc """
  Pluggable durability for the EchoMQ transactional-enqueue outbox. The facade reads the
  configured adapter and dispatches; nothing else knows which backend is durable. This is
  how the Postgres-vs-Oban balance is struck: the **bus stays on Valkey** (fast, reliable,
  D-2 volatile) and only the low-volume **outbox intents** land in the journal — so a
  single-instance Postgres is a small, mostly-idle dependency, not the hot path Oban puts
  every dequeue/heartbeat/ack through. Durability is a config choice, not a rewrite:

      config :echo_store, EchoStore.Durability, adapter: EchoStore.Durability.SQLite

  ## Plugin isolation (no dependency bloat)

  Core ships only the adapters that need no extra dependency — `SQLite` (the shipped
  `EchoStore.Journal` over `exqlite`) and `Memory` (ETS, tests). An adapter that needs its
  own dependency — `Postgres` (`ecto_sql` + `postgrex`) or the EchoMQ 4+ `Graft`
  commit-log-as-outbox — is a bring-your-own plugin a host provides in its own app, so this
  app never carries it. See `EchoStore.Durability.Adapter`.
  """
  @behaviour EchoStore.Durability.Adapter
  alias EchoStore.Durability.Adapter

  @spec adapter() :: module()
  def adapter, do: Keyword.fetch!(config(), :adapter)

  @spec config() :: keyword()
  def config,
    do: Application.get_env(:echo_store, __MODULE__, adapter: EchoStore.Durability.SQLite)

  @impl Adapter
  def child_spec(opts), do: adapter().child_spec(Keyword.merge(config(), opts))

  @impl Adapter
  def intend_and_enqueue(journal, conn, name_id, version),
    do: adapter().intend_and_enqueue(journal, conn, name_id, version)

  @impl Adapter
  def record(journal, job_id, name_id, version),
    do: adapter().record(journal, job_id, name_id, version)

  @impl Adapter
  def mark_enqueued(journal, job_id), do: adapter().mark_enqueued(journal, job_id)

  @impl Adapter
  def record_many(journal, triples), do: adapter().record_many(journal, triples)

  @impl Adapter
  def replay(journal, conn), do: adapter().replay(journal, conn)

  @impl Adapter
  def compact(journal), do: adapter().compact(journal)

  @impl Adapter
  def last_applied(journal, name_id), do: adapter().last_applied(journal, name_id)

  @impl Adapter
  def stats(journal), do: adapter().stats(journal)
end
