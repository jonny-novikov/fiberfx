# MCP2 · agent brief (llms)

> Implementation brief for a coding agent. References, traced requirements, the execution topology,
> and a self-contained build brief. Pairs with the spec mcp2.md and the stories mcp2.stories.md.
> This rung has no runbook — the comprehensive implementation prompt below is the complete build
> instruction. Reconciled post-build: the rung is as-built at HEAD (`f44f0539`); every cite below
> is pinned to that tree.

## References

- `apps/aaw/cmd/aaw/main.go` — the tool surface, as built: `:179-185` `EntryIn` (`Actor` at `:184`
  — the attribution gap closed), `:264-279` `aaw_spawn` (the spawn-declared `deliverable` recorded
  via `SpawnIn.Deliverable`, `:72`), `:281-306` `agent_register` (`:294-303` the FAKE-N
  computation, kept and re-routed from stderr to `.claude/audit.log`), `:308-319` `agent_send`
  (every writer now touches via `touchActor`, `:197-206`), `:321-342` `agent_heartbeat` (the 18th
  tool), `:344-384` `aaw_status` (the gate console).
- `apps/aaw/internal/store/` — the store MCP1 hardened, now carrying the rung's surfaces:
  `ledger.go:54-67` `Tallies` (the gate-console feed), `ledger.go:125-167` `AppendAttributed`
  (the ledger-then-registry attributed write under the per-scope lock), `store.go:466-483`
  `TouchActor`, `store.go:492-514` `Liveness` (the three-source fusion), `store.go:438-459`
  `Heartbeat`. MCP1's lock + atomic-write discipline is assumed, not re-built here.
- `apps/aaw/internal/signals/signals.go` — the shipped signal plane: `:23-32` the policy constants
  (W/K/cap), `:35-41` the closed code set, `:76-94` `VSolo1`, `:99-108` `VSolo2`
  (computed-never-emitted), `:116-168` the deduplicating `Emitter` (O_APPEND to
  `<workspace>/.claude/audit.log`), `:171-180` the line format.
- The design canon (settled): [`../aaw.mcp.design.md`](../aaw.mcp.design.md) — AD-4 (attribution,
  the three-source fusion, lease-at-dispatch, the ledger-then-registry order and the `aaw audit`
  drift detector), AD-5 (the signal contract: codes, dedup, the line format, V-SOLO-2
  evidence-only per W-1), §7.1 (the `agent_heartbeat` shape). The dual-Venus corpus the canon
  consolidates — venus-1 ADR-9 (attribution parameters; its `· by` header tail superseded by the
  registry-side resolution), ADR-10 (three-source fusion), ADR-11 (codes/dedup/format), ADR-12
  (the console); venus-2 ADR-7 (the single `actor`), ADR-8 (`agent_heartbeat`), ADR-9 (the
  evidence matrix), ADR-10 (the gate console); apollo rows 7/8/17/27, §0 W-1, §4.3-2/3 — was
  retired from the tree at `f44f0539`; those ids resolve in git history
  (`git show 9d145486:docs/aaw/mcp/design/<file>`).
- Upstream: the proposal `aaw.mcp.proposal.md` — R-5 (registry + liveness make FAKE-N/V-SOLO
  detectable) and R-4 at `:74-79` (the degraded run that decides W-1); retired from the tree
  post-canon, readable via `git show 74d8a899:docs/aaw/mcp/aaw.mcp.proposal.md`;
  the ledger [`../aaw.mcp.progress.md`](../aaw.mcp.progress.md) — D-3 (the narrowed ship set),
  D-6(a) (the `agent_heartbeat` name pick and the riding Director picks), D-7 (the formation
  context); [the specs approach](../../../elixir/specs/specs.approach.md).
- Depends on MCP1 (the per-scope lock, the read-through index, the registry write discipline) —
  referenced by id; its triad is a concurrent-wave sibling and is not linked here.

## Requirements

