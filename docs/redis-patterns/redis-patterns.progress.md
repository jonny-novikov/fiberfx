# Redis Patterns Applied — build progress

> Live dashboard for authoring the `/redis-patterns` course. Recounted at each wave close. A module is **✓ built**
> when its pages (hub + dives, or the directory pages) are authored and gated STATUS: PASS; **◐** when specced or
> mid-build; **○** when only planned in the TOC/chapter spec. The structural map is the
> [TOC](redis-patterns.toc.md); the grounding map is the [roadmap](redis-patterns.roadmap.md); this file tracks
> delivery.

```
REDIS PATTERNS APPLIED · /redis-patterns                        modules 53 / 53  built ✓ COMPLETE

  R0 Overview            ████████████████████████  3/3  ✓✓✓  COMPLETE
  R1 Caching             ████████████████████████  7/7  ✓✓✓✓✓✓✓  COMPLETE
  R2 Coordination        ████████████████████████  6/6  ✓✓✓✓✓✓  COMPLETE
  R3 Reliable Queues     ████████████████████████  6/6  ✓✓✓✓✓✓  COMPLETE
  R4 Time/Delay/Priority ████████████████████████  6/6  ✓✓✓✓✓✓  COMPLETE
  R5 Streams & Events    ████████████████████████  5/5  ✓✓✓✓✓  COMPLETE
  R6 Flow Control        ████████████████████████  6/6  ✓✓✓✓✓✓  COMPLETE
  R7 Data Modeling       ████████████████████████  7/7  ✓✓✓✓✓✓✓  COMPLETE
  R8 Production & Ops     ████████████████████████  7/7  ✓✓✓✓✓✓✓  COMPLETE

  ──────────────────────────────────────────────────────────────────────
  COURSE   ███████████████████████████  53 / 53 modules built   (100%)
           pages: 203 html + 1 llms.txt · R0–R8 ALL COMPLETE — the catalog is fully built · door → /echomq
```

Legend — `✓` built & gated PASS · `◐` specced / in build · `○` planned · `█` built cell · `░` remaining.

## Now building

- **R0 · Overview — COMPLETE.** R0.1 (home + overview landing) ✓, R0.2 (Redis under Portal) ✓, R0.3 (Patterns become
  protocol) ✓ — all gated, the R0.3 tile activated on the overview landing, `llms.txt` served in every subfolder.
- **R1 · Caching — COMPLETE.** Chapter landing + all seven modules (R1.01–R1.07), 29 pages, gated + verified +
  relinked; `llms.txt` served in every subfolder. Grounding: Portal's catalog cache machine (the cache family is not
  an EchoMQ one) + the one real EchoMQ crossing in R1.04 (`apps/echomq-go/.../loader.go`).
