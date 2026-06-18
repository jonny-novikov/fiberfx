# EMQ.4.1 · the build orchestration runbook — ship the fair-lanes control plane (Movement II opens)

> **Status: SPECCED, the runbook ready (authored at the `emq-4-1` ship run, Stage 1).** This runbook drives the
> **emq.4.1** build — the FIRST sub-rung of the groups-deepened family (the operator control plane) — the rung that
> **OPENS Movement II**. The `/echo-mq-ship` skill ([`.claude/skills/echo-mq-ship/SKILL.md`](../../../../../.claude/skills/echo-mq-ship/SKILL.md))
> is the binding (it is `/x-mode` with the echo_mq context pre-loaded: Venus loads `echo-mq-architect`, Mars loads
> `echo-mq-implementor`, the Director verifies code + invariants, Apollo — the Mentor — loads `echo-mq-evaluator` out
> of the per-rung pipeline on a NORMAL rung); the inputs are the triad ([`./emq.4.1.md`](emq.4.1.md) ·
> [`./emq.4.1.stories.md`](emq.4.1.stories.md) · [`./emq.4.1.llms.md`](emq.4.1.llms.md)), the family
> ([`../emq.4.md`](../emq.4.md) — the deepening contract + the carve + the THREE forks), and the canon
> ([`../../../emq.design.md`](../../../emq.design.md) §10 seam 2 / §4 cluster 2 / §4 row 4 / S-1/§6 / S-6 / §5).

## The family in one paragraph

emq.4 is the groups-deepened family — the shipped fair-lanes (`EchoMQ.Lanes`) mechanism taken to **production
multi-tenant depth** along four axes: a control plane (move a member between lanes; deepen pause/resume/limit/drain),
group-aware recovery (a group-scoped stalled-sweep), the park-don't-poll metronome (the wake/notify beat hardened),
and weighted/deficit rotation (fair-share beyond round-robin + a starvation drill). The basics ALREADY shipped (B3.4
"Fair Lanes", 8/8 G1–G8); emq.4 does **not** found the family — it **deepens** it, every axis **additive over the
shipped `g:`-segment keyspace**, nothing a wire break. The family carves into emq.4.1 (control plane) · 4.2
(group-aware recovery) · 4.3 (the metronome — HIGH-risk) · 4.4 (weighted/deficit + the drill — HIGH iff `@gclaim` is
edited), the Operator-ruled spine. The full deepening contract + the three forks are [`../emq.4.md`](../emq.4.md).

## The rung in one paragraph

emq.4.1 carves the **control plane** — the verbs an operator uses to re-shape contention live — the least-risky,
most-exercised surface, founding the chapter's vocabulary before the higher-risk metronome (4.3) and fairness (4.4)
rungs. It builds, inside `echo/apps/echo_mq` under the v2 laws (declared keys, branded group ids gated at the
lane-key builder, the inline `Script.new/2` law, additive-minor conformance, **no shipped-lane-script edit**): **(1)**
a **lane re-assignment** host verb on `EchoMQ.Lanes` (Venus recommends `reassign/4`, src-derived — the D-2 ruling) +
its inline `@greassign` move script (`ZREM` the `src` lane + `ZADD` the `dst` lane at **score 0** + rewrite the row's
`group` field + re-shape the ring for both lanes, **one atomic script on one `{q}` slot**, **no clock**); **(2)** the
**deepened** pause/resume/limit/drain control verbs over the shipped lane keys (the shipped pause/resume/limit carried
forward; a lane-scoped drain if the rung adds one); **(3)** the **re-aim** of the two RETIRED v1 priority commands
(`changePriority-7` → re-assignment, **no** numeric priority; `getCountsPerPriority-4` → the **shipped**
`Metrics.lane_depths/3`, **no new read**); **(4)** the re-assignment conformance scenario(s) (additive minor, the
prior **52** byte-unchanged); **(5)** the `:valkey` suites + a multi-seed sweep. The shipped `@gclaim`/`@genqueue`/
`@gpause`/`@gresume`/`@glimit` are **byte-frozen** (INV3); the lanes stay **score-0** (Fork C parked). The honest
**Out**: the intra-group priority dimension (Fork C, parked), a cross-queue move (**not expressible at arity 4** —
atomic by construction), a re-assignment of a claimed/in-flight member (`{:error, :not_pending}`), group-aware
recovery (emq.4.2), the metronome (emq.4.3), weighted rotation (emq.4.4). The contract is [`./emq.4.1.md`](emq.4.1.md)
(D1–D6, INV1–INV5).

