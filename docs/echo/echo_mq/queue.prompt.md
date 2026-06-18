# The Queue · EchoMQ, In Depth — chapter fan-out brief (persistent prompt)

> **Who reads this & how.** One `echo-mq-expert` builds ONE module (hub + its 3 dives, or the workshop) from its
> `## MODULE` section below. Read the **`echo-mq-writer`** skill first, then this brief's **Shared context (every
> module)**, then your `## MODULE` section, then the **model pages**. This is a **FRESH BUILD to the target** — the
> Queue pillar built new to the dark-editorial identity. Copy only the **design-system shell** from the models; author
> all `<main>` content fresh. **Do NOT re-skin.** Engine: `/echo-mq-reconcile queue`. Agent: `echo-mq-expert`. Skill:
> `echo-mq-writer`. Canon: the as-built `echo/apps/echo_mq` (+ `echo_wire`).

## The thesis in one paragraph

The Queue is the **first pillar** — distribute work over the wire. A producer enqueues a job; one worker claims it,
runs it, and completes it; a failure retries with backoff or dies into a morgue. It is **all real code** in
`echo/apps/echo_mq`: a **state machine over four sorted sets** (`pending` · `active` · `schedule` · `dead`) where the
**active-set score IS the lease deadline** and the row's **`attempts` IS the fencing token** — no separate lock. Fair
**lanes** rotate a constructed ring so no one identity starves the others; a supervised **consumer loop** parks instead
of polling; **batches** admit and extend in bulk; **lifecycle controls** schedule, cancel, checkpoint, recover, and run
the operator's runbook; **flows** compose parent/child orchestration with an atomic fan-in. Taught **as shipped,
Elixir-canonical, no versions** — and grounded entirely in real code, so it carries **no `[RECONCILE]` markers** (flag
anything you cannot ground in code). This is the depth behind the Overview's "the Queue distributes work."

## Shared context (every module)

- **Chapter:** The Queue · **route:** `/echomq/queue` · **dir:** `html/echomq/queue/` · **md mirror root:**
  `docs/echo_mq/course/markdown/queue/`.
- **The modules (hub + 3 dives each) + the workshop:** `the-lifecycle` · `jobs-lanes-consumer` · `batches` ·
  `lifecycle-controls` · `flows` · `workshop` (a single page). Served routes `/echomq/queue/<module>` (hub) and
  `/echomq/queue/<module>/<dive>`.
- **The model pages (shell only):** for a **dive**, copy the shell from
  `html/echomq/protocol/the-lua-layer/scripts-are-the-protocol.html` (a built dive in the target identity, with the
  canonical **two-beat Lua** treatment — its `<head>`…`</style>`, `<header>`, the dive `<footer class="site-foot">`
  markup, and the trailing `<script>` blocks); for a **hub**, copy from `html/echomq/protocol/the-lua-layer/index.html`
  (a built module hub). Author all `<main>` fresh; carry over NO prose. The stamp id `TSK0Nb1VTbfnu4` is valid — reuse
  it. (The landing `html/echomq/queue/index.html` is **orchestrator-built — do not touch it**.)
