# The Proof — authoring brief (persistent prompt · pillar VI · BCS-direction)

> **Who reads this & how.** A `general-purpose` agent loading the **`echo-mq-writer`** skill, authoring ONE target of
> the **Proof pillar** (`/echomq/proof`) in the **dark-editorial** identity. Read **both** skills — **`echo-mq-writer`**
> (the craft: dark-editorial, as-shipped / NO-version voice, extract-and-annotate Elixir, two-column References, the
> clickable segmented route-tag + canonical 3-column footer, the EMQ branded stamp) AND **`bcs-writer`**
> (`references/bcs-canon.md`, the five deltas + §1a). Build your target (the **landing**, or a **module hub + 3 dives**,
> or the **workshop**) from your `## …` section, **md-first then HTML** (the route-mirror is the source-of-record),
> gate to STATUS: PASS. **NEVER run git.** Model the design system on the built **Bus landing**
> `html/echomq/bus/index.html` (a pillar landing) and a built Bus dive
> `html/echomq/bus/the-consumer-group/at-least-once-and-the-handler.html` (the dive anatomy).

## The thesis (one paragraph)

The Proof is the closing pillar: **the whole system holds, and it can show you.** Three concerns — but two are
shipped code and one is a frontier. The **conformance suite** (`EchoMQ.Conformance`) is the bus contract written as a
set of runnable scenarios: each drives the public surface against a live server and asserts the externally visible
verdict, so the protocol is *proven*, not asserted — and any runtime that speaks the wire must pass the same set (the
polyglot promise made testable). **Telemetry & the read plane** (`EchoMQ.Meter` + `EchoMQ.Metrics`) is how the running
system answers *how it is doing* without being asked to change: the lifecycle is metered the standard Elixir
`:telemetry` way at zero cost when telemetry is absent, and a pure-read plane reports counts, state, throughput, and
the rate-gate over the as-built structures. The **benchmark gate** is the named frontier — there is **no benchmark
surface on disk yet**, so it is a **`soon` card on the landing, never a built module this run** (no-invent: a surface
that is neither code nor canon is fabrication). This run builds the **landing** + **two modules** (conformance ·
telemetry-and-the-read-plane) + the **workshop**.

## Shared context

**Chapter / routes / dirs.** Pillar VI, `/echomq/proof`. `/echomq` is folder-routed — a new section dir needs **no
`main.go` change**, only the dir. This run:
- **The landing** → `html/echomq/proof/index.html` (the pillar manifest — the orchestrator may build this; if it is
  your target, build ONLY it).
- Module 01 → `html/echomq/proof/the-conformance-suite/` — `index.html` (hub) + 3 dives.
- Module 02 → `html/echomq/proof/telemetry-and-the-read-plane/` — `index.html` (hub) + 3 dives.
- The workshop → `html/echomq/proof/workshop.html` (single page, NO dives).
- md mirrors (write FIRST) → `docs/echo/echo_mq/markdown/proof/<module>/<page>.md`; the landing mirror is the flat
  `docs/echo/echo_mq/markdown/proof.md`; the workshop mirror is the flat `markdown/proof/workshop.md` — mirror the
  exact shape of the built `docs/echo/echo_mq/markdown/bus/` tree.

**The as-built floor — every surface this run teaches (verified on disk 2026-06-25, all MATCH real code; the arity is
in the file — confirm before citing, never print a `file:line` on a page). All under
`echo/apps/echo_mq/lib/echo_mq/`:**

- **`EchoMQ.Conformance`** (`conformance.ex`) — **module 01's surface**: the bus contract as a set of **runnable
  scenarios**. `scenarios/0` → the scenario **names + one-line contracts, in run order** (a keyword/tuple list; each
  scenario drives the public surface — and, where the contract IS the wire, raw commands — against a **live server**
  and asserts the externally visible verdict: the fence, the row shape, idempotent admission, the kind law, the lex
  law, the token discipline, the schedule, the morgue, the reaper, the lanes, the read/operator/watch planes, the
  flow family, …). `run(conn, queue)` → **`{:ok, n}`** when all pass / **`{:error, failed_names}`** otherwise; it runs
  every scenario **on per-scenario sub-queues of `queue`** (and **purges what it mints**), printing **one `CONF` line
  per scenario + a closing tally**. **DO NOT pin a hard scenario count on the page** — the set grows additively and a
  number goes stale; teach the **shape** (names+contracts in run order → run on sub-queues → one CONF line each → the
  `{:ok, n}` / `{:error, names}` verdict). The growth law: **prior scenarios stay byte-frozen + git-verified, each new
  one is probe-registered**, additive registration is a protocol **minor**, a wire break a **major**.
