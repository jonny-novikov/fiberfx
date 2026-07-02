# msh2.1 — anchor integrity (the rung spec)

> M1 · go-code · builds in the genesis run (D-1). Derives from [msh.design.md](../msh.design.md) §3
> (anchor v1.1, D-5) + §4 (invariants) and the [msh.roadmap.md](../msh.roadmap.md) msh2.1 row. Ruled
> read-only minimal (D-5). Stories: [msh2.1.stories.md](./msh2.1.stories.md); brief:
> [msh2.1.llms.md](./msh2.1.llms.md). Boundary: `go/msh` only. All cited lines verified 2026-07-02.

## §1 · Goal

Anchor integrity in three moves, read-only preserved (D-5): **(a)** ONE canonical config-marker spelling,
every legacy spelling still read through a deprecation window — the three-way wart dies at its root cause
(two independently-maintained name lists); **(b)** anchor schema v1.1 — `.msh-memory.json` gains an
optional, additive `docs_root`, parsed into the project info and reported by `memory_project` (tool + CLI);
**(c)** docstring sync — user-facing strings name only the canonical spelling and the v1.1 field. SHIPS:
honest root resolution from any directory; `memory_project` reports `docs_root`.

## §2 · The wart, grounded

Four sites spell the config marker three ways; **no file by any of these names exists on disk** (the
genesis census, [grounding §2](../kb/genesis/genesis.grounding.md)) — a zero-migration fix window.

| Site | Spelling(s) | Where |
|---|---|---|
| marker walk-up probe | `.msh.memory.yaml` · `msh.memory.yaml` | `go/msh/memory/command/root.go:163-174` (`hasMemoryMarker`) |
| rule-config loader | `msh-memory.yaml` · `.msh-memory.yaml` | `go/msh/memory/internal/config/config.go:41-44` (`Resolve` candidates) |
| CLI `--config` help | `msh.memory.yaml` + `.msh-memory.yaml` mixed in one string | `go/msh/memory/command/root.go:58` |
| MCP arg docstrings | `msh.memory.yaml` | `go/msh/cmd/main.go:187` (`auditArgs.Config`) · `go/msh/cmd/main.go:191` (`staleArgs.Config`) |

The `ResolveRoot` doc comment repeats the dot form (`go/msh/memory/command/root.go:85-90`); the resolution
ORDER itself is correct and stays untouched (§5).

## §3 · The canonical-spelling decision (rung-internal, decided here)

**Canonical: `.msh-memory.yaml`.** Grounding, in force order: (1) the live anchor is `.msh-memory.json`
(`go/msh/memory/command/project.go:15`) — the dash-dotted `.msh-memory.*` stem is the one family already
shipping, and one stem means one spelling rule for both anchor and config; (2) `.msh-memory.yaml` is already
a first-class loader candidate (`config.go:43`), so the choice breaks nothing that resolves today; (3) the
dotted form matches the anchor's hidden-file posture for repo-root machine files.

**The legacy set** — `msh-memory.yaml` (`config.go:42`), `msh.memory.yaml` and `.msh.memory.yaml`
(`root.go:167,170`). **Window semantics:** every legacy spelling keeps resolving, identically to the
canonical, in both the marker probe and the loader; no legacy name appears in any user-facing string; the
window closes only by a future Operator-ruled removal rung. The window is silent — no warning surface, no
logging change in this rung.

**The root cause dies structurally:** one shared candidate-name list, defined once (forward-tense: a
`MarkerNames`-style set in `memory/internal/config`, imported by `memory/command`) and consumed by BOTH the
marker probe and the loader. Probe set = `{MEMORY.md} ∪` the config set; loader set = the config set,
canonical first then legacy in one fixed order (`.msh-memory.yaml` → `msh-memory.yaml` →
`.msh.memory.yaml` → `msh.memory.yaml`); first hit wins, so a canonical file beats a coexisting legacy one.

## §4 · Deliverables

1. **The shared name list** (one authority): the candidate names defined once in `memory/internal/config`,
   consumed by `hasMemoryMarker` (`root.go:163-174`) and `Resolve` (`config.go:41-44`); order per §3.
2. **The probe recognizes the canonical + legacy set**; `MEMORY.md` stays a marker unchanged
   (`root.go:164`).
3. **The loader resolves canonical-first** in the §3 order; `--config` explicit path behavior unchanged
   (`config.go:34-40`).
