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
**24 modules are built in the manifest; 32 are planned.** Of the 57 registered page fragments, **2 ship in
this bundle** as authorable source — both validated A+ this session. The remaining 55 are already authored
in the full repository (and most are deployed); their source is not part of this bundle.

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
| F3.03 Functions, modules & the pipe | `/elixir/language/modules` | built | **planned (deploy lags)** | — | — |
| **F3.04 Enumerables & streams (hub)** | `/elixir/language/enum-streams` | built | **planned (deploy lags)** | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.04 Enum, the eager workhorse | `/elixir/language/enum-streams/enum` | built | planned | **yes** | **yes** |
| &nbsp;&nbsp;↳ F3.04 Comprehensions | `/elixir/language/enum-streams/comprehensions` | built | planned | — | — |
| &nbsp;&nbsp;↳ F3.04 Lazy streams | `/elixir/language/enum-streams/streams` | built | planned | — | — |
| F3.05 Structs, maps & keyword lists | `/elixir/language/structs` | planned | planned | — | — |
| F3.06 Protocols & behaviours | `/elixir/language/protocols` | planned | planned | — | — |
| F3.07 Processes & the actor model | `/elixir/language/processes` | planned | planned | — | — |
| F3.08 OTP: GenServer & supervisors | `/elixir/language/otp` | planned | planned | — | — |
| F3.09 The process playground (lab) | `/elixir/language/playground` | planned | planned | — | — |

F3.02 and F3.03 also carry subpage hubs (3 each); F3.04 carries 3 (enum, comprehensions, streams).
F3 front-matter: `history`, `timeline`, `under-the-hood` (built in the manifest).

### F4 · Algorithms & Data Structures — `/elixir/algorithms` — accent sage — chapter planned

All nine planned: lists, trees, sorting, maps, HAMT, CHAMP, branded-CHAMP, dynamic-programming, and the
"watch a Branded Champ map grow" lab. F4.07 (`branded-champ`) is where the branded Snowflake / trie
convention used across the course gets its own module.

### F5 · Pragmatic Programming — `/elixir/pragmatic` — accent sage — chapter planned

All nine planned: Mix, ExUnit, typespecs, "let it crash", Tasks, **telemetry**, releases, performance, and
the supervision-tree lab. F5 is where the portal gains telemetry.

### F6 · Phoenix Framework — `/elixir/phoenix` — accent blue — chapter planned

All nine planned: request lifecycle, routing/plugs, Ecto, contexts, HEEx, **LiveView**, PubSub, deployment,
and the live-dashboard lab. F6 is where the portal gains Phoenix LiveView.

## The deploy-versus-local gap

The local manifest is ahead of the deployed contents page in one place worth tracking:

- **F3.03 (modules)** and **F3.04 (enum-streams)** are `built` in `build_page.py` but the published
  contents page still shows them as `planned` (non-linking cards). The live build stamp was minted earlier
  today, so the deploy predates these promotions.
- Practical reading: F3.03 and F3.04 are authored and pass the gates, but are not yet linked from the live
  site. Closing the gap is a deploy step, not an authoring step — except that this bundle only carries the
  F3.04 hub and its first subpage as source, so a local rebuild of F3.03 and the rest of F3.04 needs their
  fragments synced from the full repository first.

## Validation evidence (this session)

```text
id decode TSK0KHTOWnGLuC  ->  snowflake 274557032793636864 · 2026-01-27 15:11:37 UTC   [exact match]
extract-head              ->  _head.html, 16.3 KB, all colour tokens present
build --page f3-4         ->  enum-streams.html  · Apollo A+ · 9/9 gates PASS
build --page f3-4-en      ->  enumerables.html   · Apollo A+ · 9/9 gates PASS
build fidelity            ->  enum-streams.html == shipped reference (after normalising the stamp)
node --check (page JS)    ->  OK for both pages
suite.elixir.js ONLY=enum-streams  ->  11 PASS, 0 FAIL · images embedded: 0
```

Apollo gates that passed, per page: `containers`, `svg`, `no-future`, `voice`, `storage`, `motion`,
`degrade`, `links`, `pager`.

## Resume point and next actions

**Resume at F3.05, Structs.** The maps that `Enum` and `Stream` walked in F3.04 gain a name and a shape — a
struct. A natural hub plus three subpages: defining a struct over a Portal entity; enforcing keys and
defaults; pattern-matching on a struct's type. After structs: `protocols` (where the Enumerable protocol
from F3.04 pays off), `processes`, `otp`, then the `playground` lab.

Immediate steps, in order:

1. Sync the remaining `content/` fragments from the full repository (or accept that new modules build in
   isolation until the F3 landing and the F3.04 sibling fragments are present). The bundle ships 2 of 57
   fragments; the builder's `build --all` needs the full set.
2. Author the F3.05 hub + subpages into `content/`, following the page anatomy and the interactive contract
   in `SKILL.md`.
3. Promote F3.05 to `built`; register its subpages and pages with unique output filenames.
4. Relink F3.04's `.note` and pager forward to F3.05; light up F3.05 on the F3 landing (needs
   `content/f3-00-landing.html` present).
5. Verify routes, run the voice sweep, build, grade for A+, `node --check` the JS, and add a tagged
   validator block run with `ONLY="structs"`.
6. Regenerate `functional-programming-in-elixir.md` and `elixir-references.md`, then deliver.

## Known follow-ups

- The outline generator's hand-written "At a glance" summary prose lags the manifest (it predates the
  F2.09 and F3.01–F3.04 promotions); its per-chapter tables, derived from the manifest, are correct. Refresh
  the summary prose in `_gen_course_md.py` when convenient.
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