- **R2 · Coordination — COMPLETE (6/6 modules).** Landing ✓ + R2.01 atomic-updates ✓ + R2.02 distributed-locking ✓ +
  **R2.03 redlock ✓** + **R2.04 cross-shard-consistency ✓** + **R2.05 hash-tag-colocation ✓** (`the-tag-mechanic` ·
  `crossslot-prevention` · `cluster-auto-detect`) + **R2.06 workshop ✓** (capstone, no dives) — six hubs + 15 dives +
  the workshop, all gated STATUS: PASS. (The R2.05/R2.06 door pages carry the intended `<a href="/echomq">` forward-link
  the `links` gate flags by design, the same way the home/landing manifests' forward-links do.) Grounded in the
  **iconic Elixir** EchoMQ `echo/apps/echomq` (the authoritative "our-context" source): R2.01 = `move_to_active/4` →
  `moveToActive-11.lua` + `execute_transaction/2`; R2.02 = `Keys.lock/2` + `extendLock-2.lua` + `LockManager`; R2.03 =
  the **contrast** (no Redlock — the single-Redis lease is the road taken); R2.04 = the **prevention** answer; R2.05 =
  the colocation that keeps the iconic Elixir `moveToActive-11.lua` legal — cluster enforcement is the documented
  **Elixir cluster gap** filled by the **Go runtime** (`apps/echomq-go` `cluster.go` `GetClusterSlot`/`ValidateHashTags`/
  `CalculateCRC16` % 16384 + `validateClusterCompatibility`), framed as the polyglot contrast, **not** "the Go port =
  EchoMQ". **Next gap: R3 reliable queues.**
- **R3 · Reliable Queues — COMPLETE (landing + 3 course-direction dives + all 6 granular modules R3.01–R3.06).**
  The strategic forward-looking entry to the pivot chapter, plus the first three granular modules: the **chapter landing**
  ([`/redis-patterns/queues`](/redis-patterns/queues), a route manifest that surveys the arc R3→R8) + three deep dives —
  **the-reliable-queue** (`RPOPLPUSH wait→active` under a lock via `moveToActive-11.lua` + `de:{id}` idempotency via
  `EchoMQ.Keys.dedup/2` + `moveStalledJobsToWait-8.lua`), **states-as-locations** (`moveToFinished-14.lua` as one
  EVALSHA via `EchoMQ.Scripts.execute_raw/4` + `emq:{queue}:marker`/`BZPOPMIN`, no busy-poll), **the-road-ahead** (the
  orientation dive: the arc R3→R8 + the door into the living EchoMQ course). Grounded in the **iconic Elixir** app
  `echo/apps/echomq` (mechanic dives) and the real cross-link map `docs/echomq/echomq.toc.md` (the orientation dive).
  All 4 gated 9/10 (the only `links` FAIL is the intended `/echomq/*` forward-doors + the landing's R4–R8 up-next).
  **Door:** R3 → the living EchoMQ course **Queue pillar** (`/echomq/queue`) + `/echo-persistence` at the durability frontier.
  Then the granular modules landed in two fan-out builds: **R3.01 processing-list · R3.02 at-least-once · R3.03
  stalled-recovery** (12 pages), then **R3.04 atomic-state-machine · R3.05 blocking-vs-polling · R3.06 workshop**
  (9 pages — the workshop is a no-dives capstone), both via the senior-narrative-then-per-module fan-out (see the build
  log). R3 is the first fully-built granular chapter. **Next gap: R4 Time/Delay/Priority. R8.07 capstone still deferred.**
- **R4 · Time, Delay & Priority — COMPLETE (landing + 3 orientation dives + all six granular modules R4.01–R4.06 built; the second fully-built granular chapter).**
  The strategic forward-looking entry to the scheduling chapter: the **chapter landing**
  ([`/redis-patterns/time-delay-priority`](/redis-patterns/time-delay-priority), a route manifest that surveys the arc
  R4→R8) + three orientation dives hosted directly under it — **the-sorted-set-as-a-clock** (one ZSET, two readings:
  the `:delayed` timer wheel + the `:prioritized` ladder), **score-as-meaning** (the score as the semantic axis —
  fire-time `ts×0x1000`, composite `getPriorityScore` = `priority×0x100000000+pc`, `:repeat` next-run upsert), and
  **the-road-ahead** (the arc R4.01→R4.06 + the door to EchoMQ's scheduler subsystem). Grounded in the **iconic
  Elixir** app `echo/apps/echomq`, every fact senior-verified before authoring: `:delayed` score = `(ts+delay)×0x1000`
  (`addDelayedJob-6.lua` `getDelayedScore`) + the `promoteDelayedJobs` sweep; `getPriorityScore`
  `priority×0x100000000 + (INCR pc)%0x100000000` (an included Lua fn reused across the priority-aware scripts; the
  `:pc` counter key is `EchoMQ.Keys.pc/1`, NOT `priority_counter/1`); `:repeat` a **ZSET** (`ZADD nextMillis customKey`,
  `ZSCORE` upsert — the `keys.ex` "hash" doc-comment is a source defect); `EchoMQ.Backoff.calculate/4` `base×2^(n-1)` +
  `retryJob-11.lua` reschedule. **Door:** R4 → **E6 · Lifecycle controls** (`/echomq/lifecycle`) + **E4 · Groups**
  (`/echomq/groups`) — the honest content fit, not the spec's coarse "E6/E7" pair (E7 = EchoStore is a dishonest door
  for time/priority; recorded in `r4.progress.md`). Landing 10-gate (FAIL only on intended `/echomq` + R5–R8
  forward-links); the-sorted-set-as-a-clock STATUS: PASS (clean 10/10); score-as-meaning + the-road-ahead 9/10 (only
  the `/echomq` doors). The first three granular modules are now built (below). **Next gap: R4.04–R4.06 granular
  modules. R8.07 capstone still deferred.**

## Build log (newest first)

- **`/redis-write R4.04 + R4.05 + R4.06` with the mandatory EchoMQ 2.0 focus — the chapter close (9 pages).** The
  request's framing ("drop BullMQ, `emq:` prefix, 1.3→2.0") initially CONTRADICTED its own target spec
  (`dragonfly.md` asserted "BullMQ-wire-compatible by construction") — surfaced via AskUserQuestion; Operator chose
  the GENUINE 2.0 pivot (full native redesign, specs-first) and turned out to be reframing the specs LIVE in the
  same session (`emq.roadmap.md`/`emq.1.md`/`emq.md` converted to "the EchoMQ 2.0 protocol break"; a SUPERSESSION
  NOTE landed on `dragonfly.md` mid-flight — the Edit stale-file guard caught the collision, orchestrator backed off
  all spec edits). Pages then authored with a **mandatory "Where this is heading — EchoMQ 2.0" note on every page**
  (verified facts: `emq:` replaces `emq:`, every Lua key declared, `meta.version` `echomq:2.0.0`, two-way fence, v1
  frozen at `1.3.0`, Dragonfly-native; FORWARD-framed, never asserted-as-shipped; punchline = the pattern is a
  property of the sorted set, not the prefix). **R4.04 backoff-retry** (hub + exponential-backoff ·
  jitter-thundering-herd · reuse-the-delayed-zset; `EchoMQ.Backoff.calculate/4` owns the math, `retryJob-11.lua`
  only reschedules) + **R4.05 leaderboards** (hub + zadd-and-zrank · top-n-and-around-me · the-score-update-path)
  as a concurrent wave of 2, then **R4.06 workshop** (single-page capstone folding all five modules) as a lone tail.
  All 9 pages 9/10 (the lone intended `/echomq/*` door FAIL). **Grounding catch #4 (no-invent on own bank):** the
  bank's "Portal progress rankings (ZADD/ZRANK/ZREVRANGE)" was ASPIRATIONAL — Portal has NO Redis ZSET; real surface
  = `Portal.Enrollment.Progress` (`percent :: 0..100`, `PRG`) → R4.05 grounds in a clean standalone board + a
  counterfactual bridge ("a ranking view would ZADD the percent"). **Operator built ahead out-of-band:** R4.05's
  HTML + 3 of R4.04's pages were already committed at HEAD before the wave ran (the R4.05 agent's independent build
  converged byte-identical on the dives; net new = the 8 route-mirror mds the prior build lacked + a 3-line voice
  fix to the committed hub + `reuse-the-delayed-zset.html` + the workshop). Manifests relinked (R4.04/05/06
  `soon→built`, landing cards `<div>→<a>`), TOC R4 `✓ complete` (stale `retryJob (base*2^(n-1))` grounding fixed to
  the Backoff owner), llms.txt promoted, dashboard 25→28/53 (53%), pages 102→111 html; live crawl all 9 routes 200.
  R4 = the second fully-built granular chapter. **Next gap: R5 Streams & Events. R8.07 capstone still deferred.**
- **`/redis-write R4.03` — the composite-priority module (4 pages, lone agent).** R4.03 priority-scores
  ([`/redis-patterns/time-delay-priority/priority-scores`](/redis-patterns/time-delay-priority/priority-scores) + dives
  `packing-two-keys-in-one-score` · `fifo-within-tier` · `zpopmin`), the chapter's sharpest "Redis Pattern Applied"
  moment: a naive priority queue needs two structures (a set per tier + a FIFO within), but EchoMQ packs BOTH into one
  numeric score — `getPriorityScore` = `priority × 0x100000000 + (INCR pc) % 0x100000000` (tier in the high 32 bits,
  arrival counter in the low 32), so a single `ZPOPMIN` on the `:prioritized` ZSET yields strict priority then FIFO,
  no second structure. Source = `fundamental/lexicographic-sorted-sets` (its score-based half: composite keys +
  "Combining with Score-Based Ordering"); the honest contrast is that a lexicographic key packs fields into the
  MEMBER (read by `ZRANGEBYLEX`) while EchoMQ packs them into the SCORE (read by `ZPOPMIN`). **NO-INVENT CAUGHT A
  DEFECT IN MY OWN BANK (again):** `r4.progress.md` cited `EchoMQ.Keys.priority_counter/1` — that function does NOT
  exist; the real key fn is **`EchoMQ.Keys.pc/1`** → `emq:{queue}:pc` (`keys.ex:179`, passed as KEYS[9] via
  `Keys.pc(ctx)` in `add_prioritized_job`, `scripts.ex:624`). Verified against code before briefing; corrected the
  bank (spec ← code) and the agent shipped `Keys.pc/1` (the phantom name is absent from all 4 pages). Also corrected
  the bank's "six scripts" → `getPriorityScore` is an included fn reused across 11 priority-aware scripts. Grounding:
  `:prioritized` ZSET (`keys.ex:114`), `getPriorityScore` (`addPrioritizedJob-9.lua:84`), `ZADD prioritizedKey score
  jobId`, `EchoMQ.Scripts.add_prioritized_job/4`, consumption `rcall("ZPOPMIN", priorityKey)`→`LPUSH activeKey`
  (`moveToActive-11.lua:113`), `change_priority`/`changePriority-7.lua` as the re-score aside. All 4 pages 9/10 (lone
  `links` FAIL = the intended `/echomq/groups` E4·Groups door — the honest priority fit). Adversarial sweep clean: no
  invented surface (zero `Portal.*`, phantom `priority_counter` absent), clamps spaced, route-tags segmented, 2-col
  refs, pager chain hub→packing→fifo→zpopmin→hub, md↔html bijection. Agent self-fixed two component-voice slips
  pre-report (a priority queue "wants" two → "needs"; "logic to choose" → "a selection step"); my adversarial
  component-voice grep then came back clean. Dev server had stopped mid-session (stale PID) → `make start` restored it,
  live crawl confirms all 4 routes 200, unbuilt R4.04–R4.06 404. Manifests relinked (home map R4.03 pill `soon→built`,
  R4 landing granular card `<div>→<a>` + `built`); TOC + dashboard 24→25/53 (47%), pages 98→102 html;
  `time-delay-priority/llms.txt` R4.03 promoted to built.

- **`/redis-write R4.01 + R4.02` — the first two granular scheduling modules (8 pages).** Per-module fan-out from
  `r4.progress.md`: two prompt packs (`r4.01.prompt.md` delayed-queue · `r4.02.prompt.md` schedulers) extending the
  verified-grounding bank, then two redis-experts fanned concurrently (≤2 heavy agents), zero drops. **R4.01 · The
  delayed queue** ([`/redis-patterns/time-delay-priority/delayed-queue`](/redis-patterns/time-delay-priority/delayed-queue))
  — hub + `score-is-fire-time` · `zrangebyscore-promotion` · `the-next-wake`; grounds the textbook delayed queue
  (`fundamental/delayed-queue`) in EchoMQ's `:delayed` ZSET — `getDelayedScore` `delayedTimestamp×0x1000` (the low 12
  bits discriminate jobs due in the same ms), the `promoteDelayedJobs` included sweep
  (`ZRANGEBYSCORE delayedKey 0 (timestamp+1)×0x1000-1 LIMIT 0 1000` + `ZREM`, in `moveToActive-11.lua`/`retryJob-11.lua`/
  `moveToFinished-14.lua`), `getNextDelayedTimestamp` (`/0x1000`), and the delay marker `ZADD markerKey nextTimestamp "1"`.
  **R4.02 · Schedulers & repeatable jobs** ([`/redis-patterns/time-delay-priority/schedulers`](/redis-patterns/time-delay-priority/schedulers))
  — hub + `cron-vs-interval` · `upsert-no-duplicates` · `start-to-start-cadence`; grounds in the `:repeat` **ZSET**
  upsert (`addRepeatableJob-2.lua` `storeRepeatableJob` `ZADD repeatKey nextMillis customKey`, probed by
  `ZSCORE repeatKey customKey` so a reboot adds no duplicate; per-scheduler opts in a companion HASH at
  `repeat:<customKey>` — which honestly resolves the `keys.ex` "hash" doc-comment), plus the newer
  `addJobScheduler-11.lua` `storeJobScheduler`. All 8 pages 9/10 (the lone `links` FAIL is the intended
  `/echomq/lifecycle` door — same as the R3 module precedent). Adversarial sweep: **no invented surface** (every
  `EchoMQ.*`/`*.lua`/included-fn cross-checked real in `echo/apps/echomq`; zero `Portal.*`), clamps spaced, route-tags
  segmented, 2-col refs, pager chains correct, md↔html bijection (8 mds). Two gate-invisible component-voice defects
  self-fixed (a "removal **decides** the owner" → "establishes"; "how it computes the next score **decides**" →
  "governs"). Manifests relinked: home map R4.01/R4.02 pills `soon→built`, R4 landing granular cards `<div>→<a>` +
  `built`, and the R4.02 hub now links its R4.01 sibling (deferred during the concurrent build, restored once R4.01
  landed). TOC R4 header + module rows `✓ built`; dashboard 22→24/53 (45%), pages 90→98 html.

