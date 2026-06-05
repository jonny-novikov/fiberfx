# F4.09.2 — Structural sharing (dive)

- Route (served): `/elixir/algorithms/branded-champ/trie`
- File: `/Users/jonny/dev/jonnify/elixir/algorithms/branded-champ/trie.html`
- Place in the chapter: The second of three dives under the `F4.09` hub. Inside a partition, the CHAMP is a trie keyed on the lesson's Snowflake; this dive teaches how `Portal.Progress` marks a lesson complete by copying one root-to-leaf path and sharing the rest, giving free snapshots and cheap diffs. It follows `partition` and hands off to `genserver`.
- Accent: sage (the F4 · Algorithms & Data Structures chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.09 · part 2 of 3 · progress snapshots`

Hero `h1`: Structural `sharing`

Lede (verbatim):

> Inside a partition, the CHAMP is a trie keyed on the lesson’s Snowflake. `Portal.Progress` tracks which lessons a user has finished, and marking one complete does not mutate the map — it returns a new one that **shares** every sub-tree except the path to the lesson that changed. The previous snapshot stays intact and valid, so a history of progress, and a cheap diff between any two points, comes for free.

Kicker (verbatim):

> A progress trie of four lessons. Mark one complete and watch which nodes are copied and which the new snapshot shares with the old — counted from the tree itself.

## Sections

In order:

1. `#share` — **Copy one path, share the rest** (teaching section). The four lessons sit two levels down under two sub-nodes; marking one complete copies the root, the one sub-node on its path, and that leaf; everything else is shared memory. Carries the interactive figure.
2. `#advanced` — **Advanced: snapshots and diffs for free**. Holding a root *is* a snapshot; a diff is cheap because sub-trees shared by identity are equal without inspection (the F4.06 canonical-shape property). The cost of an update is the trie's depth, not its size.

Running example: a progress trie `root -> {n0 -> [L1,L2], n1 -> [L3,L4]}` keyed by lesson Snowflakes.

Real Elixir code shown (advanced section, verbatim):

```elixir
# Portal.Progress.complete/2 returns a new snapshot; the old stays valid
v1 = Progress.complete(v0, "LSN0NbCMKoAopE")   # lesson 1 done
v2 = Progress.complete(v1, "LSN0NbD94T0Qtu")   # lesson 3 done

Progress.percent_complete(v0)   # the original snapshot, unchanged
Progress.diff(v1, v2)               # cheap: only the changed path is inspected
```

## The interactives

### Section figure (`#share`) — Mark complete · select one

- `<figure class="fig">`, labelled by `id="trTitle"`: `Mark complete · select one`.
- Control group `id="trSel"` (`role="group"`, `aria-label="Lesson to mark complete"`), four buttons, all `data-c="sage"`:
  - `data-k="L1"` (active) — `lesson 1`
  - `data-k="L2"` — `lesson 2`
  - `data-k="L3"` — `lesson 3`
  - `data-k="L4"` — `lesson 4`
- SVG element ids: root `trRoot`; sub-nodes `trA` (`n0`), `trB` (`n1`); leaves `trL1`/`trL2`/`trL3`/`trL4`; root edges `trErA`/`trErB`; leaf edges `trEa1`/`trEa2`/`trEb3`/`trEb4`; caption `trCaption` (`marking L1 complete copies 3 nodes and shares 4`). A legend marks `copied` (sage stroke) vs `shared` (blue stroke).
- Readouts: `pre.code` `id="trCode"`, `div.geo-readout` `id="trOut"`, copied `id="trRole"` (`3 nodes (the path)`), shared `id="trResult"` (`4 nodes`).
- Pure function `pick(k)`: marks `root` + the leaf's parent sub-node + the leaf as copied (sage), every other node shared (blue); recolours the path edges; recomputes `nCopied` (always 3) and `nShared` (always 4). Topology maps (verbatim): `PARENT = { L1:'trA', L2:'trA', L3:'trB', L4:'trB' }`; `LESSON = { L1:'LSN0NbCMKoAopE', L2:'LSN0NbCiUI0Sg4', L3:'LSN0NbD94T0Qtu', L4:'LSN0NbDmwjVOEa' }`. Colours `COPY = '#a7c9b1'`, `SHARE = '#5a87c4'`.
- Readout body VERBATIM (with selected fields): `Marking <b>L1</b> complete copies the <b>3</b> nodes on its path (root → n0 → L1) and shares the other <b>4</b> with the previous snapshot, which still points at the old root and reads unchanged.`
- Take string (verbatim): `One update touches one path. The new snapshot is the copied path plus pointers into the old tree, so it costs a few nodes — and the old snapshot is untouched, still a valid map.`
- Degrade behaviour: the SVG renders a static L1-selected default in markup; `pick('L1')` runs on load; no figure animation gated on `prefers-reduced-motion` beyond the page-wide reveal/scroll-behaviour suppression.

### Footer build-stamp decoder

- The footer `div.stamp` (`id="stamp"`) decodes the real build id `id="stampId"` = `TSK0Ncc9OSjU80` via `decodeBranded` (base-62 of the post-prefix tail, `EPOCH_MS = 1704067200000`). The decoded timestamp shown in the panel is `2026-06-01 10:28:31 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- [Persistent data structure — Wikipedia](https://en.wikipedia.org/wiki/Persistent_data_structure) — coexisting snapshots and path copying.
- [Steindorfer & Vinju, “Optimizing Hash-Array Mapped Tries” (OOPSLA 2015)](https://michael.steindorfer.name/publications/oopsla15.pdf) — the canonical shape that makes a diff cheap.
- [Elixir — Map](https://hexdocs.pm/elixir/Map.html) — immutable updates returning a new map.

Related in this course:
- `/elixir/algorithms/hamt/sharing` — F4.05.3 · Structural sharing — the path-copy property this rides on.
- `/elixir/algorithms/champ/equality` — F4.06.3 · Canonical equality — why a snapshot diff is cheap.
- `/elixir/algorithms/branded-champ` — F4.09 · Branded CHAMP maps & GenServer — the module hub.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures.

## Wiring

- route-tag: `/ elixir / algorithms / branded-champ / trie` (last segment `trie` as `.rcur`).
- crumbs: `F4` (`/elixir/algorithms`) / `F4.09` (`/elixir/algorithms/branded-champ`) / `trie` (here).
- toc-mini: `#share` (Copy one path, share the rest), `#advanced` (Advanced: snapshots and diffs for free).
- pager: prev → `/elixir/algorithms/branded-champ/partition` (`F4.09.1 · partition`); next → `/elixir/algorithms/branded-champ/genserver` (`Next · own it with a GenServer`).
- footer columns: **Chapters** — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta:
  - `<title>`: `Structural sharing — F4.09.2 · jonnify`
  - `<meta description>`: `Inside a partition the CHAMP is keyed on the lesson's Snowflake, and Portal.Progress marks a lesson complete by returning a new map that shares every sub-tree except the path to the changed leaf. The previous snapshot stays valid, so a history of progress and a cheap diff between any two points come for free — the cost of an update is the trie's depth, not its size.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure `pick`/decoder logic, and the reveal-on-scroll enhancement) verbatim from a recent built sibling on the sage F4 accent, then change only the `<title>`/`<meta description>`, the route-tag, the crumbs, and the `<main>` body. Keep the dark-editorial tokens, the `.dive`/`.bridge`/`.note`/`.solid-select`/`.fig`/`.arc-*` shells, and the `.hero-copy .lede` upright-lede override as written. No-invent guards: use only the real Portal surfaces as written — `Portal.Progress` with `complete/2`, `percent_complete/1`, `diff/2`; the branded CHAMP keyed by lesson Snowflakes; the structural-sharing/path-copy property of F4.05 and the canonical equality of F4.06; the event-sourced engine behind one Portal facade. Cite the companion course for OTP internals; do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously. Model sibling to copy from: `/elixir/algorithms/branded-champ/partition` (the prior dive in this same module, identical dive anatomy on the sage accent).
