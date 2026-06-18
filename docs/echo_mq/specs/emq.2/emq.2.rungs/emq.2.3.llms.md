# EMQ.2.3 · the agent brief (LLM build brief)

> The build-grade brief Mars builds emq.2.3 from and the Operator/verifier accepts against. Derived from
> [`./emq.2.3.md`](emq.2.3.md) (the spec body — **authoritative**; this brief and the stories may lag it,
> and when they disagree the body wins) and the carve [`./emq.2.design.md`](../emq.2.design.md). The contract
> is "emq.2.3 builds the watch plane"; nothing here is asserted-as-shipped. Framing: no gendered pronouns for
> agents; no perceptual or interior-state verbs for agents or software (components read, compute, refuse,
> return, publish); no first-person narration. Enforce these same rules in any downstream prompt.

## References (read first, in order)

1. **The carve + the ADRs** — [`./emq.2.design.md`](../emq.2.design.md): ADR-0 (no migration — built fresh),
   ADR-1 (the carve: emq.2.3 = the watch plane, last because it watches the surface the first two rungs
   complete), ADR-2 (the parity/family boundary — emq.2.3 ships the cooperative cancel + the telemetry/event
   **surface**, NOT the distributed cancel / TTL / checkpoints / the telemetry **contract** / the durable
   stream), **ADR-3 (the stalled plane — the lock-extension verb + the worker-side lock plane + the explicit
   stalled-sweep)**, **ADR-4 (the event + telemetry plane — the existing pub/sub seam, not a new transport)**.
2. **The spec body** — [`./emq.2.3.md`](emq.2.3.md): Goal · 5W · Scope · D1–D8 · INV1–INV8 · DoD.
3. **The as-built floor (the seam + structures emq.2.3 watches)** — RE-PROBE each at build time (the lag-1
   law; earlier emq.* builds move the surface):
   - `echo/apps/echo_wire/lib/echo_mq/connector.ex` — **the pub/sub seam**: `subscribe/2` (`connector.ex:108`),
     `unsubscribe/2` (`connector.ex:118`), the `subscriptions` `MapSet` (`connector.ex:158`,222,229),
     `resubscribe/1` re-issuing the set at the `:reconnect` success arm (`connector.ex:606`,334-335), `down/1`
     keeping the set (`connector.ex:586-599`), pushes routed as `{:emq_push, payload}` to `push_to`
     (`connector.ex:553`), RESP3-gated (`requires_resp3`). **The telemetry precedent**: the private `emit/3`
     (`connector.ex:634-640`) — guarded `:erlang.function_exported(:telemetry, :execute, 3)`, firing
     `[:emq, :connector, …]`. The `EchoWire` facade exposes `subscribe`/`unsubscribe` defdelegates
     (`echo_wire.ex:26-27`).
   - `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — the lease IS the `active` sorted-set score: `@claim`
     `ZADD KEYS[2], now + tonumber(ARGV[2]), id` (`jobs.ex:135`); the `EMQSTALE` token fence: `@complete`
     `att ~= ARGV[2] → redis.error_reply('EMQSTALE …')` (`jobs.ex:142-144`), `@retry` likewise
     (`jobs.ex:175-177`); the server clock `local t = redis.call('TIME')` inside every leased script; the
     as-built dead-lease reaper `reap/2` + `@reap` (`jobs.ex:243-271`,329-333) — the watch plane's
     stalled-sweep is BEYOND it, not a replacement.
   - `echo/apps/echo_mq/lib/echo_mq/pump.ex` — **the opt-in supervised process precedent** (the lock plane's
     shape): `child_spec/1` `restart: :transient` (`pump.ex:31-38`), owner-started/no `mod:` (`pump.ex:7-9`),
     a pure decision `Pump.Core` (the cadence arithmetic — the extend interval — is a value tested without a
     clock), a timer via `arm/1` `Process.send_after(self(), :tick, …)` (`pump.ex:146-149`), a thin GenServer
     shell, `sweep/1` exposed for a direct-drive test (`pump.ex:91-100`).
   - `echo/apps/echo_mq/lib/echo_mq/consumer.ex` — the `spawn_link` drain loop (NOT a GenServer) that
     reap+promote+drain+park (`consumer.ex:91-98`); the lock plane is a SEPARATE opt-in process beside it (a
     consumer without it is the unchanged v2 worker), never folded in.
   - `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` — `queue_key/2` (`emq:{q}:<type>`, `keyspace.ex:14-15`),
     `job_key/2` (gated by `BrandedId.valid?/1`, `keyspace.ex:18-24`), `reserve/1` (the `{emq}:` reserve,
     `keyspace.ex:27`), the §6 grammar. The event channel + the stalled-count carrier are `queue_key` suffixes
     spelled against §6.
   - `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — the floor the watch plane built ON was **32 scenarios**
     (14 emq.0 → 18 emq.1 → 24 emq.2.1 → 32 emq.2.2); emq.2.3's **5** watch scenarios (`lock_extend`,
     `stalled`, `events`, `telemetry`, `cancel`) registered beside them, so `scenarios/0` is now **37**
     (`conformance.ex:25-65`); the 32 prior pass byte-unchanged. The two pinning tests carry the new total:
     `conformance_scenarios_test.exs` pins `@run_order` (37 names) via
     `Keyword.keys(Conformance.scenarios()) == @run_order` (`:56-57`); `conformance_run_test.exs` pins
     `Conformance.run(conn, q) == {:ok, 37}` behind `:valkey` (`:37`).
