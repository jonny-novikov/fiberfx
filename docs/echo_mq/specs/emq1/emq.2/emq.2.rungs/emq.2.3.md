# EMQ.2.3 · The watch plane — Movement I, the parity floor (observability & recovery)
> ✅ **Shipped** — the as-built deliverable (verbs · conformance delta · commit) is in the [changelog](../../../../emq.changelog.md). This body is the historical spec.

> **Status: BUILT** (the third and final rung of the emq.2 full-parity cluster; the carve + the
> ADRs are [`./emq.2.design.md`](../emq.2.design.md)). emq.2.3 builds,
> inside `echo/apps/echo_mq` (with the one named `echo/apps/echo_wire` connector seam it reads), the **watch
> plane** of the bus — the observability and lease-recovery surface an operator dashboard, a consumer's
> telemetry, and a long-running handler stand on. It ports the v1 `echomq` watch capabilities (the per-queue
> event stream, the `:telemetry` attach/emit/span surface, the worker-side lock plane with lease extension,
> the explicit stalled-recovery sweep, the cooperative cancellation token) onto `echo_mq`'s **as-built**
> structures (the four sorted sets, the three-field row, the connector pub/sub seam, the server-clock lease)
> — inventing no v1-shaped transport, lock key, or clock the bus does not have. The v1 line (`apps/echomq`)
> is a **capability reference** — the list of watch surfaces to port — never a thing migrated from. This is
> the rung that **completes the lease lifecycle** (server-side reap is shipped; worker-side extend is new)
> and **lights up the observability plane** over the transitions emq.2.1/2.2 expose; it watches the surface
> the first two parity rungs complete.

## Goal