- **`/redis-write R4 landing + 3 dives` — the scheduling-chapter strategic entry (4 pages).** Senior-played-by-orchestrator:
  the grounding was verified directly against `echo/apps/echomq` and banked in `specs/time-delay-priority/r4.progress.md`
  (the verified-grounding table + the door reconcile), then three persistent prompt packs
  (`r4.the-sorted-set-as-a-clock.prompt.md` · `r4.score-as-meaning.prompt.md` · `r4.the-road-ahead.prompt.md`) were
  injected and redis-experts fanned out (wave 1 = clock + score, wave 2 = road-ahead; ≤2 concurrent). Landing authored
  orchestrator-side from the R3 landing model (new ZSET-as-clock SVG: a timer wheel over `:delayed` + a priority ladder
  over `:prioritized`). Adversarial sweep clean: no invented surface (every EchoMQ symbol cross-checked in
  `echo/apps/echomq`; `EchoMQ.Keys.delayed/prioritized/repeat` confirmed real at keys.ex 110/114/184), clamps spaced,
  `data-c` on all select-buttons, 4 route-mirror mds, zero component-voice hits, all JS parses. Two defects self-fixed on
  the landing pre-fan-out (a `voice` "just"; a genuinely-missing `/elixir/pragmatic/genserver-state` → real
  `/elixir/language/otp/genserver`). Killer reuse lesson: a path absent as **both** `<slug>.html` **and**
  `<slug>/index.html` is the real dangling case — folder-routing means an `ls` of only the `.html` form is a misleading
  check (R0.2 + `/elixir/pragmatic/cqrs` are dirs, so they resolve). Home map needs **no** edit at a strategic entry —
  it tracks per-module pills (all R4 modules correctly stay `soon`) and the `Open chapter →` forward-link now simply
  resolves. TOC R4 `○→◐` (orientation dives linked); dashboard 22/53 unchanged (orientation dives are not modules),
  pages 86→90 html + 18→19 llms.txt; `time-delay-priority/llms.txt` added.

