# EMQ.2.1 · the x-mode orchestration runbook — the read plane (the parity cluster opens)

> **Status: SPECCED — the runbook for the emq.2.1 build run (a later session).** emq.2.1 is the first rung
> of the emq.2 **full-parity cluster** (the carve: [`./emq.2.design.md`](../emq.2.design.md)): the bus's
> read plane — introspection, metrics, the rate-limit read-and-gate — ported from the v1 `echomq` read API
> onto `echo_mq`'s as-built structures, never migrated from. The pipeline mirrors the emq.1 runbook (the
> proven five-stage shape), with the one open sequencing fork (design §6 — does the Operator keep the
> cluster to the floor, Arm A, or pull the feature families in, Arm B) settled BEFORE Stage 1. The x-mode
> skill ([`.claude/skills/x-mode/SKILL.md`](../../../../../.claude/skills/x-mode/SKILL.md)) binds the laws; its
> inputs are the spec triad ([`./emq.2.1.md`](emq.2.1.md) · [`./emq.2.1.stories.md`](emq.2.1.stories.md)), the carve ADR, and the canon ([`../emq.design.md`](../../../emq.design.md)).

## The rung in one paragraph

emq.2.1 builds the bus's **read plane**: pure-read verbs over `echo_mq`'s as-built structures
(`pending`/`active`/`schedule`/`dead` + the registered metrics keys) — counts by state, job + state
lookup, completed/failed throughput, the dedup read, and the rate-limit read + at-ceiling gate. The
capability reference is the frozen v1 `EchoMQ.Queue` read API + its read scripts (`getCounts`/`getState`/
`getMetrics`/`getRateLimitTtl`/`isMaxed`); emq.2.1 re-derives those capabilities against `echo_mq`'s real
keyspace — NOT the v1 state names (the bus has four sets, no `completed` set under completion-deletes). The
reads observe state and never change it (the state machine is emq.1's); the rate gate is a read-and-refuse
with an `EMQ*` class. The contract is [`./emq.2.1.md`](emq.2.1.md) (D1–D8, INV1–INV7); the carve it
opens is [`./emq.2.design.md`](../emq.2.design.md) ADR-1.

## Mode

**Flat-L2** (a build + a gate + a verify), Director-supervised — the emq.1 five-stage shape: **Mars-1
(design-make + build) → solo Director review → Mars-2 (remediate + harden + test) → Venus (specs
reconcile) → Director (closure + one post-closure commit)**. **Not** the Design-Phase variant (the system
spec and the carve already exist). The risk profile is low (a bus-internal read rung on the local Valkey
substrate; no auth/deploy/network surface; no new process; no state transition) — a solo Director review
is the rigor floor, recovered by a real reconcile-plus-gate-plus-adversarial Stage 2 + Venus's independent
Stage 4. **An Apollo charter is NOT required** at this risk tier (x-mode §11.3).

Scope slug: **`emq-2-1`** (dashed, no dots — `tool_x_*` and `TeamCreate` require `^[a-z0-9][a-z0-9-]*$`).
Operator: `jonny`. Workspace: `/Users/jonny/dev/jonnify`. Ledger: `docs/echo_mq/specs/emq-2-1.progress.md`.

## The pre-Stage-1 gate (the surfaced fork — Operator's call)

Before Stage 1, the design §6 sequencing fork must be ruled: **Arm A** (recommended — the parity cluster
fills the read/ops/observability floor; emq.3–emq.8 keep their confirmed slots) or **Arm B** (pull
flows/groups-deepened/batches into the cluster, re-sequence emq.3+). This triad is authored to **Arm A**;
an Arm-B ruling is a cheap roadmap edit before this build. The Director confirms the ruling with the
Operator and records it; nothing builds until it is ruled.

## The design-make — the relocated gate (what Mars-1 adopts, not re-litigates)

Mars-1 **adopts the carve** ([`./emq.2.design.md`](../emq.2.design.md) ADR-1: emq.2.1 = the read plane,
first) and rules the two build-shaping decisions the spec leaves to D1, logging each as a
`tool_x_decision`:

1. **Module placement** → recommended: a new `EchoMQ.Metrics` (a cohesive read surface). The alternative
   (read verbs folded onto `EchoMQ.Jobs`/`EchoMQ.Lanes`) is steelmanned and chosen-against unless the
   build finds a reason; record ≥2 alternatives either way.
2. **The counts contract** → the read answers the as-built state set `pending`/`active`/`schedule`/`dead`
   (+ the metrics counter for "completed"), NOT the v1 `getCounts` list. An unregistered state name errors
   (the §6 closed-registry discipline).
3. **The metrics-counter write** → probe whether a completion/dead transition already maintains a counter.
   If yes, `get_metrics` reads it. If no, rule the minimal additive counter write — land it here (a small,
   additive write the completion/dead scripts gain) or flag it to emq.2.2 — but **read no metric that is
   not written** (INV2's no-phantom-counter).
4. **The rate-gate class word** → spell the `EMQ*` class for the at-ceiling refusal against §5 (e.g.
   `EMQRATE`); register it with its conformance probe in the same change; leave the five-code fence union
   unextended.

**Carried, not re-litigated:** the rung is the read plane (the carve); the structures are the as-built
four sets; the v1 read API is a capability reference, never migrated from. If the Stage-2 review finds an
adopted decision unsound, it is the Director's gate to send Mars back or escalate — not to ship it.

## The as-built floor (RE-PROBE at build time — the lag-1 law)

Every anchor below is probed against the as-landed tree (anchors drift after the emq.1 + emq.2-cluster
builds; Mars-1 RE-PROBES each):

- `EchoMQ.Jobs` — the three-field row + the four sets `pending`/`active`/`schedule`/`dead`
  (`echo/apps/echo_mq/lib/echo_mq/jobs.ex`); `complete/4` retires the row everywhere (**no `completed`
  set**).
- `EchoMQ.Keyspace.job_key/2` — gated by `BrandedId.valid?/1` (`keyspace.ex:18-24`); `queue_key/2` builds
  `emq:{q}:<type>`; the §6 `metrics:`/`de:` suffixes.
- `EchoMQ.Lanes.depth/2` — `lanes.ex:182` (the per-lane introspection's base).
- `EchoMQ.Conformance.scenarios/0` — **18** scenarios (`conformance.ex`); INV1 holds them byte-unchanged.
- The `EchoWire` facade — `echo/apps/echo_wire/lib/echo_wire.ex` (`eval` runs the read scripts); expect no
  facade change.
- **No `echo/apps/echo_mq/priv/` directory** — scripts are inline `Script.new/2` attributes. **emq.2.1
  follows the inline convention, NOT `priv/`.**
- The v1 capability reference — `echo/apps/echomq/lib/echomq/queue.ex` + `priv/scripts/{getCounts-1,
  getState-8,getMetrics-2,getRateLimitTtl-2,isMaxed-2}.lua` (these read v1 state types — port the
  *capability*, not the state list).

## The pipeline — five stages, Director-in-loop

Each spawned stage is a real `general-purpose` Agent that adopts its `.claude/agents/<role>.md` charter
(Mars / Venus) — and, where the build team is echo_mq-specialized, the echo_mq dev skill — and
self-registers via `mcp__aaw__*` (LAW-1; no narrated spawns). The Director holds the gate between stages.
The per-spawn contract is the x-mode skill §3 (Framing → adopt charter → aaw ceremony → the stage block →
audit directive → propagation clause → report).

### Stage 1 — Mars-1 (implementor): design-make + build

Directive (lift into the spawn): **make the read-plane design real and build it.** (a) RE-PROBE every
as-built anchor above (the lag-1 law). (b) Adopt the carve + rule the four design-make decisions above;
log each as a `tool_x_decision` (D-n) citing the design § it adopts; invent no read surface. (c) Build
EMQ.2.1-D2 → D7 to the agent stories — counts over the as-built
sets (D2), job + state lookup gated by `BrandedId.valid?/1` (D3), the metrics read with no phantom counter
(D4), the dedup read (D5), the rate-limit read + the `EMQ*`-classed gate (D6), per-lane introspection over
`Lanes.depth/2` (D7). Every verb a **pure read** (INV2 — the rate gate is a read-and-refuse; no state
transition); the structures the as-built four sets (INV3 — never a v1 state name); every job id gated at
the key builder (INV5); every read script declares its keys in `KEYS[]` or grammar-derives them (INV4);
new scripts follow the inline `Script.new/2` convention. Register a conformance scenario + probe for every
read IN THE SAME CHANGE (INV1, the additive-minor law). Compile clean (`--warnings-as-errors`, per-app).
Report any realization-over-literal clause.

Gate before advancing: per-app compiles green; D2–D7 deliverables exist; the four design-make decisions
logged; the diff stays inside `echo_mq` (`apps/echomq` untouched; no third app touched); the inline-script
convention followed; no state transition added (INV2); the lock-delta law holds. (The full test gate is
Stage 3 — Stage 1 ends at compile-green + deliverables-present + a smoke that the new reads load.)

### Stage 2 — Director (solo review): the relocated charter

The Director reviews Mars-1's design-make + build **from a fresh gate**, not from Mars-1's report
(max-effort = a real verification pass):

- **Reconcile** the build against the carve + the brief: every read verb MATCH / realized-and-logged /
  flagged; the counts contract reads the as-built four sets (NOT the v1 list — the headline INV3 check);
  no metric is read that is not written (INV2); every read key declared-or-grammar-derived (INV4); the
  rate-gate class registered against §5.
- **Run the gate fresh** (per-app, `TMPDIR=/tmp`, Valkey 6390 PONG first): the per-app compiles; a pure
  suite per touched app; the new `:valkey` read scenarios load and the 18 prior ones still enumerate.
- **≥1 adversarial probe** — attack a claimed invariant (e.g. INV3: assert that requesting "completed" as
  a SET name errors / answers from the metrics counter, never from a phantom `completed` set; or INV2:
  confirm a read changes no row by reading counts before and after).
- **A mutation spot-check** on one read (e.g. flip a `ZCARD` to `LLEN` on a sorted-set count, or flip the
  rate-gate `>=` to `>`), confirm a test catches it, then **REVERT by the inverse edit and verify
  `git diff --stat` clean** (the Director's only edit-class action — a net-zero verification probe,
  immediately reverted; the Director authors no production code, LAW-1a).

Gate: the build is faithful to the carve and inside the boundary; the probes hold or the gaps are written
as REMEDIATE items for Stage 3. The Director records the review as a `tool_x_report` + any REMEDIATE list
as `tool_x_learning`/decisions, then advances to Mars-2.

### Stage 3 — Mars-2 (implementor, harden + test): the gate ladder + REMEDIATE (MAX=3)

**Resume the Stage-1 Mars** (`SendMessage`, preserving build context) — one Mars identity, two passes.
Directive: (a) REMEDIATE every Stage-2 item. (b) Run the rung's full gate — toolchain re-probe (no
hardcode) + Valkey 6390 PONG; per-app pure + `:valkey` suites (`TMPDIR=/tmp`); the new read conformance
scenarios registered + green beside the **18 prior scenarios byte-unchanged and green** (INV1); the
read-verdict drills (counts equal the structure cardinalities; a claimed job reads `active`; a completed
job reads absent + the completed metric increments; a rate-limited queue answers a positive TTL; the
over-ceiling claim refuses with the `EMQ*` class); the **emq.1 + emq.2-cluster gate ladders still green
end-to-end** (no regression). emq.2.1 adds **no new process**, so the standing ≥100-iteration determinism
loop is NOT triggered by this rung (the reads are synchronous, deterministic verbs) — run the multi-seed
suite instead and state the determinism posture honestly. The REMEDIATE loop closes failures, MAX 3
passes.

Gate: every ladder item PASS or explained; tests green; the 18+new conformance tally clean; the read
drills recorded; the boundary grep empty; coverage tabled honestly (no fake-100).

### Stage 4 — Venus (architect): post-build specs reconcile

Directive: run a post-build reconcile (`/reconcile emq.2.1 post` — as-built ⇄ spec, the lag-1 discipline)
and bring the spec surface to as-built truth. Fold the four design-make decisions into the triad
([`./emq.2.1.md`](emq.2.1.md) body authoritative; stories + brief follow); record the module placement
chosen, the counts contract built, whether the metrics counter write landed here or flagged to emq.2.2,
and the rate-gate class word; re-pin every drifted anchor; mark any realization-over-literal deviation;
**update [`./emq.2.design.md`](../emq.2.design.md)** if the build refined the carve (e.g. the placement, the
class word). Venus edits the spec triad + the carve doc + the ledger, **never production code, never
commits**.

Gate: every triad claim MATCH or `[RECONCILE]`-marked; the carve reflects the build; the brief internally
consistent (every D/INV/US referenced-and-defined); voice + traceability + link gates clean.

### Stage 5 — Director: closure + ONE post-closure LAW-4 commit + feedback

Preconditions in order (x-mode skill §4): the Stage-2 review clean (or its REMEDIATE items closed) + the
Stage-3 gate green + the Stage-4 reconcile build-grade; **≥1 `tool_x_decision` (D-n)** locked + a
**`tool_x_complete` (Z-n)** written this turn; `git status --short` AND `git diff --cached --name-only`
reviewed; `.git/rebase-merge`/`rebase-apply` checked. Then the **pathspec commit** (never `git add -A`,
never a bare commit) over the Stage-5 pathspec below; the message cites the slug, the Z-n, the D-n
decisions, and the Y-n reports. **Same turn:** flip the emq.2.1 status in the carve doc + the roadmap
rows; write/extend `emq-2-1.progress.md`; surface the next frontier (emq.2.2 — the operator plane); under
an **explicit Operator grant only**, apply any mentoring diffs to the peer agent defs.

## The Stage-5 commit pathspec (Director-only)

Commit exactly these on closure (the rung's surface; the build run's actual touch-set is authoritative —
adjust to what Stages 1–4 truly changed):

```text
docs/echo_mq/specs/emq.2.1.md
docs/echo_mq/specs/emq.2.1.stories.md
docs/echo_mq/specs/emq.2.1.prompt.md          (this runbook)
docs/echo_mq/specs/emq.2.design.md            (Venus updates the carve if the build refined it)
docs/echo_mq/specs/emq-2-1.progress.md
docs/echo_mq/specs/emq-2-1.registry.json
echo/apps/echo_mq/lib/echo_mq/                 (the read module/verbs + the read scripts)
echo/apps/echo_mq/test/                        (the new suites + the read conformance scenarios)
echo/apps/echo_wire/lib/echo_wire.ex           (ONLY if a read delegate was added — expect EXCLUDED)
```

**EXCLUDE** (Operator out-of-band — never sweep into the rung commit):
`echo/apps/live_svelte/**`, `echo/apps/mercury_cms/**`, `echo/apps/mercury_live_admin/**`, `html/**`, and
any `[emq]`/`[bcs]`/`[mercury]` doc commits the Operator lands between stages. `apps/echomq` is
untouched by construction (the capability reference). `echo/mix.lock` ships ONLY if a real dep moved
(emq.2.1 adds none — expect it EXCLUDED). **Never `git add -A`.**

## Risk tier

emq.2.1 touches no auth / deploy / external-network surface, adds no new process, and makes no state
transition — a bus-internal **read** rung on the local Valkey substrate. The solo Director review (Stage 2)
+ Venus's independent reconcile (Stage 4) are the rigor floor; no Apollo charter is required at this tier
(x-mode §11.3). The one substantive correctness risk is reading a v1-shaped state the bus does not have —
INV3 + the Stage-2 adversarial probe are the mitigating gate.

## Acceptance — "shipped" means

Every DoD box in [`./emq.2.1.md`](emq.2.1.md) is checkable from the run's outputs: the sequencing fork
ruled; the design-make adopted + logged (placement, counts contract, the metrics-counter ruling, the rate
class); D2–D7 built as pure reads over the as-built four sets with declared keys and every job id gated;
no phantom metric; the rate gate's `EMQ*` class registered; pure + `:valkey` suites green per-app; the
**18 prior conformance scenarios byte-unchanged** + the new read scenarios green; the read-verdict drills
recorded; the emq.1 + emq.2-cluster ladders still green; the solo Director review clean; the Venus
reconcile build-grade; one Director post-closure pathspec commit.

---

The contract: [`./emq.2.1.md`](emq.2.1.md). The stories: [`./emq.2.1.stories.md`](emq.2.1.stories.md).
The carve it opens:
[`./emq.2.design.md`](../emq.2.design.md). The canon: [`../emq.design.md`](../../../emq.design.md). The program:
[`../emq.roadmap.md`](../../../emq.roadmap.md) · [`../echo_mq.md`](../../../echo_mq.md). The x-mode skill:
[`.claude/skills/x-mode/SKILL.md`](../../../../../.claude/skills/x-mode/SKILL.md). The capability reference:
`echo/apps/echomq/lib/echomq/queue.ex` + the read scripts.