## Mode

**Flat-L2** (a build + a gate + a verify), Director-supervised. **Not** the Design-Phase variant (the triad exists —
authored this cycle). **HIGH-RISK (as built)**: the rung was authored NORMAL (re-assignment alone is pure control
over shipped keys), but **R3 was ruled BUILD (D-5)** and the lane-scoped drain (`drain/3`/`@gdrain`) is a
**destructive at-rest delete** — a frozen-class hazard (a destructive op), so the rung graded **HIGH**. emq.4.1 adds
**two** host control verbs + **two** new inline scripts over the shipped `g:`-segment keyspace; it edits **no** shipped
lane script (`@gclaim`/`@genqueue`/`@gpause`/`@gresume`/`@glimit` byte-unchanged) and founds **no** process/lease
surface (both verbs touch no `TIME`, mint no branded id, start no process). So the standard per-app gate ladder + the
**blast-radius mutation battery** (the destructive drain's **over-reach** + **under-clean** both caught — the right
gate for a destructive op) + a **multi-seed sweep + an honest determinism-posture statement** (the **≥100-iteration
loop is NOT run** — the same-millisecond-mint hazard it guards does not exist here; the loop would forge load rather
than catch the destructive hazard). **Apollo** the Mentor may engage as a closure fast-finisher; the Director's verify
(the blast-radius battery) is the gate of record for the destructive op.

Scope slug: **`emq-4-1`** (dashed, no dots — `tool_x_*`/`TeamCreate` require `^[a-z0-9][a-z0-9-]*$`). Operator:
`jonny`. Workspace: `/Users/jonny/dev/jonnify`. Ledger: `docs/echo_mq/specs/progress/emq-4-1.progress.md` (the ship
run opens it; the `emq-4` design-cycle ledger carries the family-triad authoring; records-freeze on the design half).

## The fork gate — the Director's rulings (recorded; the verb-name D-2 owed before the build)

The family body ([`../emq.4.md`](../emq.4.md)) and this rung's body ([`./emq.4.1.md`](emq.4.1.md)) surface the forks;
the Director has **ruled** the two that gate emq.4.1, and the triad is authored to them:

