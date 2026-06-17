# MCP6 · interactive aaw — the Bubble Tea console

> The formation, watched live: `aaw tui` — an interactive, READ-ONLY terminal console over the file
> plane, the third application of the design-§10 zero-MCP-tool CLI pattern (after `aaw reconcile` at
> mcp5; `aaw audit` rides mcp7). The master invariant is the enabling fact: files are truth and the
> server is rebuildable from the tree at any instant, so a console that re-reads the file plane renders
> the whole formation live without touching the server. Adds no MCP tool; the catalog is untouched.

## Goal

The sixth rung of the build ladder, inside milestone M3: give the formation a live face. mcp6 builds
`aaw tui` on charmbracelet Bubble Tea — the Elm-architecture `tea.Model` (`Init() tea.Cmd` ·
`Update(tea.Msg) (tea.Model, tea.Cmd)` · `View() string`, run by `tea.NewProgram`) with `bubbles`
(table, viewport) and `lipgloss` (styling) — rendering two thin views: the scope list (from
`.aaw/scopes.json`) and the scope detail — the liveness table in the `aaw_status` row shape (agent ·
role · CCL-id · model · verdict · quiet), the gates panel (`z_eligible` plus the D/Z counts behind
it), the live-follow ledger tail, and the parse-health line (unknown prefixes). Refresh is a
`tea.Tick` re-read of the file plane, mtime-guarded — no fsnotify, no dependency beyond the charm
trio; reads take no lock and never block a writer, because mcp1's whole-file atomic writes make a
torn read impossible. The detail view is the D-17 measurement made visible: the console RENDERS the
coordination the mcp6 rung-close tally counts — ceremonies landing, liveness verdicts moving, the
Z-gate opening — as it happens. The charm trio is the ladder's first third-party UI dependency and is
named as a seam (the D-5 analog: a designed, Operator-ratifiable addition, versions pinned at build
time). The tool surface stays 18 and the v2 catalog end-state stays 22; the displaced message
channels ride mcp7. Build formation: **standard tier** (a new package + a new dependency; the
roadmap's "How the roadmap runs").

## Rationale (5W)

- **Why**   — the developer pays today's cost in blind formations: watching a live run means hand-looping
  `aaw_status` calls or juggling three open files (`.aaw/scopes.json`, `<scope>.registry.json`,
  `<scope>.progress.md`), and the D-17 measurement counts coordination the server carries while no
  surface shows it happening. The agent pays nothing today and must keep paying nothing: a console
  that took locks or attributed its reads would block writers and skew the very liveness evidence it
  renders. The master invariant has already paid for the fix — every durable fact is a plain file and
  the server is rebuildable from the tree at any instant, so a read-only re-reader renders the whole
  formation live without touching the server.
- **What**  — `aaw tui`: the Bubble Tea console (mcp6 adds the charm trio — bubbletea, bubbles,
  lipgloss — the named dependency seam), the scope list + the scope detail (liveness table, gates
  panel, live-follow ledger tail, parse-health line), `tea.Tick` mtime-guarded re-read, the `tui`
  mode word flags-first, a non-TTY refusal (exit 2), and zero MCP-tool change.
- **Who**   — two audiences, named. **The developer** — the human who runs and audits formations:
  the whole formation on one screen instead of N status calls and three open files — scopes,
  per-agent verdicts with their winning sources, `z_eligible` with the counts behind it, the ledger
  tail following appends, unknown prefixes — the D-17 coordination visible as it happens. **The
  agent** — the server's primary users pay no toll: the console holds no lock, blocks no writer,
  attributes no read, and renders the same derivation `aaw_status` answers with — one truth, two
  faces.
- **When**  — the rung after mcp5; in code it stands on mcp1's atomic-write discipline (whole-or-old
  files make lock-free reads torn-proof) and reuses the mcp2/mcp3 read surfaces (the three-source
  liveness fusion, parse-health). The displaced message channels ride mcp7. mcp6 stays the D-17
  measurement rung: its own authoring formation runs server-coordinated on the upfront instruments,
  and the console renders the coordination the close-entry tally counts.
