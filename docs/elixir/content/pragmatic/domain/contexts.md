# F5.02.2 — Bounded contexts (dive)

- Route (served): `/elixir/pragmatic/domain/contexts`
- File: `elixir/pragmatic/domain/contexts.html`
- Place in the chapter: the second of the three F5.02 dives, building the middle layer of the domain model — the boundary. It groups the typed structs of F5.02.1 into context modules and sets the reference-by-id rule, then feeds F5.02.3 (the public API) which is the only way into a context.
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F5.02 · part 2 of 3`

Kicker (after the lede): "Three contexts and the references between them. Select one to see what it owns and what it points at."

Hero lede (verbatim):

> Structs on their own are a pile of shapes; a **bounded context** gives them an owner. A context is a module that holds a few related entities and the rules that bind them — `Accounts` owns User and Session, `Catalog` owns Course, Lesson, and Page, `Learning` owns Enrollment and Progress. The rule that keeps them decoupled is simple: a context references another only by **branded id**, never by reaching into its structs. An `Enrollment` carries a `user_id` and a `course_id`, not a `%User{}` and a `%Course{}` — so Accounts and Catalog can change their internals without breaking Learning.

## Sections

In order:

1. `#map` — **Three contexts** (teaching section): the dependencies all run one way — Learning depends on Accounts and Catalog by holding their ids, and neither of those depends on anything. A reference by id is a loose coupling that survives the other context reshaping its data. Carries the first interactive figure.
2. `#code` — **In code**: one module per context, entities beneath it; the reference rule shows up directly in the data — an `Enrollment` holds ids, not structs. A `.bridge` (a boundary → referenced by id) and a `.note` to F5.02.3.
3. **Translating at the boundary** (`#aclTitle`, advanced/`reveal` section): the anti-corruption layer — when `Learning` needs a course it calls `Catalog`'s public function and translates the returned `%Course{}` into a local shape of its own. Names Eric Evans' *Domain-Driven Design* and the *Phoenix — Contexts* guide. Carries a second SVG diagram plus a code listing and its own `.bridge` and `.take`.

Running example: the three Portal contexts — `Portal.Accounts`, `Portal.Catalog`, `Portal.Learning` — with `Enrollment` referencing `USR`/`CRS` ids; the advanced section runs `Portal.Learning.course_summary/1`.

Real Elixir code shown:

- `#code` listing: a `lib/portal/` tree (`accounts.ex`, `catalog.ex`, `learning.ex` each with its entities beneath), `defmodule Portal.Learning` with `alias Portal.Learning.{Enrollment, Progress}`, and `%Enrollment{user_id: "USR0Nb2", course_id: "CRS0Nb3"}` (ids — not `%User{}` / `%Course{}`).
- advanced listing: `defmodule Portal.Learning` with `course_summary/1` using a `with {:ok, course} <- Catalog.fetch_course(course_id)` chain returning `{:ok, translate(course)}`, a private `defp translate(%Catalog.Course{title: title, lessons: lessons})` returning `%{title: title, lessons: length(lessons)}`, and two call results: `course_summary("CRS0Nb3") # => {:ok, %{title: "Pragmatic Elixir", lessons: 12}}` and `course_summary("CRS0000") # => {:error, :not_found}`.

## The interactives

### Section figure — "The contexts · select one"

`<figure class="fig">` labelled by `#cxTitle`. Control group `#cxSel` (`role="group"`, `aria-label="Bounded context"`) with three buttons:

- `data-k="accounts"` — label `Accounts`
- `data-k="catalog"` — label `Catalog`
- `data-k="learning"` — label `Learning` (active by default)

SVG element ids (the highlighted boxes): `#cxBox_accounts` (User · Session, USR · SES), `#cxBox_catalog` (Course · Lesson · Page, CRS LSN PGE), `#cxBox_learning` (Enrollment · Progress, ENR · PRG), with `user_id` and `course_id` reference lines drawn between them.

Pure function `pick(k)`: looks up the `CTX` table, toggles the active button + box stroke/fill, and writes `#cxRole` (context name), `#cxResult` (its references), and `#cxOut` (readout). `pick('learning')` runs on load.

Readout `#cxOut` composed as: "The <b>{name}</b> context — references <b>{refs}</b>. {desc}". The `CTX` table values VERBATIM:

