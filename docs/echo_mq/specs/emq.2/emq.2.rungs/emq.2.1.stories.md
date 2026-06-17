# EMQ.2.1 · user stories

> Who wants the read plane, what they need, and how acceptance is known. Derived from
> [`./emq.2.1.md`](emq.2.1.md) (**BUILT** — the acceptance below is proven against the as-shipped
> `EchoMQ.Metrics` surface; the body is authoritative). The consumer ground is the bus's observers — an
> operator dashboard, an operator runbook, the conformance harness, and the later parity rungs (emq.2.2/2.3)
> whose acceptance reads through these verbs. The capability ground is the v1 `echomq` read API
> (`EchoMQ.Queue`) and its read scripts, ported onto `echo_mq`'s as-built structures (never the v1 state
> names). The as-built verbs carry the `conn` first: `get_counts/3` · `get_job/3` · `get_job_state/3` ·
> `get_metrics/3` · `get_deduplication_job_id/3` · `get_rate_limit_ttl/3` · `get_global_rate_limit/2` ·
> `is_maxed/2` · `lane_depth/3` · `lane_depths/3`.

## EMQ.2.1-US1 — queue depth at a glance

As an operator watching the bus, I want a counts-by-state read over the queue's real structures, so that
I can see how many jobs are pending, active, scheduled, and dead without walking a set or trusting prose.

Acceptance criteria
- Given a queue with jobs spread across states, when `get_counts/3` requests the state names, then each
  answer equals the cardinality of the as-built structure (`ZCARD pending`/`active`/`schedule`/`dead`),
  and an unregistered state name is refused with `{:error, {:unknown_state, name}}`, never an open
  concatenation.
- Given completion-deletes, when "completed" is requested, then the answer comes from the registered
  metrics counter (the bus has **no** `completed` set), and the contract states this — no phantom set is
  read.
- Given the read, when it runs, then it changes nothing (a pure read — the counts before and after are
  identical for an idle queue).

INVEST — independent of the lookups; testable by a `:valkey` suite at the build run;
encodes EMQ.2.1-INV2, EMQ.2.1-INV3, EMQ.2.1-INV4.
Priority: must · Size: 5 · Implements deliverables: EMQ.2.1-D2.

## EMQ.2.1-US2 — what is this job, and where

As an operator about to act on a job (the emq.2.2 mutations gate on knowing its state), I want to read a
job's row and its state by branded id, so that a runbook checks "is it still pending" before it pauses,
removes, or reprocesses.

Acceptance criteria
- Given a branded job id, when `get_job/3` reads it, then it answers the three-field row
  (`state`/`attempts`/`payload`), and an ill-formed id raises at the key builder
  (`BrandedId.valid?/1`) before any wire.
- Given a job in some state, when `get_job_state/3` reads it, then it answers the state by which structure
  holds the id (`pending`/`active`/`scheduled`/`dead`/absent — the four as-built sets), never a v1-shaped
  state.
- Given a missing job, when either read runs, then it answers a typed absent shape, never an exception.

INVEST — independent of the counts; testable by a `:valkey` suite at the build run;
encodes EMQ.2.1-INV2, EMQ.2.1-INV5, EMQ.2.1-INV3.
Priority: must · Size: 3 · Implements deliverables: EMQ.2.1-D3.

## EMQ.2.1-US3 — throughput, honestly

As an operator dashboard owner reading queue health, I want the completed/failed throughput metrics, so
that a dashboard plots work done and work failed from the bus's own counters, not from a derived guess.

Acceptance criteria
- Given a queue that has completed and failed jobs, when `get_metrics/3` reads `:completed`/`:failed`,
  then it answers the `count` the terminal transitions tally at `emq:{q}:metrics:completed`/`:failed` (the
  minimal `HINCRBY` write landed here, in `@complete`/`@retry`), and no metric is read that the transition
  scripts do not write — the `:data` rolling series is unwritten this rung, so `get_metrics` reports its
  length honest-0 (no phantom counter; the series is deferred to emq.8).
- Given the read, when it runs, then it declares its keys in `KEYS[]` and changes no row.

INVEST — independent of the rate plane; testable by a `:valkey` suite at the build run;
encodes EMQ.2.1-INV2, EMQ.2.1-INV1, EMQ.2.1-INV4.
Priority: should · Size: 3 · Implements deliverables: EMQ.2.1-D4.

## EMQ.2.1-US4 — is this work a duplicate?

As a producer checking idempotency, I want to read the branded id parked under a dedup key, so that I can
ask "did this idempotency key already mint a job" without a second enqueue.

Acceptance criteria
- Given a dedup id that an enqueue parked, when `get_deduplication_job_id/3` reads it, then it answers the
  branded id at `emq:{q}:de:<dedupId>` (the §2/§6 dedup key); an absent dedup id answers a typed absent
  shape.
