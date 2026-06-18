> ⚠ **SUPERSEDED 2026-06-13.** emq.2 was RE-SCOPED to the **full-parity rewrite cluster** (`emq-2` ledger
> D-1/D-2). The live stories are in the cluster triads [`./emq.2.1.stories.md`](emq.2.rungs/emq.2.1.stories.md) ·
> [`./emq.2.2.stories.md`](emq.2.rungs/emq.2.2.stories.md) · [`./emq.2.3.stories.md`](emq.2.rungs/emq.2.3.stories.md); the
> design is [`./emq.2.design.md`](emq.2.design.md). The content below is the **retired** migration spec.

# EMQ.2 · user stories
> Who needs the v1→v2 crossing, what they need, and how acceptance is known. Derived from
> [`./emq.2.md`](emq.2.md) (SPECCED, not built — acceptance runs at the build run). The beneficiary is the
> operator who runs the crossing and the program that can then dissolve `apps/echomq`; this rung is PROGRAM
> HYGIENE and names no downstream consumer (recorded, not asserted). The mechanism ground is the frozen
> v1 tool (`echo/apps/echomq/lib/echomq/migration.ex`) and its guide
> (`echo/apps/echomq/guides/migration_v1_to_v2.md`); the law ground is the design's §2 branding lane, §3 fence
> merge, §6 grammar, and §10 seam 1.

## EMQ.2-US1 — the in-place-treatment ruling before any build

As the Operator, I want the in-place-treatment seam (design §10 seam 1) ruled — drain-precondition vs an
in-place converter, plus the wire-semver call — BEFORE any build story runs, so that the migration rung never
silently decides a fork that touches how a future post-reform 2.0 keyspace is crossed, and the build proceeds
on a recorded ground (the likely one being the no-release precondition — the v2 line has never shipped).

Acceptance criteria
- Given the seam, when the build run opens, then the ruling is recorded in the run's ledger (drain-precondition
  as the default, or an in-place converter, with the wire-semver call stated), and no migration artifact in
  `echo_mq` predates it.
- Given the recorded ruling, when the build lands, then the at-rest tool's contract matches it (a
  drain-precondition tool refuses a non-drained source; an in-place converter, if ruled, carries its own
  wire-semver note) — the spec body and the build agree.

INVEST — the opening story, blocking all build stories; testable from the ledger;
encodes EMQ.2-INV7.
Priority: must · Size: 2 · Implements deliverables: EMQ.2-D1.

## EMQ.2-US2 — cross from a v1 deployment without losing a job

As an operator of a v1 (`1.3.0`) deployment, I want an offline at-rest tool that copies one queue's state from
a v1 source to a braced v2 target, journaled and idempotent, so that far-future delayed entries and retained
history that could not drain still cross — and a re-run of a completed crossing is a safe no-op, never a
re-copy.

Acceptance criteria
- Given a v1 source and a v2 target (independent connections — v1-on-Redis → v2-on-Valkey the expected shape),
  when `EchoMQ.Migration.migrate/4` runs for a queue, then it journals at `{emq}:migration:<queue>` on the
  target, copies structures/scores verbatim and per-job hashes field-for-field, and reports `{:ok, report}`.
- Given a queue whose migration already completed, when `migrate/4` runs again, then it re-verifies and answers
  `{:ok, :already_migrated}` with no re-copy (journal idempotency).
- Given an unsafe precondition, when `migrate/4` runs, then it refuses typed — `{:active_jobs, n}` (the v1
  `active` list is non-empty), `{:live_locks, ids}` (unexpired v1 locks), or `{:invalid_target_name, _}` (the
  v1 name fails v2 validation and no explicit rename was given — silent renames forbidden) — and writes nothing
  destructive.

INVEST — independent of the branding lane's id details; testable by a `:valkey` cross-engine drill at the build
run; encodes EMQ.2-INV4, EMQ.2-INV1.
Priority: must · Size: 5 · Implements deliverables: EMQ.2-D2.

## EMQ.2-US3 — migrated jobs keep their order and pass the branded gate

As an operator crossing a v1 queue, I want every migrated numeric job id branded order-preserving and every
non-numeric custom id turned back, so that a migrated queue browses in the same order it had, the v2 keyspace's
job position holds only branded `JOB` ids, and an id the v2 grammar cannot carry is a typed refusal I act on,
not a silent corruption.

Acceptance criteria
- Given a numeric v1 id, when the tool brands it, then the produced id is `EchoData.BrandedId.encode("JOB",
  id)` (14 bytes), the per-job key is `emq:{q}:job:<branded-id>` and passes `EchoMQ.Keyspace.job_key/2`'s
  `BrandedId.valid?/1` gate, and two ids preserve their numeric order as byte order (the order theorem holds
  across the crossing — base62 is order-preserving and INCR-era ids are numerically disjoint from Snowflakes).
- Given a non-numeric v1 custom id, when the tool enumerates ids, then it refuses `{:error,
  {:unmigratable_job_ids, ids}}` (drain those jobs first) and the job position never receives a non-branded id.
- Given set or list members carrying ids, when the structure copy runs, then those members are rewritten to the
  branded form in the same pass (no stale numeric member survives in a v2 structure).

INVEST — independent of US2's connection plumbing; testable by a `:valkey` suite asserting the produced
keyspace; encodes EMQ.2-INV3, EMQ.2-INV2.
Priority: must · Size: 5 · Implements deliverables: EMQ.2-D3.

## EMQ.2-US4 — nothing is destroyed until the copy is proven

As an operator running an irreversible crossing, I want every destructive act gated behind a green verify, so
that the v1 state is deleted only after the v2 copy is proven complete and correct, and a stale v1 worker that
wakes later finds empty, tombstoned queues rather than double-processing live work.

