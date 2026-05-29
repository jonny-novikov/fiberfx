# Functional Programming in Elixir — Course Brief

A bridge from the algebra you already know to real-time apps on the BEAM. Six
chapters (**F1–F6**), **9 modules each = 54 modules** (eight lessons + a practical, richly-visual lab). English. Interactive,
runnable code throughout. Part of the jonnify knowledge map.

- **Landing:** `elixir.html` → `/elixir`
- **F1 chapter landing:** `elixir-algebra.html` → `/elixir/algebra`
- **Design system:** jonnify dark-editorial; Elixir-purple (`--elixir`) accent.
- **Authoring rules:** see `authoring-skills.md` (Technical Writer + Visualization Master).
- **Build:** `build_page.py` (extract-head once, then build; treat any FAIL as a stop).
- **Route convention:** `/elixir/<chapter-slug>/<module-slug>` (e.g. `/elixir/algebra/functions`).
- **Module id convention:** `F<chapter>.<NN>` (e.g. `F1.01`). The `.09` of every chapter is its **practical, richly-visual lab** — a hands-on capstone with a name specific to that chapter.

The arc: **Algebra → Functional Programming → the Elixir language → Algorithms &
Data Structures → Pragmatic engineering → Phoenix.** Each chapter reuses the last.

---

## F1 — Algebra  `/elixir/algebra`
*The functional mindset, straight from the math you know.* (landing built)

| # | module | one-line | status |
|---|--------|----------|--------|
| F1.01 | What a function really is | mapping, domain/range, exactly-one-output → first-class functions | **built** |
| F1.02 | The substitution model | equals for equals → referential transparency & purity | planned |
| F1.03 | Composition, f∘g | chaining mappings, associativity → the pipe `\|>` | planned |
| F1.04 | Immutability & binding | a symbol names a fixed value → immutable data | planned |
| F1.05 | Sets, sequences & mappings | applying f across a collection → lists, maps, `Enum.map` | planned |
| F1.06 | Recursion & induction | base case + step; proof → recursion, no loops | planned |
| F1.07 | Higher-order operators (Σ, Π) | operators over functions → `map`/`filter`/`reduce` | planned |
| F1.08 | Equations & pattern matching | identities, solving by structure → pattern matching | planned |
| **F1.09** | **Functions on the plane — a plotting lab** | practical: plot & compose functions, watch f∘g as curves; rich visualization | planned |

## F2 — Functional Programming
*Pure functions, immutability and higher-order functions in their own right.*

| # | module | one-line |
|---|--------|----------|
| F2.01 | Pure functions & side effects | what purity buys you; isolating effects |
| F2.02 | Immutability & persistent data | structural sharing, why copying is cheap |
| F2.03 | Higher-order functions | functions as arguments and return values |
| F2.04 | Recursion patterns & tail calls | accumulators, tail-call optimisation |
| F2.05 | map / filter / reduce (folds) | reduce as the universal fold |
| F2.06 | Closures & partial application | capturing environment; `&` and currying-by-hand |
| F2.07 | Algebraic data types | sum/product types, tagged tuples, pattern matching |
| F2.08 | Composition & pipelines | building programs by composing functions |
| **F2.09** | **The data-pipeline lab** | practical: compose map/filter/reduce over a dataset; watch each stage |

## F3 — The Elixir Language
*Syntax, pipelines, pattern matching and structs on the BEAM.*

| # | module | one-line |
|---|--------|----------|
| F3.01 | Values, types & IEx | the data you build with; the shell as a tool |
| F3.02 | Pattern matching & the match operator | `=` is a match, not assignment |
| F3.03 | Functions, modules & the pipe `\|>` | defining and composing in modules |
| F3.04 | Enumerables & streams | eager vs lazy traversal |
| F3.05 | Structs, maps & keyword lists | shaping data; when to use which |
| F3.06 | Protocols & behaviours | polymorphism and contracts |
| F3.07 | Processes & the actor model | spawn, send, receive; isolation |
| F3.08 | OTP: GenServer & supervisors | stateful servers and fault tolerance |
| **F3.09** | **The process playground** | practical: spawn processes, send messages, watch the mailbox live |

## F4 — Algorithms & Data Structures in Elixir
*Classical and advanced problems — with rich visualization.* (user-named)

| # | module | one-line |
|---|--------|----------|
| F4.01 | Lists, recursion & complexity | cons cells, big-O on the BEAM |
| F4.02 | Trees & traversals | binary/n-ary trees, DFS/BFS, functionally |
| F4.03 | Sorting & searching | merge/quick sort, binary search, immutably |
| F4.04 | Maps, sets & hashing | hash maps, collisions, the cost model |
| F4.05 | Hash Array Mapped Tries (HAMT) | persistent maps via prefix trees |
| F4.06 | **CHAMP maps** | Compressed Hash-Array Mapped Prefix-trees; layout & iteration |
| F4.07 | **Branded Champ maps** | namespaced/branded keys as cross-system pivots (e.g. `TSK0KHTOWnGLuC`) |
| F4.08 | Dynamic programming & advanced problems | memoisation and harder challenges |
| **F4.09** | **Watch a Branded Champ map grow** | practical: insert keys, animate the CHAMP / Branded Champ trie building |

> F4 is the visualization-heavy chapter: CHAMP node layout, branch compression,
> and Branded Champ key routing are all shown interactively.

## F5 — Pragmatic Programming with Elixir
*Real-world engineering: structure, testing, tooling, shipping.* (user-named)

| # | module | one-line |
|---|--------|----------|
| F5.01 | Project structure & Mix | apps, deps, tasks |
| F5.02 | Testing with ExUnit & doctests | fast, deterministic tests |
| F5.03 | Documentation & typespecs | `@doc`, `@spec`, Dialyzer |
| F5.04 | Error handling & "let it crash" | tagged tuples vs exceptions; supervision |
| F5.05 | Concurrency patterns & Tasks | `Task`, `async/await`, back-pressure |
| F5.06 | Telemetry, logging & observability | seeing inside a running system |
| F5.07 | Dependencies, releases & deployment | `mix release`, config, runtime |
| F5.08 | Performance & profiling | benchmarks, the scheduler, hot paths |
| **F5.09** | **Let it crash — a supervision tree that heals** | practical: crash a worker, watch the supervisor restart it |

## F6 — Phoenix Framework
*Web applications on Elixir — and the road into real-time LiveView.* (user-named)

| # | module | one-line |
|---|--------|----------|
| F6.01 | Architecture & the request lifecycle | endpoint → router → controller → view |
| F6.02 | Routing, controllers & plugs | the plug pipeline |
| F6.03 | Ecto: schemas, changesets & queries | data, validation, the repo |
| F6.04 | Contexts & domain design | boundaries that scale |
| F6.05 | Templates, components & HEEx | server-rendered markup |
| F6.06 | Phoenix LiveView fundamentals | interactive UIs without hand-written JS |
| F6.07 | PubSub, channels & real-time | live updates over WebSockets |
| F6.08 | Auth, deployment & going live | sessions, releases, production |
| **F6.09** | **The live dashboard** | practical: real-time LiveView state over a socket, multi-client via PubSub |

---

## Status
- **F1.01 "What a function really is" — built** (`f1-01-functions.html` → `/elixir/algebra/functions`).
- F1 landing + course landing live. Remaining 53 modules planned per the tables above (including the six `.09` practical labs).
- F2/F3 titles are inferred to fit the arc; rename freely.
