> ⚠ **SUPERSEDED 2026-06-13.** emq.2 was RE-SCOPED from "the v1→v2 migration path" to the **full-parity
> rewrite cluster** (`echo_mq` built fresh, no compatibility layer — `emq-2` ledger D-1/D-2). The binding
> artifacts are [`./emq.2.design.md`](emq.2.design.md) (the carve + the ADRs + the Arm A/B fork) and the
> triads [`./emq.2.1.md`](emq.2.rungs/emq.2.1.md) (read plane) · [`./emq.2.2.md`](emq.2.rungs/emq.2.2.md) (operator plane) ·
> [`./emq.2.3.md`](emq.2.rungs/emq.2.3.md) (watch plane). The content below is the **retired** migration spec, kept
> for history; it carries no live contract.

# EMQ.2 · The v1→v2 migration path, re-proven against echo_mq — Movement I, program hygiene
> ✅ **Shipped** — the as-built deliverable (verbs · conformance delta · commit) is in the [changelog](../../../emq.changelog.md). This body is the historical spec.
> **Status: SPECCED, not built** (planned-abstract on the Stage-1b ladder; authored this run alongside the
> emq.1 build; built a later run). emq.2 builds, inside `echo/apps/echo_mq` under the v2 laws, the supported
> crossing from a v1 (`1.3.0`) deployment to the BCS 2.0 keyspace: drain-and-switch as the primary runbook,
> an at-rest copy-verify-DELETE tool whose every produced key is braced `emq:{q}:` and whose every migrated
> job id is a branded `JOB`, the typed refusal that turns an unmigratable id back at the boundary, and the
> v1-side terminal `1.3.1` fence-only patch. This rung is PROGRAM HYGIENE — it retires the push source's
> deployments so `apps/echomq` can dissolve; no consumer rung gates on it (recorded, not asserted).

## Goal

emq.2 builds the migration surface that lets a v1 deployment cross to EchoMQ 2.0 as the convergence target
serves it. The mechanism precedent is the frozen v1 line's own tool (`EchoMQ.Migration.migrate/4`,
`apps/echomq/lib/echomq/migration.ex:61` — offline, journaled, copy-verify-DELETE, typed-refusal-gated), and
the precedent runbook is its guide (`apps/echomq/guides/migration_v1_to_v2.md` — drain-and-switch primary, the
at-rest tool for what cannot drain, the fence both ways, the named residuals). emq.2 re-proves that path
against `echo_mq`: the produced keyspace is braced `emq:{q}:` per the design §6 grammar (not the v1 tool's
older unbraced form), every migrated job id is branded order-preserving through `EchoData.BrandedId.encode/2`
(`JOB` + base62 of the v1 numeric id — design §2), the boot crossing rides the connect-scoped `{emq}:version`
fence the bus already carries (`echo_wire/lib/echo_mq/connector.ex:465`, landed at emq.0), and the v1 line
gets its single terminal fence-only patch on its `1.3.x` maintenance branch. All migration work is additive on
the v2 wire (the conformance scenarios pass byte-unchanged; the version fence is unchanged in logic), opened by
an Operator ruling on the in-place treatment seam (design §10 seam 1).

## Rationale (5W)

- **Why** — the push source can dissolve only when nothing depends on what it alone provides, and a v1
  deployment's at-rest state is exactly that: jobs, structures, and history under the v1 keyspace that no v2
  boot can read (a v2 boot meeting a non-`echomq:` keyspace refuses typed — the fence law). The design names
  the crossing as a standing obligation: "an explicit migration path" (§1 S-3), "Migration must brand: numeric
  v1 ids brand order-preserving (`JOB` + base62(integer) — injective, numerically disjoint from any realistic
  Snowflake); non-numeric v1 custom ids refuse through the existing typed lane (`{:error,
  {:unmigratable_job_ids, ids}}` — drain first); set/list members carrying ids rewrite in the same pass" (§2
  Consequences). The roadmap places it as Movement I program hygiene: "the v1→v2 migration path re-proven
  against `echo_mq` (drain-and-switch; the order-preserving branding lane; the typed unmigratable-ids refusal;
  the v1-side terminal `1.3.1` fence-only patch)" ([`../emq.roadmap.md`](../../../emq.roadmap.md), the emq.2 ladder
  row). The mechanism is not invented here: the frozen v1 tool already implements the copy-verify-DELETE shape
  and the four typed refusals; emq.2 re-targets it at the braced, branded convergence keyspace.
