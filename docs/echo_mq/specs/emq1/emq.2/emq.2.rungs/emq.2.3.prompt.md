# EMQ.2.3 · the x-mode orchestration runbook — the watch plane (the parity cluster closes)

> **Status: SPECCED — the runbook for the emq.2.3 build run (a later session).** emq.2.3 is the third and
> final rung of the emq.2 **full-parity cluster** (the carve: [`./emq.2.design.md`](../emq.2.design.md)): the
> bus's watch plane — the event + telemetry observability surface and the lease-recovery plane (the
> lock-extension verb, the opt-in worker-side lock plane, the explicit stalled-sweep, the cooperative
> cancellation token) — ported from the v1 `echomq` watch surface onto `echo_mq`'s as-built structures, never
> migrated from. The pipeline mirrors the emq.1 / emq.2.1 runbook (the proven five-stage shape), with the one
> open sequencing fork (design §6 — Arm A vs Arm B) settled BEFORE Stage 1. **emq.2.3 reintroduces opt-in
> PROCESSES (the lock plane + the stalled sweep run on timers)** — so unlike the read-only emq.2.1, this
> runbook requires the **≥100-iteration determinism loop** for the process-touching suites and runs at a
> **higher risk tier** (a dedicated Apollo evaluator is warranted — see Risk tier). The x-mode skill
> ([`.claude/skills/x-mode/SKILL.md`](../../../../../.claude/skills/x-mode/SKILL.md)) binds the laws; its inputs are
> the spec triad ([`./emq.2.3.md`](emq.2.3.md) · [`./emq.2.3.stories.md`](emq.2.3.stories.md)), the carve ADR, and the canon ([`../emq.design.md`](../../../emq.design.md)).

## The rung in one paragraph

