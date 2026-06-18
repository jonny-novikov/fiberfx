# EMQ.3.2 · the build orchestration runbook — ship the child-result reads (the flow family's second slice)

> **Status: SHIPPED 2026-06-15 at CONFORMANCE 46/46.** This runbook drove the **emq.3.2** build — the SECOND
> sub-rung of the parent/flow family (the child-result reads) — the rung that made a single-queue flow's outcome
> **consumable** and **closed emq.3.1's honest bound O1** (the `:processed` value is now a real result). The
> forks ruled R1·B + R2·A; NORMAL-risk (no shipped-script edit), Apollo not required. The **`echo-mq-ship`**
> skill is the echo_mq binding (Venus loads `echo-mq-architect`, Mars loads `echo-mq-implementor`); the inputs
> are the triad ([`./emq.3.2.md`](emq.3.2.md) · [`./emq.3.2.stories.md`](emq.3.2.stories.md) ·
> [`./emq.3.2.llms.md`](emq.3.2.llms.md)), the family ([`./emq.3.md`](../emq.3.md) — the carve + the forks), the
> SHIPPED first slice ([`./emq.3.1.md`](emq.3.1.md) — the floor emq.3.2 reads), and the canon
> ([`../emq.design.md`](../../../emq.design.md) §11.10/§6/§5/S-6).

## The family in one paragraph

emq.3 is the parent/flow family — the v1 `flow_producer` capability redesigned so a parent becomes claimable
only when its children complete (fan-in), **under the v2 A-1 declared-keys law**. The dependency graph rides
**declared §6 subkeys of the parent** (`emq:{q}:job:<parent>:dependencies` the outstanding-child counter +
`:processed` the completed-children HASH), each rooted at the parent's declared job key, on the parent's `{q}`
slot, A-1-clean by construction. The family carves into emq.3.1 (single-queue, **SHIPPED** 2026-06-15) · **3.2
(child-result reads)** · 3.3 (cross-queue) · 3.4 (failure-policy + bulk). The full design + the surfaced forks
are [`./emq.3.md`](../emq.3.md).

## The rung in one paragraph

emq.3.2 carves the **child-result reads** — the host API a flow's parent handler reads its children's outcomes
through. It builds, inside `echo/apps/echo_mq` under the v2 laws: **(1)** `EchoMQ.Flows.children_values/3` (a
pure `HGETALL`-class read of the parent's `:processed` HASH → the completed children's results keyed by child
id); **(2)** `EchoMQ.Flows.dependencies/3` (a pure `GET`-class read of the parent's `:dependencies` STRING
counter → the outstanding count, Fork R2·A); **(3)** the **real-result-carrying completion** (Fork R1·B):
`EchoMQ.Jobs.complete` gains a result argument passed through the **existing `ARGV[5]` slot** the emq.3.1 fan-in
hook already `HSET`s into `:processed` — so `:processed[child_id]` holds the **real result** (closing O1), and
**the shipped `@complete` Lua is BYTE-UNCHANGED** (host-only); **(4)** the conformance scenario
`flow_children_values` (additive minor, `45 → 46`, the prior set byte-unchanged); **(5)** the `:valkey` read
suite + the ≥100 loop. The flow-subkey **cleanup is a NAMED CARRY** to the emq.3.x lifecycle rung. The honest
**Out**: the cross-queue read (emq.3.3), the failure reads (emq.3.4), bulk (emq.3.4), deep recursion. The
contract is [`./emq.3.2.md`](emq.3.2.md) (D1–D6, INV1–INV8).

## Mode

**Flat-L2** (a build + a gate + a verify), Director-supervised. **Not** the Design-Phase variant (the triad
exists — authored this cycle). **NORMAL-RISK**: emq.3.2 edits **no shipped Lua script** — Fork R1·B is
**host-only** (the `@complete` Lua already writes `ARGV[5]`; only the host-supplied value changes), and the two
reads are **pure**. So a dedicated **Apollo evaluator is OPTIONAL** (the Director's solo review + the gate
ladder are the gate); the **≥100-iteration determinism loop** still applies to the mint/process-touching flow
read scenario (the read stands on a flow that minted N+1 ids).

