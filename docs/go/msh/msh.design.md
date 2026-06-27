# msh — the design (the as-built source of truth)

> A REVERSE-MODE specification: the code in [`go/msh/`](../../../go/msh) is canonical and this document is
> derived from it ([the reverse playbook](../../aaw/aaw.reverse.md) — the code wins on every surface fact). Every
> surface cited below is verified at its `file:line` in the tree as of 2026-06-18; where this document and the
> code disagree, the code is correct and this document is the defect. Shipped surface is written present-tense;
> the one genuinely-unbuilt arm (Phase 2) is written forward-tense. The delivery view is in
> [`./msh.roadmap.md`](./msh.roadmap.md); the as-built dashboard in [`./msh.progress.md`](./msh.progress.md).

## 0 · Genesis — what msh is and why it exists

`msh` is the toolchain and MCP server for the `memory/` corpus: the directory of markdown notes a Claude agent
keeps as durable cross-session memory (the corpus at [`memory/`](../../../memory), anchored by its
`MEMORY.md` index). The corpus is plain markdown with YAML frontmatter; left untended it rots — a note links a
file that has been deleted, names an MCP tool that was unregistered, or supersedes another note that supersedes
it back. `msh` walks the corpus, builds a typed cross-reference graph, and detects that rot through seven
context-aware rules, so an agent (or CI) can audit the memory it stands on instead of trusting it blind.

The module is `github.com/jonny-novikov/msh` ([`go/msh/go.mod:1`](../../../go/msh/go.mod), `go 1.25.0`), one
self-contained Go module. It vendors the MCP transport from a sibling (`replace
github.com/fiberfx/mcp-go/v2 => ../mcp-go`, [`go/msh/go.mod:23`](../../../go/msh/go.mod)) and the branded-id
codec from `dev/echo_data/runtimes/go/brandedid` (re-asserted by test vectors so the copy cannot drift —
[`brandedid/brandedid.go:6`](../../../go/msh/brandedid/brandedid.go)). It ships **two surfaces over one
implementation**: a cobra CLI and an MCP server, both routed through the `memory/command` package (§7). Phase 1
(the graph + stale MVP) is built; Phase 2 (semantic-similarity enrichment) is deferred
([`memory/README.md:9`](../../../go/msh/memory/README.md)).

## 1 · Purpose & scope

**In scope.** The `msh` binary built from [`cmd/main.go`](../../../go/msh/cmd/main.go): the `memory` toolchain
(scan · graph · stale · audit · project · version), the `mint` branded-id minter, the `specs` stale-link
checker, and the MCP server that serves the same operations as tools over streamable HTTP. The corpus model,
the root-resolution order, the frontmatter contract, the graph model, the seven stale rules, and the brandedid
codec — each specified against its as-built location.

**Out of scope.** The consumers of the running server (the `.mcp.json` client wiring, the `mcpd` controller
that supervises this binary beside `aaw`) are named where they bear on a surface but are not specified here —
they are owned by their own trees. The `memory/` corpus *content* is data the tool operates on, not part of the
tool. Phase 2 enrichment (the `hugot`/similarity config keys carried but unused — §6) is forward-tense only.

## 2 · The corpus model

The corpus is a directory tree of markdown notes. `msh` reads it through three layers:

- **The notes** — every `*.md` file under the root. The walker (`walker.WalkMarkdown/1` —
  [`internal/walker/walker.go:17`](../../../go/msh/memory/internal/walker/walker.go)) does a `filepath.WalkDir`,
  keeps `.md` files (case-insensitive), **skips any dot-directory** below the root, and returns entries sorted by
  relative slash-path. Each note becomes one graph node.
- **The `MEMORY.md` index** — the corpus' table of contents and a **root marker** (§3). It is classified as a
  `NodeIndex` and exempted from the orphan rule, since by design nothing links *to* the index
  ([`command/corpus.go:101`](../../../go/msh/memory/command/corpus.go),
  [`internal/stale/rule_orphan.go:16`](../../../go/msh/memory/internal/stale/rule_orphan.go)).