- **What** — emq.2 builds, inside `echo_mq`: an `EchoMQ.Migration` surface (the offline `migrate/4` over a
  dual-connection source/target, the journal at `{emq}:migration:<queue>`, the precondition refusals, the
  verbatim structure/score copy, the per-job hash copy, the dedup-key copy with re-applied TTLs, the verify
  pass, the terminal DELETE-then-tombstone); the order-preserving branding lane (every numeric v1 id →
  `EchoData.BrandedId.encode("JOB", id)`; every non-numeric custom id → the `{:error, {:unmigratable_job_ids,
  ids}}` lane; the set/list members carrying ids rewritten in the same pass); the `EchoMQ.Version` constants in
  `echo_mq` (`wire_version/0` = `echomq:2.0.0`, `migration_tombstone/0` = `echomq:2.0.0-migrated`); the
  migration-tombstone discrimination added to the connect-scoped fence (tombstone + journal-`completed` ⇒
  proceed; tombstone + no `{emq}:version` + no journal ⇒ the config points at a drained source, refuse —
  design §3); the operator CLI (`mix echo_mq.migrate`); and the v1-side terminal `1.3.1` fence-only patch on the
  `apps/echomq` `1.3.x` maintenance branch (the mirror preflight: refuse `:v2_keyspace` on a v2-stamped
  keyspace, refuse `:migration_tombstone` on its own tombstoned meta — design §11.5).
- **Who** — operators of a v1 (`1.3.0`) deployment crossing to 2.0; the program itself (the rung un-blocks the
  push source's dissolution — seam 5). **No consumer rung names this surface.** The program front door
  records it as hygiene, not a feature: "program hygiene rather than a consumer feature: it retires the push
  source's deployments; no consumer rung gates on it (recorded, not asserted)" ([`../echo_mq.md`](../../../echo_mq.md),
  the emq.2 ladder row). This rung manufactures no consumer trace; the crossing's beneficiary is the operator
  who runs it and the program that can then dissolve `apps/echomq`.
- **When** — Movement I, after emq.1 closes (planned-abstract on the confirmed ladder). SPECCED this run,
  BUILT a later run. The in-place-treatment seam (design §10 seam 1) settles with the Operator BEFORE the build
  starts; its likely resolution ground is the no-release precondition (the v2 line has never shipped — §11.11).
- **Where** — `echo/apps/echo_mq` (the new `EchoMQ.Migration` + `EchoMQ.Version` modules; the fence-tombstone
  arm in the bus's connect path; the new conformance scenarios for the crossing; the CLI under
  `lib/mix/tasks/`) and the frozen v1 `echo/apps/echomq` on its `1.3.x` maintenance branch ONLY for the
  terminal `1.3.1` patch (the named exception to the freeze — flagged as a seam, settled with the Operator).
  Exact key, registry, and script anchors beyond those cited here are pinned at the rung's pre-build reconcile
  (the lag-1 discipline), not invented now — emq.1's build moves the `echo_mq` surface before emq.2 reads it.

## Scope

- **In** — the Operator ruling on the in-place-treatment seam (the gate); the at-rest `EchoMQ.Migration`
  surface re-targeted at the braced, branded convergence keyspace; the order-preserving branding lane; the four
  typed precondition refusals carried from the v1 tool's vocabulary; the journal idempotency
  (`{:ok, :already_migrated}` on a re-run of a completed migration); the verify-before-destructive ordering;
  the terminal DELETE-then-tombstone; the migration-tombstone discrimination on the connect-scoped fence; the
  v1-side terminal `1.3.1` fence-only patch; the drain-and-switch runbook re-homed for `echo_mq`; the
  conformance-scenario and probe additions that register the crossing; pure + `:valkey` suites; the
  cross-engine migration drill (v1-source → v2-target) as a recorded check.
