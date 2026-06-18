# Session task: tool-optimize page authoring, then finish the EchoMQ Queue pillar + reconcile R1

> Handoff brief for the next session. The last session's per-page LLM authoring was too token-expensive
> (~260–285k tokens per 4-page module) because each agent re-emitted the ~14 KB byte-identical design-system shell on
> every ~34 KB page and re-read the skill + ~10 source files. **First build a shell-assembler tool so authors write
> only the per-page `<main>` + interactive JS; then finish the work below.**

## 0 — Reorient (read these, do not re-derive)
- `docs/echo_mq/course/echo_mq.course.md` (the spine) + `echo_mq.course.progress.md` (the dashboard).
- `docs/echo_mq/course/queue.prompt.md` (the persistent Queue fan-out brief — the as-built floor + the four disciplines).
- The four authoring disciplines (NON-NEGOTIABLE): (1) **as-shipped, NO versions** (no "2.0/3.0/the break"; never the
  build-program lineage — "Chapter 3.x", "emq.N", "INV", "S-6", "D-N", "v1 … re-derived", BullMQ, "Dragonfly primary");
  (2) **extract-and-annotate code, NO `file:line`**, Lua in two beats (named handle, then a separate decoded body);
  (3) **`[RECONCILE]` only in md, never HTML** (Queue is all real code → expect zero); (4) **no-invent** — never cite
  the frozen tree `echo/apps/echomq` (no underscore: `EchoMQ.Keys`/`LockManager`/`Scripts`/`Worker`/`moveToActive`/`bull:`).
- Grounding code lives in `echo/apps/echo_mq/lib/echo_mq/` (+ `echo_wire`). Key grammar: `job_key` = `emq:{q}:job:<id>`
  (NOT `j:`), `queue_key` = `emq:{q}:<type>`, the four sets `emq:{q}:{pending,active,schedule,dead}`.

## 1 — Build the shell-assembler tool (the optimization)
Create `docs/echo_mq/course/tool/build_page.py` (a DEV-TIME generator like `cmd/sitemap` — it emits committed static
HTML; the served site stays byte-for-byte). Pattern after `docs/elixir/toolkit/build_page.py` if useful.

- **Extract the shell ONCE** from two gated donor pages: a **dive** donor
  `html/echomq/queue/the-lifecycle/claim-and-the-lease.html` and a **hub** donor
  `html/echomq/queue/the-lifecycle/index.html`. Split each into reusable fragments:
  - `_head.html` — `<!doctype>` … `</style></head><body>` + skip link (IDENTICAL on every page).
  - `_header.html` — `<header class="site">…</header>` with `{{route_cur}}` placeholder for the leaf segment.
  - `_foot_queue.html` — `<footer class="site-foot">…</footer>` (per-chapter "This chapter" nav; identical within Queue).
  - `_scripts_common.html` — the trailing stamp-decoder + reveal `<script>` blocks (IDENTICAL on every page; stamp id
    `TSK0Nb1VTbfnu4`).
- **Per-page input** = `{slug, title, meta, route_cur, main_html (file), interactive_js (file)}`. The tool emits:
  `_head` + `_header(route_cur)` + `<main>…</main>` (from main_html) + `_foot_queue` + `<script>interactive_js</script>`
  + `_scripts_common`. The author writes ONLY `main_html` (the hero/sections/figures/.bridge/.take/refs/pager) and
  `interactive_js` — never the shell. This roughly halves output tokens/page and removes the copy-the-shell read.
- Verify the tool round-trips: regenerate `claim-and-the-lease.html` from extracted fragments + its main/js and confirm
  it still gates STATUS: PASS (byte-equivalent enough to pass the 10 gates). Then use it for all remaining pages.

