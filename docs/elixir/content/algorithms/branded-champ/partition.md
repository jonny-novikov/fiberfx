# F4.09.1 — Partition by namespace (dive)

- Route (served): `/elixir/algorithms/branded-champ/partition`
- File: `/Users/jonny/dev/jonnify/elixir/algorithms/branded-champ/partition.html`
- Place in the chapter: The first of three dives under the `F4.09` hub. It teaches the entity registry — one store holding users, sessions, lessons, and pages as a tiny top-level map from a three-letter namespace to a CHAMP per kind. Predecessor in the spine: `F4.08` persistence. It hands off to `trie` (structural sharing).
- Accent: sage (the F4 · Algorithms & Data Structures chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.09 · part 1 of 3 · the entity registry`

Hero `h1`: Partition by `namespace`

Lede (verbatim):

> The Portal keeps users, sessions, lessons, and pages in one in-memory registry. Rather than one CHAMP holding every kind of key, the store is a tiny top-level map from a three-letter **namespace** to a CHAMP per kind. A lookup reads the prefix it already has, picks the partition, and descends only that sub-trie — so a `USR` key never shares a node with an `LSN` key, and each partition stays shallow.

Kicker (verbatim):

> The registry, grouped. Select a namespace to see its partition and how many records it holds — counted from the same eight records.

## Sections

In order:

1. `#parts` — **Four partitions, one prefix away** (teaching section). The top-level map has one entry per namespace; selecting a namespace routes to its CHAMP and lists what it holds. The routing is a single map read on the three-character prefix. Carries the interactive figure.
2. `#advanced` — **Advanced: why not one big map**. Argues against a single combined CHAMP (deeper trie, shared nodes across kinds, no seam to act on one kind), then shows the real `partition/1` routing on the prefix and the `bridge` cell summary.

Running example: the registry's eight records across four partitions (`USR` 2 users, `SES` 1 session, `LSN` 3 lessons, `PGE` 2 pages).

Real Elixir code shown (advanced section, verbatim):

```elixir
# the store routes on the prefix, then works one partition
defp partition("USR" <> _), do: :users
defp partition("SES" <> _), do: :sessions
defp partition("LSN" <> _), do: :lessons

def get(id), do: parts |> Map.fetch!(partition(id)) |> Champ.get(id)
# one map read for the partition, then the CHAMP lookup within it
```

## The interactives

### Section figure (`#parts`) — Namespace · select one

- `<figure class="fig">`, labelled by `id="paTitle"`: `Namespace · select one`.
- Control group `id="paSel"` (`role="group"`, `aria-label="Namespace partition"`), four buttons:
  - `data-k="USR"` `data-c="sage"` (active) — `USR`
  - `data-k="SES"` `data-c="blue"` — `SES`
  - `data-k="LSN"` `data-c="gold"` — `LSN`
  - `data-k="PGE"` `data-c="sage"` — `PGE`
- SVG element ids: highlight `paHi`; the partition header `paHead` (`USR partition · 2 records`); three entry rows `paE0`/`paE1`/`paE2`; caption `paCaption` (`the USR partition holds only user records`). The four namespace boxes are labelled `USR` (`2 users`), `SES` (`1 session`), `LSN` (`3 lessons`), `PGE` (`2 pages`).
- Readouts: `pre.code` `id="paCode"`, `div.geo-readout` `id="paOut"`, partition role `id="paRole"` (`USR`), records `id="paResult"` (`2`).
- Pure function `pick(k)`: moves the highlight to the partition's x, fills the header/role/caption with the partition accent, lists up to three records, and writes the code + readout. The registry `REG` (verbatim) — eight records across four partitions:
  - `USR` (`users`, sage): `USR0NbAb1xcFCy` / `ada@portal.dev`, `USR0NbWMtkosp8` / `kit@portal.dev`.
  - `SES` (`sessions`, blue): `SES0NbAb29FnXc` / `ada · active`.
  - `LSN` (`lessons`, gold): `LSN0NbAb2Lk9GS` / `Hash array mapped tries`, `LSN0NbCMKoAopE` / `Bitmapped nodes`, `LSN0NbCiUI0Sg4` / `Structural sharing`.
  - `PGE` (`pages`, sage): `PGE0NbWMtkolM0` / `/elixir/algorithms/hamt`, `PGE0NXh7MFjxT6` / `/elixir/algorithms/champ`.
- Readout body VERBATIM (with selected fields): `The <b>USR</b> partition is a CHAMP holding <b>2</b> records — only users. No other kind of key reaches this sub-trie, so it stays shallow and can be snapshotted on its own.`
- Take string (verbatim): `The store is a map of namespaces over CHAMPs. The prefix you already hold is the routing key, so finding the right partition costs one map read and never mixes one kind of record with another.`
- Degrade behaviour: the SVG renders a static USR-selected default in markup; `pick('USR')` runs on load. No animation gated on `prefers-reduced-motion` here beyond the page-wide reveal/scroll-behaviour suppression.

### Footer build-stamp decoder

- The footer `div.stamp` (`id="stamp"`) decodes the real build id `id="stampId"` = `TSK0Ncc9OEXXcm` via `decodeBranded` (base-62 of the post-prefix tail, `EPOCH_MS = 1704067200000`). The decoded timestamp shown in the panel is `2026-06-01 10:28:31 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- [Steindorfer & Vinju, “Optimizing Hash-Array Mapped Tries” (OOPSLA 2015)](https://michael.steindorfer.name/publications/oopsla15.pdf) — the CHAMP each partition is.
- [Elixir — Map](https://hexdocs.pm/elixir/Map.html) — the tiny top-level namespace map.
- [Elixir — binary matching (`<>`)](https://hexdocs.pm/elixir/Kernel.SpecialForms.html#%3C%3E/2) — matching the prefix to route.

Related in this course:
- `/elixir/algorithms/branded-champ` — F4.09 · Branded CHAMP maps & GenServer — the module hub.
- `/elixir/algorithms/identifiers/branded` — F4.07.3 · Branded ids — where the prefix comes from.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures.

## Wiring

- route-tag: `/ elixir / algorithms / branded-champ / partition` (last segment `partition` as `.rcur`).
- crumbs: `F4` (`/elixir/algorithms`) / `F4.09` (`/elixir/algorithms/branded-champ`) / `partition` (here).
- toc-mini: `#parts` (Four partitions, one prefix away), `#advanced` (Advanced: why not one big map).
- pager: prev → `/elixir/algorithms/branded-champ` (`F4.09 · branded-champ`); next → `/elixir/algorithms/branded-champ/trie` (`Next · structural sharing`).
- footer columns: **Chapters** — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta:
  - `<title>`: `Partition by namespace — F4.09.1 · jonnify`
  - `<meta description>`: `The Portal's entity registry keeps users, sessions, lessons, and pages in one store: a tiny top-level map from a three-letter namespace to a CHAMP per kind. A lookup reads the prefix it already has, picks the partition, and descends only that sub-trie — so a USR key never shares a node with an LSN key, each partition stays shallow, and a kind can be snapshotted or evicted on its own.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure `pick`/decoder logic, and the reveal-on-scroll enhancement) verbatim from a recent built sibling on the sage F4 accent, then change only the `<title>`/`<meta description>`, the route-tag, the crumbs, and the `<main>` body. Keep the dark-editorial tokens, the `.dive`/`.bridge`/`.note`/`.solid-select`/`.fig` shells, and the `.hero-copy .lede` upright-lede override as written. No-invent guards: use only the real Portal surfaces as written — the branded store and its `:users`/`:sessions`/`:lessons`/`:pages` partitions keyed by namespace-prefixed branded ids, the `partition/1` prefix match, `Champ.get/get`, the event-sourced engine behind one Portal facade, the Phoenix web app. Cite the companion course for OTP internals; do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously. Model sibling to copy from: `/elixir/algorithms/branded-champ/trie` (the next dive in this same module, identical dive anatomy on the sage accent).
