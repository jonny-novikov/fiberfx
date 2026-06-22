# The invalidation push

> Route: `/redis-patterns/caching/client-side-caching/invalidation-push` · Module R1.04 · dive 2 · Source:
> `content/fundamental/client-side-caching.md.txt` (the *How Invalidation Works* section) · Grounding: real RESP3 push
> frames + EchoCache's broadcast lane (`Coherence.broadcast/4` PUBLISH `ecc:{<table>}:coh`, `coherence.ex:82`; the
> 29-byte message `id <> ":" <> version`, `coherence.ex:35`; the push handler `{:emq_push, ["message", …]}`,
> `table.ex:362`).

A tracked key changes; the server pushes its name to every connection holding it, and only those. The near caches drop
their copy. Tracking records who holds what; the push is what the record is for.

## One message, naming the key

The invalidation is a push, not a reply to a request. On a RESP3 connection the server can send a frame the client did
not ask for, and tracking uses exactly that: when a tracked key is modified, an invalidation message arrives carrying
the name of the key — or a null, meaning the whole local cache should be cleared, as on a flush. The message does not
carry the new value. It says only that the held copy is no longer trustworthy.

That is the minimal contract. A bare `CLIENT TRACKING` invalidation has no record of what the client cached, only which
keys the client read, so the most it can report is "this key changed." A change is a change: a `SET`, a `DEL`, an
expiry, an eviction all trigger the same push to the key's holders.

## What the holder does with it

The client's job on receiving an invalidation is small and fixed: drop the local copy of the named key. It does not
re-read eagerly. The next time the application asks for that key, the near cache misses, the client fetches once from
the server, repopulates the local copy, and is tracked again. So an invalidation costs nothing until the key is next
needed — and a key that is never read again costs only the one dropped entry.

The lifecycle runs through four states: the holder serves reads from memory; the push arrives and the copy is now
suspect; the holder drops the copy without re-reading; the next access misses, fetches once, and is tracked again.

## Applied — the broadcast lane in EchoCache

EchoCache rides this push over plain pub/sub, and adds one byte-field a bare invalidation lacks: the writer's mint-time
version. A writer that changes an instrument row publishes the change on the table's channel — the real
`Coherence.broadcast/4`:

```elixir
# echo/apps/echo_cache/lib/echo_cache/coherence.ex
def channel(table), do: "ecc:{" <> table <> "}:coh"
def payload(<<_::binary-14>> = id, <<_::binary-14>> = version), do: id <> ":" <> version

def broadcast(conn, table, id, version) do
  Connector.command(conn, ["PUBLISH", channel(table), payload(id, version)])
end
```

Every subscribing table receives the push and applies it newer-wins in its owner:

```elixir
# echo/apps/echo_cache/lib/echo_cache/table.ex
def handle_info({:emq_push, ["message", _channel, payload]}, state) do
  case Coherence.parse(payload) do
    {:ok, id, version} -> Ring.publish(state.ring, {id, version})
    :error -> :ignored
  end
  {:noreply, state}
end
```

The message is twenty-nine bytes — a cached name, a colon, and the writer's mint-time version. That version is the one
thing a bare `CLIENT TRACKING` invalidation cannot send, and it is what lets a late stale message bounce off both
layers: the L2 drop runs as a Lua script that deletes the row only when the incoming version is newer than the one
framed into the stored value. The committed measure (`content/bcs4.2.md`): **median push latency 72 us over 100
messages**, against the durable job lane at **148 us at-least-once** — *the guarantee costs 2.1 times the latency*. A
lost broadcast costs one TTL of staleness, which is why a risk surface rides the job lane instead.

## References

### Sources
- [Valkey — Pub/Sub](https://valkey.io/topics/pubsub/) — at-most-once delivery: a message is delivered once if at all; the broadcast lane's contract.
- [Valkey — Client-side caching](https://valkey.io/topics/client-side-caching/) — the invalidation message and its null clear-all form; the unversioned gap the 29-byte message closes.
- [Redis — CLIENT TRACKING](https://redis.io/commands/client-tracking) — the tracking that drives the push, and the `REDIRECT` option.

### Related in this course
- [R1.04 · Client-side caching](/redis-patterns/caching/client-side-caching) — the module hub.
- [R1.04.1 · CLIENT TRACKING](/redis-patterns/caching/client-side-caching/client-tracking) — the record the push uses.
- [R1.04.3 · The SHA1 script-cache parallel](/redis-patterns/caching/client-side-caching/script-cache) — the next dive.
- [/echomq](/echomq) — the connector's send-only push path, in depth.
