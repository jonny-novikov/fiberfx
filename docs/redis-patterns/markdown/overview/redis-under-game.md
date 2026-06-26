# Valkey under codemojex

> Route: `/redis-patterns/overview/redis-under-game` · Module R0.2 (hub) · Source: ORIENTATION — the
> named-consumer module, no single pattern source (the connector and the protocol are taught by `/echomq`) · Grounding:
> `echo/apps/echo_wire` · `echo/apps/echo_mq` · `echo/apps/echo_store` · `docs/echo/bcs/content/bcs3.1.md` ·
> `bcs4.md` · `echo/apps/codemojex` — every figure verbatim from a committed record. Reframed under
> [`specs/reframe-echomq/`](../../specs/reframe-echomq/reframe-echomq.md).

Before the patterns, the play. **codemojex** reaches one boundary — the echo data layer — and
below it Valkey serves two roles: **EchoStore** — the near-cache, an L1 of ETS tables over the L2 Valkey — and the
**EchoMQ bus** — the owned-protocol bus at `echo/apps/echo_mq` — both over one Valkey, and no surface holds a raw
Valkey key. Three dives take the play apart, in the arc *the seam → the roles → the tier*: the **facade seam**
every surface respects, the **two roles** the store plays below it, and the **tier** once held in reserve — now
shipped, owned-protocol code. The connector and the protocol are taught by the [`/echomq`](/echomq) course; this
module places the store around it.

## §1 · Below the facade

The codemojex reaches Valkey through one owned boundary — the echo data layer — and every surface, from the
order API to a background consumer, calls that boundary and reads typed results, never a raw store condition. None
of them opens a socket, holds a key, or branches on a wire error. The one owned Valkey client is **EchoWire**
(`echo/apps/echo_wire`); above it sit two roles, both over Valkey:

- **EchoStore** — the near-cache in front of the read path. Its one-line case is the Part IV title made plain:
  *branded keys, local speed, bus-driven coherence* (`bcs4`). An L1 of declared ETS tables over the L2 Valkey.
- **The EchoMQ bus** — the owned-protocol bus at `echo/apps/echo_mq`: the closed braced `emq:{q}:<type>`
  grammar, the three-field job hash, the four sorted sets, eight verbs over six scripts — backed by Valkey.

That single rule is the master invariant the whole course respects. It is why a cache can be added, swapped, or
deleted without a surface changing, and why the bus could be re-derived and shipped as new code — the program
story the third dive retells — without a surface changing either.

## §2 · Two roles, one store

Below the facade the store does two distinct jobs, and the two roles ground different halves of the catalog.

- **The cache machine is EchoStore.** It holds **derived** state — a copy of the truth, safe to drop. A dropped
  row costs a slower read, never a lost fact. The caching and data-modeling families ground here (`bcs4.*`), or
  in clean standalone examples.
- **The EchoMQ bus holds authoritative state** — the jobs *are* the work. Per queue, four sorted sets carry the
  lifecycle: `pending` (score-zero, lex order is mint order), `active` (lease-scored), `schedule` (run-at-scored),
  `dead`. The queues, coordination, streams, and flow-control families ground here (`bcs3.*`).

The application door: one engine, one closed grammar. The committed keyspace line from `bcs3.1` reads
`emq:{orders}:pending | emq:{orders}:job:ORD0NgWEfAEJfs | {emq}:version | {emq}:locks -- 17 bytes before the
payload`. On Valkey, the braced hashtag is what keeps every key of one queue in one cluster slot — co-location by
grammar, not by review.

> Notes on Valkey · In a sorted set, elements with the same score are ordered lexicographically — which is why
> the score-zero `pending` set browses in mint order with no second index
> ([valkey.io/topics/sorted-sets](https://valkey.io/topics/sorted-sets/)).

## §3 · The three dives

Each dive takes one part of the play, in the arc *the seam → the roles → the tier*. Read them in order —
the facade seam starts.

- **R0.2.1 · The facade seam** — the master invariant: every surface calls only the echo data layer and reads
  typed results, never a raw key. EchoWire is the one owned Valkey client below it.
- **R0.2.2 · The two roles** — EchoStore, the derived near-cache in front of the read path, and the EchoMQ bus,
  the authoritative state below — and which pattern families ground in each half of the catalog.
- **R0.2.3 · The reserved tier** — the tier once held in reserve, now shipped: EchoMQ at `echo/apps/echo_mq`,
  the Valkey-native bus, with the real `claim` script as the worked move.

**The play → its BCS application.** Keep one store below one facade, in two clear roles; surfaces never
depend on the store, and the store can change without them. In the BCS build that is EchoStore and the EchoMQ
bus over one owned client, `EchoWire`, both over Valkey — the near-cache derived, the bus authoritative, and the
bus's protocol owned outright. After R0.2, the next module — R0.3 · Patterns become protocol — shows how the
bus's patterns become a protocol any conforming runtime speaks.

## References

### Sources
- [Valkey — Sorted sets](https://valkey.io/topics/sorted-sets/) — equal-score lexicographic ordering, the fact behind the score-zero pending set.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — hash tags as the same-slot mechanism behind the braced keyspace.
- [Redis — Documentation](https://redis.io/docs/) — the command and data-type reference behind the catalog.
- [llmstxt.org — The llms.txt convention](https://llmstxt.org/) — the machine-readable map format the course follows.

### Related in this course
- [R0.2.1 · The facade seam](/redis-patterns/overview/redis-under-game/the-facade-seam) — the master invariant.
- [R0.2.2 · The two roles](/redis-patterns/overview/redis-under-game/two-roles) — the near-cache and the bus.
- [R0.2.3 · The reserved tier](/redis-patterns/overview/redis-under-game/reserved-tier) — the tier, shipped.
- [R0 · Overview](/redis-patterns/overview) — the chapter.
- [R0.3 · Patterns become protocol](/redis-patterns/overview/patterns-become-protocol) — the next module.
- [Functional Programming in Elixir](/elixir) — the functional-Elixir and OTP craft behind the echo umbrella.
