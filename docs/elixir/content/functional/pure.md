# F2.01 — Pure functions & side effects (dive)

- Route (served): `/elixir/functional/pure`
- File: `elixir/functional/pure.html`
- Place in the chapter: the first module of F2 · Functional Programming and its Foundations movement — the "start here" leaf the rest of the chapter rests on. It precedes F2.02 · Immutability & persistent data and grounds the chapter's working style: a pure core wrapped in a thin effectful shell.
- Accent: chapter accent `elixir` (purple — `--elixir`/`--elixir-bright`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F2 · Functional Programming`

H1 (verbatim): `Pure functions & side effects`

Hero lede (verbatim):

> A pure function depends only on its arguments and changes nothing outside itself. Same input, same output, every time — and the world is untouched. That single property is what makes functional code easy to reason about.

Kicker line (verbatim):

> F1.02 met this idea as referential transparency: a call can be replaced by its result. Here we take the practitioner's view. A pure function is deterministic and effect-free; a side effect is any reach beyond the return value — printing, reading the clock, drawing a random number, mutating shared state. Real programs need effects, so the craft is isolating them: a pure core wrapped in a thin effectful shell.

## Sections

In order, three teaching sections (each closes with a `.bridge` and a `.take`), then a synthesis:

1. `#same` — "Same in, same out". The purity test: call a function twice with the same argument and compare. Running example: `square(3)` vs `:rand.uniform()`, `next_id()`, `utc_now()`. Carries a `deflist` defining `pure`, `side effect`, `deterministic`, `effect boundary`.
2. `#effects` — "What counts as an effect". An effect is any reach beyond the return value: I/O, randomness, time, mutation. Running example: six operations sorted pure vs effect.
3. `#shell` — "Core and shell". Push effects to the edges — a pure **functional core** wrapped in an effectful **imperative shell**. Running example: a five-step program stepped through.
4. Synthesis "What this lands", then the pager.

Real Elixir shown across the sections (verbatim from the figure code/data): `square(3) == square(3)   # => true`; `:rand.uniform() == :rand.uniform()   # => false`; `next_id()`; `DateTime.utc_now() == DateTime.utc_now()   # => false`; `String.upcase("hi")   # => "HI"`; `a + b`; `Enum.map([1, 2], &(&1 * 2))   # => [2, 4]`; `IO.puts("hi")   # prints, returns :ok`; and the core/shell pipeline `read_line()` → `String.to_integer(line)` → `double(n)` → `to_string(result)` → `IO.puts(text)`.

## The interactives

### Figure 1 — Call it twice · do the results agree?
- `<figure>` title (verbatim `<h4 id="sameTitle">`): `Call it twice · do the results agree?`.
- Control group `#sameSel` (`role="group"`), four buttons (`data-fn`): `sq` `data-c="sage"` (active by default) label `square(3)`; `rand` `data-c="elixir"` label `:rand.uniform()`; `counter` `data-c="elixir"` label `next_id()`; `now` `data-c="elixir"` label `utc_now()`.
- SVG element ids: `#sameV1`, `#sameV2` (the two call results), `#sameBadge`/`#sameBadgeBox`/`#sameBadgeT` (the `=`/`≠` badge); plus `#sameCode` and `#sameOut` readouts (`aria-live="polite"`).
- Pure function: `renderSame()` reads `SAME[key]` and writes the two values, the badge (`=` for pure / `≠` for impure, with stroke/fill recoloured sage vs burgundy), the code line, and the readout.
- Readout strings (verbatim `SAME` data): `square(3)` → `equal — pure, referentially transparent`; `:rand.uniform()` → `differ — nondeterministic (draws randomness)`; `next_id()` → `differ — depends on hidden, changing state`; `utc_now()` → `differ — depends on the clock`. Static default `#sameOut` markup: `square(3) twice → 9 and 9 · equal — pure, referentially transparent`.

### Figure 2 — Pure or effect?
- `<figure>` title (verbatim `<h4 id="effTitle">`): `Pure or effect?`.
- Control group `#effSel` (`role="group"`), six buttons (`data-op`): `upcase` `data-c="sage"` (active) label `String.upcase`; `add` `data-c="sage"` label `a + b`; `map` `data-c="sage"` label `Enum.map`; `puts` `data-c="elixir"` label `IO.puts`; `rand` `data-c="elixir"` label `:rand.uniform`; `now` `data-c="elixir"` label `DateTime.utc_now`.
- SVG element ids: `#effExpr` (the expression), `#effBadge`/`#effBadgeBox`/`#effBadgeT` (the `pure`/`effect` badge); plus `#effCode` and `#effOut` readouts.
- Pure function: `renderEff()` reads `EFF[key]`, sets the expression, recolours the badge (`pure` sage / `effect` burgundy), and writes the code + readout.
- Readout reasons (verbatim `EFF` data): `String.upcase` → `depends only on its argument and returns a value`; `a + b` → `arithmetic on its arguments; no outside contact`; `Enum.map` → `returns a new list; the input is unchanged`; `IO.puts` → `writes to standard output — an observable effect`; `:rand.uniform` → `draws a random number — nondeterministic`; `DateTime.utc_now` → `reads the system clock — depends on time`. Static default `#effOut` markup: `pure · depends only on its argument and returns a value`.

### Figure 3 — Functional core, imperative shell
- `<figure>` title (verbatim `<h4 id="shellTitle">`): `Functional core, imperative shell`.
- Control: a `.fold-ctrl` slider `#shellStep` (`min=0 max=4 step=1 value=0`) with value label `#shellStepval` (default `1 / 5`).
- SVG element ids: step groups `#stp0`–`#stp4` with value labels `#v0`–`#v4`; readout `#shellOut` (`aria-live="polite"`).
- Pure function: `renderShell()` reads the `STEPS` array (five entries, `kind` `effect`/`pure`), revealing values up to the slider step and writing the readout. Steps 0 and 4 are effects (`read_line()`, `IO.puts(text)`); steps 1–3 are the pure core (`String.to_integer(line)` → `42`, `double(n)` → `84`, `to_string(result)` → `"84"`).
- Readout (verbatim default `#shellOut`): `step 1 · read_line() (effect) · reads "42" from input`. The SVG label `PURE CORE · TESTABLE` brackets the three pure steps.

### Degrade behaviour
Each figure renders its static default in the markup (the active button + the verbatim default readouts above), so the lesson reads without JS. `html.js .reveal` is JS-gated; `prefers-reduced-motion: reduce` disables the reveal transition; `scroll-behavior` falls back to `auto` under reduced motion.

### Footer build-stamp decoder
- Stamp id (verbatim `#stampId`): `TSK0NZWQM0ydEW`.
- Decoded UTC timestamp (verbatim `#st-ts`): `2026-05-30 13:45:34 UTC`.
- `decodeBranded` splits the `TSK` namespace from the base-62 Snowflake (`EPOCH_MS = 1704067200000`) and fills the panel `dt`/`dd` rows; toggles open on click/Enter/Space.

## References (#refs, verbatim)

This page has no `#refs` References block — no intro line, no Sources list, and no "Related in this course" list are present in the markup. The cross-links it does carry are inline: the `.bridge` cells cite `F1.02 · substitution`, `Algebra`, `Elixir`, and `Principle`; the synthesis and `.note` point forward to F2.02 and back to `/elixir/functional` (the F2 overview).

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `functional` `/ ` `pure` (`<a href="/elixir">elixir</a>`, `<a href="/elixir/functional">functional</a>`, `<span class="rcur">pure</span>`).
- crumbs (verbatim): `F2 · Functional` → `/elixir/functional` / `F2.01` (`here`).
- toc-mini (`.toc-mini`, in-page anchors): `Same in, same out` → `#same`; `What counts as an effect` → `#effects`; `Core and shell` → `#shell`.
- pager: prev → `/elixir/functional` label `← F2 · Functional overview`; next → `/elixir/functional` label `More in F2 · Functional →`.
- footer columns (verbatim): identical to the chapter hub — foot-brand `jonnify` → `/elixir` with the "functional thinking taught twice" tagline; Chapters `F1 · Algebra`/`F2 · Functional Programming`/`F3 · The Elixir Language`/`F4 · Algorithms & Data Structures`/`F5 · Pragmatic Programming`/`F6 · Phoenix Framework` → `/elixir/algebra`/`/elixir/functional`/`/elixir/language`/`/elixir/algorithms`/`/elixir/pragmatic`/`/elixir/phoenix`; The course `Course home`/`Contents & history`/`Start · F1.01` → `/elixir`/`/elixir/course`/`/elixir/algebra/functions`.
- Page meta:
  - `<title>` (verbatim): `Pure functions & side effects — F2.01 · jonnify`
  - `<meta name="description">` (verbatim): `What purity buys and how to keep it: same input gives the same output, what counts as a side effect, and the functional core / imperative shell that isolates effects at the edges.`

## Build instruction

To (re)build this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the trailing two `<script>` blocks verbatim from a recent BUILT sibling on this chapter accent — the model sibling is `elixir/functional/persistence.html` (the next F2 leaf: same three-section hero/`toc-mini`/`bridge`/`take` anatomy and the same footer). Change only the `<title>`/`<meta name="description">`, the `route-tag`, the crumbs, and the `<main>` body (hero, the `#same`/`#effects`/`#shell` figures and their `SAME`/`EFF`/`STEPS` data, and the synthesis). Keep the `elixir` purple accent on impure/effect controls (`data-c="elixir"`) and sage on pure ones, and keep the stamp decoder verbatim. No-invent guards: cite only the real Elixir surfaces as written (`String.upcase`, `Enum.map`, `IO.puts`, `:rand.uniform`, `DateTime.utc_now`, `String.to_integer`) and the real course routes; when later editions reach the F5/F6 platform, name only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE `Portal` facade, the Phoenix web app — and cite the companion course for OTP internals rather than re-teaching them; do not invent a readout string, code token, or route. Voice rules: no first person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously".
