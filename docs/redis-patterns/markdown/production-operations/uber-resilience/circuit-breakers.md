# Circuit breakers

> R8.05.2 · Uber: resilience & staggered sharding — dive 2 · route `/redis-patterns/production-operations/uber-resilience/circuit-breakers`

When a Redis node is down, every get and set routed to it pays a latency penalty before it fails — and at
millions of requests per second that penalty compounds into a system-wide slowdown. Uber added a **sliding-window
circuit breaker** per node: count errors per node in each time bucket, sum over the window, short-circuit a
fraction of requests once the threshold is hit, and trip entirely until the window passes. The BCS echo is the
connector's `max_pending` → `:overloaded` **backpressure** — the in-process cousin, the same goal reached by a
different mechanism.

Grounding: the Uber case study (*How Uber Uses Integrated Redis Cache*) and the canonical Circuit Breaker pattern
for the technique; the as-built `echo/apps/echo_wire/lib/echo_mq/connector.ex` for the applied half. Valkey is
the BCS engine; Uber's Redis is the case study.

## §1 · The cost of calling a dead node

A cache in front of a database trades a fast in-memory hit for a slow fall-through on a miss. That trade is good
while the cache is healthy. It inverts when a node is *down*: a request routed to a dead node does not return
quickly with a miss — it waits for a connection or a read to **time out**, then fails. Every such request pays
the full timeout before it can fall through to the database.

At millions of requests per second, this is the dangerous case. The slow timeouts pile up, threads and
connections stay blocked waiting on a node that will not answer, and the latency penalty for one bad node bleeds
into the whole service. The naive behaviour — keep trying the node, keep timing out — is precisely what amplifies
a single node's failure into a system-wide latency spike.

## §2 · The sliding-window circuit breaker

The circuit breaker breaks that loop. It is the canonical resilience pattern: stop calling a dependency that is
known to be failing, and fail fast instead of waiting for each call to time out. Uber's is a **sliding-window**
breaker, per node:

1. **Count errors per node, per time bucket.** Each node has a window divided into buckets; failed calls in the
   current bucket increment its count.
2. **Sum over the window's width.** The breaker's view of a node's health is the sum of the buckets in the
   window — recent errors weigh, old errors age out as the window slides forward.
3. **Short-circuit a fraction once the threshold is hit.** When the error count crosses the threshold, the
   breaker **short-circuits a fraction of requests** to that node: those requests skip the doomed call and go
   straight to the fallback, paying no timeout.
4. **Trip until the window passes.** If errors keep accumulating, the breaker **trips** fully — no requests reach
   the node at all — and stays tripped until the window passes and the counts age out, at which point traffic is
   allowed back to test whether the node has recovered.

The sliding window is the key refinement over a naive counter. A flat lifetime error count would trip on old,
recovered failures; the old buckets age out of the sum, so the windowed count tracks how the node is doing *now*.
Short-circuiting a
*fraction* before tripping fully is the second refinement — it sheds the worst of the load while still probing
whether the node is coming back, rather than going hard open and blind.

## §3 · The BCS echo — backpressure, not a circuit breaker

The EchoMQ connector reaches the same *goal* — do not pile work onto a struggling path — but by a different
mechanism, and the difference is the whole point of this section.

The connector bounds its **in-flight depth**. Every pipeline waiting for a reply sits in a FIFO; the connector
caps how many can be outstanding at once with `max_pending` (default `10_000`). When the cap is reached, the next
call is refused immediately with `{:error, :overloaded}` instead of being queued without bound:

```elixir
# echo/apps/echo_wire/lib/echo_mq/connector.ex — the bounded in-flight depth
def handle_call({:pipeline, _}, _from, %{pending_n: n, max_pending: max} = s) when n >= max do
  emit([:emq, :connector, :overload], %{pending: n}, %{label: s.label})
  {:reply, {:error, :overloaded}, %{s | overloads: s.overloads + 1}}
end
```

