# EMQ · EchoMQ 4 — Groups Deepened, the Movement II Opener (line spec)

<show-structure depth="2"/>

Status: **PROPOSED — the BCS-side specification mirror of the Movement II opener.** The binding design canon and the
ratified ladder live with the production tree (the Operator's [`emq.design.md`](../emq.design.md) and
[`emq.roadmap.md`](../emq.roadmap.md)); this file is their specification mirror inside the BCS documentation set — it
fixes what the "groups deepened" chapter is, the laws it carries whole, the as-built fair-lanes surface it deepens,
and the four-rung decomposition, and it never redesigns what the canon owns. The chapter body
([`emq.4/emq.4.md`](emq.4/emq.4.md)) is authoritative; the line beneath is [`emq.streams.md`](../emq.streams.md) (the
stream tier) and the parity line [`emq.2.specs.md`](emq.2.specs.md).

## What the chapter is

emq.4 is **the first rung of Movement II** — the family ladder that follows Movement I's closed parity core. It
**deepens the fair-lanes (groups) family** that landed structurally in the foundation as `EchoMQ.Lanes` (the
displaced family the roadmap RULED into this slot — [`emq.roadmap.md`](../emq.roadmap.md) seam 2, CLOSED; design §10
seam 2 / §4 cluster 2). The basics already shipped and are gated (B3.4 "Fair Lanes", G1–G8): grouped admission, the
rotating-ring claim, per-group pause/resume, concurrency ceilings, per-lane depth, and the park-don't-poll loop.
emq.4 takes that floor to **production multi-tenant depth** along four axes — a control plane, group-aware recovery,
the metronome, and weighted/deficit fairness — without breaking the wire (every axis is additive over the shipped
`g:`-segment keyspace; nothing here is a major).

## The laws (binding, carried whole from the canon)

**The key universe is grammar-total, and the lane family is already inside it.** Every lane key is braced
`emq:{q}:` — the as-built family is `emq:{q}:g:<group>:pending` (the lane ZSET), `…:ring`, `…:paused`, `…:glimit`,
`…:gactive`, `…:wake`, each built by `Keyspace.queue_key/2`. The group identity is a **branded id**, gated
`EchoData.BrandedId.valid?/1` at the lane-key builder (`Lanes.lane_key!/2`) — a valid branded group or a raise,
never interpolation. emq.4 proposes **no new lane key family**: every deepening rides the shipped keys (the
canon-recorded discipline — intra-group priority is a non-zero score on the existing lane ZSET, never a `prioritized`
key; lane re-assignment moves a member between two existing lane ZSETs).

**Declared keys, server clock, additive minor.** Every Lua key a rung adds is in `KEYS[]` or derived in-script from a
**declared `KEYS[n]` root** by the registered grammar — the as-built `@gclaim` derives the lane as
`ARGV[1] .. 'g:' .. g .. ':pending'` from a queue base passed as a declared-root operand (the A-1 ARGV-slot-rooted
convention ratified at emq.3, design §1 S-6). Any transition that touches a lease reads `TIME` **server-side** inside
the script (the as-built `@gclaim`/`@reap` pattern). The conformance set grows ONLY by additive minor — the prior
**52** scenarios byte-unchanged and git-verified, each new one probe-registered, the count re-pinned in both pinning
tests. Additive registration is a protocol minor; a wire break is a major.

**The wire stands unextended.** `{emq}:version` (`echomq:2.0.0`) is monotone behind the five-code fence; emq.4 adds
no fence code, no new wire class (the kind law reuses `EMQKIND`), and no new transport. The fork happened once; no
emq.4 rung re-breaks it.

## The as-built surface this chapter deepens (Movement 0 + B3.4, landed and gated)

