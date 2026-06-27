# Server-assisted client-side caching

> Route: `/redis-patterns/caching/client-side-caching` · Module R1.04 · Source:
> `content/fundamental/client-side-caching.md.txt` · Grounding: the real broadcast-coherence path of EchoStore — the
> client holds L1 ETS, the server pushes invalidations over RESP3 pub/sub (`EchoStore.Coherence.broadcast/4`,
> `coherence.ex:82`; the RESP3 subscription `Connector.start_link(protocol: 3, push_to: self())`, `table.ex:243`), plus
> the SHA1 script cache (`EchoMQ.Script.new/2`, EVALSHA-first, `script.ex:13`) shown as a parallel, not a door.

Eliminate network round-trips for frequently accessed keys by caching values in application memory, with the engine
automatically sending invalidation messages when data changes. Even with sub-millisecond Valkey response times, the
network round-trip can be a bottleneck for ultra-high-throughput applications. Client-side caching stores frequently
accessed data in the application's local memory, with the server managing invalidation.

## The Architecture

This creates a multi-tier cache:

- **L1 (local memory)** — nanosecond access, managed by the application.
- **L2 (Valkey)** — microsecond to millisecond access.
- **L3 (database)** — millisecond access.

The key innovation is that the server records which keys each client holds and sends invalidation messages when those
keys change. A repeated read of an unchanged key never leaves the process; the value is a memory lookup, and the server
pushes a message the moment it goes stale. This is exactly the shape of EchoStore (`echo/apps/echo_store`): an L1 ETS
table in the caller's process over an L2 Valkey row, with coherence carried by a server-side push.

## Tracking Modes

**Default tracking.** The server remembers which keys each client has requested. After `CLIENT TRACKING ON`, every
`GET` causes the server to record that this client accessed that key; if another client modifies the key, an
invalidation message is pushed to the original client.

```
CLIENT TRACKING ON
```

The trade-off is that the server must maintain a table mapping keys to client IDs. That table consumes memory
proportional to the number of tracked keys.

**Broadcasting mode.** Instead of recording individual key accesses, clients subscribe to key prefixes. The server
broadcasts invalidation messages to all subscribers when any matching key changes.

```
CLIENT TRACKING ON BCAST PREFIX user: PREFIX session:
```

This client receives invalidations for any key starting with `user:` or `session:`. The trade-off reverses: a client
may receive invalidations for keys it does not have cached locally, but server memory stays minimal because it tracks
prefix subscriptions, not individual key accesses. EchoStore rides the broadcast shape over plain pub/sub: a table
subscribes to one channel, `ecc:{<table>}:coh`, and the writer publishes a message naming the changed key.

## How Invalidation Works

When tracking is enabled and a key changes:

1. The server checks which clients have accessed (or subscribed to) that key.
2. The server sends an invalidation message containing the key name.
3. The client removes the key from its local cache.
4. The next access fetches fresh data from the server.

This keeps local caches synchronized without polling. In EchoStore the message carries one more thing than a bare
`CLIENT TRACKING` invalidation does — the writer's mint-time version — so a late stale message can never erase a newer
row.

## Redis Commands

```
CLIENT TRACKING ON                          # enable tracking for the connection
CLIENT TRACKING ON BCAST PREFIX user:       # broadcast mode with a prefix
CLIENT TRACKING ON REDIRECT 123             # redirect invalidations to another connection
CLIENT TRACKING OFF                         # disable tracking
```

The `REDIRECT` form routes invalidations to a separate connection, which suits a dedicated invalidation handler — and
a RESP2 client that cannot receive push frames on its data connection.

## The NOLOOP, OPTIN, and OPTOUT Options

By default, modifying a key sends an invalidation for it back to the modifying client. `NOLOOP` suppresses that — the
client that wrote the value already holds it, so it has no reason to drop its own copy.

```
CLIENT TRACKING ON NOLOOP
```

`OPTIN` and `OPTOUT` give per-key control over what is tracked. With `OPTIN`, keys are tracked only when caching is
explicitly enabled before the read:

```
CLIENT TRACKING ON OPTIN
CLIENT CACHING YES
GET user:123       # this key will be tracked
CLIENT CACHING NO
GET temp:data      # this key will NOT be tracked
```

`OPTOUT` is the mirror image: everything is tracked unless explicitly excluded.

## When to Use Client-Side Caching

This pattern benefits:

- Ultra-high-throughput applications where network RTT matters.
- Frequently accessed "hot" keys.
- Read-heavy workloads with relatively stable data.
- Applications already maintaining local caches that need invalidation.

## Considerations

