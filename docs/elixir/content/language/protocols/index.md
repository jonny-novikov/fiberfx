# F3.06 — Polymorphism: protocols & behaviours (module hub)

- Route (served): `/elixir/language/protocols`
- File: `elixir/language/protocols/index.html`
- Place in the chapter: the sixth module of F3 · The Elixir Language. It follows F3.05 (`structs`) — where a struct's `__struct__` tag was matched by hand — and turns that hand-written dispatch into two language features: protocols (runtime, value-typed) and behaviours (compile-time, module contracts). It frames three deep dives and leads into F3.07 (`processes`).
- Accent: `elixir` (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3 · Data & shape · module 6`

H1: Polymorphism: `protocols` & behaviours

Hero lede (verbatim):

> A struct carries its module in the `__struct__` tag, and F3.05 matched on that tag by hand. Elixir turns the same idea into a language feature two ways. A **protocol** dispatches a function to a different implementation depending on a value's type, at runtime. A **behaviour** is a contract a module promises to fulfil, checked at compile time.

Kicker (verbatim):

> The portal needs both: one `summarize/1` that reads any entity, and a `Notifier` contract that email and SMS modules each satisfy. This module separates the two mechanisms, then takes each apart.

## What the page frames

The hub opens with a "Two kinds of polymorphism" section (an interactive that contrasts protocol vs behaviour), then lists the three dives as cards:

- **F3.06.1 · Defining a protocol** — `defprotocol` declares the contract; a call resolves to an implementation by the value's type, or raises `Protocol.UndefinedError`. Route `/elixir/language/protocols/define`. Built.
- **F3.06.2 · Implementing for a struct** — one `defimpl` per type builds a dispatch table; new types are added without touching the protocol or the other implementations. Route `/elixir/language/protocols/defimpl`. Built.
- **F3.06.3 · Behaviours & callbacks** — `@callback` declares the contract, `@behaviour` and `@impl` fulfil it — the compile-time counterpart that OTP is built on. Route `/elixir/language/protocols/behaviours`. Built.

The running example is a learning Portal: a `Portal.Summary` protocol with `summarize/1`, and a `Portal.Notifier` behaviour. A closing `bridge` connects F3.05 (the `__struct__` tag) to F3 protocol dispatch, and a `note` points forward to F3.07 — Processes & the actor model.

## The interactives

Hero figure — `<figure class="hero-fig">`, caption title "Adding a type: closed for editing" (`id="oxTitle"`). SVG label "DISPATCH ON A VALUE TYPE". Controls: `<button id="oxBtn">▸ add a type</button>` and `<button id="oxReset">reset</button>`. SVG element ids: `oxFrame`, `oxHead`, `oxRows`, `oxFoot`, `oxNote`, caption `oxCap`. A self-contained IIFE cycles a three-state machine (`state = (state + 1) % 3`): state 0 = a `case` with three type clauses; state 1 = the `case` reopened with a fourth (`Cohort`) clause grafted in (frame turns burgundy); state 2 = four separate `defimpl Summary, for: …` blocks while `defprotocol Summary` stays untouched. `TYPES = ['Course', 'Lesson', 'User', 'Cohort']`. Readout strings (verbatim):
  - state 0 caption: `[ Course · Lesson · User ]` / `A new type means reopening this one function.`; button `▸ add a type`; note `one function · every type lives in it`.
  - state 1 caption: `[ Course · Lesson · User · Cohort ]` / `The fourth type forced an edit to existing code.`; button `▸ make it a protocol`; note `one function · reopened to add a clause`.
  - state 2 caption: `[ Course · Lesson · User · Cohort ]` / `Each type is its own defimpl. The protocol module is never reopened.`; button `▸ back to the case`; head `defprotocol Summary do  # untouched`; note `four separate blocks · the protocol stays closed`.

Section figure — `<figure class="fig">` with title "What varies · select one" (`id="poTitle"`). Control group `id="poSel"`, role group, label "What varies", buttons:
  - `data-k="value"`, `data-c="elixir"`, label "by the value type" (default active)
  - `data-k="module"`, `data-c="gold"`, label "by the module"
  SVG ids: `poBox`, `poBoxT`, `poP0`, `poP1`, `poKey`, `poEx`; readout `id="poOut"`. The pure function `pick(k)` reads a `MECH` table and rewrites the mechanism box, the two "WHEN IT RESOLVES" dots, the dispatch key, the built-in examples, and the `poOut` prose. Readout strings (verbatim):
  - `value` → `out`: `A <b style="color:var(--elixir-bright)">protocol</b> chooses an implementation at runtime from the value type. You write one implementation per type with <code class="inl">defimpl</code>; the built-ins <code class="inl">Enumerable</code>, <code class="inl">String.Chars</code>, and <code class="inl">Inspect</code> work this way.` (box `Protocol · dispatch on a value`, key `the value __struct__ tag`, examples `Enumerable, String.Chars, Inspect`)
  - `module` → `out`: `A <b style="color:var(--gold-bright)">behaviour</b> is a compile-time contract: a module declares <code class="inl">@behaviour</code> and must define the listed callbacks. OTP modules like <code class="inl">GenServer</code> and <code class="inl">Supervisor</code> are behaviours you implement.` (box `Behaviour · a module contract`, key `the module name`, examples `GenServer, Supervisor, Application`)

Degrade behaviour: both figures ship a static default in the markup (the hero shows a three-clause `case`; the section shows the `value` mechanism), visible without JS. CSS `@media (prefers-reduced-motion: no-preference)` gates the row-in animation (`.hp-row.hp-new`) and the `.arc-flow` dash animation; `prefers-reduced-motion: reduce` disables both. Reveal-on-scroll is JS-gated and content is visible without JS.

Footer build-stamp: `id="stampId"` carries `TSK0NbPCyE4mpc`; the in-markup decoded `timestamp` is `2026-05-31 16:59:48 UTC`. The decoder splits the first three chars as namespace (`TSK`) and base62-decodes the rest to a Snowflake, then derives `snowflake`/`node`/`seq` and the UTC timestamp against `EPOCH_MS = 1704067200000`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/protocols.html` — Protocols — Elixir documentation — polymorphism by data type.
- `https://hexdocs.pm/elixir/Protocol.html` — `Protocol` — Elixir documentation — defining and consolidating protocols.
- `https://hexdocs.pm/elixir/typespecs.html` — Typespecs and behaviours — Elixir documentation — contracts via behaviours.

Related in this course:
- `/elixir/language/structs` — F3.05 · Structs, maps & keyword lists — the `__struct__` tag dispatch builds on.
- `/elixir/language/enum-streams` — F3.04 · Enumerables & streams — `Enumerable`, the canonical protocol.
- `/elixir/language/otp` — F3.08 · OTP: GenServer & supervisors — behaviours in practice.

## Wiring

- route-tag: `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/language">language</a><span class="rsep">/</span><span class="rcur">protocols</span>`
- crumbs: `F3 · The Elixir Language` (→ `/elixir/language`) `/` `F3.06 · protocols` (here)
- toc-mini: `#two` "Two kinds of polymorphism"; `#dives` "Three deep dives"
- pager: prev → `/elixir/language/structs` "F3.05 · structs"; next → `/elixir/language/protocols/define` "Start · defining a protocol"
- footer: column "Chapters" → `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework); column "The course" → `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01); brand tagline "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta: `<title>Protocols &amp; behaviours — F3.06 · jonnify</title>`; `<meta name="description" content="Two kinds of polymorphism in Elixir: a protocol dispatches a function on a value's type at runtime, a behaviour is a compile-time contract a module fulfils — with the portal's Summary and Notifier as examples.">`

## Build instruction

To (re)build this page, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on this `elixir` (purple) chapter accent — the model sibling is `elixir/language/structs/index.html` (the adjacent F3.05 module hub), which carries the same hub anatomy (hero with `hero-fig`, a `solid-select` figure, a `.mods`/dive-card list, the `bridge`, References, pager, and the branded stamp). Change only `<title>`/`<meta>`, the `route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the branded store and branded ids (`TSK…`/`SES…`/`LSN…`), the event-sourced engine behind ONE `Portal` facade, and the Phoenix web app; the `Portal.Summary` protocol with `summarize/1` and the `Portal.Notifier` behaviour with `deliver/2` and `valid_target?/1` are the only domain surfaces this module names. Cite the companion `/elixir/phoenix` chapter and `/elixir/language/otp` for OTP internals (`GenServer`, `Supervisor`); do not re-teach them here. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