4. **The capability reference (the v1 watch surface to port — NEVER migrated from, NEVER literally copied)** —
   `echo/apps/echomq/lib/echomq/queue_events.ex` (`subscribe/2`@184, `unsubscribe/2`@192, `close/1`@200, the
   `@callback handle_event/3`@462 behaviour), `telemetry.ex` (`attach/4`@116, `attach_many/4`@134, `emit/3`@145/149,
   `span/3`@166; the six lifecycle helpers `job_added/4`@223, `job_started/4`@232, `job_completed/5`@242,
   `job_failed/6`@252, `job_retried/5`@263, `worker_started/3`@272), `lock_manager.ex` (`track_job/3`@62,
   `untrack_job/2`@70, `get_active_job_count/1`@78, `get_tracked_job_ids/1`@86, `is_tracked?/2`@94, the extend
   loop), `stalled_checker.ex` (`check/2`@110, `job_stalled?/4`@122 + the periodic sweep),
   `cancellation_token.ex` (`new/0`@107, `cancel/3`@117, `check/1`@140, `check!/1`@161) +
   `echo/apps/echomq/priv/scripts/{extendLock-2,extendLocks-2,releaseLock-1,moveStalledJobsToWait-9}.lua`.
   **These use v1 mechanisms** (a separate `…:lock` string, the caller clock, wait/active LISTs, a 9-key
   sweep, a v1 event transport) — emq.2.3 re-derives the *capability* against `echo_mq`'s real surface (the
   active-set score, the server `TIME`, the four sets, the connector pub/sub seam), it does NOT port the v1
   mechanism.
5. **The canon** — [`../emq.design.md`](../../../emq.design.md): §12.3 (the event-transport deferral — `SSUBSCRIBE`
   is the cache rung's; under completion-deletes the event record is the durable receipt), §5 (the closed
   wire-class registry — `EMQSTALE` reused for the extension stale refusal, **no new class**; the five-code
   fence union stands), §4 + DQ-2c (the server clock on any lease), §6 (the grammar — the event/lock/stalled
   keys are `queue_key` suffixes), S-4 (Valkey the gate).
6. **The shape precedent** — [`./emq.2.1.md`](emq.2.1.md) + [`./emq.2.1.llms.md`](emq.2.1.llms.md) +
   [`./emq.2.1.prompt.md`](emq.2.1.prompt.md) (the triad + brief + runbook shape; the inline-`Script.new/2`
   convention; the design-make-as-relocated-gate), and [`./emq.1.md`](../../emq.1/emq.1.md) (the `EchoMQ.Pump` opt-in
   process precedent + the ≥100 determinism loop a process rung runs).

## Requirements (each traced back to a story, forward to an invariant/check)