- **MCP2-R1** — every writing tool accepts an optional `actor` (`agent_heartbeat` attributes by
  its `name` parameter — AD-4); a registered name advances `last_seen_at` and, on a ledger
  writer, that agent's per-prefix activity counter (a non-ledger writer carries no entry prefix
  and advances `last_seen_at` alone), registry-side only — the ledger entry header stays the
  locked form; an unregistered name proceeds, appends one `UNREGISTERED-ATTRIBUTION` advisory
  line, and creates no registry row. [US: MCP2-US1]
- **MCP2-R2** — `agent_heartbeat(scope, name, note?, quiet_for_minutes?)` ships as the 18th tool: a
  zero-ledger-cost touch recording `last_seen_at`, an optional declared-quiet window
  (`quiet_for_minutes` capped at 240), and an optional note; lease-at-dispatch — the director may
  heartbeat for a peer it dispatches. [US: MCP2-US2]
- **MCP2-R3** — effective liveness = the most recent of {an attributed-call touch, an unexpired
  declared-quiet window, the spawn-declared `deliverable` file mtime}; the per-row verdict is
  active | quiet-declared | stale with the winning source named; evaluation happens only at
  `aaw_status` and Z-append — no background janitor. [US: MCP2-US2]
- **MCP2-R4** — `aaw_status` returns the gate-console shape: `tallies`,
  `gates:{z_eligible, d_count, z_count}` with z_eligible = d_count ≥ 1, per-agent rows
  {name, role, ccl_id, last_seen_at, verdict + winning source}, open (unexpired) signals, the
  archived flag, and parse-health fields ([RECONCILE] AD-4's `model` field landed early in the
  harden pass — `Agent.Model` at `internal/store/store.go:48`, additive and record-only; the
  `wire_contract` verdict stays deferred to mcp4 per `cmd/aaw/main.go:154`). [US: MCP2-US3]
- **MCP2-R5** — FAKE-N is evaluated at `agent_register` (registered > spawned); V-SOLO-1 at
  `aaw_status` and Z-append with both clauses required (all non-director rows stale AND ≥K
  director-attributed entries within W); V-SOLO-2 is computed but never emitted; dedup = one line
  per (scope, code, evidence-window); the line format is
  `<RFC3339> aaw <CODE> scope=<scope> <k>=<v>… msg="<evidence>"`. [US: MCP2-US4]
