# aaw MCP server v2 — delivery roadmap

> The delivery plan for the v2 server: how the approved design
> ([aaw.mcp.design.md](aaw.mcp.design.md)) ships as a **thin-rung build ladder** over the as-built
> PoC (`apps/aaw`, `2.0.0-min`) — under the Operator's key principle, **Pragmatic Agile
> Delivery**: rung 1 is the smallest shippable increment over the PoC, every subsequent rung a
> thin vertical slice built to production quality, the server runnable and dialable after each.
> This file plans; the design defines; the rung triads (under `docs/aaw/mcp/specs/`, derived from
> the design per [specs.approach.md](../../elixir/specs/specs.approach.md)) prove. Status:
> **canon (D-11)** — mcp1 shipped (`7972859f`, settled tier), mcp2 shipped (`f44f0539` ·
> `514d4768`), mcp3 shipped (`750bda97`, standard tier — close P-9); mcp4 build-grade (D-18);
> mcp5 specced (the Reconcile tool per ledger D-14; the displaced transport posture + C-1 probe
> ride mcp8); mcp6 specced (interactive aaw — the Bubble Tea console; the displaced message
> channels ride mcp7; mcp6 stays the measurement rung — D-17); mcp7–mcp8 planned. The chapter
> index is [specs/mcp.md](specs/mcp.md).

## What this chapter delivers

The fully-fledged aaw MCP server: the file-backed process engine for the AAW framework — the
single-file scope ledger factory, the team registry with three-source liveness, the machine
gates, the formation signals, message channels, deterministic resonance, the `aaw audit`
integrity CLI, and the 22-tool surface — replacing the PoC on the locked wire contract
(`localhost:8905`) with zero loss and the 17 v1 tool names preserved.

## Where this starts and ends

- **Start.** The PoC serves the live formation today: 17 tools, working ledger factory, known
  defects on record (the unlocked registry read-modify-write, the read-once index, the
  partial-bind family split, the frozen-liveness false positive — design §1). The approved
  design is the contract; the build specs derive from it.
- **End.** The v2 server live on `localhost:8905`, every design AD realized, the four-tier
  conformance suite green, the 22-tool selftest pinned, the live formation re-registered against
  it, and the runbooks carrying the one documented upgrade note (none of the v1 names or shapes
  break — additive evolution throughout).

## The architecture decision — and its reversible seam

**Stateless transport over a file-backed engine** (design AD-1): every request self-contained,
durability entirely in files, restart invisible. The reversible seam is the **C-1 probe**: at
the transport rung's gate, one live harness-dial probe (real `.mcp.json` client + deferred
`ToolSearch` schema load + one tool round-trip) settles the mode; probe failure flips the
configuration to stateful sessions — a one-option change, not a redesign, because zero-loss
lives in the file plane either way. The second seam is **D-5**: `apps/mcp-go` is first-party
and modifiable, so where stock SDK behavior and an aaw requirement collide, the rung may modify
the fork — as a designed, ADR-recorded change whose diff boundary names `apps/mcp-go`.

## The master invariant (restated for this chapter)

> Files are truth; no loss by construction. Every rung leaves every durable fact in a plain
> file, every write atomic (whole-or-old), history append-only, and the server rebuildable from
> the tree at any instant. No rung introduces server state that cannot be re-derived by
> re-reading the files, and no rung breaks a v1 tool name or shape (additive-only evolution).

## How the roadmap runs — the Author/Operator loop

Each rung runs the six-stage loop (sharpen → build → ship → demo → review → feedback → adapt):
the Author derives the rung's spec triad from the design, the build formation is **sized to the
rung** (the 2026-06-11 Operator calibration — ceremony scales with risk, never the reverse), the
Operator reviews the demo and returns feedback, and feedback edits the spec — the design stays
the single source of truth, amended only through the Operator. The three tiers:

- **Settled** (settled design, verified `file:line` grounding, no open fork, diff inside one
  package): one implementor pass carrying the rung's full gate → the Director's independent
  gate re-run → one LAW-4 pathspec commit. No separate harden or verifier spawn — the gate run
  by two contexts IS the verification. **mcp1 is this tier** (first run at full pipeline;
  recalibrated mid-rung — aaw-mcp ledger D-10).
- **Standard** (a new package, a new tool, or a new contract surface): implementor build → one
  second context (a resumed-implementor harden OR an evaluator verify — not both) → Director
  gate → the commit. **mcp2 is this tier.**
