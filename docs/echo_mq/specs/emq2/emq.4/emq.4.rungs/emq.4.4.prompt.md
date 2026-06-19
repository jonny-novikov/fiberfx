# EMQ.4.4 · the build orchestration runbook — weighted/deficit rotation + the starvation drill (the groups-family CAPSTONE)

> The authoritative run scope for shipping emq.4.4 via `/echo-mq-ship` (Flat-L2, Director-supervised). The body
> ([`emq.4.4.md`](emq.4.4.md)) is the contract; the acceptance is [`emq.4.4.stories.md`](emq.4.4.stories.md); the
> Mars brief is [`emq.4.4.llms.md`](emq.4.4.llms.md). This runbook binds them to the pipeline stages + the gate
> ladder + the Fork-B-conditional risk tier. **No decision the body has fixed is left open here — EXCEPT Fork B
> (the weighted-rotation mechanism), which the Operator rules at the pre-build reconcile (the Director routes via
> AskUserQuestion). The risk grade + the formation + the determinism posture are CONDITIONAL on that ruling.**
>
> **Framing law (propagated).** Third person for any agent; no gendered pronouns for agents; no perceptual or
> interior-state verbs for agents or software; no first-person narration. Bind this same clause in any sub-brief.

## The family in one paragraph

emq.4 deepens the shipped fair-lanes (groups) surface to multi-tenant production depth across four
dependency-ordered sub-rungs ([`../emq.4.md`](../emq.4.md), the Operator-ruled spine): **emq.4.1** the control
plane (move/re-assign a member between lanes; deepened pause/resume/limit/drain) — SHIPPED; **emq.4.2**
group-aware recovery (a group-scoped stalled-sweep into the member's own lane) — SHIPPED; **emq.4.3** the
park-don't-poll metronome (`EchoMQ.Metronome` — one `BLPOP wake` blocker + an idle-consumer registry per queue,
BEAM-message fan-out, the opt-in consumer path) — SHIPPED; **emq.4.4** weighted/deficit rotation + the starvation
drill — THIS rung, the CAPSTONE. Each ships independently; nothing in the family is a wire break.

## The rung in one paragraph

emq.4.4 deepens the **rotation** itself. Today the ring serves serviceable lanes in **strict round-robin** —
`@gclaim` rotates the ring one step (`LMOVE KEYS[1] KEYS[1] 'LEFT' 'RIGHT'`, lanes.ex:38) then `ZPOPMIN`s that
lane's head (lanes.ex:41), so every serviceable lane gets an equal turn (constructed, not hashed — D-9). emq.4.4
takes fairness from **equal** to **proportional**: a lane carries a **weight**, and the rotation serves lanes **in
proportion to weight** (weighted / deficit round-robin) — plus the **starvation drill**, the capstone proof that
**no lane starves under skew** (a heavy lane cannot monopolize the machine; a quiet lane is still served). It is
the capstone because it is the highest-risk axis (it may re-shape the shipped `@gclaim` ring rotation, the
fairness-critical claim path) and it builds on the whole chapter (4.1 shapes the lanes, 4.2 keeps them whole, 4.3
wakes them, 4.4 decides which lane is served and in what share). All under the v2 master invariant (braced
keyspace · branded group ids gated · declared keys A-1 · server clock on any lease · no new key family · no wire
break).

## Mode

**Flat-L2, Director-supervised.** Venus (reconcile/author the triad — DONE; loads `echo-mq-architect`) → Mars-1
(build to the brief — `echo-mq-implementor`) → Director solo review (independent gate re-run on Valkey 6390 + an
adversarial probe + a net-zero mutation spot-check) → Mars-2 (remediate + harden) → Director ship (one LAW-4
pathspec commit). **Apollo (`echo-mq-evaluator`) is MANDATORY iff Fork B rules an `@gclaim` edit** (a
shipped-script edit on the fairness-critical claim path); if Fork B rules additive, Apollo is an optional
fast-finisher (closure + stories).

## The fork is OPEN — Fork B, the weighted-rotation mechanism (the Operator rules at the pre-build reconcile)