- **The `.msh-memory.json` anchor** — a per-project file that pins the corpus root and carries the active
  program's development context (§3, §3.1). It is the highest-precedence root source and the sole input to the
  `project` surface.

## 3 · Root resolution (`ResolveRoot`)

A single resolution order decides which directory is the corpus, shared by the CLI and the MCP server so both
resolve the corpus identically (`command.ResolveRoot/1` →`resolveRoot/1` —
[`command/root.go:88`](../../../go/msh/memory/command/root.go), [`:123`](../../../go/msh/memory/command/root.go)):

1. **`--root` flag** (or the tool-call `root` override) — if non-empty, made absolute and `os.Stat`-checked; an
   unreadable explicit root is an error, not a fallback.
2. **`.msh-memory.json` `root`** — `LoadMemoryConfig("")` walks up from the cwd for the anchor file
   ([`command/project.go:44`](../../../go/msh/memory/command/project.go)); a relative `root` in it is resolved
   against the file's own directory. It takes precedence over the `MEMORY.md` marker below.
3. **The marker walk-up** — from the cwd, ascend until a directory holds a memory marker: `MEMORY.md`,
   `msh.memory.yaml`, or `.msh.memory.yaml` (`hasMemoryMarker/1` —
   [`command/root.go:163`](../../../go/msh/memory/command/root.go)). The first match is the root.
4. **No root found** — the walk reaches the filesystem boundary and returns the typed `errRootRequired` usage
   error (exit code 2 — [`command/root.go:157`](../../../go/msh/memory/command/root.go)).

> Note (recorded, not corrected — code wins): the *config-file* candidate set in
> [`internal/config/config.go:42`](../../../go/msh/memory/internal/config/config.go) looks for
> `<root>/msh-memory.yaml` then `<root>/.msh-memory.yaml`, whereas the root *marker* probe looks for
> `msh.memory.yaml` / `.msh.memory.yaml` (dot before `memory`). The two filename spellings are independent
> (one names the root, one names the rule config) and both are as-built; a future rung may reconcile the
> spellings, but neither is wrong today.

### 3.1 · The `.msh-memory.json` schema

The anchor parses into `MemoryConfig` ([`command/project.go:34`](../../../go/msh/memory/command/project.go)):

```text
{
  "root":    "<absolute or file-relative corpus path>",
  "project": {
    "name":    "<program name, e.g. echo_mq>",
    "code":    "<short code, e.g. emq>",
    "roadmap": "<roadmap filename>",
    "state":   { "status": "<e.g. in_progress>", "current_rung": "<e.g. emq.4.1>" }
  }
}
```

The `project` block is the development context an agent reads to orient itself to what is being built. It is
surfaced by `command.ProjectInfo/1` ([`command/project.go:77`](../../../go/msh/memory/command/project.go)) as
text (default) or JSON, behind both `msh memory project` and the `memory_project` tool. When no anchor is found
the surface reports that plainly rather than erroring.

## 4 · The frontmatter contract

A note may open with a YAML frontmatter block delimited by `---\n` … `\n---\n`. The parser
(`frontmatter.Parse/1` — [`internal/frontmatter/parse.go:26`](../../../go/msh/memory/internal/frontmatter/parse.go))
returns whether a block is present, the body offset, any YAML error, and the decoded `Frontmatter` struct. That
struct reads four **top-level** fields ([`internal/frontmatter/parse.go:10`](../../../go/msh/memory/internal/frontmatter/parse.go)):

```text
name             yaml:"name"
description      yaml:"description"
type             yaml:"type"
originSessionId  yaml:"originSessionId"
```

`name`, `description`, and `originSessionId` flow onto the node; `type` is fed to `classifyType/2`
([`command/corpus.go:84`](../../../go/msh/memory/command/corpus.go)), which maps the lowercased value to one of
seven node types (`feedback` · `project` · `reference` · `law` · `session_pause` · `index`), and — when the
field is empty or unrecognized — falls back to **filename heuristics** (`MEMORY.md`/`completed-projects.md`
→ index; a `law…` / `session_pause…` / `feedback_…` / `project_…` / `reference_…` prefix → the matching type;
otherwise `unknown`).

