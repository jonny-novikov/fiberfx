# msh — References

> The sources, conventions, and lineages the `msh` toolchain rests on, each cited at its as-built location or
> its external authority. Reverse mode: the code is canonical; where a convention below and the code disagree,
> the code wins. Grouped in four families: the memory-format convention the corpus follows, the branded-id
> lineage the codec inherits, the project-anchor schema, and the MCP transport.

---

## I. The memory-format convention

### 1. The `memory/` corpus — markdown notes with YAML frontmatter

The corpus is a flat directory of markdown notes, each opening with a YAML frontmatter block delimited by
`---\n` … `\n---\n`, plus a `MEMORY.md` index. `msh` walks it, parses the frontmatter, and builds a typed
cross-reference graph.

- **As-built:** the corpus at [`memory/`](../../../memory); the index [`memory/MEMORY.md`](../../../memory/MEMORY.md).
- **The parser contract:** four top-level fields — `name`, `description`, `type`, `originSessionId`
  ([`internal/frontmatter/parse.go:10`](../../../go/msh/memory/internal/frontmatter/parse.go)).
- **The classification:** `type` → one of seven node types, else a filename-heuristic fallback
  ([`command/corpus.go:84`](../../../go/msh/memory/command/corpus.go)).
- **The contract divergence:** the live corpus nests `type` under a `metadata:` map; the parser reads top-level.
  This is the surfaced design fork ([`./msh.design.md`](./msh.design.md) §8) — recorded, Operator to rule.

### 2. The seven stale rules

The detection vocabulary the toolchain reports: `DEAD-TARGET` · `DELETED-PATH` · `REMOVED-TOOL` ·
`BROKEN-ANCHOR` · `ORPHAN` · `SUPERSEDE-CYCLE` · `STALE-EXTERNAL`, each a file under `internal/stale/`.

- **As-built:** the named constants ([`internal/stale/rules.go:22`](../../../go/msh/memory/internal/stale/rules.go));
  the README rule table ([`memory/README.md:43`](../../../go/msh/memory/README.md)).
- **The default rule config:** `deleted_paths`, `removed_tools`, `context_whitelist_keywords`, `ignore_orphans`
  ([`internal/config/defaults.go:3`](../../../go/msh/memory/internal/config/defaults.go)).

### 3. The seven edge kinds

The cross-reference vocabulary: `md_link` · `md_link_anchor` · `external_rel` · `code_path` · `bare_mention` ·
`anchor_only` · `cross_subdir` ([`internal/graph/edge.go:5`](../../../go/msh/memory/internal/graph/edge.go);
classified at [`internal/linkx/classifier.go:9`](../../../go/msh/memory/internal/linkx/classifier.go)).

---

## II. The branded-id lineage

### 4. brd14 — the branded snowflake contract

The id format `mint` produces: a 3-byte uppercase namespace + an 11-char Base62 payload over a
`ts(41) | node(10) | seq(12)` snowflake, fixed length 14, epoch `2024-01-01T00:00:00Z`
(`EpochMs = 1_704_067_200_000` — [`brandedid/brandedid.go:18`](../../../go/msh/brandedid/brandedid.go)).
Time-ordered (sorts by mint) and coordination-free (mint on any host, no registry).

### 5. The vendored codec — `dev/echo_data/runtimes/go/brandedid`

The codec (`Encode`/`Parse`/`Decode`/`Valid`/`Hash32`/`UnixMs`/`Time`/`MinFor`) is vendored **verbatim** from
the canonical reference at `dev/echo_data/runtimes/go/brandedid`, whose contract "travels as test vectors, not
as a shared object" — `brandedid_test.go` re-asserts those vectors so this copy can never drift
([`brandedid/brandedid.go:6`](../../../go/msh/brandedid/brandedid.go);
[`brandedid/brandedid_test.go`](../../../go/msh/brandedid/brandedid_test.go)).

### 6. The minter — a port of `EchoData.Snowflake`

The lock-free snowflake `Generator` (a single atomic cell that CAS-advances `max(now, last+1)`, monotone under
same-ms and backward-clock) ports the Elixir `EchoData.Snowflake`; the node id (0..1023) derives from the
hostname (fallback pid) with no coordination
([`brandedid/snowflake.go:18`](../../../go/msh/brandedid/snowflake.go)). The BCS branded-id contract is taught
in the `/bcs` course (App. F, the canon) — the wider lineage frames the id as the type checked at every
boundary.

---

## III. The project anchor

### 7. `.msh-memory.json` — the per-project anchor

A JSON file (walk-up from cwd) that pins the corpus `root` and carries the active program's development context:
`project.{name, code, roadmap, state.{status, current_rung}}`
([`command/project.go:34`](../../../go/msh/memory/command/project.go)). It is the highest-precedence input to
root resolution after an explicit `--root` ([`command/root.go:138`](../../../go/msh/memory/command/root.go)) and
the sole source for the `project` surface. A relative `root` resolves against the file's own directory. The
schema is reproduced in [`./msh.design.md`](./msh.design.md) §3.1.

---

## IV. The MCP transport

### 8. mcp-go — streamable-HTTP MCP server

The server is built on `github.com/fiberfx/mcp-go/v2`, replaced to the sibling module `../mcp-go`
([`go/msh/go.mod:23`](../../../go/msh/go.mod)). It serves over a `NewStreamableHTTPHandler` on
`localhost:<port>` (default `8899`) or a `StdioTransport` with `--stdio`
([`cmd/main.go:135`](../../../go/msh/cmd/main.go)). The server identifies as `{Name: "msh", Version: "0.1.0"}`
([`cmd/main.go:171`](../../../go/msh/cmd/main.go)) and registers seven tools via `AddTool`. A client wires it in
`.mcp.json` as `{"type": "streamable-http", "url": "http://localhost:8899/"}`.

### 9. The Model Context Protocol

The protocol the tools speak. Tool args are declared as Go structs with `jsonschema` tags
([`cmd/main.go:180`](../../../go/msh/cmd/main.go)); each handler returns a `CallToolResult` of text content. The
running server is supervised beside `aaw` by the `mcpd` controller — named in [`./msh.design.md`](./msh.design.md)
§1, owned by its own tree.

- Model Context Protocol — [modelcontextprotocol.io](https://modelcontextprotocol.io)

---

## Internal canon

- The binding design: [`./msh.design.md`](./msh.design.md) · the roadmap: [`./msh.roadmap.md`](./msh.roadmap.md)
  · the dashboard: [`./msh.progress.md`](./msh.progress.md) · the features: [`./msh.features.md`](./msh.features.md)
  · the testing view: [`./msh.testing.md`](./msh.testing.md).
- The reverse-mode discipline (code canonical): [`../../aaw/aaw.reverse.md`](../../aaw/aaw.reverse.md); the rules
  + delta taxonomy: [`../../aaw/aaw.rules.md`](../../aaw/aaw.rules.md); the architect's four-part arm:
  [`../../aaw/aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md); the workflow:
  [`../../aaw/aaw.framework.md`](../../aaw/aaw.framework.md).
- The shared Go-server operating manual: [`../program/go.program.md`](../program/go.program.md). The build guide:
  [`/Users/jonny/dev/jonnify/go/CLAUDE.md`](../../../go/CLAUDE.md).
- The as-built README: [`go/msh/memory/README.md`](../../../go/msh/memory/README.md) (pre-restructure; see
  [`./msh.roadmap.md`](./msh.roadmap.md) §Seams 4 for the recorded drift).