> **FORK C (this rung's fork) — the intra-group priority dimension. RULED → PARK (Arm B).** Lanes stay **score-0**;
> emq.4.1 does **not** thread a non-zero score onto the `g:<group>:pending` ZSET. The score-0 invariant is
> load-bearing for the `@gclaim` `ZPOPMIN` head-selection (mint-order FIFO = the order theorem). The intra-group
> priority band is recorded as **parked** (a real but unrequested surface; the named consumers — codemojex
> one-lane-per-player — need lane fairness, not intra-lane priority). An Arm-A ruling would re-derive the carve (the
> score dimension + the `@gclaim` head-selection re-examination) before the build; that ruling is NOT made.
>
> **VERSION — RULED → ADDITIVE MINOR.** emq.4.1 ships at **`echomq:2.0.0`** — no fence code, no new wire class, no
> wire break (INV1). Conformance grew additively **52 → 54** (`reassign` + `lane_drain`). emq.4.1 is one
> additive-minor step within the Movement II / echomq:3.0.0 arc the Director tracks separately (the 3.0 horizon is an
> emq.8-era target, NOT this rung).

> **THE VERB-NAME RULING — RULED → `reassign/4` (D-2).** The Director ruled **`reassign(conn, queue, job_id,
> dst_group)` — arity 4, src-derived** (as Venus recommended): the source group is read from the row's `group` field
> inside the atomic script (the row is authoritative, written by `@genqueue` at `lanes.ex:23`), so src cannot mismatch
> and a cross-queue dst is not expressible. Built at `lanes.ex:262` (`reassign/4`) + `:119` (`@greassign`).

> **THE DRAIN RULING — RULED → BUILD (D-5).** The Director/Operator ruled **R3 → BUILD**: the lane-scoped destructive
> drain `drain(conn, queue, group)` (arity 3) + `@gdrain` shipped at `lanes.ex:319`/`:294` — the `Admin.@drain` wipe
> scoped to one lane (`ZRANGE` → `DEL` rows + logs → `DEL` lane set → `LREM` ring), blast radius bounded. This is what
> graded the rung **HIGH** (a destructive at-rest delete) and drove the **blast-radius mutation battery** verify.

## The as-built floor (verified at Stage 1, 2026-06-18 — the build's Stage-0 RE-PROBES each; the lag-1 law)

Anchors drift; a sibling rung could move the `echo_mq` surface before emq.4.1 reads it — the build's Stage-0
reconcile re-pins every line below:

- **The conformance count** — `conformance.ex` `scenarios/0` (the pre-build floor = **52**, ending
  `flow_grandchild_fail`). **As built: 52 → 54** — `reassign` (`:118`) + `lane_drain` (`:119`); both pin tests
  re-pinned (`conformance_run_test.exs:47` `{:ok, 54}`; `conformance_scenarios_test.exs`); module docs "fifty-four".
- **`@genqueue` (the move's ring-add model)** — `lanes.ex:16-35` (stores `'group',ARGV[3]` on the row at **line 23**;
  `ZADD KEYS[2] 0 ARGV[1]` score-0 lane; the ring-add guard lines 25-32). `Lanes.enqueue/5`.
- **`@gclaim` (BYTE-FROZEN — the ring rotation the move must NOT disturb)** — `lanes.ex:37-61` (`LMOVE ring ring LEFT
  RIGHT`; `ZPOPMIN lane` the score-0 head at line 41; the server-clock lease; `LREM ring 0 g` the lane-drop pattern at
  56-59). `Lanes.claim/3`.
- **`@gpause`/`@gresume`/`@glimit` (BYTE-FROZEN)** — `lanes.ex:63-99`; `pause/3`/`resume/3`/`limit/4` host wrappers
  `lanes.ex:146-190`; `depth/3` `lanes.ex:193-195`.
- **`lane_key!/2` (the branded gate)** — `lanes.ex:197-203` (RAISES unless `BrandedId.valid?/1` — INV2).
- **The group-field readers the move's row rewrite keeps honest** — `jobs.ex` `@complete` `HGET KEYS[2] 'group'`
  (**:182**), `@reap` `HGET jk 'group'` (**:349**), `@promote` (**:320**). **The move MUST `HSET <row> 'group' dst`**
  (T-2 — else a later claim/complete/reap of the moved member touches `gactive[src]`). These are NOT edited.
- **`Metrics.lane_depths/3` (the re-aim target — already shipped)** — `metrics.ex:279-310` (`@lane_counts`,
  `ZCARD base..'g:'..g..':pending'` per group, declared-base-rooted). No new read (Fork C parked).
- **`Admin.drain/3` (the slot-rooted lane-drain precedent)** — `admin.ex:84-122` (`@drain`: `base .. 'job:' .. id`
  from a declared `KEYS[1]` base, `DEL jk, jk..':logs'`). A lane-scoped drain is this pattern over `g:<g>:pending`.
- **`Keyspace.job_key/2`** — `keyspace.ex:17-24` (gates `BrandedId.valid?/1`, RAISES — INV2), `queue_key/2`.
- **No existing reassign/move verb** — grep-confirmed empty (the surface is genuinely NEW, PROPOSED).

## The pipeline — the NORMAL rung (Venus → Mars-1 → Director review → Mars-2 → Director ship; Apollo optional)

Each spawned stage is a real `general-purpose`/dedicated `Agent` that adopts its `.claude/agents/<role>.md` charter,
LOADS its `echo-mq-<role>` skill, and self-registers via `mcp__aaw__*` (LAW-1; no narrated spawns). The Director
holds the gate between stages. The per-spawn contract is the `/x-mode` skill §3 (Framing → adopt charter → aaw
ceremony → the stage block → audit directive → propagation clause → report). **Require artifact-level checkpoints**
(SendMessage a concrete report after each pass; the Director's ground-truth verification is the gate, not the
self-verdict).

### Stage 0/1 — Venus (architect): the triad + the pre-build reconcile + the fork-settlement gate

**(DONE this run — Stage 1.)** Directive: author the full emq.4.1 triad (`.stories.md` / `.llms.md` / `.prompt.md`),
reconciled lag-1 against the as-built tree. Re-probe every anchor above; pin the conformance count (52); confirm the
src-derived-arity finding (the row stores `group`); recommend the verb name/arity (`reassign/4`); record the forks
(C park / additive minor) as RULED. Gate: the triad authored; the reconcile delta table; the BUILD-GRADE verdict; the
verb-name D-2 surfaced for the Director's ruling. **At the build's Stage 0, Mars RE-PROBES the floor (the lag-1 law —
a sibling rung could have moved an anchor).**

### Stage 1 — Mars-1 (implementor): build the control plane

Directive: after the verb-name D-2 is ruled, build EMQ.4.1-D2 → D6 to the brief's agent stories (AS1–AS3) and the
design. The order: (1) the inline `@greassign` move script (model the `dst`-ring re-add on `@genqueue`'s guard, the
`src`-drop on `@gclaim`'s `LREM`-on-empty — **a NEW script; the existing ones byte-frozen**) + the `reassign/4` host
verb (gate the `job_id` at `Keyspace.job_key/2` + the `dst_group` at `lane_key!/2`; reject a cross-queue dst
host-side; src derived from the row); (2) confirm with the Director whether a lane-scoped drain is in scope (R3) — if
yes, build it (the `Admin.@drain` pattern over one lane); (3) record the re-aim discharge (no new read); (4) the
re-assignment scenario(s) in `conformance.ex` + the count re-pin in both pin tests; (5) the `:valkey` suite. Cite the
spec/design line for every public call; **declared keys** (every key in `@greassign` in `KEYS[]` or rooted — the A-1
lint; NO key read from a data value — INV5); **inline `Script.new/2`** (no `priv/`); **no clock** (no `TIME` — the
move touches no lease); register the conformance scenarios + probes **in the same change** (INV4, the additive-minor
law; the prior 52 byte-unchanged; re-pin the count in both pin tests); compile clean (`--warnings-as-errors`,
per-app). **INV3 gate**: `@gclaim`/`@genqueue`/`@gpause`/`@gresume`/`@glimit` byte-unchanged (`grep redis.call` on
those scripts in the lib diff = 0). Gate: per-app compiles green; D2–D6 exist; the diff stays inside `echo_mq` (no
`echo_wire`, no `keyspace.ex` grammar edit, no `jobs.ex` edit, no `apps/echomq`); the boundary grep empty.

### Stage 2 — Director: solo review (a REAL pass)

A fresh-gate reconcile + an independent gate re-run on Valkey 6390 + ≥1 adversarial probe: the **declared-keys** F-1
probe on `@greassign` (every key declared/rooted; no hash-field-to-key derivation; the v1 data-value-rooted form NOT
lifted); the **byte-freeze** probe (`grep redis.call` on `@gclaim`/`@genqueue`/`@gpause`/`@gresume`/`@glimit` in the
lib diff = 0; the prior fair-lanes scenarios `rotate`/`pause`/`limit`/`lane_depth`/`stalled_group`/`obliterate_grouped`
byte-identical); the **move-soundness** probe (the moved member claims from `dst` with `group = dst`; a completion
decrements `gactive[dst]` not `gactive[src]` — the row-rewrite correctness, T-2); the **score-0** probe (the member
enters `g:<dst>:pending` at score 0 — Fork C park held); the **not-pending** probe (a claimed/in-flight member answers
`{:error, :not_pending}`, the row untouched); the **blast-radius mutation battery** on `@gdrain` (the destructive
drain's **over-reach** — it must NOT delete `active`/`gactive`/`paused`/`glimit`/a sibling lane/the repeat registry —
and its **under-clean** — it must leave no row/log/set/ring entry — both caught); the **byte-unchanged conformance**
probe (`git diff` shows only additions to `scenarios/0`; the 52 prior scenarios byte-identical); a **mutation
spot-check** (Edit-in a fault → the `reassign`/`lane_drain` scenario catches it → revert → `git diff --stat` clean,
net-zero, LAW-1a). Produce the REMEDIATE list.

### Stage 3 — Mars-2 (implementor, harden + the full gate ladder)

Resume the Stage-1 Mars (one identity, two passes). Directive: remediate; run the full ladder — toolchain re-probe
(`asdf current erlang`) + Valkey 6390 PONG; per-app pure + `:valkey` suites (`TMPDIR=/tmp`, NEVER umbrella-wide;
`--include valkey` for the lane suites); `Conformance.run/2 → {:ok, N}` with the prior 52 byte-unchanged + the
re-assignment scenario(s) probe-registered; a **multi-seed sweep** + an **honest determinism-posture statement**
(NORMAL — no id-mint/process/lease hazard, **no ≥100 loop**; state it explicitly — the move mints no id, touches no
`TIME`, starts no process); coverage tabled with the reason for any gap. REMEDIATE loop MAX 3. Gate: every ladder item
PASS or explained; the conformance tally clean; the byte-freeze grep = 0; the boundary grep empty.

### Stage 4 (optional) — Apollo (evaluator) — the fast-finisher (NORMAL rung)

Directive (optional on a NORMAL rung — the Mentor as a closure fast-finisher, NOT mandatory): a light post-build
reconcile (as-built ⇄ spec) + the stories closure (the Coverage map traces every D-n to a story; the determinism
posture stated honestly). If engaged, render a closure note + ≥1 mentoring observation folded forward
(Director-ratified). **Mandatory only on a high-risk rung — not this one** (the 5 lane scripts are byte-frozen by
design, the move is a pure re-shape, no destructive at-rest op).

### Stage 5 — Venus (architect): the post-build reconcile

Sync the triad body to the as-built surface (the `EchoMQ.Lanes.reassign` real arity; the `@greassign` real key
declarations; the ruled verb/arity D-2; the final conformance N; whether a lane-scoped drain landed); every triad
claim MATCH or `[RECONCILE]`-marked; fold the parity proof ([`../../../emq.features.md`](../../../emq.features.md)
Part B / the groups feature records) to mark `changePriority-7` + `getCountsPerPriority-4` discharged (re-aimed) for
the control-plane slice.

### Stage 6 — Director: closure + ONE LAW-4 commit + the Movement-II fold

Preconditions (x-mode §4): the gate green + the reconcile build-grade (Apollo BUILD-GRADE if engaged, else the
Director's verify is the gate); **≥1 `tool_x_decision` (D-n)** — at minimum the verb-name/arity ruling (`reassign/4`)
— + a **`tool_x_complete` (Z-n)** this turn; `git status --short` AND `git diff --cached --name-only` reviewed;
`.git/rebase-merge`/`rebase-apply` checked. Then the **pathspec** commit (below; NEVER `git add -A`, NEVER a bare
commit). **Same turn:** flip the emq.4.1 row in the single roadmap ([`../../../emq.roadmap.md`](../../../emq.roadmap.md))
and the dashboard ([`../../../emq.progress.md`](../../../emq.progress.md)); record **Movement II OPEN** (emq.4.1 the
control-plane slice shipped; the groups family deepening; 4.2–4.4 next); record the **echomq:3.0.0 horizon note** (the
additive-minor step within the Movement II / 3.0 arc — the 3.0 wire-version target is an emq.8-era decision, NOT
taken here); surface the **next frontier** (emq.4.2 group-aware recovery — NORMAL; then emq.4.3 the metronome — HIGH,
Apollo mandatory + the ≥100 loop; then emq.4.4 weighted/deficit — HIGH iff `@gclaim` edited; Fork A settles before
4.3 builds, Fork B before 4.4); under an **explicit Operator grant only**, fold any mentoring diff into the peer
charters / the echo-mq-* skills (one guardrail per finding). The message cites the slug, the Z-n, the D-n, and the
Y-n report.

## Risk tier

**HIGH (as built — authored NORMAL, graded HIGH when R3 was ruled BUILD).** Two dimensions:
1. **The destructive at-rest delete (the HIGH driver).** `drain/3`/`@gdrain` (R3 BUILD, D-5) `DEL`s drained members'
   rows + logs + the lane set — a frozen-class hazard (a destructive op). The mitigating gate is the **blast-radius
   mutation battery**: the drain's **over-reach** (it must touch only the target lane — NOT `active`/`gactive`/
   `paused`/`glimit`/a sibling lane/the repeat registry) and its **under-clean** (it must leave no row/log/set/ring
   entry) are both caught. This is the right gate for a destructive op — NOT the ≥100 loop (the drain mints no id,
   touches no `TIME`, starts no process, so the loop would forge load rather than catch the destructive hazard).
2. **The move-soundness correctness.** The row's `group` field must be rewritten to `dst` (`@greassign`
   `HSET <row> 'group' dst`), else a later claim/complete/reap mis-accounts `gactive` — T-2; the mitigating gate is
   the Director's **move-soundness probe** (the moved member claims from `dst` and a completion charges `gactive[dst]`)
   + the byte-freeze grep on the 5 shipped lane scripts.

**No** id-mint / process / lease hazard is introduced (both verbs mint no branded id, touch no `TIME`, start no
process), so the **≥100 determinism loop is NOT run** — a multi-seed sweep + the blast-radius battery + an honest
posture statement is the proof. **Apollo** the Mentor may engage as a closure fast-finisher; the Director's verify
(the blast-radius battery) is the gate of record for the destructive op.

## The Stage-6 commit pathspec (Director-only — the emq.4.1 BUILD)

Commit exactly the rung's measured surface (the build run's actual touch-set is authoritative — adjust to what the
stages truly changed):

