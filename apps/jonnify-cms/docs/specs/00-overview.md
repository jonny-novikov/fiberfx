# 00 — Overview: architecture, reconciliation model, package layout

This document specifies the architecture of `jonnify-cms` (binary `cms`), a Go
content-management toolchain for the static **Functional Programming in Elixir** course.
The course is the `/elixir` section of the jonnify site: a tree of pre-authored HTML pages
served byte-for-byte by the jonnify Fiber server, folder-routed so a clean URL maps to a
file on disk.

`cms` is the Go successor to the Python `docs/elixir/kb/build_page.py`. It ports that
script's manifest, page builder, branded-Snowflake id scheme, and nine Apollo A+ quality
gates, and extends them with route, graph, audit, and readiness commands. This document
covers the whole tool's shape; the per-feature specs (`01`–`06`, `90`) cover each command
in detail.

## 1. Scope and role

`cms` is an **offline authoring and maintenance tool**. It does not run at request time, is
not linked into the jonnify server, and never serves traffic. The jonnify server stays a
pure static file server; `cms` operates on the same files from a workstation or CI before
those files are deployed.

The tool has two halves:

- **Read/report** — `manifest`, `routes`, `graph`, `audit` (without `--fix`), `readiness`,
  `check`, `stamp decode`. These inspect the manifest and the built pages and emit reports.
  They do not mutate the content tree.
- **Write** — `build`, `audit --fix`, `stamp mint`. `build` assembles and writes pages,
  `audit --fix` renames orphan files to their canonical names, and `stamp mint` emits a new
  id. These are the only commands that produce side effects on the filesystem (and
  `stamp mint` only writes to standard output).

## 2. The reconciliation model — three sources of truth

The course is described three times over, by three independent sources. Each answers a
different question. They diverge whenever content is authored ahead of, or behind, the
manifest. The central purpose of `cms` is to make those divergences visible and to close
them.

```
        ┌────────────────────┐
        │      MANIFEST      │   declared status of every page
        │  internal/manifest │   (CHAPTERS / MODULES / SUBPAGES / PAGES)
        └─────────┬──────────┘   LINKABLE = {live, built}
                  │
   declared       │ reconcile
   vs actual      │
                  ▼
        ┌────────────────────┐         ┌────────────────────┐
        │     FILESYSTEM     │◀───────▶│   APOLLO  GATES    │
        │  built /elixir tree│  quality │  internal/apollo   │
        │  (clean-URL files) │          │  nine A+ checks    │
        └────────────────────┘         └────────────────────┘
```

| Source | Implementation | Asserts |
|---|---|---|
| **Manifest** | `internal/manifest`, ported verbatim from `build_page.py`. | The *declared* status of each chapter, module, and subpage, hence which routes are links (status in `{live, built}`) versus non-linking cards (`planned`/`soon`). |
| **Filesystem** | The built HTML under the `/elixir` root, folder-routed. | What pages *actually exist*, and how they link to each other. |
| **Apollo gates** | `internal/apollo`, run against a page's bytes. | Whether a page meets the *quality bar* — A+ across all nine gates. |

Two derived notions are defined once here and used throughout the specs:

- **Readiness** (`docs/specs/04-readiness.md`). A module is *ready* when its backing file
  exists **and** that file passes all nine Apollo gates. Readiness combines the filesystem
  and quality axes. It is independent of the manifest's declared status, which is the axis
  it gets checked against.

- **Drift** (`docs/specs/04-readiness.md`). A module *drifts* when the manifest declares it
  `planned`/`soon` while the backing file exists and is ready. The page is finished; the
  manifest has not caught up. The resolution is to **promote** the declared status to
  `built`, which flips the contents directory entry from a non-linking "soon" card to a
  live link. The canonical drift example today is F2.06 (closures), F2.07 (adt), and F2.08
  (composition): each is on disk and passes, yet the manifest still declares `planned`.

The reconciliation produces a small matrix over (declared-linkable?, file-exists?,
gates-pass?). The full matrix and the action each cell implies are specified in
`docs/specs/04-readiness.md`.

## 3. Clean-URL ↔ file resolution

Every command that touches the filesystem shares one resolver. The `/elixir` section is
folder-routed: the URL tree mirrors the on-disk tree. Given a content root `R` (the
directory served at `/elixir`) and a clean route `/elixir/<path>`:

- A route that names a **leaf page** resolves to `R/<path>.html`
  (`/elixir/algebra/functions` → `R/algebra/functions.html`).
- A route that names a **directory/hub** resolves to `R/<path>/index.html`
  (`/elixir/functional` → `R/functional/index.html`;
  `/elixir/algebra` → `R/algebra/index.html`).
- The bare section route `/elixir` resolves to `R/index.html`.

When both `R/<path>.html` and `R/<path>/index.html` could exist (a hub that also has a
sibling leaf), the resolver checks `R/<path>.html` first, then `R/<path>/index.html`. This
mirrors the server's `try_files`-style cascade (`serveDirTree`) so that `cms`'s view of
"which file backs this route" matches what the server would send.

