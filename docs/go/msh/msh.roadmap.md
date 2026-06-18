# msh — the delivery roadmap (reverse-mode: as-built ladder + the harden plan)

> A REVERSE-MODE roadmap: the toolchain in [`go/msh/`](../../../go/msh) is built and shipped; this ladder cuts
> the as-built system into rungs for specification, names what is proven vs. what is deferred, and records the
> one open design fork. The code is canonical ([the reverse playbook](../../aaw/aaw.reverse.md)). The binding
> design is [`./msh.design.md`](./msh.design.md); the as-built dashboard is [`./msh.progress.md`](./msh.progress.md).

Read [`./msh.references.md`](./msh.references.md) before expanding this roadmap.

## The program

**One self-contained Go module — `github.com/jonny-novikov/msh` — that tends the `memory/` corpus and serves it
as MCP tools.**

- **Why.** A Claude agent's durable cross-session memory is a directory of markdown notes
  ([`memory/`](../../../memory)); it rots silently — dead links, removed-tool mentions, supersession cycles. The
  toolchain walks the corpus, builds a typed cross-reference graph, and detects that rot through seven
  context-aware rules, so the memory an agent stands on can be audited rather than trusted blind. The same
  operations are served over MCP so a running agent can call them in-session.
- **What.** The `msh` binary ([`cmd/main.go`](../../../go/msh/cmd/main.go)) with two surfaces over one
  implementation: the `memory` toolchain (scan · graph · stale · audit · project · version), the `mint`
  branded-id minter, the `specs` stale-link checker, and the streamable-HTTP MCP server that exposes seven
  tools. Phase 1 (the graph + stale MVP) is **built**; Phase 2 (semantic-similarity enrichment) is **deferred**
  ([`memory/README.md:9`](../../../go/msh/memory/README.md)).
- **Who.** The Operator owns the goal and the one open fork (§Seams). The toolchain is consumed by Claude agents
  (via the MCP server, registered in a client's `.mcp.json`) and by CI (`msh memory audit`, non-zero exit on
  errors). The running server is supervised by the `mcpd` controller beside `aaw` — named, not specified here.
- **When.** Phase 1 is shipped and in use; the MCP server runs on `:8899`. This roadmap specifies the as-built
  surface retrospectively (reverse mode); the only forward work is the deferred Phase 2 and whichever arm the
  Operator rules on the frontmatter fork.
- **Where.** Code: [`go/msh/`](../../../go/msh) (`cmd/`, `memory/command/`, `memory/internal/`, `brandedid/`).
  Corpus: [`memory/`](../../../memory). Specs: [`docs/go/msh/`](.) (this roadmap, the design canon, the
  references, the per-rung triads under [`specs/`](./specs)).

## The as-built rung ladder

Reverse-mode rungs: each is one coherent subsystem a maintainer reasons about in one pass, cut from the module's
real boundaries ([the reverse playbook](../../aaw/aaw.reverse.md), the ladder design). A rung is **shipped** when
its surface exists in the tree; it is **specified** when its triad is authored and grounded. Triads are
**deferred** to follow-on rungs ([`specs/README.md`](./specs/README.md)).

