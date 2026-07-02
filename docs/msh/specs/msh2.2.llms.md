# msh2.2 — the implementor brief

> Build to [msh2.2.md](./msh2.2.md) (the body wins; placement, arity, degrade order, status precedence,
> and the REVIEW-DUE contract are its §3). Boundary: `go/msh` + the fenced `memory/` backfill (spec §5).
> This brief + the spec carry every citation — first actions are writes, not a subsystem read. Read at
> most: `memory/command/corpus.go`, `memory/internal/frontmatter/parse.go`,
> `memory/internal/stale/rules.go`.

## References

Spec [msh2.2.md](./msh2.2.md) · design [§3 schema v2 (D-8) + §4 invariants](../msh.design.md) · roadmap
[msh2.2 row + S-2/S-4](../msh.roadmap.md) · gate ladders [program §3](../program/msh.program.md) (go-code
AND memory-data) · stories [msh2.2.stories.md](./msh2.2.stories.md).

## The touch set (each line verified 2026-07-02)

| File | Line(s) | Change |
|---|---|---|
| `go/msh/memory/internal/frontmatter/parse.go` | 10-15, 30-36, 74-85 | `Frontmatter` + `rawFrontmatter` gain `Project`, `Status`, `ReviewAfter` (strings; yaml tags `project`/`status`/`review_after`), TOP-LEVEL only — no `metadata:` coalesce for the three new keys (spec §3.1); old keys untouched |
| `go/msh/memory/internal/graph/node.go` | 22-34 | `Node` gains ``Project string `json:"project,omitempty"` `` + ``ReviewAfter string `json:"review_after,omitempty"` `` |
| `go/msh/memory/command/corpus.go` | 43-64 | in `loadCorpus`: effective project = normalized declared key → first path segment of `fe.RelPath` (slash-split) when nested → `""`; status precedence per spec §3.4 (valid declared wins; invalid → `FrontmatterError` + the `isSupersededByText` fallback; absent → fallback, byte-unchanged); `ReviewAfter` passthrough. Normalize = `strings.ToLower(strings.TrimSpace(…))` (the `classifyType` precedent, line 85) |
| `go/msh/memory/command/scan.go` | 41 | `--project` flag; filter `g.Nodes()` before render via one shared `filterNodesByProject(nodes, p)` helper in `command` |
| `go/msh/memory/command/stale.go` | 44-46, 55-57 | `--project` flag; POST-filter `findings` by the file's effective project (build the allowed-path set from `g.Nodes()`) — never pre-filter the graph (spec §3.3) |
| `go/msh/memory/command/ops.go` | 20, 80 | `Scan` + `Stale` grow a `project` param (empty = no filter); same helpers as the cobra paths |
| `go/msh/memory/command/ops.go` + `audit.go` | 118-140 · 33 | both `stale.Run` call sites pass the reference date (UTC today, day-truncated, computed once per invocation) |
| `go/msh/memory/internal/stale/rules.go` | 22-30, 32-42, 44 | `RuleReviewDue = "REVIEW-DUE"` const; `AllRules(ref time.Time)` + `Run(g, cfg, src, names, ref)`; the seven existing rule funcs unchanged (the review-due entry closes over `ref`) |
| `go/msh/memory/internal/stale/rule_review_due.go` | new | the rule per spec §3.5: parse `Node.ReviewAfter` (`2006-01-02`); due iff `!ref.Before(date)` → warn (File=path, Line=1, Target=date, message names date+ref); unparseable → error `invalid review_after`; skip `StatusSuperseded` nodes; skip empty |
| `go/msh/memory/command/audit.go` | 44 | exit trigger: DEAD-TARGET-only → ANY error-severity count > 0 (aligns to its own Long, line 17) |
| `go/msh/cmd/main.go` | 189-195, 201-204 | `staleArgs` + `scanArgs` gain `Project string json:"project,omitempty"` with a jsonschema line |
| `go/msh/cmd/main.go` | 227, 229, 249, 251 | descriptions name the new metadata + REVIEW-DUE; handlers pass `in.Project` through |
| `go/msh/memory/internal/render/pretty.go` | 15, 23 | `PrettyScan` gains a PROJECT column after STATUS |
| `go/msh/memory/internal/stale/stale_test.go` + `rules_extra_test.go` | (extend) | existing `Run` callers gain a FIXED ref date; G-6 golden fixture under `go/msh/memory/testdata/` (due / not-yet / boundary ref==date / invalid / superseded-skip) |
| `go/msh/memory/command/*_test.go` + `internal/frontmatter` tests | (extend) | G-1..G-5, G-7 homes; fixtures = temp dirs, never the live corpus |

