# The two lanes

> Route: `/echomq/cache/coherence/the-two-lanes` · Module 03, dive 02.
> Grounded in `EchoStore.Coherence` (+ `EchoStore.Ring`, `EchoStore.Journal`) — `echo/apps/echo_store/`. All real
> code. No Lua (the conditional drop is the next dive).

## One payload, two carriers

The 29-byte message from the previous dive can ride two different lanes, and the table chooses by declaring its
`coherence` mode. The choice is not about throughput — both are cheap — it is about **what a lost message costs**.

```elixir
# EchoStore.Coherence — the two lanes and their addresses
# Same 29-byte payload(id, version); two carriers; the table picks by the
# cost of a missed invalidation.

def channel(table), do: "ecc:{" <> table <> "}:coh"   # the broadcast address
def queue(table),   do: "ecc.coh." <> table           # the job-lane address

# Broadcast: fire-and-forget, one wire hop, returns the receiver count.
def broadcast(conn, table, id, version) do
  Connector.command(conn, ["PUBLISH", channel(table), payload(id, version)])
end

# Job lane: at-least-once over EchoMQ's fair lanes. The lane mints a JOB id
# and carries the same coherence payload as the job's body.
def enqueue(conn, table, group, id, version) do
  Lanes.enqueue(conn, queue(table), group, BrandedId.generate!("JOB"), payload(id, version))
end
```

Note the addresses share the cache's `{table}` hashtag, so the broadcast channel and the L2 keys it invalidates land
on the same Valkey Cluster slot. The job-lane queue is named `ecc.coh.<table>` — its own queue under EchoMQ, so a
coherence job is just a job, claimed and retried like any other.

## The broadcast lane — at-most-once, for cheap staleness

`broadcast/4` is a single `PUBLISH`. There is no acknowledgement and no retry: if a subscriber is briefly
disconnected when the message goes out, it never sees it — and that is acceptable precisely because **a lost
broadcast costs one TTL of staleness**. The row this node missed invalidating will expire on its jittered clock and
be re-filled with the current value. For a board, a leaderboard, a presence count — read-mostly data where a second
of staleness is invisible — that is the right trade.

The applier on the receiving side is `EchoStore.Ring`: a bounded ring with **one producer and one applier**, the
Disruptor's shape translated to the BEAM. Two `:atomics` carry the head/tail sequences, an ETS table holds the
preallocated slots reused by index, and **occupancy = tail − head** is the backpressure gauge anyone can read at any
time. Wakes are **edge-triggered** — the producer sends one `:wake` only on the empty→non-empty transition, and the
applier re-checks the tail before parking — so a busy burst costs one message however many items flow through it.

```elixir
# EchoStore.Ring — publish/2 (single producer)
# When the ring is full the publish is refused and counted — never blocked,
# never overwritten. The broadcast lane is at-most-once by its substrate's
# contract, and a counted drop under storm keeps that contract honest where
# silent overwriting or unbounded queueing would trade it for a worse one.
def publish(name, item) do
  rt = :persistent_term.get({__MODULE__, name})
  tail = :atomics.get(rt.seq, 1)
  head = :atomics.get(rt.seq, 2)

  if tail - head >= rt.capacity do
    :counters.add(rt.counters, @counters[:dropped], 1)
    :dropped                       # full: refuse and count, do not block
  else
    next = tail + 1
    :ets.insert(rt.slots, {rem(next, rt.capacity), item})
    :atomics.put(rt.seq, 1, next)
    :counters.add(rt.counters, @counters[:published], 1)
    # one wake only on the empty -> non-empty edge
    if tail == :atomics.get(rt.seq, 2) do
      send(rt.applier, :wake)
      :counters.add(rt.counters, @counters[:wakes], 1)
    end
    :ok
  end
end
```

A full ring drops and counts; it does not block the table's owner and it does not overwrite a slot another item is
using. **Surfaces that cannot accept a drop do not ride this lane** — they ride the job lane, which does not pass
through the ring at all.

## The job lane — at-least-once, for staleness that costs money

`enqueue/5` puts the same payload on `ecc.coh.<table>` over EchoMQ's fair lanes. Now the message is a **job**:
admitted once (the bus deduplicates the job id), claimed by a worker, retried on failure, surviving a crash. This is
the lane for data where **a stale read costs money** — a wallet balance, an inventory count, a settlement — where
"the row will expire eventually" is not good enough.

The memory behind the job lane is `EchoStore.Journal`, a transactional outbox standing *beside* the bus (the bus
stays volatile by decision D-2). Its `applied` table records the last version applied per name and **survives the
node, the cache, and the bus** — so even a coherence intent replayed after a crash answers correctly. The deep
durability of that lane is the subject of the next dive and the `/echo-persistence` floor.

## Choosing the lane

The table's declared spec carries one field:

```
coherence: :none | :broadcast | :tracking
```

- `:none` — no coherence lane; the cache relies on TTL expiry alone (acceptable for derived, short-lived data).
- `:broadcast` — the PUBLISH + Ring lane above: at-most-once, cheap, for read-mostly data.
- `:tracking` — RESP3 server-assisted client tracking, where Valkey itself pushes the invalidation (named here; the
  store opts into the server-push instead of carrying its own message).

## Pattern & implementation

- **The pattern (pub/sub invalidation vs durable queue):** an invalidation can be a fire-and-forget signal or a
  guaranteed-delivery job. You pick per data class by what a missed message costs.
- **The implementation (`EchoStore.Coherence` + `Ring` + `Journal`):** `broadcast/4` → `PUBLISH` → `Ring`
  (at-most-once, refuse-and-count under storm); `enqueue/5` → `Lanes.enqueue` → `Journal` (at-least-once,
  crash-surviving). One `payload/2` feeds both; the `coherence:` field selects.

The cheap lane and the durable lane carry the identical 29-byte truth; what differs is the promise. The next dive is
what the receiver does when the message lands: the one conditional drop that makes either lane safe to replay.

## References

- Valkey — PUBLISH — the one wire hop of the broadcast lane.
- Valkey — Cluster specification — the `{table}` hashtag co-locating the coherence channel with the cache's keys.
- LMAX — the Disruptor — the single-producer/single-consumer ring `EchoStore.Ring` translates to the BEAM.
- King — Announcing Snowflake — the version both lanes carry.
- Related in this course: `/echomq/cache/coherence` (the hub), `/echomq/cache/coherence/newer-wins-the-conditional-drop`,
  `/echomq/queue` (the fair lanes the job lane rides), `/echo-persistence`.
