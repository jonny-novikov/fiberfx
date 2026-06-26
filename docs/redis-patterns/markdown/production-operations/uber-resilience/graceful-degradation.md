# Graceful degradation

> R8.05.3 · Uber: resilience & staggered sharding — dive 3 · route `/redis-patterns/production-operations/uber-resilience/graceful-degradation`

A cache exists to be faster than the store behind it. The resilience question is what happens when the cache is
*not there* — a miss, a short-circuited request, a node down, a whole region in trouble. Uber's answer is
**graceful degradation**: a miss or short-circuit **falls through to Docstore**, slower but served. The measured
effect — **P75 latency down about 75%, P99.9 down over 67%**, and a use case at over 6M reads/second that **failed
over to a remote region**. The BCS echo is the connector's **capped-jittered-backoff reconnect** and
**fail-not-replay**, with `-READONLY` taught as the Valkey failover pattern.

Grounding: the Uber case study (*How Uber Uses Integrated Redis Cache*) for the degradation path and the results;
the as-built `echo/apps/echo_wire/lib/echo_mq/connector.ex` for the applied half. This dive frames failover
through Uber's lens and cross-links R8.02, which taught the READONLY-reconnect failover and pool sizing in full.
Valkey is the BCS engine; Uber's Redis and Docstore are the case study.

## §1 · Degrade, do not fail

Graceful degradation is the discipline of having a worse-but-working answer ready for when the best answer is
unavailable. For the integrated cache the best answer is a Redis hit; the worse-but-working answer is a Docstore
read. A request that misses the cache, or that the circuit breaker short-circuits, or that hits a node which is
down, does not error back to the caller — it **falls through to Docstore**. The read is slower than a cache hit
because it pays the full database cost, but it returns a correct value. The cache is an optimisation in front of
the truth; when the optimisation is gone, the truth is still reachable.

This is why the circuit breaker (the previous dive) is safe to be aggressive. Short-circuiting a request only
helps if there is somewhere for that request to go; the fall-through to Docstore is that somewhere. Tripping the
breaker does not drop the read — it reroutes it to the durable path. The two techniques compose: the breaker
rules out Redis, and graceful degradation routes the read to Docstore.

## §2 · The results, and remote-region failover

The combined effect of the integrated cache with its resilience layer was measured. Latency fell sharply at the
tail as well as the median: **P75 latency down about 75%, P99.9 latency down over 67%**, with latency spikes
limited rather than allowed to run away. The tail matters most here — P99.9 is where the dead-node timeouts and
the hot-shard pile-ups would have shown up, and that is exactly where the circuit breaker and the staggered
sharding hold the line.

Degradation also scales up a level, from a node to a **region**. A documented use case running at **over 6
million reads per second with a 99% cache hit rate** had its primary region run into trouble and **failed over
successfully to a remote region**. The cache being unavailable in one region degraded to the remote path rather
than taking the read down — the same fall-through principle, applied to a whole region's worth of cache instead
of a single node. The title figure for the whole integrated cache is **40 million reads per second**; the
resilience story is what let that number stay up under trouble.

## §3 · The BCS echo — recover by reconnecting, fail honestly

The EchoMQ connector's graceful behaviour under a lost dependency is two properties: it fails the in-flight work
honestly, and it recovers by reconnecting with backoff. Both are in the as-built connector.

**Fail-not-replay.** When the socket to Valkey drops, every in-flight caller is failed `:disconnected` and the
in-flight FIFO is cleared. The connector does not silently retry those calls, because it cannot know which are
idempotent — replaying a non-idempotent command after a partial failure could double-apply it. A fast, honest
error is the safe degradation: the caller is told at once that the call did not complete, and the retry decision
is left to the calling code.

```elixir
# echo/apps/echo_wire/lib/echo_mq/connector.ex — in-flight callers failed :disconnected on socket loss, never replayed
Enum.each(:queue.to_list(s.pending), fn
  {:internal, _, _, _, _} -> :ok
  {from, _, _, _, _} -> GenServer.reply(from, {:error, :disconnected})
end)
```

**Capped jittered backoff reconnect.** After the socket drops, the connector schedules a reconnect, and each
failed attempt backs off — doubling the delay up to a cap, with jitter so a fleet of connectors does not retry in
lockstep:

```elixir
# echo/apps/echo_wire/lib/echo_mq/connector.ex — @backoff_min 100, @backoff_max 2_000
defp schedule(%{sock: nil} = s) do
  jitter = :rand.uniform(div(s.backoff, 2) + 1)
  Process.send_after(self(), :reconnect, s.backoff + jitter)
  %{s | backoff: min(s.backoff * 2, s.backoff_max)}
end
```