- **`/redis-write R3.04–R3.06` — the closing reliable-queue modules (9 pages) — R3 COMPLETE.** Same
  senior-narrative-then-per-module fan-out: the narrative `specs/queues/r3.progress.md` was extended (build 2) and three
  persistent prompt packs injected (`r3.04.prompt.md` · `r3.05.prompt.md` · `r3.06.prompt.md`), each grounded in facts
  **read directly from `echo/apps/echomq`** before any agent ran. Then redis-writers fanned out (wave 1 = R3.04 + R3.05
  concurrent, hub-then-3-dives each; wave 2 = R3.06 lone). Built: **R3.04 atomic-state-machine**
  (`EchoMQ.Scripts.move_to_finished/7` → `moveToFinished-14.lua`, the 14 keys in verified order, `fetch_next`=1 finishes
  AND fetches the next in one EVALSHA, + the `EVALSHA→NOSCRIPT→EVAL` fallback `execute_raw/4`; dives states-as-locations ·
  read-decide-write-in-one-evalsha · evalsha-and-noscript, door→E2/E6), **R3.05 blocking-vs-polling**
  (`EchoMQ.Worker.wait_for_job/2` → `do_wait_for_job/3`'s `BZPOPMIN` on the `emq:{queue}:marker` ZSET, woken by
  `ZADD marker 0 "0"` (`addBaseMarkerIfNeeded`), vs the Go `time.Sleep` poll; dives the-busy-poll-cost · blocking-pop ·
  the-marker-wake-up, door→E2/E6), **R3.06 workshop** (a no-dives capstone: a reliable Portal enrollment-job queue
  assembling R3.01–R3.05; at-least-once + Portal's idempotent `Portal.Enrollment.enroll/2` / `:already_enrolled` =
  exactly-once-in-effect, door→E2). **Verify (adversarial, orchestrator):** all 9 pages 9/10 (the only `links` FAIL is
  the intended `/echomq/*` cross-mount doors); no invented surface (every `Portal.*` real — `Portal.Enrollment.enroll`,
  `Portal.Engine.Core.authorize`/`decide`, `Portal.Enrollment.Events.LearnerEnrolled`, `Portal.Error` — every EchoMQ
  Lua/symbol cross-checked in `echo/apps/echomq`); all clamps spaced; `data-c` on every select button (0 missing);
  9 route-mirror md files; segmented route-tags; zero component-voice perceptual-verb hits; live routes 200, unbuilt R4
  404. **Defect caught — in MY OWN brief:** the packs (following `echo/CLAUDE.md` §5's stale table) named
  `Portal.Learning.enroll/2`; the R3.06 writer verified against the built code and cited the real
  `Portal.Enrollment.enroll/2` (the `Portal.enroll/2` facade delegates to it; there is NO `Portal.Learning` module).
  The served page was right; I corrected the two spec docs (spec ← code reconcile). **Other writer self-fixes:** R3.04
  and R3.05 each rephrased component perceptual-verb slips (sweep "finds"/worker "decides"/"waits for") to operational
  phrasing before reporting. Manifests relinked (R3 landing promotes all 6 modules to `built` cards + drops the in-build
  note; home map pills `soon→built`); `queues/llms.txt` + TOC + this dashboard synced (22/53, 42%, 86 html).

- **`/redis-write R3.01–R3.03` — the granular reliable-queue modules (12 pages) via senior-narrative-then-per-module fan-out.**
  A **senior redis-expert** explored the worker path, authored the build narrative `specs/queues/r3.progress.md`, and
  injected three persistent on-disk prompt packs (`r3.01.prompt.md` · `r3.02.prompt.md` · `r3.03.prompt.md`) — each a
  self-contained A+ build brief. Then redis-writers fanned out per module (wave 1 = R3.01 + R3.02 concurrent, wave 2 =
  R3.03 lone; hub-then-dives inside each agent). Built: **R3.01 processing-list** (`EchoMQ.Scripts.move_to_active/4` →
  `moveToActive-11.lua`'s `RPOPLPUSH wait→active` under a lock; dives list-wait-active · lmove-rpoplpush ·
  the-in-flight-list, door→E2), **R3.02 at-least-once** (producer-side `de:{id}` dedup `EchoMQ.Keys.dedup/2` +
  `removeDeduplicationKey-1.lua`; idempotent consumers grounded in `Portal.Engine` enrollment; dives
  at-least-once-semantics · idempotent-consumers · why-exactly-once-is-a-lie, door→E2/E6), **R3.03 stalled-recovery**
  (atomic `EchoMQ.Scripts.move_stalled_jobs_to_wait/4` → `moveStalledJobsToWait-8.lua` vs the non-atomic Go
  `StalledChecker` — the honest double-recovery-window contrast; dives lock-expiry-detection · two-phase-mark-recover ·
  atomic-vs-non-atomic, door→E6/E2). **Verify:** all 12 pages 9/10 (the only `links` FAIL is the intended `/echomq/*`
  cross-mount doors); no invented surface (only the real `Portal.Engine`, every EchoMQ key/Lua/symbol cross-checked in
  `echo/apps/echomq`); all clamps spaced; `data-c` on every select button (0 missing); 12 route-mirror md files;
  segmented route-tags; live routes 200, `/echomq/core` 404 by design. **Defects fixed (orchestrator):** one
  component-voice slip ("it assumes the worker died" → "treats the worker as dead") in the at-least-once hub + its md.
  **Honesty note:** R3.03 cites the as-built 8-key list from the Elixir wrapper `move_stalled_jobs_to_wait/4`
  (`stalled · wait · active · failed · stalled-check · meta · paused · marker`) over the drifted Lua header comment —
  the call site wins. Key notation standardized to the `{queue}` placeholder form to match the shipped chapter dives.
  Manifests relinked (R3 landing promotes the 3 modules to `built` cards; home map pills `soon→built`); TOC +
  `queues/llms.txt` + this dashboard synced.
- **`/redis-write R3 (strategic)` — Reliable Queues landing + 3 course-direction dives (4 pages).** The pivot chapter's
  forward-looking entry, authored via redis-expert fan-out (landing lone → dives in waves of ≤2). The landing surveys
  the course direction through R8 and opens the **R3 → E2/E5/E6** door into the **living EchoMQ course** (the new
  agile-spec course `docs/echomq/specs/emq/` + the cross-linking `echomq.toc.md`: E2 `/echomq/core` ← R3, E5
  `/echomq/batches` ⇄ emq.3, E6 `/echomq/lifecycle` ⇄ emq.4). Two mechanic dives grounded in the iconic Elixir worker
  path (`moveToActive-11.lua`'s `RPOPLPUSH wait→active`, `EchoMQ.Keys.dedup/2`, `moveStalledJobsToWait-8.lua`,
  `moveToFinished-14.lua` as one EVALSHA, `emq:{queue}:marker`+`BZPOPMIN`); one orientation dive grounded in the real
  course arc + the EchoMQ cross-link map. `/echomq/*` doors are real `<a href>` forward-doors (cross-mount, gate-flagged
  by design). Landing's 3 dive cards relinked `soon→built`; TOC + `queues/llms.txt` + dashboard synced. R8.07 capstone
  (course summary + invite to `/echomq`) deferred to a follow-up batch per the operator.

- **`/redis-write R2.05 + R2.06` — Hash-tag co-location + Workshop AUTHORED, then RECONCILED to the iconic-Elixir door
  (5 pages).** R2.05 hub + 3 dives (`the-tag-mechanic` · `crossslot-prevention` · `cluster-auto-detect`) + the R2.06
  capstone workshop, per-page redis-expert fan-out (hub lone, then dives/workshop ≤2 concurrent, rate-safe). **Reconcile
  (mid-build, operator-triggered `/reconcile`):** the first drafts grounded the **Go port AS EchoMQ** and doored "built
  next with this toolkit". Corrected against ground truth (`docs/echomq/echomq.roadmap.md` + `echo/apps/echomq`): the
  exemplar is the **iconic Elixir** `moveToActive-11.lua` / `EchoMQ.Scripts.move_to_active/4` (eleven `emq:{queue}:*`
  keys, one EVAL); the Go runtime is framed as the documented **Elixir-cluster-gap filler** (`cluster.go`
  `GetClusterSlot`/`ValidateHashTags`, not "EchoMQ"); and the `→ EchoMQ` door is a real `<a href="/echomq">` to the
  designed **E0–E8 companion course** (`docs/echomq`, served `/echomq` when its build ships — a forward-door the `links`
  gate flags by design, like the manifests). Hub + `the-tag-mechanic` re-framed in place; `cluster-auto-detect` +
  `workshop` built correct from the start. Both manifests (home + landing) + the TOC + the chapter `llms.txt` relinked;
  **R2 COMPLETE (6/6)**. Lesson recorded: redis-patterns grounds in the **iconic Elixir** app and doors to the real
  EchoMQ course — the Go port is a labelled polyglot contrast, never a stand-in for EchoMQ.
- **`/redis-write R2.03 + R2.04` — Redlock (contrast) + Cross-shard consistency AUTHORED in parallel (8 pages).** Two
  modules built together via the senior-writer-narrative-then-per-page fan-out (prompt packs
  `specs/coordination/r2.03.prompt.md` + `r2.04.prompt.md`), 4 waves of 2 concurrent redis-expert agents (both hubs,
  then dives interleaved), zero socket drops. **R2.03 redlock** (`majority-of-n` · `clock-assumptions` ·
  `single-instance-enough`) — taught as a CONTRAST: verified **zero** `redlock` in `echo/apps/echomq` and
  `apps/echomq-go` (the lone Go hit is the substring in the test name `TestStalled_RequeuesExpiredLock`), so the module
  grounds in the absence — EchoMQ's single-Redis lease (`Keys.lock/2` + `LockManager`'s one-timer renewal) is the road
  taken, and a queue's idempotent work + `moveStalledJobsToWait` recovery is why majority-of-N is not needed. **R2.04
  cross-shard-consistency** (`torn-writes` · `version-tokens` · `commit-markers`) — grounds in EchoMQ's **prevention**:
  `apps/echomq-go/pkg/echomq/cluster.go` `GetClusterSlot` = CRC16 % 16384 + `validateClusterCompatibility`
  (`worker_impl.go:413`) building the six sample keys → the real warning *"Multi-key Lua scripts may fail with CROSSSLOT
  errors in cluster mode."*; detection is the fallback when keys cannot share a slot. All 8 gated STATUS: PASS
  (authoritative re-gate after the link graph closed; 16/16 inline scripts parse; voice / no-invent / clamp /
  2-col-refs / md-bijection / hub-h2-order all verified). Agents self-caught voice traps (did not copy the sources'
  `believe` / `see`; fixed `decides` / `want` / `notice` / `just` → mechanism verbs). Both manifests relinked
  (R2.03+R2.04 `soon→built`; also repaired the stale R2.01/R2.02 `soon` pills in the home map → home now 12 built);
  chapter `llms.txt` + 2 module `llms.txt` synced. DOOR-NOT-DEPTH honoured — one verified excerpt + a forward door per
  page. **Next: R2.05 hash-tag co-location.**
