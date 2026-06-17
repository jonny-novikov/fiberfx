# MCP6 · user stories

> Who wants this, what they need, and how we will know it works — the acceptance face of the
> interactive-console rung (mcp6.md). Stories are split by audience: `US-D[N]` the developer (the
> human who runs and audits formations), `US-A[N]` the agent (the session peers whose ceremonies the
> console watches).

## MCP6-US-D1 — the formation watched live
As the developer running a formation, I want one console that renders the scopes, the per-agent
liveness, the gates, the ledger tail, and the parse health live from the file plane, so that watching
a run is one screen instead of N status calls and three open files.

Acceptance criteria
- Given an initialized workspace, when `aaw -workspace <dir> tui` launches on a TTY, then the scope
  list renders from `.aaw/scopes.json`, and selecting a scope renders the detail — the liveness table
  (agent · role · CCL-id · model · verdict · quiet), the gates panel (`z_eligible` plus the D/Z
  counts behind it), the ledger tail following the entries, and the parse-health line (unknown
  prefixes).
- Given a ceremony, append, or hand edit landing out-of-band, when the next `tea.Tick` re-read runs,
  then the change appears with no restart — files are truth, made visible.
- Given a non-TTY stdout, when the command runs, then it refuses with usage, exit 2.

INVEST — independent of mcp4–mcp5; testable by a fixture-tree launch, an out-of-band-edit tick case,
and the exit-2 assertion; encodes MCP6-INV5.
Priority: must · Size: 5 · Implements deliverables: MCP6-D1, MCP6-D2, MCP6-D3.

## MCP6-US-D2 — risk-free over any workspace
As the developer, I want the console session to be read-only and workspace-contained, so that
watching any corpus — including a live formation's — is risk-free.

Acceptance criteria
- Given any session over any workspace, when it ends, then the tree is byte-identical to before the
  session.
- Given the running console, when its reads are traced, then only paths under `-workspace` are
  opened — the index, the registries, and the ledgers it names, nothing else.

INVEST — independent; testable by a tree-hash comparison and a read-trace fixture; encodes MCP6-INV1,
MCP6-INV4.
Priority: must · Size: 2 · Implements deliverables: MCP6-D5.

## MCP6-US-A1 — ceremonies unimpeded
As an agent running a ceremony while the console watches, I want the console to hold no lock and
attribute no read, so that spawns, appends, and heartbeats proceed unimpeded and the liveness
evidence stays exactly what the agents declared.

Acceptance criteria
- Given a writer mid-ceremony, when the console ticks, then the writer never waits on the console (no
  lock acquired; read-only opens) and the read observes whole-or-old bytes, never torn — the mcp1
  atomic-write discipline.
- Given a console session over a scope, when the registry is compared before and after, then no
  `last_seen_at`, activity counter, or quiet window moved — the console's reads are unattributed.

INVEST — independent; testable by a concurrent writer-vs-tick case and a registry byte-comparison;
encodes MCP6-INV3.
Priority: must · Size: 3 · Implements deliverables: MCP6-D5.

## MCP6-US-A2 — one truth, two faces
As an agent whose status the developer watches, I want the console to render the same derivation
`aaw_status` answers with, so that the human view and the tool view never dispute.

Acceptance criteria
- Given a scope, when the detail view renders and `aaw_status` is read over the same tree state, then
  the verdicts with their winning sources, `z_eligible` with the D/Z counts, the per-prefix tallies,
  and the unknown prefixes agree — one derivation through the store's read paths, two faces.

INVEST — independent; testable by a parity assertion over a fixture tree; encodes MCP6-INV5.
Priority: must · Size: 2 · Implements deliverables: MCP6-D1.

## MCP6-US-D3 — the dependency seam, named and fenced
As the developer owning the dependency surface, I want the charm trio pinned and fenced as the rung's
only addition, so that the ladder's first third-party UI dependency is a ratified seam, not a
drive-by.

Acceptance criteria
- Given the rung's diff, when `go.mod` is compared to HEAD, then the delta is exactly the charm trio
  (bubbletea, bubbles, lipgloss) plus its transitives, pinned — no fsnotify, no other addition.
- Given `aaw selftest` after the rung, when it runs, then the tool count is still 18 and every schema
  is unchanged — the dependency is build-side only.

INVEST — independent; testable by a go.mod diff assertion and the selftest pin; encodes MCP6-INV2.
Priority: must · Size: 2 · Implements deliverables: MCP6-D4.

## MCP6-US-D4 — the views are pinned, not folklore
As the developer, I want the update logic and the rendered views pinned by tests and goldens, so that
a regression fails a test instead of silently mis-rendering the formation.

Acceptance criteria
- Given the committed fixture trees, when the golden test runs, then the width-pinned `View` renders
  match, and the table-driven `Update` cases pass with no I/O inside `Update` — the model update is
  pure.
- Given the same tree twice, when the console launches twice, then the two renders are identical —
  the re-launch determinism case — and the suite is green under `go test -race -count=1`.

INVEST — independent; testable by the goldens themselves; encodes MCP6-INV5.
Priority: must · Size: 3 · Implements deliverables: MCP6-D6.

---
Coverage: D1→US-D1,US-A2 · D2→US-D1 · D3→US-D1 · D4→US-D3 · D5→US-D2,US-A1 · D6→US-D4.  Spec: mcp6.md · Agent brief: mcp6.llms.md.
