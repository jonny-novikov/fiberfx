# F4.09.3 — Own it with a GenServer (dive)

- Route (served): `/elixir/algorithms/branded-champ/genserver`
- File: `/Users/jonny/dev/jonnify/elixir/algorithms/branded-champ/genserver.html`
- Place in the chapter: The third and closing dive under the `F4.09` hub, completing the persistent-map spine `F4.05 -> F4.09`. The Portal's session store is a CHAMP behind a GenServer: the GenServer serializes writes through its mailbox and publishes each snapshot, while reads run lock-free because the map is immutable. It follows `trie` and pages forward to the F4 chapter landing.
- Accent: sage (the F4 · Algorithms & Data Structures chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.09 · part 3 of 3 · the session store`

Hero `h1`: Own it with a `GenServer`

Lede (verbatim):

> The Portal’s session store is one of these CHAMPs behind a **GenServer**. `Portal.Auth.current_user/1` runs on every request, so reads must not queue; `start_session/1` and logout must not race. The split is clean because the map is immutable: the GenServer serializes *writes* through its mailbox and publishes each new snapshot, while *reads* traverse the published snapshot with no lock at all.

Kicker (verbatim):

> A burst of six operations against the store. Compare owning writes with a GenServer (reads stay concurrent) against routing everything through one mailbox. Select a mode.

## Sections

In order:

1. `#own` — **Reads run free, writes take a number** (teaching section). Each write goes through the GenServer one at a time and bumps the snapshot version; each read sees the latest published version without queuing. Routing reads through the mailbox too would make the process a bottleneck. Carries the interactive figure.
2. `#advanced` — **Advanced: publishing the snapshot**. The mechanism is a single published reference to the current root (in `:persistent_term` or an ETS cell); a write is a `GenServer.call` that builds the next root with structural sharing, publishes it, and replies. Closes with the `bridge` cell summary and the chapter hand-off to F4.10.

Running example: a fixed burst of six operations — `current_user/1` (read), `start_session/1` (write), `current_user/1`, `current_user/1`, `delete_session/1` (write), `current_user/1`; writes bump the published snapshot version.

Real Elixir code shown (advanced section, verbatim):

```elixir
defmodule Portal.Auth do
  use GenServer

  # read: lock-free, off the published snapshot — runs on every request
  def current_user("SES" <> _ = sid) do
    :persistent_term.get(:sessions) |> Champ.get(sid)
  end

  # write: serialized through the mailbox, publishes a new snapshot
  def handle_call({:start, sid, user}, _from, champ) do
    champ = Champ.put(champ, sid, user)
    :persistent_term.put(:sessions, champ)
    {:reply, :ok, champ}
  end
end
```

## The interactives

### Section figure (`#own`) — Edge mode · select one

- `<figure class="fig">`, labelled by `id="gsTitle"`: `Edge mode · select one`.
- Control group `id="gsSel"` (`role="group"`, `aria-label="Store mode"`), two buttons:
  - `data-k="genserver"` `data-c="sage"` (active) — `GenServer owns writes`
  - `data-k="naive"` `data-c="gold"` — `everything serialized`
- SVG element ids: row group `gsRows` (six rows built once, each `gsBox<i>` with a per-row lane `gsLane<i>`); summary line `gsSummary` (`2 writes serialized · 4 reads lock-free`).
- Readouts: `pre.code` `id="gsCode"`, `div.geo-readout` `id="gsOut"`, writes `id="gsRole"` (`2, serialized`), reads `id="gsResult"` (`4, lock-free`).
- Pure function `pick(k)`: per row, a write always reads lane `mailbox · serialized` (gold); a read reads lane `concurrent · lock-free` (sage) in `genserver` mode, or `mailbox · serialized` (gold) in `naive` mode. The fixed `OPS` burst is six operations (two writes, four reads); a write bumps `ver` and shows `-> vN`, a read shows the current `vN`.
- Readout body VERBATIM:
  - genserver mode: `With the GenServer owning writes, the <b>4 reads</b> run concurrently off the published snapshot, and only the <b>2 writes</b> serialize through the mailbox — each bumping the version the next reads observe.`
  - naive mode: `Routing everything through the GenServer serializes all <b>6</b> operations, so <code>current_user/1</code> queues behind every write. Correct, but the process becomes the bottleneck — the cost immutability lets you avoid.`
  - Summary strings: genserver → `2 writes serialized · 4 reads lock-free`; naive → `all 6 serialized through one mailbox`.
- Take string (verbatim): `A GenServer is the right owner for writes because its mailbox serializes them; it is the wrong path for reads, and immutability means reads do not need it — they walk a snapshot that no writer can disturb.`
- Degrade behaviour: the SVG carries a static `gsSummary` default (`2 writes serialized · 4 reads lock-free`); rows build and `pick('genserver')` runs on load; no figure animation gated on `prefers-reduced-motion` beyond the page-wide reveal/scroll-behaviour suppression.

### Footer build-stamp decoder

- The footer `div.stamp` (`id="stamp"`) decodes the real build id `id="stampId"` = `TSK0Ncc9OhD1lI` via `decodeBranded` (base-62 of the post-prefix tail, `EPOCH_MS = 1704067200000`). The decoded timestamp shown in the panel is `2026-06-01 10:28:31 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- [Elixir — GenServer](https://hexdocs.pm/elixir/GenServer.html) — the mailbox that serializes writes.
- [Erlang — persistent_term](https://www.erlang.org/doc/man/persistent_term.html) — publishing an immutable root for lock-free reads.
- [Elixir — Agent](https://hexdocs.pm/elixir/Agent.html) — the simpler state-owner this pattern generalizes.

Related in this course:
- `/elixir/algorithms/branded-champ/trie` — F4.09.2 · Structural sharing — why a new snapshot is cheap to publish.
- `/elixir/algorithms/persistence` — F4.08 · Branded ids & persistence — the same id on disk and at the edge.
- `/elixir/algorithms/branded-champ` — F4.09 · Branded CHAMP maps & GenServer — the module hub.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures.

## Wiring

- route-tag: `/ elixir / algorithms / branded-champ / genserver` (last segment `genserver` as `.rcur`).
- crumbs: `F4` (`/elixir/algorithms`) / `F4.09` (`/elixir/algorithms/branded-champ`) / `genserver` (here).
- toc-mini: `#own` (Reads run free, writes take a number), `#advanced` (Advanced: publishing the snapshot).
- pager: prev → `/elixir/algorithms/branded-champ/trie` (`F4.09.2 · trie`); next → `/elixir/algorithms` (`F4 · Algorithms & Data Structures`).
- footer columns: **Chapters** — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta:
  - `<title>`: `Own it with a GenServer — F4.09.3 · jonnify`
  - `<meta description>`: `The Portal's session store is a CHAMP behind a GenServer. The GenServer serializes writes through its mailbox and publishes each new snapshot; because the map is immutable, Portal.Auth.current_user/1 reads the published root lock-free on every request. Writes never race and reads never queue — the split the immutable, partitioned CHAMP makes possible.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure `pick`/decoder logic, and the reveal-on-scroll enhancement) verbatim from a recent built sibling on the sage F4 accent, then change only the `<title>`/`<meta description>`, the route-tag, the crumbs, and the `<main>` body. Keep the dark-editorial tokens, the `.dive`/`.bridge`/`.note`/`.solid-select`/`.fig` shells, and the `.hero-copy .lede` upright-lede override as written. No-invent guards: use only the real Portal surfaces as written — `Portal.Auth` with `current_user/1`, `start_session/1`, `delete_session/1`, `handle_call/3`; the session-store CHAMP keyed by `SES`-prefixed branded ids; `:persistent_term` (or an ETS cell) as the published-root mechanism; the structural sharing of the previous dive; the event-sourced engine behind one Portal facade; the Phoenix web app. Cite the companion course for OTP internals (GenServer, `:persistent_term`, Agent); do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously. Model sibling to copy from: `/elixir/algorithms/branded-champ/trie` (the prior dive in this same module, identical dive anatomy on the sage accent).
