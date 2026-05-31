# jonnify-cms

A Go content-management toolchain for the static **Functional Programming in Elixir**
course — the `/elixir` section of the jonnify site. The binary is named `cms`.

`cms` ports the Python `build_page.py` builder and its nine Apollo A+ quality gates
into Go, and adds the reconciliation and navigation tooling that the course needs as it
grows: a manifest reader, a route lister, a navigation-graph emitter, a link auditor with
a repair mode, a per-module readiness reconciler, the Apollo gate runner, and the branded
Snowflake stamp mint/decode pair.

The course content is a tree of pre-authored static HTML pages served byte-for-byte by the
jonnify Fiber server under `/elixir` (folder-routed: a clean URL maps to a file on disk).
`cms` does not run at request time and does not touch the server. It is an offline
authoring and maintenance tool operated from a workstation or CI.

- Module path: `github.com/jonny-novikov/jonnify-cms`
- Go: 1.25
- Dependencies: the Go standard library and `github.com/spf13/cobra`. No other third-party
  code. No network access. Output is deterministic.

## Status

`build` is **spec-complete but not yet runnable**: the hand-authored content fragments it
assembles (`content/*.html`) are not committed to this repository. The fragment registry,
the substitution set, the assembly order, and the gate suite are specified in full
(`docs/specs/05-build-validate.md`); `cms build` runs once the fragments land. Every other
command operates on the manifest and on the already-built pages under `/elixir`, and is
runnable as specified.

## Build and run

```bash
# from apps/jonnify-cms
go build -o bin/cms ./cmd/cms      # build the binary
./bin/cms --help                   # top-level help

go vet ./...
gofmt -l .                         # must print nothing
```

The course content lives outside this module, in the jonnify repo root under `elixir/`.
Commands that read the filesystem take a `--root DIR` flag that points at the built
`/elixir` tree; it defaults to `./elixir` resolved against the current working directory.

```bash
# run audits and readiness against the in-repo content tree
./bin/cms audit    --root ../../elixir
./bin/cms readiness --root ../../elixir --json
```

## Command surface

`cms` exposes the following commands. Each is specified in `docs/specs/`.

### `cms manifest`

Print the course manifest as a table: chapters (F0–F6), their modules, and the deep-dive
subpages, with each declared status. The numbered spine F1–F6 is nine modules per chapter,
**54 modules total**; the optional F0 history chapter and its dives are surfaced
separately and are not folded into that count.

```bash
cms manifest
```

Specification: `docs/specs/01-manifest.md`.

### `cms routes`

Print every route the manifest produces — chapter, module, and subpage — each tagged
`link` (a status in the linkable set `{live, built}`) or `card` (a non-linking
`planned`/`soon` placeholder), with the declared status.

```bash
cms routes
```

Specification: `docs/specs/01-manifest.md`, `docs/specs/02-nav-graph.md`.

### `cms graph [--format dot|mermaid|json] [--out FILE]`

Emit the structural navigation graph: nodes are pages, edges are the pager prev/next links,
hub-to-subpage links, and breadcrumbs. `--format` selects the serialization (`dot` for
Graphviz, `mermaid` for Markdown-embeddable diagrams, `json` for machine consumption);
default `dot`. `--out` writes to a file instead of standard output.

```bash
cms graph --format mermaid
cms graph --format json --out nav.json
```

Specification: `docs/specs/02-nav-graph.md`.

### `cms audit [--root DIR] [--fix]`

Walk the built `/elixir` tree, parse every internal `/elixir` href, and report **true
broken links** — an internal href whose route has no backing file — separately from
**deliberate placeholders** (planned modules rendered as non-linking cards, `<dt>`, or
prose, which are not errors). Two true broken links exist today, both slug mismatches
between a clean route and the orphan file that backs it. `--fix` renames each orphan file
to the canonical clean-URL filename that the file's own header already advertises, which
turns the broken links live.

```bash
cms audit --root ../../elixir            # report only
cms audit --root ../../elixir --fix      # report, then repoint orphan files
```

Specification: `docs/specs/03-link-audit.md`.

### `cms readiness [--root DIR] [--json]`

For each module, report `ready` or `not`, reconciling the three sources of truth: the
manifest's declared status, the presence of the backing file under `/elixir`, and the nine
Apollo gates run against that file. A module is **ready** when its file exists **and**
passes all nine gates. `--json` emits a machine-readable report instead of the table.

