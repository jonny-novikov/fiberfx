> ⚠ **SUPERSEDED 2026-06-13.** emq.2 was RE-SCOPED to the **full-parity rewrite cluster** (`emq-2` ledger
> D-1/D-2). The live agent briefs are [`./emq.2.1.llms.md`](emq.2.rungs/emq.2.1.llms.md) ·
> [`./emq.2.2.llms.md`](emq.2.rungs/emq.2.2.llms.md) · [`./emq.2.3.llms.md`](emq.2.rungs/emq.2.3.llms.md); the design is
> [`./emq.2.design.md`](emq.2.design.md). The content below is the **retired** migration spec.

# EMQ.2 · agent brief (llms)
> **Status: SPECCED, not built** — this brief opens a later run, after emq.1 closes. It is seam-gated: the
> first story is the Operator's ruling on the in-place-treatment seam (design §10 seam 1), and no build story
> runs before that gate. Pairs with [`./emq.2.md`](emq.2.md) and [`./emq.2.stories.md`](emq.2.stories.md).
> Framing clause (propagates into every derived prompt): third person for any agent reference; no gendered
> pronouns for agents; no perceptual or interior-state verbs for agents or software; components read, compute,
> refuse, return.

## References

- [`./emq.2.md`](emq.2.md) — the contract (D1–D8, INV1–INV7); the spec body is authoritative.
- [`./emq.2.stories.md`](emq.2.stories.md) — acceptance (US1–US8, incl. the standing EMQ.2-US-GATE).
- The MECHANISM precedent (no-invent applies exactly as to any code — read, re-target, never lift verbatim):
  `echo/apps/echomq/lib/echomq/migration.ex` — the frozen v1 tool's `migrate/4` (`:61`): the dual-connection
  source/target, the journal at the migration key, `target_name/2` (`:79`, silent-rename refusal), the
  `run/6` pipeline (`:95` — `preconditions → enumerate_job_ids → gate_job_ids → journal → copy_structures →
  copy_jobs → copy_dedup_keys → verify → delete_v1_state → stamp_tombstone`), `preconditions/3` (`:131`,
  `{:active_jobs, n}` / `{:live_locks, ids}`), `gate_job_ids/1` (`:152`, `{:unmigratable_job_ids, ids}`),
  `copy_dedup_keys/5` (`:288`, the `de:` scan), `stamp_tombstone/3` (`:403`). Its `@list_types`/`@zset_types`/
  `@hash_types`/`@data_list_types`/`@job_subkeys` structure inventory (`:45-49`). NOTE: this tool produces the
  OLDER unbraced/`j:` form and carries numeric ids "by numeric disjointness" — emq.2 re-targets it at the
  braced grammar AND brands (the contract change, below).
- `echo/apps/echomq/guides/migration_v1_to_v2.md` — the precedent runbook: drain-and-switch primary (§1), the
  at-rest tool (§2), the fence both ways (§3), the named residuals (§4), after-the-crossing (§5). Its braced
  target form (`emq:{q}:<X>`, `emq:{q}:j:<id>`, journal `{emq}:migration:<queue>`) and the five closed fence
  codes are the precedent emq.2 re-homes for `echo_mq`.
- `echo/apps/echomq/lib/echomq/version.ex` — `wire_version/0` `echomq:2.0.0`, `migration_tombstone/0`
  `echomq:2.0.0-migrated`, `major/0` (`:49`), `minor/0` (`:53`) — the constants emq.2's `EchoMQ.Version`
  re-homes in `echo_mq`.
- `echo/apps/echomq/lib/echomq/fence.ex` — the v1-side preflight `preflight/3` (`:67`), `sentinel_keys/2`
  (`:174`), the five codes (`:v1_keyspace` / `:v2_keyspace` / `:version_major_mismatch` / `:foreign_version` /
  `:migration_tombstone`) — the precedent for D7's mirror preflight (the `1.3.1` patch lands on the v1
  `1.3.x` branch, not `echo_mq`).
