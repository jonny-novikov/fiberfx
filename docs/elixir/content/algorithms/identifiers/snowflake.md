# F4.07.2 — The Snowflake bigint (dive)

- Route (served): `/elixir/algorithms/identifiers/snowflake`
- File: `elixir/algorithms/identifiers/snowflake.html`
- Place in the chapter: the second of three dives under the F4.07 module hub (`/elixir/algorithms/identifiers`), part 2 of 3. It takes the integer the previous dive (`choosing`) chose and shows how the 64 bits are laid out and read; the next dive (`branded`) turns that integer into the portal's url-safe string.
- Accent: sage (the F4 Algorithms & Data Structures chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.07 · part 2 of 3`

Hero `h1`: The Snowflake `bigint`

Hero lede (verbatim): "A Snowflake is one 64-bit integer with three fields packed into it: the high **42 bits** are a millisecond timestamp counted from a custom epoch, the next **10 bits** name the worker that minted it, and the low **12 bits** are a sequence that disambiguates ids made in the same millisecond by the same worker. Reading a field is one shift and one mask — no parsing, no lookup."

Kicker (verbatim): "One real Snowflake, `319545566822428714`. Select a field and watch it get extracted with the actual shift and mask, computed on this page."

## Sections

In order:

1. `#bits` — "Three fields in 64 bits" — the teaching section, carrying the field-extraction interactive and the takeaway.
2. `#advanced` — "Advanced: epoch, headroom, and limits" — the custom epoch, the headroom maths, and why high-bit time gives natural sort order, with the three-line extract code and the `.bridge` to F4.07.3.

Running example: the single 64-bit Snowflake `319545566822428714`, whose layout is `timestamp << 22 | worker << 12 | sequence`, decoded against the custom epoch `2024-01-01 00:00:00 UTC` (= `1_704_067_200_000`).

Real Elixir code shown (`#advanced`, verbatim):

```
import Bitwise
# EchoData.Snowflake.extract/1, in three lines
timestamp = (snowflake >>> 22) + 1_704_067_200_000
worker    = (snowflake >>> 12) &&& 0x3FF   # 10 bits → 0..1023
sequence  =  snowflake &&& 0xFFF          # 12 bits → 0..4095
```

The `.bridge`: `F4.07.2 · a 64-bit integer` ("Time, worker, and sequence packed tight, read with shifts and masks.") → `F4.07.3 · the branded string` ("That integer, base62-encoded and namespaced, becomes the id the portal hands out.").

## The interactives

### Figure — "Field · select one" (`#snwTitle`)

Control group `#snwSel`, buttons: `data-k="timestamp" data-c="sage"` (active) labelled `timestamp`; `data-k="worker" data-c="blue"` labelled `worker`; `data-k="sequence" data-c="gold"` labelled `sequence`. SVG element ids: highlight rect `snwHi`; field rects `snwT` (timestamp), `snwW` (worker), `snwS` (sequence); expression text `snwExpr`; value text `snwVal`; `snwCaption`. Below: `pre#snwCode`, `div#snwOut`, `span#snwRole`, `span#snwResult`.

Pure computation (in JS, on load): `var SNOW = 319545566822428714n`, `EPOCH_MS = 1704067200000`; `TS = SNOW >> 22n`, `WORKER = (SNOW >> 12n) & 0x3FFn`, `SEQ = SNOW & 0xFFFn`; the timestamp formats to `2026-05-31 18:40:00 UTC`. `pick(k)` swaps the highlight, the expression, and the value for the chosen field.

- `timestamp` case — expr "timestamp = (snowflake >>> 22) + epoch"; caption (verbatim): "the high 42 bits are a millisecond timestamp"; role "the high 42 bits"; result "2026-05-31 18:40:00 UTC"; out (verbatim): "The high **42 bits** shifted down are `<TS>` milliseconds past the 2024 epoch — **2026-05-31 18:40:00 UTC**. The time is read with one shift and one add." (`<TS>` is the computed `SNOW >> 22n`.)
- `worker` case — expr "worker = (snowflake >>> 12) &&& 0x3FF"; value "= `<WORKER>`  (0..1023)"; caption (verbatim): "the next 10 bits name the worker that minted it"; role "the middle 10 bits"; result "worker `<WORKER>`"; out (verbatim): "The middle **10 bits** are the worker id — here `<WORKER>`. Up to 1024 workers can mint ids at once, each owning its own sequence, so no two coordinate."
- `sequence` case — expr "sequence = snowflake &&& 0xFFF"; value "= `<SEQ>`  (0..4095)"; caption (verbatim): "the low 12 bits disambiguate ids in the same millisecond"; role "the low 12 bits"; result "sequence `<SEQ>`"; out (verbatim): "The low **12 bits** are the per-millisecond sequence — here `<SEQ>`. A worker can mint 4096 ids in one millisecond before it waits for the clock to tick." (`<WORKER>` and `<SEQ>` are the computed masked fields of `319545566822428714`.)

Takeaway (verbatim): "Three fields, one integer, one machine word. Every read is a shift and a mask, so extracting the time, the worker, or the sequence costs the same as comparing two numbers."

### Degrade behaviour

The SVG ships a static initial state for the `timestamp` field (`snwExpr` = "timestamp = (snowflake >>> 22) + epoch", `snwVal` = "= 2026-05-31 18:40:00 UTC"), filled in markup before JS runs; `pick('timestamp')` confirms it on load. The `.reveal` scroll-in is JS-gated and disabled under `prefers-reduced-motion: reduce`; the `.arc-flow` animation is gated behind `prefers-reduced-motion: no-preference`.

### Footer build-stamp decoder

`div#stamp` shows `build TSK0NcYQisqgEq`. Click/Enter/Space toggles the `.panel`; on load `decodeBranded` (base62 over `EPOCH_MS = 1704067200000`) fills namespace `TSK`, the Snowflake, node, seq, and timestamp. The static markup timestamp fallback is `2026-06-01 09:36:27 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://en.wikipedia.org/wiki/Snowflake_ID` — Snowflake ID — Wikipedia — the 64-bit field layout and epoch.
- `https://discord.com/developers/docs/reference#snowflakes` — Discord — Snowflakes (developer reference) — a public spec with the exact shifts and masks.
- `https://github.com/twitter-archive/snowflake/tree/snowflake-2010` — Twitter Snowflake (archived source, 2010) — the original timestamp-worker-sequence packing.

Related in this course:
- `/elixir/algorithms/identifiers` — F4.07 · Identifiers, Snowflake & branded ids — the module hub.
- `/elixir/algorithms/maps` — F4.04 · Maps, sets & hashing — where the integer is hashed to a slot.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / identifiers / snowflake` (the trailing `snowflake` is `.rcur`; `elixir`, `algorithms`, `identifiers` are links).
- crumbs (verbatim): `F4` / `F4.07` / `snowflake` (the `.here` segment).
- toc-mini: `#bits` → "Three fields in 64 bits"; `#advanced` → "Advanced: epoch, headroom, and limits".
- pager: prev → `/elixir/algorithms/identifiers/choosing` label "F4.07.1 · choosing"; next → `/elixir/algorithms/identifiers/branded` label "Next · branded ids".
- footer: three columns. Chapters — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). The course — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta — `<title>`: `The Snowflake bigint — F4.07.2 · jonnify`. `<meta description>`: "A Snowflake packs three fields into 64 bits: a 42-bit millisecond timestamp from a custom 2024 epoch, a 10-bit worker id, and a 12-bit per-millisecond sequence. Each field is read with one shift and one mask, and because time is in the high bits the integer's natural order is time order."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks verbatim from a recent built dive on the sage F4 accent (the model sibling is `elixir/algorithms/identifiers/branded.html`, the F4.07.3 dive). Change only the `<title>`/`<meta>`, the route-tag (append `/ snowflake`), and the `<main>` body (hero, the `#bits` teaching section, the `#advanced` section, references, pager). Keep the design tokens, the `.solid-select`/`.fig`/`.geo-readout` shell, the build-stamp decoder, and the reveal script unchanged. No-invent guards: use only the real surfaces as written — `EchoData.Snowflake.extract/1`, the `timestamp << 22 | worker << 12 | sequence` layout, the custom epoch `1_704_067_200_000`, the branded store, the event-sourced engine behind the one `Portal` facade, the Phoenix web app; cite the companion course for OTP internals (and `Bitwise`/BEAM integer semantics) and do not re-teach them; the example Snowflake `319545566822428714` is the page's fixed value, decoded on the page rather than invented. Voice rules: no first person, no exclamation marks, no emoji, and none of "just", "simply", or "obviously". Model sibling to copy from: `elixir/algorithms/identifiers/branded.html`.
