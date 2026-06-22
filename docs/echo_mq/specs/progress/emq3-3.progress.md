# emq3.3 — S2 · the readers: `EchoMQ.StreamConsumer` + the polyglot seam — RUNG LEDGER

S2 of EchoMQ 3.0 (the Stream Tier) opens: a BEAM consumer group beside one non-BEAM reader on the same group,
at-least-once with idempotent handlers, crash → `XAUTOCLAIM` re-delivery, the stored `id` field proven the
polyglot receipt. Risk **HIGH** (a NEW supervised process + a blocking `XREADGROUP` surface + a lease-like PEL
recovery) — the ≥100 determinism loop + the full mutation battery are its gate; Apollo mandatory (post-build).

## T-1 — the design phase (Director): the dual-architect design-ahead, ruled

emq3.3 founds the S2 reader surface as emq3.2 founded the S1 writer law. Per Operator direction (2026-06-22),
the design ran as a **DUAL-ARCHITECT design-ahead of the COMPLETE Stream Tier (emq3.3–emq3.6)**, following
[`aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md), written to
[`kb/streams-tier/`](../../kb/streams-tier/) for independent Operator review:
- **Lens A** (consumer/operability) + **Lens B** (spec-steward/invariants) argued the same forks independently,
  neither reading the other.
- **Result: 9 of 10 forks CONVERGED** (the two opposite-optimizing lenses reached the same arm, each for its
  own reason — robustness); **1 diverged** (F3.4-A, the retention-trim cadence — an emq3.4 decision, deferred).
- The synthesis (Director, [`streams.synthesis.md`](../../kb/streams-tier/streams.synthesis.md)) staged the
  agreement + the one disagreement. **Operator ruled (AskUserQuestion, 2026-06-22): ship emq3.3 now** to the
  converged decision set; F3.4-A deferred to emq3.4 (emq3.3 forecloses nothing).

The §0 derivation: emq3.3 stands ONLY on emq3.1 (the verbs ride generic on the certified `Connector`; `XGROUP`
rides the same path) + emq3.2 (`EchoMQ.Stream`: the branded `EVT` id stored as the `id` field, the order
theorem, real-Unix-ms). The key design tension — does `XREADGROUP BLOCK` stall the single-owner socket? — is
retired one tier down by the shipped law "blocking verbs get their own lane" (`consumer.ex` moduledoc,
Appendix B): a `StreamConsumer` holds a PRIVATE connector lane, exactly as the job `Consumer` holds one for
`BLPOP`. No new concurrency model — inherited.

## D-1 — formation + scope (Operator)

Dual-architect design-ahead over emq3.3–emq3.6, to `kb/streams-tier/`, for independent review (D-1). **Ship
emq3.3 now**; F3.4-A (trim cadence) deferred to emq3.4. The KB is the emq3.4–3.6 design reference; each later
rung is still spec-triad-first at its own build.

## D-2 — the SETTLED session forks (Operator, pre-design)

1. The BEAM consumer = a NEW SIBLING `EchoMQ.StreamConsumer` (beside `Consumer`, a private connector lane,
   `XREADGROUP GROUP … >`). NOT a mode on the job `Consumer`. (Sibling precedent: `EchoMQ.BatchConsumer`.)
2. Crash re-delivery = FOLDED INTO the consumer's own beat (`XAUTOCLAIM` reclaim of entries idle past a
   min-idle threshold, mirroring the job `Consumer`'s reap-on-beat). No separate sweep module.
3. The polyglot seam is proven by a RAW-CONNECTOR PARITY TEST in-suite (raw `XREADGROUP`/`XRANGE` through the
   bare `Connector`, asserting the stored `id` field is the canonical receipt a non-BEAM client redeems).

## D-3 — F3.3-A the XGROUP lifecycle = lazy ensure-on-start (CONVERGED, ruled)

`XGROUP CREATE <key> <group> <start> MKSTREAM` on `StreamConsumer.start_link`, swallowing ONLY `BUSYGROUP` (a
`WRONGTYPE` etc. is LOUD, never swallowed — the gate-liveness discipline). The start position (`$` new-only vs
`0` replay) is a **declared `start_link` option**, never a default. NO destructive `group_destroy` verb at this
rung (a destructive at-rest op belongs with the retention/archive family; the emq.4.1 `drain/3` precedent).
Zero new frozen public verb on `EchoMQ.Stream`. (Both lenses → A1.)

## D-4 — F3.3-B restart read mode + handler = drain-PEL-first + exact mirror (CONVERGED, ruled)

On (re)start, drain the consumer's own PEL (`XREADGROUP GROUP g c 0`, the un-acked backlog) to exhaustion, then
switch to `>`. PEL-drain recovers SELF on restart; the SETTLED `XAUTOCLAIM` beat recovers dead PEERS —
complementary, both named in the spec. The handler is the job `Consumer`'s `%{id, payload, attempts, group}` →
`:ok | {:error, reason}` EXACTLY (one portable handler shape across job + stream). **NAMED invariant**
(EMQ3.3-INV): on the stream side `attempts` carries the `XPENDING` per-entry **delivery-count** (not a
handler-failure count) — specced, not assumed. (Both lenses → B-i-1 + B-ii-1, both independently demanding the
named mapping.)

## D-5 — F3.3-C conformance grain = +1 `stream_group` (CONVERGED, ruled)

ONE new conformance scenario `stream_group` (the at-least-once grouped-delivery capability), probe-registered,
prior scenarios byte-unchanged, count re-pinned in both pins. **The scenario must POSITIVELY prove re-delivery**
(an un-acked entry, an idle-window/forced `XAUTOCLAIM`, an assertion the SAME entry returns) — never a no-op
(the false-green guard). The deep proofs (every-entry-delivered-≥1, PEL-first, ≥100 process loop) ride
property/loop tests beside the registry. Re-probe the live conformance count at the reconcile before pinning.
(Both lenses → C1.)

## D-6 — the order-theorem PEL exception, named (CONVERGED canon point)

emq3.3's `.md` body NAMES where the order theorem holds and where it cannot: the stream stays id-ordered
(`XRANGE` / `XREADGROUP … >` hand entries in mint order), but a **re-claimed** entry returns to a consumer OUT
of real-time delivery order — the honest at-least-once cost. A spec asserting "order preserved" without this is
the false-green Lens B exists to catch.

## D-7 — label + risk (Director)

Label `echomq:2.6.2` (within-family PATCH — emq3.1 opened the family at `2.6.0`, emq3.2 → `2.6.1`).
`@wire_version` FROZEN `echomq:2.4.2` (the deferred cutover). Conformance +1 (74? → re-probe; additive-minor).
Risk **HIGH** — a new supervised process + a blocking-read surface + a lease-like PEL recovery → the Director's
deepened verify (the ≥100 determinism loop on the consumer suite + the full mutation battery) and Apollo
mandatory (post-build evaluate/mentor). No frozen-line touch (zero `echo_wire` edit; the stream verbs ride
generic, no new `Script.new/2`), no destructive op (no `group_destroy`/`XGROUP DESTROY`).

## D-8 — the build-release ratification (Operator): B·T·N ratified, Mars released

The Operator ratified the rung's build contract along its three Director-locked dimensions and released Mars-1
to Stage 2. No open Operator fork remains (the design-ahead converged on EVERY emq3.3 fork; F3.4-A is an emq3.4
decision emq3.3 forecloses nothing of):

- **B — the Boundary (the build scope).** Edit ONLY `echo/apps/echo_mq`: the NEW `lib/echo_mq/stream_consumer.ex`
  + the NEW `test/stream_consumer_test.exs` + `conformance.ex` + the two pinning tests + `mix.exs`. `echo_wire`
  UNTOUCHED (the consumer rides the shipped `Connector.command/3` on a private lane); NO new/edited Lua (the
  group verbs issued direct — `grep -c redis.call` on the `lib/` diff = 0; every shipped `Script.new/2`
  byte-identical); `keyspace.ex` UNTOUCHED (group state is server-side stream state on the `{q}` slot);
  `echo_store`/`EchoStore.Graft` UNTOUCHED (COEXIST — the archive fold is emq3.5); `apps/echomq` untouched;
  `mix.lock` excluded (no dep moved; the StreamData arm is the one named, NOT-taken exception).
  `@wire_version` FROZEN `echomq:2.4.2`.
- **T — the Tier (risk HIGH → the deepened verify).** The ≥100 determinism loop on the consumer suite
  (a NEW supervised process + a same-ms mint hazard) + recovery-completeness under crash injection (every entry
  delivered ≥1; PEL-drain recovers SELF, the `XAUTOCLAIM` beat recovers dead PEERS) + the full mutation battery
  (`>`→`0`, drop-PEL-drain, ack-on-`{:error,_}`, drop-`BUSYGROUP`-only-swallow) + the PEL-exception probe + the
  polyglot-parity probe + the net-zero spot-check. **Apollo MANDATORY** (a ship precondition on this rung).
- **N — the conformance N.** 75 → 76 (+1 `stream_group`, a POSITIVE re-delivery proof — never a no-op); the
  prior 75 byte-unchanged (git-verified); both pins re-pinned (`conformance_run_test.exs:65` `{:ok, 76}` +
  `conformance_scenarios_test.exs:43` `@run_order` gains `stream_group`); additive-minor.

Label `echomq:2.6.2` (D-7). Stage 2 released to a real self-registered Mars (mars charter + `echo-mq-implementor`),
building inside the boundary, running the gate ladder + the ≥100 loop before reporting, running NO git.

## Forward — the build

Venus authors the triad (`emq3.3.{md,llms.md,stories.md}` + `.prompt.md`) to D-2..D-7. Mars builds
`EchoMQ.StreamConsumer` + lazy-ensure group + the drain-PEL-first/`>` beat + the `XAUTOCLAIM` reclaim + the
mirrored handler + the `stream_group` scenario + the raw-connector parity test + the property/loop proofs; the
per-app gate ladder green on Valkey 6390. The Director verifies (deepened — HIGH risk), Mars-2 hardens, Apollo
evaluates/mentors, the Director ships (LAW-4 pathspec + the Stage-6 fold).

---

## Y-1 — Director verify

_(pending the build)_

## Z-1 — SHIPPED

_(pending the ship)_

## {emq3-3-progress} Progress

### P-1 — Stage 1 (Venus) DONE: the emq3.3 triad authored to the ruled convergence (D-2..D-7). Four NEW files under docs/echo_mq/specs/emq3/: emq3.3.{md,stories.md,llms.md,prompt.md}. VERDICT: BUILD-GRADE — every fork RULED, no open Operator decision for Mars.

Conformance re-probed at source: live N=75 (conformance.ex moduledoc "seventy-five runnable scenarios"; scenarios/0 has 75 entries; pins conformance_run_test.exs:65 {:ok,75} + conformance_scenarios_test.exs:43 @run_order tail :stream_append) → emq3.3 grows to 76 (+1 stream_group, additive-minor, both pins re-pinned).

StreamConsumer surface specced: a NEW supervised sibling (spawn_link loop, the Consumer/BatchConsumer shape) — child_spec/1 + start_link/1 + stop/2; start_link opts {:queue,:stream,:group,:consumer,:group_start (declared, :new->$/:head->0, no default),:handler,:min_idle_ms,:beat_ms,:count,:conn/:connector}; loop = lazy-ensure (XGROUP CREATE…MKSTREAM, BUSYGROUP-only swallow) → drain-PEL-first (XREADGROUP…0, recover SELF) → > BLOCK on the private lane → XAUTOCLAIM reclaim on the beat (recover dead PEERS) → settle; handler %{id,payload,attempts,group}->:ok|{:error,reason} byte-identical SHAPE to consumer.ex:147, attempts=XPENDING delivery-count (NAMED, EMQ3.3-INV3).

Lag-1 reconcile ALL MATCH (one non-blocking drift NOTE: lens-doc connector line numbers drift — cite by surface name, Mars re-probes). No-new-dep confirmed (deps/0 = echo_data+echo_wire; deep proofs are deterministic ExUnit + the ≥100 loop). Risk HIGH; Apollo MANDATORY (carried, not re-decided). msh specs over the 4 files → no findings; bracket-paren Lua hazard 0; all relative links resolve. Ready for /echo-mq-ship emq3.3.

## {emq3-3-thinking} Thinking

### T-2 — the team re-established on the aaw spine; the process violation corrected

Post-/compact the aaw MCP tools were deferred (schemas unloaded); the prior pipeline rode them not at all. aaw_status(emq3-3) showed agents:null — ZERO registered agents — despite a hand-authored ledger asserting P-1 "Stage 1 (Venus) DONE" and the emq3.3 triad existing on disk. Two Mars releases were attempted as bare background Agent spawns (both Operator-rejected). Correction (Operator-directed, 2026-06-22): aaw_init re-opened the scope idempotently (created:false — the existing ledger bound, nothing orphaned); the Director registered against ccl-emq3-3-1 (fake_n_signal:false); TeamCreate(emq3-3) stood up the peer surface. FROM HERE every peer is a real self-registered Agent visible in aaw_status; decisions ride tool_x_decision, learnings tool_x_learning — never a raw markdown ledger edit. The design-ahead (T-1 dual-architect KB + the emq3.3 triad) is treated as Operator-reviewed PRIOR ART (D-1 already ruled "ship emq3.3 now"), NOT re-attributed to a backdated Venus.

## {emq3-3-decisions} Decisions

### D-9 — the L2 Topology Router (program calibration, Operator-authorized) + the emq3.3 formation

The echo_mq 3.0 program enforces formation-triage as a NAMED router (Flat-L2 lead-team; the Director triages at bootstrap; RIGOR IS CONSTANT, only ceremony scales — the gate ladder always runs in full). Tiers (peer = an in-pipeline self-registered Agent beside the always-present Director):
- SOLO — Director + 1 builder. Trivial/mechanical: a doc reconcile, a 1-line fix, a re-pin, a version digit. The ewr.4.1 escape (a LOW-risk client-contract change is one builder, NOT the full team — it once burned ~370k tokens shipping zero).
- DUO — Venus + Mars. NORMAL additive capability with a clean/existing triad. Director verifies; Apollo folds findings async.
- TRIO — Venus + Mars + Apollo. Apollo MANDATORY (a new process/lease surface, a destructive at-rest op, a frozen-line touch) OR a docs/stories-heavy rung.
- SQUAD — 4+. HIGH-risk with a wide design space: a dual-architect design-ahead (2 Venus, divergent lenses, aaw.architect-approach.md) and/or a Mars-1/Mars-2 split + a specialist, + Apollo.
Router input = the rung .prompt.md risk tier x design-space width. A tier can be re-graded MID-BUILD (footgun 8: surface, do not decide; the Operator rules; re-grade the verify depth). 
RULING — emq3.3 = SQUAD-classified: HIGH-risk (a new supervised process + a blocking XREADGROUP + a lease-like PEL recovery), and the dual-architect design-ahead (T-1; 9/10 forks converged) WAS the 2-architect Squad front — now spent, Operator-reviewed prior art. The LIVE build formation is the Squad back-half: Mars (build to GREEN + the BLUE harden, one identity two passes) + Apollo (MANDATORY post-build verify/mentor) + Director (rule/verify/ship). Venus is NOT re-spawned (the triad is build-grade per P-1; the Director independently re-verifies it before release).
BDD OVERLAY (Operator-directed "BDD Mars-2 blue phase"): RED = the Given/When/Then story via the EchoMQ.Story DSL -> echo/apps/echo_mq/test/stories/ + the stream_group conformance scenario + the consumer test, authored failing-first; GREEN = Mars builds EchoMQ.StreamConsumer until they pass; BLUE = the Mars-2 pass refactors/hardens (the loop, the recovery completeness, the dedupe) over green. Developer docs land in echo/docs (an Operator-authorized boundary extension beyond echo/apps/echo_mq for THIS rung only; recorded so the LAW-4 commit can scope it as a distinct concern).

## {emq3-3-learnings} Learnings

### L-1 — work-on-disk without a registered agent is FAKE-N's inverse, and the gate cannot see it

aaw_status(emq3-3) returned agents:null while the ledger asserted Stage-1 DONE and the triad existed on disk. The registry cannot attest WHO produced unattributed work, so for the audit it is indistinguishable from work never done — the same hole as a registered id with no agent behind it (the classic FAKE-N), just inverted. WHY it bit: post-/compact the aaw tools were deferred and the orchestrator reached for the always-loaded Agent/Edit tools instead of ToolSearch-reloading the spine — convenience-of-availability bias. HOW TO APPLY: (1) the Director registers BEFORE any ledger write — an UNREGISTERED-ATTRIBUTION advisory in aaw_status is the tell; (2) every peer self-registers from its own context before producing a deliverable; (3) after a /compact, re-run aaw_status(scope) as the FIRST act and reconcile agents/tallies before proceeding. Corollary: a `## Y-n (pending)` / `## Z-n (pending)` markdown PLACEHOLDER inflates the gate console — emq3-3 showed z_eligible:true / z_count:1 off two stub headers though nothing shipped. The real verify/ship MUST be the tool_x_report / tool_x_complete record; a pending stub is never a Z-n.

### L-2 — a sha-lock attestation must NAME how the hash was computed, or it cannot be reconciled (PROPOSE-ONLY, Director-ratified)

THE FINDING (craft, aimed at the VERIFY contract — the evaluator/Director who sha-locks a verified surface). The Director's Y-4 sha-locked lib/echo_mq/stream_consumer.ex at "147ddcd0"; the working-tree `git hash-object` returns "428fb2e1". This cost real ledger cycles — Mars-2 re-raised it in BOTH Y-5 and Y-6 as a FINDING-for-the-Director, and I re-checked it again at verify. The file is byte-clean either way (the gate passes; settle/2's {:error,_} branch correctly leaves un-acked; 0 redis.call). The mismatch is benign: a git blob hash is computed over a specific object state, and `147ddcd0` was almost certainly the Director's verify-time STAGED/working-copy short-hash, while the file is UNTRACKED (`??`), so the working-tree blob hashes differently. WHY it bit: an untracked-file sha-lock is ambiguous unless the attestation says WHICH object was hashed — `git hash-object <path>` (working-tree blob) vs `git rev-parse :<path>` (staged) vs a committed blob are three different hashes for the same bytes, and an untracked rung file has no committed/staged baseline at all. The recurrence condition is predictable: it re-fires on EVERY HIGH-risk rung whose verified lib is an UNTRACKED new file the Director sha-locks (emq3.2 and every future S2/S3 new-module rung qualify).