| # | Requirement | From | To |
| --- | --- | --- | --- |
| R1 | `EchoMQ.Events` — per-queue subscribe/unsubscribe/close + lifecycle delivery over the connector pub/sub seam; events published host-side after a transition verdict; auto-resubscribe across a reconnect; no new transport, no `SSUBSCRIBE` | US1 | INV2, INV1 · the events scenario |
| R2 | `EchoMQ.Meter` — attach/attach_many/emit/span over the `[:emq, …]` lifecycle (the v1 six re-rooted); zero cost when `:telemetry` is absent; the surface fires, the contract is emq.8 | US2 | INV6, INV1 · the telemetry scenario |
| R3 | The lock-extension verb on `EchoMQ.Jobs` — re-score the active member to `TIME`+lease, refuse `EMQSTALE` on a stale token (no new wire class), declared keys `[active, job_key]`, never a separate `…:lock` string; + a batch extension | US3 | INV3, INV4, INV5 · the lock-extend scenario |
| R4 | The worker-side lock plane — an opt-in supervised process (the `EchoMQ.Pump` shape): track/untrack, the read trio, extend-on-a-timer, release-on-completion; a consumer without it is the unchanged v2 worker | US4 | INV3, INV7 · the process suite + the determinism loop |
| R5 | The explicit stalled-sweep — `check`/`job_stalled?` + the periodic stall-count recovery over the four as-built sets under the server `TIME`; beyond the dead-lease reaper, not a replacement; never the v1 caller-clock / 9-key LIST shape | US5 | INV4, INV3, INV1 · the stalled scenario |
| R6 | The cooperative cancellation token — worker-side new/cancel/check/check!; the distributed cancel is emq.6 | US6 | INV7, INV5 |
| R7 | The watch-plane design recorded first: the event surface (placement + §6 channel + payload contract + host-side-vs-Lua emit) + the telemetry tree + the lock plane (verb + opt-in shape) + the stalled-count carrier; ≥2 steelmanned alternatives per fork; every new key against §6 | US7 | INV8, INV4 · the ledger |
| R8 | Every new Lua key declared-or-grammar-derived; the conformance registry grows additively (both pinning tests updated to 37); the 32 prior scenarios byte-unchanged; honest-row reporting; the ≥100 determinism loop for the process-touching suites | US8 | INV1, INV8, INV4 · the conformance run + the loop |

## Execution topology

**Runtime shape.** A watch layer above the wire, in two halves. **The observability half** — `EchoMQ.Events`
(a subscription surface + host-side publish over the connector `subscribe/2`/`unsubscribe/2` seam — the
`{:emq_push, …}` push, the resubscribe `MapSet`) and `EchoMQ.Meter` (an `attach`/`emit`/`span` wrapper
over `:telemetry`, re-rooted `[:emq, …]`, guarded zero-cost). **The recovery half** — the lock-extension verb
on `EchoMQ.Jobs` (a new inline `Script.new/2` transition: re-score the active member to `TIME`+lease,
`EMQSTALE` on a stale token, declared keys), the worker-side lock plane (a **NEW opt-in supervised process**,
the `EchoMQ.Pump` `:transient`/owner-started shape with a pure decision core + a timer), the explicit
stalled-sweep (a new inline `Script.new/2` script over the four sets under `TIME` + a `check`/`job_stalled?`
surface), and the cooperative cancellation token (a host-side primitive — `new`/`cancel`/`check`, no wire
identity). **The lock plane + the stalled sweep are the process-touching surfaces** → the ≥100 determinism
loop applies (R4/R5/R8); the events/telemetry/extension verb/token are synchronous or host-side.

**Build-order task DAG.**
1. **D1 design-make (gate)** — adopt the carve (ADR-1/3/4); rule the event surface (placement + the §6
   channel name + the payload contract + host-side-vs-Lua emit — recommended host-side, transition scripts
   byte-unchanged), the telemetry `[:emq, …]` tree, the lock plane (the extension verb's name/return + the
   opt-in supervised process shape), the stalled-count carrier; spell every new key against §6. Log each as a
   `tool_x_decision`.
2. **D4 the lock-extension verb** → a new inline transition on `EchoMQ.Jobs` (depends on D1's name/return;
   the `@claim` re-score + the `@complete` `EMQSTALE` patterns are the precedent). **First of the recovery
   half** because D5 drives it.
3. **D5 the worker-side lock plane** → a new opt-in `:transient` process (depends on D4 — it calls the verb on
   a timer; the `EchoMQ.Pump` shape; a pure decision core for the extend interval).
4. **D6 the explicit stalled-sweep** → a new inline script + `check`/`job_stalled?` (depends on D1's
   stall-count carrier; over the four sets under `TIME`; beyond `reap/2`).
5. **D2 `EchoMQ.Events`** → the subscription surface + host-side publish (depends on D1's channel + payload
   contract + the connector seam; independent of the recovery half).
