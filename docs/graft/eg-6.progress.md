# eg-6 — AAW scope ledger

## {eg-6-thinking} Thinking

### T-1 — REFRAME eg.6 + DEFER (Operator redirect mid-bootstrap). Mode: Flat-L2, **L2 Duo** (Director + Venus) per the v3.0 router — a docs-only reconcile+reframe, NOT a build/ship.

OPERATOR REDIRECT (interrupted the Stage-1 spawn): reframe eg.6 from "cross-compile + CI + shootout" → **"Ship AND RUN fully integrated EchoMQ + Graft (BEAM↔Rust)"** + the per-workload durability shootout (echo_graft beside Champ + Oban) + **fly.io Dockerfile/fly.toml for EchoMQ**; reconcile the durability md files under `html/echo-persistence/engines/`; write the reconciled triad at status **Draft**; mark the rung **Deferred**; then hand back to the Operator to start the **EchoMQ Dashboard**.

WHY DEFER (recorded, honest): the reframed eg.6 is no longer just packaging — it is "ship AND RUN fully integrated," which stands on a live **fly.io deployment of EchoMQ** as the substrate the integrated BEAM↔Rust system runs on. That deploy (Dockerfile + fly.toml for EchoMQ) is **not ready**. A rung whose load-bearing leg (the live integrated run) has no deploy floor cannot be honestly shipped → DEFER; spec DRAFTED, not built. This is the inverse of eg.5's D-1: eg.5 deliberately ISOLATED the live binding so eg.6 could stay packaging+NORMAL; the reframe folds the full integrated run INTO eg.6, re-raising a deploy dependency that is not met.

SCOPE OF THIS RUN (reconcile + reframe + defer):
1. **Venus** reframes `docs/graft/specs/graft.6.md` → broadened scope, **status: Draft**, stories/brief folded inline (eg.* inline-brief convention), the per-workload shootout incl. the native Elixir `EchoStore.Graft.*` engine (D-5), and the **fly.io-deploy-not-ready** deferral reason recorded as the rung's blocker.
2. **Venus** reconciles the `html/echo-persistence/engines/` md tree (+ the `foundations/durability-spectrum/the-shootout-and-the-knob` dive) against as-built: eg.1–**eg.5 SHIPPED** (not "eg.1–3"), eg.6 **DEFERRED**, the shootout still pending (now explicitly deferred), COEXIST framing held; clear the stale markers (course-design index EP10 **planned**→eg.4 shipped, EP8/EP9 **reframe pending**, rust-hub **eg.1–3 shipped**); mirror the surgical factual deltas into the paired **.html** so the served site is honest.
3. **Director** marks eg.6 DEFERRED in `graft.roadmap.md` (line 70, reframed Ships cell) + `graft.progress.md` (the ANSI tracker, guarded byte-replace) + writes D-n/Z-n + hands back for the Dashboard.

BOUNDARY: `docs/graft` (graft.6.md + roadmap + progress + this ledger) + the **Operator-extended** `html/echo-persistence/engines/` md+paired-html (explicit Operator allowance — outside the normal graft boundary, in-scope for THIS directive only). **NO code** (Rust or Elixir); the fly.io artifacts **NOT created** (deferred deliverable, recorded not built); native `EchoStore.Graft.*` + `github.local/graft` untouched.

DEFAULTS STATED (reversible): (a) the engines reconcile edits the .md (explicit target) + mirrors changed factual claims into the paired .html (the site serves .html raw — a md-only pass leaves the live site stale); (b) the fly.io Dockerfile/fly.toml are RECORDED as the deferred deliverable in the Draft spec, NOT created now.

## {eg-6-analysis} Analysis

### A-1 — eg.6 reframe reconcile: as-built ground truth vs the two work-streams

RECONCILE DELTA (every claim cited to as-built file:line or a roadmap/design §):

