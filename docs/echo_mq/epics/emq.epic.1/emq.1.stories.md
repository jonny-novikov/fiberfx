# EMQ.1 · user stories
> Who wants the time-and-retry vocabulary, what they need, and how acceptance is known. Derived from
> [`./emq.1.md`](../../specs/emq.1.md) (BUILT — acceptance ran in the emq-1 run and PASSED; this body reflects the
> as-built surface). The consumer ground is the worked consumer codemoji (`echo/apps/codemoji`) and the
> planned consumer echo_bot (`echo/apps/echo_bot`, forward-tense); the capability ground is the drop
> ROADMAP's 2.1 row and the design's §11.10 deferral.

## EMQ.1-US1 — delayed and scheduled work on a clock

As a notifications author (echo_bot is a planned consumer: a delayed Telegram send is a time-window
enqueue, and codemoji's prize settlement runs as a follow-up after scoring), I want run-at and run-in
scheduled enqueue whose delay is a visibility fence over the schedule set, so that a deferred follow-up
or a delayed notification is one enqueue with a due time, not a second queue or a sleeping process.

Acceptance criteria
- Given a queue and a due time, when `enqueue_at/5` enqueues, then the job carries a fresh branded `JOB`
  id, is absent from a claim before the due time, and is claimable after promotion once due.
- Given a run-in delay, when `enqueue_in/5` enqueues, then the semantics equal `enqueue_at/5` with the
  due time computed wire-side from the server clock, and the mint-ordered id remains the sort key (no
  second ordering scheme).
- Given the pending set, when scheduled jobs exist, then no new queue or structure type outside the
  declared grammar exists for them (the visibility-fence constraint, verbatim from the 2.1 row): the row
  carries `state = scheduled` on the existing `emq:{q}:schedule` set.

INVEST — independent of repeatables; testable by a `:valkey` suite at the build run;
encodes EMQ.1-INV2, EMQ.1-INV3.
Priority: must · Size: 5 · Implements deliverables: EMQ.1-D2.

## EMQ.1-US2 — reporting and reconciliation on a cadence

As a periodic-jobs author (a consumer that needs a recurring job — a daily report, a periodic sweep), I
want repeatable jobs whose every occurrence is a fresh branded mint, so that a daily report or a periodic
sweep registers once and every run is a first-class, browsable, mint-ordered job.

Acceptance criteria
- Given a registered repeatable, when two occurrences fire, then each carries a DIFFERENT fresh `JOB` id
  and the morgue/browse surfaces order them by mint (the order theorem holds per occurrence).
- Given a cancellation, when the repeatable is cancelled, then no further occurrence mints and the
  registration is gone from the declared keyspace.
- Given the declared-keys analysis, when the repeat surface lands, then every key it touches is declared
  or grammar-derived (the §11.10 problem, solved by the D1 design).

INVEST — independent of US1's verbs; testable by a `:valkey` suite at the build run;
encodes EMQ.1-INV2, EMQ.1-INV3.
Priority: must · Size: 5 · Implements deliverables: EMQ.1-D3.

## EMQ.1-US3 — retriable follow-ups that exhaust honestly

As a consumer author handling retriable follow-ups (codemoji's work shape is exactly this — a guess is
scored, then a prize is settled, both at-least-once with idempotent handlers), I want
attempts-with-backoff vocabulary and a poison-job drill, so that a transient failure retries on a
policy curve and a persistent failure dead-letters at exactly max attempts with its error kept.

Acceptance criteria
- Given a backoff policy, when a handler fails, then the host-side vocabulary computes `delay_ms` and the
  as-built `Jobs.retry/7` reschedules (`:scheduled`) with `last_error` kept — policy above the wire, the
  wire taking literal delays.
- Given max attempts, when the failure persists, then the job dead-letters (`:dead`) at exactly the cap,
  `last_error` is browsable in the morgue, and the drill records it (the 2.1 row's "max-attempts blind
  spot … closes here, gated by a poison-job drill").
- Given the existing wire, when the vocabulary lands, then `retry`'s wire surface is unchanged (the
  vocabulary composes the as-built verb; no new transition script for retry itself).

INVEST — independent of the scheduler verbs; testable by the drill + a `:valkey` suite;
encodes EMQ.1-INV4, EMQ.1-INV1.
Priority: must · Size: 3 · Implements deliverables: EMQ.1-D4.

## EMQ.1-US4 — due work releases itself

As a bus operator, I want a supervised, opt-in promote pump sweeping due schedule entries through the
existing `promote` verb, so that scheduled and retried work releases on a cadence without every consumer
hand-rolling a sweeper — and a worker started without the pump stays the unchanged v2 core worker.

Acceptance criteria
- Given the pump started with a cadence, when schedule entries come due, then they are promoted and
  claimable within one cadence interval, through `Jobs.promote/3` and nothing else.
- Given the pump NOT started, when a consumer runs, then nothing about the core worker's behavior
  changes (opt-in — the family law).
- Given a pump crash, when supervision restarts it, then the restart semantics are the stated ones and no
  due entry is lost (promotion is idempotent over the schedule set).

INVEST — independent of the repeat surface; testable by a `:valkey` suite with a tight cadence;
encodes EMQ.1-INV5, EMQ.1-INV1.
Priority: should · Size: 3 · Implements deliverables: EMQ.1-D5.

## EMQ.1-US5 — subscribers survive a reconnect

As a near-cache table owner (a coherence feed rides the connector's subscription surface, and the 2.1 row
names the gap: "Connector auto-resubscribe after reconnect (today the table's restart is the
resubscription)"), I want the Connector to re-issue its subscription set after `:reconnect`, so that a
dropped socket does not silently end a table's coherence feed.

Acceptance criteria
- Given a connector with active subscriptions, when the socket drops and the `:reconnect` path restores
  it (the re-issue at `connector.ex:606`, called in the `:reconnect` success arm `connector.ex:334`),
  then the prior subscriptions answer again without any caller restart.
- Given a connector with no subscriptions, when it reconnects, then the behavior is unchanged (the
  re-issue set is empty).
- Given the facade, when the capability lands, then `EchoWire`'s surface is unchanged or extended
  additively only.

INVEST — independent of the scheduler; testable by a `:valkey` suite that kills the socket;
encodes EMQ.1-INV1, EMQ.1-INV6.
Priority: should · Size: 3 · Implements deliverables: EMQ.1-D6.

## EMQ.1-US6 — the design gate before any build

As the Operator, I want the A-1-compatible scheduler design — every schedule/repeat key declared or
grammar-derived, with steelmanned alternatives and an ADR — approved BEFORE any build story runs, so that
the rung never inherits the v1 family's structural flaw (key operands rooted in data values — the design
§11.10 deferral ground).