Backoff is the recovery analogue of degradation: rather than spin on a node that is down (which would amplify the
failure, the very thing the circuit breaker prevents), the connector waits a little longer between attempts, up to
the `@backoff_max` of 2_000 ms, and re-fences on every reconnect. Its `stats/1` reports `status: :reconnecting`
and a `reconnects` count, so the recovery is observable.

The bridge holds the parallel:

- **The pattern** — when the fast path is gone, serve the slow path (fall through to the durable store) and
  recover the fast path without hammering it (back off, retry, re-test).
- **Its EchoMQ application** — on socket loss the connector fails in-flight callers `:disconnected` (a fast honest
  error, never a silent replay) and reconnects with capped jittered backoff (`@backoff_min 100` → `@backoff_max
  2_000`), re-fencing on every reconnect.

There is one guard. The connector has **no special `-READONLY` handler**. A Valkey primary failover surfaces to a
client as a `-READONLY` error from a not-yet-promoted replica, but the connector does not branch on that string —
its recovery to a topology change is the general one: the socket drops, the supervised connector reconnects. So
`-READONLY` is taught here as the Valkey failover *signal* the connector recovers from by reconnecting, not as an
echo surface. R8.02 (`persistence-pooling-failover`) taught the READONLY-reconnect failover and pool sizing in
full; this dive frames the same recovery through Uber's resilience lens rather than duplicating it.

The durability floor sits underneath all of this: a cache or a queue serves from memory, and when the question is
*where does the value survive a crash*, that is the durable substrate's job — `/echo-persistence` is the dial
from holding nothing to committing every record off-box.

### Notes on Valkey

When a Valkey primary fails over, a client that reconnects to a replica before it is promoted sees `-READONLY
You can't write against a read only replica`; once the replica is promoted the writes succeed. The owned wire has
no `-READONLY`-specific branch — it recovers from the socket drop a failover causes by reconnecting with backoff,
re-fencing each time. Valkey's guidance on failover and the latency around it is at
[valkey.io/topics/latency](https://valkey.io/topics/latency/).

## Recap — a worse answer beats no answer

Graceful degradation is the discipline of always having a worse-but-working path. Uber's integrated cache falls
through to Docstore on a miss or short-circuit, which is what makes the aggressive circuit breaker safe and what
let a region failover keep serving — P75 down ~75%, P99.9 down over 67%, 40M reads/second held up under trouble.
The EchoMQ connector reaches the same posture by failing in-flight work honestly (`:disconnected`, never
replayed) and recovering with capped jittered backoff, treating a `-READONLY` failover as a socket drop to
reconnect through. With this, the Uber module closes; return to the Production & Operations chapter to continue.

## References

### Sources

- [Uber Engineering — How Uber Serves Over 40 Million Reads Per Second Using an Integrated Cache](https://www.uber.com/blog/how-uber-serves-over-40-million-reads-per-second-using-an-integrated-cache/)
- [ByteByteGo — How Uber Uses Integrated Redis Cache to Serve 40M Reads/Second](https://blog.bytebytego.com/p/how-uber-uses-integrated-redis-cache)
  — graceful degradation falling through to Docstore, the P75 −75% / P99.9 −67% latency results, and the
  remote-region failover at over 6M reads/second.
- [Valkey — Diagnosing latency issues](https://valkey.io/topics/latency/) — failover and reconnect behaviour, and
  the `-READONLY` signal a client recovers from by reconnecting.
- [Microsoft Learn — Circuit Breaker pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker)
  — the half-open probe that re-tests a recovering dependency, the recovery analogue of backoff-and-retry.

### Related in this course

- [R8.05 · Uber: resilience & staggered sharding](/redis-patterns/production-operations/uber-resilience) — the module hub.
- [R8.05.2 · Circuit breakers](/redis-patterns/production-operations/uber-resilience/circuit-breakers) — the previous dive: stop hammering a sick node.
- [R8.02 · Persistence, pooling & failover](/redis-patterns/production-operations/persistence-pooling-failover) — the READONLY-reconnect failover and pool sizing in full.
- [R8 · Production & Operations](/redis-patterns/production-operations) — the chapter.
- [/echo-persistence](/echo-persistence) — the durability floor beneath the volatile tiers.
- [/echomq/queue](/echomq/queue) — the Queue pillar: the connector's reconnect and fail-not-replay.
