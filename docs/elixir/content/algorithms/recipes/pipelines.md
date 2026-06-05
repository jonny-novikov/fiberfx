# F4.10.2 — Streams & pipelines (dive)

- Route (served): `/elixir/algorithms/recipes/pipelines`
- File: `/Users/jonny/dev/jonnify/elixir/algorithms/recipes/pipelines.html`
- Place in the chapter: part 2 of 3 of module `F4.10` (Practical recipes) in F4 · Algorithms & Data Structures. It is the activity-feed recipe — eager `Enum` against lazy `Stream` over the same twelve completions — and pulls from the F4.09 store the previous dive admits a request into. Sits between `patterns` and `profiling`.
- Accent: sage (F4 · Algorithms & Data Structures).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.10 · part 2 of 3 · the activity feed`

Hero h1 (verbatim): Streams & `pipelines`

Hero lede (verbatim):

> The dashboard's activity feed wants the three most recent completions for a course. The transforms are the same either way — filter to that course, shape each into a feed entry, take three — but the engine matters. `Enum` runs each stage to completion and hands the next a full list; `Stream` fuses the stages into one pass that pulls elements on demand and **stops** the moment `take/2` has its three.

Kicker line (verbatim):

> The same pipeline over the same twelve completions. Switch the engine and watch how many it examines and how many lists it builds.

## Sections

In order:

1. `#fuse` — **Examine only what you take** (teaching). The "Engine · select one" figure (Stream vs Enum over twelve completions, seven matching, three wanted) plus its take.
2. `#advanced` — **Advanced: when eager still wins** (advanced). Building a `Stream` does no work until an `Enum` terminal pulls; fused stages and `Enum.take/2` halt at the cutoff; per-element closure overhead means eager `Enum` is usually faster on a small list read to the end. The feed (a long log, only three wanted) favours the stream.

Running example: the activity feed `recent(completions, course_id)`. Real Elixir shown (advanced block, verbatim): `completions |> Stream.filter(&(&1.course_id == course_id)) # lazy |> Stream.map(&to_feed_entry/1) # lazy, fused with the filter |> Enum.take(3) # pulls until 3, then stops`.

## The interactives

### Figure — "Engine · select one"

- `<figure class="fig">`, labelled by `id="ppTitle"` (`Engine · select one`).
- Control group `id="ppSel"` (role `group`, aria-label `Pipeline engine`) with buttons: `data-k="stream"` `data-c="sage"` (active, label `Stream (lazy)`); `data-k="enum"` `data-c="gold"` (`Enum (eager)`).
- SVG ids: cell group `ppCells` (twelve cells `ppCell0`..`ppCell11` built in JS, matches marked at indices `0,2,4,5,7,9,11`), stop marker `ppStop` + `ppStopT`, stage lines `ppStage1`, `ppStage2`, `ppStage3`. Code/readout ids: `ppCode`, `ppOut`, `ppRole`, `ppResult`.
- Pure logic: `N = 12`, `TAKE = 3`, `MATCH` set; `STREAM_EXAMINED` computes how many source elements a lazy pull touches to collect three matches (`5`); `TAKEN` is the first three matching indices (`[0,2,4]`). Lazy → examined `5`, mapped `3`, `0` intermediate lists; eager → examined `12`, mapped `7` (total matches), `2` intermediate lists.
- Readout strings (VERBATIM):
  - Static default markup: `ppStopT` `stop: 3 taken`; `ppStage1` `filter: examined 5 of 12`; `ppStage2` `map: applied 3 times`; `ppStage3` `intermediate lists: 0 · result: 3 entries`; `ppRole` `5 of 12`; `ppResult` `0`.
  - Stage line templates (JS): `filter: examined <examined> of <N>`; `map: applied <mapped> time` / `... times`; `intermediate lists: <lists> · result: <TAKE> entries`.
  - `ppRole`: `<examined> of <N>`.
  - Readout `ppOut` (lazy): `The lazy pipeline pulls until take/2 has three, examining <examined> of <N> completions, applying the map <mapped> times, and allocating 0 intermediate lists. The eight completions past the cutoff are never touched.`
  - Readout `ppOut` (eager): `Eager Enum walks all <N> in the filter and all <totalMatches> matches in the map, building 2 intermediate lists, before take/2 keeps three. Same result, more work and more allocation.`
- Take (verbatim): `Same transforms, same result — three feed entries. The lazy pipeline reaches them by examining five completions and allocating nothing in between; the eager one walks all twelve and builds two lists to throw most of away.`

### Bridge

`Enum · eager` (Each stage runs to completion and hands on a full list.) → `Stream · lazy` (Stages fuse into one pull that stops at the cutoff, allocating nothing between.).

### Footer build-stamp decoder

- `id="stamp"` keyboard-activatable; `id="stampId"` text `TSK0NcdRbtyg4m`.
- Decodes namespace `TSK`, snowflake, node, seq, timestamp via the B62 / epoch `1704067200000` decoder; markup pre-decoded timestamp dd `2026-06-01 10:46:37 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- Elixir — Stream — lazy composition and fusion. — `https://hexdocs.pm/elixir/Stream.html`
- Elixir — `Enum.take/2` — the terminal that halts the pull. — `https://hexdocs.pm/elixir/Enum.html#take/2`
- Elixir — Enumerable and Streams — eager versus lazy, and when each fits. — `https://hexdocs.pm/elixir/enumerable-and-streams.html`

Related in this course:
- `/elixir/algorithms/recipes` — F4.10 · Practical recipes in Elixir — the module hub.
- `/elixir/algorithms/branded-champ` — F4.09 · Branded CHAMP maps & GenServer — the store these pipelines read.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `algorithms` `/` `recipes` `/` `pipelines` (`pipelines` is `.rcur`; `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`, `recipes` → `/elixir/algorithms/recipes`).
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) / `F4.10` (→ `/elixir/algorithms/recipes`) / `pipelines` (here).
- toc-mini: `#fuse` → `Examine only what you take`; `#advanced` → `Advanced: when eager still wins`.
- pager: prev → `/elixir/algorithms/recipes/patterns` label `F4.10.1 · patterns`; next → `/elixir/algorithms/recipes/profiling` label `Next · profiling & complexity`.
- footer: column **Chapters** — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column **The course** — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01. Foot-tag: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta:
  - `<title>`: `Streams & pipelines — F4.10.2 · jonnify`
  - `<meta description>`: `The activity feed wants the three most recent completions for a course. Eager Enum runs each stage to a full list — walking all twelve completions and mapping all seven matches before three are taken. Lazy Stream fuses filter and map into one pull that stops at the third match, examining five completions and allocating no intermediate lists for the same result. Eager still wins on small collections read to the end.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, `header`, `footer`, and trailing `<script>` blocks verbatim from a recent built sibling on the sage F4 accent — copy from the chapter-mate dive `/elixir/algorithms/recipes/patterns` (`/Users/jonny/dev/jonnify/elixir/algorithms/recipes/patterns.html`), which shares this dive's exact anatomy (hero lede, one teaching `.fig` + one advanced section, bridge, refs, pager). Change only `<title>`/`<meta>`, the `route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — `Stream.filter/2`, `Stream.map/2`, `Enum.take/2`, the branded store the pipeline pulls from, the event-sourced engine behind one Portal facade, the Phoenix web app; cite the companion course for OTP internals, do not re-teach them; do not invent ids, routes, readout strings, counts, or reference URLs beyond those above. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
