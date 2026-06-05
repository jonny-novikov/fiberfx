# F5.02 — Modeling the Portal domain (module hub)

- Route (served): `/elixir/pragmatic/domain`
- File: `elixir/pragmatic/domain/index.html`
- Place in the chapter: F5.02 is the second module of F5 · Pragmatic Programming, where the framework-free Portal engine is built technique by technique. It follows F5.01 (foundations — a thin server) and gives the engine a shape before behavior. The hub frames three dives — structs, bounded contexts, the public API — that together build the domain model the rest of the chapter (F5.03 tracer-bullets onward) drives use cases through.
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F5 · the engine · module 2`

Kicker (after the lede): "A context, seen from the inside out: structs at the core, a boundary around them, a public API on top. Select a layer to see what it is and which dive builds it."

Hero lede (verbatim):

> With the Portal running behind a thin server, the engine needs a shape before it needs behavior. That shape is the **domain model**, and it is built in three layers. Each entity — a user, a lesson, an enrollment — is a plain **struct** with a typespec. Entities are grouped into **bounded contexts** — Accounts, Catalog, Learning — modules that own their data and reference one another only by branded id. And each context exposes a small **public API** that validates input and keeps its internals private. No Ecto, no database rows yet; the model is data and the functions that guard it.

## What the page frames

The landing carries two prose sections (`#anatomy` "Anatomy of a context", `#dives` "Three deep dives") and a `.dives`-style card list of three dives, each a clickable card on the burgundy/blue/gold left-border scheme:

- F5.02.1 — **Structs & typespecs** — `@enforce_keys` for the required fields, defaults for the rest, and a `@type t` the compiler and Dialyzer can check. Route: `/elixir/pragmatic/domain/structs`. Built.
- F5.02.2 — **Bounded contexts** — Accounts, Catalog, Learning — each owns its entities and references the others only by branded id, so each can change alone. Route: `/elixir/pragmatic/domain/contexts`. Built.
- F5.02.3 — **A context's public API** — A smart constructor that validates and returns `{:ok, struct}` or `{:error, reason}` — the only way in. Route: `/elixir/pragmatic/domain/api`. Built.

A `.bridge` block frames the arc from F5.01 ("it runs" — a thin server puts the Portal on a port, but its handlers call an engine that has no shape yet) to F5.02 ("give it a shape" — model the entities as structs, group them into contexts, and expose each context through a small API). The closing `.note` links the three dives in order and points forward to F5.03 — Tracer bullets, and to the design brief `/elixir/pragmatic/domain-model`.

## The interactives

### Hero figure — "Reference by id, not by struct"

`<figure class="hero-fig">` labelled by `#hpTitle` ("Reference by id, not by struct"). The SVG depicts an `ACCOUNTS · CONTEXT` band over a `LEARNING · CONTEXT` band, split by a `CONTEXT BOUNDARY` line, with a reference row group `#hpRef` crossing the boundary.

- Controls: two buttons — `#hpBtn` (label `▸ reference by id`, toggles to `▸ embed the struct`) and `#hpReset` (label `reset`).
- Pure functions (inline IIFE): `render()` rebuilds the `#hpRef` group from the `byId` flag; helper `link(stroke)` draws the curved path, `row(...)` builds the reference row; `el(name, attrs)` is the SVG-element factory.
- Readout `#hpCap` (`aria-live="polite"`), VERBATIM. Coupled (default) state:
  - `user: %User{id: usr_7f3, …}`
  - "The whole struct is embedded — the contexts are coupled."
  - Toggled (by-id) state: `user_id: usr_7f3` / "One branded id — each context owns its own data."
- Degrade: the static initial state renders the coupled form (the whole `%User{}` embedded across the boundary) directly in markup, visible without JS. The `.hp-row.hp-new` slide-in animation is gated by `prefers-reduced-motion: no-preference`. No render on load — the static SVG already shows the coupled form.

### Section figure — "A context, inside out · select a layer"

`<figure class="fig">` labelled by `#dnTitle`. Control group `#dnSel` (`role="group"`, `aria-label="Model layer"`) with three buttons:

- `data-k="struct"` — label `structs` (active by default)
- `data-k="context"` — label `context`
- `data-k="api"` — label `public API`

SVG element ids: `#dnPart_context`, `#dnPart_api`, `#dnPart_struct` (the rects highlighted on select). The Learning context's public API band shows `enroll/2 · record_progress/2 · courses_of/1`; the entities band shows `%Enrollment{}` and `%Progress{}`. Pure function `pick(k)` looks up the `LAYERS` table, toggles the active button and rect stroke/fill, and writes `#dnRole` (layer name), `#dnResult` (the dive number), and `#dnOut` (the readout). `pick('struct')` runs on load.

