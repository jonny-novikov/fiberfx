# EMQ.1 · the x-mode orchestration runbook — LAUNCH (Operator-reshaped 2026-06-13)

> **Status: LAUNCH.** The Operator reshaped this run's pipeline and ordered execution (2026-06-13,
> `/effort max`): **Mars-1 (design-make + build) → solo Director review → Mars-2 (remediate + harden +
> test) → Venus (specs reconcile) → Director (closure + one post-closure commit)**. Two structural moves
> from the authored Venus → Mars ×2 → Apollo flow: Venus **skips the pre-build stage** — the design-make
> folds into Mars-1; and the **Apollo charter is replaced by a solo Director review** (single verifier,
> Director-accountable), with Venus reconciling the specs **after** the build. The EMQ.1-D1 design gate
> is **relocated, not skipped**: Mars-1 makes the design by adopting [`./emq.1.design.md`](emq.1.design.md)'s
> already-recommended arms (§"The design-make" below), the solo Director review scrutinizes it, and the
> Operator's acceptance of the single post-closure commit is the ratification. The x-mode skill
> ([`.claude/skills/x-mode/SKILL.md`](../../../../.claude/skills/x-mode/SKILL.md)) binds the laws; its inputs
> are the spec triad ([`./emq.1.md`](./emq.1.md) · [`./emq.1.stories.md`](./emq.1.stories.md)), the design, and the canon ([`../emq.design.md`](../../emq.design.md)).

## The rung in one paragraph

emq.1 opens Movement I: the bus's **time-and-retry vocabulary** for its worked consumer, codemojex.
It builds — inside `echo/apps/echo_mq` under the v2 laws, additive on the wire — scheduled
enqueue (run-at / run-in as a visibility fence over the existing `emq:{q}:schedule` set, never a new
queue), repeatable jobs (each occurrence a fresh branded `JOB` mint), the attempts-with-backoff retry
vocabulary above the wire with the poison-job drill, a supervised opt-in promote pump, and connector
auto-resubscribe after `:reconnect`. The substrate is largely as-built (the schedule set, `retry/7`,
`promote/3`, the `'scheduled'` state all exist — verified below); emq.1 adds the verbs, the host-side
policy, the pump, and the resubscribe seam. The contract is [`./emq.1.md`](./emq.1.md) (D1–D7,
INV1–INV7); the design it makes real is [`./emq.1.design.md`](emq.1.design.md).

## Mode

**Flat-L2** (multi-stream: a build + a gate + a verify), Director-supervised — **Operator-reshaped
2026-06-13** to the five stages below. **Not** the Design-Phase variant (the system spec already exists).
The risk profile is unchanged from the authored runbook (no auth/deploy/network surface); the Operator's
choice of a solo Director review over an Apollo charter is honored, and the lost §11.2 rigor is recovered
by making the Director review a real reconcile-plus-gate-plus-adversarial pass (Stage 2) and by Venus's
independent post-build reconcile (Stage 4).

Scope slug: **`emq-1`** (dashed, no dots — `tool_x_*` and `TeamCreate` require `^[a-z0-9][a-z0-9-]*$`).
Operator: `jonny`. Workspace: `/Users/jonny/dev/jonnify`. Ledger: `docs/echo_mq/specs/emq-1.progress.md`.

## The design-make — the relocated gate (what Mars-1 adopts, not re-litigates)

The Operator delegated the EMQ.1-D1 design-making to Mars-1 with the order to execute. Mars-1 **adopts
[`./emq.1.design.md`](emq.1.design.md)'s chosen-proposed arms** (it invents no new design; the draft
already steelmans and recommends each), logs each as a `tool_x_decision`, and builds. The six forks
settle by adoption as follows — the Director records this as the gate-relocation decision, and the
Operator's post-closure acceptance ratifies (or amends, as a cheap additive follow-up):

1. **Keyspace seam (D-10) → Arm C (keep the annotated cross-app read).** Zero wire-app churn; emq.1 stays
   focused on the scheduler. Arms A/B (inline the constant / move `version_key/0`) are a later dedicated
   seam pass, not this rung. (ADR-5 still edits `connector.ex` for the resubscribe set — a separate
   concern; the version-key read is left exactly as the emq.0 as-built.)
2. **A-1 lint binding rule → DEFER.** emq.1's new scripts add no new derivation power (they follow the
   as-built ARGV-base + declared-structure-key convention); the strict-`KEYS`-root-vs-hashtag-equality
   reading is a canon question the emq.8 proof-stack lint forces, not an emq.1 blocker. Mars-1 builds to
   the existing convention and flags the reading for the closing report.
