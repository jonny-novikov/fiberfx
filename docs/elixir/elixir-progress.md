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
**39 modules are built in the manifest; 20 are planned.** Of the 115 registered page fragments, the whole of F3
(9 modules) plus the F4 landing and F4.01, F4.02, F4.03, F4.04, F4.05, F4.06, F4.07, F4.08, F4.09, and F4.10 are authorable source in this working tree and were
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
F4.09 (Branded CHAMP maps &amp; GenServer), and F4.10 (Practical recipes in Elixir) are now built** &mdash; each a
hub plus three dives with an advanced section and a References block. F4.09 closes the spine: it folds the CHAMP node
(F4.06) and the branded id (F4.07/F4.08) into one in-memory store &mdash; a CHAMP keyed by branded ids, partitioned
by the three-letter namespace, owned by a GenServer &mdash; and threads three Portal uses through its dives: the
entity registry (partition), progress snapshots (structural sharing), and the session store (GenServer, lock-free
reads over a published immutable root). F4.10 then turns those structures into the Portal&rsquo;s everyday code: a
`with` chain for the request lifecycle (validate &rarr; authenticate &rarr; load &rarr; authorize, short-circuiting
to a status), a lazy `Stream` pipeline for the activity feed (fused filter/map that stops at `take/2`), and reading
complexity to choose a lookup (`O(n)` list scan vs `O(log32 n)` CHAMP). F4.11&ndash;F4.12 remain planned. The
five-module **persistent-map spine is complete**: F4.05&ndash;F4.09 (HAMT &rarr; CHAMP &rarr; **identifiers, Snowflake
&amp; branded ids** &rarr; **branded ids &amp; persistence** &rarr; **branded CHAMP maps &amp; GenServer**), followed
by practical recipes (F4.10, built), dynamic programming (F4.11), and a lab that builds a branded CHAMP store (F4.12,
three dives). The id, persistence, branded-CHAMP, and recipes modules give the branded Snowflake / trie convention
used across the course its own modules; **F4.05.2 was renamed from slug `index` to
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
| F4.11 Dynamic programming & advanced problems (+ 3 dives) | `/elixir/algorithms/dynamic-programming` | planned | planned | — | — |
| F4.12 Lab: build a branded CHAMP store (+ 3 dives) | `/elixir/algorithms/lab` | planned | planned | — | — |

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

**The F4 chapter is open; F4.01&ndash;F4.10 are complete.** The chapter is
`live`, the landing (`/elixir/algorithms`) is built, and **F4.01&ndash;F4.10** each ship as a hub plus three dives.
F4.02&ndash;F4.10 carry a dedicated advanced section on every page, all A+ and green in the validator (F4.04:
45+8 = 53 PASS; F4.05: 44+8 = 52 PASS; F4.06: 46+8 = 54 PASS; F4.07: 34+8 = 42 PASS; F4.08: 33+8 = 41 PASS; F4.09:
34+8 = 42 PASS; F4.10: 33+8 = 41 PASS). Every page now also carries a **References** section (Sources + Related in
this course), styled by `.refs` in `HEAD_CSS`. The persistent-map spine is complete:
**F4.04** grounds maps/sets/hashing in the course&rsquo;s own page registry (a map keyed by branded `PGE`
Snowflake ids, the route sets behind the links gate, `phash2` into a 32-way HAMT); **F4.05 (HAMT)** builds that
32-way trie explicitly &mdash; one bitmap and one packed array per node, a 5-bit hash-chunk descent, and path-copy
structural sharing; **F4.06 (CHAMP)** compresses the node into two bitmaps and two arrays for a canonical shape and
cheap diffs. With F4.05 built, the F4.04 &rarr; F4.05 and F4.06 &rarr; F4.05 references are linked, the F4.06 hub
back-pager points to `/elixir/algorithms/hamt`, and the F4 landing&rsquo;s F4.05 card is linkable (its journey-SVG
node left thematic, per the F4.06 precedent). **The chapter was then restructured to twelve modules, with F4.07
(Identifiers, Snowflake &amp; branded ids), F4.08 (Branded ids &amp; persistence), F4.09 (Branded CHAMP maps &amp;
GenServer), and F4.10 (Practical recipes in Elixir) built**: F4.07&rsquo;s dives decode a branded id, run a real
lexical sort, and extract Snowflake fields; F4.08&rsquo;s dives store the id as a `bigint`, range-query by time via
`id >= min AND id < max`, and validate a request id at the edge to answer malformed or impossible ids with a `404`
before any I/O; F4.09&rsquo;s dives fold the lot into one in-memory store &mdash; a CHAMP keyed by branded ids,
partitioned by namespace, owned by a GenServer &mdash; with three Portal uses (entity registry, progress snapshots,
session store); F4.10&rsquo;s dives turn those structures into everyday code &mdash; a `with` chain for the request
lifecycle, a lazy `Stream` pipeline for the activity feed, and reading `O(n)` vs `O(log32 n)` to choose a lookup.
F4.11&ndash;F4.12 remain planned; the now-complete spine is F4.05&ndash;F4.09 (HAMT, CHAMP, identifiers, persistence,
branded CHAMP), with recipes (F4.10, built), dynamic programming (F4.11), and a branded-CHAMP lab (F4.12) after it.
F4.05.2 was renamed slug `index`&rarr;`indexing` (route `/elixir/algorithms/hamt/indexing`) to avoid an `index.html`
collision when serving statically. The chapter accent is sage; `.ex`/`code.inl` stay the global Elixir purple.

