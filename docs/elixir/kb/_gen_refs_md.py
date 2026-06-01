#!/usr/bin/env python3
"""Generate elixir-references.md: a curated, per-module bibliography keyed to the manifest."""
import os
import build_page as bp

# Each entry: (title, url_or_None, note). Lists are paste-ready for a page "References" block.
REFS = {
 # ---------- F0 · History ----------
 "F0.1": [
   ("The Lambda Calculus (Stanford Encyclopedia of Philosophy)", "https://plato.stanford.edu/entries/lambda-calculus/", "the formal core every functional language descends from."),
   ("John McCarthy, \u201cHistory of Lisp\u201d", "https://www-formal.stanford.edu/jmc/history/lisp/lisp.html", "the origins of Lisp, by its creator."),
   ("Hudak, Hughes, Peyton Jones & Wadler, \u201cA History of Haskell: Being Lazy with Class\u201d (2007)", "https://www.microsoft.com/en-us/research/publication/a-history-of-haskell-being-lazy-with-class/", "the ML/Haskell lineage and the immutable turn."),
   ("Abelson & Sussman, *Structure and Interpretation of Computer Programs*", "https://mitpress.mit.edu/sicp/", "the canonical functional-programming text."),
 ],
 "F0.2": [
   ("Joe Armstrong, \u201cMaking reliable distributed systems in the presence of software errors\u201d (PhD thesis, 2003)", "https://erlang.org/download/armstrong_thesis_2003.pdf", "the design rationale for Erlang and OTP."),
   ("Armstrong, \u201cA History of Erlang\u201d (HOPL III, 2007)", "https://dl.acm.org/doi/10.1145/1238844.1238850", "telecom roots through to open source."),
   ("Erlang/OTP documentation", "https://www.erlang.org/doc", "the BEAM, the runtime, and OTP."),
   ("Fred H\u00e9bert, *Learn You Some Erlang for Great Good!*", "https://learnyousomeerlang.com/", "free, accessible tour of the runtime."),
 ],
 # ---------- F1 · Algebra ----------
 "F1.01": [
   ("Function (mathematics) \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Function_(mathematics)", "domain, range, and single-valued mappings."),
   ("SICP \u00a71.1, \u201cThe Elements of Programming\u201d", "https://mitpress.mit.edu/sicp/", "procedures as first-class objects."),
   ("Elixir \u2014 Anonymous functions", "https://hexdocs.pm/elixir/anonymous-functions.html", "first-class functions in Elixir."),
 ],
 "F1.02": [
   ("SICP \u00a71.1.5, \u201cThe Substitution Model for Procedure Application\u201d", "https://mitpress.mit.edu/sicp/", "evaluation as substitution."),
   ("Referential transparency \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Referential_transparency", "equals for equals; the meaning of purity."),
 ],
 "F1.03": [
   ("Function composition \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Function_composition", "f after g, and associativity."),
   ("Elixir \u2014 Kernel.|>/2 (the pipe operator)", "https://hexdocs.pm/elixir/Kernel.html#%7C%3E/2", "composition written left to right."),
 ],
 "F1.04": [
   ("Immutable object \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Immutable_object", "names bound to fixed values."),
   ("Elixir \u2014 Pattern matching", "https://hexdocs.pm/elixir/pattern-matching.html", "binding, and why = is a match."),
 ],
 "F1.05": [
   ("Map (higher-order function) \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Map_(higher-order_function)", "applying a function across a collection."),
   ("Elixir \u2014 Enum", "https://hexdocs.pm/elixir/Enum.html", "Enum.map and friends over enumerables."),
   ("Elixir \u2014 Keywords and maps", "https://hexdocs.pm/elixir/keywords-and-maps.html", "the collection types in practice."),
 ],
 "F1.06": [
   ("Mathematical induction \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Mathematical_induction", "base case, step, and the proof."),
   ("SICP \u00a71.2, \u201cProcedures and the Processes They Generate\u201d", "https://mitpress.mit.edu/sicp/", "recursive and iterative processes."),
   ("Elixir \u2014 Recursion", "https://hexdocs.pm/elixir/recursion.html", "loops as recursion in Elixir."),
 ],
 "F1.07": [
   ("SICP \u00a71.3, \u201cFormulating Abstractions with Higher-Order Procedures\u201d", "https://mitpress.mit.edu/sicp/", "operators over functions."),
   ("Fold (higher-order function) \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Fold_(higher-order_function)", "\u03a3 and \u03a0 as folds."),
   ("Elixir \u2014 Enum.reduce/3", "https://hexdocs.pm/elixir/Enum.html#reduce/3", "the general higher-order operator."),
 ],
 "F1.08": [
   ("Pattern matching \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Pattern_matching", "solving by structure."),
   ("Elixir \u2014 Pattern matching", "https://hexdocs.pm/elixir/pattern-matching.html", "the match operator and clauses."),
 ],
 "F1.09": [
   ("Function composition \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Function_composition", "f\u2218g seen as curves."),
   ("Elixir \u2014 Introduction", "https://hexdocs.pm/elixir/introduction.html", "the basics the lab applies."),
 ],
 # ---------- F2 · Functional Programming ----------
 "F2.01": [
   ("Pure function \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Pure_function", "determinism and no side effects."),
   ("Side effect (computer science) \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Side_effect_(computer_science)", "what purity isolates."),
   ("*Elixir in Action* \u2014 functional abstractions", None, "see the books appendix."),
 ],
 "F2.02": [
   ("Persistent data structure \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Persistent_data_structure", "structural sharing under immutability."),
   ("Bagwell, \u201cIdeal Hash Trees\u201d (2001)", "https://lampwww.epfl.ch/papers/idealhashtrees.pdf", "the sharing that makes copying cheap."),
   ("*Purely Functional Data Structures* \u2014 Okasaki", None, "see the books appendix."),
 ],
 "F2.03": [
   ("Higher-order function \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Higher-order_function", "functions as arguments and results."),
   ("Elixir \u2014 Enum", "https://hexdocs.pm/elixir/Enum.html", "higher-order functions over collections."),
   ("Elixir \u2014 Anonymous functions", "https://hexdocs.pm/elixir/anonymous-functions.html", "fn, &, and the capture operator."),
 ],
 "F2.04": [
   ("Elixir \u2014 Recursion", "https://hexdocs.pm/elixir/recursion.html", "accumulators and recursive shape."),
   ("Tail call \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Tail_call", "constant-stack recursion."),
   ("*Programming Elixir* \u2014 recursion chapter", None, "see the books appendix."),
 ],
 "F2.05": [
   ("Elixir \u2014 Enum", "https://hexdocs.pm/elixir/Enum.html", "map, filter, reduce, and beyond."),
   ("Fold (higher-order function) \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Fold_(higher-order_function)", "reduce as the universal fold."),
   ("Graham Hutton, \u201cA tutorial on the universality and expressiveness of fold\u201d (1999)", "https://people.cs.nott.ac.uk/pszgmh/fold.pdf", "why everything is a fold."),
 ],
 "F2.06": [
   ("Closure (computer programming) \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Closure_(computer_programming)", "capturing the environment."),
   ("Elixir \u2014 Function (the capture operator)", "https://hexdocs.pm/elixir/Function.html", "& capture and function references."),
   ("Partial application \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Partial_application", "fixing arguments to specialise."),
 ],
 "F2.07": [
   ("Algebraic data type \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Algebraic_data_type", "sums and products."),
   ("Tagged union \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Tagged_union", "tagged tuples as sum types."),
   ("Elixir \u2014 Structs", "https://hexdocs.pm/elixir/structs.html", "product types in Elixir."),
 ],
 "F2.08": [
   ("Function composition \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Function_composition", "composing functions."),
   ("Elixir \u2014 Kernel.|>/2 (the pipe operator)", "https://hexdocs.pm/elixir/Kernel.html#%7C%3E/2", "the pipe and its first-argument rule."),
   ("Elixir \u2014 Stream", "https://hexdocs.pm/elixir/Stream.html", "lazy pipelines over data."),
 ],
 "F2.09": [
   ("Elixir \u2014 Enum", "https://hexdocs.pm/elixir/Enum.html", "the stages a pipeline is built from."),
   ("Elixir \u2014 Stream", "https://hexdocs.pm/elixir/Stream.html", "lazy, composable pipelines."),
   ("Elixir \u2014 Enumerables and streams (guide)", "https://hexdocs.pm/elixir/enumerable-and-streams.html", "eager versus lazy traversal."),
 ],
 # ---------- F3 · The Elixir Language ----------
 "F3.01": [
   ("Elixir \u2014 Basic types", "https://hexdocs.pm/elixir/basic-types.html", "the values you build with."),
   ("Elixir \u2014 IEx", "https://hexdocs.pm/iex/IEx.html", "the interactive shell."),
 ],
 "F3.02": [
   ("Elixir \u2014 Pattern matching", "https://hexdocs.pm/elixir/pattern-matching.html", "= as the match operator."),
   ("Elixir \u2014 case, cond, and if", "https://hexdocs.pm/elixir/case-cond-and-if.html", "matching in control flow."),
 ],
 "F3.03": [
   ("Elixir \u2014 Modules and functions", "https://hexdocs.pm/elixir/modules-and-functions.html", "defining and grouping functions."),
   ("Elixir \u2014 Kernel", "https://hexdocs.pm/elixir/Kernel.html", "def, defp, and the pipe."),
 ],
 "F3.04": [
   ("Elixir \u2014 Enumerables and streams (guide)", "https://hexdocs.pm/elixir/enumerable-and-streams.html", "eager versus lazy."),
   ("Elixir \u2014 Stream", "https://hexdocs.pm/elixir/Stream.html", "lazy enumerables."),
   ("Elixir \u2014 Enumerable protocol", "https://hexdocs.pm/elixir/Enumerable.html", "what makes a thing enumerable."),
 ],
 "F3.05": [
   ("Elixir \u2014 Keywords and maps", "https://hexdocs.pm/elixir/keywords-and-maps.html", "choosing a data shape."),
   ("Elixir \u2014 Structs", "https://hexdocs.pm/elixir/structs.html", "named, typed maps."),
   ("Elixir \u2014 Map", "https://hexdocs.pm/elixir/Map.html", "the map module."),
 ],
 "F3.06": [
   ("Elixir \u2014 Protocols", "https://hexdocs.pm/elixir/protocols.html", "polymorphism by data type."),
   ("Elixir \u2014 Protocol", "https://hexdocs.pm/elixir/Protocol.html", "defining and consolidating protocols."),
   ("Elixir \u2014 Typespecs and behaviours", "https://hexdocs.pm/elixir/typespecs.html", "contracts via behaviours."),
 ],
 "F3.07": [
   ("Elixir \u2014 Processes", "https://hexdocs.pm/elixir/processes.html", "spawn, send, receive."),
   ("Actor model \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Actor_model", "the concurrency model."),
   ("Armstrong thesis \u2014 concurrency-oriented programming", "https://erlang.org/download/armstrong_thesis_2003.pdf", "isolation and message passing."),
 ],
 "F3.08": [
   ("Elixir \u2014 GenServer", "https://hexdocs.pm/elixir/GenServer.html", "the stateful server behaviour."),
   ("Elixir \u2014 Mix & OTP: GenServer (guide)", "https://hexdocs.pm/elixir/genservers.html", "building one step by step."),
   ("Elixir \u2014 Supervisor", "https://hexdocs.pm/elixir/Supervisor.html", "fault tolerance and restarts."),
 ],
 "F3.09": [
   ("Elixir \u2014 Processes", "https://hexdocs.pm/elixir/processes.html", "the mailbox and message passing."),
   ("Elixir \u2014 Process", "https://hexdocs.pm/elixir/Process.html", "the process API."),
 ],
 # ---------- F4 · Algorithms & Data Structures ----------
 "F4.01": [
   ("Elixir \u2014 List", "https://hexdocs.pm/elixir/List.html", "cons-cell lists."),
   ("Erlang \u2014 Efficiency Guide", "https://www.erlang.org/doc/system/efficiency_guide.html", "complexity on the BEAM."),
   ("Okasaki, *Purely Functional Data Structures* (1996 thesis, free PDF)", "https://www.cs.cmu.edu/~rwh/students/okasaki.pdf", "the foundational text."),
 ],
 "F4.02": [
   ("Tree traversal \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Tree_traversal", "DFS and BFS."),
   ("Okasaki, *Purely Functional Data Structures* (thesis PDF)", "https://www.cs.cmu.edu/~rwh/students/okasaki.pdf", "trees, functionally."),
 ],
 "F4.03": [
   ("Merge sort \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Merge_sort", "a stable functional sort."),
   ("*Introduction to Algorithms* (CLRS)", "https://mitpress.mit.edu/9780262046305/", "sorting and searching, in depth."),
 ],
 "F4.04": [
   ("Hash table \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Hash_table", "hashing and collisions."),
   ("Elixir \u2014 Map / MapSet", "https://hexdocs.pm/elixir/Map.html", "maps and sets in Elixir."),
 ],
 "F4.05": [
   ("Bagwell, \u201cIdeal Hash Trees\u201d (2001)", "https://lampwww.epfl.ch/papers/idealhashtrees.pdf", "the original HAMT paper."),
   ("Hash array mapped trie \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Hash_array_mapped_trie", "the structure in brief."),
 ],
 "F4.06": [
   ("Steindorfer & Vinju, \u201cOptimizing Hash-Array Mapped Tries\u2026\u201d (OOPSLA 2015)", "https://michael.steindorfer.name/publications/oopsla15.pdf", "the CHAMP paper (DOI 10.1145/2814270.2814312)."),
   ("The Morning Paper \u2014 CHAMP summary", "https://blog.acolyer.org/2015/11/27/hamt/", "an accessible walkthrough."),
 ],
 # F4.07-F4.12 re-keyed for the 9->12 restructure (2026-06-01): the old F4.07 Snowflake
 # sources stay on the new F4.07 (Identifiers, Snowflake & branded ids); the CHAMP paper
 # moves to F4.09 (Branded CHAMP maps & GenServer); the old F4.08 DP sources move to F4.11.
 # The four new topics (F4.08 persistence, F4.10 recipes) carry canonical docs to refine at
 # authoring time.
 "F4.07": [
   ("Snowflake ID \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Snowflake_ID", "the 64-bit time-ordered id layout."),
   ("Twitter Snowflake (archived source, 2010)", "https://github.com/twitter-archive/snowflake/tree/snowflake-2010", "the original generator."),
   ("Discord \u2014 Snowflakes (developer reference)", "https://discord.com/developers/docs/reference#snowflakes", "a practical bit-layout spec."),
 ],
 "F4.08": [
   ("SQLite \u2014 Datatypes", "https://www.sqlite.org/datatype3.html", "storing branded ids as TEXT keys."),
   ("PostgreSQL \u2014 Data Types", "https://www.postgresql.org/docs/current/datatype.html", "a branded id as a primary key."),
   ("Ecto \u2014 Ecto.Schema", "https://hexdocs.pm/ecto/Ecto.Schema.html", "custom primary-key types in Elixir persistence."),
 ],
 "F4.09": [
   ("Steindorfer & Vinju, CHAMP (OOPSLA 2015)", "https://michael.steindorfer.name/publications/oopsla15.pdf", "the trie keyed by branded ids."),
   ("Elixir \u2014 GenServer", "https://hexdocs.pm/elixir/GenServer.html", "the server holding the partitioned map."),
   ("Snowflake ID \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Snowflake_ID", "the branded-key namespace scheme."),
 ],
 "F4.10": [
   ("Elixir \u2014 Enum", "https://hexdocs.pm/elixir/Enum.html", "idiomatic collection recipes."),
   ("Elixir \u2014 Stream", "https://hexdocs.pm/elixir/Stream.html", "lazy pipelines over large data."),
 ],
 "F4.11": [
   ("Dynamic programming \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Dynamic_programming", "memoisation and overlapping subproblems."),
   ("*Introduction to Algorithms* (CLRS)", "https://mitpress.mit.edu/9780262046305/", "the dynamic-programming chapter."),
 ],
 "F4.12": [
   ("Steindorfer & Vinju, CHAMP (OOPSLA 2015)", "https://michael.steindorfer.name/publications/oopsla15.pdf", "the structure the lab builds."),
   ("Elixir \u2014 GenServer", "https://hexdocs.pm/elixir/GenServer.html", "the store behind the lab."),
   ("Snowflake ID \u2014 Wikipedia", "https://en.wikipedia.org/wiki/Snowflake_ID", "the branded keys inserted."),
 ],
 # ---------- F5 · Pragmatic Programming ----------
 "F5.01": [
   ("Elixir \u2014 Introduction to Mix (guide)", "https://hexdocs.pm/elixir/introduction-to-mix.html", "applications, deps, tasks."),
   ("Elixir \u2014 Mix", "https://hexdocs.pm/mix/Mix.html", "the build tool reference."),
 ],
 "F5.02": [
   ("Phoenix \u2014 Contexts", "https://hexdocs.pm/phoenix/contexts.html", "bounded contexts as the public API."),
   ("Eric Evans \u2014 Domain-Driven Design", "https://www.domainlanguage.com/ddd/", "the source of bounded contexts and the ubiquitous language."),
   ("Elixir \u2014 Structs", "https://hexdocs.pm/elixir/structs.html", "typed records for the domain entities."),
 ],
 "F5.03": [
   ("Hunt and Thomas \u2014 The Pragmatic Programmer", "https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/", "tracer bullets: build end-to-end before exhaustive."),
   ("Elixir \u2014 Introduction to Mix", "https://hexdocs.pm/elixir/introduction-to-mix.html", "scaffold the thin, running skeleton app."),
 ],
 "F5.04": [
   ("Bertrand Meyer \u2014 Applying Design by Contract", "https://se.inf.ethz.ch/~meyer/publications/computer/contract.pdf", "preconditions, postconditions, invariants."),
   ("Eiffel \u2014 Design by Contract and assertions", "https://www.eiffel.org/doc/solutions/Design_by_Contract_and_Assertions", "the contract metaphor, in depth."),
   ("Elixir \u2014 Patterns and guards", "https://hexdocs.pm/elixir/patterns-and-guards.html", "guards as executable preconditions."),
 ],
 "F5.05": [
   ("Martin Fowler \u2014 CQRS", "https://martinfowler.com/bliki/CQRS.html", "separate the write model from the read model."),
   ("Martin Fowler \u2014 Event Sourcing", "https://martinfowler.com/eaaDev/EventSourcing.html", "state as a log of events to fold over."),
   ("Martin Fowler \u2014 CommandQuerySeparation", "https://martinfowler.com/bliki/CommandQuerySeparation.html", "Meyer's rule: a method asks or acts, not both."),
 ],
 "F5.06": [
   ("Elixir \u2014 GenServer", "https://hexdocs.pm/elixir/GenServer.html", "a process that holds state behind a contract."),
   ("Elixir \u2014 Agent", "https://hexdocs.pm/elixir/Agent.html", "the minimal state-holding process."),
   ("Erlang \u2014 ets", "https://www.erlang.org/doc/man/ets.html", "in-memory tables for shared, fast reads."),
 ],
 "F5.07": [
   ("Elixir \u2014 ExUnit", "https://hexdocs.pm/ex_unit/ExUnit.html", "the test framework."),
   ("StreamData", "https://hexdocs.pm/stream_data/StreamData.html", "property-based testing of the pure core."),
   ("Elixir \u2014 ExUnit.DocTest", "https://hexdocs.pm/ex_unit/ExUnit.DocTest.html", "examples in @doc become tests."),
 ],
 "F5.08": [
   ("Alistair Cockburn \u2014 Hexagonal architecture", "https://alistair.cockburn.us/hexagonal-architecture/", "ports and adapters around a core."),
   ("Elixir \u2014 Typespecs and behaviours", "https://hexdocs.pm/elixir/typespecs.html", "@callback defines the port contract."),
   ("Jos\u00e9 Valim \u2014 Mocks and explicit contracts", "https://dashbit.co/blog/mocks-and-explicit-contracts", "test seams without mutating globals."),
 ],
 "F5.09": [
   ("Phoenix \u2014 Phoenix.LiveView", "https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html", "server-rendered, stateful UI over the engine."),
   ("Phoenix \u2014 Phoenix.Component (HEEx)", "https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html", "function components and the HEEx template."),
   ("Elixir \u2014 Supervisor", "https://hexdocs.pm/elixir/Supervisor.html", "the engine runs under a supervision tree."),
 ],
 # ---------- F6 · Phoenix Framework ----------
 "F6.01": [
   ("Phoenix \u2014 Overview", "https://hexdocs.pm/phoenix/overview.html", "the framework at a glance."),
   ("Phoenix \u2014 Request life-cycle", "https://hexdocs.pm/phoenix/request_lifecycle.html", "endpoint to view."),
 ],
 "F6.02": [
   ("Phoenix \u2014 Routing", "https://hexdocs.pm/phoenix/routing.html", "verbs, paths, and scopes."),
   ("Phoenix \u2014 Controllers", "https://hexdocs.pm/phoenix/controllers.html", "actions and rendering."),
   ("Plug", "https://hexdocs.pm/plug/readme.html", "the composable middleware spec."),
 ],
 "F6.03": [
   ("Ecto", "https://hexdocs.pm/ecto/Ecto.html", "schemas, changesets, queries."),
   ("Phoenix \u2014 Ecto (guide)", "https://hexdocs.pm/phoenix/ecto.html", "Ecto inside Phoenix."),
   ("*Programming Ecto*", None, "see the books appendix."),
 ],
 "F6.04": [
   ("Phoenix \u2014 Contexts", "https://hexdocs.pm/phoenix/contexts.html", "domain boundaries that scale."),
 ],
 "F6.05": [
   ("Phoenix \u2014 Phoenix.Component (HEEx & function components)", "https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html", "components and the ~H sigil."),
   ("Phoenix LiveView \u2014 Welcome", "https://hexdocs.pm/phoenix_live_view/welcome.html", "assigns and server-rendered markup."),
 ],
 "F6.06": [
   ("Phoenix LiveView \u2014 Welcome", "https://hexdocs.pm/phoenix_live_view/welcome.html", "the LiveView programming model."),
   ("Phoenix.LiveView", "https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html", "the module reference."),
   ("*Programming Phoenix LiveView*", None, "see the books appendix."),
 ],
 "F6.07": [
   ("Phoenix \u2014 Channels", "https://hexdocs.pm/phoenix/channels.html", "real-time over WebSockets."),
   ("Phoenix.PubSub", "https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html", "distributed publish/subscribe."),
 ],
 "F6.08": [
   ("Phoenix \u2014 mix phx.gen.auth", "https://hexdocs.pm/phoenix/mix_phx_gen_auth.html", "generated authentication."),
   ("Phoenix \u2014 Deploying with releases", "https://hexdocs.pm/phoenix/releases.html", "release-based deployment."),
   ("Phoenix \u2014 Deployment", "https://hexdocs.pm/phoenix/deployment.html", "going to production."),
 ],
 "F6.09": [
   ("Phoenix LiveDashboard", "https://hexdocs.pm/phoenix_live_dashboard/", "real-time monitoring UI."),
   ("Phoenix.LiveView", "https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html", "live state over a socket."),
 ],
}