This contract carries one genuine design fork against the live corpus — surfaced in §8.

## 5 · The graph model

`loadCorpus/1` ([`command/corpus.go:23`](../../../go/msh/memory/command/corpus.go)) builds a `graph.Graph` of
nodes and edges, then calls `ResolveEdges` to mark which edges land on a node.

### 5.1 · Nodes

A `Node` ([`internal/graph/node.go:22`](../../../go/msh/memory/internal/graph/node.go)) carries its relative
path, type (the seven `NodeType` values + `unknown` — [`:5`](../../../go/msh/memory/internal/graph/node.go)),
name, description, `originSessionId`, a status (`active` | `superseded`), byte size, a frontmatter-present flag,
any frontmatter error, and the SHA-256 of the file body. **Supersession** is detected from body text, not
frontmatter: `isSupersededByText/2` ([`command/corpus.go:125`](../../../go/msh/memory/command/corpus.go)) scans
the first 1024 bytes of the body for `(superseded` / `[superseded` / `> superseded` markers.

### 5.2 · The seven edge kinds

Links are extracted by `linkx` and classified into seven `EdgeKind` values
([`internal/graph/edge.go:5`](../../../go/msh/memory/internal/graph/edge.go); the classifier is
[`internal/linkx/classifier.go:9`](../../../go/msh/memory/internal/linkx/classifier.go)):

| Edge kind | Meaning |
|---|---|
| `md_link` | a same-corpus markdown link to a bare `file.md` (no slash, no anchor) |
| `md_link_anchor` | a same-corpus markdown link carrying a `#anchor` |
| `external_rel` | a `../` · `./` · `http(s)://` · or other-subdir target — reaches outside the flat corpus |
| `code_path` | a repository code path mentioned in the prose (e.g. `apps/…`) |
| `bare_mention` | a bare token mention (an unfenced tool/name reference) |
| `anchor_only` | an empty or `#…`-only target — a same-file anchor |
| `cross_subdir` | a `topics/…` link into a known corpus subdirectory |

Each `Edge` also records the source line/column, a snippet, the resolved target, and whether it sat in a code
block or a deletion context — the masks the stale rules read
([`internal/graph/edge.go:15`](../../../go/msh/memory/internal/graph/edge.go); the code-block masker is
[`internal/linkx/codeblock.go`](../../../go/msh/memory/internal/linkx/codeblock.go)).

### 5.3 · Rendering

The graph renders as JSON (`render_json.go`) or GraphViz dot (`render_dot.go`); per-note metadata renders as
NDJSON or a pretty table (`internal/render/{ndjson,pretty}.go`). `graph --include_external` opts the
`external_rel` edges into the rendered graph
([`cmd/main.go:235`](../../../go/msh/cmd/main.go), [`command/graph.go`](../../../go/msh/memory/command/graph.go)).

## 6 · The seven stale rules

The stale engine (`stale.Run/4` — [`internal/stale/rules.go:44`](../../../go/msh/memory/internal/stale/rules.go))
applies a fixed set of seven rules, named by exported constants
([`:22`](../../../go/msh/memory/internal/stale/rules.go)), and sorts findings by file/line/rule/target. Each
rule is one file under `internal/stale/`. The whitelisting layer is paragraph-level deletion context: a finding
inside prose that itself cites a deletion (keywords `deleted` · `removed` · `superseded` · `legacy` … —
[`internal/config/defaults.go:24`](../../../go/msh/memory/internal/config/defaults.go)) is downgraded or
suppressed (`stale.DeletionContext` — [`internal/stale/context.go`](../../../go/msh/memory/internal/stale/context.go)).

