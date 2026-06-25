# EchoMQ, In Depth — course map

> **⚠ BCS CALIBRATION (2026-06-25) — defer to `bcs-writer` on the cross-cutting facts below.** The new manuscript
> `docs/echo/bcs/bcs.N.md` re-pointed surfaces this digest still names the old way. Read every **`EchoCache.*` /
> `echo/apps/echo_cache`** (the grounding-map rows, the Cache pillar) as **`EchoStore.*` / `echo/apps/echo_store`**
> (renamed 2026-06-18, 1:1), and the bus consumer **`Exchange.{Gateway,OrderBook,Decider}`** (`echo/apps/exchange`,
> deleted) as **`codemojex` / `echo/apps/codemojex`** (manuscript B7). The figure source moved from
> `docs/echo/bcs/content/bcsN.*` (retired) to `docs/echo/bcs/bcs.N.md`; a new **persistence floor** + the
> **`/echo-persistence`** door also apply. The **Protocol** pillar (`/echomq/protocol`) carries the refined branded-id
> canon on the immutability contract; the **Queue** pillar (`/echomq/queue`) opens the **`/echo-persistence`** door on
> its durability-frontier pages (stalled / dead-lettered / archived jobs → `EchoStore.StreamArchive` → `EchoStore.Graft`
> → Tigris). Authority: the **`bcs-writer`** skill; the page reconcile is **`/bcs-reconcile E<N>`**.

The course **"EchoMQ, In Depth"** is served at **`/echomq`** (folder-routed via `serveDirTree`; **wired live** in
`main.go` — `/echomq` + `/echomq/*`, `ECHOMQ_DIR`, default `/app/html/echomq`; the URL tree mirrors `html/echomq/`,
a new `.html` is live on save). It teaches the **internals of the Valkey-native job system you own** — canonical in
**Elixir** — and what those internals mean for the **BCS family of systems**. The **home** (`html/echomq/index.html`)
and **every chapter landing** are **route manifests**: they forward-link pages not yet built (the `soon` pill), so
those forward-links FAIL the `links` gate **by design on the home and landings only**; every lesson/hub page must keep
all internal links resolving.

> **This digest supersedes the old "EchoMQ — the protocol, in depth, as it is built" map.** The two-movements split,
> the v1-line teaching, the three-state living-status, and all version framing are **retired** (see §"What changed").

## 1. Identity — one system, three pillars, taught as shipped

EchoMQ is **one system**: a Valkey-native, Branded-Component-System bus you own end to end, canonical in **Elixir**.
The course teaches it through Elixir's implementation, and presents it **as a shipped product** — no version numbers,
no "tracked as it is built", no live build-status. Above one owned wire sit **three pillars**:

| Pillar | One line | Route |
|---|---|---|
| **The Queue** | distribute work — enqueue · claim · retry · complete; one job, one worker; lanes, batches, lifecycle, flows | `/echomq/queue` |
| **The Bus** | broadcast signals — pub/sub events + a retained, replayable event log (consumer groups, time-travel, archive) | `/echomq/bus` |
| **The Cache** | serve reads — an L1/L2 cache-aside near-cache, single-flight, jittered TTL, coherent on the Bus | `/echomq/cache` |

**"Polyglot" is the thesis, not the syllabus.** Because the protocol lives **below the language line** (the keys + the
Lua scripts), any runtime that speaks it is a peer — so EchoMQ is **supported in / ported to** other runtimes. State
that in **one line** where it belongs (the overview); never teach a per-runtime port, never badge maturity, never
invent a runtime's status. The course's depth is **Elixir, canonical**.

Rendered in the **jonnify dark-editorial design system** (dark ink, cream text, gold/blue house accents + a scoped
EchoMQ teal token) — **never** the redis/BCS contract-sheet identity.

## 2. The structure — six sections, the three-pillar spine

Routes are **named by section** (route-rename authority granted). `/echomq` is folder-routed, so new section dirs need
**no `main.go` change** — only the dirs.