Acceptance criteria
- Given a finished copy, when the tool verifies, then it runs a keyspace classification sweep (every produced
  key parses against the closed braced grammar), per-structure count parity (source vs target), and a per-job
  field-set digest (source vs target) — and proceeds only if all three are green.
- Given a green verify, when the terminal acts run, then they run in the fixed order: DELETE the v1 state keys,
  then stamp the surviving v1 `meta` with `version` = `echomq:2.0.0-migrated`; a failed verify leaves the v1
  source intact.
- Given a stale unfenced v1 worker that wakes after the crossing, when it reads its queues, then they are empty
  (the double-processing residual closed by the terminal DELETE).

INVEST — independent of the fence arm; testable by a `:valkey` suite that inspects ordering and post-state;
encodes EMQ.2-INV4, EMQ.2-INV2.
Priority: must · Size: 3 · Implements deliverables: EMQ.2-D4.

## EMQ.2-US5 — one version authority for the crossing

As a bus maintainer, I want the wire version and the tombstone constant to live as one authority in `echo_mq`,
so that the migration stamps and the connect fence read the same `echomq:2.0.0` / `echomq:2.0.0-migrated`
values from one place, not two drifting copies.

Acceptance criteria
- Given the migration's stamps, when `EchoMQ.Version` is read, then `wire_version/0` answers `echomq:2.0.0` and
  `migration_tombstone/0` answers `echomq:2.0.0-migrated`, and the migration uses those, not literals.
- Given the connector's pinned `@wire_version` (`echo_wire/lib/echo_mq/connector.ex:33`), when `EchoMQ.Version`
  lands, then the pre-build reconcile records one authority and the deduplication is a build concern, not a
  wire change (the wire string is byte-identical either way).

INVEST — independent of the branding details; testable by a pure suite over `EchoMQ.Version`;
encodes EMQ.2-INV5, EMQ.2-INV1.
Priority: should · Size: 2 · Implements deliverables: EMQ.2-D5.

## EMQ.2-US6 — a v2 boot refuses a drained source

As a v2 operator who may misconfigure a target at a drained v1 source, I want the connect-scoped fence to
discriminate the migration tombstone, so that a boot pointed at a tombstoned, drained keyspace refuses typed
rather than running against empty or migrated state — while a correctly migrated store that recorded its
crossing proceeds.

Acceptance criteria
- Given the connect-scoped `{emq}:version` claim (landed at emq.0, `connector.ex:465`), when emq.2 adds the
  tombstone arm, then the claim/read-back/refuse path is byte-unchanged and the five-code fence union is
  unextended (no new fence code).
- Given a store whose meta reads the tombstone with a `journal-completed` record, when a connection fences,
  then it proceeds (the crossing is recorded); given a tombstone with no `{emq}:version` and no journal, when a
  connection fences, then it refuses typed (the config points at a drained source).

INVEST — independent of the at-rest copy; testable by a `:valkey` suite that stamps a tombstone and connects;
encodes EMQ.2-INV5, EMQ.2-INV6.
Priority: should · Size: 3 · Implements deliverables: EMQ.2-D6.

## EMQ.2-US7 — the v1 line refuses a v2 keyspace and its own tombstone

As an operator who upgrades v1 workers during the crossing, I want a terminal `1.3.1` fence-only patch on the
v1 maintenance branch, so that an upgraded v1 worker refuses to run against a v2-stamped keyspace or its own
tombstoned meta — closing the window where a v1 worker writes into a half-crossed keyspace.

Acceptance criteria
- Given the `1.3.x` maintenance branch, when the `1.3.1` patch lands, then its entire diff is the mirror
  preflight: refuse `:v2_keyspace` when the braced `emq:{<q>}:meta` exists; refuse `:migration_tombstone` when
  its own meta reads `echomq:2.0.0-migrated` — and nothing else in `apps/echomq` changes.
- Given EMQ.2-D1's ruling, when the rung closes, then either the `1.3.1` patch is recorded as landed on the
  maintenance branch, or the Operator's decision that it stays a documented runbook step is recorded — the
  freeze exception is explicit, not silent.

INVEST — independent of the v2-side tool; testable from the maintenance-branch diff + the recorded ruling;
encodes EMQ.2-INV6, EMQ.2-INV7.
Priority: should · Size: 2 · Implements deliverables: EMQ.2-D7.

## EMQ.2-US8 · EMQ.2-US-GATE — the crossing is a parse, not prose

As the Operator, I want the crossing's after-state registered as conformance scenarios proven against the truth
row, so that the migration's keyspace claims grow the protocol by additive minors only and "the keyspace is
clean after the crossing" is a parse, not a sentence.

Acceptance criteria
- Given the build, when the conformance suite runs against Valkey on 6390, then the scenarios that exist at the
  pre-build reconcile pass byte-unchanged and every new crossing scenario passes beside them: every key parses
  against the closed grammar, one hashtag per queue, zero unbraced `emq:*` keys, zero `<v1_prefix>:*` operands
  in the operational round-trip.
- Given a host without the truth row, when probes run elsewhere, then results report as that row, never as the
  truth row (honest-row reporting — design §1 S-4).

INVEST — standing (the design §7 per-rung twin); testable by one tagged conformance run;
encodes EMQ.2-INV1, EMQ.2-INV2.
Priority: must · Size: 2 · Implements deliverables: EMQ.2-D8.

---
Coverage: D1→US1 · D2→US2 · D3→US3 · D4→US4 · D5→US5 · D6→US6 · D7→US7 · D8→US8.
Spec: [`./emq.2.md`](emq.2.md).
