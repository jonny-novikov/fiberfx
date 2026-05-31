# Elixir course — page readiness

A living tracker for *Functional Programming in Elixir* on the jonnify dark-editorial system,
published at `https://jonnify.fly.dev/elixir`. It records what the toolkit can do, what is
published, what is authored, and what comes next. Update it after every page promotion.

> Snapshot taken 2026-05-31. Sources of truth: `build_page.py` (the manifest and gates) and the
> live contents page fetched today. Where the local manifest and the deployed site disagree, both
> states are shown so the gap stays visible.

## This session — what was initialized

The attached guide was unpacked, verified safe, and stood up as a working toolkit. Every part runs.

| Step | Result |
|---|---|
| Unpack the guide bundle | 12 files: `build_page.py`, the two doc generators, the validator harness (4 files), two canonical content fragments, one built reference page, the README, the playbook. |
| Toolkit laid out at `/home/claude/elixir-course/` | builder + generators at root, `content/`, `validator/`, playbook, SKILL. |
| Branded Snowflake IDs verified | `TSK0KHTOWnGLuC` decodes to `274557032793636864` / `2026-01-27 15:11:37 UTC` — exact match to the verified example. Fresh mint + round-trip pass. |
| Design system extracted | `extract-head` wrote `_head.html` (16.3 KB); all colour tokens present (`--ink`, `--cream`, `--gold`, `--blue`, `--sage`, `--elixir`, `--burgundy`, `--line`). |
| Course-design docs generated | `functional-programming-in-elixir.md` (272 lines, 4 Mermaid graphs) and `elixir-references.md` (385 lines, 145 module references). Both report voice gate CLEAN. |
| SKILL initialized | `SKILL.md` — a self-contained, actionable authoring skill distilled from the playbook. |
| Two shipped pages built + graded | both **A+** across all nine Apollo gates. |
| Build fidelity | the freshly built `enum-streams.html` is byte-identical to the shipped reference after normalising the per-build stamp. |
| JavaScript | `node --check` passes on the longest script of each built page. |
| Headless validator | **11 PASS, 0 FAIL, 0 images embedded** (9 DOM checks + 2 mobile-overflow checks, scoped to the built page). |

## Readiness legend

- **Manifest** — status in the local `build_page.py` (`live` / `built` / `planned`).
- **Deployed** — what the published contents page at jonnify.fly.dev currently links (`published` / `planned`).
- **Source here** — whether the page fragment ships in this bundle's `content/` (so it can be built right now).
- **A+ this session** — whether it was built and graded A+ in this session.

## Toolkit components

| Component | File(s) | State |
|---|---|---|
| Page builder + manifest + gates + ID tools + CLI | `build_page.py` | operational |
| Design-system head | `_head.html` (from `HEAD_CSS`) | regenerated |
| Course outline generator | `_gen_course_md.py` → `functional-programming-in-elixir.md` | operational |
| References generator | `_gen_refs_md.py` → `elixir-references.md` | operational |
| Headless DOM validator | `validator/validator.js` | operational (Playwright + chromium resolve here) |
| Course validator suite | `validator/suite.elixir.js` | operational (run with `ONLY=<tag>` to scope) |
| Visual-regression option | `validator/visual.js` | available; needs a one-time `npm install` in `validator/` for `pixelmatch`/`pngjs` |
| Authoring skill | `SKILL.md` | initialized |
| Authoring playbook | `course-authoring-playbook.md` | reference, copied into the toolkit |

## Page readiness by chapter

Scope is six numbered chapters of nine modules each (54), plus the optional two-part F0 history chapter.
**32 modules are built in the manifest; 24 are planned.** Of the 87 registered page fragments, the whole of F3
(9 modules) plus the F4 landing and F4.01, F4.02, and F4.03 are authorable source in this working tree and were
validated A+ here. The earlier chapters (F0–F2 and F3.01–F3.03) are authored in the full repository and most are
deployed; their source is not part of this working tree.

### F0 · History — `/elixir/course` — accent blue

| Module | Route | Manifest | Deployed | Source here | A+ this session |
|---|---|---|---|---|---|
| F0.1 The evolution of functional languages & runtimes | `/elixir/course/fp-evolution` | built | published | — | — |
| F0.2 The evolution of Erlang, the BEAM & OTP | `/elixir/course/beam-evolution` | built | published | — | — |

