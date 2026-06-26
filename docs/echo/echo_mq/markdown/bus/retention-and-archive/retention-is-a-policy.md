# Retention is a policy — the Bus, module 05, dive 01

> Route: `/echomq/bus/retention-and-archive/retention-is-a-policy`. Surface: `EchoMQ.Stream.trim/4` +
> `EchoMQ.StreamRetention`. Real `echo/apps/echo_mq` code; no Lua (`XTRIM` issued direct).

## The frame

Retention is a **policy**, not a default. A stream you want unbounded is never declared and so is never
silently trimmed; a stream you want bounded declares its window and the trim re-applies it on its own beat.
The trap the design refuses: coupling a **safety** property (bounded memory) to a **liveness** fact (a
consumer is up). That coupling is the silent-no-op class — fold the trim into a consumer's loop and a stream
nobody drains grows forever, while a stream whose consumer crashed stops being bounded exactly when you most
need it bounded. So the cadence lives on its own beat, decoupled from any `EchoMQ.StreamConsumer`.

## The two windows

`EchoMQ.Stream.trim(conn, queue, name, window)` removes the entries **outside** a declared window over
`XTRIM` issued direct. Two window forms:

- `{:maxlen, count, approx?}` → `XTRIM <key> MAXLEN [~|=] <count>` — keep the `count` newest entries, remove
  the older. Bound by **length**.
- `{:minid, %DateTime{}, approx?}` → `XTRIM <key> MINID [~|=] "<ms>-0"` — remove every entry minted strictly
  **before** the instant; the floor id is derived from `minid_floor/1` (`ms = DateTime.to_unix(dt,
  :millisecond)`, the rung's one piece of real id-math — never a raw snowflake integer to the wire). Bound by
  **age**.

It answers `{:ok, removed_count}` (the integer `XTRIM` returns) or `{:error, term}` verbatim — a `WRONGTYPE`
against a non-stream key is **surfaced, not swallowed**. It raises `ArgumentError` before any wire on a
malformed queue/stream name (policy before existence before write, the `append_id/5` precedent).

## The safe default — `~` vs `=` (INV4)

The third element of the window, `approx?`, selects the trim mode:

- `true` → `~` (approximate) — the **safe default**. `XTRIM` trims in whole macro-nodes, so it may
  **under-trim** (leave a few extra entries) but can **never over-trim**. Because it can never reach past the
  window edge, it can never delete an entry **inside** the window — **INV4** holds by construction.
- `false` → `=` (exact) — the **opt-in**. Removes precisely to the window edge.

Either way the blast radius is bounded by the window: a trim can never delete an entry inside it. That is the
guarantee that makes a default-on trim safe — it can only ever shrink the part of the log you declared
expendable.

## The named opt-in driver — `EchoMQ.StreamRetention`

`EchoMQ.StreamRetention` is the named, opt-in trim driver: a `:transient` GenServer that beats on `:tick_ms`
(default `1_000`) and, on each beat, re-applies a **declared** per-stream `:policy` — a list of `{queue,
name, window}` — via the public `EchoMQ.Stream.trim/4`. Three properties make it safe:

- **Decoupled from consumer liveness.** Retention is a property of the **stream**, not of a consumer: a
  stream nobody drains still trims if its policy is declared here, and the `EchoMQ.StreamConsumer` loop is
  never touched. The cadence lives here, on its own beat.
- **Opt-in, owner-started.** Like the queue's `EchoMQ.Pump`, there is no `mod:` auto-start. A deployment that
  wants continuous bounded memory over a declared stream starts the driver; a stream you want unbounded is
  never declared. No default-on destructive sweep.
- **BEAM-side policy, idempotent.** The policy is process state, not a keyspace subkey (no
  `emq:{q}:stream:<name>:policy` is written), so there is no at-rest cleanup obligation. The trim is
  idempotent over the stream — re-applying the same window removes nothing already removed — so a `:transient`
  restart loses no guarantee and over-deletes nothing.

A manual `EchoMQ.Stream.trim/4` call is the equally-supported cadence: the driver is sugar over the verb,
never the only path. `sweep/1` exposes one beat for a direct-drive test, answering `{:ok, %{trimmed: n,
calls: k}}`.

## The worked example — bound a codemojex activity feed

A codemojex activity feed (`GES` guess events appended on the game lifecycle) wants the **last 10_000**
events resident and no more. Declare a length window and start the driver; every beat re-caps the feed:

```elixir
{:ok, _} =
  EchoMQ.StreamRetention.start_link(
    conn: conn,
    tick_ms: 1_000,
    policy: [{"codemojex", "activity", {:maxlen, 10_000, true}}]
  )
```

The feed stays at ~10_000 resident events; the `~` default never deletes one of the newest 10_000.

## Pattern & implementation

- **The pattern (Redis Patterns Applied).** A stream needs retention; `XTRIM MAXLEN`/`MINID` caps it by
  length or age; the approximate `~` form is cheaper and safe. [Streams & Events](/redis-patterns/streams-events)
  teaches stream retention.
- **The implementation (echo_mq).** `EchoMQ.Stream.trim/4` issues `XTRIM` direct, mapping `MAXLEN`/`MINID` to
  the two declared windows; `~` is the safe default that can never delete inside the window (INV4); the
  `EchoMQ.StreamRetention` driver re-applies a declared BEAM-side policy on its own beat, decoupled from
  consumer liveness.

## Recap

Retention bounds the live log by length or age, on its own beat — never coupled to a consumer being up. The
`~` approximate default can never over-trim, so it can never delete inside the window (INV4); the
`EchoMQ.StreamRetention` driver re-applies a declared, BEAM-side, idempotent policy, opt-in and owner-started.
A manual `trim/4` is the equally-supported cadence. What this dive does not cover: where the trimmed records
go — they are folded to the durable floor first, so nothing is lost. That is the next dive.

## References

### Sources
- [Valkey — XTRIM](https://valkey.io/commands/xtrim/) — the trim by `MAXLEN` or `MINID` the two windows compile to.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the approximate `~` trim and the macro-node structure that makes it safe.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hashtag co-locates a queue and its stream on one of 16384 slots.

### Related in this course
- [Retention & the archive](/echomq/bus/retention-and-archive) — the module this dive belongs to.
- [Nothing is lost](/echomq/bus/retention-and-archive/nothing-is-lost) — where the trimmed records go before the trim.
- [The stream log](/echomq/bus/the-stream-log) — the writer whose `EVT` ids this trim bounds.
- [The Bus](/echomq/bus) — the pillar landing.
- [The Branded Component System · the persistence floor](/bcs/persistence) — the manuscript chapter this module's floor realizes.
