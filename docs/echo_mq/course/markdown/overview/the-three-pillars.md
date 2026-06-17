# The three pillars

> **Route:** `/echomq/overview/the-three-pillars` · **surface:** dive · **chapter:** Overview ·
> **crumbs:** EchoMQ › Overview › The three pillars
> **md source-of-record.** The `[RECONCILE]` markers below flag every claim that is ahead of the as-built
> `echo/apps/echo_mq` code (chiefly the Bus's retained, replayable event log — design canon, not yet on disk). The
> HTML reads as shipped and carries **no** `[RECONCILE]` marker.

## The fact

EchoMQ is one Valkey-native job system you own, canonical in Elixir. Above the one wire it owns stand three pillars,
and each answers a different question about moving data between parts of a system:

- **The Queue** distributes work. One job, one worker. A task is handed to exactly one consumer, runs once, and is
  marked done — point to point.
- **The Bus** broadcasts signals. One event, many listeners. A fact is announced and every interested party hears it
  — one to many.
- **The Cache** serves reads. One value, read often. A hot answer is held close so a read does not pay the full cost
  twice — read through.

These are three classic messaging shapes, and EchoMQ owns all three over the same keyspace and the same Lua layer.
That is the whole point of the chapter: name the three surfaces, name the real function that opens each one, and
defer the deep mechanism to the pillar chapters.

## The worked example — the three surfaces, named

Each pillar is a real module surface in `echo/apps/echo_mq` (the Queue and the Bus) or `echo/apps/echo_cache` (the
Cache). The point here is orientation: which function is the door into each pillar, and what shape of delivery it
gives you.

### The Queue — distribute work (point to point)

A job is admitted with `EchoMQ.Jobs.enqueue/4`, claimed by a worker with `EchoMQ.Jobs.claim/3`, and the loop that
owns the claim rhythm is `EchoMQ.Consumer`. One job is handed to exactly one consumer.

```elixir
# echo/apps/echo_mq — EchoMQ.Jobs.enqueue/4
# Admit a job: one atomic step on the server. The Elixir verb passes the
# job key and the pending set as the two declared KEYS; the Lua does the rest.
def enqueue(conn, queue, job_id, payload) when is_binary(job_id) and is_binary(payload) do
  keys = [Keyspace.job_key(queue, job_id), Keyspace.queue_key(queue, "pending")]

  case Connector.eval(conn, @enqueue, keys, [job_id, payload]) do
    {:ok, 1} -> {:ok, :enqueued}   # admitted
    {:ok, 0} -> {:ok, :duplicate}  # already present — idempotent
    {:error, {:server, "EMQKIND" <> _}} -> {:error, :kind}  # not a JOB-namespaced id
    other -> other
  end
end
```

The admission rule lives in one named Lua handle — **`EchoMQ.Jobs @enqueue`** — run on the server so kind policy,
duplicate refusal, the row write, and the pending insertion happen atomically:

```lua
-- EchoMQ.Jobs @enqueue — the atomic admission script (KEYS[1]=job key, KEYS[2]=pending set)
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then            -- the branded-id gate: ids are JOB-namespaced
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
if redis.call('EXISTS', KEYS[1]) == 1 then            -- already admitted? refuse, idempotently
  return 0
end
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])  -- write the row
redis.call('ZADD', KEYS[2], 0, ARGV[1])               -- same-score set: byte order is mint order
return 1
```

### The Bus — broadcast signals (one to many)

A listener subscribes with `EchoMQ.Events.subscribe/2`; a lifecycle fact is announced with
`EchoMQ.Events.publish/5` on the per-queue channel `EchoMQ.Events.channel/1` (`emq:{q}:events`). One event reaches
every subscribed listener.

```elixir
# echo/apps/echo_mq — EchoMQ.Events.publish/5
# Announce a lifecycle fact to every listener on the per-queue channel.
def publish(conn, queue, event, job_id, extra \\ []) do
  _ = Keyspace.job_key(queue, job_id)        # gate the id at the key builder before the wire
  payload = encode_event(event, job_id, extra)

  case Connector.command(conn, ["PUBLISH", channel(queue), payload]) do
    {:ok, _n} -> :ok                          # delivered to live subscribers (fire-and-forget)
    other -> other
  end
end
```

The Bus has two faces. The first is **pub/sub** — the live broadcast above, real in `echo/apps/echo_mq` today. The
second is a **retained, replayable event log**: append order is mint order, a reader can start at an offset and read
forward, and a consumer group recovers what it missed.
[RECONCILE: the retained, replayable event log — append == mint order, read at offset, consumer-group recovery,
time-travel by mint instant — is DESIGN CANON, not yet on disk. Grounded in `emq.roadmap.md` §"EchoMQ 3.x — the
stream tier" (`EchoMQ.Stream`, the writer law = emq3.2; retention windows `MAXLEN`/`MINID` = emq3.4; time-travel =
emq3.6) + `emq3.specs.md` (S1 writer · S2 readers · S3 memory). Pub/sub via `EchoMQ.Events` is real; the durable
stream is not. The HTML states the event log as shipped; this marker is the iteration-2 worklist entry.]

