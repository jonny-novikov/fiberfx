# 01 — Manifest: the course data model

This document specifies `internal/manifest`, the in-code data model of the **Functional
Programming in Elixir** course. It is a direct Go port of the manifest tables in
`docs/elixir/kb/build_page.py` (the `CHAPTERS`, `MODULES`, `SUBPAGES`, and `PAGES`
structures, the `LINKABLE` set, and the derived helpers `_module_route`, `subpages_of`,
`allowed_routes`, `module_count`). The manifest is the **declared** source of truth — one of
the three the tool reconciles (`docs/specs/00-overview.md` §2).

This package backs `cms manifest`, `cms routes`, and supplies routes/statuses to `graph`,
`audit`, `readiness`, and `build`.

## 1. Status vocabulary

A page has exactly one status. Status governs whether the page renders as a navigable
**link** or a non-linking **card**.

| Status | Meaning | Renders as |
|---|---|---|
| `live` | Chapter-level: the chapter hub page is published. | link |
| `built` | The page exists and is published. | link |
| `planned` | Declared in the manifest, not yet authored. | non-linking card |
| `soon` | A dive/subpage announced ahead of its parent being linkable. | non-linking card |

The linkable set is:

```
LINKABLE = { "live", "built" }
```

A route is linkable iff its page's status is in `LINKABLE`. `planned` and `soon` are
deliberate placeholders, not errors (`docs/specs/03-link-audit.md` §2).

## 2. Data model

The Go types below carry the same fields as the Python dictionaries. Field names are the Go
spelling of the Python keys; JSON tags reproduce the Python key for `--json` parity.

```go
package manifest

// Status is one of "live", "built", "planned", "soon".
type Status string

const (
    StatusLive    Status = "live"
    StatusBuilt   Status = "built"
    StatusPlanned Status = "planned"
    StatusSoon    Status = "soon"
)

// Linkable reports whether a status renders as a link (live or built).
func (s Status) Linkable() bool { return s == StatusLive || s == StatusBuilt }

// Chapter is a top-level section (F0–F6).
type Chapter struct {
    ID     string `json:"id"`     // "F0".."F6"
    Title  string `json:"title"`  // "History", "Algebra", ...
    Slug   string `json:"slug"`   // "course", "algebra", ...
    Route  string `json:"route"`  // "/elixir/course", ...
    Status Status `json:"status"`
    One    string `json:"one"`    // one-line abstract
    Reuses string `json:"reuses"` // prerequisite note
    Accent string `json:"accent"` // design token: blue|gold|elixir|sage
}

// Dive is a nested item listed inside a module card (F0 only, in the manifest today).
type Dive struct {
    N      string `json:"n"`     // "F0.1.1"
    Title  string `json:"title"`
    Slug   string `json:"slug"`
    Status Status `json:"status"`
}

// Module is a numbered lesson within a chapter (F‹c›.0N).
type Module struct {
    N      string `json:"n"`      // "F1.01", "F2.06", ...
    Title  string `json:"title"`
    One    string `json:"one"`    // one-line abstract
    Slug   string `json:"slug"`   // route leaf under the chapter
    Status Status `json:"status"`
    Lab    bool   `json:"lab"`    // the ninth module of each chapter
    Dives  []Dive `json:"dives,omitempty"`
}

// Subpage is a deep-dive page under a module. Subpages are NOT counted as modules.
type Subpage struct {
    Slug  string `json:"slug"`
    Title string `json:"title"`
    One   string `json:"one"`
}
```

The data lives in package-level values, populated exactly as in `build_page.py`:

- `Chapters []Chapter` — the seven chapters F0–F6, in order, with the statuses from the
  Python `CHAPTERS`: F0, F1, F2 are `live`; F3–F6 are `planned`.
- `Modules map[string][]Module` — keyed by chapter ID, the module list per chapter, in
  order. The contents reproduce the Python `MODULES` table exactly, including:
  - F0 carries two modules, each with a three-item `Dives` list (statuses `soon`).
  - F1 carries nine modules, all `built`, the ninth (`plotting-lab`) a lab.
  - F2 carries nine modules: F2.01–F2.05 `built`, **F2.06 (`closures`), F2.07 (`adt`),
    F2.08 (`composition`) `planned`**, F2.09 (`pipeline-lab`) `planned` and a lab. The three
    `planned` interior modules are the canonical drift case
    (`docs/specs/04-readiness.md`).
  - F3–F6 carry nine `planned` modules each, the ninth a lab.
