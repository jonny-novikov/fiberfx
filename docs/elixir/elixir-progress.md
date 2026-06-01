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

Scope is six numbered chapters; five carry nine modules and F4 now carries twelve (57 core), plus the optional
two-part F0 history chapter.
**41 modules are built in the manifest; 18 are planned.** Of the 123 registered page fragments, the whole of F3
(9 modules) plus the F4 landing and F4.01, F4.02, F4.03, F4.04, F4.05, F4.06, F4.07, F4.08, F4.09, F4.10, F4.11, and F4.12 are authorable source in this working tree and were
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

The chapter is open: the landing is built and `/elixir/algorithms` is linkable. F4.01, F4.02, F4.03, and F4.04 are
built (each a hub plus three dives; F4.02&ndash;F4.06 carry an advanced section per dive). **F4.05 (HAMT)** is
built &mdash; a hub plus three dives (bitmap / indexing / sharing), each with an advanced section &mdash; closing the
gap before **F4.06 (CHAMP maps)**, so F4.06&rsquo;s hub pager now points back to `/elixir/algorithms/hamt` and the
F4.04 &rarr; F4.05 and F4.06 &rarr; F4.05 references are linked. **The chapter was then restructured from nine
modules to twelve, and F4.07 (Identifiers, Snowflake &amp; branded ids), F4.08 (Branded ids &amp; persistence),
F4.09 (Branded CHAMP maps &amp; GenServer), F4.10 (Practical recipes in Elixir), F4.11 (Dynamic programming &amp;
advanced problems), and F4.12 (Lab: build a branded CHAMP store) are now built &mdash; so every module of F4 is
complete, and with it the whole course.** Each is a hub plus three dives with an advanced section and a References
block. F4.09 closes the spine: it folds the CHAMP node (F4.06) and the branded id (F4.07/F4.08) into one in-memory
store &mdash; a CHAMP keyed by branded ids, partitioned by the three-letter namespace, owned by a GenServer &mdash;
and threads three Portal uses through its dives: the entity registry (partition), progress snapshots (structural
sharing), and the session store (GenServer, lock-free reads over a published immutable root). F4.10 then turns those
structures into the Portal&rsquo;s everyday code: a `with` chain for the request lifecycle, a lazy `Stream` pipeline
for the activity feed, and reading complexity to choose a lookup (`O(n)` list scan vs `O(log32 n)` CHAMP). F4.11
applies dynamic programming to three Portal cases: memoising a prerequisite-depth recursion (the per-lesson
evaluation counts are the Fibonacci numbers, 20 collapsing to 6), tabulating the fewest modules to reach a credit
target bottom-up (where greedy loses), and edit distance as a two-dimensional grid for typo-tolerant search. **F4.12
is the capstone lab**: it assembles the chapter into one `Portal.Store` &mdash; a GenServer over `%{namespace =>
CHAMP}` &mdash; and exercises it across three dives: a `put` that routes by prefix and grows the store by partition,
a `get` that resolves any id to its entry and a free Snowflake timestamp (rejecting unknown namespaces at the edge),
and a `range` that turns a time window into id bounds. **No planned F4 modules remain.** The five-module
**persistent-map spine is complete**: F4.05&ndash;F4.09 (HAMT &rarr; CHAMP &rarr; **identifiers, Snowflake &amp;
branded ids** &rarr; **branded ids &amp; persistence** &rarr; **branded CHAMP maps &amp; GenServer**), followed by
practical recipes (F4.10), dynamic programming (F4.11), and the branded-CHAMP lab (F4.12) &mdash; all built. The id,
persistence, branded-CHAMP, recipes, dynamic-programming, and lab modules give the branded Snowflake / trie
convention used across the course its own modules; **F4.05.2 was renamed from slug `index` to
`indexing`** so its route (`/elixir/algorithms/hamt/indexing`) does not collide with an `index.html` when the site
is served statically.

