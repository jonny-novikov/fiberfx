# Elixir Course — References

A curated bibliography keyed to every module of the *Functional Programming in Elixir* course. Each module below carries a short, paste-ready list of authoritative sources — official documentation, primary papers, and canonical books — ready to drop into a **References** block on the corresponding page.

> The lists favour primary sources: the Elixir and Erlang/OTP documentation, the papers a topic rests on, and a small set of standard books (collected in the appendix). They are deliberately short — two to four entries — so a page's References block stays focused.

## How to use this file

- Each `###` heading matches a module id and title from the course manifest, so a page can pull its block by id.
- A module's list is self-contained and ready to paste; the **Core references** below are assumed throughout and need not be repeated on every page.
- Subpages (the deep dives under an F2 hub) inherit their parent module's references; add a subpage-specific entry only where the dive introduces a source of its own.
- Books are cited by short name inline and listed in full under **Further reading — books**.

## Core references

Cited implicitly by most pages; link these once in a shared footer or the course landing rather than on every page.

- [Elixir documentation (guides + module reference)](https://hexdocs.pm/elixir/) — the primary source for the language and standard library.
- [Elixir — Introduction (Getting Started)](https://hexdocs.pm/elixir/introduction.html) — the introductory walkthrough; chapters are linked per module above.
- [The Elixir website — install & learning hub](https://elixir-lang.org/learning.html) — curated books, courses, and videos.
- [Erlang/OTP documentation](https://www.erlang.org/doc) — the runtime Elixir compiles to.
- [HexDocs](https://hexdocs.pm/) — documentation for every published package.

## F0 &middot; History

History and context. Primary accounts of where functional languages and the BEAM came from.

### F0.1 &middot; The evolution of functional languages & runtimes

- [The Lambda Calculus (Stanford Encyclopedia of Philosophy)](https://plato.stanford.edu/entries/lambda-calculus/) — the formal core every functional language descends from.
- [John McCarthy, “History of Lisp”](https://www-formal.stanford.edu/jmc/history/lisp/lisp.html) — the origins of Lisp, by its creator.
- [Hudak, Hughes, Peyton Jones & Wadler, “A History of Haskell: Being Lazy with Class” (2007)](https://www.microsoft.com/en-us/research/publication/a-history-of-haskell-being-lazy-with-class/) — the ML/Haskell lineage and the immutable turn.
- [Abelson & Sussman, *Structure and Interpretation of Computer Programs*](https://mitpress.mit.edu/sicp/) — the canonical functional-programming text.

### F0.2 &middot; The evolution of Erlang, the BEAM & OTP

- [Joe Armstrong, “Making reliable distributed systems in the presence of software errors” (PhD thesis, 2003)](https://erlang.org/download/armstrong_thesis_2003.pdf) — the design rationale for Erlang and OTP.
- [Armstrong, “A History of Erlang” (HOPL III, 2007)](https://dl.acm.org/doi/10.1145/1238844.1238850) — telecom roots through to open source.
- [Erlang/OTP documentation](https://www.erlang.org/doc) — the BEAM, the runtime, and OTP.
- [Fred Hébert, *Learn You Some Erlang for Great Good!*](https://learnyousomeerlang.com/) — free, accessible tour of the runtime.

## F1 &middot; Algebra

The mathematical foundation. References pair each idea with its treatment in SICP and the matching Elixir guide.

### F1.01 &middot; What a function really is

- [Function (mathematics) — Wikipedia](https://en.wikipedia.org/wiki/Function_(mathematics)) — domain, range, and single-valued mappings.
- [SICP §1.1, “The Elements of Programming”](https://mitpress.mit.edu/sicp/) — procedures as first-class objects.
- [Elixir — Anonymous functions](https://hexdocs.pm/elixir/anonymous-functions.html) — first-class functions in Elixir.

### F1.02 &middot; The substitution model

- [SICP §1.1.5, “The Substitution Model for Procedure Application”](https://mitpress.mit.edu/sicp/) — evaluation as substitution.
- [Referential transparency — Wikipedia](https://en.wikipedia.org/wiki/Referential_transparency) — equals for equals; the meaning of purity.

### F1.03 &middot; Composition, f∘g

- [Function composition — Wikipedia](https://en.wikipedia.org/wiki/Function_composition) — f after g, and associativity.
- [Elixir — Kernel.|>/2 (the pipe operator)](https://hexdocs.pm/elixir/Kernel.html#%7C%3E/2) — composition written left to right.

### F1.04 &middot; Immutability & binding

- [Immutable object — Wikipedia](https://en.wikipedia.org/wiki/Immutable_object) — names bound to fixed values.
- [Elixir — Pattern matching](https://hexdocs.pm/elixir/pattern-matching.html) — binding, and why = is a match.

### F1.05 &middot; Sets, sequences & mappings

- [Map (higher-order function) — Wikipedia](https://en.wikipedia.org/wiki/Map_(higher-order_function)) — applying a function across a collection.
- [Elixir — Enum](https://hexdocs.pm/elixir/Enum.html) — Enum.map and friends over enumerables.
- [Elixir — Keywords and maps](https://hexdocs.pm/elixir/keywords-and-maps.html) — the collection types in practice.

### F1.06 &middot; Recursion & induction

- [Mathematical induction — Wikipedia](https://en.wikipedia.org/wiki/Mathematical_induction) — base case, step, and the proof.
- [SICP §1.2, “Procedures and the Processes They Generate”](https://mitpress.mit.edu/sicp/) — recursive and iterative processes.
- [Elixir — Recursion](https://hexdocs.pm/elixir/recursion.html) — loops as recursion in Elixir.

### F1.07 &middot; Higher-order operators (Σ, Π)

- [SICP §1.3, “Formulating Abstractions with Higher-Order Procedures”](https://mitpress.mit.edu/sicp/) — operators over functions.
- [Fold (higher-order function) — Wikipedia](https://en.wikipedia.org/wiki/Fold_(higher-order_function)) — Σ and Π as folds.
- [Elixir — Enum.reduce/3](https://hexdocs.pm/elixir/Enum.html#reduce/3) — the general higher-order operator.

### F1.08 &middot; Equations & pattern matching

- [Pattern matching — Wikipedia](https://en.wikipedia.org/wiki/Pattern_matching) — solving by structure.
- [Elixir — Pattern matching](https://hexdocs.pm/elixir/pattern-matching.html) — the match operator and clauses.

### F1.09 &middot; Functions on the plane — a plotting lab

- [Function composition — Wikipedia](https://en.wikipedia.org/wiki/Function_composition) — f∘g seen as curves.
- [Elixir — Introduction](https://hexdocs.pm/elixir/introduction.html) — the basics the lab applies.

## F2 &middot; Functional Programming

Functional programming as Elixir. The standard-library docs plus the papers and concepts behind each idea.

### F2.01 &middot; Pure functions & side effects

- [Pure function — Wikipedia](https://en.wikipedia.org/wiki/Pure_function) — determinism and no side effects.
- [Side effect (computer science) — Wikipedia](https://en.wikipedia.org/wiki/Side_effect_(computer_science)) — what purity isolates.
- *Elixir in Action* — functional abstractions — see the books appendix.

### F2.02 &middot; Immutability & persistent data

- [Persistent data structure — Wikipedia](https://en.wikipedia.org/wiki/Persistent_data_structure) — structural sharing under immutability.
- [Bagwell, “Ideal Hash Trees” (2001)](https://lampwww.epfl.ch/papers/idealhashtrees.pdf) — the sharing that makes copying cheap.
- *Purely Functional Data Structures* — Okasaki — see the books appendix.

### F2.03 &middot; Higher-order functions

- [Higher-order function — Wikipedia](https://en.wikipedia.org/wiki/Higher-order_function) — functions as arguments and results.
- [Elixir — Enum](https://hexdocs.pm/elixir/Enum.html) — higher-order functions over collections.
- [Elixir — Anonymous functions](https://hexdocs.pm/elixir/anonymous-functions.html) — fn, &, and the capture operator.

### F2.04 &middot; Recursion patterns & tail calls

- [Elixir — Recursion](https://hexdocs.pm/elixir/recursion.html) — accumulators and recursive shape.
- [Tail call — Wikipedia](https://en.wikipedia.org/wiki/Tail_call) — constant-stack recursion.
- *Programming Elixir* — recursion chapter — see the books appendix.

### F2.05 &middot; map / filter / reduce (folds)

- [Elixir — Enum](https://hexdocs.pm/elixir/Enum.html) — map, filter, reduce, and beyond.
- [Fold (higher-order function) — Wikipedia](https://en.wikipedia.org/wiki/Fold_(higher-order_function)) — reduce as the universal fold.
- [Graham Hutton, “A tutorial on the universality and expressiveness of fold” (1999)](https://people.cs.nott.ac.uk/pszgmh/fold.pdf) — why everything is a fold.

### F2.06 &middot; Closures & partial application

- [Closure (computer programming) — Wikipedia](https://en.wikipedia.org/wiki/Closure_(computer_programming)) — capturing the environment.
- [Elixir — Function (the capture operator)](https://hexdocs.pm/elixir/Function.html) — & capture and function references.
- [Partial application — Wikipedia](https://en.wikipedia.org/wiki/Partial_application) — fixing arguments to specialise.

### F2.07 &middot; Algebraic data types

- [Algebraic data type — Wikipedia](https://en.wikipedia.org/wiki/Algebraic_data_type) — sums and products.
- [Tagged union — Wikipedia](https://en.wikipedia.org/wiki/Tagged_union) — tagged tuples as sum types.
- [Elixir — Structs](https://hexdocs.pm/elixir/structs.html) — product types in Elixir.

### F2.08 &middot; Composition & pipelines

- [Function composition — Wikipedia](https://en.wikipedia.org/wiki/Function_composition) — composing functions.
- [Elixir — Kernel.|>/2 (the pipe operator)](https://hexdocs.pm/elixir/Kernel.html#%7C%3E/2) — the pipe and its first-argument rule.
- [Elixir — Stream](https://hexdocs.pm/elixir/Stream.html) — lazy pipelines over data.

### F2.09 &middot; The data-pipeline lab

- [Elixir — Enum](https://hexdocs.pm/elixir/Enum.html) — the stages a pipeline is built from.
- [Elixir — Stream](https://hexdocs.pm/elixir/Stream.html) — lazy, composable pipelines.
- [Elixir — Enumerables and streams (guide)](https://hexdocs.pm/elixir/enumerable-and-streams.html) — eager versus lazy traversal.

## F3 &middot; The Elixir Language

The language proper. Almost entirely the official guides and module references.

### F3.01 &middot; Values, types & IEx

- [Elixir — Basic types](https://hexdocs.pm/elixir/basic-types.html) — the values you build with.
- [Elixir — IEx](https://hexdocs.pm/iex/IEx.html) — the interactive shell.

### F3.02 &middot; Pattern matching & the match operator

- [Elixir — Pattern matching](https://hexdocs.pm/elixir/pattern-matching.html) — = as the match operator.
- [Elixir — case, cond, and if](https://hexdocs.pm/elixir/case-cond-and-if.html) — matching in control flow.

### F3.03 &middot; Functions, modules & the pipe

- [Elixir — Modules and functions](https://hexdocs.pm/elixir/modules-and-functions.html) — defining and grouping functions.
- [Elixir — Kernel](https://hexdocs.pm/elixir/Kernel.html) — def, defp, and the pipe.

### F3.04 &middot; Enumerables & streams

- [Elixir — Enumerables and streams (guide)](https://hexdocs.pm/elixir/enumerable-and-streams.html) — eager versus lazy.
- [Elixir — Stream](https://hexdocs.pm/elixir/Stream.html) — lazy enumerables.
- [Elixir — Enumerable protocol](https://hexdocs.pm/elixir/Enumerable.html) — what makes a thing enumerable.

### F3.05 &middot; Structs, maps & keyword lists

- [Elixir — Keywords and maps](https://hexdocs.pm/elixir/keywords-and-maps.html) — choosing a data shape.
- [Elixir — Structs](https://hexdocs.pm/elixir/structs.html) — named, typed maps.
- [Elixir — Map](https://hexdocs.pm/elixir/Map.html) — the map module.

### F3.06 &middot; Protocols & behaviours

- [Elixir — Protocols](https://hexdocs.pm/elixir/protocols.html) — polymorphism by data type.
- [Elixir — Protocol](https://hexdocs.pm/elixir/Protocol.html) — defining and consolidating protocols.
- [Elixir — Typespecs and behaviours](https://hexdocs.pm/elixir/typespecs.html) — contracts via behaviours.

### F3.07 &middot; Processes & the actor model

- [Elixir — Processes](https://hexdocs.pm/elixir/processes.html) — spawn, send, receive.
- [Actor model — Wikipedia](https://en.wikipedia.org/wiki/Actor_model) — the concurrency model.
- [Armstrong thesis — concurrency-oriented programming](https://erlang.org/download/armstrong_thesis_2003.pdf) — isolation and message passing.

### F3.08 &middot; OTP: GenServer & supervisors

- [Elixir — GenServer](https://hexdocs.pm/elixir/GenServer.html) — the stateful server behaviour.
- [Elixir — Mix & OTP: GenServer (guide)](https://hexdocs.pm/elixir/genservers.html) — building one step by step.
- [Elixir — Supervisor](https://hexdocs.pm/elixir/Supervisor.html) — fault tolerance and restarts.

### F3.09 &middot; The process playground

- [Elixir — Processes](https://hexdocs.pm/elixir/processes.html) — the mailbox and message passing.
- [Elixir — Process](https://hexdocs.pm/elixir/Process.html) — the process API.

## F4 &middot; Algorithms & Data Structures

Algorithms and data structures. The persistent-map family rests on primary papers; the branded key ties to Snowflake.

### F4.01 &middot; Lists, recursion & complexity

- [Elixir — List](https://hexdocs.pm/elixir/List.html) — cons-cell lists.
- [Erlang — Efficiency Guide](https://www.erlang.org/doc/system/efficiency_guide.html) — complexity on the BEAM.
- [Okasaki, *Purely Functional Data Structures* (1996 thesis, free PDF)](https://www.cs.cmu.edu/~rwh/students/okasaki.pdf) — the foundational text.

### F4.02 &middot; Trees & traversals

- [Tree traversal — Wikipedia](https://en.wikipedia.org/wiki/Tree_traversal) — DFS and BFS.
- [Okasaki, *Purely Functional Data Structures* (thesis PDF)](https://www.cs.cmu.edu/~rwh/students/okasaki.pdf) — trees, functionally.

### F4.03 &middot; Sorting & searching

- [Merge sort — Wikipedia](https://en.wikipedia.org/wiki/Merge_sort) — a stable functional sort.
- [*Introduction to Algorithms* (CLRS)](https://mitpress.mit.edu/9780262046305/) — sorting and searching, in depth.

### F4.04 &middot; Maps, sets & hashing

- [Hash table — Wikipedia](https://en.wikipedia.org/wiki/Hash_table) — hashing and collisions.
- [Elixir — Map / MapSet](https://hexdocs.pm/elixir/Map.html) — maps and sets in Elixir.

### F4.05 &middot; Hash Array Mapped Tries (HAMT)

- [Bagwell, “Ideal Hash Trees” (2001)](https://lampwww.epfl.ch/papers/idealhashtrees.pdf) — the original HAMT paper.
- [Hash array mapped trie — Wikipedia](https://en.wikipedia.org/wiki/Hash_array_mapped_trie) — the structure in brief.

### F4.06 &middot; CHAMP maps

- [Steindorfer & Vinju, “Optimizing Hash-Array Mapped Tries…” (OOPSLA 2015)](https://michael.steindorfer.name/publications/oopsla15.pdf) — the CHAMP paper (DOI 10.1145/2814270.2814312).
- [The Morning Paper — CHAMP summary](https://blog.acolyer.org/2015/11/27/hamt/) — an accessible walkthrough.

### F4.07 &middot; Identifiers, Snowflake & branded ids

- [Snowflake ID — Wikipedia](https://en.wikipedia.org/wiki/Snowflake_ID) — the 64-bit time-ordered id layout.
- [Twitter Snowflake (archived source, 2010)](https://github.com/twitter-archive/snowflake/tree/snowflake-2010) — the original generator.
- [Discord — Snowflakes (developer reference)](https://discord.com/developers/docs/reference#snowflakes) — a practical bit-layout spec.

### F4.08 &middot; Branded ids & persistence

- [SQLite — Datatypes](https://www.sqlite.org/datatype3.html) — storing branded ids as TEXT keys.
- [PostgreSQL — Data Types](https://www.postgresql.org/docs/current/datatype.html) — a branded id as a primary key.
- [Ecto — Ecto.Schema](https://hexdocs.pm/ecto/Ecto.Schema.html) — custom primary-key types in Elixir persistence.

### F4.09 &middot; Branded CHAMP maps & GenServer

- [Steindorfer & Vinju, CHAMP (OOPSLA 2015)](https://michael.steindorfer.name/publications/oopsla15.pdf) — the trie keyed by branded ids.
- [Elixir — GenServer](https://hexdocs.pm/elixir/GenServer.html) — the server holding the partitioned map.
- [Snowflake ID — Wikipedia](https://en.wikipedia.org/wiki/Snowflake_ID) — the branded-key namespace scheme.

### F4.10 &middot; Practical recipes in Elixir

- [Elixir — Enum](https://hexdocs.pm/elixir/Enum.html) — idiomatic collection recipes.
- [Elixir — Stream](https://hexdocs.pm/elixir/Stream.html) — lazy pipelines over large data.

### F4.11 &middot; Dynamic programming & advanced problems

- [Dynamic programming — Wikipedia](https://en.wikipedia.org/wiki/Dynamic_programming) — memoisation and overlapping subproblems.
- [*Introduction to Algorithms* (CLRS)](https://mitpress.mit.edu/9780262046305/) — the dynamic-programming chapter.

### F4.12 &middot; Lab: build a branded CHAMP store

- [Steindorfer & Vinju, CHAMP (OOPSLA 2015)](https://michael.steindorfer.name/publications/oopsla15.pdf) — the structure the lab builds.
- [Elixir — GenServer](https://hexdocs.pm/elixir/GenServer.html) — the store behind the lab.
- [Snowflake ID — Wikipedia](https://en.wikipedia.org/wiki/Snowflake_ID) — the branded keys inserted.

## F5 &middot; Pragmatic Programming

Engineering practice. Tooling docs, the OTP guides, and the “let it crash” primary sources.

### F5.01 &middot; Foundations

- [Elixir — Introduction to Mix (guide)](https://hexdocs.pm/elixir/introduction-to-mix.html) — applications, deps, tasks.
- [Elixir — Mix](https://hexdocs.pm/mix/Mix.html) — the build tool reference.

### F5.02 &middot; Modeling the Portal domain

- [Elixir — ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) — the test framework.
- [Elixir — ExUnit.DocTest](https://hexdocs.pm/ex_unit/ExUnit.DocTest.html) — tests from documentation examples.

### F5.03 &middot; Tracer bullets: a walking skeleton

- [Elixir — Writing documentation](https://hexdocs.pm/elixir/writing-documentation.html) — @doc and @moduledoc.
- [Elixir — Typespecs](https://hexdocs.pm/elixir/typespecs.html) — @spec and types.
- [Dialyxir](https://hexdocs.pm/dialyxir/readme.html) — Dialyzer for Elixir.

### F5.04 &middot; Design by contract

- [Armstrong thesis — “let it crash” and supervision](https://erlang.org/download/armstrong_thesis_2003.pdf) — the philosophy, from the source.
- [Elixir — Mix & OTP: Supervision trees and applications](https://hexdocs.pm/elixir/supervisor-and-application.html) — rescue versus restart.
- [Fred Hébert, *Stuff Goes Bad: Erlang in Anger* (free)](https://www.erlang-in-anger.com/) — failure in production systems.

### F5.05 &middot; Commands, queries & events

- [Elixir — Task](https://hexdocs.pm/elixir/Task.html) — async/await concurrency.
- [GenStage](https://hexdocs.pm/gen_stage/GenStage.html) — demand-driven back-pressure.
- [Flow](https://hexdocs.pm/flow/Flow.html) — parallel data pipelines.

### F5.06 &middot; Telemetry, logging & observability

- [:telemetry](https://hexdocs.pm/telemetry/readme.html) — the metrics and events library.
- [Telemetry.Metrics](https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html) — defining metrics.
- [Phoenix LiveDashboard](https://hexdocs.pm/phoenix_live_dashboard/) — live observability.

### F5.07 &middot; Dependencies, releases & deployment

- [Elixir — Mix & OTP: Configuration and releases](https://hexdocs.pm/elixir/releases.html) — runtime config and releases.
- [Elixir — mix release](https://hexdocs.pm/mix/Mix.Tasks.Release.html) — building a release.

### F5.08 &middot; Performance & profiling

- [Erlang — Efficiency Guide](https://www.erlang.org/doc/system/efficiency_guide.html) — the scheduler and hot paths.
- [Benchee](https://hexdocs.pm/benchee/readme.html) — benchmarking in Elixir.

### F5.09 &middot; Let it crash — a supervision tree that heals

- [Elixir — Supervisor](https://hexdocs.pm/elixir/Supervisor.html) — supervision strategies.
- [Elixir — DynamicSupervisor](https://hexdocs.pm/elixir/DynamicSupervisor.html) — supervising at runtime.
- [Armstrong thesis](https://erlang.org/download/armstrong_thesis_2003.pdf) — why a tree heals.

## F6 &middot; Phoenix Framework

The Phoenix stack. The Phoenix, LiveView, Ecto, and Plug documentation.

### F6.01 &middot; Architecture & the request lifecycle

- [Phoenix — Overview](https://hexdocs.pm/phoenix/overview.html) — the framework at a glance.
- [Phoenix — Request life-cycle](https://hexdocs.pm/phoenix/request_lifecycle.html) — endpoint to view.

### F6.02 &middot; Routing, controllers & plugs

- [Phoenix — Routing](https://hexdocs.pm/phoenix/routing.html) — verbs, paths, and scopes.
- [Phoenix — Controllers](https://hexdocs.pm/phoenix/controllers.html) — actions and rendering.
- [Plug](https://hexdocs.pm/plug/readme.html) — the composable middleware spec.

### F6.03 &middot; Ecto: schemas, changesets & queries

- [Ecto](https://hexdocs.pm/ecto/Ecto.html) — schemas, changesets, queries.
- [Phoenix — Ecto (guide)](https://hexdocs.pm/phoenix/ecto.html) — Ecto inside Phoenix.
- *Programming Ecto* — see the books appendix.

### F6.04 &middot; Contexts & domain design

- [Phoenix — Contexts](https://hexdocs.pm/phoenix/contexts.html) — domain boundaries that scale.

### F6.05 &middot; Templates, components & HEEx

- [Phoenix — Phoenix.Component (HEEx & function components)](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) — components and the ~H sigil.
- [Phoenix LiveView — Welcome](https://hexdocs.pm/phoenix_live_view/welcome.html) — assigns and server-rendered markup.

### F6.06 &middot; Phoenix LiveView fundamentals

- [Phoenix LiveView — Welcome](https://hexdocs.pm/phoenix_live_view/welcome.html) — the LiveView programming model.
- [Phoenix.LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) — the module reference.
- *Programming Phoenix LiveView* — see the books appendix.

### F6.07 &middot; PubSub, channels & real-time

- [Phoenix — Channels](https://hexdocs.pm/phoenix/channels.html) — real-time over WebSockets.
- [Phoenix.PubSub](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html) — distributed publish/subscribe.

### F6.08 &middot; Auth, deployment & going live

- [Phoenix — mix phx.gen.auth](https://hexdocs.pm/phoenix/mix_phx_gen_auth.html) — generated authentication.
- [Phoenix — Deploying with releases](https://hexdocs.pm/phoenix/releases.html) — release-based deployment.
- [Phoenix — Deployment](https://hexdocs.pm/phoenix/deployment.html) — going to production.

### F6.09 &middot; The live dashboard

- [Phoenix LiveDashboard](https://hexdocs.pm/phoenix_live_dashboard/) — real-time monitoring UI.
- [Phoenix.LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) — live state over a socket.

## Further reading — books

Full bibliographic entries for the books cited by short name above.

- [Dave Thomas, *Programming Elixir ≥ 1.6*](https://pragprog.com/titles/elixir16/) — Pragmatic Bookshelf, 2018.
- [Saša Jurić, *Elixir in Action* (3rd ed.)](https://www.manning.com/books/elixir-in-action-third-edition) — Manning, 2024.
- [Joe Armstrong, *Programming Erlang* (2nd ed.)](https://pragprog.com/titles/jaerlang2/) — Pragmatic Bookshelf, 2013.
- [James Edward Gray II & Bruce Tate, *Designing Elixir Systems with OTP*](https://pragprog.com/titles/jgotp/) — Pragmatic Bookshelf, 2019.
- [Svilen Gospodinov, *Concurrent Data Processing in Elixir*](https://pragprog.com/titles/sgdpelixir/) — Pragmatic Bookshelf, 2021.
- [Bruce A. Tate & Sophie DeBenedetto, *Programming Phoenix LiveView*](https://pragprog.com/titles/liveview/) — Pragmatic Bookshelf, 2024.
- [Darin Wilson & Eric Meadows-Jönsson, *Programming Ecto*](https://pragprog.com/titles/wmecto/) — Pragmatic Bookshelf, 2019.
- [Chris McCord, *Metaprogramming Elixir*](https://pragprog.com/titles/cmelixir/) — Pragmatic Bookshelf, 2015.
- [Abelson, Sussman & Sussman, *Structure and Interpretation of Computer Programs* (2nd ed.)](https://mitpress.mit.edu/sicp/) — MIT Press, 1996 — free online.
- [Chris Okasaki, *Purely Functional Data Structures*](https://www.cambridge.org/9780521663502) — Cambridge University Press, 1998 (1996 thesis free online).
- [Cormen, Leiserson, Rivest & Stein, *Introduction to Algorithms* (4th ed.)](https://mitpress.mit.edu/9780262046305/) — MIT Press, 2022.
- [Fred Hébert, *Learn You Some Erlang for Great Good!*](https://learnyousomeerlang.com/) — No Starch Press, 2013 — free online.

---

*Keyed to the course manifest; module ids and titles are generated, reference lists are curated. When new modules are built, add their id to the reference map and regenerate.*
