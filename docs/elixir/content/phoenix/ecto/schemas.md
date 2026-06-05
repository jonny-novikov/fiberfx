# F6.03.1 — Schemas & migrations (dive)

- **Route (served):** `/elixir/phoenix/ecto/schemas`
- **File:** `elixir/phoenix/ecto/schemas.html`
- **Place in the chapter:** the first of the three F6.03 (Ecto) dives, reached from the `/elixir/phoenix/ecto` hub. It opens the Ecto teaching arc — schema and table — and hands forward to F6.03.2 (changesets) and F6.03.3 (the repo). It teaches how a migration and a schema describe a table, and how the Portal's Snowflake-id convention carries into the database row.
- **Accent:** F6 · Phoenix Framework, accent blue (the selected SVG rows and the `Ecto.Schema`/`Ecto.Migration` code tokens use `--blue`/`--blue-bright`; the `h1` accent word `migrations` is the course `.ex` style).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Hero eyebrow (verbatim): `F6.03 · part 1 of 3`.

Hero `h1` (verbatim): `Schemas & migrations` (accent word `migrations` wrapped `<span class="ex">`).

Hero lede (`.lede`, verbatim):

> Two artifacts describe a table, and they are deliberately separate. A **migration** is a versioned instruction to the database — create this table, add that column — checked in and run in order, so the schema of production is the sum of migrations applied. A **schema** is the Elixir side: `schema "courses" do field ... end` declares the fields and gives you a struct, so a row reads as `%Course{}` with typed fields you pattern-match. They are not redundant — the migration owns the database, the schema owns the struct, and they can differ. One detail carries the whole course's identity convention into the database: the primary key is a **Snowflake bigint** that `Portal.ID` mints, not a database serial, so a row's id is the same time-ordered value the engine has used since F4.

Kicker line (`.kicker`, verbatim):

> See the three layers a table touches, watch a column map across them, then read a real migration and schema with a Snowflake primary key.

## Sections

The dive runs three teaching sections plus the code section, in order:

1. **`#layers` — "Three layers":** prose (migration in the database, schema in Elixir, struct at runtime) plus the interactive `scSel` figure. Takeaway (`.take`, verbatim): "Keeping the migration and the schema separate is what lets the database evolve safely: a migration adds a column to existing rows without touching code, and the schema picks it up when you choose to declare it."
2. **`#mapping` — "A column, mapped across":** prose plus a static SVG that lines up the `courses` table → schema → struct field by field (`id bigint PK` ↔ `@primary_key :id` ↔ `id: "CRS0KHT..."`; `title varchar` ↔ `field :title, :string` ↔ `title: "OTP"`; `inserted_at` ↔ `timestamps()` ↔ `inserted_at: ~U[..]`). Takeaway (`.take`, verbatim): "A schema is a lens, not a cage. It names the columns you care about as struct fields; the database can hold more, and a read populates only what the schema declares."
3. **`#code` — "A migration and a schema":** prose then the `pre.code` block (the real Elixir, below), the `bridge`, and the closing `.note`.

**Running example:** the `courses` table mapped to `%Course{}` with a Snowflake bigint primary key minted by `Portal.ID`.

**Real Elixir shown (`pre.code`, verbatim):**

```elixir
# migration — define the table; id is a Snowflake bigint, not a serial
defmodule Portal.Repo.Migrations.CreateCourses do
  use Ecto.Migration

  def change do
    create table(:courses, primary_key: false) do
      add :id,        :bigint,  primary_key: true     # Snowflake id (CRS...)
      add :title,     :string,  null: false
      add :published, :boolean, null: false, default: false
      timestamps(type: :utc_datetime)
    end
  end
end

# schema — map the table to a struct we work with as %Course{}
defmodule Portal.Catalog.Course do
  use Ecto.Schema

  @primary_key {:id, :id, autogenerate: false}   # we mint Snowflakes via Portal.ID
  schema "courses" do
    field :title,     :string
    field :published, :boolean, default: false
    timestamps(type: :utc_datetime)
  end
end
```

The `bridge` (verbatim): cell `idea` labeled "the migration" — "Owns the database: a versioned instruction that creates the `:courses` table." → cell `elix` labeled "the schema" — "Owns the struct: `%Course{}` with a Snowflake id and typed fields."

Closing `.note` (verbatim): "Next: [**changesets & validation**](/elixir/phoenix/ecto/changesets) — before a `%Course{}` is written, a changeset casts and checks the data."

## The interactives

### Figure — "Table layers · select one" (`scTitle` / `#scSel`)

