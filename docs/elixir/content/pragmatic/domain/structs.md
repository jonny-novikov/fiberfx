# F5.02.1 — Structs & typespecs (dive)

- Route (served): `/elixir/pragmatic/domain/structs`
- File: `elixir/pragmatic/domain/structs.html`
- Place in the chapter: the first of the three F5.02 dives, building the lowest layer of the Portal domain model — the typed struct. It opens the teaching arc data → boundary → interface, and feeds directly into F5.02.2 (bounded contexts) which group these structs into modules.
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F5.02 · part 1 of 3`

Kicker (after the lede): "The three parts of an `Enrollment` struct, and what each one guarantees. Select a part to see its job."

Hero lede (verbatim):

> An entity is a plain struct, and a good struct definition is three declarations working together. `@enforce_keys` lists the fields the entity cannot exist without; `defstruct` declares every field and gives the optional ones a default; and a `@type t` documents the shape so the compiler and Dialyzer can check it. The result is data with a fixed, known set of keys, where a malformed entity raises at construction rather than failing somewhere downstream. The branded-id fields carry their namespace, so a wrong reference is visible on sight.

## Sections

In order:

1. `#parts` — **Three declarations** (teaching section): the three lines are not redundant — enforced keys decide what must be present, the struct definition decides what fields exist and their defaults, and the type decides what each field may hold. Carries the interactive figure.
2. `#code` — **In code**: a full entity. Building one with all enforced keys succeeds; omitting one raises a `KeyError` at compile-checked construction; the typespec gives Dialyzer enough to flag a wrong-typed field. A `.bridge` (an entity → a typed struct) and a `.note` to F5.02.2.

Running example: the `Portal.Learning.Enrollment` entity (an enrollment joining a learner to a course).

Real Elixir code shown (the `#code` block): a `defmodule Portal.Learning.Enrollment` with `@enforce_keys [:id, :user_id, :course_id]`, `defstruct [:id, :user_id, :course_id, enrolled_at: nil, progress: 0]`, and a `@type t :: %__MODULE__{...}` mapping `id`/`user_id`/`course_id` to `String.t()`, `enrolled_at` to `DateTime.t() | nil`, and `progress` to `non_neg_integer()`. Then two construction lines:

- `%Enrollment{id: "ENR0Nb1", user_id: "USR0Nb2", course_id: "CRS0Nb3"}` — all enforced keys present.
- `%Enrollment{id: "ENR0Nb1"}` — `** (KeyError) the following keys must also be given: [:user_id, :course_id]`.

## The interactives

### Section figure — "A struct definition · select a part"

`<figure class="fig">` labelled by `#srTitle`. Control group `#srSel` (`role="group"`, `aria-label="Struct declaration"`) with three buttons:

- `data-k="enforce"` — label `@enforce_keys` (active by default)
- `data-k="defstruct"` — label `defstruct`
- `data-k="type"` — label `@type t`

SVG element ids (the three highlighted rects): `#srPart_enforce` (REQUIRED FIELDS, `@enforce_keys [:id, :user_id, :course_id]`), `#srPart_defstruct` (FIELDS + DEFAULTS, `defstruct [:id, :user_id, :course_id, enrolled_at: nil, progress: 0]`), `#srPart_type` (THE SHAPE, CHECKED, `@type t :: %__MODULE__{progress: non_neg_integer(), ...}`).

Pure function `pick(k)`: looks up the `PARTS` table, toggles the active button + rect stroke/fill, and writes `#srRole` (declaration name), `#srResult` (the guarantee), and `#srOut` (readout). `pick('enforce')` runs on load.

Readout `#srOut` composed as: "<b>{name}</b> — {role}. {desc}". The `PARTS` table values VERBATIM:

- `enforce`: name "@enforce_keys", role "required fields", desc "Names the fields a struct cannot be built without. `%Enrollment{}` missing a `:user_id` raises at construction — a malformed entity never exists."
- `defstruct`: name "defstruct", role "fields + defaults", desc "Declares every field and gives the optional ones a default — `progress: 0`, `enrolled_at: nil`. The struct is a map with a fixed, known set of keys."
- `type`: name "@type t", role "the shape, checked", desc "Documents the struct's shape and each field's type. Dialyzer uses it to catch mismatches — a number where a String id belongs — before the code runs."

Static labels under the figure: `declaration: @enforce_keys` (`#srRole`) and `guarantees: required fields` (`#srResult`).

Note: this dive carries one interactive figure and one in-code listing; it does not have a second SVG diagram (unlike the contexts dive). Degrade: content is visible without JS; the `.reveal` sections fall back to fully shown under `prefers-reduced-motion: reduce` or without `IntersectionObserver`.

### Build-stamp decoder

Footer stamp `#stamp` carries id `TSK0Ncs2SEukoC` (`#stampId`). `decodeBranded` (base62, `EPOCH_MS = 1704067200000`) splits namespace `TSK` and decodes snowflake/node/seq; displayed `#st-ts` is `2026-06-01 14:10:51 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/ex_unit/ExUnit.html` — `ExUnit` — Elixir documentation — the test framework.
- `https://hexdocs.pm/ex_unit/ExUnit.DocTest.html` — `ExUnit.DocTest` — Elixir documentation — tests from documentation examples.

Related in this course:
- `/elixir/pragmatic/domain/contexts` — F5.02 · Bounded contexts
- `/elixir/pragmatic/domain/api` — F5.02 · The context API

## Wiring

- route-tag (verbatim): `/ elixir / pragmatic / domain / structs` — `elixir`, `pragmatic`, and `domain` are links; `structs` is the current segment (`.rcur`).
- crumbs (verbatim): `F5` (links `/elixir/pragmatic`) / `F5.02` (links `/elixir/pragmatic/domain`) / `structs` (`.here`).
- toc-mini: `#parts` "Three declarations"; `#code` "In code".
- pager: prev → `/elixir/pragmatic/domain` label "F5.02 · domain"; next → `/elixir/pragmatic/domain/contexts` label "bounded contexts".
- footer: column "Chapters" → `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. Column "The course" → `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- Page meta: `<title>` is `Structs & typespecs — F5.02.1 · jonnify`; `<meta name="description">` is "An entity is a plain struct: @enforce_keys names the fields it cannot exist without, defstruct gives the optional ones their defaults, and a @type t documents the shape and lets Dialyzer check it. Branded-id fields carry their namespace, so a malformed reference is visible at a glance — no database row, just data."

## Build instruction

To (re)build this page, copy the `<head>…</style>`, `header.site`, `footer.site-foot`, and the two trailing `<script>` blocks (the interactive `pick()`/`PARTS` shell + Snowflake decoder, and the reveal enhancer) verbatim from a recent BUILT sibling on this burgundy F5 accent — the closest model is the companion dive `elixir/pragmatic/domain/contexts.html` (same dive anatomy: hero lede, a `select-a-part` figure, an `#code` listing, `.bridge`, `#refs`, pager). Change only `<title>`/`<meta>`, the route-tag's current segment, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the branded store (`ENR`/`USR`/`CRS` namespaces, ids like `ENR0Nb1`), the `%Enrollment{}` struct with exactly its enforced keys and defaults, the event-sourced engine behind ONE `Portal` facade, and Phoenix in F6; cite the companion course for OTP internals rather than re-teaching, and do not redefine `@enforce_keys`, `defstruct`, or the `@type t` field types. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
