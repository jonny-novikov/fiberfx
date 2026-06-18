# EchoStore.Durability — Postgres & Graft plugins

Two bring-your-own durability adapters for the `EchoStore.Durability.Adapter` contract, plus the
behaviour itself. They implement the same transactional-outbox semantics as the shipped SQLite
adapter (`EchoStore.Journal`) — record the intent before the enqueue, remember the newest version
after the apply, recover by replay, compact by coverage — over different backends.

## Plugin isolation

Core ships only the adapters that need **no extra dependency**: `EchoStore.Journal` (SQLite over
`exqlite`) and `EchoStore.Durability.Memory` (ETS, tests). An adapter that needs its own
dependency is a bring-your-own plugin a host provides **in its own app**, so core never carries
it:

| Adapter | Extra dependency | Lives in |
|---------|------------------|----------|
| `EchoStore.Durability.Adapter` (behaviour) | none | **echo_store core** |
| `EchoStore.Journal` (SQLite) | `exqlite` (already core) | echo_store core |
| `EchoStore.Durability.Postgres` | `ecto_sql` + `postgrex` | a host app |
| `EchoStore.Durability.Graft` | the Graft tier + `cubdb` | a host app |

## Files & placement

```
core/adapter.ex      -> apps/echo_store/lib/echo_store/durability/adapter.ex   (behaviour, core)
plugins/postgres.ex  -> <host_app>/lib/.../durability/postgres.ex              (ecto_sql + postgrex)
plugins/graft.ex     -> <host_app>/lib/.../durability/graft.ex                 (Graft volume + cubdb)
```

In this umbrella they are placed in `echo_store` (the behaviour) and `codemojex` (both plugins,
since it already depends on `ecto_sql`/`postgrex` and on `echo_store`).

> **Compilation note:** parse-checked (valid Elixir AST), not `mix compile`-d here — the plugins
> pull `ecto_sql`/`postgrex` (Postgres) and the Graft runtime + `cubdb` (Graft), which need the
> umbrella with network access to Hex. The behaviour (`adapter.ex`) compiles standalone in core.
> All three target the real `EchoStore.Coherence` (`payload`/`parse`/`queue`/`newer?`),
> `EchoStore.Table.apply_coherence/4`, `EchoMQ.Lanes.enqueue/5`, and `EchoStore.Graft.*` APIs.

## The contract (`EchoStore.Durability.Adapter`)

`record/4`, `mark_enqueued/2`, `intend_and_enqueue/4`, `last_applied/2`, `apply_and_remember/4`,
`replay/2`, `compact/1`, `stats/1`; optional `start_link/1`, `record_many/2`, `handler/2`,
`stop/1`. A *version* is a 14-byte branded id; newer-wins compares the trailing 11 chars
(`substr(version, 4)` in SQL).

## Postgres — atomic enqueue without Oban's ceiling

The intent insert runs on the **host's own Ecto Repo**, so inside the host's `Repo.transaction/1`
it commits atomically with the business row, while the bus/dequeue/retries/history stay on Valkey.
Postgres holds only the small `emq_intents` outbox and `emq_applied` memory.

```elixir
# 1. migration
def up, do: Enum.each(EchoStore.Durability.Postgres.up(), &execute/1)

# 2. handle
pg = EchoStore.Durability.Postgres.new(repo: MyApp.Repo, group: group_id, table: "players")

# 3a. compose the intent into the host's own transaction (atomic outbox)
MyApp.Repo.transaction(fn ->
  order = Repo.insert!(order_changeset)
  {:ok, _seq} = EchoStore.Durability.Postgres.record(pg, EchoData.BrandedId.generate!("JOB"), order.id, version)
end)

# 3b. or the all-in-one verb
{:ok, job_id} = EchoStore.Durability.Postgres.intend_and_enqueue(pg, conn, name_id, version)
```

## Graft — the commit log is the outbox (EchoMQ 4+)

No separate intents table: an intent **is** a Graft commit, so it is durable *and replicated*
(rolled up to object storage by the Streamer). Two small CubDB cursors hold the enqueue watermark
and the applied memory. Recovery is a head-snapshot scan of the reserved intent page range.

```elixir
g = EchoStore.Durability.Graft.new(volume_id: vol, group: group_id, table: "players")
{:ok, job_id} = EchoStore.Durability.Graft.intend_and_enqueue(g, conn, name_id, version)
{:ok, counts} = EchoStore.Durability.Graft.replay(g, conn)   # after a restart
```

Run `EchoStore.Graft.Committer` alongside it for the steady-state drain; this adapter is the
journal-contract face of the same log (recovery, memory, stats).
