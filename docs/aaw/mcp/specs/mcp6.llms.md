# MCP6 · agent brief (llms)

> Implementation brief for a coding agent. References, traced requirements, the execution topology, and
> a self-contained build brief. Pairs with the spec mcp6.md and the stories mcp6.stories.md; this rung
> has no runbook — the comprehensive implementation prompt below is the complete build instruction.

## References

- `apps/aaw/cmd/aaw/main.go` — the CLI face, as built: `:31-34` the flag block (`-addr`, `-workspace`
  at `:32-33`); `:36-51` the mode dispatch (`flag.Parse()` `:37`, default `serve` `:38`,
  `flag.Arg(0)` `:40`, `serve` `:43-44`, `selftest` `:45-46`, the usage line + exit 2 at `:48-49`) —
  this rung adds the `tui` case and extends the usage line. **Invocation is flags-first** (ledger
  L-5: `flag.Parse` stops at the first non-flag word) — every doc, test, and example writes
  `aaw -workspace <dir> tui`. The status console the read model mirrors: the `aaw_status`
  registration at `:395`, the gates derivation at `:421` (`ZEligible: t["D"] >= 1`), and the shapes —
  `Gates` `:139-145`, `LivenessRow` `:147`, `StatusOut` `:169`.
- `apps/aaw/internal/store/store.go` — the read-only paths the read model REUSES (build no parallel
  reader): `readIndex` `:116` + `ScopeNames` `:235` (the scope list; pure read-through — files win),
  `GetScope` `:220`, `LedgerPath` `:250`, `LoadRegistry` `:261`, and `Scope.Liveness(a, window, at)`
  `:519` — the as-built three-source fusion returning the verdict and its winning source, the exact
  derivation the liveness table renders.
- `apps/aaw/internal/store/ledger.go` — `ParseHealth` `:101-121`: one whole-ledger scan yielding the
  per-prefix tallies and the sorted unknown prefixes (the gates panel's D/Z counts and the
  parse-health line); `Tallies` `:124-128` delegates to it.
- `apps/aaw/internal/signals/signals.go` — `:22-32` the policy constants (`WindowW` 45 min,
  `ThresholdK` 3, `QuietCapMinutes` 240) the verdict derivation reads until mcp4's config rung homes
  them; the read model consumes the same constants, never private copies.
- The Bubble Tea stack (real external APIs — mcp6 adds them; cite nothing beyond these):
  charmbracelet/bubbletea — the Elm-architecture `tea.Model` (`Init() tea.Cmd` ·
  `Update(tea.Msg) (tea.Model, tea.Cmd)` · `View() string`), `tea.NewProgram`, `tea.Tick`;
  charmbracelet/bubbles — `table` (the liveness table) and `viewport` (the live-follow ledger tail);
  charmbracelet/lipgloss — styling. <https://github.com/charmbracelet/bubbletea>. The trio is the
  rung's ONLY dependency addition — at HEAD `apps/aaw/go.mod` requires only the first-party
  `github.com/fiberfx/mcp-go/v2` replace plus transitives — a named seam (the D-5 analog), versions
  pinned at build time.
- The run ledger [`../aaw-mcp.progress.md`](../aaw-mcp.progress.md) — D-17 (mcp6 is the measurement
  rung; the console renders the coordination the close tally counts), D-14/D-16 (the rung-promotion
  precedent this rung repeats), D-3 (tool fatigue — the zero-MCP-tool form), L-5 (flags-first); the
  design [`../aaw.mcp.design.md`](../aaw.mcp.design.md) — §3 (the master invariant: the server is
  rebuildable from the tree, the fact that makes a lock-free live console possible), §10 (the
  zero-MCP-tool CLI pattern), AD-12 (the layout extends by one seam), AD-6 (the catalog untouched).
- Depends on mcp1 by id (atomic whole-file writes make lock-free reads torn-proof) and reuses the
  mcp2/mcp3 read surfaces (the liveness fusion, parse-health); mcp4 and mcp5 are not required at
  build time.

## Requirements