- **`/redis-write R2.02` — Distributed locking AUTHORED (4 pages).** Hub + 3 dives (`set-nx-px` · `fencing-tokens` ·
  `lease-renewal`) via the same senior-writer-then-per-page fan-out (prompt pack `specs/coordination/r2.02.prompt.md`;
  hub lone → 2 dives → 1 dive lone — all held). **Grounding (Elixir `echo/apps/echomq`, DOOR not depth):** the lock
  key `EchoMQ.Keys.lock/2` → `emq:<queue>:<jobId>:lock` (`keys.ex:206`); the token-checked `extendLock-2.lua`
  (`GET==token then SET … PX; SREM stalled`) + `releaseLock-1.lua` (`GET==token then DEL`); `extend_lock/5` /
  `extend_locks/5` / `release_lock/4`; and the star — **`EchoMQ.LockManager`** (`lock_manager.ex`), the one-timer
  batch renewal that realizes the chapter-spec's "one timer per worker." The `fencing-tokens` dive cites the real
  Kleppmann/Sanfilippo fencing debate as Sources. **Verify:** 4/4 PASS; no `Portal.*` invented, every EchoMQ name
  real before citing (`untrack_job/2` arity confirmed, not a miscite); clamp spaced; 2-col refs ×4; hub lede = source
  summary + `<h2>`s in source `##` order; **md bijection 4↔4**; `/elixir/pragmatic/cqrs` resolves. Voice: agents
  self-caught + fixed `just`/`remembers`/`our token`/`knows`; the orchestrator fixed one borderline `manager tracks` →
  `records` (kept the `track_job/3` citation). Landing relinked (R2.02 `soon→built`); module `llms.txt` added.
  **Next: R2.03 redlock** (contrast).