3. **Repeat-registry key shape → ADOPT** `emq:{q}:repeat` (zset, scored by next-run ms) +
   `emq:{q}:repeat:<name>` (record hash: `every_ms` + payload template). Declared-keys-clean, registered
   with a conformance probe, additive-minor against §6's closed registry.
4. **run-at admission → ADMIT both run-at and run-in.** The consumer's settlement / end-of-day work is
   calendar-anchored (run-at is its named need); run-in computes the score wire-side from `TIME`. The
   caller's clock prices only the schedule SCORE; the fence and lease laws are untouched.
5. **The pump's shape → ONE opt-in pump carrying both sweeps** (promote + repeat), pure decision core,
   restart semantics stated in the child spec.
6. **`unsubscribe/2` companion verb → ADD** beside the recorded subscription set (keeps it truthful;
   small, additive on the `EchoWire` facade).

**Carried, not re-litigated:** the rung contract is Candidate B (Stage-1b); the consumer is codemojex;
the ladder slot is emq.1. If the solo Director review (Stage 2) finds an adopted arm unsound or
scope-expanding, it is the Director's gate to send Mars back or escalate to the Operator — not to ship it.

## The as-built floor (re-verified 2026-06-13, post-emq.0 `a2d599c8`)

Every anchor below was probed against the as-landed tree after the emq.0 import relocated the wire trio
to `echo/apps/echo_wire`. Mars-1 RE-PROBES each at build time (anchors drift; the lag-1 law):

- `EchoMQ.Jobs.retry/7` — `echo/apps/echo_mq/lib/echo_mq/jobs.ex:242` (literal `delay_ms`/`max_attempts`
  in; `{:ok, :scheduled} | {:ok, :dead}` out; `last_error` kept; dead-letters at the cap).
- `EchoMQ.Jobs.promote/3` — `echo/apps/echo_mq/lib/echo_mq/jobs.ex:268` (moves due scheduled jobs to
  pending, group-aware). The `emq:{q}:schedule` set and the `'scheduled'` row state both exist as-built.
- `EchoMQ.Connector.subscribe/2` — `echo/apps/echo_wire/lib/echo_mq/connector.ex:104` (rides
  `push_command`, RESP3). The `:reconnect` success arm is `connector.ex:284-287`; the init state map
  (`:129-158`) holds no subscription set (the 2.1 gap, verified). A `[:emq, :connector, :reconnect]`
  telemetry event already fires (`:286`).
- The `EchoWire` facade — `echo/apps/echo_wire/lib/echo_wire.ex`: 9 `defdelegate`s + `script/2`.
- `EchoMQ.Conformance.scenarios/0` — exactly **14** scenarios (`conformance.ex`); INV1 holds them
  byte-unchanged.
- `EchoMQ.Consumer` process shape — `child_spec` `consumer.ex:18`, `start_link` `:35`, `stop/2` `:78`,
  the loop `:91` (the pump's process-shape precedent).
- **No `echo/apps/echo_mq/priv/` directory exists** — scripts are inline `Script.new/2` module
  attributes (`echo_wire/lib/echo_mq/script.ex`; `@enqueue` at `jobs.ex:14-24`). **emq.1 follows the
  inline convention, NOT `priv/`.** The triad's "new Lua under `priv/`" line ([`./emq.1.md`](./emq.1.md)
  §Where) is a Stage-4 reconcile flag for Venus.

## The pipeline — five stages, Director-in-loop

Each spawned stage is a real `general-purpose` Agent that adopts its `.claude/agents/<role>.md` charter
and self-registers via `mcp__aaw__*` (LAW-1; no narrated spawns). The Director holds the gate between
stages. The per-spawn contract is the x-mode skill §3 (Framing → adopt charter → aaw ceremony → the
stage block → audit directive → propagation clause → report).

### Stage 1 — Mars-1 (implementor): design-make + build

Directive (lift into the spawn): **make the design real and build it.** (a) RE-PROBE every as-built
anchor above (the lag-1 law — the import moved files). (b) Adopt the six arms from "The design-make"
above; log each as a `tool_x_decision` (D-n) citing the design-doc section it adopts; invent no new
design. (c) Build EMQ.1-D2 → D6 to the brief's agent stories and the adopted
design — scheduled enqueue run-at/run-in over one new inline script (D2), the repeat registration surface
+ pump-swept fresh mints (D3), `EchoMQ.Backoff` pure module feeding `Jobs.retry/7` unchanged (D4), the
one supervised opt-in pump over `Jobs.promote/3` + the repeat sweep (D5), the connector resubscribe set
re-issued at the `:reconnect` success arm + `unsubscribe/2` (D6). Cite the spec/design line for every
public call; keep the diff inside `echo_mq` + the `connector.ex` resubscribe seam; new scripts follow the
inline `Script.new/2` convention; every new Lua key declared in `KEYS[]` or grammar-derived (INV2);
compile clean (`--warnings-as-errors`, per-app). Register a conformance scenario + probe for every new
surface IN THE SAME CHANGE (INV1, the additive-minor law) — the four proposed names `schedule`, `repeat`,
`backoff`, `resubscribe`. Report the realization-over-literal clause for any item built differently.

