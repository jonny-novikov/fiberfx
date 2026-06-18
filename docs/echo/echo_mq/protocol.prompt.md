# The Protocol · EchoMQ, In Depth — chapter fan-out brief (persistent prompt)

> **Who reads this & how.** One `echo-mq-expert` builds ONE module (hub + its 3 dives, or the workshop) from its
> `## MODULE` section below. Read the **`echo-mq-writer`** skill first, then this brief's **Shared context (every
> module)**, then your `## MODULE` section, then the **model pages**. This is a **FRESH BUILD to the target** — the
> Protocol chapter is rebuilt to the new identity. Copy only the **design-system shell** from the models; author all
> `<main>` content fresh. **Do NOT re-skin** (dark-editorial). Engine: `/echo-mq-reconcile protocol`. Agent:
> `echo-mq-expert`. Skill: `echo-mq-writer`. Canon: `docs/echo_mq/` + the as-built `echo/apps/echo_mq` + `echo_wire`.

## The thesis in one paragraph

The Protocol is the **substrate the three pillars share** — the wire EchoMQ owns. It is **all real code**: the braced
`emq:{q}:` keyspace, the record hash, the inline Lua scripts run by EVALSHA, and the immutability + branded-id
discipline that lets one wire serve the Queue, the Bus, and the Cache and lets any runtime speak it. Taught **as
shipped, Elixir-canonical, no versions** — and grounded entirely in `echo/apps/echo_mq` (+ `echo_wire`), so it carries
**no `[RECONCILE]` markers** (nothing here is ahead of code). This is the depth behind the Overview's "protocol below
the line".

## Shared context (every module)

- **Chapter:** The Protocol · **route:** `/echomq/protocol` · **dir:** `html/echomq/protocol/` · **md mirror root:**
  `docs/echo_mq/course/markdown/protocol/`.
- **The modules (hub + 3 dives each) + the workshop:** `the-owned-keyspace` · `the-record-hash` · `the-lua-layer` ·
  `immutability-and-branded-ids` · `workshop` (a single page). Served routes `/echomq/protocol/<module>` (hub) and
  `/echomq/protocol/<module>/<dive>`.
- **The model pages (shell only):** for a **dive**, copy the shell from `html/echomq/overview/the-protocol-below-the-line.html`
  (a built dive in the target identity — its `<head>`…`</style>`, `<header>`, `<footer class="site-foot">` with the
  `.foot-cols` markup, and the trailing `<script>` blocks); for a **hub**, copy from `html/echomq/overview/index.html`
  (the chapter-landing surface — adapt to a module hub). Author all `<main>` fresh; carry over NO prose. The stamp id
  `TSK0Nb1VTbfnu4` is valid — reuse it.
- **The as-built floor** (READ each file and verify arity/fields/`KEYS[]` before citing; **never print a `file:line` on
  the page**) — all **real**, all in `echo/apps/echo_mq` + `echo_wire`:
  - `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` → `EchoMQ.Keyspace.queue_key/2` builds `emq:{q}:<type>` (e.g.
    `["emq:{", queue, "}:", type]`); `job_key/2` → `emq:{q}:j:<id>`; `version_key/0` → `{emq}:version`; `slot/1`
    (CRC16-XMODEM % 16384 over `hashtag/1`, vector `slot("123456789") == 12739`); `hashtag/1`; `reserve/1`. The `{q}`
    hashtag pins one queue's keys to one slot; the `{emq}:` reserve is the core's own space (first-byte-disjoint).
  - `echo/apps/echo_mq/lib/echo_mq/jobs.ex` → `EchoMQ.Jobs.enqueue/4` (the `@enqueue` named Lua handle), `claim/3`
    (`@claim`), `complete/4` (`@complete`), `retry/7`, `enqueue_many/3`. The job record HASH + its fields (READ the
    file for the exact field set — the overview agents verified `state`, `attempts`, `payload`; confirm and add any
    others actually present). The Lua bodies declare every key in `KEYS[]` and carry the `EMQKIND` branded-id gate.
  - `echo/apps/echo_wire/lib/echo_mq/script.ex` → `EchoMQ.Script.new/2` (inline source, SHA1-precomputed, declared
    keys). `echo/apps/echo_wire/lib/echo_mq/connector.ex` → `EchoMQ.Connector.eval/5` (EVALSHA-first, NOSCRIPT
    fallback, the `{emq}:version` fence). The fence value (`echomq:2.0.0`) may appear ONLY as a quoted code constant in
    a script/fence extract — NEVER as a course-version label in prose.
  - **NEVER** cite the frozen, unrelated tree `echo/apps/echomq` (no underscore — `EchoMQ.Keys`, `LockManager`,
    `Scripts`, `Worker`, `moveToActive`). It is not part of this course (scrub → 0 on every page).