- **`EchoMQ.Meter`** (`meter.ex`) — **module 02's telemetry half**: the **`:telemetry` surface over the job
  lifecycle**, re-rooted under **`[:emq, …]`**. `attach(handler_id, event_suffix, handler_fn, config \\ nil)`,
  `attach_many(handler_id, event_suffixes, handler_fn, config \\ nil)`, `emit(event, measurements, metadata)`,
  `span(event_suffix, metadata, fun)`, + the lifecycle convenience emitters `job_added/4`, `job_started/4`,
  `job_completed/5`, `job_failed/6`. **AT ZERO COST when `:telemetry` is not loaded**: every emission guards
  `:erlang.function_exported(:telemetry, :execute, 3)`, so with no `:telemetry` dependency an emit is a **no-op** and
  an `attach` answers `:ok` with no effect — **the bus carries NO `:telemetry` dependency edge** (a host opts in by
  adding the dep). The connector already fires `[:emq, :connector, …]` — **one tree**. **Teach the name
  `EchoMQ.Meter`** (NOT `EchoMQ.Telemetry` — that is the frozen-v1 name in `apps/echomq`; a same-named module would
  shadow non-deterministically. The §3a frozen-tree scrub forbids the v1 names).
- **`EchoMQ.Metrics`** (`metrics.ex`) — **module 02's read-plane half**: **pure-read verbs over the bus's as-built
  structures** — *every verb observes, none mutates*. `get_counts(conn, queue, states)` (counts per state over the
  four sorted sets), `get_job(conn, queue, job_id)` + `get_job_state(conn, queue, job_id)` (which set holds the id),
  `get_metrics(conn, queue, :completed | :failed)` (the terminal-transition throughput tally),
  `get_deduplication_job_id(conn, queue, dedup_id)`, `get_rate_limit_ttl(conn, queue, max_jobs \\ 0)` +
  `get_global_rate_limit(conn, queue)`, `is_maxed(conn, queue)` (the read-and-refuse gate at the concurrency ceiling),
  `lane_depth(conn, queue, group)`. **Every read script declares its keys**; an unregistered state name is an error,
  never an open read.
- **(Named only — the benchmark frontier):** there is **NO benchmark module on disk** (`EchoMQ.Bench` does not exist;
  `bench*` matches nothing). The benchmark gate is a **landing `soon` card** + a one-line forward mention — **never a
  built module, never a fabricated surface, never a number.**

