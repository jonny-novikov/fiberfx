# echo_mq — the as-built surface (NO-INVENT anchors)

The real module / Lua / key names a rung cites. **Re-probe at the rung's reconcile** — line numbers drift,
so treat them as hints, not contract; the master invariant is per-app testing, so this is the floor, not the
ceiling. Probe with `grep`/`Read` against the tree, never assert from this list alone. Paired with the
program law `.claude/skills/echo-mq-program.md`.

## `echo/apps/echo_mq/lib/echo_mq/` — the bus

| Module | Role | Real surface (cite by re-probe) |
|---|---|---|
| `EchoMQ.Keyspace` | the braced grammar | `queue_key/2` → `emq:{q}:<type>`; `job_key/2` gates `BrandedId.valid?`; `version_key/0` → `{emq}:version`; `reserve/1` |
| `EchoMQ.Jobs` | the state machine | `enqueue` · `claim` · `complete` · `retry/7` · `promote/3` · `enqueue_at/5` · `enqueue_in/5`; inline `@enqueue`/`@claim`/`@complete`/`@retry`/`@promote`/`@reap`/`@schedule` `Script.new/2` attrs |
| `EchoMQ.Lanes` | fair groups | the `g:`-segment family — `@genqueue`/`@gclaim`/… inline scripts; the rotating claim, ceilings, pause/resume, park-don't-poll |
| `EchoMQ.Consumer` | the drain loop | `child_spec` · `start_link` (a `spawn_link` loop, NOT a GenServer) · `stop/2`; the loop calls `Jobs.promote/3` |
| `EchoMQ.Pool` | connection pool | (probe) |
| `EchoMQ.Backoff` | host-side policy | `delay_ms/2`; `{:fixed,ms}`/`{:exponential,base,cap}`/`{:jitter,inner}`; full-jitter the only random arm; handed to `retry/7` as a literal |
| `EchoMQ.Repeat` | the repeat registry | `register`/`cancel`/`due`/`advance`/`count` over `emq:{q}:repeat` (zset) + `emq:{q}:repeat:<name>` (hash); host-side fresh mint per occurrence |
| `EchoMQ.Pump` + `EchoMQ.Pump.Core` | the opt-in cadence | a `:transient` opt-in child; pure tick/batch decision core; `sweep/1` = promote + fire_repeats; owner-started, no `mod:` |
| `EchoMQ.Conformance` | the gate | `scenarios/0` (18 as-built — see the program-law file) · `run/2` → `{:ok, n}` |

## `echo/apps/echo_wire/lib/` — the wire layer (under the `EchoWire` facade)

| Module | Role | Real surface |
|---|---|---|
| `EchoMQ.Connector` | the RESP3 connection + fence | `subscribe/2` · `unsubscribe/2` · `fence/2` (reads `version_key/0`, claims `SET NX` + read-back, refuses `{:error, {:version_fence, got}}`); `@wire_version "echomq:2.0.0"`; the recorded subscription `MapSet` re-issued in `resubscribe/1` at the `:reconnect` success arm; `down/1` keeps the set |
| `EchoMQ.RESP` | the protocol codec | `encode`/`decode` |
| `EchoMQ.Script` | `Script.new/2` | the inline-script primitive (**no `priv/` exists**) |
| `EchoWire` (`echo_wire.ex`) | the facade | the `defdelegate` surface (subscribe/unsubscribe/script/…) |

## `echo/apps/echomq/lib/` — the FROZEN feature reference — REFERENCE ONLY

The capability list to port (NEVER edited, NEVER migrated-from). These NAME what to port under the v2 laws;
they are NOT the target surface. The 25 `.ex` modules include: `flow_producer` (parent/child flows) ·
`lock_manager` + `extendLock(s)`/`releaseLock` (locks) · `job_scheduler` · `queue_events` (events) ·
`stalled_checker` + `moveStalledJobsToWait` (stalled recovery) · `telemetry` · `worker` (the worker
abstraction) · `queue` · `job`. The 26 `.lua` scripts include: `addPrioritizedJob` (priorities) ·
`getRateLimitTtl`/`isMaxed` (rate-limiting) · `getCounts`/`getMetrics`/`getState` (metrics) · `pause` ·
`obliterate`/`drain` (lifecycle) · `reprocessJob` · `updateData`/`updateProgress` · `moveToActive`/
`moveToDelayed`/`moveToFinished`/`moveJobFromActiveToWait`/`promote`. Port each rewritten to the v2 laws
(braced + branded + declared-keys + server-clock); never lift the v1 form (its scripts root key operands in
data values — structurally inexpressible under declared-keys).

## The substrate

`EchoData.BrandedId.valid?/1` + `encode/2` + `generate!/1` (`echo/apps/echo_data`, the in-umbrella dep — the
branded-id gate costs no dependency edge). `EchoData.Snowflake` (the mint; must be started — `generate!`
needs it). Engine: **Valkey on port 6390** (`redis-cli -p 6390 ping` → `PONG`).