No other file. `TestToolCountPin` (`cmd/mcp_test.go:236-263`) is NOT touched — it must pass as-is (G-8).
`memory_audit` stays unscoped. No `mcp-go` edit.

## The backfill sub-rung (staged; the script is never committed)

Order is law (the memory-data ladder, program §3; before-leg audit already recorded green — 71 files,
error=0 warn=0 info=1):

1. **Backup**: copy the whole `memory/` tree into the session scratchpad.
2. **Dry-run**: the scratchpad script walks notes (skip `MEMORY.md`), computes each slug, EMITS the full
   note→slug table + insertion previews. STOP — the Director reviews the table before apply.
3. **Apply**: insert `project: <slug>` immediately BEFORE each note's `metadata:` line (the
   corpus-uniform anchor — verified present in all 70 notes); text-insertion only, no YAML
   reserialization. ZERO `status:` / `review_after:` keys (spec §5 R-3/R-4: sniff census = 0, the one
   tombstone ruled active).
4. **Verify**: byte-diff = pure one-line frontmatter insertions; scan STATUS values byte-identical
   pre/post; `msh memory audit` after-leg = 0 errors, counts unchanged (G-10).
5. **Carve-out**: leave `memory/MEMORY.md`, `memory/mercury-design-system.md`,
   `memory/mercury-visual-regression-harness.md` OUT of the rung's staged commit (Operator's own
   `[memory]` batch carries their lines); `MEMORY.md` receives no edit at all.

Slugs: **R-1** dir notes = the directory name verbatim (`aaw` · `courses` · `echo_graft` · `echo_mq` ·
`elixir`). **R-2** flat notes = the primary program's docs-tree / ship-command slug; the closed
vocabulary: `mercury` · `codemojex` · `echo_mq` · `echo_graft` · `echo-courses` · `courses` · `elixir` ·
`aaw` · `msh` · `mcpd` · `go` · `figma-local` · `exchange` · `echo`. Guide: course notes → `courses`;
workspace/SDK notes (go.work, mcp-go) → `go`; BCS-umbrella notes without their own tree (echo-bot, mesh,
bcs, art) → `echo`; a straddler declares its PRIMARY program (spec §3.2). Ambiguous rows are the
Director's to rule at the dry-run review — do not guess silently.

## The gates (run before reporting)

```bash
cd go/msh
GOWORK=off go build -o "$TMPDIR/msh-gate" ./cmd   # NEVER bare ./...
GOWORK=off go vet ./...
GOWORK=off go test ./...
gofmt -l . | grep -v vendor                        # silence
make mcp                                           # repo root; then /mcp reconnect
# live smoke: memory_scan {project: "echo_mq"} → the echo_mq-scoped rows (G-9)
# backfill leg: the §5 runbook above, in order (G-10)
```

## Notes for the build

- Determinism: the rule NEVER calls `time.Now()`; only the two command entry points do (once, UTC,
  day-truncated). Goldens carry fixed dates and stay byte-stable forever.
- Filter normalization is TWO-sided (declared value at load, filter arg at entry) — the `corpus.go:85`
  precedent.
- The sniff (`corpus.go:125-142`) stays byte-identical — demoted to the absent-key path, never deleted.
- `walker` RelPaths are slash-separated; first segment = `strings.SplitN(rel, "/", 2)[0]` when nested.
- Finding order: `sortFindings` (`rules.go:68-81`) untouched; REVIEW-DUE findings sort with the rest.
- Fixtures: temp dirs per test; the live corpus is touched ONLY by the §5 runbook under the S-4 fence.