> **This is the one decision the body leaves open; it decides the risk grade.** Venus surfaces all three arms
> re-grounded against the re-probed `@gclaim` (lanes.ex:37-61) + the shipped `metronome.ex`; the Director routes to
> the Operator (AskUserQuestion). The ruling pins the [WITHHELD] weight representation + rotation mechanism and
> sets the risk grade / formation / determinism posture:
> - **Arm 1 — a deficit counter on the ring (DRR).** EDITS `@gclaim` → **HIGH** (byte-freeze the OTHER seven `@g*`
>   + **Apollo MANDATORY** + the **≥100 FOREGROUND determinism loop**). A `gdeficit` HASH field (an existing
>   shape). Bounded, fair, starvation-free by construction; smooth at fine granularity.
> - **Arm 2 — a weighted multi-pop.** ADDITIVE — a new `@gwclaim` script leaves `@gclaim` byte-unchanged →
>   **NORMAL+** (byte-freeze ALL eight `@g*` + the determinism posture by a **multi-seed sweep** — mint-free,
>   process-free). A higher-weight lane serves K heads per rotation (K = the weight). Integer-multiple granularity.
> - **Arm 3 — a per-lane budget refreshed by the metronome.** Couples to 4.3's metronome — but the reconcile
>   finds it **ENTANGLING** (the shipped metronome owns no lease + decides host-side in a pure Core; a per-lane
>   budget either regresses fairness host-side or needs a new wire structure + couples two rungs + risks a §6
>   question). Dis-recommended.
>
> **Venus's recommendation (the Operator decides): Arm 2 (the additive weighted multi-pop)** — it keeps `@gclaim`
> byte-frozen (the fairness-critical claim path stands), keeps fairness server-side in the claim (sound across a
> pool and a future cluster — the BCS property), is reversible (a new script vs. re-founding a frozen one), and
> avoids the 4.3↔4.4 coupling Arm 3 forces. Its only cost is integer-multiple granularity (acceptable for
> per-tenant fair-share). Arm 1 (DRR) buys smoother proportionality at the cost of a frozen-claim-path edit +
> HIGH-risk formation; the Operator may prefer it if fine-grained smoothness is the priority.

## The as-built floor (re-probed at Venus's reconcile, this run — Mars RE-PROBES each at Stage-0; the lag-1 law)

- **Toolchain:** Erlang 28.5.0.1 / Elixir 1.18.4 (`echo/.tool-versions`, re-probe `asdf current` from the app
  dir). Valkey on **6390** → PONG. `{emq}:version` = `echomq:2.4.2` == `@wire_version` (connector.ex:35 — the
  boot fence passes).
- **`@gclaim` (lanes.ex:37-61) — the shipped ring rotation, BYTE-FROZEN across 4.1/4.2/4.3 (verified):** `LMOVE
  KEYS[1] KEYS[1] 'LEFT' 'RIGHT'` :38 · `lane = ARGV[1]..'g:'..g..':pending'` :40 · `ZPOPMIN lane` :41 · `HINCRBY
  <row> attempts 1` :48 · the server-clock lease `TIME` :50-51 → `ZADD KEYS[2] now+ARGV[2] id` :52 · `HINCRBY
  ARGV[1]..'gactive' g 1` :53 · the `glimit` re-ring guard :54-58. `claim/3` host verb :171-184.
- **The full `@g*` family = EIGHT scripts (the byte-freeze universe):** `@genqueue` :16, `@gclaim` :37, `@gpause`
  :63, `@gresume` :69, `@glimit` :84, `@greassign` :119 (4.1), `@gdrain` :294 (4.1), `@greap_group` :355 (4.2).
- **The weight home:** `glimit`/`gactive` are per-queue HASHes keyed by group (`Keyspace.queue_key(queue,
  "glimit")` :150-151; `HGET ARGV[1]..'glimit' g` :54). A `gweight` per-queue g-segment HASH (group→weight) is an
  existing SHAPE — `keyspace.ex` `queue_key/2` :13-15 builds `emq:{q}:<type>` for any type, NO grammar edit. No
  `gweight`/`gdeficit`/`gbudget` exists yet (greenfield).
- **The metronome (4.3):** `EchoMQ.Metronome` (metronome.ex) owns NO Valkey lease (moduledoc :17-24); pure
  `Metronome.Core`; opt-in consumer path (D-3).
- **Conformance = 59 (LIVE):** `conformance_run_test.exs:48` `{:ok, 59}`; `conformance_scenarios_test.exs`
  `@run_order` = 59 names :28-88 (the module-doc prose says "fifty-five" — STALE prose, the pins are authoritative).
  The `rotate` scenario (conformance.ex:91) is the equal-share precedent.
- **The version model (two-planes, 4.3 D-4):** `mix.exs` version "2.4.3" = the rung LABEL read by nobody at
  runtime; `@wire_version` "echomq:2.4.2" = the wire constant, frozen by committed records.