- **Where** — a new `apps/aaw/internal/tui/` (the read model + the `tea.Model`; the AD-12 layout
  extended by one seam); the mode dispatch in `apps/aaw/cmd/aaw/main.go:36-51` (the third mode word
  beside `serve`/`selftest`; the usage line at `:48` extends); `apps/aaw/go.mod` + `go.sum` (the
  charm trio — the dependency seam); tests and committed fixture trees. No MCP tool, no schema, no
  store change, no `apps/mcp-go`.

## Scope

- **In**  — the read model over the file plane, reusing the store's existing read-only paths; the two
  views (the scope list; the scope detail — liveness table · gates panel · live-follow ledger tail ·
  parse-health line); `tea.Tick` mtime-guarded re-read; lipgloss styling; the charm trio as the
  rung's only dependency addition, pinned (the named seam); the `tui` mode word flags-first (L-5) +
  the extended usage line + the non-TTY exit-2 refusal; read-only / no-lock / unattributed /
  workspace-contained by construction; the harness (pure-`Update` table tests, width-pinned `View`
  goldens, the determinism case, `go test -race`, the 18-tool selftest pin).
- **Out** — any MCP tool or schema change (the catalog stays 18 at this rung and 22 at v2 end); any
  write face — an interactive write surface (keystroke → tool call) is a future Operator decision,
  surfaced here and not taken; fsnotify or any watcher dependency (the refresh is `tea.Tick` re-read
  only); message channels (mcp7 — the displacement this rung's promotion caused); resonance, archival,
  and the `aaw audit` CLI (mcp7); the transport posture and the C-1 probe (mcp8). Each deferral goes
  to the named rung.

## Deliverables

- **MCP6-D1** — the **read model**: re-reads the file plane through the store's existing read-only
  paths — the index (`readIndex`, `internal/store/store.go:116`; `ScopeNames`, `:235`; `GetScope`,
  `:220`), the registry (`LoadRegistry`, `store.go:261`), and the ledger (`ParseHealth`,
  `internal/store/ledger.go:101-121` — one scan yielding the per-prefix tallies and the sorted
  unknown prefixes) — and derives the same surfaces `aaw_status` answers with: per-agent verdicts via
  the as-built three-source fusion (`Scope.Liveness`, `store.go:519` — verdict + winning source) and
  the gates panel by the console's own rule (`z_eligible` = D-tally ≥ 1, the derivation at
  `cmd/aaw/main.go:421`). Re-reads are mtime-guarded (re-parse only what changed); the model is
  deterministic — the same tree yields the same model.
- **MCP6-D2** — the **`tea.Model` and the two views**: `Init() tea.Cmd` schedules the first read +
  the `tea.Tick` cadence; `Update(tea.Msg) (tea.Model, tea.Cmd)` is pure over messages (tick →
  re-read command; key → navigation); `View() string` renders via lipgloss — the scope list, and the
  scope detail composed of the liveness table (`bubbles` table), the gates panel, the live-follow
  ledger tail (`bubbles` viewport, following appends), and the parse-health line. Run by
  `tea.NewProgram`.
- **MCP6-D3** — the **CLI face**: the `tui` mode word beside `serve`/`selftest` in the
  `cmd/aaw/main.go:36-51` dispatch (flags-first per L-5 — `aaw -workspace <dir> tui`); the usage line
  at `:48` extends to name the mode; a non-TTY stdout refuses with usage, exit 2 (a CLI usage
  refusal, not a §9 code — the mcp5 exit-code precedent).
