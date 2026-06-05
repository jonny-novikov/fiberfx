# F4.07 — Identifiers, Snowflake & branded ids (module hub)

- Route (served): `/elixir/algorithms/identifiers`
- File: `elixir/algorithms/identifiers/index.html`
- Place in the chapter: module 7 of the 12-module F4 chapter, and the centre of the persistent-map spine `F4.05 → F4.09`. It frames the id that every other module's keys are built on: the page registry of `F4.04` keys `%Page{}` rows by one, the tries of `F4.05`/`F4.06` hash it, and `F4.09` keys a branded CHAMP on it. The hub frames three dives — choosing an identifier, the Snowflake bigint, branded ids.
- Accent: sage (the F4 Algorithms & Data Structures chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4 · Persistent maps · module 7`

Hero `h1`: Identifiers, Snowflake & branded `ids`

Hero lede (verbatim): "Every row in F4.04's page registry, every user and session in the portal, needs a name. A database counter (1, 2, 3…) names them in one place, but the moment two machines mint ids at once it breaks. A **Snowflake** answers that: a 64-bit integer that carries its own millisecond timestamp, the worker that made it, and a per-millisecond sequence — sortable by time and unique without a central counter. A **branded id** wraps it for the outside world: a three-letter namespace and a base62 encoding, e.g. `TSK0KHTOWnGLuC`."

Kicker (verbatim): "This is the id behind every other module's keys: the registry of F4.04 keys `%Page{}` rows by one, the trie of F4.05/F4.06 hashes it, and F4.09 keys a branded CHAMP on it. The build stamp at the foot of every page in this course is one of these."

## What the page frames

The hub carries one in-page interactive section (`#anatomy`) plus the `#dives` directory and an `#advanced` section. The three dives, in order:

- F4.07.1 — Choosing an identifier — "From an auto-increment counter to a random UUID to a Snowflake: which properties each one keeps, and which it gives up." Route `/elixir/algorithms/identifiers/choosing`. Built.
- F4.07.2 — The Snowflake bigint — "A 64-bit integer split into a 42-bit timestamp, a 10-bit worker, and a 12-bit sequence, read with shifts and masks." Route `/elixir/algorithms/identifiers/snowflake`. Built.
- F4.07.3 — Branded ids — "A namespace prefix and a base62 encoding turn the integer into a compact, url-safe, self-describing string." Route `/elixir/algorithms/identifiers/branded`. Built.

The `#advanced` section ("Advanced: the five W's of an id") shows the canonical mint-then-brand code:

```
snowflake = EchoData.Snowflake.generate(worker_id: 7)
# => 274557032793636864  (a 64-bit integer; time-ordered)
branded   = "TSK" <> EchoData.Base62.encode(snowflake)
# => "TSK0KHTOWnGLuC"  (3-char namespace + 11-char base62)
```

A `.bridge` closes the section: `F4.04–F4.06 · the key` ("A map hashes a key into a trie; the key was treated as opaque.") → `F4.07 · the id itself` ("That key is a branded Snowflake — a timestamped, namespaced, coordination-free integer.").

## The interactives

### Hero figure — "A Snowflake is 64 bits" (`#hpTitle`)

A `figure.hero-fig` drawing the 64-bit bit-layout as four labelled fields: a 1-bit unused sign bit, a 41-bit timestamp, a 10-bit machine id (element `hpNodeBits`), and a 12-bit sequence (`hpSeqBits`, box `hpSeqBox`). The composition arrow reads `↓ (ts << 22) | (machine << 12) | seq`. Decimal id element `hpDec` shows `274557032793636864`; branded fields show `TSK` + `hpBranded` = `0KHTOWnGLuC`; `hpDecoded` shows `2026-01-27 15:11:37 UTC · worker 0 · sequence 0`; timestamp bits element `hpTsBits` shows `ms since epoch` statically.

- Controls: `button#hpMint` labelled `▸ mint next id`; `button#hpReset` labelled `reset`.
- Pure functions: `b62enc(n)` (BigInt → base62), `pad11(s)` (left-pad to 11), `fmt(tsMs)` (ms-since-epoch → UTC string), and `render(flash)` recomputing `snow = (ts << 22n) | (WORKER << 12n) | seq`. `WORKER = 0n`, `SEQ_MAX = 0xFFFn`, `EPOCH_MS = 1704067200000`. `BASE = 274557032793636864n`.
- Behaviour: mint advances the 12-bit sequence within the millisecond; on overflow (`seq >= SEQ_MAX`) it resets `seq = 0n` and ticks `ts = ts + 1n`. Reset returns to `ts = BASE_TS, seq = 0n` — the static example.
- Readout `#hpCap` (verbatim): "`TSK0KHTOWnGLuC` · seq `0`" then on the next line "Mint advances the sequence within the millisecond; on overflow the timestamp ticks."

### Anatomy figure — "What to read · select one" (`#idnTitle`)

Control group `#idnSel`, buttons: `data-k="namespace" data-c="sage"` (active) labelled `namespace`; `data-k="payload" data-c="blue"` labelled `base62 payload`; `data-k="decoded" data-c="gold"` labelled `decode it`. SVG element ids: `idnNsHi`, `idnPayHi` (highlight rects), `idnDec` (the decode group), `idnCaption`. Below: `pre#idnCode`, `div#idnOut`, `span#idnRole`, `span#idnResult`. The real branded id decoded is `var ID = "TSK0KHTOWnGLuC"`; `var EPOCH_MS = 1704067200000`. Pure function `decode(id)` slices the 3-char namespace and `b62dec`s the payload to the Snowflake `274557032793636864`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn` → `2026-01-27 15:11:37 UTC`, node `0`, seq `0`.

- `namespace` case — caption (verbatim): "TSK names the entity; the rest is a base62 Snowflake"; role "the namespace names the entity"; result "TSK · task"; out (verbatim): "The **namespace** `TSK` names the kind of thing this id refers to. A service can route or validate on it without decoding the payload at all."
- `payload` case — caption "eleven base62 characters encode a 64-bit integer"; role "the payload is a base62 Snowflake"; result "base62 → 64-bit integer"; out (verbatim): "The **payload** `0KHTOWnGLuC` is base62 over `0-9A-Za-z`, eleven characters wide — enough for any 64-bit value, and url-safe with no padding characters."
- `decoded` case — caption "the integer splits into timestamp, worker, and sequence"; role "decoded: when, where, which"; result "snowflake → 2026-01-27 15:11:37 UTC"; out (verbatim): "Decoding the payload (in this page's JS) gives the Snowflake `274557032793636864`: a timestamp of **2026-01-27 15:11:37 UTC**, worker `0`, sequence `0`. No `created_at` column needed."

Takeaway (verbatim): "One string carries a type and a timestamped, coordination-free integer. A service can route on the first three characters and never decode the rest; a database can store the integer and sort by it."

### Degrade behaviour

Both figures ship a static initial state in the markup (the bit diagram and one decoded example are visible without JS; the anatomy SVG renders the `namespace` state). The hero figure's `.hp-flash` mint animation and the `.arc-flow` dash animation are gated behind `prefers-reduced-motion: no-preference`; under reduced motion they do not animate. The `.reveal` scroll-in is JS-gated and disabled under reduced motion.

### Footer build-stamp decoder

`div#stamp` shows `build TSK0NcYQiCGqjA`. Click/Enter/Space toggles the `.panel` open; on load `decodeBranded` fills namespace, snowflake, node, seq, timestamp from the id. The static markup timestamp fallback is `2026-06-01 09:36:27 UTC`; decoding `TSK0NcYQiCGqjA` (base62 over `EPOCH_MS = 1704067200000`) recovers that build's namespace `TSK`, its Snowflake, node, sequence, and UTC timestamp.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://en.wikipedia.org/wiki/Snowflake_ID` — Snowflake ID — Wikipedia — the 64-bit id layout and its history.
- `https://github.com/twitter-archive/snowflake/tree/snowflake-2010` — Twitter Snowflake (archived source, 2010) — the original generator that named the scheme.
- `https://discord.com/developers/docs/reference#snowflakes` — Discord — Snowflakes (developer reference) — a practical, public bit-layout spec.
- `https://en.wikipedia.org/wiki/Base62` — Base62 — Wikipedia — the compact, url-safe encoding for the branded form.

Related in this course:
- `/elixir/algorithms/maps` — F4.04 · Maps, sets & hashing — the registry these ids key.
- `/elixir/algorithms/hamt` — F4.05 · Hash array mapped tries — the trie that hashes the id.
- `/elixir/algorithms/champ` — F4.06 · CHAMP maps — the compressed successor F4.09 keys on these.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / identifiers` (the trailing `identifiers` segment is the current `.rcur`; `elixir` and `algorithms` are links).
- crumbs (verbatim): `F4 · Algorithms & Data Structures` / `F4.07 · identifiers` (the `.here` segment).
- toc-mini: `#anatomy` → "The anatomy of a branded id"; `#dives` → "Three deep dives"; `#advanced` → "Advanced: the five W's of an id".
- pager: prev → `/elixir/algorithms/champ` label "F4.06 · champ"; next → `/elixir/algorithms/identifiers/choosing` label "Start · choosing an identifier".
- footer: three columns. Chapters — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). The course — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand column tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta — `<title>`: `Identifiers, Snowflake & branded ids — F4.07 · jonnify`. `<meta description>`: "Every record in the portal needs a name. A database counter breaks across machines; a random UUID is large and unsortable. A Snowflake is a 64-bit integer carrying its own millisecond timestamp, a worker id, and a sequence — sortable by time, unique without coordination — and a branded id wraps it as a namespaced, base62 string like TSK0KHTOWnGLuC. It is the id behind every other module's keys."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks verbatim from a recent built sibling on the sage F4 accent (the model sibling is `elixir/algorithms/champ/index.html`, the F4.06 module hub). Change only the `<title>` and `<meta name="description">`, the route-tag (`elixir / algorithms / identifiers`), and the `<main>` body (hero, `#anatomy`, `#dives`, `#advanced`, references, pager). Keep the design tokens, the `.mod`/`.dives` directory shell, the build-stamp decoder, and the reveal/scroll script unchanged. No-invent guards: cite only the real Portal/EchoData surfaces as written — `EchoData.Snowflake.generate/1`, `EchoData.Base62.encode/1` and `.decode/1`, the branded store, the event-sourced engine behind the one `Portal` facade, the Phoenix web app; cite the companion course for OTP internals and do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, and none of "just", "simply", or "obviously". Model sibling to copy from: `elixir/algorithms/champ/index.html`.
