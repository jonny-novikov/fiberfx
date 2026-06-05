# F6.03.2 — Changesets & validation (dive)

- **Route (served):** `/elixir/phoenix/ecto/changesets`
- **File:** `elixir/phoenix/ecto/changesets.html`
- **Place in the chapter:** the second of the three F6.03 (Ecto) dives, between F6.03.1 (schemas & migrations) and F6.03.3 (queries & the repo). It teaches the changeset as a pure pipeline that guards every write and shows how a failed changeset becomes the closed `%Portal.Error{}` contract from F5.08.
- **Accent:** F6 · Phoenix Framework, accent blue (the selected SVG rows and `Ecto.Changeset`/`Portal.Error` code tokens use `--blue`/`--blue-bright`; the `h1` accent word `validation` is the course `.ex` style).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Hero eyebrow (verbatim): `F6.03 · part 2 of 3`.

Hero `h1` (verbatim): `Changesets & validation` (accent word `validation` wrapped `<span class="ex">`).

Hero lede (`.lede`, verbatim):

> A changeset is the gate every write passes through, and it is a **pure pipeline** — data in, a changeset struct out, no side effects. You `cast` an untrusted map to permit and coerce only the fields you name; you `validate` the rules — required, length, format, number; and you declare **constraints** that the database enforces, like uniqueness. The result is a `%Ecto.Changeset{}` carrying `valid?` and a list of `errors`, computed before anything touches the database. Because it is pure, you can test a changeset without a repo and reuse it for both inserts and updates. And the engine's boundary stays clean: a failed changeset becomes the closed `%Portal.Error{}` from F5.08, so the web layer sees one error shape, never raw Ecto internals.

Kicker line (`.kicker`, verbatim):

> See the three stages of the pipeline, follow a map through to a valid-or-invalid changeset, then read a real changeset and how the engine wraps its errors.

## Sections

The dive runs three teaching sections plus the code section, in order:

1. **`#pipeline` — "The changeset pipeline":** prose plus the interactive `csSel` figure (cast · validate · constraint). Takeaway (`.take`, verbatim): "`cast` is your security boundary: a field not in its allow-list is dropped, so a client cannot set `:published` or an internal flag by smuggling it into the params."
2. **`#flow` — "Valid or invalid":** prose plus a static SVG that flows `params → cast + validate → %Changeset{}` and branches `valid?` → `Repo.insert(cs)` / `{:ok, %Course{}}` versus `invalid` → `errors` → `%Portal.Error{}`. Takeaway (`.take`, verbatim): "One value, two destinations. The valid changeset is the write; the invalid one is the error report — and the engine maps it to the closed error set so the controller branches on `%Portal.Error{}`, not on Ecto."
3. **`#code` — "A real changeset":** prose then the `pre.code` block (below), the `bridge`, and the closing `.note`.

**Running example:** the `Course` changeset (`cast → validate_required → validate_length → unique_constraint`) and the engine boundary that maps `{:error, changeset}` to `%Portal.Error{}`.

**Real Elixir shown (`pre.code`, verbatim):**

```elixir
import Ecto.Changeset

def changeset(course, attrs) do
  course
  |> cast(attrs, [:title, :published])      # permit only these fields
  |> validate_required([:title])
  |> validate_length(:title, min: 3, max: 120)
  |> unique_constraint(:title)             # enforced by the database on insert
end

# at the engine boundary: a failed changeset becomes the closed contract (F5.08)
case Repo.insert(changeset(%Course{}, attrs)) do
  {:ok, course}       -> {:ok, course}
  {:error, changeset} -> {:error, Portal.Error.from_changeset(changeset)}
end
```

The `bridge` (verbatim): cell `idea` labeled "cast & validate" — "A pure pipeline produces a changeset with `valid?` and `errors`." → cell `elix` labeled "one error shape" — "The engine maps a failed changeset to `%Portal.Error{}` — never raw Ecto."

Closing `.note` (verbatim): "Next: [**queries & the repo**](/elixir/phoenix/ecto/repo) — the `Repo.insert` above is one repo call, and the repo lives behind the engine's port."

## The interactives

### Figure — "The pipeline · select a stage" (`csTitle` / `#csSel`)

- **Markup:** a `<figure class="fig" aria-labelledby="csTitle">` titled `The pipeline · select a stage`. SVG (`viewBox="0 0 720 170"`) draws three rows `#csRow_cast`, `#csRow_validate`, `#csRow_constraint`. Readout `.geo-readout#csOut` (`aria-live="polite"`) plus mono lines `#csRole` (default `cast`) and `#csResult` (default `permit & coerce fields`).
- **Control group `#csSel`** (`role="group"`, `aria-label="Changeset stage"`), three buttons (no `data-c`):
  - `data-k="cast"` — label `cast` — starts `active`
  - `data-k="validate"` — label `validate`
  - `data-k="constraint"` — label `constraint`