Chapter front-matter (not counted as modules): `course` landing/contents, and the `csharp` onramp
("Elixir for C# developers"). Both published.

### F1 · Algebra — `/elixir/algebra` — accent gold

All nine modules built and published.

| Module | Route | Manifest | Deployed |
|---|---|---|---|
| F1.01 What a function really is | `/elixir/algebra/functions` | built | published |
| F1.02 The substitution model | `/elixir/algebra/substitution` | built | published |
| F1.03 Composition, f∘g | `/elixir/algebra/composition` | built | published |
| F1.04 Immutability & binding | `/elixir/algebra/immutability` | built | published |
| F1.05 Sets, sequences & mappings | `/elixir/algebra/collections` | built | published |
| F1.06 Recursion & induction | `/elixir/algebra/recursion` | built | published |
| F1.07 Higher-order operators (Σ, Π) | `/elixir/algebra/higher-order` | built | published |
| F1.08 Equations & pattern matching | `/elixir/algebra/pattern-matching` | built | published |
| F1.09 Functions on the plane — a plotting lab | `/elixir/algebra/plotting-lab` | built | published |

### F2 · Functional Programming — `/elixir/functional` — accent elixir

All nine modules built and published; F2.04–F2.08 carry deep-dive subpage hubs (16 subpages total).

| Module | Route | Manifest | Deployed | Subpages |
|---|---|---|---|---|
| F2.01 Pure functions & side effects | `/elixir/functional/pure` | built | published | — |
| F2.02 Immutability & persistent data | `/elixir/functional/persistence` | built | published | — |
| F2.03 Higher-order functions | `/elixir/functional/higher-order` | built | published | — |
| F2.04 Recursion patterns & tail calls | `/elixir/functional/recursion` | built | published | 3 (shape, tail-calls, patterns) |
| F2.05 map / filter / reduce (folds) | `/elixir/functional/folds` | built | published | 4 (map, filter, reduce, advanced) |
| F2.06 Closures & partial application | `/elixir/functional/closures` | built | published | 3 (environment, capture, currying) |
| F2.07 Algebraic data types | `/elixir/functional/adt` | built | published | 3 (product, sum, matching) |
| F2.08 Composition & pipelines | `/elixir/functional/composition` | built | published | 3 (compose, pipe, pipeline) |
| F2.09 The data-pipeline lab | `/elixir/functional/pipeline-lab` | built | published | — |

### F3 · The Elixir Language — `/elixir/language` — accent elixir

This is the active chapter and the focus of the gap below.

| Module | Route | Manifest | Deployed | Source here | A+ this session |
|---|---|---|---|---|---|
| F3.01 Values, types & IEx | `/elixir/language/values` | built | published | — | — |
| F3.02 Pattern matching & the match operator | `/elixir/language/match` | built | published | — | — |
| **F3.03 Functions, modules & the pipe (hub)** | `/elixir/language/modules` | built | **planned (deploy lags)** | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.03.1 Defining functions | `/elixir/language/modules/functions` | built | planned | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.03.2 Organising with modules | `/elixir/language/modules/organising` | built | planned | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.03.3 The pipe operator | `/elixir/language/modules/pipe` | built | planned | **yes** | **yes** |
| **F3.04 Enumerables & streams (hub)** | `/elixir/language/enum-streams` | built | **planned (deploy lags)** | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.04 Enum, the eager workhorse | `/elixir/language/enum-streams/enum` | built | planned | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.04 Comprehensions | `/elixir/language/enum-streams/comprehensions` | built | planned | — | — |
| &nbsp;&nbsp;↳ F3.04 Lazy streams | `/elixir/language/enum-streams/streams` | built | planned | — | — |
| **F3.05 Structs, maps & keyword lists (hub)** | `/elixir/language/structs` | built | **planned (deploy lags)** | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.05 Defining a struct | `/elixir/language/structs/define` | built | planned | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.05 Enforcing keys & defaults | `/elixir/language/structs/defaults` | built | planned | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.05 Matching on a struct's type | `/elixir/language/structs/matching` | built | planned | **yes** | **yes** |
| **F3.06 Protocols & behaviours (hub)** | `/elixir/language/protocols` | built | **planned (deploy lags)** | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.06 Defining a protocol | `/elixir/language/protocols/define` | built | planned | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.06 Implementing for a struct | `/elixir/language/protocols/defimpl` | built | planned | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.06 Behaviours & callbacks | `/elixir/language/protocols/behaviours` | built | planned | **yes** | **yes** |
| **F3.07 Processes & the actor model (hub)** | `/elixir/language/processes` | built | **planned (deploy lags)** | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.07 Spawning a process | `/elixir/language/processes/spawn` | built | planned | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.07 Sending & receiving messages | `/elixir/language/processes/messages` | built | planned | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.07 Holding state in a loop | `/elixir/language/processes/state` | built | planned | **yes** | **yes** |
| **F3.08 OTP: GenServer & supervisors (hub)** | `/elixir/language/otp` | built | **planned (deploy lags)** | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.08 The GenServer behaviour | `/elixir/language/otp/genserver` | built | planned | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.08 Synchronous call, asynchronous cast | `/elixir/language/otp/call-cast` | built | planned | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.08 Supervisors & restart strategies | `/elixir/language/otp/supervisors` | built | planned | **yes** | **yes** |
| **F3.09 The process playground (lab)** | `/elixir/language/playground` | built | **planned (deploy lags)** | **yes** | **yes** |