Readout `#dnOut` is composed as: "The <b>{name}</b> layer — built in <b>{dive}</b>. {desc}". The `LAYERS` table values VERBATIM:

- `struct`: name "Structs", dive `F5.02.1`, desc "Each entity is a plain struct with enforced keys and a typespec — the data the context holds. `%Enrollment{}` and `%Progress{}` here."
- `context`: name "Bounded context", dive `F5.02.2`, desc "A module — `Portal.Learning` — that owns those structs and guards their rules. It references other contexts only by branded id, never by reaching into their data."
- `api`: name "Public API", dive `F5.02.3`, desc "A small set of functions — `enroll/2`, `courses_of/1` — the only way in. Everything below the surface is private to the context."

Static labels under the figure: `layer: Structs` (`#dnRole`) and `built in: F5.02.1` (`#dnResult`).

### Build-stamp decoder

Footer stamp `#stamp` carries id `TSK0Ncs2RwSpM0` (`#stampId`). The `decodeBranded` function (base62, `EPOCH_MS = 1704067200000`) splits the 3-char namespace `TSK` from the snowflake and decodes ts/node/seq; the displayed `#st-ts` timestamp is `2026-06-01 14:10:51 UTC`.

## References (#refs, verbatim)

Intro line: "Modeling a domain in structs and bounded contexts."

Sources:
- `https://hexdocs.pm/elixir/structs.html` — Elixir — Structs — entities with enforced keys.
- `https://hexdocs.pm/elixir/typespecs.html` — Elixir — Typespecs — `@type` and `@spec`.
- `https://hexdocs.pm/phoenix/contexts.html` — Phoenix — Contexts — bounded contexts and their public APIs.
- `https://martinfowler.com/bliki/BoundedContext.html` — Martin Fowler — Bounded Context — the boundary as a unit of decoupling.

Related in this course:
- `/elixir/pragmatic/domain/structs` — F5.02.1 · Structs & typespecs
- `/elixir/pragmatic/domain/contexts` — F5.02.2 · Bounded contexts
- `/elixir/pragmatic/domain/api` — F5.02.3 · A context's public API
- `/elixir/pragmatic/domain-model` — F5.0.2 · The domain model — the map of all three contexts.
- `/elixir/algorithms/identifiers` — F4.07 · Identifiers, Snowflake & branded ids — the ids that key every entity.

## Wiring

- route-tag (verbatim): `/ elixir / pragmatic / domain` — `elixir` links to `/elixir`, `pragmatic` links to `/elixir/pragmatic`, `domain` is the current segment (`.rcur`).
- crumbs (verbatim): `F5 · Pragmatic Programming` (links to `/elixir/pragmatic`) / `F5.02 · domain` (`.here`).
- toc-mini: `#anatomy` "Anatomy of a context"; `#dives` "Three deep dives".
- pager: prev → `/elixir/pragmatic` label "F5 · overview"; next → `/elixir/pragmatic/domain/structs` label "Start · structs & typespecs".
- footer: column "Chapters" → `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column "The course" → `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta: `<title>` is `Modeling the Portal domain — F5.02 · jonnify`; `<meta name="description">` is "The engine needs a shape before it needs behavior. F5.02 models the Portal's domain in three layers: each entity is a plain struct with a typespec; entities are grouped into bounded contexts — Accounts, Catalog, Learning — that reference one another only by branded id; and each context exposes a small public API that validates input and hides its internals. Three dives on structs, contexts, and the public API."

## Build instruction

To (re)build this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the interactive IIFE shell + Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on this burgundy F5 accent — the closest model is the sibling module hub `elixir/pragmatic/tracer-bullets/index.html` (same hub anatomy: hero with `hero-fig`, `#anatomy`/`#dives` sections, dive cards, `.bridge`, `#refs`). Change only `<title>`/`<meta>`, the route-tag's current segment, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the branded store (ids like `usr_7f3`, namespaces `USR`/`CRS`/`ENR`), the event-sourced engine behind ONE `Portal` facade, and the Phoenix web app to come in F6; cite the companion course for OTP internals rather than re-teaching them, and do not invent context names, function arities, or struct fields beyond Accounts/Catalog/Learning, `enroll/2`, `record_progress/2`, `courses_of/1`, `%Enrollment{}`, `%Progress{}`. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