| Rule | Trigger | Severity | Source |
|---|---|---|---|
| **DEAD-TARGET** | an internal markdown-link target ending `.md` resolves to no node in the graph | error | [`rule_dead_target.go:11`](../../../go/msh/memory/internal/stale/rule_dead_target.go) |
| **DELETED-PATH** | a `code_path` edge matches a `deleted_paths` glob (e.g. `apps/mcp/**`) | error → warn if whitelisted | [`rule_deleted_path.go:11`](../../../go/msh/memory/internal/stale/rule_deleted_path.go) |
| **REMOVED-TOOL** | a bare-mention or inline-code token matches a `removed_tools` name (e.g. `tool_x`, `llms_parse`) | warn → info if whitelisted | [`rule_removed_tool.go:13`](../../../go/msh/memory/internal/stale/rule_removed_tool.go) |
| **BROKEN-ANCHOR** | a markdown link resolves to a node, but its `#anchor` matches no heading slug there | warn | [`rule_broken_anchor.go`](../../../go/msh/memory/internal/stale/rule_broken_anchor.go) |
| **ORPHAN** | a non-index node has zero incoming edges and is not in `ignore_orphans` | info | [`rule_orphan.go:8`](../../../go/msh/memory/internal/stale/rule_orphan.go) |
| **SUPERSEDE-CYCLE** | two `superseded` nodes cite each other | warn | [`rule_supersede_cycle.go:10`](../../../go/msh/memory/internal/stale/rule_supersede_cycle.go) |
| **STALE-EXTERNAL** | an `external_rel` (non-http) relative reference resolves to no file on disk | warn | [`rule_stale_external.go:12`](../../../go/msh/memory/internal/stale/rule_stale_external.go) |

The default config (`config.Defaults/0` — [`internal/config/defaults.go:3`](../../../go/msh/memory/internal/config/defaults.go))
ships the `deleted_paths`, `removed_tools`, `context_whitelist_keywords`, and `ignore_orphans` lists, plus
`hugot` and `similarity` blocks that are **Phase-2 carriers** — parsed and merged today, consumed by nothing in
the shipped rules. Config resolution is `--config` → `<root>/msh-memory.yaml` → `<root>/.msh-memory.yaml` →
baked defaults (`config.Resolve/2` — [`internal/config/config.go:33`](../../../go/msh/memory/internal/config/config.go)).

### 6.1 · The `specs` checker — a second link engine, on purpose

`speclint.Check/2` ([`internal/speclint/speclint.go:38`](../../../go/msh/memory/internal/speclint/speclint.go))
is a deliberately distinct engine for a docs/specs tree (not the flat corpus). Where the memory rules validate
links against graph *membership* — and `linkx` classifies any `../` or `subdir/file.md` target as
`external_rel` — speclint resolves every relative link to the **real filesystem**, so a cross-area link
(`../aaw/x.md`, `../../echo/…`) is validated wherever it points
([`internal/speclint/speclint.go:1`](../../../go/msh/memory/internal/speclint/speclint.go)). It reuses `linkx`
for extraction and emits the same `stale.Finding` vocabulary (DEAD-TARGET for a missing file, BROKEN-ANCHOR for
a missing heading). Off-site targets — `http(s)://`, `mailto:`, `tel:`, and site-absolute web routes (`/echomq…`)
— are skipped, not flagged ([`internal/speclint/speclint.go:183`](../../../go/msh/memory/internal/speclint/speclint.go)).
The CLI surface is `msh specs [AREA]`; the area is an existing path, a name resolved under `<repo>/<base>/<AREA>`
(base defaults to `docs`), or — empty — the active project's `name` from `.msh-memory.json`
([`command/specs.go:26`](../../../go/msh/memory/command/specs.go)).

## 7 · One implementation, two surfaces

