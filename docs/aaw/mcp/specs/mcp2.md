# MCP2 · attribution, liveness, and the status gate console

> The evidence plane of the aaw MCP server v2: opt-in actor attribution recorded registry-side, a
> three-source liveness fusion that never false-positives a long-authoring peer, `aaw_status` grown
> into the one-call gate console, and the advisory FAKE-N / V-SOLO-1 signal contract — over MCP1's
> hardened store, adding exactly one tool (`agent_heartbeat`).

## Goal

The second rung of the build ladder: make the server's evidence plane honest and one-call-readable.
Every writing tool accepts an optional `actor` whose effect is registry-side only, so attribution
accrues without changing a byte of the ledger grammar; `agent_heartbeat` plus a three-source
liveness fusion produce per-agent verdicts that stay truthful through an hour of heads-down
authoring; `aaw_status` becomes the gate console that answers the Director's x.md §10 pre-commit
check in one call; FAKE-N and the two-clause V-SOLO-1 emit deduplicated advisory lines to
`.claude/audit.log`, while V-SOLO-2 is computed but never emitted. The tool surface grows to
18 (17 v1 tools + `agent_heartbeat`); every addition is additive against MCP1 shapes. Build
formation: **standard tier** — implementor build → one second-context verification pass (a
resumed-implementor harden OR an evaluator verify, not both) → the Director gate + one pathspec
commit (the 2026-06-11 calibration; the tier rule lives in the roadmap's "How the roadmap runs").

## Rationale (5W)

- **Why**   — the PoC could not attribute a ledger write to an agent: pre-rung, `EntryIn` carried
  no identity and only `agent_send` touched a registry row, so the x.md §5 V-SOLO detectors were
  uncomputable and a peer authoring a large design for an hour read as frozen; the Director's
  pre-commit check was hand-derived from greps; FAKE-N landed on the server's own stderr where
  nobody tails it. (Closed as-built: `EntryIn.Actor` at `cmd/aaw/main.go:184`; FAKE-N re-routed to
  the audit log at `main.go:294-303`.)
- **What**  — an optional `actor` parameter on every writing tool with registry-side recording; the
  `agent_heartbeat` tool plus three-source liveness fusion with declared-quiet windows;
  `aaw_status` extended to the gate-console shape with `gates.z_eligible`; the advisory signal
  contract (FAKE-N and two-clause V-SOLO-1 emitted, V-SOLO-2 evidence-only) into
  `.claude/audit.log`; and the ledger-then-registry write order for the attributed write.
- **Who**   — the Director (the one-call pre-commit verdict and trustworthy liveness rows), every
  peer (long authoring without a false stale verdict), the Operator (who tails `.claude/audit.log`
  per x.md §8 and tunes the W/K/cap policy), and the maintainer who needs the signal rules pinned
  by running tests.
- **When**  — the rung after MCP1; it depends on MCP1's per-scope lock, read-through index, and
  registry write discipline, and on nothing later. The config rung later homes the W/K/cap
  constants in `.aaw/config.json`; the CLI rung later ships the `aaw audit` tally-recount this
  rung names as its drift detector.
- **Where** — `apps/aaw/cmd/aaw/main.go` (the writer call sites, `aaw_spawn`, `agent_register`,
  `aaw_status`, the new `agent_heartbeat`), `apps/aaw/internal/store/` (registry fields and the
  liveness fusion), the new `apps/aaw/internal/signals/` package, plus tests. The ledger grammar
  and the locked entry header are untouched.

## Scope

- **In**  — the optional `actor` parameter on every writing tool and the `UNREGISTERED-ATTRIBUTION`
  advisory; `agent_heartbeat(scope, name, note?, quiet_for_minutes?)` with the 240-minute cap and
  lease-at-dispatch; the three-source liveness fusion evaluated at `aaw_status` and Z-append; the
  gate-console `aaw_status` shape; advisory FAKE-N and two-clause V-SOLO-1 emission with the dedup
  rule and line format; V-SOLO-2 computed-never-emitted; the ledger-then-registry write order with
  the accepted retry-duplicate; the policy defaults W=45 / K=3 / cap=240 as named constants.
- **Out** — the `channel_*` family and `tool_x_resonance` (the Q-3-ship rung); `.aaw/config.json`
  and the W-3 gitignore negation (the config rung — until then the policy constants stay named in
  code); the `aaw audit` CLI tally-recount (a later rung — named here as the drift detector only);
  the closed error-code vocabulary and the EBNF grammar formalization (their own rung); V-SOLO-3
  and V-SOLO-4 as sensors (out by design — the harness and Director hold those fences, with the
  registry as post-hoc evidence).

## Deliverables

- **MCP2-D1** — an optional **`actor`** parameter on every writing tool (`agent_heartbeat`
  attributes by its `name` parameter — AD-4); recording is registry-side only — a ledger writer
  touches the agent's `last_seen_at` and advances its per-prefix activity counter, a non-ledger
  writer touches `last_seen_at` alone (it carries no entry prefix) — and the ledger entry
  header stays the locked `### <PREFIX>-<n> — <title>` form (venus-1 §3.13 carries no attribution
  production; the §2.2 adjudication in apollo row 8; venus-2 ADR-7). An unregistered actor name
  appends an `UNREGISTERED-ATTRIBUTION` advisory line and creates no row. As-built: `EntryIn.Actor`
  (`cmd/aaw/main.go:184`), `Scope.AppendAttributed` (`internal/store/ledger.go:125-167`),
  `Scope.TouchActor` (`internal/store/store.go:466-483`) — the pre-rung gap (an identity-less
  `EntryIn`; `agent_send` the only touch) is closed.
- **MCP2-D2** — **`agent_heartbeat(scope, name, note?, quiet_for_minutes?)`** (the D-6(a) name) — a
  zero-ledger-cost touch recording `last_seen_at`, an optional declared-quiet window, and a note;
  **three-source liveness fusion**: effective liveness = the most recent of {an attributed-call
  touch, an unexpired declared-quiet window, the spawn-declared `deliverable` file mtime};
  lease-at-dispatch (the director may heartbeat for a peer it dispatches); `quiet_for_minutes`
  capped at 240. (venus-1 ADR-10 three-source + venus-2 ADR-8 shape; apollo row 7.)
- **MCP2-D3** — **`aaw_status` becomes the one-call gate console**: `tallies` +
  `gates:{z_eligible, d_count, z_count}` (z_eligible = d_count≥1, the x.md §10 pre-commit check) +
  per-agent rows {name, role, ccl_id, last_seen_at, the liveness verdict
  active|quiet-declared|stale + its winning source} + open (unexpired) signals + the archived flag
  + parse-health fields. [RECONCILE] AD-4's `model` identity field LANDED EARLY in the harden pass
  (`Agent.Model` at `internal/store/store.go:48`; optional `model` params on spawn/register,
  applied at `internal/store/store.go:348/:375` — additive, record-only); the `wire_contract` verdict
  stays DEFERRED to mcp4 (`cmd/aaw/main.go:154` omits the field until a rung computes one). (Q-1 = yes; venus-1 ADR-12 +
  venus-2 ADR-10; as-built — `Tallies` at `internal/store/ledger.go:54-67`, the console at
  `cmd/aaw/main.go:344-384`.)
- **MCP2-D4** — **advisory-only signals** to `.claude/audit.log`: FAKE-N (registered > spawned, at
  `agent_register` — kept from the PoC, re-routed from stderr; as-built `main.go:294-303`);
  V-SOLO-1 (two clauses, both required:
  all non-director rows stale by the three-source rule AND ≥K director-attributed entries within
  window W; evaluated at `aaw_status` and at Z-append); V-SOLO-2 is evidence-only — computed but
  never emitted (W-1: venus-2's self-correction overrides venus-1-review's adoption, grounded in
  the proposal's R-4 degraded run at `aaw.mcp.proposal.md:74-79`, where only the Director wrote
  entries); V-SOLO-3/4 out as sensors; codes = FAKE-N, V-SOLO-1, UNREGISTERED-ATTRIBUTION,
  CONTAINMENT; the dedup rule = one line per (scope, code, evidence-window); line format
  `<RFC3339> aaw <CODE> scope=<scope> <k>=<v>… msg="<evidence>"`. (venus-1 ADR-11 + venus-2 ADR-9;
  apollo row 17, W-1.)
- **MCP2-D5** — the attributed write touches two files under the per-scope lock, ordered
  **ledger-append then registry-counter** (the durable audit record leads); the cross-file drift on
  a crash between them is named as bounded and advisory, with the `aaw audit` tally-recount (a
  later rung's CLI) named as its detector; the retry-after-ambiguous-failure duplicate entry is
  documented as accepted — visible, inspectable history. (apollo §4.3-2/3.)
- **Policy defaults** (Operator-tunable, D-6): W = 45 min (the V-SOLO-1 silence window), K = 3
  (the director-activity threshold), cap = 240 min — named constants, homed in `.aaw/config.json`
  once the config rung lands.

## Invariants

- **MCP2-INV1** — **attribution is opt-in and registry-side.** A writer with no `actor` proceeds
  unattributed; with `actor` it touches only registry liveness and counters, never the ledger
  header — so the §3.13 grammar and the hand-written exemplars are byte-unaffected.
- **MCP2-INV2** — **liveness never false-positives a long-authoring peer.** An agent advancing its
  declared `deliverable` mtime, or inside a declared-quiet window, reads active or quiet-declared
  (not stale) with zero tool calls (the Q-4 property).
- **MCP2-INV3** — **all formation signals are advisory.** No signal blocks a tool call; the only
  hard process gate remains `tool_x_complete` refused while d_count = 0 (the LAW-4 trigger,
  unchanged).
- **MCP2-INV4** — **V-SOLO-1 requires both clauses.** A quiet whole team (everyone between stages,
  no director growth) never signals; the signal fires only when all non-director rows are stale AND
  ≥K director-attributed entries landed within W.
- **MCP2-INV5** — **one-call pre-commit.** `aaw_status.gates.z_eligible` is the x.md §10
  precondition (a Z exists and ≥1 D is locked), answered without greps.

## Definition of Done

- [ ] every writing tool accepts an optional `actor`; a registered name advances `last_seen_at` and
      the per-prefix counter registry-side (ledger writers — a non-ledger writer advances
      `last_seen_at` alone); the appended entry header is byte-identical with and
      without `actor`; an unregistered name appends `UNREGISTERED-ATTRIBUTION` and creates no row
      (MCP2-D1).
- [ ] `agent_heartbeat` ships as the 18th tool; the three-source fusion returns
      active|quiet-declared|stale with the winning source per row; `quiet_for_minutes` is capped at
      240; the spawn-declared `deliverable` is recorded (MCP2-D2).
- [ ] `aaw_status` returns the gate-console shape; `gates.z_eligible` is true exactly when
      d_count ≥ 1 (MCP2-D3).
- [ ] FAKE-N and two-clause V-SOLO-1 emit deduplicated lines in the fixed format to
      `.claude/audit.log`; V-SOLO-2 is computed and never emitted — the R-4 degraded run produces
      no line (MCP2-D4).
- [ ] the attributed write is ledger-append then registry-counter under the per-scope lock; the
      bounded drift and the accepted retry-duplicate are documented with `aaw audit` named as the
      detector (MCP2-D5).
- [ ] MCP2-INV1–INV5 are pinned by running tests: the exemplar-ledger byte-identity golden (INV1);
      the Q-4 mtime property (INV2); a no-signal-blocks test (INV3); the two-clause and
      degraded-run cases (INV4); the one-call `z_eligible` assertion (INV5).
- [ ] the tool surface is 18 (17 v1 + `agent_heartbeat`); a deferred-schema client holding MCP1
      shapes stays valid — every field is additive; `aaw selftest` is green and the live scopes
      still parse and append — demoable.

Stories: ./mcp2.stories.md · Agent brief: ./mcp2.llms.md · Index: ./mcp.md · Roadmap: ../aaw.mcp.roadmap.md · Approach: ../../../elixir/specs/specs.approach.md
