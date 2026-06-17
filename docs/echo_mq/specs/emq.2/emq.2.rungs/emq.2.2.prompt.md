# EMQ.2.2 · the x-mode orchestration runbook — the operator plane (the parity cluster's mutation rung)

> **Status: SPECCED — the runbook for the emq.2.2 build run (a later session).** emq.2.2 is the second rung
> of the emq.2 **full-parity cluster** (the carve: [`./emq.2.design.md`](../emq.2.design.md)): the bus's
> operator plane — queue-wide pause/resume, drain, obliterate, the in-flight job mutations
> (update-data/update-progress/add-log + the log read), and the job lifecycle moves (remove, reprocess) —
> ported from the v1 `echomq` operator API onto `echo_mq`'s as-built four-set state machine, never migrated
> from. The pipeline mirrors the emq.1 / emq.2.1 runbook (the proven five-stage shape). emq.2.2 stands on
> emq.2.1: emq.2.1's reads are the acceptance lens (a drained queue reads pending zero). The x-mode skill
> ([`.claude/skills/x-mode/SKILL.md`](../../../../../.claude/skills/x-mode/SKILL.md)) binds the laws; its inputs
> are the spec triad ([`./emq.2.2.md`](emq.2.2.md) · [`./emq.2.2.stories.md`](emq.2.2.stories.md) ·
> [`./emq.2.2.llms.md`](emq.2.2.llms.md)), the carve ADR, the read plane ([`./emq.2.1.md`](emq.2.1.md)),
> and the canon ([`../emq.design.md`](../../../emq.design.md)).

## The rung in one paragraph

emq.2.2 builds the bus's **operator plane**: real-transition verbs that change `echo_mq`'s as-built
structures (`pending`/`active`/`schedule`/`dead` + the §6-registered `metrics:`/`de:`/`job:<id>:logs` keys)
— queue-wide pause/resume (a claim gate, distinct from `Lanes.pause/3`'s per-group park), drain (empty
pending, active intact), obliterate (destroy a paused queue, bounded, refusing non-paused/live-active),
update_data (replace payload), update_progress (write progress + the watch-plane event seam), add_log /
get_job_logs (the §6 `logs` subkey), remove_job (multi-set remove, refusing a locked job), and reprocess_job
(`dead`→`pending`, refusing a non-dead job). The capability reference is the frozen v1 `EchoMQ.Queue`
lifecycle + `EchoMQ.Worker` mutation API + their scripts
(`pause-7`/`drain-6`/`obliterate-2`/`updateData-1`/`updateProgress-3`/`addLog-2`/`removeJob-12`/
`reprocessJob-8`); emq.2.2 re-derives those capabilities against `echo_mq`'s real keyspace. 
Each verb is a real transition (the queue-wide pause gates the *future* claim); every
precondition failure refuses with an `EMQ*` class (a §5 additive minor with a probe). The contract is
[`./emq.2.2.md`](emq.2.2.md) (D1–D10, INV1–INV8); the carve it continues is
[`./emq.2.design.md`](../emq.2.design.md) ADR-1.

## Mode