- **Out** — any change to the v2 wire grammar (the migration produces the existing braced keyspace; it adds no
  key type — the program's master invariant); the connect-scoped version claim itself (landed at emq.0,
  unchanged in logic — emq.2 adds only the tombstone arm); the in-place v2→v2 migration of a future
  post-reform 2.0 keyspace (design §10 seam 1's other half — that build, if ruled in, is its own concern);
  the parent/flow family (emq.3); groups deepening (emq.4); batches (emq.5); any edit to the frozen v1 line
  beyond the single terminal `1.3.1` fence-only patch; the never-upgraded `1.3.0` binary's structural
  unfenceability (a documented residual, not a buildable surface — design §3, §11.5).

## Deliverables

emq.2 builds (forward-named; nothing below exists in `echo_mq` yet — the migration surface lives only in the
frozen `apps/echomq`):

- **EMQ.2-D1** — **the seam ruling (FIRST):** the Operator's settlement of the in-place-treatment seam
  (design §10 seam 1) — drain-precondition (the cheap default: empty queues before the upgrade) vs an
  in-place converter, plus the wire-semver call for any keyspace a future post-reform 2.0 tree writes; the
  likely ground is the no-release precondition (§11.11). Recorded BEFORE any build story runs.
- **EMQ.2-D2** — the at-rest tool: `EchoMQ.Migration.migrate/4` in `echo_mq` over a dual-connection
  source/target (cross-engine first-class — v1-on-Redis → v2-on-Valkey), copy-based (never `RENAME`),
  journaled at `{emq}:migration:<queue>`, idempotent (`{:ok, :already_migrated}` on a completed re-run), with
  the four typed precondition refusals carried from the v1 tool's vocabulary (`{:active_jobs, n}` /
  `{:live_locks, ids}` / `{:invalid_target_name, _}` / `{:unmigratable_job_ids, ids}`).
- **EMQ.2-D3** — the order-preserving branding lane: every numeric v1 id maps to
  `EchoData.BrandedId.encode("JOB", id)` (the 14-byte branded form `echo_mq`'s `EchoMQ.Keyspace.job_key/2`
  gates on); the produced per-job key is `emq:{q}:job:<branded-id>` (the braced grammar, design §6); every
  non-numeric custom id is refused through the `{:error, {:unmigratable_job_ids, ids}}` lane (drain first);
  set/list members carrying ids are rewritten to the branded form in the same pass.
- **EMQ.2-D4** — the verify-before-destructive contract: a keyspace classification sweep (every produced key
  parses against the closed braced grammar), per-structure count parity, and a per-job field-set digest
  (source vs target) — all green before the terminal acts: DELETE the v1 state keys (a stale unfenced `1.3.0`
  worker that wakes finds empty queues), then stamp the surviving v1 `meta` with
  `version` = `echomq:2.0.0-migrated`.
- **EMQ.2-D5** — `EchoMQ.Version` in `echo_mq`: the wire-version authority and the tombstone constant
  (`wire_version/0` = `echomq:2.0.0`; `migration_tombstone/0` = `echomq:2.0.0-migrated`), the migration's
  version source — placed beside the as-built `@wire_version` the connector already pins
  (`connector.ex:33`), reconciled to one authority at the pre-build reconcile (the as-built fence inlines the
  string; emq.2 names the deduplication a build concern, not a wire change).
- **EMQ.2-D6** — the fence-tombstone arm: the connect-scoped `{emq}:version` fence (landed at emq.0 —
  `connector.ex:465`, unchanged in logic) gains the migration-tombstone discrimination (tombstone +
  journal-`completed` on this store ⇒ proceed; tombstone + no `{emq}:version` + no journal ⇒ the config points
  at a drained source, refuse — design §3); the existing typed fence outcome is reused, no new fence-union
  code added (the five-code union stands — design §5).
- **EMQ.2-D7** — the v1-side terminal `1.3.1` fence-only patch on the `apps/echomq` `1.3.x` maintenance
  branch: the entire diff is the mirror preflight — refuse `:v2_keyspace` when the braced `emq:{<q>}:meta`
  exists, refuse `:migration_tombstone` when its own meta reads `echomq:2.0.0-migrated` (design §11.5). The
  named exception to the freeze, isolated to the maintenance branch; flagged as a seam (EMQ.2-D1's ruling
  covers whether this lands here or stays a documented runbook step).
- **EMQ.2-D8** — proof: the drain-and-switch runbook re-homed for `echo_mq`; conformance scenarios + probes
  registered for the crossing (the after-the-crossing assertions: every key parses against the closed grammar,
  one hashtag per queue, zero unbraced `emq:*` keys, zero `<v1_prefix>:*` operands in the operational
  round-trip); the cross-engine migration drill recorded; pure + `:valkey` suites; the operator CLI
  (`mix echo_mq.migrate`).

## Invariants

- **EMQ.2-INV1** — the wire law: zero wire breaks; the migration adds no key type and produces only the
  existing braced grammar; every conformance addition is an additive protocol minor registered with its probe
  in the same change; the conformance scenarios that exist at the pre-build reconcile pass byte-unchanged.
