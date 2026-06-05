# F4.10 — Practical recipes in Elixir (module hub)

- Route (served): `/elixir/algorithms/recipes`
- File: `/Users/jonny/dev/jonnify/elixir/algorithms/recipes/index.html`
- Place in the chapter: module 10 of the restructured 12-module F4 · Algorithms & Data Structures chapter. It turns the chapter's structures (the F4.05→F4.09 persistent-map spine: HAMT → CHAMP → branded ids → persistence → the live branded-CHAMP store) into the Portal's everyday code, framing three dives — idiomatic `with` patterns, lazy `Stream` pipelines, and reading complexity to choose a lookup. Predecessor `F4.09 — Branded CHAMP maps & GenServer`; successor `F4.11 — Dynamic programming in Elixir`.
- Accent: sage (F4 · Algorithms & Data Structures).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4 · Practical recipes · module 10`

Hero h1 (verbatim): Practical `recipes` in Elixir

Hero lede (verbatim):

> The spine of this chapter built the structures; this module is how the Portal actually uses them. Three recipes recur: a `with` chain to thread a request through validate-load-authorize without nested cases; a lazy `Stream` pipeline to build reports over large collections without materialising every step; and reading **complexity** to pick the structure a lookup deserves. None is exotic — together they are most of the Portal's day-to-day code.

Kicker line (verbatim):

> Start with the report the dashboard shows: how far a learner has progressed, counted from the progress store of F4.09. Select a learner.

## What the page frames

The hub opens with a worked report section, then a three-card `.dives`-style list (rendered as inline anchor cards, not the `.mods` grid), then an advanced "recipes compose" section.

The three recipe dives:

- `F4.10.1` · the request lifecycle — **Idiomatic patterns** — a `with` chain threads validate → authenticate → load → authorize, short-circuiting to the right status on the first `{:error, _}`, no nested cases. Route: `/elixir/algorithms/recipes/patterns`. Built.
- `F4.10.2` · the activity feed — **Streams & pipelines** — a lazy `Stream` filters and maps completions in one fused pass and stops as soon as `take/2` is satisfied, instead of materialising the whole collection. Route: `/elixir/algorithms/recipes/pipelines`. Built.
- `F4.10.3` · choosing a lookup — **Profiling & complexity** — why the Portal keeps sessions in the F4.09 store and not a list: an `O(n)` scan against an `O(log₃₂ n)` map lookup, read straight from the code. Route: `/elixir/algorithms/recipes/profiling`. Built.

The chapter bridge (advanced section) frames `F4.05–F4.09 · the structures` (HAMT, CHAMP, branded ids, persistence, the live store) → `F4.10 · the recipes` (the idioms that turn those structures into the Portal's everyday code).

## The interactives

### Hero figure — "An Enum pipeline, one stage at a time"

- `<figure class="hero-fig">`, labelled by `id="hpTitle"`, caption text: `An Enum pipeline, one stage at a time`.
- Controls: `id="hpStep"` (`▸ step`) and `id="hpReset"` (`reset`, ghost). No data-key control-group; two buttons.
- SVG element ids: stage labels `hpLbl0`..`hpLbl3` (`input`, `|> map(&(&1 + 1))`, `|> filter(even?)`, `|> reduce(+)`); the live collection row `hpRow`; caption `hpCap` (`aria-live="polite"`).
- Pure functions / logic (inline IIFE): `STAGES` array computes each pipeline stage over `INPUT = [1, 2, 3, 4, 5, 6]` — map increments to `[2, 3, 4, 5, 6, 7]`, filter keeps the evens `[2, 4, 6]`, reduce sums to `12`. Helpers `cellG`, `resultCell`, `highlight`, `render(animate)`.
- Readout strings (VERBATIM):
  - Static default caption (in markup): `input  [1, 2, 3, 4, 5, 6]` then `Step to map each element, keep the evens, then sum what is left.`
  - Stage hints: `Step to map each element, keep the evens, then sum what is left.`; `map runs the function over every element — one new list, same length.`; `filter keeps the elements that pass the test — the odd ones are dropped.`; `reduce folds the list into one value — here the running sum.`
- Degrade: the static SVG already shows stage 0 (the input collection), so the pipeline reads without JS; no render runs on load. Cells animate via `.hp-new` under `prefers-reduced-motion: no-preference` and the animation is suppressed under `prefers-reduced-motion: reduce`.

### Report figure — "Learner · select one"

- `<figure class="fig">`, labelled by `id="rcTitle"` (`Learner · select one`).
- Control group `id="rcSel"` (role `group`, aria-label `Learner`) with buttons: `data-k="ada"` `data-c="sage"` (active, label `ada`), `data-k="kit"` `data-c="blue"` (`kit`), `data-k="jo"` `data-c="gold"` (`jo`).
- SVG ids: `rcBar`, `rcPct`, `rcTicks` (five `rcTick0`..`rcTick4` / `rcTickT0`..`rcTickT4` built in JS), `rcCaption`. Code/readout ids: `rcCode`, `rcOut`, `rcRole`, `rcResult`.
- Pure function name: `Portal.Progress.percent_complete/1` (the code the figure prints; named in prose as the report function). The figure's JS counts a learner's done-set over five lessons `LESSONS = ['LSN0NbCMKoAopE', 'LSN0NbCiUI0Sg4', 'LSN0NbD94T0Qtu', 'LSN0NbDmwjVOEa', 'LSN0NbAb2Lk9GS']` and divides. Learner ids: `ada` `USR0NbAb1xcFCy` done `[1,1,1,1,1]`; `kit` `USR0NbWMtkosp8` done `[1,1,1,0,0]`; `jo` `USR0NXh7MFjxT6` done `[1,0,0,0,0]`.
- Readout strings (VERBATIM):
  - Static default caption (markup): `ada has finished all five lessons`; default `rcPct` `100%`; default `rcResult` `5 of 5`; default `rcRole` `ada`.
  - Computed caption (JS): `<k> has finished all five lessons` when all five done, else `<k> has finished <done> of <TOTAL> lessons`.
  - Printed code template: `# count the learner's finished lessons, divide by the course size` / `Progress.percent_complete("<id>")` / `# <done> of <TOTAL> complete  ->  <pct>%`.
  - Readout (`rcOut`): `<k> has completed <done> of the course's <TOTAL> lessons — <pct>%. The figure is a count over an immutable snapshot of the progress store, not a query per lesson.`