### The Cache — serve reads (read through)

A hot value is read with `EchoCache.Table.fetch/3`: an L1 hit returns in the caller's own process, and a miss falls
through to a single fill that writes both layers.

```elixir
# echo/apps/echo_cache — EchoCache.Table.fetch/3
# Read through the cache: an L1 (ETS) hit never enters the owner process;
# a miss is a single-flight fill through the owner (L2 Valkey, then the loader).
def fetch(name, id, timeout \\ 10_000) do
  case EchoCache.spec(name) do
    :error -> {:error, :no_such_cache}
    {:ok, spec} ->
      with :ok <- gate(spec.kind, id) do          # wrong-namespace id refused at the door
        now = System.monotonic_time(:millisecond)

        case :ets.lookup(name, id) do
          [{^id, value, expires_at, _version}] when now < expires_at ->
            {:ok, value, :hit}                      # L1 hit, in the caller's process
          _ ->
            GenServer.call(name, {:fill, id}, timeout)  # single-flight fill: :l2 or :fill
        end
      end
  end
end
```

## The triangle — the pattern, the pillar, the shape

This is an orientation dive, so the pairing is the three messaging shapes against the three EchoMQ surfaces, and the
redis-patterns chapter that teaches each shape applied.

| The pattern (redis-patterns) | The shape | The EchoMQ pillar | The door function |
|---|---|---|---|
| Reliable queues (work distribution) | point to point — one job, one worker | The Queue | `EchoMQ.Jobs.enqueue/4` · `claim/3` |
| Streams & events (broadcast + log) | one to many — one event, many listeners | The Bus | `EchoMQ.Events.subscribe/2` · `publish/5` |
| Caching (read path) | read through — one value, read often | The Cache | `EchoCache.Table.fetch/3` |

**The bridge.** The Redis pattern catalog teaches each shape on its own; EchoMQ applies all three over one owned
keyspace and one Lua layer, so the three pillars share a substrate instead of being three separate systems. The
redis-patterns course is the near side of every door; this course is the far side.

## Recap

EchoMQ is one system with three surfaces. The Queue distributes work point to point (`EchoMQ.Jobs.enqueue/4`,
`claim/3`, `EchoMQ.Consumer`). The Bus broadcasts signals one to many (`EchoMQ.Events.subscribe/2`, `publish/5`) and
keeps a replayable log [RECONCILE: the replayable log is canon — `emq.roadmap.md` §"EchoMQ 3.x — the stream tier" +
`emq3.specs.md`; pub/sub is real]. The Cache serves reads through two layers (`EchoCache.Table.fetch/3`). Each is
named here and taught in depth in its own pillar chapter; the protocol below the line — the shared keyspace and Lua —
is the next dive.

## References

### Sources

- Redis — *Documentation* (`https://redis.io/docs/`) — the data structures the three pillars are built from.
- Redis — *EVALSHA* (`https://redis.io/commands/evalsha/`) — the load-once, run-by-SHA dispatch each pillar's atomic
  script runs through.
- Valkey — *Documentation* (`https://valkey.io/docs/`) — the BSD-licensed, foundation-governed store EchoMQ is
  backed by — the substrate of record.
- DragonflyDB — *Server flags* (`https://www.dragonflydb.io/docs/managing-dragonfly/flags`) — the thread-per-shard
  engine the declared-key, per-queue-hashtag keyspace is built for.

### Related in this course

- `/echomq/overview` — the Overview landing (the chapter frame; the pager prev).
- `/echomq/overview/the-protocol-below-the-line` — the next dive: why the three pillars interoperate.
- `/echomq/protocol` — The Protocol: the keyspace and the Lua the three pillars share.
- `/redis-patterns/overview/patterns-become-protocol` — the near side of the door: a pattern becomes a protocol.
- `/bcs` — The Branded Component System: the architecture EchoMQ is the bus, the broadcast, and the near-cache of.
