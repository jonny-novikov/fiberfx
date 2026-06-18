# EMQ.2.1 · The introspection & metrics plane — Movement I, the parity floor (read side)

> **Status: BUILT** (the first rung of the emq.2 full-parity cluster; the carve + the ADRs are
> [`./emq.2.design.md`](../emq.2.design.md)). The read plane shipped inside `echo/apps/echo_mq` as a new
> module **`EchoMQ.Metrics`** (`lib/echo_mq/metrics.ex`) under the v2 laws — the introspection and metrics
> surface an operator dashboard, an operator runbook, and the later parity rungs read the queue through. It
> ports the v1 `echomq` read capabilities (counts by state, job-and-state lookups, the completed/failed
> metrics, the rate-limit read-and-gate) onto `echo_mq`'s **as-built** structures (the three-field row, the
> four sorted sets `pending`/`active`/`schedule`/`dead`), inventing no v1-shaped state type the bus does not
> have. The v1 line (`apps/echomq`) is a **capability reference** — the list of read surfaces to port —
> never a thing migrated from. This is the floor the operator plane (emq.2.2) and the watch plane (emq.2.3)
> are gated against: their acceptance reads through emq.2.1's verbs.
>
> **As-built reconcile (Stage 4, against the as-shipped tree).** The body is authoritative; the rulings the
> design-make settled and the two realization-over-literal deviations the build recorded are folded inline
> (marked **[BUILT]** / **[REALIZED]**). The as-built surface (cite by re-probe): `EchoMQ.Metrics` —
> `get_counts/3` · `get_job/3` · `get_job_state/3` · `get_metrics/3` · `get_deduplication_job_id/3` ·
> `get_rate_limit_ttl/3` · `get_global_rate_limit/2` · `is_maxed/2` · `lane_depth/3` · `lane_depths/3` (every
> verb carries the `conn` first). Conformance: **24** scenarios (the 18 prior byte-unchanged + 6 new —
> `counts`/`state`/`metrics`/`dedup`/`rate`/`lane_depth`; `run/2 → {:ok, 24}`). The touch-set is exactly six
> `echo_mq` files (`metrics.ex` + `metrics_test.exs` new; `jobs.ex` + `conformance.ex` + the two pin tests
> edited); `echo_wire` and `apps/echomq` untouched, `echo/mix.lock` unchanged (no new dependency).

## Goal

emq.2.1 builds the bus's read surface: pure-read verbs over `echo_mq`'s as-built structures that answer
"how many jobs in each state", "what is this job and its state", "the completed/failed throughput
metrics", "is the queue rate-limited and for how long". The capability reference is the frozen v1 line's
read API (`EchoMQ.Queue` — `get_counts`/`get_job`/`get_job_state`/`get_jobs`/`get_metrics`/
`get_rate_limit_ttl`/`get_global_rate_limit`, `apps/echomq/lib/echomq/queue.ex`) and its read scripts
(`getCounts-1.lua`, `getState-8.lua`, `getMetrics-2.lua`, `getRateLimitTtl-2.lua`, `isMaxed-2.lua` under
`apps/echomq/priv/scripts/`). emq.2.1 re-derives those capabilities against `echo_mq`'s real keyspace —
**not** the v1 state names: the as-built bus has `pending`/`active`/`schedule`/`dead` (and **no
`completed` set** — completion-deletes retire the row), so the counts surface reads the structures that
exist, and the metrics surface reads the `metrics:completed`/`metrics:failed` keys the design §6 grammar
registers. Every read key is declared in `KEYS[]` or grammar-derived (the master invariant); no read is a
state transition (the state machine is untouched); every addition registers a conformance scenario in the
same change (the additive-minor law). The rate-limit read is a read-and-refuse (an `EMQ*`-classed gate
where the ceiling is met), not a new transition over the row.

## Rationale (5W)