```text
docs/echo_mq/specs/emq.4/emq.4.md                          (the family contract + carve + forks, if Stage-5 synced it)
docs/echo_mq/specs/emq.4/emq.4.stories.md
docs/echo_mq/specs/emq.4/emq.4.llms.md
docs/echo_mq/specs/emq.4/emq.4.rungs/emq.4.1.md            (the seed, Stage-5 synced)
docs/echo_mq/specs/emq.4/emq.4.rungs/emq.4.1.stories.md
docs/echo_mq/specs/emq.4/emq.4.rungs/emq.4.1.llms.md
docs/echo_mq/specs/emq.4/emq.4.rungs/emq.4.1.prompt.md     (this runbook)
docs/echo_mq/specs/progress/emq-4-1.progress.md
docs/echo_mq/specs/emq.commands/features/groups/changePriority-7.md       (→ discharged, if Stage-5 marks it)
docs/echo_mq/specs/emq.commands/features/groups/getCountsPerPriority-4.md (→ discharged, if Stage-5 marks it)
docs/echo_mq/emq.roadmap.md                                (the emq.4.1 row → shipped; Movement II OPEN)
docs/echo_mq/emq.progress.md                               (the dashboard fold)
echo/apps/echo_mq/lib/echo_mq/lanes.ex                     (the reassign/4 verb + @greassign; + a lane-scoped drain if R3)
echo/apps/echo_mq/lib/echo_mq/conformance.ex               (the re-assignment scenario(s), additive)
echo/apps/echo_mq/test/                                     (the reassign :valkey suite + the conformance pins)
```