Gate before advancing: per-app compiles green; D2–D6 deliverables exist; the four arms adopted are
logged as decisions; the diff stays inside the boundary (`apps/echomq` untouched; no third app touched);
the inline-script convention followed; the lock-delta law holds (INV6). (The full test gate is Stage 3 —
Stage 1 ends at compile-green + deliverables-present + a smoke that the new verbs load.)

### Stage 2 — Director (solo review): the relocated charter

The Director reviews Mars-1's design-make + build **from a fresh gate**, not from Mars-1's report. This
replaces the Apollo charter; max-effort means it is a real verification pass, not a glance:

- **Reconcile** the build against the adopted design + the brief: every public surface MATCH /
  realized-and-logged / flagged. The six adopted arms are present and sound; fork 2 is deferred, not
  silently decided; the keyspace extension (fork 3) is declared-keys-clean by reading every new script.
- **Run the gate fresh** (per-app, `TMPDIR=/tmp`, Valkey 6390 PONG first): the per-app compiles; a pure
  suite per touched app; the new `:valkey` scenarios load and the 14 prior ones still enumerate.
- **≥1 adversarial probe** — attack a claimed invariant (e.g. the order theorem: a job minted-early but
  scheduled-late must sort by mint once promoted; or the poison drill's exact-max-attempts boundary).
- **A mutation spot-check** on one new surface (e.g. flip a backoff branch or the schedule score sign),
  confirm a test catches it, then **REVERT by the inverse edit and verify `git diff --stat` clean**.
  (This is the Director's only edit-class action — a verification probe with net-zero change, immediately
  reverted; the Director authors no production code, LAW-1a.)

Gate: the build is faithful to the adopted design and inside the boundary; the probes hold or the gaps
are written as REMEDIATE items for Stage 3. The Director records the review as a `tool_x_report` (the
solo-charter finding set) + any REMEDIATE list as `tool_x_learning`/decisions, then advances to Mars-2.

### Stage 3 — Mars-2 (implementor, harden + test): the gate ladder + REMEDIATE (MAX=3)

**Resume the Stage-1 Mars** (`SendMessage`, preserving build context) — one Mars identity, two passes.
Directive: (a) REMEDIATE every item the Director's Stage-2 review flagged. (b) Run the rung's full gate —
toolchain re-probe (no hardcode) + Valkey 6390 PONG; per-app pure + `:valkey` suites (`TMPDIR=/tmp`); the
four new conformance scenarios registered + green beside the **14 prior scenarios byte-unchanged and
green** (INV1); the **poison-job drill** (dead-letter at exactly max attempts, `last_error` browsable);
the **socket-kill resubscribe drill** (subscriptions answer after reconnect without a caller restart);
the pump cadence + crash-restart check; the **emq.0 gate ladder still green end-to-end** (3_1..3_5,
4_1..4_4, the shadow rung); the **determinism loop ≥100 iterations** over every process-touching suite
(the pump is the new process — the standing law; tee output to a file, report from the file — background
shells die with the turn). The REMEDIATE loop closes failures, MAX 3 passes.

Gate: every ladder item PASS or explained; tests green; the 14+4 conformance tally clean; the drills
recorded; the determinism loop 0-fail; the boundary grep empty; coverage tabled honestly (no fake-100).

### Stage 4 — Venus (architect): post-build specs reconcile

Directive: run a post-build reconcile (as-built ⇄ spec, the lag-1 discipline) and bring the spec surface
to as-built truth. Fold the six adopted-arm decisions into the triad ([`./emq.1.md`](emq.1.md) body
authoritative; stories + brief follow); **flip [`./emq.1.design.md`](emq.1.design.md) from DRAFT to
adopted-as-built**, recording which arm each fork took and that fork 2 is deferred-to-canon; **correct
the `priv/`-vs-inline reconcile flag** (the triad's "new Lua under `priv/`" → the as-built inline
`Script.new/2` convention); re-pin every drifted anchor; mark any Stage-1/3 realization-over-literal
deviation. Venus edits the spec triad + the design doc + the ledger, **never production code, never
commits**.

Gate: every triad claim MATCH or `[RECONCILE]`-marked; the design doc reflects the adopted arms; the
`priv/` flag corrected; the brief internally consistent (every D/INV/US referenced-and-defined); voice +
traceability + link gates clean.

### Stage 5 — Director: closure + ONE post-closure LAW-4 commit + feedback

Preconditions in order (x-mode skill §4): the Stage-2 review clean (or its REMEDIATE items closed by
Stage 3) + the Stage-3 gate green + the Stage-4 reconcile build-grade; **≥1 `tool_x_decision` (D-n)**
locked + a **`tool_x_complete` (Z-n)** written this turn; `git status --short` AND `git diff --cached
--name-only` reviewed; `.git/rebase-merge`/`rebase-apply` checked. Then the **pathspec commit** (never
`git add -A`, never a bare commit) over the Stage-5 pathspec below; the message cites the slug, the Z-n,
the D-n decisions, and the Y-n reports. **Stage 6 (same turn):** flip the emq.1 ladder rows
([`../emq.roadmap.md`](../../emq.roadmap.md) — the single consolidated roadmap) and
[`../echo_mq.md`](../../echo_mq.md) M1's emq.1 status (this rung un-blocks codemojex's
scheduled/settlement trace); write/extend `emq-1.progress.md`; **surface the adopted six arms to
the Operator for post-closure acceptance/amend**; under an **explicit Operator grant only**, apply any
mentoring diffs to the peer agent defs. Surface the next frontier (emq.2 migration, or the emq.7 /
emq3.1–emq3.2 pull-forwards).