CORE = [
 ("Elixir documentation (guides + module reference)", "https://hexdocs.pm/elixir/", "the primary source for the language and standard library."),
 ("Elixir \u2014 Introduction (Getting Started)", "https://hexdocs.pm/elixir/introduction.html", "the introductory walkthrough; chapters are linked per module above."),
 ("The Elixir website \u2014 install & learning hub", "https://elixir-lang.org/learning.html", "curated books, courses, and videos."),
 ("Erlang/OTP documentation", "https://www.erlang.org/doc", "the runtime Elixir compiles to."),
 ("HexDocs", "https://hexdocs.pm/", "documentation for every published package."),
]

BOOKS = [
 ("Dave Thomas, *Programming Elixir \u2265 1.6*", "https://pragprog.com/titles/elixir16/", "Pragmatic Bookshelf, 2018."),
 ("Sa\u0161a Juri\u0107, *Elixir in Action* (3rd ed.)", "https://www.manning.com/books/elixir-in-action-third-edition", "Manning, 2024."),
 ("Joe Armstrong, *Programming Erlang* (2nd ed.)", "https://pragprog.com/titles/jaerlang2/", "Pragmatic Bookshelf, 2013."),
 ("James Edward Gray II & Bruce Tate, *Designing Elixir Systems with OTP*", "https://pragprog.com/titles/jgotp/", "Pragmatic Bookshelf, 2019."),
 ("Svilen Gospodinov, *Concurrent Data Processing in Elixir*", "https://pragprog.com/titles/sgdpelixir/", "Pragmatic Bookshelf, 2021."),
 ("Bruce A. Tate & Sophie DeBenedetto, *Programming Phoenix LiveView*", "https://pragprog.com/titles/liveview/", "Pragmatic Bookshelf, 2024."),
 ("Darin Wilson & Eric Meadows-J\u00f6nsson, *Programming Ecto*", "https://pragprog.com/titles/wmecto/", "Pragmatic Bookshelf, 2019."),
 ("Chris McCord, *Metaprogramming Elixir*", "https://pragprog.com/titles/cmelixir/", "Pragmatic Bookshelf, 2015."),
 ("Abelson, Sussman & Sussman, *Structure and Interpretation of Computer Programs* (2nd ed.)", "https://mitpress.mit.edu/sicp/", "MIT Press, 1996 \u2014 free online."),
 ("Chris Okasaki, *Purely Functional Data Structures*", "https://www.cambridge.org/9780521663502", "Cambridge University Press, 1998 (1996 thesis free online)."),
 ("Cormen, Leiserson, Rivest & Stein, *Introduction to Algorithms* (4th ed.)", "https://mitpress.mit.edu/9780262046305/", "MIT Press, 2022."),
 ("Fred H\u00e9bert, *Learn You Some Erlang for Great Good!*", "https://learnyousomeerlang.com/", "No Starch Press, 2013 \u2014 free online."),
]

