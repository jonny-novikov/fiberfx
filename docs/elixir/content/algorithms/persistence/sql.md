# F4.08.2 — SQLite & PostgreSQL (dive)

- Route (served): `/elixir/algorithms/persistence/sql`
- File: `elixir/algorithms/persistence/sql.html`
- Place in the chapter: Part 2 of 3 of the F4.08 persistence module. It follows `keys` (store the integer, brand at the edge) and precedes `redis` (shedding abusive traffic). It teaches that, because the high bits of the id are a timestamp, a relational store range-queries by time with no `created_at` column — a time window is a contiguous window of ids, served by the primary-key index.
- Accent: sage (F4 chapter accent); the dive uses sage / blue / gold for the three time-window cases.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.08 · part 2 of 3`

Hero h1: SQLite & `PostgreSQL` (the word `PostgreSQL` is the italic `.ex` accent span).

Lede (verbatim): "Because the high bits of the id are a timestamp, a window of time is a contiguous window of ids. To find every user created in a span, you do not need a `created_at` column or a second index: compute the Snowflake at the start of the window and the Snowflake at the end, and ask for `id >= min AND id < max`. The primary-key index already answers it."

Kicker (verbatim): "Pick a window. The bounds are computed the same way the generator makes ids — `(ms − epoch) << 22` — so the query is exact. Select a range."

## Sections

- `#range` "A time window is an id range" (teaching) — the lower bound is the smallest id mintable at or after the window opens; the upper bound the smallest id at or after it closes; every row in between was created in the window. Carries the interactive time-window figure and a take.
- `#advanced` "Advanced: one index, two queries" — the bound is `(ms − epoch) << 22` (timestamp shifted into place, worker and sequence bits zeroed); `id >= min` and `id < max` form a half-open range that misses nothing and double-counts nothing across all 1024 workers; identical in SQLite (INTEGER class) and PostgreSQL (`bigint`); the `EchoData.Snowflake` helpers `min_for_time/1` and `max_for_time/1` produce the bounds. Carries an Ecto.Query code block and a bridge.

Running example: the `users` table queried over date windows (May 2026, a single day `2026-05-31`, all of 2026).

Real Elixir code shown (`#advanced`, verbatim):
```
# a date range becomes an id range — the PK index serves it
min = EchoData.Snowflake.min_for_time("2026-05-01")   # => 308392073625600000
max = EchoData.Snowflake.max_for_time("2026-06-01")   # => 319626097459200000

from(u in User, where: u.id >= ^min and u.id < ^max)
# every user created in May 2026 — no created_at column, no second index
```

## The interactives

### `#range` figure — "Time window · select one"
- `<figure class="fig">` labelled by `#sqTitle` ("Time window · select one").
- Control group `#sqSel` (`.solid-select`, role group "Time window"), buttons:
  - `data-k="may"` `data-c="sage"` (active) — "May 2026"
  - `data-k="day"` `data-c="blue"` — "2026-05-31"
  - `data-k="year"` `data-c="gold"` — "all of 2026"
- SVG element ids: window text `#sqWin`, min bound `#sqMin`, max bound `#sqMax`, SQL line `#sqSql`, caption `#sqCaption`. Below: code `#sqCode`, readout `#sqOut`, window label `#sqRole`, served-by `#sqResult`.
- Pure function `boundFor(ms)` computes `(BigInt(ms) - EPOCH_MS) << 22n`, the same shift the generator uses; `EPOCH_MS = 1704067200000n`. The `WIN` table holds each window's start/end ms (`Date.UTC(...)`), label, window string, caption, and accent.
- Computed bounds: `may` → `308392073625600000` .. `319626097459200000`; the SVG default shows window "2026-05-01 .. 2026-06-01", min `308392073625600000`, max `319626097459200000`.
- Readout strings VERBATIM:
  - captions: "one month of users, with no created_at column" (may), "a single day of users, by id range alone" (day), "a whole year, still one contiguous id range" (year).
  - `#sqRole` window labels: "2026-05", "2026-05-31", "2026".
  - `#sqResult`: "the primary-key index" (all cases).
  - `#sqOut`: "The window **<win>** becomes the half-open id range `[<min>, <max>)`. Every row in between was created in the window — selected by the primary-key index, with no `created_at` column."
- Static SVG default matches the `may` case (window "2026-05-01 .. 2026-06-01"); no figure animation beyond the shared reveal-on-scroll.
- Take (verbatim): "No timestamp column, no second index: the bounds are pure arithmetic on the dates, and the primary-key B-tree already stores rows in the order the query wants them."

### Footer build-stamp
- `.stamp#stamp` decodes `#stampId` = `TSK0NcaQNHQrYG` via `decodeBranded` (ns + `snow >> 22n` timestamp, `(snow >> 12n) & 0x3FFn` node, `snow & 0xFFFn` seq; this page's decoder uses `Number(EPOCH_MS)` since `EPOCH_MS` is a BigInt). Static fallback `#st-ts` reads `2026-06-01 10:04:21 UTC`; click/Enter/Space toggles the panel.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://www.sqlite.org/datatype3.html` — "SQLite — Datatypes — INTEGER comparison and ordering."
- `https://www.postgresql.org/docs/current/indexes-types.html` — "PostgreSQL — Index Types — the B-tree that serves both point and range queries."
- `https://hexdocs.pm/ecto/Ecto.Query.html` — "Ecto.Query — expressing the half-open id range in Elixir."

Related in this course:
- `/elixir/algorithms/persistence` — "F4.08 · Branded ids & persistence — the module hub."
- `/elixir/algorithms/identifiers/snowflake` — "F4.07.2 · The Snowflake bigint — why time sits in the high bits."
- `/elixir/algorithms` — "F4 · Algorithms & Data Structures"

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / persistence / sql` — segments `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`, `persistence` → `/elixir/algorithms/persistence`, current `sql` in `.rcur`.
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) / `F4.08` (→ `/elixir/algorithms/persistence`) / `sql` (`.here`).
- toc-mini: `#range` "A time window is an id range"; `#advanced` "Advanced: one index, two queries".
- pager: prev → `/elixir/algorithms/persistence/keys` "F4.08.1 · keys"; next → `/elixir/algorithms/persistence/redis` "Next · Redis keys".
- footer: column "Chapters" — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column "The course" — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta — `<title>`: "SQLite & PostgreSQL — F4.08.2 · jonnify". `<meta description>`: "Because the high bits of the id are a timestamp, a window of time is a contiguous window of ids: compute the Snowflake at the window's open and close and query id >= min AND id < max. The primary-key index serves it as a contiguous read, so a point lookup and a time range share one structure — no created_at column, no second index, identical in SQLite and PostgreSQL."

## Build instruction

To rebuild this dive, copy the `head`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the F4 sage accent — the model sibling is the companion dive `elixir/algorithms/persistence/keys.html` (same module, same single-figure `.solid-select` shell). Change only the `<title>`/`<meta description>`, the header `route-tag`, the crumbs, and the `<main>` body (the `#range` time-window figure plus its `WIN` table and `boundFor` arithmetic, and the `#advanced` Ecto.Query block and bridge). No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE `Portal` facade, the Phoenix web app — so reference `EchoData.Snowflake.min_for_time/1` and `max_for_time/1` exactly, and keep the bound as `(ms − epoch) << 22`; cite the companion course for OTP internals, do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