- **The as-built floor** (READ each file and verify arity/fields/`KEYS[]`/return shapes before citing; **never print a
  `file:line` on the page**) — all **real**, all in `echo/apps/echo_mq/lib/echo_mq/`:
  - `keyspace.ex` → `queue_key(queue, type)` builds `emq:{q}:<type>`; `job_key(queue, id)` builds
    `emq:{q}:job:<id>` (and **gates the id** via `EchoData.BrandedId.valid?/1` — raises on an ill-formed id). The
    per-queue `{q}` hashtag pins one queue's keys to one slot. **The grammar is `job:<id>` — NOT `j:<id>`.**
  - The four state sets are `pending` / `active` / `schedule` / `dead` (sorted sets). The aux keys you may meet:
    `meta` (the `paused` flag), `ring` / `wake` (the lanes rota + wake list), `g:<group>:pending` / `gactive` /
    `glimit` / `paused` (the lane structures), `repeat` / `repeat:<name>`, `metrics:completed` / `metrics:failed`,
    `job:<id>:logs` / `:lock` / `:dependencies` / `:processed` / `:unsuccessful` / `:failed`, `flow:outbox`.
  - The **job record HASH** at `job_key/2` carries `state`, `attempts`, `payload` (the protocol floor) plus, as the
    lifecycle adds them: `group`, `last_error`, `progress`, `stalled`, `parent`, `parent_queue`, `parent_policy`. The
    **states** are `pending` · `active` · `scheduled` · `dead` · `awaiting_children`. (Verify the field/state in the
    file before you cite it — do not invent one.)
  - `jobs.ex` — the state machine + the operator per-job plane. Named Lua handles: `@enqueue`, `@schedule`, `@claim`,
    `@complete`, `@retry`, `@promote`, `@reap`, `@update_data`, `@update_progress`, `@add_log`, `@remove_job`,
    `@reprocess`, `@extend_lock`, `@extend_locks`. Public fns: `enqueue/4`, `enqueue_at/5`, `enqueue_in/5`,
    `enqueue_many/3`, `claim/3`, `paused?/2`, `complete/4` (+ optional `result`, arity 5), `retry/7`, `promote/3`,
    `reap/2`, `browse/3`, `pending_size/2`, `update_data/4`, `update_progress/4`, `add_log/4` (+ `keep`, arity 5),
    `get_job_logs/3`, `remove_job/3` (+ `dedup_id`, arity 4), `reprocess_job/3`, `extend_lock/5`, `extend_locks/4`.
  - `lanes.ex` — fair lanes. Handles `@genqueue`, `@gclaim`, `@gpause`, `@gresume`, `@glimit`. Fns `enqueue/5`,
    `claim/3`, `pause/3`, `resume/3`, `limit/4`, `depth/3`. The **ring** is a Valkey LIST; `@gclaim` rotates it one
    step with `LMOVE KEYS[1] KEYS[1] LEFT RIGHT` then serves that lane's head — fairness is **constructed, not hashed**.
  - `consumer.ex` — the supervised loop. `child_spec/1`, `start_link/1`, `stop/2`. The loop is reap → promote → drain
    (rotating `Lanes.claim`) → park (`BLPOP` the `wake` key). Defaults: `:lease_ms` 30_000, `:beat_ms` 1_000,
    `:retry_delay_ms` 1_000, `:max_attempts` 3, `:pump_batch` 100. The handler takes `%{id:, payload:, attempts:,
    group:}` → `:ok | {:error, reason}`; a raising handler is caught (`try/rescue/catch`) and converted to a typed retry.
  - `backoff.ex` — `delay_ms/2`, a **pure host-side** function: `{:fixed, ms}` · `{:exponential, base, cap}`
    (`base * 2^(attempts-1)`, clamped at `cap`) · `{:jitter, inner}` (full-jitter over an inner policy). The wire takes
    a **literal** delay; the curve is computed above the wire (doctests in the file are real — you may cite them).
  - `repeat.ex` — repeatables. `register/6`, `cancel/3`, `due/3`, `advance/4`, `count/2`. Keys `emq:{q}:repeat`
    (a sorted set scored by next-run ms) + `emq:{q}:repeat:<name>` (a hash `{every_ms, template}`). Mints a **fresh
    `JOB` id per occurrence** (never a reused row). The cadence is the **Pump's** (`EchoMQ.Pump`, `pump.ex`).
  - `cancel.ex` — the cooperative cancellation token, **host-side, no wire identity**: `new/0` (a `make_ref/0`),
    `cancel/3` (sends `{:emq_cancel, token, reason}` to a pid), `check/1` (a non-blocking `receive after 0`),
    `check!/1` (raises `EchoMQ.Cancel.Cancelled`). Worker-side only.
  - `stalled.ex` — the count-thresholded stalled sweep **on top of** `Jobs.reap/2`. `@sweep_stalled` increments a
    per-job `stalled` field, recovers a job below `:max_stalled` (default 1) back to pending/its lane, and
    **dead-letters** one at/above it. Fns `check/3` → `{:ok, %{recovered: [...], dead: [...]}}`, `job_stalled?/4`;
    an optional periodic GenServer (`child_spec/1`/`start_link/1`/`stop/2`).
  - `admin.ex` — the queue-scope operator plane. Handles `@pause`, `@resume`, `@drain`, `@obliterate`. Fns
    `pause/2`, `resume/2`, `drain/3`, `obliterate/3`. `pause/2` sets the `paused` field on `emq:{q}:meta` (the
    **separate-gate** form — the `@claim`/`@gclaim` scripts stay byte-unchanged; `Jobs.claim/3`/`Lanes.claim/3` read
    it first); `drain/3` empties pending (+ optional schedule) and deletes rows + `:logs`, leaving `active` and the
    repeat registry; `obliterate/3` destroys a **paused** queue, bounded by `:budget` (→ `:more`/`:ok`), refusing a
    non-paused queue (`{:error, :not_paused}`) or one with live active jobs (`{:error, :active}`, unless `force: true`).
  - `flows.ex` — single-queue + cross-queue parent/child flows. Handles `@enqueue_flow` (same-queue, atomic on one
    slot), `@hold_parent` + `@enqueue_flow_child` (cross-queue, host-orchestrated). Fns `add/3`, `add_bulk/3`,
    `children_values/3`, `dependencies/3`, `ignored_failures/3`. The parent is held `state = awaiting_children` with a
    `:dependencies` STRING counter = N; the **fan-in hook lives inside `jobs.ex`'s `@complete`** (DECR `:dependencies`,
    release the parent to `pending` at zero). The failure policy (`fail_parent_on_failure` default vs
    `ignore_dependency_on_failure`) rides a `parent_policy` token (`'fp'`/`'id'`) read host-side at retry.
  - The id primitive: `EchoData.BrandedId` (14 bytes: a 3-char uppercase namespace + an 11-char Base62 Snowflake;
    `JOB` is the job namespace the `@enqueue` kind-gate enforces via `string.sub(ARGV[1], 1, 3) == 'JOB'`).
  - **NEVER** cite the frozen, unrelated tree `echo/apps/echomq` (no underscore — `EchoMQ.Keys`, `LockManager`,
    `Scripts`, `Worker`, `moveToActive`, the `bull:`/`wait`/`completed` BullMQ set names). It is not part of this
    course; scrub → 0 on every page.