WORK-STREAM A — graft.6.md (current: STALE, dated Jun 19, predates eg.4/eg.5 + COEXIST):
- Title "cross-compile, CI, shootout" → MISSING the "ship AND RUN fully integrated" frame + the eg.5 stdin-EOF watchdog debt. STALE.
- §Scope "an echo_graft row beside Champ, Oban, Memory, BullMQ" → must become PER-WORKLOAD (D-5, engine-split.design.md §7) incl. the native EchoStore.Graft.* engine (4 durable contenders); Memory/BullMQ are EXTERNAL baselines, not durable-tier. STALE.
- Acceptance crit 4 lists "Memory, BullMQ" as peers of echo_graft in the durable comparison → reframe: durable tier = {native Elixir engine, Rust echo_graft, Champ, Oban}; Memory/BullMQ baseline-only.
- NO fly.io Dockerfile/fly.toml deploy substrate mentioned → the "run fully integrated" leg stands on it; ADD as scope (RECORD only — do NOT scaffold; it is the deferred deliverable).
- NO deferral record → ADD §Status-DEFERRED + frontmatter note (deferred ∵ fly.io EchoMQ deploy not ready). KEEP status: Draft (Director sets the ladder "Deferred").
- stdin-EOF watchdog (backend_main.rs, eg-5 L-3 / D-8) → FOLD as ship-hardening. backend_main.rs select! watches ONLY ctrl_c + serve, no stdin (eg-5 Y-5); Port.close orphans backend to ppid 1; pkill reap is the interim. CITED: eg-5.progress.md:178, 297, 341.
- References/declared-keys: proto FROZEN at v2 (PROTO_MIN=PROTO_MAX=2, eg-5 D-5); the shootout READS engines (no new wire); fly.io adds DEPLOY config, not wire. No new declared key.

WORK-STREAM B — html/echo-persistence (SURGICAL; md + mirror .html):
- index.md:48 EP8 "built (reframe pending)" / :49 EP9 "built (reframe pending)" → clear the reframe-pending markers (cite graft roadmap/coexist). :50 EP10 "planned" → eg.4 RUNG shipped, page unbuilt: state "rung eg.4 shipped; page planned". index.html:178 EP10 pill = `soon` ("on the runway"), NOT `planned` — semantics differ; mirror the rung-shipped/page-unbuilt distinction in the card prose, keep the pill (Director-domain visual, page genuinely unbuilt).
- rust/index.md:20 "The first three components (eg.1–3) are shipped." → eg.1–eg.5 shipped (README.md eg.1–eg.5 SHIPPED; eg-5.progress Z-1). MIRROR-CHECK: rust/index.html:133 is ALREADY reframed (full eg.1→eg.6 sequence + COEXIST/sidecar, NO stale eg.1-3 claim) — the .md LAGS the .html here (reverse of usual). The html states the sequence without ship-status; safe to leave OR add the eg.1-5-shipped fact. Surgical: bring md up to html + add the ship-status fact to both.
- rust/index.md:42 + native dives: refs cite "eg.1–3" → widen to eg.1–5 where it states ship scope.
- the-shootout-and-the-knob.md:33 row "pending eg.6 · per-workload" + :35 "measured per-workload at eg.6" → reflect eg.6 DEFERRED ("pending eg.6 — DEFERRED · per-workload"). html:129 + :132 carry the same → mirror. Keep the table + D-5 framing; status-reflection only.
- native-elixir/tigris+fence dives: recon found NO stale rung-status claims (the-commit-log-outbox.md "shipped" = segment-upload state, not rung status — LEAVE). VERIFY-only pass.

FORK CHECK: none required — the directive's scope is fully determined (D-5 per-workload ruled, D-1=A coexist ruled, fly.io RECORD-not-build instructed, status Draft held). One NOTE for the Director (not a fork): the index.html EP10 pill is `soon` not `planned` while index.md says EP10 "planned" — a pre-existing md↔html pill-semantics drift; I reconcile the PROSE (rung-shipped/page-unbuilt) and leave the pill as-is (page genuinely unbuilt → `soon` is honest). If the Director wants the pill flipped that is a visual call I surface, not self-rule.

## {eg-6-report} Report

### Y-1 — Venus: eg.6 reframe + engines reconcile COMPLETE. Verdict BUILD-GRADE (spec drafted, deferral recorded, all claims grounded, link-check 0).

