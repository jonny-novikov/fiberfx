# EchoMQ, In Depth — course index

**Route:** `/echomq` · **Served from:** `html/echomq/` (folder-routed, wired live)

The index for **EchoMQ, In Depth** — the **internals of the Valkey-native job system you own**, canonical in
**Elixir**, and what they mean for the **BCS family of systems**. It is the far side of every `→ EchoMQ` door in
[Redis Patterns Applied](/redis-patterns). This file is the course's front matter — the structural authority every
batch builds against. The build status of the pages is [`echo_mq.course.progress.md`](./echo_mq.course.progress.md);
the program canon it grounds in is under [`../`](../) (`emq.design.md` / `emq.roadmap.md` / `emq3.specs.md`).

> **Supersedes the old "EchoMQ — the protocol, in depth, as it is built" index.** The two-movements split, the v1-line
> teaching, the three-state living-status, and all version framing are **retired** (see "What changed"). The course is
> now **one shipped system, three pillars**, taught Elixir-canonical, as shipped.

## One system, three pillars

EchoMQ is one Valkey-native, Branded-Component-System bus you own end to end — canonical in Elixir. Below the language
line sit the keys + the Lua scripts (the **protocol**); above it sit three product surfaces:

- **The Queue** — distribute work: enqueue · claim · retry · complete; one job, one worker; lanes, batches, lifecycle, flows.
- **The Bus** — broadcast signals: pub/sub events + a retained, replayable event log (consumer groups, time-travel, archive).
- **The Cache** — serve reads: an L1 ETS / L2 Valkey cache-aside near-cache, single-flight, jittered TTL, coherent on the Bus.

"Polyglot" is the **thesis** (the protocol lives below the language line, so any runtime that speaks it is a peer — EchoMQ
is *supported in / ported to* other runtimes), stated in one line on the Overview; the course teaches **Elixir, canonical**.

## The chapters — the six-section spine

| # | Chapter | Route | Grounding | Status |
|---|---|---|---|---|
| — | **Overview** — one system, three pillars, the protocol below the line | [`/echomq`](/echomq) + [`/echomq/overview`](/echomq/overview) | thesis (`echo_mq.md` + roadmap) | ✅ built |
| 1 | **The Protocol** — the substrate the pillars share | [`/echomq/protocol`](/echomq/protocol) | **real** — `EchoMQ.Keyspace` + the inline Lua | ✅ built |
| 2 | **The Queue** — distribute work | [`/echomq/queue`](/echomq/queue) | **real** — `EchoMQ.{Jobs,Lanes,Consumer,Cancel,Stalled,Flows}` | ✅ built |
| 3 | **The Bus** — broadcast signals + the event log | [`/echomq/bus`](/echomq/bus) | **mixed** — `EchoMQ.Events` real; the stream tier **canon** → `[RECONCILE]` | planned |
| 4 | **The Cache** — the branded near-cache | [`/echomq/cache`](/echomq/cache) | **real** — `EchoCache.{Table,Ring,Journal,Coherence}` | planned |
| 5 | **The Proof** — the system holds | [`/echomq/proof`](/echomq/proof) | **real** — `EchoMQ.{Conformance,Meter,Metrics}` (benchmark partial) | planned |

Three levels per chapter: **Section** landing (`<section>/index.html`) → **Module** hub (`<section>/<module>/index.html`,
≥3 dives) → **Dive**. Each chapter closes with a **workshop**. **Flows live in the Queue pillar** (orchestration is
composed work). `/echomq` is folder-routed, so new section dirs need no `main.go` change.

### The modules (the full map — Batch 1 builds Overview + The Protocol)

**Overview** (`/echomq`) — orientation, flat dives (no `.applied`): `the-three-pillars` · `the-protocol-below-the-line`
(the four layers as substrate) · `the-door` (the Redis-Patterns door + the BCS family + the living course).

**The Protocol** (`/echomq/protocol`) — the four-layer substrate, all real code:
`the-owned-keyspace` (`emq:{q}:`, the `{q}` hashtag, the `{emq}:` reserve, `slot/1` CRC16) · `the-record-hash` (the job
record + fields) · `the-lua-layer` (scripts ARE the protocol, EVALSHA, declared keys — two-beat Lua) ·
`immutability-and-branded-ids` (the immutable line + the 14-byte branded-id gate + the version fence) · `workshop`.

**The Queue** (`/echomq/queue`) — distribute work, all real code:
`the-lifecycle` (the state machine) · `jobs-lanes-consumer` (producer/worker + fair lanes/groups + the consumer loop) ·
`batches` (bulk consumption) · `lifecycle-controls` (TTL · cancel · checkpoints · stalled) · `flows` (orchestration:
parent/child, fan-in, cross-queue) · `workshop`.

**The Bus** (`/echomq/bus`) — broadcast signals; `pub-sub-events` real, the rest canon (`[RECONCILE]`):
`pub-sub-events` (the event seam; subscribe/publish — **real** `EchoMQ.Events`) · `the-event-log` (the retained,
replayable stream; append == mint order — **canon** `EchoMQ.Stream`) · `consumer-groups` (at-least-once; the polyglot
reader seam — **canon**) · `time-travel-and-archive` (retention; the archive under the cache's shadow; mint-instant
reads — **canon**) · `workshop`.