**The four disciplines (echo-mq-writer §4).** (1) As-shipped, **no version labels** in prose (no "2.0/3.0", no "as it
is built"); a real wire constant inside a code extract is fine as code. (2) Extract-and-annotate the atomic **Elixir**
fn (the real code + added teaching comments); **NO `file:line` on any page**. (3) The `[RECONCILE]` md shadow: the
conformance + telemetry + read-plane surfaces are **shipped real code → NONE needed**; the **benchmark** is the one
frontier — if a page *names* it, the md mirror may carry a single `[RECONCILE: benchmark surface not yet on disk]`
marker, but **the landing's `soon` card is the cleaner expression and zero `[RECONCILE]` may leak into HTML**. (4)
No-invent: every surface is in the floor above — never a scenario count, a key, a field, an arity, or a module not
listed; **the benchmark is named, never built.**

**No Lua this run.** The Proof surfaces are read/telemetry verbs (`get_*`, `attach`/`emit`/`span`, `run`/`scenarios`)
issued through `EchoMQ.Connector` — **no new Lua script** to extract. The two-beat Lua rule **does not apply**;
extract-and-annotate the **Elixir** fn only, and **never fabricate a Lua script**. (`EchoMQ.Metrics`' read scripts are
shipped + declared-keys; quote the Elixir verb, not a Lua body.)

**Identity + the branded stamp.** Dark-editorial (copy the `:root` tokens + the whole design system from
`html/echomq/bus/index.html`). The build stamp is **`EMQ`** — copy the stamp block + the Branded-Snowflake decoder
`<script>` from the Bus landing's footer verbatim, with `id="stampId"` = **`EMQ0OGUWI87UdF`** and `id="st-ts"` left as
`&mdash;` (the decoder fills it). **NEVER a `TSK` stamp on an echomq page.**

**The frozen-tree guard (echo-mq-writer §3a — load-bearing).** Ground ONLY in `echo/apps/echo_mq` (underscore). The
scrub `grep -E 'echo/apps/echomq\b|EchoMQ\.Keys\b|EchoMQ\.LockManager|EchoMQ\.Scripts|moveToActive|EchoMQ\.Worker|EchoMQ\.Telemetry'`
must be **0** on every page. Teach `EchoMQ.Meter` (never the v1 `EchoMQ.Telemetry`); never `EchoCache.*` (delta 2) or
`Exchange.*` (delta 3).

**Doors (resolving — all real, mounted in the gate).**
- The `.applied` reverse-door (the **landing** carries the full one; a dive may name it): → `/redis-patterns/production-operations`
  (R8 — running the tier; **built — hard-link OK**) and `/redis-patterns/coordination` (R2 — the atomicity the
  conformance suite proves, **built**, hard-linked).
- → `/bcs/together` (B6 — the four libraries as one umbrella, the closest manuscript chapter; **built, hard-link OK**).
  **`/bcs/proof` does NOT exist on disk — never link it.**
- → `/echo-persistence` only at a durability frontier (the Proof pillar rarely reaches it — the read plane is
  volatile; touch lightly or not at all).
- Within-course (resolve on disk): `/echomq/proof` (the landing), `/echomq/queue`, `/echomq/bus`, `/echomq/cache`,
  `/echomq/protocol`, `/echomq/overview`.

**Sources (vetted — use the real Elixir/OTP/Valkey pages, never a `.out`):**
[Elixir — the `:telemetry` library](https://hexdocs.pm/telemetry/readme.html) (the standard metering surface the Meter
re-roots under `[:emq, …]`), [Erlang/OTP — `:telemetry.execute/3`](https://hexdocs.pm/telemetry/telemetry.html), the
Valkey command pages the read plane issues (`commands/zcard/`, `commands/hget/`, `commands/zscore/`),
[Beck — Test-Driven Development](https://www.oreilly.com/library/view/test-driven-development/0321146530/) (the
verdict-asserting scenario as the contract). **Valkey 9 is the only engine — never Dragonfly** (bcs-writer §1a.A).

**Gate command (ship only at STATUS: PASS):**
```bash
go/jonnify-cms/bin/cms check \
  --routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns \
  --routes-from /bcs=html/bcs --routes-from /elixir=elixir \
  --routes-from /echo-persistence=html/echo-persistence \
  --require-refs html/echomq/proof/<path>.html
```
Gate-invisible checks (verify by reading): clamp spacing; the clickable segmented route-tag (`/ echomq / proof /
<module> / <page>`); the no-version scrub; **no `file:line`**; **no Lua block** (Proof issues read/telemetry verbs
direct); the §3a frozen-tree + `EchoCache`/`Exchange`/`dragonfly` scrubs → **0**; **no hard scenario count**; the EMQ
stamp; every `EchoMQ.*` re-found in `echo/apps/echo_mq`; **zero `[RECONCILE]` in HTML**.

---

## LANDING — The Proof  ·  `html/echomq/proof/index.html` (the pillar manifest)
**Built in WAVE 1 (one landing agent), the module routes do NOT exist yet — so build ALL FOUR module cards as `soon`
non-link `<div>`s** (the Bus-landing precedent): card **01 The conformance suite**, card **02 Telemetry & the read
plane**, card **03 Benchmark** (the named frontier, no surface — stays `soon` forever), card **04 Workshop** (a
`.mod work` card). **The orchestrator flips 01/02/04 to `built` `<a>`-links after waves 2/3 land; 03 stays `soon`.** So
at THIS agent's gate time the page has NO dangling links (every `soon` card is a non-link div; the within-course nav +
the reverse-doors all resolve) → the landing should gate **STATUS: PASS clean**. The pillar landing in the
dark-editorial identity, modelled on `html/echomq/bus/index.html`: the thesis (the system holds, and it can show you)
+ the 4-card module grid (all `soon`) + the `.applied` reverse-door block (R2 coordination **and** R8
production-operations both hard-linked, both built) + the within-course nav (`/echomq/queue`,`/bus`,`/cache`,
`/protocol`,`/overview` — all resolve) + the pillar pager/marks + one framing interactive (e.g. the three concerns:
conformance → telemetry → benchmark, the last greyed as the frontier). The `/bcs/together` (B6) manuscript door.

## MODULE 01 — The conformance suite  ·  dir `the-conformance-suite`
**Surface:** `EchoMQ.Conformance` (`scenarios/0`, `run/2`). **Hub** + 3 dives. **No Lua.**

- **Hub (`the-conformance-suite/index.html`).** Frame it: the bus contract is not asserted, it is **run**. A scenario
  is a name + a one-line contract that drives the public surface against a **live server** and asserts the externally
  visible verdict; the suite is the **polyglot promise made testable** — any runtime that speaks the wire must pass
  the same set. One framing interactive (e.g. a scenario list → each driving a verb → green/red verdict over a fixed
  dataset) + the 3 dive cards.
- **Dive `the-scenarios`.** `scenarios/0` → the names + one-line contracts **in run order**; each asserts an
  externally visible verdict (the fence, the row shape, idempotent admission, the kind law, the lex law, the token
  discipline, the schedule/morgue/reaper, the lanes, the read/operator/watch planes, the flow family). Each scenario
  drives the **public surface** — or **raw commands** where the contract IS the wire. Extract: `scenarios/0` (a
  representative slice of the keyword list, annotated). **No hard count.**
- **Dive `run-and-the-verdict`.** `run(conn, queue)`: runs every scenario on **per-scenario sub-queues** of `queue`
  (and **purges what it mints** — the suite leaves no residue), printing **one `CONF` line per scenario** + a closing
  tally, returning **`{:ok, n}`** (all pass) or **`{:error, failed_names}`** (the names that failed). Extract:
  `run/2`'s loop, annotated. Interactive: a run streaming CONF lines → the `{:ok, n}` tally (a fixed pass/one-fail
  dataset).