Scope slug: **`emq-3-2`** (dashed, no dots — `tool_x_*`/`TeamCreate` require `^[a-z0-9][a-z0-9-]*$`). Operator:
`jonny`. Workspace: `/Users/jonny/dev/jonnify`. Ledger: `docs/echo_mq/specs/emq-3-2.progress.md` (this design
cycle opened it — T-1 the Stage-0 grounding, T-2 the forks + the lifecycle disposition, D-1/D-2/D-3 the locked
contracts, V-1/V-2 the surfaced forks; the build run continues it).

## The fork gate — Fork R1 MUST be ruled before the build (EMQ.3.2-D1)

**emq.3.2 does not build until the Operator rules Fork R1.** The triad is authored to the recommended arms
(R1·B, R2·A); a ruling the other way is a cheap pre-build re-derive (R1·A) or a non-free re-scope (R2·B).

> **FORK R1 (the headline — GATES the build) — the result-payload mechanism.** The real-result-carrying
> completion (Arm B, recommended: `complete` gains a result argument threaded into the **existing `ARGV[5]`**
> slot; `:processed[child_id]` holds the real result; `children_values/3` returns it = the v1
> `get_children_values` parity; **the `@complete` Lua byte-unchanged** → emq.3.2 stays **NORMAL-risk**) vs a
> pure presence read (Arm A: `children_values/3` returns the emq.3.1 presence marker — which children completed,
> not what they produced; zero completion change, but O1 stays open). **Nothing in the build runs until Fork R1
> is ruled.** Arm B → the build is the slice this triad is authored to (closes O1). Arm A → emq.3.2 narrows to a
> pure presence read (drop the `complete` result arg) — a **free narrowing** before the build. **The risk-tier
> consequence (state it at the launch review):** Arm B is host-only → NORMAL-risk → Apollo optional; a variant
> that EDITED `@complete`'s Lua → HIGH-RISK → Apollo mandatory.
>
> **FORK R2 (a representation re-scope — note: R2·B is NOT free) — the `dependencies/3` read shape.** The
> outstanding COUNT (Arm A, recommended: a pure `GET` of the `:dependencies` STRING counter → an integer;
> minimal) vs the pending SET (Arm B: which children remain — the v1 `get_dependencies` set, but it adds a NEW
> `:children` roster subkey written at `@enqueue_flow` **and** an `@enqueue_flow` edit — a pre-build
> write-surface add that re-opens the flow script + extends the lifecycle-cleanup carry). RECOMMEND the **count**
> (R2·A); the SET is a clean later carry. Unlike R1·A→B, **R2·A→B is not a free re-scope** (it changes the write
> surface) — flag this at the launch review.

If the launch review finds Fork R1 needs a fuller ADR than the family/ledger surfacing, that is a design-make
stage the Operator inserts — flagged, not pre-built.

## The as-built floor (verified at this design cycle, 2026-06-15 — the build's Stage-0 RE-PROBES each; the lag-1 law)

Anchors drift; a sibling rung may move the `echo_mq` surface before emq.3.2 reads it — the build's Stage-0
reconcile re-pins every line below:

- **The conformance count** — `conformance.ex` `scenarios/0` (the live count is **45** as-built: the emq.2
  cluster grew it 18 → 43, emq.3.1 added `flow_add` + `flow_fanin` → 45; re-probe the LIVE count at Stage 0 — do
  NOT hardcode 45; the floor is whatever exists at the pre-build reconcile; the two pin tests
  `conformance_run_test.exs` `run/2 → {:ok, N}` + `conformance_scenarios_test.exs` the N names + the moduledoc
  `"forty-N"`).
- **`@complete` (the BYTE-UNCHANGED Lua + the `ARGV[5]` seam)** — `jobs.ex` `@complete` (`:152-192`): the fan-in
  branch `if KEYS[3] and was_active == 1 then … HSET KEYS[4] ARGV[1] ARGV[5] …` (`:183`) — `ARGV[5]` is **already**
  the value `HSET` into `:processed`. **emq.3.2 does NOT edit this attribute** (R1·B changes only the host-supplied
  `ARGV[5]` value). `Jobs.complete/4` (`:350-370`): `argv ++ [parent_id, job_id]` (`:361`) — `job_id` IS the
  current `ARGV[5]` (the presence marker); R1·B passes the result instead. `parent_of/3` (`:382-389`): the O2
  `HGET 'parent'` (an optional fold — N2).