emq.2.3 builds the bus's **watch plane**: the observability half — `EchoMQ.Events` (per-queue subscribe/
unsubscribe/close + host-side lifecycle publish over the connector pub/sub seam, auto-resubscribe across a
reconnect) and `EchoMQ.Telemetry` (attach/emit/span over a re-rooted `[:emq, …]` lifecycle, zero-cost when
`:telemetry` is absent) — and the recovery half — a lock-extension verb on `EchoMQ.Jobs` (re-score the
`active` member to `TIME`+lease, `EMQSTALE` on a stale token), an opt-in worker-side lock plane (track/extend-
on-a-timer/release, the `EchoMQ.Pump` shape), the explicit stalled-sweep (a stall-count recovery beyond the
dead-lease reaper, on the server clock), and the cooperative cancellation token (worker-side new/cancel/
check). The capability reference is the frozen v1 `EchoMQ.QueueEvents`/`Telemetry`/`LockManager`/
`StalledChecker`/`CancellationToken` surface + its scripts; emq.2.3 re-derives those capabilities against
`echo_mq`'s real surface — NOT the v1 mechanism (the lease is the active score, not a `…:lock` string; the
event plane rides the existing seam, not a new transport; the clock is the server's `TIME`). The events fire
but the rung does NOT assert the telemetry **contract** (emq.8 — ADR-2's two-layer split); the **distributed**
cancel is emq.6 and the **durable replayable stream** is emq3.2 (out of scope). The contract is
[`./emq.2.3.md`](emq.2.3.md) (D1–D8, INV1–INV8); the carve it closes is
[`./emq.2.design.md`](../emq.2.design.md) ADR-1/3/4.

## Mode

**Flat-L2** (a build + a gate + a verify), Director-supervised, **with a dedicated Apollo evaluator** — the
emq.1 five-stage shape extended by the evaluator: **Mars-1 (design-make + build) → Director review →
Mars-2 (remediate + harden + test) → Apollo (adversarial verify + reconcile) → Venus (specs reconcile) →
Director (closure + one post-closure commit)**. **Not** the Design-Phase variant (the system spec and the
carve already exist). The risk profile is **moderate** (new opt-in PROCESSES on timers + a new lease
transition — higher than emq.2.1's read-only tier; no auth/deploy/network surface) — so a **dedicated Apollo
charter IS warranted** (x-mode §11.3: the process-and-lease risk tier), and the ≥100 determinism loop is
mandatory for the process-touching suites. (If the Director judges the build came in clean and the process
surface is thin, Apollo MAY use `AskUserQuestion` to confirm the tier with the Operator — but the default for
a process-and-lease rung is the dedicated evaluator.)

Scope slug: **`emq-2-3`** (dashed, no dots — `tool_x_*` and `TeamCreate` require `^[a-z0-9][a-z0-9-]*$`).
Operator: `jonny`. Workspace: `/Users/jonny/dev/jonnify`. Ledger: `docs/echo_mq/specs/emq-2-3.progress.md`.

## The pre-Stage-1 gate (the surfaced fork — Operator's call)

Before Stage 1, the design §6 sequencing fork must be ruled: **Arm A** (recommended — the parity cluster
fills the read/ops/observability floor; emq.3–emq.8 keep their confirmed slots) or **Arm B** (pull
flows/groups-deepened/batches into the cluster, re-sequence emq.3+). This triad is authored to **Arm A**; an
Arm-B ruling is a cheap roadmap edit before this build. **emq.2.3 also depends on emq.2.1 + emq.2.2 being
built** (the read plane is the lens the watch verdicts read through; the operator plane provides the
transitions the events fire on) — confirm both have landed (or that the build re-probes their as-built
surface) before Stage 1. The Director confirms the ruling + the dependency with the Operator and records it;
nothing builds until it is ruled.

## The design-make — the relocated gate (what Mars-1 adopts, not re-litigates)

Mars-1 **adopts the carve** ([`./emq.2.design.md`](../emq.2.design.md) ADR-1: emq.2.3 = the watch plane, last;
ADR-3: the stalled plane; ADR-4: the event+telemetry plane) and rules the build-shaping decisions the spec
leaves to D1, logging each as a `tool_x_decision`:

1. **The event surface** → the `EchoMQ.Events` placement; the §6 event channel name (a `queue_key` suffix,
   e.g. `emq:{q}:events`, vs the `{emq}:` reserve — recommended a `queue_key` suffix, per-queue); the event
   payload contract (which lifecycle facts publish — completed/failed/scheduled/stalled/…); and **where the
   events emit** — recommended **host-side** after a transition's verdict (the connector already sees it), so
   the as-built transition scripts stay byte-unchanged and the publish is an additive host step (the
   alternative — a Lua-side `PUBLISH` from each transition script — is steelmanned and chosen-against unless
   the build finds a reason, because it mutates the byte-frozen transition scripts).
2. **The telemetry tree** → the `[:emq, …]` event names for the lifecycle (the v1 `job_added`/`job_started`/
   `job_completed`/`job_failed`/`job_retried`/`worker_started` re-rooted, e.g. `[:emq, :job, :completed]`,
   `[:emq, :worker, :started]`); the zero-cost emission guard (the `Connector.emit/3`
   `:erlang.function_exported/3` precedent).
3. **The lock plane** → the lock-extension verb's name + return shape (re-score the active member to
   `TIME`+lease, `EMQSTALE` on a stale token, declared keys `[active, job_key]`); the worker-side lock-plane
   process name (the `EchoMQ.LockManager` capability) + its **opt-in supervised** shape (the `EchoMQ.Pump`
   `:transient`/owner-started/no-`mod:` precedent, a pure decision core for the extend interval). Record ≥2
   steelmanned alternatives for the lease-extension mechanism (re-score the active ZSET member — recommended,
   the v2 lease IS that score — vs a parallel `…:lock` string — chosen-against, the v1 form is structurally
   unnecessary under the single-ZSET lease).
4. **The stalled mechanism** → how the stall-count threshold is recorded and read (a field on the three-field
   row vs a registered `queue_key` set), distinct from the dead-lease reaper; the sweep declares only the sets
   it touches under `TIME` (never the v1 9-key LIST shape).

**Carried, not re-litigated:** the rung is the watch plane (the carve); the lease is the active-set score
(not a `…:lock` string); the event plane rides the existing connector pub/sub seam (no new transport, no
`SSUBSCRIBE`); the clock is the server's `TIME`; the v1 watch surface is a capability reference, never
migrated from; the telemetry **contract** is emq.8 and the **distributed** cancel is emq.6 (out of scope). If
the Stage-2 review or Apollo finds an adopted decision unsound, it is the Director's gate to send Mars back or
escalate — not to ship it.

## The as-built floor (RE-PROBE at build time — the lag-1 law)

Every anchor below is probed against the as-landed tree (anchors drift after the emq.1 + emq.2.1/2.2 builds;
Mars-1 RE-PROBES each):

- **The pub/sub seam** — `EchoMQ.Connector.subscribe/2`/`unsubscribe/2` + the `subscriptions` `MapSet` +
  `resubscribe/1` (re-issues the set at the `:reconnect` success arm) + the `{:emq_push, payload}` push to
  `push_to`; RESP3-gated (`echo/apps/echo_wire/lib/echo_mq/connector.ex` — `:108`,118,158,222,229,334-335,553,606).
  The `EchoWire` facade's `subscribe`/`unsubscribe` defdelegates (`echo_wire.ex:26-27`).
- **The telemetry precedent** — `Connector.emit/3` (`connector.ex:634-640`), guarded
  `:erlang.function_exported(:telemetry, :execute, 3)`, firing `[:emq, :connector, …]`.
- **The lease IS the active-set score** — `EchoMQ.Jobs` `@claim` `ZADD active, now + lease, id`
  (`jobs.ex:135`); the `EMQSTALE` token fence `@complete`/`@retry` (`jobs.ex:142-144`,175-177); the server
  clock `redis.call('TIME')` inside every leased script; the as-built dead-lease reaper `reap/2` + `@reap`
  (`jobs.ex:243-271`,329-333) — the stalled-sweep is BEYOND it, not a replacement.
- **The opt-in process precedent** — `EchoMQ.Pump` `child_spec/1` `restart: :transient`, owner-started/no
  `mod:`, pure `Pump.Core`, the `arm/1` timer, `sweep/1` direct-drive (`pump.ex:31-38`,7-9,91-100,146-149).
  `EchoMQ.Consumer` is the `spawn_link` drain loop the lock plane sits BESIDE (`consumer.ex:91-98`).
- **The grammar** — `EchoMQ.Keyspace.queue_key/2` (`emq:{q}:<type>`), `job_key/2` (gated by
  `BrandedId.valid?/1`), `reserve/1` (the `{emq}:` reserve) (`keyspace.ex:14-15`,18-24,27). The event channel
  + the stalled-count carrier are `queue_key` suffixes spelled against §6.
- **Conformance** — `EchoMQ.Conformance.scenarios/0` = **18** (`conformance.ex:20-41`); INV1 holds them
  byte-unchanged. The pinning tests: `conformance_scenarios_test.exs` `@run_order`
  (`Keyword.keys(scenarios()) == @run_order`, `:13-35`) + `conformance_run_test.exs`
  (`Conformance.run(conn, q) == {:ok, 18}`, `:34`, behind `:valkey`) — BOTH re-pinned to the new total.
- **No `echo/apps/echo_mq/priv/` directory** — scripts are inline `Script.new/2` attributes. **emq.2.3 follows
  the inline convention, NOT `priv/`.**
- The v1 capability reference —
  `echo/apps/echomq/lib/echomq/{queue_events,telemetry,lock_manager,stalled_checker,cancellation_token}.ex` +
  `priv/scripts/{extendLock-2,extendLocks-2,releaseLock-1,moveStalledJobsToWait-9}.lua` (these use the v1
  mechanism — port the *capability*, not the `…:lock` string / caller clock / 9-key LIST shape / v1 transport).

## The pipeline — six stages, Director-in-loop

Each spawned stage is a real `general-purpose` Agent that adopts its `.claude/agents/<role>.md` charter
(Mars / Apollo / Venus) — and the echo_mq dev skill (`echo-mq-implementor` / `echo-mq-evaluator` /
`echo-mq-architect`) — and self-registers via `mcp__aaw__*` (LAW-1; no narrated spawns). The Director holds
the gate between stages. The per-spawn contract is the x-mode skill §3 (Framing → adopt charter → aaw ceremony
→ the stage block → audit directive → propagation clause → report).

### Stage 1 — Mars-1 (implementor): design-make + build

Directive (lift into the spawn): **make the watch-plane design real and build it.** (a) RE-PROBE every
as-built anchor above (the lag-1 law). (b) Adopt the carve (ADR-1/3/4) + rule the four design-make decisions
above; log each as a `tool_x_decision` (D-n) citing the design § it adopts; invent no transport, no lock key,
no clock. (c) Build EMQ.2.3-D2 → D7 to the agent stories — the
lock-extension verb (D4, the recovery half first, since D5 drives it), the worker-side lock plane (D5, the
opt-in `:transient` process), the explicit stalled-sweep (D6), `EchoMQ.Events` (D2), `EchoMQ.Telemetry` (D3),
the cooperative cancellation token (D7). The lock-extension verb + the stalled sweep read the server `TIME`
(INV3 — they touch a lease); the lock-extension reuses `EMQSTALE` (no new wire class — INV1); the event plane
rides the existing connector pub/sub seam (no new transport, no `SSUBSCRIBE` — INV2); every job id gated at
the key builder (INV5); every new Lua key declared-or-grammar-derived (INV4); the lock plane is opt-in (a
consumer without it is the unchanged v2 worker — INV3/INV7); new scripts follow the inline `Script.new/2`
convention. Ship the event/telemetry **surface** only (the contract is emq.8 — INV6); ship the **worker-side**
cooperative cancel only (the distributed cancel is emq.6 — INV7). Register a conformance scenario + probe for
every watch verb IN THE SAME CHANGE (INV1, the additive-minor law). Compile clean (`--warnings-as-errors`,
per-app). Report any realization-over-literal clause.

Gate before advancing: per-app compiles green; D2–D7 deliverables exist; the four design-make decisions
logged; the diff stays inside `echo_mq` (+ the read-only `echo_wire` seam; `apps/echomq` untouched; no third
app touched); the inline-script convention followed; the lock-extension reuses `EMQSTALE` (no new wire class);
the event plane adds no new transport; the lock-delta law holds. (The full test gate + the determinism loop is
Stage 3 — Stage 1 ends at compile-green + deliverables-present + a smoke that the new modules load + a single
green process smoke.)

### Stage 2 — Director (solo review): the relocated charter

The Director reviews Mars-1's design-make + build **from a fresh gate**, not from Mars-1's report (max-effort
= a real verification pass):

- **Reconcile** the build against the carve + the brief: every watch verb MATCH / realized-and-logged /
  flagged; the lease-extension re-scores the active member (NOT a `…:lock` string — the headline INV3 check);
  the event plane rides the existing seam (NOT a new transport — the headline INV2 check); the lock plane is
  opt-in (a consumer without it is the unchanged v2 worker — INV7); the lock-extension reuses `EMQSTALE` (no
  new wire class — INV1); every new Lua key declared-or-grammar-derived (INV4); the telemetry **surface** only
  (no emq.8 proof — INV6); the **worker-side** cancel only (no distributed cancel — INV7).
- **Run the gate fresh** (per-app, `TMPDIR=/tmp`, Valkey 6390 PONG first): the per-app compiles; a pure suite
  per touched app; the new `:valkey` watch scenarios load and the 18 prior ones still enumerate; a single
  process smoke (the lock plane extends a lease once).
- **≥1 adversarial probe** — attack a claimed invariant (e.g. INV3: claim a job, extend its lease past the
  original deadline, run `reap/2`, confirm the job is NOT reclaimed; then present a stale token to the
  extension verb and confirm `EMQSTALE`; or INV2: confirm the event plane uses `subscribe/2` and not a new
  command — grep the build for `SSUBSCRIBE` and a new transport, expect empty).
- **A mutation spot-check** on one watch verb (e.g. flip the lock-extension's `TIME`-derived deadline to the
  caller-supplied value, or flip the stalled-count `>=` threshold to `>`), confirm a test catches it, then
  **REVERT by the inverse edit and verify `git diff --stat` clean** (the Director's only edit-class action — a
  net-zero verification probe, immediately reverted; the Director authors no production code, LAW-1a).

Gate: the build is faithful to the carve and inside the boundary; the probes hold or the gaps are written as
REMEDIATE items for Stage 3. The Director records the review as a `tool_x_report` + any REMEDIATE list as
`tool_x_learning`/decisions, then advances to Mars-2.

### Stage 3 — Mars-2 (implementor, harden + test): the gate ladder + REMEDIATE (MAX=3)

**Resume the Stage-1 Mars** (`SendMessage`, preserving build context) — one Mars identity, two passes.
Directive: (a) REMEDIATE every Stage-2 item. (b) Run the rung's full gate — toolchain re-probe (no hardcode) +
Valkey 6390 PONG; per-app pure + `:valkey` + process suites (`TMPDIR=/tmp`); the new watch conformance
scenarios registered + green beside the **18 prior scenarios byte-unchanged and green** (INV1), with BOTH
pinning tests re-pinned to the new total + `@run_order`; the watch-verdict drills (an extended lease survives
the reaper; a stale token refuses `EMQSTALE`; a past-threshold job is recovered/dead per the threshold; a
subscriber receives a lifecycle event; an attached `[:emq, …]` handler fires); the **emq.1 + emq.2.1/2.2 gate
ladders still green end-to-end** (no regression). emq.2.3 adds **opt-in PROCESSES** (the lock plane + the
stalled sweep run on timers), so the standing **≥100-iteration determinism loop IS triggered by this rung** —
run `for i in $(seq 1 100); do TMPDIR=/tmp mix test || break; done` (inside `echo/apps/echo_mq`) over the
process-touching suites, the loop OWNING the machine (no concurrent liveness server, no sibling heavy I/O —
the master-invariant gate ladder; a load-gated pre-existing test forges a failure the rung did not cause). The
REMEDIATE loop closes failures, MAX 3 passes.

Gate: every ladder item PASS or explained; tests green; the 18+new conformance tally clean + both pins
updated; the watch drills recorded; the ≥100 loop green and machine-owned; the boundary grep empty; coverage
tabled honestly (no fake-100).

### Stage 4 — Apollo (evaluator): adversarial verify + the post-build reconcile

The dedicated evaluator (the process-and-lease risk tier — x-mode §11.3). Directive: **independently** verify
the rung against the spec's promises and the §11.2-charter probes applied to echo_mq:

- **The order-theorem / declared-keys / destructive-act probes** (the `echo-mq-evaluator` craft): assert every
  new Lua script declares its keys (the A-1 lint over the lock-extension + the stalled sweep — no key rooted
  in a data value); assert the lock-extension is token-fenced (a stale token NEVER extends — the order
  theorem applied to the lease); assert no destructive act (the stalled sweep recovers/dead-letters, it does
  not silently drop a job).
- **Re-run the per-app gate ladder + the ≥100 determinism loop INDEPENDENTLY** (not from Mars's report — the
  loop is the gate, not the implementer's single run); re-verify the conformance count is byte-unchanged for
  the 18 with each new scenario probe-registered (the additive-minor law).
- **The two-layer boundary probe** (INV6/INV7): confirm emq.2.3 ships the telemetry **surface** and NOT the
  contract (no emq.8 proof leaked), and the **worker-side** cancel and NOT the distributed cancel (no emq.6
  surface leaked) — the family boundary holds.
- **Render the BUILD-GRADE / BLOCKED verdict** and sync the spec to what shipped where it drifted (Apollo
  edits the triad + the ledger, per the evaluator charter; never production code, never commits).

Gate: every spec promise verified or written as a BLOCKED item; the declared-keys/order-theorem/destructive
probes hold; the determinism loop green independently; the family boundary clean; the verdict rendered.

### Stage 5 — Venus (architect): post-build specs reconcile

Directive: run a post-build reconcile (`/reconcile emq.2.3 post` — as-built ⇄ spec, the lag-1 discipline) and
bring the spec surface to as-built truth. Fold the four design-make decisions into the triad
([`./emq.2.3.md`](emq.2.3.md) body authoritative; stories + brief follow); record the event channel name +
the payload contract + the host-side-vs-Lua emit chosen, the telemetry `[:emq, …]` tree built, the
lock-extension verb's name/return, the worker-side lock-plane process name + shape, and the stalled-count
carrier; re-pin every drifted anchor; mark any realization-over-literal deviation; **update
[`./emq.2.design.md`](../emq.2.design.md)** if the build refined the carve (e.g. the channel name, the verb
name, the stalled mechanism). Venus edits the spec triad + the carve doc + the ledger, **never production
code, never commits**. (Apollo + Venus may run concurrently if the Director partitions their edits — Apollo
the adversarial verdict + the tests-reconcile, Venus the triad + the carve — one-owner-per-file.)

Gate: every triad claim MATCH or `[RECONCILE]`-marked; the carve reflects the build; the brief internally
consistent (every D/INV/US referenced-and-defined); voice + traceability + link gates clean.

### Stage 6 — Director: closure + ONE post-closure LAW-4 commit + feedback

Preconditions in order (x-mode skill §4): the Stage-2 review clean (or its REMEDIATE items closed) + the
Stage-3 gate green + the Apollo verdict BUILD-GRADE + the Venus reconcile build-grade; **≥1 `tool_x_decision`
(D-n)** locked + a **`tool_x_complete` (Z-n)** written this turn; `git status --short` AND
`git diff --cached --name-only` reviewed; `.git/rebase-merge`/`rebase-apply` checked. Then the **pathspec
commit** (never `git add -A`, never a bare commit) over the Stage-6 pathspec below; the message cites the slug,
the Z-n, the D-n decisions, and the Y-n reports. **Same turn:** flip the emq.2.3 status in the carve doc + the
roadmap rows; mark the **emq.2 cluster COMPLETE** (emq.2.1/2.2/2.3 all shipped); write/extend
`emq-2-3.progress.md`; surface the next frontier (emq.3 — parent/flow); under an **explicit Operator grant
only**, apply any Apollo mentoring diffs to the peer agent defs / the dev skills.

## The Stage-6 commit pathspec (Director-only)

Commit exactly these on closure (the rung's surface; the build run's actual touch-set is authoritative —
adjust to what Stages 1–5 truly changed):

```text
docs/echo_mq/specs/emq.2.3.md
docs/echo_mq/specs/emq.2.3.stories.md
docs/echo_mq/specs/emq.2.3.prompt.md          (this runbook)
docs/echo_mq/specs/emq.2.design.md            (Venus updates the carve if the build refined it; flip emq.2 → COMPLETE)
docs/echo_mq/specs/emq-2-3.progress.md
docs/echo_mq/specs/emq-2-3.registry.json
echo/apps/echo_mq/lib/echo_mq/                 (events.ex, telemetry.ex, lock_manager.ex[+core], stalled_checker.ex, cancellation_token.ex, jobs.ex)
echo/apps/echo_mq/test/                        (the new suites + the re-pinned conformance tests)
echo/apps/echo_wire/lib/echo_wire.ex           (ONLY if a facade delegate was added — expect EXCLUDED, the events ride the existing subscribe/unsubscribe)
```

**EXCLUDE** (Operator out-of-band — never sweep into the rung commit):
`echo/apps/live_svelte/**`, `echo/apps/mercury_cms/**`, `echo/apps/mercury_live_admin/**`, `html/**`, and any
`[emq]`/`[bcs]`/`[mercury]` doc commits the Operator lands between stages. `apps/echomq` is
untouched by construction (the capability reference). `echo/mix.lock` ships ONLY if a real dep moved (emq.2.3
adds none — `:telemetry` is a guarded optional use, the `Connector.emit/3` precedent; expect it EXCLUDED —
confirm at D1). **Never `git add -A`.**

## Risk tier

emq.2.3 touches no auth / deploy / external-network surface, BUT it **adds opt-in PROCESSES** (the worker-side
lock plane + the explicit stalled sweep, both timer-driven) **and a new lease transition** (the lock-extension
verb) — a **moderate** tier, higher than emq.2.1's read-only floor. The two substantive correctness risks are
(1) the lease-extension racing the reaper/consumer (a slow handler's extension must land before the reaper's
scan — the ≥100 determinism loop + the Stage-2/Apollo extend-survives-reap probe are the mitigating gate) and
(2) reading a v1-shaped mechanism the bus does not have (a `…:lock` string, the caller clock, a new transport
— INV2/INV3 + the Stage-2/Apollo adversarial probes are the mitigating gate). **A dedicated Apollo charter IS
required at this tier** (Stage 4; x-mode §11.3) — the solo Director review (Stage 2) + Apollo's independent
adversarial verify (Stage 4) + Venus's reconcile (Stage 5) are the rigor floor; the ≥100 determinism loop is
mandatory for the process-touching suites and must own the machine.

## Acceptance — "shipped" means

Every DoD box in [`./emq.2.3.md`](emq.2.3.md) is checkable from the run's outputs: the sequencing fork ruled
+ emq.2.1/2.2 confirmed built; the design-make adopted + logged (the event surface, the telemetry tree, the
lock plane, the stalled mechanism); D2–D7 built — the lock-extension verb re-scoring the active member under
`TIME` with `EMQSTALE` and no new wire class; the opt-in worker-side lock plane (a consumer without it the
unchanged v2 worker); the explicit stalled-sweep beyond the reaper on the server clock; `EchoMQ.Events` over
the existing connector pub/sub seam with no new transport; `EchoMQ.Telemetry` firing the `[:emq, …]` surface
(the contract emq.8); the worker-side cooperative cancel (the distributed cancel emq.6); every new Lua key
declared-or-grammar-derived; pure + `:valkey` + process suites green per-app; the **18 prior conformance
scenarios byte-unchanged** + the new watch scenarios green + both pinning tests re-pinned; the watch-verdict
drills recorded; the **≥100 determinism loop green and machine-owned**; the emq.1 + emq.2.1/2.2 ladders still
green; the solo Director review clean; the **Apollo verdict BUILD-GRADE**; the Venus reconcile build-grade;
one Director post-closure pathspec commit; the **emq.2 cluster marked COMPLETE**.

---

The contract: [`./emq.2.3.md`](emq.2.3.md). The stories: [`./emq.2.3.stories.md`](emq.2.3.stories.md).
The carve it closes:
[`./emq.2.design.md`](../emq.2.design.md). The canon: [`../emq.design.md`](../../../emq.design.md). The program:
[`../emq.roadmap.md`](../../../emq.roadmap.md) · [`../echo_mq.md`](../../../echo_mq.md). The x-mode skill:
[`.claude/skills/x-mode/SKILL.md`](../../../../../.claude/skills/x-mode/SKILL.md). The capability reference:
`echo/apps/echomq/lib/echomq/{queue_events,telemetry,lock_manager,stalled_checker,cancellation_token}.ex` +
the scripts. The as-built floor: `echo/apps/echo_mq/lib/echo_mq/{jobs,consumer,pump,keyspace,conformance}.ex`
+ `echo/apps/echo_wire/lib/echo_mq/connector.ex` (the pub/sub seam + `emit/3`).