- **Dive `the-additive-minor-law`.** How the suite grows without breaking the wire: **prior scenarios stay
  byte-frozen + git-verified, each new one is probe-registered, the count re-pinned** in the pinning tests. **Additive
  registration is a protocol minor; a wire break is a major.** The conformance set is the contract that lets the
  protocol live below the language line — a new runtime is *conformant* iff it passes the same scenarios. Interactive:
  an additive-minor (a new scenario appended, prior set unchanged → still green) vs a wire-break-major (a prior
  scenario's verdict changes → red).
- **Pager:** hub ↔ dives loop; module 01 before module 02.

## MODULE 02 — Telemetry & the read plane  ·  dir `telemetry-and-the-read-plane`
**Surface:** `EchoMQ.Meter` (the `:telemetry` surface) + `EchoMQ.Metrics` (the read plane). **Hub** + 3 dives. **No Lua.**

- **Hub (`telemetry-and-the-read-plane/index.html`).** Frame the two ways the running system reports on itself:
  **push** (the lifecycle metered via `:telemetry`, `EchoMQ.Meter`) and **pull** (a pure-read plane over the as-built
  structures, `EchoMQ.Metrics`). One observes by emitting events as work happens; the other answers a question without
  changing anything. One framing interactive (e.g. a job lifecycle emitting `[:emq, :job, …]` events on one side, a
  read-plane query answering counts on the other) + the 3 dive cards.
- **Dive `the-telemetry-surface`.** `EchoMQ.Meter`: `attach`/`attach_many`/`emit`/`span` + the lifecycle emitters
  (`job_added/4`, `job_started/4`, `job_completed/5`, `job_failed/6`), re-rooted under **`[:emq, …]`** — throughput,
  latency, and failure counts metered the **standard Elixir `:telemetry` way**, one tree with the connector's
  `[:emq, :connector, …]`. Extract: `attach/4` or `span/3` + a lifecycle emitter, annotated. Interactive: a lifecycle
  firing `[:emq, :job, :started]` / `[:emq, :job, :completed]` to an attached handler over a fixed dataset.
- **Dive `zero-cost-when-absent`.** The opt-in property: **every emission guards
  `:erlang.function_exported(:telemetry, :execute, 3)`**, so with **no `:telemetry` dependency loaded** an emit is a
  **no-op** and an `attach` answers `:ok` with no effect — **the bus carries NO `:telemetry` dependency edge** (a host
  opts in by adding the dep). Name the collision-avoidance: the module is **`EchoMQ.Meter`** (not `EchoMQ.Telemetry`)
  so it never shadows the frozen-v1 surface on the shared code path. Extract: the guarded `emit/3` (the
  `function_exported` check), annotated.
- **Dive `the-read-plane`.** `EchoMQ.Metrics`: **pure-read verbs, every one observes, none mutates** —
  `get_counts/3` (per-state counts over the four sorted sets), `get_job_state/3` (which set holds the id),
  `get_metrics/3` (completed/failed throughput), `get_rate_limit_ttl` + `is_maxed/2` (the read-and-refuse gate),
  `lane_depth/3`. **Every read script declares its keys**; an unregistered state name is an error, never an open read.
  Extract: `get_counts/3` or `get_job_state/3`, annotated. Interactive: a queue's per-state counts read off the four
  sorted sets over a fixed dataset.
- **Pager:** hub ↔ dives loop; placed after module 01.

## WORKSHOP — Prove it on a live queue  ·  file `workshop.html` (single page, NO dives)
**Surface:** `EchoMQ.Conformance.run/2` + `EchoMQ.Metrics.*` + `EchoMQ.Meter.*` over a **codemojex** queue.

> A **single page** `html/echomq/proof/workshop.html` + the flat md mirror `markdown/proof/workshop.md`. **NO dives.**
> ≥2 interactives. It **folds the pillar** — link both built modules (01 + 02). The worked domain is **codemojex**
> (verify a real `Codemojex.*` queue/worker on disk, e.g. `Codemojex.ScoreWorker` / `Codemojex.NotificationWorker`
> over `cm.notify`).

- **The build:** (1) **run the conformance suite** against a live server (`Conformance.run/2` → `{:ok, n}`) — the
  contract holds; (2) **attach a meter** (`Meter.attach_many/4` on the codemojex lifecycle events) and watch the
  `[:emq, :job, …]` events flow as a codemojex job runs; (3) **read the plane** (`Metrics.get_counts/3` +
  `lane_depth/3` + `is_maxed/2`) — the queue answers how it is doing without being asked to change. The system holds,
  meters itself, and reports honestly.
- **Doors:** → `/redis-patterns/coordination` (R2, built) · → `/bcs` (the manuscript) · within-course
  `/echomq/queue`, `/echomq/bus`, `/echomq/cache`. **`<strong>`-name** R8 (`/redis-patterns/production-operations`,
  unbuilt) — do NOT hard-link it.
- **Pager:** `prev` = module 02 `telemetry-and-the-read-plane`, `up` = the Proof landing `/echomq/proof`.

## Acceptance
- **LANDING (1) + MODULE 01 (4) + MODULE 02 (4) + WORKSHOP (1) = 10 pages.** Every page **STATUS: PASS** on the gate
  command (the landing's one intended `links` FAIL = the `soon` benchmark card, by design); the md mirror written
  FIRST under `docs/echo/echo_mq/markdown/proof/`.
- Gate-invisible: dark-editorial; the clickable segmented route-tag; the canonical 3-column footer with the
  **`EMQ0OGUWI87UdF`** stamp; **no** version label; **no** `file:line`; **no** Lua block; **no hard scenario count**;
  the §3a frozen-tree (incl. `EchoMQ.Telemetry`) + `EchoCache`/`Exchange`/`dragonfly` scrubs → **0**; ≥2 interactives
  per dive (framing + worked); every `EchoMQ.*` surface re-found in `echo/apps/echo_mq`; the doors resolve.
- **NEVER run git.** Edit only your target's files.

## Inputs
- Skills: `echo-mq-writer` (+ its `references/course-map.md`) and `bcs-writer` (+ `references/bcs-canon.md`).
- Source (read before citing): `echo/apps/echo_mq/lib/echo_mq/{conformance,meter,metrics}.ex`. The workshop's
  codemojex domain: `echo/apps/codemojex/lib/codemojex/{score_worker is in game.ex, notification_worker}.ex` — verify
  the real worker/queue on disk.
- Models: `html/echomq/bus/index.html` (the landing — the design system + the EMQ stamp), a built Bus dive
  `html/echomq/bus/the-consumer-group/at-least-once-and-the-handler.html` (the dive anatomy).
- Manuscript figure home: `docs/echo/bcs/bcs.6.md` (B6 the four libraries as one umbrella) + the conformance/telemetry
  framing — quote verbatim where cited.