`EchoMQ.Lanes` (`echo/apps/echo_mq/lib/echo_mq/lanes.ex`) — the fair-groups system over the wire: `enqueue/5`
(`@genqueue`, kind law first, the score-0 lane admission + ring bookkeeping + a wake), `claim/3` (`@gclaim`, the
rotating ring `LMOVE`, `ZPOPMIN` the lane head, the server-clock lease, attempts as the fencing token, the group
returned beside the job), `pause/3` (`@gpause`), `resume/3` (`@gresume`), `limit/4` (`@glimit`, the concurrency
ceiling that parks/reopens a lane), `depth/3`. `EchoMQ.Metrics` (`metrics.ex`) — `lane_depth/3` and `lane_depths/3`
(`@lane_counts`, the per-lane backlog reads, branded-gated). `EchoMQ.Jobs.@reap` (`jobs.ex`) — **already group-aware**:
an expired grouped lease returns to its lane `g:<g>:pending` (not a global pool), decrements `gactive`, re-rings,
and wakes (the `stalled_group` conformance scenario is its proof). `EchoMQ.Consumer` (`consumer.ex`) — **the
park-don't-poll loop already shipped**: `reap → promote → drain (rotating claim) → park (`BLPOP` the `wake` key,
the beat as the fallback)`, the wake pushed by every transition that makes a lane serviceable. emq.4 stands ON all of
this unchanged and deepens it.

## The capability decomposition (the four rungs)

emq.4 decomposes into four dependency-ordered rungs (the Operator-ruled spine — [`emq.4/emq.4.md`](emq.4/emq.4.md)
"The carve"), each a full triad + a runbook, one increment per run:

| Rung | Deepens (PROPOSED) | Stands on (as-built) | Risk |
|---|---|---|---|
| **emq.4.1** | the **control plane** — group move / re-assignment; deepened pause/resume/limit/drain; the v1 `changePriority-7` re-aimed to lane re-assignment (no numeric priority — mint order IS the order theorem), `getCountsPerPriority-4` re-aimed to `Metrics.lane_depths/3` | `Lanes.{pause,resume,limit}/_`, `Metrics.lane_depths/3`, the lane ZSET | NORMAL |
| **emq.4.2** | **group-aware recovery** — a group-scoped stalled-sweep that returns expired-lease members to their lane (not a global pool), respecting the ring; server clock | the shipped group-aware `@reap`, the `stalled_group` scenario | NORMAL |
| **emq.4.3** | the **park-don't-poll metronome** — the wake/notify beat deepened (consumers park and are woken on admission/availability, not busy-polled) | the shipped `Consumer` park loop + the `wake` protocol | **HIGH** — founds a process/lease surface; Apollo mandatory; the Director's verify deepens (≥100 determinism loop) |
| **emq.4.4** | **weighted/deficit rotation + the starvation drill** — fair-share beyond round-robin over the ring, with a proof no lane starves under skew (the capstone) | the `@gclaim` ring rotation, the lane ZSET | **HIGH** if it edits the shipped `@gclaim` ring → byte-freeze discipline + Apollo mandatory |

Nothing in this decomposition invents a surface: each rung re-aims a named v1 capability (the groups feature record,
[`emq.commands/features/groups/`](emq.commands/features/groups/)) or deepens a shipped `EchoMQ.Lanes`/`Consumer`
surface, designed under the v2 laws.

## Seams (owned by the program, mirrored here)

The deepening carries genuine open shaping decisions, surfaced to the Operator at the chapter body and re-surfaced at
each rung's pre-build reconcile (none is Venus's to decide): the **emq.4.3 boundary** (the park-don't-poll core is
shipped — what "founds a process/lease surface" means is the deepening's new surface, a fork); the **weighted-rotation
mechanism** (a deficit counter on the ring vs a weighted multi-pop vs a per-lane budget — a representation fork at
emq.4.4); the **intra-group priority dimension** (the canon-recorded non-zero lane score on the existing ZSET — a
`ZCOUNT` over a score window, no new key — whether it lands at emq.4.1 or parks past the chapter); and the
**re-assignment atomicity** (a single-queue lane move is one slot → atomic; a cross-queue move crosses a slot, so it
inherits the emq.3 cross-queue posture — honest, not atomic).

## Map

Delivery: the single consolidated [`emq.roadmap.md`](../emq.roadmap.md) (the emq.4 row · Movement II). The chapter:
[`emq.4/emq.4.md`](emq.4/emq.4.md) (authoritative) · [`emq.4/emq.4.stories.md`](emq.4/emq.4.stories.md). The lines beneath: [`emq.streams.md`](../emq.streams.md) (the stream
tier) · [`emq.2.specs.md`](emq.2.specs.md) (the parity floor). The as-built record this chapter deepens:
`echo/apps/echo_mq/lib/echo_mq/{lanes,metrics,consumer}.ex` + `jobs.ex` (`@reap`). The v1 capability reference (the
re-aim record, READ-ONLY): [`emq.commands/features/groups/`](emq.commands/features/groups/).
