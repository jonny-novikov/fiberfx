# Course map — the F0-F6 manifest

The single source of truth for chapters, modules, routes, and statuses, mirrored from the build manifest. The course teaches functional programming twice — first as mathematics (F1), then as Elixir (F2 onward) — across an optional History prologue (F0) and six core chapters (F1–F6) of nine modules each (fifty-four numbered modules). Use this to choose routes, set the crumbs and pager, and decide whether a target is linkable.

## Conventions

- **F-id format.** F0 uses a single-digit module id: `F0.1`, `F0.2`. F1–F6 use a two-digit module id: `F1.01` … `F6.09`. A deep-dive subpage uses a three-segment id under its module: `F2.04.1`, `F2.05.4`.
- **Route.** A chapter lives at `/elixir/<chapter-slug>`; a module at `/elixir/<chapter-slug>/<module-slug>`; a deep-dive subpage at `/elixir/<chapter-slug>/<module-slug>/<subpage-slug>`. The URL tree mirrors the reading tree.
- **The lab.** The `.09` module of each chapter (`F0` excepted) is its interactive capstone lab — a richer build-it-yourself page.
- **Status → linkability.** `live` and `built` are **linkable** (render as an `<a href>`). `planned` and `soon` are **not linkable** (render as a non-linking card, dimmed and dashed). The Apollo `links` gate fails on any `href` to a non-linkable route. A subpage becomes linkable only once its parent module is linkable.
- **Hub vs leaf.** A hub module is an overview page plus several deep-dive subpages, linked by the pager and on-page cards; a leaf module is a single self-contained lesson.

## Live now

`live` chapters: **F0, F1, F2**. `built` (and therefore linkable) modules: **all nine of F1**, **F2.01–F2.05** plus their sixteen-page subset of F2 subpages, and **both F0 History essays**. F2.06–F2.09 and all of F3–F6 are `planned`.

## F0 · History — `/elixir/course`

Optional prologue: where the languages and the runtimes came from.

| Module | Route | Status |
|---|---|---|
| F0.1 · The evolution of functional languages & runtimes | `/elixir/course/fp-evolution` | built |
| F0.2 · The evolution of Erlang, the BEAM & OTP | `/elixir/course/beam-evolution` | built |

## F1 · Algebra — `/elixir/algebra`

The mathematical foundation; every idea is carried across to Elixir in F2.

| Module | Route | Status |
|---|---|---|
| F1.01 · What a function really is | `/elixir/algebra/functions` | built |
| F1.02 · The substitution model | `/elixir/algebra/substitution` | built |
| F1.03 · Composition, f∘g | `/elixir/algebra/composition` | built |
| F1.04 · Immutability & binding | `/elixir/algebra/immutability` | built |
| F1.05 · Sets, sequences & mappings | `/elixir/algebra/collections` | built |
| F1.06 · Recursion & induction | `/elixir/algebra/recursion` | built |
| F1.07 · Higher-order operators (Σ, Π) | `/elixir/algebra/higher-order` | built |
| F1.08 · Equations & pattern matching | `/elixir/algebra/pattern-matching` | built |
| F1.09 · Functions on the plane — a plotting lab | `/elixir/algebra/plotting-lab` | built · lab |

## F2 · Functional Programming — `/elixir/functional`

The same foundations as working Elixir; later modules expand into hubs with deep-dive subpages.

| Module | Route | Status |
|---|---|---|
| F2.01 · Pure functions & side effects | `/elixir/functional/pure` | built |
| F2.02 · Immutability & persistent data | `/elixir/functional/persistence` | built |
| F2.03 · Higher-order functions | `/elixir/functional/higher-order` | built |
| F2.04 · Recursion patterns & tail calls (hub) | `/elixir/functional/recursion` | built · hub |
| ↳ F2.04.1 · The shape of recursion | `/elixir/functional/recursion/shape` | built |
| ↳ F2.04.2 · Tail calls & accumulators | `/elixir/functional/recursion/tail-calls` | built |
| ↳ F2.04.3 · Recursion patterns | `/elixir/functional/recursion/patterns` | built |
| F2.05 · map / filter / reduce (folds) (hub) | `/elixir/functional/folds` | built · hub |
| ↳ F2.05.1 · map | `/elixir/functional/folds/map` | built |
| ↳ F2.05.2 · filter | `/elixir/functional/folds/filter` | built |
| ↳ F2.05.3 · reduce | `/elixir/functional/folds/reduce` | built |
| ↳ F2.05.4 · Advanced folds | `/elixir/functional/folds/advanced` | built |
| F2.06 · Closures & partial application (hub) | `/elixir/functional/closures` | planned |
| ↳ F2.06.1 · Capturing the environment | `/elixir/functional/closures/environment` | planned |
| ↳ F2.06.2 · The capture operator | `/elixir/functional/closures/capture` | planned |
| ↳ F2.06.3 · Partial application & currying | `/elixir/functional/closures/currying` | planned |
| F2.07 · Algebraic data types (hub) | `/elixir/functional/adt` | planned |
| ↳ F2.07.1 · Product types | `/elixir/functional/adt/product` | planned |
| ↳ F2.07.2 · Sum types | `/elixir/functional/adt/sum` | planned |
| ↳ F2.07.3 · Pattern matching on data | `/elixir/functional/adt/matching` | planned |
| F2.08 · Composition & pipelines (hub) | `/elixir/functional/composition` | planned |
| ↳ F2.08.1 · Function composition | `/elixir/functional/composition/compose` | planned |
| ↳ F2.08.2 · The pipe operator | `/elixir/functional/composition/pipe` | planned |
| ↳ F2.08.3 · Building pipelines | `/elixir/functional/composition/pipeline` | planned |
| F2.09 · The data-pipeline lab | `/elixir/functional/pipeline-lab` | planned · lab |

