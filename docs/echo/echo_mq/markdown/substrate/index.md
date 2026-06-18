# E3 · EchoMQ 2.0 — the protocol break

> Route: `/echomq/substrate` (chapter landing). The route-mirror source-of-record. Movement II opens with the fork. A
> **route manifest**: the five module cards (E3.01–E3.05) and the "Up next" grid (E4–E8) forward-link not-yet-built
> routes with the `soon` pill. The rung this chapter tracks, `emq.1`, is **drafted** — the EchoMQ 2.0 protocol break,
> taught from its rewritten spec ("emq.1 ships …"), never asserted as shipped. `⇄ emq.1` · `← redis-patterns R0, R2`.

## Hero

EchoMQ 2.0 — the protocol break. emq.1 ships EchoMQ's own wire: the `emq:{q}:…` keyspace replacing `emq:` with the
per-queue hashtag applied **transparently by the core**, the reserved `{emq}:` base for the core's own cross-queue
keys, every Lua key declared in `KEYS[]` (the inherited undeclared-keys flaw resolved at the root), `meta.version`
`echomq:2.0.0` behind a two-way boot fence, and an explicit v1→v2 migration path. BullMQ compatibility is dropped by
design; the v1 line freezes at 1.3.0.

Movement I taught the as-built core — the **v1 line**, BullMQ-wire-compatible, frozen at 1.3.0. Movement II opens by
breaking from it: deliberately, once, versioned. The rung is **drafted**: nothing of the v2 surface exists on disk yet,
so this chapter teaches from the rewritten `emq.1` spec — "emq.1 ships `<surface>`" — and is re-grounded in the real
modules when the rung ships.

## The triangle this chapter stands on

Every Movement-II page names three artifacts:

- **the pattern** — `← redis-patterns R0` (foundations: load-once, SHA-dispatched scripts; the keyspace as a contract)
  and `R2` (atomicity: a multi-key change as one indivisible Lua move), plus the undeclared-keys audit evidence
  (the superseded second-engine chapter, since removed from the tree). The transferable techniques and the measured reason to break.
- **the spec** — `⇄ emq.1`, the rung tracked (`docs/echomq/specs/emq/emq.1.md`, rewritten 2026-06-10 to the 2.0
  break), its deliverables D1–D7. **Drafted.**
- **the as-built code** — the v1 evidence the break answers: the `emq:` key builders (`keys.ex`), the in-script
  concatenation (`moveToActive-11.lua:148` `local jobKey = keyPrefix .. jobId`, `:162` the lock key), the caller
  sending only declared keys (`scripts.ex:256`), `meta.version` = `bullmq:5.65.1`, `@version "1.3.0"`.

## Why & when

The v1 line's scripts reach keys they never declare — ~24–26 of the 50 concatenate per-job keys inside the script. On
a single-threaded engine that is invisible, but it sits outside the engine scripting contract — Valkey's own guidance:
every key a script accesses arrives as an input key argument. The keyspace is also unplaced: no hashtags, nothing for
slot placement to work with. Containing
that flaw script-by-script would preserve a wire EchoMQ no longer wants; emq.1 resolves it at the root by shipping a
protocol EchoMQ owns. Read this chapter first if you are about to follow the build into groups (E4), batches (E5),
lifecycle controls (E6), or the cache (E7) — each is a set of declared-keys scripts on the owned keyspace.

(Framing interactive: the fork comparator — the same `payments` queue on the v1 line (`emq:payments:*`, no hashtag,
undeclared per-job keys, frozen at 1.3.0) and on the 2.0 wire emq.1 ships (`emq:{payments}:*`, the hashtag applied
transparently by the core, every key declared, plus the reserved `{emq}:` base).)

## Start here — the orientation

Three orientation dives take the break's big ideas in turn, before the granular modules:

- **The owned keyspace** — `/echomq/substrate/the-opt-in-floor` — emq.1 ships `emq:{q}:…` replacing `emq:` — the
  per-queue hashtag applied transparently by the core, the `{emq}:` base reserved for the core's own keys. Grounds in
  emq.1 D1.
- **The versioned break** — `/echomq/substrate/loaded-beside-the-core` — one fork, fenced: `meta.version` becomes
  `echomq:2.0.0`, a two-way boot fence refuses cross-version contact, and an explicit v1→v2 migration path closes the
  line frozen at 1.3.0. Grounds in emq.1 D3/D7.
- **Conformance, not compatibility** — `/echomq/substrate/compatibility-as-a-check` — the v2 conformance probe and
  the fleet-interop round-trip that make "correct on its own wire" a running check — and the honest seam: stock BullMQ
  clients cannot speak v2, by design. Grounds in emq.1 D5/D6.

## The full chapter (the depth, on the way)

Re-derived from the rewritten rung's deliverables:

