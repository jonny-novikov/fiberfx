# aaw MCP server — the as-built design (reverse, code→spec)

> The reverse (code→spec) design of record for the **aaw** Go MCP server as it ships today —
> module `github.com/jonny-novikov/aaw`, version **`2.0.0-min`**, source root
> [`go/aaw/`](../../../go/aaw/). This document is **derived from the running code**, not a contract
> the code implements: where a stated fact and the tree disagree, the tree wins and this document is
> corrected (the reverse-mode canonicality rule, [`aaw.reverse.md`](../../aaw/aaw.reverse.md)). Every
> surface below is re-verified at its `file:line` before it is written; nothing is invented; a
> genuinely unbuilt surface is named forward-tense and pointed at the forward authority.
>
> **One authority per fact.** The **forward v2 design of record** for this server already exists at
> [`docs/aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md) — the 22-tool target surface,
> the `mcp1`–`mcp8` build ladder, the 14 architecture decisions (AD-1…AD-12). **That document is the
> forward authority; this one is the as-built reconcile.** This file never restates the forward
> design — it records what `2.0.0-min` actually serves (an 18-tool surface) and links the forward
> doc for the design rationale and the path to 22. The forward triads stay untouched.

Canon: the forward design [`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md) ·
the forward ladder [`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md) ·
the framework the server enforces [`../../aaw/aaw.framework.md`](../../aaw/aaw.framework.md) ·
the reverse playbook [`../../aaw/aaw.reverse.md`](../../aaw/aaw.reverse.md) ·
the voice + delta rules [`../../aaw/aaw.rules.md`](../../aaw/aaw.rules.md) ·
the shared Go-server operating manual [`../program/go.program.md`](../program/go.program.md) ·
the build guide [`go/CLAUDE.md`](../../../go/CLAUDE.md). As-built source: [`go/aaw/`](../../../go/aaw/).

---

## S-1 · Purpose & scope

The aaw server is **the machine for the AAW framework**
([`aaw.framework.md`](../../aaw/aaw.framework.md)): an enforcer and recorder of process, never an
actor in the work. It runs no agents, edits no specs or code, and makes no commits. It serves a
team/scope registry, a per-scope single-file audit ledger, and the process gates behind the x-mode
lead-team protocol, over MCP (the Model Context Protocol) on a streamable-HTTP wire.

As built (`cmd/aaw/main.go:1-9`, the package doc), the server is `2.0.0-min`
(`cmd/aaw/main.go:34`) and registers itself to the SDK as `Implementation{Name: "aaw", Version:
version}` (`cmd/aaw/main.go:366`). The wire contract per `.mcp.json` is streamable HTTP at
`localhost:8905`.

**In scope (this document):** the as-built 18-tool surface, the workspace scope/agent/message
registry (`internal/store`), the per-scope ledger and its LAW-4 `Z`-gate, the boot/config plane
(`internal/config`), the closed gate vocabulary + the PATH_ESCAPE predicate (`internal/gates`), the
advisory formation-signal contract (`internal/signals`), and the wire/flock boot contract.

**Out of scope (pointers — do not work them from here):** the forward v2 design rationale (the ADRs,
the steelmen, the donor record) → [`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md);
the path from 18 → 22 tools (message channels, resonance, the `aaw audit` / `aaw reconcile` / `aaw
tui` CLI faces) → the `mcp5`–`mcp8` rows of
[`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md); the vendored SDK fork
(`go/mcp-go`, module `github.com/fiberfx/mcp-go/v2`).

## S-2 · The as-built / forward reconcile (the one delta that matters)

The forward roadmap narrates a **start state** — a PoC at 17 tools with named defects (an unlocked
registry read-modify-write, a read-once index, a partial-bind family split, a frozen-liveness false
positive) — and a **target** of 22 tools across eight rungs
([`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md), "The ladder at a glance").
The tree at `2.0.0-min` sits **between** that start and that target, and ahead of the narrated
"PoC":

| Surface | Forward "PoC start" | This as-built tree (`2.0.0-min`) | Where it lands forward |
| --- | --- | --- | --- |
| Tool count | 17 | **18** (`agent_heartbeat` present; `selftest` pins 18 — `cmd/aaw/main.go:778`) | mcp2 adds `agent_heartbeat` (18); mcp7 reaches 22 |
| Registry mutation | unlocked read-modify-write | **per-scope serialized**, atomic temp+fsync+rename (`internal/store/store.go` doc; `atomic.go`) | mcp1 |
| Workspace index | read-once | **pure read-through** every access (`internal/store/store.go` doc) | mcp1 |
| Loopback bind | continue-on-one-family | **all-or-nothing dual-stack**, diagnosed `PORT_BUSY` (`cmd/aaw/main.go:595-608`, `:716-718`) | mcp4 |
| Boot/config plane | absent | **present** — five identity flags + `.aaw/config.json` read-through + `-wire-check` (`internal/config/config.go`) | mcp4 |
| Error vocabulary | free-text | **closed 16-code set**, `aaw: <CODE>: <detail>` (`internal/gates/gates.go`) | mcp3 |