The load-bearing structural decision: **the CLI and the MCP server share one implementation**. Each MCP tool
handler forwards to the same `memory/command` facade the CLI calls
([`cmd/main.go:206`](../../../go/msh/cmd/main.go)) — `command.{Audit,Stale,Graph,Scan}`, `command.ProjectInfo`,
`command.SpecsLinks`, and `brandedid` for `mint`. `cmd/main.go` mounts the whole memory command tree verbatim
via `command.New("memory", …)` ([`cmd/main.go:66`](../../../go/msh/cmd/main.go)), so `msh memory scan` and the
`memory_scan` tool run identical code. The reason speclint/mint logic lives in `memory/command` rather than in
`cmd/` is the import boundary: `cmd/` cannot import the memory *internals* it relies on, so the shared facade is
the only seam both surfaces can hold ([`cmd/specs.go:17`](../../../go/msh/cmd/specs.go)).

### 7.1 · The command tree (as-built)

| CLI command | MCP tool | Facade | Source |
|---|---|---|---|
| `msh memory scan` | `memory_scan` | `command.Scan/2` | [`cmd/main.go:243`](../../../go/msh/cmd/main.go) |
| `msh memory graph` | `memory_graph` | `command.Graph/3` | [`cmd/main.go:232`](../../../go/msh/cmd/main.go) |
| `msh memory stale` | `memory_stale` | `command.Stale/5` | [`cmd/main.go:221`](../../../go/msh/cmd/main.go) |
| `msh memory audit` | `memory_audit` | `command.Audit/2` | [`cmd/main.go:210`](../../../go/msh/cmd/main.go) |
| `msh memory project` | `memory_project` | `command.ProjectInfo/1` | [`cmd/main.go:254`](../../../go/msh/cmd/main.go) |
| `msh memory version` | — (CLI only) | build metadata | [`command/version.go:9`](../../../go/msh/memory/command/version.go) |
| `msh mint [NS]` | `mint` | `brandedid` (§9) | [`cmd/mint.go:181`](../../../go/msh/cmd/mint.go) |
| `msh specs [AREA]` | `specs` | `command.SpecsLinks/4` | [`cmd/specs.go:61`](../../../go/msh/cmd/specs.go) |
| `msh mcp serve\|start\|stop\|restart` | — (server lifecycle) | §7.2 | [`cmd/main.go:86`](../../../go/msh/cmd/main.go) |

**Seven tools** are registered on the server: `registerMemoryTools` binds the five `memory_*` tools
([`cmd/main.go:209`](../../../go/msh/cmd/main.go)), `registerMintTool` binds `mint`
([`cmd/mint.go:181`](../../../go/msh/cmd/mint.go)), and `registerSpecsTool` binds `specs`
([`cmd/specs.go:61`](../../../go/msh/cmd/specs.go)) — all three called by `buildMCPServer/1`
([`cmd/main.go:170`](../../../go/msh/cmd/main.go)). The server identifies itself as `{Name: "msh", Version:
"0.1.0"}` (`mcpName` / `mcpVersion` — [`cmd/main.go:43`](../../../go/msh/cmd/main.go)).

### 7.2 · Server lifecycle

`msh mcp serve` runs in the foreground on streamable HTTP at `localhost:<port>` (default `8899` —
`defaultMCPPort`, [`cmd/main.go:45`](../../../go/msh/cmd/main.go)), or over stdio with `--stdio`, blocking until
SIGINT/SIGTERM with a 5-second graceful-shutdown window
([`cmd/main.go:135`](../../../go/msh/cmd/main.go)). `start` re-execs the binary detached into its own session
(`Setsid`), writing a pidfile and logfile under `os.TempDir()`; `stop` SIGTERMs the pid and removes the
pidfile; `restart` stops, waits up to 1s for the socket to release, then starts
([`cmd/main.go:291`](../../../go/msh/cmd/main.go)). The running server is registered in a client's `.mcp.json`
as `{"type": "streamable-http", "url": "http://localhost:8899/"}`
([`cmd/main.go:13`](../../../go/msh/cmd/main.go)).

## 8 · Surfaced fork — the frontmatter `type` placement (Venus surfaces, the Operator rules)