- **Memory management** — the application must bound its local cache size, evicting when memory is constrained.
- **Complexity** — handling invalidation messages requires dedicated connection management or async processing.
- **Not for volatile data** — if data changes constantly, invalidation traffic may exceed the benefit of caching.
- **RESP3 recommended** — the RESP3 protocol carries push notifications natively, making invalidation handling cleaner.
  EchoStore requires it for the broadcast lane: the table opens a RESP3 connection precisely so a push and a reply can
  share one wire.

## Applied — the broadcast lane in EchoStore

The near cache codemojex would put in front of its emoji set is an EchoStore table: an L1 ETS row
in the caller's process over an L2 Valkey row keyed `ecc:{instruments}:<id>`. Coherence is carried by a server push,
not by polling. On start the table opens a RESP3 connection and subscribes to its coherence channel:

```elixir
# echo/apps/echo_store/lib/echo_store/table.ex (init) — the broadcast subscription
{:ok, sub} =
  Connector.start_link(
    Keyword.get(opts, :connector, [])
    |> Keyword.merge(protocol: 3, push_to: self(), heartbeat_ms: 0)
  )

:ok = Connector.subscribe(sub, Coherence.channel(table_str))   # ecc:{<table>}:coh
```

When a writer changes a row, it publishes the change on that channel. The message is twenty-nine bytes — the cached
name, a colon, and the writer's mint-time version, and nothing else:

```elixir
# echo/apps/echo_store/lib/echo_store/coherence.ex
def channel(table), do: "ecc:{" <> table <> "}:coh"
def payload(<<_::binary-14>> = id, <<_::binary-14>> = version), do: id <> ":" <> version

def broadcast(conn, table, id, version) do
  Connector.command(conn, ["PUBLISH", channel(table), payload(id, version)])
end
```

Every subscribing table receives the push as `{:emq_push, ["message", channel, payload]}` and applies it newer-wins in
its owner. The committed measure (`bcs.4.md`): the message is a **twenty-nine-byte** payload, and the
broadcast lane runs at **broadcast median 72 us fire-and-forget**, against the job lane at **148 us at-least-once** —
*the guarantee costs 2.1 times the latency*. A lost broadcast costs one TTL of staleness, which is why a surface where
a stale read costs money rides the durable job lane over EchoMQ's fair lanes instead.

## The three dives

The module takes the pattern in three steps — *track → invalidate → the same shape elsewhere*:

- **R1.04.1 · CLIENT TRACKING** — the server-assisted near cache: how the server records which keys a connection
  holds, in default and broadcast mode, and the real RESP3 subscription EchoStore opens for it.
- **R1.04.2 · The invalidation push** — when a tracked key changes, the server sends a RESP3 message naming the key to
  every holder, which drops its local copy and re-reads lazily; the real `Coherence.broadcast/4` and the 29-byte
  message.
- **R1.04.3 · The SHA1 script-cache parallel** — `EVALSHA` with a precomputed SHA1 and a `NOSCRIPT` fallback, the same
  cache-then-invalidate shape in EchoMQ's real `EchoMQ.Script.new/2`.

The third dive draws a **parallel** only. The script cache uses the same cache-then-invalidate idea as
`CLIENT TRACKING`; the queue protocol itself — the full Lua bundle and the version fence — is the dedicated EchoMQ
course, which this module links forward to rather than teaches.

**One idea, two places.** Server-assisted client-side caching is one instance of a broader move: keep a derived copy
near the work, and accept a signal that invalidates it when the source changes. EchoStore holds an L1 ETS value and
drops it on a broadcast push; `EchoMQ.Script` holds a script's precomputed SHA1 and resends the body on a `NOSCRIPT`
reply. The signal differs; the shape is the same.

## References

### Sources
- [Valkey — Client-side caching](https://valkey.io/topics/client-side-caching/) — server-assisted tracking and its invalidation messages; the unversioned, orderless gap EchoStore's mint-time version closes.
- [Valkey — Pub/Sub](https://valkey.io/topics/pubsub/) — at-most-once delivery, the broadcast lane's contract taken whole.
- [Redis — Client-side caching](https://redis.io/docs/latest/develop/use/client-side-caching/) — the server-assisted near cache and `CLIENT TRACKING`.
- [Redis — CLIENT TRACKING](https://redis.io/commands/client-tracking) — default and broadcast modes, `REDIRECT`, `NOLOOP`, and `OPTIN`/`OPTOUT`.

### Related in this course
- [R1.04.1 · CLIENT TRACKING](/redis-patterns/caching/client-side-caching/client-tracking) — the near cache.
- [R1.04.2 · The invalidation push](/redis-patterns/caching/client-side-caching/invalidation-push) — the change notification.
- [R1.04.3 · The SHA1 script-cache parallel](/redis-patterns/caching/client-side-caching/script-cache) — the same shape, applied.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [R0 · Overview](/redis-patterns/overview) — Valkey under codemojex.
- [/echomq/cache](/echomq/cache) — the EchoStore :tracking coherence mode, in depth.