6. **D3 `EchoMQ.Meter`** → the `attach`/`emit`/`span` surface (depends on D1's event tree; the
   `Connector.emit/3` zero-cost precedent).
7. **D7 the cooperative cancellation token** → a host-side `new`/`cancel`/`check`/`check!` (independent).
8. **D8 proof** → the conformance scenarios + probes for each watch verb; pure + `:valkey` + process suites;
   the 32 prior byte-unchanged (→ 37 live); both pinning tests re-pinned; the ≥100 loop for the process suites.

**Exact files touched** (as-built — the file name keeps the v1 *concept*, the module is the collision-free name; this file/module-name divergence is the recorded carry C1):
- `echo/apps/echo_mq/lib/echo_mq/events.ex` — NEW (`EchoMQ.Events` — subscribe/unsubscribe/close + host-side
  `publish/5` + `channel/1` + `event_name/1` over the connector seam).
- `echo/apps/echo_mq/lib/echo_mq/telemetry.ex` — NEW (**`EchoMQ.Meter`** — attach/emit/span + the six
  lifecycle helpers, `[:emq, …]`).
- `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — the lock-extension verb `extend_lock/5` + the batch `extend_locks/4`
  + their inline `@extend_lock`/`@extend_locks` `Script.new/2`.
- `echo/apps/echo_mq/lib/echo_mq/lock_manager.ex` — NEW (**`EchoMQ.Locks`** — the opt-in supervised lock
  plane) + `echo/apps/echo_mq/lib/echo_mq/lock_manager/core.ex` (**`EchoMQ.Locks.Core`** — the pure
  extend-interval arithmetic; the build DID mirror the `EchoMQ.Pump` split).
- `echo/apps/echo_mq/lib/echo_mq/stalled_checker.ex` — NEW (**`EchoMQ.Stalled`** — `check/3`/`job_stalled?/4` +
  the supervised periodic sweep + the inline `@sweep_stalled` `Script.new/2`).
- `echo/apps/echo_mq/lib/echo_mq/cancellation_token.ex` — NEW (**`EchoMQ.Cancel`** — host-side
  `new/0` (a `make_ref()`) / `cancel/3` / `check/1` / `check!/1` + the `EchoMQ.Cancel.Cancelled` exception).
- `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — the 5 watch scenarios registered in `scenarios/0` (now 37).
- `echo/apps/echo_mq/test/` — the new pure + `:valkey` + process suites; `conformance_scenarios_test.exs` +
  `conformance_run_test.exs` re-pinned to `{:ok, 37}` + the 37-name `@run_order`.
- `echo/apps/echo_wire/lib/echo_wire.ex` — UNCHANGED (the events ride the existing `subscribe`/`unsubscribe`
  delegates at `echo_wire.ex:26-27` — no facade change, as predicted).
- **`apps/echomq` untouched** (the capability reference). No third app touched. `echo/mix.lock` unchanged
  (emq.2.3 added no dep — `:telemetry` is a transitive umbrella dep used guarded by `function_exported`, the
  `Connector.emit/3` precedent).

## Agent stories (Directive + Acceptance gate — contracts, not tasks)