- **The four authoring disciplines** (course-map §4): (1) as-shipped, **NO versions** (no "2.0/3.0", "the break",
  "tracked as it is built"); (2) **extract-and-annotate code, NO `file:line`** — lift the real Elixir fn with teaching
  comments; **Lua in two beats** (the named handle, e.g. `EchoMQ.Jobs @enqueue`, then a SEPARATE Lua `pre.code` block
  with the real, decoded script body, deeply commented — the `KEYS`/`ARGV` contract, the branded-id gate, each atomic
  transition); (3) the `[RECONCILE]` md shadow — **expected to be empty here** (all real code); (4) no-invent.
- **Voice:** no first person, no exclamation, no {just, simply, obviously, magical}, no perceptual verb on a tool.
- **Sources allow-list:** `redis.io/docs`, `redis.io/commands/<cmd>` (e.g. `hset`, `zadd`, `evalsha`), `valkey.io/docs/`
  + `valkey.io/commands/<cmd>/` (substrate of record), `dragonflydb.io/docs/...` (the declared-keys → thread placement
  link), `llmstxt.org`. At most one `docs.bullmq.io` as a lineage reference, never as the wire's canon. Never invent a URL.
- **Cross-course doors (must resolve):** `/redis-patterns`, `/redis-patterns/overview/patterns-become-protocol`,
  `/bcs`, `/elixir`, `/echomq`, `/echomq/overview`, `/echomq/overview/the-protocol-below-the-line`, `/echomq/protocol`.
- **The gate command** (ship only at STATUS: PASS):
  ```bash
  apps/jonnify-cms/bin/cms check --routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns \
    --routes-from /elixir=elixir --routes-from /bcs=html/bcs --require-refs html/echomq/protocol/<module>/<page>.html
  ```
- **Hard constraints:** NEVER run git. Edit ONLY your module's `html/echomq/protocol/<module>/` files + their md
  mirrors `docs/echo_mq/course/markdown/protocol/<module>/`. Do NOT touch the chapter landing, the home, or any
  `llms.txt` (orchestrator-owned). Two interactives per dive (hero + main), ≥1 on the hub — real computation over a
  fixed dataset, live `.geo-readout`, pure functions, degrade without JS, reduced-motion, no storage. Each dive: a
  `.bridge` (the redis-patterns pattern → the EchoMQ implementation) + a `.take`. Pager loop hub→dive1→dive2→dive3→hub.

## MODULE the-owned-keyspace · hub + 3 dives

- **Routes:** hub `/echomq/protocol/the-owned-keyspace`; dives `the-braced-grammar`, `the-hashtag-and-the-slot`,
  `the-reserve`.
- **Directive:** Teach the **owned keyspace**. Hub: `emq:{q}:<type>` is grammar-total and braced; `EchoMQ.Keyspace`
  builds every key. Dives: (1) **the-braced-grammar** — extract `queue_key/2` + `job_key/2`, annotate the grammar
  (`emq:{q}:<type>`, `emq:{q}:j:<id>`); (2) **the-hashtag-and-the-slot** — the `{q}` hashtag pins one queue to one
  slot; extract `slot/1`/`hashtag/1`, show CRC16-XMODEM % 16384 with the vector `slot("123456789") == 12739`; an
  interactive that computes the slot for a typed queue name; (3) **the-reserve** — `{emq}:` is the core's reserved,
  first-byte-disjoint space (`version_key/0` → `{emq}:version`); why `emq` is rejected as a queue name. `.bridge`: the
  redis-patterns hash-tag-colocation pattern (R2) → `EchoMQ.Keyspace`.
- **Gate:** STATUS: PASS each page; no version label; no `file:line`; frozen-tree uncited; every keyspace fn verified
  in `keyspace.ex`; refs two-column; crumbs `EchoMQ › The Protocol › The owned keyspace › <dive>`; pager loop closed.

## MODULE the-record-hash · hub + 3 dives

- **Routes:** hub `/echomq/protocol/the-record-hash`; dives `the-hash-and-its-fields`, `the-state-and-attempts`,
  `the-payload`.
- **Directive:** Teach the **job record**. READ `jobs.ex` for the exact HASH field set first. Hub: a job is a Valkey
  HASH at `job_key/2`; the field names are part of the protocol. Dives: (1) **the-hash-and-its-fields** — extract the
  `HSET` from the `@enqueue` Lua (the field list), annotate each field; (2) **the-state-and-attempts** — `state` (the
  lifecycle position) + `attempts` (the retry fence); (3) **the-payload** — `payload` (the opaque caller data) and why
  it is never interpreted by the wire. `.bridge`: the redis-patterns data-modeling pattern (R7) → the EchoMQ record.
- **Gate:** STATUS: PASS; no version label; no `file:line`; the HASH fields verified in `jobs.ex` (do not invent a
  field); Lua shown two-beat (handle + body); frozen-tree uncited; refs two-column; pager loop closed.

