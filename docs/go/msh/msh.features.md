# msh — the feature catalog (the as-built capability surface)

> A canon-level companion to [`./msh.design.md`](./msh.design.md) (the binding design) and
> [`./msh.roadmap.md`](./msh.roadmap.md) (the delivery plan). This file CATALOGS every shipped `msh` capability
> in one place, with the surface each exposes (CLI command, MCP tool, the facade) and its as-built location.
> Grounding law (NO-INVENT): every reference is a real surface verified at its `file:line`; voice tracks status
> — SHIPPED reads present-tense, Phase 2 reads forward-tense. The code is canonical
> ([the reverse playbook](../../aaw/aaw.reverse.md)).

Verified against the as-built tree 2026-06-18 ([`go/msh/`](../../../go/msh)). Status legend: **✅ shipped** ·
**🔒 deferred** (Phase 2, config-carried, not consumed).

---

## The feature set

Each feature is one operation exposed over both surfaces — the cobra CLI and the MCP server — through a single
`memory/command` (or `brandedid`) facade ([`./msh.design.md`](./msh.design.md) §7).

### scan — per-note metadata ✅

Walks the corpus and dumps one record per note: frontmatter `name`/`type`/`description`, byte size, and the
SHA-256 of the body. The walker keeps `.md` files, skips dot-directories, and sorts by relative path
([`internal/walker/walker.go:17`](../../../go/msh/memory/internal/walker/walker.go)); the node carries the
parsed frontmatter and a supersession flag derived from body text
([`command/corpus.go:42`](../../../go/msh/memory/command/corpus.go)).

- **CLI:** `msh memory scan [--format ndjson|pretty]`
- **MCP:** `memory_scan` (args: `root?`, `format?`) — [`cmd/main.go:243`](../../../go/msh/cmd/main.go)
- **Facade:** `command.Scan/2` · render `internal/render/{ndjson,pretty}.go`

### graph — the cross-reference graph ✅

Builds the full node + edge graph and emits it as JSON or GraphViz dot. Links are extracted by `linkx` and
classified into the **seven edge kinds** (`md_link` · `md_link_anchor` · `external_rel` · `code_path` ·
`bare_mention` · `anchor_only` · `cross_subdir` — [`internal/graph/edge.go:5`](../../../go/msh/memory/internal/graph/edge.go));
`ResolveEdges` marks which land on a node. `--include_external` opts the `external_rel` edges into the render.

- **CLI:** `msh memory graph [--format json|dot] [--out FILE]`
- **MCP:** `memory_graph` (args: `root?`, `format?`, `include_external?`) — [`cmd/main.go:232`](../../../go/msh/cmd/main.go)
- **Facade:** `command.Graph/3` · render `internal/graph/{render_json,render_dot}.go`

### stale — the seven detection rules ✅

Runs the stale engine: the closed, named set of seven rules
([`internal/stale/rules.go:22`](../../../go/msh/memory/internal/stale/rules.go)) over the graph, with
paragraph-level deletion-context whitelisting that downgrades or suppresses a finding sitting in prose that
itself cites a deletion ([`internal/stale/context.go`](../../../go/msh/memory/internal/stale/context.go)).
Findings sort stably by file/line/rule/target.

| Rule | Trigger (one line) | Default severity |
|---|---|---|
| `DEAD-TARGET` | an internal `.md` link target resolves to no node | error |
| `DELETED-PATH` | a `code_path` matches a `deleted_paths` glob | error → warn whitelisted |
| `REMOVED-TOOL` | a bare/inline token matches a `removed_tools` name | warn → info whitelisted |
| `BROKEN-ANCHOR` | a link resolves, but its `#anchor` matches no heading there | warn |
| `ORPHAN` | a non-index node has zero incoming edges | info |
| `SUPERSEDE-CYCLE` | two `superseded` nodes cite each other | warn |
| `STALE-EXTERNAL` | a non-http `external_rel` reference resolves to no file on disk | warn |

- **CLI:** `msh memory stale [--rules all|NAME,…] [--severity error|warn|info] [--format ndjson|pretty]`
- **MCP:** `memory_stale` (args: `root?`, `config?`, `rules?`, `severity?`, `format?`) — [`cmd/main.go:221`](../../../go/msh/cmd/main.go)
- **Facade:** `command.Stale/5` · engine `stale.Run/4`

### audit — the composite gate ✅

Composite scan + stale + summary: node count, per-rule finding counts, and the warn+ findings; intended for CI
with a non-zero exit on errors ([`memory/README.md:22`](../../../go/msh/memory/README.md)).

- **CLI:** `msh memory audit [--max-warn N]`
- **MCP:** `memory_audit` (args: `root?`, `config?`) — [`cmd/main.go:210`](../../../go/msh/cmd/main.go)
- **Facade:** `command.Audit/2`

### project — the active development context ✅

Reads the nearest `.msh-memory.json` (walk-up from cwd) and reports the active program's `name`, `code`,
`roadmap`, `status`, `current_rung`, and the resolved corpus root — orienting an agent to what is being built
([`command/project.go:77`](../../../go/msh/memory/command/project.go)). The anchor schema is in
[`./msh.design.md`](./msh.design.md) §3.1.