4. **Anchor schema v1.1:** `MemoryConfig` (`project.go:34-39`) gains ``DocsRoot string
   `json:"docs_root,omitempty"` ``, top-level beside `root`; a relative value resolves against the anchor
   file's own directory (the `Root` precedent, `project.go:61-63`); `renderProject` (`project.go:85-111`)
   gains a `docs:` text line (unset → `-` via `orDash`); JSON carries the key via the tag (omitted unset).
5. **Docstring sync** to the canonical spelling + the v1.1 field: `root.go:58` (`--config` help),
   `root.go:85-90` (`ResolveRoot` comment), `main.go:187` + `main.go:191` (MCP arg schemas),
   `main.go:258-267` (`memory_project` description), `project.go:124-125` (cmd Short/Long).
6. **The tool-count pin test** (new; operationalizes design §4.4 for every later rung): `buildMCPServer`
   (`main.go:173-180`) registers exactly **8** tools — `memory_scan/graph/stale/audit/project`, `mint`,
   `specs`, `history_search`. This rung moves the count by zero.

## §5 · Invariants held

- **Read-only, verbatim (design §4.1).** No write surface added; the anchor stays hand-edited; neither the
  repo-root `.msh-memory.json` nor `memory/` is touched.
- **Resolution order unchanged (D-5).** `--root` → anchor → marker walk-up → typed error
  (`root.go:123-161`); the rung changes the marker NAME SET, never the order or the walk-up semantics.
- **Additive-minor (design §4.4).** v1.1 adds one optional key; no tool renamed, removed, or narrowed; the
  count stays 8 and becomes pinned. **One authority (§4.2):** the name list exists once — probe and loader
  cannot drift again. **Determinism (§4.3):** the candidate order is fixed in §3 and pinned by a test.

## §6 · Boundary + non-goals

Boundary: `go/msh` only (design §4.6). Non-goals, each already ruled or recorded: no `memory_project set`
and no multi-project anchor (deferred, D-5 — trigger: real worktree parallelism); no legacy-hit warning or
logging change (§3); no edit to the live repo-root anchor; no `memory/README.md` repair — its broader drift
is the frozen record's follow-on ([docs/go/msh roadmap](../../go/msh/msh.roadmap.md) §Seams 4), and a
spelling-only partial sync is worse than none; no frontmatter work (msh2.2).

## §7 · Gates (the closed list)

The go-code ladder ([program/msh.program.md](../program/msh.program.md) §3), verbatim:

```bash
cd go/msh
GOWORK=off go build -o "$TMPDIR/msh-gate" ./cmd   # NEVER bare ./... — cmd output collision
GOWORK=off go vet ./...
GOWORK=off go test ./...
gofmt -l . | grep -v vendor   # expect silence
make mcp                      # repo root: mcpd hot-swap :8899 — NEVER pkill a live server
# client /mcp reconnect → one live smoke call (memory_project)
```

Rung extras (each a test in the suite unless marked):

- **G-1** nested-dir walk-up regression: anchor resolution from a nested cwd is unchanged.
- **G-2** canonical-marker resolution: a directory holding only `.msh-memory.yaml` is a root marker.
- **G-3** legacy regression: each of `msh-memory.yaml`, `.msh.memory.yaml`, `msh.memory.yaml` still
  resolves — as a loader candidate and as a root marker.
- **G-4** precedence: canonical + legacy files coexisting → the canonical file is loaded.
- **G-5** `docs_root`: present (text + JSON), absent (dash / omitted), relative (anchor-dir resolution).
- **G-6** docstring grep: the dot-form spelling in NO user-facing string — only the shared list + tests.
- **G-7** the tool-count pin: exactly 8.
- **G-8** live smoke after `make mcp`: `memory_project` answers over MCP; `docs_root` reported against a
  fixture anchor (`-` against the live one until the Operator hand-adds the key).

## §8 · Traceability

| Deliverable | Stories | Gate |
|---|---|---|
| D1 shared name list | S-2, S-3, S-4 | G-2, G-3, G-4 |
| D2 probe set | S-2, S-3 | G-2, G-3 |
| D3 loader order | S-4 | G-4 |
| D4 anchor v1.1 `docs_root` | S-5, S-6, S-7 | G-5, G-8 |
| D5 docstring sync | S-9 | G-6 |
| D6 tool-count pin | S-8 | G-7 |
| (regression) resolution order | S-1 | G-1 |
