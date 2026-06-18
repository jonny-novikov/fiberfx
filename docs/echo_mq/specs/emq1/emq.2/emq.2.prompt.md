# EMQ.2.4 · the cluster-closing orchestration runbook — drive the parity close

> **Status: LIVE (2026-06-14).** This runbook drives the **emq.2.4** build — the FOURTH and FINAL rung of the
> emq.2 full-parity cluster (read → ops → watch → **close**) — and closes the cluster. It **replaces** this
> file's prior content (the retired v1→v2 *migration* runbook, itself superseded 2026-06-13 when emq.2
> re-scoped from "the migration path" to the **full-parity rewrite**; that runbook's history is recoverable
> via git). Authored at the **`emq-2-4` design cycle** (2026-06-14 — the features catalog
> [`../emq.features.md`](../../emq.features.md), the emq.2 ⇄ emq.2.3 reconcile, and the emq.2.4 triad). The
> `/x-mode` skill ([`.claude/skills/x-mode/SKILL.md`](../../../../.claude/skills/x-mode/SKILL.md)) binds the laws;
> the **`echo-mq-ship`** skill is the echo_mq binding; the inputs are the triad ([`./emq.2.4.md`](emq.2.rungs/emq.2.4.md)
> · [`./emq.2.4.stories.md`](emq.2.rungs/emq.2.4.stories.md)), the canon
> ([`../emq.design.md`](../../emq.design.md)), the carve ([`./emq.2.design.md`](emq.2.design.md)), the gap table
> ([`./emq.2.4.md`](emq.2.rungs/emq.2.4.md) §0), and the parity proof ([`../emq.features.md`](../../emq.features.md) Part B).

## The cluster in one paragraph

emq.2 is the **full-parity rewrite** of the v1 capability floor `echo_mq` lacks, carved read → ops → watch on
the dependency-and-concern boundary (the carve + the five ADRs: [`./emq.2.design.md`](emq.2.design.md)).
Three rungs are down: **emq.2.1** (the read plane, `EchoMQ.Metrics` — 10 verbs) shipped `7d98ef86`;
**emq.2.2** (the operator plane, `EchoMQ.Admin` + six `Jobs` mutations) shipped `76fc947c`; **emq.2.3** (the
watch plane, `EchoMQ.Events`/`Meter`/`Locks`(+`Locks.Core`)/`Stalled`/`Cancel` +
`Jobs.extend_lock(s)`) **shipped `3c6461ff`** (+ the docs fold `5a3fdd73`; conformance grew **32 → 37**; both
determinism flakes fixed at root; the ≥100 gate green 100/0; Apollo BUILD-GRADE). The **feature** parity for the carved floor is essentially
complete — the parity proof is [`../emq.features.md`](../../emq.features.md) Part B (every v1 capability → its v2
home → its rung → status; the one ruled-out row is `migration.ex`, ADR-0). The emq.2 ⇄ emq.2.{1,2,3} reconcile
(this design cycle, [`./emq.2.4.md`](emq.2.rungs/emq.2.4.md) §0) found the residue concentrated in (a) a **small genuine
feature residue** (G1 the rate-gate fork, G2 the metrics `:data` series, G3 the `de:` orphan) and (b) the
Operator-flagged **TEST DEPTH** gap (v1 `echomq` **534** tests / 41 files / 195 describes vs v2 `echo_mq`
**201** / 28 / 36). **emq.2.4 closes both** and the cluster with it.

## The rung in one paragraph

emq.2.4 builds, inside `echo/apps/echo_mq` under the v2 laws (declared keys, branded `JOB`, server clock, the
`EMQ*` refusals, the inline `Script.new/2` law, the conformance additive-minor): **(1) the feature residue** —
the rate-gate resolution to the ruled fork arm (default **Arm 2**: the *consult-before-claim* contract + the
pure-read `is_maxed/2` unchanged, **no `@claim` edit**); the optional metrics `:data` rolling series (built, or
its recorded hold to emq.8 — D3 fixes which); the `de:` orphan documented as the declared-keys honest limit
(no sweep, no backref). **(2) the complete test suite** — the depth scenarios for the **shipped** read
(D5 `metrics_depth`), ops (D6 `admin_depth`), and watch (D7 `watch_depth`) verbs — multi-job, concurrent,
edge-case — each genuine new behavior a conformance scenario (additive minor, **the 37 prior byte-unchanged**),
the process-touching suites under the **≥100-iteration determinism loop**, the un-ported v1 depth **explicitly
attributed** (D8: the worker abstraction → emq.6, OTel → emq.8, distributed cancel → emq.6, flow → emq.3, the
scheduler → emq.1-shipped, the stress files → the loop). **INV2 is the honesty gate** — no test drives an
unshipped surface; a false-green is forbidden; "complete" means *v1's depth for the verbs `echo_mq` ships*, not
padded coverage. The contract is [`./emq.2.4.md`](emq.2.rungs/emq.2.4.md) (D1–D8, INV1–INV8).