emq.2.3 builds the bus's watch surface: the event-and-telemetry plane that publishes the lifecycle of work,
and the recovery plane that keeps a live handler's lease and reclaims a dead one. The capability reference
is the frozen v1 line's watch surface — the event stream (`EchoMQ.QueueEvents` — `subscribe/2`/
`unsubscribe/2`/`close/1` + the `handle_event/3` behaviour, `apps/echomq/lib/echomq/queue_events.ex`), the
telemetry surface (`EchoMQ.Telemetry` — `attach/4`/`attach_many/4`/`emit/3`/`span/3` + the lifecycle helpers
`job_added`/`job_started`/`job_completed`/`job_failed`/`job_retried`/`worker_started`, `telemetry.ex`), the
worker-side lock plane (`EchoMQ.LockManager` — `track_job/3`/`untrack_job/2`/`get_active_job_count/1`/
`get_tracked_job_ids/1`/`is_tracked?/2` + the extend loop, `lock_manager.ex`, with `extendLock-2.lua`/
`extendLocks-2.lua`/`releaseLock-1.lua`), the explicit stalled-recovery (`EchoMQ.StalledChecker` — `check/2`,
`job_stalled?/4` + the periodic sweep, `stalled_checker.ex`, with `moveStalledJobsToWait-9.lua`), and the
cooperative cancel (`EchoMQ.CancellationToken` — `new/0`/`cancel/3`/`check/1`/`check!/1`,
`cancellation_token.ex`). emq.2.3 re-derives those capabilities against `echo_mq`'s real surface — **not** the
v1 mechanism: the v2 lease is the `active` sorted-set score (not a separate `…:lock` string), the event
plane rides the connector's existing pub/sub seam (not a new transport), the clock is the server's `TIME`
(not the caller's), and the recovery is over the four as-built sets (not the v1 wait/active LISTs). Every new
key is declared in `KEYS[]` or grammar-derived (the master invariant); the lock-extension verb is a
transition under the server clock with an `EMQSTALE` typed refusal on a stale token (the existing wire
class — no new class); the event-and-telemetry surface fires events but does not assert their contract (the
telemetry **contract** proof stack is emq.8 — ADR-2's two-layer split); every addition registers a
conformance scenario in the same change (the additive-minor law).

## Rationale (5W)

- **Why** — `echo_mq` ships the state machine, the lanes, the cadence, and (after emq.2.1/2.2) the read and
  operator planes, but has **no watch surface**: a consumer cannot subscribe to "job completed / failed", the
  platform cannot attach a `:telemetry` handler to the job lifecycle, a long-running handler cannot keep its
  lease (so a slow-but-alive job is reaped today — the as-built `Jobs.reap/2` is a server-side dead-lease
  scan with no worker-side counterpart), there is no explicit stalled-recovery distinct from the single-scan
  reaper, and a worker cannot cooperatively cancel an in-flight job. The v1 line carries all five — and the
  program's parity thesis ([`../emq.roadmap.md`](../../../../emq.roadmap.md) Movement I) requires `echo_mq` to carry
  them before `apps/echomq` can dissolve. The parity carve ([`./emq.2.design.md`](../emq.2.design.md) ADR-1)
  places the watch plane **third** because it watches the surface the first two rungs complete: the events
  fire on the transitions emq.2.2 added (pause/drain/obliterate/update/remove) and the lifecycle emq.1
  shipped (enqueue/claim/complete/retry/dead); the telemetry spans the verbs emq.2.1/2.2 expose; the
  stalled-recovery's verdicts read through emq.2.1's state lookups. The front door records the consumer
  story: "the event/telemetry plane the platform observes the work surface through"
  ([`../echo_mq.md`](../../../../echo_mq.md), the reframed emq.2 row).
- **What** — emq.2.3 builds, inside `echo_mq`: **`EchoMQ.Events`**, the per-queue event subscription surface
  over the as-built connector `subscribe/2`/`unsubscribe/2` pub/sub seam (the emq.1 auto-resubscribe set
  keeps it live across a reconnect), publishing lifecycle events the transitions emit; **`EchoMQ.Meter`**,
  the `:telemetry` attach/attach_many/emit/span surface over the same lifecycle, re-rooted `[:emq, …]`; **a
  lock-extension verb on `EchoMQ.Jobs`** that re-scores the active-set member to a fresh lease deadline from
  the server clock and refuses `EMQSTALE` on a stale attempts-token; **a worker-side lock plane** (the v1
  `EchoMQ.LockManager` capability, built as **`EchoMQ.Locks`** — track held jobs, extend on a timer, release
  on completion) ported as an opt-in supervised process beside the consumer; **the explicit stalled-sweep**
  (the v1 `EchoMQ.StalledChecker` capability, built as **`EchoMQ.Stalled`** — a periodic recovery
  distinguishing a reaped dead lease from a stalled-count threshold, beyond the as-built single-scan reaper);
  and **the cooperative cancellation token** (the worker-side half, built as **`EchoMQ.Cancel`** —
  `new`/`cancel`/`check`). The exact verb-and-event set traces to the v1 watch surface (Deliverables below);
  no watch surface here is invented, and the **distributed** cancel + the **durable replayable event stream**
  are explicitly out of scope (emq.6 and emq3.2 — ADR-2/ADR-4).
- **Who** — the bus's observers and long-running consumers: an operator dashboard subscribing to completed/
  failed events and plotting throughput from telemetry, a consumer attaching a `:telemetry` handler to the
  job lifecycle, a long-running handler extending its lease so it is not reaped mid-work, an operator's
  recovery sweep reclaiming genuinely stalled jobs, and a cooperative handler checking a cancellation token
  at a safe point. A worked consumer like codemojex observes its work surface through exactly this kind of
  event-and-telemetry plane (it publishes a `scored` event per guess through `EchoMQ.Events`; the dashboard's
  live feed). emq.6's **distributed** cancel coordinates the local cooperative token this rung ships; emq.8's
  proof stack asserts the telemetry **contract** over the surface this rung fires (ADR-2's two-layer split).
  No single consumer rung *gates* on emq.2.3 by name (it is the floor, not a feature), recorded not asserted.
- **When** — Movement I, after emq.1 closes and the emq.2 cluster's read (emq.2.1) and operator (emq.2.2)
  planes land, **last of the emq.2 cluster** (emq.2.1 → emq.2.2 → emq.2.3;
  [`./emq.2.design.md`](../emq.2.design.md) ADR-1's dependency order). BUILT — the watch plane lives in
  `echo_mq` and the 37-scenario harness is green against Valkey on 6390.
  The parity carve's one open sequencing fork (does the Operator keep the cluster to the floor, Arm A, or
  pull the feature families in, Arm B — design §6) settled to **Arm A** (the floor) for this rung; the carve is
  the one this triad is authored to.
- **Where** — `echo/apps/echo_mq` (the event/telemetry/lock/stalled/cancel modules + the lock-extension and
  stalled scripts as inline `Script.new/2` attributes — the as-built convention, **not** `priv/`; the new
  conformance scenarios in `conformance.ex`; the pure + `:valkey` suites + the process suites), reading the
  one named `echo/apps/echo_wire` connector seam (`subscribe/2`/`unsubscribe/2`, the `{:emq_push, …}` message,
  the resubscribe set) — the event plane rides it, it is not modified. `apps/echomq` is untouched (the
  capability reference). Exact key, structure, and script anchors beyond those cited here are pinned at the
  rung's pre-build reconcile (the lag-1 discipline) — emq.1's and emq.2.1/2.2's earlier builds move the
  `echo_mq` surface before emq.2.3 watches it.

## Scope

- **In** — `EchoMQ.Events`: per-queue event subscription over the connector pub/sub seam
  (`subscribe`/`unsubscribe`/`close` + a `handle_event/3`-style delivery), publishing lifecycle events
  (completed/failed/scheduled/stalled/… — the exact set ruled at D1) the transitions emit; auto-resubscribe
  across a reconnect (the emq.1 set). `EchoMQ.Meter`: `attach`/`attach_many`/`emit`/`span` over the job
  lifecycle, re-rooted `[:emq, …]` (the v1 `job_added`/`job_started`/`job_completed`/`job_failed`/
  `job_retried`/`worker_started` capability). The **lock-extension verb** on `EchoMQ.Jobs` (re-score the
  active-set member to `TIME`+lease; `EMQSTALE` on a stale token; declared keys), plus a batch extension (the
  `extendLocks` capability). The **worker-side lock plane** (`track`/`untrack`/`get_active_job_count`/
  `get_tracked_job_ids`/`is_tracked?` + extend-on-a-timer + release-on-completion) as an opt-in supervised
  process. The **explicit stalled-sweep** (`check`/`job_stalled?` + the periodic recovery with a stall-count
  threshold, distinct from the dead-lease reaper). The **cooperative cancellation token** (worker-side
  `new`/`cancel`/`check`/`check!`). Pure + `:valkey` + process suites; the conformance scenarios + probes
  registering each verdict.
- **Out** — any **new event transport / `SSUBSCRIBE`** (the event plane rides the existing connector pub/sub
  seam — design §12.3 defers `SSUBSCRIBE` to the cache rung's invalidation bus); the **durable replayable
  event stream** with ids and range reads (emq3.2's `EchoMQ.Stream` — the 3.x tier; emq.2.3 ships the v1-parity
  pub/sub subscription, not the durable stream); the **telemetry contract proof stack** (the matrix + the
  contract assertions over the events — emq.8; emq.2.3 ships the surface that *fires*, ADR-2's two-layer
  split); the **distributed** cancel / per-worker TTL / checkpoints (emq.6 — emq.2.3 ships the local
  cooperative token); the v1 **separate `…:lock` string key** (the v2 lease IS the `active` sorted-set score;
  the extension re-scores it — never a parallel lock string); the v1 **caller-clock** stalled timestamp (the
  v2 recovery reads the server `TIME`); the v1 **wait/active LISTs** (the bus is four sorted sets); the v1
  **9-key `moveStalledJobsToWait` shape** (the v2 sweep declares only the sets it touches under §6); any
  **new wire-class** (the lock-extension stale refusal reuses the existing `EMQSTALE`; the five-code fence
  union stands unextended); any **state-machine rebuild** (the transitions are emq.1/emq.2.2's, read and
  observed, not rewritten); any wire break; any edit to the frozen v1 line.

## Deliverables

emq.2.3 builds (forward-named; nothing below exists in `echo_mq` yet — the watch surface lives only in the
frozen `apps/echomq` reference):

- **EMQ.2.3-D1** — **the design-make gate (FIRST):** the watch-plane design adopting
  [`./emq.2.design.md`](../emq.2.design.md)'s carve (ADR-1, ADR-3, ADR-4) and the rulings needed before the
  build — (a) **the event surface**: the `EchoMQ.Events` placement, the event channel name (a `queue_key`
  suffix spelled against §6, e.g. `emq:{q}:events`, vs the `{emq}:` reserve), and **the event payload
  contract** (which lifecycle facts publish — completed/failed/scheduled/stalled/… — and **where they are
  emitted**: host-side after a transition verdict the connector already sees, vs a Lua-side publish from the
  transition script; the recommended placement is host-side, so the transition scripts stay byte-unchanged
  and the publish is an additive host step); (b) **the telemetry event tree**: the `[:emq, …]` event names
  for the lifecycle (the v1 six re-rooted); (c) **the lock plane**: the lock-extension verb's name + return,
  the worker-side lock-plane process name (the v1 `EchoMQ.LockManager` capability, built as `EchoMQ.Locks`)
  and its opt-in supervised shape (the `EchoMQ.Pump` `:transient`/owner-started precedent); (d) **the stalled
  mechanism**: how the
  explicit sweep's stall-count threshold is recorded and read (a field on the row vs a registered set),
  distinct from the dead-lease reap. Every new key spelled against §6; ≥2 steelmanned alternatives for each
  fork; recorded BEFORE any build story runs (the emq.1/emq.2.1 precedent: the design-make is the relocated
  gate).
- **EMQ.2.3-D2** — **`EchoMQ.Events`** — the per-queue event subscription surface over the as-built connector
  `subscribe/2`/`unsubscribe/2` pub/sub seam (the `{:emq_push, payload}` message routed to `push_to`, the
  recorded-subscription `MapSet` re-issued by `resubscribe/1` at the `:reconnect` success arm — the emq.1
  set, kept live across a reconnect): `subscribe`/`unsubscribe`/`close` and a `handle_event/3`-style delivery
  of lifecycle events (the names ruled at D1 — completed/failed/scheduled/stalled/…). The events are
  **published host-side** after a transition's verdict (the recommended D1 placement — the transition scripts
  stay byte-unchanged) onto the §6 event channel; the at-most-once honesty of the fire-and-forget push channel
  is stated (the emq.1 resubscribe is the existing mitigation — design §12.3). **No new transport, no
  `SSUBSCRIBE`.**
- **EMQ.2.3-D3** — **`EchoMQ.Meter`** — the `:telemetry` surface over the job lifecycle: `attach/4`,
  `attach_many/4`, `emit/3` (or `execute`), `span/3`, with the event names re-rooted under `[:emq, …]` (the
  v1 `job_added`/`job_started`/`job_completed`/`job_failed`/`job_retried`/`worker_started` capability,
  re-rooted, e.g. `[:emq, :job, :completed]`). Zero cost when `:telemetry` is not loaded (the as-built
  `Connector.emit/3` precedent — guarded by `:erlang.function_exported(:telemetry, :execute, 3)`). This
  ships the **surface** (the events fire); the telemetry **contract** (the payload-shape assertions, the
  matrix) is **emq.8** (ADR-2's two-layer split) — emq.2.3 does not ship emq.8's proof.
- **EMQ.2.3-D4** — **the lock-extension verb** on `EchoMQ.Jobs` — re-score the `active`-set member to a fresh
  lease deadline computed from the server clock (`TIME` inside the script, the DQ-2c law — the `@claim`
  re-score pattern `ZADD active, now + lease, id`), refusing **`EMQSTALE`** when the caller's attempts-token
  does not match the row's current attempts (the existing fencing-token wire class — the `@complete`/`@retry`
  pattern; **no new wire class**), declared keys `[active, job_key]`. A batch extension (the v1 `extendLocks`
  capability — many ids in one call, the ids whose lease could not be extended returned). The verb is a clean
  additive transition under the master invariant; it adds no key *type* outside §6.
- **EMQ.2.3-D5** — **the worker-side lock plane** (the v1 `EchoMQ.LockManager` capability, built as
  **`EchoMQ.Locks`**) — an **opt-in, supervised** process beside the consumer (the `EchoMQ.Pump`
  process-shape precedent: a `:transient`
  child, owner-started, no `mod:` auto-start; the cadence arithmetic — the extend interval — in a pure
  decision core where it is a value tested without a clock): `track`/`untrack` held jobs (id + the
  attempts-token), `get_active_job_count`/`get_tracked_job_ids`/`is_tracked?` reads, **extend on a timer**
  (call D4's verb for each tracked job before its lease elapses), and **release on completion** (untrack +,
  where the v2 lease is the active score, the score is retired by the existing `complete`/`retry`
  transitions — the plane untracks, it does not double-retire). **A consumer started without the lock plane
  is the unchanged v2 worker** (the opt-in law — the `EchoMQ.Pump` precedent).
- **EMQ.2.3-D6** — **the explicit stalled-sweep** (the v1 `EchoMQ.StalledChecker` capability, built as
  **`EchoMQ.Stalled`**) — a periodic recovery that distinguishes a **reaped dead lease** (the as-built
  `Jobs.reap/2` single scan) from a **stalled-count threshold**: a job whose lease expired without extension
  is marked stalled; one that crosses the configured `max_stalled` threshold is recovered (back to pending)
  or dead-lettered per the threshold (the v1 `moveStalledJobsToWait` capability, re-derived). `check/3` runs
  one sweep (`conn, queue, opts` — the `:max_stalled`/`:limit` keyword carrier); `job_stalled?/4` answers
  whether a job is stalled. The sweep reads the server clock (`TIME` — never the v1 caller-clock
  timestamp), declares only the sets it touches in `KEYS[]` (never the v1 9-key LIST shape), and registers
  its key against §6 (the stall-count carrier ruled at D1). Beyond the as-built reaper, not a replacement for
  it (the reaper stays the server-side dead-lease scan; this is the worker-stall recovery on top).
- **EMQ.2.3-D7** — **the cooperative cancellation token** (the v1 `EchoMQ.CancellationToken` capability,
  built as **`EchoMQ.Cancel`**, worker-side half) — `new/0` mints a token (a plain `make_ref()`), `cancel/3`
  flags it (with an optional reason), `check/1` answers
  whether it is cancelled, `check!/1` raises a typed cancellation when it is. A cooperative handler checks the
  token at a safe point and stops its own work. The **distributed** cancel (a cancel issued from another node,
  coordinated across the cluster) is **emq.6** (ADR-2) — emq.2.3 ships the local cooperative primitive emq.6
  coordinates.
- **EMQ.2.3-D8** — **proof:** the conformance scenarios + probes registered for every watch verdict (the
  after-the-watch assertions — the exact set + names ruled at D1/D8, e.g. a **lock-extend** scenario: an
  extended lease is NOT reaped past its original deadline + a stale token is refused `EMQSTALE`; a **stalled**
  scenario: a job past the stall-count threshold is recovered/dead per the threshold; an **events** scenario:
  a subscriber receives a lifecycle event on the connector pub/sub seam; a **telemetry** scenario: an
  attached `[:emq, …]` handler receives a lifecycle event — the scenario is **two-mode** (the
  `Connector.emit/3` zero-cost precedent): on this machine `:telemetry` is loaded in echo_mq's per-app test
  context (a transitive dep of the umbrella, one shared `_build`), so the **present** branch runs and the
  surface really fires; the **absent** branch is the safe no-op (attach + emit answer `:ok`, no event), proven
  but not exercised where the dep is present); pure + `:valkey` + process suites; the prior **32**
  conformance scenarios pass byte-unchanged (14 emq.0 → 18 emq.1 → 24 emq.2.1 → 32 emq.2.2; the
  additive-minor law) and the **5** watch scenarios register beside them for a live total of **37**; honest-row
  reporting (Valkey the truth row); the **≥100-iteration determinism loop** for the process-touching suites
  (the lock plane + the stalled sweep run on timers — the master-invariant gate ladder).

## Invariants

- **EMQ.2.3-INV1** — the wire law: zero wire breaks; emq.2.3 adds no key *type* outside the §6 grammar (the
  event channel, the lock-extension's keys, the stalled-count carrier are §6-spelled `queue_key` suffixes or
  the `{emq}:` reserve); **no new wire class** (the lock-extension stale refusal reuses `EMQSTALE`; the
  five-code fence union stands unextended); every conformance addition is an additive protocol minor
  registered with its probe in the same change; the **32 prior conformance scenarios pass byte-unchanged**
  (14 emq.0 → 18 emq.1 → 24 emq.2.1 → 32 emq.2.2) and the **5** watch scenarios register beside them
  (`lock_extend`, `stalled`, `events`, `telemetry`, `cancel`) for a live total of **37**.
- **EMQ.2.3-INV2** — the event plane rides the existing seam: `EchoMQ.Events` publishes and subscribes over
  the as-built connector `subscribe/2`/`unsubscribe/2` pub/sub seam (the `{:emq_push, …}` message + the
  resubscribe `MapSet`) — **never a new transport, never `SSUBSCRIBE`** (design §12.3); the durable replayable
  stream stays emq3.2. The push channel's at-most-once honesty is stated, not papered over (the emq.1
  resubscribe is the mitigation).
- **EMQ.2.3-INV3** — the lease lifecycle is server-clocked and token-fenced: the lock-extension verb reads
  the server `TIME` inside the script (the DQ-2c law — never the caller's clock), re-scores the `active`-set
  member (the v2 lease IS that score — **never** a separate `…:lock` string), and refuses `EMQSTALE` when the
  attempts-token is stale (the existing fencing-token class — the `@complete`/`@retry` pattern). The extend is
  a transition; the worker-side plane that drives it on a timer is **opt-in** (a consumer without it is the
  unchanged v2 worker — the `EchoMQ.Pump` law).
- **EMQ.2.3-INV4** — declared keys, self-justified: every new Lua key (the lock-extension's, the stalled
  sweep's) is in `KEYS[]` or derived in-script only from a declared `KEYS[n]` root by the registered grammar
  (the master invariant; the A-1 lint); the stalled sweep declares **only the sets it touches** — never the
  v1 9-key `moveStalledJobsToWait` shape; new scripts follow the inline `Script.new/2` convention (there is
  **no `priv/`** in `echo_mq`).
- **EMQ.2.3-INV5** — branded identity at every job boundary: the lock-extension verb, the worker-side plane,
  the stalled sweep, and the events all key the job position through `Keyspace.job_key/2`, which gates
  `BrandedId.valid?/1` and raises before any wire (an ill-formed id never reaches a key); the cooperative
  token is host-side and carries no wire identity.
- **EMQ.2.3-INV6** — the surface fires, the proof stack asserts (ADR-2's two-layer split): emq.2.3 ships the
  event-and-telemetry **surface** (the events fire on the lifecycle, the handlers attach) and registers its
  own conformance scenarios; it does **not** ship the telemetry **contract** (the payload-shape assertions,
  the engine matrix) — that is **emq.8**. The two-layer boundary is explicit so emq.8 is not pre-empted and
  the additive-minor law stays clean (emq.2.3 adds its scenarios; emq.8 adds the matrix over them).
- **EMQ.2.3-INV7** — the family boundary holds (ADR-2): emq.2.3 ships the **worker-side cooperative** cancel +
  the worker-side lock plane (the local primitives); the **distributed** cancel / per-worker TTL / checkpoints
  are **emq.6**; the **durable replayable event stream** is emq3.2; the **telemetry contract** is emq.8.
  emq.2.3 pre-empts no family rung and re-ships no shipped surface.
- **EMQ.2.3-INV8** — the design gate (honored): no build artifact predated EMQ.2.3-D1's
  event/telemetry/lock/stalled rulings (each recorded with ≥2 steelmanned alternatives where the spec leaves a
  fork) — the design-make opened the build, as the emq.1/emq.2.1 precedent requires. The process-touching
  suites (the lock plane + the stalled sweep) run the **≥100-iteration determinism loop** — one green run is not
  proof (the master-invariant gate ladder).

## Definition of Done

- [x] EMQ.2.3-D1: the watch-plane design recorded — the event surface (placement + the §6 channel name + the
      payload contract + the host-side-vs-Lua emit ruling), the telemetry `[:emq, …]` event tree, the lock
      plane (the extension verb's name/return + the opt-in supervised process shape), and the stalled
      mechanism (the stall-count carrier, distinct from the reaper); ≥2 steelmanned alternatives per fork;
      every new key spelled against §6 (the gate that opens the build).
- [x] D2 `EchoMQ.Events` built over the connector pub/sub seam (INV2): subscribe/unsubscribe/close + lifecycle
      delivery; events published host-side after a transition verdict; auto-resubscribe across a reconnect; no
      new transport, no `SSUBSCRIBE`.
- [x] D3 `EchoMQ.Meter` built (INV6): attach/attach_many/emit/span over the `[:emq, …]` lifecycle (the v1
      six re-rooted); zero cost when `:telemetry` is absent; the surface fires — the contract is emq.8.
- [x] D4 the lock-extension verb on `EchoMQ.Jobs` (INV3, INV4, INV5): re-scores the active member to
      `TIME`+lease under declared keys, refuses `EMQSTALE` on a stale token (no new wire class), never a
      separate `…:lock` string; + the batch extension.
- [x] D5 the worker-side lock plane (INV3, INV7): an opt-in supervised process (the `EchoMQ.Pump` shape) —
      track/untrack, the read trio, extend-on-a-timer, release-on-completion; a consumer without it is the
      unchanged v2 worker.
- [x] D6 the explicit stalled-sweep (INV4): `check`/`job_stalled?` + the periodic stall-count recovery over
      the four as-built sets under the server `TIME`; beyond the dead-lease reaper, not a replacement; never
      the v1 caller-clock / 9-key LIST shape.
- [x] D7 the cooperative cancellation token (INV7): worker-side new/cancel/check/check!; the distributed
      cancel is emq.6.
- [x] D8 the watch verdicts proven: a lock-extend scenario (extended lease survives the reaper; a stale token
      refuses `EMQSTALE`); a stalled scenario (a past-threshold job recovered/dead per the threshold); an
      events scenario (a subscriber receives a lifecycle event); a telemetry scenario (an attached `[:emq, …]`
      handler fires); pure + `:valkey` + process suites green per-app; the **32 prior conformance scenarios
      pass byte-unchanged** (14 emq.0 → 18 emq.1 → 24 emq.2.1 → 32 emq.2.2) and the **5** new watch scenarios
      pass beside them for a live total of **37** (the registry grows additively — INV1); honest-row reporting
      (Valkey on 6390 the truth row); the **≥100-iteration determinism loop** for the process-touching suites
      (INV8).
- [x] The emq.1 + emq.2.1/2.2 gate ladders + the emq.2.design carve still green end-to-end (no regression);
      the spec body remains authoritative and the as-built reconcile syncs it post-build.

## Carries forward (to emq.2.4 — the closer)

Recorded at the post-build reconcile, NOT fixed here — emq.2.4 (the emq.2 cluster closer) owns them:

- **C1 — the file/module-name mismatch (a cleanliness debt).** The watch modules avoided the v1-name
  collision by keeping the v1-*concept* file names while giving the *modules* collision-free identities:
  `lib/echo_mq/telemetry.ex` → `EchoMQ.Meter`, `lib/echo_mq/lock_manager.ex` → `EchoMQ.Locks`,
  `lib/echo_mq/stalled_checker.ex` → `EchoMQ.Stalled`, `lib/echo_mq/cancellation_token.ex` → `EchoMQ.Cancel`
  (`events.ex` → `EchoMQ.Events` is the one already-aligned pair). The collision-rename is correct and shipped;
  the file-name-to-module-name realignment (rename the files to match, or accept the divergence as documented)
  is a closer-rung cleanup — recorded as a known debt, not a defect.
- **C2 — two untested-but-verified behaviors (owed an explicit test).** The post-build adversarial probe held
  both, but neither has a dedicated test: (i) `EchoMQ.Jobs.extend_locks/4` partial-batch — given
  `[live, stale, gone]`, the live id is extended while the stale and the gone ids are returned in `failed`;
  (ii) the `@sweep_stalled` GROUP-AWARE recover branch — a grouped stalled job recovers into its lane
  `g:<grp>:pending`, not the flat `pending`. emq.2.4's "complete the test suite" adds an explicit case for each.

Stories: [`./emq.2.3.stories.md`](emq.2.3.stories.md) ·
Runbook: [`./emq.2.3.prompt.md`](emq.2.3.prompt.md) · Carve + ADRs: [`./emq.2.design.md`](../emq.2.design.md)
(ADR-1 the carve, ADR-2 the parity/family boundary, ADR-3 the stalled plane, ADR-4 the event+telemetry plane) ·
Depends on: [`./emq.2.1.md`](emq.2.1.md) (the read plane — the lens the watch verdicts read through),
[`./emq.2.2.md`](emq.2.2.md) (the operator plane — the transitions the events fire on) · Roadmap:
[`../emq.roadmap.md`](../../../../emq.roadmap.md) (the emq.2 ladder row) · Design: [`../emq.design.md`](../../../../emq.design.md)
§12.3 (the event-transport deferral — no `SSUBSCRIBE`; the event record as durable receipt), §5 (the closed
wire-class registry — `EMQSTALE` reused, no new class), §4 + DQ-2c (the server clock on a lease), §6 (the
grammar — the event/lock/stalled keys), S-4 (Valkey the gate) · Capability reference:
`echo/apps/echomq/lib/echomq/{queue_events,telemetry,lock_manager,stalled_checker,cancellation_token}.ex` +
`echo/apps/echomq/priv/scripts/{extendLock-2,extendLocks-2,releaseLock-1,moveStalledJobsToWait-9}.lua` ·
As-built floor: `echo/apps/echo_mq/lib/echo_mq/{jobs.ex,consumer.ex,pump.ex,keyspace.ex,conformance.ex}`,
`echo/apps/echo_wire/lib/echo_mq/connector.ex` (the pub/sub seam + `emit/3`) · Program front door:
[`../echo_mq.md`](../../../../echo_mq.md) (the reframed emq.2 row) · Approach:
[`../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