## 2 — Finish the Queue: the 3 missing lifecycle-controls dives (19/22 → 22/22)
The `lifecycle-controls` module agent crashed after writing md-first. **On disk already:** the hub
`html/echomq/queue/lifecycle-controls/index.html` (verify+gate it) and ALL FOUR md mirrors
`docs/echo_mq/course/markdown/queue/lifecycle-controls/{index,scheduling-and-recurrence,cancellation-and-checkpoints,the-operator-plane}.md`
(the content source-of-record). **MISSING — build these 3 dive HTMLs via the tool, reflecting their md:**
- `scheduling-and-recurrence.html` — `enqueue_at/5`+`enqueue_in/5` (the `@schedule` Lua: state=scheduled, ZADD the
  schedule set at run-at — a visibility fence, not a second queue; `in` uses server `TIME`), `@promote`/`promote/3`,
  `Backoff.delay_ms/2` (fixed | exponential `base*2^(att-1)` clamped `cap` | jitter — pure host-side; doctests are real),
  `Repeat` (register/cancel/due/advance; `emq:{q}:repeat` ZSET + `repeat:<name>` hash; a fresh JOB id per occurrence).
- `cancellation-and-checkpoints.html` — `Cancel` (cooperative token `make_ref/0`, `{:emq_cancel,token,reason}`,
  `check/1`/`check!/1` — worker-side, no wire identity), `extend_lock/5` (checkpoint the lease; the lease IS the active
  score; token-fenced), `Stalled` (count-thresholded sweep ON TOP of `reap/2`; the `stalled` field; `:max_stalled` →
  dead-letter; `check/3`, `job_stalled?/4`).
- `the-operator-plane.html` — `Admin` queue-scope (`pause/2`/`resume/2` via the `emq:{q}:meta` `paused` field — the
  separate-gate that keeps `@claim` byte-unchanged; `drain/3`; `obliterate/3` → `:more`/`:ok`,
  `{:error,:not_paused}`/`{:error,:active}`) + the per-job verbs on `Jobs` (`update_data/4`; `update_progress/4` +
  PUBLISH on `emq:{q}:events`; `add_log/5`/`get_job_logs/3` over `:logs`; `remove_job/4` → `{:error,:locked}` EMQLOCK;
  `reprocess_job/3` → `{:error,:not_dead}` EMQSTATE).
- Per dive: 2 interactives (hero + main; pure fns over a fixed dataset, live `.geo-readout`, degrade-without-JS,
  reduced-motion-safe, no storage), a `.bridge` → `/redis-patterns/time-delay-priority` (R4, built), a `.take`,
  two-column References, crumbs `EchoMQ › The Queue › Lifecycle controls › <dive>`, pager loop hub→sched→cancel→operator→hub.
- Source files to verify against (read only as needed): `jobs.ex` (`@schedule`,`@promote`,`update_*`,`add_log`,
  `remove_job`,`reprocess`,`extend_lock`), `backoff.ex`, `repeat.ex`, `cancel.ex`, `stalled.ex`, `admin.ex`.
- **Cheapest path:** the orchestrator can author the three `<main>` fragments + interactive JS inline (no subagent —
  the content already exists in md) and assemble via the tool, avoiding the per-agent skill re-read that dominated cost.

## 3 — Q4 verify all 22 Queue pages (batch, not per-page)
Run ONE gate loop + ONE scrub pass over `html/echomq/queue/` (zsh: `${=FLAGS}`):
```
FLAGS="--routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns --routes-from /elixir=elixir --routes-from /bcs=html/bcs --require-refs"
for p in html/echomq/queue/**/*.html html/echomq/queue/index.html; do printf "%s " $p; apps/jonnify-cms/bin/cms check ${=FLAGS} $p 2>&1 | grep -oE 'STATUS: (PASS|FAIL)'; done
grep -rniE '\b[23]\.0\b|the break|tracked as built' html/echomq/queue/ | grep -v 'echomq:2.0.0' || echo "no-version OK"
grep -rniE 'echomq[^_]|EchoMQ\.Keys|LockManager|moveToActive|bull:' html/echomq/queue/ || echo "frozen-tree OK"
grep -rn 'RECONCILE' html/echomq/queue/ || echo "no-RECONCILE-in-HTML OK"
grep -rnE 'Chapter 3\.|emq\.[0-9]|INV[0-9]|\bS-[0-9]\b' html/echomq/queue/ || echo "no-lineage OK"
```
Fix any defect do-no-harm; re-gate to PASS. Re-find every quoted surface in `echo/apps/echo_mq` before trusting it.