- **`/redis-write R2.01` — Atomic updates AUTHORED (the first R2 teaching module; 4 pages).** Built the hub +
  3 dives (`watch-multi-exec` · `lua-for-logic` · `shadow-key-bulk`) via the **senior-writer-narrative-then-per-page
  fan-out** pattern: the orchestrator gathered Sources + verified grounding + wrote the chapter narrative
  (`specs/coordination/r2.progress.md`) and the per-module prompt pack (`specs/coordination/r2.01.prompt.md`, one
  self-contained brief per page), then fanned out one `redis-expert` per page — **hub lone → 2 dives → 1 dive lone**
  (rate-safe; all held, no socket drops). **Grounding source = the user's two directives (2026-06-07):** (1) the
  authoritative EchoMQ source for our context is the **Elixir** app `echo/apps/echomq` (the real `priv/scripts/*.lua`
  + `EchoMQ.Scripts`/`Keys`/`LockManager`), not just the Go port; (2) **DOOR, NOT DEPTH** — redis-patterns cites ONE
  verified excerpt as proof + doors forward to prepare the learner for EchoMQ's "under the hood"; the dedicated EchoMQ
  course covers every Lua script. R2.01 grounds in `EchoMQ.Scripts.move_to_active/4` (`scripts.ex:806`) →
  `moveToActive-11.lua` (11 keys, one atomic move), `execute_raw/4` (EVALSHA→NOSCRIPT→EVAL), `execute_transaction/2`
  + `add_standard_jobs_pipelined/3` (MULTI/EXEC all-or-none) — every name verified real before citing. **Verify:**
  4/4 PASS; voice CLEAN (nouns + pronouns — 3 agents each self-caught + fixed a gate-invisible component-verb slip:
  `decides`/`sees`/`just`); no `Portal.*` invented; clamp spaced; 2-col refs ×4; hub lede = source opening summary +
  `<h2>`s in source `##` order; **md bijection 4 html ↔ 4 route-mirror mds**; `/elixir/pragmatic/cqrs` resolves; all
  8 `<script>` blocks parse. Landing relinked (R2.01 `soon→built`; stays a manifest, `links` FAIL on the unbuilt
  R2.02–R2.06 by design). **Next: R2.02 distributed-locking** (`Keys.lock/2` + `extendLock-2.lua` + `LockManager`
  one-timer batch renewal).