| Rung | Ships (the as-built slice) | Code home | Status |
|---|---|---|---|
| **msh.0** | the corpus model: walker (`.md`, dot-dir skip, sorted), frontmatter parse, `Node`/graph scaffold, SHA-256 | [`internal/walker/`](../../../go/msh/memory/internal/walker) · [`internal/frontmatter/`](../../../go/msh/memory/internal/frontmatter) · [`internal/graph/`](../../../go/msh/memory/internal/graph) | ✅ SHIPPED · triad 📋 PLANNED |
| **msh.1** | root resolution + the project anchor: `ResolveRoot`, `LoadMemoryConfig`, `ProjectInfo`, the `.msh-memory.json` schema | [`command/root.go`](../../../go/msh/memory/command/root.go) · [`command/project.go`](../../../go/msh/memory/command/project.go) | ✅ SHIPPED · triad 📋 PLANNED |
| **msh.2** | the graph: the 7 edge kinds, the linkx extractor + code-block masker, JSON/dot render | [`internal/linkx/`](../../../go/msh/memory/internal/linkx) · [`internal/graph/`](../../../go/msh/memory/internal/graph) | ✅ SHIPPED · triad 📋 PLANNED |
| **msh.3** | the stale engine: the 7 rules + deletion-context whitelist + config (defaults/resolve) | [`internal/stale/`](../../../go/msh/memory/internal/stale) · [`internal/config/`](../../../go/msh/memory/internal/config) | ✅ SHIPPED · triad 📋 PLANNED |
| **msh.4** | the `specs` checker: speclint (filesystem-resolved cross-area links) | [`internal/speclint/`](../../../go/msh/memory/internal/speclint) · [`command/specs.go`](../../../go/msh/memory/command/specs.go) | ✅ SHIPPED · triad 📋 PLANNED |
| **msh.5** | brandedid + `mint`: the brd14 codec (vendored) + the Snowflake minter | [`brandedid/`](../../../go/msh/brandedid) | ✅ SHIPPED · triad 📋 PLANNED |
| **msh.6** | the surfaces: the cobra command tree + the 7 MCP tools + server lifecycle (serve/start/stop/restart) | [`cmd/main.go`](../../../go/msh/cmd/main.go) · [`cmd/mint.go`](../../../go/msh/cmd/mint.go) · [`cmd/specs.go`](../../../go/msh/cmd/specs.go) | ✅ SHIPPED · triad 📋 PLANNED |
| **msh.P2** | semantic-similarity enrichment (the `hugot`/`similarity` config carriers) | — (config keys parsed, not consumed) | 🔒 PROPOSED — deferred (Phase 2) |
| **msh.FX** | the frontmatter-`type` fix (whichever arm is ruled — design §8) | [`internal/frontmatter/`](../../../go/msh/memory/internal/frontmatter) | 📋 PLANNED — pending the Operator ruling (§Seams 1) |

The ladder is the **specification** order, not a build order — msh.0–msh.6 are already in the tree. A reverse
rung closes when every documented surface is confirmed at its cited `file:line` and every invariant maps to a
running check or an explicit recorded gap ([the reverse playbook](../../aaw/aaw.reverse.md)).

## The master invariant

**One implementation, two surfaces — and a closed, deterministic core.** Every MCP tool handler forwards to the
same `memory/command` facade the CLI calls ([`cmd/main.go:206`](../../../go/msh/cmd/main.go)); both surfaces
resolve the corpus through one `ResolveRoot` (the ordered `--root` → `.msh-memory.json` → marker walk-up →
typed error — [`command/root.go:88`](../../../go/msh/memory/command/root.go)). The stale engine is a closed set
of **seven** named rules ([`internal/stale/rules.go:22`](../../../go/msh/memory/internal/stale/rules.go)); the
graph carries exactly **seven** edge kinds ([`internal/graph/edge.go:5`](../../../go/msh/memory/internal/graph/edge.go));
the server registers exactly **seven** tools (5 `memory_*` + `mint` + `specs`). The branded codec is vendored
verbatim and pinned by test vectors so it cannot drift
([`brandedid/brandedid.go:6`](../../../go/msh/brandedid/brandedid.go)). No shipped command writes into the
corpus — the tool is read-only over the memory it audits. A change that adds a rule, an edge kind, or a tool is
an additive minor and re-pins the counts in the pinning tests; a change that breaks the one-implementation
seam, the resolution order, or the read-only property is a major.

## How the program runs

Reverse mode: the code is the contract. Each rung's specification is authored against the as-built tree —
`module.fun/arity` with its `file:line`, every cited surface re-verified at source (NO-INVENT —
[the reverse rules](../../aaw/aaw.rules.md)). Where a documented claim and the code disagree, the code wins and
the spec is corrected. The forward-tense voice is reserved for the genuinely-unbuilt (Phase 2) and the
unruled fork arms; everything in the tree is present-tense as-built. The workflow is
[`../../aaw/aaw.framework.md`](../../aaw/aaw.framework.md); the build guide for the Go modules is
[`/Users/jonny/dev/jonnify/go/CLAUDE.md`](../../../go/CLAUDE.md); the shared Go-server operating manual is
[`../program/go.program.md`](../program/go.program.md).

