# msh2.1 — the implementor brief

> Build to [msh2.1.md](./msh2.1.md) (the body wins; the canonical spelling + candidate order are its §3).
> Boundary: `go/msh` only. This brief + the spec carry every citation — first actions are writes, not a
> subsystem read. Read at most: `memory/command/root.go`, `memory/command/project.go`,
> `memory/internal/config/config.go`.

## References

Spec [msh2.1.md](./msh2.1.md) · design [§3 anchor v1.1 + §4 invariants](../msh.design.md) · roadmap
[msh2.1 row](../msh.roadmap.md) · gate ladder [program §3](../program/msh.program.md).

## The touch set (each line verified 2026-07-02)

| File | Line(s) | Change |
|---|---|---|
| `go/msh/memory/internal/config/config.go` | 41-44 | replace the inline candidate pair with the shared name list, canonical-first order (spec §3): `.msh-memory.yaml` → `msh-memory.yaml` → `.msh.memory.yaml` → `msh.memory.yaml`; define the list ONCE here (exported, e.g. `MarkerNames() []string`), explicit `--config` path (33-40) unchanged |
| `go/msh/memory/command/root.go` | 163-174 | `hasMemoryMarker` probes `MEMORY.md` (unchanged, 164) + every shared-list name via the config import |
| `go/msh/memory/command/root.go` | 58 | `--config` help → the canonical spelling only |
| `go/msh/memory/command/root.go` | 85-90 | `ResolveRoot` comment → canonical spelling |
| `go/msh/memory/command/project.go` | 34-39 | `MemoryConfig` gains ``DocsRoot string `json:"docs_root,omitempty"` `` (top-level, beside `Root`) |
| `go/msh/memory/command/project.go` | 61-63 | resolve a relative `DocsRoot` against the anchor's dir (mirror the `Root` block) |
| `go/msh/memory/command/project.go` | 92-97 | `renderProject` text gains `docs:` line via `orDash(mc.DocsRoot)` (JSON needs nothing — the tag carries it) |
| `go/msh/memory/command/project.go` | 124-125 | `project` cmd Short/Long mention `docs_root` |
| `go/msh/cmd/main.go` | 187, 191 | `auditArgs`/`staleArgs` `Config` jsonschema → canonical spelling |
| `go/msh/cmd/main.go` | 258-267 | `memory_project` tool description mentions `docs_root` |
| `go/msh/memory/internal/config/config_test.go` | (extend) | G-2/G-3/G-4: canonical resolves, each legacy resolves, canonical wins |
| `go/msh/memory/command/project_test.go` | (extend) | G-5: `docs_root` present/absent/relative (S-5/6/7) |
| `go/msh/cmd/mcp_test.go` | (extend) | G-7: the NEW tool-count pin — `buildMCPServer` (main.go:173-180) registers exactly 8 |
| marker tests | `memory/command` (extend an existing `_test.go`) | G-1 nested-dir regression + G-2/G-3 marker-side cases (`hasMemoryMarker` is unexported — test in-package) |

No other file. No `memory/` edit, no repo-root anchor edit, no `mcp-go` edit, no README repair (spec §6).

## The gates (run before reporting)

```bash
cd go/msh
GOWORK=off go build -o "$TMPDIR/msh-gate" ./cmd   # NEVER bare ./...
GOWORK=off go vet ./...
GOWORK=off go test ./...
gofmt -l . | grep -v vendor                        # silence
grep -rn "msh\.memory\.yaml" --include='*.go' .    # hits ONLY in the shared list + its tests (G-6)
make mcp                                           # repo root; then /mcp reconnect + memory_project smoke
```

## Notes for the build

- One authority: the name list exists exactly once; probe = `{MEMORY.md} ∪ list`, loader = list order.
- `memory/command` already imports sibling internals; importing `memory/internal/config` from `root.go` is
  legal (same module, `internal/` under `memory/`).
- Read-only: no write path anywhere; the deprecation window is silent (no logging change).
- Fixtures: temp dirs per test; never the live repo-root `.msh-memory.json`.