- **AS-1 — the design-make (the relocated gate).** *Directive:* adopt the carve (ADR-1/3/4); rule the event
  surface (placement + the §6 channel name + the payload contract + host-side-vs-Lua emit), the telemetry
  `[:emq, …]` tree, the lock plane (the extension verb's name/return + the opt-in supervised process shape),
  and the stalled-count carrier — each a `tool_x_decision` citing the design §; spell every new key against §6.
  *Acceptance gate:* each fork is recorded with ≥2 steelmanned alternatives; the event channel + the lock keys
  + the stalled-count carrier are §6-spelled `queue_key` suffixes (or the `{emq}:` reserve); the lock-extension
  reuses `EMQSTALE` (no new wire class); no `.ex`/Lua artifact predates the ledger entry (INV8).
- **AS-2 — `EchoMQ.Events`.** *Directive:* build the per-queue subscription surface (subscribe/unsubscribe/
  close + lifecycle delivery) over the connector `subscribe/2`/`unsubscribe/2` seam; publish lifecycle events
  host-side after a transition verdict; keep the feed live across a reconnect (the resubscribe set).
  *Acceptance gate:* a subscriber receives a lifecycle event over the `{:emq_push, …}` push; a dropped socket
  re-issues the subscription and the feed answers again; no new transport, no `SSUBSCRIBE`; an events scenario
  passes (INV2, INV1).
- **AS-3 — `EchoMQ.Meter`.** *Directive:* build attach/attach_many/emit/span over the `[:emq, …]`
  lifecycle (the v1 six re-rooted); guard emission zero-cost when `:telemetry` is absent (the
  `Connector.emit/3` precedent). *Acceptance gate:* an attached handler receives a lifecycle `[:emq, …]`
  event; emission costs nothing with no `:telemetry`; the surface fires (the contract is emq.8 — not asserted
  here); a telemetry scenario passes (INV6, INV1).
- **AS-4 — the lock-extension verb.** *Directive:* build a new inline `Script.new/2` transition on
  `EchoMQ.Jobs` that re-scores the active member to `TIME`+lease and refuses `EMQSTALE` on a stale token,
  under declared keys `[active, job_key]`; + a batch extension. *Acceptance gate:* an extended lease is NOT
  reaped past its original deadline; a stale token refuses `EMQSTALE` mapped to `{:error, :stale}`; the verb
  re-scores the active member (never a `…:lock` string); the batch answers the ids it could not extend; a
  lock-extend scenario passes (INV3, INV4, INV5).
- **AS-5 — the worker-side lock plane.** *Directive:* build an opt-in `:transient` supervised process (the
  `EchoMQ.Pump` shape — owner-started, no `mod:`, a pure decision core for the extend interval, a timer):
  track/untrack held jobs, the read trio, extend-on-a-timer (call AS-4's verb), release-on-completion.
  *Acceptance gate:* the plane extends a tracked job's lease before it elapses and untracks on completion (no
  double-retire); the read trio answers the tracked set; a consumer WITHOUT the plane is the unchanged v2
  worker; the process suite passes under the ≥100 determinism loop (INV3, INV7).
- **AS-6 — the explicit stalled-sweep.** *Directive:* build `check`/`job_stalled?` + a new inline sweep script
  over the four sets under `TIME` that distinguishes a dead-lease reap from a stall-count threshold (recover
  or dead-letter past `max_stalled`); register the stall-count carrier against §6; declare only the sets it
  touches. *Acceptance gate:* a lease that expired without extension is marked stalled; a past-threshold job
  is recovered/dead per the threshold; the sweep reads `TIME` (never a caller clock) and declares its keys
  (never the v1 9-key LIST shape); beyond the reaper, not a replacement; a stalled scenario passes (INV4,
  INV3).
- **AS-7 — the cooperative cancellation token.** *Directive:* build a host-side `new/0`/`cancel/3`/`check/1`/
  `check!/1`. *Acceptance gate:* a cancelled token answers cancelled (`check!/1` raises typed); an
  un-cancelled token answers not-cancelled; it is the worker-side primitive only (the distributed cancel is
  emq.6); a pure suite passes (INV7, INV5).
- **AS-8 — proof.** *Directive:* register a conformance scenario + probe for every watch verb (lock-extend,
  stalled, events, telemetry, cancel); run pure + `:valkey` + process suites; keep the 32 prior scenarios
  byte-unchanged; re-pin BOTH pinning tests to the new total (37) + `@run_order`; run the ≥100 determinism loop
  for the process-touching suites; report honest-row. *Acceptance gate:* `EchoMQ.Conformance.run/2` answers
  `{:ok, 37}`, the 32 prior verdicts identical; both pinning tests re-pinned; the loop owns
  the machine and stays green; Valkey on 6390 the truth row (INV1, INV8).

## The comprehensive prompt (leaves no decision the spec has not fixed)

Build emq.2.3 — the bus's **watch plane** — inside `echo/apps/echo_mq` (reading the one named
`echo/apps/echo_wire` connector pub/sub seam), to [`./emq.2.3.md`](emq.2.3.md) (authoritative) and the carve
[`./emq.2.design.md`](../emq.2.design.md) (ADR-1/2/3/4), under the v2 master invariant (braced `emq:{q}:` ·
branded `JOB` ids gated at the key builder · every Lua key declared-or-rooted · **server clock where a lease
is touched** — emq.2.3's lock-extension verb + the stalled sweep DO touch a lease, so read `TIME` inside the
script · honest-row conformance · additive-minor protocol). FIRST run the design-make (AS-1): rule the event
surface (the `EchoMQ.Events` placement + the §6 event channel name — a `queue_key` suffix, e.g.
`emq:{q}:events` — + the event payload contract + the host-side-vs-Lua emit ruling, recommended **host-side**
after a transition verdict so the transition scripts stay byte-unchanged), the telemetry `[:emq, …]` event
tree (the v1 six re-rooted), the lock plane (the lock-extension verb's name/return + the worker-side
lock-plane process name + its **opt-in supervised** shape — the `EchoMQ.Pump` `:transient`/owner-started
precedent), and the stalled-count carrier (distinct from the dead-lease reaper). The v1 `echomq` watch
modules + scripts are the **capability reference** — what to port — never a literal copy and never a thing
migrated from: the v2 lease is the `active` sorted-set score (the lock-extension verb re-scores it — **never**
a separate `…:lock` string), the event plane rides the **existing** connector pub/sub seam (**no new
transport, no `SSUBSCRIBE`** — design §12.3), the clock is the server's `TIME` (never the caller's), and the
stalled recovery is over the four as-built sets (never the v1 wait/active LISTs or the 9-key sweep). Build:
the lock-extension verb (D4 — re-score the active member to `TIME`+lease, refuse `EMQSTALE` on a stale token —
the existing fencing-token class, **no new wire class** — declared keys `[active, job_key]`; + a batch
extension); the worker-side lock plane (D5 — an opt-in `:transient` process that tracks held jobs, extends on
a timer, releases on completion; a consumer without it is the unchanged v2 worker); the explicit stalled-sweep
(D6 — `check`/`job_stalled?` + a periodic stall-count recovery over the four sets under `TIME`, beyond the
reaper); `EchoMQ.Events` (D2 — subscribe/unsubscribe/close + host-side lifecycle publish over the connector
seam, auto-resubscribe across a reconnect); `EchoMQ.Meter` (D3 — attach/attach_many/emit/span over the
`[:emq, …]` lifecycle, zero-cost when `:telemetry` is absent — the surface fires; the **contract** is emq.8,
ADR-2's two-layer split — do NOT ship emq.8's proof); the cooperative cancellation token (D7 — worker-side
new/cancel/check/check!; the **distributed** cancel is emq.6 — do NOT ship it). New scripts follow the inline
`Script.new/2` convention (there is **no `priv/`** in `echo_mq`). Register a conformance scenario + probe for
every watch verb in the same change (the additive-minor law — a lock-extend, a stalled, an events, a
telemetry, and a cancel scenario, **5** in all); the **32 prior scenarios pass byte-unchanged**
(14 emq.0 → 18 emq.1 → 24 emq.2.1 → 32 emq.2.2) and BOTH pinning tests
(`conformance_scenarios_test.exs` `@run_order` + `conformance_run_test.exs` `{:ok, 37}`) carry the new
total of **37**. Compile clean (`--warnings-as-errors`, per-app); pure + `:valkey` + process suites green
(`TMPDIR=/tmp`, Valkey 6390 PONG first); the **≥100-iteration determinism loop** for the process-touching
suites (the lock plane + the stalled sweep — one green run is not proof, the loop owns the machine); honest-row
reporting. Keep the diff inside `echo_mq` (+ a facade delegate only if needed — expect none, the events ride
the existing `subscribe`/`unsubscribe` delegates); `apps/echomq` is untouched. Cite the spec/design line for
every public call; invent no transport, no lock key, no clock the design does not register; report any
realization-over-literal deviation. Author DOCS-free code (the spec is the doc); run no git.

---
The contract: [`./emq.2.3.md`](emq.2.3.md). The stories: [`./emq.2.3.stories.md`](emq.2.3.stories.md).
The runbook: [`./emq.2.3.prompt.md`](emq.2.3.prompt.md). The carve: [`./emq.2.design.md`](../emq.2.design.md).
The canon: [`../emq.design.md`](../../../emq.design.md). The capability reference:
`echo/apps/echomq/lib/echomq/{queue_events,telemetry,lock_manager,stalled_checker,cancellation_token}.ex` +
the scripts. The as-built floor: `echo/apps/echo_mq/lib/echo_mq/{jobs,consumer,pump,keyspace,conformance}.ex`
+ `echo/apps/echo_wire/lib/echo_mq/connector.ex` (the pub/sub seam + `emit/3`).