F3.02 and F3.03 also carry subpage hubs (3 each); F3.04 carries 3 (enum, comprehensions, streams);
F3.05 carries 3 (define, defaults, matching); F3.06 carries 3 (define, defimpl, behaviours); F3.07 carries 3
(spawn, messages, state); F3.08 carries 3 (genserver, call-cast, supervisors). F3.09 is a **single-page lab**
with no subpages \u2014 a comprehensive interactive playground rather than a hub-plus-dives module, which is the
intended shape for the chapter's capstone lab.
F3 front-matter: `history`, `timeline`, `under-the-hood` (built in the manifest).

F3.03 (functions, modules & the pipe) was already `built` in the manifest with `SUBPAGES["F3.03"]` and four
registered PAGES, but its four fragment files were absent from this working tree; they have now been authored
here and validated A+ (the hub plus `functions`, `organising`, and `pipe`). Following the F3 convention, the
dives carry two teaching sections each rather than the F4.02/F4.03-style advanced section. The running example
is a learning `Portal`: a learner's scores piped through `Portal.average/1` and `Portal.grade/1` to the atom
`:b`. The hub frames the function/module/pipe trio; the functions dive shows the same guarded `grade/1` as a
named, anonymous, and captured function; the organising dive builds the `Portal` module with an attribute,
`alias`, and `import` (plus `@moduledoc`/`@doc` and the one-module-per-file convention); the pipe dive contrasts
nested calls with the pipeline and states the value-first rewrite rule, `x |> f(a, b) == f(x, a, b)`. The hub
pager goes back to F3.02 (`/elixir/language/match`) and the last dive (pipe) forward to the chapter overview
(`/elixir/language`); the hub note and the pipe note both link forward to the built F3.04. The F3 chapter
landing fragment is not in this working tree, so no landing card relink was needed (F3.03 was already built in
the manifest).

### F4 · Algorithms & Data Structures — `/elixir/algorithms` — accent sage — **chapter live**

The chapter is open: the landing is built and `/elixir/algorithms` is linkable. F4.01, F4.02, and F4.03 are
built (each a hub plus three dives; F4.02 and F4.03 carry an advanced section per dive); F4.04–F4.09 are
planned, and each carries a
three-dive roadmap in the manifest so the navigation
shows the whole path. F4.05–F4.07 (HAMT → CHAMP → **branded CHAMP**) are the chapter spine, where the branded
Snowflake / trie convention used across the course gets its own modules; F4.09 is the "watch a branded CHAMP
map grow" lab.

