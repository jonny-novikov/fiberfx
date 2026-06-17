# EMQ.3.4 · the BUILD orchestration runbook — ship the flow failure-policy + bulk add (the flow family's fourth slice, HIGH-risk)

> **Status: the build runbook (the triad is AUTHORED — `emq.3.4.{md,stories,llms}` exist; this ships it).**
> Unlike emq.3.3 (which opened with a design-authoring cycle because its quad did not exist), emq.3.4's **design
> is in the body** ([`./emq.3.4.md`](emq.3.4.md)) — the failure mechanism is decided (the additive `@retry`
> dead-letter branch; the cross-queue fail-entry over the same `flow:outbox` + sweep emq.3.3 founded; the
> `:processed`-class HSETNX idempotency guard over `:failed`/`:unsuccessful`), and the one scope question — the
> **V-1 fork** (grandchildren IN emq.3.4, or a separate later rung) — is **RULED → Arm A (D-2)**: emq.3.4 =
> failure-policy + bulk; grandchildren the locked Out → emq.3.5. This runbook fans out the
> **echo-mq-ship** lead-team (Venus → Mars-1 → Director review → Mars-2 → Apollo MANDATORY → Venus → Director
> ship) to build it. **Risk: HIGH** — emq.3.4 (a) **edits a shipped Lua script** (`@retry`'s dead-letter arm
> gains an additive failure-propagation branch; the existing body `jobs.ex:254-259` BYTE-FROZEN) and (b) crosses
> the same slot boundary the cross-queue completion does (a cross-queue child's DEATH reaches the parent over the
> same outbox+sweep) → **Apollo MANDATORY** + the **≥100 determinism loop**.

## The family in one paragraph

The emq.3 **parent/flow family** ([`./emq.3.md`](../../emq.3.md)) is Movement I's closer — the v1 `flow_producer`
capability redesigned A-1-clean (the dependency graph in declared §6 parent subkeys, never the v1 data-value
`parent_key`). The carve: **3.1 (single-queue, atomic)** SHIPPED + **3.2 (child-result reads)** SHIPPED + **3.3
(cross-queue, eventually-consistent via the outbox+sweep)** SHIPPED · **3.4 (failure-policy + bulk)** ← this
runbook · grandchildren/deep recursion (the V-1 fork). emq.3.1–3.3 built the **happy path** end to end (a child
that COMPLETES releases its parent — same-slot via `@complete`'s fan-in, cross-slot via the `flow:outbox` +
`@flow_deliver`). emq.3.4 closes the **failure half**: a child that DIES today never reaches the parent.

## The rung in one paragraph (the build)

