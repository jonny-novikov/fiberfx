# EMQ.2.3 · user stories

> Who wants the watch plane, what they need, and how acceptance is known. Derived from
> [`./emq.2.3.md`](emq.2.3.md) (BUILT — acceptance has run at the build run). The
> consumer ground is the bus's observers and long-running consumers — an operator dashboard, a consumer's
> telemetry, a long-running handler, an operator's recovery sweep, the conformance harness. The capability
> ground is the v1 `echomq` watch surface (`EchoMQ.QueueEvents`, `EchoMQ.Telemetry`, `EchoMQ.LockManager`,
> `EchoMQ.StalledChecker`, `EchoMQ.CancellationToken`) and its scripts, ported onto `echo_mq`'s as-built
> structures (never the v1 transport, lock key, or clock) — and built there under collision-free module names:
> `EchoMQ.Events`, **`EchoMQ.Meter`**, **`EchoMQ.Locks`**, **`EchoMQ.Stalled`**, **`EchoMQ.Cancel`** (the
> lock-extension verbs live on `EchoMQ.Jobs`).

## EMQ.2.3-US1 — subscribe to the work, not the keys

As an operator dashboard reading queue health, I want to subscribe to a queue's lifecycle events (completed,
failed, scheduled, stalled), so that the dashboard reacts to work as it happens without polling the sets, and
the feed survives a dropped socket.

Acceptance criteria
- Given a subscribed consumer, when a job's lifecycle transition fires (e.g. completed/failed), then the
  subscriber receives the lifecycle event over the as-built connector pub/sub seam (the `{:emq_push, …}`
  message), and the event names match the D1 contract — never a v1-shaped event the bus does not emit.
- Given a dropped socket, when the connector reconnects, then the recorded subscription is re-issued (the
  emq.1 auto-resubscribe set) and the feed answers again without a caller restart — the push channel's
  at-most-once honesty is stated, not papered over.
- Given the event plane, when it runs, then it rides the **existing** seam — no new transport, no
  `SSUBSCRIBE` (design §12.3) — and the durable replayable stream stays emq3.2.

INVEST — independent of telemetry; testable by a `:valkey` suite that subscribes and kills the socket;
encodes EMQ.2.3-INV2, EMQ.2.3-INV1.
Priority: must · Size: 5 · Implements deliverables: EMQ.2.3-D2.

## EMQ.2.3-US2 — attach a meter to the lifecycle

As the platform's telemetry owner, I want to attach a `:telemetry` handler to the job lifecycle under a
stable `[:emq, …]` event tree, so that throughput, latency, and failure counts are metered the standard
Elixir way, at zero cost when telemetry is not loaded.

Acceptance criteria
- Given an attached handler, when a job is added / started / completed / failed / retried (or a worker
  starts), then the handler receives the corresponding `[:emq, …]` event (the v1 six re-rooted — e.g.
  `[:emq, :job, :completed]`), with the D1 event tree.
- Given no `:telemetry` dependency loaded, when the lifecycle fires, then emission costs nothing (the
  as-built `Connector.emit/3` precedent — guarded by `:erlang.function_exported/3`).
- Given the surface, when it fires, then it ships the **surface only** — the telemetry contract (the
  payload-shape assertions, the matrix) is emq.8, not asserted here (the two-layer split).

INVEST — independent of the event stream; testable by a `:valkey` suite attaching a handler;
encodes EMQ.2.3-INV6, EMQ.2.3-INV1.
Priority: must · Size: 3 · Implements deliverables: EMQ.2.3-D3.

## EMQ.2.3-US3 — keep my lease while I work

As a long-running handler, I want to extend my job's lease before it expires, so that a slow-but-alive job is
not reaped mid-work, and a stale token is refused so I cannot extend a lease I no longer hold.