- **CLI:** `msh memory project [--format text|json]`
- **MCP:** `memory_project` (args: `format?`) — [`cmd/main.go:254`](../../../go/msh/cmd/main.go)
- **Facade:** `command.ProjectInfo/1`

### specs — the cross-area stale-link checker ✅

A deliberately distinct link engine for a docs/specs tree (not the flat corpus): it resolves every relative
markdown link to the **real filesystem**, so a cross-area link (`../aaw/x.md`, `../../echo/…`) is validated
wherever it points — and emits the same `Finding` vocabulary (DEAD-TARGET for a missing file, BROKEN-ANCHOR for
a missing heading), skipping off-site `http(s)`/`mailto`/`tel`/site-absolute targets
([`internal/speclint/speclint.go:1`](../../../go/msh/memory/internal/speclint/speclint.go)). The area is a path,
a name resolved under `<repo>/<base>/<area>` (base `docs`), or — empty — the active project's `name` from
`.msh-memory.json`.

- **CLI:** `msh specs [AREA] [--base docs] [--format pretty|ndjson|audit] [--severity error|warn|info]`
- **MCP:** `specs` (args: `area?`, `base?`, `format?`, `severity?`) — [`cmd/specs.go:61`](../../../go/msh/cmd/specs.go)
- **Facade:** `command.SpecsLinks/4` · engine `speclint.Check/2`

### mint — brd14 branded snowflake ids ✅

Mints time-ordered, coordination-free branded ids: a 3-letter uppercase namespace + 11 Base62 over a
`ts(41)|node(10)|seq(12)` snowflake (epoch `2024-01-01Z`). The codec is vendored verbatim from
`dev/echo_data/runtimes/go/brandedid` ([`brandedid/brandedid.go:6`](../../../go/msh/brandedid/brandedid.go)); the
minter ports `EchoData.Snowflake` — a lock-free atomic cell, monotone under same-ms and backward-clock
([`brandedid/snowflake.go:24`](../../../go/msh/brandedid/snowflake.go)). Text output is one id per line; the
structured formats emit the decoded record (id, ns, snowflake, unix_ms, time, node, seq).

- **CLI:** `msh mint [NS] [--ns NS] [-f text|json|ndjson|csv|yaml] [-n COUNT] [--node 0..1023]`
- **MCP:** `mint` (args: `ns`, `count?`, `node?`, `format?`) — [`cmd/mint.go:181`](../../../go/msh/cmd/mint.go)
- **Facade:** `brandedid.{Encode,Generator}`

### mcp serve / start / stop / restart — the server lifecycle ✅

Runs and manages the MCP server: `serve` foregrounds streamable HTTP on `localhost:8899` (default
`defaultMCPPort` — [`cmd/main.go:45`](../../../go/msh/cmd/main.go)) or stdio with `--stdio`; `start` detaches
into its own session with a pidfile/logfile under `os.TempDir()`; `stop`/`restart` manage that pid
([`cmd/main.go:291`](../../../go/msh/cmd/main.go)). Registered in a client `.mcp.json` as
`{"type":"streamable-http","url":"http://localhost:8899/"}`.

- **CLI:** `msh mcp {serve [--stdio] | start | stop | restart} [--port 8899] [--root P]`
- **Facade:** `buildMCPServer/1` → `registerMemoryTools` + `registerMintTool` + `registerSpecsTool`

### version — build metadata (CLI only) ✅

Prints `msh-memory <version> (commit …, built …)` with link-time-overridable defaults (`"dev"` unset —
[`command/run.go:21`](../../../go/msh/memory/command/run.go)). Distinct from the MCP server's self-reported
`Version: "0.1.0"` ([`cmd/main.go:45`](../../../go/msh/cmd/main.go)) — see [`./msh.roadmap.md`](./msh.roadmap.md)
§Seams 5.

---

## Deferred — Phase 2 (forward-tense) 🔒

**Semantic-similarity enrichment.** The `hugot` config block (endpoint `http://localhost:8902`, model, timeout)
and the `similarity` block (default threshold `0.85`, top-k `5`) are parsed and merged today
([`internal/config/defaults.go:38`](../../../go/msh/memory/internal/config/defaults.go),
[`internal/config/config.go:22`](../../../go/msh/memory/internal/config/config.go)) but are consumed by no
shipped rule — they are carriers for a planned similarity pass over note bodies. The README's architecture note
names an `internal/hugot/` directory as the Phase-2 placeholder
([`memory/README.md:75`](../../../go/msh/memory/README.md)); that directory is **not** in the current tree (the
config keys are the only Phase-2 surface today). Forward-tense: the roadmap plans this as rung msh.P2; it is
not slotted ([`./msh.roadmap.md`](./msh.roadmap.md) §Seams 2).

---

The binding design: [`./msh.design.md`](./msh.design.md). The roadmap: [`./msh.roadmap.md`](./msh.roadmap.md).
The dashboard: [`./msh.progress.md`](./msh.progress.md). The testing view: [`./msh.testing.md`](./msh.testing.md).
The references: [`./msh.references.md`](./msh.references.md).