## 4 — Q5 relink + sync (orchestrator-only; NO subagents)
- `html/echomq/index.html` (home): flip the **Queue** card from non-anchor `soon` → `<a class="mod" href="/echomq/queue">`
  with `pill built`; re-gate the home.
- `html/echomq/protocol/index.html` "Up next": optionally flip Queue `soon`→`built` (links `/echomq/queue`).
- `docs/echo_mq/course/echo_mq.course.md`: Queue row → `✅ built`. `echo_mq.course.progress.md`: counts **45 / 91**,
  fill the Queue per-chapter table, note Queue `[RECONCILE]`=0.
- Memory: update `/Users/jonny/.claude/projects/-Users-jonny-dev-jonnify/memory/echomq-course-spec.md` (Queue shipped)
  + the `MEMORY.md` index line.

## 5 — Reconcile R1 (redis-patterns caching)
Run `/redis-reconcile B1` using the authored brief `docs/redis-patterns/specs/caching/caching.prompt.md`. Light second
pass over 7 modules (`cache-aside`, `write-through`, `write-behind`, `cache-stampede-prevention`, `client-side-caching`,
`session-management`, `workshop`): fix surface drift (`Journal.intend`→`intend_and_enqueue/4`;
`Gateway.parse`→`parse_place/1`+`parse_cancel/1`; `Table.expires` fn→the `expires_at` field), keep contract-sheet +
zero-BullMQ, pull the branded-id/`{q}` angle forward. **The `→ EchoMQ` door:** the Cache pillar `/echomq/cache` is NOT
built — point the door at **`/echomq/overview`** (CTA naming the Cache pillar), and record in
`docs/redis-patterns/redis-patterns.echomq-doors.md` "retarget href to /echomq/cache when it lands". Then orchestrator-
relink the R1 landing + home + sync TOC/roadmap/llms.txt. Apply the same tool optimization where the redis shell allows
(redis is the BCS **contract-sheet** identity, a different shell — extract its own fragments from a gated R1 page).

## Hard constraints (verbatim)
NEVER run git (the operator commits out-of-band). `html/ru/` off-limits to search/authoring. echomq = dark-editorial;
redis = contract-sheet (no re-skin either way). Fanned agents edit ONLY their own module's files; the landing/home/
content-map/llms.txt/prompt files are orchestrator-only. Link only resolvable routes (a page is not a manifest —
unbuilt pillars stay `soon` non-anchor cards). Stamp id `TSK0Nb1VTbfnu4`.

## Current state (built PASS A+ unless noted) — git HEAD unchanged, nothing committed
- **Overview (5):** `html/echomq/index.html` + `html/echomq/overview/{index,the-three-pillars,the-protocol-below-the-line,the-door}.html`
- **The Protocol (18):** `html/echomq/protocol/` landing + 4 modules×(hub+3) + workshop
- **The Queue (19/22):** `html/echomq/queue/index.html` (landing) + `the-lifecycle`(4) + `jobs-lanes-consumer`(4) +
  `batches`(4) + `flows`(4) + `workshop/index.html`(1) + `lifecycle-controls/index.html` (hub only) — **3 dives missing** (§2).
- **R1 caching:** prompt authored, run pending (§5). **Bus/Cache/Proof pillars:** forward program.
- **Transitional (ignore):** `html/echomq/{core,substrate}` (old structure, superseded; not linked from anything current).