- **MCP6-R1** — the read model re-reads the file plane through the store's existing read-only paths
  (`readIndex`/`ScopeNames`, `GetScope`, `LoadRegistry`, `ParseHealth`, `Scope.Liveness`) with an
  mtime guard (re-parse only what changed), and derives verdicts + winning sources, `z_eligible` +
  D/Z counts, per-prefix tallies, and unknown prefixes exactly as the `aaw_status` handler does — one
  derivation, no parallel reader, no private policy constants. [US: MCP6-US-A2, MCP6-US-D1]
- **MCP6-R2** — the `tea.Model`: `Init() tea.Cmd` schedules the first read and the `tea.Tick`
  cadence; `Update(tea.Msg) (tea.Model, tea.Cmd)` is pure over messages (tick → a re-read command;
  keys → navigation); `View() string` renders via lipgloss the scope list and the scope detail — the
  `bubbles` table liveness rows (agent · role · CCL-id · model · verdict · quiet), the gates panel,
  the `bubbles` viewport ledger tail following appends, and the parse-health line; run by
  `tea.NewProgram`. [US: MCP6-US-D1]
- **MCP6-R3** — the CLI face: the `tui` mode word beside `serve`/`selftest` in the
  `cmd/aaw/main.go:36-51` dispatch (flags-first, L-5); the usage line at `:48` extends to name the
  mode; a non-TTY stdout refuses with usage, exit 2 — a CLI usage refusal, never a §9 code.
  [US: MCP6-US-D1]
- **MCP6-R4** — the dependency seam: the go.mod/go.sum delta is exactly the charm trio (bubbletea,
  bubbles, lipgloss) plus transitives, pinned; no fsnotify, no other addition. [US: MCP6-US-D3]
- **MCP6-R5** — read-only, lock-free, unattributed, contained, by construction: no write API in the
  package; no lock acquired (read-only opens that never block a writer); no registry row's
  `last_seen_at`, counter, or quiet window moves because the console read; only workspace-contained
  paths are opened. [US: MCP6-US-D2, MCP6-US-A1]
- **MCP6-R6** — zero MCP surface change: no tool registered, no schema touched; the selftest tool
  count stays 18 and every existing shape is unchanged. [US: MCP6-US-D3]
- **MCP6-R7** — the harness pins the rung: table-driven `Update` tests (no I/O inside `Update`);
  width-pinned `View` goldens over committed fixture trees; the re-launch determinism case (same
  tree → identical renders); all green under `go test -race -count=1`. [US: MCP6-US-D4]

## Execution topology

Runtime: a terminal session — parse flags, refuse a non-TTY, hand the model to `tea.NewProgram`; the
model re-reads the file plane on every tick and renders what the files say. No server, no locks, no
writes, no network.

```text
aaw -workspace <dir> tui            (flags-first, L-5; non-TTY stdout ⇒ usage, exit 2)
  ──▶ tea.NewProgram(model).Run()
        Init() ──▶ first file-plane read + the tea.Tick cadence
        Update(msg) ── tick ──▶ mtime-guarded re-read (index · registry · ledger; read-only, no lock)
                    ── key  ──▶ navigate: scope list ⇄ scope detail
        View() ──▶ lipgloss render — scopes | detail: liveness table · gates panel · ledger tail ·
                   parse-health line
  files are truth: every fact on screen re-derives from .aaw/scopes.json + <scope>.registry.json +
  <scope>.progress.md; a re-launch over the same tree renders the same view
```

Tasks (each step leaves the app compiling):

```text
1. the seam: go get the charm trio (bubbletea · bubbles · lipgloss), pinned — go.mod/go.sum the
   only dependency delta
   ─▶ 2. internal/tui/read.go: the read model — the store read paths + the mtime guard + the
         status-parity derivation (verdicts, gates, tallies, unknown prefixes)
   ─▶ 3. internal/tui/model.go: the tea.Model (Init/Update/View) + the scope list view
   ─▶ 4. internal/tui/detail.go: the detail view — bubbles/table liveness · gates panel ·
         bubbles/viewport ledger tail · parse-health line; lipgloss styles; tea.Tick wiring
   ─▶ 5. cmd/aaw/main.go: the `tui` case in the :42 switch + the usage line + the non-TTY refusal
   ─▶ 6. harness: pure-Update table tests · width-pinned View goldens over fixture trees · the
         re-launch determinism case · -race · selftest 18
```

