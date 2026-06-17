# EMQ.3.1 · the build orchestration runbook — ship the single-queue flow (the flow family opens)

> **Status: SPECCED, the runbook ready (authored at the `emq-3` design cycle).** This runbook drives the
> **emq.3.1** build — the FIRST sub-rung of the parent/flow family (the single-queue flow) — the rung that
> **opens Movement I's close** (the emq.2 parity cluster closed; emq.3 is the last Movement-I parity surface).
> The `/x-mode` skill ([`.claude/skills/x-mode/SKILL.md`](../../../../../.claude/skills/x-mode/SKILL.md)) binds the
> laws; the **`echo-mq-ship`** skill is the echo_mq binding (Venus loads `echo-mq-architect`, Mars loads
> `echo-mq-implementor`, Apollo loads `echo-mq-evaluator`); the inputs are the triad
> ([`./emq.3.1.md`](emq.3.1.md) · [`./emq.3.1.stories.md`](emq.3.1.stories.md) ·
> [`./emq.3.1.llms.md`](emq.3.1.llms.md)), the family ([`./emq.3.md`](../../emq.3.md) — the A-1 flow design + the
> carve + the THREE forks), and the canon ([`../emq.design.md`](../../../emq.design.md) §11.10/§6/§5/S-6/§11.12).

## The family in one paragraph