def ref_line(t, u, note):
    head = f"[{t}]({u})" if u else t
    return f"- {head} \u2014 {note}"

p = []
W = p.append
W("# Elixir Course \u2014 References")
W("")
W("A curated bibliography keyed to every module of the *Functional Programming in Elixir* course. Each "
  "module below carries a short, paste-ready list of authoritative sources \u2014 official documentation, primary "
  "papers, and canonical books \u2014 ready to drop into a **References** block on the corresponding page.")
W("")
W("> The lists favour primary sources: the Elixir and Erlang/OTP documentation, the papers a topic rests on, "
  "and a small set of standard books (collected in the appendix). They are deliberately short \u2014 two to four "
  "entries \u2014 so a page's References block stays focused.")
W("")
W("## How to use this file")
W("")
W("- Each `###` heading matches a module id and title from the course manifest, so a page can pull its block "
  "by id.")
W("- A module's list is self-contained and ready to paste; the **Core references** below are assumed throughout "
  "and need not be repeated on every page.")
W("- Subpages (the deep dives under an F2 hub) inherit their parent module's references; add a subpage-specific "
  "entry only where the dive introduces a source of its own.")
W("- Books are cited by short name inline and listed in full under **Further reading \u2014 books**.")
W("")
W("## Core references")
W("")
W("Cited implicitly by most pages; link these once in a shared footer or the course landing rather than on "
  "every page.")