## F3 · The Elixir Language — `/elixir/language` (planned)

| Module | Route |
|---|---|
| F3.01 · Values, types & IEx | `/elixir/language/values` |
| F3.02 · Pattern matching & the match operator | `/elixir/language/match` |
| F3.03 · Functions, modules & the pipe | `/elixir/language/modules` |
| F3.04 · Enumerables & streams | `/elixir/language/enum-streams` |
| F3.05 · Structs, maps & keyword lists | `/elixir/language/structs` |
| F3.06 · Protocols & behaviours | `/elixir/language/protocols` |
| F3.07 · Processes & the actor model | `/elixir/language/processes` |
| F3.08 · OTP: GenServer & supervisors | `/elixir/language/otp` |
| F3.09 · The process playground | `/elixir/language/playground` (lab) |

## F4 · Algorithms & Data Structures — `/elixir/algorithms` (planned)

| Module | Route |
|---|---|
| F4.01 · Lists, recursion & complexity | `/elixir/algorithms/lists` |
| F4.02 · Trees & traversals | `/elixir/algorithms/trees` |
| F4.03 · Sorting & searching | `/elixir/algorithms/sorting` |
| F4.04 · Maps, sets & hashing | `/elixir/algorithms/maps` |
| F4.05 · Hash Array Mapped Tries (HAMT) | `/elixir/algorithms/hamt` |
| F4.06 · CHAMP maps | `/elixir/algorithms/champ` |
| F4.07 · Branded Champ maps | `/elixir/algorithms/branded-champ` |
| F4.08 · Dynamic programming & advanced problems | `/elixir/algorithms/dynamic-programming` |
| F4.09 · Watch a Branded Champ map grow | `/elixir/algorithms/champ-lab` (lab) |

## F5 · Pragmatic Programming — `/elixir/pragmatic` (planned)

| Module | Route |
|---|---|
| F5.01 · Project structure & Mix | `/elixir/pragmatic/mix` |
| F5.02 · Testing with ExUnit & doctests | `/elixir/pragmatic/testing` |
| F5.03 · Documentation & typespecs | `/elixir/pragmatic/typespecs` |
| F5.04 · Error handling & "let it crash" | `/elixir/pragmatic/let-it-crash` |
| F5.05 · Concurrency patterns & Tasks | `/elixir/pragmatic/tasks` |
| F5.06 · Telemetry, logging & observability | `/elixir/pragmatic/telemetry` |
| F5.07 · Dependencies, releases & deployment | `/elixir/pragmatic/releases` |
| F5.08 · Performance & profiling | `/elixir/pragmatic/performance` |
| F5.09 · Let it crash — a supervision tree that heals | `/elixir/pragmatic/supervision-lab` (lab) |

## F6 · Phoenix Framework — `/elixir/phoenix` (planned)

| Module | Route |
|---|---|
| F6.01 · Architecture & the request lifecycle | `/elixir/phoenix/lifecycle` |
| F6.02 · Routing, controllers & plugs | `/elixir/phoenix/routing` |
| F6.03 · Ecto: schemas, changesets & queries | `/elixir/phoenix/ecto` |
| F6.04 · Contexts & domain design | `/elixir/phoenix/contexts` |
| F6.05 · Templates, components & HEEx | `/elixir/phoenix/heex` |
| F6.06 · Phoenix LiveView fundamentals | `/elixir/phoenix/liveview` |
| F6.07 · PubSub, channels & real-time | `/elixir/phoenix/pubsub` |
| F6.08 · Auth, deployment & going live | `/elixir/phoenix/deployment` |
| F6.09 · The live dashboard | `/elixir/phoenix/live-dashboard` (lab) |

## Linkable-route rule, restated

When setting any `href` in a fragment (crumbs, pager, in-prose links, dive cards):

- The route's status is `live` or `built` → link it with `<a href>`.
- The route's status is `planned` or `soon` → do not link it; reference it as plain text or a dimmed `.mod.is-quiet` card.
- A subpage is linkable only if its parent module is linkable.

When in doubt, the only currently linkable internal routes are `/elixir`, the three live chapter roots (`/elixir/course`, `/elixir/algebra`, `/elixir/functional`), the built modules listed above (all F1, F2.01–F2.05, both F0 essays), and the built F2.04 / F2.05 subpages.
