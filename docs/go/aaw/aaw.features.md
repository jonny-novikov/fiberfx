# aaw MCP server — the as-built feature catalog (reverse)

> The 18 tools of the **aaw** server (`2.0.0-min`) by feature, each grounded at its `file:line` in
> [`go/aaw/`](../../../go/aaw/). This file **maps** the as-built surface; the as-built design
> [`./aaw.design.md`](./aaw.design.md) **defines** it, and the forward design
> [`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md) is the authority for the
> 22-tool target and the rationale. NO-INVENT: every tool name, channel prefix, and error code below
> is re-verified at source; an unbuilt surface is named forward-tense and linked, never asserted.

Two feature groups, exactly as the code registers them: **lifecycle & registry** (7 explicit
`mcp.AddTool` calls) and **the `tool_x_*` ledger family** (11 tools built in one `streams` loop —
`cmd/aaw/main.go:539-582`). 7 + 11 = **18**, the count `selftest` pins over the wire
(`cmd/aaw/main.go:778`).

---

## A · Lifecycle & registry (7 tools)

These tools open scopes, register the team, carry liveness and messages, and report state. They
write the registry (`<scope>.registry.json`) and the message log, never a ledger entry — the one
exception's ledger touch is `tool_x_complete`'s gate in group B.

### `aaw_init` — open or re-open a scope (`cmd/aaw/main.go:369`)
Creates or idempotently re-opens a scope: registers it in the workspace index
(`<workspace>/.aaw/scopes.json`) and writes `<ledger_dir>/<scope>.progress.md` if absent — a
hand-written ledger is first-class input and is never touched. `ledger_dir` is required on first
init and must resolve under the workspace root, or the call refuses `PATH_ESCAPE` /
`LEDGER_DIR_REQUIRED` / `LEDGER_DIR_CONFLICT` (`internal/gates/gates.go`).

### `aaw_spawn` — record a spawned agent (`cmd/aaw/main.go:385`)
Records a spawned agent in the scope registry and mints its CCL-id from the persisted `next_ccl`
counter. The parent (by CCL-id) must exist, except for the director (`PARENT_NOT_FOUND` otherwise).
An optional `deliverable` file path is recorded as the agent's third liveness source — its mtime
testifies to silent work (files-are-truth applied to liveness). A `deliverable` outside the root
refuses `PATH_ESCAPE`.

### `agent_register` — register an identity, LAW-1 (`cmd/aaw/main.go:410`)
Registers an agent identity in the scope registry (LAW-1, "each registered identity backed by a real
spawned subagent"). Returns the spawn-vs-register tallies; **`registered > spawned` raises the
advisory `FAKE-N` signal** to `.claude/audit.log` (`internal/signals/signals.go:43`) without
refusing the call — the REJECT-EXECUTION action belongs to the protocol layer and the humans reading
the log, never to the server.

### `agent_send` — durable point-to-point message (`cmd/aaw/main.go:438`)
Records a message to a registered agent (`Scope.RecordMessage`, `cmd/aaw/main.go:444`); delivery is
the harness's job, this is the durable log. Touches the sender's liveness when an `actor` is given
(`touchActor`, `cmd/aaw/main.go:449`).

### `agent_heartbeat` — zero-ledger liveness touch (`cmd/aaw/main.go:452`)
A zero-ledger-cost liveness touch on a registry row: refreshes `last_seen_at`, optionally declares a
quiet window (capped at 240 minutes) and a note. Lease-at-dispatch: the director may heartbeat for a
peer it dispatched. A live quiet window suppresses the `V-SOLO-1` silence clause for that agent.

### `aaw_status` — the gate console (`cmd/aaw/main.go:478`)
The one-call scope report: per-prefix tallies, `gates{z_eligible, d_count, z_count}` (the LAW-4
pre-commit check in one call — `z_eligible = d_count >= 1`, `cmd/aaw/main.go:148-154`), per-agent
three-source liveness verdicts with their winning source, open advisory signals, and ledger
parse-health. `V-SOLO-1` evaluation runs here and at `tool_x_complete`.

### `probe` — health & boot diagnostics (`cmd/aaw/main.go:520`)
Health/diagnostic, no scope required: server name, version, workspace, known scopes, the
instance-lock holder, and the boot surface (`started_at`, listeners, `effective_config` with each
knob's winning source, `wire_contract`, per-scope `reopened_at`). It is also the answerer the
all-or-nothing bind's holder probe calls (`probeHolder`, `cmd/aaw/main.go:633`).

## B · The `tool_x_*` ledger family (11 tools)

Eleven ledger writers, one per channel, built in the `streams` loop (`cmd/aaw/main.go:539-582`). Each
shares one parameter shape — `task_id` req · `slug` req (must equal an initialized scope) · `body`
req (a first line `<PREFIX>-<k> — <title>` lifts the title into the header) · `actor` (registry-side
attribution only — the entry header is byte-identical with or without it) — and appends one entry to
its tagged channel section of `<scope>.progress.md` under the per-scope lock via
`Scope.AppendAttributed` (`internal/store/ledger.go:185`). Shared refusals: `ARG_MISSING`,
`SLUG_INVALID`, `NOT_INITIALIZED` (`cmd/aaw/main.go:556-565`).

| Tool | Appends | Channel section → prefix | `file:line` |
| --- | --- | --- | --- |
| `tool_x_trace` | a derivation trace | `{<scope>-thinking}` → `T-n` | `cmd/aaw/main.go:540` |
| `tool_x_analyze` | an analysis | `{<scope>-analysis}` → `A-n` | `cmd/aaw/main.go:541` |
| `tool_x_alternative` | an alternative (an architect's arm) | `{<scope>-alternatives}` → `V-n` | `cmd/aaw/main.go:542` |
| `tool_x_decision` | a locked decision | `{<scope>-decisions}` → `D-n` | `cmd/aaw/main.go:543` |
| `tool_x_learning` | a learning | `{<scope>-learnings}` → `L-n` | `cmd/aaw/main.go:544` |
| `tool_x_nxm_synthesize` | an NxM synthesis | `{<scope>-nxm}` → `S-n` | `cmd/aaw/main.go:545` |
| `tool_x_consensus` | a consensus record | `{<scope>-consensus}` → `C-n` | `cmd/aaw/main.go:546` |
| `tool_x_escalation` | an escalation | `{<scope>-escalations}` → `E-n` | `cmd/aaw/main.go:547` |
| `tool_x_progress` | a progress record | `{<scope>-progress}` → `P-n` | `cmd/aaw/main.go:548` |
| `tool_x_complete` | a completion record | `{<scope>-complete}` → `Z-n` | `cmd/aaw/main.go:549` |
| `tool_x_report` | a final report | `{<scope>-report}` → `Y-n` | `cmd/aaw/main.go:550` |

### The LAW-4 gate — `tool_x_complete` requires a locked `D-n`

`tool_x_complete` is the one writer carrying a hard process gate: it is **refused while the scope
ledger holds zero `D-n` decision entries**. The refusal is enforced inside the ledger engine at the
`Z`-prefix branch (`internal/store/ledger.go:241`), returning `GATE_Z_REQUIRES_D`
(`internal/store/ledger.go:250`) — so a hand-written `D-n` satisfies it exactly as a tool-written one
does. On a successful `complete` the formation signal evaluation runs (`evaluateFormation`,
`cmd/aaw/main.go:577-579`), emitting `V-SOLO-1` to the audit log when both its clauses hold. This is
the server half of LAW-4: a task cannot be completed whose decision was never recorded; the commit
stays the Director's act, outside the server.

## C · The planes the tools ride

The tools are thin faces over four `internal/` planes — each its own authority, defined in
[`./aaw.design.md`](./aaw.design.md):

- **`internal/store`** — the per-scope single-writer registry + the single-file ledger (the `T..Y`
  channels), the read-through index, the atomic write, the persisted `next_ccl` mint, the instance
  flock (§S-5/S-6/S-10).
- **`internal/config`** — the five identity flags, the `.aaw/config.json` policy read-through, the
  `-wire-check` (§S-7).
- **`internal/gates`** — the closed 16-code error vocabulary + the `PATH_ESCAPE` containment
  predicate `Contained(root, path)` (§S-8).
- **`internal/signals`** — the advisory `FAKE-N` / `V-SOLO-1` / `V-SOLO-2`(computed) /
  `UNREGISTERED-ATTRIBUTION` / `CONTAINMENT` set + the deduplicated `.claude/audit.log` emitter
  (§S-9).

## D · Toward 22 — what this surface does not yet carry (forward)

The forward catalog (22 tools) adds, at `mcp7`, four tools this as-built tree does not serve —
`channel_publish`, `channel_poll`, `channel_list` (scope-wide message topics in
`<scope>.messages.jsonl`) and `tool_x_resonance` (deterministic shingle + citation-Jaccard echo
measurement, which is why `ARTIFACTS_REQUIRED` is reserved in the closed code set) — plus the `aaw
audit` / `aaw reconcile` / `aaw tui` CLI faces. **Forward-tense:** the roadmap plans the 18 → 22 jump
at `mcp7` ([`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md) §mcp7); the rationale
is the forward design ([`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md) §7). This
file does not restate those surfaces — it records that the as-built family is 11 `tool_x_*` + 7
lifecycle/registry = 18.

---

## Map

- As-built design (the `file:line` map): [`./aaw.design.md`](./aaw.design.md).
- As-built roadmap / dashboard / testing: [`./aaw.roadmap.md`](./aaw.roadmap.md) ·
  [`./aaw.progress.md`](./aaw.progress.md) · [`./aaw.testing.md`](./aaw.testing.md).
- Forward authority (the 22-tool catalog + rationale):
  [`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md) §7.
- The framework the tools serve: [`../../aaw/aaw.framework.md`](../../aaw/aaw.framework.md).
- Source: [`go/aaw/`](../../../go/aaw/).