- `Subpages map[string][]Subpage` — keyed by module `N`, the deep-dive subpages. The Python
  `SUBPAGES` declares them for **F2.04** (3: `shape`, `tail-calls`, `patterns`) and **F2.05**
  (4: `map`, `filter`, `reduce`, `advanced`). A subpage's route becomes linkable only once
  its parent module is linkable (§4).

> Note on the brief vs. the ported table. The course brief (`fp-elixir-brief.md`) describes
> a richer F2 in which F2.06/F2.07/F2.08 are `built` hubs and F2.04–F2.08 carry sixteen
> subpages. The manifest in this package is the port of `build_page.py` as it stands —
> F2.06/07/08 `planned`, subpages declared for F2.04 and F2.05 only — because the manifest,
> not the brief, is the declared source of truth the tool reconciles. The gap between the
> brief and the ported table is exactly the drift that `readiness` surfaces
> (`docs/specs/04-readiness.md`); promoting the three modules (and adding the further
> subpages) is a manifest edit, after which `routes`/`graph`/`audit` reflect it
> automatically.

## 3. Route construction

Routes are computed, never stored redundantly. The root route is the package constant:

```
RootRoute = "/elixir"
```

- **Chapter route** is stored on the chapter (`Chapter.Route`, e.g. `/elixir/algebra`).
- **Module route** = `chapter.Route + "/" + module.Slug`
  (`/elixir/functional/pure`). `ModuleRoute(n string) (route string, status Status, ok bool)`
  scans `Chapters`×`Modules` for the module whose `N == n` and returns its route and status;
  this is the port of `_module_route`.
- **Subpage route** = `moduleRoute + "/" + subpage.Slug`
  (`/elixir/functional/recursion/shape`). `SubpagesOf(n string) []SubpageRoute` returns, for
  module `N`, each subpage's `(route, title, one)`; the port of `subpages_of`.
- **Dive** entries (F0) are listed inside their module card but do **not** form independent
  routes in the manifest; they have no standalone page registered in `PAGES`. They appear in
  `cms manifest` output and in the F0 module cards only.

## 4. The allowed-routes (linkable) set

`AllowedRoutes() map[string]struct{}` reproduces `allowed_routes()` exactly. It is the set of
clean routes that a page is permitted to link to — the basis of the `links` and `pager`
Apollo gates (`docs/specs/05-build-validate.md`) and of the audit's "true broken" test
(`docs/specs/03-link-audit.md`). It is built as:

1. Always include `RootRoute` (`/elixir`).
2. For each chapter whose `Status` is in `LINKABLE`, include `chapter.Route`.
3. For each module whose `Status` is in `LINKABLE`, include its module route.
4. For each module that has subpages, include each subpage route **only if the parent
   module's status is in `LINKABLE`** (a subpage is reachable only once its parent links).

The set therefore contains no `planned`/`soon` routes. As statuses are promoted in the
manifest, routes enter this set automatically, and the dependent gates and audit follow.

## 5. The PAGES build registry

`PAGES` is the build registry — the input table for `cms build` (`docs/specs/05-build-validate.md`).
It is separate from `Modules` because it maps **hand-authored content fragments** to
**output files and metadata**, including subpages and the landing/chapter-landing pages that
are not themselves rows in `Modules`.

```go
// Page is one buildable output: a fragment assembled into a standalone HTML page.
type Page struct {
    Key      string // registry key, e.g. "f1-1", "f2-landing", "landing"
    Fragment string // content fragment path, e.g. "content/f1-01-functions.html"
    Out      string // output filename, e.g. "functions.html"
    Title    string // <title> / og title
    Desc     string // meta description
}

// Pages is the ordered build registry, keyed by Key.
var Pages map[string]Page
var PageOrder []string // keys in registration order, for `--all` determinism
```