This is **backpressure**, a bounded queue — and it is **not a circuit breaker**. The distinction is sharp and
worth keeping:

- A **circuit breaker** watches a dependency's *error rate* over a sliding window and stops calling it once the
  errors cross a threshold. Its trigger is *failures over time*.
- **`max_pending` backpressure** watches the connector's *in-flight depth* and refuses new work once too many
  requests are outstanding. Its trigger is *concurrency right now* — it does not count errors or track a window.

They share a goal — refuse to amplify a struggling path — but a depth limit and an error-rate trip are different
instruments. The connector has two more analogues that, together with the bound, cover the circuit breaker's
*goals* without being one: **fail-fast** errors (a call against a dead socket returns `{:error, :disconnected}`
at once rather than hanging) and **supervised reconnect** with capped jittered backoff (the connector backs off
between reconnect attempts rather than spinning on a node that is down — the next dive). Same goals — fail fast,
do not hammer a sick dependency, recover — different mechanisms.

The worked consumer is **codemojex**. A burst of guesses during a popular round flows through one
`EchoMQ.Connector`; if Valkey slows and replies back up past `max_pending`, the next guess gets a fast
`:overloaded` rather than swelling an unbounded queue that would make the slowdown worse. The bound sheds load at
the edge so a saturated wire degrades instead of collapsing.

### Notes on Valkey

A circuit breaker is a client-side pattern — Valkey does not implement one for you; the connector's bounded
in-flight depth and fail-fast errors are the client's responsibility, layered over the engine. Valkey's own
guidance on the latency a slow or unreachable instance imposes — the cost the circuit breaker and the bound exist
to cap — is at [valkey.io/topics/latency](https://valkey.io/topics/latency/).

## Recap — same goal, different instrument

Calling a dead node is expensive: each request pays a timeout, and at scale those timeouts amplify one node's
failure into a service-wide spike. Uber's sliding-window circuit breaker counts errors per node, short-circuits a
fraction once a threshold is hit, and trips until the window passes — failing fast against a known-bad
dependency. The EchoMQ connector reaches the same goal with a different instrument: `max_pending` backpressure
caps in-flight depth and answers `:overloaded`, fail-fast returns `:disconnected` against a dead socket, and
supervised backoff keeps it from spinning on a down node. The next dive follows the request that gets
short-circuited — graceful degradation, falling through to the durable store.

## References

### Sources

- [Uber Engineering — How Uber Serves Over 40 Million Reads Per Second Using an Integrated Cache](https://www.uber.com/blog/how-uber-serves-over-40-million-reads-per-second-using-an-integrated-cache/)
- [ByteByteGo — How Uber Uses Integrated Redis Cache to Serve 40M Reads/Second](https://blog.bytebytego.com/p/how-uber-uses-integrated-redis-cache)
  — the sliding-window circuit breaker: per-node error counts in time buckets, short-circuit a fraction, trip
  until the window passes.
- [Microsoft Learn — Circuit Breaker pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker)
  — the canonical resilience pattern, its closed/open/half-open states, and the fail-fast rationale.
- [Valkey — Diagnosing latency issues](https://valkey.io/topics/latency/) — the latency a slow or unreachable
  instance imposes — the cost the breaker and the in-flight bound exist to cap.

### Related in this course

- [R8.05 · Uber: resilience & staggered sharding](/redis-patterns/production-operations/uber-resilience) — the module hub.
- [R8.05.1 · Staggered sharding](/redis-patterns/production-operations/uber-resilience/staggered-sharding) — the previous dive: spread the failure.
- [R8.05.3 · Graceful degradation](/redis-patterns/production-operations/uber-resilience/graceful-degradation) — the next dive: fall through, stay available.
- [R8 · Production & Operations](/redis-patterns/production-operations) — the chapter.
- [/echomq/queue](/echomq/queue) — the Queue pillar: the connector and its bounded in-flight depth.