- Given the read, when it runs, then it is a read only (the `remove_deduplication_key` mutation is
  emq.2.2's, not exercised here).

INVEST — independent of the other reads; testable by a `:valkey` suite;
encodes EMQ.2.1-INV2, EMQ.2.1-INV4.
Priority: should · Size: 2 · Implements deliverables: EMQ.2.1-D5.

## EMQ.2.1-US5 — is the queue rate-limited?

As a consumer author respecting a ceiling, I want the rate-limit read and the at-ceiling gate, so that I
know how long until the limiter clears and an over-ceiling claim is refused with a typed class, not a
silent stall.

Acceptance criteria
- Given a rate-limited queue, when `get_rate_limit_ttl/3` reads it, then it answers the remaining limiter
  TTL in ms (0 = not limited — the v1 `getRateLimitTtl` capability), and `get_global_rate_limit/2` reads
  the configured limit from meta.
- Given a queue at its concurrency ceiling, when `is_maxed/2` reads it, then the gate refuses with the
  `EMQRATE` first-word class (design §5), mapped client-side to a typed `{:error, :rate}`; the five-code
  fence union stands unextended. (The gate ships as a pure-read primitive a claimer consults; wiring it
  into a claim transition is emq.2.2's operator plane.)
- Given an unrecognized `EMQ*` first word, when a client receives it, then it passes through untyped
  (forward-compatible with minors).

INVEST — independent of the counts/lookups; testable by a `:valkey` suite that sets a limiter;
encodes EMQ.2.1-INV6, EMQ.2.1-INV2.
Priority: should · Size: 3 · Implements deliverables: EMQ.2.1-D6.

## EMQ.2.1-US6 — a lane's backlog

As an operator running multi-tenant lanes (and emq.4's deepened recovery, which gates on lane reads), I
want counts/depth per group, so that I can see which lane is backed up before I pause or limit it.

Acceptance criteria
- Given a queue with grouped jobs, when the per-lane introspection reads a group, then it answers the
  lane's backlog built on the as-built `Lanes.depth/2`, per group.
- Given the read, when it runs, then it changes no rotation or recovery state (that is emq.4); it is a
  pure read over the lane structures.

INVEST — independent of the queue-wide reads; testable by a `:valkey` suite with two lanes;
encodes EMQ.2.1-INV2, EMQ.2.1-INV3.
Priority: should · Size: 2 · Implements deliverables: EMQ.2.1-D7.

## EMQ.2.1-US7 — the design gate before any build

As the Operator, I want the read-plane design — the module placement and the counts contract derived from
the four as-built sets, with steelmanned alternatives — recorded BEFORE any build story runs, so that the
rung reads `echo_mq`'s real structures and invents no v1-shaped state.

Acceptance criteria
- Given the design gate, when the build run opens, then the placement decision (a new `EchoMQ.Metrics` vs
  folded read verbs) is recorded with ≥2 steelmanned alternatives, the counts contract names exactly the
  as-built state set (NOT the v1 list), every read key is spelled against §6, and no `.ex`/Lua artifact
  predates it.
- Given the approved design, when the build lands, then the declared-keys analysis passes over every new
  read script.

INVEST — the opening story, blocking all build stories; testable from the ledger + the analysis run;
encodes EMQ.2.1-INV7, EMQ.2.1-INV4.
Priority: must · Size: 2 · Implements deliverables: EMQ.2.1-D1.

## EMQ.2.1-US8 · EMQ.2.1-US-GATE — the Valkey gate, specification by example

As the Operator, I want every emq.2.1 read registered with a conformance probe and proven against the
truth row, so that the protocol grows by additive minors only and the read verdicts stay a parse, not
prose.

Acceptance criteria
- Given the build, when the conformance suite runs against Valkey on 6390, then the prior **18** scenarios
  pass byte-unchanged and every new read scenario (`counts`, `state`, `metrics`, `dedup`, `rate`,
  `lane_depth` — six) passes beside them — the registry grows additively to **24** and
  `EchoMQ.Conformance.run/2` answers `{:ok, 24}`.
- Given a host without the truth row, when probes run elsewhere, then results report as that row, never as
  the truth row (honest-row reporting — design §1 S-4).

INVEST — standing (the design §7 per-rung twin); testable by one tagged conformance run;
encodes EMQ.2.1-INV1, EMQ.2.1-INV3.
Priority: must · Size: 2 · Implements deliverables: EMQ.2.1-D8.

---
Coverage: D1→US7 · D2→US1 · D3→US2 · D4→US3 · D5→US4 · D6→US5 · D7→US6 · D8→US8.
Spec: [`./emq.2.1.md`](emq.2.1.md) · Agent brief: [`./emq.2.1.llms.md`](emq.2.1.llms.md) ·
Carve: [`./emq.2.design.md`](../emq.2.design.md).