- Take (verbatim): `The report is a count over an immutable snapshot and a division. The recipes below are how that stays small: validate the request once, stream the completions, and lean on a store whose lookups are cheap.`

### Advanced code block (static)

The "recipes compose" `course_progress(raw_uid, raw_cid)` function shown verbatim: a `with` validating `Portal.Id.validate(raw_uid, :USR)` and `Portal.Id.validate(raw_cid, :CRS)`, matching `%{} = user <- Store.get(uid)`, then `Catalog.lessons(cid)` and `lessons |> Stream.filter(&Progress.completed?(user, &1)) |> Enum.count()`, returning `{:ok, round(done / length(lessons) * 100)}`.

### Footer build-stamp decoder

- `id="stamp"` (role `button`, keyboard-activatable), id `id="stampId"` text `TSK0NcdRbJ4pAO`.
- Decodes the branded Snowflake (B62 alphabet, epoch `1704067200000`) into namespace / snowflake / node / seq / timestamp. The markup's pre-decoded timestamp dd reads `2026-06-01 10:46:37 UTC`; decoding `TSK0NcdRbJ4pAO` yields namespace `TSK` and the same UTC build time.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- Elixir — `with/1` — threading a happy path over fallible steps. — `https://hexdocs.pm/elixir/Kernel.SpecialForms.html#with/1`
- Elixir — Stream — lazy, composable enumerables. — `https://hexdocs.pm/elixir/Stream.html`
- Elixir — Enum — the eager counterpart and where a pipeline terminates. — `https://hexdocs.pm/elixir/Enum.html`

Related in this course:
- `/elixir/algorithms/branded-champ` — F4.09 · Branded CHAMP maps & GenServer — the store these recipes read.
- `/elixir/algorithms/persistence` — F4.08 · Branded ids & persistence — the validation the `with` chain reuses.
- `/elixir/algorithms/maps` — F4.04 · Maps, sets & hashing — why a map lookup beats a scan.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `algorithms` `/` `recipes` (the trailing `recipes` is the current `.rcur` segment; `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`).
- crumbs (verbatim): `F4 · Algorithms & Data Structures` (→ `/elixir/algorithms`) / `F4.10 · recipes` (here).
- toc-mini: `#report` → `The progress report`; `#recipes` → `Three recipes`; `#advanced` → `Advanced: recipes compose`.
- pager: prev → `/elixir/algorithms/branded-champ` label `F4.09 · branded-champ`; next → `/elixir/algorithms/recipes/patterns` label `Start · idiomatic patterns`.
- footer: column **Chapters** — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column **The course** — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01. Foot brand links `/elixir`; foot-tag: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta:
  - `<title>`: `Practical recipes in Elixir — F4.10 · jonnify`
  - `<meta description>`: `The chapter's structures turned into the Portal's everyday code through three recurring recipes: a with chain to thread a request through validate-load-authorize without nested cases; a lazy Stream pipeline to build reports over large collections without materialising every step; and reading complexity to choose the structure a lookup deserves. The hub computes a learner's course progress as a count over the F4.09 store, and the recipes compose into one request flow.`

## Build instruction

To rebuild this hub, copy the `<head>…</style>`, the `header`, the `footer`, and the trailing two `<script>` blocks verbatim from a recent built sibling on the sage F4 accent — the closest model is the chapter-mate module hub at `/elixir/algorithms/branded-champ` (`/Users/jonny/dev/jonnify/elixir/algorithms/branded-champ/index.html`), which carries the same hub anatomy (hero-fig, report-style `.fig`, dives list, bridge, refs, pager). Change only `<title>`/`<meta>`, the `route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the branded store (`Store.get/1`, `Portal.Id.validate/2`, `Champ.get/2`), the event-sourced engine behind one Portal facade, and the Phoenix web app; cite the companion course for OTP internals, do not re-teach them; do not invent ids, routes, readout strings, or reference URLs beyond those above. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