- **MCP6-D4** — the **dependency seam, named**: the charm trio (charmbracelet bubbletea + bubbles +
  lipgloss) added to `apps/aaw/go.mod` — the ladder's FIRST third-party UI dependency (at HEAD the
  module requires only the first-party `mcp-go` replace plus transitives); a designed,
  Operator-ratifiable addition (the D-5 analog), versions pinned at build time; no fsnotify, nothing
  beyond the trio.
- **MCP6-D5** — **honesty + safety, by construction**: no write API exists anywhere in the package —
  a session creates, modifies, and deletes nothing; no lock is acquired — reads are read-only opens
  that never block a writer (mcp1's atomic temp+fsync+rename makes a torn read impossible); reads are
  unattributed — no registry row's `last_seen_at`, counter, or quiet window moves because the console
  looked; only workspace-contained paths are opened; the view derives from the files alone — no
  client-side invented state, and a re-launch over the same tree renders the same view.
- **MCP6-D6** — the **harness**: table-driven `Update` tests (the model update is pure — no I/O in
  `Update`); `View` goldens over committed fixture trees (lipgloss output snapshots, width-pinned);
  the read-model determinism case (same tree → same model → same render); `go test -race` green; the
  selftest pin unchanged at 18 tools.

## Invariants

- **MCP6-INV1** — **read-only.** A console session leaves the tree byte-identical — no file is
  created, modified, or deleted by any code path in the package; rendering goes to the terminal only.
- **MCP6-INV2** — **zero tool-surface change.** The MCP catalog stays 18; no tool is registered, no
  schema changes; the dependency addition is build-side only — a deferred-schema client holding mcp5
  shapes is unaffected and the selftest pin is unchanged.
- **MCP6-INV3** — **never blocks a writer.** The console acquires no lock and opens read-only; a
  concurrent ceremony, append, or heartbeat proceeds unimpeded, and a read concurrent with a write
  observes whole-or-old bytes, never torn (the mcp1 atomic-write discipline).
- **MCP6-INV4** — **contained.** Only paths under `-workspace` are ever opened; the console reads the
  index, the registries, and the ledgers it names — nothing else.
- **MCP6-INV5** — **honest rendering.** Every fact on screen derives from the files alone — no state
  is invented client-side; the verdicts, gates, tallies, and unknown prefixes shown are the same
  derivation `aaw_status` answers with; a re-launch over the same tree renders the same view.

## Definition of Done

- [ ] the read model re-reads the file plane through the store's read-only paths, mtime-guarded, and
      derives verdicts, gates, tallies, and unknown prefixes exactly as `aaw_status` does (MCP6-D1,
      MCP6-INV5).
- [ ] the `tea.Model` ships both views — the scope list and the scope detail (liveness table · gates
      panel · live-follow ledger tail · parse-health line) — refreshed by `tea.Tick`, styled by
      lipgloss (MCP6-D2).
- [ ] `aaw -workspace <dir> tui` works flags-first (L-5); the usage line names the mode; a non-TTY
      stdout refuses with usage, exit 2 (MCP6-D3).
- [ ] the go.mod delta is exactly the charm trio plus its transitives, pinned — the seam named, no
      fsnotify, no other addition (MCP6-D4, MCP6-INV2).
- [ ] the package holds no write API and acquires no lock; reads are unattributed and
      workspace-contained; the tree is byte-identical after any session (MCP6-D5, MCP6-INV1,
      MCP6-INV3, MCP6-INV4).
- [ ] pure-`Update` table tests, width-pinned `View` goldens over committed fixture trees, and the
      re-launch determinism case are green under `go test -race` (MCP6-D6, MCP6-INV5).
- [ ] the tool surface is unchanged (18); `aaw selftest` is green; `apps/mcp-go` is untouched — the
      live formation watched in the console is the demo (MCP6-INV2) — demoable.

Stories: ./mcp6.stories.md · Agent brief: ./mcp6.llms.md · Index: ./mcp.md · Roadmap: ../aaw.mcp.roadmap.md · Approach: ../../../elixir/specs/specs.approach.md