SCOPE EDITED (exactly the 6 instructed files; NO code, NO Director-owned tracker/ledger, NO native EchoStore.Graft.*, NO github.local/graft, NO fly.io artifacts created):
1. docs/graft/specs/graft.6.md — reframed (Work-stream A)
2. html/echo-persistence/index.md — Ch III EP8/9/10 reconcile
3. html/echo-persistence/engines/rust/index.md — §1 ship-status + COEXIST
4. html/echo-persistence/engines/rust/index.html — §1 mirror
5. html/echo-persistence/foundations/durability-spectrum/the-shootout-and-the-knob.md — eg.6 DEFERRED reflection
6. .../the-shootout-and-the-knob.html — mirror
+ html/echo-persistence/index.html EP10 card (rung-shipped/page-unbuilt prose)

GATES: (1) graft.6.md frontmatter status: Draft RETAINED (size M→L, risk NORMAL→HIGH — body-authoritative, flagged for Director tracker fold). (2) msh specs over docs/graft = 0 findings (17 files, error=0/warn=0/info=0). (3) every claim cited to as-built README/design §/file:line. (4) md↔html mirror parity verified (deferred 2×/2×; eg.1-5-shipped 1×/1×).

NOTE for the Director (NOT a self-ruled fork): index.html EP10 pill = `soon` while index.md said EP10 "planned" — pre-existing md↔html pill-semantics drift. I reconciled the PROSE (rung-shipped/page-unbuilt) in both and LEFT the pill (page genuinely unbuilt → `soon` honest). If a pill flip is wanted, that is the Director's visual call.

DEFERRAL RECORDED: graft.6.md §Status-DEFERRED + frontmatter `deferred:` note — deferred ∵ the fly.io EchoMQ deploy floor is not ready (the live integrated run stands on a deployed bus that does not exist); spec drafted now to capture scope; status: Draft held (the program ladder carries "Deferred" — Director sets it).

L-1 RE-FIRE (coordination): the aaw queue re-delivered completed task #1 mid-session — the documented eg.5 L-1 hazard. Per L-1 the on-disk state is authoritative; did NOT reopen.

## {eg-6-decisions} Decisions

### D-1 — REFRAME eg.6 + DEFER (Operator-ruled 2026-06-22, mid-bootstrap redirect).

The Operator reframed eg.6 from "cross-compile + CI + shootout" (NORMAL packaging) → **"Ship AND RUN fully integrated EchoMQ + Graft (BEAM↔Rust)"** + the per-workload durability shootout + a **fly.io Dockerfile/fly.toml deploy floor for EchoMQ**, and **DEFERRED** the rung. REASON (honest, recorded): the reframed load-bearing leg (the whole stack running LIVE + integrated) stands on a deployed EchoMQ bus that does not yet exist — no fly.io artifacts; eg.5 proved the binding against a local Valkey :6390, not a deployed bus — so the integration acceptance (crit 5/7) cannot be discharged.

RULED:
- (a) `graft.6.md` reframed → the broadened scope; frontmatter **status: Draft held**, size **M→L**, risk **NORMAL→HIGH** (body-authoritative); the deferral recorded in §Status-DEFERRED + a frontmatter `deferred:` note. The program ladder carries the "Deferred" lifecycle marker (Director sets it, not the spec).
- (b) the per-workload shootout (D-5) = the FOUR durable contenders {native Elixir `EchoStore.Graft.*`, Rust `echo_graft`, Champ, Oban}; Memory/BullMQ are EXTERNAL baselines only (not the durable tier).
- (c) the fly.io Dockerfile/fly.toml are **RECORDED as the deferred deliverable, NOT scaffolded** (they are the deferral root; building them is the first step when the rung is taken up).
- (d) the eg.5-carried **stdin-EOF watchdog** (eg-5 L-3/D-8) folded into eg.6 as ship-hardening (crit 7).
- (e) the program ladder marks the rung DEFERRED: `graft.roadmap.md` line 70 (reframed Ships cell + a §4 deferral note) + `graft.progress.md` (the ANSI dashboard, guarded byte-replace).
- (f) the Operator-extended `html/echo-persistence/engines/` course md + paired .html reconciled to **eg.1–eg.5 shipped / eg.6 deferred** (the COEXIST framing held); the EP10 `index.html` pill left `soon` (the course page is genuinely unbuilt — honest; Director-ratified, not a fork).