The as-built tree therefore realizes the forward `mcp1`–`mcp4` band (the implementation dashboard
records mcp1–mcp3 shipped, mcp4 build-grade —
[`../../aaw/mcp/specs/mcp.progress.md`](../../aaw/mcp/specs/mcp.progress.md)). What remains toward 22
— message channels, resonance, archival, and the `aaw audit` / `aaw reconcile` / `aaw tui` CLI faces
— is `mcp5`–`mcp8`, owned by the forward roadmap and not duplicated here. **The code is the
authority for every surface fact in this document; the forward design is the authority for the
rationale and the unbuilt remainder.**

## S-3 · The master invariant (as-built, restated from the forward design)

> **Files are truth; no loss by construction.** Every durable fact lives in a plain file in the
> repository tree, and the files win: the server holds no state that cannot be rebuilt by re-reading
> them, writes every whole-file mutation atomically (temp + fsync + rename — whole-or-old, never
> torn), and appends history rather than rewriting it.

This is the forward design's §3 invariant
([`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md) §3), and the as-built tree
holds it: the index is read-through (`internal/store/store.go` doc), every whole-file write is
`writeFileAtomic` (temp + fsync + rename — `internal/store/atomic.go:8-`), and ledger entries are
append-only (`internal/store/ledger.go` doc, "Entries are append-only and never rewritten").

## S-4 · The 18-tool surface

The server registers exactly **18 MCP tools** — 7 by explicit `mcp.AddTool` and 11 in a single
`streams` loop. The `selftest` mode asserts the count over the live wire
(`cmd/aaw/main.go:778`, `len(tools.Tools) == 18`).

### S-4.1 · Lifecycle & registry (7 tools — explicit `mcp.AddTool`)

| Tool | `file:line` | What it does |
| --- | --- | --- |
| `aaw_init` | `cmd/aaw/main.go:369` | create or idempotently re-open a scope; writes `<ledger_dir>/<scope>.progress.md` if absent (a hand-written ledger is never touched) |
| `aaw_spawn` | `cmd/aaw/main.go:385` | record a spawned agent in the scope registry and mint its CCL-id; the parent (by CCL-id) must exist except for the director; an optional `deliverable` file's mtime is the third liveness source |
| `agent_register` | `cmd/aaw/main.go:410` | register an identity (LAW-1); returns the spawn-vs-register tallies; `registered > spawned` raises the advisory `FAKE-N` signal without refusing |
| `agent_send` | `cmd/aaw/main.go:438` | record a message to a registered agent (the durable log; delivery is the harness's job) |
| `agent_heartbeat` | `cmd/aaw/main.go:452` | zero-ledger-cost liveness touch on a registry row; refreshes `last_seen_at`, optionally declares a quiet window (capped 240 min) and a note; lease-at-dispatch |
| `aaw_status` | `cmd/aaw/main.go:478` | the gate console: per-prefix tallies, `gates{z_eligible,d_count,z_count}` (the LAW-4 pre-commit check in one call), per-agent three-source liveness verdicts, open advisory signals, parse health |
| `probe` | `cmd/aaw/main.go:520` | health/diagnostic: name, version, workspace, known scopes, the instance-lock holder, and the boot surface (`started_at`, listeners, `effective_config` with winning sources, `wire_contract`, per-scope `reopened_at`) |

### S-4.2 · The `tool_x_*` ledger family (11 tools — the `streams` loop)

Eleven ledger writers built in one loop (`cmd/aaw/main.go:539-582`, the `streams := []struct{ tool,
stream, desc string }{…}` slice). Every writer shares one parameter shape (`task_id` req · `slug`
req · `body` req · `actor`) and one output shape (`{ok, entry, path}`), and appends one entry to its
tagged channel section of `<scope>.progress.md` under the per-scope lock via
`Scope.AppendAttributed` (`internal/store/ledger.go:185`).

| Tool | `file:line` | Channel section → prefix |
| --- | --- | --- |
| `tool_x_trace` | `cmd/aaw/main.go:540` | `{<scope>-thinking}` → `T-n` |
| `tool_x_analyze` | `cmd/aaw/main.go:541` | `{<scope>-analysis}` → `A-n` |
| `tool_x_alternative` | `cmd/aaw/main.go:542` | `{<scope>-alternatives}` → `V-n` |
| `tool_x_decision` | `cmd/aaw/main.go:543` | `{<scope>-decisions}` → `D-n` |
| `tool_x_learning` | `cmd/aaw/main.go:544` | `{<scope>-learnings}` → `L-n` |
| `tool_x_nxm_synthesize` | `cmd/aaw/main.go:545` | `{<scope>-nxm}` → `S-n` |
| `tool_x_consensus` | `cmd/aaw/main.go:546` | `{<scope>-consensus}` → `C-n` |
| `tool_x_escalation` | `cmd/aaw/main.go:547` | `{<scope>-escalations}` → `E-n` |
| `tool_x_progress` | `cmd/aaw/main.go:548` | `{<scope>-progress}` → `P-n` |
| `tool_x_complete` | `cmd/aaw/main.go:549` | `{<scope>-complete}` → `Z-n` — **refused while no `D-n` is locked** |
| `tool_x_report` | `cmd/aaw/main.go:550` | `{<scope>-report}` → `Y-n` |

> **The 18 vs the forward 22.** The forward catalog adds four message/measurement tools
> (`channel_publish`, `channel_poll`, `channel_list`, `tool_x_resonance`) and reconciles the v1
> `created` flag — `mcp7` per
> [`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md). The as-built `tool_x_*`
> family is 11 (no `tool_x_resonance` yet); the message-channel family is unbuilt. Forward-tense:
> the roadmap plans the 18 → 22 jump at `mcp7`.

## S-5 · The LAW-4 gate — `Z` requires `D`

The one **hard process gate**: `tool_x_complete` is refused while the scope ledger holds zero `D-n`
decision entries. It is enforced inside the ledger engine, not at the tool boundary, so a
hand-written `D-n` satisfies it exactly as a tool-written one does.

- The gate fires in `Scope.Append` / `AppendAttributed` at the `Z`-prefix branch
  (`internal/store/ledger.go:241`), returning
  `gates.Errorf(gates.GATE_Z_REQUIRES_D, …)` (`internal/store/ledger.go:250`) when no `D-n` is
  locked.
- `GATE_Z_REQUIRES_D` is one of the closed 16 codes (`internal/gates/gates.go:31`).
- The pre-commit answer is `aaw_status.gates`: `z_eligible = d_count >= 1` (`cmd/aaw/main.go:148-154`
  — the `Gates` struct doc), so the Director's LAW-4 pre-commit check is one read, no greps.
- `selftest` proves the refusal over the wire: a premature `Z-0` (before any `D`) must refuse with
  `GATE_Z_REQUIRES_D` (`cmd/aaw/main.go:856`), then a `T-1 → D-1 → Z-1` round-trip succeeds
  (`cmd/aaw/main.go:857-859`).

This is the server half of the framework's LAW-4 ("each X-Task ends in exactly one git commit"): the
server cannot complete a task whose decision was never recorded; the commit itself stays the
Director's act, outside the server.

## S-6 · The store — the workspace scope/agent/message registry

`internal/store` holds the server's durable state; files are the source of record and the server
keeps no state that cannot be rebuilt from them (`internal/store/store.go` doc).

- **The scope index** — `<workspace>/.aaw/scopes.json`: **pure read-through**; every lookup
  re-reads the file under the store lock, every mutation read-merges the single row and writes it
  atomically (`internal/store/store.go` doc, ADR-1). This is the as-built fix for the forward
  design's L-2 read-once defect.
- **The atomic write** — `writeFileAtomic` replaces a path via temp + fsync + rename in the target
  directory, so a reader observes either the complete prior file or the complete new file, never a
  torn one (`internal/store/atomic.go:8-`). Line-granular logs use `O_APPEND` instead.
- **The per-scope ledger** — `<ledger_dir>/<scope>.progress.md`, one file per scope; channel
  sections tagged `{<scope>-<channel>}`, entries `### <PREFIX>-<n> — <title>`, parse-lenient /
  emit-strict, append-only (`internal/store/ledger.go` doc + the embedded EBNF). CCL-ids mint from
  the registry's persisted `next_ccl` counter (`internal/store/store.go` doc, ADR-22).
- **The single-writer discipline** — all writes to a scope's ledger, registry, and messages
  serialize under one per-scope mutex; no lock nests except store→scope (`internal/store/store.go`
  doc, ADR-3).

The `tool_x_*` family's twelfth slot — `tool_x_resonance` over peer artifacts — and the message
channels (`<scope>.messages.jsonl`) are the forward design's `mcp7`; as built, `agent_send` records
a point-to-point message through `Scope.RecordMessage` (`cmd/aaw/main.go:444`) and the dedicated
channel tools do not yet exist.

## S-7 · The boot/config plane

`internal/config` is the AD-8 boot/config plane (`internal/config/config.go` doc): identity by
flags, policy by the tree-visible file, no environment layer.

- **The five identity flags** (`config.RegisterFlags`, `internal/config/config.go:45-51`):
  `-addr` (default `localhost:8905`), `-workspace` (default `.`), `-log-level` (default `info`),
  `-stdio` (default `false`), `-wire-check` (default `strict`). Boot identity is flags-only.
- **Flags precede the mode word.** `flag.Parse` stops at the first non-flag argument, so every flag
  must come before `serve` | `selftest` or it silently keeps its default (`cmd/aaw/main.go:5-9`, the
  L-5 quirk; the mode is `flag.Arg(0)` — `cmd/aaw/main.go:50-53`).
- **Runtime policy is files-truth.** `<workspace>/.aaw/config.json` is Operator-edited, **never
  written by the server**, and read through on every evaluation (no cache, no mtime keying), so an
  edit applies on the next call with no restart; precedence is file > built-in default, per knob,
  each knob's winning source reported in `probe.effective_config` (`internal/config/config.go` doc).
  No per-knob policy flag exists anywhere.
- **The wire check.** `config.WireCheck` (`internal/config/config.go:276`) validates the workspace
  `.mcp.json` `aaw` entry against the bound address and returns one verdict —
  `agree | mismatch | absent | unparseable | skipped`. The three-state `-wire-check` is
  `strict` by default: strict refuses to boot on `mismatch`/`unparseable` (`wireRefuses`,
  `cmd/aaw/main.go:653-655`; the boot `log.Fatalf` at `cmd/aaw/main.go:739`), printing the fix in
  both directions (`wireFix`, `cmd/aaw/main.go:661-667`); `warn` proceeds loudly; `skip` opts out.
  The server **never generates or edits** `.mcp.json`.

## S-8 · The gate plane — the closed error vocabulary + PATH_ESCAPE

`internal/gates` is the gate plane (`internal/gates/gates.go` doc): the closed error vocabulary
every domain refusal renders through, plus the containment predicate behind the PATH_ESCAPE
boundary gate.

- **The contract (AD-7).** Every domain refusal is an `IsError` tool result whose text is
  `aaw: <CODE>: <detail>`, `<CODE>` from the closed set; the code is the contract a caller branches
  on, the detail is prose (`internal/gates/gates.go` doc). Codes are **append-only**: a rung may add
  a constant, never rename, retype, or remove one. Protocol failures (malformed JSON-RPC, unknown
  tool) stay the SDK's and carry no `aaw:` code.
- **The closed set** (the sixteen §9 codes; constant names equal their wire literals —
  `internal/gates/gates.go:24-52`): `SLUG_INVALID` · `NOT_INITIALIZED` · `LEDGER_DIR_REQUIRED` ·
  `LEDGER_DIR_CONFLICT` · `PATH_ESCAPE` · `PARENT_NOT_FOUND` · `AGENT_UNKNOWN` · `NOT_REGISTERED` ·
  `GATE_Z_REQUIRES_D` · `ARCHIVED` · `ARG_MISSING` · `ARTIFACTS_REQUIRED` · `CORRUPT_STATE` ·
  `INSTANCE_LOCKED` · `PORT_BUSY` · `WIRE_MISMATCH`.
- **The PATH_ESCAPE predicate.** `gates.Contained(root, path)` (`internal/gates/gates.go:93`)
  resolves a path and reports whether it stays under the workspace root; it backs both faces of the
  containment gate — `aaw_init` and `aaw_spawn` refuse a `ledger_dir`/`deliverable` that escapes the
  root with `PATH_ESCAPE`. `selftest` proves it: an out-of-root `ledger_dir` is refused
  `PATH_ESCAPE` at the door (`cmd/aaw/main.go:852`).

> Some codes are emitted by surfaces this as-built tree does not yet fully exercise:
> `ARTIFACTS_REQUIRED` is reserved for `tool_x_resonance` (forward `mcp7`); the set is declared
> closed and complete now so no later rung adds one silently (the forward §9 contract).

## S-9 · The advisory formation-signal contract

`internal/signals` holds the advisory formation-signal contract (`internal/signals/signals.go`
doc): the policy constants, the closed signal-code set, the V-SOLO computations, and the
deduplicated line emitter for `<workspace>/.claude/audit.log`.

- **Advisory by construction.** No emission — and no emission *failure* — blocks a tool call; the
  only hard process gate is the LAW-4 `Z`-gate (S-5) (`internal/signals/signals.go` doc, MCP2-INV3).
- **The closed signal-code set** (`internal/signals/signals.go:41-47`): `FAKE-N` · `V-SOLO-1` ·
  `V-SOLO-2` (computed, **never emitted** — the W-1 adjudication: a legitimate degraded run is
  honest history) · `UNREGISTERED-ATTRIBUTION` · `CONTAINMENT`.
- **The policy constants** (Operator-tunable defaults under the `.aaw/config.json` read-through;
  the one authority for each value is `internal/config`): the liveness window, the director-activity
  threshold, and the quiet-window cap (`internal/signals/signals.go:34-` doc).
- **The dedup emitter** writes one line per signal to `.claude/audit.log`, deduplicated per
  `(scope, code, evidence window)`. `FAKE-N` is evaluated on `agent_register`; `V-SOLO-1` (both
  clauses required) at `aaw_status` and `tool_x_complete` — the `complete` stream triggers
  `evaluateFormation` (`cmd/aaw/main.go:577-579`).

## S-10 · The wire contract + the instance flock

- **Streamable HTTP at `localhost:8905`.** The server builds an `mcp.NewServer` + an
  `mcp.NewStreamableHTTPHandler` (`cmd/aaw/main.go:366`, `:710`) and serves it over HTTP. `-stdio`
  is a development convenience with no listener, reported `wire_contract: skipped`
  (`cmd/aaw/main.go:697-705`).
- **Dual-stack loopback bind, all-or-nothing.** For host `localhost` the server binds **both**
  loopback families — `tcp4 127.0.0.1` and `tcp6 [::1]` — or refuses: `bindLocalhost`
  (`cmd/aaw/main.go:595-608`) closes any already-bound listener and returns `PORT_BUSY` if either
  family fails, and `runServer` makes that refusal fatal (`cmd/aaw/main.go:716-718`). On refusal one
  capped (~500 ms) MCP probe of the occupied port names an answering aaw holder (its workspace +
  version) or falls back to `lsof` guidance (`probeHolder`, `cmd/aaw/main.go:614-647`). No automatic
  port hunting. This is the as-built realization of the forward AD-9 — the PoC's continue-on-one-
  family lenience is already redesigned away in this tree.
- **The instance flock.** An advisory flock on `<workspace>/.aaw/aaw.lock` is held for the process
  lifetime; a second boot on the same workspace exits non-zero with `INSTANCE_LOCKED` naming the
  current holder (`InstanceLock` / `AcquireInstanceLock`, `internal/store/lock.go:14-`; the boot
  acquire + `log.Fatalf` at `cmd/aaw/main.go:683-686`). One instance per workspace makes the
  in-process per-scope lock sufficient for all file mutations.

## S-11 · Genuine design forks (none manufactured)

A reverse as-built spec records what shipped; it does not re-open a settled design. **No genuine
design fork is open in this tree.** The architecture decisions that *were* forks — the stateless
transport posture, the tokenless v2 auth, the SDK-modification policy — were ruled in the forward
Design Phase and are recorded there with their four-part arms (Rationale · 5W · Steelman · Steward,
[`aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md)) and their donor ADRs
([`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md) §13, the decision record). The
open seams that remain — the C-1 transport probe, the D-5 SDK seam, the auth upgrade path — are the
forward roadmap's "Seams & open decisions"
([`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md)), not this document's.
Surfacing a fork here where the code already settled it would manufacture a decision the Operator did
not need.

---

## Map

- The forward v2 design (the authority for rationale + the 22-tool target):
  [`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md).
- The as-built ladder + the path to 22: [`./aaw.roadmap.md`](./aaw.roadmap.md).
- The as-built dashboard: [`./aaw.progress.md`](./aaw.progress.md).
- The 18 tools by feature: [`./aaw.features.md`](./aaw.features.md).
- The testing view: [`./aaw.testing.md`](./aaw.testing.md).
- References: [`./aaw.references.md`](./aaw.references.md).
- The rung-triad index (links the forward triads, does not duplicate them):
  [`./specs/README.md`](./specs/README.md).
- As-built source: [`go/aaw/`](../../../go/aaw/) · the build guide [`go/CLAUDE.md`](../../../go/CLAUDE.md).