- **Pure function:** `pick(k)` over the `STAGES` dataset, `ORDER = ['cast','validate','constraint']` — toggles each `#csSel` button's `active` + `aria-pressed`, restrokes the matching `#csRow_*` (active `BLUE_MUTE`/2/`#11203a`, else `#3a4263`/1.3/`#10162b`), writes `#csRole`/`#csResult`, sets `#csOut.innerHTML`. Initial call `pick('cast')`.
- **Readout strings (`STAGES`, verbatim) — `#csOut` renders `<name> — <does>. <desc>`:**
  - cast: name `cast`, does `permit & coerce fields`, desc `cast(struct, attrs, [:title, :published]) takes an untrusted map and keeps only the named fields, coercing each to its declared type. A field outside the allow-list is silently dropped.`
  - validate: name `validate`, does `check the rules`, desc `validate_required, validate_length, validate_format, validate_number and friends check values in Elixir and add an error when a rule fails. Pure functions — no database needed to test them.`
  - constraint: name `constraint`, does `defer to the database`, desc `unique_constraint and foreign_key_constraint let the database enforce what only it can know — uniqueness, references — and translate its error into a changeset error on insert, so no exception escapes.`
- **Degrade:** the SVG renders with the `cast` row pre-stroked blue and the readout fields carry static defaults; JS only enhances. Respects `prefers-reduced-motion`; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0NdP4LUDrqy` (in `#stampId`); panel `#st-ts` hard-codes `2026-06-01 21:53:04 UTC`.
- **Decoded:** namespace `TSK`, snowflake `319956541933355008`, node `0`, seq `0`, timestamp `2026-06-01 21:53:04 UTC` (epoch `1704067200000`). `decodeBranded(id)` splits `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`. Toggles `.open` + `aria-expanded` on click / Enter / Space.

## References (#refs, verbatim)

This dive has **no `#refs` / References section** — there is no `.refs` block on the page; the cross-links live in the closing `.note` and the footer. (The module hub `/elixir/phoenix/ecto` carries the consolidated References block for F6.03.)

## Wiring

- **route-tag** (verbatim, segmented): `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/phoenix">phoenix</a><span class="rsep">/</span><a href="/elixir/phoenix/ecto">ecto</a><span class="rsep">/</span><span class="rcur">changesets</span>` — i.e. `/ elixir / phoenix / ecto / changesets` with `changesets` current.
- **crumbs:** `F6` → `/elixir/phoenix` · sep `/` · `F6.03` → `/elixir/phoenix/ecto` · sep `/` · here `changesets` (no link).
- **toc-mini:** `#pipeline` ("The changeset pipeline") · `#flow` ("Valid or invalid") · `#code` ("A real changeset").
- **pager:** prev → `/elixir/phoenix/ecto/schemas` ("← F6.03.1 · schemas & migrations"); next → `/elixir/phoenix/ecto/repo` ("Next · queries & the repo →").
- **footer (3-column `foot-nav`):**
  - brand: `foot-logo` → `/elixir`; `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters column links: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column links: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
  - Brand links (header `.brand`, footer `.foot-logo`) both point at `/elixir`.
- **Page meta:** `<title>` `Changesets & validation — F6.03.2 · jonnify`; `<meta description>` "A changeset is a pure pipeline — cast permits and coerces fields, validate checks the rules, and a constraint defers to the database — producing a struct that carries valid? and errors before any write. The engine wraps a failed changeset in the closed %Portal.Error{} contract from F5.08."

## Build instruction

To rebuild this dive, copy the `<head>`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built sibling on this F6 blue accent — the model is `elixir/phoenix/ecto/schemas.html` (the same-module dive with the identical single-`<figure class="fig">` + static-SVG section + `pre.code` + `bridge` shape) — then change only the `<title>`/`<meta description>`, the `.route-tag` current segment, the crumbs, and the `<main>` body. Keep the clamp spacing intact (e.g. `clamp(2.7rem,1.9rem + 4.2vw,5.1rem)` with spaces around `+`). Use only the real Portal surfaces as written: the `Course` changeset pipeline (`cast`/`validate_required`/`validate_length`/`unique_constraint`), `Repo.insert/1`, `Portal.Error.from_changeset/1` and the closed `%Portal.Error{}` set, and the event-sourced engine behind the single `Portal` facade. Cite the companion course for the F5.08 error contract rather than re-teaching it, and invent no Ecto validation, constraint, or facade function not shown in the live page. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