> **Resolution (2026-06-18) — RULED + SHIPPED.** The Operator ruled Arm A; the as-built realizes it through
> Arm C's mechanism (the safest blend): `Parse` reads the nested `metadata:` block while a top-level
> `type`/`originSessionId` still wins when present, so the live corpus is classified *and* the top-level
> fixtures keep passing ([`internal/frontmatter/parse.go`](../../../go/msh/memory/internal/frontmatter/parse.go)
> — `rawFrontmatter` + `coalesce`; tests `TestParseNestedMetadata` / `TestParseTopLevelTypeWinsOverMetadata`).
> Proven: **0 `unknown`** over the 40-node corpus. The arms below are retained as the decision record (Arm B —
> the destructive corpus rewrite — CHOSEN-AGAINST).

A genuine, verified design fork: the frontmatter parser reads a **top-level** `type:` field
([`internal/frontmatter/parse.go:13`](../../../go/msh/memory/internal/frontmatter/parse.go)), but the live
corpus at [`memory/`](../../../memory) nests it under a `metadata:` map — every note opens

```text
---
name: msh-mcp-server
description: "…"
metadata:
  node_type: memory
  type: project
  originSessionId: fa6ff6a4-…
---
```

so `name` and `description` parse (they are top-level) while `type` and `originSessionId` are invisible to the
struct. With `type` empty, `classifyType/2` falls to filename heuristics
([`command/corpus.go:84`](../../../go/msh/memory/command/corpus.go)); a corpus whose notes use descriptive
filenames (`art-course.md`, `exchange-platform.md`) and not the `project_…`/`feedback_…` prefixes therefore
classifies almost entirely as `unknown`, and `originSessionId` never reaches the node. This is a real
gate-invisible gap: `scan`/`graph` run clean and produce a structurally-valid but mostly-untyped graph. The
fork is the reconciliation strategy. The arms, argued per [the architect's approach](../../aaw/aaw.architect-approach.md):

### Arm A — fix the parser to read nested `metadata.type`

**Rationale.** The live corpus is the data of record and already in production; aligning the parser to the
on-disk shape makes the existing corpus classify correctly with no content migration. The need is "the typed
graph should reflect the corpus that exists," and reading `metadata.{type,node_type,originSessionId}` answers it
directly.

**5W.**
- **Why** — the typed graph and every type-dependent rule (ORPHAN skips index nodes; classification feeds the
  graph) are only as good as the `type` the parser reads; today it reads none.
- **What** — a `metadata:` sub-struct on `Frontmatter` (or a nested decode), preferring `metadata.type` and
  reading `metadata.originSessionId`.
- **Who** — the memory toolchain maintainer; no corpus author is asked to touch a file.
- **When** — a small, well-bounded rung; the heaviest cost is choosing the precedence when both top-level and
  nested `type` are present.
- **Where** — [`internal/frontmatter/parse.go`](../../../go/msh/memory/internal/frontmatter/parse.go) and the
  `classifyType` call site in [`command/corpus.go`](../../../go/msh/memory/command/corpus.go).

**Steelman.** This is the only arm that fixes the *running* system without rewriting data: ~200 corpus notes
classify correctly the moment it lands, and the change is local to one parser and one struct. It honors *Do no
harm* (no corpus edit) and is the cheapest path to a faithful graph. The synthetic testdata
([`memory/testdata/memory/`](../../../go/msh/memory/testdata/memory), top-level `type:`) keeps passing if the
parser reads *both* placements, so the existing per-rule fixtures need no churn.

**Steward.** A `metadata:` block is a new public frontmatter shape the parser must keep supporting forever; if
it reads both placements it must define a precedence (a multi-year invariant), and the testdata should grow a
nested-`metadata` fixture so the contract is pinned, not assumed. The liability is small and well-contained —
one struct, one decode path — and ages cleanly because the corpus shape is already stable.

### Arm B — migrate the corpus to top-level `type`

**Rationale.** Keep the parser as the contract of record and bring the data to it: a one-time rewrite lifts
`metadata.type` → top-level `type` across the corpus, after which the as-built parser is correct unchanged. The
need is "the corpus should match the documented contract," answered by editing the corpus once.

**5W.**
- **Why** — the parser's flat four-field struct is the simplest possible contract; migrating the data preserves
  that simplicity instead of growing the struct.
- **What** — a migration over [`memory/`](../../../memory) hoisting the nested keys to top level.
- **Who** — the corpus owner (the agent's memory author); the toolchain maintainer writes the migration.
- **When** — a one-shot data rung, ahead of any new typed-graph feature.
- **Where** — the corpus tree only; no Go change.

**Steelman.** The shipped parser is already correct against the documented top-level contract and against the
testdata; this arm needs zero production-code change and leaves the smallest possible frontmatter struct
standing. It removes an ambiguity at the source rather than teaching the parser to tolerate two shapes.

**Steward.** A bulk corpus rewrite is a destructive at-rest operation over the agent's durable memory — the
exact class of change that wants a backup and a byte-diff. It also fights *Do no harm*: any other reader of the
corpus that expects the nested `metadata:` shape (the `node_type` key the parser does not read today is
evidence such a reader exists) breaks silently. The cost recurs every time a note is authored in the old shape
by habit.

### Arm C — support both placements

**Rationale.** Read top-level `type` when present, else fall back to `metadata.type`. The need is "be correct
for both the testdata and the live corpus without forcing a migration," answered by a precedence rule rather
than a choice between data and parser.

**5W.**
- **Why** — neither the testdata (top-level) nor the corpus (nested) has to move; both classify correctly.
- **What** — a decode that fills `type`/`originSessionId` from the nested map only when the top-level field is
  empty.
- **Who** — the toolchain maintainer; nobody else is asked to change anything.
- **When** — the same small rung as Arm A, plus one precedence decision and one fixture.
- **Where** — [`internal/frontmatter/parse.go`](../../../go/msh/memory/internal/frontmatter/parse.go).

**Steelman.** This is Arm A's faithful-to-the-corpus fix *and* Arm B's keep-the-testdata property at once: it
is the most robust against future drift, since a note authored in either shape classifies. It is the safest for
a corpus that is still being written by tools that may emit either form.

**Steward.** Tolerating two shapes is the largest standing invariant of the three — a precedence the parser
must honor and test forever, and a subtle bug surface if the two placements ever disagree in one file. It risks
masking a real authoring inconsistency that a stricter contract would surface. The fixture burden is two shapes,
not one.

### The fork, surfaced

| Arm | Fixes the live corpus | Production-code change | Corpus rewrite | Standing invariant added |
|---|---|---|---|---|
| **A** — parser reads nested | yes | one struct + decode | none | nested-`metadata` contract |
| **B** — migrate corpus | yes | none | yes (destructive) | none (keeps flat contract) |
| **C** — support both | yes | one struct + precedence | none | both-placements precedence |

The choice is the Operator's; this document surfaces the fork and does not decide it. Until ruled it is a
**named decision** in [`./msh.roadmap.md`](./msh.roadmap.md) ("Seams & open decisions"). Recommendation (advice,
not a decision): Arm A reads as the lowest-liability fix that makes the *running* graph correct — one local
change, no destructive corpus operation — with the testdata kept green by reading both placements (which is
Arm C's mechanism applied conservatively). The Operator rules.

## 9 · The brandedid codec and `mint`

`mint` mints **brd14** branded snowflake ids: a 3-byte uppercase namespace + an 11-char Base62 payload over a
`ts(41) | node(10) | seq(12)` snowflake, epoch `2024-01-01T00:00:00Z` (`EpochMs = 1_704_067_200_000`,
`Len = 14` — [`brandedid/brandedid.go:18`](../../../go/msh/brandedid/brandedid.go)). The ids are time-ordered
and coordination-free. The codec (`Encode` / `Parse` / `Decode` / `Valid` / `Hash32` / `UnixMs` / `Time` /
`MinFor` — [`brandedid/brandedid.go:43`](../../../go/msh/brandedid/brandedid.go)) is vendored verbatim from the
canonical reference `dev/echo_data/runtimes/go/brandedid`, its contract carried as test vectors so the copy
cannot drift ([`brandedid/brandedid.go:6`](../../../go/msh/brandedid/brandedid.go); the vectors are re-asserted
in [`brandedid/brandedid_test.go`](../../../go/msh/brandedid/brandedid_test.go)). The minter
(`Generator` / `NewGenerator` / `Next` / `DefaultNode` — [`brandedid/snowflake.go:24`](../../../go/msh/brandedid/snowflake.go))
ports `EchoData.Snowflake`: a lock-free single-atomic-cell that CAS-advances `max(now, last+1)`, so ids strictly
increase even within a millisecond or across a backward clock step; the node id (0..1023) derives from the
hostname (fallback pid) with no registry ([`brandedid/snowflake.go:38`](../../../go/msh/brandedid/snowflake.go)).
The CLI mints under `--ns`/`-f csv|json|ndjson|yaml`/`-n`/`--node` ([`cmd/mint.go:131`](../../../go/msh/cmd/mint.go));
the `mint` tool takes `ns`/`count`/`node`/`format` ([`cmd/mint.go:173`](../../../go/msh/cmd/mint.go)). Text
output is one id per line; the structured formats emit the full decoded record (id, ns, snowflake, unix_ms,
time, node, seq).

## 10 · Invariants (the properties the as-built code holds)

- **One implementation, two surfaces.** Every MCP tool forwards to the same `memory/command` facade the CLI
  calls; the CLI and server resolve the corpus root through one `ResolveRoot`. There is no second code path to
  drift (§7).
- **Deterministic resolution order.** Root resolution is `--root` → `.msh-memory.json` root → marker walk-up →
  typed usage error — a total, ordered function (§3).
- **The corpus is read-only to the tool.** `msh` walks, parses, hashes, and reports; no shipped command writes
  into the corpus. (Server lifecycle writes only a pidfile/logfile under `os.TempDir()`.)
- **Branded ids are time-ordered and coordination-free.** The minter is monotone under same-ms and
  backward-clock conditions; the codec round-trips and is gate-checked at the boundary (`Parse` rejects a
  wrong-length, non-uppercase, or over-range id — [`brandedid/brandedid.go:65`](../../../go/msh/brandedid/brandedid.go)).
- **The seven rules are a closed, named set.** `stale.AllRules/0` returns exactly seven rules by exported name;
  the engine sorts findings stably (§6).

## 11 · Map

Code: [`go/msh/`](../../../go/msh) (entry [`cmd/main.go`](../../../go/msh/cmd/main.go) +
[`cmd/mint.go`](../../../go/msh/cmd/mint.go) + [`cmd/specs.go`](../../../go/msh/cmd/specs.go); the toolchain
[`memory/command/`](../../../go/msh/memory/command) + [`memory/internal/`](../../../go/msh/memory/internal); the
codec [`brandedid/`](../../../go/msh/brandedid)). The corpus: [`memory/`](../../../memory). The README:
[`go/msh/memory/README.md`](../../../go/msh/memory/README.md). The delivery plan:
[`./msh.roadmap.md`](./msh.roadmap.md). The dashboard: [`./msh.progress.md`](./msh.progress.md). The features:
[`./msh.features.md`](./msh.features.md). The testing view: [`./msh.testing.md`](./msh.testing.md). The
references: [`./msh.references.md`](./msh.references.md). The shared Go-server operating manual:
[`../program/go.program.md`](../program/go.program.md). The build guide: [`/Users/jonny/dev/jonnify/go/CLAUDE.md`](../../../go/CLAUDE.md).
The reverse-mode discipline: [`../../aaw/aaw.reverse.md`](../../aaw/aaw.reverse.md). The workflow:
[`../../aaw/aaw.framework.md`](../../aaw/aaw.framework.md).
