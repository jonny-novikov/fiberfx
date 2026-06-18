# msh — Program Progress Dashboard

> **The single consolidated status view of the `msh` toolchain** — the `memory/`-corpus graph + stale toolchain
> and MCP server built in [`go/msh/`](../../../go/msh). This is a REVERSE-MODE program: the code is shipped and
> canonical; this dashboard reports the as-built surface and the specification status of each rung. This file
> *reports*; the binding artifacts *define* — the design canon [`./msh.design.md`](./msh.design.md), the roadmap
> [`./msh.roadmap.md`](./msh.roadmap.md), and the per-rung triads under [`specs/`](./specs) (deferred). Re-probe
> the tree before trusting any figure — the code wins.

**One-line state.** Phase 1 is **shipped and in use**: the corpus walker, the typed cross-reference graph (7
edge kinds), the stale engine (7 context-aware rules), the `specs` cross-area link checker, the brd14 `mint`
codec, and the streamable-HTTP MCP server exposing **7 tools** (5 `memory_*` + `mint` + `specs`) on `:8899`.
The MCP server self-reports `Version: "0.1.0"` ([`cmd/main.go:45`](../../../go/msh/cmd/main.go)). Phase 2
(semantic-similarity enrichment) is **deferred** — its config keys are carried but consumed by nothing. One
design fork is **OPEN** for the Operator: the frontmatter `type` placement (top-level parser vs. nested-corpus —
design §8).

---

## Legend

| Symbol | State | Meaning |
|---|---|---|
| ✅ | **SHIPPED** | in the tree, surface confirmed at its `file:line` |
| 🔨 | **IN FLIGHT** | building now — partial artifacts, not yet complete |
| 📐 | **SPECCED** | rung triad authored & grounded against as-built, no further work |
| 📋 | **PLANNED** | on the specification ladder, triad not yet authored |
| 🔒 | **PROPOSED** | deferred (Phase 2) or awaiting an Operator ruling |

ANSI bars: `█` shipped · `░` not yet (specified or built). A rung is one coherent subsystem.

---

## Development Progress

```text
msh — the memory toolchain + MCP server · github.com/jonny-novikov/msh · go 1.25.0

Phase 1 · the graph + stale MVP   ✅ SHIPPED (code in tree)
  msh.0  ✅ shipped   ████████████████████  corpus model · walker · frontmatter parse · Node/graph scaffold · SHA-256
  msh.1  ✅ shipped   ████████████████████  root resolution (ResolveRoot) · .msh-memory.json anchor · project context
  msh.2  ✅ shipped   ████████████████████  the graph · 7 edge kinds · linkx extractor + codeblock mask · JSON/dot
  msh.3  ✅ shipped   ████████████████████  stale engine · 7 rules · deletion-context whitelist · config + defaults
  msh.4  ✅ shipped   ████████████████████  specs checker · speclint · filesystem-resolved cross-area links
  msh.5  ✅ shipped   ████████████████████  brandedid · brd14 codec (vendored) · Snowflake minter · mint
  msh.6  ✅ shipped   ████████████████████  surfaces · cobra tree · 7 MCP tools · server serve/start/stop/restart

Specification (reverse triads)
  msh.0–msh.6  📋 PLANNED  ░░░░░░░░░░░░░░░░░░░░  per-rung triads deferred to follow-on rungs (specs/README.md)

Deferred / pending a ruling
  msh.P2  🔒 PROPOSED  ░░░░░░░░░░░░░░░░░░░░  Phase 2 · semantic-similarity (hugot + similarity config, unused)
  msh.FX  📋 PLANNED   ░░░░░░░░░░░░░░░░░░░░  frontmatter-type fix · pending the Operator ruling (design §8)

── roll-up ──
  shipped       Phase 1 — msh.0 … msh.6 (code in tree)
  specified     none yet — triads PLANNED
  deferred      msh.P2 (Phase 2) · msh.FX (the frontmatter fork)
  ─────────────────────────────────────────────
  Phase 1 SHIPPED → reverse-spec the as-built ladder; Phase 2 deferred
```

---

## The surface — what shipped

### The MCP tools (7)