- The law: [`../emq.design.md`](../../emq.design.md) §2 (the branding lane VERBATIM — "numeric v1 ids brand
  order-preserving (`JOB` + base62(integer) …); non-numeric v1 custom ids refuse through the existing typed
  lane … set/list members carrying ids rewrite in the same pass") · §3 (the fence merge + the tombstone
  discrimination: "tombstone + journal-`completed` on this store ⇒ proceed; tombstone + no `{emq}:version` + no
  journal ⇒ the config points at the drained source — refuse"; "all five fence codes survive the merge") · §6
  (the braced grammar any produced key must satisfy) · §10 seam 1 (the in-place-treatment fork — the D1 gate)
  · §11.4 (replace-on-main: the v2 script set on main, the v1 bundle on the `1.3.x` branch, the migration tool
  carries its own frozen v1 key-name table) · §11.5 (the v1-side `1.3.1` fence-only patch = the mirror
  preflight) · §1 S-1 / §11.1 (the v1 prefix is operator/config input, default `"bull"`; every
  migration/tombstone surface parametric on `v1_prefix`).
- As-built seeds in `echo_mq` (verified anchors; everything else pins at the build run's pre-build reconcile):
  `EchoMQ.Keyspace.job_key/2` (`echo/apps/echo_mq/lib/echo_mq/keyspace.ex:18` — composes `emq:{q}:job:<branded>`
  after `BrandedId.valid?/1`) · `EchoMQ.Keyspace.version_key/0` (`keyspace.ex:30` = `{emq}:version`) ·
  `EchoMQ.Keyspace.queue_key/2` (`keyspace.ex:14`) · `EchoMQ.Keyspace.reserve/1` (`keyspace.ex:27`) · the
  connect-scoped fence `fence/2` (`echo/apps/echo_wire/lib/echo_mq/connector.ex:465`: `SET vkey @wire_version
  NX` + read-back `GET`, refuse `{:error, {:version_fence, got}}` at `:478`/`:483`; the connect path calls it
  at `:387`; `@wire_version` `:33`; the fatal class `:version_fence` `:338`) · `EchoMQ.Conformance.scenarios/0`
  (`echo/apps/echo_mq/lib/echo_mq/conformance.ex:20` — **eighteen** scenarios at this reconcile, `n == 18`,
  `:46`; INV1 holds the as-built count byte-unchanged) · the branding primitive `EchoData.BrandedId.encode/2`
  (`echo/apps/echo_data/lib/echo_data/branded_id.ex:66` — `(ns, snow) :: {:ok, t()} | :error`), `encode!/2`
  (`:85`), `valid?/1` (`:95`), `namespace/1` (`:97`).
- Upstream rung: [`./emq.1.md`](../emq.1.md) — the gate ladder this rung must keep green (its build moves the
  `echo_mq` surface before emq.2 reads it — the lag-1 reconcile is non-optional).
- The seam ground: [`../emq.roadmap.md`](../../emq.roadmap.md) §Seams (seam 1 OPEN, seam 5 dissolution) ·
  [`../echo_mq.md`](../../echo_mq.md) (emq.2 = hygiene, no TRD gate).

## Requirements

- **EMQ.2-R1** — the seam gate: the Operator's in-place-treatment ruling (drain-precondition default vs an
  in-place converter + the wire-semver call), recorded in the run's ledger BEFORE any migration artifact in
  `echo_mq`; the likely ground is the no-release precondition (design §11.11). [US: EMQ.2-US1]
- **EMQ.2-R2** — the at-rest tool in `echo_mq`: `EchoMQ.Migration.migrate/4` over a dual-connection
  source/target, copy-based (never `RENAME`), journaled at `{emq}:migration:<queue>`, idempotent
  (`{:ok, :already_migrated}`), with the four typed precondition refusals re-homed from the v1 tool's
  vocabulary; `v1_prefix` is an option (default `"bull"`), parametric across every source pattern and the
  tombstone target. [US: EMQ.2-US2]
- **EMQ.2-R3** — the branding lane: every numeric v1 id → `EchoData.BrandedId.encode("JOB", id)`; the per-job
  key is `emq:{q}:job:<branded-id>` gated by `EchoMQ.Keyspace.job_key/2`; non-numeric custom ids → `{:error,
  {:unmigratable_job_ids, ids}}`; set/list members carrying ids rewritten to the branded form in the same
  pass; order preserved (the order theorem holds across the crossing). [US: EMQ.2-US3]
- **EMQ.2-R4** — the verify-before-destructive contract: the classification sweep (closed braced grammar) +
  count parity + per-job digest all green before DELETE; the terminal order DELETE-then-tombstone; the
  journal-idempotent re-run no-op. [US: EMQ.2-US4]
- **EMQ.2-R5** — `EchoMQ.Version` in `echo_mq`: `wire_version/0` `echomq:2.0.0`, `migration_tombstone/0`
  `echomq:2.0.0-migrated`; the migration reads these, not literals; the pre-build reconcile records one
  authority against the connector's `@wire_version` (the deduplication is a build concern, the wire string
  unchanged). [US: EMQ.2-US5]