- **Why** — `echo_mq` ships the state machine and the lanes but has **no read surface**: a consumer can
  enqueue, claim, complete, and browse the pending set, but cannot ask "how deep is each state", "what is
  job X's state", "what is the completed/failed throughput", or "is the queue rate-limited". The v1 line's
  2144-line `EchoMQ.Queue` is almost entirely this read API, and the program's parity thesis
  ([`../emq.roadmap.md`](../../../emq.roadmap.md) Movement I) requires `echo_mq` to carry it before `apps/echomq`
  can dissolve. The parity carve ([`./emq.2.design.md`](../emq.2.design.md) ADR-1) places the read plane
  **first** because the later parity rungs' acceptance reads through it — emq.2.2's pause/drain/obliterate
  effects are observed by emq.2.1's counts; emq.2.3's stalled-recovery is observed by emq.2.1's state
  lookups. The front door records the consumer story: "the operational floor every consumer reads through
  … the counts/metrics/state introspection an operator dashboard reads" ([`../echo_mq.md`](../../../echo_mq.md),
  the reframed emq.2 row).
- **What** — emq.2.1 builds, inside `echo_mq`: the read module **`EchoMQ.Metrics`** (the placement ruled at
  the design gate — D1; the fold-onto-`Jobs`/`Lanes` and per-verb-split alternatives steelmanned and
  chosen-against, ledger V-1/V-2) carrying **counts-by-state** (over the four as-built sets + any registered metrics keys, one read script
  declaring exactly the sets it counts), **job-and-state lookup** (`get_job` reads the three-field row;
  `get_job_state` derives the state from which structure holds the id), **the metrics read** (the
  `metrics:completed`/`metrics:failed` throughput keys, §6 grammar), and **the rate-limit plane**
  (`get_rate_limit_ttl` reads the limiter TTL; the `is_maxed`/concurrency gate refuses an over-ceiling
  claim with an `EMQ*` class — the read-and-refuse). The exact verb set traces to the v1 read API
  (Deliverables below); no read surface here is invented.
- **Who** — the bus's operators and observers: an operator dashboard reading queue depth and throughput, an
  operator runbook reading job state before a mutation (emq.2.2), the conformance harness asserting the
  read verdicts, and the later parity rungs whose acceptance reads through these verbs. A worked consumer
  like codemojex reads its guess-queue depth and throughput through exactly this kind of surface (the
  queue-health reads are the operator's dashboard). No single consumer rung *gates* on emq.2.1 by name (it
  is the floor, not a feature), recorded not asserted.
- **When** — Movement I, after emq.1 closes, **first of the emq.2 cluster** (emq.2.1 → emq.2.2 → emq.2.3;
  [`./emq.2.design.md`](../emq.2.design.md) ADR-1's dependency order). SPECCED this run; BUILT a later run.
  The parity carve's one open sequencing fork (does the Operator keep the cluster to the floor, or pull
  the feature families in — design §6) settles BEFORE the build; the recommended carve (Arm A) is the one
  this triad is authored to.
- **Where** — `echo/apps/echo_mq` only (the read module + the read scripts as inline `Script.new/2`
  attributes — the as-built convention, **not** `priv/`; the new conformance scenarios in
  `conformance.ex`; the pure + `:valkey` suites). `apps/echomq` is untouched (the capability reference).
  Exact key, structure, and script anchors beyond those cited here are pinned at the rung's pre-build
  reconcile (the lag-1 discipline) — emq.1's and emq.2's earlier builds move the `echo_mq` surface before
  emq.2.1 reads it.

## Scope

- **In** — the counts-by-state read over the four as-built sets (`pending`/`active`/`schedule`/`dead`) +
  the registered metrics keys; the job lookup (`get_job` → the three-field row) and the state lookup
  (`get_job_state` → which structure holds the id); the completed/failed throughput metrics read
  (`metrics:completed`/`metrics:failed`, §6); the dedup-key read (`get_deduplication_job_id`); the
  rate-limit read (`get_rate_limit_ttl`/`get_global_rate_limit`) and the concurrency/rate gate (`is_maxed`
  — a read-and-refuse with an `EMQ*` class where the ceiling is met); the per-lane introspection reads
  (counts/depth per group, building on the as-built `Lanes.depth/2`); pure + `:valkey` suites; the
  conformance scenarios + probes registering each read verdict.