- **Markup:** a `<figure class="fig" aria-labelledby="scTitle">` titled `Table layers · select one`. SVG (`viewBox="0 0 720 170"`) draws three rows `#scRow_migration`, `#scRow_schema`, `#scRow_struct`. Readout `.geo-readout#scOut` (`aria-live="polite"`) plus mono lines `#scRole` (default `Schema`) and `#scResult` (default `a table ↔ struct mapping`).
- **Control group `#scSel`** (`role="group"`, `aria-label="Table layer"`), three buttons (no `data-c`):
  - `data-k="migration"` — label `migration`
  - `data-k="schema"` — label `schema` — starts `active`
  - `data-k="struct"` — label `struct`
- **Pure function:** `pick(k)` over the `LAYERS` dataset, `ORDER = ['migration','schema','struct']` — toggles each `#scSel` button's `active` + `aria-pressed`, restrokes the matching `#scRow_*` (active `BLUE_MUTE`/2/`#11203a`, else `#3a4263`/1.3/`#10162b`), writes `#scRole`/`#scResult`, sets `#scOut.innerHTML`. Initial call `pick('schema')`.
- **Readout strings (`LAYERS`, verbatim) — `#scOut` renders `The <name> layer — <is>. <desc>`:**
  - migration: name `Migration`, is `creates the table`, desc `A versioned instruction to the database — create table, add column — checked in and run in order with mix ecto.migrate. The production schema is the sum of migrations applied.`
  - schema: name `Schema`, is `a table ↔ struct mapping`, desc `schema "courses" do field ... end declares the fields and produces a struct. Compiled into the app, it is the lens through which a row becomes a %Course{}.`
  - struct: name `Struct`, is `a %Course{} value`, desc `The runtime value created for each row: %Course{id: "CRS0KHTOWnGLuC", title: "OTP"}. Plain data you pattern-match and pass to the facade; the id is a decodable Snowflake.`
- **Degrade:** the SVG renders with the `schema` row pre-stroked blue and the readout fields carry static defaults; JS only enhances. Respects `prefers-reduced-motion`; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0NdP4LCcjmy` (in `#stampId`); panel `#st-ts` hard-codes `2026-06-01 21:53:04 UTC`.
- **Decoded:** namespace `TSK`, snowflake `319956541673308160`, node `0`, seq `0`, timestamp `2026-06-01 21:53:04 UTC` (epoch `1704067200000`). `decodeBranded(id)` splits `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`. Toggles `.open` + `aria-expanded` on click / Enter / Space.

## References (#refs, verbatim)

This dive has **no `#refs` / References section** — there is no `.refs` block on the page; the cross-links live in the closing `.note` and the footer instead. (The module hub `/elixir/phoenix/ecto` carries the consolidated References block for F6.03.)

## Wiring

- **route-tag** (verbatim, segmented): `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/phoenix">phoenix</a><span class="rsep">/</span><a href="/elixir/phoenix/ecto">ecto</a><span class="rsep">/</span><span class="rcur">schemas</span>` — i.e. `/ elixir / phoenix / ecto / schemas` with `schemas` current.
- **crumbs:** `F6` → `/elixir/phoenix` · sep `/` · `F6.03` → `/elixir/phoenix/ecto` · sep `/` · here `schemas` (no link).
- **toc-mini:** `#layers` ("Three layers") · `#mapping` ("A column, mapped across") · `#code` ("A migration and a schema").
- **pager:** prev → `/elixir/phoenix/ecto` ("← F6.03 · overview"); next → `/elixir/phoenix/ecto/changesets` ("Next · changesets & validation →").
- **footer (3-column `foot-nav`):**
  - brand: `foot-logo` → `/elixir`; `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters column links: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column links: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
  - Brand links (header `.brand`, footer `.foot-logo`) both point at `/elixir`.
- **Page meta:** `<title>` `Schemas & migrations — F6.03.1 · jonnify`; `<meta description>` "A migration creates and evolves a database table; a schema maps that table to an Elixir struct you work with as %Course{}. The primary key is a Snowflake bigint minted by Portal.ID rather than a database serial, so the same time-ordered id convention from F4 and F5 carries into the database row."

## Build instruction

To rebuild this dive, copy the `<head>`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built sibling on this F6 blue accent — the model is `elixir/phoenix/ecto/changesets.html` (a same-module dive with the identical single-`<figure class="fig">` + `pre.code` + `bridge` shape) — then change only the `<title>`/`<meta description>`, the `.route-tag` current segment, the crumbs, and the `<main>` body. Keep the clamp spacing intact (e.g. `clamp(2.7rem,1.9rem + 4.2vw,5.1rem)` with spaces around `+`). Use only the real Portal surfaces as written: `Portal.ID` Snowflake ids minted for the `:id` bigint primary key, the `Portal.Catalog.Course` schema and `Portal.Repo.Migrations.CreateCourses` migration, the event-sourced engine behind the single `Portal` facade and its `Portal.EventStore` port, and the closed `%Portal.Error{}` set. Cite the companion course for OTP / engine internals (the F4–F5 id convention, the F5.09 engine lab) rather than re-teaching them, and invent no Ecto field, option, or API not shown in the live page. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