Acceptance criteria
- Given a claimed job with a live token, when the lock-extension verb runs, then the `active`-set member is
  re-scored to a fresh deadline computed from the **server clock** (`TIME` inside the script — never the
  caller's), and the reaper does NOT reclaim the job past its original deadline.
- Given a stale attempts-token, when the extension runs, then it is refused **`EMQSTALE`** (the existing
  fencing-token wire class — no new class), mapped client-side to a typed `{:error, :stale}`; the five-code
  fence union stands unextended.
- Given the verb, when it runs, then it re-scores the active member (the v2 lease IS that score) — **never** a
  separate `…:lock` string — under declared keys `[active, job_key]`; a batch extension answers the ids whose
  lease could not be extended.

INVEST — independent of the worker-side plane (the verb is callable directly); testable by a `:valkey` suite;
encodes EMQ.2.3-INV3, EMQ.2.3-INV4, EMQ.2.3-INV5.
Priority: must · Size: 5 · Implements deliverables: EMQ.2.3-D4.

## EMQ.2.3-US4 — a plane that holds my leases for me

As a consumer author running long jobs, I want an opt-in worker-side lock plane that tracks held jobs and
extends their leases on a timer, so that I do not hand-roll a lease-extender, and a worker that does not opt
in is the unchanged v2 worker.

Acceptance criteria
- Given the lock plane tracking a held job, when its timer beats, then it calls the lock-extension verb for
  each tracked job before its lease elapses; on completion the plane untracks the job (it does not
  double-retire — the `complete`/`retry` transition already retires the score).
- Given the read surface, when queried, then `get_active_job_count`/`get_tracked_job_ids`/`is_tracked?` answer
  the tracked set; `track`/`untrack` add and remove a job by id + attempts-token.
- Given a consumer started **without** the lock plane, when it runs, then it is the unchanged v2 worker (the
  opt-in law — the `EchoMQ.Pump` `:transient`/owner-started precedent; no `mod:` auto-start).

INVEST — depends on EMQ.2.3-D4 (the verb it drives); testable by a process suite under the determinism loop;
encodes EMQ.2.3-INV3, EMQ.2.3-INV7.
Priority: must · Size: 5 · Implements deliverables: EMQ.2.3-D5.

## EMQ.2.3-US5 — reclaim the genuinely stalled, not the merely slow

As an operator running a recovery sweep, I want an explicit stalled-recovery that distinguishes a job whose
lease expired without extension from a dead lease the reaper already reclaims, so that a job that crosses the
stall-count threshold is recovered or dead-lettered, on the server's clock.

Acceptance criteria
- Given a job whose lease expired without extension, when the sweep runs, then the job is marked stalled; one
  that crosses the configured `max_stalled` threshold is recovered (back to pending) or dead-lettered per the
  threshold (the v1 `moveStalledJobsToWait` capability, re-derived).
- Given the sweep, when it runs, then it reads the server clock (`TIME` — never the v1 caller-clock
  timestamp), declares only the sets it touches in `KEYS[]` (never the v1 9-key LIST shape), and registers
  its stall-count carrier against §6.
- Given `check/3`/`job_stalled?/4`, when called, then `check` (`conn, queue, opts` — the `:max_stalled`/
  `:limit` keyword carrier) runs one sweep and `job_stalled?` answers whether a job is stalled — beyond the
  as-built dead-lease reaper, not a replacement for it.

INVEST — independent of the events/telemetry; testable by a process suite that lets a lease lapse;
encodes EMQ.2.3-INV4, EMQ.2.3-INV3, EMQ.2.3-INV1.
Priority: should · Size: 5 · Implements deliverables: EMQ.2.3-D6.

## EMQ.2.3-US6 — stop cooperatively, in-flight

As a cooperative handler, I want a cancellation token I can check at a safe point, so that a long job stops
its own work when asked, without a forced kill mid-transaction.

Acceptance criteria
- Given a token, when `new/0` mints it and `cancel/3` flags it (with an optional reason), then `check/1`
  answers cancelled and `check!/1` raises a typed cancellation; an un-cancelled token answers not-cancelled.
- Given a handler checking the token at a safe point, when it is cancelled, then the handler stops its own
  work cooperatively (no forced kill).
- Given the token, when it runs, then it is the **worker-side** cooperative primitive only — the
  **distributed** cancel (issued from another node, coordinated across the cluster) is emq.6, not exercised
  here.

INVEST — independent of the wire surfaces (host-side, no wire identity); testable by a pure suite;
encodes EMQ.2.3-INV7, EMQ.2.3-INV5.
Priority: should · Size: 2 · Implements deliverables: EMQ.2.3-D7.

## EMQ.2.3-US7 — the design gate before any build

As the Operator, I want the watch-plane design — the event surface (placement + the §6 channel + the payload
contract + where events emit), the telemetry `[:emq, …]` tree, the lock plane (the extension verb + the
opt-in process shape), and the stalled mechanism — recorded BEFORE any build story runs, so that the rung
rides `echo_mq`'s real seam and invents no v1-shaped transport, lock key, or clock.

Acceptance criteria
- Given the design gate, when the build run opens, then the event placement + the §6 channel name + the
  payload contract + the host-side-vs-Lua emit ruling, the telemetry event tree, the lock-extension verb's
  name/return + the opt-in supervised process shape, and the stalled-count carrier are each recorded with ≥2
  steelmanned alternatives where a fork exists, and no `.ex`/Lua artifact predates the ledger entry.
- Given the approved design, when the build lands, then the declared-keys analysis passes over every new Lua
  script (the lock-extension's, the stalled sweep's), and the event/lock/stalled keys are §6-spelled.

INVEST — the opening story, blocking all build stories; testable from the ledger + the analysis run;
encodes EMQ.2.3-INV8, EMQ.2.3-INV4.
Priority: must · Size: 3 · Implements deliverables: EMQ.2.3-D1.

## EMQ.2.3-US8 · EMQ.2.3-US-GATE — the Valkey gate, specification by example

As the Operator, I want every emq.2.3 watch verdict registered with a conformance probe and proven against
the truth row, with the process-touching suites under the determinism loop, so that the protocol grows by
additive minors only and the watch verdicts stay a parse, not prose.

Acceptance criteria
- Given the build, when the conformance suite runs against Valkey on 6390, then the prior **32** scenarios
  (14 emq.0 → 18 emq.1 → 24 emq.2.1 → 32 emq.2.2) pass byte-unchanged and the **5** new watch scenarios
  (lock-extend, stalled, events, telemetry, cancel) pass beside them — the registry grows additively and
  `EchoMQ.Conformance.run/2` answers `{:ok, 37}`; both pinning tests (the `@run_order` registry pin and the
  `{:ok, 37}` run pin) carry the new total in the same change.
- Given the lock plane + the stalled sweep run on timers, when the process-touching suites run, then they run
  the **≥100-iteration determinism loop** (one green run is not proof — the master-invariant gate ladder),
  and the loop owns the machine (no concurrent liveness server, no sibling heavy I/O).
- Given a host without the truth row, when probes run elsewhere, then results report as that row, never as the
  truth row (honest-row reporting — design §1 S-4).

INVEST — standing (the design §7 per-rung twin); testable by one tagged conformance run + the loop;
encodes EMQ.2.3-INV1, EMQ.2.3-INV8.
Priority: must · Size: 3 · Implements deliverables: EMQ.2.3-D8.

---
Coverage: D1→US7 · D2→US1 · D3→US2 · D4→US3 · D5→US4 · D6→US5 · D7→US6 · D8→US8.
Spec: [`./emq.2.3.md`](emq.2.3.md) · Agent brief: [`./emq.2.3.llms.md`](emq.2.3.llms.md) ·
Carve: [`./emq.2.design.md`](../emq.2.design.md).
