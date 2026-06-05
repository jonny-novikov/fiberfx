# F6.04.1 — Context boundaries (dive)

- Route (served): `/elixir/phoenix/contexts/boundaries`
- File: `elixir/phoenix/contexts/boundaries.html`
- Place in the chapter: the first of the three F6.04 dives. It opens the architecture module's teaching arc (**what & why → how → when**): what a context exposes versus hides, drawing the line by cohesion, the public API in code, and what it looks like when a caller respects or breaks the seal. It precedes F6.04.2 (`/elixir/phoenix/contexts/vs-facade`).
- Accent: blue (F6 · Phoenix). The hero `.ex` word `boundaries`; the interactive SVG rows use blue `#5a87c4` / `#9fc0ea`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.04 · part 1 of 3`

Title (verbatim): `Context boundaries` (accent word `boundaries`).

Hero lede (verbatim): "A context earns its keep by what it refuses to expose. The Phoenix guides describe a context as a module that groups related functionality and presents a public API; the discipline that makes the description worth anything is the second half — **everything else is private**. The schemas the context defines, the queries it builds, the `Repo` it calls: none of that crosses the boundary. A caller sees `Catalog.list_courses/0` and `Catalog.get_course!/1`, not `Course` the schema and not `Repo.all/1`. That single rule is what lets a context change its storage, rename a column, or split a table without any caller noticing — the same payoff the F5 facade gave the engine, now applied to the data layer. The hard part is not the syntax; it is deciding *where* the line goes, and then holding it when a controller would find it convenient to reach through."

Kicker (verbatim): "Four parts: what a context exposes versus hides, how to choose the boundary by cohesion, the public API in real code, and what it looks like when a caller respects the seal versus breaks it."

## Sections

In order (four `<section>`s):

1. `#expose` — "Exposed and hidden": three things live in a context, one public (the public API), two private (the schemas, the `Repo`). Carries the `bdSel` interactive. Takeaway: "The boundary is a promise about what may break. Anything public is a contract you keep; anything private is yours to change. A context with a wide public surface has promised too much."
2. `#line` — "Where the line goes": group by **cohesion**, not by table; a cohesive `Catalog` (course + lesson) and `Accounts` (user + identity) versus a scattered table-per-context split. Carries a static SVG ("By cohesion, not by table"). Takeaway: "When unsure, prefer fewer contexts. It is easier to split a context that has grown a clear internal seam than to merge four anemic ones that turned out to be the same capability all along."
3. `#api` — "The public API": the `Portal.Catalog` module shown in code (first `pre.code` block). Takeaway: "The `!` on `get_course!/1` is a contract choice: it raises on a missing row, which a controller route turns into a 404. A non-raising `get_course/1` returning `nil` or `{:ok, course}` is the variant a composing context prefers — F6.04.3 uses it."
4. `#seal` — "Respecting the seal": two controllers (WRONG reaches past the boundary into the schema and `Repo`; RIGHT calls the public function) shown in the second `pre.code` block, then a `.bridge` ("expose a little" → "change freely").

Running example: the `Portal.Catalog` context (`list_courses/0`, `get_course!/1`, `create_course/1`) with its private `Portal.Catalog.Course` schema and `Portal.Repo`, contrasted against a `Catalog`/`Accounts` cohesive split.

Real Elixir code shown:
- Code block 1 (`#api`): `defmodule Portal.Catalog` — `@moduledoc`, `import Ecto.Query`, `alias Portal.Repo`, `alias Portal.Catalog.Course` (private), then `list_courses` (`Repo.all(from c in Course, where: c.published == true, order_by: [desc: c.inserted_at])`), `get_course!(id)` (`Repo.get!(Course, id)`), and `create_course(attrs)` (`%Course{id: Portal.ID.snowflake("CRS")} |> Course.changeset(attrs) |> Repo.insert()`).
- Code block 2 (`#seal`): a WRONG `show/2` controller (`Portal.Repo.get!(Portal.Catalog.Course, id)` — knows the schema AND the Repo) versus a RIGHT `show/2` (`Portal.Catalog.get_course!(id)` — one function, no internals).

## The interactives

This dive carries one selector figure plus the footer build-stamp decoder. The second section's "By cohesion, not by table" SVG is static (no controls).

### Figure — "Inside a context · select a part" (`#bdTitle`, `#bdSel` selector + `#bdOut` readout)

