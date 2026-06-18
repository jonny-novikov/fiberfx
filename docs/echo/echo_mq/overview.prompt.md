# Overview · EchoMQ, In Depth — chapter fan-out brief (persistent prompt)

> **Who reads this & how.** One `echo-mq-expert` builds ONE dive from its `## MODULE` section below. Read the
> **`echo-mq-writer`** skill first, then this brief's **Shared context (every module)**, then your `## MODULE` section,
> then the **model page** for the shell. This is a **FRESH BUILD to the target** — the Overview is being rebuilt to the
> new three-pillar identity. Copy only the **design-system shell** from the model; author all `<main>` content fresh.
> **Do NOT re-skin** (it is and stays dark-editorial). Engine: `/echo-mq-reconcile overview`. Agent: `echo-mq-expert`.
> Skill: `echo-mq-writer`. Canon: `docs/echo_mq/` + the as-built `echo/apps/echo_mq` (+ `echo_wire`, `echo_store`).

## The thesis in one paragraph

EchoMQ is **one Valkey-native job system you own, canonical in Elixir**. Its keys and Lua scripts are the protocol;
above that line stand **three pillars** — the **Queue** (distribute work), the **Bus** (broadcast signals + a retained,
replayable event log), and the **Cache** (serve reads). The Overview is the orientation chapter: it introduces the
three pillars, the protocol-below-the-line that makes them polyglot and coherent, and the door to/from
`/redis-patterns` + the BCS family. **No version numbers; as shipped; Elixir-canonical.**

## Shared context (every module)

- **Chapter:** Overview · **route:** `/echomq/overview` · **dir:** `html/echomq/overview/` · **md mirror root:**
  `docs/echo_mq/course/markdown/overview/`.
- **The dives (this chapter, flat — no module hubs):** `the-three-pillars` · `the-protocol-below-the-line` · `the-door`
  (the served routes `/echomq/overview/<slug>`). Each is a full dive page.
- **The model page (shell only):** `html/echomq/overview/the-four-layers.html` — a built dark-editorial dive. **Copy
  its `<head>`…`</style>`, `<header class="site">`, `<footer class="site-foot">`, and the trailing `<script>` blocks
  verbatim** (the design system + the stamp decoder + the reveal script), then **author all `<main>` content fresh** to
  your section. Carry over **none** of its prose (it is the retired model — versioned, BullMQ-framed, four-layers-led).
  Keep the footer EXACTLY as the rebuilt landing's footer (see `html/echomq/overview/index.html`): the "This chapter"
  column links Overview + the three new dives; the "The course" column links Course home · The Protocol ·
  Redis Patterns Applied. The stamp id `TSK0Nb1VTbfnu4` is valid — reuse it.
