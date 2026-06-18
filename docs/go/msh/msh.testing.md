# msh — testing strategy (the as-built proof)

> How the shipped `msh` toolchain is proven: the synthetic corpus fixture, the per-rule tests, the codec test
> vectors, the round-trip/parity checks, and the over-the-wire MCP integration tests. This is the **testing
> view** beside the design, roadmap, and progress docs; it adds no contract — it records how the as-built code
> is proven and where the proof is thin. Grounded in the tree at [`go/msh/`](../../../go/msh) as of 2026-06-18 —
> re-run `go test ./...` from [`go/msh/`](../../../go/msh) before trusting any figure (the code wins).

Canon: [`./msh.design.md`](./msh.design.md) (the as-built surface) · [`./msh.roadmap.md`](./msh.roadmap.md)
(the ladder) · [`./msh.progress.md`](./msh.progress.md) (status) · the per-rung triads under [`specs/`](./specs).

---

## 0 · The test corpus — the synthetic fixture

The deterministic offline fixture is a 12-file synthetic memory tree at
[`memory/testdata/memory/`](../../../go/msh/memory/testdata/memory). It is hand-built to exercise every rule and
edge kind without depending on the live corpus:

| Fixture file | Exercises |
|---|---|
| `MEMORY.md` · `completed-projects.md` | the index nodes (orphan-exempt) |
| `feedback_alpha.md` · `feedback_beta.md` | typed nodes + inbound links |
| `feedback_dead.md` | a DEAD-TARGET (link to a missing `.md`) |
| `feedback_anchor.md` | a BROKEN-ANCHOR (link to an absent heading) |
| `feedback_orphan.md` | an ORPHAN (no incoming edges) |
| `feedback_external.md` | a STALE-EXTERNAL (`../` ref off disk) |
| `feedback_removed_tool.md` · `feedback_removed_tool_whitelist.md` | a REMOVED-TOOL and its deletion-context downgrade |
| `topics/topic_a.md` · `topics/cclin/sub_a.md` | the `cross_subdir` edge + nested-subdir walk |

The filename prefixes (`feedback_…`) are deliberate: they exercise the `classifyType` **filename-heuristic**
fallback ([`command/corpus.go:99`](../../../go/msh/memory/command/corpus.go)), and the fixture's frontmatter
uses the **top-level** `type:` shape the parser reads — which is why the testdata classifies correctly while the
live corpus (nested `metadata.type`) does not. That divergence is the design fork ([`./msh.design.md`](./msh.design.md) §8);
a nested-`metadata` fixture is the test the fork's chosen arm should add.

---

## 1 · The test files and what each proves

`go test ./...` from [`go/msh/`](../../../go/msh) runs 17 test files. The load-bearing ones:

