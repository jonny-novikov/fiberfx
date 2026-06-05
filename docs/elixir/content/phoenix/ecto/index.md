# F6.03 — Ecto: schemas, changesets & queries (module hub)

- **Route (served):** `/elixir/phoenix/ecto`
- **File:** `elixir/phoenix/ecto/index.html`
- **Place in the chapter:** the F6.03 module hub inside F6 · Phoenix Framework. It is the third module of the chapter — it follows F6.02 (`/elixir/phoenix/routing`) and precedes F6.04 (contexts & domain design). The hub frames Ecto in three pieces and routes to its three deep dives: `schemas` (F6.03.1), `changesets` (F6.03.2), and `repo` (F6.03.3).
- **Accent:** F6 · Phoenix Framework, accent blue (the dive cards and SVG strokes use `--blue`/`--blue-bright`; the `h1` accent word `queries` is rendered with the course `--elixir-bright` `.ex` style shared by every chapter).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Hero eyebrow (verbatim): `F6 · the architecture · module 3`.

Hero `h1` (verbatim): `Ecto: schemas, changesets & queries` (the accent word `queries` is wrapped `<span class="ex">`).

Hero lede (`.lede`, verbatim):

> Ecto is Elixir's database toolkit, and it does its work in three clear pieces. A **schema** maps a database table to a plain Elixir struct, so a row is a `%Course{}` in your code. A **changeset** is a pure pipeline that casts and validates incoming data before any write, carrying its own `valid?` flag and errors. And the **repo** runs composable queries and persists changesets. The discipline that keeps F5 intact is where Ecto lives: **behind the engine's port** — the same `Portal.EventStore` behaviour from the F5.09 lab, now backed by its Postgres adapter — so the domain core still names no database. Ecto is an adapter detail, not a layer the Portal logic depends on.

Kicker line (`.kicker`, verbatim):

> This module covers Ecto's three pieces and the boundary that contains them: schemas and migrations, changesets and validation, and queries and the repo behind the port.

## What the page frames

This module hub does not use the `.mods` grid (that belongs to chapter landings). Instead it frames the module through two content sections and a vertical stack of three dive cards.

- **`#pieces` — "Three pieces, one adapter":** prose plus the interactive `ecSel` figure restating schema · changeset · query/repo. Takeaway (`.take`, verbatim): "Ecto is not an ORM that hides the database; it is three explicit tools you compose. And because they sit behind the F5 port, swapping the in-memory adapter for Postgres is a config change, not a rewrite of the Portal."
- **`#dives` — "Three deep dives":** the three dive cards (each an `<a>` with a colored left border), the F5.09-port `bridge`, and the closing `.note`.

The three dive cards (verbatim numbers, titles, summaries, routes):

- **F6.03.1 · Schemas & migrations** → `/elixir/phoenix/ecto/schemas` — left border `--blue` — "A migration creates the table; a schema maps it to `%Course{}`. The primary key is a Snowflake bigint we mint, not a serial." — built.
- **F6.03.2 · Changesets & validation** → `/elixir/phoenix/ecto/changesets` — left border `--gold` — "`cast` → `validate` → `%Changeset{}`: a pure pipeline that guards every write and carries its own errors." — built.
- **F6.03.3 · Queries & the repo** → `/elixir/phoenix/ecto/repo` — left border `--sage` — "Composable queries and `Repo` calls, kept behind the F5.09 port so the core never names the database." — built.

The `bridge` (verbatim): cell `idea` labeled "F5.09 · the port" — "The engine reads and appends through `Portal.EventStore`, a behaviour with two adapters." → cell `elix` labeled "F6.03 · the Postgres adapter" — "Ecto implements that port for production — schemas, changesets, and queries behind it."

Closing `.note` (verbatim): "Start with [schemas and migrations](/elixir/phoenix/ecto/schemas), then [changesets and validation](/elixir/phoenix/ecto/changesets), then [queries and the repo](/elixir/phoenix/ecto/repo). This module follows F6.02 — [routing, controllers & plugs](/elixir/phoenix/routing) — and the next, F6.04, draws the boundary between Phoenix contexts and the F5 facade."

