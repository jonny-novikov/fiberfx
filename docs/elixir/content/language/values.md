# F3.01 — Values, types & IEx (dive / leaf lesson)

- **Route (served):** `/elixir/language/values`
- **File:** `elixir/language/values.html`
- **Place in the chapter:** the first module of F3, a single-page leaf lesson in the Foundations movement (`F3.01`). It is the "start here" entry of the nine-module arc, making the abstract values of F1/F2 concrete and introducing the shell as the tool for inspecting them; it leads into `F3.02 · match`.
- **Accent:** elixir (purple); the `<h1>` accent word `IEx` is the `<span class="ex">`.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3 · Foundations · module 1`

`<h1>`: Values, types & `IEx`

Lede (verbatim):

> Every program is built from a small set of values. Before any syntax for combining them, it is worth knowing what they are and how to inspect them — and the fastest way to do that is the shell, where you type a value and Elixir tells you what it is.

Kicker (verbatim):

> F1 and F2 treated values abstractly: a function maps inputs to outputs, immutable data is never edited in place. This module makes those values concrete. Elixir has integers and floats, atoms and booleans, strings, lists, tuples, and maps — and a shell, IEx, for examining each one as you go.

## Sections

In order: `#iex` ("The shell"), `#values` ("The values" — the interactive), `#types` ("The eight you meet first"), then a References section.

- **The shell (`#iex`):** introduces IEx, `h/1` and `i/1`, with a static `pre.code` showing `iex> 40 + 2 → 42`, `iex> "hello" <> " world" → "hello world"`, and the comment `# i/1 describes any value; h/1 prints docs`.
- **The eight you meet first (`#types`):** a `.deflist` of the eight built-in types with example literals (`integer 42`, `float 3.14`, `atom :ok`, `boolean true`, `string (binary) "hi"`, `list [1, 2, 3]`, `tuple {:ok, value}`, `map %{a: 1}`), plus a `.bridge` from "F1 & F2 · abstract values" to "F3 · concrete types".
- **Running example:** none of the Portal domain; the page works directly with primitive Elixir literals shown through IEx.
- **`.take` (verbatim):** "A value's type is never in doubt: ask the shell. `i/1` names it, and an `is_*` predicate confirms it — the habit that makes pattern matching, next, feel natural."
- **`.note` (verbatim):** "Next: **F3.02 — Pattern matching & the match operator**, where `=` turns out to be a match rather than assignment. Return to the chapter overview for the full path."

## The interactives

### Figure — "The built-in values · select one" (`#values`)
- **Markup:** `<figure class="fig" aria-labelledby="vTitle">` titled "The built-in values · select one"; an `<svg viewBox="0 0 720 200">` whose `<g id="tymap">` is populated at runtime with eight `.ty-node` tiles, plus a live `pre.code#vCode` and a `.geo-readout#vOut` (both `aria-live="polite"`).
- **Control:** eight SVG tiles built by `build()`, each a `<g class="ty-node" data-k="<type>" role="button" tabindex="0">` with a `[data-box]` `<rect>` and `[data-lit]` literal `<text>`. The `data-k` keys are `integer`, `float`, `atom`, `boolean`, `string`, `list`, `tuple`, `map`.
- **`TYPES` dataset (the eight, verbatim literals/predicates/data-types):** `integer`/`42`/`is_integer`/`Integer`; `float`/`3.14`/`is_float`/`Float`; `atom`/`:ok`/`is_atom`/`Atom`; `boolean`/`true`/`is_boolean`/`Atom`; `string`/`"hi"`/`is_binary`/`BitString`; `list`/`[1, 2, 3]`/`is_list`/`List`; `tuple`/`{:ok, 1}`/`is_tuple`/`Tuple`; `map`/`%{a: 1}`/`is_map`/`Map`.
- **Pure functions:** `build()` lays the eight tiles in a `COLS=4` grid; `select(key)` highlights the matching tile (stroke `#cdb8f0`, fill `#1a1530`), rewrites `#vCode` to a three-command IEx transcript (the literal, its `is_*(...)` predicate returning `true`, and `i <literal>` reporting `Data type: <dt>`), and writes the `#vOut` readout `<code>literal</code> is a/an <b>type</b> — note`. Helpers `esc(s)` and `article(w)`. Wired via `click`/`keydown` per tile; initial calls `build()` then `select('integer')`.
- **Degrades:** the tiles are JS-built and so absent without JS, but the eight types are also enumerated statically in the `#types` `.deflist` (the content survives without the figure). The `.reveal` References block falls back to visible under `prefers-reduced-motion` or when `IntersectionObserver` is unavailable; no browser storage.

### Footer build-stamp decoder (`#stamp`)
- **Stamp id:** `TSK0NbBlxncgls` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-31 13:51:47 UTC". The `decodeBranded` function (epoch `1704067200000`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`) decodes it to `ns=TSK · node=0 · seq=0 · 2026-05-31 13:51:47 UTC`, matching `#st-ts`. Toggle on click / Enter / Space.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

**Sources**
- `https://hexdocs.pm/elixir/basic-types.html` — Basic types — Elixir documentation — the values you build with.
- `https://hexdocs.pm/iex/IEx.html` — `IEx` — Elixir documentation — the interactive shell.

**Related in this course**
- `/elixir/language/match` — F3.02 · Pattern matching & the match operator
- `/elixir/language` — F3 · The Elixir Language

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/language">language</a><span class="rsep">/</span><span class="rcur">values</span>`.
- **crumbs:** `F3 · The Elixir Language` → `/elixir/language` · sep `/` · here `F3.01 · values` (no link).
- **toc-mini:** `#iex` ("The shell") · `#values` ("The values") · `#types` ("The eight you meet first").
- **pager:** prev → `/elixir/language/under-the-hood` ("← Under the hood"); next → `/elixir/language/match` ("Next · F3.02 · match →").
- **footer (`.foot-nav`, three columns):** Chapters → `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`; The course → `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01"); brand + foot-logo both → `/elixir`.
- **Page meta:** `<title>` "Values, types & IEx — F3.01 · jonnify"; `<meta name="description">` "The data Elixir is built from — integers, floats, atoms, booleans, strings, lists, tuples, and maps — explored through IEx, the interactive shell, and the i/1 helper."

## Build instruction

To rebuild this leaf lesson, copy the `<head>`…`</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir (purple) accent — this page itself, `elixir/language/values.html`, is the cleanest model among the F3 leaves — then change only `<title>`/`<meta>`, the route-tag, and the `<main>` body. Keep the `.refs` styles and the `.reveal`-wrapped References section, and the branded-stamp decoder. Preserve clamp-spacing (`clamp(2.7rem,1.9rem + 4.2vw,5.1rem)`; spaces around `+` are load-bearing). No-invent guards: teach only the real Elixir value types and IEx helpers as written; where the chapter's running example is the learning `Portal`, use only its real surfaces (branded store, an event-sourced engine behind ONE `Portal` facade, a Phoenix web app) and cite the companion course for OTP internals rather than re-teaching them. Voice: no first person, no exclamation marks, no emoji, and none of *just*/*simply*/*obviously*. Model sibling to copy from: `elixir/language/values.html`.