- **Out** — any state transition (the reads observe state; they never change it — the state machine is
  emq.1's, untouched); any new key *type* outside the §6 grammar (the metrics/limiter keys are §6-registered;
  a count reads the existing sets); the operator mutation verbs (pause/drain/obliterate/update/remove/reprocess
  — emq.2.2); the event stream + telemetry + stalled-recovery + lock plane (emq.2.3); the
  Prometheus *export* format wrapper beyond the raw metrics read (a presentation concern, deferred to the
  emq.8 telemetry contract unless a consumer names it — recorded, not built here); any v1-shaped state type
  the bus does not have (`wait`/`prioritized`/`waiting-children`/`completed`-as-a-set — the bus is
  `pending`/`active`/`schedule`/`dead` with completion-deletes); any wire break; any edit to the frozen v1
  line.

## Deliverables

emq.2.1 builds (forward-named; nothing below exists in `echo_mq` yet — the read surface lives only in the
frozen `apps/echomq` reference):

- **EMQ.2.1-D1** — **the design-make gate (FIRST):** the read-plane design adopting
  [`./emq.2.design.md`](../emq.2.design.md)'s carve (ADR-1) and the rulings needed before the build —
  the **module placement** (a new `EchoMQ.Metrics` vs read verbs folded onto `EchoMQ.Jobs`/`EchoMQ.Lanes`)
  and the **counts contract** (the exact set of state names the bus answers, derived from the four as-built
  sets — NOT the v1 list). Every read key spelled against §6; ≥2 steelmanned placement alternatives;
  recorded BEFORE any build story runs (the emq.1 precedent: the design-make is the relocated gate).
  **[BUILT]** the design-make recorded four rulings (the emq-2-1 ledger D-2..D-5): **(1) placement** = a new
  `EchoMQ.Metrics` (the two alternatives — read verbs folded onto `Jobs`/`Lanes`, and a per-verb module
  split `EchoMQ.Counts`/`Rate`/… — steelmanned and chosen-against at ledger V-1/V-2; `get_job`/`get_job_state`
  placed in `Metrics` as pure reads citing `Keyspace.job_key/2`, NOT on `Jobs`, to keep `Jobs`
  transition-only for INV2); **(2)** the counts contract (D2 below); **(3)** the metrics-counter write
  landed here (D4 below); **(4)** the rate-gate class `EMQRATE` (D6 below). No `.ex`/Lua artifact predated
  the ledger entry (INV7 held).
- **EMQ.2.1-D2** — **counts by state:** **[BUILT]** `get_counts/3` answers a count per requested state name,
  over `echo_mq`'s as-built structures, via ONE inline `@counts` `Script.new/2` declaring exactly the keys it
  touches in `KEYS[]` (the `getCounts-1.lua` capability re-derived: an unregistered state name is the typed
  error `{:error, {:unknown_state, name}}`, never an open concatenation — the design §6 closed-registry
  discipline). The contract — the **closed accepted set** `{pending, active, schedule, dead, completed,
  failed}`: the four set states `pending`/`active`/`schedule`/`dead` read `ZCARD` of their sorted set; the
  two metric states `completed`/`failed` read the terminal-outcome counter (the bus has no `completed` SET —
  completion-deletes retire the row, so "completed"/"failed" answer from `emq:{q}:metrics:completed`/`:failed`,
  not a set, stated in the contract). The key shape is slot-sound under braces: the queue base is declared as
  **`KEYS[1]`** (the slot root) and the set keys at `KEYS[2..]`, so even a metric-only request (no set states)
  pins the `{q}` slot and the metrics keys derive from the declared `KEYS[1]` root (the F-1 fix — declared
  keys / S-6, Cluster-safe; ledger D-6).