## Risk tier

emq.1 touches no auth / deploy / external-network surface — a bus-internal capability rung on the local
Valkey substrate. The one elevated dimension is the new PROCESS (the pump): Stage 3's determinism loop
over the pump suite is the mitigating gate. The Operator chose a solo Director review over a second
verifier; Stage 2's reconcile-plus-gate-plus-adversarial pass + Stage 4's independent Venus reconcile are
the rigor floor in Apollo's absence.

## The Stage-5 commit pathspec (Director-only)

Commit exactly these on closure (the rung's surface; the build run's actual touch-set is authoritative —
adjust to what Stages 1–4 truly changed):

```text
docs/echo_mq/specs/emq.1.md
docs/echo_mq/specs/emq.1.stories.md
docs/echo_mq/specs/emq.1.design.md          (Venus flips DRAFT → adopted-as-built)
docs/echo_mq/specs/emq.1.prompt.md          (this reshaped runbook)
docs/echo_mq/specs/emq-1.progress.md
docs/echo_mq/specs/emq-1.registry.json
docs/echo_mq/emq.roadmap.md                 (the single consolidated roadmap; + ../echo_mq.md M1 row)
echo/apps/echo_mq/lib/echo_mq/              (the scheduler / repeat / backoff / pump surfaces)
echo/apps/echo_mq/test/                     (the new suites + the 4 conformance scenarios)
echo/apps/echo_wire/lib/echo_mq/connector.ex (the resubscribe seam)
echo/apps/echo_wire/lib/echo_wire.ex         (ONLY if unsubscribe/2 is delegated)
echo/apps/echo_wire/test/                    (the resubscribe drill, if placed here)
```

**EXCLUDE** (Operator out-of-band — never sweep into the rung commit): `echo/apps/live_svelte/**`,
`echo/apps/mercury_cms/**`, `echo/apps/mercury_live_admin/**`, `html/**`, and any `[emq]`/`[bcs]`/
`[mercury]` doc commits the Operator lands between stages (and the emq-0 ledger churn). `apps/echomq` is
untouched by construction. `echo/mix.lock` ships ONLY if a real dep moved (emq.1 adds none — expect it
EXCLUDED). **Never `git add -A`.**

## Acceptance — "shipped" means

Every DoD box in [`./emq.1.md`](emq.1.md) is checkable from the run's outputs: the design adopted +
logged (the relocated EMQ.1-D1 gate); D2–D6 built with declared-keys passing and every addition
probe-registered; the poison-job drill at exactly max attempts; pure + `:valkey` suites green per-app;
the prior 14 conformance scenarios byte-unchanged + the 4 new green; the reconnect drill (subscriptions
answer without a caller restart); the emq.0 ladder still green; the solo Director review clean; the Venus
reconcile build-grade; one Director post-closure pathspec commit; the six adopted arms surfaced to the
Operator.

---

The contract: [`./emq.1.md`](emq.1.md). The stories: [`./emq.1.stories.md`](./emq.1.stories.md). The design it makes real: [`./emq.1.design.md`](emq.1.design.md).
The canon: [`../emq.design.md`](../../emq.design.md). The program: [`../emq.roadmap.md`](../../emq.roadmap.md)
· [`../echo_mq.md`](../../echo_mq.md). The x-mode skill: [`.claude/skills/x-mode/SKILL.md`](../../../../.claude/skills/x-mode/SKILL.md).
The consumer: `echo/apps/codemojex` (the worked game consumer).