- **Full** (an open Operator fork; auth/data/deploy risk; or the deliverable IS a system spec):
  the complete lead-team pipeline (steward reconcile + brief → build → harden → verifier
  verdict → ratify + commit), or the x.md §12 Design Phase formation.

The live formation keeps running against the server throughout: each rung's cutover is a
restart, which the master invariant makes loss-free.

## Thin but robust (the production bar)

A rung ships production quality, not a prototype: every refusal a named code from the closed
vocabulary; every write atomic under the per-scope lock; every behavior pinned by a tier-1/2
test and exercised by the selftest; the diff inside the rung's named boundary; the boundary
grep empty at hardening; the conformance suite green at close. Near-term rungs ship first;
nothing below ships ahead of its dependencies.

## The value measurement — framework productivity, proven at mcp6

The roadmap optimizes one quantity: **aaw framework productivity** — how much of a formation's
coordination the server carries instead of the Director's hands. Every rung before mcp6 is an
**upfront rung**: an instrument built ahead of the point where its value is exercised. The floor
(mcp1–mcp2) and the contract (mcp3–mcp5) are investments — each passes its own gate at close, but
a gate proves correctness, not value. Value gets a measurement, and the measurement is **the
coordination of authoring mcp6 itself** (Operator directive, 2026-06-11).

mcp6 is the measurement rung by construction: the first rung whose whole formation — sharpen →
build → ship → close — runs coordinated end-to-end by the v2 server the upfront rungs built, and
whose own subject — the interactive console that renders the formation live from the file plane —
makes that coordination visible on screen as the tally counts it. Each upfront instrument carries
one named stage of the mcp6 authoring, and each stage has a countable outcome:

| Upfront instrument | The mcp6-authoring stage it carries | Counted at the mcp6 close |
| --- | --- | --- |
| mcp5 — `aaw reconcile` | the pre-build sharpen: the mcp6 triad probed against HEAD | drift caught by exit code vs by hand-grep |
| mcp1 — store discipline | every ceremony recorded through `aaw_spawn` / `tool_x_*` | server-recorded entries vs hand-written |
| mcp2 — liveness + console | the build watched live; the close gated on one `gates.z_eligible` read | false-silent verdicts on authoring peers (target 0) |
| mcp3 — error vocabulary | every refusal during the run diagnosed by its named code | undiagnosed free-text failures (target 0) |
| mcp4 — honest boot + wire | every agent session dials the committed `.mcp.json` and lands | misdialed or wire-drifted sessions (target 0) |

The tally is recorded in the mcp6 rung-close entry, with one inverse metric above the rest:
**manual out-of-band interventions** — every step the Operator or the Director performed by hand
that an instrument should have carried. Each intervention is a named finding with a disposition:
a deliverable for mcp7/mcp8, a future-rung candidate, or a documented non-goal. The measurement
feeds the ladder; productivity is counted at mcp6, never asserted by the upfront rungs themselves.

## The ladder at a glance

| Rung | Theme | Tool count after | Milestone |
| --- | --- | --- | --- |
| **mcp1** | The single-writer store discipline — the correctness foundation | 17 | M1 · The floor |
| **mcp2** | Attribution, liveness, and the status gate console — the observability layer | 18 | M1 · The floor |
| **mcp3** | The error vocabulary + the ledger-grammar formalization | 18 | M2 · The contract |
| **mcp4** | Config, ports & the wire contract | 18 | M2 · The contract |
| **mcp5** | The Reconcile tool — deterministic spec↔tree drift, the `aaw reconcile` CLI | 18 | M2 · The contract |
| **mcp6** | Interactive aaw — the Bubble Tea console (`aaw tui`, read-only) | 18 | M3 · The 22-tool surface |
| **mcp7** | Message channels, resonance, archival, the `aaw audit` CLI | 22 | M3 · The 22-tool surface |
| **mcp8** | The transport posture, conformance closure + live cutover | 22 | M4 · The proof |