- **Off-limits framing (from the source moduledocs, NEVER on the page):** the build-program **chapter numbers**
  ("Chapter 3.2", "emq.2.2-D2", "emq.3.x", "INV5", "S-6"); the **lineage** ("the v1 capability re-derived", "the v1
  default", "BullMQ", "Dragonfly the primary"); any **version** ("2.0/3.0", "the break", "tracked as built"). Teach the
  **capability and the mechanism** in present tense, as one shipped system. The fence value `echomq:2.0.0` may appear
  **only** as a quoted code constant in a script/fence extract, never as a course label.
- **The four authoring disciplines** (course-map §4): (1) **as-shipped, NO versions**; (2) **extract-and-annotate
  code, NO `file:line`** — lift the real Elixir fn with *added* teaching comments; **Lua in two beats** (the named
  handle, e.g. `EchoMQ.Jobs @claim`, then a SEPARATE Lua `pre.code` block with the real, decoded script body, deeply
  commented — the `KEYS`/`ARGV` contract, the atomic transition, the fencing check); (3) the `[RECONCILE]` md shadow —
  **expected empty here** (all real code; flag, don't invent, if a claim cannot be grounded); (4) **no-invent**.
- **Voice:** no first person, no exclamation, no {just, simply, obviously, magical}, no perceptual verb on a tool
  (a queue/worker/script/set does not "see"/"want"/"know"/"decide").
- **Sources allow-list:** `valkey.io/docs/` + `valkey.io/commands/<cmd>/` (the substrate of record — e.g. `zadd`,
  `zpopmin`, `zrangebyscore`, `lmove`, `blpop`, `hincrby`, `hset`), `redis.io/docs`, `redis.io/commands/<cmd>` (e.g.
  `evalsha`), `llmstxt.org`. Never invent a URL; never `bullmq.io` as the wire's canon.
- **Cross-course doors (must resolve — verify before linking):** `/echomq`, `/echomq/overview`, `/echomq/protocol`
  (+ its modules), `/echomq/queue`, `/bcs`, `/elixir`, `/redis-patterns`, and — **built and link-safe** —
  `/redis-patterns/queues` (R3) and `/redis-patterns/time-delay-priority` (R4). **`/redis-patterns/flow-control` is NOT
  built** — name it in prose with `<strong>`, never as a link (a redis dive is not a manifest; every link must resolve).
- **The gate command** (ship only at STATUS: PASS; zsh: force word-split with `${=FLAGS}` if you loop):
  ```bash
  apps/jonnify-cms/bin/cms check --routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns \
    --routes-from /elixir=elixir --routes-from /bcs=html/bcs --require-refs html/echomq/queue/<module>/<page>.html
  ```
- **Hard constraints:** NEVER run git. Edit ONLY your module's `html/echomq/queue/<module>/` files + their md mirrors
  `docs/echo_mq/course/markdown/queue/<module>/`. Do NOT touch the chapter landing, the home, the content-map, or any
  `llms.txt` (orchestrator-owned). **Two interactives per dive** (a hero figure + a main one), **≥1 on the hub** — real
  computation over a fixed dataset, a live `.geo-readout`, pure functions, degrade without JS, reduced-motion-safe, no
  storage. Each dive carries a `.bridge` (the redis-patterns pattern → the EchoMQ implementation, link only built
  routes) + a `.take`. Pager loop hub→dive1→dive2→dive3→hub; crumbs `EchoMQ › The Queue › <module> › <dive>`.

## MODULE the-lifecycle · hub + 3 dives

- **Routes:** hub `/echomq/queue/the-lifecycle`; dives `the-four-sets`, `claim-and-the-lease`, `completion-and-recovery`.
- **Directive:** Teach the **state machine**. Hub: a job moves `pending → active → done`, or `active → scheduled →
  pending` on a retry, or `active → dead` at max attempts, or `active → pending` when a lease lapses; the whole machine
  is four sorted sets and one row. Dives:
  (1) **the-four-sets** — `pending`/`active`/`schedule`/`dead` are sorted sets whose **members are the branded ids
  themselves**, so **byte order is mint order** and the queue needs **no second index**; `browse/3` (`ZRANGE … REV
  BYLEX`) and `pending_size/2` (`ZCARD`). Interactive: a state diagram + a set-inspector over a fixed job set.
  (2) **claim-and-the-lease** — extract the `@claim` two-beat Lua (`ZPOPMIN` pending → `HINCRBY attempts` → `HSET state
  active` → `ZADD active` at `now + lease`); annotate that **the active-set score IS the lease deadline** and
  **`attempts` IS the fencing token**; `claim/3` honors `paused?/2` first (`:empty` | `{:ok, {id, payload, att}}`).
  (3) **completion-and-recovery** — the token-fenced terminal + recovery transitions: `@complete`/`complete/4` (att
  matches → `ZREM active`, `DEL` row, `metrics:completed`), `@retry`/`retry/7` (schedule with a literal delay, or dead
  at max + `last_error`), `@reap`/`reap/2` (an expired-lease member returns to pending — crash recovery on the **server
  clock**), `reprocess_job/3` (a `dead` job back to pending; `{:error, :not_dead}` otherwise).
  `.bridge`: the redis-patterns **reliable-queue** pattern (R3 `/redis-patterns/queues`) → this state machine.
- **Gate:** STATUS: PASS each page; no version label; no `file:line`; frozen-tree uncited; every set/field/fn verified
  in `jobs.ex`/`keyspace.ex`; Lua shown two-beat; refs two-column; crumbs + pager loop closed.

## MODULE jobs-lanes-consumer · hub + 3 dives

- **Routes:** hub `/echomq/queue/jobs-lanes-consumer`; dives `enqueue-and-claim`, `fair-lanes-and-the-ring`,
  `the-consumer-loop`.
- **Directive:** Teach the **producer, the fair worker, and the loop that owns the rhythm**. Hub: enqueue is one
  idempotent script; claiming is fair across identities; a supervised loop parks rather than polls. Dives:
  (1) **enqueue-and-claim** — extract the `@enqueue` two-beat Lua (the `EMQKIND` kind-gate
  `string.sub(ARGV[1],1,3) ~= 'JOB'`, the `EXISTS` idempotency → return 0, `HSET` the three-field row, `ZADD pending`);
  `enqueue/4` (`{:ok, :enqueued}` | `{:ok, :duplicate}` | `{:error, :kind}`) and the flat `claim/3`.
  (2) **fair-lanes-and-the-ring** — `Lanes`: per-group lanes `emq:{q}:g:<group>:pending`; the **ring** LIST is the rota
  of serviceable lanes; extract the `@gclaim` two-beat Lua and annotate the **`LMOVE KEYS[1] KEYS[1] LEFT RIGHT`
  rotate-one-step** + the `gactive`/`glimit` concurrency bookkeeping — **fairness is constructed, not hashed**;
  `enqueue/5`, `claim/3` (returns `{id, payload, att, group}`), `pause/3`, `resume/3`, `limit/4`, `depth/3`.
  (3) **the-consumer-loop** — `Consumer`: the supervised `reap → promote → drain → park` beat; **park-don't-poll**
  (`BLPOP` the `wake` key — a parked consumer costs the wire nothing); a **dedicated connector lane** for the blocking
  verb; the raising handler caught and converted to a **typed retry**; `stop/2` drains the job in hand; the handler map
  `%{id:, payload:, attempts:, group:}` and the rhythm defaults (`:lease_ms` 30_000, `:beat_ms` 1_000, `:max_attempts`
  3, `:pump_batch` 100). (`EchoMQ.Pump` is the optional dedicated cadence twin — name it, defer depth to lifecycle-controls.)
  `.bridge`: the redis-patterns **reliable-queue / consumer** pattern (R3 `/redis-patterns/queues`).
- **Gate:** STATUS: PASS; no version label; no `file:line`; both Lua handles shown two-beat; the ring rotation true to
  `@gclaim`; the loop's defaults verified in `consumer.ex`; frozen-tree uncited; refs two-column; pager loop closed.

## MODULE batches · hub + 3 dives

- **Routes:** hub `/echomq/queue/batches`; dives `enqueue-many`, `bulk-flows`, `batch-lease-extension`.
- **Directive:** Teach **bulk** — admit, compose, and extend many at once in one wire flush. Hub: a batch is the same
  per-item contract, pipelined. Dives:
  (1) **enqueue-many** — `enqueue_many/3`: `SCRIPT LOAD` the `@enqueue` source once, then an **`EVALSHA` pipeline** in
  one flush; **per-item verdicts in input order** (`:enqueued` | `:duplicate` | `{:error, :kind}`), under the same
  script, row, and idempotency as `enqueue/4`. Interactive: a batch composer showing per-item verdicts.
  (2) **bulk-flows** — `Flows.add_bulk/3`: many flows, each landed by `add/3`, **fail-closed PER flow** (a flow that
  fails to land leaves its OWN parent held; the batch continues), returning `{:ok, [{parent_id, [child_id]}]}` in input
  order. (Cross-reference the flows module for the flow shape.)
  (3) **batch-lease-extension** — `extend_locks/4`: gate every id first, then `@extend_locks` re-scores each `active`
  member whose token matches under **one server-clock read**, returning the **`failed`** list (ids whose token was
  stale or row gone); contrast the single `extend_lock/5`.
  `.bridge`: the redis-patterns **pipelining / batch** angle (R3 `/redis-patterns/queues`).
- **Gate:** STATUS: PASS; no version label; no `file:line`; the per-item-order contract true to `enqueue_many/3`;
  fail-closed-per-flow true to `add_bulk/3`; frozen-tree uncited; refs two-column; pager loop closed.

## MODULE lifecycle-controls · hub + 3 dives

- **Routes:** hub `/echomq/queue/lifecycle-controls`; dives `scheduling-and-recurrence`, `cancellation-and-checkpoints`,
  `the-operator-plane`.
- **Directive:** Teach the **control plane** beyond enqueue→claim→complete: controls over **time**, over the **worker in
  hand**, and over the **whole queue**. Dives:
  (1) **scheduling-and-recurrence** — `enqueue_at/5` + `enqueue_in/5` (the `@schedule` Lua: `state = scheduled`, `ZADD`
  the **schedule** set at the run-at score — a **visibility fence, not a second queue**; `in` uses the **server**
  `TIME`); `@promote`/`promote/3` releases due jobs to pending; `Backoff.delay_ms/2` (the pure host-side curve —
  fixed/exponential/jitter; the wire takes a **literal** delay; the doctests are real); `Repeat`
  (register/cancel/due/advance — the `emq:{q}:repeat` ZSET + `repeat:<name>` hash; **a fresh `JOB` id per occurrence**;
  the Pump's cadence). Interactive: a backoff-curve plotter over the real policies.
  (2) **cancellation-and-checkpoints** — `Cancel` (the cooperative token: `make_ref/0`, `cancel/3` sends
  `{:emq_cancel, token, reason}`, `check/1`/`check!/1` — **worker-side, no wire identity**; a handler that never checks
  completes normally); `extend_lock/5` (**checkpoint the lease** so a long-but-alive handler is not reaped — re-score
  the active member; the lease IS the active score; token-fenced); `Stalled` (the **count-thresholded** sweep ON TOP of
  `reap/2` — the `stalled` field, `:max_stalled` → dead-letter; `check/3` → `{:ok, %{recovered, dead}}`; `job_stalled?/4`).
  (3) **the-operator-plane** — `Admin` queue-scope (`pause/2`/`resume/2` via the `emq:{q}:meta` `paused` field — the
  separate-gate that keeps `@claim` byte-unchanged; `drain/3` — empty pending [+schedule], `active` and the repeat
  registry survive; `obliterate/3` — destroy a **paused** queue, bounded `:budget` → `:more`/`:ok`, refusing
  `{:error, :not_paused}` / `{:error, :active}`) + the per-job verbs on `Jobs` (`update_data/4`; `update_progress/4` +
  the `PUBLISH` of a progress event on `emq:{q}:events`; `add_log/5`/`get_job_logs/3` over the `:logs` subkey;
  `remove_job/4` — refuses a `:lock`ed job with `{:error, :locked}`; `reprocess_job/3` — `{:error, :not_dead}`).
  `.bridge`: the redis-patterns **delay/schedule/priority** pattern (R4 `/redis-patterns/time-delay-priority`).
- **Gate:** STATUS: PASS; no version label; no `file:line`; Backoff doctests real; every verb verified in
  `jobs.ex`/`admin.ex`/`cancel.ex`/`stalled.ex`/`repeat.ex`/`backoff.ex`; the `paused`-field separate-gate stated
  correctly; frozen-tree uncited; refs two-column; pager loop closed.

## MODULE flows · hub + 3 dives

- **Routes:** hub `/echomq/queue/flows`; dives `parent-and-children`, `reading-the-results`,
  `cross-queue-and-failure-policy`.
- **Directive:** Teach **orchestration** — a flow is a parent job and a list of children. Hub: the parent is held out
  of pending until its children finish; one atomic script lands a same-queue flow; the fan-in releases the parent. Dives:
  (1) **parent-and-children** — the shape: the parent held `state = awaiting_children` with a `:dependencies` STRING
  counter = N; the children claimable in pending; the **same-queue `@enqueue_flow`** lands the whole flow **atomically
  on one slot** (all-or-none); the **fan-in hook inside `@complete`** DECRs `:dependencies` and at zero releases the
  parent to pending. `add/3` → `{:ok, {parent_id, [child_id]}}`. (Show the `@enqueue_flow` two-beat.)
  (2) **reading-the-results** — the parent handler runs **on** its children's results, through three pure reads:
  `children_values/3` (`HGETALL` the `:processed` hash → `%{child_id => result}`), `dependencies/3` (`GET` the
  `:dependencies` counter → a non-negative integer, `0` when none), `ignored_failures/3` (`HGETALL` the
  `:unsuccessful` hash → `%{child_id => error}`). All id-gated, no state change.
  (3) **cross-queue-and-failure-policy** — a child in a different queue lands on a different slot, so a cross-queue add
  is **host-orchestrated, non-atomic across slots, parent-first, fail-closed** (`@hold_parent` then
  `@enqueue_flow_child` per child carrying `parent` + `parent_queue`); its fan-in is **eventually-consistent** (the
  child emits to its own-slot `flow:outbox`; the per-queue **Pump** sweep delivers the decrement on the parent's slot).
  The **failure policy**: `fail_parent_on_failure` (the default — a dead child fails the parent) vs
  `ignore_dependency_on_failure` (a dead child is a satisfied dependency, recorded in `:unsuccessful`), carried as the
  `parent_policy` token (`'fp'`/`'id'`) read host-side at retry.
  `.bridge`: the redis-patterns **flow-control / orchestration** angle — name **<strong>R6 · Flow control</strong>**
  in prose (NOT a link — `/redis-patterns/flow-control` is not built); the resolvable door is R3
  `/redis-patterns/queues`.
- **Gate:** STATUS: PASS; no version label; no `file:line`; `@enqueue_flow` shown two-beat; the atomic-same-queue vs
  eventually-consistent-cross-queue distinction true to `flows.ex`; the failure-policy tokens correct; **no link to
  `/redis-patterns/flow-control`**; frozen-tree uncited; refs two-column; pager loop closed.

## MODULE workshop · single page

- **Route:** `/echomq/queue/workshop`.
- **Directive:** A hands-on close: **trace one job through its whole lifecycle, then compose a small flow.** Walk a job
  `enqueue → claim (lease + token) → complete`, and the failure fork `claim → retry (scheduled) → promote → claim →
  dead`, and the recovery `reap`; then a flow of a parent + N children landing atomically and fanning in. Two
  interactives: a **lifecycle stepper** (step a job across the four sets, showing the set membership + the row state at
  each step) and a **flow composer** (a parent + N children → the `:dependencies` count ticking to zero → the parent
  released). Build it as a dive-surface page (no sub-dives). `.bridge` (R3 `/redis-patterns/queues`) + `.take`.
- **Gate:** STATUS: PASS; no version label; no `file:line`; the traced transitions real (match `jobs.ex`); pager
  prev = the last module hub (`flows`), next = the chapter landing (`/echomq/queue`).

## Acceptance — "The Queue built" means
Every page (landing + 5 module hubs + 15 dives + workshop = 22): gated STATUS: PASS; as-shipped, no versions, no
`file:line`; Lua shown two-beat; all surfaces verified real in `echo/apps/echo_mq` (no `[RECONCILE]` expected — flag if
any claim cannot be grounded in code); two real interactives per dive (≥1 per hub); a route-mirror md per page; pager
loops closed; dark-editorial unchanged.

## Inputs
- Skill: `.claude/skills/echo-mq-writer/SKILL.md` + `references/course-map.md`.
- As-built: `echo/apps/echo_mq/lib/echo_mq/{jobs,keyspace,lanes,consumer,backoff,repeat,cancel,stalled,admin,flows,pump}.ex` ·
  `echo/apps/echo_wire/lib/echo_mq/{script,connector}.ex` (the EVALSHA dispatch + the version fence).
- Model pages (shell): dive `html/echomq/protocol/the-lua-layer/scripts-are-the-protocol.html`; hub
  `html/echomq/protocol/the-lua-layer/index.html`. Landing model (orchestrator): `html/echomq/protocol/index.html`.
- Content-map: `docs/echo_mq/course/echo_mq.course.md`. Doors: `docs/redis-patterns/redis-patterns.echomq-doors.md`.