Acceptance criteria
- Given the design gate, when the build run opens, then the ADR exists with ≥2 steelmanned alternatives
  (incl. the do-nothing baseline), every proposed key spelled against the §6 grammar, and the Operator's
  approval recorded — and no `.ex`/`.lua` artifact predates it.
- Given the approved design, when the build lands, then the declared-keys analysis passes over every new
  script (no exemption at any grain).

INVEST — the opening story, blocking all build stories; testable from the ledger + the analysis run;
encodes EMQ.1-INV7, EMQ.1-INV2.
Priority: must · Size: 2 · Implements deliverables: EMQ.1-D1.

## EMQ.1-US7 · EMQ.1-US-GATE — the Valkey gate, specification by example

As the Operator, I want every emq.1 addition registered with a conformance probe and proven against the
truth row, so that the protocol grows by additive minors only and engine claims stay a parse, not prose.

Acceptance criteria
- Given the build, when the conformance suite runs against Valkey on 6390, then the prior 14 scenarios
  pass byte-unchanged and every new scenario (`schedule`, `repeat`, `backoff`, `resubscribe`) passes
  beside them — the registry is 18 and `EchoMQ.Conformance.run/2` answers `{:ok, 18}`.
- Given a host without the truth row, when probes run elsewhere, then results report as that row, never
  as the truth row (honest-row reporting — design §1 S-4).

INVEST — standing (the design §7 per-rung twin); testable by one tagged conformance run;
encodes EMQ.1-INV1, EMQ.1-INV2.
Priority: must · Size: 2 · Implements deliverables: EMQ.1-D7.

---
Coverage: D1→US6 · D2→US1 · D3→US2 · D4→US3 · D5→US4 · D6→US5 · D7→US7.
Spec: [`./emq.1.md`](../../specs/emq.1.md) · Agent brief: [`./emq.1.llms.md`](../../specs/emq.1.llms.md).