## Mode

**Flat-L2** (a build + a gate + a verify), Director-supervised. **Not** the Design-Phase variant (the triad
exists — authored this cycle). **HIGH-RISK**: emq.2.4 is **process/mint-touching** (the watch depth suites run
the lock-plane timer + the stalled sweep and mint jobs) **and** carries an optional **shipped-script-touching
feature fork** (Arm 1 edits `@claim`/`@gclaim`) → **Apollo MANDATORY** (the §11.2 charter + `AskUserQuestion`)
+ the **≥100-iteration determinism loop** over the process-touching suites.

Scope slug: **`emq-2-4`** (dashed, no dots — `tool_x_*`/`TeamCreate` require `^[a-z0-9][a-z0-9-]*$`). Operator:
`jonny`. Workspace: `/Users/jonny/dev/jonnify`. Ledger: `docs/echo_mq/specs/emq-2-4.progress.md` (the design
cycle opened it: T-1/T-2 the ground truth, A-1/A-2 the gap table, D-1 the Director review, D-2 the carried
fork, L-1 the peer-hygiene notes — the build's T/D/L/Y append after these, records-freeze on the design half).

## Settled forks (the G1 rate-gate fork RULED — Arm 2, 2026-06-14)

Carried into the build, not re-litigated: the cluster contract (the carve read → ops → watch → **close**,
ADR-1); the **parity/family boundary** (ADR-2 — what emq.2.4 closes vs what emq.3/emq.6/emq.8/emq3.2 keep — the
gap table G5–G11 attributions); the **Arm A** cluster sequencing (settled, design §6, not reopened). The G4
"batch counts" candidate is **CONFIRMED NOT A GAP** (`get_counts/3` already takes a state list — ledger A-2).

**RULED — Arm 2 (Operator, 2026-06-14).** EMQ.2.4-D1 is SETTLED at spec time; the build proceeds to Arm 2 (no `@claim` edit) without a launch-time fork stop. The two arms are kept below as the decision record:

> **The rate-ceiling-into-claim wiring.** emq.2.1 named "the rate ceiling **refuses an over-ceiling claim**"
> (D6/US5) but shipped `is_maxed/2` as a **pure-read primitive** and routed the transition-side wiring to
> emq.2.2; emq.2.2 chose FORM-b for the queue-wide pause **precisely to avoid editing the shipped `@claim`** and
> did not wire the gate — so the auto-refuse is **unbuilt**, and closing it lands on emq.2.4 (editing a shipped
> script). The decision is the Operator's:
>
> - **Arm 1 — wire it into the claim transition.** `@claim`/`@gclaim` read `meta.concurrency` vs `ZCARD active`
>   FIRST and refuse `EMQRATE` (or short-circuit empty) before popping. *Operationally complete* — an
>   over-ceiling claim cannot succeed even if a caller forgets to consult `is_maxed/2`. **Cost:** edits emq.1's
>   **shipped** `@claim` + emq.2.2's claim path; the `claim`/`rate`/`limit`/`rotate` conformance scenarios
>   re-verified byte-identical-or-updated; the named **HIGH-RISK** shipped-script edit (Apollo re-verifies INV1
>   + the order theorem).
> - **Arm 2 — hold the pure-read primitive + document the contract (RECOMMENDED).** `is_maxed/2` stays the
>   read-and-refuse a claimer consults before `claim/3`; emq.2.4 ships **no `@claim` edit**; the triad documents
>   the *consult-before-claim* contract. **Also the more faithful v1 parity** — the v1 `isMaxed-2` is a
>   **pre-claim** read the worker calls, **not** a step inside `moveToActive-11.lua` — and it keeps emq.2.4's
>   whole risk surface to the **test suite** (the rung's primary mandate).
>
> **Resolution: Arm 2** (the Operator ruled 2026-06-14; Venus recommended, the Director concurred — ledger
> D-2/D-3). The triad is already authored to Arm 2, so there is **no re-scope**: emq.2.4 ships the
> consult-before-claim contract + the pure-read `is_maxed/2` unchanged, **no `@claim`/`@gclaim` edit**.
> EMQ.2.4-D1's gate is satisfied at spec time; `lanes.ex`/`@gclaim` drops from the Stage-6 pathspec (no
> claim-path edit); the build runs Arm 2 directly (EMQ.2.4-AS1 records the settled ruling, it no longer stops
> for it).

No new `emq.2.design.md` ADR is authored here — the boundary and the laws are design-settled, and the one open
question is an Operator ruling on a feature arm, not a design fork needing steelmanned arms. If the launch
review finds the fork needs a full ADR, that is a design-make stage the Operator inserts — flagged, not
pre-built.

## The as-built floor (verified at this design cycle, 2026-06-14 — the build's B0 RE-PROBES each; the lag-1 law)

Anchors drift; emq.2.3's commit (and any sibling rung) moves the `echo_mq` surface before emq.2.4 reads it —
the build's Stage-0 reconcile re-pins every line below:

- **Conformance = 37** (`conformance.ex:25` `scenarios/0`; the two pin tests `conformance_run_test.exs`
  `run/2 → {:ok, 37}` + `conformance_scenarios_test.exs` `@run_order` 37 names). INV1 holds the as-built count
  byte-unchanged at B0 — do NOT hardcode 37 if emq.2.3's commit moved it; the floor is whatever exists at the
  pre-build reconcile.
- **The read plane (emq.2.1, shipped)** — `EchoMQ.Metrics` (`metrics.ex`): `get_counts/3` (takes a state
  **list**), `get_job/3`, `get_job_state/3`, `get_metrics/3`, `get_deduplication_job_id/3`,
  `get_rate_limit_ttl/3`, `get_global_rate_limit/2`, `is_maxed/2`, `lane_depth/3`, `lane_depths/3`.
- **The operator plane (emq.2.2, shipped)** — `EchoMQ.Admin` (`admin.ex`): `pause/2`, `resume/2`, `drain/3`,
  `obliterate/3`; `EchoMQ.Jobs` mutations: `update_data/4`, `update_progress/4` (the `PUBLISH emq:{q}:events`
  D-5 seam), `add_log/5`, `get_job_logs/3`, `remove_job/4` (`EMQLOCK`), `reprocess_job/3` (`EMQSTATE`).
- **The watch plane (emq.2.3, shipped `3c6461ff`)** — `EchoMQ.Events` (`events.ex`: `subscribe/2`, `unsubscribe/2`,
  `close/2`, `channel/1`, `publish/5`, `event_name/1`); `EchoMQ.Meter` (FILE still `telemetry.ex`:
  `attach/4`, `attach_many/4`, `emit/3`, `span/3`); `EchoMQ.Locks` (+ `EchoMQ.Locks.Core`; FILES `lock_manager.ex` + `lock_manager/core.ex`): `track_job/3`,
  `untrack_job/2`, `get_active_job_count/1`, `get_tracked_job_ids/1`, `is_tracked?/2`; `EchoMQ.Stalled` (FILE `stalled_checker.ex`):
  `check/3`, `job_stalled?/4`; `EchoMQ.Cancel` (FILE `cancellation_token.ex`): `new/0`, `cancel/3`, `check/1`, `check!/1`;
  `EchoMQ.Jobs.extend_lock/5` (`jobs.ex:646`) + `extend_locks/4` (`jobs.ex:671`) via `@extend_lock`/`@extend_locks`.
- **The rate-gate seam (G1)** — `is_maxed/2` is a pure-read primitive in `metrics.ex` (`EMQRATE`); the
  `@claim`/`@gclaim` transitions are in `jobs.ex`/`lanes.ex` (the Arm-1 edit target). Re-pin at B0.
- **The v1 test-depth REFERENCE (read, never edit)** — the matching shipped-surface depth to port:
  `echo/apps/echomq/test/echomq/{queue_getters,queue_integration,rate_limiter_integration,obliterate,queue_events_integration,worker_cancellation}_test.exs`.
  **NOT** the worker-abstraction / OTel / flow / scheduler / stress files (emq.6 / emq.8 / emq.3 / emq.1 / the
  loop — D8's attribution).

## The pipeline — the HIGH-RISK flow (Venus → Mars-1 → Director review → Mars-2 → **Apollo** → Director ship)

Each spawned stage is a real `general-purpose`/dedicated `Agent` that adopts its `.claude/agents/<role>.md`
charter, LOADS its `echo-mq-<role>` skill, and self-registers via `mcp__aaw__*` (LAW-1; no narrated spawns).
The Director holds the gate between stages. The per-spawn contract is the `/x-mode` skill §3 (Framing → adopt
charter → aaw ceremony → the stage block → audit directive → propagation clause → report). **Require
artifact-level checkpoints** (the L-1 carry: SendMessage a concrete report after each pass; the Director's
ground-truth verification is the gate, not the self-verdict).

### Stage 0 — Venus (architect): the pre-build reconcile + the fork-settlement gate

Directive: run the lag-1 reconcile (re-probe every anchor above against the post-emq.2.3-commit tree; re-pin
the conformance count + the metrics/admin/jobs/watch surfaces + the v1 reference depth files). Confirm the
**G1 fork is Operator-ruled** (EMQ.2.4-D1) and **re-derive D2 to the ruled arm** (Arm 2 default; Arm 1 re-scopes
the claim-gate edit). Bring the triad to as-built truth where a cluster commit moved an anchor; mark each delta
MATCH-or-`[RECONCILE]`. Gate: the reconcile delta table; the fork ruling recorded; the triad re-derived.

### Stage 1 — Mars-1 (implementor): build the residue + the depth suites

Directive: after the fork is ruled, build EMQ.2.4-D2 → D8 to the brief's agent stories (AS1–AS8) and the
design. The feature residue first (D2 the rate-gate to the ruled arm; D3 the optional `:data` series OR its
recorded hold; D4 the `de:` orphan documented + the bounded-complete release test), then the depth suites (D5
`metrics_depth_test.exs`, D6 `admin_depth_test.exs`, D7 `watch_depth_test.exs`), then the attribution record
(D8). Cite the spec/design line for every public call; **declared keys** (any new Lua in `KEYS[]` or rooted —
the A-1 lint; the F-1 probe); **inline `Script.new/2`** (no `priv/`); register a conformance scenario + probe
for each genuine new behavior **in the same change** (INV1, the additive-minor law; the 37 prior byte-unchanged;
re-pin 37 → N in both pinning tests); compile clean (`--warnings-as-errors`, per-app). **INV2 honesty gate**:
no test drives an unshipped surface. Gate: per-app compiles green; D2–D8 exist; the diff stays inside `echo_mq`
(Arm 2 touches no `echo_wire`); the boundary grep empty.

### Stage 2 — Director: solo review (a REAL pass)

A fresh-gate reconcile + an independent gate re-run on Valkey 6390 + ≥1 adversarial probe (the **declared-keys**
F-1 probe on any new Lua; the **INV2 false-green** probe — does any depth test assert a verb `echo_mq` does not
ship?; the **order theorem** if Arm 1 was ruled) + a mutation spot-check (Edit-in → a depth test catches it →
revert → `git diff --stat` clean, net-zero, LAW-1a). Produce the REMEDIATE list.

### Stage 3 — Mars-2 (implementor, harden + the full gate ladder)

Resume the Stage-1 Mars (one identity, two passes). Directive: remediate; run the full ladder — toolchain
re-probe (`asdf current erlang`) + Valkey 6390 PONG; per-app pure + `:valkey` + process suites (`TMPDIR=/tmp`,
NEVER umbrella-wide); `Conformance.run/2 → {:ok, N}` with the prior 37 byte-unchanged + the new ones
probe-registered; the **≥100-iteration determinism loop** over the process-touching depth suites (D7 — the lock
plane + the stalled sweep + events; the loop OWNS the machine, tee to a file, report from the file); the read/ops
depth suites (D5/D6) pass the multi-seed sweep (the honest posture — they are synchronous deterministic
round-trips, running the loop forges load the rung did not introduce — INV7); D8's attribution stated; coverage
tabled with the reason for any gap. REMEDIATE loop MAX 3. Gate: every ladder item PASS or explained; the
conformance tally clean; the boundary grep empty.

### Stage 4 — Apollo (evaluator) — MANDATORY (high-risk)

Directive (the §11.2 charter): post-build reconcile (as-built ⇄ spec); re-run the gate ladder + the ≥100 loop
**independently**; adversarially verify — the **order theorem** (byte = mint across the depth mints); the
**declared-keys** grep on every NEW Lua (the F-1 class); the **INV2 false-green** probe (no test for an
unshipped surface — worker-abstraction / OTel-contract / distributed-cancel / flow / durable-stream); the
**byte-unchanged conformance** with each new scenario probe-registered; if Arm 1 was ruled, the **shipped-`@claim`
re-verification** (INV1 + the order theorem hold across the edit). Render **BUILD-GRADE / BLOCKED**; an
un-prompted finding + an attack-that-held + a mutation kill-rate; `AskUserQuestion` to keep it shippable. Fold
findings forward as mentoring (Director-ratified).

### Stage 5 — Venus (architect): the post-build reconcile

Sync the triad body to the as-built surface (the depth suites' real names; the ruled arm; the final conformance
N); every triad claim MATCH or `[RECONCILE]`-marked; fold the parity proof ([`../emq.features.md`](../../emq.features.md)
Part B) to flip the 🔨 watch + closer rows to ✅ where they land.

### Stage 6 — Director: closure + ONE LAW-4 commit + the cluster-close fold

Preconditions (x-mode §4): Apollo BUILD-GRADE (or its REMEDIATE items closed) + the gate green + the reconcile
build-grade; **≥1 `tool_x_decision` (D-n)** + a **`tool_x_complete` (Z-n)** this turn; `git status --short` AND
`git diff --cached --name-only` reviewed; `.git/rebase-merge`/`rebase-apply` checked. Then the **pathspec**
commit (below; NEVER `git add -A`, NEVER a bare commit). **Same turn:** flip the emq.2.4 + cluster rows in the
single roadmap ([`../emq.roadmap.md`](../../emq.roadmap.md)) and the dashboard ([`../emq.progress.md`](../../emq.progress.md));
mark **the emq.2 cluster CLOSED**; surface the **push-source dissolution seam** (the cluster close un-blocks
`apps/echomq`'s dissolution — timing Operator-owned, roadmap §Seams item 5) and the **next frontier** (emq.3
parent/flow opens Movement I's close; or an emq.7 / emq3.1 pull-forward); under an **explicit Operator grant
only**, fold any mentoring diff into the peer charters / the echo-mq-* skills (one guardrail per finding —
e.g. the L-1 checkpoint-discipline note, the skill-ref staleness flag below). The message cites the slug, the
Z-n, the D-n, and the Y-n report.

## Risk tier

Two elevated dimensions the high-risk pipeline mitigates: **(a) process/mint-touching** — the watch depth
suites run the lock-plane timer + the stalled sweep and mint multi-job sets; the mitigating gate is the **≥100
determinism loop** (the same-ms branded-id mint hazard; one green run is not proof) + Apollo's independent
re-run. **(b) the shipped-`@claim` edit — N/A (the G1 fork is RULED Arm 2):** Arm 2 touches no claim path, so the
whole risk surface stays in the **test suite**; the `@claim`-edit dimension (the byte-identical re-verification
of `claim`/`rate`/`limit`/`rotate` + the order theorem) does **not** arise. (Had Arm 1 been ruled, that
re-verification would have gated it.) Apollo is MANDATORY either way (the process/mint dimension alone qualifies).

## The Stage-6 commit pathspec (Director-only — the emq.2.4 BUILD)

Commit exactly the rung's measured surface (the build run's actual touch-set is authoritative — adjust to what
the stages truly changed):

```text
docs/echo_mq/specs/emq.2.4.md
docs/echo_mq/specs/emq.2.4.stories.md
docs/echo_mq/specs/emq.2.prompt.md            (this runbook)
docs/echo_mq/specs/emq-2-4.progress.md
docs/echo_mq/specs/emq-2-4.registry.json      (if the run mints one)
docs/echo_mq/emq.features.md                  (the 3.0 catalog + the v1→v2 parity proof)
docs/echo_mq/emq.roadmap.md                   (the emq.2 cluster rows → CLOSED)
docs/echo_mq/emq.progress.md                  (the dashboard fold)
echo/apps/echo_mq/lib/echo_mq/metrics.ex      (G2 the :data series, IF built; Arm-2 touches no claim path)
echo/apps/echo_mq/lib/echo_mq/jobs.ex         (G2 the :data counter on @complete/@retry, IF built; Arm-1 @claim IF ruled)
# echo/apps/echo_mq/lib/echo_mq/lanes.ex      EXCLUDED — Arm 2 ruled, no @gclaim edit
echo/apps/echo_mq/lib/echo_mq/conformance.ex  (the depth scenarios, additive)
echo/apps/echo_mq/test/                        (metrics_depth + admin_depth + watch_depth + the conformance pins)
```

**EXCLUDE** (Operator out-of-band — never sweep into the rung commit):
`echo/apps/live_svelte/**`, `echo/apps/mercury_cms/**`, `echo/apps/mercury_live_admin/**`, `html/**`, the F#
course, and any `[emq]`/`[bcs]`/`[mercury]` doc commits the Operator lands between stages. The
**emq.2.3 watch-plane code is already committed** (`3c6461ff` the rung + `5a3fdd73` the docs fold) — the
emq.2.4 LAW-4 commit records exactly emq.2.4's own surface (the depth suites + the §0 residue + the C1 file
rename + the conformance re-pin), never re-sweeping emq.2.3's shipped surface. `echo/apps/echomq` (frozen v1) + `echo/mix.lock`
UNTOUCHED (emq.2.4 adds no dep — expect `mix.lock` EXCLUDED). **Never `git add -A`.**

## Acceptance — "shipped" + "the cluster closed" means

Every DoD box in [`./emq.2.4.md`](emq.2.rungs/emq.2.4.md) is checkable from the run's outputs: the G1 fork ruled +
recorded before any build artifact (EMQ.2.4-D1); the feature residue built (D2 the rate-gate to the ruled arm;
D3 the `:data` series or its recorded hold; D4 the `de:` orphan documented + the bounded-complete release
asserted); the depth suites D5–D7 built against the **shipped** read/ops/watch verbs (INV2 — no false-green);
D8's attribution stated (the un-ported v1 depth → its owning rung, no padding); the conformance set grown by the
genuine new scenarios with **the 37 prior byte-unchanged** and the count re-pinned (INV1); pure + `:valkey` +
process suites green per-app; the **≥100 determinism loop** green for D7's process-touching suites (D5/D6 the
multi-seed sweep — INV7); no regression (INV3 — emq.1 + emq.2.1/2.2/2.3 + `Conformance.run/2` unchanged); a depth
test that fails triaged as a real shipped-surface finding (escalated — design §11.12), never papered over;
**Apollo BUILD-GRADE** (INV8); one Director pathspec commit; the roadmap + dashboard flipped to **the emq.2
cluster CLOSED** (read ✅ + ops ✅ + watch ✅ + the closer ✅, proven at depth); the push-source dissolution seam
surfaced.

---

The contract: [`./emq.2.4.md`](emq.2.rungs/emq.2.4.md). The stories: [`./emq.2.4.stories.md`](emq.2.rungs/emq.2.4.stories.md). The parity proof + the 3.0 catalog:
[`../emq.features.md`](../../emq.features.md). The carve + ADRs: [`./emq.2.design.md`](emq.2.design.md). The
canon: [`../emq.design.md`](../../emq.design.md) §5/§6/§7/§11.12/§The master invariant. The program:
[`../emq.roadmap.md`](../../emq.roadmap.md) · [`../echo_mq.md`](../../echo_mq.md). The dashboard:
[`../emq.progress.md`](../../emq.progress.md). The run's audit trail: `emq-2-4.progress.md` + `mcp__aaw__status`.
The capability reference (the test DEPTH to port — read, never edit):
`echo/apps/echomq/test/echomq/{queue_getters,queue_integration,rate_limiter_integration,obliterate,queue_events_integration,worker_cancellation}_test.exs`.