The registry reproduces the Python `PAGES` dict verbatim — the same keys, fragment paths,
output filenames, titles, and descriptions. It currently holds the landing page, the two F0
history pages, all nine F1 pages, the F2 chapter landing, the built F2 modules, and the
F2.04/F2.05 subpages — 34 entries. The output filenames are **not** always the module slug
(e.g. key `f2-3` → `higher-order-functions.html`, key `f2-4` → `recursion-functional.html`);
this slug-vs-filename divergence is precisely what the link audit repairs
(`docs/specs/03-link-audit.md`). `cms build` consumes `Page.Fragment`/`Page.Out`/`Page.Title`/
`Page.Desc`; the assembly is specified in `docs/specs/05-build-validate.md`.

`PageOrder` fixes the iteration order so `cms build --all` builds in registration order
deterministically.

## 6. Module count

`ModuleCount() int` reproduces `module_count()`:

```
sum over chapters whose ID != "F0" of len(Modules[chapter.ID])
```

The six numbered chapters F1–F6 are the spine — nine modules each — so the figure is **54**.
The optional F0 history chapter and its dives are surfaced separately and are **not** folded
into this count. `build` substitutes this value into `{{MODULE_COUNT}}`
(`docs/specs/05-build-validate.md`); the landing copy promises "fifty-four modules".

## 7. `cms manifest` — output

`cms manifest` prints the full manifest as an indented table, reproducing the Python
`cmd_manifest` layout: a header row, then each chapter with its modules indented, and each
module's dives indented one level further, closing with the total module count.

```
ID       STATUS   TITLE
F0       live     History  [/elixir/course]
  F0.1   built    The evolution of functional languages & runtimes
    F0.1.1 soon   From λ-calculus to LISP
    F0.1.2 soon   Types & laziness — the ML and Haskell branch
    F0.1.3 soon   The immutable turn — persistent data on the JVM & CLR
  F0.2   built    The evolution of Erlang, the BEAM & OTP
    ...
F1       live     Algebra  [/elixir/algebra]
  F1.01  built    What a function really is
  ...
  F1.09  built    Functions on the plane — a plotting lab (lab)
F2       live     Functional Programming  [/elixir/functional]
  F2.01  built    Pure functions & side effects
  ...
  F2.06  planned  Closures & partial application
  F2.07  planned  Algebraic data types
  F2.08  planned  Composition & pipelines
  F2.09  planned  The data-pipeline lab (lab)
...

total modules (incl. dives): 54
```

Formatting rules (ported):

- Header: `ID` left-padded to 8, `STATUS` to 8, then `TITLE`.
- Chapter line: `id` (8), `status` (8), `title`, then `  [route]`.
- Module line: two-space indent, `n` (6), `status` (8), `title`, ` (lab)` suffix when
  `Module.Lab`.
- Dive line: four-space indent, `n` (6), `status` (8), `title`.
- Footer: a blank line then `total modules (incl. dives): <ModuleCount()>`. (The label text
  is carried over verbatim from the source; the value is the F1–F6 spine count, 54.)

Output is deterministic: chapters in `Chapters` order, modules in `Modules[id]` order, dives
in `Module.Dives` order.

Exit code: `0`.

## 8. `cms routes` — output

`cms routes` prints one line per route — chapter, then each of its modules — tagged with the
link/card disposition. It reproduces the Python `cmd_routes`:

```
ROOT     live     link  /elixir
F0       live     link  /elixir/course
F0.1     built    link  /elixir/course/fp-evolution
F0.2     built    link  /elixir/course/beam-evolution
F1       live     link  /elixir/algebra
F1.01    built    link  /elixir/algebra/functions
...
F2       live     link  /elixir/functional
F2.01    built    link  /elixir/functional/pure
...
F2.06    planned  card  /elixir/functional/closures
F2.07    planned  card  /elixir/functional/adt
F2.08    planned  card  /elixir/functional/composition
F2.09    planned  card  /elixir/functional/pipeline-lab
F3       planned  card  /elixir/language
...
```

Rules (ported):

- First row is the synthetic root: `ROOT  live  link  /elixir`.
- Then, in `Chapters` order: the chapter row, then each module row in `Modules[id]` order.
- Columns: id (8), status (8), `link`/`card` (5), route. The disposition is `link` when the
  row's status is in `LINKABLE`, else `card`.
- Subpages are not listed by `cms routes` (parity with the Python command, which lists
  chapters and modules only). Subpage routes are surfaced by `cms graph`
  (`docs/specs/02-nav-graph.md`).

Output is deterministic. Exit code: `0`.
