# F6.04.3 — Composing contexts (dive)

- Route (served): `/elixir/phoenix/contexts/composition`
- File: `elixir/phoenix/contexts/composition.html`
- Place in the chapter: the third and last F6.04 dive, closing the architecture module's arc. After what a boundary hides (F6.04.1) and how a context relates to the facade (F6.04.2), this dive shows one context depending on another only through its public API — a one-way acyclic graph, a `with` pipeline returning the closed `%Portal.Error{}`, and where `Ecto.Multi` belongs. It follows F6.04.2 (`/elixir/phoenix/contexts/vs-facade`) and its pager returns to the F6.04 overview.
- Accent: blue (F6 · Phoenix). The hero `.ex` word `contexts`; the interactive SVG rows use blue `#5a87c4` / `#9fc0ea` (the graph figure adds sage `#7ba387` for the healthy edge and burgundy `#c4504c` for the avoided cycle).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.04 · part 3 of 3`

Title (verbatim): `Composing contexts` (accent word `contexts`).

Hero lede (verbatim): "Real domains have dependencies: enrolling a student needs to know the course exists. The boundary does not forbid that — it dictates *how* it happens. One context depends on another only through its **public API**: `Enrollment` calls `Catalog.fetch_course/1`, branches on the public struct it gets back, and never builds a query against `Catalog`'s tables or touches its `Repo`. Data crosses a boundary as an **id or a public struct**, not as a schema the other side could couple to. And the dependency graph stays **acyclic** — if `Enrollment` uses `Catalog`, then `Catalog` must not reach back, or the two collapse into one tangled unit. When a single operation spans contexts, you orchestrate the public calls with `with` and return the one closed error shape; when writes inside a single context must be atomic, you reach for `Ecto.Multi`. The Phoenix guides frame this as the difference between cross-context dependencies and intra-context transactions, and getting it right is what keeps a growing app from turning back into a ball of mud."

Kicker (verbatim): "Four parts: the rules for one context calling another, the shape of a healthy dependency graph, a real cross-context call, and how to keep an operation consistent across or within contexts."

## Sections

In order (four `<section>`s):

1. `#how` — "How contexts relate": three rules — relate **by public API**, pass data **by id or public struct**, **never the schema or Repo**. Carries the `cpSel` interactive. Takeaway: "A foreign struct passed across a boundary is a quiet coupling: if `Enrollment` pattern-matches the internal fields of `Catalog`'s schema, a column rename in `Catalog` now breaks `Enrollment`. Pass the id, or a struct the other context publishes on purpose."
2. `#graph` — "A healthy graph": one-way edges and no cycles; a healthy `Enrollment → Catalog` with independent `Accounts`, against an avoided `Billing ↔ Orders` cycle. Carries a static SVG ("One-way edges, no cycles"). Takeaway: "A cycle is the clearest signal a boundary is wrong. Two contexts that need each other constantly were probably one context all along — or there is a missing third that both should depend on."
3. `#call` — "One context calling another": `Enrollment.enroll/2` calling `Catalog.fetch_course/1` and folding into `%Portal.Error{}` (first `pre.code` block). Takeaway: "Notice the variant: composition wants `fetch_course/1` returning a tagged tuple, not the raising `get_course!/1` a controller uses. A context exposes both so each caller picks the failure mode it can handle."
4. `#consistency` — "Consistency across contexts": a `with` pipeline across contexts versus `Ecto.Multi` + one `Repo.transaction` within a context (second `pre.code` block), then a `.bridge` ("across contexts" → "within a context").

Running example: `Portal.Enrollment` depending on `Portal.Catalog`'s public `fetch_course/1`, emitting an `%Enrolled{}` event through `EventStore.append/2`, and an `enroll_and_welcome/2` orchestration over `Catalog` / `Enrollment` / `Accounts`.

Real Elixir code shown:
- Code block 1 (`#call`): `defmodule Portal.Enrollment` — `alias Portal.Catalog`, `alias Portal.{EventStore, Error}`, `alias Portal.Enrollment.Enrolled`, then `enroll(user_id, course_id)` with a `case Catalog.fetch_course(course_id) do` matching `{:ok, %{published: true} = course}` (append `%Enrolled{...}` via `EventStore.append("enrollment:#{user_id}", [event])`), `{:ok, %{published: false}}` (`{:error, Error.new(:course_unpublished)}`), and `{:error, :not_found}` (`{:error, Error.new(:course_not_found)}`).
- Code block 2 (`#consistency`): `enroll_and_welcome(user_id, course_id)` — a `with {:ok, course} <- Catalog.fetch_course(course_id), {:ok, _enr} <- Enrollment.enroll(user_id, course.id), {:ok, _msg} <- Accounts.notify(user_id, {:enrolled, course.id}) do ... else {:error, %Portal.Error{} = err} -> {:error, err}` (one closed error shape); plus the commented `Multi.new() |> Multi.insert(:enr, cs) |> Multi.update(:seat, seat_cs) |> Repo.transaction()` note for intra-context atomicity.

## The interactives

This dive carries one selector figure plus the footer build-stamp decoder. The "One-way edges, no cycles" graph SVG is static (no controls; it defines `<marker>` arrowheads `#cpArrow` and `#cpArrowR`).

### Figure — "Rules of composition · select one" (`#cpTitle`, `#cpSel` selector + `#cpOut` readout)