Touched files: `apps/aaw/internal/tui/` (new — `read.go`, `model.go`, `detail.go`, `tui_test.go`,
`testdata/`), `apps/aaw/cmd/aaw/main.go` (the mode word + usage + the non-TTY check),
`apps/aaw/go.mod` + `go.sum` (the charm trio), tests. No MCP tool registration, no
store/signals/gates change, no `apps/mcp-go`.

## Agent stories

- **MCP6-AS1** [implements MCP6-US-D3] — Directive: add the charm trio to `apps/aaw/go.mod` (pinned
  versions; bubbletea + bubbles + lipgloss; nothing else). Acceptance gate: the go.mod/go.sum delta
  is exactly the trio plus transitives; `GOWORK=off go build ./...` clean.
- **MCP6-AS2** [implements MCP6-US-A2, MCP6-US-D1] — Directive: build the read model in
  `internal/tui/read.go` over the store's read-only paths (`readIndex`/`ScopeNames`, `GetScope`,
  `LoadRegistry`, `ParseHealth`, `Scope.Liveness`) with the mtime guard, deriving verdicts + winning
  sources, `z_eligible` + D/Z counts, tallies, and unknown prefixes the way the `aaw_status` handler
  does. Acceptance gate: the status-parity test (same fixture tree → the read model and the status
  derivation agree) plus the determinism case green.
- **MCP6-AS3** [implements MCP6-US-D1] — Directive: build the `tea.Model` — `Init` (first read +
  `tea.Tick`), pure `Update` (tick → re-read command; keys → list ⇄ detail), `View` via lipgloss —
  with the scope list and the detail view (`bubbles` table liveness · gates panel · `bubbles`
  viewport ledger tail · parse-health line). Acceptance gate: the table-driven `Update` cases pass
  with no I/O inside `Update`; one `View` golden renders.
- **MCP6-AS4** [implements MCP6-US-D1, MCP6-US-D2, MCP6-US-A1] — Directive: wire the `tui` mode word
  into the `cmd/aaw/main.go:36-51` dispatch (flags-first), extend the usage line at `:48`, refuse a
  non-TTY stdout with usage (exit 2); hold the safety line by construction — no write API and no lock
  acquisition anywhere under `internal/tui/` (pin both with grep assertions), reads unattributed and
  workspace-contained. Acceptance gate: the exit-2 case; a tree-hash comparison before/after a
  session is equal; a registry byte-comparison across a session is equal; the no-write-API and
  no-lock greps are empty.
- **MCP6-AS5** [implements MCP6-US-D4] — Directive: commit the fixture trees + the width-pinned
  `View` goldens; add the re-launch determinism case; run the suite under `-race`; run `aaw selftest`
  and pin 18 tools. Acceptance gate: `GOWORK=off go test -race -count=1 ./apps/aaw/...` green;
  selftest green at 18; the goldens match.

## Execution plan — first two stories

1. **MCP6-AS1 — the seam.** `go get` the charm trio, pinned; go.mod/go.sum the only delta. Gate:
   `GOWORK=off go build ./...` clean; the diff holds nothing but the trio + transitives.
2. **MCP6-AS2 — the read model.** `internal/tui/read.go` over the store read paths + the mtime guard
   + the status-parity derivation, with the parity and determinism tests. Gate: both tests green.

## Comprehensive implementation prompt

