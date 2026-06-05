# F6.03.3 — Queries & the repo (dive)

- **Route (served):** `/elixir/phoenix/ecto/repo`
- **File:** `elixir/phoenix/ecto/repo.html`
- **Place in the chapter:** the third and last of the F6.03 (Ecto) dives, after F6.03.1 (schemas) and F6.03.2 (changesets). It closes the Ecto arc: a query is composable data, the repo is the one module that executes, and the repo lives behind the F5.09 `Portal.EventStore` port — completing F6.03 and handing forward to F6.04 (contexts & domain design).
- **Accent:** F6 · Phoenix Framework, accent blue (the selected SVG rows, the port-boundary diagram, and the `Ecto.Query`/`Repo`/`Portal.EventStore` code tokens use `--blue`/`--blue-bright`; the `h1` accent word `repo` is the course `.ex` style).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Hero eyebrow (verbatim): `F6.03 · part 3 of 3`.

Hero `h1` (verbatim): `Queries & the repo` (accent word `repo` wrapped `<span class="ex">`).

Hero lede (`.lede`, verbatim):

> Ecto splits describing a question from asking it. A **query** is data — a value built with the `from` DSL that you can pass around and compose, adding a `where` or an `order_by` to an existing query without running anything. The **repo** is the one module that executes: `Repo.all` runs a query, `Repo.get` fetches one row by its Snowflake id, and `Repo.insert` persists a changeset. The architectural point is where the repo sits: **behind the engine's port**. The domain core from F5 reads and appends through the `Portal.EventStore` behaviour, and the Postgres adapter is the only module that calls `Repo` — so swapping in-memory for Postgres is a config change, and the Portal logic never imports Ecto.

Kicker line (`.kicker`, verbatim):

> See the three repo operations, then the boundary that keeps Ecto on the far side of the port, then a composable query and the adapter that implements the F5.09 behaviour.

## Sections

The dive runs two teaching sections plus the code section, in order:

1. **`#ops` — "Three repo operations":** prose plus the interactive `rpSel` figure (`Repo.get` · `Repo.all` · `Repo.insert`). Takeaway (`.take`, verbatim): "A query is a value; the repo is the only thing that runs it. That split is what lets you build a query in one function, test it without a database, and execute it somewhere else entirely."
2. **`#boundary` — "Ecto sits behind the port":** prose plus a static SVG drawing `domain → port → adapter → database` (DOMAIN CORE "no Ecto" → PORT "EventStore behaviour" → POSTGRES ADAPTER "Ecto + Repo here" → DATABASE "Postgres", with "the seam" between port and adapter). Takeaway (`.take`, verbatim): "This is the F5.09 port paying off. The database is the most replaceable detail in the system, and the port is why — the engine asked for "append" and "read," not for Postgres."
3. **`#code` — "A query and the adapter":** prose then the `pre.code` block (below), the `bridge`, and the closing `.note`.

**Running example:** the `published/1` composable query and the `Portal.EventStore.Postgres` adapter implementing `append/2` and `read_stream/1` from the F5.09 behaviour.

**Real Elixir shown (`pre.code`, verbatim):**

```elixir
import Ecto.Query

# a composable query — data, not execution
def published(query \\ Course), do: from c in query, where: c.published == true

Repo.all(published())                                  # run the query
Repo.all(from c in published(), order_by: [desc: c.inserted_at])  # compose
Repo.get(Course, "CRS0KHTOWnGLuC")                      # one row by Snowflake id

# Ecto lives behind the engine's port — the F5.09 Postgres adapter
defmodule Portal.EventStore.Postgres do
  @behaviour Portal.EventStore
  import Ecto.Query

  @impl true
  def append(stream, events), do: Repo.insert_all(Event, rows_for(stream, events))

  @impl true
  def read_stream(stream) do
    {:ok, Repo.all(from e in Event, where: e.stream == ^stream, order_by: e.seq)}
  end
end
```

The `bridge` (verbatim): cell `idea` labeled "a query is data" — "Built with `from`, composed freely, and run only by the repo." → cell `elix` labeled "the repo is the adapter" — "`Repo` appears only in the Postgres adapter behind the F5.09 port."

Closing `.note` (verbatim): "That completes F6.03. Ecto is wired as an adapter, not a dependency of the core. The next module, **F6.04 — Contexts & domain design**, draws the boundary between Phoenix contexts and the F5 facade. Back to [the module overview](/elixir/phoenix/ecto) or the [F6 chapter](/elixir/phoenix)."

## The interactives

### Figure — "Repo operations · select one" (`rpTitle` / `#rpSel`)

- **Markup:** a `<figure class="fig" aria-labelledby="rpTitle">` titled `Repo operations · select one`. SVG (`viewBox="0 0 720 170"`) draws three rows `#rpRow_get`, `#rpRow_all`, `#rpRow_insert`. Readout `.geo-readout#rpOut` (`aria-live="polite"`) plus mono lines `#rpRole` (default `Repo.get`) and `#rpResult` (default `one row by id`).
- **Control group `#rpSel`** (`role="group"`, `aria-label="Repo operation"`), three buttons (no `data-c`):
  - `data-k="get"` — label `Repo.get` — starts `active`
  - `data-k="all"` — label `Repo.all`
  - `data-k="insert"` — label `Repo.insert`