The resolver is the single point that maps the manifest's routes onto the filesystem. It is
specified in full in `docs/specs/02-nav-graph.md` §3 and reused by audit
(`docs/specs/03-link-audit.md`) and readiness (`docs/specs/04-readiness.md`).

## 4. Package layout

The module mirrors the `apps/gateway` layout (`cmd/` for the command tree, `internal/` for
the libraries, a `README.md` at the root).

```
apps/jonnify-cms/
  go.mod                      module github.com/jonny-novikov/jonnify-cms (Go 1.25)
  go.sum
  README.md
  cmd/
    cms/
      main.go                 entrypoint: builds the root cobra command, calls Execute
      root.go                 root command, persistent flags, version
      manifest.go             `cms manifest`
      routes.go               `cms routes`
      graph.go                `cms graph`
      audit.go                `cms audit`
      readiness.go            `cms readiness`
      check.go                `cms check`
      build.go                `cms build`
      stamp.go                `cms stamp mint|decode`
  internal/
    manifest/                 the ported manifest: chapters, modules, subpages,
                              the PAGES build registry, statuses, LINKABLE,
                              allowed-routes computation, module-count
    snowflake/                branded Snowflake encode/decode, base62, mint/decode
    apollo/                   the nine quality gates + the gate runner + report
    audit/                    link extraction, broken-vs-placeholder classification,
                              the --fix repoint engine
    graph/                    navigation-graph construction + dot/mermaid/json emitters
  docs/
    specs/                    these specifications
  content/                    (NOT YET COMMITTED) hand-authored page fragments for `build`
  bin/                        build output (git-ignored)
```

Responsibilities and the spec that governs each:

| Package | Owns | Spec |
|---|---|---|
| `cmd/cms` | The cobra command tree, flag parsing, exit codes, output formatting. Thin: each command delegates to an `internal` package. | this doc |
| `internal/manifest` | The data model and every derived query (routes, linkable set, module count, the page→route→file mapping). The Go translation of the `build_page.py` manifest tables. | `01` |
| `internal/snowflake` | `EPOCH_MS`, the base62 alphabet, the bit layout, `Encode`/`Decode`, `Mint`/`DecodeBranded`. | `06` |
| `internal/apollo` | The nine gates, the runner that produces a per-gate result list and an overall pass, the report formatter. | `05` |
| `internal/audit` | href extraction, classification of broken vs placeholder, the known-fix table, the rename engine for `--fix`. | `03` |
| `internal/graph` | The node/edge model, edge derivation (pager, hub→subpage, breadcrumb), and the three serializers. | `02` |

`cmd/cms` depends on the `internal` packages; the `internal` packages depend only on the
standard library (and on `internal/manifest`, which the others read for routes and
statuses). No `internal` package imports cobra.

## 5. Design goals

These constraints bind every package and every command. The per-feature specs restate the
ones they touch.

1. **Offline.** No network access at any point. The tool reads the manifest (compiled in)
   and local files only. No CDN, no API, no telemetry.

2. **Standard library plus cobra only.** The sole third-party dependency is
   `github.com/spf13/cobra` for the command tree. Everything else — HTML scanning, base62,
   JSON, file walking — uses the Go standard library. HTML is processed with the same
   regex/string approach `build_page.py` uses (see `05` and `03`); no HTML parser
   dependency is introduced, so that the Go gates match the Python gates byte-for-byte.

3. **Deterministic output.** Given the same inputs, every command produces identical bytes.
   Map iteration is sorted before output; route lists, audit findings, and graph nodes/edges
   are emitted in a defined, stable order (specified per command). The one intentionally
   non-deterministic value is a freshly minted Snowflake id (it encodes the current time);
   `build` consumes a fresh id per page, and `stamp mint --at` pins the time for
   reproducible output.

4. **Read-only by default.** Only `build`, `audit --fix`, and `stamp mint` write anything.
   `audit --fix` performs in-place renames within the content root and never writes outside
   it; `build` writes only the registered output paths. All other commands are pure
   reporters.

5. **CGO-free.** The module builds with `CGO_ENABLED=0` and links statically, matching the
   Alpine runtime image of the jonnify deployment. No package pulls in cgo. (This also fixes
   the database driver choice for the deferred progress store; see
   `docs/specs/90-deferred-auth.md`.)

6. **Parity with the Python source.** Where a behavior is ported from `build_page.py`
   (the manifest tables, the gate logic, the Snowflake math, the assembly substitutions),
   the Go implementation reproduces it exactly, including the constants and the
   string-matching semantics, so a page that passes under the Python `check` passes under
   `cms check` and vice versa.

## 6. Exit codes

| Code | Meaning |
|---|---|
| `0` | Success; for `check`/`build`/`audit`/`readiness`, all targets passed / clean. |
| `1` | Operational failure: at least one Apollo gate failed (`check`, `build`), at least one true broken link found (`audit` without `--fix`), or at least one module is not ready when the command treats not-ready as failure (`readiness`, when so configured). |
| `2` | Usage error: unknown page key, unknown subcommand, malformed flag, unreadable root. |

The precise mapping for each command is given in that command's spec. Cobra handles `2` for
flag/argument errors; the commands return `1` from their `RunE` for content failures.