## The interactives

### Hero figure — "The changeset pipeline" (`csTitle` / `csToggle`)

- **Markup:** a `<figure class="hero-fig" aria-labelledby="csTitle">` titled `The changeset pipeline` (label id `csTitle`). The SVG (`viewBox="0 0 320 348"`) draws a vertical chain of stages: a flow spine `line.cs-flow`, the stage group `#csStages` (groups `.cs-stage[data-stage="params|cast|validate|constraint|repo"]`), each non-terminal stage carrying a `.cs-mark` circle + a `.cs-tick` path; a status badge `#csBadge` with text `#csBadgeTxt`.
- **Control:** one `<button class="hp-btn" id="csToggle">` labeled `▸ try an invalid input` (toggles to `▸ back to a valid input`).
- **Pure logic:** an IIFE with a `STATES` dataset (`valid`, `invalid`) and a `render()` that repaints each stage (`paintStage` / `setMark`) pass/fail/skip, sets the badge, the caption `#csCap` (`paintStage` uses `pass` blue, `fail` burgundy, `skip` dimmed), and the repo terminal. No render runs on load — the static SVG already shows the valid input inserted.
- **Static `#csBadgeTxt`:** `valid?: true — row inserted`. Static `#csCap` (verbatim): list line `%{title: "Algebra", credits: 4}` then `cast → validate → constraint all pass — the Repo writes the row.`
- **Valid state strings (verbatim):** params `%{"title" => "Algebra", "credits" => 4}`; badge `valid?: true — row inserted`; cap list `%{title: "Algebra", credits: 4}`; cap `cast → validate → constraint all pass — the Repo writes the row.`
- **Invalid state strings (verbatim):** params `%{"title" => "", "credits" => 99}`; badge `valid?: false — 2 errors, no write`; cap list `%{title: "", credits: 99}`; cap `validate records two errors (title required, credits ≤ 6) — valid? is false, so the Repo never runs.`
- **Degrade:** the static markup shows the valid pipeline fully passing; the global `@media (prefers-reduced-motion: reduce)` stops the `.cs-flow` animation; no browser storage.

### Content figure — "The Ecto layer · select a piece" (`ecTitle` / `#ecSel`)

- **Markup:** a `<figure class="fig" aria-labelledby="ecTitle">` titled `The Ecto layer · select a piece`. SVG (`viewBox="0 0 720 170"`) draws three rows `#ecRow_schema`, `#ecRow_changeset`, `#ecRow_query`. Readout `.geo-readout#ecOut` (`aria-live="polite"`) plus two mono lines `#ecRole` (default `Schema`) and `#ecResult` (default `a table ↔ a struct`).
- **Control group `#ecSel`** (`role="group"`, `aria-label="Ecto piece"`), three buttons (no `data-c`):
  - `data-k="schema"` — label `schema` — starts `active`
  - `data-k="changeset"` — label `changeset`
  - `data-k="query"` — label `query`
- **Pure function:** `pick(k)` over the `PIECES` dataset, ordered by `ORDER = ['schema','changeset','query']` — toggles each `#ecSel` button's `active` class + `aria-pressed`, restrokes the matching `#ecRow_*` (active `BLUE_MUTE`/width 2/fill `#11203a`, else `#3a4263`/1.3/`#10162b`), writes `#ecRole`/`#ecResult`, and sets `#ecOut.innerHTML`. Initial call `pick('schema')`.
- **Readout strings (`PIECES`, verbatim) — `#ecOut` renders `The <name> piece — <is>. <desc>`:**
  - schema: name `Schema`, is `a table ↔ a struct`, desc `schema "courses" do ... end lists the fields of a table and produces a struct, so a row is a %Course{} you pattern-match and pass around. The primary key is a Snowflake bigint we mint ourselves.`
  - changeset: name `Changeset`, is `validate before a write`, desc `A pure pipeline: cast permits and coerces fields, validate checks the rules, and the result is a %Changeset{} carrying valid? and errors. No invalid data reaches the database.`
  - query: name `Query / Repo`, is `fetch and persist`, desc `Composable queries run through Repo.all/Repo.get; changesets persist through Repo.insert/update. The Repo lives behind the F5.09 port, so the core asks the port, not Ecto.`
