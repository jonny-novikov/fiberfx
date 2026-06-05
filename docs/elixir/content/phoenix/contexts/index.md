# F6.04 — Contexts & domain design (module hub)

- Route (served): `/elixir/phoenix/contexts`
- File: `elixir/phoenix/contexts/index.html`
- Place in the chapter: the F6.04 module hub of the F6 · Phoenix Framework chapter. It frames the architecture module — how the domain sits behind one web surface — and routes the reader to its three deep dives (`boundaries`, `vs-facade`, `composition`). It follows F6.03 (`/elixir/phoenix/ecto`) and precedes F6.05 (HEEx & components).
- Accent: blue (the F6 · Phoenix chapter accent; the hero `.ex` word `design` renders in `--elixir-bright`, the chapter SVGs use blue `#5a87c4` / `#9fc0ea`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6 · the architecture · module 4`

Title (verbatim): `Contexts & domain design` (accent word `design`).

Hero lede (verbatim): "The Phoenix guides put it bluntly: *Phoenix is not your application*. The framework is the web interface; the application is a set of **contexts** — dedicated modules that group related functionality and expose it through a small, deliberate public API. A context names a slice of the domain ("the catalog," "enrollment," "accounts"), owns the schemas and queries inside it, and hides the `Repo` behind functions like `Catalog.list_courses/0`. Callers — controllers, LiveViews, other contexts — depend on that API, never on its internals. If that sounds familiar, it should: it is the same boundary the F5 `Portal` facade already draws. This module reconciles the two vocabularies and makes the boundary load-bearing — a context that leaks its schemas is a boundary in name only, and the cost shows up the first time two slices need to change independently."

Kicker (verbatim): "Three dives: how to draw a context boundary by cohesion and keep its schemas private; how a Phoenix context relates to the hexagonal facade and its port from F5 and F6.03; and how to compose across contexts without one reaching into another."

## What the page frames

The hub presents F6.04 as three deep dives, each a `<a>` card in a stacked column under `#dives`. There is no `.mods` grid on this hub; the dives are direct links to the three subpages.

- F6.04.1 · **Context boundaries** — "What a context exposes and what it hides; drawing the line by cohesion; why a schema is private to its context." — route `/elixir/phoenix/contexts/boundaries` — built (blue left-border `--blue`).
- F6.04.2 · **Contexts vs the F5 facade** — "The context and the `Portal` facade are one idea; how they layer, and where Ecto sits when the port already hides it." — route `/elixir/phoenix/contexts/vs-facade` — built (gold left-border `--gold`).
- F6.04.3 · **Composing contexts** — "One context calling another's API, a one-way dependency graph, and a `with` pipeline that returns the closed error." — route `/elixir/phoenix/contexts/composition` — built (sage left-border `--sage`).

Two prose sections precede the dives list:

- `#pieces` — "Three ways to look at a boundary": a context as **boundary** (groups and decides what is public), as **facade** (the one public API a slice exposes), and in **composition** (contexts relate only through APIs). Carries the `ctSel` interactive and the takeaway: "A context is not a layer and not a table — it is a *capability*. "Enroll a student, list a student's courses" is one context; the rows behind it are an implementation detail it is free to change."
- `#map` — "A context map": the Portal as `Catalog`, `Enrollment` (depends on `Catalog`), and an independent `Accounts`, all over a private Ecto/Repo persistence layer. Carries the `ctMapTitle` static SVG figure and the takeaway: "Read top to bottom, every arrow crosses a public API. Nothing in the web layer knows a schema name, and `Enrollment` reaches `Catalog` only through `Catalog`'s functions — the property the rest of this module defends."

A `.bridge` after the dives pairs "Phoenix says" ("A context is a module that groups related functionality and exposes a public API.") with "F5 already built" (the `Portal` facade — one public API over a slice of the domain. Same boundary.). The closing `.note` (verbatim): "Start with [context boundaries](/elixir/phoenix/contexts/boundaries), then [contexts vs the F5 facade](/elixir/phoenix/contexts/vs-facade), then [composing contexts](/elixir/phoenix/contexts/composition). This module follows F6.03 — [Ecto](/elixir/phoenix/ecto) — and the next, F6.05, renders these contexts' data with HEEx and components."

## The interactives

This hub carries two figures plus the footer build-stamp decoder. Two static map SVGs accompany the dynamic selector; there is no `.fold-ctrl` slider and no `pre.code` block on the hub.

### Hero figure — "Through the API, or reaching in" (`#hpTitle`)

- `<figure class="hero-fig" aria-labelledby="hpTitle">`, label "Through the API, or reaching in". A `<svg viewBox="0 0 320 300">` shows a `Controller` (a caller) reaching the `Enrollment` context, routed through its public API door (`enroll/2 · list_courses/1`) over the private schemas/queries/`Repo`.
- Control group `.hp-ctrls` (no `data-key` keys — two plain buttons):
  - `#hpToggle` — label "▸ reach into internals" (toggles to "▸ through the API")
  - `#hpReset` (class `ghost`) — label "through the API"
- SVG element ids: `#hpBound` (the context boundary rect), `#hpApi` (the public API door), `#hpThrough` + `#hpThroughHead` (caller → public API, the static live edge), `#hpReach` + `#hpReachHead` + `#hpBreach` (the boundary-piercing edge, hidden until toggled).
- Function: `render(reaching)` — when `reaching` is true it hides the through-edge, shows the reach edge + "boundary breached" label, recolours `#hpBound` to `#e08f8b` dashed and dims `#hpApi`, and swaps the caption to `REACH_CAP`; when false it restores the through-state and `THROUGH_CAP`. No render runs on load — the static SVG already shows the call routed through the public API.
- Caption strings (`#hpCap`, verbatim):
  - THROUGH_CAP / default: "Controller → Enrollment.enroll/2" then "The call enters through the one public door; the schemas and Repo stay sealed."
  - REACH_CAP: "Controller → Repo.get(Enrollment, id)" then "Reaching past the API pierces the boundary; the public door goes unused and the seal is gone."

### Content figure — "A context, three ways · select one" (`#ctTitle`, `#ctSel` selector + `#ctOut` readout)

- `<figure class="fig" aria-labelledby="ctTitle">`. Control group `#ctSel` (`role="group"`), three `<button>`s with `data-k`: `boundary` (starts `active`), `facade`, `composition`. (No `data-c` colour attribute on these buttons.)
- SVG row ids: `#ctRow_boundary`, `#ctRow_facade`, `#ctRow_composition`. Readout ids: `#ctOut`, `#ctRole`, `#ctResult`.
- Pure function: `pick(k)` over `VIEWS` — toggles each button's `active`/`aria-pressed`, restrokes/refills each row (`BLUE_MUTE` `#5a87c4` + `#11203a` on, `#3a4263` + `#10162b` off), sets `#ctRole` to the view name and `#ctResult` to its `is`, and writes `As a <b>NAME</b> — IS. DESC` into `#ctOut.innerHTML`. Initial call `pick('boundary')`.
- `VIEWS` dataset (verbatim `name` / `is` / `desc`):
  - boundary — name "Boundary", is "group & expose a slice", desc "A context groups related functionality and decides what is public. It owns its schemas and queries and exposes only named functions — the seam other code is allowed to touch."
  - facade — name "Facade", is "one public API", desc "Seen from outside, a context is a facade: a single module of public functions over a slice of the domain. This is exactly what the F5 Portal already is — Phoenix calls it a context."
  - composition — name "Composition", is "contexts call contexts", desc "Contexts relate only through public APIs. Enrollment asks Catalog for a course; it never queries Catalog's tables. The domain becomes a graph of small public surfaces, not one module."
- The two static labels below the SVG default to: `view:` `Boundary`; `is:` `group & expose a slice`.

### Static figure — "The Portal as a context map" (`#ctMapTitle`)

- A non-interactive `<figure class="fig" aria-labelledby="ctMapTitle">` `<svg viewBox="0 0 720 250">` drawing the web layer over `Catalog`, `Enrollment`, `Accounts` over the F6.03-port persistence layer. No controls, no JS.

### Degrade behaviour

Controls, both SVGs, and the default `boundary` readout are present in static markup; JS only re-applies the default state. The `.hp-edge` call edge animates its dash only under `prefers-reduced-motion: no-preference` (`hpFlow`), never layout; reduced motion stops it. No browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id `TSK0NdRI04NN8i` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 22:24:08 UTC". Decoded by `decodeBranded` (base62 over `B62`, `EPOCH_MS = 1704067200000`): ns `TSK`, snowflake `319964360745156608`, node `0`, seq `0`, timestamp `2026-06-01 22:24:08 UTC`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (`#refs`, verbatim)

Intro prose: "The Phoenix contexts guide, its generators, and the domain-driven idea the term comes from."

**Sources**
- [Phoenix — Contexts](https://hexdocs.pm/phoenix/contexts.html) — dedicated modules that group and expose functionality.
- [Phoenix — mix phx.gen.context](https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Context.html) — the generator that scaffolds a context, schema, and tests.
- [Martin Fowler — Bounded Context](https://martinfowler.com/bliki/BoundedContext.html) — the domain-driven design idea behind the name.
- [Ecto — Multi](https://hexdocs.pm/ecto/Ecto.Multi.html) — grouping writes inside a context transactionally.

**Related in this course**
- `/elixir/phoenix/contexts/boundaries` — F6.04.1 · Context boundaries
- `/elixir/phoenix/contexts/vs-facade` — F6.04.2 · Contexts vs the F5 facade
- `/elixir/phoenix/contexts/composition` — F6.04.3 · Composing contexts
- `/elixir/phoenix/ecto` — F6.03 · Ecto — the schemas and Repo a context keeps private.
- `/elixir/phoenix` — F6 · Phoenix Framework

## Wiring

- route-tag: `/` `elixir` `/` `phoenix` `/` `contexts` — `elixir` and `phoenix` are `<a>` links; `contexts` is the current `<span class="rcur">`.
- crumbs: `F6 · Phoenix Framework` → `/elixir/phoenix` · sep `/` · here `F6.04 · contexts` (no link).
- toc-mini: `#pieces` ("Three ways to look at a boundary") · `#map` ("A context map") · `#dives` ("Three deep dives").
- pager: prev → `/elixir/phoenix/ecto` ("← F6.03 · Ecto"); next → `/elixir/phoenix/contexts/boundaries` ("Start · context boundaries →").
- footer (`foot-nav`, 3 columns):
  - Brand: `.foot-logo` → `/elixir`; tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters column: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
  - Header `.brand` → `/elixir`; `Contents` nav link → `/elixir/course`.
- Page meta: `<title>` "Contexts & domain design — F6.04 · jonnify"; `<meta description>` "A context is a dedicated module that groups related functionality behind a public API and hides its schemas and the Repo — the same idea as the hexagonal Portal facade from F5, under Phoenix's name for it. Three dives: drawing context boundaries, reconciling a context with the F5 facade and its port, and composing across contexts without breaking their boundaries."

## Build instruction

To rebuild this page, copy the `<head>`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent BUILT blue-accent sibling on this chapter — the model is the F6.04 dive `elixir/phoenix/contexts/boundaries.html`; change only the `<title>`/`<meta description>`, the `.route-tag`, and the `<main>` body (this hub additionally carries the two-figure architecture layout with the hero `hpToggle`/`hpReset` figure and the `ctSel` selector). Use only the real Portal surfaces as written: the branded store, the event-sourced engine behind ONE `Portal` facade, the Phoenix web app, and the named contexts `Catalog` / `Enrollment` / `Accounts` with the closed `%Portal.Error{}` set `:already_enrolled | :course_not_found | :lesson_locked | :invalid_progress`; cite the companion course for OTP internals and do not re-teach them; invent no route, id, readout string, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of "just", "simply", or "obviously". Model sibling to copy from: `elixir/phoenix/contexts/boundaries.html`.