- **The as-built floor** (verify in the file before citing; **never print a `file:line` on the page**):
  - **Queue** → `EchoMQ.Jobs.enqueue/4` · `claim/3` · `EchoMQ.Lanes` · `EchoMQ.Consumer` (`echo/apps/echo_mq`). **real.**
  - **Bus** → `EchoMQ.Events.subscribe/2` · `publish/5` (`echo/apps/echo_mq`) — **real**; the *retained, replayable
    event log* (append == mint order, read at offset, time-travel) is **CANON** (`emq.roadmap.md` §"EchoMQ 3.x — the
    stream tier" + `emq3.specs.md`) → **mark `[RECONCILE]` in the md** at any event-log claim.
  - **Cache** → `EchoStore.Table.fetch/3` · `put/3` (`echo/apps/echo_store`). **real.**
  - **Protocol** → `EchoMQ.Keyspace.queue_key/2` → `emq:{q}:<type>` (the `{q}` hashtag); the inline
    `EchoMQ.Script.new/2` Lua run EVALSHA-first by `EchoMQ.Connector.eval/5` (`echo/apps/echo_wire`). **real.**
  - **NEVER** cite the frozen, unrelated tree `echo/apps/echomq` (no underscore — `EchoMQ.Keys`, `LockManager`,
    `Scripts`, `Worker`, `moveToActive`). It is not part of this course.
- **The four authoring disciplines** (course-map §4): (1) **as-shipped, NO versions** — no "2.0/3.0", no "the break",
  no "tracked as it is built"; (2) **extract-and-annotate code, NO `file:line`** — lift a real Elixir fn with teaching
  comments; for Lua use two beats (the named handle, e.g. `EchoMQ.Jobs @enqueue`, then a separate commented script
  body); (3) **the `[RECONCILE]` md shadow** — every canon-grounded claim carries `[RECONCILE: …]` in the md only,
  never in the HTML; (4) **no-invent** — real code or design canon, never past either.
- **Voice:** no first person, no exclamation, no {just, simply, obviously, magical}, no perceptual verb on a tool
  (a queue/script/cache does not "see"/"want"/"know"). Active, short, one idea per section.
- **Sources allow-list:** `redis.io/docs`, `redis.io/commands/<cmd>`, `valkey.io/docs/` + `valkey.io/commands/<cmd>/`
  (the substrate of record), `dragonflydb.io/docs/...` (the multithreading target), `docs.bullmq.io` (lineage/benchmark
  reference only — at most one, never as the wire's canon), `llmstxt.org`. Never invent a URL.
- **Cross-course doors (must resolve):** `/redis-patterns`, `/redis-patterns/overview/patterns-become-protocol`,
  `/bcs`, `/elixir`, `/echomq`, `/echomq/overview`, `/echomq/protocol`.
- **The gate command** (ship only at STATUS: PASS):
  ```bash
  apps/jonnify-cms/bin/cms check --routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns \
    --routes-from /elixir=elixir --routes-from /bcs=html/bcs --require-refs html/echomq/overview/<slug>.html
  ```
- **Hard constraints:** NEVER run git. Edit ONLY your dive's `html/echomq/overview/<slug>.html` + its md mirror
  `docs/echo_mq/course/markdown/overview/<slug>.md`. Do NOT touch the landing, the home, or any `llms.txt` (the
  orchestrator owns them). Two interactives per dive (one in the hero figure, one in main) — real computation over a
  fixed dataset, live `.geo-readout`, pure functions, degrades without JS, honours reduced-motion, no storage.

## MODULE the-three-pillars · "The three pillars" (the *what*)

- **Route:** `/echomq/overview/the-three-pillars` · **file:** `html/echomq/overview/the-three-pillars.html` · **md:**
  `docs/echo_mq/course/markdown/overview/the-three-pillars.md`.
- **Directive:** Teach **what EchoMQ is**: three surfaces over one owned wire. Open (hero) with the thesis — one
  protocol, three pillars. Then a section per pillar: **the Queue** (distribute work: one job, one worker — name
  `EchoMQ.Jobs.enqueue/4`/`claim/3`, `EchoMQ.Consumer`), **the Bus** (broadcast signals: pub/sub events — name
  `EchoMQ.Events.subscribe/2`/`publish/5` — and a retained, replayable event log → **`[RECONCILE]` in md**, canon), and
  **the Cache** (serve reads: an L1/L2 near-cache — name `EchoStore.Table.fetch/3`). Show the contrast with the classic
  messaging shapes (queue = one-to-one work distribution; bus = one-to-many broadcast; cache = read path). Keep it
  orientation-level — name the real surfaces, defer the deep mechanism to the pillar chapters. **Interactives:** (hero)
  a "pick a pillar" selector whose readout names the surface + the job it does + the shape (point-to-point / broadcast /
  read-through); (main) a small "which pillar fits this need?" classifier over a fixed set of example needs. Close with
  a `.bridge` (the redis-patterns pattern the pillars apply → the EchoMQ surface) + a `.take`.
- **Gate:** STATUS: PASS; no version label; no `file:line`; the event-log claim is `[RECONCILE]`-marked in the md and
  reads as shipped in the HTML; the frozen tree uncited; refs two-column; crumbs `EchoMQ › Overview › The three
  pillars`; pager prev = the overview landing (`/echomq/overview`), next = `the-protocol-below-the-line`.

## MODULE the-protocol-below-the-line · "The protocol below the line" (the *why*)

- **Route:** `/echomq/overview/the-protocol-below-the-line` · **file:**
  `html/echomq/overview/the-protocol-below-the-line.html` · **md:**
  `docs/echo_mq/course/markdown/overview/the-protocol-below-the-line.md`.
- **Directive:** Teach **why the three pillars interoperate and why any runtime can speak them**: the protocol lives
  *below the language line*. Use the layer model (L0 Valkey · L1 keys+fields · L2 Lua · L3 executor · L4 API) — the
  shared line falls between L2 and L3. Make it concrete with **one real key** (extract `EchoMQ.Keyspace.queue_key/2` →
  `emq:{q}:<type>`, annotate the `{q}` hashtag and what it pins) and **one real script handle** (name it two-beat: the
  handle `EchoMQ.Jobs @enqueue`, then a short commented Lua excerpt of the atomic move — the `KEYS`/`ARGV` contract;
  keep it an excerpt, the deep treatment is the Protocol chapter). State the polyglot consequence in ONE line (any
  runtime that speaks the keys + Lua is a peer; EchoMQ is supported in / ported to others) — do not enumerate runtimes.
  **Interactives:** (hero) the layer-stack "pick a layer" diagram (you may adapt the model page's `.stack` interactive —
  reframe its labels: L0 Valkey, L1 keys, L2 Lua, L3 executor, L4 `EchoMQ.Jobs.enqueue`; the shared line between L2/L3;
  **drop any BullMQ-derived note**); (main) a "change a field name → who breaks?" demonstrator showing why L1/L2 are
  fixed. Close with a `.bridge` + a `.take`.
- **Gate:** STATUS: PASS; no version label; **no `file:line`**; the Lua shown as handle + commented body; the keyspace
  + script verified real in `echo/apps/echo_mq`/`echo_wire`; frozen tree uncited; refs two-column; crumbs; pager prev =
  `the-three-pillars`, next = `the-door`.

## MODULE the-door · "The door & the BCS family" (the *where*)

- **Route:** `/echomq/overview/the-door` · **file:** `html/echomq/overview/the-door.html` · **md:**
  `docs/echo_mq/course/markdown/overview/the-door.md`.
- **Directive:** Teach **where EchoMQ lands**: the bidirectional door with `/redis-patterns` (this course is the far
  side of every `→ EchoMQ` door; name the canonical map `docs/redis-patterns/redis-patterns.echomq-doors.md`), and what
  owning the queue, the bus, and the cache means for the **BCS family** — `/bcs` (the architecture EchoMQ completes;
  codemojex the worked consumer that rides all three pillars). Explain how to read the course: the foundation
  (Overview, Protocol) then the three pillars then the Proof. **Interactives:** (hero) a "follow a door" selector
  mapping a redis-patterns chapter → the echomq pillar it doors into (R1 → the Cache, R3 → the Queue, R5 → the Bus …);
  (main) a "what the BCS family inherits" picker (queue / bus / cache → what a system built on BCS gets for free).
  Close with a `.bridge` + a `.take`. Link only **built** routes; `<strong>`-name an unbuilt one.
- **Gate:** STATUS: PASS; no version label; no `file:line`; every `/redis-patterns` + `/bcs` link resolves; frozen tree
  uncited; refs two-column; crumbs; pager prev = `the-protocol-below-the-line`, next = the overview landing
  (`/echomq/overview`) — closing the chapter loop.

## Acceptance — "Overview dives built" means
Each of the three dives: gated STATUS: PASS; as-shipped, no versions, no `file:line`; the Bus event-log claim
`[RECONCILE]`-marked in the md (none in HTML); two real interactives; a route-mirror md; the pager loop closed
(landing → three-pillars → protocol-below-the-line → door → landing); dark-editorial unchanged.

## Inputs
- Skill: `.claude/skills/echo-mq-writer/SKILL.md` + `references/course-map.md`.
- Canon: `docs/echo_mq/emq.roadmap.md` (incl. §stream tier) · `emq.design.md` · `emq3.specs.md`.
- As-built: `echo/apps/echo_mq/lib/echo_mq/{keyspace,jobs,events,consumer,lanes}.ex` · `echo/apps/echo_wire/lib/echo_mq/{connector,script}.ex` · `echo/apps/echo_store/lib/echo_store/table.ex`.
- Model page (shell): `html/echomq/overview/the-four-layers.html`. Rebuilt landing (footer + identity): `html/echomq/overview/index.html`.
- Doors: `docs/redis-patterns/redis-patterns.echomq-doors.md`.
