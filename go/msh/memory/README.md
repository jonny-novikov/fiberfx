# msh

Memory graph + stale-reference toolchain for the `memory/` corpus.

Walks a directory of markdown notes, parses YAML frontmatter, builds a typed
cross-reference graph (7 edge kinds), and detects stale references via 7
context-aware rules with paragraph-level deletion-context whitelisting.

## Phases

- Phase 1 - MVP. 
- Phase 2 (semantic-similarity enrichment) is deferred.

## Subcommands

| Subcommand | Purpose |
|---|---|
| `scan` | Walk memory, parse frontmatter, dump per-file metadata |
| `graph` | Build full node+edge graph; emit JSON or dot |
| `stale` | Run detection rules; emit `Finding[]` |
| `audit` | Composite scan + stale + summary; non-zero exit on errors |
| `version` | Print build version |

## Examples

```bash
# Walk memory, list every node as one-line NDJSON.
msh memory scan --format ndjson | wc -l

# Render the cross-reference graph for visualization.
msh memory graph --format dot --out /tmp/memory.dot
dot -Tsvg /tmp/memory.dot > /tmp/memory.svg

# Detect stale references at warn or higher.
msh memory stale --severity warn

# Composite audit; non-zero exit on errors. Use in CI.
msh memory audit --max-warn 50
```

## Stale-detection rules

| Rule | Trigger | Default severity |
|---|---|---|
| `DEAD-TARGET` | `*.md` link target not present in graph | error |
| `DELETED-PATH` | Code-path edge matches `cfg.deleted_paths` glob | error → warn if whitelisted |
| `REMOVED-TOOL` | Bare-mention or backtick token matches `cfg.removed_tools` | warn → info if whitelisted |
| `BROKEN-ANCHOR` | Anchor link target resolves but anchor missing | warn |
| `ORPHAN` | Node has zero incoming edges + not in `cfg.ignore_orphans` | info |
| `SUPERSEDE-CYCLE` | Two superseded nodes cite each other | warn |
| `STALE-EXTERNAL` | External relative link does not resolve to disk | warn |

## Configuration

Resolved in this order:

1. `--config <path>`
2. `<root>/msh-memory.yaml`
3. `<root>/.msh-memory.yaml`
4. Baked-in defaults

Schema lives in `internal/config/config.go`. The corpus-tied config for the memory tree lives at `memory/msh-memory.yaml`.

## Architecture

```
cmd/msh/      # Cobra root + subcommands
internal/walker/       # filepath.WalkDir + .md filter
internal/frontmatter/  # YAML frontmatter parser
internal/linkx/        # 7-edge regex extractor + codeblock masker
internal/graph/        # node/edge model + JSON/dot serializers
internal/stale/        # 7 rules + paragraph-level whitelist
internal/config/       # YAML loader + baked defaults
internal/render/       # output formatters (pretty / ndjson)
internal/hugot/        # Phase 2 placeholder (HTTP client for hugot-server)
testdata/memory/       # 12-file synthetic fixture
```