Dependency arc: mcp1 is the substrate every later rung writes through (its committed goldens
are the regression floor every rung runs against); mcp2 stands on mcp1's locks (attributed
counters mutate registry state safely) and fixes the write order whose recount detector mcp7
ships; mcp3 hardens the contract surfaces (codes, grammar) the evidence rungs report through;
mcp4 fixes the boot surface whose C-1 probe rides mcp8's cutover; mcp5's reconcile instrument
guards every later rung's pre-build sharpen (in code it depends only on the tree); mcp6 renders
the file plane mcp1's discipline keeps whole (read-only, lock-free — a torn read is impossible);
mcp7 absorbs the message channels (polling touches liveness — mcp2) and completes the 22-tool
surface; mcp8 settles the transport posture and proves all of it at cutover.

## Milestones

| Milestone | Rungs | What the Operator can verify at the end |
| --- | --- | --- |
| **M1 · The floor** | mcp1–mcp2 | nothing recorded can be lost, and the evidence engine reads true: concurrent ceremonies are safe, a kill at any instant leaves whole files, a second instance is refused, an out-of-band index edit is honored, the locked grammar is pinned by committed goldens; attributed liveness with no Q-4 false positive, and the Director's pre-commit check is one `gates.z_eligible` read |
| **M2 · The contract** | mcp3–mcp5 | every refusal is a named code; the grammar is formal and reserved; the boot is honest: all-or-nothing bind, diagnosed `PORT_BUSY`, `.mcp.json` agreement validated strict-by-default, policy in the committed `.aaw/config.json`; spec↔tree drift is a one-command deterministic verdict (`aaw reconcile`, gate-able exit codes) |
| **M3 · The 22-tool surface** | mcp6–mcp7 | the formation watched live in the read-only console (`aaw tui` — the whole formation on one screen, re-derived from the file plane on every tick); durable replayable coordination, deterministic resonance with the baseline caveat, lazy archival, and the corpus integrity CLI — the full 22-tool catalog live at mcp7; **and the measurement lands**: the mcp6 authoring runs fully server-coordinated, its close entry carrying the productivity tally that proves (or prices) the upfront rungs |
| **M4 · The proof** | mcp8 | the four-tier suite green, the 22-tool selftest pinned over a hermetic workspace, the transport posture settled by the C-1 probe at cutover, the live formation re-registered on the v2 server |

## The thin-rung build ladder

Every rung below is one iteration row — **Ships · Demo · Harness · Feedback asked** — plus its
**diff boundary** (the pathspec of the rung's one LAW-4 commit; it extends to `apps/mcp-go`
only where named, per D-5). mcp6 additionally carries a **Measurement** row — it is the ladder's
productivity gauge ("The value measurement", above). Rungs `mcp1` and `mcp2` are fixed by the Director (their triads are
authored first, under `docs/aaw/mcp/specs/`); the sequencing of mcp3–mcp8 is this roadmap's.

### mcp1 — The single-writer store discipline

The correctness foundation: the smallest shippable increment over the live PoC, no new tool.

- **Ships:** the per-scope serialization domain over ledger + registry + messages — closing the
  unlocked registry read-modify-write (apollo row 2); the persisted `next_ccl` mint + identity
  continuity on re-spawn (row 19); atomic temp + fsync + rename for every whole-file write with
  the `O_APPEND` carve-out for line-logs (row 3); the pure read-through index — the L-2 fix
  (row 1); the boot flock single-instance guard (row 20).
- **Demo:** two concurrent `aaw_spawn` storms mint distinct sequential CCL-ids; `kill -9`
  mid-append leaves a whole file; a second instance on the same workspace is refused; an index
  row deleted on disk stays deleted.
- **Harness:** tiers 1–2 built this rung — unit/property over the ledger engine (numbering,
  title-lift, splice, the preservation invariant, the Z-gate).
- **Feedback asked:** do the goldens encode the locked grammar exactly as the Operator reads
  the exemplars; is refuse-on-second-instance the right strictness for the dev workflow?
- **Diff boundary:** `apps/aaw/internal/store/**` (+ `testdata/`), `apps/aaw/cmd/aaw/main.go`,
  tests. **No `apps/mcp-go`.**

### mcp2 — Attribution, liveness, and the status gate console

The observability layer; depends on mcp1; +1 tool (`agent_heartbeat`, 18).