| Tool | What it returns | Facade | Source |
|---|---|---|---|
| `memory_scan` | per-note metadata (name/type/description, size, hash) | `command.Scan/2` | [`cmd/main.go:243`](../../../go/msh/cmd/main.go) ✅ |
| `memory_graph` | the cross-reference graph as JSON or dot | `command.Graph/3` | [`cmd/main.go:232`](../../../go/msh/cmd/main.go) ✅ |
| `memory_stale` | the stale findings (the 7 rules) | `command.Stale/5` | [`cmd/main.go:221`](../../../go/msh/cmd/main.go) ✅ |
| `memory_audit` | node count + stale counts + warn+ findings | `command.Audit/2` | [`cmd/main.go:210`](../../../go/msh/cmd/main.go) ✅ |
| `memory_project` | the active project context from `.msh-memory.json` | `command.ProjectInfo/1` | [`cmd/main.go:254`](../../../go/msh/cmd/main.go) ✅ |
| `mint` | brd14 branded snowflake id(s) | `brandedid` | [`cmd/mint.go:181`](../../../go/msh/cmd/mint.go) ✅ |
| `specs` | stale-link findings for a docs/specs tree | `command.SpecsLinks/4` | [`cmd/specs.go:61`](../../../go/msh/cmd/specs.go) ✅ |

### The CLI command tree

`msh memory {scan,graph,stale,audit,project,version}` · `msh mcp {serve,start,stop,restart}` · `msh mint [NS]`
· `msh specs [AREA]` ([`cmd/main.go:56`](../../../go/msh/cmd/main.go), [`command/root.go:60`](../../../go/msh/memory/command/root.go)).

### The seven stale rules

`DEAD-TARGET` · `DELETED-PATH` · `REMOVED-TOOL` · `BROKEN-ANCHOR` · `ORPHAN` · `SUPERSEDE-CYCLE` ·
`STALE-EXTERNAL` ([`internal/stale/rules.go:22`](../../../go/msh/memory/internal/stale/rules.go)).

### The seven edge kinds

`md_link` · `md_link_anchor` · `external_rel` · `code_path` · `bare_mention` · `anchor_only` · `cross_subdir`
([`internal/graph/edge.go:5`](../../../go/msh/memory/internal/graph/edge.go)).

---

## Master invariant (held at every rung)

> **One implementation, two surfaces.** Every MCP tool forwards to the same `memory/command` facade the CLI
> calls; both resolve the corpus through one ordered `ResolveRoot`
> ([`command/root.go:88`](../../../go/msh/memory/command/root.go)). The stale rules (7), the edge kinds (7), and
> the served tools (7) are closed, named sets; the branded codec is vendored verbatim and pinned by test
> vectors ([`brandedid/brandedid.go:6`](../../../go/msh/brandedid/brandedid.go)). The tool is read-only over the
> corpus it audits. Adding a rule/edge/tool is an additive minor (re-pin the counts); breaking the shared seam,
> the resolution order, or the read-only property is a major.

---

## Sources

- **Design canon:** [`./msh.design.md`](./msh.design.md) (S-sections + the frontmatter fork) · **Roadmap:** [`./msh.roadmap.md`](./msh.roadmap.md)
- **Features:** [`./msh.features.md`](./msh.features.md) · **Testing:** [`./msh.testing.md`](./msh.testing.md) · **References:** [`./msh.references.md`](./msh.references.md)
- **Rung triads:** [`specs/`](./specs) — deferred to follow-on rungs ([`specs/README.md`](./specs/README.md))
- **As-built:** [`go/msh/`](../../../go/msh) — [`cmd/`](../../../go/msh/cmd) · [`memory/command/`](../../../go/msh/memory/command) · [`memory/internal/`](../../../go/msh/memory/internal) · [`brandedid/`](../../../go/msh/brandedid) · the README [`go/msh/memory/README.md`](../../../go/msh/memory/README.md)
- **Corpus:** [`memory/`](../../../memory) · the anchor `.msh-memory.json`
- **Build guide:** [`/Users/jonny/dev/jonnify/go/CLAUDE.md`](../../../go/CLAUDE.md) · the operating manual [`../program/go.program.md`](../program/go.program.md) · the workflow [`../../aaw/aaw.framework.md`](../../aaw/aaw.framework.md)