- **EMQ.2-R6** — the fence-tombstone arm: the connect-scoped `{emq}:version` claim is byte-unchanged in its
  claim/read-back/refuse path; emq.2 adds the migration-tombstone discrimination (proceed on tombstone +
  journal-`completed`; refuse on tombstone + no `{emq}:version` + no journal); the five-code fence union
  unextended. [US: EMQ.2-US6]
- **EMQ.2-R7** — the v1-side terminal `1.3.1` fence-only patch on the `apps/echomq` `1.3.x` maintenance branch
  (the mirror preflight: refuse `:v2_keyspace` / `:migration_tombstone`); the entire diff is that preflight;
  the freeze exception is explicit (or the Operator's runbook-step decision recorded). [US: EMQ.2-US7]
- **EMQ.2-R8** — proof: the drain-and-switch runbook re-homed; the crossing's after-state registered as
  conformance scenarios + probes; the scenarios that exist at the pre-build reconcile pass byte-unchanged; the
  cross-engine drill recorded; pure + `:valkey` suites per app; the operator CLI `mix echo_mq.migrate`.
  [US: EMQ.2-US8]
- **EMQ.2-R9** — the carried laws: per-app testing only + `TMPDIR=/tmp`; toolchain re-probed
  (`asdf current erlang`), never hardcoded; Valkey 6390 PONG precondition; `apps/echomq` untouched save the one
  named `1.3.1` maintenance-branch patch (INV6); no agent git; lock-delta law; every surface written "emq.2
  builds" until the build ships. [US: all]

## Execution topology

Runtime (the shape emq.2 builds — forward-named):

```text
echo_mq:    EchoMQ.Migration = a pure-cored module composing Connector commands against TWO connections
            (source + target), the run/6-style pipeline a sequence of pure decisions over wire reads
            (no new process — the migration is a caller-invoked offline pass, the Connector pattern);
            the branding lane = a pure mapper (numeric id -> BrandedId.encode("JOB", id); non-numeric ->
            the typed-refusal lane); EchoMQ.Version = a pure module (constants); the CLI
            Mix.Tasks.EchoMq.Migrate = a thin wrapper over migrate/4.
echo_wire:  the connector's connect-scoped fence keeps its claim/read-back/refuse path BYTE-UNCHANGED;
            it gains the migration-tombstone discrimination arm (reads the tombstone + the journal record;
            proceed-or-refuse) — the only echo_wire edit, additive on the as-built fence.
echomq (v1, FROZEN): the terminal 1.3.1 fence-only patch on the 1.3.x maintenance branch ONLY — the mirror
            preflight; nothing else in apps/echomq changes (the named freeze exception, EMQ.2-D1-gated).
New Lua:    none expected — the migration is wire commands + at most a verify helper; if any transition
            script is touched, every key declared in KEYS[] or grammar-derived (INV1/the design S-6).
```

Tasks (the build run's DAG — D1 gates everything):

```text
B0 pre-build reconcile (lag-1: pin the as-landed echo_mq surface after emq.1 — Keyspace, the fence, the
   conformance count; confirm the migration surface is still absent from echo_mq)
→ B1 EMQ.2-AS1 the seam ruling (STOP for the Operator's in-place-treatment decision)
→ B2 AS5 EchoMQ.Version (the constants + the reconcile to one authority)
→ B3 AS2 the at-rest tool skeleton (dual-connection, journal, preconditions, the four refusals)
→ B4 AS3 the branding lane (encode("JOB", id); the unmigratable refusal; member rewrite)
→ B5 AS4 the verify-before-destructive contract + the terminal acts
→ B6 AS6 the fence-tombstone arm in echo_wire
→ B7 AS7 the v1-side 1.3.1 patch (maintenance branch; D1-gated landing-or-runbook-step)
→ B8 AS8 the conformance crossing scenarios + the runbook re-home + the CLI + the full ladder
```

Touched files (the build run; exact paths fixed at B0/B1): `echo/apps/echo_mq/lib/echo_mq/migration.ex` (new),
`echo/apps/echo_mq/lib/echo_mq/version.ex` (new), `echo/apps/echo_mq/lib/mix/tasks/echo_mq.migrate.ex` (new),
`echo/apps/echo_mq/lib/echo_mq/conformance.ex` (the crossing scenarios, additive),
`echo/apps/echo_wire/lib/echo_mq/connector.ex` (the fence-tombstone arm), the two apps' test trees, and — on the
v1 `1.3.x` maintenance branch ONLY — `echo/apps/echomq/lib/echomq/fence.ex` (the `1.3.1` mirror preflight).
Nothing else in `apps/echomq` on main; nothing in any other app.

## Agent stories

- **EMQ.2-AS1** [implements EMQ.2-US1] — Directive: surface the in-place-treatment seam (design §10 seam 1) —
  drain-precondition vs in-place converter + the wire-semver call, with the no-release-precondition ground —
  and STOP for the Operator's ruling. Acceptance gate: the ruling is recorded in the run's ledger; no migration
  artifact in `echo_mq` predates it.
- **EMQ.2-AS2** [implements EMQ.2-US2] — Directive: build `EchoMQ.Migration.migrate/4` in `echo_mq` —
  dual-connection, journaled at `{emq}:migration:<queue>`, idempotent, the four typed precondition refusals;
  re-target the v1 tool's shape, do not lift it. Acceptance gate: the `:valkey` cross-engine drill proves the
  copy + the idempotent re-run; each refusal fires on its unsafe precondition and writes nothing destructive.
- **EMQ.2-AS3** [implements EMQ.2-US3] — Directive: build the branding lane — `encode("JOB", id)` for numeric
  ids, the `{:unmigratable_job_ids, ids}` refusal for non-numeric, member rewrite in the structure copy.
  Acceptance gate: the produced per-job key passes `Keyspace.job_key/2`'s gate; two ids preserve order as bytes;
  a non-numeric id never reaches the job position; the `:valkey` suite asserts the produced keyspace.
- **EMQ.2-AS4** [implements EMQ.2-US4] — Directive: build the verify-before-destructive contract — the
  classification sweep + count parity + per-job digest, then the terminal DELETE-then-tombstone in order.
  Acceptance gate: no destructive act runs before a green verify; the terminal order holds; a completed-migration
  re-run no-ops; a stale-worker-finds-empty-queues check passes.
- **EMQ.2-AS5** [implements EMQ.2-US5] — Directive: build `EchoMQ.Version` in `echo_mq` (the constants) and
  reconcile to one authority against the connector's `@wire_version`. Acceptance gate: the pure suite proves the
  constants; the migration reads them, not literals; the wire string is byte-identical to the as-built fence's.
- **EMQ.2-AS6** [implements EMQ.2-US6] — Directive: add the migration-tombstone discrimination arm to the
  connect-scoped fence in `echo_wire`, leaving the claim/read-back/refuse path byte-unchanged. Acceptance gate:
  a tombstone + journal-`completed` store proceeds; a tombstone + no `{emq}:version` + no journal refuses typed;
  the five-code union is unextended; the prior fence drills still pass.
- **EMQ.2-AS7** [implements EMQ.2-US7] — Directive: under EMQ.2-D1's ruling, land the v1-side terminal `1.3.1`
  fence-only patch on the `apps/echomq` `1.3.x` maintenance branch (the mirror preflight only), or record the
  Operator's decision that it stays a runbook step. Acceptance gate: the maintenance-branch diff is the mirror
  preflight and nothing else, or the runbook-step ruling is recorded; `apps/echomq` on main is untouched.
- **EMQ.2-AS8** [implements EMQ.2-US8] — Directive: register the crossing's after-state as conformance
  scenarios + probes, re-home the drain-and-switch runbook for `echo_mq`, add the CLI, and run the full proof.
  Acceptance gate: the scenarios that exist at the reconcile pass byte-unchanged; the new crossing scenarios
  green; the cross-engine drill recorded; the emq.1 gate ladder green end-to-end.

## Execution plan — first two stories

1. **EMQ.2-AS1 — the seam ruling.** Read the design §10 seam 1 + §11.11 (the no-release precondition) + the
   roadmap's seam 1; state the fork (drain-precondition default vs in-place converter + the wire-semver call)
   with its ground; STOP for the Operator. No `echo_mq` migration artifact predates the ruling.
2. **EMQ.2-AS5 — EchoMQ.Version.** Only after the ruling (a constants module is the cheapest first build and
   the version source D2–D6 depend on): re-home `wire_version/0` + `migration_tombstone/0` in `echo_mq`; gate:
   the pure suite + the byte-identity check against the connector's `@wire_version`.

## Comprehensive implementation prompt

```text
ROLE: the emq.2 build seats (the architect seat authors EMQ.2-AS1, the seam ruling — STOP for the Operator;
the implementor builds AS2-AS8 ONLY after the Operator rules the in-place-treatment seam). The spec body
docs/echo_mq/specs/emq.2.md is authoritative; this brief derives from it. THIS RUNG IS SPECCED, NOT BUILT —
nothing below exists in echo_mq until the build run (the migration surface lives ONLY in the frozen apps/echomq).
FRAMING: third person for agents; no gendered pronouns; no perceptual/interior-state verbs for agents or
software; components read, compute, refuse, return.

THE GATE (inviolable): EMQ.2-AS1 first — the in-place-treatment seam (design §10 seam 1). State the fork
(drain-precondition, the cheap default — empty queues before the upgrade — vs an in-place converter,
plus the wire-semver call), the likely ground (the no-release precondition: the v2 line has never shipped,
§11.11), and STOP. The Operator rules; only then do build stories run.

WHAT emq.2 IS (do not confuse with a lift of the v1 tool): the v1->v2 migration path RE-PROVEN against
echo_mq. The frozen v1 apps/echomq already implements the copy-verify-DELETE shape and the four typed refusals
(migration.ex:61), but it produces the OLDER unbraced/j: keyspace and carries numeric ids by numeric
disjointness. emq.2 re-targets that path at echo_mq's convergence keyspace: BRACED emq:{q}: (design §6) and
BRANDED JOB ids (design §2: numeric -> BrandedId.encode("JOB", id), order-preserving; non-numeric -> the typed
{:error, {:unmigratable_job_ids, ids}} lane; set/list members rewritten in the same pass). The boot crossing
rides the connect-scoped {emq}:version fence the bus ALREADY carries (echo_wire connector.ex:465, landed at
emq.0) — emq.2 adds only the migration-tombstone arm, not a new fence and not a move-to-connect (already done).

LAWS (carried from emq.1/emq.0 + the design):
- B0 pre-build reconcile first: pin every echo_mq anchor against the AS-LANDED tree (post-emq.1) — Keyspace
  (job_key/2 keyspace.ex:18, version_key/0 :30), the fence (connector.ex:465), the conformance count
  (conformance.ex; 18 at the spec-time reconcile — INV1 holds the as-built count byte-unchanged); confirm the
  migration surface is STILL absent from echo_mq (grep: none today).
- The migration produces ONLY the existing braced grammar; it adds NO key type (INV1/INV2). Every migrated id
  is branded order-preserving via BrandedId.encode("JOB", id); the per-job key passes job_key/2's gate (INV3).
- Verify before destroy: classification sweep + count parity + per-job digest green BEFORE DELETE; terminal
  order DELETE-then-tombstone; the completed-migration re-run no-ops (INV4).
- The connect-scoped fence claim path stays BYTE-UNCHANGED; emq.2 adds the tombstone arm only; the five-code
  fence union is unextended (INV5).
- apps/echomq is untouched EXCEPT the single terminal 1.3.1 fence-only patch on its 1.3.x maintenance branch
  (the mirror preflight), and only under EMQ.2-D1's ruling (INV6). v1_prefix is config input, default "bull"
  (design S-1/§11.1) — parametric across every source pattern and the tombstone target.
- Per-app tests only + TMPDIR=/tmp; toolchain re-probed (asdf current erlang), never hardcoded; Valkey 6390
  PONG before wire steps; no agent git; the lock-delta law.
- This rung is PROGRAM HYGIENE — it names NO Exchange-platform consumer (echo_mq.md, the emq.2 row: "no TRD rung
  gates on it (recorded, not asserted)"). Manufacture no consumer trace.

BUILD ORDER: B0 reconcile -> B1 seam ruling+STOP -> B2 EchoMQ.Version -> B3 the at-rest tool skeleton ->
B4 the branding lane -> B5 verify+terminal acts -> B6 the fence-tombstone arm -> B7 the v1 1.3.1 patch
(D1-gated) -> B8 conformance crossing scenarios + the runbook re-home + the CLI + the emq.1 ladder end-to-end.

REPORT: the seam ruling reference; per-story acceptance-gate outputs (the cross-engine drill, the produced
braced+branded keyspace, the verify-before-destroy ordering, the terminal-order check, the tombstone-arm
fence drills, the maintenance-branch 1.3.1 diff or the runbook-step ruling); the classification-sweep result;
the conformance tallies (the as-built count byte-unchanged + the crossing additions); the full ladder tails;
the INV checks. Completion claim only when every DoD box in emq.2.md is checkable from the outputs.
```
