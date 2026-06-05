# F0 — Where this came from (chapter landing / course contents)

- Route (served): `/elixir/course`
- File: `elixir/course/index.html`
- Place in the chapter: the contents-and-history landing for chapter F0. It frames the whole course map (the six chapters and 54 modules), the optional history chapter F0, and the C# onramp, and routes a reader to the right starting point.
- Accent: chapter F0 · History · blue (the lineage rail draws the `--blue` `λ-calculus → Erlang / BEAM` nodes; the page itself sits on the shared gold/elixir editorial palette).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `Chapter F0 · context, not a prerequisite`

H1 (verbatim): `Where this came from` (`came from` rendered in the `.ex` elixir-bright italic).

Lede (verbatim): "This is the map of the course and the story behind it. Elixir did not appear from nowhere: it sits at the end of a long line of ideas about functions and a thirty-year line of work on a fault-tolerant runtime. F0 sketches both, and you can skip it — F1 stands on its own."

Kicker (verbatim): "The course proper is six chapters and 54 modules, plus this optional history. If you are arriving from another platform, the onramp below maps what you already know onto the BEAM."

## What the page frames

This is the contents directory for the entire course. The F0 chapter section lists two history modules plus the onramp:

- F0.1 · `The evolution of functional languages & runtimes` — `λ-calculus → LISP → ML/Haskell → the immutable turn.` — route `/elixir/course/fp-evolution` — pill `built`. Dives listed: `F0.1.1 From λ-calculus to LISP`, `F0.1.2 Types & laziness — the ML and Haskell branch`, `F0.1.3 The immutable turn — persistent data on the JVM & CLR`.
- F0.2 · `The evolution of Erlang, the BEAM & OTP` — `Telecom roots, soft-real-time scheduling, and supervision.` — route `/elixir/course/beam-evolution` — pill `built`. Dives listed: `F0.2.1 Telecom roots & "let it crash"`, `F0.2.2 Inside the BEAM — scheduling, heaps & soft-real-time GC`, `F0.2.3 OTP & the supervision tree — and the polyglot BEAM`.
- Onramp · `Elixir for C# developers` — route `/elixir/course/csharp` — labelled `onramp` (a deflist row, not a numbered module): "The bridge from .NET: runtimes compared, and language-ext as the Rosetta stone."

The full-map section then lists every chapter card, each linking to its hub: F0 `/elixir/course`, F1 Algebra `/elixir/algebra` (9 modules), F2 Functional Programming `/elixir/functional` (9), F3 The Elixir Language `/elixir/language` (9), F4 Algorithms & Data Structures `/elixir/algorithms` (12), F5 Pragmatic Programming `/elixir/pragmatic` (9), F6 Phoenix Framework `/elixir/phoenix` (9) — every module card carries the `built` pill.

## The interactives

- `<figure aria-labelledby="sTitle">` — title `Your background · select one`. Control group `id="startSel"` (`role="group"`, `aria-label="Your background"`) with four buttons:
  - `data-k="new"` `data-c="sage"` (default active) — label `new to this`
  - `data-k="oop"` `data-c="blue"` — label `from OOP`
  - `data-k="csharp"` `data-c="elixir"` — label `from C# / .NET`
  - `data-k="fp"` `data-c="gold"` — label `already functional`
  - Readout target `id="startOut"` (`aria-live="polite"`). The pure picker `pick(k)` looks up `START[k]` and writes its HTML into `#startOut`; it is seeded with `pick('new')`. Readout strings VERBATIM:
    - `new`: "**Start at F1 · Algebra.** It assumes no prior functional programming and builds every idea — functions, composition, immutability — from the ground up."
    - `oop`: "**Start at F1 · Algebra**, then read F2 · Functional, which reframes the objects-and-methods habit as data-and-functions. The shift is conceptual, and these two chapters make it gently."
    - `csharp`: "**Read the C# onramp first** — it maps the CLR, async, and the BCL you know onto the BEAM — then begin F1 · Algebra. Open the onramp → (links `/elixir/course/csharp`)"
    - `fp`: "**Skim F0, then jump ahead.** If folds and closures are old friends, go straight to F3 · The Elixir Language for the syntax and runtime, dipping back into F2 only where you want the framing."
- Hero motif: a static decorative `svg.hero-motif` lineage rail (`λ-calculus → Erlang / BEAM → Elixir → your app`); not interactive, always rendered.
- Degrade behaviour: the contents cards carry `.reveal`; the trailing script adds `html.js` then reveals on scroll via `IntersectionObserver`. Content is visible without JS, and `prefers-reduced-motion: reduce` shows everything immediately with no transition.
- Footer build-stamp decoder (`#stamp` / `#stampId`): real id `TSK0NbE6xjm16O`; the markup carries the decoded timestamp `2026-05-31 14:24:31 UTC`. The decoder strips the 3-char `TSK` namespace, base62-decodes the rest, and splits the snowflake into `timestamp >> 22`, `node = (snow >> 12) & 0x3FF`, `seq = snow & 0xFFF` against `EPOCH_MS = 1704067200000`.

## References (#refs, verbatim)

This page has no `#refs` References section. The only external `https://` links are the Google Fonts preconnect/stylesheet in `<head>`; there are no Sources or a "Related in this course" refs block to transcribe.

## Wiring

- route-tag (verbatim): `/ ` `elixir` ` / ` `course` — markup `<span class="route-tag"><span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><span class="rcur">course</span></span>`.
- crumbs (verbatim): `Course` (links `/elixir`) `/` `F0 · History & contents`.
- toc-mini: this landing has no `.toc-mini`; its in-page sections are `#start` (Where should you start?), `#onramp` (Coming from C# and .NET?), `#history` (The history chapter), `#map` (The full map).
- pager: prev → `/elixir` label `Home`; next → `/elixir/course/csharp` label `The C# onramp`.
- footer: three columns. Brand: logo → `/elixir` + tagline "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir." Column `Chapters`: `F1 · Algebra` → `/elixir/algebra`, `F2 · Functional Programming` → `/elixir/functional`, `F3 · The Elixir Language` → `/elixir/language`, `F4 · Algorithms & Data Structures` → `/elixir/algorithms`, `F5 · Pragmatic Programming` → `/elixir/pragmatic`, `F6 · Phoenix Framework` → `/elixir/phoenix`. Column `The course`: `Course home` → `/elixir`, `Contents & history` → `/elixir/course`, `Start · F1.01` → `/elixir/algebra/functions`. Foot bar: `© jonnify` + the build stamp.
- Page meta — `<title>`: `Course contents — History · jonnify`. `<meta name="description">`: "The full map of the course — six chapters and an optional history — plus an onramp for engineers arriving from C# and .NET, comparing the CLR and the BEAM and the functional ideas they share."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the start-picker + snowflake decoder, then the reveal-on-scroll enhancer) verbatim from this same chapter-F0 landing or its built sibling `elixir/course/fp-evolution.html`; change only `<title>` / `<meta>`, the `route-tag` current segment, and the `<main>` body (the start picker, the onramp card, the history deflist, and the full-map contents directory). No-invent guards: cite only the real course structure as it stands — the six built chapters and their real hub routes (`/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`), the two real history routes, and the real onramp route; do not invent module counts, dive titles, or routes. For any OTP/runtime claim, defer to F0.2 and the companion course rather than re-teaching it here. Voice rules: no first person, no exclamation marks, no emoji, and none of "just" / "simply" / "obviously". Model sibling to copy from: `elixir/course/fp-evolution.html` (same F0 chapter, same shared head and footer).