- **EMQ.2-INV2** — braced totality: every key the tool produces is `emq:{q}:<suffix>` or a `{emq}:` reserve
  member, parses against the closed grammar (design §6), and carries exactly the queue's hashtag; no unbraced
  `emq:*` key and no `<v1_prefix>:*` operand survives in the operational round-trip after the crossing.
- **EMQ.2-INV3** — branded identity, order-preserving: every migrated job id is `EchoData.BrandedId.encode("JOB",
  v1_numeric_id)` — injective and numerically disjoint from any realistic Snowflake, so mint order stays byte
  order (the order theorem holds across the crossing); the per-job key is gated by `BrandedId.valid?/1` at
  `EchoMQ.Keyspace.job_key/2`; a non-numeric custom id never reaches the job position (refused through the
  typed lane, drain first).
- **EMQ.2-INV4** — verify before destroy: no DELETE or tombstone stamp runs until the classification sweep,
  the count parity, and the per-job digest are all green; the terminal acts run in the fixed order
  (DELETE v1 state → stamp tombstone); a re-run of a completed migration re-verifies and no-ops, never
  re-copies (journal idempotency).
- **EMQ.2-INV5** — the fence is unchanged in logic: the connect-scoped `{emq}:version` claim (landed at emq.0)
  is byte-unchanged in its claim/read-back/refuse path; emq.2 adds only the migration-tombstone discrimination
  arm; the five-code fence union stands unextended (design §5); no new fence code is minted.
- **EMQ.2-INV6** — the freeze holds except for the one named patch: `apps/echomq` is untouched save for the
  terminal `1.3.1` fence-only patch on its `1.3.x` maintenance branch (EMQ.2-D7), and that patch's entire diff
  is the mirror preflight; the program's per-app testing law, the no-git-by-agents law, and the lock-delta law
  carry from emq.0.
- **EMQ.2-INV7** — the seam gate: no build artifact exists until EMQ.2-D1's in-place-treatment ruling is
  Operator-recorded; this triad ships as SPECCED and every surface is written "emq.2 builds", never as shipped.

## Definition of Done

- [ ] EMQ.2-D1: the in-place-treatment seam ruled by the Operator (the gate that opens the build run).
- [ ] D2–D6 built in `echo_mq` with every produced key passing the braced-grammar classification (INV2) and
      every migrated id branded order-preserving (INV3); the at-rest tool's four typed refusals exercised.
- [ ] The verify-before-destructive ordering proven: the classification sweep + count parity + per-job digest
      green before DELETE; the terminal order held; a completed-migration re-run no-ops (INV4).
- [ ] The cross-engine migration drill recorded: a v1-keyspace source migrates to a braced, branded v2 target;
      after the crossing every key parses against the closed grammar and zero `<v1_prefix>:*` operands survive.
- [ ] The fence-tombstone arm proven: a tombstoned source refuses on connect; a tombstone + journal-`completed`
      store proceeds; the connect-scoped claim path is byte-unchanged (INV5).
- [ ] EMQ.2-D7: the v1-side terminal `1.3.1` fence-only patch on the maintenance branch (or the Operator's
      ruling that it stays a documented runbook step) — recorded either way.
- [ ] Pure + `:valkey` suites green per-app; the conformance scenarios that exist at the pre-build reconcile
      pass byte-unchanged and green; the new crossing scenarios green.
- [ ] The emq.1 gate ladder still green end-to-end (no regression); the spec body remains authoritative and the
      as-built reconcile syncs it post-build.

Stories: [`./emq.2.stories.md`](emq.2.stories.md) ·
Runbook: [`./emq.2.prompt.md`](emq.2.prompt.md) · Roadmap: [`../emq.roadmap.md`](../../../emq.roadmap.md) (the emq.2
ladder row; seam 1) · Design: [`../emq.design.md`](../../../emq.design.md) §2 (the branding lane), §3 (the fence
merge + tombstone discrimination), §6 (the braced grammar), §10 seam 1 (the in-place treatment), §11.4 (replace
-on-main), §11.5 (the v1 terminal fence-only patch), §1 S-1 / §11.1 (`v1_prefix` is config input, default
`"bull"`) · Mechanism precedent: `echo/apps/echomq/lib/echomq/migration.ex`,
`echo/apps/echomq/guides/migration_v1_to_v2.md` · Program front door: [`../echo_mq.md`](../../../echo_mq.md) (emq.2 =
hygiene, no consumer gate) · Approach: [`../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