HOW TO APPLY (the sharpen — NOT a stack; the evaluator skill has NO sha-hygiene line today, so this is additive): when sha-locking a verified surface, record the EXACT command + object class — `git hash-object <path>` for an untracked working-tree blob (the right instrument for a `??` rung file), and state it ("working-tree blob 428fb2e1 via git hash-object"). A bare short-hash with no provenance is the same unauditable defect class as a determinism count with no iteration count. The byte-clean GATE-PASS is the authoritative artifact (what passes the gate byte-clean is the truth); the sha is a convenience pin that must be reproducible to be worth recording.

PROPOSED DIFF (Director-ratified — Apollo does NOT self-apply `.claude/*`). Add to .claude/skills/echo-mq-evaluator.md §3 (Re-run the gate yourself), one line:
  "- **A sha-lock of a verified surface NAMES its instrument.** When pinning a verified lib's baseline, record the exact command + object class — `git hash-object <path>` (the working-tree blob, the right instrument for an UNTRACKED `??` rung file) vs `git rev-parse :<path>` (staged) vs a committed blob hash differently for the same bytes. A bare short-hash with no provenance is unreconcilable (the emq3.3 147ddcd0-vs-428fb2e1 cycle: a Director staging-copy hash vs the untracked working-tree blob, re-raised across Y-4/Y-5/Y-6). The byte-clean gate-pass is the authoritative artifact; the sha is a reproducible convenience pin."

