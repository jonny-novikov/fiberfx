# emq-4 · groups deepened — chapter-open audit ledger

> Scope `emq-4` (the Movement-II opener). This run **opens the chapter spec-only** — it authors the
> spec set, it ships **no production code**. The frozen per-rung build ledgers (`emq-4-1.progress.md`
> …) are written later when each rung builds. This file is the live audit trail of the chapter-open.
> Records freeze: entries below are appended, never rewritten.

## T-1 · Director bootstrap derivation (2026-06-18)

**The rung.** emq.4 = **groups deepened**, the Movement-II opener. The groups *basics* shipped in the
foundation as `EchoMQ.Lanes` (`enqueue/5` `@genqueue` · `claim/3` `@gclaim` · `pause/3` `@gpause` ·
`resume/3` `@gresume` · `limit/4` `@glimit` · `depth/3`) + `EchoMQ.Metrics.lane_depth/3,lane_depths/3`,
gated B3.4 "Fair Lanes" PASS 8/8 (G1–G8). emq.4 *deepens* that surface; it invents no new family.

**5W.** *What* — the four deepenings the canon names (roadmap §95-97/§118): the control plane, group-aware
recovery, the park-don't-poll metronome, weighted/deficit rotation + the starvation drill. *Why* — a
multi-tenant bus needs group-level operation, recovery, fairness, and no busy-poll; the basics give
rotation but not these. *Who* — multi-tenant operators of the bus; codemojex is the worked consumer
(per-player lanes). *Where* — `echo/apps/echo_mq` only (`EchoMQ.Lanes` + `EchoMQ.Metrics`); no third app.
*When* — Movement I closed (conformance 52/52); Movement II opens on a complete core.

**Slot — RULED.** The displaced groups family's rung slot is **emq.4**, ruled at the design's Stage-1b
(roadmap §137 "seam 2 closed"; design §10 seam 2 / §4 cluster 2). No open slot fork.

**Do-nothing baseline.** The basics already serve codemojex's per-player lanes. emq.4 is *pattern depth a
multi-tenant bus needs*, not a correctness gap — so it decomposes into independent, individually-shippable
rungs, each one deepening of the shipped surface, none a wire change (additive registration = protocol minor).

**Smallest change that preserves correctness.** Each rung adds verbs/scripts over the **declared** `g:`-segment
keyspace and the shipped ring; every new Lua key declared-or-`KEYS[n]`-rooted (A-1); server clock where a lease
is touched (4.2/4.3); the shipped `@genqueue/@gclaim/@gpause/@gresume/@glimit` stay byte-frozen unless a rung
declares an edit (4.4 may; Apollo mandatory there).

## D-1 · Fork ruling (Operator, via AskUserQuestion, 2026-06-18)

The chapter spine + run scope were the open forks; ruled before any spawn (skill Step 0):

- **Spine = canon order.** `emq.4.1` control plane (group move/re-assignment; deepened pause/resume/limit/drain;
  re-aims the RETIRED `changePriority-7` → lane re-assignment + `getCountsPerPriority-4` → `Metrics.lane_depths`)
  · `emq.4.2` group-aware recovery (group-scoped stalled-sweep / reap that respects the ring) · `emq.4.3`
  park-don't-poll metronome (the wake/notify beat; consumers park, no poll) — **HIGH-risk** (process/lease
  surface) · `emq.4.4` weighted/deficit rotation + the starvation drill (fair-share beyond round-robin) — the
  capstone.
- **Scope = open chapter, spec-only.** Author `emq.4.specs.md` + the chapter triad `emq.4/emq.4.{md,stories,llms}`
  + the four carves `emq.4/emq.4.rungs/emq.4.{1..4}.md` + the `emq.progress.md` update. **No production code** this
  run; each rung builds later via its own `/echo-mq-ship`.

## Formation (right-sized — spec-only, no code)