- **EMQ.2.1-D3** — **job & state lookup:** **[BUILT]** `get_job/3` reads the three-field row (`state`/
  `attempts`/`payload`) for a branded id (the key gated by `BrandedId.valid?/1` at `Keyspace.job_key/2`),
  answering `:absent` on an empty row; `get_job_state/3` answers the job's state by which set holds the id via
  one `@state_lookup` script declaring the four set keys + the row key (the `getState-8.lua` capability
  re-derived against the four sets — a job is `:pending`/`:active`/`:scheduled`/`:dead`, `:absent` when no row
  exists, or `:unknown` when the row exists but sits in no set (in-flight between transitions)). Both are pure
  reads; a missing job answers a typed absent shape, never an exception. (Note the set-suffix vs state-word
  split: the set KEY suffix is `schedule`, so D2's count names that set `schedule`; `get_job_state` answers
  the canonical state WORD `scheduled`.)
- **EMQ.2.1-D4** — **throughput metrics:** **[BUILT]** `get_metrics/3` reads the completed/failed throughput
  keys (`emq:{q}:metrics:completed`, `emq:{q}:metrics:failed`), `:completed`/`:failed` selectable. The metrics
  keys are §6-registered suffixes; the read names them by `Keyspace.queue_key/2`. **The metrics-counter write
  LANDED HERE** (the design-make ruled it in, not flagged to emq.2.2 — the read is a phantom without it):
  a re-probe proved no counter was written before this rung (`@complete` DELs the row, `@retry` writes
  `last_error`, neither touched a `metrics:*` key), so the minimal additive write rides the EXISTING terminal
  transitions — `@complete` does `HINCRBY emq:{q}:metrics:completed 'count' 1` on the successful retire
  (`jobs.ex:169`), `@retry`'s dead-letter arm does `HINCRBY emq:{q}:metrics:failed 'count' 1` (`jobs.ex:206`),
  each a new declared `KEYS[]` entry derived from the queue base root (ledger D-4). This is a counter the
  completion/dead transition maintains, NOT an emq.2.1 read-verb that mutates — INV2 (every emq.2.1 verb is a
  pure read) holds.
  - **[REALIZED]** the `:data` rolling series is **not written this rung** (deferred — Scope "Out", the
    presentation meter beyond the raw read → emq.8). The §6 grammar registers `metrics:completed[:data]` as a
    structure, but the build writes only the scalar `count` field; `get_metrics` reads `count` (real — proven
    `count: 1` after a completion) AND reports the `:data` series length honestly (`data_points` = `LLEN` →
    `0` while unwritten — read-no-series-that-is-not-written, INV2's no-phantom extended to the series). The
    rolling time-series is the deferred presentation concern (ledger L-2(1)).
- **EMQ.2.1-D5** — **the dedup read:** **[BUILT]** `get_deduplication_job_id/3` reads the branded id parked
  at `emq:{q}:de:<dedupId>` (the design §2/§6 dedup key), answering `:absent` when no id is parked; a read, no
  mutation (the `remove_deduplication_key` mutation is emq.2.2's, recorded).
- **EMQ.2.1-D6** — **the rate-limit plane:** **[BUILT]** `get_rate_limit_ttl/3` reads the remaining limiter
  TTL in ms (`0` = not limited — the limiter string spent down to the configured `max`, read from meta when
  `max_jobs` is `0`; the `getRateLimitTtl-2.lua` capability re-derived against the §6 limiter/meta keys),
  `get_global_rate_limit/2` reads the configured limit (`max`) from meta, and the **concurrency/rate gate**
  (`is_maxed/2` — the `isMaxed-2.lua` capability) answers whether the queue is at its ceiling. The gate is a
  **read-and-refuse**: where the active set is at the configured ceiling (`meta.concurrency`), the refusal
  leads with the wire class **`EMQRATE`** via `redis.error_reply` (the design §5 closed wire-class registry —
  `EMQRATE` joins `EMQKIND`/`EMQSTALE` as an additive minor, registered with its `rate` conformance probe in
  the same change), mapped client-side to `{:error, :rate}`; an unrecognized `EMQ*` first word passes through
  untyped. No new fence-union code (the five-code union stands).
  - **[REALIZED]** the gate ships as a **pure-read primitive**, not yet wired into a claim transition. The
    bus-shape adaptation: v1 `isMaxed-2` reads `meta.concurrency` + `LLEN active` (a LIST); the bus active set
    is a ZSET (`ZCARD`), so `is_maxed/2` reads `meta.concurrency` vs `ZCARD active` and refuses where it
    exceeds — moving no member, performing no transition (INV2). A claimer consults this primitive before
    claiming; **wiring the gate INTO a claim transition** (so an over-ceiling claim auto-refuses) is a
    transition change = emq.2.2's operator plane (ledger L-2(2)). The limiter/meta keys are read targets a
    queue configures out-of-band; the read answers `0`/`false` when unwritten (honest-no-phantom).
- **EMQ.2.1-D7** — **per-lane introspection:** **[BUILT]** `lane_depth/3` delegates to the as-built
  `Lanes.depth/2` (single group); `lane_depths/3` answers a count per group in one read (each group id gated
  by `BrandedId.valid?/1` before the wire, then one `@lane_counts` script deriving each lane key in-script
  from the declared queue-base root by the registered grammar `base..'g:'..g..':pending'` — INV4), so an
  operator (and emq.4's deepened recovery) reads a lane's backlog. A read over the lane structures; no
  rotation/recovery change (that is emq.4).
- **EMQ.2.1-D8** — **proof:** **[BUILT]** six conformance scenarios + probes registered for the read verdicts
  — `counts`, `state`, `metrics`, `dedup`, `rate`, `lane_depth` (the after-the-read assertions: counts equal
  the structure cardinalities; a claimed job reads `active`; a completed job reads absent + increments the
  completed metric; a rate-limited queue answers a positive TTL); the per-verb `:valkey` suite
  (`test/metrics_test.exs`, **20** tests, INV5 raise paths asserted); the prior 18 conformance scenarios pass
  byte-unchanged (the additive-minor law) and the registry grows to **24** (`run/2 → {:ok, 24}`, both pin
  tests re-pinned 18→24); honest-row reporting (Valkey on 6390 the truth row).

## Invariants

- **EMQ.2.1-INV1** — the wire law: zero wire breaks; emq.2.1 adds no key *type* outside the §6 grammar
  (counts read the existing sets; metrics/limiter/dedup keys are §6-registered suffixes); every conformance
  addition is an additive protocol minor registered with its probe in the same change; the **18 prior
  conformance scenarios pass byte-unchanged** and the registry grows additively to **24** (the 6 new read
  scenarios). **[BUILT]** held — `@run_order` is the 18 prior (`fence`…`resubscribe`) byte-unchanged + the 6
  new; `run/2 → {:ok, 24}`.
- **EMQ.2.1-INV2** — reads observe, never mutate: every emq.2.1 verb is a pure read (or a read-and-refuse
  for the rate gate); no verb writes the row or moves a set member; the state machine (emq.1's transitions)
  is untouched. **[BUILT]** held — the one WRITE is the metrics counter the EXISTING completion/dead
  transitions now maintain (the `HINCRBY` inside `@complete`/`@retry`, D4), NOT an emq.2.1 read-verb that
  mutates; `is_maxed/2` refuses at the ceiling moving no member; and **no metric is read that is not written**
  (the `:data` series, unwritten, reads honest-0 — no phantom counter).
- **EMQ.2.1-INV3** — the structures are the as-built ones: the counts/state surface reads
  `pending`/`active`/`schedule`/`dead` (the four sets) and the registered metrics keys — **never** a
  v1-shaped state type the bus does not have (no `wait`/`prioritized`/`waiting-children`/`completed`-set);
  "completed" answers from the metrics counter under completion-deletes, stated in the contract.
- **EMQ.2.1-INV4** — declared keys, self-justified: every read script declares its structure keys in
  `KEYS[]` or derives them in-script only from a declared `KEYS[n]` root by the registered grammar (the
  master invariant; the A-1 lint); a counts read of an unregistered state name is an error, never an open
  concatenation (the §6 closed-registry discipline).
- **EMQ.2.1-INV5** — branded identity at the read boundary: every job lookup gates the id with
  `BrandedId.valid?/1` at `Keyspace.job_key/2` (an ill-formed id raises before any wire — the as-built key
  builder's contract); the read never constructs a job key from an ungated string.
- **EMQ.2.1-INV6** — the wire-class discipline: the rate gate's refusal leads with its `EMQ*` first-word
  class via `redis.error_reply` (the design §5 convention), mapped client-side to a typed
  `{:error, :rate}` (or the placed atom); an unrecognized `EMQ*` first word passes through untyped
  (forward-compatible with minors); the five-code fence union stands unextended.
- **EMQ.2.1-INV7** — the design gate: no build artifact exists until EMQ.2.1-D1's placement + counts
  contract are recorded. **[BUILT]** held — the design-make rulings (ledger D-2..D-5) preceded every `.ex`/Lua
  artifact; the rung is now BUILT, and the post-build reconcile (this Stage 4) syncs the body to the
  as-shipped surface.

## Definition of Done

- [x] EMQ.2.1-D1: the read-plane design recorded (module placement = `EchoMQ.Metrics` + the counts contract
      derived from the four as-built sets, NOT the v1 list); ≥2 steelmanned placement alternatives (ledger
      V-1/V-2); every read key spelled against §6 (the gate that opened the build).
- [x] D2–D7 built in `echo_mq` as pure reads (INV2): counts over the as-built sets (INV3); job + state
      lookup gated by `BrandedId.valid?/1` (INV5); the metrics read with no phantom counter (INV2); the
      dedup read; the rate-limit read + the `EMQRATE`-classed gate (INV6); per-lane introspection over
      `Lanes.depth/2`.
- [x] Every read script declares its keys or grammar-derives them (INV4 — `@counts` declares the queue base
      as `KEYS[1]`, the F-1 fix); an unregistered state name is the typed `{:error, {:unknown_state, _}}`;
      the A-1 reading is the as-built convention.
- [x] Pure + `:valkey` suites green per-app; the **18 prior conformance scenarios pass byte-unchanged**
      and the 6 new read scenarios pass beside them (the registry grows additively to **24** — INV1);
      honest-row reporting (Valkey on 6390 the truth row).
- [x] The read verdicts proven: counts equal the structure cardinalities; a claimed job reads `active`; a
      completed job reads absent + the completed metric increments; a rate-limited queue answers a positive
      TTL; the over-ceiling claim refuses with `EMQRATE` → `{:error, :rate}`.
- [x] The emq.1 gate ladder + the emq.2.design carve still green end-to-end (no regression); the spec body
      remains authoritative and the as-built reconcile (Stage 4) has synced it post-build.

Stories: [`./emq.2.1.stories.md`](emq.2.1.stories.md) · Agent brief: [`./emq.2.1.llms.md`](emq.2.1.llms.md) ·
Runbook: [`./emq.2.1.prompt.md`](emq.2.1.prompt.md) · Carve + ADRs: [`./emq.2.design.md`](../emq.2.design.md)
(ADR-1 the carve, ADR-2 the parity/family boundary) · Roadmap: [`../emq.roadmap.md`](../../../emq.roadmap.md) (the
emq.2 ladder row) · Design: [`../emq.design.md`](../../../emq.design.md) §6 (the grammar + the metrics/dedup
suffixes), §5 (the wire-class registry for the rate gate), §2 (the branded id at the key builder), S-4
(Valkey the gate) · Capability reference: `echo/apps/echomq/lib/echomq/queue.ex` (the read API),
`echo/apps/echomq/priv/scripts/{getCounts-1,getState-8,getMetrics-2,getRateLimitTtl-2,isMaxed-2}.lua` · As-built
floor: `echo/apps/echo_mq/lib/echo_mq/{jobs.ex,lanes.ex,keyspace.ex,conformance.ex}` · Program front door:
[`../echo_mq.md`](../../../echo_mq.md) (the reframed emq.2 row) · Approach:
[`../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
