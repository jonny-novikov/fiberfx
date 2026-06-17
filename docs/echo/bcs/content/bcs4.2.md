# BCS · Chapter 4.2 — Coherence by Mint Time

<show-structure depth="2"/>

Chapter 4.1 bounded staleness by the clock; this chapter bounds it by the write. The coherence message of EchoCache is twenty-nine bytes — a cached name, a colon, and the writer's mint-time version — and everything else falls out of the order theorem: because a branded id's payload bytes sort in mint order, *newer wins* is a comparison of two names, with no coordinator, no lock, and no clock but the one already inside every id. Two lanes carry the same message and the committed record (`bcs_rung_4_2_check.out`, `PASS 6/6`) prices them side by side: the broadcast lane at a median of 72 microseconds, fire-and-forget by the substrate's own definition; the job lane at 148 microseconds, surviving a consumer crash with at-least-once delivery and exactly-once effect. One production module lands (`EchoCache.Coherence`), the table grows version-aware, and the connector gains the send-only push path the broadcast lane stands on — `the guarantee costs 2.1 times the latency, and gates F4 and F5 are the reason a surface pays it`.

## Why

A TTL is a promise about the past — *this row was true within the last N milliseconds* — and for quotes on a screen that promise is enough. For a position limit, a halted instrument, or a risk parameter, it is not: the desk needs *this row reflects the latest write*, and the latest write is exactly what the comparison set cannot say. Valkey's own tracking sends an unversioned *forget this key* [2]; Nebulex's multilevel topology synchronizes by deletion; neither message carries an order, so a late invalidation and a fresh write race, and the loser is whoever applied last. The fix the literature reached in 1978 is a total order constructed from timestamps [3], and this series has carried that order in every identity since Part I. The version of a cached row is a branded id; comparing two versions is comparing eleven payload bytes; and a coherence protocol whose conflicts resolve by comparison needs no coordination — which is the entire chapter, stated once.

## What

**The message.** `EchoCache.Coherence.payload/2` frames two names and nothing else; `parse/1` refuses anything that is not exactly two valid branded ids. The committed surface gate: `a twenty-nine-byte payload of two names, parse refusing garbage`. The cargo law of the whole series — only identities cross — rides into coherence unchanged.

**Newer-wins has teeth.** The dangerous case is not the fresh invalidation; it is the *stale* one arriving late — a slow lane, a retry, a replay. The committed drill stages it: a row written at version `v_new`, then an invalidation carrying an older version. The record: `a late stale invalidation bounced off both layers -- the L1 row survived holding px=105.00 and the L2 drop script answered 0`. The L1 side is one comparison in the owner; the L2 side is one Lua script — read the framed version, compare payloads, delete only if newer — one transition, one script, Part III's law applied to the cache. And the same comparison is the idempotence story: `idempotence is a comparison, not a log` — replaying a version answers `:stale` the second time, with no dedup table anywhere.

**The broadcast lane.** A coherence write publishes on the table's channel; every node's table holds a RESP3 subscription and applies pushes in its owner. The substrate's contract is stated by its own documentation — Valkey pub/sub is at-most-once, "a message will be delivered once if at all" [1] — so the lane is fast and lossy by construction. Measured: `median push latency 72 us over 100 messages, inside the derived band`, and the cross-node round trip closes end to end — `the writer put px=106.00, 3 subscribers heard the name, and the other node's next read fell through its dropped L1 to the shared L2` and answered fresh. The receiver never refetches on the push itself: an invalidation drops the L1 row, and the next read pays the normal cache-aside path against an L2 the writer already updated.

**The loss, gated.** Fire-and-forget is a price, and the record pays it in the open: a table that declared the job lane holds no subscription, so `the broadcast passed it by and it still serves px=100.00 -- bounded staleness until its own lane delivers`. A missed broadcast costs one TTL of staleness — exactly the 4.1 bound — which is why the broadcast lane is declared per surface rather than assumed.

**The job lane.** The same twenty-nine bytes enqueued on EchoMQ's fair lanes, applied by a consumer running `Table.coherence_handler/1`. The drill is the bus's own crash choreography from Part III, now carrying coherence: `the first consumer died holding the job, the reaper returned it, the healer applied it -- :qc dropped its stale row and now serves px=107.00 from the shared L2 -- the completed job left no row to browse, and replaying the same version answers stale: at-least-once delivery, exactly-once effect`. Redelivery is harmless because application is a comparison; the provenance machinery of 3.5 is not even needed here — the version *is* the provenance.

**The price, on one row.** `broadcast median 72 us fire-and-forget, job lane median 148 us at-least-once -- the guarantee costs 2.1 times the latency`. Both lanes are sub-millisecond on this wire; the real difference is gates F4 and F5, not the microseconds — a surface chooses its lane by what a stale read costs, and the declaration in the directory records the choice.

## Who

Risk and limits surfaces, which ride the job lane because a stale ceiling is money. Quote boards and reference data, which ride broadcast — or nothing — because a TTL was already enough and the push only tightens it. Writers, whose obligation is one call after the store write: `put/4` with the write's version, then `broadcast/4` or `enqueue/5`, both one line. Chapter 4.3, which inherits the applier: today the table's owner applies pushes inline, and the ring chapter moves that application onto a single-writer ring with batching and occupancy — the semantics gated here do not change, only the engine under them. And the Go port: the lane vocabulary is channel names, queue names, and a twenty-nine-byte frame — nothing in it assumes the BEAM.

## When

Declare `:broadcast` when staleness is tolerable but a tighter bound is cheap value — the lane costs one subscription per table per node and 72 microseconds per message. Declare `:job` when at-least-once is a requirement — and note what the record shows: the guarantee's latency price on this wire is 76 microseconds, so the job lane is not the slow lane, it is the accountable one. Declare `:none` when the TTL already says everything true. And mint versions where the write happens: the version is the write's identity, so the writer who changed the store is the only true source of it — `put/3` mints one for writers who have no event id of their own, `put/4` carries the writer's own.

## Where

The vocabulary in `runtimes/elixir/lib/echo_cache/coherence.ex`; the table's growth in `lib/echo_cache/table.ex` (versioned four-tuple rows, framed L2 values, the newer-wins applier, the broadcast subscription, the job-lane handler); the connector's send-only push path in `lib/echo_mq/connector.ex` (`push_command/3`, `subscribe/2` — nothing enqueued on the FIFO, RESP3 required and refused otherwise with a typed `:requires_resp3`, as the surface gate shows). The channel is `ecc:{<table>}:coh`; the queue is `ecc.coh.<table>`; both derive from the table name and nothing else.

## How — wiring a surface

**The writer's side, after its store write:**

```elixir
version = BrandedId.generate!("TXN")           # the write's own identity
:ok = Table.put(:quotes, ast_id, "px=106.00", version)
{:ok, _heard} = Coherence.broadcast(conn, "quotes", ast_id, version)
# or, when at-least-once matters:
{:ok, :enqueued} = Coherence.enqueue(conn, "quotes", group, ast_id, version)
```

**The job lane's consumer — one supervised child in the application's tree:**

```elixir
{:ok, _} =
  EchoMQ.Consumer.start_link(
    queue: Coherence.queue("quotes"),
    connector: [port: 6390],
    handler: Table.coherence_handler(:quotes)
  )