- **Pure function:** `pick(k)` over the `OPS` dataset, `ORDER = ['get','all','insert']` — toggles each `#rpSel` button's `active` + `aria-pressed`, restrokes the matching `#rpRow_*` (active `BLUE_MUTE`/2/`#11203a`, else `#3a4263`/1.3/`#10162b`), writes `#rpRole`/`#rpResult`, sets `#rpOut.innerHTML`. Initial call `pick('get')`.
- **Readout strings (`OPS`, verbatim) — `#rpOut` renders `<name> — <returns>. <desc>`:**
  - get: name `Repo.get`, returns `one row by id`, desc `Repo.get(Course, id) fetches one row by its primary key — a Snowflake id here — and returns the struct or nil. Repo.get! raises instead of returning nil.`
  - all: name `Repo.all`, returns `run a query`, desc `Repo.all(query) executes a composable Ecto query and returns a list of structs. The query is a value built with from; all is what actually hits the database.`
  - insert: name `Repo.insert`, returns `persist a changeset`, desc `Repo.insert(changeset) writes a valid changeset and returns {:ok, struct} or {:error, changeset} — the tagged tuple the engine maps to %Portal.Error{} from F6.03.2.`
- **Degrade:** the SVG renders with the `get` row pre-stroked blue and the readout fields carry static defaults; JS only enhances. Respects `prefers-reduced-motion`; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0NdP4LlXOmu` (in `#stampId`); panel `#st-ts` hard-codes `2026-06-01 21:53:04 UTC`.
- **Decoded:** namespace `TSK`, snowflake `319956542189207552`, node `0`, seq `0`, timestamp `2026-06-01 21:53:04 UTC` (epoch `1704067200000`). `decodeBranded(id)` splits `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`. Toggles `.open` + `aria-expanded` on click / Enter / Space.

## References (#refs, verbatim)

This dive has **no `#refs` / References section** — there is no `.refs` block on the page; the cross-links live in the closing `.note` (to `/elixir/phoenix/ecto` and `/elixir/phoenix`) and the footer. (The module hub `/elixir/phoenix/ecto` carries the consolidated References block for F6.03.)

## Wiring

- **route-tag** (verbatim, segmented): `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/phoenix">phoenix</a><span class="rsep">/</span><a href="/elixir/phoenix/ecto">ecto</a><span class="rsep">/</span><span class="rcur">repo</span>` — i.e. `/ elixir / phoenix / ecto / repo` with `repo` current.
- **crumbs:** `F6` → `/elixir/phoenix` · sep `/` · `F6.03` → `/elixir/phoenix/ecto` · sep `/` · here `repo` (no link).
- **toc-mini:** `#ops` ("Three repo operations") · `#boundary` ("Ecto sits behind the port") · `#code` ("A query and the adapter").
- **pager:** prev → `/elixir/phoenix/ecto/changesets` ("← F6.03.2 · changesets & validation"); next → `/elixir/phoenix/ecto` ("Back to F6.03 · overview →").
- **footer (3-column `foot-nav`):**
  - brand: `foot-logo` → `/elixir`; `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters column links: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column links: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
  - Brand links (header `.brand`, footer `.foot-logo`) both point at `/elixir`.
- **Page meta:** `<title>` `Queries & the repo — F6.03.3 · jonnify`; `<meta description>` "The Repo executes composable Ecto queries and persists changesets — get one row by Snowflake id, run a query, insert a changeset. Crucially the Repo lives behind the engine's port, the F5.09 Postgres adapter, so the domain core calls the facade and never the database directly."

## Build instruction

To rebuild this dive, copy the `<head>`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built sibling on this F6 blue accent — the model is `elixir/phoenix/ecto/schemas.html` (the same-module dive sharing the single-`<figure class="fig">` + static-SVG boundary section + `pre.code` + `bridge` shape) — then change only the `<title>`/`<meta description>`, the `.route-tag` current segment, the crumbs, and the `<main>` body. Keep the clamp spacing intact (e.g. `clamp(2.7rem,1.9rem + 4.2vw,5.1rem)` with spaces around `+`). Use only the real Portal surfaces as written: the `published/1` query, `Repo.get/2`, `Repo.all/1`, `Repo.insert/1`, `Repo.insert_all/2`, the `Portal.EventStore` behaviour and its `Portal.EventStore.Postgres` adapter (`append/2`, `read_stream/1`), and the closed `%Portal.Error{}` set the engine maps repo errors to. Cite the companion course for the F5.09 port / engine internals rather than re-teaching them, and invent no Ecto query, repo call, or behaviour callback not shown in the live page. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