- **`EchoMQ.Flows.add/3` + `@enqueue_flow`** — `flows.ex`: the module emq.3.2 **extends** with `children_values/3`
  + `dependencies/3`; `@enqueue_flow` `SET KEYS[2] n` (`:49`) writes `:dependencies` as a **STRING counter**
  (Fork R2·A reads it via `GET`); `KEYS[2] = parent_key <> ":dependencies"` (`:85`).
- **`add_log/5` (the subkey-compose precedent)** — `jobs.ex` (`:456-458`): `Keyspace.job_key(queue, job_id) <>
  ":logs"`. The read keys compose the same way (`<> ":processed"`, `<> ":dependencies"`).
- **`Keyspace.job_key/2`** — `keyspace.ex` (`:17-24`, gates `BrandedId.valid?/1`, RAISES on an ill-formed id —
  INV4), `queue_key/2`.
- **`del_job` (the L-5/N1 lifecycle carry — DO NOT EDIT)** — `admin.ex` (`:150-153`): the FIXED `DEL jk, jk ..
  ':logs', jk .. ':lock'` enumeration that excludes the flow subkeys. emq.3.2 **names** the cleanup disposition
  (the `obliterate`-sweep + per-flow cleanup) and **routes it to the emq.3.x lifecycle rung**; `admin.ex` stays
  **untouched** this rung.
- **The v1 capability reference (READ, never edit, the FORM not lifted)** —
  `echo/apps/echomq/lib/echomq/flow_producer.ex:64,70` (`get_children_values`/`get_dependencies` — the
  parent-handler reads to port) + `echo/apps/echomq/lib/echomq/job.ex:48,54` + the subkey names at
  `echo/apps/echomq/lib/echomq/keys.ex:288-294`.

## The pipeline — the NORMAL-risk flow (Venus → Mars-1 → Director review → Mars-2 → Director ship)

Each spawned stage is a real `general-purpose`/dedicated `Agent` that adopts its `.claude/agents/<role>.md`
charter, LOADS its `echo-mq-<role>` skill, and self-registers via `mcp__aaw__*` (LAW-1; no narrated spawns). The
Director holds the gate between stages. The per-spawn contract is the `/x-mode` skill §3 (Framing → adopt
charter → aaw ceremony → the stage block → audit directive → propagation clause → report). **Apollo is OPTIONAL**
(NORMAL-risk — no shipped-script edit); the Director MAY spawn Apollo at discretion (e.g. if R1·B's host change
turns out to touch the claim path via the O2 fold), but the default NORMAL-risk pipeline is Venus → Mars-1 →
Director review → Mars-2 → Director ship.

### Stage 0 — Venus (architect): the pre-build reconcile + the fork-settlement gate