- **Ships:** the `actor` parameter on every writing tool, recorded registry-side only — entry
  headers stay the locked form (row 8); `agent_heartbeat` + the three-source liveness fusion
  with the `liveness_source` winning-source verdict (row 7; the D-6(a) name); `aaw_status` as
  the one-call gate console — tallies, `gates.z_eligible`, liveness verdicts, parse-health,
  signals (row 27, Q-1 = yes); the advisory signal emitter to `.claude/audit.log` with dedup —
  `FAKE-N` + two-clause `V-SOLO-1` + `UNREGISTERED-ATTRIBUTION` + `CONTAINMENT`, with V-SOLO-2
  **evidence-only** (row 17 / W-1); the fixed attributed-write order — ledger append, then
  registry counter — with the `aaw audit` tally recount named as its drift detector (§4.3-2;
  mcp7 ships the recount).
- **Demo:** a peer declares a 90-minute quiet window, authors silently, and reads `quiet` — not
  `silent` — in status (the Q-4 scenario re-run on purpose); the Director's pre-commit check is
  one `gates.z_eligible` read.
- **Harness:** liveness-rule table tests over synthetic registries; signal dedup tests;
  attribution round-trips; mcp1 goldens green.
- **Feedback asked:** do the liveness verdicts match the live formation's reality across one
  real rung; are the policy defaults (W=45 / K=3 / cap=240) right?
- **Diff boundary:** `apps/aaw/internal/store/**`, `apps/aaw/internal/gates/` +
  `apps/aaw/internal/audit/` (new), `apps/aaw/cmd/aaw/main.go`, tests. No `apps/mcp-go`.

### mcp3 — The error vocabulary + the ledger-grammar formalization

- **Ships:** the closed `aaw: <CODE>: <detail>` vocabulary (design §9) on every domain refusal;
  the boundary gates re-expressed on it (slug, parent-exists, recipient-registered, init
  idempotency, `LEDGER_DIR_*`, containment); `created` kept by alias + `ledger_created` added;
  the §8 EBNF as the implemented single authority — lenient parse (`#`/`##` sections, `##`/`###`
  entries), strict emit, reserved prefix vocabulary, unknown-prefix reporting in status; the
  selftest upgraded to exact-code assertions.
- **Demo:** each refusal class triggered once from a hand client — the code, not substring
  luck, is what the assertion matches; a hand-written `### ADR-3` heading tolerated and
  reported, never gating.
- **Harness:** tier-3 in-process round-trips begin — every gate refused at least once with its
  exact code; goldens green.
- **Feedback asked:** does any runbook or charter branch on a v1 free-text error that needs a
  documented mapping note?
- **Diff boundary:** `apps/aaw/cmd/aaw/main.go`, `apps/aaw/internal/gates/`,
  `apps/aaw/internal/store/**`, selftest code.

### mcp4 — Config, ports & the wire contract

- **Ships:** identity flags (`-addr`, `-workspace`, `-log-level`, `-stdio`, `-wire-check`) +
  the `.aaw/config.json` policy file read-through — no env layer, no per-knob overrides
  (D-6(c)); all-or-nothing dual-stack bind + diagnosed `PORT_BUSY` (capped ~500 ms holder
  probe, refusal-path only); the three-state `-wire-check` with `strict` default + the
  `unparseable` verdict; the boot banner + `probe.effective_config` with winning sources;
  **the W-3 `.gitignore` conversion** (`.aaw/` → `.aaw/*` + `!.aaw/config.json`) and the
  committed policy file; **the F-2 doc edit** (`.claude/commands/x.md:123` bootstrap signature
  gains `ledger_dir`) — Operator-fenced, lands only under the standing grant.
- **Demo:** boot against the committed `.mcp.json` → banner reports `wire_contract: agree`; a
  deliberately mis-flagged port refuses with the printed two-direction fix; a policy edit
  applies on the next call with no restart.
- **Harness:** bind/wire/config unit tests; tier-3 grows; goldens green.
- **Feedback asked:** is `strict` the right wire-check default for the dev loop, or does any
  legitimate workflow need `warn` documented as its standing mode?
- **Diff boundary:** `apps/aaw/cmd/aaw/main.go`, `apps/aaw/internal/config/` (new),
  `.gitignore` (the two W-3 lines), `.claude/commands/x.md` (the one F-2 line, under grant),
  tests.

### mcp5 — The Reconcile tool

Promoted by Operator directive (ledger D-14), displacing the transport rung to mcp8.

