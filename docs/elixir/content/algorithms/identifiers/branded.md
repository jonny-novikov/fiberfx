# F4.07.3 — Branded ids (dive)

- Route (served): `/elixir/algorithms/identifiers/branded`
- File: `elixir/algorithms/identifiers/branded.html`
- Place in the chapter: the third and last of three dives under the F4.07 module hub (`/elixir/algorithms/identifiers`), part 3 of 3. It closes the teaching arc — the integer chosen in `choosing` and dissected in `snowflake` is dressed for the outside world as a namespaced, base62 string — and hands forward to F4.08 (persistence) and F4.09 (the branded CHAMP keyed by these ids).
- Accent: sage (the F4 Algorithms & Data Structures chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.07 · part 3 of 3`

Hero `h1`: Branded `ids`

Hero lede (verbatim): "A 64-bit integer is right for a database column, but awkward in a URL, a log line, or a support ticket. A **branded id** dresses it for the outside: encode the integer in **base62** — the alphabet `0-9A-Za-z`, url-safe with no punctuation — left-pad it to eleven characters, and prepend a three-letter **namespace**. The result is `PGE0NbWMtkosp8`: self-describing, compact, and still sortable."

Kicker (verbatim): "One Snowflake, `319545566822428714`, taken through encode → brand → decode. Every step is computed on this page."

## Sections

In order:

1. `#brand` — "Integer to branded string" — the teaching section, carrying the encode/brand/decode interactive and the takeaway.
2. `#advanced` — "Advanced: why base62, and why the order survives" — why base62 over base64, why fixed-width left-padding preserves lexical = numeric = time order, with the encode/brand/decode code and the `.bridge` to F4.08–F4.09.

Running example: the Snowflake `319545566822428714` encoded to base62 `0NbWMtkosp8`, branded with the `PGE` namespace to `PGE0NbWMtkosp8`, and decoded back round-trip. Namespace `var NS = "PGE"`, `EPOCH_MS = 1704067200000`.

Real Elixir code shown (`#advanced`, verbatim):

```
# EchoData.Base62 — alphabet "0-9A-Za-z", width 11
EchoData.Base62.encode(319545566822428714)
# => "0NbWMtkosp8"

branded = "PGE" <> "0NbWMtkosp8"        # => "PGE0NbWMtkosp8"
EchoData.Base62.decode(String.slice(branded, 3, 11))
# => {:ok, 319545566822428714}
```

The `.bridge`: `F4.07 · a branded id` ("A namespaced, base62 string over a time-ordered 64-bit integer.") → `F4.08–F4.09 · keys` ("The id becomes a database key, then a key in a branded CHAMP partitioned by namespace.").

## The interactives

### Figure — "Step · select one" (`#brdTitle`)

Control group `#brdSel`, buttons: `data-k="encode" data-c="blue"` (active) labelled `encode`; `data-k="brand" data-c="sage"` labelled `brand`; `data-k="decode" data-c="gold"` labelled `decode`. SVG element ids: row rects `brdR1` (snowflake), `brdR2` (base62), `brdR3` (branded); the base62 payload text `brdB62`; `brdCaption`. Below: `pre#brdCode`, `div#brdOut`, `span#brdRole`, `span#brdResult`.

Pure functions (computed once on load): `b62encode(n)` (BigInt → 11-char left-padded base62), `b62decode(s)` (base62 → BigInt), `pad2(x)`. `SNOW = 319545566822428714n`; `PAY = b62encode(SNOW)` = `"0NbWMtkosp8"`; `BRANDED = NS + PAY` = `"PGE0NbWMtkosp8"`; `BACK = b62decode(PAY)` round-trips to `SNOW`; `TSTR` formats to the timestamp. The SVG payload text is filled from the computed `PAY` (`txt('brdB62', PAY)`).

- `encode` case — caption (verbatim): "base62 turns the 64-bit integer into eleven url-safe characters"; role "integer to base62"; result `0NbWMtkosp8`; out (verbatim): "Encoding the integer in **base62** gives `0NbWMtkosp8` — 11 characters from `0-9A-Za-z`, no padding, safe to drop straight into a URL."
- `brand` case — caption (verbatim): "a three-letter namespace is prepended to name the entity"; role "prepend the namespace"; result `PGE0NbWMtkosp8`; out (verbatim): "Prepending the **namespace** `PGE` gives `PGE0NbWMtkosp8`. The prefix names the kind of record and is shared by every id of that kind, so it never disturbs the sort order."
- `decode` case — caption (verbatim): "strip the prefix, decode the rest, recover the integer and its time"; role "branded back to integer"; result `319545566822428714 · <TSTR>`; out (verbatim): "Decoding (in this page's JS) round-trips exactly: `PGE0NbWMtkosp8` → `319545566822428714`, whose timestamp is **<TSTR>**. The branding was lossless." (`<TSTR>` is the computed UTC timestamp of the decoded Snowflake.)

Takeaway (verbatim): "A branded id is a lossless skin over an integer: encode and prefix on the way out, strip and decode on the way in. The database keeps the 64-bit number; everyone else sees a tidy string."

### Degrade behaviour

The SVG ships a static initial state: the snowflake row, the base62 row (`brdB62` = `0NbWMtkosp8`), and the branded row (`PGE` + `0NbWMtkosp8`) render in markup; on load `txt('brdB62', PAY)` confirms the payload from the computed value and `pick('encode')` highlights the first step. The `.reveal` scroll-in is JS-gated and disabled under `prefers-reduced-motion: reduce`; the `.arc-flow` animation is gated behind `prefers-reduced-motion: no-preference`.

### Footer build-stamp decoder

`div#stamp` shows `build TSK0NcYQjDHnbU`. Click/Enter/Space toggles the `.panel`; on load `decodeBranded` (base62 over `EPOCH_MS = 1704067200000`) fills namespace `TSK`, the Snowflake, node, seq, and timestamp. The static markup timestamp fallback is `2026-06-01 09:36:27 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://en.wikipedia.org/wiki/Base62` — Base62 — Wikipedia — the `0-9A-Za-z` encoding used for the branded form.
- `https://www.rfc-editor.org/rfc/rfc4648` — RFC 4648 — The Base16, Base32, and Base64 Data Encodings — the base64 alphabet base62 trims for url-safety.
- `https://en.wikipedia.org/wiki/Snowflake_ID` — Snowflake ID — Wikipedia — the integer being encoded.

Related in this course:
- `/elixir/algorithms/identifiers` — F4.07 · Identifiers, Snowflake & branded ids — the module hub.
- `/elixir/algorithms/champ` — F4.06 · CHAMP maps — the map F4.09 keys on these branded ids.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / identifiers / branded` (the trailing `branded` is `.rcur`; `elixir`, `algorithms`, `identifiers` are links).
- crumbs (verbatim): `F4` / `F4.07` / `branded` (the `.here` segment).
- toc-mini: `#brand` → "Integer to branded string"; `#advanced` → "Advanced: why base62, and why the order survives".
- pager: prev → `/elixir/algorithms/identifiers/snowflake` label "F4.07.2 · snowflake"; next → `/elixir/algorithms` label "F4 · Algorithms & Data Structures".
- footer: three columns. Chapters — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). The course — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta — `<title>`: `Branded ids — F4.07.3 · jonnify`. `<meta description>` (verbatim): "A branded id encodes the 64-bit Snowflake in base62 over 0-9A-Za-z, left-pads it to eleven characters, and prepends a three-letter namespace, e.g. PGE0NbWMtkosp8. It is url-safe, self-describing, lossless to decode, and order-preserving — the fixed width keeps lexical order equal to numeric order, which is time order."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks verbatim from a recent built dive on the sage F4 accent (the model sibling is `elixir/algorithms/identifiers/snowflake.html`, the F4.07.2 dive). Change only the `<title>`/`<meta>`, the route-tag (append `/ branded`), and the `<main>` body (hero, the `#brand` teaching section, the `#advanced` section, references, pager). Keep the design tokens, the `.solid-select`/`.fig`/`.geo-readout` shell, the build-stamp decoder, and the reveal script unchanged. No-invent guards: use only the real surfaces as written — `EchoData.Base62.encode/1` and `.decode/1` over the `0-9A-Za-z` alphabet at width 11, the three-letter namespace convention (`PGE`, `TSK`), the branded store, the event-sourced engine behind the one `Portal` facade, the Phoenix web app; cite the companion course for OTP internals and do not re-teach them; the Snowflake `319545566822428714`, its payload `0NbWMtkosp8`, and the branded `PGE0NbWMtkosp8` are computed on the page (round-tripped), not invented. Voice rules: no first person, no exclamation marks, no emoji, and none of "just", "simply", or "obviously". Model sibling to copy from: `elixir/algorithms/identifiers/snowflake.html`.