emq.3 is the parent/flow family — the v1 `flow_producer` capability redesigned so a parent becomes claimable
only when its children complete (fan-in), **under the v2 A-1 declared-keys law** (the design work design §11.10
named as owed). The v1 form roots the parent→child link in **data values** (`parent_key` built from a
data-value `job_id`, stuffed into each child's hash) and **spans queues** — two structural violations of the
A-1 law and the braced keyspace. The redesign carries the dependency graph in **declared §6 subkeys of the
parent** (`emq:{q}:job:<parent>:dependencies` + `:processed`/`:failed`/`:unsuccessful` — subkeys the founding
**reserved** at §6 for exactly this), each rooted at the parent's declared job key, on the parent's `{q}` slot,
A-1-clean by construction. The family carves into emq.3.1 (single-queue) · 3.2 (child-result reads) · 3.3
(cross-queue) · 3.4 (failure-policy + bulk). The full design + the three surfaced forks are
[`./emq.3.md`](../../emq.3.md).

## The rung in one paragraph

emq.3.1 carves the **single-queue flow** — a parent + its children **in one queue** (one slot → every flow
script **atomic**), the smallest coherent slice that founds the WHOLE A-1-compatible mechanism. It builds,
inside `echo/apps/echo_mq` under the v2 laws (declared keys, branded `JOB`, the `EMQ*` refusals, the inline
`Script.new/2` law, the conformance additive-minor): **(1)** `EchoMQ.Flows.add/3` + the inline `@enqueue_flow`
(a parent + same-queue children enqueued atomically — the children claimable, the parent withheld from
`pending` with its outstanding-child count in `:dependencies` and its row `state = awaiting_children`); **(2)**
a **fan-in hook** folded into the shipped `EchoMQ.Jobs.@complete` (decrement the parent's count idempotently on
each child completion; at zero release the parent to `pending` + record the child result in `:processed`) — the
ONE shipped-script edit; **(3)** the `awaiting_children` row state in `Metrics.get_job_state/3`; **(4)** the
conformance scenarios `flow_add` + `flow_fanin` (additive minor, the prior set byte-unchanged); **(5)** the
`:valkey`/process suites + the ≥100 loop. The non-flow path is **byte-unchanged**; the shipped `@claim` is
**untouched** (the gate is the parent's absence from `pending`). The honest **Out**: cross-queue (emq.3.3), deep
recursion, child-result reads (emq.3.2), failure policy + bulk (emq.3.4) — and the dead-child limit (a dead
child does not decrement, documented). The contract is [`./emq.3.1.md`](emq.3.1.md) (D1–D6, INV1–INV9).

## Mode

**Flat-L2** (a build + a gate + a verify), Director-supervised. **Not** the Design-Phase variant (the triad
exists — authored this cycle). **HIGH-RISK**: emq.3.1 **edits a shipped script** (the `@complete` fan-in hook)
**and** is **mint-touching** (a flow mints N+1 ids per call — the same-ms collision surface) → **Apollo
MANDATORY** (the §11.2 charter + `AskUserQuestion`) + the **≥100-iteration determinism loop** over the
mint/process-touching flow suite.

Scope slug: **`emq-3-1`** (dashed, no dots — `tool_x_*`/`TeamCreate` require `^[a-z0-9][a-z0-9-]*$`). Operator:
`jonny`. Workspace: `/Users/jonny/dev/jonnify`. Ledger: `docs/echo_mq/specs/emq-3-1.progress.md` (the build run
opens it; the `emq-3` design-cycle ledger `docs/echo_mq/specs/emq-3.progress.md` carries the design half — T-1
the ground truth, the Venus-3-1 family-triad + emq.3.1 authoring, the forks surfaced; records-freeze on the
design half).

## The fork gate — Fork A MUST be ruled before the build (EMQ.3.1-D1)

**emq.3.1 does not build until the Operator rules Fork A.** The family body ([`./emq.3.md`](../../emq.3.md)) surfaces
three forks; the triad is authored to the recommended arms (A·A, B·counter+guard, C·`awaiting_children`).

> **FORK A (the headline — GATES the build) — the flow SHAPE.** Single-queue-first (Arm A, recommended: the
> same-queue flow on one slot → every script atomic; cross-queue is emq.3.3 over a completion-signal sweep,
> eventually-consistent) vs cross-queue-from-emq.3.1 (Arm B: a host-orchestrated NON-atomic fan-in, a crash
> window that itself needs a recovery sweep). **Nothing in the build runs until Fork A is ruled.** Arm A → the
> build is the single-queue slice this triad is authored to; Arm B → emq.3.1 re-scopes to the cross-queue shape
> (a larger, non-atomic first slice) before the build.
>
> **FORK B (a cheap pre-build re-scope) — the dependency representation.** A decrementing STRING counter (Arm 1,
> recommended: O(1), minimal) vs a children-id SET (Arm 2: idempotent-for-free). RECOMMEND the counter **with
> the double-complete idempotency guard as a BUILD requirement either way** (a child must decrement the parent
> exactly once — gate the `DECR` on the child's own `active`→done transition succeeding). String-vs-set is not a
> grammar change.
>
> **FORK C (a cheap pre-build re-scope) — the parent's waiting state.** A new `awaiting_children` row state
> (Arm 1, recommended: honest — a flow parent is released by fan-in, not time, and is not on `schedule`) vs
> reuse `scheduled` (Arm 2: a read-plane lie + risks the promote pump treating it as stuck).

If the launch review finds Fork A needs a fuller ADR than the family body's surfacing, that is a design-make
stage the Operator inserts — flagged, not pre-built. Forks B/C are representation re-scopes (surface, do not
block the build).

## The as-built floor (verified at the `emq-3` design cycle, 2026-06-14 — the build's Stage-0 RE-PROBES each;
the lag-1 law)

Anchors drift; the emq.2 cluster's commits (and any sibling rung) moved the `echo_mq` surface before emq.3.1
reads it — the build's Stage-0 reconcile re-pins every line below:

- **The conformance count** — `conformance.ex` `scenarios/0` (the emq.2 cluster grew it **18 → 43** across
  emq.2.1/2.2/2.3/2.4 — emq.2.4 shipped the +6 depth scenarios, 37 → 43; re-probe the LIVE count at Stage 0 —
  do NOT hardcode 43; the floor is whatever exists at the pre-build reconcile; the two pin tests
  `conformance_run_test.exs` `run/2 → {:ok, N}` + `conformance_scenarios_test.exs` the N names).
- **`@enqueue` (the shape to model `@enqueue_flow` on)** — `jobs.ex` `@enqueue` (the kind law FIRST act
  `string.sub(ARGV[1],1,3) ~= 'JOB'` → `EMQKIND`; the `EXISTS` guard; `HSET` row `state/attempts/payload`;
  `ZADD` `pending`; `KEYS[1]=job row`, `KEYS[2]=pending`). `Jobs.enqueue/4`.
- **`@complete` (the fan-in hook host)** — `jobs.ex` `@complete` (the `was_active = ZREM KEYS[1] ARGV[1]` guard;
  the `p` base-derivation of lane keys; `DEL KEYS[2]` retires the row; the metrics counter). The fan-in branch
  conditions on the child carrying a parent ref + uses the `was_active`-style guard for the idempotent
  decrement. `Jobs.complete/4`.
- **`@extend_locks` (the A-1 derivation precedent)** — `jobs.ex` `@extend_locks` (`local jk = base .. 'job:' ..
  id`; ids gated host-side at `Jobs.extend_locks/4` before the wire). The declared-root in-script derivation
  `@enqueue_flow` extends.
- **`add_log/5` (the subkey-compose precedent)** — `jobs.ex` `Keyspace.job_key(queue, job_id) <> ":logs"`. The
  flow subkeys compose the same way (`<> ":dependencies"`, `<> ":processed"`) — already-registered §6 subkeys,
  no new key type.
- **`Keyspace.job_key/2`** — `keyspace.ex` (gates `BrandedId.valid?/1`, RAISES on an ill-formed id — INV6),
  `queue_key/2`.
- **`Metrics.get_job_state/3`** — `metrics.ex` (the state-set membership the `awaiting_children` value threads
  into — D4/Fork C; re-pin the as-built state set).
- **The v1 capability reference (READ, never edit, the FORM not lifted)** —
  `echo/apps/echomq/lib/echomq/flow_producer.ex` (`add/2`; the data-value `parent_key`/`parent_info` tree NOT
  lifted) + the dependency-subkey names at
  `echo/apps/echomq/priv/scripts/moveToFinished-15.lua:140-141`.

## The pipeline — the HIGH-RISK flow (Venus → Mars-1 → Director review → Mars-2 → **Apollo** → Director ship)

Each spawned stage is a real `general-purpose`/dedicated `Agent` that adopts its `.claude/agents/<role>.md`
charter, LOADS its `echo-mq-<role>` skill, and self-registers via `mcp__aaw__*` (LAW-1; no narrated spawns). The
Director holds the gate between stages. The per-spawn contract is the `/x-mode` skill §3 (Framing → adopt
charter → aaw ceremony → the stage block → audit directive → propagation clause → report). **Require
artifact-level checkpoints** (SendMessage a concrete report after each pass; the Director's ground-truth
verification is the gate, not the self-verdict).

### Stage 0 — Venus (architect): the pre-build reconcile + the fork-settlement gate

Directive: run the lag-1 reconcile (re-probe every anchor above against the post-emq.2.4-commit tree; re-pin the
conformance count + the `@enqueue`/`@complete`/`@extend_locks`/`add_log` shapes + `job_key/2` + the `Metrics`
state set + the v1 reference). Confirm **Fork A is Operator-ruled** (EMQ.3.1-D1) and **re-derive the triad to
the ruled arm** (Arm A → single-queue; Arm B re-scopes to cross-queue); note Forks B/C's recorded recommendations
(counter+guard; `awaiting_children`). Bring the triad to as-built truth where a cluster commit moved an anchor;
mark each delta MATCH-or-`[RECONCILE]`. Gate: the reconcile delta table; the Fork A ruling recorded; the triad
re-derived; the BUILD-GRADE / BLOCKED verdict.

### Stage 1 — Mars-1 (implementor): build the single-queue flow

Directive: after Fork A is ruled, build EMQ.3.1-D2 → D6 to the brief's agent stories (AS1–AS4) and the design.
The order: (1) `@enqueue_flow` (the inline script — model on `@enqueue`'s kind-law/declared-keys shape) +
`EchoMQ.Flows.add/3` (the host API — mint + gate every id at `Keyspace.job_key/2`, reject a cross-queue child);
(2) the `@complete` fan-in hook (the conditioned branch + the idempotent decrement gated on `was_active` + the
at-zero `ZADD pending` + the `:processed` `HSET`) — the ONE shipped-script edit; (3) the `awaiting_children`
state in `metrics.ex`; (4) `flow_add` + `flow_fanin` in `conformance.ex` + the count re-pin in both pin tests;
(5) the `:valkey`/process suites. Cite the spec/design line for every public call; **declared keys** (every key
in `@enqueue_flow` + the `@complete` hook in `KEYS[]` or rooted — the A-1 lint; NO key read from a data value —
INV2); **inline `Script.new/2`** (no `priv/`); **the kind law FIRST** in `@enqueue_flow` (`EMQKIND`); register
the conformance scenarios + probes **in the same change** (INV7, the additive-minor law; the prior set
byte-unchanged; re-pin the count in both pin tests); compile clean (`--warnings-as-errors`, per-app). **INV3
gate**: the non-flow `@complete` path + the `@claim`/`@enqueue` byte-unchanged. Gate: per-app compiles green;
D2–D6 exist; the diff stays inside `echo_mq` (no `echo_wire`, no `keyspace.ex` grammar edit); the boundary grep
empty.

### Stage 2 — Director: solo review (a REAL pass)

A fresh-gate reconcile + an independent gate re-run on Valkey 6390 + ≥1 adversarial probe: the **declared-keys**
F-1 probe on `@enqueue_flow` + the `@complete` hook (every key declared/rooted; no hash-field-to-key derivation
— the v1 form not lifted); the **fan-in soundness** probe (claim the parent → `:empty` until the Nth child, then
claimable); the **idempotency** probe (a double-complete drops the count by exactly 1 — INV5); the **byte-unchanged**
probe (`git diff` of `@enqueue`/`@claim` empty; the 43 prior conformance scenarios byte-identical); a mutation
spot-check (Edit-in → `flow_fanin` catches it → revert → `git diff --stat` clean, net-zero, LAW-1a). Produce the
REMEDIATE list.

### Stage 3 — Mars-2 (implementor, harden + the full gate ladder)

Resume the Stage-1 Mars (one identity, two passes). Directive: remediate; run the full ladder — toolchain
re-probe (`asdf current erlang`) + Valkey 6390 PONG; per-app pure + `:valkey` + process suites (`TMPDIR=/tmp`,
NEVER umbrella-wide; `--include valkey` for the flow suites); `Conformance.run/2 → {:ok, N}` with the prior set
byte-unchanged + `flow_add`/`flow_fanin` probe-registered; the **≥100-iteration determinism loop** over the
mint/process-touching flow suite (`flow_fanin` — the multi-id mint + the fan-in across completions; the loop
OWNS the machine, tee to a file, report from the file); the dead-child limit test (a flow with a dead child
leaves the parent `awaiting_children` — INV9, the honest bound); coverage tabled with the reason for any gap.
REMEDIATE loop MAX 3. Gate: every ladder item PASS or explained; the conformance tally clean; the boundary grep
empty.

### Stage 4 — Apollo (evaluator) — MANDATORY (high-risk)

Directive (the §11.2 charter): post-build reconcile (as-built ⇄ spec); re-run the gate ladder + the ≥100 loop
**independently**; adversarially verify — the **order theorem** (byte = mint across the N+1 flow mints; two
distinct ids minimum per flow); the **declared-keys** grep on `@enqueue_flow` + the `@complete` hook (the F-1
class — no data-value rooting); the **fan-in soundness** (the parent claimable IFF `:dependencies` = 0; INV4);
the **idempotent-decrement** under a redelivered child (INV5); the **byte-unchanged conformance** with each new
scenario probe-registered; the **shipped-`@complete`/`@claim`/`@enqueue` re-verification** (INV3 — the non-flow
path byte-unchanged across the edit). Render **BUILD-GRADE / BLOCKED**; an un-prompted finding + an
attack-that-held + a mutation kill-rate; `AskUserQuestion` to keep it shippable. Fold findings forward as
mentoring (Director-ratified).

### Stage 5 — Venus (architect): the post-build reconcile

Sync the triad body to the as-built surface (the `EchoMQ.Flows` real arities; the `@enqueue_flow`/`@complete`-hook
real key declarations; the ruled Fork arms; the final conformance N); every triad claim MATCH or
`[RECONCILE]`-marked; fold the parity proof ([`../emq.features.md`](../../../emq.features.md) Part B) to flip the
`flow_producer → emq.3` row from 📋 toward ✅ for the single-queue slice (the cross-queue/reads/policy parts stay
📋 to emq.3.2–3.4 — the honest bound).

### Stage 6 — Director: closure + ONE LAW-4 commit + the family-open fold

Preconditions (x-mode §4): Apollo BUILD-GRADE (or its REMEDIATE items closed) + the gate green + the reconcile
build-grade; **≥1 `tool_x_decision` (D-n)** + a **`tool_x_complete` (Z-n)** this turn; `git status --short` AND
`git diff --cached --name-only` reviewed; `.git/rebase-merge`/`rebase-apply` checked. Then the **pathspec**
commit (below; NEVER `git add -A`, NEVER a bare commit). **Same turn:** flip the emq.3.1 row in the single
roadmap ([`../emq.roadmap.md`](../../../emq.roadmap.md)) and the dashboard ([`../emq.progress.md`](../../../emq.progress.md));
record **the flow family OPEN** (emq.3.1 the single-queue slice shipped; 3.2–3.4 next); surface the **next
frontier** (emq.3.2 child-result reads, or emq.3.3 cross-queue once Fork A's cross-queue arm is designed, or the
Movement-II open if the Operator closes Movement I here); under an **explicit Operator grant only**, fold any
mentoring diff into the peer charters / the echo-mq-* skills (one guardrail per finding). The message cites the
slug, the Z-n, the D-n, and the Y-n report.

## Risk tier

Two elevated dimensions the high-risk pipeline mitigates: **(a) the shipped-`@complete` edit** — the fan-in hook
folds a conditioned branch into a shipped transition; the mitigating gate is Apollo's **INV3 re-verification**
(the non-flow path + `@claim`/`@enqueue` byte-unchanged across the edit) + the byte-unchanged conformance.
**(b) mint-touching** — a flow mints N+1 ids per call (the same-ms branded-id collision surface; one green run
is not proof); the mitigating gate is the **≥100 determinism loop** over `flow_fanin` + Apollo's independent
re-run + the order theorem (byte = mint across the flow mints). Apollo is MANDATORY (either dimension qualifies).

## The Stage-6 commit pathspec (Director-only — the emq.3.1 BUILD)

Commit exactly the rung's measured surface (the build run's actual touch-set is authoritative — adjust to what
the stages truly changed):

```text
docs/echo_mq/specs/emq.3.md                   (the family contract + carve + forks)
docs/echo_mq/specs/emq.3.stories.md
docs/echo_mq/specs/emq.3.llms.md
docs/echo_mq/specs/emq.3.1.md
docs/echo_mq/specs/emq.3.1.stories.md
docs/echo_mq/specs/emq.3.1.llms.md
docs/echo_mq/specs/emq.3.1.prompt.md          (this runbook)
docs/echo_mq/specs/emq-3-1.progress.md
docs/echo_mq/specs/emq-3-1.registry.json      (if the run mints one)
docs/echo_mq/emq.features.md                  (the flow row → ✅ for the single-queue slice)
docs/echo_mq/emq.roadmap.md                   (the emq.3.1 row → shipped; the family OPEN)
docs/echo_mq/emq.progress.md                  (the dashboard fold)
echo/apps/echo_mq/lib/echo_mq/flows.ex        (NEW — EchoMQ.Flows + @enqueue_flow)
echo/apps/echo_mq/lib/echo_mq/jobs.ex         (the @complete fan-in hook — the ONE shipped-script edit)
echo/apps/echo_mq/lib/echo_mq/metrics.ex      (the awaiting_children state-set membership)
echo/apps/echo_mq/lib/echo_mq/conformance.ex  (flow_add + flow_fanin, additive)
echo/apps/echo_mq/test/                        (flow_add + flow_fanin + the dead-child limit + the conformance pins)
```

**EXCLUDE** (Operator out-of-band — never sweep into the rung commit):
`echo/apps/live_svelte/**`, `echo/apps/mercury_cms/**`, `echo/apps/mercury_live_admin/**`, `html/**`, the F#
course, and any `[emq]`/`[bcs]`/`[mercury]` doc commits the Operator lands between stages.
`echo/apps/echomq` (frozen v1 — the capability reference) + `echo/apps/echo_wire` (the flow rides the shipped
connector) + `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` (no grammar edit) + `echo/mix.lock` (emq.3.1 adds no
dep — expect `mix.lock` EXCLUDED) UNTOUCHED. **Never `git add -A`.**

## Acceptance — "shipped" + "the flow family opened" means

Every DoD box in [`./emq.3.1.md`](emq.3.1.md) is checkable from the run's outputs: Fork A ruled + recorded
before any artifact (D1); `EchoMQ.Flows.add/3` + `@enqueue_flow` (D2 — N+1 distinct gated ids, children
claimable, the parent `awaiting_children` + withheld, a cross-queue child rejected); the `@complete` fan-in hook
(D3 — the idempotent decrement + the at-zero release + the `:processed` record; the non-flow path
byte-unchanged; `@claim` untouched); the `awaiting_children` state (D4); `flow_add` + `flow_fanin` additive-minor
with the prior set byte-unchanged + the count re-pinned in both pin tests (D5); the ≥100 loop green for the
mint/process-touching flow suite + the prior suites unchanged + the dead-child limit documented + **Apollo
BUILD-GRADE** (D6). The spec body stays authoritative; Stage 5 syncs it to the as-built surface; the family
(emq.3.2–3.4) opens on a proven single-queue core.

Inputs: [`./emq.3.1.md`](emq.3.1.md) · [`./emq.3.1.stories.md`](emq.3.1.stories.md) ·
[`./emq.3.1.llms.md`](emq.3.1.llms.md) · Family: [`./emq.3.md`](../../emq.3.md) (the A-1 flow design + the carve +
the forks) · Canon: [`../emq.design.md`](../../../emq.design.md) §11.10/§6/§5/S-6/S-1/§11.12 · Roadmap:
[`../emq.roadmap.md`](../../../emq.roadmap.md) Movement I · The feature catalog: [`../emq.features.md`](../../../emq.features.md)
(the emq.3 row) · The shape model: [`../emq.2/emq.2.prompt.md`](../../emq.2/emq.2.prompt.md) (the emq.2.4 cluster-closer runbook)
· Skills: `.claude/skills/echo-mq-ship.md` (the binding) + `echo-mq-{architect,implementor,evaluator}.md` (the
per-role craft) + `echo-mq-program.md` (the program law) · Approach:
[`../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