W("")
for t, u, note in CORE:
    W(ref_line(t, u, note))
W("")

CHNOTE = {
 "F0": "History and context. Primary accounts of where functional languages and the BEAM came from.",
 "F1": "The mathematical foundation. References pair each idea with its treatment in SICP and the matching Elixir guide.",
 "F2": "Functional programming as Elixir. The standard-library docs plus the papers and concepts behind each idea.",
 "F3": "The language proper. Almost entirely the official guides and module references.",
 "F4": "Algorithms and data structures. The persistent-map family rests on primary papers; the branded key ties to Snowflake.",
 "F5": "Engineering practice. Tooling docs, the OTP guides, and the \u201clet it crash\u201d primary sources.",
 "F6": "The Phoenix stack. The Phoenix, LiveView, Ecto, and Plug documentation.",
}

for ch in bp.CHAPTERS:
    cid = ch["id"]
    W(f"## {cid} &middot; {ch['title']}")
    W("")
    W(CHNOTE.get(cid, ""))
    W("")
    for m in bp.MODULES[cid]:
        mid = m["n"]
        W(f"### {mid} &middot; {m['title']}")
        W("")
        for (t, u, note) in REFS.get(mid, []):
            W(ref_line(t, u, note))
        W("")

W("## Further reading \u2014 books")
W("")
W("Full bibliographic entries for the books cited by short name above.")
W("")
for t, u, note in BOOKS:
    W(ref_line(t, u, note))
W("")
W("---")
W("")
W("*Keyed to the course manifest; module ids and titles are generated, reference lists are curated. "
  "When new modules are built, add their id to the reference map and regenerate.*")
W("")

doc = "\n".join(p)
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "elixir-references.md")
open(out, "w").write(doc)

# counts + voice gate
import re
total = sum(len(v) for v in REFS.values())
mods_with = sum(1 for m in bp.CHAPTERS for x in bp.MODULES[m["id"]] if REFS.get(x["n"]))
mods_all = sum(len(bp.MODULES[c["id"]]) for c in bp.CHAPTERS)
print("wrote", out, "-", len(doc), "chars,", doc.count(chr(10)) + 1, "lines")
print("modules with references:", mods_with, "/", mods_all, "| total module references:", total,
      "| core:", len(CORE), "| books:", len(BOOKS))
FORB = ["revolutionary", "blazing-fast", "blazing fast", "magical", "simply", "obviously", "effortless"]
low = doc.lower()
hits = [w for w in FORB if w in low] + (["just"] if re.search(r"\bjust\b", low) else [])
print("voice gate:", "CLEAN" if not hits else "HITS -> " + ", ".join(hits))