**Flat-L2** (a build + a gate + a verify), Director-supervised — the emq.1 / emq.2.1 five-stage shape:
**Mars-1 (design-make + build) → solo Director review → Mars-2 (remediate + harden + test) → Venus (specs
reconcile) → Director (closure + one post-closure commit)**. **Not** the Design-Phase variant (the system
spec and the carve already exist). The risk profile is **low-moderate** (a bus-internal mutation rung on the
local Valkey substrate; no auth/deploy/external-network surface; no new process) — slightly above the
read-only emq.2.1 because emq.2.2 adds **destructive** verbs (drain/obliterate delete rows and sets) and a
pause gate that **may touch the shipped `@claim` transition** (the INV1 byte-unchanged-conformance risk). A
solo Director review is the rigor floor, recovered by a real reconcile-plus-gate-plus-adversarial Stage 2 +
Venus's independent Stage 4. **An Apollo charter is NOT required** at this risk tier (x-mode §11.3) — but
the Stage-2 adversarial probe is aimed squarely at the destructive verbs and the pause gate (the "Risk
tier" section names the targets), and the Director may escalate to an Apollo charter if the build realizes
the pause gate inside `@claim` and the `claim` scenario does not stay byte-for-byte identical.

Scope slug: **`emq-2-2`** (dashed, no dots — `tool_x_*` and `TeamCreate` require `^[a-z0-9][a-z0-9-]*$`).
Operator: `jonny`. Workspace: `/Users/jonny/dev/jonnify`. Ledger: `docs/echo_mq/specs/emq-2-2.progress.md`.

## The design-make — the relocated gate (what Mars-1 adopts, not re-litigates)

Mars-1 **adopts the carve** ([`./emq.2.design.md`](../emq.2.design.md) ADR-1: emq.2.2 = the operator plane,
second) and rules the four build-shaping decisions the spec leaves to D1, logging each as a
`tool_x_decision`:

1. **Module placement** → recommended: a new `EchoMQ.Admin` for the queue-scope verbs
   (pause/resume/drain/obliterate, a cohesive operator surface); the job-mutation verbs
   (update_data/update_progress/add_log/get_job_logs/remove_job/reprocess_job) fold onto `EchoMQ.Jobs` beside
   the state machine they extend. The alternative (all verbs on `EchoMQ.Jobs`, or a single
   `EchoMQ.Operator`) is steelmanned and chosen-against unless the build finds a reason; record ≥2
   alternatives either way.
2. **The queue-wide pause mechanism** → a paused flag the claim path honors, so a paused queue claims empty
   with a non-empty pending. Two steelmanned forms: **(a) the gate inside the as-built `@claim` script**
   (atomic — the pause check rides the same transition; but it edits emq.1's shipped `@claim`, so the
   `claim` conformance scenario MUST re-run byte-for-byte identical to prove INV1), or **(b) a separate gate
   the public `claim/3` reads first** (no edit to `@claim`; one extra read on the claim path). Recommended:
   **(a)** for atomicity if the `claim` scenario stays byte-identical, else **(b)**. The flag is a
   §6-registered key (e.g. a `paused` member of the closed registry) or a meta field — ruled here, spelled
   against §6. **Distinct from `Lanes.pause/3`**: this gates the whole queue, not one group; do not touch the
   per-group `paused` set/ring.
3. **The `EMQ*` refusal class word(s)** → spell the §5 class for each precondition refusal: a held-job
   refusal on remove (e.g. `EMQLOCK`), a not-paused / live-active refusal on obliterate and a not-dead
   refusal on reprocess (e.g. `EMQSTATE`, or finer per-refusal words — the build's call). Register each with
   its conformance probe in the same change; map each client-side to a typed atom; leave the five-code fence
   union unextended.
4. **The drain/obliterate scope** → name exactly which as-built sets and §6 keys each touches: drain empties
   `pending` (+ optional `schedule`, except repeat-owned jobs) and deletes drained rows + §6 subkeys, active
   intact; obliterate (paused-only) destroys `pending`/`active`/`schedule`/`dead` + `metrics:*`/`de:*`/the
   lane structures/`repeat`/the paused flag + reachable rows, bounded per call. **NOT** the v1 set list
   (`wait`/`paused`-LIST/`completed`/`failed`/`prioritized`/`waiting-children`).

**Carried, not re-litigated:** the rung is the operator plane (the carve); the structures are the as-built
four sets; the v1 operator API is a capability reference, never migrated from; the worker-side lock plane is
emq.2.3 (emq.2.2 only *reads* the `:lock` subkey for the remove refusal); the batch *consume* family is
emq.5 and the **distributed** cancel is emq.6 (ADR-2). If the Stage-2 review finds an adopted decision
unsound, it is the Director's gate to send Mars back or escalate — not to ship it.

## The as-built floor (RE-PROBE at build time — the lag-1 law)

Every anchor below is probed against the as-landed tree (anchors drift after the emq.1 + emq.2.1 builds;
Mars-1 RE-PROBES each):

- `EchoMQ.Jobs` — the three-field row + the four sets `pending`/`active`/`schedule`/`dead`
  (`echo/apps/echo_mq/lib/echo_mq/jobs.ex`); `complete/4` DELETES the row everywhere (**no
  `completed`/`failed` set**); `@claim` is `ZPOPMIN` on `pending` (the queue-wide pause gate attaches here or
  before it — D1).
- `EchoMQ.Keyspace.job_key/2` — gated by `BrandedId.valid?/1` (RAISES on an ill-formed id); `queue_key/2`
  builds `emq:{q}:<type>`; the §6 `metrics:`/`de:`/`job:<id>:logs` suffixes (`logs` is a registered `sub`
  member).
- `EchoMQ.Lanes.pause/3`/`resume/3` — the **per-group** lifecycle (SADD `paused` set + LREM `ring`);
  emq.2.2's queue-wide pause is DISTINCT (gates the whole claim, not one group).
- `EchoMQ.Repeat` — `emq:{q}:repeat` (the drain scheduled-by-repeat guard).
- `EchoMQ.Conformance.scenarios/0` — **18** scenarios (the keyword list `fence:…resubscribe:`,
  `conformance.ex`); INV1 holds them byte-unchanged; `run/2 → {:ok, n}`, n == 18 today; both
  `conformance_scenarios_test.exs` and `conformance_run_test.exs` pin the count.
- The `EchoWire` facade — `echo/apps/echo_wire/lib/echo_wire.ex` (`eval/5` runs the mutation scripts);
  expect no facade change.
- **No `echo/apps/echo_mq/priv/` directory** — scripts are inline `Script.new/2` attributes. **emq.2.2
  follows the inline convention, NOT `priv/`.**
- The v1 capability reference — `echo/apps/echomq/lib/echomq/queue.ex` + `worker.ex` + `priv/scripts/{pause-7,
  drain-6,obliterate-2,updateData-1,updateProgress-3,addLog-2,removeJob-12,reprocessJob-8}.lua` (these root
  keys in data values + use the v1 set model — port the *capability*, not the form or the state list; v1
  `data` → the as-built `payload`).

## The pipeline — five stages, Director-in-loop

Each spawned stage is a real `general-purpose` Agent that adopts its `.claude/agents/<role>.md` charter
(Mars / Venus) — and, where the build team is echo_mq-specialized, the echo_mq dev skill — and
self-registers via `mcp__aaw__*` (LAW-1; no narrated spawns). The Director holds the gate between stages.
The per-spawn contract is the x-mode skill §3 (Framing → adopt charter → aaw ceremony → the stage block →
audit directive → propagation clause → report).

### Stage 1 — Mars-1 (implementor): design-make + build

Directive (lift into the spawn): **make the operator-plane design real and build it.** (a) RE-PROBE every
as-built anchor above (the lag-1 law). (b) Adopt the carve + rule the four design-make decisions above; log
each as a `tool_x_decision` (D-n) citing the design § it adopts; invent no operator surface. (c) Build
EMQ.2.2-D2 → D9 to [`./emq.2.2.llms.md`](emq.2.2.llms.md)'s agent stories — queue-wide pause/resume (D2),
drain (D3), obliterate (D4), update_data (D5), update_progress + the event seam (D6), add_log/get_job_logs
(D7), remove_job (D8), reprocess_job (D9). Every verb a **real transition** in ONE inline `Script.new/2`
script (INV2 — the queue-wide pause gates the future claim); the structures the as-built four sets (INV3 —
never a v1 state name); every job id gated at the key builder (INV5); every script declares its keys in
`KEYS[]` or grammar-derives them from the declared queue root (INV4); every precondition refusal leads with
its `EMQ*` class and changes nothing (INV6); the server clock binds any lease-touching verb (INV7). Register
a conformance scenario + probe for every verb IN THE SAME CHANGE, register the new `EMQ*` class(es) with
probes, and re-pin the count in both pinning tests (INV1, the additive-minor law). If the queue-wide pause
gate is realized inside `@claim`, re-run the `claim` conformance scenario byte-for-byte and confirm it is
identical. Compile clean (`--warnings-as-errors`, per-app). Report any realization-over-literal clause.

Gate before advancing: per-app compiles green; D2–D9 deliverables exist; the four design-make decisions
logged; the diff stays inside `echo_mq` (`apps/echomq` untouched; no third app touched); the inline-script
convention followed; the queue-wide pause is distinct from `Lanes.pause/3` (no per-group `paused`/`ring`
touched); if `@claim` was edited, the `claim` scenario is byte-identical; the lock-delta law holds. (The full
test gate is Stage 3 — Stage 1 ends at compile-green + deliverables-present + a smoke that the new verbs
load.)

### Stage 2 — Director (solo review): the relocated charter

The Director reviews Mars-1's design-make + build **from a fresh gate**, not from Mars-1's report
(max-effort = a real verification pass):

- **Reconcile** the build against the carve + the brief: every operator verb MATCH / realized-and-logged /
  flagged; the drain/obliterate scope touches the as-built four sets + §6 keys (NOT the v1 list — the
  headline INV3 check); every mutation is a real transition that changes nothing on a refusal (INV2, INV6);
  every mutation key declared-or-grammar-derived (INV4); the new `EMQ*` class(es) registered against §5; the
  queue-wide pause distinct from `Lanes.pause/3`.
- **Run the gate fresh** (per-app, `TMPDIR=/tmp`, Valkey 6390 PONG first): the per-app compiles; a pure
  suite per touched app; the new `:valkey` operator scenarios load and the 18 prior ones still enumerate
  byte-unchanged.
- **≥1 adversarial probe — aimed at the destructive verbs + the pause gate** (the elevated-risk targets): (i)
  **drain spares active** — enqueue + claim a job (now active), drain, assert the active job survives and
  pending is zero (emq.2.1's counts); (ii) **obliterate refuses non-paused** — assert obliterate on a
  non-paused queue refuses with the `EMQ*` class and changes nothing; (iii) **the pause gate** — assert a
  paused queue with a non-empty pending claims empty, and (if `@claim` was edited) the `claim` conformance
  scenario is byte-for-byte identical to its emq.1 form.
- **A mutation spot-check** on one verb (e.g. flip the obliterate not-paused guard's `~= 1` to `== 1`, or the
  reprocess `dead`-state check, or the remove locked-job `EXISTS` guard), confirm a test catches it, then
  **REVERT by the inverse edit and verify `git diff --stat` clean** (the Director's only edit-class action —
  a net-zero verification probe, immediately reverted; the Director authors no production code, LAW-1a).

Gate: the build is faithful to the carve and inside the boundary; the destructive-verb + pause-gate probes
hold or the gaps are written as REMEDIATE items for Stage 3. The Director records the review as a
`tool_x_report` + any REMEDIATE list as `tool_x_learning`/decisions, then advances to Mars-2.

### Stage 3 — Mars-2 (implementor, harden + test): the gate ladder + REMEDIATE (MAX=3)

**Resume the Stage-1 Mars** (`SendMessage`, preserving build context) — one Mars identity, two passes.
Directive: (a) REMEDIATE every Stage-2 item. (b) Run the rung's full gate — toolchain re-probe (no hardcode)
+ Valkey 6390 PONG; per-app pure + `:valkey` suites (`TMPDIR=/tmp`); the new operator conformance scenarios
registered + green beside the **18 prior scenarios byte-unchanged and green** (INV1) with the count re-pinned
in both pinning tests; the new `EMQ*` class(es) registered with probes (the five-code fence union
unextended); the mutation-verdict drills (a paused queue claims empty; drain leaves pending zero and active
intact; obliterate refuses non-paused and clears every set when paused; update/log rewrites the row/logs;
remove_job removes an unlocked job and refuses a locked one; reprocess_job moves dead→pending and refuses a
non-dead job); the **emq.1 + emq.2.1 gate ladders still green end-to-end** (no regression).

**The ≥100-iteration determinism loop DOES apply to this rung** — unlike the read-only emq.2.1 (which
skipped it). emq.2.2's `:valkey` suites **mint branded job ids** to set up every mutation (enqueue → drain;
enqueue → claim → reprocess; enqueue → remove), and the program's standing hazard is **same-millisecond
branded-id mint contention WITHIN a run** (program law §The ≥100 determinism loop; `echo/CLAUDE.md` §4 — the
arc hit the id-collision flake three times, each caught only by the independent loop, never by a single
run). Run `for i in $(seq 1 100); do TMPDIR=/tmp mix test || break; done` inside `echo/apps/echo_mq` (the
loop must OWN the machine — no concurrent liveness server, no sibling heavy I/O). One green run is NOT proof.
State the determinism posture honestly with the loop's result. The REMEDIATE loop closes failures, MAX 3
passes.

Gate: every ladder item PASS or explained; tests green; the 18+new conformance tally clean with the count
re-pinned; the new `EMQ*` class(es) registered; the mutation drills recorded; the ≥100 determinism loop
green (it OWNED the machine); the boundary grep empty; coverage tabled honestly (no fake-100).

### Stage 4 — Venus (architect): post-build specs reconcile

Directive: run a post-build reconcile (`/reconcile emq.2.2 post` — as-built ⇄ spec, the lag-1 discipline)
and bring the spec surface to as-built truth. Fold the four design-make decisions into the triad
([`./emq.2.2.md`](emq.2.2.md) body authoritative; stories + brief follow); record the module placement
chosen, the queue-wide pause mechanism built (gate-in-`@claim` or separate), the `EMQ*` class word(s)
registered + their client-side atoms, and the drain/obliterate scope built; re-pin every drifted anchor +
the new conformance count; mark any realization-over-literal deviation; **update
[`./emq.2.design.md`](../emq.2.design.md)** if the build refined the carve (e.g. the placement, the pause
mechanism, the class words). Note any seam the build surfaced for **emq.2.3** (the lock plane the remove
refusal reads; the event seam update_progress emits). Venus edits the spec triad + the carve doc + the
ledger, **never production code, never commits**.

Gate: every triad claim MATCH or `[RECONCILE]`-marked; the carve reflects the build; the brief internally
consistent (every D/INV/US referenced-and-defined); voice + traceability + link gates clean.

### Stage 5 — Director: closure + ONE post-closure LAW-4 commit + feedback

Preconditions in order (x-mode skill §4): the Stage-2 review clean (or its REMEDIATE items closed) + the
Stage-3 gate green (including the ≥100 determinism loop) + the Stage-4 reconcile build-grade; **≥1
`tool_x_decision` (D-n)** locked + a **`tool_x_complete` (Z-n)** written this turn; `git status --short` AND
`git diff --cached --name-only` reviewed; `.git/rebase-merge`/`rebase-apply` checked. Then the **pathspec
commit** (never `git add -A`, never a bare commit) over the Stage-5 pathspec below; the message cites the
slug, the Z-n, the D-n decisions, and the Y-n reports. **Same turn:** flip the emq.2.2 status in the carve
doc + the roadmap rows; write/extend `emq-2-2.progress.md`; surface the next frontier (emq.2.3 — the watch
plane); under an **explicit Operator grant only**, apply any mentoring diffs to the peer agent defs.

## The Stage-5 commit pathspec (Director-only)

Commit exactly these on closure (the rung's surface; the build run's actual touch-set is authoritative —
adjust to what Stages 1–4 truly changed):

```text
docs/echo_mq/specs/emq.2.2.md
docs/echo_mq/specs/emq.2.2.stories.md
docs/echo_mq/specs/emq.2.2.llms.md
docs/echo_mq/specs/emq.2.2.prompt.md          (this runbook)
docs/echo_mq/specs/emq.2.design.md            (Venus updates the carve if the build refined it)
docs/echo_mq/specs/emq-2-2.progress.md
docs/echo_mq/specs/emq-2-2.registry.json
echo/apps/echo_mq/lib/echo_mq/                 (the operator module/verbs + the mutation scripts)
echo/apps/echo_mq/test/                        (the new suites + the operator conformance scenarios + the count re-pin)
echo/apps/echo_wire/lib/echo_wire.ex           (ONLY if a delegate was added — expect EXCLUDED)
```

**EXCLUDE** (Operator out-of-band — never sweep into the rung commit): `echo/apps/exchange/**`,
`echo/apps/live_svelte/**`, `echo/apps/mercury_cms/**`, `echo/apps/mercury_live_admin/**`, `html/**`, and
any `[emq]`/`[bcs]`/`[mercury]`/`[exchange]` doc commits the Operator lands between stages. `apps/echomq` is
untouched by construction (the capability reference). `echo/mix.lock` ships ONLY if a real dep moved
(emq.2.2 adds none — expect it EXCLUDED). **Never `git add -A`.**

## Risk tier

emq.2.2 touches no auth / deploy / external-network surface and adds no new process — a bus-internal
**mutation** rung on the local Valkey substrate. It is **low-moderate** risk, **above** the read-only
emq.2.1 on two counts the Stage-2 probe targets: (1) **destructive verbs** — drain and obliterate **delete**
rows and clear sets, so the adversarial probe asserts drain spares active jobs and obliterate refuses a
non-paused queue (a wrong guard would discard live work); (2) **the pause gate may touch the shipped
`@claim` transition** — if D1 rules the gate-in-`@claim` form, the `claim` conformance scenario MUST stay
byte-for-byte identical (INV1), and the Director **escalates to an Apollo charter** if it does not. The solo
Director review (Stage 2) + Venus's independent reconcile (Stage 4) are the rigor floor at this tier
(x-mode §11.3); the determinism loop applies (the suites mint branded ids — see Stage 3). The substantive
correctness risks are: mutating a v1-shaped state the bus does not have (INV3 + the Stage-2 scope check); a
refusal that changes state before refusing (INV6 + the spot-check); and a same-ms mint flake in the new
suites (the ≥100 loop).

## Acceptance — "shipped" means

Every DoD box in [`./emq.2.2.md`](emq.2.2.md) is checkable from the run's outputs: the design-make adopted
+ logged (placement, the queue-wide pause mechanism, the `EMQ*` class words, the drain/obliterate scope);
D2–D9 built as real transitions over the as-built four sets with declared keys and every job id gated; the
queue-wide pause distinct from `Lanes.pause/3`; every precondition refusal leading with its `EMQ*` class and
changing nothing; the new `EMQ*` class(es) registered with probes; pure + `:valkey` suites green per-app;
the **18 prior conformance scenarios byte-unchanged** + the new operator scenarios green with the count
re-pinned; the ≥100 determinism loop green; the mutation-verdict drills recorded; the emq.1 + emq.2.1
ladders still green; the solo Director review clean (the destructive-verb + pause-gate probes held); the
Venus reconcile build-grade; one Director post-closure pathspec commit.

---

The contract: [`./emq.2.2.md`](emq.2.2.md). The stories: [`./emq.2.2.stories.md`](emq.2.2.stories.md).
The brief: [`./emq.2.2.llms.md`](emq.2.2.llms.md). The carve it continues:
[`./emq.2.design.md`](../emq.2.design.md). The read plane (the acceptance lens):
[`./emq.2.1.md`](emq.2.1.md). The canon: [`../emq.design.md`](../../../emq.design.md). The program:
[`../emq.roadmap.md`](../../../emq.roadmap.md) · [`../echo_mq.md`](../../../echo_mq.md). The x-mode skill:
[`.claude/skills/x-mode/SKILL.md`](../../../../../.claude/skills/x-mode/SKILL.md). The capability reference:
`echo/apps/echomq/lib/echomq/queue.ex` + `worker.ex` + the operator scripts.