| Test file | Proves |
|---|---|
| [`brandedid/brandedid_test.go`](../../../go/msh/brandedid/brandedid_test.go) | the **codec contract vectors** (`TestContractVectors`), invalid-id rejection (`TestRejectsInvalid`), and minter monotonicity + branding (`TestMintMonotonicAndBranded`) — the vendored copy can't drift |
| [`internal/frontmatter/parse_test.go`](../../../go/msh/memory/internal/frontmatter/parse_test.go) | four-/three-field parse, missing/malformed/no-closing-delimiter handling (5 tests) |
| [`internal/walker/walker_test.go`](../../../go/msh/memory/internal/walker/walker_test.go) | dot-dir skip, empty-root rejection, missing-root error, case-insensitive `.md` (4 tests) |
| [`internal/linkx/extractor_test.go`](../../../go/msh/memory/internal/linkx/extractor_test.go) | every edge kind extracted + classified, code-block masking (13 tests) |
| [`internal/graph/graph_test.go`](../../../go/msh/memory/internal/graph/graph_test.go) · [`graph_extra_test.go`](../../../go/msh/memory/internal/graph/graph_extra_test.go) | dedup/nil rejection, edge resolution (incl. `cross_subdir`/`external_rel`/`bare_mention`), **JSON round-trip** (`TestRenderJSONRoundTrip`), dot digraph + node colors (18 tests) |
| [`internal/stale/stale_test.go`](../../../go/msh/memory/internal/stale/stale_test.go) | each of the 7 rules fires correctly + the whitelist downgrades (17 tests) |
| [`internal/stale/rules_extra_test.go`](../../../go/msh/memory/internal/stale/rules_extra_test.go) | glob matching, rule selection, severity rank, stable finding sort (8 tests) |
| [`internal/stale/context_test.go`](../../../go/msh/memory/internal/stale/context_test.go) | paragraph-level deletion-context bounds + matching (5 tests) |
| [`internal/config/config_test.go`](../../../go/msh/memory/internal/config/config_test.go) | config resolution order, dotted variant, defaults fallback, malformed YAML, all sections present (6 tests) |
| [`internal/speclint/speclint_test.go`](../../../go/msh/memory/internal/speclint/speclint_test.go) | cross-area filesystem resolution, display-path relativity, off-site skip (3 tests) |
| [`internal/render/render_test.go`](../../../go/msh/memory/internal/render/render_test.go) | pretty + NDJSON node/finding rendering, audit summary (6 tests) |
| [`command/integration_test.go`](../../../go/msh/memory/command/integration_test.go) | **end-to-end against the synthetic corpus** — audit, scan NDJSON, graph JSON/dot, stale `--rules` selection, the memory-reference whitelist (13 tests) |
| [`command/project_test.go`](../../../go/msh/memory/command/project_test.go) | `.msh-memory.json` walk-up, absent-anchor handling, project render (3 tests) |
| [`command/specs_test.go`](../../../go/msh/memory/command/specs_test.go) | the `specs` facade: explicit path, no-findings pretty, unknown area, invalid format (4 tests) |
| [`command/cmd_extra_test.go`](../../../go/msh/memory/command/cmd_extra_test.go) | CLI-level format/severity validation + audit exit codes (17 tests) |
| [`cmd/mcp_test.go`](../../../go/msh/cmd/mcp_test.go) | **the MCP tools over streamable HTTP** — memory tools, the mint tool, the specs tool, end to end (3 tests) |

---

## 2 · The proof shape — what is strong, what is thin

**Strong.**
- **One-implementation parity is proven over the wire.** [`cmd/mcp_test.go`](../../../go/msh/cmd/mcp_test.go)
  exercises the actual MCP tools through the streamable-HTTP server, not just the facade — so the CLI⇄MCP shared
  path is checked at the boundary, not assumed on one side
  ([the reverse playbook's cross-boundary discipline](../../aaw/aaw.reverse.md)).
- **The codec cannot silently drift.** `TestContractVectors` re-asserts the vendored vectors from the canonical
  reference; a divergence from `dev/echo_data/runtimes/go/brandedid` fails the build
  ([`brandedid/brandedid_test.go`](../../../go/msh/brandedid/brandedid_test.go)).
- **Every rule and edge kind has a fixture-backed test** — the 7 rules, the 7 edge kinds, and the deletion-context
  whitelist each fire against the synthetic corpus.
- **Serialization round-trips** — `TestRenderJSONRoundTrip` proves the graph survives JSON encode→decode.

**Thin (recorded gaps, not defects).**
- **No test pins the live-corpus classification gap.** The fork in design §8 is gate-invisible precisely because
  the testdata uses the top-level `type:` shape; there is no nested-`metadata` fixture, so `go test` is green
  while the live corpus classifies `unknown`. The chosen fork arm should add that fixture.
- **The `version` surface has no assertion** on the link-time defaults vs. the MCP `0.1.0` — the two values are
  independent and untested together ([`./msh.roadmap.md`](./msh.roadmap.md) §Seams 5).
- **Phase 2 is untested by construction** — the `hugot`/`similarity` config is carried but consumed by nothing,
  so `TestDefaultsHaveAllSections` checks the keys exist but no behavior rides them.

---

## 3 · Running the gate

From [`go/msh/`](../../../go/msh): `go test ./...` runs the whole suite offline (no network, no live corpus —
the synthetic fixture is embedded under `testdata/`). The MCP integration tests stand up an in-process
streamable-HTTP server and call the tools; they need no external MCP client. The build uses `GOWORK=off` per the
repo convention ([`/Users/jonny/dev/jonnify/go/CLAUDE.md`](../../../go/CLAUDE.md); the build guide is the
authority for the toolchain). Re-probe the suite before trusting any count above — the working tree, not this
doc, is the source of truth.

---

The binding design: [`./msh.design.md`](./msh.design.md). The roadmap: [`./msh.roadmap.md`](./msh.roadmap.md).
The dashboard: [`./msh.progress.md`](./msh.progress.md). The features: [`./msh.features.md`](./msh.features.md).
The references: [`./msh.references.md`](./msh.references.md).