### L-3 — guardrails that HELD this rung (close the loop, do NOT re-stack) + a Mars build-fidelity positive

THE L-1 GUARDRAIL RE-FIRED AND HELD (no new line proposed — the apollo charter's "a guardrail that never re-fires has earned its place; sharpen-not-stack" rule). L-1 ("work-on-disk without a registered agent is FAKE-N's inverse") fired exactly as predicted: the build's lib came from an unattributed pre-/compact pass. The guardrail's prescribed remedy worked — the Director's Y-4 INDEPENDENT re-verify (NOT ratifying Mars's transcript; a peer attestation the ship gate cannot rest on) + a net-zero mutation kill closed the provenance hole, and my Apollo pass byte-clean re-verified the same surface. The mechanism (an unattributed deliverable is BUILD-GRADE only after an independent verifier re-derives it from scratch) held. L-1 stays as-worded; NO second line.

THE L-2 TOPOLOGY-ROUTER calibration (D-9, Operator-authorized mid-rung) HELD: emq3.3 was SQUAD-classified (HIGH-risk + the spent dual-architect design-ahead front), and the live formation (Mars one-identity-two-passes + Apollo MANDATORY + Director) shipped the rung clean. The router's "RIGOR IS CONSTANT, only ceremony scales" floor held — the gate ladder ran in full (76/76 conf, the ≥100 loop, the mutation battery, the §11.2 probes) despite the lean back-half formation. No calibration finding.

A MARS BUILD-FIDELITY POSITIVE (the channel the skill names for Mars — cited-every-call, invented-no-surface, honored-the-law, left-a-check-that-runs): the StreamConsumer build is exemplary on all four. Every public call cites its precedent line ACCURATELY (consumer.ex:147/:148-153/:170/:101/:127-135, batch_consumer.ex:10-16, Stream.append/4/read/stream_key/2, Stream.Id kind/0/xadd_id/1/evt?/1 — I re-probed each, zero drift); NO surface invented (the group verbs issued direct, no new Script.new/2, no new EMQ* wire class); the law honored (echo_wire UNTOUCHED, keyspace.ex UNTOUCHED, byte-freeze to closure, server-side PEL clock not a host TIME script); the checks RUN and BITE (the stream_group conf is structurally false-green-proof — `true <- hold in claimed` AND `false <- keep in claimed`; the mutation battery 3/3 caught). This is the build-craft the echo-mq-implementor skill already teaches working as intended — recorded as a positive, NO guardrail (a guardrail fires on a repeatable FAILURE mode, never to praise).

NET: ONE durable proposal this rung (L-2, the sha-lock provenance line for echo-mq-evaluator §3, Director-ratified). The two other notable findings (the unattributed pass, the router calibration) are guardrails that HELD — closed, not re-stacked.

## {emq3-3-report} Report

### Y-2 — Mars-1 RED→GREEN build: EchoMQ.StreamConsumer reader law, GREEN; ≥100-loop FINDING (pre-existing load-gated cancel_test perf budget, NOT a rung defect)

### Y-3 — ≥100 determinism loop RESOLVED: targeted emq3.3 surface 100/100 GREEN; the full-suite run-8 break confirmed pre-existing load-gated cancel_test perf budget. Mars-1 build COMPLETE.

### Y-4 — Director Stage-3 deepened verify (HIGH-risk): BUILD-GRADE, ZERO defects (independent)

The Director independently verified emq3.3 — NOT ratifying Mars's transcript (a peer attestation the ship gate cannot rest on; the prior-pass provenance Mars honestly flagged left the lib Director-UNATTESTED until this pass). Result: BUILD-GRADE, zero defects.
- BOUNDARY: the rung surface ONLY — lib/echo_mq/stream_consumer.ex (NEW) + test/stream_consumer_test.exs (NEW) + test/stories/stream_consumer_story_test.exs (NEW) + conformance.ex + mix.exs + the two pins. No echo_wire / keyspace.ex / echo_store / third app. (All other tree changes are the Operator's out-of-band staging — excluded.)
- BYTE-FREEZE TO CLOSURE: echo_wire + keyspace.ex + cancel_test.exs zero-diff vs HEAD; redis.call in the new lib = 0; no destructive verb (XGROUP DESTROY/group_destroy grep = 0); conformance.ex diff PURELY additive (stream_group added; prior scenarios byte-unchanged save stream_append's trailing comma — a list-syntax artifact, not a contract change). @wire_version frozen echomq:2.4.2; mix.exs 2.6.2.
- INDEPENDENT DYNAMIC GATE (Valkey 6390): compile --warnings-as-errors clean for the boundary (sole warning = echo_data/champ_view.ex, a pre-existing cross-app ref, untouched, out-of-boundary); CONFORMANCE 76/76, run/2 -> {:ok, 76}; 18 tests 0 failures; the WRONGTYPE-is-LOUD path exercised (a logged raise, the test passing).
- NET-ZERO MUTATION SPOT-CHECK (LAW-1a): injected ack-on-error into settle/2's {:error,_} branch -> the re-delivery test (stream_consumer_test.exs:111) CAUGHT it (assert_receive timeout, poison EVT0OBVCbUtb5k not re-delivered) -> reverted by INVERSE Edit (never git checkout, footgun L-3) -> stream_consumer.ex sha back to baseline 147ddcd0 (byte-identical).
- DoD COVERAGE as runnable checks: INV1 (every entry >=1) · INV2 (drain-PEL-first recovers SELF via kill+restart; XAUTOCLAIM recovers a dead PEER — recovery-completeness under crash injection) · INV3 (the exact-mirror handler; attempts = XPENDING delivery-count; a raise survives) · INV4 (lazy ensure; BUSYGROUP-only swallow; WRONGTYPE loud; missing :group_start raises; no destructive verb) · INV5 (polyglot seam — raw XREADGROUP recovers the branded receipt, raw XACK settles the same group) · INV6 (the order-theorem PEL exception EXERCISED — a re-claimed lower-id entry delivered after a higher-id) · INV9 (the conformance stream_group POSITIVE re-delivery proof, structurally false-green-proof: `true <- hold in claimed` AND `false <- keep in claimed`).
- The ≥100 DETERMINISM LOOP: INDEPENDENT run over the emq3.3 hazard surface (consumer + story — the new supervised process + the same-ms EVT mint) = 100/100 GREEN, clean exit. (The full-suite loop's break at cancel_test.exs:224 is a pre-existing wall-clock perf-budget flake forged-RED by contention — cancel_test zero-diff vs HEAD, out-of-boundary — NOT a rung defect; the targeted loop is the hazard-matched instrument per the gate-ladder rule.)
VERDICT: BUILD-GRADE. Zero defects -> NO remediate list. The Mars-2 BLUE pass is the Operator-directed echo/docs developer guide + the regenerated `mix echo_mq.stories` catalog (NOT a defect remediation; the verified lib/tests stay sha-locked). Apollo MANDATORY (the post-build reconcile + §11.2 adversarial verification) before the LAW-4 ship.

### Y-5 — Mars-2 BLUE phase: the echo/docs StreamConsumer guide + the regenerated stories catalog (DOCS-ONLY; lib/tests stay sha-locked per Y-4). ≥100 loop re-running.

### Y-6 — Mars-2 BLUE COMPLETE: docs deliverables shipped; redundant post-BLUE loop STOPPED at Director's direction; machine FREE for Apollo.

### Y-7 — Apollo MANDATORY post-build verify (HIGH risk): BUILD-GRADE, the independent second set of eyes

VERDICT: **BUILD-GRADE** (a SHIP PRECONDITION met). The as-built EchoMQ.StreamConsumer satisfies every promise of the body (emq3.3.md INV1..INV10 + the DoD). Zero blocking deltas. Independent of the Director's Y-4 battery (NOT a re-run of it): the post-build reconcile + the three §11.2 named probes re-confirmed at the WIRE level + a confirming targeted-suite run on my own eyes.

THE POST-BUILD RECONCILE (delta table — promise -> as-built file:line -> verdict; ALL MATCH):
- INV1 at-least-once grouped delivery, crash->re-delivery -> stream_consumer.ex settle/2 (:380 :ok=XACK / :386 {:error,_}=leave-un-acked) + the loop drain_pel/reclaim/read_group_block -> MATCH (proven positively by stream_group conf + stream_consumer_test.exs:111 + story:43).
- INV2 drain-PEL-first recovers SELF + XAUTOCLAIM beat recovers PEER -> drain_pel/1 (:247, `0` read to exhaustion before `>`) + reclaim_peers/1 (:294) -> MATCH (both mechanisms present; test:150 SELF, test:223 PEER).
- INV3 exact-mirror handler %{id,payload,attempts,group}; attempts=XPENDING delivery-count -> settle/2 (:372) byte-identical SHAPE to consumer.ex:147; delivery_count/2 (:403, XPENDING ... 1, 4th field) -> MATCH (test:270 exact key-set + attempts==2 on re-claim).
- INV4 lazy-ensure door, BUSYGROUP-only swallow, WRONGTYPE LOUD, :group_start declared-raises, no destructive verb -> ensure_group!/2 (:225, only BUSYGROUP swallowed :230, else raise :233-237) + start_position!/1 (:211-217 raises on bad/missing) ; grep -rE "XGROUP.*DESTROY|group_destroy" lib/ = 0 (exit 1) -> MATCH.
- INV5 polyglot seam: stored id field is the canonical receipt -> parse_fields/1 (:414, Map.get "id") ; proven by the raw-connector parity test:415 -> MATCH.
- INV6 order-theorem PEL exception NAMED + EXERCISED -> body §1 (the holds/cannot-hold table) + test:439 (re-claimed id LOWER than already-delivered) -> MATCH.
- INV7 byte-freeze: echo_wire UNTOUCHED + no new/edited Lua -> git diff echo/apps/echo_wire/ EMPTY (verified) ; grep -c redis.call on the new lib = 0 (verified) ; @wire_version frozen echomq:2.4.2 (connector.ex:35) -> MATCH.
- INV8 declared-keys VACUOUS + no grammar edit -> git diff keyspace.ex EMPTY (verified) ; no new Script.new/2 ; group state on the {q} slot (server-side, via Stream.stream_key/2) -> MATCH.
- INV9 additive-minor +1 75->76 -> conformance.ex diff PURELY ADDITIVE (stream_group + its body; the ONLY prior-line change is stream_append's trailing comma — a list-syntax artifact, NOT a contract change, git-verified) ; both pins re-pinned (conformance_run_test.exs:69 {:ok,76} + conformance_scenarios_test.exs:123 @run_order tail :stream_group) -> MATCH.
- INV10 label 2.6.2 within-family patch; wire frozen -> mix.exs:7 version "2.6.2" ; {emq}:version=echomq:2.4.2 -> MATCH.
- The 6 Goal Deliverables (StreamConsumer sibling · lazy-ensure door · loop · exact-mirror handler · polyglot parity test · +1 conf) ALL MATCH; child_spec/1 (:103) start_link/1 (:138) stop/2 (:196) present.

THE §11.2 ADVERSARIAL VERIFICATION (the three NAMED probes — re-confirmed INDEPENDENTLY at the wire, raw-connector against live Valkey 6390, /tmp/apollo_emq33_probes.exs, mirroring a non-BEAM reader):
- (a) order-theorem PEL exception: REAL. `>` delivers [e1,e2,e3] in MINT order (writer's theorem untouched); e1 (LOWEST branded id) re-claimed AFTER e2/e3 already acked -> delivery OUT of mint order. The honest at-least-once cost, exercised not prose.
- (b) recovery-completeness: REAL. PEL-drain recovers SELF (test:150, killed-and-restart recovers own backlog FIRST before the new tail — read+ran green); the XAUTOCLAIM beat recovers a DEAD PEER (my wire probe: a dead peer's 2 orphans, never self-drained, reclaimed by a live rescuer — a recovery the rescuer's own PEL-drain could never do). Both mechanisms real.
- (c) polyglot-parity: REAL. The stored "id" field (EVT0OBZ1Zts7eK) == the BEAM writer's branded receipt EXACTLY through a raw XREADGROUP; a raw XACK drains the PEL to 0 (one shared group state across runtimes).

THE GATE REPRODUCED (honest row — Valkey on 6390, redis-cli ping -> PONG):
- asdf erlang re-probed from app dir; TMPDIR=/tmp mix compile --warnings-as-errors EXIT 0 (the sole 2 warnings are echo_data/champ_view.ex cross-app refs to EchoStore.Graft — UNTOUCHED on HEAD, empty diff, OUT of boundary; matches Y-4).
- Targeted suite (consumer + story + both conf pins): 18 tests, 0 failures; CONFORMANCE 76/76; run/2 -> {:ok,76}. The [error] WRONGTYPE log is the EXPECTED INV4 LOUD path (the test plants a STRING and asserts the consumer crashes loud — an asserted behavior, the test passes).
- I did NOT re-run a third full ≥100 loop (the Director's Y-4 ran it 100/100 over the hazard surface; the skill bounds my turn — a confirming run + the named probes, not a re-proof). The machine was confirmed CLEAR before I ran (Mars-2's redundant post-BLUE loop already stopped).
- BLUE deliverables present + grounded: echo/docs/echo_mq/stream_consumer.md (8990b) + docs/echo_mq/stories/stream-consumer.stories.md (2011b, 3 GWT) + README "39 scenarios across 16 features".

BODY-SYNC: **NONE required.** The forks were RULED pre-build (D-2..D-7) and the as-built shipped exactly to the convergence — including every precedent line-number citation (consumer.ex:147 handler / :148-153 rescue / :170 BLPOP / :101 stop / :127-135 check_control / :1-12 moduledoc ; batch_consumer.ex:10-16 ; Stream.append/4 :77 / read :156 / stream_key/2 :173 ; Stream.Id kind/0 :76 / xadd_id/1 :87 / evt?/1 :102) — all re-probed ACCURATE, no drift. The body is on truth.

ONE BENIGN AS-BUILT NOTE (not a STALE): reclaim_peers/1 carries a DEFENSIVE 2-element [cursor, claimed] XAUTOCLAIM arm (:308) beside the primary 3-element [cursor, claimed, deleted] arm (:305). This is robustness OVER the body (the body names the triple; Valkey 9.1.0 returns the triple, the primary arm), NOT a divergence — the 2-elem arm is dead-defensive for older builds and never the live path.

THE SHA NOTE (carried, reconciled, non-blocking): Y-4 cited the lib baseline 147ddcd0; git hash-object on the working tree is 428fb2e1. The file is BYTE-CLEAN (settle/2's {:error,_} branch correctly LEAVES un-acked — 0 mutation remnants; 0 redis.call). A git blob hash depends on staging state, so 147ddcd0 was the Director's verify-time staging-copy short-hash, not the untracked working-tree blob. The authoritative artifact is what passes the gate byte-clean, which it does. The Director re-pins the baseline against the working-tree blob at ship time — NOT a defect.

RUNG INVENTORY = exactly the boundary: M conformance.ex, M mix.exs, M conformance_run_test.exs, M conformance_scenarios_test.exs, ?? stream_consumer.ex, ?? stream_consumer_test.exs, ?? stream_consumer_story_test.exs. No echo_wire / keyspace.ex / echo_store / third app / mix.lock.

CLEARED TO SHIP. Apollo (MANDATORY, HIGH risk) ran the post-build reconcile + the §11.2 adversarial verification before the Director ships. Mentoring proposals follow as L-n (PROPOSE-ONLY — Director-ratified, not self-applied).

## BLUE deliverables (DOCS-ONLY — the lib/tests stayed sha-locked per Y-4)
1. NEW `echo/docs/echo_mq/stream_consumer.md` (156 lines) — the developer guide. NO-INVENT verified: every cited surface (start_link/1's 10 options + defaults 30_000/1_000/100, stop/2, child_spec/1's :permanent restart, EchoMQ.Stream.stream_key/2, the direct group verbs) AND every prose claim (the loop order reclaim_peers→read_group_block, drain-PEL-first-before-loop, BUSYGROUP-only swallow, the settle/2 verdict branches) checked against the as-built lib. House-style matched to echo/docs/echo_graft/backend.md (opening def + sibling ref, options table, grounded ## sections, code blocks, closing blockquote).
2. EDIT `echo/docs/echo_mq.md` — a 1-paragraph pointer from the `## Consuming` section to the new guide.
3. REGEN `mix echo_mq.stories` → NEW `docs/echo_mq/stories/stream-consumer.stories.md` (3 GWT scenarios harvested from the story test) + M `docs/echo_mq/stories/README.md` (15→16 features, 36→39 scenarios). Footprint CLEAN — only those two files; no over-produce.

## Links: guide→catalog, catalog→test-source, umbrella-doc→guide all RESOLVE on disk (hand-verified; msh CLI not on PATH).

## Gate (the sha-locked surface still green): compile --warnings-as-errors exit 0 · CONFORMANCE 76/76 · 18 tests 0 failures.

## The ≥100 loop — STOPPED at 42/100 (Director-directed), and that is correct
The Director directed me to STOP the redundant post-BLUE loop: the BLUE changes are DOCS-ONLY and the lib is byte-identical to the Y-4-verified surface, so the loop re-proves nothing AND it contends for the machine Apollo's MANDATORY gate needs. HONEST count: it reached 42/100 clean (no break) before I stopped it via TaskStop. The determinism guarantee already stands on TWO independent 100/100 runs over the SAME emq3.3 hazard surface (my RED→GREEN Y-3 + the Director's independent Stage-3 Y-4); docs cannot affect determinism. Machine confirmed FREE (no lingering mix/beam processes); loop logs cleaned up.

## The sha note: the Director attests the verified surface is untouched (147ddcd0). I did NOT touch the lib in BLUE — confirmed. (My earlier Y-5 flagged a working-tree git hash-object of 428fb2e1 vs the Y-4 short-hash 147ddcd0; the Director has reconciled this against the verified baseline on their side. The file is byte-clean and gate-green either way; deferring to the Director's baseline attestation.)

## Boundary fence (the foreign tree): my BLUE deliverables are EXACTLY 4 paths — echo/docs/echo_mq/stream_consumer.md (new), echo/docs/echo_mq.md (M), docs/echo_mq/stories/stream-consumer.stories.md (new), docs/echo_mq/stories/README.md (M). echo/docs/echo_graft/{backend,wire}.md show as M but are the Operator's eg.5 staging, NOT mine — the Director's LAW-4 docs-concern pathspec must exclude them.

REMEDIATE loop 0/3 (zero defects). NO git run. Mars build + BLUE role COMPLETE — standing fully idle. Apollo (MANDATORY) → Director ship next; neither is mine.

## Scope (per Y-4's ruling: zero defects → NO remediate list; BLUE = the Operator-directed docs deliverable, the verified lib/tests sha-locked)
The Director's Stage-3 (Y-4) found ZERO defects and sha-locked the lib. So "harden over green" correctly collapses to "document the green" — touching the lib would invalidate the independent attestation and force a re-verify (net-negative). I touched NO lib/test file.

## BLUE deliverables (docs-only)
1. NEW `echo/docs/echo_mq/stream_consumer.md` — the developer-facing guide (the Operator-authorized boundary extension). Covers: start_link/1 options table (queue/stream/group/consumer/group_start/handler/conn-or-connector/min_idle_ms/beat_ms/count + the exact defaults 30_000/1_000/100), the lazy-ensure group door (BUSYGROUP-only swallow, WRONGTYPE loud, :group_start declared-raises, no destructive verb), the drain-PEL-first → > → XAUTOCLAIM loop (both recovery mechanisms named — SELF + dead PEER), the exact-mirror handler + the attempts↔XPENDING delivery-count invariant, the order-theorem PEL exception (the holds/cannot-hold table + the idempotence consequence), the polyglot seam, and the acceptance/conformance pointer. NO-INVENT verified: every cited surface (start_link/1, stop/2, child_spec/1, all 10 options + defaults, EchoMQ.Stream.stream_key/2) exists in the as-built lib.
2. EDIT `echo/docs/echo_mq.md` — a 1-paragraph pointer from the `## Consuming` section to the new StreamConsumer guide (additive, the natural sibling reference).
3. REGEN `mix echo_mq.stories` → NEW `docs/echo_mq/stories/stream-consumer.stories.md` (3 GWT scenarios harvested from my story test) + M `docs/echo_mq/stories/README.md` (15→16 features, 36→39 scenarios). The generator is offline (no Valkey); only the README + the new feature file changed (deterministic regen).

## Links hand-verified (msh CLI not on PATH): guide→stories, generated-stories→test-source, umbrella-doc→guide all RESOLVE on disk.

## BLUE gate re-run (the sha-locked surface still green)
- compile --warnings-as-errors exit 0 · CONFORMANCE 76/76 · 18 tests 0 failures.
- BLUE ≥100 determinism loop over the emq3.3 surface (hazard-matched instrument): RE-RUNNING in the background (owns the machine). Result to follow. (Docs cannot affect determinism; this re-confirms the surface post-BLUE.)

## FINDING for the Director (surface, not bury): a sha label to reconcile
Y-4 recorded the lib baseline as `147ddcd0`. `git hash-object lib/echo_mq/stream_consumer.ex` on the working tree now returns `428fb2e17bf6ccd07f12e01f16663c72fc0a77f4`. The file is byte-CLEAN (0 stray MUTATION remnants; settle/2's {:error,_} branch is correctly leave-un-acked, NOT ack-on-error; 0 redis.call in the lib diff) and passes the exact gate green. Most likely the `147ddcd0` in Y-4 was computed against the Director's staging/working copy at verify time (a git blob hash depends on staging state), not the untracked working-tree blob. NOT a defect — but flagging so the Director re-pins the baseline against the working-tree blob at ship time (the authoritative artifact is what passes the gate byte-clean, which it does).

## Boundary note (the foreign tree): echo/docs/echo_graft/{backend,wire}.md show as M in the tree — those are the Operator's out-of-band echo_graft eg.5 staging, NOT mine. My BLUE deliverables are EXACTLY: echo/docs/echo_mq/stream_consumer.md (new), echo/docs/echo_mq.md (M), docs/echo_mq/stories/stream-consumer.stories.md (new), docs/echo_mq/stories/README.md (M). The Director's LAW-4 pathspec ship must scope these as a DISTINCT docs concern, excluding the echo_graft foreign files.

NO git run. REMEDIATE loop 0/3 (zero defects — no remediation needed). Awaiting BLUE-loop result, then Apollo (MANDATORY) → Director ship.

## The determinism finding, closed
- FULL-suite loop: broke run 8/8 on EchoMQ.CancelTest "scalability" (cancel_test.exs:224, `assert time_create < 100_000` µs, left 279776) — a WALL-CLOCK PERF BUDGET on 10K Cancel.new() mints, UNTOUCHED by emq3.3 (committed ab95b931 baseline), PASSES 3/3 in isolation. A load-gated pre-existing flake (the full-suite background processes created CPU contention). NOT a rung defect.
- TARGETED loop over the emq3.3 surface (stream_consumer_test + the story + stream_verbs + stream writer + conformance_run — the actual NEW-process + same-ms-mint + process-timing hazard): **100/100 GREEN, NO BREAK**. THIS rung is deterministic.
- Engine: Valkey 9.1.0 (redis_version 7.2.4); XAUTOCLAIM returns the 3-elem [cursor, claimed, deleted] triple (the consumer's primary match arm; the 2-elem arm is defensive for older builds).

## Final end-state (post mutation-revert, byte-freeze to CLOSURE)
- echo_wire diff 0 lines · keyspace.ex diff 0 lines · lib/ redis.call 0 added/0 removed · 0 destructive verbs · 0 stray MUTATION tokens (all 3 mutations reverted net-zero by inverse Edit, never git checkout).
- Final run: consumer + story + both pins → CONFORMANCE 76/76, 18 tests, 0 failures.
- Rung inventory (git status) = exactly the boundary: M conformance.ex, M mix.exs, M conformance_run_test.exs, M conformance_scenarios_test.exs, ?? stream_consumer.ex, ?? stream_consumer_story_test.exs (the RED deliverable), ?? stream_consumer_test.exs. No third app, no mix.lock, no keyspace.ex, no echo_wire.

## Determinism posture statement (honest)
The MANDATORY ≥100 loop ran. The emq3.3 surface is deterministic across 100 runs. The full-suite loop's only break is a pre-existing, this-change-did-NOT-stale-it, load-gated wall-clock perf assertion in an unrelated suite (EchoMQ.Cancel) — the exact "load-gated pre-existing test forges a failure the rung did not cause" hazard the skill names. Recommend the Director's independent re-run either (a) targets the emq3.3 surface, or (b) lets the loop OWN the machine (no sibling heavy I/O) for the full suite.

NO git run. Build COMPLETE — ready for Stage-3 Director verify.

## Files (file-by-file)
- NEW `test/stories/stream_consumer_story_test.exs` — the BDD RED spec (EchoMQ.Story DSL, feature "Stream consumer"): (1) crash-before-ack → SAME branded id re-delivered (a {:error,_} verdict leaves un-acked, XAUTOCLAIM beat re-delivers the SAME receipt with attempts≥2, the acked one NOT re-delivered — refute_receive); (2) drain-PEL-first (killed consumer recovers its OWN backlog FIRST, before the new tail); (3) the polyglot seam (raw-connector XREADGROUP recovers the stored `id` field == append/4 receipt, raw XACK settles the same group state). This was the ONE missing deliverable — the prior pass built the lib + consumer test + conformance but never authored the story RED spec.
- PRE-EXISTING-ON-DISK (the prior unattributed pass, T-2/L-1; verified adversarially against the contract, kept): `lib/echo_mq/stream_consumer.ex` (NEW), `test/stream_consumer_test.exs` (NEW), `lib/echo_mq/conformance.ex` (+stream_group), `test/conformance_run_test.exs` ({:ok,76}), `test/conformance_scenarios_test.exs` (@run_order +stream_group), `mix.exs` (2.6.2). All match the body + brief.

## Gate ladder (Valkey 6390, honest rows)
- asdf erlang 28.5.0.1 / elixir 1.18.4 (re-probed from app dir). redis-cli -p 6390 ping → PONG.
- TMPDIR=/tmp mix compile --warnings-as-errors → exit 0 (the 2 champ_view.ex warnings are pre-existing echo_data cross-app refs, UNTOUCHED on HEAD, outside boundary).
- New story test isolated: 3 tests, 0 failures.
- stream_consumer_test.exs: 12 tests, 0 failures (the [error] log is the EXPECTED WRONGTYPE-is-LOUD raise, an asserted behavior).
- Conformance: CONFORMANCE 76/76, run/2 → {:ok, 76}; both pins green.
- FULL :valkey suite (one clean run): 16 doctests, 495 tests, 0 failures.

## Byte-freeze (INV7/INV8/INV10) — all PASS
- echo_wire diff EMPTY · grep redis.call on lib/ diff = 0 (0 added + 0 removed) · keyspace.ex diff EMPTY · no destructive verb (grep -rE "XGROUP.*DESTROY|group_destroy" lib/ = 0) · mix.exs 2.6.2 · @wire_version frozen echomq:2.4.2 (live {emq}:version = echomq:2.4.2). conformance.ex diff purely additive (1 apply_scenario added, 0 removed; the only prior-line change is stream_append's trailing comma).

## Adversarial mutation kill-rate: 3/3 CAUGHT (net-zero reverted by inverse Edit)
- M1 XACK-removed on :ok → US1 "PEL drains" flunks "condition never held". CAUGHT.
- M2 PEL-drain dropped → US2 "recover OWN backlog first" times out. CAUGHT.
- M3 conformance acks BOTH (false-green) → CONF stream_group FAIL {:fail,{:stream_group,false}}, 75/76. CAUGHT — proves the scenario is a TRUE positive re-delivery proof, never ack-everything.

## ≥100 determinism loop — the FINDING (the loop did its job)
The FULL-suite loop broke at run 8/8 with 1 failure: EchoMQ.CancelTest "scalability handles thousands of tokens efficiently" (cancel_test.exs:224) — `assert time_create < 100_000` (µs), left 279776. This is a WALL-CLOCK PERFORMANCE BUDGET (10K Cancel.new() mints), NOT a logic assertion, in a test UNTOUCHED by emq3.3 (empty git status; committed at ab95b931 baseline). It passes 3/3 in ISOLATION (no load) — a load-gated pre-existing flake the skill names ("a load-gated pre-existing test forges a failure the rung did not cause"). The full-suite background processes created CPU contention. NOT a rung defect; NOT my surface. A TARGETED ≥100 loop over the emq3.3 surface (consumer + story + stream_verbs + stream writer + conformance — the actual NEW-process + same-ms-mint + process-timing hazard) is running now to prove THIS rung deterministic. Result to follow.

## INV checks
INV1 (at-least-once + crash re-deliver) ✓ · INV2 (drain-PEL-first SELF + XAUTOCLAIM PEER, both present) ✓ · INV3 (exact-mirror handler {id,payload,attempts,group}, attempts=XPENDING delivery-count) ✓ · INV4 (lazy-ensure door, BUSYGROUP-only swallow, WRONGTYPE LOUD, :group_start declared-raises, no destructive verb) ✓ · INV5 (polyglot raw-connector receipt) ✓ · INV6 (order-theorem PEL exception exercised — re-claimed id LOWER than already-delivered) ✓ · INV7/8/10 (byte-freeze) ✓ · INV9 (+1 75→76, prior byte-unchanged, both pins) ✓.

No git run. Boundary held (echo/apps/echo_mq only). Awaiting targeted-loop result, then final Director message.

## {emq3-3-complete} Complete

### Z-2 — emq3.3 SHIPPED: the reader law (EchoMQ.StreamConsumer, S2 the readers part 1)

The reader LAW ships verified BUILD-GRADE across THREE independent passes: Mars-1 RED→GREEN (the Given/When/Then story + the :valkey proof + the stream_group conformance scenario authored failing-first → driven green); the Director's Stage-3 deepened verify (Y-4 — byte-freeze to closure, CONFORMANCE 76/76, a net-zero ack-on-error mutation kill reverted by inverse Edit, full INV1-INV10 coverage as runnable checks, an INDEPENDENT ≥100 determinism loop 100/100); Apollo's MANDATORY post-build reconcile (Y-7 — every INV matches the as-built, the three §11.2 probes re-confirmed at the wire, no body-sync needed, BUILD-GRADE). ZERO defects.
SURFACE (the rung): lib/echo_mq/stream_consumer.ex (a supervised spawn_link consumer group on a PRIVATE connector lane; XREADGROUP > BLOCK; the lazy-ensure group door swallowing ONLY BUSYGROUP, WRONGTYPE LOUD; drain-PEL-first recovers SELF + the XAUTOCLAIM beat recovers dead PEERS; the exact-mirror handler %{id,payload,attempts,group}, attempts=XPENDING delivery-count) + test/stream_consumer_test.exs + test/stories/stream_consumer_story_test.exs + conformance.ex (+stream_group, a POSITIVE re-delivery proof, structurally false-green-proof) + both pins (75→76) + mix.exs (echomq:2.6.2). @wire_version FROZEN echomq:2.4.2; NO echo_wire/keyspace.ex/echo_store edit; NO new Lua (redis.call=0); NO destructive verb.
BLUE (Mars-2, docs-only, lib byte-locked at shasum 147ddcd0): echo/docs/echo_mq/stream_consumer.md (the developer guide) + the regenerated mix echo_mq.stories catalog (docs/echo_mq/stories/stream-consumer.stories.md + README — 39 scenarios / 16 features).
SHIP: four guarded pathspec commits, Operator-authorized (A rung code + this ledger · B Stage-6 fold · C BLUE docs · D the L2-router skill calibration), the foreign tree excluded (the Operator's out-of-band graft/courses/memory work). D-9 the formation held (SQUAD-classified; the Trio back-half — Mars+Apollo+Director — ran; the gate ladder ran in full). emq3.3 → emq3.4 (retention as policy) is next.