**The Cache** (`/echomq/cache`) — serve reads, all real code:
`cache-aside-two-layers` (L1 ETS / L2 Valkey — `EchoCache.Table`) · `single-flight-and-ttl` (single-flight fill;
jittered TTL) · `coherence-on-the-bus` (newer-wins; invalidation rides the Bus — `EchoCache.Coherence`/`Journal`) ·
`workshop`.

**The Proof** (`/echomq/proof`) — the system holds:
`the-conformance-suite` (the black-box scenarios — `EchoMQ.Conformance`) · `telemetry-and-tracing` (the event catalog;
OTel — `EchoMQ.Meter`/`Metrics`) · `the-benchmark-gate` (the honest benchmark — partial, some `[RECONCILE]`) · `workshop`.

> **Old dirs in transition.** `html/echomq/{core,substrate,groups,batches,lifecycle,production}` (old E2–E8) are
> **superseded** by the pillar sections and survive on disk only until each pillar chapter is built. `overview/` +
> `protocol/` are **rebuilt in place** (Batch 1). `cache/` carries over to the Cache pillar.

## The grounding model — real code or design canon, never past either

- **Real code** — `echo/apps/echo_mq` + `echo/apps/echo_wire` + `echo/apps/echo_cache` — for the Protocol, the Queue,
  the Cache, and the Bus's **pub/sub events**: the real Lua/key/field/module fn with its **verified arity** (verified by
  reading the file; **never printed as a `file:line`**), present tense.
- **Design canon** — `emq.roadmap.md` §"EchoMQ 3.x — the stream tier" + `emq3.specs.md` + `emq.design.md` — for the
  Bus's **streams / event log** (the verbs, `EchoMQ.Stream`, retention, the archive under a shadow, time-travel), which
  is **specified but not yet on disk** (upstream work). Taught **as shipped** in the HTML; each canon-grounded claim
  carries a **`[RECONCILE]`** marker in the md shadow.
- **Never the frozen tree** `echo/apps/echomq` (no underscore) — it is unrelated to this course; cite it nowhere.

## The output layout (under `docs/echo_mq/course/`)

| Path | What |
|---|---|
| `echo_mq.course.md` | this index — the structural authority |
| `echo_mq.course.progress.md` | the build dashboard + the **`[RECONCILE]` ledger index** (the iteration-2 worklist) |
| `markdown/<route>.md` | the **route-mirror md** — the md-first source-of-record the HTML reflects, and where the **`[RECONCILE]` shadow** lives (the served route minus `/echomq/`, `.md` appended) |
| `<chapter>.prompt.md` | the **persistent fan-out brief** per chapter (the orchestrator authors it before fan-out; subagents read their `## MODULE` section) |

**The binding output rules:** (1) a route-mirror md per page, carrying the `[RECONCILE]` markers; (2) the HTML reads as
shipped and **never contains a `[RECONCILE]` marker**. (The old "every code block also a decoded examples/ file" rule is
**retired** — the on-page extract-and-annotate block is now the canonical extractable form.)

## The redis-patterns door (bidirectional)
This course is the far side of every `→ EchoMQ` door in `/redis-patterns`, governed by
[`redis-patterns.echomq-doors.md`](../../redis-patterns/redis-patterns.echomq-doors.md) (when a page and the map
disagree, the map wins). Doors resolve to the **named pillar routes** (e.g. R1 caching → `/echomq/cache`). A section
landing carries the `.applied` "Redis Patterns Applied" reverse-door block (the Overview landing + home do not).

## Identity & authoring
The course renders in the jonnify **dark-editorial** design system (dark ink, cream text, a scoped EchoMQ teal accent)
— never the redis/BCS contract-sheet identity. Author with the **`echo-mq-writer`** skill + the **`echo-mq-expert`**
agent; build/rebuild a chapter with **`/echo-mq-reconcile`** (wipe + rebuild to target) or **`/echo-mq-write`**
(greenfield), each driven by a persistent `<chapter>.prompt.md`. The four authoring disciplines: **as-shipped (no
versions) · extract-and-annotate code (two-beat Lua, no `file:line`) · the `[RECONCILE]` md shadow · no-invent**
(real-code-or-canon, never the frozen tree).

## What changed (the pivot)
- **Retired:** the two-movements split; teaching the frozen v1 line as a subject; the three-state living-status; all
  version framing ("EchoMQ 2.0", "the break", "1.3.0", "as it is built"); the `.fork` callout; the E0–E8 ⇄ `emq.N`
  chapter map; the `examples/` decoded-file rule.
- **New:** one system, three pillars (Queue/Bus/Cache) + Overview/Protocol/Proof; named pillar routes; as-shipped
  voice; extract-and-annotate code; the `[RECONCILE]` md shadow; the per-chapter persistent prompt.
- **Kept:** dark-editorial design; the shared craft (`elixir-technical-writer/references/`); no-invent; two-column
  References; md-first source-of-record; the redis-patterns door; never run git.