## MODULE the-lua-layer · hub + 3 dives

- **Routes:** hub `/echomq/protocol/the-lua-layer`; dives `scripts-are-the-protocol`, `declared-keys`, `evalsha-dispatch`.
- **Directive:** Teach **the scripts are the protocol**. Hub: every state change is one atomic Lua script; the wire is
  the set of scripts. Dives: (1) **scripts-are-the-protocol** — the two-beat form (the `@enqueue` handle, then the
  decoded Lua body, deeply commented: the `EMQKIND` gate, `EXISTS` idempotency, `HSET` the row, `ZADD` pending); (2)
  **declared-keys** — every key passed in `KEYS[]` (none constructed in-script); why this is the law (Dragonfly schedules
  by the declared key set — cite dragonflydb.io); (3) **evalsha-dispatch** — `EchoMQ.Script.new/2` (SHA1-precomputed) +
  `EchoMQ.Connector.eval/5` (EVALSHA-first, NOSCRIPT fallback). `.bridge`: the redis-patterns "patterns become protocol"
  (R0.3) + scripting → `EchoMQ.Script`/`Connector`.
- **Gate:** STATUS: PASS; no version label; **no `file:line`**; **every Lua block paired with a named handle**; the Lua
  bodies decoded verbatim (no highlight spans/entities) from `jobs.ex`; declared-keys claim true to the real script;
  frozen-tree uncited; refs two-column; pager loop closed.

## MODULE immutability-and-branded-ids · hub + 3 dives

- **Routes:** hub `/echomq/protocol/immutability-and-branded-ids`; dives `the-immutable-line`, `the-branded-id-gate`,
  `the-version-fence`.
- **Directive:** Teach **what holds the wire together**. Hub: below the line (keys + Lua) is fixed; ids are branded;
  the version record fences the wire. Dives: (1) **the-immutable-line** — why L1/L2 are fixed (a renamed field or key
  breaks every reader); the demonstrator from the overview dive, deepened on the real record; (2) **the-branded-id-gate**
  — the 14-byte branded id (`EMQKIND` checked in Lua via `string.sub(ARGV[…],1,3)`); extract the gate from a real
  script (two-beat) and annotate it; (3) **the-version-fence** — `version_key/0` → `{emq}:version`; `Connector.eval/5`
  checks it before running (the fence value `echomq:2.0.0` appears ONLY as a quoted code constant here, never as a
  course label); a v-mismatch is refused. `.bridge`: the redis-patterns branded-key/atomicity patterns (R2) → the gate.
- **Gate:** STATUS: PASS; **no version label in prose** (the fence value is code-only); no `file:line`; the gate +
  fence verified in `jobs.ex`/`connector.ex`; frozen-tree uncited; refs two-column; pager loop closed.

## MODULE workshop · single page

- **Route:** `/echomq/protocol/workshop`.
- **Directive:** A hands-on close: **decode a real key and trace one EVALSHA to its Lua source.** Walk: given
  `emq:{quotes}:j:<id>`, read off the queue (`quotes`), the slot (compute it), the kind from the branded id; then take
  the `@enqueue` handle, show its decoded Lua, and point at the `KEYS[]` it declares. Two interactives: a key-decoder
  (type a key → queue + slot + kind) and a script-tracer (pick a verb → its named handle + the keys it touches). Build
  it as a dive-surface page (no sub-dives). `.bridge` + `.take`.
- **Gate:** STATUS: PASS; no version label; no `file:line`; the decoded key + script real; pager prev = the last module
  hub (`immutability-and-branded-ids`), next = the chapter landing (`/echomq/protocol`).

## Acceptance — "The Protocol built" means
Every page (landing + 4 module hubs + 12 dives + workshop): gated STATUS: PASS; as-shipped, no versions, no `file:line`;
Lua shown two-beat; all surfaces verified real in `echo/apps/echo_mq`/`echo_wire` (no `[RECONCILE]` expected — flag if
any claim cannot be grounded in code); two real interactives per dive; a route-mirror md per page; pager loops closed;
dark-editorial unchanged.

## Inputs
- Skill: `.claude/skills/echo-mq-writer/SKILL.md` + `references/course-map.md`.
- As-built: `echo/apps/echo_mq/lib/echo_mq/{keyspace,jobs}.ex` · `echo/apps/echo_wire/lib/echo_mq/{script,connector}.ex`.
- Canon: `docs/echo_mq/emq.design.md` (the master invariant — the braced grammar, the `{emq}:` reserve, declared keys, the fence).
- Model pages (shell): dive `html/echomq/overview/the-protocol-below-the-line.html`; hub `html/echomq/overview/index.html`.
- Content-map: `docs/echo_mq/course/echo_mq.course.md`. Doors: `docs/redis-patterns/redis-patterns.echomq-doors.md`.