- **E3.01 · The owned keyspace** — the emq prefix · the transparent hashtag · the `{emq}:` reserve. Grounding:
  `emq.1-D1`.
- **E3.02 · The declared-keys script set** — the flaw · the declaration discipline · the placement payoff. Grounding:
  `emq.1-D2`.
- **E3.03 · The versioned fence & branded ids** — the version fence · the Snowflake · the codec-locality rule.
  Grounding: `emq.1-D3`/`D4`.
- **E3.04 · The two probes — conformance & fleet interop** — the conformance probe · the fleet interop · the diff
  rule. Grounding: `emq.1-D5`/`D6`.
- **E3.05 · Workshop** — walk the v1→v2 migration on a real queue and run both probes green on the v2 wire. Grounding:
  `emq.1-D5`/`D6`/`D7`.

## How it works

The break is one rung with one mechanism: own the keyspace, declare the keys, version the wire. emq.1 ships the key
builders that write `emq:{q}:wait`, `emq:{q}:active`, `emq:{q}:<jobId>` — the per-queue hashtag inserted by the core,
never by the caller — and a script set in which every key a script touches is listed in `KEYS[]` before the script
runs. The v1 line concatenates per-job keys *inside* the script (`local jobKey = keyPrefix .. jobId`,
`moveToActive-11.lua:148`), outside the engine scripting contract — Valkey's guidance: every key a script accesses
arrives in `KEYS[]`. With every key declared and placed by its `{q}` hashtag, each call's key set is slot-local and
known before it runs. `meta.version` records `echomq:2.0.0`; a two-way boot fence refuses
cross-version contact; the migration path moves a v1 deployment over once, deliberately.

**Bridge (pattern → implementation).** The pattern (R2 atomicity, R0 foundations): a multi-key change is one
indivisible Lua move over `KEYS`/`ARGV` with no foreign command, dispatched once by SHA — and the `KEYS[]` declaration
is load-bearing: it is how the store knows what a script will touch before it runs. The implementation (emq.1 ships):
the `emq:{q}:…` keyspace and the declared-keys script set, so every move keeps the v1 line's atomicity *and* gains a
true, declared key set — slot-local by construction, no escape hatch.

The break is the one rung that ships no feature — it ships the wire, so every later rung is a set of declared-keys
scripts on an owned, placed keyspace, and "correct on the v2 wire" is a check that runs.

**The 2.0 fork (the break callout).** This chapter is where the fork happens. The v1 line (frozen at 1.3.0) speaks
`emq:` and inherits the undeclared-keys flaw; emq.1 ships the whole break in one rung — the owned `emq:{q}:…`
keyspace, the `{emq}:` reserve, every Lua key declared, `echomq:2.0.0` behind a two-way fence, and the migration path —
so EchoMQ runs on an owned, placed keyspace of its own. Broken once, versioned, then owned.

**Redis Patterns Applied (the reverse door).** This chapter is the depth on the far side of two redis-patterns doors —
the mirror of redis-patterns' "a door, not a depth". The foundations it stands on (load-once SHA-dispatched scripts,
the keyspace-as-contract discipline) are taught one-excerpt-at-a-time in [R0 · Overview](/redis-patterns/overview);
the atomic multi-key move the break preserves is taught in [R2 · Coordination](/redis-patterns/coordination). There a
reader meets each pattern once and portably; here those patterns become a protocol of EchoMQ's own — every key
declared, every key placed — verified against Valkey, the conformance truth. Door map of record:
`docs/redis-patterns/redis-patterns.echomq-doors.md`.

## Up next

E4 (groups ⇄ emq.2), E5 (batches ⇄ emq.3), E6 (lifecycle controls ⇄ emq.4), E7 (EchoStore ⇄ emq.5), and E8 (production
⇄ emq.6) each build on the 2.0 wire emq.1 ships — declared-keys scripts on the owned, placed keyspace. They are
specified and on the way; each teaches from its rung's spec until the rung ships.

## References

### Sources
- [BullMQ — Documentation](https://docs.bullmq.io/) — the wire protocol the v1 line speaks and EchoMQ 2.0 deliberately leaves.
- [Valkey — Scripting with Lua](https://valkey.io/topics/eval-intro/) — the key-declaration rule: every key a script accesses arrives as an input key argument.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the slot placement the `{q}` hashtag drives.
- [Redis — Cluster specification](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/) — the `{…}` hash-tag rule the `emq:{q}:…` keyspace builds on.

### Related in this course
- [E3 · The owned keyspace](/echomq/substrate/the-opt-in-floor) — start here.
- [E2 · The core](/echomq/core) — the as-built v1 line the break forks from.
- [redis-patterns R0 · Overview](/redis-patterns/overview) — the foundations door.
- [redis-patterns R2 · Coordination](/redis-patterns/coordination) — the atomicity door.
