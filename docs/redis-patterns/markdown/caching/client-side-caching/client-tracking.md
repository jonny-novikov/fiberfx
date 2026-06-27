# CLIENT TRACKING

> Route: `/redis-patterns/caching/client-side-caching/client-tracking` · Module R1.04 · dive 1 · Source:
> `content/fundamental/client-side-caching.md.txt` (the *Tracking Modes* sections) · Grounding: real `CLIENT TRACKING`
> (default and `BCAST` modes); the EchoStore near cache opens a RESP3 subscription for the broadcast shape
> (`Connector.start_link(protocol: 3, push_to: self())`, `table.ex:243`; `Connector.subscribe`, `table.ex:248`).

The server keeps a record of which keys each connection holds, so it can warn that connection the moment one changes.
A near cache is only correct if something tells it when a value goes stale. `CLIENT TRACKING` is how the server keeps
that record.

## The server-side record

Turn tracking on for a connection with `CLIENT TRACKING ON`. From then on, every key the connection reads is noted by
the server in a tracking table: the key, and the connections holding it. The table is the whole mechanism. When a key
is modified — by this connection or any other — the server looks up who holds it and sends each of them an
invalidation. The next dive covers that push; this one is about how the record is built.

The default record is exact: the server remembers the precise keys a connection read, so an invalidation arrives only
for keys the connection actually holds. Exactness has a cost — the server stores a table proportional to the number of
distinct keys tracked across all connections. That is the memory the server spends to keep every near cache honest.

## Default vs broadcast

There are two ways to keep the record:

- **Default mode** tracks the exact keys each connection read — precise, but the server holds a per-key table.
- **Broadcast mode** (`CLIENT TRACKING ON BCAST PREFIX set:`) tracks *prefixes* instead: the server keeps no per-key
  table and notifies every broadcast subscriber whenever any key under a registered prefix changes. Cheaper for the
  server, but a connection may receive invalidations for keys it never read.

The choice is a trade between server memory and notification precision. The workload — how many distinct hot keys, how
wide the prefix — decides which is cheaper.

## The near cache in EchoStore

Picture codemojex's emoji-set read path with a near cache in front of it. The scoring consumer reads an
emoji set often and the set never changes for the round's life. With a near cache on, the table holds the set in local
L1 ETS and lets the server carry the change notification; later reads are memory lookups. The first read still falls
through to Valkey for the value, and the table populates both the L2 row (`ecc:{cm_emojisets}:<id>`) and the local copy.
Every later read of the unchanged set stays in the process.

EchoStore rides the broadcast shape over plain pub/sub. The table opens a RESP3 connection at start and subscribes to
its coherence channel — the real `init` path:

```elixir
# echo/apps/echo_store/lib/echo_store/table.ex (init)
{:ok, sub} =
  Connector.start_link(
    Keyword.get(opts, :connector, [])
    |> Keyword.merge(protocol: 3, push_to: self(), heartbeat_ms: 0)
  )

:ok = Connector.subscribe(sub, Coherence.channel(table_str))   # ecc:{<table>}:coh
```

The channel name derives from the table name and nothing else (`Coherence.channel("cm_emojisets")` is
`ecc:{cm_emojisets}:coh`). A writer that changes a set publishes on that channel; the next dive follows the push.

## References

### Sources
- [Valkey — Client-side caching](https://valkey.io/topics/client-side-caching/) — server-assisted tracking, default and broadcast modes, and the invalidation message.
- [Valkey — Pub/Sub](https://valkey.io/topics/pubsub/) — the channel the broadcast subscription rides; at-most-once delivery.
- [Redis — CLIENT TRACKING](https://redis.io/commands/client-tracking) — turning tracking on, the default and `BCAST` modes, and `REDIRECT`.

### Related in this course
- [R1.04 · Client-side caching](/redis-patterns/caching/client-side-caching) — the module hub.
- [R1.04.2 · The invalidation push](/redis-patterns/caching/client-side-caching/invalidation-push) — the next dive.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [/echomq/cache](/echomq/cache) — EchoStore :tracking over RESP3 CLIENT TRACKING, in depth.
