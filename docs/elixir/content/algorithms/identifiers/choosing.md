# F4.07.1 — Choosing an identifier (dive)

- Route (served): `/elixir/algorithms/identifiers/choosing`
- File: `elixir/algorithms/identifiers/choosing.html`
- Place in the chapter: the first of three dives under the F4.07 module hub (`/elixir/algorithms/identifiers`), part 1 of 3. It opens the teaching arc — why a counter and a random UUID both fall short and a Snowflake is the answer — before `snowflake` takes the 64 bits apart and `branded` turns the integer into the portal's string.
- Accent: sage (the F4 Algorithms & Data Structures chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.07 · part 1 of 3`

Hero `h1`: Choosing an `identifier`

Hero lede (verbatim): "The first id scheme anyone reaches for is a database **counter**: 1, 2, 3. It sorts by time and it is tiny, but it needs one writer to hand out the next number, so it does not survive being split across machines. The reaction is a random **UUID**: any node can mint one with no coordination — but it is 128 bits and sorting a pile of them tells you nothing about when they were made. A **Snowflake** keeps the good half of each: coordination-free like a UUID, time-sortable like a counter."

Kicker (verbatim): "Three ids from each scheme, created in the order shown. Sort them as plain strings and see which schemes recover the original order — the property that lets a database paginate by id."

## Sections

In order:

1. `#sort` — "Does sorting recover time order?" — the teaching section, carrying the interactive figure and the takeaway.
2. `#advanced` — "Advanced: the three tradeoffs" — coordination, order, and size, with the three-way comparison code and the `.bridge` to F4.07.2.

Running example: three ids in creation order from each of three schemes — a counter `1001, 1002, 1003`; a random UUID `f47ac10b-…, 0e8400e2-…, a3bb18e0-…`; a branded Snowflake `PGE0NXh7MFjxT6, PGE0NbLeJJpTmr, PGE0NbWMtkolM0`.

Real Elixir code shown (`#advanced`, verbatim):

```
# the same three records, three ways to name them
counter   = [1001, 1002, 1003]            # ordered, but one writer only
uuid_v4   = ["f47ac10b…", "0e8400e2…", …]  # no coordination, not ordered
snowflake = [318710061465600000, …]      # ordered AND coordination-free
```

The `.bridge`: `counter · UUID` ("Each keeps one of order or coordination, and gives up the other.") → `F4.07.2 · the Snowflake` ("Packs a timestamp, a worker, and a sequence into 64 bits to keep both.").

## The interactives

### Figure — "Id scheme · select one" (`#choTitle`)

Control group `#choSel`, buttons: `data-k="sequential" data-c="blue"` (active) labelled `counter`; `data-k="uuid" data-c="gold"` labelled `random UUID`; `data-k="snowflake" data-c="sage"` labelled `Snowflake`. SVG element ids: left (created) text `choC0`/`choC1`/`choC2`; right (sorted) boxes `choBox0`/`choBox1`/`choBox2` and text `choS0`/`choS1`/`choS2`; `choVerdict`; `choCaption`. Below: `pre#choCode`, `div#choOut`, `span#choRole`, `span#choResult`.

Pure operation `pick(k)` sorts the three created ids as plain strings (`idx.sort` by string compare), tracks the permutation, and sets `matches` if `idx === [0,1,2]`. A moved row is stroked gold; a matching column sage. Verdict strings (verbatim): "sorted order == created order  ✓ time-sortable" / "sorted order != created order  ✗ not time-sortable". Caption (verbatim): "sorting these ids recovers the order they were made in" / "sorting these ids loses the order they were made in". Result: "sorted == created" / "sorted ≠ created".

- `sequential` case — role "a central counter"; out (verbatim): "A **counter** sorts back into creation order, and it is the smallest id of all. The cost is hidden: every insert has to ask one central place for the next number, so it cannot scale past a single writer."
- `uuid` case — role "a random 128-bit UUID"; out (verbatim): "A **random UUID** needs no coordination, but its bits are random, so sorting reorders them — here the second-created id sorts first. It is also 128 bits, twice a machine word."
- `snowflake` case — role "a branded Snowflake"; out (verbatim): "A **branded Snowflake** sorts back into creation order like the counter, because the timestamp is in the high bits — yet each was minted on its own worker with no shared counter. That is the combination the next dive builds."

Takeaway (verbatim): "A counter and a Snowflake both sort back into creation order; a random UUID does not. The Snowflake reaches that without a single shared writer, which is the trait the counter could not keep."

### Degrade behaviour

The SVG ships a static initial state (the two columns render as em-dashes in markup); `pick('sequential')` fills it on load. The `.reveal` scroll-in on the References section is JS-gated and disabled under `prefers-reduced-motion: reduce`; the `.arc-flow` dash animation is gated behind `prefers-reduced-motion: no-preference`.

### Footer build-stamp decoder

`div#stamp` shows `build TSK0NcYQiYPYsC`. Click/Enter/Space toggles the `.panel`; on load `decodeBranded` (base62 over `EPOCH_MS = 1704067200000`) fills namespace `TSK`, the Snowflake, node, seq, and timestamp. The static markup timestamp fallback is `2026-06-01 09:36:27 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://en.wikipedia.org/wiki/Universally_unique_identifier` — Universally unique identifier — Wikipedia — the random scheme this lesson contrasts.
- `https://www.rfc-editor.org/rfc/rfc4122` — RFC 4122 — A Universally Unique IDentifier (UUID) URN Namespace — the UUID specification.
- `https://en.wikipedia.org/wiki/Snowflake_ID` — Snowflake ID — Wikipedia — the time-ordered, coordination-free scheme.

Related in this course:
- `/elixir/algorithms/identifiers` — F4.07 · Identifiers, Snowflake & branded ids — the module hub.
- `/elixir/algorithms/maps` — F4.04 · Maps, sets & hashing — where ids become keys.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / identifiers / choosing` (the trailing `choosing` is `.rcur`; `elixir`, `algorithms`, `identifiers` are links).
- crumbs (verbatim): `F4` / `F4.07` / `choosing` (the `.here` segment).
- toc-mini: `#sort` → "Does sorting recover time order?"; `#advanced` → "Advanced: the three tradeoffs".
- pager: prev → `/elixir/algorithms/identifiers` label "F4.07 · identifiers"; next → `/elixir/algorithms/identifiers/snowflake` label "Next · the Snowflake bigint".
- footer: three columns. Chapters — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). The course — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta — `<title>`: `Choosing an identifier — F4.07.1 · jonnify`. `<meta description>`: "An auto-increment counter is ordered and tiny but needs one writer, so it cannot scale across machines; a random UUID needs no coordination but is 128-bit and not time-sortable. A Snowflake keeps order without coordination, because the timestamp sits in the high bits — sorting a set of them recovers creation order."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks verbatim from a recent built dive on the sage F4 accent (the model sibling is `elixir/algorithms/identifiers/snowflake.html`, the F4.07.2 dive). Change only the `<title>`/`<meta>`, the route-tag (append `/ choosing`), and the `<main>` body (hero with crumbs/eyebrow/lede/kicker/toc-mini, the `#sort` teaching section, the `#advanced` section, references, pager). Keep the design tokens, the `.solid-select`/`.fig`/`.geo-readout` interactive shell, the build-stamp decoder, and the reveal script unchanged. No-invent guards: use only the real surfaces as written — branded Snowflake ids over the `0-9A-Za-z` base62 alphabet, the branded store, the event-sourced engine behind the one `Portal` facade, the Phoenix web app; cite the companion course for OTP internals and do not re-teach them; the comparison ids (`1001`, the UUID strings, `318710061465600000`, the `PGE…` Snowflakes) are the page's fixed dataset, not to be invented anew. Voice rules: no first person, no exclamation marks, no emoji, and none of "just", "simply", or "obviously". Model sibling to copy from: `elixir/algorithms/identifiers/snowflake.html`.