- `accounts`: name "Accounts", refs "nothing", desc "Owns who can use the Portal — <b>User</b> and <b>Session</b>. Self-contained: other contexts point at a User only by its USR id, so Accounts depends on no one."
- `catalog`: name "Catalog", refs "nothing", desc "Owns what there is to learn — <b>Course</b>, <b>Lesson</b>, <b>Page</b>, the content tree. Also self-contained; Learning reaches it by CRS id, not the other way around."
- `learning`: name "Learning", refs "USR, CRS (by id)", desc "Owns how a learner moves — <b>Enrollment</b> and <b>Progress</b>. An Enrollment holds a `user_id` and a `course_id`: references into Accounts and Catalog, by id only."

Static labels under the figure: `context: Learning` (`#cxRole`) and `references: USR, CRS (by id)` (`#cxResult`).

### Second diagram — "The translating seam between two contexts"

A static (non-interactive) `<figure class="fig">` labelled by `#aclFigTitle` in the advanced section: `LEARNING` (`course_summary/1`) calls `CATALOG` (`fetch_course/1`) by `CRS id`, a sage `TRANSLATE` node turns `%Course{}` ↓ into `%{title, lessons}`, and only the local map returns. Caption: "the %Course{} stops at the seam; only a local shape moves on".

Degrade: content is visible without JS; the flow animation on `.arc-flow` and the `.reveal` sections degrade under `prefers-reduced-motion: reduce`, with the advanced section shown fully when there is no `IntersectionObserver`.

### Build-stamp decoder

Footer stamp `#stamp` carries id `TSK0Ncs2SWVssC` (`#stampId`). `decodeBranded` (base62, `EPOCH_MS = 1704067200000`) splits namespace `TSK` and decodes snowflake/node/seq; displayed `#st-ts` is `2026-06-01 14:10:51 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/phoenix/contexts.html` — Phoenix — Contexts — bounded contexts as modules with a public function API, and how one context references or calls another.
- Eric Evans — *Domain-Driven Design: Tackling Complexity in the Heart of Software* (Addison-Wesley, 2003) — the source of bounded context, ubiquitous language, and the anti-corruption layer. (no external link)
- `https://hexdocs.pm/ex_unit/ExUnit.html` — `ExUnit` — Elixir documentation — the test framework that exercises each context across its boundary.

Related in this course:
- `/elixir/pragmatic/domain` — F5.02 · Modeling the Portal domain
- `/elixir/pragmatic/domain/structs` — Structs as entities
- `/elixir/pragmatic/domain/api` — A context's public API

## Wiring

- route-tag (verbatim): `/ elixir / pragmatic / domain / contexts` — `elixir`, `pragmatic`, `domain` are links; `contexts` is the current segment (`.rcur`).
- crumbs (verbatim): `F5` (links `/elixir/pragmatic`) / `F5.02` (links `/elixir/pragmatic/domain`) / `contexts` (`.here`).
- toc-mini: `#map` "Three contexts"; `#code` "In code".
- pager: prev → `/elixir/pragmatic/domain/structs` label "F5.02.1 · structs"; next → `/elixir/pragmatic/domain/api` label "a context's public API".
- footer: column "Chapters" → `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. Column "The course" → `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- Page meta: `<title>` is `Bounded contexts — F5.02.2 · jonnify`; `<meta name="description">` is "A bounded context is a module that owns a few entities and guards their rules — Accounts owns User and Session, Catalog owns Course and Lesson, Learning owns Enrollment and Progress. Contexts reference one another only by branded id, never by reaching into each other's structs, so each context can change on its own."

## Build instruction

To (re)build this page, copy the `<head>…</style>`, `header.site`, `footer.site-foot`, and the two trailing `<script>` blocks (the interactive `pick()`/`CTX` shell + Snowflake decoder, and the reveal enhancer) verbatim from a recent BUILT sibling on this burgundy F5 accent — the closest model is the companion dive `elixir/pragmatic/domain/structs.html` (same dive anatomy: hero lede, a `select-one` figure, an `#code` listing, `.bridge`, `#refs`, pager) — and for the advanced second-diagram pattern lift the `reveal` section shape from this same family. Change only `<title>`/`<meta>`, the route-tag's current segment, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the branded store (`USR`/`CRS`/`ENR`/`SES`/`LSN`/`PGE`/`PRG` namespaces), the three contexts `Portal.Accounts`/`Portal.Catalog`/`Portal.Learning`, the reference-by-id rule, the event-sourced engine behind ONE `Portal` facade, and Phoenix in F6; cite the companion course for OTP internals rather than re-teaching, and do not invent new contexts, function arities (`fetch_course/1`, `course_summary/1`), or struct fields. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