- `<figure class="fig" aria-labelledby="cpTitle">`. Control group `#cpSel` (`role="group"`, label "Composition rule"), three `<button>`s with `data-k`: `api` (label "by public API", starts `active`), `id` (label "by id or struct"), `schema` (label "never the schema"). (No `data-c` colour attribute.)
- SVG row ids: `#cpRow_api`, `#cpRow_id`, `#cpRow_schema`. Readout ids: `#cpOut`, `#cpRole`, `#cpResult`.
- Pure function: `pick(k)` over `RULES` — toggles each button's `active`/`aria-pressed`, restrokes/refills each row (`BLUE_MUTE` `#5a87c4` + `#11203a` on, `#3a4263` + `#10162b` off), sets `#cpRole` to the rule name and `#cpResult` to its `means`, and writes `<b>NAME</b> — MEANS. DESC` into `#cpOut.innerHTML`. Initial call `pick('api')`.
- `RULES` dataset (verbatim `name` / `means` / `desc`):
  - api — name "By public API", means "call its public functions", desc "One context depends on another by calling its named functions — Enrollment calls Catalog.fetch_course/1. That is the only sanctioned dependency, and it is visible in the alias list."
  - id — name "By id or struct", means "pass ids, not internals", desc "Data crosses a boundary as a course_id or a public struct the other context chooses to publish — never a private schema. Passing a foreign schema quietly couples the two contexts."
  - schema — name "Never the schema", means "no foreign Repo", desc "No context runs Repo.get(Catalog.Course, id) or builds a query against another context's tables. Reaching the schema or Repo of a foreign slice breaks the boundary even though it compiles."
- Static labels below the SVG default to: `rule:` `By public API`; `means:` `call its public functions`.

### Degrade behaviour

Controls, the SVG, and the default `api` readout are present in static markup; JS only re-applies the default (`pick('api')`). The page respects `prefers-reduced-motion` globally; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id `TSK0NdRI1Hb4bo` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 22:24:08 UTC". Decoded by `decodeBranded` (base62 over `B62`, `EPOCH_MS = 1704067200000`): ns `TSK`, snowflake `319964361856647168`, node `0`, seq `0`, timestamp `2026-06-01 22:24:08 UTC`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (`#refs`, verbatim)

This dive has no `#refs` / References section in its markup. The References block lives on the module hub (`/elixir/phoenix/contexts`); this page carries no Sources or Related-in-this-course list. (Sibling cross-links appear only inline: the `#consistency` `.note` points to `/elixir/phoenix/contexts` and `/elixir/phoenix`, and the pager links back to `/elixir/phoenix/contexts/vs-facade` and forward to `/elixir/phoenix/contexts`.)

## Wiring

- route-tag: `/` `elixir` `/` `phoenix` `/` `contexts` `/` `composition` — `elixir`, `phoenix`, and `contexts` are `<a>` links; `composition` is `<span class="rcur">`.
- crumbs: `F6` → `/elixir/phoenix` · sep `/` · `F6.04` → `/elixir/phoenix/contexts` · sep `/` · here `composition` (no link).
- toc-mini: `#how` ("How contexts relate") · `#graph` ("A healthy graph") · `#call` ("One context calling another") · `#consistency` ("Consistency across contexts").
- pager: prev → `/elixir/phoenix/contexts/vs-facade` ("← F6.04.2 · contexts vs the F5 facade"); next → `/elixir/phoenix/contexts` ("Back to F6.04 · overview →").
- footer (`foot-nav`, 3 columns) — identical to the chapter footer:
  - Brand: `.foot-logo` → `/elixir`; tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters column: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
  - Header `.brand` → `/elixir`; `Contents` nav link → `/elixir/course`.
- Page meta: `<title>` "Composing contexts — F6.04.3 · jonnify"; `<meta description>` "How one context depends on another without breaking boundaries: call the public API, pass ids or public structs, never touch a foreign schema or Repo. A one-way dependency graph with no cycles, Enrollment calling Catalog, and a with pipeline across contexts that returns the closed %Portal.Error{}."

## Build instruction

To rebuild this page, copy the `<head>`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent BUILT blue-accent sibling on this chapter — the natural model is this dive's siblings `elixir/phoenix/contexts/boundaries.html` or `elixir/phoenix/contexts/vs-facade.html` (same head/header/footer/scripts, four sections, one `cp*`/`bd*`/`vf*` selector figure, two `pre.code` blocks); change only the `<title>`/`<meta description>`, the `.route-tag`, the crumbs/pager, and the `<main>` body. Use only the real Portal surfaces as written: the named contexts `Catalog` (`fetch_course/1`, `get_course!/1`) and `Enrollment` (`enroll/2`) and `Accounts` (`notify/2`), the `Portal.EventStore` port with `append/2`, the closed `%Portal.Error{}` set built with `Error.new/1` (the body uses `:course_unpublished`, `:course_not_found`; the canonical closed set is `:already_enrolled | :course_not_found | :lesson_locked | :invalid_progress`), and `Ecto.Multi`/`Repo.transaction` for intra-context atomicity; cite the companion course for OTP and event-sourcing internals and do not re-teach them; invent no route, id, readout string, code token, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of "just", "simply", or "obviously". Model sibling to copy from: `elixir/phoenix/contexts/vs-facade.html`.