| Page | Route | Local | Deployed | A+ | Validator |
| --- | --- | --- | --- | --- | --- |
| **F4 landing** | `/elixir/algorithms` | built | **planned (deploy lags)** | **yes** | **yes** |
| **F4.01 Lists, recursion & complexity (hub)** | `/elixir/algorithms/lists` | built | planned | **yes** | **yes** |
| ↳ F4.01.1 Cons cells & the shape of a list | `/elixir/algorithms/lists/cons` | built | planned | **yes** | **yes** |
| ↳ F4.01.2 Recursion over lists | `/elixir/algorithms/lists/recursion` | built | planned | **yes** | **yes** |
| ↳ F4.01.3 Complexity & big-O on the BEAM | `/elixir/algorithms/lists/big-o` | built | planned | **yes** | **yes** |
| **F4.02 Trees & traversals (hub)** | `/elixir/algorithms/trees` | built | planned | **yes** | **yes** |
| ↳ F4.02.1 Binary trees & recursive shape | `/elixir/algorithms/trees/shape` | built | planned | **yes** | **yes** |
| ↳ F4.02.2 Depth-first: pre, in, post-order | `/elixir/algorithms/trees/dfs` | built | planned | **yes** | **yes** |
| ↳ F4.02.3 Breadth-first & balance | `/elixir/algorithms/trees/bfs` | built | planned | **yes** | **yes** |
| **F4.03 Sorting & searching (hub)** | `/elixir/algorithms/sorting` | built | planned | **yes** | **yes** |
| ↳ F4.03.1 Merge & quicksort | `/elixir/algorithms/sorting/sorts` | built | planned | **yes** | **yes** |
| ↳ F4.03.2 Linear & binary search | `/elixir/algorithms/sorting/search` | built | planned | **yes** | **yes** |
| ↳ F4.03.3 Stability & sort cost | `/elixir/algorithms/sorting/cost` | built | planned | **yes** | **yes** |
| F4.04–F4.08 (+ 3 dives each) | `…/maps … /dynamic-programming` | planned | planned | — | — |
| F4.09 Watch a branded CHAMP map grow (lab) | `/elixir/algorithms/champ-lab` | planned | planned | — | — |