**Resume at F4.11 — Dynamic programming &amp; advanced problems** (`slug` "dynamic-programming", route
`/elixir/algorithms/dynamic-programming`), the module after the recipes. It is `planned` with a three-dive roadmap
(memoization &amp; overlapping subproblems / tabulation &amp; bottom-up / classic DP problems). It covers
memoisation, tabulation, and harder challenges, with the natural Portal frame being cached or precomputed results
&mdash; a memoised computation over the catalog, a bottom-up table, a classic DP problem worked in Elixir. The bridge
in is F4.10 (the recipes) and the chapter&rsquo;s data structures; after it: the F4.12 lab that builds a branded
CHAMP store.

Immediate steps for F4.11, in order:

1. Author the F4.11 hub + three dive subpages into `content/` (e.g. `f4-11-dynamic-programming.html` + three dives:
   memoization, tabulation, problems), following the page anatomy in `SKILL.md`, with an advanced section and a
   References block per page. Keep the Portal frame; keep interactive element prefixes off `st` and unique per page.
2. Promote F4.11 to `built`; the `dives` roadmap is already in the manifest — add `SUBPAGES["F4.11"]` and register
   PAGES with unique output filenames (e.g. `dynamic-programming*.html`). Confirm the route is
   `/elixir/algorithms/dynamic-programming`.
3. Relink F4.10&rsquo;s "next module" references to F4.11 (the F4.10 hub note and the profiling-dive note name
   **F4.11 — Dynamic programming in Elixir** unlinked, "in production"): wrap them in
   `<a href="/elixir/algorithms/dynamic-programming">` and drop "(in production)". On the F4 landing, change the
   F4.11 card from `<div class="mod is-quiet">` to a linkable
   `<a class="mod" href="/elixir/algorithms/dynamic-programming">`, pill `planned` → `built` (leave the journey-SVG
   node thematic). Note the F4.11 hub title in the manifest is "Dynamic programming &amp; advanced problems" while the
   F4.10 forward-pointers say "Dynamic programming in Elixir" — reconcile the wording when relinking.
4. Verify routes, run the voice sweep (incl. JS strings AND static code comments — a dismissive adverb inside a
   `<pre class="code">` comment is visible text and fails the voice gate, because static code is NOT stripped the
   way `<script>` is; note `expectText` is case-SENSITIVE, so validator needles must match the page's capitalisation),
   build, grade for A+, `node --check` the JS, and add a tagged validator block run with `ONLY="F4.11"`. Confirm each
   new page carries a References section.
5. Regenerate `functional-programming-in-elixir.md` and `elixir-references.md`, update this tracker, then deliver.
   (After F4.11: the F4.12 lab — `lab=True` with dives grow / registry / range — closes the chapter.)

**Deferred wiring (not authoring):** lighting up F3.05–F3.09 on the F3 chapter landing needs
`content/f3-00-landing.html`, which is not in this bundle. The deploy gap above is the same kind of step — the
live site still trails the local manifest (now including the whole of F3 and the F4 landing + F4.01 + F4.02 +
F4.03 + F4.04 + F4.05 + F4.06 + F4.07 + F4.08 + F4.09 + F4.10). Both are sync/deploy steps to run against the full repository.

## Known follow-ups

- The outline generator's hand-written "At a glance" summary prose lags the manifest (it predates the
  F2.09, F3.01–F3.09, and F4 promotions); its per-chapter tables, derived from the manifest, are correct and now
  show F3 fully built and the F4 chapter open with F4.01&ndash;F4.10 as built hubs (three nested dives each) and the
  planned F4.11&ndash;F4.12 with their three-dive roadmaps. Refresh the summary prose in `_gen_course_md.py` when convenient.
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
