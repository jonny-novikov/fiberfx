# EMQ.5.2 · `min_size`/`timeout` batch shaping — the self-pacing batch consumer (Movement II, the batches family, the shaping rung)

> **Status: ✅ SHIPPED — the rung built, Director-verified BUILD-GRADE (the ledger Y-1); the two forks RULED
> (5.2-A → D-1 a new `EchoMQ.BatchConsumer` sibling · 5.2-B → D-2 the per-member verdict map); the conformance
> count LANDED at +3 → 67 (D-3).** This body is synced (Stage-5) to the as-built surface + the locked rulings; it
> is authoritative (the `.stories.md`/`.llms.md` derive — if a derived artifact disagrees, this body wins). The
> **SECOND** sub-rung of the emq.5 "batches" family; the family contract + the carve are [`../emq.5.md`](../emq.5.md).
> emq.5.2 builds the **batch CONSUME cadence** — a batch-aware consumer that waits until the pending depth reaches
> a SIZE FLOOR (`min_size`) OR a LATENCY CEILING (`timeout`) elapses, then drains one batch via the SHIPPED
> `@bclaim` / `Jobs.claim_batch/4` (emq.5.1, the spine). The spine is a manual single-shot pull; emq.5.2 gives it
> a self-pacing rhythm with both a size floor and a latency ceiling. It rides `@bclaim` and adds **NO new Lua, NO
> new lease, NO new key family, NO wire edit**.
>
> **The forks (RULED — the Operator delegated each to the Director at the pre-build reconcile; see §"The rung's
> forks"):** FORK 5.2-A — the SHAPING HOME → **D-1: a NEW `EchoMQ.BatchConsumer` (a sibling of `EchoMQ.Consumer`,
> NOT a mode on it)** + the pure `EchoMQ.BatchShaper.Core`. FORK 5.2-B — the BATCH HANDLER CONTRACT → **D-2: a
> per-member verdict map `%{id => :ok | {:error, reason}}`** (a served member absent from the map fail-safe
> RETRIES, never silently completes). Two design calls are SETTLED by this body with recorded rationale (D1 the
> accumulation model = watch-depth; D2 the timeout-partial semantics = the ceiling wins / the floor is soft) —
> they were NOT Operator forks (no genuine product trade-off; see §"Settled design decisions"). *(The lowercase
> D1/D2/D3 below are these architect design calls; the uppercase D-1/D-2/D-3 are the ledger's locked fork rulings
> — distinct.)*
>
> **Risk: NORMAL.** The increment is **additive over a proven mechanism + a proven pattern** — `@bclaim` (the
> claim) is SHIPPED and BYTE-FROZEN here; the shaping is a supervised process with a PURE decision core
> (`EchoMQ.Pump.Core` is the precedent — `pump/core.ex`: pure fns of options, an injected/absent clock, doctested),
> and the batch lifecycle events ride the SHIPPED `EchoMQ.Events.publish/5` seam (`events.ex:117`). **No new Lua ·
> no new lease · no new key family · no destructive at-rest op · no frozen-line edit · no wire break.** The only
> nondeterminism is the shaping TIMER, isolated in the pure core with an INJECTED clock, so the determinism posture
> is a **multi-seed sweep + an honest statement** (NOT the ≥100 loop — emq.5.2 mints no id in the claim path and
> touches no lease; `@bclaim` does the leasing, and it is byte-frozen + proven by emq.5.1's ≥100 loop). A
> **right-size collapse** was taken — no wire/Lua and a clean Stage-2 verify (Y-1, zero defects), so Mars-2
> collapsed (D-4): there was nothing to remediate or harden.

## 0 · The slice — what emq.5.2 builds, and why the shaping

The family ([`../emq.5.md`](../emq.5.md)) is the Movement II **consume** family. emq.5.1 shipped the **spine** —
`@bclaim` (the count-variant `ZPOPMIN emq:{q}:pending` loop, `jobs.ex:200-219`) + `Jobs.claim_batch/4`
(`jobs.ex:520-539`), the **manual-pull** host API: a worker calls `claim_batch(conn, queue, size, lease_ms)`
directly to lease up to `size` jobs in one atomic claim. The spine is **non-blocking by design** (FORK 5.1-C
RULED: an under-fill returns the short batch M; M=0/paused → `:empty`; the spine never waits) — the blocking,
self-pacing CADENCE was deferred to THIS rung (the emq.5.1 body, §Scope §Out: *"the `min_size`/`timeout` shaping
… emq.5.2; the manual-pull `claim_batch/4` is the spine, the cadence is the next rung"*).

emq.5.2 builds that cadence: a **batch-aware consumer** that, instead of pulling on demand, watches the queue
and flushes a batch when EITHER threshold is reached:

- a **SIZE FLOOR** (`min_size`) — wait until at least `min_size` jobs are pending, so a batch carries enough
  members to amortize the per-job work the batch handler does (the floor earns its latency cost only if the
  handler does ONE bulk op for N jobs — see FORK 5.2-B);
- a **LATENCY CEILING** (`timeout`) — never wait longer than `timeout` for the floor; when the ceiling elapses
  with fewer than `min_size` pending, flush the partial (the floor is SOFT/best-effort, abandoned at the ceiling —
  D2).

The mechanism is **reserved, not invented** — the carve ([`../emq.5.md`](../emq.5.md) §1 row emq.5.2): *"a
batch-aware `EchoMQ.Consumer` mode that waits for ≥ `min_size` OR until `timeout`, then drains via `@bclaim`; a
**pure shaping core** (accumulate/flush, injected clock); batch lifecycle events on the `EchoMQ.Events` seam."*
The pattern is **already proven** by the shipped `EchoMQ.Pump` + `EchoMQ.Pump.Core` (`pump/core.ex`, Chapter 3.7):
a supervised process whose tick/batch decisions are PURE functions of the start options, computed once with no
clock/process/IO, the GenServer shell beating on them. emq.5.2's shaping core is the SAME discipline — a pure
accumulate/flush decision over (the watched depth, the elapsed time, `min_size`, `timeout`), the process shell
driving it with an injected clock.

What emq.5.2 stands on (all SHIPPED, present-tense — cited by re-probe, the lag-1 law):

- `EchoMQ.Jobs.claim_batch/4` + `@bclaim` (`jobs.ex:520-539` host, `jobs.ex:200-219` script — the batch-claim
  spine; **byte-frozen** by this rung): the atomic count-variant claim the shaping core flushes through. The
  cadence DECIDES when to flush; `claim_batch/4` is HOW it flushes.
- `EchoMQ.Jobs.pending_size/2` (`jobs.ex:863-866` — `Connector.command(conn, ["ZCARD", queue_key(q, "pending")])`):
  the **watch-depth primitive** — a PURE READ of the pending depth that touches NO lease and claims NO member.
  The shaping core reads this to DECIDE whether the size floor is met, WITHOUT claiming (so no lease ticks during
  accumulation — D1).
- `EchoMQ.Consumer` (`consumer.ex`, 257 lines — `child_spec/1`, `start_link/1`, `stop/2`, the `:conn`/`:connector`
  lifecycle, `:handler`, `:lease_ms`/`:beat_ms`/`:retry_delay_ms`/`:max_attempts`): the drain-loop home, with TWO
  shipped modes today — the standalone `loop/1` (`consumer.ex:114` — reap→promote→`drain/1` exhaustive via
  `Lanes.claim/3`→park BLPOP) and the emq.4.3 `metronome_loop/1` (`consumer.ex:185` — register_idle→await_poke→
  `claim_once/1`). **Both claim via `Lanes.claim/3` (the GROUPED ring path, returning `{id, payload, att, group}`).**
  A batch mode is a clean ADDITIVE THIRD path that drains via `claim_batch/4` over the FLAT `emq:{q}:pending` set
  (NOT the ring — the grouped batch is emq.5.3's `@gbclaim`). The lifecycle (`child_spec`/`stop`/`:conn`/`:handler`)
  is reusable. (FORK 5.2-A weighs reuse-the-Consumer vs a new `BatchConsumer`.)
- `EchoMQ.Pump.Core` (`pump/core.ex` — `tick_ms/1`, `batch/1`: pure fns of options, no clock/process/IO,
  doctested): the **pure-core PRECEDENT** the shaping core is built to. The shaping core is the same shape — a
  pure decision over its inputs, the process shell reading it.
- `EchoMQ.Events.publish/5` (`events.ex:117` — `publish(conn, queue, event, job_id, extra \\ [])`, a host-side
  PUBLISH of cjson `{"event": …, "job": …, …}` on `emq:{q}:events`, the id gated at the key builder, fire-and-forget):
  the seam batch lifecycle events ride. NOTE — it gates a SINGLE `job_id`; a batch-level event must choose its shape
  (the events-shape design call, settled D3 below).
- `EchoMQ.Jobs.complete/5` (`jobs.ex:589` — `complete(conn, queue, job_id, token, result \\ nil)`) + `Jobs.retry/7`
  (`jobs.ex:759` — `retry(conn, queue, job_id, token, delay_ms, max_attempts, error)`): the per-member resolution
  the shaping consumer settles each batch member through (the standalone `drain/1` settle, `consumer.ex:155-161`,
  generalized to a batch). **BYTE-FROZEN.** The partial-failure isolation (emq.5.1 INV7) is the substrate.
- `EchoMQ.Conformance` (`conformance.ex` — the additive-minor harness, **64** scenarios live).

## Goal

emq.5.2 builds, inside `echo/apps/echo_mq`, the **`min_size`/`timeout` batch shaping** consumer:

1. **A pure shaping core** — `EchoMQ.BatchShaper.Core` (`batch_shaper/core.ex`; the `EchoMQ.Pump.Core` isomorph):
   the accumulate/flush decision as PURE functions of the start options + the observed state, with **no process, no
   wall clock, no I/O** — an INJECTED clock (a `now_ms` value passed in, the test seam) and the WATCHED pending
   depth are the only inputs. It validates `min_size` (a positive integer) and `timeout` (a positive integer ms)
   the `Pump.Core` way (a non-positive value RAISES `ArgumentError` — a shaper that cannot advance is a
   configuration error, not a silent no-op): the as-built surface is `validate!/2` (`(min_size, timeout) →
   {min_size, timeout}` or raise) + `decide/4` (`(depth, elapsed, min_size, timeout) → {:flush, size} | :wait`,
   re-validating the knobs at the decision point). The decision rule (D1 watch-depth, D2 ceiling-wins): **flush
   when `depth >= min_size`** (the floor met → request **`size = depth`**, the FULL observed ready depth) **OR when
   `elapsed >= timeout`** (the ceiling → flush whatever is pending, `size = depth`, possibly < `min_size` — the
   partial); a window with `depth == 0` at the ceiling flushes NOTHING (the empty case — `:wait`, re-open the
   window). **The size policy the body fixes: `size = depth` on BOTH legs** (the floor and the ceiling request the
   full observed ready depth, never an artificial `min_size` cap) — the floor leg's `depth >= min_size` makes the
   request always `≥ min_size` (so INV-Floor+Ceiling holds), and the byte-frozen `@bclaim` clamps the pop to the
   actual depth, so a flood drains all-ready without over-popping. The core is `@bclaim`-agnostic: it computes a
   DECISION, never touches Valkey.

2. **The batch-aware consumer** — `EchoMQ.BatchConsumer` (`batch_consumer.ex`; the home ruled at FORK 5.2-A →
   **D-1: a NEW process, a SIBLING of `EchoMQ.Consumer`, NOT a mode on it**): a supervised process that opens a
   window (marks `t0` from the injected clock), reads `Jobs.pending_size/2` on a poll cadence (the watch-depth
   primitive — NO claim, NO lease tick during accumulation), feeds (depth, elapsed = `now − t0`) to the shaping
   core, and on a `{:flush, size}` decision calls `Jobs.claim_batch/4` ONCE for the decided `size`, then invokes
   the BATCH HANDLER (the contract is FORK 5.2-B → D-2) over the served members, settling each member through the
   byte-frozen `Jobs.complete/5` / `Jobs.retry/7`. On `:wait` the window stays open — the SAME `t0` is held across
   the poll cycles (so the latency ceiling genuinely fires; a fresh `t0` is taken only after a flush), the poll
   parked on a `receive … after poll_ms` that honors control rather than busy-spinning the wire. The injected
   clock is the `:now_fn` option (default `System.monotonic_time(:millisecond)`), the seam that makes the timer
   leg deterministic. The lifecycle (`child_spec`/`start_link`/`stop/2`/the `:conn`/`:connector` lane/the settle
   points — control honored between batches and at the poll wait, never inside a batch's settle) duplicates the
   `EchoMQ.Consumer` discipline minimally (D-1's accepted ~40-line cost, cheaper than coupling three divergent
   cadences onto the shipped single-job modes). It drains the FLAT `emq:{q}:pending` (via `claim_batch/4`), NOT
   the grouped ring (the grouped batch is emq.5.3).

3. **The batch handler contract** (FORK 5.2-B → **D-2: a per-member verdict map**) — the handler is invoked ONCE
   over the served members `[%{id:, payload:, attempts:}]` and answers a **per-member verdict map
   `%{id => :ok | {:error, reason}}`**; the consumer completes the `:ok` members via the byte-frozen
   `Jobs.complete/5` and retries the `{:error, reason}` members via the byte-frozen `Jobs.retry/7` (each member's
   `reason` → that member's `last_error`) — the per-member resolution makes emq.5.1's partial-failure isolation
   OBSERVABLE through the shaping path (one poison member retries alone, the rest complete). A served member
   **ABSENT** from the returned map is a contract violation treated as a **fail-safe RETRY**
   (`{:error, "missing verdict"}`), NEVER a silent complete — unprocessed work must not retire (D-2's
   sub-decision). A raising batch handler converts to a WHOLE-batch retry (every member retried) and the loop
   survives (the standalone Consumer's `drain/1` rescue/catch discipline, generalized to the batch). (The
   standalone Consumer's single-job handler — `%{id:, payload:, attempts:, group:}` → `:ok | {:error, reason}` —
   is the per-job precedent; this per-member verdict map is its batch generalization, and the
   batch-family handler-contract PRECEDENT emq.5.3's grouped `@gbclaim` handler will mirror.)

4. The **conformance scenarios** — additive minor, the prior **64** byte-unchanged → **+3 → 67** (D-3, the
   granular decomposition the emq.5.1 precedent chose: `batch_shaping_floor` · `batch_shaping_timeout` ·
   `batch_shaping_partial_failure`; the decomposition is detailed in §"The conformance posture"); the proof (the
   `:valkey` suite + the PURE-core doctests + a **multi-seed sweep**, the core being pure + clock-injected) + the
   byte-freeze grep on `@bclaim` (and every shipped script — `grep redis.call` on the lib diff = 0; emq.5.2 adds
   NO Lua).

All under the v2 master invariant: braced `emq:{q}:` keyspace · branded `JOB` ids gated at the key builder ·
**no new Lua key** (emq.5.2 adds no script — the claim is the byte-frozen `@bclaim`) · the server clock (`TIME`)
already inside the byte-frozen `@bclaim` (no host timestamp crosses the lease) · inline `Script.new/2` (no new
script, none under `priv/`) · additive-minor conformance growth.

## Rationale (5W)

- **Why** — the emq.5.1 spine is a manual pull: a worker that wants a batch calls `claim_batch/4` and gets
  whatever is ready (the short batch, or `:empty`). A high-throughput consumer that drains continuously needs a
  CADENCE — but a naive loop that calls `claim_batch/4` in a tight cycle either (a) pays a wire round-trip per
  empty poll (busy-spin) or (b) flushes tiny batches the instant any job lands, defeating the amortization the
  batch claim exists for. emq.5.2 gives the spine a **self-pacing rhythm with two knobs**: a **size floor**
  (`min_size`) so a batch is worth the bulk-handler cost, and a **latency ceiling** (`timeout`) so a slow trickle
  still drains within a bound. The cadence WATCHES the depth (a cheap `ZCARD`, no claim, no lease tick) and flushes
  through the byte-frozen `@bclaim` only when a threshold is met — the busy-spin and the tiny-batch failure modes
  both gone. The pattern is **already proven** by the shipped `EchoMQ.Pump`/`Pump.Core` (a supervised cadence over
  a pure decision core); emq.5.2 is the batch isomorph.
- **What** — emq.5.2 builds: (1) `EchoMQ.BatchShaper.Core` — the PURE accumulate/flush decision (an injected
  clock, the watched depth, `min_size`/`timeout` as the knobs; `validate!/2` + `decide/4 → {:flush, size} |
  :wait`; the `Pump.Core` validation discipline); (2) `EchoMQ.BatchConsumer` (the home ruled at FORK 5.2-A → D-1 —
  a NEW sibling process, NOT a Consumer mode; watch `pending_size/2`, flush via the byte-frozen `claim_batch/4`,
  settle per-member); (3) the batch handler contract (ruled at FORK 5.2-B → D-2 — a handler over
  `[%{id:, payload:, attempts:}]` answering a per-member verdict map `%{id => :ok | {:error, reason}}`); (4) the
  three conformance scenarios (additive minor — the prior 64 byte-unchanged → +3 → 67, D-3); (5) the `:valkey`
  proof + the PURE-core doctests + a **multi-seed sweep** (the only nondeterminism is the timer, isolated in the
  injected-clock core) + the byte-freeze grep on `@bclaim` (= 0 — emq.5.2 adds no Lua).
- **Who** — the program (the rung that gives the batches family its self-pacing cadence); high-throughput
  **bulk-drain consumers** (codemojex's high-volume settle path — the named consumer the family carries to scale —
  drains continuously, so it needs the floor + ceiling, not the manual pull); the conformance harness, which grows
  by the shaping scenario(s). The shipped `EchoMQ.Pump`/`Pump.Core` is the pattern precedent; the shipped
  `EchoMQ.Consumer` is the lifecycle precedent. **Apollo** is an OPTIONAL fast-finisher (this rung edits no shipped
  script and adds no Lua/lease — `@bclaim` is byte-frozen); the determinism posture is a multi-seed sweep (the core
  is pure + clock-injected), NOT an Apollo-mandate ≥100 loop.
- **When** — Movement II, the batches family's **SECOND** sub-rung (the shaping, after the spine emq.5.1 SHIPPED).
  It rides the shipped `@bclaim` and is independent of emq.5.3 (affinity) and emq.5.4 (the partitioned finish) —
  all three ride only the spine, so the Operator may re-order 5.2↔5.3↔5.4 freely. The forks (FORK 5.2-A the home;
  FORK 5.2-B the batch handler contract) were RULED at the pre-build reconcile (the Operator delegated each to the
  Director — D-1 a new `BatchConsumer`, D-2 the per-member verdict map) BEFORE Mars built; the count granularity
  was ruled at the same gate (D-3, +3 → 67).
- **Where** — `echo/apps/echo_mq` only: the NEW `EchoMQ.BatchShaper.Core` (`batch_shaper/core.ex` — a pure
  module, the `Pump.Core` isomorph) + the NEW `EchoMQ.BatchConsumer` (`batch_consumer.ex` — the home ruled at
  FORK 5.2-A → D-1, a sibling process, `consumer.ex` UNTOUCHED), `conformance.ex` (the three shaping scenarios + a
  `settle_batch/4` mirror helper + the count re-pin), the NEW `:valkey` proof (`test/batch_consumer_test.exs`) +
  the PURE-core test (`test/batch_shaper_core_test.exs`), the two pinning tests (`conformance_run_test.exs` +
  `conformance_scenarios_test.exs` — the count re-pinned 64 → 67). `mix.exs` is **unchanged** (the label stays
  `2.5.0`, the emq.4.3-D4 two-planes model — a host-process rung climbs no version plane). `echo_wire` is
  **untouched** (no claim wire-behavior change — `claim_batch/4` rides the shipped connector `eval`;
  `@wire_version` stays `echomq:2.4.2`, `connector.ex:35`). `apps/echomq` is **untouched** (the capability
  reference — the v1 worker-batch abstraction is the FEATURE precedent to port, never migrated-from). The §6
  grammar in `keyspace.ex` is **unedited** (no new key family — the cadence rides the shipped
  `emq:{q}:pending`/`active` sets + the `emq:{q}:events` channel). `jobs.ex` is **byte-frozen** (`@bclaim`,
  `claim_batch/4`, `pending_size/2`, `complete/5`, `retry/7`, and every shipped script unchanged — emq.5.2 CALLS
  them, never edits them).

## Scope

- **In** — the `min_size`/`timeout` shaping cadence: (1) `EchoMQ.BatchShaper.Core` (the PURE accumulate/flush
  decision — an injected clock, the watched depth, `min_size`/`timeout`; `validate!/2` + `decide/4 → {:flush, size}
  | :wait`; the `Pump.Core` validation discipline — a non-positive knob RAISES); (2) `EchoMQ.BatchConsumer` (the
  home ruled at FORK 5.2-A → D-1, a NEW sibling process — watch `pending_size/2` on a poll cadence, flush via the
  byte-frozen `claim_batch/4`, settle each member through the byte-frozen `complete/5`/`retry/7`; the
  `EchoMQ.Consumer` lifecycle discipline minimally duplicated — control honored between batches and at the poll
  wait); (3) the batch handler contract (ruled at FORK 5.2-B → D-2, the per-member verdict map); (4) the batch
  lifecycle events on the shipped `EchoMQ.Events.publish/5` seam (the events shape settled D3 — per-member publish,
  the seam reused as-is); (5) the three conformance scenarios (additive minor — the prior 64 byte-unchanged → +3 →
  67, D-3); (6) the `:valkey` suite + the PURE-core doctests + a **multi-seed sweep** + the byte-freeze grep on
  `@bclaim` (and every shipped script — = 0).
- **Out** — any **new Lua / new script** (the claim is the byte-frozen `@bclaim`; emq.5.2 adds NO `Script.new/2` —
  INV-NoLua); any **edit to `@bclaim`/`claim_batch/4`/`pending_size/2`/`complete/5`/`retry/7` or any shipped script**
  (every shipped script byte-frozen — emq.5.2 is a host-process rung, not a Lua rung); any **new key family** (the
  cadence rides the shipped `emq:{q}:pending`/`active` + `emq:{q}:events` — INV-Boundary); **group affinity / the
  grouped batch** (`@gbclaim`, a homogeneous lane-scoped batch — emq.5.3; emq.5.2 drains the FLAT `pending` via
  `claim_batch/4`, NOT the ring); the **partitioned finish** (a batch resolving as a single partition — complete /
  retry-poison-alone / dead as a unit — emq.5.4; emq.5.2 resolves members individually through the byte-frozen
  transitions, the per-member settle, NOT a partition unit); **dynamic delay** (`Jobs.delay/N` re-score from the
  handler — emq.5.4); any **`echo_wire`/transport** change (`@wire_version` frozen); any **edit to the frozen v1
  line** (`apps/echomq`); any **server-side blocking wait** for the floor (the wait is HOST-SIDE in the consumer's
  poll cadence — NO blocking Lua, NO `BLPOP`-for-`min_size`; the floor is a host decision over `pending_size/2`
  reads, never a wire-blocking primitive — D1).

## Settled design decisions (Venus calls — recorded rationale, NOT Operator forks)

> These are pure design calls the architect settles with rationale (no genuine product trade-off the Operator must
> rule). Stated here as load-bearing PROPERTIES the build holds, distinct from the two RULED forks below.

- **D1 — the accumulation model = WATCH-DEPTH (not accumulate-claimed).** The cadence reads `Jobs.pending_size/2`
  (a `ZCARD` — a PURE READ, no claim, no lease tick) to DECIDE whether the floor is met, and claims a batch ONLY
  at the flush moment (one `claim_batch/4` call for the decided `size`). The rejected alternative —
  ACCUMULATE-CLAIMED — would claim jobs one/a-few at a time AS they arrive and HOLD the leased members until the
  floor/ceiling, giving precise batch sizes but **leasing members for the whole accumulation window**: a real
  hazard if `timeout > lease_ms` (a member leased early could have its lease EXPIRE and be reaped mid-window, so
  the held batch silently shrinks and a reaped member is double-claimed). Watch-depth holds NO lease during
  accumulation — the lease clock starts only at the flush `claim_batch/4`, so `timeout` and `lease_ms` are
  INDEPENDENT. *The stated property:* `min_size`/`timeout` shape WHEN to claim (a host decision over depth reads);
  `lease_ms` governs the claimed batch's lease (the byte-frozen `@bclaim` deadline) — the two never interact, and
  the consumer holds no Valkey lease until it flushes. This matches the carve's "*waits … THEN drains*" wording
  exactly. *Recorded:* watch-depth is the simpler, hazard-free model; accumulate-claimed buys precise sizes at the
  cost of an early-lease/timeout coupling the spine's non-blocking design specifically avoided.

- **D2 — the timeout-partial semantics = the CEILING WINS / the floor is SOFT.** On the latency ceiling
  (`elapsed >= timeout`) with `depth < min_size`, the cadence flushes the PARTIAL — it claims and processes the
  `depth` members it has, NOT waiting for the floor. `min_size` is therefore a **soft/best-effort floor**: the
  cadence prefers a full batch but ABANDONS the floor at the ceiling, so latency is bounded by `timeout` regardless
  of arrival rate. The carve's wording — "*waits for ≥ `min_size` OR until `timeout`, then drains*" — fixes this
  (the OR, with `timeout` as the latency bound). The empty case (`depth == 0` at the ceiling) flushes NOTHING (no
  batch — re-open the window), since a `claim_batch/4` for size 0 / on an empty set is `:empty` and a zero-member
  "batch" carries no work. *The stated property:* a batch flushed at the ceiling may carry 1..(min_size − 1)
  members (the partial); a batch flushed at the floor carries ≥ min_size; a window that sees zero arrivals within
  `timeout` flushes no batch and re-opens. *Recorded:* the ceiling-wins reading is the only one consistent with
  "*OR until timeout*" (a hard floor would make `timeout` meaningless — it would wait indefinitely for `min_size`);
  the soft floor is the standard Nagle/batch-shaper semantics (accumulate up to a size, bounded by a timer).

- **D3 — the batch lifecycle events = PER-MEMBER `publish/5`, the seam reused as-is.** The batch lifecycle events
  (the per-member completed/failed signals a subscriber reacts to) ride the SHIPPED `EchoMQ.Events.publish/5`
  (`events.ex:117`) — one `publish/5` per member, on the member's own branded `job_id` (the seam gates a single
  `job_id` at the key builder, INV5). The rejected alternative — a batch-LEVEL event (one PUBLISH carrying a count
  or a member-id list) — would need either a representative id (which member?) or an ADDITIVE variant of the seam
  (a new publish shape), and the per-member events already give a subscriber everything a batch-level event would
  (N completed/failed signals, each id-addressed). *The stated property:* the shaping consumer emits the SAME
  per-member lifecycle events the standalone Consumer's per-job settle would (the `@complete`/`@retry` host-side
  publish placement, the emq.2.3-D1 convention) — the batch is invisible to the events plane, which sees N
  per-member transitions. *Recorded:* per-member publish reuses the seam with zero edit and loses no information; a
  batch-level event is an additive seam variant with no consumer demand at this rung (a batch-aware subscriber is
  not in scope — codemojex reacts per-job).

> If, at the pre-build reconcile, the Operator judges any of D1/D2/D3 to carry a genuine product trade-off (e.g.
> a batch-level event IS wanted for a batch-aware subscriber), the Director may elevate it to a fork — but as
> framed, each is a settled design call with the rejected arm recorded, not an Operator decision.

## Invariants (the runnable checks emq.5.2 carries)

- **EMQ.5.2-INV-NoLua — emq.5.2 adds NO Lua; `@bclaim` and every shipped script are byte-frozen.** The shaping
  cadence is a HOST process over the byte-frozen `Jobs.claim_batch/4` / `@bclaim`; emq.5.2 adds NO new
  `Script.new/2` and edits NO shipped script (`@bclaim`, `@claim`, `@complete`, `@retry`, `@promote`, `@reap`,
  `@schedule`, every `@g*` in `lanes.ex`, and the `@update_*`/`@*_log`/`@remove_job`/`@reprocess`/`@extend_lock(s)`
  in `jobs.ex` — all byte-identical to HEAD). *Check:* `grep redis.call` on the lib diff returns **0** (emq.5.2
  touches no Lua body — the shaping core is pure Elixir, `EchoMQ.BatchConsumer` calls the byte-frozen host fns);
  the prior 64 conformance scenarios pass byte-unchanged.

- **EMQ.5.2-INV-Boundary — the diff is `echo/apps/echo_mq`; `@wire_version` frozen; no new key family.** The diff
  stays inside `echo/apps/echo_mq` (the NEW shaping core + `EchoMQ.BatchConsumer` + conformance + tests); no
  `echo_wire` edit (`@wire_version` = `echomq:2.4.2`, `connector.ex:35` — `claim_batch/4` rides the shipped
  connector `eval`); no new key family (the cadence rides the shipped `emq:{q}:pending`/`active` + `emq:{q}:events`
  — the §6 grammar in `keyspace.ex` is unedited); `apps/echomq` untouched. *Check:* the touched-file list ⊆
  `echo/apps/echo_mq` + the rung docs; `grep -r "@wire_version" echo_wire/lib` is unchanged; `{emq}:version` reads
  `echomq:2.4.2`; the §6 grammar is unedited; a grep of the new code for a key outside
  `pending`/`active`/`events`/`job:<id>` is empty.

- **EMQ.5.2-INV-PureCore — the flush/wait decision is a PURE function with an INJECTED clock.** `EchoMQ.BatchShaper.Core`
  computes the flush decision as a PURE function of (the observed pending depth, the ms elapsed since the window
  opened, `min_size`, `timeout`) — **no process, no wall clock (`System.monotonic_time`/`:erlang.now` etc.), no
  I/O**; time enters ONLY as an injected `now_ms`/`elapsed` value (the `Pump.Core` discipline). The validation is
  the `Pump.Core` way — a non-positive `min_size` or `timeout` RAISES `ArgumentError` (a shaper that cannot advance
  is a configuration error, not a silent no-op). *Check:* the core module has NO `Connector`/`Jobs`/`Process`/
  `:timer`/`System.monotonic_time` reference (grep = 0); its flush-decision fn is deterministic given its arguments
  (the same (depth, elapsed, min_size, timeout) → the same decision, asserted by doctest/unit); a non-positive knob
  raises (a guard test).

- **EMQ.5.2-INV-Floor+Ceiling — a flush carries ≥ `min_size` UNLESS the ceiling fired; never waits past `timeout`.**
  The shaper requests **`size = depth`** on BOTH legs (the full observed ready depth, never an artificial
  `min_size` cap; `@bclaim` clamps the pop to the actual depth). A batch flushed because the FLOOR was met
  (`depth >= min_size`) therefore carries ≥ `min_size` members; a batch flushed because the CEILING fired
  (`elapsed >= timeout`) carries the observed depth (possibly 1..(min_size − 1) — the partial, D2), and NO window
  waits longer than `timeout` for the floor (the ceiling is a hard latency bound, measured from the window-open
  `t0` held across `:wait` polls). A window that observes `depth == 0` at the ceiling flushes NO batch (D2 empty
  case → `:wait`). *Check:* a flood ≥ `min_size` → the next flush requests the full depth, ≥ `min_size` (the floor
  leg); a trickle < `min_size` held until `timeout` → a flush of the partial (exactly the members present, <
  `min_size`) within `timeout` of the window opening (the ceiling leg — asserted against the injected clock, no
  real-time flake); an idle window (zero arrivals) → no `claim_batch/4` call at the ceiling, the window re-opens.

- **EMQ.5.2-INV-ClaimPath — the cadence drains via `claim_batch/4` over flat `pending`, NOT `Lanes.claim`; pause
  honored.** The flush claims through the byte-frozen `Jobs.claim_batch/4` (`jobs.ex:520`) over the FLAT
  `emq:{q}:pending` set — NOT `Lanes.claim/3` (the grouped ring path, which the standalone/metronome modes use; the
  grouped batch is emq.5.3's `@gbclaim`). The queue-wide pause is honored (the byte-frozen `claim_batch/4` consults
  `paused?/2` FIRST — a paused queue answers `:empty`, the cadence flushes nothing and re-opens). The depth is read
  via `Jobs.pending_size/2` (a `ZCARD` over the same flat `pending` — the watch primitive, no claim). *Check:*
  `EchoMQ.BatchConsumer`'s flush calls `claim_batch/4` (not `Lanes.claim/3` — grep); the watch reads `pending_size/2`; a
  paused queue → the cadence claims nothing (the pause leg, `claim_batch/4` returns `:empty` pending-untouched).

- **EMQ.5.2-INV-PartialFailure — the batch handler resolves per-member over the byte-frozen `complete/5`/`retry/7`
  (emq.5.1's isolation, observable through the cadence).** The batch handler's per-member verdict map (FORK 5.2-B →
  D-2, `%{id => :ok | {:error, reason}}`) is mapped to per-member `Jobs.complete/5` (the `:ok` members) /
  `Jobs.retry/7` (the `{:error, reason}` members, each `reason` → that member's `last_error`) — one poisoned member
  is isolated to its own retry while the rest complete (the emq.5.1 INV7 partial-failure isolation, now driven by
  the shaping consumer). A served member ABSENT from the map FAIL-SAFE-RETRIES (`{:error, "missing verdict"}`),
  never silently completes (D-2's sub-decision — unprocessed work must not retire). NO batch-scoped resolution
  script exists (the batch is a CLAIM unit in emq.5.2, NOT a resolution unit — the partition unit is emq.5.4).
  *Check:* a batch where the handler fails one member and succeeds the rest → the failed member is `scheduled` (its
  `last_error` kept, its own token advanced), the rest are retired, a fresh post-promote claim finds only the
  poison; an absent-verdict member retries (the `batch_shaping_partial_failure` scenario omits a member to prove
  this observably); the resolution rides the byte-frozen `complete/5`/`retry/7` (no new Lua — INV-NoLua). The
  proof MUST actually fail a member (no vacuous pass).

- **EMQ.5.2-INV-Conf — the additive-minor conformance law.** The three shaping scenarios (`batch_shaping_floor` ·
  `batch_shaping_timeout` · `batch_shaping_partial_failure`) are registered in `scenarios/0` **with their probes in
  the same change** (D-3 — the granular decomposition in §"The conformance posture"); the prior **64** scenarios
  pass **byte-unchanged** (name + contract + verdict-body identical, git-verified); the count re-pins **64 → 67** in
  **both** pinning tests (`conformance_run_test.exs` `{:ok, 67}` + `conformance_scenarios_test.exs` `@run_order`).
  A present precondition (a flooded queue for the floor leg; a held trickle for the ceiling leg) RUNS the scenario
  with a POSITIVE proof (asserts the flush shape) — a vacuous pass is a LOUD failure. *Check:* the git-diff of
  `scenarios/0` shows only the three additions (the sole `-` line is a trailing-comma artifact on the
  previously-last map entry — contract text byte-identical); both count assertions updated to 67;
  `Conformance.run/2` prints 67 lines and returns `{:ok, 67}`.

- **EMQ.5.2-INV-Events — the batch lifecycle events ride the shipped `Events.publish/5`; the id is gated.** The
  batch lifecycle events ride the SHIPPED `EchoMQ.Events.publish/5` (`events.ex:117`) — per-member, on each
  member's branded `job_id` (D3); the id is gated at the key builder (`Keyspace.job_key/2` raises on an ill-formed
  id before the wire — INV5). emq.5.2 adds NO new event transport (no `SSUBSCRIBE`, no new channel). *Check:* the
  events plane sees N per-member transitions (not a batch-level event — D3); the `publish/5` calls are on
  per-member ids; no new channel/transport is introduced.

## Closed error set (the typed surfaces the shaping consumer may produce — grounded, no new codes)

emq.5.2 introduces **NO new `EMQ*` wire class** — it is a host-process rung over the byte-frozen claim/resolution
path, which already uses the closed registry. The surface (each grounded against the shipped path):

- **`:empty` from a flush** — the cadence decided to flush but `claim_batch/4` answered `:empty` (the pending set
  emptied between the depth read and the flush — a benign race; or the queue was paused — the `paused?/2` gate
  FIRST). The cadence treats `:empty` as "no batch this window" and re-opens (no error surfaced to the handler —
  the handler is invoked only on `{:ok, members}`). This is `claim_batch/4`'s `:empty`, consumed by the cadence.
- **A configuration error (a non-positive `min_size`/`timeout`)** — `EchoMQ.BatchShaper.Core` RAISES
  `ArgumentError` at validation (the `Pump.Core` discipline — a shaper that cannot advance is a configuration
  error, not a silent no-op). This is a programming error at start, NOT a wire refusal (the `Pump.Core`
  `tick_ms/1`/`batch/1` precedent, `pump/core.ex:27,45`).
- **A handler raise** — the batch handler may raise; `EchoMQ.BatchConsumer` converts it to a WHOLE-batch retry
  (every member retried — the standalone `drain/1` rescue/catch discipline, `consumer.ex:146-153`, generalized to
  the batch — a raising batch handler retries the batch's members rather than crashing the loop). No new code; the
  `Chapter 3.5` hardening generalized.
- **No `EMQKIND`/`EMQSTALE` from the cadence itself** — the claim is the byte-frozen `@bclaim` (no kind check, no
  token fence — the token is minted by the claim); `EMQSTALE` surfaces only at the per-member `complete/5`/`retry/7`
  resolution (the byte-frozen fencing — out of the cadence's claim path). The shaping consumer raises no `EMQSTALE`.

There is **no new typed refusal** for an under-fill or a partial flush (the partial is a normal result — D2; a
flush of M < `min_size` members at the ceiling is the soft-floor outcome, not a refusal). `min_size` and `timeout`
are validated host-side as positive integers (the `Pump.Core` guard discipline) — a non-positive value is an
`ArgumentError` at start (a programming error, not a wire refusal).

## The rung's forks — RULED (the Operator's pre-build decisions, delegated to the Director)

> Each was the architect's four-part Arm (Rationale / 5W / Steelman / Steward) with a recommended "lean"; the
> Operator delegated each to the Director at the pre-build reconcile, which RULED it (recorded as D-1/D-2/D-3 in
> the ledger). The arms + the recorded rulings are kept below for the decision trail. NONE changed the NORMAL risk
> tier (both are host-side shape decisions over the byte-frozen claim; neither adds Lua, a lease, or a wire edit).

### FORK 5.2-A — the shaping home — RULED: D-1 (a new `EchoMQ.BatchConsumer` sibling)

- **Rationale (the decision).** WHERE does the batch-aware cadence live? The carve names it "a batch-aware
  `EchoMQ.Consumer` mode" (§1 row emq.5.2), but the as-built `EchoMQ.Consumer` (`consumer.ex`, 257 lines) is built
  around the GROUPED ring (`Lanes.claim/3` → `{id, payload, att, group}`) in BOTH its modes (the standalone
  `loop/1` and the emq.4.3 `metronome_loop/1`). A batch mode is a fundamentally DIFFERENT cadence (watch the flat
  `pending` depth → flush a batch via `claim_batch/4`), so the choice is whether to ADD a third mode to the shipped
  Consumer or to FOUND a sibling process.
- **5W.** *Who* — Mars (builds the chosen home); the consumer's users (codemojex's bulk-drain path).
  *What* — the home of the watch-depth→flush cadence. *When* — the pre-build reconcile. *Where* — `consumer.ex`
  (a third mode) OR a new `batch_consumer.ex`. *Why* — a mode reuses the lifecycle but grows an already-257-line
  module with a third cadence; a sibling is clean but duplicates `child_spec`/`stop`/the `:conn` lane.
- **Arm A — a batch-aware MODE on `EchoMQ.Consumer` (the carve's wording).** A `:batch` mode (e.g. a `:min_size` +
  `:timeout` + `:batch_handler` option set) that, like the `:metronome` opt-in, dispatches to a third loop
  (`batch_loop/1`) instead of `loop/1`/`metronome_loop/1`. *Steelman:* it reuses the SHIPPED lifecycle verbatim —
  `child_spec/1`, `start_link/1`'s `:conn`/`:connector` lane setup (`consumer.ex:60-68`), `stop/2` (`consumer.ex:101`),
  the `:handler`/`:lease_ms`/`:retry_delay_ms`/`:max_attempts` options, and the settle-point control discipline
  (`check_control`, `consumer.ex:127`); it matches the carve's stated wording exactly ("a batch-aware
  `EchoMQ.Consumer` mode"); the emq.4.3 `:metronome` opt-in is the EXACT precedent (a third dispatch off
  `start_link` on an opt-in option). *Cost:* a third cadence in an already-257-line module; the batch mode's handler
  contract differs from the per-job `:handler` (the batch handler is FORK 5.2-B — so the module would carry two
  handler shapes).
- **Arm B — a new `EchoMQ.BatchConsumer` process.** A sibling supervised process (its own `child_spec`/`start_link`/
  `stop`) dedicated to the batch cadence. *Steelman:* clean separation — the batch cadence (watch-depth → flush →
  per-member settle) has a different shape AND a different handler contract from the single-job Consumer, so a
  sibling keeps each module single-purpose; it does not grow the shipped Consumer (no regression surface on the two
  shipped modes); the batch handler contract lives in its own module, unconfused with the per-job `:handler`.
  *Cost:* it DUPLICATES the lifecycle scaffolding (`child_spec`/`start_link`'s `:conn`/`:connector` lane/`stop`/the
  settle-point control) — ~40-60 lines of near-identical OTP plumbing the Consumer already has; it diverges from the
  carve's stated wording (a sibling, not "a Consumer mode").
- **Steward (lean).** **Arm A — a batch-aware mode on `EchoMQ.Consumer`** — it matches the carve's wording, reuses
  the shipped lifecycle (the emq.4.3 `:metronome` opt-in is the exact precedent for a third opt-in dispatch), and a
  right-size-collapse rung should not duplicate OTP plumbing. The weight against: the Consumer grows a third cadence
  and a second handler shape.
- **RULING: D-1 — Arm B, a NEW `EchoMQ.BatchConsumer`** (the architect's per-rung lean was Arm A; the Director
  ruled Arm B, reversing it on a wider frame). *The deciding factor:* emq.5.2 is the FIRST of three batch-family
  rungs (5.2 flat-batch via `@bclaim` · 5.3 grouped via `@gbclaim` · 5.4 the partitioned finish), so the choice is
  really WHERE the whole batches family lives. The clean responsibility boundary is `Consumer` = the single-job
  RING consumer (standalone + metronome are the SAME `Lanes.claim/3` + single-job-handler shape, just
  pool-coordinated) vs `BatchConsumer` = the BATCH consumer (watch-depth → flush → batch handler → per-member
  settle — a DIFFERENT claim path AND a different handler contract). A mode would accrete 4 cadences + 2 handler
  contracts onto the 257-line `consumer.ex` and put EVERY batch-family edit on the shipped single-job modes' file
  (a recurring regression surface); a new module gives the family a home 5.3/5.4 extend and keeps the two SHIPPED
  Consumer modes off the per-rung regression surface (zero blast radius on standalone/metronome). *The reversal,
  recorded honestly:* the Arm A lean (carve-wording + lifecycle-reuse + the `:metronome` precedent) was true in
  isolation but under-weighted the 5.3/5.4 family coupling; the `:metronome` precedent is weaker than it looks
  (metronome is still a single-job ring consumer, batch is not). *The accepted cost:* ~40 lines of stable OTP
  lifecycle boilerplate duplicated (`child_spec`/the `:conn`-`:connector` lane/`stop/2`/`check_control`) — cheaper
  than coupling three divergent cadences; a later rung MAY extract a shared lifecycle helper (YAGNI-deferred). The
  carve's "a Consumer mode" wording (carve §4 framed 5.2-A as an OPEN fork, sanctioning this divergence) is synced
  at this Stage-5.

### FORK 5.2-B — the batch handler contract — RULED: D-2 (the per-member verdict map; the load-bearing fork)

- **Rationale (the decision).** A `min_size` floor earns its latency cost ONLY if the handler does LESS per-job
  work by seeing the batch TOGETHER (one bulk DB write/API call for N jobs, not N calls). So the question is the
  HANDLER CONTRACT: does the batch mode invoke a BATCH handler over the served members (one invocation for the
  whole batch), and if so, HOW does the handler signal PER-MEMBER success/failure so the consumer can drive the
  partial-failure settle (emq.5.1's isolation, INV7 — one member retries, the rest complete)? This decision shapes
  the whole value proposition of batch shaping (a per-job handler would amortize only the CLAIM, not the WORK).
- **5W.** *Who* — Mars (builds the contract); the batch handler authors (codemojex). *What* — the handler
  invocation + the per-member verdict shape. *When* — the pre-build reconcile. *Where* — the batch consumer's
  handler call + verdict mapping (to `complete/5`/`retry/7`). *Why* — the contract decides whether batch shaping
  amortizes the handler WORK (a batch handler) or only the claim (a per-job handler), and how observable emq.5.1's
  partial-failure isolation is through the cadence.
- **Arm A — a SINGLE batch verdict (`:ok` → complete all / `{:error, reason}` → retry all).** The batch handler is
  invoked over `[%{id:, payload:, attempts:}]` and answers ONE verdict for the whole batch: `:ok` completes every
  member, `{:error, reason}` retries every member. *Steelman:* the simplest contract — one handler, one verdict,
  trivial to write; matches the per-job Consumer's `:ok | {:error, reason}` shape (just over a list); zero
  partial-failure ceremony for a handler that genuinely succeeds-or-fails atomically (a bulk DB transaction that
  commits-or-rolls-back). *Cost:* it makes emq.5.1's partial-failure isolation UNREACHABLE through the cadence — one
  bad member retries the WHOLE batch (the good members redo their work), defeating the isolation INV7 proves; a
  handler that bulk-processes but has one poison row cannot express "complete these N−1, retry that 1".
- **Arm B — a PER-MEMBER verdict map (`%{id => :ok | {:error, reason}}`).** The batch handler is invoked over the
  served members and answers a MAP from each member's id to its own verdict; the consumer completes the `:ok`
  members and retries the `{:error, _}` members, each through the byte-frozen `complete/5`/`retry/7`. *Steelman:* it
  makes emq.5.1's partial-failure isolation OBSERVABLE and USABLE through the cadence (one poison member retries
  alone, the rest complete — exactly INV7, now driven by the shaping consumer); it is the most expressive contract
  (a bulk handler with one bad row says so precisely); the per-member verdict is the natural batch generalization of
  the per-job `:ok | {:error, reason}`. *Cost:* a richer contract the handler must populate (a verdict per member,
  not one for the batch); a handler that omits a member's verdict needs a default (e.g. an absent id → `:ok`, or →
  retry — a sub-decision the body would fix to the ruled arm).
- **Arm C — a results-list / `{:ok, failed_ids}` shape.** The handler answers `:ok` (all good) or `{:error,
  failed_ids}` (the listed ids retry, the rest complete) — a middle ground. *Steelman:* lighter than the full map
  (the handler names only the FAILURES, the common case being all-good); still expresses partial failure (the
  failed-ids subset retries); a natural "exceptions list" idiom. *Cost:* it carries only a binary per-member outcome
  (failed or not) — no per-member `reason` for the retry's `last_error` (Arm B threads each failure's reason to
  `retry/7`'s `error` arg); the all-good fast path (`:ok`) and the some-failed path (`{:error, failed_ids}`) are two
  shapes the consumer must branch.
- **Steward (lean).** **Arm B — the per-member verdict map** — it makes emq.5.1's partial-failure isolation (the
  whole point of INV7) observable and usable through the shaping path, it is the most expressive (per-member
  `reason` → each failed member's `last_error`), and it is the clean batch generalization of the per-job `:ok |
  {:error, reason}`. The weight against Arm B is the contract richness; Arm A (a single verdict) is simpler but
  forfeits INV7 through the cadence; Arm C is the middle ground (failed-ids) if the per-member `reason` is judged
  unnecessary; Arm D (a per-job handler, claim-only amortization) forfeits the handler-WORK amortization the
  `min_size` floor's latency is paid for (a floor that makes the worker WAIT for N jobs only to process them
  one-at-a-time buys a saved claim syscall at the cost of added latency — argued against).
- **RULING: D-2 — Arm B, the per-member verdict map `%{id => :ok | {:error, reason}}`** (the architect's lean,
  ruled). The batch handler is invoked ONCE over the served members `[%{id:, payload:, attempts:}]` and answers
  the verdict map; the consumer completes the `:ok` members via the byte-frozen `Jobs.complete/5` and retries the
  `{:error, reason}` members via the byte-frozen `Jobs.retry/7` (each member's `reason` → that member's
  `last_error`). This makes emq.5.1's partial-failure isolation (INV7) OBSERVABLE and USABLE through the shaping
  cadence — one poison member retries alone, the rest complete. *The sub-decision (the body fixes, FAIL-SAFE):* a
  served member ABSENT from the returned map is a contract violation treated as a RETRY
  (`{:error, "missing verdict"}`), NEVER a silent complete — unprocessed work must not retire. *Family precedent:*
  this per-member-verdict-map shape is the batch-family handler contract emq.5.3's grouped `@gbclaim` handler will
  mirror (a family-wide decision, not a 5.2-local one). Chosen over Arm A (single batch verdict — forfeits
  isolation), Arm C (failed-ids — loses the per-member `reason` for `last_error`), Arm D (per-job handler,
  claim-only — forfeits the handler-WORK amortization the floor's latency is paid for).

## The conformance posture (the count RULED: +3 → 67, D-3)

The shaping scenario decomposition mirrors the emq.5.1 precedent (the Operator chose granular at FORK 5.1-B; the
Director ruled the same here, D-3). The LANDED decomposition (`+3 → 67`):

- **`batch_shaping_floor`** — the SIZE FLOOR flush: a queue flooded to ≥ `min_size` → the cadence flushes ONE batch
  of ≥ `min_size` members via `claim_batch/4` (the floor leg; the served members processed by the batch handler,
  settled per-member). Exercises INV-Floor+Ceiling (the floor), INV-ClaimPath, INV-PartialFailure (the all-good
  path).
- **`batch_shaping_timeout`** — the LATENCY CEILING flush: a trickle of M < `min_size` jobs held until `timeout` →
  the cadence flushes the PARTIAL (exactly M members, < `min_size`) within `timeout` of the window opening (the
  ceiling leg, against the injected clock — no real-time flake); an idle window (zero arrivals) flushes no batch.
  Exercises INV-Floor+Ceiling (the ceiling / the soft floor / the empty case), INV-PureCore (the injected clock).
- **`batch_shaping_partial_failure`** — the partial-failure isolation through the cadence: a batch where the handler
  fails one member and succeeds the rest → the failed member retries (scheduled, `last_error` kept), the rest
  complete, a fresh post-promote claim finds only the poison (the emq.5.1 INV7 isolation, now driven by the shaping
  consumer + the FORK 5.2-B handler contract). Exercises INV-PartialFailure, INV-Events (per-member publish).

*Landed delta:* **+3 → 67** (D-3, the granular decomposition the emq.5.1 precedent chose — each leg, floor /
ceiling / partial-failure-through-the-cadence, is a distinct observable the gate pins). The prior 64 are
byte-unchanged and git-verified; the sole `-` line in the `scenarios/0` diff is a trailing-comma artifact on the
previously-last map entry (contract text byte-identical); the count is re-pinned 64 → 67 in both pinning tests
(`conformance_run_test.exs` `{:ok, 67}` + `conformance_scenarios_test.exs` `@run_order` with the three new
names). The pure-core flush decision is ALSO covered by a doctest/unit test on `EchoMQ.BatchShaper.Core` (the
`Pump.Core` doctest precedent) — a structural property, not a conformance scenario.

> **The conformance-mirror seam (L-3, an accepted pattern — the craft note for 5.3/5.4).** The three scenarios
> settle through a conformance-LOCAL `settle_batch/4` helper that MIRRORS `EchoMQ.BatchConsumer.settle/3` (the
> verdict-map mapping + the absent-member fail-safe) rather than spinning the live process per scenario — the right
> call for the wire-level conformance harness (a supervised process per scenario would inject process-timing
> nondeterminism into the gate). It creates a duplication/drift hazard (a future bug in the real `settle/3` could
> pass the mirror green), MITIGATED two ways and therefore accepted, NOT a finding: (1) the mirror carries an
> explicit cross-reference comment ("exactly as `EchoMQ.BatchConsumer.settle/3` does"); (2) the REAL process is
> independently tested for the absent-member fail-safe in `batch_consumer_test.exs`. The family discipline (5.3's
> `@gbclaim` / 5.4's partitioned finish will mirror this): when a conformance scenario must replicate lib logic for
> determinism, PIN the duplication with a cross-ref comment AND ensure the live-process suite independently covers
> the same invariant — never let the deterministic mirror be the sole witness of a settle contract.

## Definition of Done

- [x] **FORK 5.2-A** (the shaping home) and **FORK 5.2-B** (the batch handler contract) surfaced with all arms +
      the trade-off; the Operator delegated each to the Director, which ruled (D-1 a new `EchoMQ.BatchConsumer`;
      D-2 the per-member verdict map); the conformance count granularity ruled at the same gate (D-3, +3 → 67);
      this body re-derived to the rulings (Stage-5 — the home, the handler contract, the final count).
- [x] **`EchoMQ.BatchShaper.Core`** built (the NEW pure module — the `EchoMQ.Pump.Core` isomorph): the
      accumulate/flush decision as a PURE function of (the observed pending depth, the elapsed ms, `min_size`,
      `timeout`) with an INJECTED clock — no process, no wall clock, no I/O; a non-positive knob RAISES; `decide/4
      → {:flush, depth} | :wait` (D1 watch-depth, D2 ceiling-wins, `size = depth` both legs). INV-PureCore verified.
- [x] **`EchoMQ.BatchConsumer`** built (the home ruled at FORK 5.2-A → D-1, a NEW sibling process — `consumer.ex`
      UNTOUCHED): watch `Jobs.pending_size/2` on a poll cadence (NO lease tick during accumulation — D1; the
      window `t0` held across `:wait` polls), flush via the byte-frozen `Jobs.claim_batch/4` over flat `pending`
      (NOT `Lanes.claim/3` — INV-ClaimPath), settle each member through the byte-frozen
      `Jobs.complete/5`/`Jobs.retry/7`; the `EchoMQ.Consumer` lifecycle discipline minimally duplicated (control
      honored between batches and at the poll wait). INV-Floor+Ceiling, INV-ClaimPath verified.
- [x] **The batch handler contract** built (ruled at FORK 5.2-B → D-2, the per-member verdict map): the handler
      invoked ONCE over the served members, its verdict map mapped to per-member `complete/5`/`retry/7`; an absent
      member fail-safe-retries (`"missing verdict"`); partial-failure isolation OBSERVABLE through the cadence (one
      poison member retries, the rest complete — the emq.5.1 INV7, now driven by the shaping consumer).
      INV-PartialFailure verified.
- [x] **The batch lifecycle events** ride the shipped `EchoMQ.Events.publish/5` (per-member, the id gated — D3);
      no new event transport. INV-Events verified.
- [x] The **three shaping conformance scenarios** registered (additive minor — the prior **64** byte-unchanged;
      the count re-pinned **64 → 67** in both pinning tests; the scenarios settle through a `settle_batch/4` mirror
      of `BatchConsumer.settle/3`, cross-referenced by comment, L-3). A present precondition (a flooded queue for
      the floor; a held trickle for the ceiling) RUNS the scenario with a positive proof; the partial-failure
      scenario omits a member to prove the fail-safe observably. INV-Conf verified.
- [x] The proof: the `:valkey` shaping suite green per-app (`batch_consumer_test.exs`); the **PURE-core
      doctests/unit tests** green (`batch_shaper_core_test.exs`); a **multi-seed sweep** green (8 seeds) + a 25×
      repeat of the `:valkey` suite (the only nondeterminism is the timer, isolated in the injected-clock core —
      NOT the ≥100 loop, no id-mint/lease in emq.5.2's own code) + an honest determinism-posture statement; the
      byte-freeze grep on `@bclaim` (and every shipped script) = **0** (emq.5.2 adds NO Lua); honest-row reporting
      (Valkey on 6390); `Conformance.run/2 → {:ok, 67}`.
- [x] INV-NoLua · INV-Boundary · INV-PureCore · INV-Floor+Ceiling · INV-ClaimPath · INV-PartialFailure ·
      INV-Conf · INV-Events verified as runnable checks (Director Y-1, all 8 green on an independent re-run +
      a net-zero mutation spot-check); the family contract ([`../emq.5.md`](../emq.5.md)) remains the carve
      authority; this body is authoritative (synced to the as-built post-build, Stage-5). **Apollo** was an
      OPTIONAL fast-finisher (this rung edits no shipped script and adds no Lua/lease). The **right-size collapse**
      was taken (no wire/Lua, clean Stage-2 verify) — Mars-2 collapsed (D-4).

Family: [`../emq.5.md`](../emq.5.md) (the contract, the carve, the forks — the carve authority) · Rung stories +
brief: [`emq.5.2.stories.md`](emq.5.2.stories.md) · [`emq.5.2.llms.md`](emq.5.2.llms.md) · Runbook:
[`emq.5.2.prompt.md`](emq.5.2.prompt.md) · The spine it rides (SHIPPED, **byte-frozen** by this rung):
`echo/apps/echo_mq/lib/echo_mq/jobs.ex` — `claim_batch/4` (`jobs.ex:520-539` → `{:ok, [{id, payload, att}, …]}` |
`:empty`) + `@bclaim` (`jobs.ex:200-219`) + `pending_size/2` (`jobs.ex:863-866` — the watch-depth primitive) + the
byte-frozen `complete/5` (`jobs.ex:589`) / `retry/7` (`jobs.ex:759`) the per-member settle rides · The pure-core
PRECEDENT (SHIPPED, the pattern to follow): `echo/apps/echo_mq/lib/echo_mq/pump/core.ex` — `tick_ms/1` + `batch/1`
(pure fns of options, no clock/process/IO, doctested) · The lifecycle PRECEDENT (SHIPPED): `consumer.ex` —
`child_spec/1`/`start_link/1`/`stop/2`/the `:conn`/`:connector` lane + the emq.4.3 `:metronome` opt-in (the third-mode
precedent) · The events seam (SHIPPED): `events.ex` — `publish/5` (`events.ex:117`, host-side, the id gated) · The
v2 laws: §6 (the braced keyspace) · S-6 (declared keys — no new Lua here) · §4 (the server clock — already inside
the byte-frozen `@bclaim`) · S-3/§5 (the additive-minor conformance law) · Roadmap:
[`../../../../emq.roadmap.md`](../../../../emq.roadmap.md) (the emq.5 row · Movement II) · Approach:
[`../../../../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