- **Ships:** the `aaw reconcile` CLI subcommand (the design-§10 `aaw audit` zero-MCP-tool
  pattern; the D-3 tool-fatigue precedent — no new MCP tool, the catalog untouched): the
  documented claim grammar (`file:line` cite tokens, relative markdown links, backticked
  workspace paths) + the read-only tree prober + the MATCH / STALE / MISSING classifier; the
  per-file delta table with tallies and the embedded limit line (MATCH = existence + line-range
  only — semantic agreement stays the reconciling agent's); `-json`; gate-able exit codes
  (0 no drift / 1 drift / 2 usage or containment); flags-first invocation (L-5); workspace
  containment on every input and probe target.
- **Demo:** `aaw -workspace . reconcile docs/aaw/mcp/specs/mcp3.md` over the live triad — the
  delta table or the clean verdict; a doctored fixture classifying one STALE cite and one
  MISSING path.
- **Harness:** extractor table tests; classifier goldens over committed fixtures; the
  byte-determinism case (two runs compare equal); a no-write-API grep over the package;
  `go test -race`; the selftest still green at 18 tools.
- **Feedback asked:** is the claim grammar complete for the live spec corpus (any cite form the
  extractor misses); does the CLI close the reconcile need, or should a `mcp__aaw__` tool form
  be promoted later (an Operator decision — surfaced, not taken)?
- **Diff boundary:** `apps/aaw/internal/reconcile/` (new), `apps/aaw/cmd/aaw/main.go` (the mode
  word + usage), tests. **No `apps/mcp-go`**; no MCP tool registration.

### mcp6 — Interactive aaw, the Bubble Tea console

Promoted by Operator directive (2026-06-11, the mcp5/D-14 precedent), displacing message channels
to mcp7. The third application of the §10 zero-MCP-tool CLI pattern; the master invariant is the
enabling fact — files are truth and the server is rebuildable from the tree at any instant, so a
read-only console that re-reads the file plane renders the whole formation live without touching
the server.

- **Ships:** `aaw tui` — the interactive READ-ONLY terminal console on charmbracelet Bubble Tea
  (the Elm-architecture `tea.Model`: `Init() tea.Cmd` · `Update(tea.Msg) (tea.Model, tea.Cmd)` ·
  `View() string`, run by `tea.NewProgram`; `bubbles` table + viewport; `lipgloss` styling — the
  charm trio is the ladder's FIRST third-party UI dependency, a named seam, versions pinned at
  build): the scope list (from `.aaw/scopes.json`) and the scope detail — the liveness table
  (agent · role · CCL-id · model · verdict · quiet), the gates panel (`z_eligible` + the D/Z
  counts behind it), the live-follow ledger tail, and the parse-health line (unknown prefixes);
  `tea.Tick` mtime-guarded re-read of the file plane (no fsnotify); reads take no lock and never
  block a writer (mcp1's atomic whole-file writes make a torn read impossible); the `tui` mode
  word flags-first (L-5), a non-TTY stdout refusing with usage (exit 2). Tool surface stays 18.
- **Demo:** the live formation watched in the console — a ceremony lands out-of-band and appears
  on the next tick; timing allowing, the mcp6-authoring formation itself watched live.
- **Harness:** table-driven `Update` tests (the model update is pure); width-pinned `View`
  goldens over committed fixture trees; the read-model determinism case; `go test -race`; the
  selftest still green at 18 tools.
- **Measurement:** preserved, and now rendered — the rung's own authoring formation runs fully
  server-coordinated on the upfront instruments (the pre-build sharpen via `aaw reconcile` over
  the mcp6 triad, every ceremony through `aaw_spawn` / `tool_x_*`, liveness watched and the close
  gated on `gates.z_eligible`, every refusal a named code, every session dialing the committed
  `.mcp.json`), the console RENDERS that coordination as it happens, and the rung-close entry
  records the productivity tally: the per-instrument counts plus the manual out-of-band
  interventions, each intervention a named finding with a disposition (mcp7/mcp8 deliverable ·
  future-rung candidate · documented non-goal).
- **Feedback asked:** are the two views the right thin set — what does the Operator reach for
  next; should the TUI later gain a write face (keystroke → tool call — an Operator decision,
  surfaced not taken)? And the tally read: does the measured coordination justify the upfront
  rungs — which manual intervention should the next rung retire first?
- **Diff boundary:** `apps/aaw/internal/tui/` (new), `apps/aaw/cmd/aaw/main.go` (the mode word +
  usage), `apps/aaw/go.mod` + `go.sum` (the charm trio), tests. **No `apps/mcp-go`**; no MCP tool
  registration.

### mcp7 — Message channels, resonance, archival & the `aaw audit` CLI

Absorbs the message channels mcp6's promotion displaced (the D-14 precedent applied again): the
18 → 22 tool jump lands in this one rung — a weight the Operator may split when the rung
approaches; its triad is unauthored, so the decision can wait.

- **Ships:** the `<scope>.messages.jsonl` split (registry `messages` arrays migrate on first
  write); `channel_publish` / `channel_poll` / `channel_list` (21 tools); `agent_send` re-homed
  to the log with seq; seq cursors stable forever; `channel_poll(actor)` touching liveness; the
  message-channel/channel-section terminology fence in every schema description. Plus
  `tool_x_resonance` (22 tools — the surface complete): k=5 shingle Jaccard +
  citation-set Jaccard, `baseline_note` + the standing inflation caveat embedded in every R-n
  entry, the optional `score` judgment slot; lazy TTL archival (`ARCHIVED` refusals, re-open +
  `reopened_at`); the `aaw audit` subcommand — the L-2 regression check, the corpus lint, and
  **the §4.3-2 tally recount** (closing the drift-detector loop opened at mcp2) — emitting
  `INTEGRITY` lines.
- **Demo:** a publish → drop the client → reconnect → `channel_poll(after_seq: 0)` replays the
  full history; `agent_send` and topic traffic interleave in one greppable log; resonance over
  the retired dual-Venus corpus (`venus-1.md` / `venus-2.md`, restored
  for the demo via `git show 9d145486:docs/aaw/mcp/design/<file>`) — the known shared-brief pair
  — with the baseline caveat visible in the emitted entry; `aaw audit` over the live workspace
  reporting the legacy out-of-tree rows.
- **Harness:** cursor + migration unit tests; tier-3 publish/poll round-trips; resonance
  determinism tests (same files → same table); archival clock tests;
  audit lint over deliberately-broken fixture corpora; goldens green.
- **Feedback asked:** is pull-cadence coordination sufficient beside the harness's
  `SendMessage`, or does any formation need a faster path documented; are the resonance numbers
  readable and actionable on the real corpus — anything the entry body should additionally
  carry?
- **Diff boundary:** `apps/aaw/internal/channels/` (new), `apps/aaw/internal/integrity/` (new),
  `apps/aaw/internal/store/**` (migration), `apps/aaw/cmd/aaw/main.go`, tests.

### mcp8 — The transport posture, conformance closure + live cutover

Absorbs the transport rung mcp5's promotion displaced (the D-14 resolution): the C-1 probe's
restart-invisibility content IS the cutover demo, so the posture settles where the cutover runs.

- **Ships:** **the stateless transport posture** (Stateless + JSONResponse + no session id,
  design AD-1) **with the C-1 probe as a rung gate** — one live harness dial: real `.mcp.json`
  client, deferred `ToolSearch` schema load, one tool round-trip, a mid-session server restart,
  and a post-restart call; probe failure flips the configuration to stateful sessions, recorded
  as the rung's decision either way (both zero-loss); the probe runs uncontended (a
  load-sensitive gate runs alone). Plus the complete four-tier suite: tier-3 coverage of every
  tool and every refusal; the `aaw selftest` 22-tool count pin + exact-code assertions over a
  hermetic temp workspace; the golden `tools/list` schema snapshot (the additive-only tripwire);
  the live cutover — the v2 binary replaces the PoC on `localhost:8905`, the live formation
  re-registers, and the in-flight scope ledgers continue their numbering (the design §8 gate,
  proven on production files); runbook/doc sync for the one upgrade note.
- **Demo:** the probe transcript — the restart invisible to the dialing client; selftest green
  over real HTTP against the live server; `aaw_status` on a live scope showing continued
  tallies; `probe` reporting `wire_contract: agree`.
- **Harness:** the C-1 probe; all four tiers; the verifier's mutation pass over the suite itself
  (kill-rate reported, survivors triaged — the anti-rubber-stamp charter).
- **Feedback asked:** the probe verdict — ratify stateless, or accept the stateful flip; go/no-go
  on retiring the PoC binary; anything observed in the first live week that should fold back
  into the design.
- **Diff boundary:** `apps/aaw/**` (suite + selftest + the posture configuration); **extends to
  `apps/mcp-go/**` only if the probe or conformance exposes an SDK defect** (designed +
  ADR-recorded per D-5); runbook docs under the Operator grant.

## Seams & open decisions

- **C-1 — the transport probe** (mcp8, displaced from mcp5 by the D-14 Reconcile-tool
  promotion): stateless is the intent; the probe is the decider; a flip to stateful is a
  configuration change recorded in the rung's spec, not a redesign. Only an Operator rejection
  of probe-as-decider re-opens the fork.
- **D-5 — the SDK seam:** stock configuration first; modification the sanctioned fallback,
  always designed + ADR-recorded, the rung's diff boundary extended explicitly.
- **The auth seam:** tokenless v2 is ratified (Operator D-4); `auth.RequireBearerToken` in
  `apps/mcp-go` is the named upgrade path for any future non-loopback or multi-user posture —
  a new design, not a knob.
- **F-2 — the protocol-doc edit** (`.claude/commands/x.md:123`): Operator-fenced; rides mcp4's
  pathspec under the standing grant; must not survive the build unfixed in either direction.
- **Package layout:** the design's end-state layout (§ AD-12) materializes seam-by-seam — mcp1
  and mcp2 stay within `internal/store` plus the new gates/audit homes; the index/registry/
  ledger split lands with the rung that opens each seam; no standalone refactor rung exists by
  design.
- **Policy constants** (W=45 / K=3 / cap=240): Operator-tunable in the committed
  `.aaw/config.json`; a value change is policy, never a rung.
- **Retry duplicates** (D-6 / §4.3-3): accepted, documented; if live operation shows them
  recurring beyond nuisance level, an optional client idempotency token is the named additive
  follow-up — a future rung, not this ladder.
- **Triad naming (RESOLVED — Operator, 2026-06-11):** the build specs live under
  `docs/aaw/mcp/specs/` with the rung slugs `mcp1`…`mcp8`. The chapter carries a **root index**
  `specs/mcp.md` (the `docs/echomq/specs/emq/emq.md` pattern), and each rung is the full
  [specs.approach.md](../../elixir/specs/specs.approach.md) triad — `mcpN.md` + `mcpN.stories.md`
  + `mcpN.llms.md` (plus an optional `mcpN.prompt.md` runbook). The earlier fused `mcpN.specs.md`
  form is retired; the shipped mcp1/mcp2 files are re-homed verbatim under the law.

## Conventions

- **The master invariant** (above) holds at every rung; the design §8 ledger grammar is the
  single authority for "well-formed ledger".
- **Grounding:** every cited surface verified in the tree; future surfaces written
  forward-looking ("mcpN builds …"), never asserted present; the closed error vocabulary used
  verbatim, codes append-only.
- **Commit rules:** one LAW-4 pathspec commit per rung, made by the Director at close; never
  `git add -A`; the diff inside the rung's named boundary.
- **Gates:** the spec files pass the [specs.approach.md](../../elixir/specs/specs.approach.md)
  six (voice · structure · traceability · fences · links · format); the build passes the
  four-tier conformance suite; a check counts only if it runs.
- **Voice:** plain, specific, impersonal; no banned tokens, no first person, no exclamation, no
  perceptual or interior-state verb on software or agents — propagated into every derived spec,
  story, and brief (LAW-3.1).

## Map

- The design this plan ships: [aaw.mcp.design.md](aaw.mcp.design.md).
- The requirements source: `aaw.mcp.proposal.md` — retired from the tree post-canon (the
  pragmatic-delivery cleanup); it remains the requirements record via git history
  (`git show 74d8a899:docs/aaw/mcp/aaw.mcp.proposal.md`).
- The run ledger (binding decisions): [aaw.mcp.progress.md](aaw.mcp.progress.md).
- The implementation dashboard (per-rung stage + the ladder rollup): [specs/mcp.progress.md](specs/mcp.progress.md).
- The normative framework: [aaw.framework.md](../aaw.framework.md) ·
  [aaw.rules.md](../aaw.rules.md).
- The donor designs and the evaluation: retired from the tree at `f44f0539` (pragmatic-delivery
  cleanup); they remain the decision record via git history —
  `git show 9d145486:docs/aaw/mcp/design/venus-1.md` (likewise `venus-2.md`,
  `apollo.evaluation.md`, and the two cross-reviews).

---

*Venus-3 · `ccl-aaw-mcp-5` · stage D4 · the roadmap plans, the design defines, the triads will
prove. Framing per LAW-3.1, propagated to every derived artifact.*