F4.04 (maps, sets & hashing) is grounded in the course's own Phoenix LiveView data layer, on request: the worked
example is the site's **page registry** — a map from route string to a `%Page{}` struct keyed by a branded
Snowflake id (namespace `PGE`, e.g. `PGE0NbWMtkolM0`, minted with real timestamps and decodable by the same
footer decoder). The hub frames lookup / membership / hashing over that registry; the lookup dive shows
`Map.get`/`fetch`/`put` and ties to `socket.assigns` and `assign/3`; the sets dive runs `MapSet.member?` as the
course's own links gate, with `intersection`/`difference` over the built-versus-F4 route sets (and a two-set
SVG); the hashing dive walks key → `:erlang.phash2` → bucket → collision, and its advanced section sketches the
32-way HAMT (a second SVG) as a direct bridge into F4.05. Each dive carries one teaching section plus one advanced
section, matching F4.02/F4.03. The first dive slug is `lookup` (not `maps`) to avoid a `/maps/maps` route; the
hub pager goes back to F4.03 and the last dive (hashing) forward to `/elixir/algorithms`; the hub note and the
hashing note name **F4.05 — Hash Array Mapped Tries (HAMT)** as the next module, currently unlinked ("in
production"). The F4.03 hub note, an inline F4.03 reference, the F4.03 cost note, and the F4 landing card were all
relinked to `/elixir/algorithms/maps`.

F4.06 (CHAMP maps) was built next on request, jumping past F4.05. CHAMP &mdash; Compressed Hash-Array Mapped
Prefix-tree &mdash; is the compressed successor to the HAMT introduced in F4.04's hashing dive: each node splits
its 32 slots into two bitmaps (a `datamap` and a `nodemap`) and two gap-free packed arrays (entries and
sub-nodes), which buys cache-friendly iteration and a canonical shape per map. The real-world frame is the
course's own persistent page registry and, directly, the stack's **BrandedChamp trie** (a CHAMP keyed by branded
Snowflake ids), with F4.09 named as where the keys become branded. The hub frames layout / iteration / equality
over a CHAMP node (a `datamap`/`nodemap` SVG with a canonical-form badge); the layout dive shows the two bitmaps,
two packed arrays, and the `popcount` index trick (with `Bitwise` `entry?`/`child?`/`data_index`); the iteration
dive contrasts CHAMP's contiguous entry sweep against a HAMT's interleaved 32-slot layout (two toggled SVG
groups) and ties to `Enum.reduce`; the equality dive shows canonical-form structural equality and a one-entry
snapshot diff over two CHAMP trees, bridging to the BrandedChamp trie and LiveView assign-diffing. Each dive is
one teaching section plus one advanced section; all four pages are single-SVG. Subpage slugs are
`layout`/`iteration`/`equality`. **The F4.05 gap is now closed:** with F4.05 (HAMT, slug `hamt`) built, the F4.06
hub pager back was repointed to `/elixir/algorithms/hamt` ("F4.05 · hamt") and the F4.06 hub note&rsquo;s
predecessor reference to F4.05 is now a link; the equality note now names **F4.07 — Identifiers, Snowflake & branded ids (next)**
unlinked ("in production"), with the branded CHAMP itself now at F4.09. The last dive (equality) forward still goes to
`/elixir/algorithms` by the last-dive convention. The decoder block references the real minted id `PGE0NbWMtkolM0`.

F4.05 (HAMT) was built to close the gap in the spine, the persistent-map module the rest of F4.06&ndash;F4.09 build on.
It is grounded in the same page-registry frame: a map from a route to a `%Page{}` keyed by a branded `PGE`
Snowflake id, stored as a trie. The hub frames bitmap / indexing / sharing over **one** bitmap and **one** packed
array (the single mixed array is the contrast F4.06 later compresses into two). The bitmap dive shows one bitmap
marking occupied slots, one packed array mixing leaves and children, and the `popcount` index trick (with
`Bitwise` `occupied?`/`index`), its advanced section naming the two-bitmap split as the thing F4.06 removes. The
indexing dive descends on the registry key `"/elixir/algorithms/maps"`, whose `phash2` is the same `48721903` from
F4.04, computing the 5-bit chunks **live** in JS — `(48721903 >>> 5k) &&& 31` = 15, 31, 27 (verified against
Python; `rem 8 = 7` matches F4.04&rsquo;s slot) — so the readout is truthful as the level is selected. The sharing
dive inserts a newly added page (`PGE0NcQgyPQEbI`) to turn `v1` into `v2`, highlighting the copied root-to-leaf
path against the shared sub-trees, and its advanced section bridges to F4.06&rsquo;s canonical shape and the
stack&rsquo;s BrandedChamp trie (F4.09). Each dive is one teaching section plus one advanced section; all four
pages are single-SVG, sage accent, with `.ex`/`code.inl` left global Elixir purple. The F4.04 hub note, the F4.04
hashing note, the F4.06 hub note, the F4.06 hub back-pager, and the F4 landing&rsquo;s F4.05 card were all relinked
to `/elixir/algorithms/hamt`; the landing journey-SVG node was left as the thematic trie-family sage, matching the
F4.06 build precedent.

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
| **F4.04 Maps, sets & hashing (hub)** | `/elixir/algorithms/maps` | built | planned | **yes** | **yes** |
| ↳ F4.04.1 Maps & key lookup | `/elixir/algorithms/maps/lookup` | built | planned | **yes** | **yes** |
| ↳ F4.04.2 MapSet & membership | `/elixir/algorithms/maps/sets` | built | planned | **yes** | **yes** |
| ↳ F4.04.3 Hashing & collisions | `/elixir/algorithms/maps/hashing` | built | planned | **yes** | **yes** |
| **F4.05 Hash array mapped tries (hub)** | `/elixir/algorithms/hamt` | built | planned | **yes** | **yes** |
| ↳ F4.05.1 Bitmapped nodes | `/elixir/algorithms/hamt/bitmap` | built | planned | **yes** | **yes** |
| ↳ F4.05.2 Hash-prefix indexing | `/elixir/algorithms/hamt/indexing` | built | planned | **yes** | **yes** |
| ↳ F4.05.3 Structural sharing | `/elixir/algorithms/hamt/sharing` | built | planned | **yes** | **yes** |
| **F4.06 CHAMP maps (hub)** | `/elixir/algorithms/champ` | built | planned | **yes** | **yes** |
| ↳ F4.06.1 Compressed node layout | `/elixir/algorithms/champ/layout` | built | planned | **yes** | **yes** |
| ↳ F4.06.2 Cache-friendly iteration | `/elixir/algorithms/champ/iteration` | built | planned | **yes** | **yes** |
| ↳ F4.06.3 Canonical equality | `/elixir/algorithms/champ/equality` | built | planned | **yes** | **yes** |
| **F4.07 Identifiers, Snowflake & branded ids (hub)** | `/elixir/algorithms/identifiers` | built | planned | **yes** | **yes** |
| ↳ F4.07.1 Choosing an identifier | `/elixir/algorithms/identifiers/choosing` | built | planned | **yes** | **yes** |
| ↳ F4.07.2 The Snowflake bigint | `/elixir/algorithms/identifiers/snowflake` | built | planned | **yes** | **yes** |
| ↳ F4.07.3 Branded ids | `/elixir/algorithms/identifiers/branded` | built | planned | **yes** | **yes** |
| **F4.08 Branded ids & persistence (hub)** | `/elixir/algorithms/persistence` | built | planned | **yes** | **yes** |
| ↳ F4.08.1 Branded ids as keys | `/elixir/algorithms/persistence/keys` | built | planned | **yes** | **yes** |
| ↳ F4.08.2 SQLite & PostgreSQL | `/elixir/algorithms/persistence/sql` | built | planned | **yes** | **yes** |
| ↳ F4.08.3 Redis keys | `/elixir/algorithms/persistence/redis` | built | planned | **yes** | **yes** |
| **F4.09 Branded CHAMP maps & GenServer (hub)** | `/elixir/algorithms/branded-champ` | built | planned | **yes** | **yes** |
| ↳ F4.09.1 Partition by namespace | `/elixir/algorithms/branded-champ/partition` | built | planned | **yes** | **yes** |
| ↳ F4.09.2 Structural sharing | `/elixir/algorithms/branded-champ/trie` | built | planned | **yes** | **yes** |
| ↳ F4.09.3 Own it with a GenServer | `/elixir/algorithms/branded-champ/genserver` | built | planned | **yes** | **yes** |
| **F4.10 Practical recipes in Elixir (hub)** | `/elixir/algorithms/recipes` | built | planned | **yes** | **yes** |
| ↳ F4.10.1 Idiomatic patterns | `/elixir/algorithms/recipes/patterns` | built | planned | **yes** | **yes** |
| ↳ F4.10.2 Streams & pipelines | `/elixir/algorithms/recipes/pipelines` | built | planned | **yes** | **yes** |
| ↳ F4.10.3 Profiling & complexity | `/elixir/algorithms/recipes/profiling` | built | planned | **yes** | **yes** |
| **F4.11 Dynamic programming & advanced problems (hub)** | `/elixir/algorithms/dynamic-programming` | built | planned | **yes** | **yes** |
| ↳ F4.11.1 Memoization & overlapping subproblems | `/elixir/algorithms/dynamic-programming/memoization` | built | planned | **yes** | **yes** |
| ↳ F4.11.2 Tabulation & bottom-up | `/elixir/algorithms/dynamic-programming/tabulation` | built | planned | **yes** | **yes** |
| ↳ F4.11.3 Classic DP problems | `/elixir/algorithms/dynamic-programming/problems` | built | planned | **yes** | **yes** |
| **F4.12 Lab: build a branded CHAMP store (lab hub)** | `/elixir/algorithms/lab` | built | planned | **yes** | **yes** |
| ↳ F4.12.1 Watch a branded CHAMP grow | `/elixir/algorithms/lab/grow` | built | planned | **yes** | **yes** |
| ↳ F4.12.2 A Snowflake registry | `/elixir/algorithms/lab/registry` | built | planned | **yes** | **yes** |
| ↳ F4.12.3 Query by time range | `/elixir/algorithms/lab/range` | built | planned | **yes** | **yes** |

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

build --page f4-4         ->  maps.html                  · Apollo A+ · 9/9 gates PASS
build --page f4-4-lookup  ->  maps-lookup.html           · Apollo A+ · 9/9 gates PASS
build --page f4-4-sets    ->  maps-sets.html             · Apollo A+ · 9/9 gates PASS
build --page f4-4-hashing ->  maps-hashing.html          · Apollo A+ · 9/9 gates PASS  (2 SVGs)
F4.04 was NOT pre-wired: promoted planned→built, added SUBPAGES (lookup, sets, hashing) + 4 PAGES; first dive slug lookup
rebuild f4-3, f4-3-cost, f4-landing  ->  A+ (F4.03 hub note + inline + cost note + landing F4.04 card relinked → /elixir/algorithms/maps)
mint PGE ids  ->  PGE0NbWMtkolM0 (maps), PGE0NbLeJJpTmr (sorting), PGE0NXh7MFjxT6 (modules) — all decode to real timestamps
node --check (page JS)    ->  OK for all four F4.04 pages
routes                    ->  92 allowed (was 88); F4.05 /algorithms/hamt correctly absent
suite.elixir.js ONLY=F4.04  ->  45 PASS desktop + 8 PASS mobile · 0 FAIL · images embedded: 0

build --page f4-6          ->  champ.html                 · Apollo A+ · 9/9 gates PASS
build --page f4-6-layout   ->  champ-layout.html          · Apollo A+ · 9/9 gates PASS
build --page f4-6-iteration->  champ-iteration.html       · Apollo A+ · 9/9 gates PASS
build --page f4-6-equality ->  champ-equality.html        · Apollo A+ · 9/9 gates PASS
F4.06 was NOT pre-wired: promoted planned→built, added SUBPAGES (layout, iteration, equality) + 4 PAGES; built ahead of F4.05
rebuild f4-landing         ->  A+ (landing F4.06 card relinked → /elixir/algorithms/champ; F4.05 card left planned)
F4.04 → F4.05 forward pointers left intact (F4.05 still the correct next module, in production)
node --check (page JS)     ->  OK for all four F4.06 pages
routes                     ->  96 allowed (was 92); F4.05 /algorithms/hamt and F4.07 /algorithms/branded-champ correctly absent
suite.elixir.js ONLY=F4.06  ->  46 PASS desktop + 8 PASS mobile · 0 FAIL · images embedded: 0

build --page f4-5          ->  hamt.html                  · Apollo A+ · 9/9 gates PASS
build --page f4-5-bitmap   ->  hamt-bitmap.html           · Apollo A+ · 9/9 gates PASS
build --page f4-5-index    ->  hamt-index.html            · Apollo A+ · 9/9 gates PASS
build --page f4-5-sharing  ->  hamt-sharing.html          · Apollo A+ · 9/9 gates PASS
F4.05 dives roadmap was pre-wired: promoted planned→built, added SUBPAGES (bitmap, index, sharing) + 4 PAGES (hamt*.html)
relink f4-4, f4-4-hashing, f4-6, f4-landing  ->  A+ (F4.04 hub+hashing notes + F4.06 hub note linked → /hamt; F4.06 back-pager → /hamt; landing F4.05 card div→a, pill built; landing SVG node left thematic)
hash chunks verified: phash2("/elixir/algorithms/maps")=48721903 → 5-bit chunks 15,31,27 (Python+JS agree); rem 8 = 7 matches F4.04 slot
mint PGE id  ->  PGE0NcQgyPQEbI (newly added page in the sharing worked example) — decodes to a real timestamp
node --check (page JS)     ->  OK for all four F4.05 pages
routes                     ->  100 allowed (was 96); F4.07 /algorithms/branded-champ correctly absent
suite.elixir.js ONLY=F4.05  ->  44 PASS desktop + 8 PASS mobile · 0 FAIL · images embedded: 0
_gen_course_md.py / _gen_refs_md.py  ->  regenerated; voice gate CLEAN on both

# F4 restructure (route rename + 9→12 modules)
rename slug index→indexing: cp f4-05-2-index.html → f4-05-2-indexing.html (route-tag + crumb edited), rm old
relink 5 internal /hamt/index refs → /hamt/indexing (hub card+note, bitmap note+pager, sharing back-pager label)
manifest: SUBPAGES F4.05 dive slug index→indexing; PAGES key f4-5-index→f4-5-indexing (content+outfile hamt-indexing.html)
validator suite: /hamt-index.html → /hamt-indexing.html (desktop block + mobile sweep)
rebuild f4-5-indexing / f4-5 / f4-5-bitmap / f4-5-sharing  ->  A+; rm stale hamt-index.html
manifest restructure: F4.07-F4.09 (3 planned) → F4.07-F4.12 (6 planned), reusing slugs branded-champ (now F4.09) + dynamic-programming (now F4.11)
renumber forward-refs in built pages: f4-5-sharing/f4-6/f4-6-equality (old F4.07 Branded CHAMP → F4.09; F4.06 next → new F4.07 Identifiers)  ->  rebuilt A+
rebuild f4-landing  ->  A+ (12-module cards F4.07-F4.12; journey-SVG redrawn 9→12 nodes; hero/arc/readout reworded to the 5-module spine)
save EchoData impl  ->  reference/echo_data/{snowflake.ex,base62.ex,README.md} for the future F4.07/F4.08 article
node --check (page JS)     ->  OK for hamt-indexing.html and all rebuilt pages
routes                     ->  100 link routes unchanged (index→indexing is net-zero); planned identifiers/branded-champ/recipes/dynamic-programming/lab correctly absent from link routes
suite.elixir.js ONLY=F4.05  ->  references /hamt-indexing.html (see Part-2 validation below)
site-wide home (/elixir) + Contents (/elixir/course) module count 54→57: DEPLOY step — those fragments are not in this working tree

# F4.07 authored (Identifiers, Snowflake & branded ids) + References-block convention
NEW standing rule: every page carries a References section (.reveal, .refs: Sources + Related in this course)
added .refs CSS to HEAD_CSS → extract-head → _head.html (8 rules); the builder-injected reveal observer makes .reveal degrade-safe
authored content/f4-07-identifiers.html (hub) + f4-07-1-choosing / f4-07-2-snowflake / f4-07-3-branded (3 dives)
each: single SVG, one teaching + one advanced section, sage accent, References block, branded decoder footer
interactives compute the real operation: hub decodes TSK0KHTOWnGLuC live; choosing runs a real lexical sort (Snowflake/counter recover order, UUID does not); snowflake extracts ts/worker(7)/seq(42) by shift+mask; branded base62-encodes 319545566822428714 → 0NbWMtkosp8 → PGE0NbWMtkosp8 → decode round-trip
promote F4.07 planned→built, added SUBPAGES (choosing, snowflake, branded) + 4 PAGES (identifiers*.html)
relink f4-6 + f4-6-equality "next module" notes → /elixir/algorithms/identifiers (dropped "in production"); landing F4.07 card div→a, pill built (journey-SVG node left thematic)
build f4-7 / f4-7-choosing / f4-7-snowflake / f4-7-branded + rebuilt f4-6 / f4-6-equality / f4-landing  ->  all Apollo A+ · 9/9 gates
voice sweep  ->  clean (fixed one "just" in the branded dive); node --check  ->  OK for all four pages
routes                     ->  104 link routes (was 100); F4.08 /algorithms/persistence correctly absent
suite.elixir.js ONLY=F4.07  ->  34 PASS desktop + 8 PASS mobile · 0 FAIL · images embedded: 0
_gen_course_md.py / _gen_refs_md.py  ->  regenerated; voice gate CLEAN; F4.07 shows built hub + 3 built dives; 59/59 modules carry references
```

# F4.08 authored (Branded ids & persistence) — emphasis: self-validating id sheds enumeration/DDoS before any store
authored content/f4-08-persistence.html (hub) + f4-08-1-keys / f4-08-2-sql / f4-08-3-redis (3 dives)
each: single SVG, one teaching + one advanced section, sage accent, References block, branded decoder footer
HEADLINE thread (per request): GET /user/profile/USR0NbWMtkosp8 — the edge validates structure + 64-bit range + namespace + timestamp (not future) with NO I/O; malformed/impossible ids get a 404 in constant time, shedding the cheap high-volume probe that targets a DB; the id also yields the exact creation time with no created_at column. Honest caveat stated on hub AND redis dive: validation proves well-formed + plausibly-timed, NOT existence — a correctly-shaped id still needs one lookup.
interactives compute the real operation: hub runs validate(pathId,'USR') over 4 inputs (accept / wrong-type / malformed-length / out-of-range); keys shows bigint(8B) vs wire string vs O(log n) index (real base62 encode/decode); sql computes min/max snowflake bounds live from a date window via (ms-epoch)<<22 (May 2026 -> 308392073625600000 / 319626097459200000); redis classifies a fixed 8-request burst with the same validate() (3 valid -> cache, 5 shed -> 404 vs passthrough -> 8 GETs + 5 DB reads for impossible ids)
promote F4.08 planned->built, added SUBPAGES (keys, sql, redis) + 4 PAGES (persistence*.html)
relink f4-07-identifiers + f4-07-3-branded "next module" notes -> /elixir/algorithms/persistence (dropped "in production"); landing F4.08 card div->a, pill built (journey-SVG node left thematic)
build f4-8 / f4-8-keys / f4-8-sql / f4-8-redis + rebuilt f4-7 / f4-7-branded / f4-landing  ->  all Apollo A+ · 9/9 gates
voice sweep  ->  clean (no fixes needed); node --check  ->  OK for all four pages; References block present on all four (grep id="refsTitle")
routes                     ->  108 link routes (was 104); F4.09 /algorithms/branded-champ correctly absent
suite.elixir.js ONLY=F4.08  ->  33 PASS desktop + 8 PASS mobile · 0 FAIL · images embedded: 0
_gen_course_md.py / _gen_refs_md.py  ->  regenerated; voice gate CLEAN; F4.08 shows built hub + 3 built dives; 59/59 modules carry references
```

# F4.09 authored (Branded CHAMP maps & GenServer) — closes the persistent-map spine; 3 Portal uses, one per dive
authored content/f4-09-branded-champ.html (hub) + f4-09-1-partition / f4-09-2-trie / f4-09-3-genserver (3 dives)
each: single SVG, one teaching + one advanced section, sage accent, References block, branded decoder footer
THREAD: fold F4.06 (CHAMP node) + F4.07/F4.08 (branded id) into one in-memory store — a CHAMP keyed by branded ids, partitioned by the 3-letter namespace, owned by a GenServer; immutable (lock-free reads), structurally shared (cheap snapshots), partitioned (shallow sub-trie per kind)
THREE REAL-WORLD PORTAL USES (per request), one per dive:
  - F4.09.1 partition  = the entity registry: USR/SES/LSN/PGE in one store, prefix routes to the partition (real group/count of 8 records: USR 2, SES 1, LSN 3, PGE 2)
  - F4.09.2 trie       = progress snapshots: Portal.Progress.complete/2 copies one root-to-leaf path, shares the rest (real path topology: any leaf -> 3 copied, 4 shared of 7 nodes; old snapshot intact)
  - F4.09.3 genserver  = the session store: Portal.Auth.current_user/1 reads the published immutable root lock-free; GenServer serializes writes (real classify of a 6-op burst: genserver -> 2 writes serialized + 4 reads lock-free, with snapshot version v0->v1->v2; naive -> all 6 serialized through one mailbox)
hub interactive routes a branded id to its partition by 3-char prefix and decodes its time (USR0NbAb1xcFCy ada@portal.dev, SES0NbAb29FnXc, LSN0NbAb2Lk9GS, PGE0NbWMtkolM0 — all verified)
manifest dive titles aligned to "Partition by namespace" / "Structural sharing" / "Own it with a GenServer" (slugs partition/trie/genserver)
promote F4.09 planned->built, added SUBPAGES (partition, trie, genserver) + 4 PAGES (branded-champ*.html)
relink f4-08-persistence + f4-08-3-redis "next module" notes -> /elixir/algorithms/branded-champ (dropped "in production"); landing F4.09 card div->a, pill built, dive labels aligned (journey-SVG node left thematic)
build f4-9 / f4-9-partition / f4-9-trie / f4-9-genserver + rebuilt f4-8 / f4-8-redis / f4-landing  ->  all Apollo A+ · 9/9 gates
voice sweep  ->  fixed 2x "just" (partition) + 1 "just" (trie); node --check  ->  OK for all four pages; References block present on all four (grep id="refsTitle")
routes                     ->  112 link routes (was 108); F4.10 /algorithms/recipes correctly absent
suite.elixir.js ONLY=F4.09  ->  34 PASS desktop + 8 PASS mobile · 0 FAIL · images embedded: 0
_gen_course_md.py / _gen_refs_md.py  ->  regenerated; voice gate CLEAN; F4.09 shows built hub + 3 built dives; 59/59 modules carry references
```

# F4.10 authored (Practical recipes in Elixir) — turns the chapter's structures into everyday Portal code; 3 recipes, one per dive
authored content/f4-10-recipes.html (hub) + f4-10-1-patterns / f4-10-2-pipelines / f4-10-3-profiling (3 dives)
each: single SVG, one teaching + one advanced section, sage accent, References block, branded decoder footer
THREAD: the spine built the structures (F4.05–F4.09); this module is how the Portal uses them — three recurring recipes that compose into one request flow (validate with `with`, aggregate with `Stream`, look up via an O(log n) store)
THREE REAL-WORLD PORTAL CASES (per request), one per dive:
  - hub                = the progress report: Progress.percent_complete/1 as a real count over the F4.09 store (select learner: ada 5/5=100%, kit 3/5=60%, jo 1/5=20%)
  - F4.10.1 patterns   = the request lifecycle: a with-chain (validate_id -> current_user -> fetch_lesson -> authorize -> render); select failing gate -> real short-circuit walk, ran/failed/skipped rows + HTTP status (200/400/401/404/403)
  - F4.10.2 pipelines  = the activity feed: lazy Stream vs eager Enum over 12 completions (matches at {0,2,4,5,7,9,11}=7; take 3 -> indices 0,2,4); Stream examines 5 of 12, maps 3, 0 lists; Enum examines 12, maps 7, 2 lists (real classify)
  - F4.10.3 profiling  = choosing a lookup: list O(n) vs CHAMP O(log32 n); select size {1,000|100,000|10,000,000} -> list comparisons vs map hops (2/4/5) + ~speedup, bars on log10 scale (real ceil(log32 n))
manifest dive titles already matched the pages (Idiomatic patterns / Streams & pipelines / Profiling & complexity; slugs patterns/pipelines/profiling) — no realign
promote F4.10 planned->built, added SUBPAGES (patterns, pipelines, profiling) + 4 PAGES (recipes*.html)
relink f4-09-branded-champ + f4-09-3-genserver "next module" notes -> /elixir/algorithms/recipes (dropped "in production"); landing F4.10 card div->a, pill built
build f4-10 / f4-10-patterns / f4-10-pipelines / f4-10-profiling + rebuilt f4-9 / f4-9-genserver / f4-landing  ->  all Apollo A+ · 9/9 gates
voice sweep clean (no fixes; `!` hits all JS/regex); node --check  ->  OK for all four pages; References block present on all four (grep id="refsTitle")
routes                     ->  116 link routes (was 112); F4.11 /algorithms/dynamic correctly absent
suite.elixir.js ONLY=F4.10  ->  33 PASS desktop + 8 PASS mobile · 0 FAIL · images embedded: 0  (fixed one assertion: expectText is case-SENSITIVE via nospace, so #ptStatus needle "Not Found" not "not found")
_gen_course_md.py / _gen_refs_md.py  ->  regenerated; voice gate CLEAN; F4.10 shows built hub + 3 built dives; 59/59 modules carry references
```

# F4.11 authored (Dynamic programming & advanced problems) — overlapping subproblems solved once; 3 Portal cases, one per dive
authored content/f4-11-dynamic-programming.html (hub) + f4-11-1-memoization / f4-11-2-tabulation / f4-11-3-problems (3 dives)
each: single SVG, one teaching + one advanced section, sage accent, References block, branded decoder footer
THREAD: DP = optimal substructure + overlapping subproblems -> solve each once and reuse; two styles (memoisation top-down cache, tabulation bottom-up table) + a classic problem worked end to end
THREE REAL-WORLD PORTAL CASES, one per dive (every interactive computes the real operation):
  - hub                = pacing an n-lesson track 1 or 2 at a time (Fibonacci recurrence); select N {5,10,20} -> ways(N) {8,89,10946}, naive calls {9,109,13529} vs cached subproblems = N, bars on log10 scale
  - F4.11.1 memoization = longest prerequisite-chain depth over a 6-lesson Fibonacci-structured DAG (each depends on prev two); toggle naive/memo -> per-node eval counts naive {L1..L6 = 8,5,3,2,1,1} total 20, memo 1-each total 6; depth(L6)=6 both
  - F4.11.2 tabulation  = fewest modules (worth 1,3,4) to reach a credit target; select N {6,8,11} -> fill dp[0..N] bottom-up, dp[N] {2,2,3}; greedy {3,2,3} so greedy FAILS at N=6 (3 vs 2); highlights answer + chosen predecessor + dependency arc
  - F4.11.3 problems    = edit distance for typo-tolerant search vs target "elixir"; select query {elixr,exilir,exlir} -> full Levenshtein grid, distance {1,2,3} at bottom-right; threshold <=2 -> "did you mean elixir?" (distances verified via python)
manifest dive titles already matched the pages (Memoization & overlapping subproblems / Tabulation & bottom-up / Classic DP problems; slugs memoization/tabulation/problems) — no realign
promote F4.11 planned->built, added SUBPAGES (memoization, tabulation, problems) + 4 PAGES (dynamic-programming*.html)
relink f4-10-recipes + f4-10-3-profiling "next module" notes -> /elixir/algorithms/dynamic-programming (dropped "in production"; reconciled wording "in Elixir" -> manifest title "& advanced problems"); landing F4.11 card div->a, pill built
build f4-11 / f4-11-memoization / f4-11-tabulation / f4-11-problems + rebuilt f4-10 / f4-10-profiling / f4-landing  ->  all Apollo A+ · 9/9 gates
voice sweep: fixed one "just" in problems.html (advanced prose); node --check  ->  OK for all four pages; References block present on all four (grep id="refsTitle")
routes                     ->  120 link routes (was 116); F4.12 /algorithms/lab correctly absent
suite.elixir.js ONLY=F4.11  ->  32 PASS desktop + 8 PASS mobile · 0 FAIL · images embedded: 0
_gen_course_md.py / _gen_refs_md.py  ->  regenerated; voice gate CLEAN; F4.11 shows built hub + 3 built dives; 59/59 modules carry references
```

# F4.12 authored (Lab: build a branded CHAMP store) — the CAPSTONE; assembles the chapter into one Portal.Store
authored content/f4-12-lab.html (hub) + f4-12-1-grow / f4-12-2-registry / f4-12-3-range (3 dives)
each: single SVG, one teaching + one advanced section, sage accent, References block, branded decoder footer
THREAD: assemble F4.05-F4.11 into one Portal.Store = a GenServer over %{namespace => CHAMP}; a put is validated, routed by 3-char prefix to a partition, stored in that partition's CHAMP, dated for free from the Snowflake in its id
REAL-WORLD PORTAL PROJECT, one capability per dive (every interactive computes the real operation; all branded ids verified-decode via python):
  - hub                = trace one put through the 4-layer stack (validate -> route by prefix -> CHAMP put in partition -> Snowflake created_at); select entity {usr/lsn/pge} -> USR0NbAb1xcFCy=users/3 entries/13:35:19, LSN0NbCMKoAopE=lessons/5/14:00:00, PGE0NbWMtkolM0=pages/1/18:40:00
  - F4.12.1 grow       = insert 10 real keys in order, partitions appear+fill (4 rows of dots), routing by prefix is real; checkpoints {0,3,6,10}: after 3 = USR1/SES1/LSN1 (3 entries, 3 partitions), after 6 = +PGE (6, 4 partitions), after 10 = USR3/SES1/LSN5/PGE1 (10, 4 partitions)
  - F4.12.2 registry   = resolve a branded id {usr/lsn/tsk}: USR0NbAb1xcFCy->users/present/1 hop/13:35:19, LSN0NbD94T0Qtu->lessons/present/1 hop/14:11:00, TSK0KHTOWnGLuC->unknown namespace (no partition) -> {:error, :unknown_namespace} (still decodes to 2026-01-27 15:11:37 but nothing to search)
  - F4.12.3 range      = time window -> id bounds over the lessons partition (5 lessons 13:35/14:00/14:05/14:11/14:20); windows {a:14:00-14:10, b:14:00-14:15, c:14:00-14:25} -> matches {2,3,4} (13:35 always excluded, before window); real start<=ms<end; honest catch: CHAMP is hash-ordered, so true range scan needs a sorted index (gb_sets) or a filter over a small partition
manifest dive titles already matched the pages (Watch a branded CHAMP grow / A Snowflake registry / Query by time range; slugs grow/registry/range) — no realign; lab=True preserved
promote F4.12 planned->built, added SUBPAGES (grow, registry, range) + 4 PAGES (lab*.html)
relink f4-11 hub + f4-11-3-problems "next module" notes -> /elixir/algorithms/lab (dropped "in production"; manifest title and pointers already agreed); landing F4.12 card div.is-quiet.lab -> a.mod.lab (kept lab class), pill built
build f4-12 / f4-12-grow / f4-12-registry / f4-12-range + rebuilt f4-11 / f4-11-problems / f4-landing  ->  all Apollo A+ · 9/9 gates
voice sweep: fixed one "just" in range.html (range/2 code comment); node --check  ->  OK for all four pages; References block present on all four (grep id="refsTitle")
routes                     ->  124 link routes (was 120); all four /lab routes present
suite.elixir.js ONLY=F4.12  ->  35 PASS desktop + 8 PASS mobile · 0 FAIL · images embedded: 0
_gen_course_md.py / _gen_refs_md.py  ->  regenerated; voice gate CLEAN; F4.12 shows built lab hub + 3 built dives; 59/59 modules carry references
==> F4 chapter COMPLETE (41 built / 18 planned across all chapters; F4 non-built = NONE). Every module in the manifest's live chapters is built; the course is complete bar the standing deploy gap.
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

**The F4 chapter is complete; F4.01&ndash;F4.12 are all built.** The chapter is
`live`, the landing (`/elixir/algorithms`) is built, and **F4.01&ndash;F4.12** each ship as a hub plus three dives.
F4.02&ndash;F4.12 carry a dedicated advanced section on every page, all A+ and green in the validator (F4.04:
45+8 = 53 PASS; F4.05: 44+8 = 52 PASS; F4.06: 46+8 = 54 PASS; F4.07: 34+8 = 42 PASS; F4.08: 33+8 = 41 PASS; F4.09:
34+8 = 42 PASS; F4.10: 33+8 = 41 PASS; F4.11: 32+8 = 40 PASS; F4.12: 35+8 = 43 PASS). Every page now also carries a
**References** section
(Sources + Related in this course), styled by `.refs` in `HEAD_CSS`. The persistent-map spine is complete:
**F4.04** grounds maps/sets/hashing in the course&rsquo;s own page registry (a map keyed by branded `PGE`
Snowflake ids, the route sets behind the links gate, `phash2` into a 32-way HAMT); **F4.05 (HAMT)** builds that
32-way trie explicitly &mdash; one bitmap and one packed array per node, a 5-bit hash-chunk descent, and path-copy
structural sharing; **F4.06 (CHAMP)** compresses the node into two bitmaps and two arrays for a canonical shape and
cheap diffs. With F4.05 built, the F4.04 &rarr; F4.05 and F4.06 &rarr; F4.05 references are linked, the F4.06 hub
back-pager points to `/elixir/algorithms/hamt`, and the F4 landing&rsquo;s F4.05 card is linkable (its journey-SVG
node left thematic, per the F4.06 precedent). **The chapter was then restructured to twelve modules, all of which
are now built &mdash; F4.07 (Identifiers, Snowflake &amp; branded ids), F4.08 (Branded ids &amp; persistence), F4.09
(Branded CHAMP maps &amp; GenServer), F4.10 (Practical recipes in Elixir), F4.11 (Dynamic programming &amp; advanced
problems), and F4.12 (the lab)**: F4.07&rsquo;s dives decode a branded id, run a real lexical sort, and extract
Snowflake fields; F4.08&rsquo;s dives store the id as a `bigint`, range-query by time via `id >= min AND id < max`,
and validate a request id at the edge to answer malformed or impossible ids with a `404` before any I/O;
F4.09&rsquo;s dives fold the lot into one in-memory store &mdash; a CHAMP keyed by branded ids, partitioned by
namespace, owned by a GenServer &mdash; with three Portal uses (entity registry, progress snapshots, session store);
F4.10&rsquo;s dives turn those structures into everyday code &mdash; a `with` chain for the request lifecycle, a lazy
`Stream` pipeline for the activity feed, and reading `O(n)` vs `O(log32 n)` to choose a lookup; F4.11&rsquo;s dives
apply dynamic programming &mdash; memoising a prerequisite-depth recursion (Fibonacci eval counts, 20 to 6),
tabulating fewest-modules-to-a-credit-target where greedy loses, and edit distance as a 2-D grid for typo-tolerant
search; F4.12&rsquo;s dives assemble all of it into one `Portal.Store` &mdash; a `put` that routes by prefix and
grows the store by partition, a `get` that resolves any id with a free Snowflake timestamp and rejects unknown
namespaces, and a `range` that turns a time window into id bounds. **No planned F4 modules remain &mdash; the chapter
and the course are complete.** The now-complete spine is F4.05&ndash;F4.09 (HAMT, CHAMP, identifiers, persistence,
branded CHAMP), with recipes (F4.10), dynamic programming (F4.11), and the branded-CHAMP lab (F4.12) after it, all
built. F4.05.2 was renamed slug `index`&rarr;`indexing` (route `/elixir/algorithms/hamt/indexing`) to avoid an
`index.html` collision when serving statically. The chapter accent is sage; `.ex`/`code.inl` stay the global Elixir
purple.

**F4 is complete; F5 is now open as the product chapter.** The Algorithms &amp; Data Structures chapter shipped
twelve modules (each a hub plus three dives, A+ on the nine gates, green in the validator), closing with the F4.12
lab that assembles them into one `Portal.Store`. F5 &mdash; **Pragmatic Programming** &mdash; is the chapter that
turns those parts into a product. It has been reframed from a generic engineering survey into a single-product build
of the **Portal engine**: a framework-free domain core built pragmatically, technique by technique, until it is
ready to integrate with Phoenix LiveView. The chapter accent is **burgundy** (`--burgundy`), distinct from F4&rsquo;s
sage.

This session opened F5 by building its overview and laying the roadmap:

- **Chapter promoted to `live`** in the manifest (was `planned`), accent `sage` &rarr; `burgundy`, one-liner reframed
  to the engine build. `/elixir/pragmatic` is now a linkable route.
- **The nine F5 modules were rewritten** from the old generic topics (Mix, testing, typespecs, &hellip;) into the
  Portal-engine arc, keeping the module numbers `F5.01`&ndash;`F5.09` so the doc and reference maps (keyed by module
  `n`) stay valid: foundations (DRY/orthogonality/ETC) &rarr; domain modeling &rarr; tracer bullets / walking
  skeleton &rarr; design by contract &rarr; commands/queries/events &rarr; where state lives &rarr; pragmatic testing
  &rarr; boundaries &amp; seams &rarr; the **F5.09 lab: the Portal engine, LiveView-ready**. Every module now carries a
  three-dive roadmap; all are `planned` &mdash; they are the next authoring targets, in order.
- **Three system-design front-matter subpages were authored and built** (`CHAPTER_SUBPAGES["F5"]`, linkable because
  F5 is `live`): **F5.0.1** the blueprint (`pragmatic-architecture.html`, `/elixir/pragmatic/architecture`) &mdash; a
  four-layer stack (UI / facade / domain core / persistence) with a selector mapping each layer to the module that
  builds it; **F5.0.2** the domain model (`pragmatic-domain-model.html`, `/elixir/pragmatic/domain-model`) &mdash;
  the three bounded contexts (Accounts USR/SES, Catalog CRS/LSN/PGE, Learning ENR/PRG) with a selector listing each
  context&rsquo;s entities and branded-id namespaces; **F5.0.3** the command &amp; event flow
  (`pragmatic-flow.html`, `/elixir/pragmatic/flow`) &mdash; the five-stage command &rarr; contract &rarr; event &rarr;
  state &rarr; query pipeline with a selector mapping each stage to its module (F5.04/F5.05/F5.06). Each is **A+ on
  the nine gates**, `node --check` clean, voice clean, with a References block; burgundy accent, single SVG, prefixes
  `ar`/`dm`/`fl`. They are linked from a new **&ldquo;The system we&rsquo;re building&rdquo;** (`#design`) section on
  the landing as three `<a class="mod">` cards with a `design` pill &mdash; read-before-the-modules design pages, not
  modules (not counted in the module tally). Routes 125 &rarr; 128, PAGES 124 &rarr; 127.
- **F5.01 was authored and built as a full module** (hub + three dives, A+ on the nine gates, the first built F5
  module), reframing the old &ldquo;Pragmatic foundations / DRY-orthogonality-ETC&rdquo; placeholder into the concrete
  approach the user asked for: **stand the Portal up behind a thin Elixir web server from day one and grow it**, with
  Phoenix replacing the server in F6. Title **&ldquo;Start thin: a running Portal from day one&rdquo;**, slug
  `foundations` (`/elixir/pragmatic/foundations`). The hub centerpiece is the course-wide **development roadmap**
  &mdash; HTML templating &rarr; simple web server &rarr; Portal logic &rarr; Phoenix &rarr; Fly (Fly marked out of
  scope) &mdash; as a five-chip selector mapping each stage to its chapter; prefix `fo`, burgundy. Three dives:
  **F5.01.1 The development roadmap** (`/roadmap`, burgundy, prefix `rm`) &mdash; a big-design-up-front vs
  start-thin-and-iterate selector keyed on &ldquo;first running build&rdquo;, plus the roadmap mapped onto a Mix
  project tree; **F5.01.2 A thin web server in Elixir** (`/thin-server`, blue, prefix `ts`) &mdash; a request-path
  selector (request / route / engine / response) and the whole `Plug.Router` + `Bandit` child spec in code, each
  route a single `Portal.Engine` call; **F5.01.3 A web layer built for replacement** (`/replaceable`, gold, prefix
  `rp`) &mdash; a front-end toggle (thin server now / Phoenix in F6) over one constant engine box, with the same
  `dispatch/1` call shown from a Plug handler and a LiveView `handle_event` (orthogonality and ETC made concrete).
  Dive-card borders follow the convention (dive 1 = chapter accent burgundy, then blue, then gold); each dive page
  is themed to its card. References on the hub only (matching the F4 module pattern); dives end with pager + footer.
  `MODULES["F5"]` F5.01 + its three dives promoted to `built`; `SUBPAGES["F5.01"]` added; four PAGES entries
  (`foundations.html`, `foundations-roadmap.html`, `foundations-thin-server.html`, `foundations-replaceable.html`).
  On the landing, the F5.01 card was promoted from a planned `<div class="mod is-quiet">` to a linkable
  `<a class="mod">` with a `built` pill and the new title + dives, the hero lede&rsquo;s first technique now reads
  &ldquo;stand it up behind a thin web server so it runs from day one&rdquo;, and the chapter-arc node 01 was
  relabelled `DRY` &rarr; `serve`. Routes 128 &rarr; 132, PAGES 127 &rarr; 131, module tally 41 &rarr;
  42 built / 17 planned.
- **F5.02 was authored and built as a full module** (hub + three dives, A+ on the nine gates, the second built F5
  module): **&ldquo;Modeling the Portal domain&rdquo;**, slug `domain` (`/elixir/pragmatic/domain`). It builds the
  domain in three layers and goes deeper than the F5.0.2 design subpage (which is the map). The hub centerpiece is an
  **anatomy-of-a-context** figure &mdash; the Learning context shown inside out (structs at the core, the context
  boundary, the public-API band) as a three-way selector mapping each layer to its dive; prefix `dn`, burgundy.
  Three dives: **F5.02.1 Structs & typespecs** (`/structs`, burgundy, prefix `sr`) &mdash; an
  `@enforce_keys` / `defstruct` / `@type t` selector over an `Enrollment` struct, plus the full struct in code with
  the `KeyError`-on-missing-key behaviour; **F5.02.2 Bounded contexts** (`/contexts`, blue, prefix `cx`) &mdash; a
  three-context map (Accounts / Catalog / Learning) with by-id reference arrows and a per-context selector
  (owns / references), plus the module-per-context layout and the reference-by-id rule in code; **F5.02.3 A
  context's public API** (`/api`, gold, prefix `ap`) &mdash; a public-surface / private-core figure with a function
  selector (`enroll/2` constructor, `record_progress/2` command, `courses_of/1` query), plus the Learning API in code
  with `@spec`s, tagged tuples, a `with`-chain smart constructor, and `defp` validation. Dive-card borders follow the
  convention (burgundy / blue / gold); References on the hub only. `MODULES["F5"]` F5.02 + its three dives promoted to
  `built`; `SUBPAGES["F5.02"]` added; four PAGES entries (`domain.html`, `domain-structs.html`,
  `domain-contexts.html`, `domain-api.html`). On the landing the F5.02 card was promoted to a linkable
  `<a class="mod">` with a `built` pill (arc node 02 was already labelled `domain`). Routes 132 &rarr; 136, PAGES
  131 &rarr; 135, module tally 42 &rarr; 43 built / 16 planned.
- **F5.03 was authored and built as a full module** (hub + three dives, A+ on the nine gates, the third built F5
  module): **&ldquo;Tracer bullets: a walking skeleton&rdquo;**, slug `tracer-bullets`
  (`/elixir/pragmatic/tracer-bullets`). It connects F5.01 (the running server) and F5.02 (the domain) by driving one
  use case &mdash; enroll a learner &mdash; through every layer at once. The hub centerpiece is a **vertical-slice**
  figure (the enroll tracer piercing web / context API / struct / store) with a layer selector; prefix `tb`, burgundy.
  Three dives: **F5.03.1 Tracer bullets vs prototypes** (`/prototypes`, burgundy, prefix `tp`) &mdash; a two-row
  technique selector (kept-and-built-upon vs thrown-away) plus a real enroll route contrasted with a throwaway
  prototype script; **F5.03.2 The walking skeleton** (`/skeleton`, blue, prefix `sk`) &mdash; the enroll round-trip
  (request &rarr; `Learning.enroll/2` &rarr; `Store.put` &rarr; 201) as a four-step selector, plus the route + context
  `with`-chain wired end to end; **F5.03.3 Iterating the slice** (`/iterating`, gold, prefix `it`) &mdash; three
  vertical slices over a four-layer grid (enroll / deliver lesson / record progress) with an iteration selector, plus
  the second slice added in code (a new route + one Catalog function). Dive-card borders follow the convention
  (burgundy / blue / gold); References on the hub only. `MODULES["F5"]` F5.03 + its three dives promoted to `built`;
  `SUBPAGES["F5.03"]` added; four PAGES entries (`tracer-bullets.html`, `tracer-bullets-prototypes.html`,
  `tracer-bullets-skeleton.html`, `tracer-bullets-iterating.html`). On the landing the F5.03 card was promoted to a
  linkable `<a class="mod">` with a `built` pill (arc node 03 was already labelled `tracer`). Routes 136 &rarr;
  140, PAGES 135 &rarr; 139, module tally 43 &rarr; 44 built / 15 planned.
- **F5.04 was authored and built as a full module** (hub + three dives, A+ on the nine gates, the fourth built F5
  module): **&ldquo;Design by contract&rdquo;**, slug `contracts` (`/elixir/pragmatic/contracts`). It hardens the
  enroll command from F5.03 with a contract. The hub centerpiece is a **contract-triad** figure (a precondition gate
  &rarr; the enroll command &rarr; a postcondition, with an invariant band beneath) and a term selector; prefix `ct`,
  burgundy. Three dives: **F5.04.1 Preconditions, postconditions & invariants** (`/conditions`, burgundy, prefix `cd`)
  &mdash; a three-term ownership selector (caller / function / every operation) plus the contract written as
  documentation over `enroll`; **F5.04.2 Assertions in Elixir** (`/assertions`, blue, prefix `as`) &mdash; a
  four-idiom toolkit selector (guards / `with` / tagged tuple / `raise`) plus the whole contract in one function
  (binary-pattern guard, `with` chain, `{:error, _}`, and a `true = ... in 0..100` invariant assertion); **F5.04.3
  Failing fast** (`/fail-fast`, gold, prefix `ff`) &mdash; a fail-fast vs fail-late selector plus the check-then-act
  body contrasted with a commented act-then-discover version. The split between expected failures (tagged tuples) and
  impossible states (raise) runs through all three. Dive-card borders follow the convention (burgundy / blue / gold);
  References on the hub only. `MODULES["F5"]` F5.04 + its three dives promoted to `built`; `SUBPAGES["F5.04"]` added;
  four PAGES entries (`contracts.html`, `contracts-conditions.html`, `contracts-assertions.html`,
  `contracts-fail-fast.html`). On the landing the F5.04 card was promoted to a linkable `<a class="mod">` with a
  `built` pill (arc node 04 was already labelled `contract`). Routes 140 &rarr; 144, PAGES 139 &rarr; 143,
  module tally 44 &rarr; 45 built / 14 planned.
- **F5.05 was authored and built as a full module** (hub + three dives, A+ on the nine gates, the fifth built F5
  module): **&ldquo;Commands, queries & events&rdquo;**, slug `cqrs` (`/elixir/pragmatic/cqrs`). It builds on the
  contract-checked enroll command from F5.04 and formalizes how the engine handles change. The hub centerpiece is a
  **write-path / read-path** figure (command &rarr; event &rarr; state on the write path; query reads state on the
  read path) with a piece selector; prefix `cq`, burgundy. Three dives: **F5.05.1 Command/query separation**
  (`/cqs`, burgundy, prefix `cs`) &mdash; a two-row command-vs-query selector plus enroll (returns `:ok | {:error}`)
  beside courses_of (returns data); **F5.05.2 Domain events** (`/events`, blue, prefix `ev`) &mdash; a three-event
  selector (LearnerEnrolled / LessonDelivered / ProgressRecorded) plus an event struct and the `EVT`-stamped emit;
  **F5.05.3 The engine as a reducer** (`/reducer`, gold, prefix `rd`) &mdash; a left-fold diagram (s0 &rarr; s1
  &rarr; s2 &rarr; s3 over three events) plus `Enum.reduce(events, s0, &evolve/2)` and the decide/evolve pair. Note
  the command-return shift toward CQS (`enroll` now reports `:ok | {:error}` rather than a read model) and the new
  `EVT` event-id namespace, both stated in-page. Dive-card borders follow the convention (burgundy / blue / gold);
  References on the hub only. `MODULES["F5"]` F5.05 + its three dives promoted to `built`; `SUBPAGES["F5.05"]` added;
  four PAGES entries (`cqrs.html`, `cqrs-cqs.html`, `cqrs-events.html`, `cqrs-reducer.html`). On the landing the
  F5.05 card was promoted to a linkable `<a class="mod">` with a `built` pill (arc node 05 was already labelled
  `events`). Routes 144 &rarr; 148, PAGES 143 &rarr; 147, module tally 45 &rarr; 46 built / 13 planned.
- **F5.06 was authored and built as a full module** (hub + three dives, A+ on the nine gates, the sixth built F5
  module): **&ldquo;Where engine state lives&rdquo;**, slug `state` (`/elixir/pragmatic/state`). It answers where the
  F5.05 fold actually lives at runtime &mdash; the reducer is pure and forgets its result, so the Portal keeps the
  folded state alive in a **process**. The hub centerpiece is a **runtime** figure (a supervisor over the engine
  GenServer, fed by the event log) with a piece selector mapping holder / engine / supervisor to the three dives;
  prefix `wl`, burgundy. Three dives: **F5.06.1 Choosing where state lives** (`/choosing`, burgundy, prefix `ch`)
  &mdash; a three-row holder selector (GenServer / Agent / ETS) plus the three shapes and the GenServer choice;
  **F5.06.2 The engine GenServer** (`/genserver`, blue, prefix `gs`) &mdash; a three-callback selector
  (init / command / query) plus `Portal.Engine` with `init` folding the log, a command `handle_call` running
  decide/evolve, and a query `handle_call` reading; **F5.06.3 Supervision** (`/supervision`, gold, prefix `sv`)
  &mdash; a crash &rarr; restart &rarr; replay cycle selector plus `Portal.Application` with a `:one_for_one` tree.
  The throughline: state is a fold (F5.05), a GenServer holds it, and a supervisor rebuilds it by replaying the log on
  restart. Dive-card borders follow the convention (burgundy / blue / gold); References on the hub only (GenServer /
  Agent / ETS). `MODULES["F5"]` F5.06 + its three dives promoted to `built`; `SUBPAGES["F5.06"]` added; four PAGES
  entries (`state.html`, `state-choosing.html`, `state-genserver.html`, `state-supervision.html`). On the landing the
  F5.06 card was promoted to a linkable `<a class="mod">` with a `built` pill (arc node 06 was already labelled
  `state`). Routes 148 &rarr; 152, PAGES 147 &rarr; 151, module tally 46 &rarr; 47 built / 12 planned.
- **F5.07 was authored and built as a full module** (hub + three dives, A+ on the nine gates, the seventh built F5
  module): **&ldquo;Pragmatic testing&rdquo;**, slug `testing` (`/elixir/pragmatic/testing`). It tests the F5.06
  engine and leans on the architecture &mdash; because `decide`/`evolve` are pure and state is a fold, most of the
  engine is checked with plain example tests. The hub centerpiece is a **testing pyramid** (pure core at the base,
  properties in the middle, contracts on top) with a tier selector; prefix `tp`, burgundy. Three dives: **F5.07.1
  Testing the pure core** (`/pure-core`, burgundy, prefix `pc`) &mdash; a three-function selector (decide / evolve /
  replay) plus arrange-call-assert example tests with no process or mocks; **F5.07.2 Property-based testing**
  (`/property`, blue, prefix `pr`) &mdash; a three-property selector (determinism / invariant / totality) plus
  `StreamData` `check all` properties over generated logs and command sequences; **F5.07.3 Contract tests**
  (`/contract-tests`, gold, prefix `ct`) &mdash; a three-term selector (precondition / postcondition / invariant)
  plus the F5.04 contract written as assertions and a `doctest` line. The throughline: purity makes the tests cheap,
  and the F5.04 contract from earlier becomes executable here. Dive-card borders follow the convention (burgundy /
  blue / gold); References on the hub only (ExUnit / StreamData / ExUnit.DocTest). Because F5.06 is built, the hub
  links back to it as the engine under test. `MODULES["F5"]` F5.07 + its three dives promoted to `built`;
  `SUBPAGES["F5.07"]` added; four PAGES entries (`testing.html`, `testing-pure-core.html`, `testing-property.html`,
  `testing-contract-tests.html`). On the landing the F5.07 card was promoted to a linkable `<a class="mod">` with a
  `built` pill (arc node 07 was already labelled `tests`). Routes 152 &rarr; **156**, PAGES 151 &rarr; **155**,
  module tally 47 &rarr; 48 built / 11 planned.
- **F5.08 was authored and built as a full module on a deeper standard** (hub + three dives, A+ on the nine gates,
  the eighth built F5 module): **&ldquo;Boundaries &amp; integration seams&rdquo;**, slug `boundaries`
  (`/elixir/pragmatic/boundaries`). It is the first module written to the elevated brief &mdash; longer,
  expert-level, with each dive grounded in its references and carrying real Portal code rather than a single toy
  snippet. The subject is hexagonal architecture (ports &amp; adapters) applied to the F5.06 engine. The hub
  centerpiece is a **hexagon** (core in the centre; driven ports left, driving port right, the error contract crossing
  to the UI) with a seam selector; prefix `bd`, burgundy; it also carries a three-seam teaser code block. Three dives,
  each with four sections, an interactive figure, a second static diagram, and multiple real code blocks:
  **F5.08.1 Ports &amp; adapters** (`/ports`, burgundy, prefix `pa`) &mdash; the `Portal.EventStore` behaviour with a
  config resolver, an `InMemory` (Agent) adapter and a `Postgres` (Ecto) adapter both carrying `@behaviour`, and a
  dependency-direction diagram showing the arrows point inward; **F5.08.2 The engine facade** (`/facade`, blue, prefix
  `fc`) &mdash; the `Portal` context (`enroll/2`, `deliver_lesson/2`, `progress_of/1`), the `Engine.command/query`
  wrappers that are the only callers of `GenServer.call`, and an enroll call-sequence diagram; **F5.08.3 Error
  contracts for the UI** (`/errors`, gold, prefix `er`) &mdash; the `%Portal.Error{}` struct with a closed `code`
  union, a no-catch-all `from/1` translator (unmodelled reasons raise), a reason-to-render flow diagram, and a total
  LiveView `case`. References were enriched with Jos&eacute; Valim&rsquo;s &ldquo;Mocks and explicit contracts&rdquo;
  alongside Cockburn (hexagonal) and the Elixir behaviours doc; the dives cross-link F5.04/F5.05/F5.06/F5.07. Dive-card
  borders follow the convention (burgundy / blue / gold); References on the hub only. `MODULES["F5"]` F5.08 + its three
  dives promoted to `built`; `SUBPAGES["F5.08"]` added; four PAGES entries (`boundaries.html`, `boundaries-ports.html`,
  `boundaries-facade.html`, `boundaries-errors.html`). On the landing the F5.08 card was promoted to a linkable
  `<a class="mod">` with a `built` pill (arc node 08 was already labelled `seams`). Routes 156 &rarr; **160**, PAGES
  155 &rarr; **159**, module tally 48 &rarr; **49 built / 10 planned**. F5.09 (the engine lab) is the next authoring
  target &mdash; and should be written to this same deeper standard.
- **The landing was authored and built**: `content/f5-00-landing.html` &rarr; `pragmatic.html`, route
  `/elixir/pragmatic`. Hero + a nine-node chapter-arc SVG (shape it to change &middot; make it trustworthy &middot;
  make it usable) + the three design cards (`#design`) + nine module cards with their submodules (F5.01&ndash;F5.05 now
  linkable, F5.06&ndash;F5.09 planned) + a back-pager to F4 and a forward link to Contents. **Apollo A+ across the nine
  gates**; `node --check` clean; voice gate clean. Planned module cards are `<div class="mod is-quiet">`; the design
  cards and the F5.01&ndash;F5.05 cards are linkable `<a class="mod">`; the F5.09 card carries the `lab` class.
- **Validator**: a tagged `F5` desktop block (base + the twelve landing cards + the design/planned pills + the
  LiveView-ready lab card), one desktop block per design subpage (layer&rarr;module, context&rarr;entities,
  stage&rarr;module), one per F5.01 page (roadmap stage&rarr;chapter; approach&rarr;first-run, request-step,
  front-end&rarr;engine-unchanged), one per F5.02 page (context-layer&rarr;dive; struct-declaration,
  context&rarr;references, API-function&rarr;kind), one per F5.03 page (slice-layer&rarr;artifact; technique&rarr;fate,
  round-trip step, iteration&rarr;what-it-adds), one per F5.04 page (contract-term&rarr;detail; term&rarr;owner,
  idiom&rarr;what-it-expresses, fail-fast&rarr;where), one per F5.05 page (engine-piece&rarr;detail; kind&rarr;return,
  event&rarr;records, fold-step&rarr;transition), and one per F5.06 page (engine-piece&rarr;detail; holder&rarr;verdict,
  callback&rarr;does, step&rarr;what-happens), and one per F5.07 page (test-tier&rarr;detail; function&rarr;the-test,
  property&rarr;rule, contract-term&rarr;assertion), and one per F5.08 page (boundary-seam&rarr;detail;
  port-piece&rarr;what-it-is, facade-function&rarr;kind, error-case&rarr;message) &mdash; plus 390px mobile entries for
  all thirty-six F5 pages &mdash; **332 + 72 = 404 PASS, 0 FAIL, 0 images**.
- **Build-guide specs** (`build-guide/`): five Writerside-friendly markdown guides documenting how to build the
  Portal &mdash; `pragmatic.md` (TOC, conventions, branded-Snowflake id contract, global build sequence) plus
  `f5-01-start-thin.md`, `f5-02-domain.md`, `f5-03-tracer-bullets.md`, `f5-04-contracts.md`, each with What you'll
  build / Concepts / Specs tables / Build it actionables / copy-paste **Build prompts** / Definition of done. These
  are spec docs, not site pages (no manifest/validator wiring); voice gate clean; the toolkit norm is markdown first,
  presentation second. (An F5.05 guide is the natural next addition.)
- **Docs reframed and regenerated**: the F5.01 abstract (`A` map) and references (`REFS`) now describe the thin-server
  approach and the roadmap (sources: Pragmatic Programmer tracer bullets, Plug, Bandit, Phoenix), and the three
  F5.01 dives render as `\u25cf` sub-rows under F5.01 in the course-md table. Both generators report **voice gate
  CLEAN**, and the references still cover **59 / 59** modules.

The throughline to hold while authoring F5: each module applies one pragmatic technique to the **same** growing
engine &mdash; not nine demos but one coherent Portal engine &mdash; so that the F5.09 lab can mount the engine&rsquo;s
facade behind a LiveView sketch and hand a UI-ready boundary to F6, the Phoenix chapter.

**Deployment (not authoring), unchanged and now slightly larger:** the site-wide `/elixir` home and the
`/elixir/course` Contents page are not in this working tree. Contents must move its module count 54 &rarr; 57 (F4&rsquo;s
twelve modules) **and** now surface F5 as a `live` chapter linking `/elixir/pragmatic`; the new `pragmatic.html`
landing must be deployed alongside the per-chapter relinks already prepared here.

What a resuming agent should know, condensed:

1. The manifest (`build_page.py`) is the single source of truth. `MODULES` is keyed by chapter; every F4 module and
   dive is `status="built"`. `SUBPAGES` and `PAGES` are populated for all of F4 (`PAGES` filenames: the F4.12 lab is
   `lab.html` / `lab-grow.html` / `lab-registry.html` / `lab-range.html`). **F5 is `live` with its landing built**
   (`content/f5-00-landing.html` &rarr; `pragmatic.html`, route `/elixir/pragmatic`) plus **three front-matter design
   subpages** in `CHAPTER_SUBPAGES["F5"]` (`architecture` / `domain-model` / `flow` &rarr; `pragmatic-architecture.html`
   / `pragmatic-domain-model.html` / `pragmatic-flow.html`), linked as cards on the landing. **F5.01&ndash;F5.08 are
   built** as full modules (hub + three dives each): F5.01 `/foundations` +
   `/foundations/{roadmap,thin-server,replaceable}` (the &ldquo;start thin&rdquo; approach), F5.02 `/domain` +
   `/domain/{structs,contexts,api}` (modeling the Portal domain), F5.03 `/tracer-bullets` +
   `/tracer-bullets/{prototypes,skeleton,iterating}` (a walking skeleton, enroll a learner end to end), F5.04
   `/contracts` + `/contracts/{conditions,assertions,fail-fast}` (design by contract on the engine's commands), and
   F5.05 `/cqrs` + `/cqrs/{cqs,events,reducer}` (commands, queries & events; the engine as a reducer), F5.06
   `/state` + `/state/{choosing,genserver,supervision}` (where engine state lives; a GenServer holds the fold, a
   supervisor replays it on restart), F5.07 `/testing` + `/testing/{pure-core,property,contract-tests}`
   (pragmatic testing; pure-core examples, StreamData properties, the F5.04 contract run as tests), and F5.08
   `/boundaries` + `/boundaries/{ports,facade,errors}` (boundaries &amp; integration seams; ports as behaviours with
   swappable adapters, the facade as the driving port, a closed error contract for the UI &mdash; the first module on
   the deeper standard: longer dives grounded in references with real Portal code); its one remaining module
   `F5.09` (the engine lab) is still `planned`, with a three-dive roadmap &mdash; the next authoring target (write it
   to the same deeper standard), with REFS and `A`-map abstracts already keyed by module `n`.
   `allowed_routes()` returns **160** link routes; only built/live routes are linkable
   (the `F5.09` module route is not, since it is planned; F5.01&ndash;F5.08 and the chapter
   front-matter subpages are, since they are built and the chapter is `live`), external `https://` links are exempt.
2. Rebuild any page with `python3 build_page.py build --page KEY`, grade with `check OUT.html` (nine gates + A+),
   regenerate `_head.html` with `extract-head` after editing `HEAD_CSS`. The voice gate scans all visible text
   including `<pre class="code">` comments (only `<script>`/`<style>`/`<svg>` are stripped); `expectText` in the
   validator is case-SENSITIVE.
3. The validator (`validator/suite.elixir.js`) has a tagged desktop block and a 390px mobile entry for every module;
   run all with `BASE_URL="file:///home/claude/elixir-course" node validator/suite.elixir.js`, or one module with
   `ONLY="F4.NN"`. F4.12 is 35 desktop + 8 mobile = 43 PASS; the whole F5 chapter so far (`ONLY="F5"`) is 332 desktop
   + 72 mobile = 404 PASS.
4. `_gen_course_md.py` and `_gen_refs_md.py` read the manifest and both run a voice gate that must report CLEAN;
   keep 59/59 modules carrying references.

**Deferred wiring (not authoring):** lighting up F3.05–F3.09 on the F3 chapter landing needs
`content/f3-00-landing.html`, which is not in this bundle. The deploy gap above is the same kind of step — the
live site still trails the local manifest (now including the whole of F3 and the F4 landing + F4.01 + F4.02 +
F4.03 + F4.04 + F4.05 + F4.06 + F4.07 + F4.08 + F4.09 + F4.10 + F4.11 + F4.12). Both are sync/deploy steps to run against the full repository.

## Known follow-ups

- **Authoring standard raised at F5.08.** Per reviewer feedback, modules were too short and not expert-level; dives
  must be longer, draw robust approaches from their references, and carry real Portal app code rather than a single
  toy snippet. F5.08 is the first module built to this bar &mdash; each dive has four sections, an interactive figure,
  a second static diagram, and multiple real code blocks (the `EventStore` behaviour + two adapters, the `Portal`
  facade + engine wrappers, the `%Portal.Error{}` struct + `from/1` + a total LiveView `case`), with an enriched
  reference set. F5.09 should match it. Earlier F5 modules (notably F5.05&ndash;F5.07) predate the standard and are
  candidates for a depth retrofit if desired &mdash; same structure, more sections and real code per dive.
- The outline generator's hand-written "At a glance" summary prose lags the manifest (it predates the
  F2.09, F3.01–F3.09, and F4 promotions); its per-chapter tables, derived from the manifest, are correct and now
  show F3 fully built and the F4 chapter complete with F4.01&ndash;F4.12 all built hubs (three nested dives each). Refresh the summary prose in `_gen_course_md.py` when convenient.
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