```

**The comparison that is the whole protocol:**

```elixir
Coherence.newer?("TXN0NuG2aaaaaaa", "TXN0NuFzzzzzzzz")
# payload bytes in mint order: true — no decode, no clock, no quorum
```

## Decisions

**The version is a name.** Not a counter, not a wall-clock reading, not a vector: a branded id whose payload bytes already total-order by mint time across every kind. One identity system, one more dividend.

**Coherence drops; it never writes.** A message means *the writer already placed the newer value in L2*; the receiver's only move is to discard its older L1 copy. Receivers writing values they heard about would make every subscriber a writer, and the lane carries names, not rows.

**Stale messages bounce off both layers.** The L1 comparison in the owner and the L2 comparison in one Lua script are the same predicate in two places, because a late invalidation that can erase a newer row is a coordination bug wearing a latency costume.

**The job-lane consumer lives in the application's tree.** The table wires its own broadcast subscription — cheap, self-contained, supervision-as-resubscription — but an EchoMQ consumer is a real supervised worker with a lease and a lane, and hiding one inside a cache table would falsify the supervision tree. `coherence_handler/1` makes the wiring one line; the tree stays true.

**The connector's push path is send-only and RESP3-only.** A SUBSCRIBE confirmation arrives as a push, so awaiting it on the FIFO starves the queue — the new verb sends without enqueueing an expectation, and refuses protocol 2 where pushes and replies cannot share a wire.

**The applier is the owner — for now.** Pushes apply inline in the table's process, which is correct and measured fast; Chapter 4.3 moves application onto the ring for batching and backpressure without touching the semantics gated here.

## Boundaries

The broadcast lane inherits its substrate's contract whole: at-most-once, unpersisted, lost on disconnect [1] — a node that reconnects has missed what it missed, the TTL bounds the damage, and resubscription rides supervision (the table restarts, the subscription returns; auto-resubscribe inside the connector is a carried knob, not a shipped feature). The job lane inherits the bus's: at-least-once with redelivery, volatile by D-2 — a bus restart loses queued coherence jobs along with everything else, and the TTL is again the floor under the loss. Cross-kind version comparison is mint-order only, by design; two writes minted in the same millisecond on different nodes order by node-and-sequence bits, which is an arbitrary-but-total tiebreak in exactly Lamport's sense [3]. And the latencies are this container's: one core, loopback, both lanes far below any network's floor — the ratio and the ordering travel, the microseconds do not.

## Companion files

`runtimes/elixir/lib/echo_cache/coherence.ex`, the grown `lib/echo_cache/table.ex`, the grown `lib/echo_mq/connector.ex`; the rung `bcs_rung_4_2_check.exs` and its committed record `bcs_rung_4_2_check.out`; the amended `bcs_rung_4_1_check.exs` (versioned rows under the fixture policy, frozen record untouched).

## References

1. Valkey documentation — Pub/Sub (at-most-once delivery, unpersisted channels, ordered per publisher, RESP3 commands while subscribed — the broadcast lane's contract, taken whole): [valkey.io/topics/pubsub](https://valkey.io/topics/pubsub/)
2. Valkey documentation — Client-side caching (server-assisted tracking and its invalidation messages: the comparison set's deletion-shaped coherence, carrying no version and no order — the gap this chapter's message closes): [valkey.io/topics/client-side-caching](https://valkey.io/topics/client-side-caching/)
3. Lamport, L. — Time, Clocks, and the Ordering of Events in a Distributed System, CACM 21(7), 1978 (a total order constructed from logical timestamps resolves distributed events without coordination — newer-wins is this order, carried in the name): [dl.acm.org/doi/10.1145/359545.359563](https://dl.acm.org/doi/10.1145/359545.359563)