VERIFY (Director independent): Venus Y-1 BUILD-GRADE; my re-run of `msh specs` over docs/graft = **0 findings**; boundary clean — ONLY `graft.6.md` + the (already-untracked) `html/echo-persistence/` tree + the Director ledger changed; **NO code** (Rust/Elixir), **NO** native `EchoStore.Graft.*`, **NO** `github.local/graft`, **NO** fly.io artifacts scaffolded.

Git posture: **working tree, NOT committed** (the Operator did not ask to commit). NEXT: hand back to the Operator to start the **EchoMQ Dashboard**.

## {eg-6-complete} Complete

### Z-1 — eg.6 REFRAME + DEFER COMPLETE (working tree; NO commit asked). Mode: L2 Duo (Director + Venus), v3.0 router — a docs-only reconcile+reframe, no build/ship.

DELIVERABLES:
1. `docs/graft/specs/graft.6.md` reframed → "Ship AND RUN fully integrated EchoMQ + Graft (BEAM↔Rust)"; **status: Draft held**; §Status-DEFERRED + frontmatter `deferred:` note; size M→L, risk NORMAL→HIGH; the per-workload shootout (4 durable contenders + Memory/BullMQ baselines), the fly.io deploy floor (RECORDED-not-scaffolded), the stdin-EOF watchdog folded as ship-hardening; 8 acceptance crits + 7 stories + an inline build brief carrying "a no-op must not satisfy this" gate contracts; forward-tense throughout. (Venus Y-1; Director independent-verified BUILD-GRADE — read all 173 lines.)
2. `html/echo-persistence/` reconciled (surgical; md + paired-html mirror): index.md Ch III EP8/9 reframe-pending cleared + EP10 "rung eg.4 shipped; page planned"; rust hub "eg.1–3"→"eg.1–eg.5 shipped" (md+html); shootout dive → "pending eg.6 (deferred) · per-workload" (md+html); native-elixir + tigris+fence VERIFY-only (no stale rung-status). 7 files.
3. Program ladder marked DEFERRED: `graft.roadmap.md` line 70 (reframed Ships cell) + a §4 deferral note; `graft.progress.md` ANSI dashboard (4 guarded byte-replaces — the eg.6 rung line NEXT→DEFERRED + dimmed marker, the header banner, the shootout-gate annotation, the legend pointer; ESC bytes verified intact via cat -v).

GATES: msh link-check over docs/graft = **0 findings** (Director re-run, independent of Venus's). Boundary clean — only graft.6.md + the (already-untracked) html/echo-persistence tree + the Director ledger; **NO code** (Rust/Elixir), **NO** native `EchoStore.Graft.*`, **NO** `github.local/graft`, **NO** fly.io artifacts scaffolded. status: Draft held. The EP10 index.html pill left `soon` (page genuinely unbuilt — honest; Director-ratified, not a fork).

L-1 RE-FIRED (coordination): the aaw queue re-delivered Venus's completed task #1; Venus's Y-1 surfaced via the **ledger** (activity A:1), NOT a SendMessage (messages:0) — the documented eg.5 L-1 hazard. Per L-1 the Director verified from the on-disk artifact (the reframed graft.6.md + the engines deltas via grep + the ledger Y-1), not the message layer. The precept holds across rungs: file/ledger ground truth is authoritative over the task queue.

GIT POSTURE: working tree, NOT committed (Operator did not ask). EPIC STATE: echo_graft = **eg.1–eg.5 SHIPPED** (the durability engine complete + proven in isolation); **eg.6 DEFERRED + fully specced**, pending the fly.io EchoMQ deploy floor. HANDOFF: ready to pivot to the **EchoMQ Dashboard** on the Operator's go.