**EXCLUDE** (Operator out-of-band — never sweep into the rung commit): `echo/apps/live_svelte/**`,
`echo/apps/mercury_cms/**`, `echo/apps/mercury_live_admin/**`, `html/**`, the F# course, and any
`[emq]`/`[bcs]`/`[mercury]` doc commits the Operator lands between stages. `echo/apps/echomq` (frozen v1 — the
capability reference) + `echo/apps/echo_wire` (the control plane rides the shipped connector) +
`echo/apps/echo_mq/lib/echo_mq/keyspace.ex` (no grammar edit) + `echo/apps/echo_mq/lib/echo_mq/jobs.ex` (the move
writes the `group` field jobs.ex reads — no `jobs.ex` edit expected) + `echo/apps/echo_mq/lib/echo_mq/metrics.ex` (the
`lane_depths/3` re-aim target is already shipped — UNTOUCHED unless Fork C lands, which is parked) + `echo/mix.lock`
(emq.4.1 adds no dep — expect `mix.lock` EXCLUDED) UNTOUCHED. **Never `git add -A`.**

## Acceptance — "shipped" + "Movement II opened" means

Every DoD box in [`./emq.4.1.md`](emq.4.1.md) is checkable from the run's outputs: Fork C surfaced + ruled (park),
the verb-name/arity D-2 ruled before any artifact (D1); the `reassign/4` verb + `@greassign` (D2 — a member moves
`g:<src>:pending` → `g:<dst>:pending` at score 0, both branded-gated, one slot, the row `group` rewritten, the ring
re-shaped, a cross-queue dst rejected); the deepened pause/resume/limit/drain control verbs (D3); the re-aim
discharged (`changePriority-7` → re-assignment, `getCountsPerPriority-4` → `Metrics.lane_depths/3` — D4); the
re-assignment scenario(s) additive-minor with the prior 52 byte-unchanged + the count re-pinned in both pin tests
(D5); the `:valkey` suites green + the multi-seed sweep + the honest determinism-posture statement (NORMAL, no ≥100
loop) + no regression + the 5 shipped lane scripts byte-frozen (D6). The spec body stays authoritative; Stage 5 syncs
it to the as-built surface; the groups family deepening (emq.4.2–4.4) opens on a proven control surface.

Inputs: [`./emq.4.1.md`](emq.4.1.md) · [`./emq.4.1.stories.md`](emq.4.1.stories.md) ·
[`./emq.4.1.llms.md`](emq.4.1.llms.md) · Family: [`../emq.4.md`](../emq.4.md) (the deepening contract + the carve +
the forks) · Canon: [`../../../emq.design.md`](../../../emq.design.md) §10 seam 2 / §4 cluster 2 / §4 row 4 / S-1/§6 /
S-6 / §5 · Roadmap: [`../../../emq.roadmap.md`](../../../emq.roadmap.md) Movement II · The feature catalog:
[`../../../emq.features.md`](../../../emq.features.md) (the groups records) · The shape model:
[`../../emq.3/emq.3.rungs/emq.3.1.prompt.md`](../../emq.3/emq.3.rungs/emq.3.1.prompt.md) (the flow-family opener
runbook) · Skills: `.claude/skills/echo-mq-ship.md` (the binding) + `echo-mq-{architect,implementor,evaluator}.md`
(the per-role craft) + `echo-mq-program.md` (the program law) · Approach:
[`../../../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
