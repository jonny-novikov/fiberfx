# F3.04.1 — Enum, the eager workhorse (dive)

- Route (served): `/elixir/language/enum-streams/enum`
- File: `/Users/jonny/dev/jonnify/elixir/language/enum-streams/enum.html`
- Place in the chapter: the first of three dives under the F3.04 `enum-streams` hub. It opens the eager → lazy arc — `Enum` as the eager workhorse that walks any collection — and hands off to comprehensions (F3.04.2) and lazy streams (F3.04.3).
- Accent: elixir (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3.04 · part 1 of 3`

H1: Enum, the eager workhorse

Hero lede (verbatim):

> The `Enum` module is where most collection work happens. Its functions take any enumerable and a function, walk every element, and return a new collection. It is **eager**: each call runs to completion and hands back a finished result before the next call begins.

Kicker (verbatim):

> Given a learner's progress — a list of records, each with a course and a completion flag — a handful of `Enum` functions answer most questions: how many are done, how they group by course, how the statuses break down.

## Sections

Two teaching sections, plus the running example of a learner's progress (five records across two courses, `elixir` and `otp`).

1. `#summary` — "Summarising progress": five progress records, and the `Enum operation · select one` interactive (below). Takeaway: "Each function reads the whole list and returns something new — a number, a map, a grouped structure — without changing the records. That is the eager model: compute the full answer now."
2. `#functions` — "The functions you reach for": `map` transforms, `filter` selects, `reduce` accumulates, and the rest (`group_by`, `frequencies_by`, `sort_by`) are built on `reduce`.

Real Elixir code shown (verbatim, the `#functions` static block):

```elixir
# each call returns a brand-new collection
ids       = Enum.map(progress, & &1.lesson_id)
done      = Enum.filter(progress, & &1.completed)
by_course = Enum.group_by(progress, & &1.course)
mix       = Enum.frequencies_by(progress, & &1.completed)

# reduce is the engine the others are built on
count = Enum.reduce(progress, 0, fn r, n ->
  if r.completed, do: n + 1, else: n
end)
```

Bridge cells (`F2.05 · the fold` → `F3 · Enum.reduce`): "Reduce a collection to a single value by folding each element into an accumulator." → "The same fold as a real function — and the base that `map`, `filter`, and `group_by` are written on."

Closing note: "Next: **comprehensions** — a second way to walk an enumerable and build a collection."

## The interactives

### Section figure — "Enum operation · select one"

- `<figure class="fig">`, labelled by `#enTitle` ("Enum operation · select one").
- Control group `#enSel` (`role="group"`, `aria-label="Enum operation"`), three buttons: `data-k="count"` (`data-c="elixir"`, label `count done`, default active), `data-k="group"` (`data-c="blue"`, label `group_by course`), `data-k="freq"` (`data-c="sage"`, label `frequencies`).
- SVG element ids: record-chip group `#enRecs` (drawn once from the five-record `RECS` array), result group `#enRes`; plus the code panel `#enCode` and readout `#enOut` (both `aria-live="polite"`).
- The `RECS` running example: `{elixir, done}`, `{elixir, not}`, `{otp, done}`, `{otp, done}`, `{elixir, done}` — five records, four completed.
- The pure dispatch is `pick(k)`; each operation is an entry in the `OPS` table (`count`, `group`, `freq`) that draws into `#enRes` and returns `{code, out}`.
  - count: counts done records (`= 4`); code `Enum.count(progress, & &1.completed)` `# => 4`.
  - group: buckets by course; code `Enum.group_by(progress, & &1.course)` `# => %{"elixir" => [..3..], "otp" => [..2..]}`.
  - freq: counts each outcome; code `Enum.frequencies_by(progress, & &1.completed)` `# => %{true => 4, false => 1}`.
- Readout strings (verbatim):
  - count: `Four of the five records are completed, so Enum.count with a predicate returns 4.`
  - group: `group_by buckets the records by course: elixir has 3, otp has 2.`
  - freq: `frequencies_by counts each outcome: 4 done, 1 not yet.`
- Degrade behaviour: the figure renders the static SVG scaffold (the `PROGRESS · 5 RECORDS` and `RESULT` labels and the dividing line) without JS; the chips, result, code, and readout are JS-populated, defaulting to the `count` operation via `pick('count')`. No motion in this figure; the page's `.reveal` sections fall back to visible when `prefers-reduced-motion: reduce` or no `IntersectionObserver`.

### Footer build-stamp decoder

- `.stamp` `#stamp` with `#stampId` = `TSK0NbFndscMyG`. The static panel shows timestamp `2026-05-31 14:48:08 UTC`.
- `decodeBranded` splits the 3-char namespace (`TSK`) from the base-62 Snowflake, unpacks `ts >> 22`, `node = (snow >> 12) & 0x3FF`, `seq = snow & 0xFFF` against `EPOCH_MS = 1704067200000`, decoding to `2026-05-31 14:48:08 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/enumerable-and-streams.html` — Enumerables and streams — Elixir documentation — eager versus lazy.
- `https://hexdocs.pm/elixir/Stream.html` — `Stream` — Elixir documentation — lazy enumerables.
- `https://hexdocs.pm/elixir/Enumerable.html` — `Enumerable` protocol — Elixir documentation — what makes a thing enumerable.

Related in this course:
- `/elixir/language/enum-streams` — F3.04 · Enumerables & streams
- `/elixir/language/enum-streams/streams` — Lazy streams

## Wiring

- route-tag: `/ elixir / language / enum-streams / enum` (`elixir` → `/elixir`, `language` → `/elixir/language`, `enum-streams` → `/elixir/language/enum-streams`, `enum` current `.rcur`).
- crumbs: `F3` (→ `/elixir/language`) `/` `F3.04` (→ `/elixir/language/enum-streams`) `/` `Enum` (`.here`).
- toc-mini: `Summarising progress` (`#summary`), `The functions you reach for` (`#functions`).
- pager: prev → `/elixir/language/enum-streams` label `← F3.04 · enum & streams`; next → `/elixir/language/enum-streams/comprehensions` label `Next · comprehensions →`.
- footer: column "Chapters" — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column "The course" — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01. Brand line `jonnify` → `/elixir`; copyright `© jonnify`.
- Page meta: `<title>` = `Enum, the eager workhorse — F3.04 · jonnify`. `<meta name="description">` = `The Enumerable protocol unifies lists, ranges, maps, and streams, and the Enum module is the toolkit that walks them — map, filter, reduce, group_by, frequencies — each returning a new collection.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir accent — the natural model is the next dive in this same module, `/elixir/language/enum-streams/streams.html` (identical head, header, and footer; same single-column lesson hero, single `.solid-select` figure, and References block). Change only `<title>`/`<meta>`, the route-tag, the crumbs/toc-mini/pager, and the `<main>` body (the lesson hero, the `#summary` `Enum operation` figure, the `#functions` code block and bridge). No-invent guards: the running example is the learning Portal's progress records — use only the real Portal surfaces as written (the branded store, the event-sourced engine behind one `Portal` facade, the Phoenix web app); cite the companion course for OTP internals rather than re-teaching them, and keep every Elixir token (`Enum.map`, `Enum.filter`, `Enum.reduce`, `Enum.group_by`, `Enum.frequencies_by`, `Enum.count`, the `lesson_id`/`course`/`completed` fields, the readout strings) exactly as the live page shows them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
