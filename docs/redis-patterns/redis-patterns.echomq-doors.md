# The redis-patterns ↔ EchoMQ door map — canonical, bidirectional

> The single source of truth for how the **Redis Patterns Applied** course (`/redis-patterns`, chapters R0–R8) and
> the dedicated **EchoMQ, In Depth** course (`/echomq`, the **six-pillar** spine) link to each other. Every
> `→ EchoMQ` door in a redis-patterns chapter and every `← redis-patterns` reverse-link in an EchoMQ chapter
> resolves through this table. Cited by `docs/redis-patterns/redis-patterns.roadmap.md` (the R-side door column).
> When the two drift, this file wins; fix both spec systems to it.

## What a "door" is (and is not)

- A **door** is a one-way teaching hand-off: redis-patterns teaches a transferable Redis **pattern** and proves it
  with one real excerpt, then doors forward to the EchoMQ pillar that teaches the **system** which applies it in
  depth. A door is NOT the same as **grounding**: a chapter can ground in **codemojex** (the worked consumer — a
  Telegram emoji-guessing game on the same stack) yet door to an EchoMQ pillar (R1 caching grounds in codemojex's
  round/set cache but doors to the **Cache** pillar, EchoMQ's real near-cache, EchoStore).
- The map is **bidirectional and must agree**: if `R → E` lists a door, the matching `E ← R` reverse-link must list
  it, and vice versa. A door with a reverse but no forward (or the reverse) is a drift to fix.
- A door must be **content-honest**: it points at the pillar whose subject actually receives that R-pattern, not at
  a coarse pair. (This file exists because a prior coarse pairing once sent R4 — time & priority — at the near-cache
  chapter with no time/priority content. The honest R3 **and** R4 door is the **Queue** pillar `/echomq/queue` —
  which absorbed the old lifecycle/groups/batches chapters — plus `/echo-persistence` at the durability frontier.)

## The EchoMQ pillars (what each one teaches — the door targets)

> **⚠ Six-pillar spine (current).** The EchoMQ course is organised into **six pillars** — **Overview**, a shared
> **Protocol**, the **Queue**, the **Bus**, the **Cache**, and **Proof**. The retired fine-grained E0–E8 chapters
> (core · groups · batches · lifecycle · substrate · production) are **absorbed into these pillars**; their old
> routes (`/echomq/{core,substrate,groups,batches,lifecycle,production}`) **no longer exist** (the orphaned `core/`
> and `substrate/` legacy trees were retired 2026-06-25). **🏁 ALL SIX PILLARS BUILT (2026-06-25) — the EchoMQ course
> is COMPLETE:** Overview · Protocol · Queue · Bus · Cache · Proof. (The only `soon` card left course-wide is the
> Proof pillar's **Benchmark** — a named frontier with no surface on disk.)

| Pillar · route | Built? | Teaches (the door's subject) |
|---|---|---|
| **Overview** · `/echomq/overview` | built | the three-pillar orientation, the protocol below the line, the door from redis-patterns |
| **Protocol** · `/echomq/protocol` | built | the `emq:{q}:*` key taxonomy + job hash (the data layer), the atomic Lua + EVALSHA dispatch, the owned-keyspace / declared-keys discipline, the version fence (`@wire_version "echomq:3.0.0"`), and the immutability + branded-id contract (absorbs the old "substrate" break) |
| **Queue** · `/echomq/queue` | built | the pending/active/dead lifecycle + `@claim` lease, stalled recovery, the `:schedule`/`@promote` machinery, `EchoMQ.Repeat`, backoff-retry, fair lanes, groups, batches, lifecycle controls (absorbs the old core/groups/batches/lifecycle chapters) |
| **Bus** · `/echomq/bus` | **built — COMPLETE (landing + 01 the-events-channel · 02 the-stream-log · 03 the-consumer-group · 04 time-travel · 05 retention-and-archive + the workshop)** | the broker surface above the queue — pub/sub events, the retained replayable event log, consumer groups, time-travel, the archive → `/echo-persistence` |
| **Cache** · `/echomq/cache` | **built — COMPLETE (landing + 01 cache-aside-two-layers · 02 single-flight-and-jittered-ttl · 03 coherence + the workshop)** | EchoStore — the L1 ETS / L2 Valkey cache-aside near-cache: branded-Snowflake keyed, single-flight, jittered TTL, version-guarded, bus-coherent (the two coherence lanes + `newer?/2` + `CLIENT TRACKING`) → `/echo-persistence` (the journal's durable floor) |
| **Proof** · `/echomq/proof` | **built — COMPLETE (landing + 01 the-conformance-suite · 02 telemetry-and-the-read-plane + the workshop; Benchmark = `soon` frontier)** | the conformance suite (`EchoMQ.Conformance`), the `:telemetry` surface (`EchoMQ.Meter`) + the read plane (`EchoMQ.Metrics`); the benchmark is the named frontier (no surface on disk) |

## R → E (the forward doors — what each redis-patterns chapter opens onto)

| R chapter | Doors to | Why (content) |
|---|---|---|
| **R0** Overview | **Protocol** (via R0.3), **Protocol** (via R0.2) | R0.3 "patterns become protocol" → the Protocol pillar's data/dispatch layer; R0.2 "Valkey under codemojex" (the facade seam, the reserved tier) → the same owned keyspace + version fence (the old "substrate" subject now lives in Protocol) |
| **R1** Caching | **Cache** (`/echomq/cache`, **built: landing + 01–03 + the workshop**) | the cache-aside / write-through / stampede / session patterns → EchoStore, the real L1/L2 cache-aside near-cache (door only — R1 grounds in codemojex's round/set cache). The Cache pillar is served and the R1 retarget is **DONE** (2026-06-25): the two `.door` CTAs (chapter landing + workshop) + every per-page see-also link + inline pointer now point at `/echomq/cache` (EchoStore-honest), across the served HTML and the route-mirror md; the footer course-nav stays at the bare hub |
| **R2** Coordination | **Protocol** (`/echomq/protocol`) | atomic-updates + locks → the Protocol pillar's atomic Lua/EVALSHA protocol and the owned-keyspace seam the locks stand on |
| **R3** Reliable Queues | **Queue** (`/echomq/queue`) + **`/echo-persistence`** | the pending/active/dead lifecycle, the `@claim` lease, stalled recovery → the Queue pillar's claim path; a stalled / dead-lettered job → `/echo-persistence` (the durable floor: `EchoStore.StreamArchive` → `EchoStore.Graft` → Tigris) |
| **R4** Time, Delay & Priority | **Queue** (`/echomq/queue`) + **`/echo-persistence`** | the `:schedule` ZSET / `@promote` sweep, the `EchoMQ.Repeat` cadence, backoff-retry, and the fair-lane weights that *replace* numeric priority → the Queue pillar; a scheduled / archived job at the durability frontier → `/echo-persistence` |
| **R5** Streams & Events | **Bus** (built), **Cache** (built) | the pub/sub events + the retained, replayable log → the Bus pillar (built this run); version-guarded fills kept coherent by bus invalidations → the Cache pillar's coherence |
| **R6** Flow Control & Scale | **Queue** (`/echomq/queue`) | rate-limiting / groups / multi-tenant fairness + batches & pipelining → the Queue pillar (which absorbed the old groups/batches chapters) |
| **R7** Data Modeling & Memory | **Protocol** (secondary) | "Redis as a primary database" (R7.01) + memory-optimization (R7.02) ground in EchoMQ's job HASH + compressed fields = the Protocol pillar's data layer (R7's primary grounding is codemojex read-models, so this door is secondary) |
| **R8** Production & Operations | **Proof** (soon, capstone) | operating the tier at scale → the Proof pillar's conformance suite, telemetry catalog, and benchmark gate — the capstone hand-off |

## E → R (the reverse doors — which redis-patterns chapters open onto each pillar)

| Pillar | Opened from | Why (content) |
|---|---|---|
| **Protocol** (`/echomq/protocol`) | **R0.2**, **R0.3**, **R2**, **R7** (secondary) | patterns-become-protocol; the facade/reserved-tier seam (old "substrate"); the atomic Lua/EVALSHA; the job-hash data model |
| **Queue** (`/echomq/queue`) | **R3**, **R4**, **R6** | the reliable-queue lifecycle + claim path (R3); the `:schedule`/`@promote`/`EchoMQ.Repeat`/fair-lane machinery (R4); fairness, groups, batches, rate-limit (R6) |
| **`/echo-persistence`** (durability frontier) | **R3**, **R4** | a stalled / dead-lettered job (R3) and a scheduled / archived job (R4) fold to the durable floor: `EchoStore.StreamArchive` → `EchoStore.Graft` (CubDB) → Tigris |
| **Bus** (`/echomq/bus`, **built**) | **R5** | the pub/sub events + the retained, replayable event log |
| **Cache** (`/echomq/cache`, **built: landing + 01–03 + the workshop**) | **R1**, **R5** | the cache-aside near-cache (R1); bus-coherent invalidation (R5) |
| **Proof** (`/echomq/proof`, **built**) | **R8** | operating the tier in production is the Proof pillar's subject |

## The matching /bcs doors (the manuscript the patterns are drawn from)

Each R-chapter also doors to its **Branded Component System** manuscript chapter (`/bcs`, the source the EchoMQ +
EchoStore figures are quoted from). These are content-honest and **served today**:

| R chapter | /bcs door | Why |
|---|---|---|
| **R1** Caching | `/bcs/cache` (+ `/bcs/store`) | EchoStore, the near-cache + the store |
| **R2** Coordination | `/bcs/bus` | the EchoMQ bus protocol the atomic-Lua / lock patterns prove |
| **R3** Reliable Queues | `/bcs/bus` | the bus the reliable-queue lifecycle is built on |
| **R4** Time, Delay & Priority | `/bcs/persistence` (+ `/bcs/bus`) | the durable floor a scheduled/archived job folds to |

> R5–R8 carry their `/bcs` doors when those chapters are next reconciled (natural targets: R5/R6 → `/bcs/bus`,
> R7 → `/bcs/store`, R8 → `/bcs/together` or `/bcs/codemojex`).

## The consistency invariant

Every R↔E edge appears in BOTH tables. Reading them as a set of edges:

```
R0.2─Protocol  R0.3─Protocol  R1─Cache  R2─Protocol  R3─Queue  R3─/echo-persistence
R4─Queue  R4─/echo-persistence  R5─Bus  R5─Cache  R6─Queue  R7─Protocol  R8─Proof
```

- Every R-chapter except **R7** carries a first-class `→ EchoMQ` door; R7's Protocol door is **secondary** (its
  primary grounding is codemojex read-models).
- The bare `/echomq` home is always an accepted door from any chapter (the R2.06/R3.06 workshop precedent).
- A door to a **soon** pillar (Bus/Cache/Proof) is not yet served, so a built redis-patterns door page that points
  at one carries the intended `links`-gate behaviour by design (the manifest forward-link rule); the HONESTY of the
  door — does it point at the right pillar — is what this file governs, not resolvability.

## History — deltas corrected

**2026-06-25 (the R1 → Cache retarget lands).** With the Cache pillar served, **every** EchoMQ teaching link in
R1 Caching was retargeted off the bare `/echomq` hub (and the interim `/echomq/queue` framing) to `/echomq/cache`,
EchoStore-honest: the two `.door` CTAs (the chapter landing + the workshop), all 25 per-page "Related" see-also
links, and the inline pointers — across both the served HTML and the route-mirror md (31 links each side). The
site-footer "EchoMQ — the protocol" course-nav link stays at the bare `/echomq` hub (line 92). The roadmap's R1
Door cell + prose were synced (E7 → the Cache pillar). R1's first-class door is now content-honest and resolvable.

**2026-06-25 (the Cache pillar lands).** The **Cache** pillar is served: the landing + modules
**01 `cache-aside-two-layers`** + **02 `single-flight-and-jittered-ttl`** built (the real `EchoStore` near-cache at
`/echomq/cache`, grounded in `echo/apps/echo_store`). The R1 + R5 reverse-doors into the Cache now resolve; the R1
`.door` retarget from the Queue pillar (noted 2026-06-15) is **unblocked** (a redis-side reconcile). Coherence
(module 03) + the workshop shipped 2026-06-25; the Cache pillar is now COMPLETE.

**2026-06-25 (the BCS-direction reconcile).** Remapped the whole file from the retired E0–E8 numbering to the
six-pillar spine; **Portal → codemojex** throughout (the worked consumer pivoted); removed every reference to the
retired `/echomq/{core,substrate,groups,batches,lifecycle,production}` routes (the orphaned `core/`/`substrate/`
legacy trees were retired the same day); folded the old E3 "substrate" subject into **Protocol**; added the matching
`/bcs` door table; pinned the version fence to the as-shipped `echomq:3.0.0`.

**2026-06-23.** R2's `.door` CTA + per-page "Related" EchoMQ link doored to the Protocol pillar (`/echomq/protocol`,
built) — the atomic-Lua/EVALSHA protocol the coordination patterns prove. (Its `/bcs` door was sharpened from the
bare `/bcs` root to `/bcs/bus` on 2026-06-25.)

**2026-06-15.** R1's `.door` CTAs were retargeted from the bare `/echomq` home to the **Queue** pillar (the fair
lanes the coherence/write-behind lane rides); the EchoStore concept is doored to `/bcs/cache`. **Retarget when the
Cache pillar lands:** the cache-aside family's natural EchoMQ destination is the **Cache** pillar
(`/echomq/cache`) — retarget the R1 door there once it is served.

**2026-06-08.** Corrected the dishonest R4 → near-cache pairing (the near-cache has no time/priority content);
recorded the R0.2 facade-seam door and the R1 → near-cache door; named the roadmap Door column's targets.