Director bootstrap (this T-1/D-1) → **Venus** (`echo-mq-architect`) authors the chapter-level set → Director
verify (reconcile vs as-built `EchoMQ.Lanes`/`Metrics`, NO-INVENT, traceability, shape mirrors emq.3) → fan-out
**4 architects** carve `emq.4.1–4.4` against the locked chapter body → Director verify (cross-consistency) →
`emq.progress.md` fold (emq.4 → SPECCED) → one pathspec commit (entangled-tree-aware: the emq.4 spec set ONLY).
**No Mars** (no code). **Apollo** mentors after, out of band.

**Gate posture (honest).** Spec-only → the gate is **reconcile + traceability + NO-INVENT**, not compile /
conformance / the ≥100 determinism loop (running those would forge load this run does not introduce — the
emq.2.1 posture). Each rung runs the full code gate when it builds.

## {emq-4-thinking} Thinking

### T-2 — emq.4 chapter-open reconcile (as-built grounding for the 4 chapter files)

AS-BUILT SURFACE (re-probed on disk, echo/apps/echo_mq):
- EchoMQ.Lanes (lanes.ex): enqueue/5 @genqueue · claim/3 @gclaim · pause/3 @gpause · resume/3 @gresume · limit/4 @glimit · depth/3. Keyspace family (all braced emq:{q}:, via Keyspace.queue_key): g:<group>:pending (lane ZSET, score-0), ring (rota LIST, LMOVE LEFT->RIGHT rotation), paused (SET), glimit (HASH), gactive (HASH), wake (LIST capped 64). @gclaim derives lane in-script as ARGV[1]..'g:'..g..':pending' (ARGV[1]=queue_key(queue,"") — the ratified ARGV-slot-rooted A-1 convention). Server clock TIME for the lease (gclaim:50-52).
- EchoMQ.Metrics (metrics.ex): lane_depth/3 (delegates Lanes.depth) · lane_depths/3 @lane_counts (ZCARD per g:<group>:pending, branded-gated). MODULE IS EchoMQ.Metrics — confirms the task's lane_depths/3 re-aim target.
- @reap (jobs.ex:341) IS ALREADY GROUP-AWARE: an expired grouped lease ZADDs back to its lane g:<g>:pending (not flat pending), HINCRBY gactive -1, re-rings if serviceable, pushes wake. Conformance scenario stalled_group already ships ("a lapsed GROUPED lease recovers into the lane g:<g>:pending set, not the flat pending"). => emq.4.2 DEEPENS a shipped group-aware reap (NORMAL-risk CONFIRMED).
- EchoMQ.Consumer (consumer.ex:91-149): the park-don't-poll loop IS SHIPPED — reap -> promote -> drain(rotating claim) -> park (BLPOP wake, beat fallback) -> loop. wake-push baked into @genqueue/@gclaim/@gresume/@glimit/@reap/@complete/@retry/@promote. Single per-queue wake LIST shared by all lanes. spawn_link, not GenServer. "Chapters 3.4 and 3.5."
- Conformance live count = 52 (conformance_scenarios_test.exs:80 "the fifty-two names in run order"). Lane scenarios present: rotate, pause, limit, lane_depth, stalled_group. Re-pin in BOTH conformance_scenarios_test.exs + conformance_run_test.exs.

CANON RE-AIM RECORD (emq.commands/features/groups/, verbatim PROPOSED emq.4 deltas):
- changePriority-7 RETIRED -> "no priority re-score; Lanes group re-assignment / weighted rotation (emq.4)". No numeric priority; mint order IS the order theorem; per-group Lanes replace priority.
- getCountsPerPriority-4 RETIRED -> re-aimed to EchoMQ.Metrics.lane_depths/3. PROPOSED emq.4: intra-lane priority dimension = ZCOUNT over a score window on the SAME g:<group>:pending ZSET — no new key.
- addPrioritizedJob-9 SHIPPED (Lanes.enqueue/5). PROPOSED emq.4: intra-group priority = non-zero lane score on existing g:<group>:pending ZSET — no new key family, never a global prioritized key or pc counter.

