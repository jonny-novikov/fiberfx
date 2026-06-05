# F5.0.2 — The domain model (dive — design front-matter)

- Route (served): `/elixir/pragmatic/domain-model`
- File: `elixir/pragmatic/domain-model.html`
- Place in the chapter: the second of three design front-matter pages on the F5 landing (2 of 3). It fixes the engine's data — three bounded contexts and their entities — before code, sitting between `F5.0.1 · The blueprint` and `F5.0.3 · The command & event flow`.
- Accent: burgundy (`--burgundy:#c4504c`; active context card stroke `#c4504c`, highlight text `#e08f8b`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Hero lede (verbatim):

> The core holds the Portal's data, and that data has a shape worth fixing before any code. The engine owns three **bounded contexts** — Accounts, Catalog, and Learning — and each context owns a few entities, modeled as plain Elixir structs and keyed by the branded Snowflake ids from F4. A context is a seam: it owns its entities, guards its own rules, and exposes a small public API, so the rest of the engine depends on the API rather than the data. This is the model F5.02 builds.

Eyebrow (verbatim): `F5 · system design · 2 of 3`

Kicker (verbatim):

> Select a context to see the entities it owns and the id namespaces that key them. The same branded id convention from F4 is the pivot key across every context.

h1 (verbatim): `The domain ` + `model` (`.ex` accent span).

## Sections

In order:

1. `#contexts` — "Three contexts". Teaching section. Carries the interactive contexts figure. Prose: contexts keep the model honest — a learner's `Enrollment` lives in Learning and references a `User` and a `Course` by id, so Accounts and Catalog can change internals without breaking it; every entity carries a branded id whose three-letter namespace says which kind it is. `.take` (verbatim): "A context is the unit of decoupling in the engine. Draw the boundaries here, on the data, and the modules that follow have an obvious home for every rule."
2. `#struct` — "An entity in code". Advanced/code section. Shows one entity as a struct in real Elixir, plus a `.bridge` and a forward `.note`.

Running example: the three Portal contexts — Accounts (`User` USR, `Session` SES), Catalog (`Course` CRS, `Lesson` LSN, `Page` PGE), Learning (`Enrollment` ENR, `Progress` PRG) — and an `Enrollment` joining a USR to a CRS.

Real Elixir code shown (the `#struct` `pre.code`, verbatim):

```
# a Learning entity — a plain struct keyed by branded ids (F4 convention)
defmodule Portal.Learning.Enrollment do
  @enforce_keys [:id, :user_id, :course_id]
  defstruct [:id, :user_id, :course_id, enrolled_at: nil, progress: 0]

  @type t :: %__MODULE__{
          id: String.t(),         # "ENR0Nb..."
          user_id: String.t(),    # "USR0Nb..."  -> Accounts
          course_id: String.t(),  # "CRS0Nb..."  -> Catalog
          progress: non_neg_integer()
        }
end
```

`.bridge` cells (verbatim): idea "a bounded context" — "Accounts, Catalog, Learning — each owns its entities and a small API." → elix "structs keyed by branded ids" — "References cross contexts by id; the namespace says which kind." `.note` (verbatim): "Next in the design brief: [the command & event flow](/elixir/pragmatic/flow) — how these entities change over time. Back to [the blueprint](/elixir/pragmatic/architecture)."

## The interactives

### `#contexts` figure — "The contexts · select one" (`#dmSel` selector + `#dmCode`/`#dmOut` readouts)

- Markup: `<figure class="fig" aria-labelledby="dmTitle">` titled "The contexts · select one". Inside: a `.controls` > `.solid-select#dmSel` group, an `<svg viewBox="0 0 720 210">` with three context cards (`<rect>` + entity/namespace `<text>`s), a `pre.code#dmCode` (`aria-live="polite"`), a `.geo-readout#dmOut` (`aria-live="polite"`), plus two mono lines `context:` (`#dmRole`) and `id namespaces:` (`#dmResult`).
- Control ids / buttons: `#dmSel` group, `role="group"`, `aria-label="Bounded context"`. Three `<button data-k>`s: `accounts` ("Accounts", starts `active`), `catalog` ("Catalog"), `learning` ("Learning").
- SVG element ids: cards `#dmCard_accounts`, `#dmCard_catalog`, `#dmCard_learning`. Static entity/namespace labels in markup: Accounts → `User`/USR, `Session`/SES; Catalog → `Course`/CRS, `Lesson`/LSN, `Page`/PGE; Learning → `Enrollment`/ENR, `Progress`/PRG.
- Pure function: `pick(k)` — toggles each `#dmSel` button's `active`/`aria-pressed` by `data-k === k`; for each id in `ORDER ['accounts','catalog','learning']` sets the matching card `stroke`/`stroke-width`/`fill` (on: `#c4504c` / `2` / `#1d1320`; off: `#3a4263` / `1.3` / `#10162b`); writes `C.name` into `#dmRole`, `C.ns` into `#dmResult`, a generated `defmodule Portal.<name>` snippet into `#dmCode.innerHTML`, and an HTML readout into `#dmOut`. Wired by `addEventListener('click', …)` per button; initial call `pick('accounts')`.
- Readout payloads (`CTX`, verbatim `ns` / `ents` / `desc`; `#dmOut` renders ``The <b>{name}</b> context owns <b>{ents}</b>, keyed by <b>{ns}</b>. {desc}``):
  - accounts: ns "USR, SES", ents "User, Session", desc "Who can use the Portal. **User** (USR) and **Session** (SES). Other contexts reference a user only by its USR id, never by reaching into Accounts."
  - catalog: ns "CRS, LSN, PGE", ents "Course, Lesson, Page", desc "What there is to learn. **Course** (CRS), **Lesson** (LSN), and **Page** (PGE) — the content tree, keyed so any node can be addressed by id."
  - learning: ns "ENR, PRG", ents "Enrollment, Progress", desc "How a learner moves through the Catalog. **Enrollment** (ENR) joins a USR to a CRS; **Progress** (PRG) records advance through lessons. This is where most of the engine's commands land."
- Generated `#dmCode` template (verbatim): ``# {name} context — entities: {ents}`` / ``defmodule Portal.{name} do`` / ``  # owns {ents}, keyed by {ns}; exposes a small public API`` / ``end``.
- Degrades: the `accounts` button ships `active` and the mono lines default to `Accounts` / `USR, SES`; `#dmCode`/`#dmOut` are empty in static markup until `pick('accounts')` fills them on load. Respects `prefers-reduced-motion` globally; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id (`#stampId`): `TSK0NclTceAaY4`; panel `#st-ts` hard-codes `2026-06-01 12:39:01 UTC`.
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Decoded namespace `TSK`; decoded timestamp matches `2026-06-01 12:39:01 UTC`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (#refs, verbatim)

Intro line: "Modeling a domain in structs and bounded contexts."

Sources:
- [Phoenix — Contexts](https://hexdocs.pm/phoenix/contexts.html) — bounded contexts and their public APIs.
- [Elixir — Structs](https://hexdocs.pm/elixir/structs.html) — modeling entities with enforced keys.
- [Elixir — Typespecs](https://hexdocs.pm/elixir/typespecs.html) — `@type` for each entity.

Related in this course:
- `F5.0.1 · The Portal engine blueprint` → `/elixir/pragmatic/architecture` — where the model sits.
- `F5.0.3 · The command & event flow` → `/elixir/pragmatic/flow` — how entities change.
- `F4.07 · Identifiers, Snowflake & branded ids` → `/elixir/algorithms/identifiers` — the ids that key every entity.
- `F5 · Pragmatic Programming` → `/elixir/pragmatic`

## Wiring

- route-tag (verbatim): `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/pragmatic">pragmatic</a><span class="rsep">/</span><span class="rcur">domain-model</span>` — i.e. `/ elixir / pragmatic / domain-model`.
- crumbs (verbatim): `Contents` → `/elixir/course` · sep `/` · `F5 · Pragmatic Programming` → `/elixir/pragmatic` · sep `/` · here `The domain model` (no link).
- toc-mini: `#contexts` ("Three contexts") · `#struct` ("An entity in code").
- pager: prev → `/elixir/pragmatic/architecture` ("← F5.0.1 · the blueprint"); next → `/elixir/pragmatic/flow` ("Next · the command & event flow →").
- footer (3-column `foot-nav`): identical to the chapter siblings — brand `.foot-logo` → `/elixir`; Chapters column `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework"); The course column `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
- Page meta: `<title>` "The domain model — F5.0.2 · jonnify"; `<meta description>` "The data the Portal engine owns: three bounded contexts — Accounts (User, Session), Catalog (Course, Lesson, Page), and Learning (Enrollment, Progress) — modeled as plain structs and keyed by the branded Snowflake ids from F4. The contexts are the engine's seams; each owns its entities and exposes a small public API, the shape F5.02 builds."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built design sibling on this burgundy chapter — the model is `elixir/pragmatic/architecture.html` (the preceding design front-matter sibling, same hero/figure/refs anatomy) — then change only `<title>`/`<meta description>`, the `.route-tag` (last segment `<span class="rcur">domain-model</span>`), the crumbs/eyebrow ("2 of 3"), and the `<main>` body. Keep the `#dmSel` selector + `pick(k)` shape (it generates `#dmCode` and `#dmOut` on select); ship the `accounts` button `active` for the default state. No-invent guards: use only the real Portal surfaces as written — three bounded contexts (`Portal.Accounts`, `Portal.Catalog`, `Portal.Learning`) of plain structs keyed by F4 branded Snowflake namespaces (USR/SES/CRS/LSN/PGE/ENR/PRG), no Ecto and no database row in the domain — and cite `F4` for the id machinery; do not re-teach OTP or persistence internals. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously.
