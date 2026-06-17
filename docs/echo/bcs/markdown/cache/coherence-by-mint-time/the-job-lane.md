# B4.2.3 · The Job Lane

> Dive 3 of B4.2 · route `/bcs/cache/coherence-by-mint-time/the-job-lane` · teaches `content/bcs4.2.md`
> (What: the job lane, the price) · reads gates F5–F6 of `bcs_rung_4_2_check.out`.

The lane that survives — at-least-once delivery, exactly-once effect.

The same twenty-nine bytes enqueued on EchoMQ's fair lanes, applied by a consumer running
`Table.coherence_handler/1`. The drill is the bus's own crash choreography from Part III, now carrying
coherence — a consumer dies holding the job, the reaper returns it, a second consumer applies it — and the
record closes on the chapter's one-row summary: `broadcast median 72 us fire-and-forget, job lane median 148 us
at-least-once -- the guarantee costs 2.1 times the latency`.

## §1 The transcript

The job-lane half of the record, verbatim — the derive lines, the staged consumer kill, F5, and F6 (source:
`content/echo_data/runtimes/elixir/bcs_rung_4_2_check.out`; the record opens with F1–F4 — the hub holds it
whole):

```
…
derive (job lane): a consumer crash after claim strands the coherence job on a lease; the reaper returns it, a second consumer applies it with token 2, and reapplication is harmless because newer-wins is a comparison -- expect attempts 2 and exactly one effective drop

01:36:22.839 [error] GenServer #PID<0.203.0> terminating
** (stop) killed
Last message: {:EXIT, #PID<0.202.0>, :killed}
State: %{backoff: 100, buf: "", client_name: nil, connect_timeout: 3000, counters: {:write_concurrency, #Reference<0.595650664.2344747009.170073>}, database: 0, hb_ref: #Reference<0.595650664.2344615937.170091>, heartbeat_ms: 30000, host: {127, 0, 0, 1}, label: :emq, max_pending: 10000, overloads: 0, password: nil, pending: {[], []}, pending_n: 0, port: 6390, protocol: :auto, protocol_live: 3, push_to: nil, pushes: 0, sock: #Port<0.13>}
F5 job lane ok -- the lane that survives: the first consumer died holding the job, the reaper returned it, the healer applied it -- :qc dropped its stale row and now serves px=107.00 from the shared L2 -- the completed job left no row to browse, and replaying the same version answers stale: at-least-once delivery, exactly-once effect
derive (price): the broadcast lane is one wire hop; the job lane pays three to five hops -- enqueue, wake, claim, complete -- so a parked consumer should land its median between 80 us and 2 ms, the same order as the bus's committed 0.3 ms end-to-end median, carrying the guarantee the push cannot
F6 price ok -- the two lanes on one row: broadcast median 72 us fire-and-forget, job lane median 148 us at-least-once -- the guarantee costs 2.1 times the latency, and gates F4 and F5 are the reason a surface pays it
PASS 6/6
```

The mid-record `[error] GenServer … terminating` block is the staged consumer kill of the F5 drill — part of
the frozen record, not noise around it.

## §2 The crash choreography

The drill stages the failure the lane exists for: `the first consumer died holding the job, the reaper returned
it, the healer applied it -- :qc dropped its stale row and now serves px=107.00 from the shared L2 -- the
completed job left no row to browse, and replaying the same version answers stale: at-least-once delivery,
exactly-once effect`. Every part is Part III machinery doing its committed work — the lease that strands the
job, the reaper that returns it, the second claim with token 2 — and redelivery is harmless because application
is a comparison; the provenance machinery of 3.5 is not even needed here — the version *is* the provenance.

The job-lane consumer lives in the application's tree. The table wires its own broadcast subscription — cheap,
self-contained, supervision-as-resubscription — but an EchoMQ consumer is a real supervised worker with a lease
and a lane, and hiding one inside a cache table would falsify the supervision tree. `coherence_handler/1` makes
the wiring one line; the tree stays true (source: `content/bcs4.2.md`, How):

```elixir
{:ok, _} =
  EchoMQ.Consumer.start_link(
    queue: Coherence.queue("quotes"),
    connector: [port: 6390],
    handler: Table.coherence_handler(:quotes)
  )
```

## §3 The price, on one row

`broadcast median 72 us fire-and-forget, job lane median 148 us at-least-once -- the guarantee costs 2.1 times
the latency`. The derive line prices the shape before the stopwatch runs: the broadcast lane is one wire hop;
the job lane pays three to five hops — enqueue, wake, claim, complete — the same order as the bus's committed
0.3 ms end-to-end median, carrying the guarantee the push cannot. Both lanes are sub-millisecond on this wire;
the real difference is gates F4 and F5, not the microseconds — the lane a surface declares follows from what a
stale read costs, and the declaration in the directory records the choice. Declare `:job` when at-least-once is
a requirement — and note what the record shows: the guarantee's latency price on this wire is 76 microseconds,
so the job lane is not the slow lane, it is the accountable one.

Boundaries, stated honestly: the job lane inherits the bus's contract — at-least-once with redelivery, volatile
by D-2 — a bus restart loses queued coherence jobs along with everything else, and the TTL is again the floor
under the loss. And the latencies are this container's: one core, loopback, both lanes far below any network's
floor — the ratio and the ordering travel, the microseconds do not. The applier is the owner — for now: pushes
and jobs apply inline in the table's process, which is correct and measured fast; **B4.3 · The Single Writer
and the Ring** moves application onto the ring for batching and backpressure without touching the semantics
gated here.

## References

Sources:

- Valkey — Pub/Sub — https://valkey.io/topics/pubsub/ (the contract the broadcast side of the priced pair
  inherits)
- Valkey — Client-side caching — https://valkey.io/topics/client-side-caching/ (the comparison set's
  deletion-shaped coherence the lane outbids: no version, no order, no guarantee named per surface)
- Lamport, L. — Time, Clocks, and the Ordering of Events in a Distributed System —
  https://dl.acm.org/doi/10.1145/359545.359563 (why reapplication is harmless: the order is total and lives in
  the name)

Related:

- /bcs/cache/coherence-by-mint-time — B4.2 · the module hub; the full rung in context
- /bcs/cache — B4 · EchoCache, the chapter landing
- /bcs/bus/state-machine — B3.3 · The State Machine in Lua, the lease, the reaper, and the fencing token under
  this drill
- /bcs/bus/jobs-are-entities — B3.2 · Jobs Are Entities, the enqueue and the idempotent row
- /bcs/bus — B3 · The Bus, Part III's arc
- /echomq — EchoMQ, the protocol in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/cache/coherence-by-mint-time/the-broadcast-lane` · next
`/bcs/cache/coherence-by-mint-time` (back to the hub).