RECONCILE DELTA vs the Operator-ruled spine (D-1): the task spine grades emq.4.3 "founds a process/lease surface, HIGH-risk." As-built: the park-don't-poll CORE is SHIPPED (Consumer + the wake protocol). => emq.4.3 DEEPENS the metronome (lost-wakeup hardening / per-lane wake / backpressure beat / multi-consumer fan-out), and the HIGH-risk grade attaches to whatever new process/lease surface the deepening introduces. SURFACED as a fork to the Director (do not silently re-grade or contradict the spine).

NO-INVENT: every proposed emq.4 verb traces to a canon re-aim line or an as-built key/script. No new key family proposed for 4.1/4.4 (re-weight the existing g:<group>:pending ZSET + the ring). Undetermined script bodies WITHHELD (pinned at each rung's pre-build reconcile).

## {emq-4-decisions} Decisions

### D-2 — emq.4 chapter-level triad authored (4 files, SPEC-ONLY, no production code)

Authored EXACTLY the 4 chapter-level files (the emq.4.rungs/emq.4.N carves NOT written — separate fan-out):
1. docs/echo_mq/specs/emq.4.specs.md (94 lines) — the BCS-side line-spec mirror.
2. docs/echo_mq/specs/emq.4/emq.4.md (256 lines) — the authoritative chapter body.
3. docs/echo_mq/specs/emq.4/emq.4.stories.md (187 lines) — chapter stories + coverage map.
4. docs/echo_mq/specs/emq.4/emq.4.llms.md (175 lines) — the agent brief.

The carve is the Operator-ruled spine (D-1), authored verbatim, NOT re-decomposed: emq.4.1 control plane (NORMAL) · emq.4.2 group-aware recovery (NORMAL) · emq.4.3 park-don't-poll metronome (HIGH) · emq.4.4 weighted/deficit + starvation drill (HIGH iff @gclaim edited).

VERDICT: BUILD-GRADE as a FAMILY SPEC (no per-rung build this cycle). Every public surface MATCH against as-built (lanes.ex/metrics.ex/jobs.ex@reap/consumer.ex re-probed on disk) or a canon re-aim line. Conformance count pinned at the live 52. All cross-file links resolve; the four ./emq.4.rungs/ links are intentional forward refs (the un-authored fan-out, same pattern as emq.3.md).

RECONCILE DELTA surfaced as FORK A: the ruled spine grades emq.4.3 "founds a process/lease surface"; as-built finds the park-don't-poll CORE already shipped (Consumer + the wake protocol). => emq.4.3 DEEPENS it (lost-wakeup hardening / per-lane wake / multi-consumer fairness); HIGH-risk + Apollo stand either way, but the touch-set differs. Recommended Arm A (deepen), settle before the emq.4.3 build. Plus Fork B (weighted-rotation mechanism — deficit counter vs weighted multi-pop vs per-lane budget; decides whether @gclaim is edited) and Fork C (intra-group priority — land at 4.1 vs park; recommend park to keep lanes score-0).

## {emq-4-progress} Progress

### P-1 — emq.4 per-rung carves authored (4 files, the Q2-A deliverable; SPEC-ONLY, no production code)

Authored the 4 per-rung spec-body seeds (NOT full build-time quads — each grows its triad at build):
- docs/echo_mq/specs/emq.4/emq.4.rungs/emq.4.1.md (186 lines) — control plane (NORMAL); carries Fork C (intra-group priority: land vs park, recommend park). INV1/INV4/INV6 (carried as 4.1-INV1..5). First buildable.
- docs/echo_mq/specs/emq.4/emq.4.rungs/emq.4.2.md (168 lines) — group-aware recovery (NORMAL); carries NO Operator fork (the build choice additive-beside-vs-edit flagged for the reconcile, both surfaced, not pre-decided). INV3/INV5/INV6 (carried as 4.2-INV1..5).
- docs/echo_mq/specs/emq.4/emq.4.rungs/emq.4.3.md (198 lines) — the park-don't-poll metronome (HIGH); carries Fork A (deepen the shipped metronome [Arm A, rec] vs found a new blocking primitive [Arm B]; settles before build, touch-set depends on it). Apollo MANDATORY + ≥100 loop. INV7/INV5 (carried as 4.3-INV1..5).
- docs/echo_mq/specs/emq.4/emq.4.rungs/emq.4.4.md (194 lines) — weighted/deficit rotation + starvation drill (HIGH iff @gclaim edited); carries Fork B (deficit-counter-on-ring[Arm1,edits @gclaim] vs weighted-multi-pop[Arm2,additive] vs per-lane-budget[Arm3,couples 4.3]; decides the risk grade). Byte-freeze every unedited @g*. INV7/INV3 (carried as 4.4-INV1..6).

FRESH RECONCILE (re-probed on disk before citing):
- 4.1: NO move/reassign/transfer verb exists -> built forward (ZREM g:<src>:pending + ZADD g:<dst>:pending, one slot atomic). admin.ex:109 drain/3 @drain (del_job enumerates lanes, admin.ex:137-194) = deepened-drain precedent.
- 4.2: TWO shipped group-aware recovery surfaces — @reap (jobs.ex, server-clock scan, grouped lease -> lane) AND EchoMQ.Stalled.check/3 (stalled.ex:29-31,76, stall-threshold + dead-letter, grouped -> lane). The delta is the group-SCOPED entry (recover one named group on demand), NOT a new recovery shape => NORMAL confirmed.
- 4.3: park-don't-poll CORE shipped — Consumer spawn_link (consumer.ex:40), beat_ms=1000 (:58), loop reap->promote->drain->park (:91-97), park = BLPOP emq:{q}:wake <beat> (:144-147); single per-queue wake LIST capped 64 (LTRIM 0 63) shared by all lanes/consumers => the reconcile delta surfaced as Fork A.
- 4.4: @gclaim ring rotation = LMOVE KEYS[1] KEYS[1] LEFT RIGHT (lanes.ex:38) + ZPOPMIN head (:41) + server-clock lease TIME (:50-52); rotate scenario "two lanes claim in strict rotation" = the equal-share precedent the weighting deepens.

All links resolve; conformance count pinned at the live 52 in every carve. Scope: only emq.4.rungs/ (4 files) new from me; the ?? test/stories/*.exs are the Operator's out-of-band work (untouched). NO git.

WITHHELD as undetermined (NOT invented; pinned at each rung's pre-build reconcile): every proposed verb NAME (4.1 reassign/move, 4.2 reap_group/:group-option, 4.3 the precise lost-wakeup mechanism, 4.4 the weight home/rotation) + every script BODY; 4.2's additive-beside-vs-edit; 4.3's per-lane-wake §6-grammar question (surfaced, not assumed); 4.4's weight representation (gweight HASH field candidate, no new key family).

## {emq-4-verify} Verify (Director — independent)

### V-1 — the chapter-level set (BUILD-GRADE)

Independent as-built re-probe (NOT a glance): every surface Venus cited is REAL on disk — `Lanes.{enqueue/5,claim/3,pause/3,resume/3,limit/4,depth/3}` + `@genqueue/@gclaim/@gpause/@gresume/@glimit` + `lane_key!/2` raising unless `EchoData.BrandedId.valid?` (lanes.ex:197-198, INV4 confirmed) + `Metrics.{lane_depth/3,lane_depths/3,@lane_counts}` + `Jobs.@reap` group-aware (jobs.ex:341) + `Consumer` BLPOP-wake park loop (consumer.ex:147) + conformance `{:ok, 52}` with `rotate`/`pause`/`limit`/`lane_depth`/`stalled_group`. **NO-INVENT: PASS** (zero fabricated surface). Shape mirrors emq.3 (specs mirror · body+carve+INV1-8+forks+DoD · stories+coverage · llms+requirements+topology+seeds); forward-tense; traceability closure (story→rung→INV); scope spec-only (boundary `echo/apps` clean); links clean (only `emq.4.rungs/` forward-refs). **Fork A NOT harmonized** — held open by design (the spine's "founds" + the as-built "deepens" = the Operator's call at the 4.3 build); independently confirmed the park loop IS shipped (consumer.ex:144-147) → Arm A is the likely resolution, but not pre-decided.

### V-2 — the per-rung carves (BUILD-GRADE)

Independent re-probe of the NEW citations: **`EchoMQ.Stalled.check/3` group-aware CONFIRMED** (stalled.ex — "a grouped job recovers into its lane, mirroring the reaper's group branch") — the 4.2 sharpen is grounded (TWO shipped group-aware recovery surfaces; NORMAL grade grounded harder than the body had it); `admin.ex drain/3:109`, `consumer.ex` `spawn_link:40`/`beat_ms:58`/`BLPOP:147`, `@gclaim` `LMOVE:38`/`ZPOPMIN:41`/`TIME:50` — all real. **NO-INVENT: PASS**. Each carve mirrors emq.3.1.md (status/risk · §0 · Goal · 5W · Scope · INV-subset · fork · DoD · anchors) and elaborates its body ladder row; forks match (4.1→C · 4.2→build-choice · 4.3→A · 4.4→B); proposed verbs marked, withheld where undetermined; conformance 52 pinned in each. Scope: only the 4 carves new; **ZERO `.ex`/`.exs` written** (the `?? test/stories/*.exs` are the Operator's out-of-band work). Links resolve.

## {emq-4-close} Close

### Z-1 — emq.4 chapter OPEN (SPEC-ONLY) complete

**Deliverable (Q2-A, complete):** `emq.4.specs.md` (94) + `emq.4/emq.4.{md(256),stories(187),llms(175)}` + `emq.4/emq.4.rungs/emq.4.{1(186),2(168),3(198),4(194)}.md` + this ledger + the `emq.progress.md` fold (emq.4 📋→📐 **SPECCED**, the 4.1–4.4 spine · the B3.4 grounding row · the roll-up).

**Forks carried forward to the per-rung builds (NOT resolved this cycle):** Fork A (emq.4.3 — deepen vs found; settle BEFORE the build, touch-set depends on it) · Fork B (emq.4.4 mechanism — decides the `@gclaim`-edit risk) · Fork C (emq.4.1 intra-group priority — rec park) · plus 4.2's additive-beside-vs-edit build choice. Build order: **4.1** (first buildable) → **4.2** → **4.3** (Apollo MANDATORY) → **4.4**.

**Gate posture honored:** spec-only → reconcile + traceability + NO-INVENT (no compile / conformance / ≥100 loop — running them would forge load this run did not introduce). Boundary clean (no production code; `echo/apps` untouched by this run). **Apollo:** out of band, NONE mandatory this cycle (no process/lease build); emq.4.3's build makes Apollo MANDATORY.

**Commit (pending Operator go):** a tight LAW-4 pathspec — `docs/echo_mq/specs/emq.4.specs.md` + `docs/echo_mq/specs/emq.4/` + `docs/echo_mq/specs/progress/emq-4.progress.md` + `docs/echo_mq/emq.progress.md`. The tree is ENTANGLED (92 pre-staged foreign files in the index + `emq.roadmap.md` modified, none mine), so the commit is scoped via `git commit -F <msg> -- <pathspec>` (never a bare commit) and PRESENTED for the Operator's go before execution (CLAUDE.md: commit only when asked; the entanglement warrants the confirm).
