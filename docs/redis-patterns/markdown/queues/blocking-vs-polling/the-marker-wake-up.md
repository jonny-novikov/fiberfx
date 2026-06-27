# The wake-up doorbell — a signal, not a queue

> Route: `/redis-patterns/queues/blocking-vs-polling/the-marker-wake-up` · Dive R3.05.3 · Module R3.05
> blocking-vs-polling · Chapter R3 Reliable Queues.
> Grounding: EchoMQ's wake handshake. The consumer parks on `emq:{queue}:wake` (a capped LIST) with
> `BLPOP emq:{queue}:wake <beat>` in `EchoMQ.Consumer.park/1`. The producer side, when admitting/promoting/reclaiming
> a job, runs `LPUSH emq:{queue}:wake '1'` then `LTRIM emq:{queue}:wake 0 63` (verified in `jobs.ex`, `lanes.ex`,
> `stalled.ex`), which returns the parked `BLPOP`. For a pool, one `EchoMQ.Metronome` holds the single block. All real
> in `echo/apps/echo_mq`. The worked consumer is **codemojex** (`echo/apps/codemojex`).

EchoMQ parks on a dedicated **wake key**, not on the work list. The wake key is a doorbell: the producer rings it when
a job becomes serviceable, and the ring returns the parked consumer, which then drains the ring on its command lane.
Decoupling the signal from the work means one wake fires no matter which lane the new work landed on.

## The park

The consumer's loop is reap → promote → drain → park. The park is a blocking pop on the wake key, with the beat as the
timeout:

```elixir
# EchoMQ.Consumer.park/1 — park on the wake key for one beat (real, Elixir)
defp park(s) do
  secs = :erlang.float_to_binary(s.beat_ms / 1000, decimals: 3)
  wake = Keyspace.queue_key(s.queue, "wake")          # emq:{queue}:wake
  _ = Connector.command(s.conn, ["BLPOP", wake, secs], s.beat_ms + 2_000)
  :ok
end
```

`BLPOP` returns when a wake token is pushed, or once when the beat elapses. The key is built by
`EchoMQ.Keyspace.queue_key(queue, "wake")` → `emq:{queue}:wake`, hash-tagged on the queue name so it shares the
queue's cluster slot.

## Ringing the doorbell

The producer rings the wake key from inside the admit Lua. Pushing a job onto the ring runs two calls — a push and a
trim:

```text
# inside the admit/promote/reclaim script (jobs.ex, lanes.ex, stalled.ex)
LPUSH emq:{queue}:wake '1'        -- ring: return any parked BLPOP
LTRIM emq:{queue}:wake 0 63       -- bound the list to 64 tokens
```

The `LPUSH` makes the parked `BLPOP` return; the `LTRIM` keeps the wake key from growing without bound when wakes
arrive faster than a consumer drains them. The same two calls appear wherever new work becomes serviceable — an
enqueue, a schedule promotion, a reclaimed stalled lease — so a parked consumer is returned by every path that adds
work, not only a fresh enqueue.

## A signal, not a queue

The wake key carries no payload — the token is a constant `'1'`. `BLPOP` removes one element, so one `LPUSH` returns
exactly one parked block. The actual job is never on the wake key; it is in the ring and the lanes, and the returned
consumer fetches it with `EchoMQ.Lanes.claim/3`. The wake key only answers "is there something to drain," and the
drain answers "what." That separation is why the bounded `LTRIM` is safe: a few extra tokens cost nothing, because no
token is a job.

## The beat is the fallback

A wake is the fast path, not the only path. When no wake arrives, `BLPOP` times out after one beat (`:beat_ms`,
default 1000) and the loop runs its reap/promote pump regardless — so a due delayed job or an expired lease is
recovered on the next beat even if nothing rang the doorbell. The wake makes a fresh enqueue prompt; the beat makes
the time-driven work reliable.

## One blocker for a pool — the metronome

A pool of standalone consumers would each hold their own `BLPOP` on the same wake key — a herd of blockers, one ring
returning one of them. EchoMQ's opt-in `EchoMQ.Metronome` collapses that to one: a single process holds the one
`BLPOP emq:{q}:wake <beat>` per queue and a registry of idle consumers, and on a wake it pokes each idle consumer to
run `EchoMQ.Lanes.claim/3` exactly once (one claim per idle consumer per wake). The herd is gone — one connection
blocks — and readiness is fanned out fairly over BEAM messages.

## The bridge

**The pattern:** ring a signal when work is added, and the parked worker returns the instant it rings; one ring
returns one parked worker.

**Its EchoMQ application:** the admit Lua runs `LPUSH emq:{queue}:wake '1'` / `LTRIM … 0 63`; the consumer's
`BLPOP emq:{queue}:wake <beat>` returns and drains. The beat is the fallback for time-driven work; one
`EchoMQ.Metronome` blocks once for a whole pool. **codemojex** rides this: `EchoMQ.Consumer` drains the guess queue
through `Lanes.claim`, returned the instant `Codemojex.Game` admits a guess `JOB`.

## On Valkey

`BLPOP` serves the first element of a list and, when the list is empty, parks the client until another client pushes
one; the engine returns exactly one of several clients blocked on the same key, in the order they parked
(valkey.io/commands/blpop). `LTRIM` keeps the list within a fixed length so the doorbell never grows unbounded
(valkey.io/commands/ltrim).

## References

### Sources

- [Valkey — BLPOP](https://valkey.io/commands/blpop/) — the park; returns one of several blocked clients per push, in park order.
- [Valkey — LPUSH](https://valkey.io/commands/lpush/) — ring the wake key so a parked `BLPOP` returns.
- [Valkey — LTRIM](https://valkey.io/commands/ltrim/) — cap the wake list so the doorbell never grows unbounded.
- [Redis — Documentation](https://redis.io/docs/) — lists, blocking commands, and the signal-key idiom in context.

### Related in this course

- [R3.05 · Blocking vs polling](/redis-patterns/queues/blocking-vs-polling) — the module hub.
- [R3.05.2 · Blocking pop](/redis-patterns/queues/blocking-vs-polling/blocking-pop) — the previous dive: the blocking primitive.
- [R3.01 · Processing list](/redis-patterns/queues/processing-list) — the wait/active states the returned consumer drains.
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter.
- [/echomq/queue](/echomq/queue) — the Queue pillar: the consumer loop, the wake key, and the metronome in depth.