## The pipeline — the stages (the risk-conditional formation)

### Stage 0/1 — Venus (architect): the triad + the pre-build reconcile + Fork B surfaced — DONE
The triad is authored ([`emq.4.4.md`](emq.4.4.md) body authoritative; [`emq.4.4.stories.md`](emq.4.4.stories.md)
+ [`emq.4.4.llms.md`](emq.4.4.llms.md) derived) with the six reconcile deltas carried (the 59 count, the 8-script
byte-freeze set, the re-probed `@gclaim` anchor, the metronome/Arm-3 entanglement, the `gweight` home, the
two-planes version) and the [WITHHELD] weight representation + rotation mechanism pinned at the Fork B ruling. The
T-2 reconcile trace is on the ledger. **Director gate:** read the body + this runbook (the files, not the report);
route Fork B to the Operator (AskUserQuestion); record the ruling; then release Mars.

### Stage 1 — Mars-1 (implementor): build to the ruled arm
Re-probe the floor (Stage-0, the lag-1 law — every anchor above). Build R1 (the weight home — the ruled `gweight`
shape + the host verb to set it), R2 (the weighted rotation — the ruled mechanism: an `@gclaim` edit OR a new
`@gwclaim`; byte-freeze the rest), R3 (the `:valkey` starvation drill — the load-bearing no-op-defeater), R6 (the
two conformance scenarios + the 59→61 re-pin in both pins), R5 (the wire-law grep battery), and self-verify the
per-app gate ladder + the determinism posture honest to the arm. **Stories:** Mars writes/extends the `:valkey`
proof to US1 (weighted proportion, a POSITIVE proof — lane B > 0) + US2 (the starvation drill, every lane drains).
Cite the spec line for every public call; inline `Script.new/2` (NEVER `priv/`); declared keys A-1; the server
clock on the served lease; the conformance additive-minor mechanics. Report the gate results before going idle (an
interim if the loop is mid-run).