- **`/redis-reconcile R0` — Overview reconciled; the BUILT course is now uniformly conformant + a clean md bijection.**
  R0 is all **layout-only** (orientation: no `content/*.md.txt` spine → no hub re-root). R0.2 (Redis under Portal) +
  R0.3 (Patterns become protocol) given 2-col refs on every dive + 4 route-mirror mds each; the home
  (`markdown/index.md`, the full R0–R8 map) + overview landing (`markdown/overview.md`) mds authored by the
  orchestrator (landings already 2-col). Voice fixes: R0.3 "knows or cares"→"depends on"; R0.2 "Portal decides"→
  "resolves a call" ×2, "surface never sees"→"never receives", "state decides"→"determines". **DEFECT in the
  EXEMPLAR, caught by a redis-expert:** `caching/cache-aside/miss-fill` shipped "it never sees the hit-or-miss branch"
  — a perceptual verb on the web app via a PRONOUN subject ("it"), which the noun-keyed voice grep misses; fixed →
  "never handles", re-gated PASS, and a course-wide **pronoun-subject spot-check** (it/they + perceptual verb) added —
  now CLEAN course-wide. **Convention drift fixed:** `cache-stampede-prevention`'s hub md was at
  `…/cache-stampede-prevention/index.md` → moved to the canonical `…/cache-stampede-prevention.md` (hub md sits beside
  the dive dir, never inside it). Method: R0.2+R0.3 as a 2-agent wave (R0.2 dropped on a socket; recovered via a LONE
  agent — even 2-concurrent is not drop-proof, lone agents held). **Verify:** 8/8 R0 teaching pages PASS; the two
  landings stay route manifests (`links` FAIL on unbuilt routes by design); **course-wide md bijection 40 served ↔ 40
  route-mirror mds** (+ the `branded-cache-aside.md` depth exemplar); pronoun + noun voice CLEAN; `/elixir` links
  resolve; clamp OK. **The whole built course — R0 (10) + R1 (29) + R2 landing (1) = 40 pages — is conformant; the
  `/redis-reconcile` rollout is COMPLETE. Remaining work is AUTHORING new modules (R2.01+), not reconciling.**
- **`/redis-reconcile R1` — the whole Caching chapter brought to uniform conformance.** The 5 remaining built modules
  reconciled (cache-aside + cache-stampede-prevention were already done): **write-through, write-behind,
  client-side-caching, session-management** each **hub-rerooted** (lede ← source opening summary; `<h2>`s reordered to
  the source `##` order — verified line-by-line against each `content/*.md.txt`) + all 4 pages 2-col refs + 4
  route-mirror mds; **workshop** reconciled **layout-only** (rules 2+3 — capstone, no single source, hub deliberately
  NOT re-rooted) + 4 mds; the **R1 landing md** (`markdown/caching.md`) authored. Built via **waved redis-expert
  fan-out**: the first 4-concurrent wave dropped 2 agents on rate-pressure socket closes (≈140s, vs ≈650s for the
  survivors) → recovered with a **safer 2-agent wave** (held clean) + the workshop via a lone agent; landing md +
  orphan-check by the orchestrator. **Gate-invisible voice-on-component slips the cms gate missed, fixed:**
  `client-side-caching/invalidation-push` "application observes" ×2 (prose + a JS readout string),
  write-through `consistency` "observe"→"served"/"return" + `latency-cost` "decides"→"determines",
  write-behind "client sees success"→"receives" + a stray "simply", workshop "notice"→"react"/"tracks"→"clears".
  **Verify:** 28/28 module pages STATUS: PASS; landing stays a route manifest (`links` FAIL on unbuilt R3–R8 by
  design); md bijection 29 served ↔ 29 route-mirror mds (+ the intentional `branded-cache-aside.md` depth exemplar);
  `Portal.Auth`/`Portal.Error` the only `Portal.*` cited (both real); all 7 distinct `/elixir` cross-links resolve on
  disk; clamp spaced. **R1 = 7/7 modules + landing, all conformant.** Next reconcile gap: R0 (R0.1 home/overview,
  R0.2, R0.3) — still on single-column refs / no route-mirror md.
- **`/redis-reconcile caching/cache-aside` — module brought to full conformance (first reconcile run).** The two
  un-retrofitted dives were dives-light: `invalidation` and `ttl-staleness` each given the **two-column References**
  block (`.refs` grid + two child `<div>`s) and a **route-mirror md** (`markdown/caching/cache-aside/{invalidation,
  ttl-staleness}.md`). One gate-invisible **voice-on-component** slip fixed — `ttl-staleness`'s "the web app sees"
  → "receives" (the cms voice gate does not catch a perceptual verb on a software component). The hub (`index.html`,
  source-spine + 2-col refs) and `miss-fill` were confirmed already conformant; no hub re-root needed, so the dive
  list, TOC, and content-map are unchanged. All 4 pages STATUS: PASS; 2-col refs ×4; mds ×4; `Portal.*` clean (cache
  family grounds in the facade, not a `Portal.X` call); both `/elixir` cross-links resolve on disk; clamp OK. The
  retrofit engine validated end to end on a real module.
