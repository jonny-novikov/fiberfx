# F4.09 — Branded CHAMP maps & GenServer (module hub)

- Route (served): `/elixir/algorithms/branded-champ`
- File: `/Users/jonny/dev/jonnify/elixir/algorithms/branded-champ/index.html`
- Place in the chapter: The capstone of the persistent-map spine `F4.05 -> F4.09`. It folds the chapter together — the compressed CHAMP of `F4.06`, the branded Snowflake key of `F4.07`, and the persistence of `F4.08` become one in-memory store: a CHAMP keyed by branded ids, partitioned by the three-letter namespace, owned by a GenServer. The hub frames three dives, each leaning on a different trait of that store.
- Accent: sage (the F4 · Algorithms & Data Structures chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4 · Persistent maps · module 9`

Hero `h1`: Branded CHAMP maps & `GenServer`

Lede (verbatim):

> This module folds the chapter together. Take the compressed, canonical map of F4.06, key it on the branded Snowflakes of F4.07, partition it by the three-letter namespace, and own it from a **GenServer**. The result is an in-memory store the Portal uses everywhere: immutable, so reads need no lock; structurally shared, so a snapshot is cheap; and partitioned, so each kind of record lives in its own shallow sub-trie.

Kicker (verbatim):

> The Portal runs three of these stores, all the same shape. Route a record’s id and watch the namespace prefix send it to the right partition.

## What the page frames

The hub leads into three deep dives, presented as a vertical card list under the `#uses` section. Each is a deep dive.

- `F4.09.1 · the entity registry` — **Partition by namespace** — one store holds users, sessions, lessons, and pages at once; the `USR`/`SES`/`LSN`/`PGE` prefix picks the partition, so key spaces never collide and each sub-trie stays shallow. Route `/elixir/algorithms/branded-champ/partition`. Built.
- `F4.09.2 · progress snapshots` — **Structural sharing** — marking a lesson complete copies one root-to-leaf path and shares the rest, so `Portal.Progress` keeps every prior snapshot for free and a diff is cheap. Route `/elixir/algorithms/branded-champ/trie`. Built.
- `F4.09.3 · the session store` — **Own it with a GenServer** — a GenServer owns writes and publishes each new snapshot; because the map is immutable, `Portal.Auth.current_user/1` reads it lock-free on every request. Route `/elixir/algorithms/branded-champ/genserver`. Built.

The hub also carries two teaching sections of its own: `#store` (One store, partitioned by namespace) and `#advanced` (Advanced: immutable reads, serialized writes), plus the References block.

## The interactives

### Hero figure — A GenServer owns a partitioned CHAMP

- `<figure class="hero-fig">`, labelled by `id="hpTitle"`: `A GenServer owns a partitioned CHAMP`.
- Controls: buttons `id="hpAdd"` (`▸ cast :put`) and `id="hpReset"` (`reset`).
- SVG element ids: incoming cast group `hpMsg` with body `hpMsgBody` (initial text `{:put, "USR0Nb…"}`); USR partition group `hpPart-USR` with box `hpBox-USR`, count `hpCount-USR` (`1 entry`), cells `hpCells-USR`; SES partition group `hpPart-SES` with box `hpBox-SES`, count `hpCount-SES` (`0 entries`), cells `hpCells-SES`, empty marker `hpEmpty-SES` (`%{} empty`).
- The static initial state is visible without JS: USR holds one entry (`USR0NbAb1x →`), SES is empty.
- Pure functions: `renderPartition(ns, baseX)` rebuilds a partition box (entry cells, count text, live/dim stroke); `render()` updates both partitions plus the caption; `nextSendable()` returns the next pool id whose partition is below the `CAP = 3` ceiling. The cast `POOL` is the ordered ids `SES0NbAb29FnXc`, `USR0NbWMq3Rkde`, `SES0NbWMtk7p1Z`, `USR0NbcQ8vLm0T`; the 3-char prefix routes each to its partition. `INITIAL = { USR: ['USR0NbAb1x'], SES: [] }`.
- Caption `id="hpCap"` (`aria-live="polite"`), readout strings VERBATIM:
  - `USR: 1 entry · SES: empty`
  - `The 3-letter prefix routes a put to its partition — O(1).`
  - On a cast, the message body becomes `{:put, "<first 6 chars>…"}`; entry count strings read `N entry`/`N entries`; SES empty reads `empty`.
- Degrade behaviour: no render on load — the static SVG already shows USR with one entry and SES empty. The freshly-routed entry animates via `.hp-new` (`@keyframes hpIn`), suppressed under `prefers-reduced-motion: reduce`.

### Section figure (`#store`) — Record · select one

- `<figure class="fig">`, labelled by `id="bcTitle"`: `Record · select one`.
- Control group `id="bcSel"` (`role="group"`, `aria-label="Record to route"`), four buttons:
  - `data-k="user"` `data-c="sage"` (active) — `a user`
  - `data-k="session"` `data-c="blue"` — `a session`
  - `data-k="lesson"` `data-c="gold"` — `a lesson`
  - `data-k="page"` `data-c="sage"` — `a page`
- SVG element ids: request line `bcReq` (`store.get("USR0NbAb1xcFCy")`), highlight `bcHi`, record line `bcRec` (`%User{email: "ada@portal.dev"}`), caption `bcCaption` (`the USR prefix routes to the users partition`). Four partition boxes labelled `USR`/`SES`/`LSN`/`PGE` (CHAMP · users/sessions/lessons/pages).
- Readouts: `pre.code` `id="bcCode"`, `div.geo-readout` `id="bcOut"`, partition role `id="bcRole"` (`USR · users`), created `id="bcResult"`.
- Pure function `pick(k)`: highlights the chosen partition (`set('bcHi','x',BX[e.ns])`, accent fill), updates the request, record, caption, role, and the decoded creation time via `timeOf(id)`. Fixed records `ENT` (verbatim): `user` → `USR0NbAb1xcFCy` / `users` / `%User{email: "ada@portal.dev"}`; `session` → `SES0NbAb29FnXc` / `sessions` / `%Session{user: "USR0NbAb1xcFCy"}`; `lesson` → `LSN0NbAb2Lk9GS` / `lessons` / `%Lesson{title: "Hash array mapped tries"}`; `page` → `PGE0NbWMtkolM0` / `pages` / `%Page{route: "/elixir/algorithms/hamt"}`. `BX = { USR: 44, SES: 216, LSN: 388, PGE: 566 }`.
- Readout body VERBATIM (with the selected fields substituted): `The prefix <code>USR</code> selects the <b>users</b> partition in constant time; the CHAMP there returns <code>%User{email: "ada@portal.dev"}</code>, and the id itself dates it to <timeOf(id)>.`

### Take strings (verbatim)

- `#store`: `One map of namespaces over many CHAMPs: the prefix routes in constant time, and each partition stays shallow because it holds one kind of key. The id you already have is the whole address.`

### Footer build-stamp decoder

- The footer `div.stamp` (`id="stamp"`) decodes the real build id `id="stampId"` = `TSK0Ncc9NzmOrQ` via `decodeBranded` (base-62 of the post-prefix tail, `EPOCH_MS = 1704067200000`; `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`). The decoded timestamp shown in the panel is `2026-06-01 10:28:31 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- [Steindorfer & Vinju, “Optimizing Hash-Array Mapped Tries” (OOPSLA 2015)](https://michael.steindorfer.name/publications/oopsla15.pdf) — the CHAMP this store keys by branded ids.
- [Elixir — GenServer](https://hexdocs.pm/elixir/GenServer.html) — the serialized owner of writes.
- [Erlang — persistent_term](https://www.erlang.org/doc/man/persistent_term.html) — publishing an immutable root for lock-free reads.

Related in this course:
- `/elixir/algorithms/champ` — F4.06 · CHAMP maps — the compressed map being keyed and partitioned.
- `/elixir/algorithms/identifiers` — F4.07 · Identifiers, Snowflake & branded ids — the key and its namespace.
- `/elixir/algorithms/persistence` — F4.08 · Branded ids & persistence — the same id on disk; here it is in memory.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures.

## Wiring

- route-tag: `/ elixir / algorithms / branded-champ` (last segment `branded-champ` as `.rcur`).
- crumbs: `F4 · Algorithms & Data Structures` (`/elixir/algorithms`) / `F4.09 · branded-champ` (here).
- toc-mini: `#store` (One store, partitioned by namespace), `#uses` (Three uses in the Portal), `#advanced` (Advanced: immutable reads, serialized writes).
- pager: prev → `/elixir/algorithms/persistence` (`F4.08 · persistence`); next → `/elixir/algorithms/branded-champ/partition` (`Start · partition by namespace`).
- footer columns: **Chapters** — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta:
  - `<title>`: `Branded CHAMP maps & GenServer — F4.09 · jonnify`
  - `<meta description>`: `The chapter folds together: the compressed CHAMP of F4.06, the branded Snowflake key of F4.07, and the persistence of F4.08 become one in-memory store — a CHAMP keyed by branded ids, partitioned by the three-letter namespace, owned by a GenServer. It is immutable (lock-free reads), structurally shared (cheap snapshots), and partitioned (a shallow sub-trie per kind). The Portal runs three: a session store, an entity registry, and a progress tracker.`

## Build instruction

To rebuild this hub, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure logic plus the branded decoder, and the reveal-on-scroll enhancement) verbatim from a recent built sibling on the sage F4 accent, then change only the `<title>`/`<meta description>`, the route-tag, and the `<main>` body. Keep the dark-editorial design tokens and the `.hp-*`/`.solid-select`/`.fig` shells as written. No-invent guards: use only the real Portal surfaces as written — the branded store (`Portal.Store`, partitions `:users`/`:sessions`/`:lessons`/`:pages` keyed by namespace-prefixed branded ids), `Portal.Progress`, `Portal.Auth.current_user/1`, the event-sourced engine behind one Portal facade, the Phoenix web app — and the real records (`%User{}`/`%Session{}`/`%Lesson{}`/`%Page{}`). Cite the companion course for OTP internals (GenServer, `:persistent_term`); do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously. Model sibling to copy from: `/elixir/algorithms/persistence` (the F4.08 hub, same sage accent and module-hub anatomy) or this chapter's `/elixir/algorithms/branded-champ/partition` for the dive head.