- `<figure class="fig" aria-labelledby="bdTitle">`. Control group `#bdSel` (`role="group"`, label "Part of a context"), three `<button>`s with `data-k`: `public` (label "public API", starts `active`), `schema` (label "private schema"), `repo` (label "the Repo"). (No `data-c` colour attribute.)
- SVG row ids: `#bdRow_public`, `#bdRow_schema`, `#bdRow_repo`. Readout ids: `#bdOut`, `#bdRole`, `#bdResult`.
- Pure function: `pick(k)` over `PARTS` — toggles each button's `active`/`aria-pressed`, restrokes/refills each row (`BLUE_MUTE` `#5a87c4` + `#11203a` on, `#3a4263` + `#10162b` off), sets `#bdRole` to the part name and `#bdResult` to its `is`, and writes `The <b>NAME</b> — IS. DESC` into `#bdOut.innerHTML`. Initial call `pick('public')`.
- `PARTS` dataset (verbatim `name` / `is` / `desc`):
  - public — name "Public API", is "named functions callers use", desc "The set of public functions a context exposes — list_courses/0, get_course!/1, create_course/1. This is the contract; everything a caller may rely on is here and nothing else."
  - schema — name "Private schema", is "owned, never exposed", desc "The Ecto schemas the context defines — Catalog.Course, Catalog.Lesson — describe its tables but stay internal. No other module builds a query against them or pattern-matches their module name."
  - repo — name "The Repo", is "sealed inside the context", desc "Repo.all, Repo.get!, Repo.insert run only inside this module. The context is the single place that touches the database for its slice, so storage is free to change behind the API."
- Static labels below the SVG default to: `part:` `Public API`; `is:` `named functions callers use`.

### Degrade behaviour

Controls, the SVG, and the default `public` readout are present in static markup; JS only re-applies the default (`pick('public')`). The page respects `prefers-reduced-motion` globally (only the shared `.arc-flow`/`.hp-edge` rules animate, and none are instantiated here); no browser storage. The `.reveal` sections (the References block elsewhere; this dive has no `.reveal`) are content-visible without JS.

### Footer build-stamp decoder (`#stamp`)

- Stamp id `TSK0NdRI0ZsqZs` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 22:24:08 UTC". Decoded by `decodeBranded` (base62 over `B62`, `EPOCH_MS = 1704067200000`): ns `TSK`, snowflake `319964361210724352`, node `0`, seq `0`, timestamp `2026-06-01 22:24:08 UTC`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (`#refs`, verbatim)

This dive has no `#refs` / References section in its markup. The References block lives on the module hub (`/elixir/phoenix/contexts`); this page carries no Sources or Related-in-this-course list. (Cross-links to siblings appear only inline in the body and pager: the `#seal` `.note` points to `/elixir/phoenix/contexts/vs-facade`, and the pager forwards to it.)

## Wiring

- route-tag: `/` `elixir` `/` `phoenix` `/` `contexts` `/` `boundaries` — `elixir`, `phoenix`, and `contexts` are `<a>` links; `boundaries` is `<span class="rcur">`.
- crumbs: `F6` → `/elixir/phoenix` · sep `/` · `F6.04` → `/elixir/phoenix/contexts` · sep `/` · here `boundaries` (no link).
- toc-mini: `#expose` ("Exposed and hidden") · `#line` ("Where the line goes") · `#api` ("The public API") · `#seal` ("Respecting the seal").
- pager: prev → `/elixir/phoenix/contexts` ("← F6.04 · overview"); next → `/elixir/phoenix/contexts/vs-facade` ("Next · contexts vs the F5 facade →").
- footer (`foot-nav`, 3 columns) — identical to the chapter footer:
  - Brand: `.foot-logo` → `/elixir`; tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters column: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
  - Header `.brand` → `/elixir`; `Contents` nav link → `/elixir/course`.
- Page meta: `<title>` "Context boundaries — F6.04.1 · jonnify"; `<meta description>` "A context groups related functionality behind a public API and keeps its schemas and the Repo private. How to draw the line by cohesion rather than by table, why exposing a schema across a boundary couples two contexts, and the difference between a controller that calls Catalog.get_course!/1 and one that reaches the Repo."

## Build instruction

To rebuild this page, copy the `<head>`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent BUILT blue-accent sibling on this chapter — the natural model is this dive's own siblings `elixir/phoenix/contexts/vs-facade.html` or `elixir/phoenix/contexts/composition.html` (identical head/header/footer/scripts, four sections, one `bd*`/`vf*`/`cp*` selector figure, two `pre.code` blocks); change only the `<title>`/`<meta description>`, the `.route-tag`, the crumbs/pager, and the `<main>` body. Use only the real Portal surfaces as written: the branded store with `Portal.ID.snowflake/1`, the event-sourced engine behind ONE `Portal` facade, the named contexts `Catalog` / `Enrollment` / `Accounts` over `Portal.Repo`, and the closed `%Portal.Error{}` set; cite the companion course for OTP internals and do not re-teach them; invent no route, id, readout string, code token, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of "just", "simply", or "obviously". Model sibling to copy from: `elixir/phoenix/contexts/vs-facade.html`.