- **R2 landing built + craft feedback loop.** Three binding craft rules added (source is the content spine · 2-column
  References · route-mirrored md-first at `docs/redis-patterns/markdown/<route>.md`) — encoded in skill §5a,
  redis-expert #1/#6, redis-write Step 2/3, and `toolkit/README.md`. Applied by hand to `caching/cache-aside` (hub
  re-rooted on the source spine) + `caching/cache-aside/miss-fill` (2-col refs + md), then **validated by delegation**:
  a `redis-expert` autonomously refined `caching/cache-stampede-prevention` (hub re-rooted to the source's 5-section
  spine + ported comparison table, all 4 pages 2-col refs + 4 md, real X-Fetch formula + token-checked Lua release
  preserved, 2 voice slips self-fixed) — 4/4 PASS, source `<h2>` order exact. **R2 · Coordination landing built** (`coordination/index.html` + `markdown/coordination.md`,
  PASS) — the first `→ EchoMQ` chapter; modules R2.01–R2.06 planned.
- **R0.3 COMPLETE — R0 closed.** "Patterns become protocol" (hub + the-four-layers · the-immutable-core ·
  the-door-to-echomq) built + verified; all 4 pages PASS, every EchoMQ fact (the 53-script core, `atm`/`ats`
  compressed fields, the `echomq-ex:5.62.0` version strings, `moveToActive-11`) spot-checked real in `docs/echomq/`,
  the EchoMQ-course door named in prose only. The R0.3 tile on the overview landing flipped `soon`→`built`
  (activated). **R0 = 3/3 modules; R1 = 7/7. Course at 10/53 (19%); next gap R2 · Coordination.**
- **R1 COMPLETE + R0.3 launched** — R1 wave 2 (R1.05 stampede, R1.06 sessions, R1.07 workshop) built + verified +
  relinked; all 12 pages PASS, no-invent clean (R1.06's `Portal.Auth.sign_in/2` verified real in
  `echo/apps/portal/lib/portal/auth.ex:37`), R1.05's X-Fetch formula Monte-Carlo-checked. Three residual perceptual
  verbs in the wave-1 pages (`surface sees`, `client decides`) normalized. R1 = landing + 7 modules (29 pages). The
  R0.3 "Patterns become protocol" agent is now in build (hub + 3 dives, grounded in the EchoMQ four-layer model).
- **R1 wave 2 launched** — R1.05 stampede prevention, R1.06 session management, R1.07 workshop (each hub + 3 dives),
  bootstrapping from the built R1.01 pages and mining their mapped content sources.
- **content map + served llms.txt** — authored `redis-patterns.content-map.md` (all 30 source files → modules, with
  per-page techniques) and the served `llms.txt` maps for the course root, R0, R0.2, R1, and the four R1.01–R1.04
  modules. (A `gen_llms.py` toolkit generator is the Stage-2 automation.)
- **R1 wave 1 complete + verified + relinked** — R1.01 cache-aside, R1.02 write-through, R1.03 write-behind, R1.04
  client-side-caching, all 16 pages gated PASS; adversarial sweep clean (only real `Portal.Error`, all `/elixir`
  cross-links resolve on disk, one perceptual-verb voice fix in write-behind); the home + R1-landing cards flipped
  `soon`→`built`. `/redis-patterns` confirmed already wired in `main.go` (routes 467–468).
- **R1 wave 1 launched** — four `redis-expert` agents building R1.01 cache-aside, R1.02 write-through, R1.03
  write-behind, R1.04 client-side-caching (each a hub + 3 dives), bootstrapping the design system from the built R0.2
  redis pages. Verify + relink on completion.
- **R0.2 verified + relinked** — adversarial no-invent sweep clean (only real `Portal.Error` / `Portal.enroll`); the
  overview landing's R0.2 card flipped `soon`→`built`.
- **R1 foundation** — authored the R1 Caching chapter landing + the seven per-module specs `r1.01.md`…`r1.07.md`;
  began the module fan-out (one `redis-expert` per module, hub + 3 dives, in waves of ≤4). Dashboard stood up.
- **R0.3 spec** — authored the R0.3 quad (`r0.3.md` / `.stories.md` / `.llms.md` / `.prompt.md`); grounded the
  four-layer model in `docs/echomq/`. Pages pending.
- **R0.2 built** — Redis under Portal: hub + `the-facade-seam` + `two-roles` + `reserved-tier`, all gated PASS.
- **R0.1 built** — the course home (`index.html`, the full R1–R8 map) + the overview landing (`overview/index.html`,
  R0 module cards + the `.upnext` chapter grid). Both are route manifests (forward-links to unbuilt routes expected).

## The waves (R1)

| Wave | Modules | Pages | Status |
| --- | --- | --- | --- |
| Landing | R1 chapter landing | `caching/index.html` | ✓ built |
| W1 | R1.01 cache-aside · R1.02 write-through · R1.03 write-behind · R1.04 client-side-caching | 4 hubs + 12 dives | ✓ built |
| W2 | R1.05 cache-stampede-prevention · R1.06 session-management · R1.07 workshop | 3 hubs + 9 dives | ✓ built |

Each wave: spawn one `redis-expert` per module (each authors its hub + 3 dives from `r1.0N.md` + an embedded brief),
gate every page to PASS, then the orchestrator relinks the home + chapter-landing cards and re-counts this dashboard.

---

> Part of the jonnify toolkit. The TOC maps; the roadmap plans + grounds; the chapter specs define; this dashboard
> tracks the build. Never commit from an authoring agent — the operator commits batches out-of-band.