emq.3.4 builds the **flow failure-policy + bulk add**: today a flow parent is released **only** by a child
**COMPLETING**, so a child that **DIES** (`@retry`'s dead-letter arm, `jobs.ex:254-259`) leaves the parent
**hanging in `awaiting_children` forever**. emq.3.4 closes that gap with the v1 options —
`fail_parent_on_failure` (the default: a dead child fails the parent, recorded in the parent's `:failed`) and
`ignore_dependency_on_failure` (the dead child is treated as satisfied — `:dependencies` DECR'd — and recorded
in `:unsuccessful`, so the parent proceeds) — over the **already-§6-reserved** `:failed`/`:unsuccessful` subkeys
(`emq.design.md:307` — **no grammar edit, no new key type**), plus `EchoMQ.Flows.add_bulk/3` (the v1 `add_bulk/2`
parity) and `ignored_failures/3` (the v1 `get_ignored_children_failures` read). The same-queue death routes
atomically (an additive branch in the shipped `@retry`, the existing dead-letter body byte-frozen); the
cross-queue death emits a **fail-entry** into the same `flow:outbox` emq.3.3 founded and is delivered by the same
sweep via a new **`@flow_fail_deliver`** on the parent's slot (idempotent by the `:processed`-class HSETNX guard).

## Mode

This is **`echo-mq-ship`** — the `/x-mode` lead-team bound to the echo_mq apps + the v2 laws + the per-app gate
ladder + the echo_mq-specialized build team (Venus loads `echo-mq-architect`, Mars loads `echo-mq-implementor`,
Apollo loads `echo-mq-evaluator`). Scope slug **`emq-3-4`**; ledger
[`./emq-3-4.progress.md`](../../progress/emq-3-4.progress.md) (the design reconcile T-1 + the V-1 scope fork are recorded —
the build continues it); the boundary is **`echo/apps/echo_mq`** (+ NO `echo_wire`). **Apollo is MANDATORY**
(HIGH-risk — a shipped-script edit on `@retry` + the cross-slot failure delivery).

> **The V-1 scope fork is RULED → Arm A (D-2) — no open gate.** emq.3.4 = **failure-policy + `add_bulk`**
> (the family carve [`./emq.3.md`](../../emq.3.md):198 scope); **grandchildren / deep recursion is the locked Out →
> emq.3.5** (a separate later rung, recorded NOT built). The triad is authored to Arm A → **no pre-build re-scope,
> no AskUserQuestion** (the Director ruled with delegated authority; the failure mechanism was already decided in
> the body). Arm B (folding grandchildren into emq.3.4) was the steelmanned alternative — a zero-cost re-scope
> that would only ADD the recursive-tree deliverables — and stays an Operator option to revisit later, but is
> **not this rung**. The build proceeds with grandchildren as the honest Out.

## The pipeline — the HIGH-risk flow (Venus → Mars-1 → Director review → Mars-2 → Apollo MANDATORY → Venus → Director ship)

Each spawned stage is a real `Agent` that adopts its `.claude/agents/<role>.md` charter, LOADS its
`echo-mq-<role>` skill, and self-registers via `mcp__aaw__*` (LAW-1; no narrated spawns). The Director holds the
gate between stages. **Apollo is MANDATORY** (HIGH-risk — a shipped-script edit on `@retry` + a cross-slot
failure-delivery mechanism).

### Stage 0 — Venus (architect): the pre-build reconcile (the V-1 scope already RULED → Arm A)

Directive: run the lag-1 reconcile (re-probe every as-built anchor in the brief against the current tree —
`flows.ex` `add/3`+`add_cross_queue`+`children_values/3`+`@enqueue_flow_child`, `jobs.ex` `@retry`+the dead-letter
arm `:254-259`+`@complete`+`complete/5`+`parent_of/3`, `pump.ex` `@flow_deliver`+`deliver_flow_completions`+
`split_entry`, `conformance.ex` the **live count**, `keyspace.ex` `job_key/2`). Confirm `:failed`/`:unsuccessful`
are §6-reserved (`emq.design.md:307`). The **V-1 scope fork is already RULED → Arm A** (D-2 — emq.3.4 =
failure-policy + bulk; grandchildren the locked Out → emq.3.5), so there is **no fork to re-open** (the triad is
authored to it). Gate: the grounding delta table (MATCH / `[RECONCILE]`); the live conformance count (50 expected
post-build, **47** as the pre-build floor — re-probe, do NOT hardcode); the BUILD-GRADE verdict. **(Stage 0's
reconcile is ALREADY DONE this design run — the T-1 delta + the D-2 ruling synced into the triad; the build
re-affirms it against any Operator out-of-band landing between stages.)**

### Stage 1 — Mars-1 (implementor): build the flow failure-policy + bulk add

Directive (the `echo-mq-implementor` craft; build to [`./emq.3.4.llms.md`](emq.3.4.llms.md) Reqs 1–7 + the
build-order DAG T1–T6): (1) **the failure-policy options + `add_bulk/3`** (`flows.ex` — the
`fail_parent_on_failure`/`ignore_dependency_on_failure` flags on `add/3`; `parent_policy` on the cross-queue
child; `add_bulk/3` fail-closed per flow); (2) **the same-queue failure propagation** (`jobs.ex` — the additive
`@retry` dead-letter branch AFTER the byte-frozen morgue transition `:254-259`; the host `retry`/`parent_of`
extension); (3) **the cross-queue fail-deliver** (`jobs.ex` the fail-entry emit + `pump.ex` the KIND-dispatch in
`deliver_flow_completions`/`split_entry`/`deliver_one` + the new `@flow_fail_deliver`; `@flow_deliver`
byte-unchanged); (4) **`ignored_failures/3`** (`flows.ex` — the `:unsuccessful` HGETALL, host-only); (5)
`flow_fail_parent`/`flow_ignore_dep`/`flow_add_bulk` conformance + the count re-pin **47 → 50** (both pins); (6)
the `:valkey` failure suite (`test/flow_failure_test.exs`). Run the per-app gate (compile warnings-as-errors;
`TMPDIR=/tmp mix test --include valkey` inside `echo/apps/echo_mq`). Gate: compile clean; the failure suite green;
`Conformance.run/2` → `{:ok, 50}`; the `@retry` `git diff` shows only ADDED lines (the dead-letter body `:254-259`
+ the schedule arm byte-frozen); `@complete` + `@flow_deliver` byte-unchanged; **runs NO git**.

### Stage 2 — Director: solo review (a REAL pass)

Directive: a real diff read against the triad. Verify: the **shipped-script byte-proof** (the `@retry` `git diff`
— the existing dead-letter body `:254-259` + the schedule arm byte-identical, only the new failure branch added;
`@complete` incl. the fan-in `:212-219` + cross-queue emit `:205-206` byte-identical; `@flow_deliver`
byte-identical — the HIGH-risk headline); the **declared-keys/slot grep** (the same-queue failure branch + the
cross-queue fail-emit keys all on the child's slot {C}, `@flow_fail_deliver`'s keys all on the parent's slot {P}
— no cross-slot key, the F-1 trap the 6390 single-node engine will NOT catch); the **eventually-consistent**
observable (the cross-queue scenario asserts the parent unchanged pre-sweep, failed/proceeded post-sweep — never
synchronous); the **idempotency** proof (a double fail-deliver fails/satisfies the parent once); the **no-drop**
proof (the cross-queue fail-emit RPUSH + the morgue transition are one EVAL); the **no-invent** check (no v1
data-value `parent_key` lifted; the host builds declared keys; `:failed`/`:unsuccessful` §6-reserved, no
grammar/`keyspace.ex` edit); `admin.ex` untouched (B6/INV10); the `:processed`/`:unsuccessful` disjointness
(B4/INV6). Produce the REMEDIATE list. **Apollo is MANDATORY** — confirm the dedicated evaluator is spawned at
Stage 4.

### Stage 3 — Mars-2 (implementor, harden + the full gate ladder)

Directive: clear the REMEDIATE list; run the full ladder — per-app compile warnings-as-errors; the `:valkey`
failure suite; the prior emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2,3} suites + `Conformance.run/2` **unchanged** (no
regression — INV3); the prior 47 conformance byte-unchanged + the three new probes registered; the
**≥100-iteration determinism loop** over the mint/process-touching cross-queue failure scenario **owning the
machine** (`for i in $(seq 1 100); do TMPDIR=/tmp mix test --include valkey || break; done` — a cross-queue flow
mints a parent + N children across queues, the same-ms mint hazard surfaces only across runs); the per-attr `git
diff` proving the `@retry` dead-letter body + `@complete` + `@flow_deliver` byte-frozen. Recommended hardening
(Mars's own, beyond the REMEDIATE list): a multi-child failure shape (a parent + 3 children, one dies under each
policy, the parent resolves correctly); a fail-deliver crash-window test (a sweep crash AFTER the fail-deliver,
BEFORE the outbox LTRIM → re-deliver idempotent — the emq.3.3 D-3 window applied to the fail path); the
`fail_parent_on_failure` one-level boundary (a failed flow PARENT moves to `dead` and does NOT auto-propagate to a
grandparent — B3, the grandchildren-Out boundary holds). Gate: all green; the ≥100 loop green; **runs NO git**.

### Stage 4 (MANDATORY) — Apollo (evaluator): the HIGH-risk verification

Directive (the `echo-mq-evaluator` craft; the §11.2 charter): re-run the gate ladder + the ≥100 loop
**INDEPENDENTLY** (do not trust Mars's report — re-run the suites, re-walk the diff). Adversarially verify: the
**shipped-script byte-proof** (the `@retry` dead-letter body `:254-259` + the schedule arm byte-identical;
`@complete` + `@flow_deliver` byte-identical — the explicit per-attr SHA/`git diff`, the HIGH-risk evidence); the
**declared-keys/slot soundness** (no cross-slot key in the failure branch, the fail-emit, or `@flow_fail_deliver`
— re-run the grep; name the single slot of each script's key set); the **no-drop guarantee** (the cross-queue
fail-emit's RPUSH + the morgue transition are one EVAL — a dead cross-queue child always has a fail-entry); the
**idempotency keystone** (a re-delivered fail is a no-op — fail/satisfy once; mind the emq.3.3 L-2 lesson — a
hand-fabricated crash-survivor fail-entry MUST byte-match what `@retry` emits, KIND tag + parent_queue first,
or the guard is exercised on a phantom slot and the test passes for the wrong reason); the
**eventually-consistent honesty** (no "atomic across queues" claim anywhere; the parent fails/proceeds on the
sweep tick); the **gap-closed** proof (a `fail_parent_on_failure` child death moves the parent to `dead`, NOT
left hanging — INV5; an `ignore_dependency_on_failure` death lets the parent proceed — INV6); the **additive-minor**
(47 → 50, the prior set byte-unchanged, both pins). Render the **BUILD-GRADE / BLOCKED** verdict the Director
ratifies. Apollo edits the spec triad/tests/`.operator.md`/retrospective (Director-ratified the peer agent-defs)
— **never production code, never commits.** Uses `AskUserQuestion` only to keep the product shippable (a genuine
product fork).

### Stage 5 — Venus (architect): the post-build reconcile

Directive: diff the triad against the as-built surface; flip every `[ ]` DoD box to `[x]` with the as-built
`file:line`; sync the body's forward-tense ("emq.3.4 builds …") to the as-built present tense for what shipped;
re-pin every line anchor (the build moved the surface); confirm INV1–INV11 as runnable checks against the shipped
code (Arm A — failure-policy + bulk; grandchildren the Out, emq.3.5). Gate: the post-build reconcile delta + the
BUILD-GRADE verdict; the triad synced to as-built; **edits ONLY the spec triad — no `.ex`/`.exs`; runs NO git.**

### Stage 6 — Director: closure + ONE LAW-4 commit + the frontier fold

Preconditions (x-mode §4): the gate green + the reconcile build-grade + **Apollo BUILD-GRADE** (MANDATORY); **≥1
`tool_x_decision`** (the build's locked decisions; the V-1 scope ruling D-2 already landed this design run) + a
**`tool_x_complete` (Z-n)** this turn; `git status --short` AND `git diff --cached --name-only` reviewed;
`.git/rebase-merge`/`rebase-apply` checked. Then the **pathspec** commit (below; NEVER `git add -A`). **Same
turn:** flip the emq.3.4 row in the roadmap ([`../emq.roadmap.md`](../../../emq.roadmap.md)) + the dashboard
([`../emq.progress.md`](../../../emq.progress.md)) + the catalog ([`../emq.features.md`](../../../emq.features.md)) to
**SHIPPED**; surface the **next frontier** — **emq.3.5 (grandchildren / deep recursion)** is the flow family's
**last slice** (the V-1 Arm-A Out), and closing it **CLOSES Movement I** → Movement II (emq.4–emq.8). The message
cites the slug, the Z-n, the D-n, and the Y-n report.

## Risk tier (the build)

emq.3.4 the BUILD is **HIGH-risk** — like emq.3.3, the inverse of emq.3.2's NORMAL-risk. Two elevated dimensions:
**(a)** it **edits a shipped Lua script** (`@retry`'s dead-letter arm gains an additive failure-propagation
branch; the existing body `:254-259` BYTE-FROZEN — the same shipped-script-edit class as emq.3.1/3.3's `@complete`
edits); **(b)** it crosses the **same slot boundary** the cross-queue completion does (a cross-queue child's
death reaches the parent over the same `flow:outbox` + sweep). So the build requires **Apollo MANDATORY** + the
**≥100 determinism loop** (a cross-queue flow mints a parent + N children across queues — the mint-touching
surface). The properties that set the tier, named + tested not hand-waved: the cross-queue failure is
**eventually-consistent** (INV5/INV6, inherited from emq.3.3's INV7); the recovery is **at-least-once →
effectively-once** (the `:processed`-class HSETNX guard over `:failed`/`:unsuccessful`, INV7; the no-drop atomic
fail-emit, INV8); the shipped-script touch is the **one additive `@retry` branch** (the dead-letter body
byte-frozen, INV3 — the regression bound Apollo byte-proves). The mitigant: the `:failed`/`:unsuccessful` subkeys
are **§6-reserved** (no grammar edit) and the cross-queue mechanism is **inherited proven** (the outbox + sweep
shipped at emq.3.3) — so emq.3.4's genuinely-new surface is the `@retry` branch + the `@flow_fail_deliver` script,
narrower than emq.3.3's (which founded the whole cross-slot signal).

## The Stage-6 commit pathspec (Director-only — the emq.3.4 BUILD)

Commit exactly the build's measured surface:

```text
echo/apps/echo_mq/lib/echo_mq/flows.ex                 (the policy flags + parent_policy + add_bulk/3 + ignored_failures/3)
echo/apps/echo_mq/lib/echo_mq/jobs.ex                  (the additive @retry dead-letter failure branch + host retry/parent_of)
echo/apps/echo_mq/lib/echo_mq/pump.ex                  (the KIND dispatch + @flow_fail_deliver; @flow_deliver byte-unchanged)
echo/apps/echo_mq/lib/echo_mq/conformance.ex           (flow_fail_parent/flow_ignore_dep/flow_add_bulk + the count re-pin 47→50)
echo/apps/echo_mq/test/flow_failure_test.exs            (NEW — :valkey)
echo/apps/echo_mq/test/conformance_run_test.exs         (the count re-pin → 50)
echo/apps/echo_mq/test/conformance_scenarios_test.exs   (the count re-pin → 50)
docs/echo_mq/specs/emq.3.4.md                           (the triad — Stage-5 synced + DoD boxes)
docs/echo_mq/specs/emq.3.4.stories.md
docs/echo_mq/specs/emq.3.4.llms.md
docs/echo_mq/specs/emq.3.4.prompt.md                    (this runbook)
docs/echo_mq/specs/emq-3-4.progress.md                  (the ledger — incl. the V-1 ruling)
docs/echo_mq/specs/emq.3.md                             (the carve's emq.3.4 row → SHIPPED)
docs/echo_mq/emq.roadmap.md                             (the emq.3.4 row → SHIPPED)
docs/echo_mq/emq.progress.md                            (the dashboard fold)
docs/echo_mq/emq.features.md                            (the flow row → emq.3.4 shipped)
```

**EXCLUDE** (Operator out-of-band — never sweep into the rung commit):
`echo/apps/mercury_*/**`, `html/**`, the F# course, `docs/echo/mesh/**` (the Operator's concurrent course), and
any `[emq]`/`[bcs]`/`[mercury]` commits the Operator lands between stages. **`keyspace.ex` and
`admin.ex` are UNTOUCHED** (verify they are NOT in the diff — the `:failed`/`:unsuccessful` subkeys are §6-reserved
and compose via the existing `job_key/2`; the lifecycle carry is deferred). **`@complete` and `@flow_deliver` are
BYTE-UNCHANGED** (verify in the `jobs.ex`/`pump.ex` diffs). **Never `git add -A`.** The build agents run **no git**
(the Director commits by pathspec).

## Acceptance — "shipped" means

- The failure-policy options land on `add/3`/`add_bulk/3` (`fail_parent_on_failure` default `true` +
  `ignore_dependency_on_failure`; the cross-queue child carries `parent_policy`; `add_bulk/3` fail-closed per
  flow) (D2); `ignored_failures/3` reads the `:unsuccessful` subkey (D6).
- The same-queue failure propagation is the additive `@retry` dead-letter branch (the existing body `:254-259`
  BYTE-FROZEN, git-proven): a same-queue dead child fails the parent (`:failed` + `dead`) or satisfies-and-records
  (`:unsuccessful` + DECR + at-zero release), atomically (one EVAL, one slot — INV5/INV6) (D3).
- The cross-queue fail-deliver: a cross-queue dead child RPUSHes a fail-entry into `flow:outbox` atomically with
  the morgue transition (one EVAL — the no-drop guarantee, INV8); the existing sweep dispatches the fail KIND to
  `@flow_fail_deliver` on the parent's slot, idempotent by the `:processed`-class HSETNX guard (a re-delivery is a
  no-op — INV7); `@flow_deliver` byte-unchanged (D4).
- `flow_fail_parent`/`flow_ignore_dep`/`flow_add_bulk` registered additive-minor (47 → 50, the prior 47
  byte-unchanged, both pins re-pinned — INV9); the `:valkey` failure suite green; the **≥100 loop** green; the
  prior suites + `Conformance.run/2` unchanged (INV3); **Apollo BUILD-GRADE** (MANDATORY); honest-row reporting
  (Valkey on 6390).
- The gap is CLOSED: a `fail_parent_on_failure` child death moves the parent to `dead` (not hanging — INV5); an
  `ignore_dependency_on_failure` death lets the parent proceed (INV6). The `:failed`/`:unsuccessful` subkeys'
  lifecycle is NAMED, deferred (B6/INV10); `admin.ex`, `keyspace.ex`, `@complete`, `@flow_deliver` untouched. The
  V-1 scope ruling is **Arm A** (D-2 — failure-policy + bulk; grandchildren the locked Out → emq.3.5). The spec
  body stays authoritative; Stage 5 syncs it to the as-built surface; the roadmap + dashboard + catalog flip to
  SHIPPED; the frontier folds to **emq.3.5 (grandchildren)** → closing it **CLOSES Movement I**.

Inputs (the build): [`./emq.3.4.md`](emq.3.4.md) (authoritative) · [`./emq.3.4.stories.md`](emq.3.4.stories.md)
· [`./emq.3.4.llms.md`](emq.3.4.llms.md) (the build brief) · [`./emq-3-4.progress.md`](../../progress/emq-3-4.progress.md)
(T-1 the reconcile + V-1 the scope fork) · [`./emq.3.md`](../../emq.3.md) (the family + the carve emq.3.4 row + INV3 +
INV7) · the shipped slices [`./emq.3.1.md`](emq.3.1.md) + [`./emq.3.2.md`](emq.3.2.md) +
[`./emq.3.3.md`](emq.3.3.md) (the cross-queue mechanism the fail-deliver rides) · the build-runbook FORM
[`./emq.3.3.prompt.md`](emq.3.3.prompt.md) PART II (HIGH-risk, the same tier) · Canon
[`../emq.design.md`](../../../emq.design.md) §6 (`:failed`/`:unsuccessful` reserved at `:307`)/§11.10/§5/S-6/S-1 ·
Skills: `echo-mq-ship` (the binding) + `echo-mq-implementor` + `echo-mq-evaluator` + `echo-mq-architect` +
`echo-mq-program.md` (the program law) · Approach
[`../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