- **Degrade:** controls + SVG render statically (the default `schema` row is pre-stroked blue); JS only enhances. Respects `prefers-reduced-motion`; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0NdP4KuAoKm` (in `#stampId`); panel `#st-ts` hard-codes `2026-06-01 21:53:03 UTC`.
- **Decoded:** namespace `TSK`, snowflake `319956541400678400`, node `0`, seq `0`, timestamp `2026-06-01 21:53:03 UTC` (epoch `1704067200000`). `decodeBranded(id)` splits `ns = id.slice(0,3)` and `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`. Toggles `.open` + `aria-expanded` on click / Enter / Space.

## References (#refs, verbatim)

The page carries a full `#refsTitle` "References" section (a `.reveal` section). Intro prose (verbatim): "Ecto's three pieces in reference form: the schema, the changeset, the query, and the repo."

**Sources**
- [Ecto — Schema](https://hexdocs.pm/ecto/Ecto.Schema.html) — mapping a table to a struct.
- [Ecto — Changeset](https://hexdocs.pm/ecto/Ecto.Changeset.html) — cast, validate, and constraints.
- [Ecto — Query](https://hexdocs.pm/ecto/Ecto.Query.html) — the composable query DSL.
- [Ecto — Repo](https://hexdocs.pm/ecto/Ecto.Repo.html) — running queries and persisting.

**Related in this course**
- F6.03.1 · Schemas & migrations → `/elixir/phoenix/ecto/schemas`
- F6.03.2 · Changesets & validation → `/elixir/phoenix/ecto/changesets`
- F6.03.3 · Queries & the repo → `/elixir/phoenix/ecto/repo`
- F5.09 · The engine lab → `/elixir/pragmatic/engine-lab` — the port Ecto sits behind.
- F6 · Phoenix Framework → `/elixir/phoenix`

## Wiring

- **route-tag** (verbatim, segmented): `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/phoenix">phoenix</a><span class="rsep">/</span><span class="rcur">ecto</span>` — i.e. `/ elixir / phoenix / ecto` with `ecto` as the current (non-link) segment.
- **crumbs:** `F6 · Phoenix Framework` → `/elixir/phoenix` · sep `/` · here `F6.03 · ecto` (no link).
- **toc-mini:** `#pieces` ("Three pieces, one adapter") · `#dives` ("Three deep dives").
- **pager:** prev → `/elixir/phoenix/routing` ("← F6.02 · routing, controllers & plugs"); next → `/elixir/phoenix/ecto/schemas` ("Start · schemas & migrations →").
- **footer (3-column `foot-nav`):**
  - brand: `foot-logo` → `/elixir`; `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters column links: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column links: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
  - Brand links (header `.brand`, footer `.foot-logo`) both point at `/elixir`.
- **Page meta:** `<title>` `Ecto: schemas, changesets & queries — F6.03 · jonnify`; `<meta description>` "Ecto in three pieces: a schema maps a table to a struct, a changeset validates before a write, and the repo runs queries and persists. The whole library lives behind the engine's port — the F5.09 Postgres adapter — so the domain core still names no database. Three dives: schemas and migrations, changesets and validation, and queries and the repo."

## Build instruction

To rebuild this hub, copy the `<head>`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built sibling on this F6 blue accent — the model is this page's own dive `elixir/phoenix/ecto/schemas.html` (or any F6.03 page; they share the head/header/footer/scripts) — then change only the `<title>`/`<meta description>`, the `.route-tag` current segment, and the `<main>` body. Keep the clamp spacing intact (e.g. `clamp(2.7rem,1.9rem + 4.2vw,5.1rem)` with spaces around `+`). Use only the real Portal surfaces as written: the branded store and `Portal.ID` Snowflake ids, the event-sourced engine behind the single `Portal` facade and its `Portal.EventStore` port, the closed `%Portal.Error{}` set, and the `Portal.EventStore.Postgres` Ecto adapter. Cite the companion course for OTP internals (the F5.09 engine lab) rather than re-teaching them, and invent no API not present in the live page. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