```text
Build MCP6 — interactive aaw, the Bubble Tea console — as a read-only TUI over the as-built aaw
binary. Edit apps/aaw only; register NO MCP tool; do not touch apps/mcp-go; run no git. Execute the
agent stories in order, AS1 -> AS5.

AS1 — the dependency seam. GOWORK=off go get the charm trio into apps/aaw, pinned:
github.com/charmbracelet/bubbletea, github.com/charmbracelet/bubbles,
github.com/charmbracelet/lipgloss. The go.mod/go.sum delta is exactly the trio plus its transitives
— no fsnotify, nothing else. This is the ladder's first third-party UI dependency: a named seam,
versions pinned, ratified at the rung gate.

AS2 — the read model. New package apps/aaw/internal/tui, file read.go: re-read the file plane
through the store's EXISTING read-only paths — readIndex/ScopeNames (internal/store/store.go:116,
:235) for the scope list, GetScope (:220), LoadRegistry (:261) for the rows, Scope.Liveness (:519)
for the verdict + winning source per agent, and ParseHealth (internal/store/ledger.go:101-121) for
the per-prefix tallies + the sorted unknown prefixes. Derive the gates panel the way the aaw_status
handler does (cmd/aaw/main.go:421: z_eligible = D-tally >= 1, with the D and Z counts). Guard
re-reads by mtime: re-parse only files whose mtime moved. Build NO parallel reader and NO private
policy constants — the signals package constants (signals.go:22-32) are the only window/cap source.
The model is deterministic: the same tree yields the same model.

AS3 — the tea.Model. model.go + detail.go: the Elm architecture exactly — Init() tea.Cmd schedules
the first read and the tea.Tick cadence; Update(tea.Msg) (tea.Model, tea.Cmd) is PURE (a tick
returns a re-read tea.Cmd; key messages navigate scope list <-> scope detail; no file I/O inside
Update); View() string renders with lipgloss. Views: (1) the scope list from the index; (2) the
scope detail — the liveness table as a bubbles table (columns: agent, role, CCL-id, model, verdict,
quiet), the gates panel (z_eligible + the D/Z counts), the ledger tail as a bubbles viewport
following appends, and the parse-health line (unknown prefixes). Run by tea.NewProgram.

AS4 — the CLI face + the safety line. Add the `tui` case to the mode switch in
apps/aaw/cmd/aaw/main.go:36-51 (beside serve/selftest) and extend the usage line at :48. Invocation
is FLAGS-FIRST (ledger L-5): aaw -workspace <dir> tui — flags after the mode word silently no-op in
stdlib flag. A non-TTY stdout refuses with the usage line, exit 2 — a CLI usage refusal, never a §9
code. By construction: no os.Create, os.WriteFile, os.Rename, os.Remove, os.MkdirAll anywhere under
internal/tui/ (pin with a grep assertion); no lock acquisition (no lockFor, no flock — a second grep
assertion); reads unattributed (no registry mutation on read; pin with a registry byte-comparison
across a session) and workspace-contained.

AS5 — the harness. Commit testdata/ fixture trees (an index + registries + ledgers covering: a
multi-agent scope with mixed verdicts, a z_eligible=false scope, a ledger holding an unknown prefix);
golden the View renders WIDTH-PINNED (fix the terminal width in tests so lipgloss output is stable);
add the re-launch determinism case (two model builds over the same tree render identically); run
GOWORK=off go test -race -count=1 ./apps/aaw/... and aaw selftest (18 tools, unchanged shapes).

End on the gates: GOWORK=off go build ./... clean; GOWORK=off go vet ./apps/aaw/... clean;
GOWORK=off go test -race -count=1 ./apps/aaw/... green (status-parity, determinism, pure-Update
tables, width-pinned View goldens, exit-2 case, tree-hash equality, registry byte-equality,
no-write-API + no-lock greps); aaw selftest green at 18 tools (zero tool-surface change); the
go.mod delta is exactly the charm trio + transitives; apps/mcp-go untouched; never git. Report the
modules changed, the gate results, the pinned versions chosen, and confirmation that no MCP tool,
schema, or error code was added and no lock or write path exists in internal/tui/.
```

Spec: mcp6.md · Stories: mcp6.stories.md · Index: mcp.md · Roadmap: ../aaw.mcp.roadmap.md · Approach: ../../../elixir/specs/specs.approach.md
