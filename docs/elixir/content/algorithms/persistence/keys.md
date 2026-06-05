# F4.08.1 — Branded ids as keys (dive)

- Route (served): `/elixir/algorithms/persistence/keys`
- File: `elixir/algorithms/persistence/keys.html`
- Place in the chapter: Part 1 of 3 of the F4.08 persistence module. It sits first in the teaching arc — what you actually store and index — before `sql` (range-querying by time) and `redis` (shedding abusive traffic). It establishes that the database stores the 64-bit integer, not the wire string, and brands at the edge.
- Accent: sage (F4 chapter accent); the dive uses sage / blue / gold for the three key-view cases.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.08 · part 1 of 3`

Hero h1: Branded ids as `keys` (the word `keys` is the italic `.ex` accent span).

Lede (verbatim): "The wire shows `USR0NbWMtkosp8`, but the database does not store that string. It stores the 64-bit integer underneath it as a `bigint` primary key — eight bytes, not fourteen characters — and the application brands it back into a string only at the edge, on the way out. The integer key is compact, it sorts by time, and it carries enough to validate itself."

Kicker (verbatim): "One record, three views of its key: the integer the database keeps, the branded string the client sees, and the index that turns either into a row. Select one."

## Sections

- `#store` "Store the integer, brand at the edge" (teaching) — the integer and the string are the same value in two encodings; storing the number keeps the key small and numerically ordered; an index answers a point lookup in `O(log n)`. Carries the interactive key-view figure and a take.
- `#advanced` "Advanced: eight bytes that sort themselves" — a `bigint` is fixed at eight bytes and compares in one instruction; the high-bit timestamp makes the primary-key index naturally clustered by time, which the next dive's range query rides on; the brand is a boundary concern, not a storage one. Carries an Ecto-schema code block and a bridge.

Running example: a `users` record whose key is the Snowflake integer `319545566822428714`, wire form `USR0NbWMtkosp8`.

Real Elixir code shown (`#advanced`, verbatim):
```
# the schema keys on the integer; the namespace lives at the edge
schema "users" do
  field :id, :integer, primary_key: true   # bigint Snowflake, 8 bytes
  field :email, :string
end

Portal.Id.brand("USR", user.id)   # => "USR0NbWMtkosp8"  (only at the edge)
```

## The interactives

### `#store` figure — "View · select one"
- `<figure class="fig">` labelled by `#keTitle` ("View · select one").
- Control group `#keSel` (`.solid-select`, role group "Key view"), buttons:
  - `data-k="integer"` `data-c="sage"` (active) — "stored integer"
  - `data-k="string"` `data-c="blue"` — "wire string"
  - `data-k="index"` `data-c="gold"` — "index"
- SVG element ids: integer highlight `#keIntHi`, string highlight `#keStrHi`, index group `#keIdx`, caption `#keCaption`. Below: code `#keCode`, readout `#keOut`, role `#keRole`, size `#keResult`.
- Constants: `SNOW = 319545566822428714n`, `NS = "USR"`, `EPOCH_MS = 1704067200000`. Pure functions `b62encode(n)` (11-char zero-padded base62) and `b62decode(s)`; `PAY = b62encode(SNOW)`, `WIRE = NS + PAY` computes the wire string `USR0NbWMtkosp8`; `TSTR` decodes the creation time from `SNOW >> 22n`. The `CASES` table drives each view's highlight opacity, caption, role, size, code, and readout.
- Readout strings VERBATIM:
  - integer — caption "the database stores the 64-bit integer, not the string"; role "the stored primary key"; size "8 bytes"; out: "The stored key is the **64-bit integer** `319545566822428714` — eight bytes that compare in one instruction and, because time is in the high bits, sort by creation time on their own."
  - string — caption "the branded string is derived for the wire, then discarded"; role "the branded wire form"; size "14 chars (derived)"; out: "The **wire form** `USR0NbWMtkosp8` is base62 of the same integer with a namespace prepended. It is computed at the edge and never persisted — storing it would double the key width and lose numeric order."
  - index — caption "a B-tree index on the integer answers a lookup in O(log n)"; role "the primary-key index"; size "O(log n) lookup"; out: "A **B-tree index** on the bigint locates the row in `O(log n)`. Because ids are time-ordered, that one index also serves range scans by time, so no separate timestamp index is needed."
- Static SVG default: integer row highlighted (`#keIntHi` fill-opacity `0.10`), caption "the database stores the 64-bit integer, not the string", `#keRole` "the stored primary key", `#keResult` "8 bytes" — matching the `integer` case picked on load. No animation in this figure (no prefers-reduced-motion gate beyond the shared reveal-on-scroll).
- Take (verbatim): "Store the number, show the string. The column stays eight bytes and sorts by time on its own, and the branded form is a pure function of it — computed at the edge, never persisted twice."

### Footer build-stamp
- `.stamp#stamp` decodes `#stampId` = `TSK0NcaQMsSA6a` via `decodeBranded` (ns + `snow >> 22n` timestamp, `(snow >> 12n) & 0x3FFn` node, `snow & 0xFFFn` seq). Static fallback `#st-ts` reads `2026-06-01 10:04:21 UTC`; click/Enter/Space toggles the panel.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://www.sqlite.org/datatype3.html` — "SQLite — Datatypes — the INTEGER storage class for a 64-bit key."
- `https://www.postgresql.org/docs/current/datatype-numeric.html` — "PostgreSQL — Numeric Types — `bigint`, eight bytes, indexed and compared cheaply."
- `https://hexdocs.pm/ecto/Ecto.Schema.html` — "Ecto.Schema — defining the integer primary key in Elixir."

Related in this course:
- `/elixir/algorithms/persistence` — "F4.08 · Branded ids & persistence — the module hub."
- `/elixir/algorithms/identifiers` — "F4.07 · Identifiers, Snowflake & branded ids — the id being stored."
- `/elixir/algorithms` — "F4 · Algorithms & Data Structures"

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / persistence / keys` — segments `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`, `persistence` → `/elixir/algorithms/persistence`, current `keys` in `.rcur`.
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) / `F4.08` (→ `/elixir/algorithms/persistence`) / `keys` (`.here`).
- toc-mini: `#store` "Store the integer, brand at the edge"; `#advanced` "Advanced: eight bytes that sort themselves".
- pager: prev → `/elixir/algorithms/persistence` "F4.08 · persistence"; next → `/elixir/algorithms/persistence/sql` "Next · SQLite & PostgreSQL".
- footer: column "Chapters" — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column "The course" — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta — `<title>`: "Branded ids as keys — F4.08.1 · jonnify". `<meta description>`: "The database stores the 64-bit integer as a bigint primary key — eight bytes, numerically ordered — and the application brands it into a fourteen-character string only at the edge. An index on the integer answers a point lookup in O(log n), and because time is in the high bits the same index is clustered by creation time, which the next dive's range query rides on."

## Build instruction

To rebuild this dive, copy the `head`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the F4 sage accent — the model sibling is the companion dive `elixir/algorithms/persistence/sql.html` (same module, same single-figure `.solid-select` shell). Change only the `<title>`/`<meta description>`, the header `route-tag`, the crumbs, and the `<main>` body (the `#store` key-view figure plus its `CASES`, and the `#advanced` Ecto-schema block and bridge). No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE `Portal` facade, the Phoenix web app — so reference `Portal.Id.brand/2` exactly and keep the schema `field :id, :integer, primary_key: true`; cite the companion course for OTP internals, do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
