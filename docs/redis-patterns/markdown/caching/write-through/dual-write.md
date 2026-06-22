# The synchronous dual write

> Route: `/redis-patterns/caching/write-through/dual-write` · Module R1.02 · dive 1 · Source:
> `content/fundamental/write-through.md.txt` (the *How It Works* sequence + *Redis Commands Used*) · Grounding:
> `EchoCache.Table` `handle_call({:put, …})` (`echo/apps/echo_cache/lib/echo_cache/table.ex`) — `SET … PX` to L2
> then `insert` into L1, both in one synchronous call.

One write reaches both layers. The L1 ETS cache and the L2 Valkey row update together, and the call does not return
until both are done. This is the write half of write-through — the source's *How It Works* sequence, focused on the
dual write, with the one Valkey command its cache side runs.

## Two writes, bound into one

The write-through write is a single logical step made of two store writes. `EchoCache.Table.put` receives a changed
value, sets the L2 Valkey row with `SET … PX`, writes the L1 ETS table with `insert`, and returns once both have
landed. The two layers are never out of step at the moment the write returns, because the write does not return
until both are done. In the as-built code the order is L2 first, then L1: the `handle_call({:put, id, value,
version})` clause runs `Connector.command(["SET", l2, version <> value, "PX", ttl])`, matches `{:ok, "OK"}`, then
calls `insert(state, id, value, version)`.

The order is a discipline, and a write-then-invalidate caller chooses the safe order for its own two stores. If the
source write fails, the cache write is never attempted, so the cache cannot end up holding a value the source
rejected. If the cache write fails after the source succeeds, the writer treats it as a failed write rather than
reporting success with a stale cache. The latency dive covers those failure modes; this dive fixes the shape of the
successful path.

- **dual write** — one logical write that touches two layers, the L1 cache and the L2 store, before it returns.
- **synchronous** — the caller waits for both writes to land; the write completes only when both are done.
- **`SET … PX`** — the Valkey write-path command. `SET key value PX <ms>` stores a key, its value, and a millisecond
  TTL in one command — value and expiry together, atomically.
- **acknowledge** — a store confirms the write landed. `{:ok, "OK"}` from Valkey gates the L1 insert; both gate the
  return.

## SET — value and TTL in one command

The cache half of the write is one Valkey command. `SET … PX` sets the value and the millisecond TTL together: the
L2 row carries the declared TTL on the server's own clock, so the second layer expires itself even if every node
forgets. A separate `EXPIRE` after `SET` leaves an immortal key if the process dies between the two — which is why
the write sets value and expiry atomically. The command is the cache side of the write; the database write follows
on the same path.

```
SET ecc:{instruments}:AST0NgWEfAEJfs "<version><value>" PX 300000   # value + 5-minute TTL, atomically
SET ecc:{instruments}:AST0NgWEfAEJfs "<version><value>" PX 3600000  # value + 1-hour TTL
```

The key is the cache's own form `ecc:{<table>}:<id>` (`EchoCache.Keyspace.key/2`): a fresh prefix beside `emq:`,
with the table name hash-tagged in braces so every key of one cache lands in one cluster slot. The value is framed
`version <> value` — a 14-byte branded version prefix in front of the bytes — so a later coherence message can
compare newer-wins.

## On EchoCache

Take one change: an instrument reference row is updated. `EchoCache.Table.put` sets the new value into the L2 Valkey
row and the L1 ETS table, then returns. A later read serves the cached value and matches the source, because the
cache was written on the same path. A caller above the table calls `put` and reads `fetch`; it is never exposed to
the two store writes directly.

```
# echo/apps/echo_cache/lib/echo_cache/table.ex — handle_call({:put, id, value, version})
l2 = Keyspace.key(state.table, id)                     # "ecc:{instruments}:AST0NgWEfAEJfs"

{:ok, "OK"} =
  Connector.command(state.conn, [
    "SET", l2, version <> value, "PX", Integer.to_string(state.spec.ttl_ms)
  ])                                                   # L2 Valkey: value + TTL, atomically

insert(state, id, value, version)                      # L1 ETS, on the same call
{:reply, :ok, state}                                   # returns only after both land
```

`put/3` mints the version now, of the table's kind; `put/4` carries the writer's own. The functional-Elixir and OTP
craft behind the echo data layer is taught in the [`/elixir`](/elixir) course. This dive stays on the Valkey side:
one command writes the cache on the same path as the source.

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set) — `SET key value PX <ms>` sets value and TTL atomically; the L2 write-path command in the put clause.
- [Valkey — Topics](https://valkey.io/topics/) — the engine the L2 layer is written against; the live line is Valkey.
- [Redis — SET](https://redis.io/commands/set) — the string write-path command, with optional `EX`/`PX` expiry.
- [Redis — Documentation](https://redis.io/docs/) — the string and expiry commands the cache write is built from.

### Related in this course
- [R1.02 · Write-through](/redis-patterns/caching/write-through) — the module hub.
- [R1.02.2 · The consistency guarantee](/redis-patterns/caching/write-through/consistency) — the next dive.
- [R1.02.3 · The latency cost](/redis-patterns/caching/write-through/latency-cost) — the price of the dual write.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [/echomq](/echomq) — the bus behind the coherence lane the framed version feeds.