## Seams & open decisions

1. **The frontmatter `type` placement** (design §8) — **OPEN, Operator to rule.** The parser reads top-level
   `type:` ([`internal/frontmatter/parse.go:13`](../../../go/msh/memory/internal/frontmatter/parse.go)); the
   live corpus nests it as `metadata.type`, so most notes classify `unknown`. Three arms are surfaced in the
   design (Arm A fix the parser to read nested · Arm B migrate the corpus to top-level · Arm C support both).
   Recommendation on record: Arm A (lowest-liability, no destructive corpus rewrite). Until ruled this is rung
   **msh.FX**, planned but not scheduled.
2. **Phase 2 — semantic-similarity enrichment** — **DEFERRED.** The `hugot` (endpoint `localhost:8902`) and
   `similarity` (threshold `0.85`, top-k `5`) config blocks are parsed and merged today
   ([`internal/config/defaults.go:38`](../../../go/msh/memory/internal/config/defaults.go)) but consumed by no
   shipped rule. Rung **msh.P2**, forward-tense; not slotted.
3. **Config-filename spelling** — **RECORDED, not a defect.** The root *marker* probe looks for
   `msh.memory.yaml` / `.msh.memory.yaml` ([`command/root.go:163`](../../../go/msh/memory/command/root.go))
   while the rule-*config* probe looks for `msh-memory.yaml` / `.msh-memory.yaml`
   ([`internal/config/config.go:42`](../../../go/msh/memory/internal/config/config.go)). The README documents a
   third order again ([`memory/README.md:55`](../../../go/msh/memory/README.md)). The two probes name different
   files and both are as-built; a future rung may reconcile the spellings. Code wins.
4. **README drift** — **RECORDED, not a defect.** [`memory/README.md`](../../../go/msh/memory/README.md)
   pre-dates the `go/msh` restructure: it names `cmd/msh/` (actual: `cmd/`), an `internal/hugot/` directory
   (absent — Phase 2 is config-only), and omits `project` / `mint` / `specs` from its subcommand table. The
   code is canonical; the README is a follow-on doc-sync target, not a spec input.
5. **The `version` surface** — **RECORDED.** `msh memory version` prints `msh-memory <version> …` with a
   link-time-overridable default of `"dev"` ([`command/run.go:21`](../../../go/msh/memory/command/run.go)) —
   distinct from the MCP server's self-reported `Version: "0.1.0"`
   ([`cmd/main.go:45`](../../../go/msh/cmd/main.go)). The `0.1.0` names the served MCP implementation; the CLI
   build version is set at link time. Both are as-built; do not conflate them.

## Dependencies, recorded

- **The `memory/command` facade is the spine.** Both surfaces (CLI and MCP) and every tool stand on it; the
  `cmd/` package mounts the memory tree verbatim and forwards each tool to it
  ([`cmd/main.go:66`](../../../go/msh/cmd/main.go)). It is the universal predecessor of msh.1–msh.6.
- **`brandedid` is independent.** The codec + minter (msh.5) has no dependency on the memory toolchain and is
  consumed only by `mint` (CLI + tool). It is vendored from `dev/echo_data/runtimes/go/brandedid` and pinned by
  test vectors.
- **The MCP transport is vendored.** `github.com/fiberfx/mcp-go/v2` is replaced to `../mcp-go`
  ([`go/msh/go.mod:23`](../../../go/msh/go.mod)); the streamable-HTTP handler and stdio transport come from it.

---

The binding design: [`./msh.design.md`](./msh.design.md). The references: [`./msh.references.md`](./msh.references.md).
The dashboard: [`./msh.progress.md`](./msh.progress.md). The features: [`./msh.features.md`](./msh.features.md).
The testing view: [`./msh.testing.md`](./msh.testing.md). Rung triads: [`specs/`](./specs) — deferred to
follow-on rungs ([`specs/README.md`](./specs/README.md)).