The F4 landing is a hand-authored fragment (`content/f4-00-landing.html`) with an SVG roadmap of the nine
modules and a hand-written `.mods` directory (the `{{CONTENTS}}` placeholder renders *all* chapters, so a
chapter-only directory is written by hand using the head's card classes). F4.01's, F4.02's, and F4.03's three
dives each are real SUBPAGES; the per-module `dives` lists drive the display roadmap on the contents page and the landing.

F4.02 carries a dedicated **advanced section per page**, as requested: the hub closes on balance and the road to
tries (BST O(log n), degenerate chains, AVL/red-black, and a HAMT's branch-32 ⇒ log₃₂ n shallowness); the shape
dive adds structural sharing on insert (a second static SVG of the rebuilt path vs shared subtrees); the dfs
dive generalises the three orders into one parameterised fold and notes the explicit-stack iterative form; the
bfs dive contrasts a balanced tree against a degenerate chain (a second static SVG) to make the O(log n)-vs-O(n)
split concrete. The running structure throughout is one seven-node BST (`12 · 8 · 30 · 5 · 10 · 20 · 42`), so
in-order is sorted by construction.

F4.03 continues the same advanced-section-per-page treatment, and reuses F4.02's data directly: the array it
sorts and searches is that BST's in-order output, `[5, 8, 10, 12, 20, 30, 42]`, and the search target is `20`
(binary path 12 → 30 → 20, three comparisons; linear, five). The hub frames sorting and searching as one
bargain — pay O(n log n) once, then every lookup is O(log n) — and previews the comparison floor; the sorts
dive shows merge (split/merge over `[8, 3, 5, 1]`) and quicksort (pivot/partition) as one divide-and-conquer
idea, with an advanced section on worst cases and `Enum.sort` being a stable merge sort; the search dive
contrasts linear O(n) with binary O(log n), and its advanced section makes the BEAM-specific point that binary
search needs O(1) random access, so a list forces O(n) and sorted data wants a tuple or a tree; the cost dive
ranks merge / quick / insertion on average, worst, space, and stability, then proves the Ω(n log n) lower bound
with a decision-tree SVG (n! leaves, height ≥ log₂(n!) ≈ n log n).

### F5 · Pragmatic Programming — `/elixir/pragmatic` — accent sage — chapter planned

All nine planned: Mix, ExUnit, typespecs, "let it crash", Tasks, **telemetry**, releases, performance, and
the supervision-tree lab. F5 is where the portal gains telemetry.

### F6 · Phoenix Framework — `/elixir/phoenix` — accent blue — chapter planned

All nine planned: request lifecycle, routing/plugs, Ecto, contexts, HEEx, **LiveView**, PubSub, deployment,
and the live-dashboard lab. F6 is where the portal gains Phoenix LiveView.

## The deploy-versus-local gap

The local manifest is ahead of the deployed contents page in one place worth tracking:

- **F3.03 (modules)**, **F3.04 (enum-streams)**, **F3.05 (structs)**, **F3.06 (protocols & behaviours)**,
  **F3.07 (processes & the actor model)**, **F3.08 (OTP: GenServer & supervisors)**, and **F3.09 (the
  process playground lab)** are `built` in `build_page.py` but the published contents page still shows them as
  `planned` (non-linking cards). With F3.09 done, **F3 is 9/9 built locally** \u2014 the whole chapter.
- **F4 is now open locally**: the chapter is `live`, the F4 landing (`/elixir/algorithms`), **F4.01**, and
  **F4.02** (each a hub + three dives) are built, and the deployed site has not seen any of it yet. The live
  build stamp predates all of these promotions.
- Practical reading: F3.03 through F3.09 and the F4 landing + F4.01 + F4.02 are authored and pass the gates, but
  are not yet linked from the live site. Closing the gap is a deploy step, not an authoring step — except that
  this bundle only carries the fragments authored here (F3.04–F3.09 and F4.00/F4.01/F4.02), so a local
  `build --all` of the rest needs the remaining fragments synced from the full repository first.

## Validation evidence (this session)

```text
id decode TSK0KHTOWnGLuC  ->  snowflake 274557032793636864 · 2026-01-27 15:11:37 UTC   [exact match]
build --page f4-3         ->  sorting.html               · Apollo A+ · 9/9 gates PASS
build --page f4-3-sorts   ->  sorting-sorts.html         · Apollo A+ · 9/9 gates PASS
build --page f4-3-search  ->  sorting-search.html        · Apollo A+ · 9/9 gates PASS
build --page f4-3-cost    ->  sorting-cost.html          · Apollo A+ · 9/9 gates PASS  (2 SVGs)
rebuild f4-2, f4-2-bfs, f4-landing  ->  A+ (F4.02 hub + bfs notes + landing F4.03 card relinked → /elixir/algorithms/sorting)
node --check (page JS)    ->  OK for all four F4.03 pages
routes                    ->  88 allowed (was 84); F4.04 /algorithms/maps correctly absent
suite.elixir.js ONLY=F4.03  ->  44 PASS desktop + 8 PASS mobile · 0 FAIL · images embedded: 0

build --page f3-3         ->  modules.html               · Apollo A+ · 9/9 gates PASS
build --page f3-3-fn      ->  modules-functions.html     · Apollo A+ · 9/9 gates PASS
build --page f3-3-org     ->  modules-organising.html    · Apollo A+ · 9/9 gates PASS
build --page f3-3-pipe    ->  modules-pipe.html          · Apollo A+ · 9/9 gates PASS
F3.03 was already wired in the manifest (built + SUBPAGES + 4 PAGES); only the 4 fragments were missing → authored
node --check (page JS)    ->  OK for all four F3.03 pages
suite.elixir.js ONLY=F3.03  ->  39 PASS desktop + 8 PASS mobile · 0 FAIL · images embedded: 0
```

F4.03's pages are validated by deterministic select-and-read sequences over the sorted seven-element array: the
hub cycles sort → search → cost (role text, the first box's sage stroke, and the result line moving from the
sorted sequence to "found 20" to the "log n" cost); the sorts dive reads the merge step and the `[1, 3, 5, 8]`
result with the split divider at full opacity, then the quicksort pivot step with the pivot bar gold; the search
dive reads the O(n) / O(log n) badge and the "one by one" / "halves" step text with the first binary mid box
turning blue; the cost dive reads the algorithm name and stability across merge (stable), quick (not stable),
and insertion (stable) with the average-case badge.

Apollo gates that passed, per page: `containers`, `svg`, `no-future`, `voice`, `storage`, `motion`,
`degrade`, `links`, `pager`.

## Resume point and next actions

**The F4 chapter is open; F4.01, F4.02, and F4.03 are complete.** The chapter is `live`, the landing
(`/elixir/algorithms`) is built, and **F4.01 (Lists, recursion & complexity)**, **F4.02 (Trees & traversals)**,
and **F4.03 (Sorting & searching)** each ship as a hub plus three dives. F4.02 and F4.03 carry a dedicated
advanced section on every page, all A+ and green in the validator (F4.03: 44 desktop + 8 mobile = 52 PASS).
F4.02's hub and bfs notes and the landing's F4.03 card were relinked to `/elixir/algorithms/sorting`; F4.03's
last-subpage (cost) pager goes forward to the chapter overview `/elixir/algorithms`, and both the F4.03 hub note
and the cost note name **F4.04 — Maps, sets & hashing** as the next module, currently unlinked ("in production").
The chapter accent is sage (primary `solid-select` + diagram highlights); `.ex`/`code.inl` stay the global
Elixir purple. **Resume at F4.04 — Maps, sets & hashing** (`slug` "maps", route `/elixir/algorithms/maps`); the
three dives already named in the manifest roadmap are `maps`, `sets`, and `hashing` — a likely first dive is
`maps`. The bridge in is F4.03's closing line: hashing trades ordering away to make lookup O(1) on average,
which is the door into the HAMT/CHAMP/branded-CHAMP spine (F4.05–F4.07).

Immediate steps for F4.04, in order:

1. Author the F4.04 hub + three dive subpages into `content/` (suggested fragments `f4-04-maps.html`,
   `f4-04-1-maps.html`, `f4-04-2-sets.html`, `f4-04-3-hashing.html`), following the page anatomy in `SKILL.md`,
   with an advanced section per page to match F4.02/F4.03. The bridge back is F4.03: sorting buys O(log n) search
   by ordering; a hash buys O(1)-average lookup with no ordering at all. Keep prefixes off `st` and unique per
   page (the hub `so`/`sr`/`se`/`co` codes are taken by F4.03).
2. Promote F4.04 to `built`; the `dives` roadmap is already in the manifest — add `SUBPAGES["F4.04"]` (maps,
   sets, hashing) and register PAGES with unique output filenames (e.g. `maps.html`, `maps-sets.html`,
   `maps-hashing.html`).
3. Relink F4.03's forward pointers: the F4.03 hub note and the cost note both name **F4.04 — Maps, sets &
   hashing (in production)** without a link — wrap them in `<a href="/elixir/algorithms/maps">` and drop "(in
   production)". The F4.03 hub pager back stays `/elixir/algorithms/trees`; the cost (last subpage) pager forward
   stays `/elixir/algorithms`. On the F4 landing, change the F4.04 card from `<div class="mod is-quiet">` to a
   linkable `<a class="mod" href="/elixir/algorithms/maps">` and swap its pill `planned` → `built`.
4. Verify routes, run the voice sweep (incl. JS strings and comments — watch for a stray dismissive adverb in
   visible prose), build, grade for A+, `node --check` the JS, and add a tagged validator block run with
   `ONLY="F4.04"`.
5. Regenerate `functional-programming-in-elixir.md` and `elixir-references.md`, update this tracker, then
   deliver.

**Deferred wiring (not authoring):** lighting up F3.05–F3.09 on the F3 chapter landing needs
`content/f3-00-landing.html`, which is not in this bundle. The deploy gap above is the same kind of step — the
live site still trails the local manifest (now including the whole of F3 and the F4 landing + F4.01 + F4.02 +
F4.03). Both are sync/deploy steps to run against the full repository.

## Known follow-ups

- The outline generator's hand-written "At a glance" summary prose lags the manifest (it predates the
  F2.09, F3.01–F3.09, and F4 promotions); its per-chapter tables, derived from the manifest, are correct and now
  show F3 fully built, the F4 chapter open with F4.01, F4.02, and F4.03 as built hubs (three nested dives each),
  and F4.04–F4.08 with their three-dive roadmaps. Refresh the summary prose in `_gen_course_md.py` when convenient.
- Wiring references into the builder as a `references` manifest field with a `render_references()` footer
  (rather than a separate document) remains an open enhancement noted in the playbook.

## How to continue

Read `SKILL.md` first (it is the operational guide), then `course-authoring-playbook.md` for the full
reasoning and the copy-paste appendices. The CLI:

```bash
python3 build_page.py manifest        # the current chapter/module state
python3 build_page.py routes          # every linkable route
python3 build_page.py build --page KEY
python3 build_page.py check OUT.html  # the nine gates + grade
python3 build_page.py id mint
BASE_URL="file:///home/claude/elixir-course" ONLY="<tag>" node validator/suite.elixir.js
```