Directive: run the lag-1 reconcile (re-probe every anchor above against the post-emq.3.1 tree; re-pin the
conformance count + the `@complete` `ARGV[5]` seam + `complete/4`'s `job_id`-as-`ARGV[5]` + `@enqueue_flow`'s
`:dependencies` STRING counter + `add_log`'s `<> ":logs"` + `job_key/2` + `del_job`'s FIXED list + the v1
reference). Confirm **Fork R1 is Operator-ruled** (EMQ.3.2-D1) and **re-derive the triad to the ruled arm**
(R1·B → the real-result completion; R1·A → narrow to the presence read); note Fork R2's recommendation (the
count; R2·B is a non-free re-scope). Re-affirm the **flow-subkey lifecycle disposition is NAMED** (D5/INV7 — the
§2 guardrail). Bring the triad to as-built truth where a commit moved an anchor; mark each delta
MATCH-or-`[RECONCILE]`. Gate: the reconcile delta table; the Fork R1 ruling recorded; the triad re-derived; the
BUILD-GRADE / BLOCKED verdict. *(This design-cycle pass already discharged the Stage-0 grounding — T-1/T-2,
D-1/D-2/D-3, V-1/V-2; the build's Stage-0 re-probes against the then-current tree.)*

### Stage 1 — Mars-1 (implementor): build the child-result reads

Directive: after Fork R1 is ruled, build EMQ.3.2-D2 → D6 to the brief's agent stories (AS-2 → AS-7) and the
design. The order: (1) `jobs.ex` — the **host-only** result arg (`complete` gains the result; `ARGV[5]` becomes
the result, not `job_id`; the non-flow caller byte-unchanged; **verify the `git diff` of the `@complete`
attribute is empty after the edit** — the NORMAL-risk proof); (2) `flows.ex` — `children_values/3` (`HGETALL` →
map) + `dependencies/3` (`GET` → non-neg integer), both gating `parent_id` at `Keyspace.job_key/2`, both
**read-only** (INV2); (3) `conformance.ex` — `flow_children_values` + the `apply_scenario` probe + re-pin `45 →
N` in both pin tests; (4) `test/flow_children_values_test.exs` (NEW, `:valkey`). Cite the spec/design line for
every public call; **the reads are pure** (no `HSET`/`SET`/`DECR`/`ZADD`/`DEL` — INV2); **no shipped Lua script
edited** (INV1/INV3 — the headline); register the conformance scenario + probe **in the same change** (INV6, the
additive-minor law; the prior 45 byte-unchanged); compile clean (`--warnings-as-errors`, per-app). **The
no-cleanup gate (INV7):** emq.3.2's touch-set adds **no** `DEL`/`HDEL`/`UNLINK` of a flow subkey; `admin.ex`
untouched. Gate: per-app compiles green; D2–D6 exist; the diff stays inside `echo_mq` (no `echo_wire`, no
`keyspace.ex` grammar edit, no `admin.ex` edit, no Lua-attribute edit); the boundary grep empty; the empty
`git diff` of every `Script.new/2` attribute.

### Stage 2 — Director: solo review (a REAL pass)

A fresh-gate reconcile + an independent gate re-run on Valkey 6390 + ≥1 adversarial probe: the **no-shipped-script-edit**
probe (`git diff` of **every** `@… Script.new/2` attribute in `jobs.ex` + `flows.ex` — **all 15 as-built**: the 8
state-machine/flow scripts `@enqueue`/`@claim`/`@complete`/`@retry`/`@promote`/`@reap`/`@schedule`/`@enqueue_flow`
**plus** the 7 emq.2.x mutation scripts `@update_data`/`@update_progress`/`@add_log`/`@remove_job`/`@reprocess`/
`@extend_lock`/`@extend_locks` — **empty**; the NORMAL-risk headline); the **purity** probe (a double-read
of `children_values/3` + `dependencies/3` leaves the `:dependencies` count + `:processed` contents
byte-identical — INV2); the **O1-closed** probe (two children completed with distinct results → `children_values/3`
returns the results, not the child ids — INV5); the **byte-unchanged** probe (the 45 prior conformance scenarios
byte-identical; the non-flow `complete` path unchanged — INV3); a mutation spot-check (Edit-in → `flow_children_values`
catches it → revert by **inverse Edit** → `git diff --stat` clean, net-zero, LAW-1a; **NEVER `git checkout` in a
dirty tree** — the emq.3.1 L-3 footgun). Produce the REMEDIATE list. **Apollo decision:** confirm NORMAL-risk
(no shipped-script edit) → Apollo NOT required; spawn it only if the O2 fold (N2) was taken and reached the
claim path.

### Stage 3 — Mars-2 (implementor, harden + the full gate ladder)

Resume the Stage-1 Mars (one identity, two passes). Directive: remediate; run the full ladder — toolchain
re-probe (`asdf current erlang`) + Valkey 6390 PONG; per-app pure + `:valkey` suites (`TMPDIR=/tmp`, NEVER
umbrella-wide; `--include valkey` for the read suite); `Conformance.run/2 → {:ok, N}` with the prior set
byte-unchanged + `flow_children_values` probe-registered; the **≥100-iteration determinism loop** over the
mint/process-touching read scenario (a flow minting N+1 ids, fanned in, then read; the loop OWNS the machine,
tee to a file, report from the file); the **byte-unchanged Lua proof** (`git diff` of every `Script.new/2`
attribute empty); coverage tabled with the reason for any gap. REMEDIATE loop MAX 3. Gate: every ladder item
PASS or explained; the conformance tally clean; the boundary grep empty; the empty Lua-attribute `git diff`.

### Stage 4 (CONDITIONAL) — Apollo (evaluator) — OPTIONAL (NORMAL-risk)

emq.3.2 is NORMAL-risk (no shipped-script edit), so Apollo is **not mandatory**. The Director MAY spawn Apollo
if a Stage-2/3 finding elevates the rung (e.g. the O2 fold reached the claim path, or a read turned out to
mutate). If spawned (the §11.2 charter): re-run the gate ladder + the ≥100 loop **independently**; adversarially
verify — the **no-shipped-script-edit** proof (the empty Lua-attribute `git diff` — the NORMAL-risk evidence);
the **purity** (the reads effect no state change — INV2); the **O1-closed** result read (INV5); the
**byte-unchanged conformance** with `flow_children_values` probe-registered; an un-prompted finding + an
attack-that-held + a mutation kill-rate. Render BUILD-GRADE / BLOCKED. **If NOT spawned:** the Director's
Stage-2 solo review + Mars-2's independent ladder are the gate (the NORMAL-risk default).

### Stage 5 — Venus (architect): the post-build reconcile

Sync the triad body to the as-built surface (the `EchoMQ.Flows.children_values/3`/`dependencies/3` real arities
+ return shapes; the `complete`'s real result-arg form — `complete/5` or a `result:` opt; the final conformance
N; the ruled Fork arms); every triad claim MATCH or `[RECONCILE]`-marked; fold the parity proof
([`../emq.features.md`](../../../emq.features.md) Part B) to advance the `flow_producer → emq.3` row for the
child-result-read parity (the cross-queue/failure/bulk parts stay 📋 to emq.3.3–3.4 — the honest bound). Confirm
**O1 is CLOSED** in the body (the `:processed` value is the real result under R1·B) and the **N1 lifecycle carry
is NAMED**, not discovered.

### Stage 6 — Director: closure + ONE LAW-4 commit + the frontier fold

Preconditions (x-mode §4): the gate green + the reconcile build-grade (+ Apollo BUILD-GRADE iff spawned);
**≥1 `tool_x_decision` (D-n)** + a **`tool_x_complete` (Z-n)** this turn; `git status --short` AND `git diff
--cached --name-only` reviewed; `.git/rebase-merge`/`rebase-apply` checked. Then the **pathspec** commit (below;
NEVER `git add -A`, NEVER a bare commit). **Same turn:** flip the emq.3.2 row in the single roadmap
([`../emq.roadmap.md`](../../../emq.roadmap.md)) and the dashboard ([`../emq.progress.md`](../../../emq.progress.md)); record
**O1 closed** + the **N1 lifecycle carry** still open (routed to the emq.3.x lifecycle rung); surface the **next
frontier** (emq.3.3 cross-queue once Fork A's cross-queue arm is designed, or emq.3.4 failure-policy + bulk);
under an **explicit Operator grant only**, fold any mentoring diff into the peer charters / the echo-mq-* skills
(one guardrail per finding). The message cites the slug, the Z-n, the D-n, and the Y-n report.

## Risk tier

emq.3.2 is **NORMAL-risk** — the inverse of emq.3.1's HIGH-risk. The two elevated dimensions emq.3.1 carried are
**absent** here: **(a)** emq.3.2 edits **no shipped Lua script** (Fork R1·B is host-only — the `@complete` Lua
already writes `ARGV[5]`, only the host-supplied value changes; the two reads are pure), so the
shipped-`@complete`-edit dimension is gone (the mitigating gate is the **empty `git diff` of every `Script.new/2`
attribute** — the NORMAL-risk proof itself). **(b)** emq.3.2 does **not mint** ids (the reads stand on a flow
emq.3.1 already minted), but a read scenario constructs a flow (which mints N+1 ids), so the **≥100 determinism
loop** over the read scenario is retained as the residual mint-touching gate. **Apollo is OPTIONAL** — neither
dimension qualifies it as mandatory; the Director's solo review + Mars-2's independent ladder are the gate. The
single highest-leverage property is the **no-shipped-script-edit** invariant (INV1/INV3): it is both the source
of the NORMAL-risk tier and its proof.

## The Stage-6 commit pathspec (Director-only — the emq.3.2 BUILD)

Commit exactly the rung's measured surface (the build run's actual touch-set is authoritative — adjust to what
the stages truly changed):

```text
docs/echo_mq/specs/emq.3.2.md                 (the contract)
docs/echo_mq/specs/emq.3.2.stories.md
docs/echo_mq/specs/emq.3.2.llms.md
docs/echo_mq/specs/emq.3.2.prompt.md          (this runbook)
docs/echo_mq/specs/emq-3-2.progress.md
docs/echo_mq/specs/emq-3-2.registry.json      (if the run mints one)
docs/echo_mq/emq.features.md                  (the flow row → advance for the child-result-read parity)
docs/echo_mq/emq.roadmap.md                   (the emq.3.2 row → shipped)
docs/echo_mq/emq.progress.md                  (the dashboard fold)
echo/apps/echo_mq/lib/echo_mq/flows.ex        (children_values/3 + dependencies/3 — the two pure reads)
echo/apps/echo_mq/lib/echo_mq/jobs.ex         (complete + the result arg — HOST ONLY; the @complete Lua byte-unchanged)
echo/apps/echo_mq/lib/echo_mq/conformance.ex  (flow_children_values, additive)
echo/apps/echo_mq/test/                        (flow_children_values + the conformance pins)
```

**EXCLUDE** (Operator out-of-band — never sweep into the rung commit):
`echo/apps/live_svelte/**`, `echo/apps/mercury_cms/**`, `echo/apps/mercury_live_admin/**`, `html/**`, the F#
course, and any `[emq]`/`[bcs]`/`[mercury]` doc commits the Operator lands between stages.
`echo/apps/echomq` (frozen v1 — the capability reference) + `echo/apps/echo_wire` (the reads ride the shipped
connector) + `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` (no grammar edit) + `echo/apps/echo_mq/lib/echo_mq/admin.ex`
(the L-5/N1 lifecycle carry — NOT this rung) + `echo/mix.lock` (emq.3.2 adds no dep — expect `mix.lock`
EXCLUDED) UNTOUCHED. **Never `git add -A`.**

## Acceptance — "shipped" + "O1 closed" means

Every DoD box in [`./emq.3.2.md`](emq.3.2.md) is checkable from the run's outputs: Fork R1 ruled + recorded
before any artifact (D1); `EchoMQ.Flows.children_values/3` (D2 — the result map keyed by child id, the empty-parent
case, the gated id); `EchoMQ.Flows.dependencies/3` (D3 — the outstanding count, the honest none-key sentinel,
the gated id); the real-result-carrying completion (D4 — `complete` + the result arg; the `@complete` Lua
byte-unchanged; the non-flow completion byte-unchanged; O1 closed); the flow-subkey lifecycle disposition NAMED
+ no cleanup added (D5); `flow_children_values` additive-minor with the prior 45 byte-unchanged + the count
re-pinned in both pin tests (D6/INV6); the ≥100 loop green for the mint/process-touching read scenario + the
prior emq.1 + emq.2.{1,2,3,4} + emq.3.1 suites unchanged + the **empty `git diff` of every `Script.new/2`
attribute** (NORMAL-risk proven). The spec body stays authoritative; Stage 5 syncs it to the as-built surface;
**O1 is closed** and the **N1 lifecycle carry** is named (routed to the emq.3.x lifecycle rung).

Inputs: [`./emq.3.2.md`](emq.3.2.md) · [`./emq.3.2.stories.md`](emq.3.2.stories.md) ·
[`./emq.3.2.llms.md`](emq.3.2.llms.md) · Family: [`./emq.3.md`](../emq.3.md) (the carve + the forks) · The
first slice (SHIPPED): [`./emq.3.1.md`](emq.3.1.md) + [`./emq.3.1.prompt.md`](emq.3.1.prompt.md) (the
HIGH-risk runbook this NORMAL-risk one mirrors) · Canon: [`../emq.design.md`](../../../emq.design.md) §11.10/§6/§5/S-6
· Roadmap: [`../emq.roadmap.md`](../../../emq.roadmap.md) Movement I · The feature catalog:
[`../emq.features.md`](../../../emq.features.md) (the emq.3 row) · Skills: `.claude/skills/echo-mq-ship.md` (the
binding) + `echo-mq-{architect,implementor,evaluator}.md` (the per-role craft) + `echo-mq-program.md` (the
program law) · Approach: [`../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
