# B3.1.3 · The Co-location Law

> Dive 3 of B3.1 · route `/bcs/bus/fence-and-keyspace/the-co-location-law` · teaches F5 of `content/bcs3.1.md`
> (`bcs_rung_3_1_check.out`, `PASS 5/5`).

The hashtag is the queue.

F5 is the chapter's theorem. The hashtag is the queue name, so every key of one queue answers one slot — and
every transition script this part will write stays single-slot legal on the clustered day, by grammar rather
than by review.

## §1 The transcript

This dive reads F5 (source: `content/echo_data/runtimes/elixir/bcs_rung_3_1_check.out`, verbatim):

```
F1 map ok -- the part's map: emq:{orders}:pending | emq:{orders}:job:ORD0NgWEfAEJfs | {emq}:version | {emq}:locks -- 17 bytes before the payload
F2 gate ok -- the job position is gated: a fourteen-byte decimal and a fourteen-byte slug both raise before any wire is touched; kind policy waits for the enqueue script
F3 fence ok -- the fence holds on a live wire: GET {emq}:version answers echomq:2.0.0 through the fenced connector itself
F4 binary ok -- binary payloads with embedded CRLF and NUL survive 500/500 round trips through job keys in two pipelines
F5 slot ok -- co-location law: pending, active, meta, and the job row of {orders} all answer slot 105; {fills} answers 4165 -- multi-key scripts stay legal on the clustered day (vector 12739 holds)
PASS 5/5
```

## §2 F5 — the theorem

The hashtag *is* the queue name, so every key of one queue answers one slot: `pending, active, meta, and the job
row of {orders} all answer slot 105; {fills} answers 4165` — and slot 105 is the same figure the appendix froze
for the same hashtag, continuity across rungs by arithmetic rather than by intention. The appendix's record also
holds the contrast figure: `8507` for the payments queue (source: `content/bcsA.md`).

The consequence is the part's road ahead: hash tags exist to ensure that multiple keys are allocated in the same
hash slot, which is what makes multi-key operations legal in a cluster — so every transition script this part
will write (claim moves a job between pending and active; retry touches the job row and a schedule) stays
single-slot legal on the clustered day, by grammar rather than by review. The `vector 12739 holds` for the
client-side CRC16.

## §3 Committed, correct, and parked

The slot function stays what the preface said: committed, correct, and parked, because single-instance is the
part's stated topology. The connector does not speak cluster redirects, and teaching it `MOVED` is the clustered
day's rung, not a hidden feature of this one. Mind the slot function's two lives: today it is partition
arithmetic the connector can run without a round trip; on the clustered day it becomes routing, and the
co-location law means the scripts written between now and then need no edits to survive the move.

Agents writing against the bus inherit one rule that prevents the whole category of cross-slot accidents: if a
script needs keys from two queues, the design is wrong before the script is. Cross-queue choreography goes
through the application, never through a multi-queue script.

## References

Sources:

- Valkey — Cluster specification — https://valkey.io/topics/cluster-spec/ (hash slots, CRC16 modulo 16384, and
  hash tags as the same-slot mechanism behind the co-location law)
- Valkey — Protocol specification — https://valkey.io/topics/protocol/ (the wire under the slot arithmetic;
  length-prefixed bulk strings)

Related:

- /bcs/bus/fence-and-keyspace — B3.1, the module hub; the full rung in context
- /bcs/bus — B3 · The Bus, the chapter landing
- /bcs/ideas — B1 · Ideas Behind, the identity canon
- /echomq — EchoMQ, the keyspace in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate: cluster hash slots, atomic Lua
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/bus/fence-and-keyspace/the-fence-live` · next `/bcs/bus/fence-and-keyspace` (back to the
hub).