```bash
cms readiness --root ../../elixir
cms readiness --root ../../elixir --json
```

Specification: `docs/specs/04-readiness.md`.

### `cms check FILES...`

Run the nine Apollo A+ gates against one or more already-built HTML files and print a
per-gate PASS/FAIL report and an overall `STATUS: PASS|FAIL`. Exit status is non-zero if any
file fails any gate.

```bash
cms check ../../elixir/functional/pure.html ../../elixir/algebra/functions.html
```

Specification: `docs/specs/05-build-validate.md`.

### `cms stamp mint` / `cms stamp decode`

Mint and decode the branded Snowflake stamp that every page carries in its footer. `mint`
produces a 14-character branded id (a 3-character namespace plus an 11-character base62
Snowflake); `decode` reverses it to its namespace, raw Snowflake, node, sequence, and UTC
timestamp.

```bash
cms stamp mint                                            # ns=TSK, node=0, seq=0, now
cms stamp mint --ns TSK --node 0 --seq 0 --at 2026-01-27T15:11:37Z
cms stamp decode TSK0KHTOWnGLuC
```

Specification: `docs/specs/06-snowflake-stamp.md`.

### `cms build [--page KEY | --all]`

Port of `build_page.py`'s assemble step: read a hand-authored content fragment, substitute
the generated head, contents directory, chapter data, branded build id, build timestamp,
and module count, append the bootstrap reveal script, write the output page, then run the
nine Apollo gates against it. `--page KEY` builds one registered page; `--all` builds every
registered page. **Spec-complete**: runs once the `content/*` fragments are committed.

```bash
cms build --page f1-1
cms build --all
```

Specification: `docs/specs/05-build-validate.md`.

## The three sources of truth

`cms` exists to reconcile three independent descriptions of the same course. Each answers a
different question, and they drift apart as content is authored ahead of, or behind, the
manifest.

| Source | What it is | What it asserts |
|---|---|---|
| **Manifest** | The `internal/manifest` data tables, ported verbatim from `build_page.py` (`CHAPTERS`, `MODULES`, `SUBPAGES`, `PAGES`, the `LINKABLE = {live, built}` set). | The **declared** status of every chapter, module, and subpage, and therefore which routes render as links versus non-linking cards. |
| **Filesystem** | The built HTML pages under `/elixir`, folder-routed so a clean URL resolves to a file (`/elixir/a/b` → `a/b.html`, `/elixir/a` → `a/index.html`). | What pages **actually exist** and how they link to one another. |
| **Apollo gates** | The nine quality checks in `internal/apollo`, run against a built page's bytes. | Whether a page meets the **quality bar** (A+ across all nine gates). |

Two derived notions drive the tooling:

- **Readiness.** A module is *ready* when its backing file exists **and** that file passes
  all nine gates. Readiness is the filesystem-and-quality view; the manifest's declared
  status is a separate axis it is checked against. See `docs/specs/04-readiness.md`.
- **Drift.** A module *drifts* when the manifest still declares it `planned`/`soon` but the
  backing file exists and passes the gates — that is, the page is ready while the manifest
  has not caught up. The fix is to **promote** the manifest status to `built`, which flips
  the contents directory from a non-linking "soon" card to a live link. The canonical drift
  example today is F2.06 (closures), F2.07 (adt), and F2.08 (composition): all three are on
  disk and pass, yet the manifest still calls them `planned`. See `docs/specs/04-readiness.md`.

The reconciliation model, the package layout, and the design goals are specified in
`docs/specs/00-overview.md`.

## Documentation

| File | Contents |
|---|---|
| `docs/specs/00-overview.md` | Architecture, the reconciliation model, package layout, design goals. |
| `docs/specs/01-manifest.md` | The course manifest data model and the `PAGES` build registry. |
| `docs/specs/02-nav-graph.md` | Navigation-graph extraction; dot/mermaid/json output; URL-to-file resolution. |
| `docs/specs/03-link-audit.md` | The link audit, broken-vs-placeholder distinction, and `--fix` repoint. |
| `docs/specs/04-readiness.md` | Readiness detection and the manifest ↔ filesystem ↔ gates matrix. |
| `docs/specs/05-build-validate.md` | The `build_page.py` pipeline port and the nine Apollo gates. |
| `docs/specs/06-snowflake-stamp.md` | The branded Snowflake stamp specification. |
| `docs/specs/90-deferred-auth.md` | Deferred: external-auth login and per-learner progress (not this cycle). |