### Stage 2 — Director: solo review (a REAL pass — DEEPENED iff Arm 1 / HIGH)
Independent gate re-run on Valkey 6390 (not Mars's word): `compile --warnings-as-errors`, `mix test --include
valkey`, `Conformance.run/2 → {:ok, 61}`. The adversarial probes: (1) the **starvation-drill no-op-defeater** —
mutate the rotation to FIFO/no-fair-share → a light lane must stay stuck (the drill goes RED); (2) the
**weighted-proportion** mutation — neutralize the weight read → the served share must collapse to ≈1:1 (US1 RED);
(3) the **byte-freeze** grep over the frozen `@g*` set = 0; (4) **declared-keys A-1** over any new/edited script (a
reviewer can name the declared root of every key); (5) the **server clock** on the served lease (grep host
timestamp = empty); (6) **no numeric priority / no new key family / §6 unedited / two-planes version**; (7) a
**net-zero mutation spot-check** (two distinct load-bearing tests proven to BITE, reverted net-zero). **IF Arm 1
(HIGH):** the verify DEEPENS — the **≥100 FOREGROUND determinism loop** owns the proof + the byte-frozen OTHER
seven `@g*` re-verified + **Apollo is a ship precondition**.

### Stage 3 — Mars-2 (implementor): remediate + harden + the full gate ladder
Apply the Director's findings. Run the FULL per-app gate ladder + the determinism posture (the ≥100 FOREGROUND
loop owning the machine IFF a process/lease surface, else the multi-seed sweep + the statement). Byte-freeze +
boundary + FROZEN-WIRE confirmations. Report (an interim before idle — silence reads as a stall, emq.4.3 L-2).

### Stage 4 — Apollo (evaluator): MANDATORY iff `@gclaim` is edited (Arm 1)
The post-build reconcile (does the as-built code satisfy the spec's promises?); the §11.2-charter adversarial
verification (the order theorem / declared-keys / destructive-act probes applied to the weighted rotation);
re-run the per-app gate ladder + the ≥100 determinism loop independently; re-verify the conformance count is
byte-unchanged with each new scenario probe-registered; sync the spec to what shipped; the mentoring loop. **If
Fork B rules additive (Arm 2/3):** Apollo is an optional fast-finisher (closure + stories), NOT a gate.

### Stage 5 — Venus (architect): the post-build reconcile
Sync the triad to what shipped — the ruled mechanism, the pinned weight home, the byte-freeze set actually frozen,
the final count N, the `@wire_version` disposition. Surgical sync, body authoritative. (The `emq.4.4.md` body is
edited at THIS stage — the as-built reconcile syncs the seed POST-build, never pre-build.)

### Stage 6 — Director: closure + ONE LAW-4 commit + the family fold
One Director pathspec commit of the rung's measured surface (the code + the triad + the `emq-4-4` ledger). Re-verify
`git diff --cached --name-only` is purely the rung before committing (the Operator pre-stages out-of-band — exclude
`AM`-status files); split an entangled tree into separate scoped commits per concern. Fold the family: mark emq.4.4
SHIPPED in the roadmap/progress, note the groups family parity-complete (4.1→4.4 closed). No push unless asked.

## Risk tier (CONDITIONAL on the Fork B ruling)

| Fork B arm | Risk | Apollo | Determinism | Byte-freeze set | Wire |
|---|---|---|---|---|---|
| **Arm 1** — DRR deficit counter (edits `@gclaim`) | **HIGH** | **MANDATORY** | **≥100 FOREGROUND loop** | the OTHER seven `@g*` | `@wire_version` step (a claim's wire behaviour changes — a protocol minor) |
| **Arm 2** — weighted multi-pop (additive `@gwclaim`) | **NORMAL+** | optional fast-finisher | multi-seed sweep + the statement | ALL eight `@g*` | `@wire_version` UNCHANGED at `echomq:2.4.2` (additive; `mix.exs` label → 2.4.4) |
| **Arm 3** — per-lane budget (couples to the metronome) | **NORMAL+ / entangling** | optional | ≥100 loop (a process/lease budget refresh) | ALL eight `@g*` + the metronome surface | likely a new wire structure + a possible §6 question (dis-recommended) |

The grade is stated forward so the build runs at the right rigor the instant the Operator rules.

## The Stage-6 commit pathspec (Director-only — the emq.4.4 BUILD; adjust to the ruled touch-set)

```bash
# THE CODE (the ruled touch-set — Arm 2 shown; Arm 1 adds connector.ex for the @wire_version step):
#   echo/apps/echo_mq/lib/echo_mq/lanes.ex          (the weighted rotation: a new @gwclaim + the gweight host wiring; @gclaim byte-frozen under Arm 2)
#   echo/apps/echo_mq/lib/echo_mq/conformance.ex    (the weighted_proportion + starvation_drill scenarios + the count prose)
#   echo/apps/echo_mq/test/<weighted_or_lanes>_test.exs  (the :valkey weighted + drill proof — NEW or EDIT)
#   echo/apps/echo_mq/test/conformance_run_test.exs       (re-pin {:ok, 61})
#   echo/apps/echo_mq/test/conformance_scenarios_test.exs (re-pin @run_order → 61 names)
#   echo/apps/echo_mq/mix.exs                        (the rung label 2.4.4)
#   [IFF Arm 1] echo/apps/echo_wire/lib/echo_mq/connector.ex   (the @wire_version step)
# THE DOCS:
#   docs/echo_mq/specs/emq2/emq.4/emq.4.rungs/emq.4.4.{md,stories.md,llms.md,prompt.md}
#   docs/echo_mq/specs/progress/emq-4-4.progress.md  (+ the registry)
# EXCLUDED: keyspace.ex/jobs.ex/stalled.ex/admin.ex (byte-unchanged), apps/echomq, mix.lock (no real dep moved),
#   the .claude/ calibration diffs (harness-fenced), any AM-status out-of-band file.
```

## Acceptance — "shipped" means

- Fork B ruled (the Operator's mechanism call recorded); the [WITHHELD] weight representation + rotation pinned to
  the ruled arm; the triad re-derived to it (Stage-5).
- R1–R7 built and green: the weight home (no new key family); the weighted rotation (lanes served in proportion,
  never all); the starvation drill (every lane drains under skew — the capstone guarantee, proved positively); the
  two conformance scenarios (additive minor — prior 59 byte-unchanged, re-pinned 59→61 in both pins); the wire law
  (no numeric priority / §6 unedited / two-planes version); the byte-freeze grep = 0 over every unedited `@g*`.
- The proof: the `:valkey` weighted + drill suites green per-app; the determinism posture honest to the ruled arm
  (the ≥100 FOREGROUND loop iff process/lease, else the multi-seed sweep + the statement); honest-row (Valkey
  6390); Apollo MANDATORY iff `@gclaim` is edited.
- INV1–6 verified as runnable checks; the body remains authoritative; the as-built reconcile syncs the seed
  post-build (Stage-5); one LAW-4 pathspec commit (Stage-6); the groups family folded parity-complete.