- **MCP2-R6** — the attributed write orders ledger-append then registry-counter under the per-scope
  lock; the retry-after-ambiguous-failure duplicate is documented as accepted; the `aaw audit`
  tally-recount (a later rung's CLI) is named as the cross-file-drift detector. [US: MCP2-US5]
- **MCP2-R7** — the `actor`, heartbeat, and status fields are additive: a deferred-schema client
  holding MCP1 shapes stays valid; the tool surface is 18 = 17 + `agent_heartbeat`.
  [US: MCP2-US1, MCP2-US3]

## Execution topology

Runtime: a writing tool flows handler → store under the per-scope lock → ledger append then
registry counter; liveness fuses three file-backed sources at read time; signals append advisory
lines to `.claude/audit.log`; `aaw_status` reads and never blocks.

```text
write ──▶ handler(actor?) ──scope-lock──▶ ledger.Append ──then──▶ registry: counter + last_seen_at
                                            └── unregistered actor ──▶ audit.log UNREGISTERED-ATTRIBUTION
liveness (read-time) = most-recent{ attributed touch · quiet_until · deliverable mtime }
                                            ──▶ verdict active | quiet-declared | stale + winning source
signals: FAKE-N @agent_register · V-SOLO-1 @aaw_status/Z-append (two clauses)
                                            ──▶ .claude/audit.log, one line per (scope, code, window)
aaw_status ──▶ tallies + gates{z_eligible,d_count,z_count} + agent rows + open signals  (never blocks)
```

Tasks (each step leaves the app compiling):

```text
1. actor on EntryIn + every writer; registry-side touch + per-prefix counter; UNREGISTERED-ATTRIBUTION
   ─▶ 2. agent_heartbeat (cap 240) + deliverable recorded at aaw_spawn + the three-source fusion
   ─▶ 3. aaw_status grown to the gate console (gates + rows w/ verdicts + open signals + parse health)
   ─▶ 4. internal/signals: FAKE-N + two-clause V-SOLO-1 emit, V-SOLO-2 computed-only, dedup + format
   ─▶ 5. write order ledger-then-registry + retry-duplicate accepted + the aaw-audit detector named
   ─▶ 6. tests: exemplar byte-identity golden (INV1) · Q-4 mtime property (INV2) · one-call
         z_eligible (INV5) · R-4 degraded-run no-emission + two-clause V-SOLO-1 (INV3/INV4) ·
         selftest at 18 tools
```

Touched files (as built): `apps/aaw/cmd/aaw/main.go`, `apps/aaw/internal/store/ledger.go`,
`apps/aaw/internal/store/store.go`, `apps/aaw/internal/signals/` (new — FAKE-N/V-SOLO computation
+ audit.log emit, with `signals_test.go`), `apps/aaw/internal/store/mcp2_test.go` +
`mcp2_wire_test.go` + `store_test.go`.

## Agent stories

- **MCP2-AS1** [implements MCP2-US1] — Directive: add `actor` to `EntryIn` and every writing tool;
  when the name is registered, touch `last_seen_at` and advance the per-prefix activity counter
  registry-side; leave the entry header production unchanged; when unregistered, proceed and append
  the `UNREGISTERED-ATTRIBUTION` advisory line, creating no row. Acceptance gate: an
  exemplar-ledger golden is byte-identical with and without `actor`; an unregistered-actor test
  shows the advisory line and no new row.
- **MCP2-AS2** [implements MCP2-US2] — Directive: add
  `agent_heartbeat(scope, name, note?, quiet_for_minutes?)` with the 240-minute cap; record the
  spawn-declared `deliverable` at `aaw_spawn`; compute the three-source liveness fusion with the
  winning source on each row. Acceptance gate: the Q-4 property — a peer advancing only its
  deliverable mtime reads active with zero tool calls.
- **MCP2-AS3** [implements MCP2-US3] — Directive: extend `aaw_status` to the gate-console shape
  (`tallies`, `gates`, per-agent rows with verdicts and winning sources, open signals, the archived
  flag, parse-health fields; the `wire_contract` verdict stays omitted until mcp4). Acceptance
  gate: a seeded scope with ≥1 D and a Z returns `gates.z_eligible` true in one call.
- **MCP2-AS4** [implements MCP2-US4] — Directive: add `internal/signals/` computing FAKE-N (at
  `agent_register`) and two-clause V-SOLO-1 (at `aaw_status`/Z-append), emitting deduplicated lines
  in the fixed format to `.claude/audit.log`; compute V-SOLO-2 without emitting. Acceptance gate:
  the R-4 degraded-run test asserts no V-SOLO-2 line; a two-clause test asserts V-SOLO-1 fires only
  with both clauses true.
- **MCP2-AS5** [implements MCP2-US5] — Directive: order the attributed write ledger-append then
  registry-counter under the per-scope lock; document the bounded cross-file drift and the accepted
  retry-duplicate, naming the `aaw audit` tally-recount as the detector. Acceptance gate: a
  write-order test plus a comment/doc naming the drift and `aaw audit`.

## Execution plan — first two stories

1. **MCP2-AS1 — the actor parameter.** Add `Actor string` to `EntryIn` and the other writer inputs
   in `cmd/aaw/main.go`; in the write path, after the ledger append, resolve the name against the
   registry under the per-scope lock — registered: touch + counter; unregistered:
   `UNREGISTERED-ATTRIBUTION` to `.claude/audit.log`, no row. Gate: the exemplar golden
   byte-identical with and without `actor`; `go build ./...` clean.
2. **MCP2-AS2 — heartbeat + fusion.** Register `agent_heartbeat` (cap `quiet_for_minutes` at 240;
   persist `quiet_until` and the note on the registry row); record `deliverable` at `aaw_spawn`;
   implement the most-recent-of fusion returning verdict + winning source. Gate: the Q-4 property
   test (an mtime-only peer reads active) green.

## Comprehensive implementation prompt

```text
Build MCP2 — attribution, liveness, and the status gate console — over the MCP1 store discipline
(the per-scope lock, the read-through index, the atomic write discipline). Edit apps/aaw only; do
not touch apps/mcp-go; run no git. Execute the agent stories in order, AS1 -> AS5.

AS1 — actor. Add an optional `actor` parameter to EntryIn and every writing tool in
apps/aaw/cmd/aaw/main.go (agent_heartbeat attributes by its name parameter). When the name matches
a registry row: touch last_seen_at and, on a ledger writer, advance that agent's per-prefix
activity counter (a non-ledger writer has no entry prefix — touch only) — registry-side only; the
appended ledger entry header stays
the locked `### <PREFIX>-<n> — <title>` form byte-for-byte. When the name matches no row: the
write proceeds, one UNREGISTERED-ATTRIBUTION advisory line is appended to .claude/audit.log, and
no row is created.

AS2 — heartbeat + three-source liveness. Add agent_heartbeat(scope, name, note?,
quiet_for_minutes?) — a zero-ledger-cost touch; cap quiet_for_minutes at 240 and persist
quiet_until plus the note on the registry row. Record the spawn-declared deliverable path at
aaw_spawn. Effective liveness = the most recent of {an attributed-call touch, an unexpired
declared-quiet window, the deliverable file mtime}; the verdict is active | quiet-declared | stale
with the winning source named; evaluated only at aaw_status and Z-append — no background janitor.
The director may heartbeat for a peer it dispatches (lease-at-dispatch).

AS3 — the gate console. Extend aaw_status to return: tallies; gates{z_eligible = d_count >= 1,
d_count, z_count}; per-agent rows {name, role, ccl_id, last_seen_at, verdict + winning source};
open (unexpired) signals; the archived flag; parse-health fields. The wire_contract verdict is
OMITTED until mcp4 computes one. Additive only — a client holding MCP1 shapes stays valid.

AS4 — signals. New package apps/aaw/internal/signals: FAKE-N at agent_register
(registered > spawned); V-SOLO-1 at aaw_status and Z-append with BOTH clauses required (all
non-director rows stale by the three-source rule AND >= K director-attributed entries within
window W); V-SOLO-2 computed, NEVER emitted (the W-1 adjudication: the proposal's R-4 degraded run
is legitimate history). Policy constants W = 45 min, K = 3, cap = 240 min — named constants.
Emission: one line per (scope, code, evidence-window) appended to .claude/audit.log in the form
<RFC3339> aaw <CODE> scope=<scope> <k>=<v>... msg="<evidence>". Codes: FAKE-N, V-SOLO-1,
UNREGISTERED-ATTRIBUTION, CONTAINMENT. No signal blocks a tool call; the only hard process gate
remains tool_x_complete refused while d_count = 0.

AS5 — write order. The attributed write runs ledger-append then registry-counter under the
per-scope lock (the durable audit record leads); document the bounded cross-file drift (a crash
between the two writes skews only the advisory plane), naming the aaw audit tally-recount as the
detector, and document the retry-after-ambiguous-failure duplicate as accepted, visible history.

End on the gates: the exemplar-ledger golden byte-identical with/without actor; the
unregistered-actor advisory test; the Q-4 mtime property; the one-call z_eligible assertion; the
R-4 degraded-run test (no V-SOLO-2 line); the two-clause V-SOLO-1 test; the write-order test;
go build ./... and go test ./... clean; the tool surface counts 18 (17 v1 + agent_heartbeat).
Report the modules changed, the gate results, and confirmation that the tool surface is 18 and
apps/mcp-go was untouched.
```

Spec: mcp2.md · Stories: mcp2.stories.md · Index: mcp.md · Roadmap: ../aaw.mcp.roadmap.md · Approach: ../../../elixir/specs/specs.approach.md