| Section | Route | Teaches | Grounded in |
|---|---|---|---|
| **Overview** | `/echomq` (home + `/echomq/overview`) | one system; the three pillars; the protocol below the line (why it's polyglot + coherent); Elixir-canonical; the Redis-Patterns door; the BCS-family implications | `echo_mq.md` + `emq.roadmap.md` (thesis) |
| **The Protocol** | `/echomq/protocol` | the substrate all three pillars share: the owned keyspace `emq:{q}:`, the `{q}` hashtag, the `{emq}:` reserve; the record/job hash & fields; the Lua layer & EVALSHA (*scripts ARE the protocol*); immutability + branded ids (the 14-byte gate) | `EchoMQ.Keyspace` + the inline `EchoMQ.Script.new/2` Lua — **real code** |
| **The Queue** | `/echomq/queue` | distribute work: the lifecycle/state machine; jobs · lanes · consumer; fair lanes/groups; batches; lifecycle controls (TTL/cancel/checkpoints); **flows** (orchestration) | `EchoMQ.{Jobs,Lanes,Consumer,Cancel,Stalled,Backoff,Repeat,Flows}` — **real code** |
| **The Bus** | `/echomq/bus` | broadcast signals: pub/sub events; the retained replayable event log/streams; consumer groups + at-least-once; time-travel & the archive | `EchoMQ.Events` (**real code**) + the stream-tier **canon** (`emq.roadmap.md` §stream tier, `emq3.specs.md`) → **`[RECONCILE]`-shadowed** |
| **The Cache** | `/echomq/cache` | serve reads: cache-aside two layers (L1 ETS / L2 Valkey); single-flight + jittered TTL; coherence — newer wins on the Bus | `EchoCache.{Table,Ring,Journal,Coherence,Keyspace,Shadow}` — **real code** |
| **The Proof** | `/echomq/proof` | the whole system holds: the conformance suite; telemetry & tracing; the benchmark gate | `EchoMQ.{Conformance,Meter,Metrics}` — **real code** (benchmark partial) |

Three levels per section: **Section** landing (`<section>/index.html`) → **Module** hub (`<section>/<module>/index.html`,
≥3 dives) → **Dive** (`<section>/<module>/<sub>.html`). Each section closes with a **workshop**. The Overview is the
orientation chapter (home `/echomq` + `/echomq/overview` + dives). **Flows live in the Queue pillar** (orchestration is
composed work), not the Bus.

> **Old routes in transition.** The pre-wipe dirs `html/echomq/{core,substrate,groups,batches,lifecycle,production}`
> (old E2–E8) are **superseded** by the pillar sections. They survive on disk until their pillar chapter is built;
> the content-map marks them transitional so nothing reads as current. `overview/` and `protocol/` are **rebuilt in
> place** (Batch 1). `cache/` carries over to the Cache pillar.

## 3. The grounding — real code where it exists, design canon where it doesn't

**The single source of truth is the program canon `docs/echo_mq/`** + the **as-built code** in `echo/apps/`. The
course OUTPUT lives under **`docs/echo_mq/course/`** — `echo_mq.course.md` (the content-map/TOC), `markdown/<route>.md`
(the route-mirror **source-of-record** — this is where the **`[RECONCILE]` shadow** lives), `echo_mq.course.progress.md`
(the dashboard + the `[RECONCILE]` ledger index), and the per-chapter **`<chapter>.prompt.md`** fan-out briefs.

| Canon / code | Role for the course |
|---|---|
| [`docs/echo_mq/emq.roadmap.md`](../../../../docs/echo_mq/emq.roadmap.md) | the program map + the **3.x stream-tier canon** (§"EchoMQ 3.x — the stream tier": the verbs, `EchoMQ.Stream`, retention, the archive under a shadow, time-travel) — the **Bus pillar's grounding where code is not yet on disk**. |
| [`docs/echo_mq/emq.design.md`](../../../../docs/echo_mq/emq.design.md) | the binding design — the master invariant (grammar-total braced `emq:{q}:`, the `{emq}:` reserve, declared-or-rooted Lua keys, the version fence) + the laws. The canon a not-yet-coded surface is taught from. |
| [`docs/echo_mq/emq3.specs.md`](../../../../docs/echo_mq/emq3.specs.md) | the **stream-tier specification** (S1 writer · S2 readers · S3 memory; `emq3.1`–`emq3.6`). The Bus's deep grounding. |
| [`docs/echo_mq/emq.progress.md`](../../../../docs/echo_mq/emq.progress.md) · `echo_mq.md` · `emq.references.md` | the as-built dashboard, the program front door, the references. |
| **`echo/apps/echo_mq`** | **THE convergence target — the canonical bus.** Cite this and nothing else for the Queue/Protocol/Proof + the Bus's pub/sub. |
| **`echo/apps/echo_wire`** | the wire facade — `EchoMQ.{Connector, Script, RESP}` under `EchoWire`. The EVALSHA-first executor, the version fence. |
| **`echo/apps/echo_cache`** | the near-cache — `EchoCache.*`. The Cache pillar. |

### 3a. The one-way grounding guard (the old "trap", simplified)
There is a **frozen, unrelated** tree `echo/apps/echomq` (no underscore) — the old BullMQ-wire line (`EchoMQ.Keys`,
`LockManager`, `Scripts`, `Worker`, `moveToActive`). **It is NOT part of this course.** Ground every page in
`echo/apps/echo_mq` / `echo_wire` / `echo_cache` (underscore) and **never cite the frozen tree.** The scrub
`grep -E 'echo/apps/echomq\b|EchoMQ\.Keys\b|EchoMQ\.LockManager|EchoMQ\.Scripts|moveToActive|EchoMQ\.Worker'` must be
**0 on every page**.

### 3b. The real surfaces (verify arity in the file before citing — never on the page)
- **Protocol** — `EchoMQ.Keyspace.queue_key/2` → `emq:{q}:<type>`, `job_key/2`, `version_key/0` (`{emq}:version`),
  `slot/1`/`hashtag/1` (CRC16-XMODEM % 16384, vector `slot("123456789") == 12739`), `reserve/1`; the inline
  `EchoMQ.Script.new/2` Lua (SHA1-precomputed, declared keys), run EVALSHA-first by `EchoMQ.Connector.eval/5`; the
  branded-id 14-byte gate (`EMQKIND`).
- **Queue** — `EchoMQ.Jobs.{enqueue/4, enqueue_at/5, enqueue_in/5, enqueue_many/3, claim/3, complete/4‑5, retry/7,
  extend_lock/5}`; the operator verbs **live in `EchoMQ.Jobs`** (`update_data/4, update_progress/4, add_log/4‑5,
  remove_job/3‑4, reprocess_job/3`); `EchoMQ.Admin.{pause/2, resume/2, drain/2‑3, obliterate/2‑3}` (queue-wide only);
  `EchoMQ.Lanes.{enqueue/5, claim/3, pause/3, resume/3, limit/4, depth/3}`; `EchoMQ.Consumer` (`:lease_ms` 30_000);
  `EchoMQ.{Cancel, Stalled, Backoff, Repeat}`; `EchoMQ.Flows.{add/3, children_values/3, dependencies/3, complete/5}`.
- **Bus** — **real:** `EchoMQ.Events.{subscribe/2, unsubscribe/2, publish/5, channel/1, close/2}` (pub/sub over
  `emq:{queue}:events`). **canon (→ `[RECONCILE]`):** the stream verbs `XADD/XRANGE/XREADGROUP/XACK/XAUTOCLAIM`,
  `EchoMQ.Stream` (append == mint order), retention (`MAXLEN`/`MINID`), the archive under `EchoCache.Shadow`,
  time-travel by mint instant — all from `emq.roadmap.md` §stream tier + `emq3.specs.md`.
- **Cache** — `EchoCache.Table.{fetch/3, put/3‑4, invalidate/3, stats/1}` (+ `launch_flight`); `EchoCache.Journal.{intend_and_enqueue/4, record/4}`;
  `EchoCache.Coherence.newer?/2`; `EchoCache.Keyspace.key/2` → `ecc:{<table>}:<id>`; `EchoCache.{Ring, Shadow, Litestream}`.
- **Proof** — `EchoMQ.Conformance.run/2` (the scenario suite); `EchoMQ.Meter.{attach/4, attach_many/4, emit/3}` (the
  telemetry surface — **`Meter`, there is no `EchoMQ.Telemetry` module**); `EchoMQ.Metrics.*` (the read plane).
- The named consumer for "who drains the bus" is `Exchange.{Gateway, OrderBook, Decider}` (`echo/apps/exchange`).

## 4. The authoring model — four disciplines (the heart of the new course)

1. **As-shipped, no versions.** Present tense, one system. **No "2.0 / 3.0"** as a label in prose; no "tracked as it
   is built". A real wire constant inside a code extract (e.g. the `{emq}:version` value) is fine as code — never as
   the course's framing.
2. **Extract-and-annotate code, no `file:line`.** Lift the atomic **Elixir** fn onto the page as a code block with
   *added teaching comments* (the real code, commented to explain the idea). **Lua in two beats:** first the named
   handle (e.g. `EchoMQ.Jobs @enqueue`), then a **separate** Lua block with the real script body
   (`if string.sub(ARGV[1],1,3) == kind then …`), deeply commented — the branded-id gate, the `KEYS`/`ARGV` contract,
   the atomic transition. **Never print a `file:line` citation on a page.**
3. **The `[RECONCILE]` shadow.** The md source-of-record (`docs/echo_mq/course/markdown/<route>.md`) carries an inline
   **`[RECONCILE: …]`** marker at every claim that is **ahead of the as-built code** — chiefly the Bus/streams depth
   (grounded in canon, not yet in `echo/apps/echo_mq`) and any internal that cannot yet be written precisely. **The
   HTML reader never sees a `[RECONCILE]` marker.** These markers are the iteration-2 worklist (swept when the upstream
   stream tier lands).
4. **No-invent (still load-bearing).** "As shipped" grounds in **real code** where it exists (Protocol, Queue, Cache,
   the Bus's pub/sub) and in the **design canon** where it doesn't (the Bus's streams). **Never past either.** A
   surface that is neither in code nor in canon is fabrication — omit it, or write it provisionally and mark
   `[RECONCILE]`. Never invent a key, script, field, module, or arity.

## 5. The persistent prompt mechanism — one `[chapter].prompt.md` per chapter

The orchestrator authors a durable per-chapter brief **before** fan-out, then points each subagent at its section
(rather than an ephemeral inline brief). Locations: `docs/echo_mq/course/<chapter>.prompt.md` (echomq) ·
`docs/redis-patterns/specs/<chapter>/<chapter>.prompt.md` (redis). Skeleton: status blockquote (who reads it + HOW;
"FRESH BUILD to target — wipe old internals") → the thesis in one paragraph → **Shared context** (chapter/routes/dirs;
the as-built **floor** — every surface this chapter teaches, verified on disk with the author's grounding, **MATCH**
(real) or **CANON** (spec → `[RECONCILE]`); the four disciplines; the model page; sources; the resolving cross-course
doors; the gate command; hard constraints) → one **`## MODULE`** section per fan-out target (Directive + Gate) →
**Acceptance** → **Inputs**. Each subagent reads the content-map + this brief's Shared context + its own `## MODULE`
section.

## 6. The redis-patterns door (bidirectional)
This course is the far side of every `→ EchoMQ` door in `/redis-patterns`. The canonical edge table is
`docs/redis-patterns/redis-patterns.echomq-doors.md` (R ↔ E); when a page and the map disagree, the map wins. As the
pillars land, the doors re-point to the **named pillar routes** (e.g. **R1 caching → `/echomq/cache`**). A chapter
landing carries the **`.applied` "Redis Patterns Applied"** reverse-door block naming the R-chapters that door into
it — **link only a BUILT redis-patterns chapter; `<strong>`-name an unbuilt one.**

## 7. The gate
Build the validator (`cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .`), then on every page:
```bash
apps/jonnify-cms/bin/cms check \
  --routes-from /echomq=html/echomq \
  --routes-from /redis-patterns=html/redis-patterns \
  --routes-from /elixir=elixir --routes-from /bcs=html/bcs \
  --require-refs html/echomq/<path>.html
```
Ship only at **STATUS: PASS**. Gate-invisible checks (verify by reading): clamp spacing; the segmented route-tag; the
no-version scrub (no "2.0/3.0" label in prose); **no `file:line` in any code block**; every Lua block paired with a
named handle; the §3a frozen-tree scrub → 0; every `EchoMQ.*`/`EchoCache.*` re-found in **code or canon** (canon-only ⇒
`[RECONCILE]` present in the md mirror); **zero `[RECONCILE]` leak into HTML**.

## 8. What changed (from the retired model)
- **Retired:** the two-movements split (Movement I / II); teaching the frozen v1 line (`echo/apps/echomq`) as a
  subject; the three-state living-status (shipped/specced/planned voice); all version framing ("EchoMQ 2.0", "the
  break", "1.3.0", "as it is built"); the `.fork` "2.0 break" callout; the E0–E8 ⇄ `emq.N` chapter map.
- **New:** one system, three pillars (Queue/Bus/Cache) + Overview/Protocol/Proof; named pillar routes; as-shipped
  voice; extract-and-annotate code (two-beat Lua, no `file:line`); the `[RECONCILE]` md shadow; the per-chapter
  persistent prompt; the one-way frozen-tree guard (§3a).
- **Kept:** dark-editorial design system; the shared craft (`elixir-technical-writer/references/`); no-invent;
  two-column References; md-first source-of-record; the redis-patterns door; never run git.

## 9. Resume point
**Batch 1** builds the **Overview** + **The Protocol** (fresh, to this target), redesigns the content-map to the spine
above, and reconciles redis **R1 caching** (door → `/echomq/cache`). **Forward program:** The Queue, The Bus (the big
new construction — `Events` real + the stream tier canon, `[RECONCILE]`-heavy), The Cache, The Proof — each via its own
`<chapter>.prompt.md`; then redis R2–R8 second-pass. **Iteration 2** sweeps the `[RECONCILE]` ledger against the
shipped upstream stream tier.
