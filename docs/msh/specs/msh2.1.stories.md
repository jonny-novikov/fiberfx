# msh2.1 — acceptance stories

> Given/when/then over the rung's public surface. Derives from [msh2.1.md](./msh2.1.md); the body wins on
> any disagreement. Every story runs against fixture directories — never the live repo-root anchor.

## S-1 · Resolution from a nested directory (regression — invariant: resolution order unchanged)

As a CLI user, invoking `msh memory` commands from anywhere under a project, so that the corpus resolves
without `--root`.
- **Given** a fixture tree whose root holds `.msh-memory.json` with a valid `root`, **when** `msh memory
  scan` runs from a directory three levels below, **then** the corpus resolves to the anchor's `root` and
  the command exits 0.
- **Given** no anchor and no marker anywhere up the tree, **when** a memory command runs, **then** the typed
  usage error (exit 2) is returned — unchanged.

## S-2 · The canonical marker resolves (invariant: one authority)

As a project owner, marking a corpus root with the ONE documented filename, so that resolution needs no lore.
- **Given** a directory holding only `.msh-memory.yaml` (no `MEMORY.md`, no anchor), **when** a memory
  command runs from inside it, **then** that directory is the resolved root.

## S-3 · Every legacy spelling still resolves (invariant: the deprecation window)

As an operator with a config file authored under an old docstring, so that nothing silently stops resolving.
- **Given** a root holding exactly one of `msh-memory.yaml` / `.msh.memory.yaml` / `msh.memory.yaml`
  (three cases), **when** the marker walk-up runs, **then** the directory is recognized as a root; **and
  when** the stale/audit config resolves with no `--config`, **then** that file's values are loaded.

## S-4 · The canonical file wins precedence (invariant: determinism)

As a maintainer migrating a config to the canonical name, so that the old copy cannot shadow the new one.
- **Given** a root holding both `.msh-memory.yaml` and a legacy-named config with different values, **when**
  config resolution runs, **then** the canonical file's values win and the reported source path is the
  canonical file.

## S-5 · `docs_root` present (anchor v1.1)

As an agent orienting at rung-open, calling `memory_project`, so that the docs tree is discoverable from
the anchor.
- **Given** a fixture anchor carrying `"docs_root": "<abs path>"`, **when** `memory_project` (tool) or
  `msh memory project` (CLI) runs in text format, **then** the output contains a `docs:` line with that
  path; **when** format is `json`, **then** the object carries `docs_root`.

## S-6 · `docs_root` absent (degrade soft)

As an operator with a v1.0 anchor, so that the old shape keeps working unchanged.
- **Given** an anchor with no `docs_root` key, **when** the project surface renders, **then** text shows
  `docs:    -`, JSON omits the key, and no error or warning is produced.

## S-7 · A relative `docs_root` resolves against the anchor's directory

As a project owner keeping the anchor portable, so that a checked-in relative path works from any cwd.
- **Given** an anchor at `<dir>/.msh-memory.json` with `"docs_root": "docs/msh"`, **when** the config is
  loaded, **then** the reported `docs_root` is the absolute `<dir>/docs/msh` (the `root` precedent).

## S-8 · The tool count is pinned at eight (invariant: additive-minor)

As the program's maintainer, so that a tool addition or loss is a visible test diff, never a drift.
- **Given** the MCP server built by `buildMCPServer`, **when** the pin test lists registered tools, **then**
  the count is exactly 8 and the set is `memory_scan/graph/stale/audit/project`, `mint`, `specs`,
  `history_search`.

## S-9 · The documentation names only the canonical spelling (deliverable: docstring sync)

As a new user reading `--help` or a tool schema, so that one spelling exists in every doc surface.
- **Given** the built binary and source tree, **when** user-facing strings (flag help, command Short/Long,
  MCP tool descriptions and arg schemas) are swept, **then** `.msh-memory.yaml` is the only config-marker
  spelling present; legacy spellings survive only in the shared candidate-name list and its tests.

## Coverage

| Deliverable (spec §4) | Stories |
|---|---|
| D1 shared name list | S-2, S-3, S-4 |
| D2 probe set | S-2, S-3 |
| D3 loader order | S-4 |
| D4 anchor v1.1 | S-5, S-6, S-7 |
| D5 docstring sync | S-9 |
| D6 tool-count pin | S-8 |
| resolution-order regression | S-1 |
