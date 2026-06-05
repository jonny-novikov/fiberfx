# F0 onramp — Elixir for C# developers (dive / onramp)

- Route (served): `/elixir/course/csharp`
- File: `elixir/course/csharp.html`
- Place in the chapter: front-matter for F0 — an onramp, not a numbered module. It maps the C#/.NET reader's existing knowledge onto the BEAM, sits beside the two history modules in the F0 contents, and hands off to F1 · Algebra (or to F0.2 for the runtime in depth).
- Accent: chapter F0 · History · blue (the CLR card draws in `--blue`; the BEAM card and code accents draw in `--elixir`; the page sits on the shared editorial palette).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F0 · onramp`

H1 (verbatim): `Elixir for C# developers` (`developers` rendered in the `.ex` elixir-bright italic).

Lede (verbatim): "If you write C# — ASP.NET controllers, EF Core queries, `Task` and `async/await` — you already hold most of the ideas Elixir is built from. What is genuinely different is the machine underneath. This page maps the gap: the two runtimes, the functional features C# has steadily borrowed, and a library that makes the translation almost line for line."

Kicker (verbatim): "C# has spent twenty years drifting toward functional programming — generics, closures, LINQ, records, pattern matching. Elixir began there, on a runtime designed for a different goal. Knowing where the two meet, and where they part, is the fastest way in."

## Sections

In order:

1. `#runtimes` — `Two runtimes: the CLR and the BEAM` (teaching; the interactive CLR-vs-BEAM comparator). Running contrast: one CLR process with many threads over shared memory vs many isolated BEAM processes that share nothing.
2. `#adopted` — `What C# already gave you` (teaching). Two static `pre.code` blocks shown side by side: a modern C# `record` + LINQ `.Where(...).Select(...)` + `switch` expression, then the Elixir equivalent — a `defmodule Lesson` with `defstruct [:id, :completed]`, an `Enum.filter/Enum.map` pipeline, and a `case`. Real Elixir tokens: `defmodule`, `defstruct`, `Enum.filter`, `Enum.map`, `case`, `when`, `|>`.
3. `#langext` — `language-ext: the bridge` (advanced; the interactive concept translator pairing C# `language-ext` with Elixir). The running example walks `Option`, `Either`, immutable `Map`, pattern matching, and the actor model.
4. `#map` — `A concept map` (the C#→Elixir phrasebook deflist + a closing bridge). Then the pager.

## The interactives

- `<figure aria-labelledby="rtTitle">` — title `CLR vs BEAM · select a dimension`. Control group `#rtSel` (`role="group"`, `aria-label="Runtime dimension"`) with five buttons:
  - `data-k="conc"` `data-c="elixir"` (default active) — label `concurrency`
  - `data-k="mem"` `data-c="blue"` — label `memory & GC`
  - `data-k="type"` `data-c="sage"` — label `typing`
  - `data-k="fail"` `data-c="burg"` — label `failure`
  - `data-k="dep"` `data-c="gold"` — label `deployment`
  - SVG targets `#rtDim` (the dimension header), `#rtClr` (the CLR cell), `#rtBeam` (the BEAM cell); readout `#rtOut`. Pure function `rt(key)` reads `RT[key]` and writes `#rtDim`/`#rtClr`/`#rtBeam`/`#rtOut`; seeded with `rt('conc')`. `RT` table VERBATIM (`dim` / `clr` / `beam` / `out`):
    - `conc`: `CONCURRENCY` · `threads + async/await` · `millions of processes` · "The CLR runs work on OS threads and a thread pool, coordinated with Task and async/await over shared memory. The BEAM runs millions of lightweight processes, each isolated, communicating only by copying messages — the actor model, built in."
    - `mem`: `MEMORY & GC` · `shared heap + gen GC` · `per-process heaps` · "CLR objects share one heap collected by a generational GC, which can pause threads to run. Each BEAM process owns a small heap collected on its own, so collection is incremental and never stops the whole system at once."
    - `type`: `TYPING` · `static, nominal` · `dynamic, strong` · "C# checks types at compile time and leans on a huge typed class library and tooling. Elixir checks at run time and leans on pattern matching — with a set-theoretic type system now arriving as a preview."
    - `fail`: `FAILURE` · `try / catch` · `let it crash` · "C# guards against errors with exceptions and defensive checks. The BEAM lets a failing process crash in isolation while a supervisor restarts it to a known-good state — failures are contained, not prevented everywhere."
    - `dep`: `DEPLOYMENT` · `assemblies, JIT/AOT` · `releases, hot swap` · "C# ships assemblies run by the CLR's JIT, or compiled ahead of time with NativeAOT. The BEAM ships a release that can be upgraded while running, swapping modules without dropping live connections."
- `<figure aria-labelledby="ctTitle">` — title `language-ext ↔ Elixir · select a concept`. Control group `#ctSel` (`role="group"`, `aria-label="Concept"`) with five buttons:
  - `data-k="option"` `data-c="elixir"` (default active) — label `Option`
  - `data-k="either"` `data-c="blue"` — label `Either`
  - `data-k="map"` `data-c="sage"` — label `immutable Map`
  - `data-k="match"` `data-c="gold"` — label `pattern match`
  - `data-k="actor"` `data-c="burg"` — label `the actor model`
  - Code targets `#csCode` (the C# · language-ext block) and `#exCode` (the Elixir block); readout `#ctOut`. Pure function `ct(key)` reads `CT[key]` and writes `#csCode`/`#exCode`/`#ctOut`; seeded with `ct('option')`. The `CT` table holds the paired code samples (`Option<User>.Match` vs `case … %User{} … nil`; `Either<Error, Claims>` vs `{:ok, _}/{:error, _}`; `Map.Add` vs `Map.put`; the `switch` expression vs `case`; echo-process `spawn`/`tell` vs `GenServer.cast` + `handle_cast`). Readout strings VERBATIM:
    - `option`: "`Option<T>` replaces `null` with a type that is `Some` or `None`, forcing the empty case to be handled — the same discipline as matching `%User{}` against `nil`."
    - `either`: "`Either<L, R>` is success-or-failure carrying a reason — structurally the same as Elixir's `{:ok, _} | {:error, _}` tuples, and matched the same way."
    - `map`: "language-ext's `Map` returns a new map from `Add` and leaves the original intact — the structural sharing Elixir's maps give you out of the box."
    - `match`: "Switch expressions, added in C# 8, are pattern matching with guards — clause for clause, an Elixir `case`."
    - `actor`: "Paul Louth, language-ext's author, built echo-process to bring the actor model to C#: an actor is a `State -> Message -> State` function — which is exactly an Elixir process, and the core of a `GenServer`."
- Degrade behaviour: no `.reveal` elements; the `html.js` enhancer is a no-op here. Both interactive figures seed a default state in JS (`rt('conc')`, `ct('option')`); the static `pre.code` comparison blocks in `#adopted` are plain markup and read with JS off. The animated `.arc-flow` (if present) honours `prefers-reduced-motion`.
- Footer build-stamp decoder (`#stamp` / `#stampId`): real id `TSK0NbE6xxOlLU`; markup-decoded timestamp `2026-05-31 14:24:31 UTC`. Same decoder (3-char `TSK` namespace + base62 snowflake, `EPOCH_MS = 1704067200000`, `ts >> 22`, `node = (snow >> 12) & 0x3FF`, `seq = snow & 0xFFF`).

## References (#refs, verbatim)

This page has no `#refs` References section (no intro line, no Sources list, no "Related in this course" block). It carries one inline external Source in the `#langext` prose: `language-ext` → `https://github.com/louthy/language-ext` (Paul Louth's pure functional-programming framework for C#). Inline forward cross-links in the closing note: `/elixir/algebra` (F1 — Algebra), `/elixir/course/beam-evolution` (F0.2 — the BEAM & OTP), and `/elixir/language/match` (F3.02 — pattern matching). The other `https://` links are the Google Fonts preconnect/stylesheet in `<head>`.

## Wiring

- route-tag (verbatim): `/ ` `elixir` ` / ` `course` ` / ` `csharp` — markup `<span class="route-tag"><span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/course">course</a><span class="rsep">/</span><span class="rcur">csharp</span></span>`.
- crumbs (verbatim): `F0 · History` (links `/elixir/course`) `/` `Elixir for C# developers`.
- toc-mini: `Two runtimes` → `#runtimes`; `What C# gave you` → `#adopted`; `language-ext` → `#langext`; `A concept map` → `#map`.
- pager: prev → `/elixir/course` label `History & contents`; next → `/elixir/algebra` label `Start the course · F1`.
- footer: three columns identical to the F0 landing. Brand logo → `/elixir` + the "taught twice" tagline. Column `Chapters`: `F1 · Algebra` → `/elixir/algebra`, `F2 · Functional Programming` → `/elixir/functional`, `F3 · The Elixir Language` → `/elixir/language`, `F4 · Algorithms & Data Structures` → `/elixir/algorithms`, `F5 · Pragmatic Programming` → `/elixir/pragmatic`, `F6 · Phoenix Framework` → `/elixir/phoenix`. Column `The course`: `Course home` → `/elixir`, `Contents & history` → `/elixir/course`, `Start · F1.01` → `/elixir/algebra/functions`. Foot bar: `© jonnify` + build stamp.
- Page meta — `<title>`: `Elixir for C# developers — History · jonnify`. `<meta name="description">`: "A bridge from .NET to the BEAM: how the two runtimes differ, the functional ideas C# has already adopted, and how the language-ext library maps Option, Either, immutability, and the actor model onto Elixir's own."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks (the runtime comparator + concept translator + snowflake decoder, then the `html.js` enhancer) verbatim from a recent built F0 sibling on this chapter; change only `<title>` / `<meta>`, the `route-tag` current segment, the crumbs, and the `<main>` body (the two runtimes comparator, the C#-already-gave-you code pair, the language-ext translator, and the concept-map deflist). No-invent guards: state only the real CLR-vs-BEAM facts and the real Elixir surfaces the C# constructs map to (`defmodule`, `defstruct`, `Enum`, `case`/`when`, `%{}` maps, `{:ok, _}`/`{:error, _}` tuples, `GenServer.cast`/`handle_cast`); cite the actual `language-ext` project and `echo-process` by Paul Louth, and do not invent library names, APIs, or URLs. Defer the runtime internals to F0.2 and the companion course; cross-link forward (F1 · Algebra, F3.02) rather than re-teaching. Voice rules: no first person, no exclamation marks, no emoji, none of "just" / "simply" / "obviously". Model sibling to copy from: `elixir/course/fp-evolution.html` (the F0 dive — same head, footer, two-figure interactive anatomy, and decoder script).
