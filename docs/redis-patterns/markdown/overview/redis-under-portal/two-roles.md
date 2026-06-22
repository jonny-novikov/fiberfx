# The two roles

> Route: `/redis-patterns/overview/redis-under-portal/two-roles` · Module R0.2 · dive 2 · Source: ORIENTATION —
> the placement module, no single pattern source · Grounding: `docs/echo/bcs/content/bcs4.md` · `bcs4.1.md` (the
> EchoCache role) · `bcs3.2.md` · `bcs3.3.md` (the EchoMQ bus role) — every figure verbatim from a committed
> record. Reframed under [`specs/reframe-echomq/`](../../../specs/reframe-echomq/reframe-echomq.md).

One store, two jobs below the facade: **EchoCache**, the near-cache in front of the read path, and the **EchoMQ
bus**, the work itself. The two roles hold different kinds of state and ground different halves of the catalog.
EchoCache holds **derived** state — a copy of the truth, safe to drop. The EchoMQ bus holds **authoritative**
state — the jobs *are* the work. Which role grounds a pattern is the first thing each chapter names.

## §1 · The cache machine is EchoCache

The first role is the near-cache in front of the engine's reads: an L1 of declared ETS tables over the L2 Valkey
the systems already share. Its one-line case is the `bcs4` title made plain — *branded keys, local speed,
bus-driven coherence*. A warm read is a local ETS lookup; a cold read fills through a declared loader and lands
the L2 row with its TTL; an L1 drop falls back to L2 before the loader is consulted again.

The state here is **derived** — a copy of a truth that lives elsewhere, so a dropped cache costs a slower read,
never a lost fact. And the speed difference is committed, not estimated. The headline from `bcs4.1`:
`1311621 hit reads per second (762 ns each) against 31 us per L2 GET on the same wire -- the L1 hit is 40 times
cheaper than the round trip it replaces, inside the derived band`. This role grounds the caching and
data-modeling families — in EchoCache's committed record, or in clean standalone examples.

## §2 · The EchoMQ bus holds the work

The second role is the bus: the owned-protocol job queue at `echo/apps/echo_mq`, backed by Valkey. Here the
store holds the queues themselves, and the state is **authoritative**: the jobs in the sets *are* the work, so
the bus is built for atomic hand-off and recovery, not for eviction.

The shapes are exact (`bcs3.2`, `bcs3.3`). A job row is a hash of exactly three fields — `state`, `attempts`,
`payload` — and deliberately nothing more: no `enqueued_at`, because mint time already lives inside the id. Per
queue, four sorted sets carry the lifecycle:

- `pending` — score-zero forever; equal scores order lexicographically, and for branded ids lex order is mint
  order, so the set is the FIFO, the browse index, and the time-range index at once.
- `active` — scored by lease deadline; the in-flight roster and the expiry index in one structure.
- `schedule` — scored by run-at; the separate set that keeps scores out of the lex law.
- `dead` — score-zero again; the morgue browses newest-first like everything else.

Eight verbs over six scripts move work between them. The committed dividend from `bcs3.2` reads: `the last five
minted in reverse mint order; the very first job sits at the head; 301 pending, no second index anywhere`. This
role grounds the queues, coordination, streams, and flow-control families.

> Notes on Valkey · In a sorted set, elements with the same score are ordered lexicographically — the engine
> fact behind the score-zero pending set, and the reason delayed work lives in a separate run-at-scored set
> ([valkey.io/topics/sorted-sets](https://valkey.io/topics/sorted-sets/)).

## §3 · Which family, which role

The split is the map for the whole course: a pattern family grounds in one role or the other. The caching and
data-modeling families ground in EchoCache — the derived, read-path half. The queues, coordination,
streams-events, and flow-control families ground in the EchoMQ bus — the authoritative, work-path half.

The application door: one engine, two keyspaces. The bus writes the closed `emq:{q}:<type>` grammar; EchoCache's
keyspace is its own — `ecc:{<table>}:<id>`, a fresh prefix beside `emq:`, never inside it, hashtagged on the
table name for the clustered day (`bcs4.1`). On Valkey, each L2 row carries its TTL on the server's own clock:
written with `SET … PX`, read back as `PTTL 300 ms of 300` in the committed record.

**The split → its BCS application.** One store can hold two kinds of state: a derived cache, safe to drop, and
an authoritative queue, the work itself; the kind of state determines how the role is built. In the BCS build,
EchoCache holds the derived half — declared tables, single-flight fills, jittered TTL — and the EchoMQ bus holds
the authoritative half — the three-field row, the four sorted sets, every transition one atomic script.

## References

### Sources
- [Valkey — Sorted sets](https://valkey.io/topics/sorted-sets/) — equal-score lexicographic ordering; the same-score family behind the score-zero decision.
- [Valkey — SET](https://valkey.io/commands/set/) — the `PX` option: the L2 row written with its expiry in one command.
- [Valkey — EXPIRE](https://valkey.io/commands/expire/) — expiration semantics; the L2-side counterpart of the L1 sweeper.
- [Redis — Documentation](https://redis.io/docs/) — the command and data-type reference behind the catalog.

### Related in this course
- [R0.2 · Valkey under the Exchange Platform](/redis-patterns/overview/redis-under-portal) — the module hub.
- [R0.2.1 · The facade seam](/redis-patterns/overview/redis-under-portal/the-facade-seam) — the previous dive.
- [R0.2.3 · The reserved tier](/redis-patterns/overview/redis-under-portal/reserved-tier) — the next dive; the bus, shipped.
- [R1 · Caching](/redis-patterns/caching) — the family EchoCache grounds.
- [R3 · Reliable Queues](/redis-patterns/queues) — the family the bus grounds.
- [/bcs](/bcs) — the architecture both roles are built inside.
