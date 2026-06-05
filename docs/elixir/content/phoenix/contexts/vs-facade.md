# F6.04.2 — Contexts vs the F5 facade (dive)

- Route (served): `/elixir/phoenix/contexts/vs-facade`
- File: `elixir/phoenix/contexts/vs-facade.html`
- Place in the chapter: the second of the three F6.04 dives. It reconciles vocabularies in the architecture module's arc — a Phoenix **context** and the F5 **facade** are the same boundary, with **port** the one extra idea — and answers where Ecto sits once the F6.03 port hides the `Repo`. It follows F6.04.1 (`/elixir/phoenix/contexts/boundaries`) and precedes F6.04.3 (`/elixir/phoenix/contexts/composition`).
- Accent: blue (F6 · Phoenix). The hero `.ex` word `facade`; the interactive SVG rows use blue `#5a87c4` / `#9fc0ea`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.04 · part 2 of 3`

Title (verbatim): `Contexts vs the F5 facade` (accent word `facade`).

Hero lede (verbatim): "Two communities arrived at the same boundary from different directions, and it is worth naming the overlap precisely. Phoenix calls it a **context**: a module that groups related functionality and exposes a public API. The hexagonal architecture this course built in F5 calls the same thing a **facade** — the `Portal` module the web layer is allowed to call, and nothing deeper. They are the same shape: one public surface over a slice of the domain. The differences are emphasis. Phoenix's default context talks to Ecto directly, so the context *is* the persistence boundary. The F5 design adds one more seam — a **port**, the `Portal.EventStore` behaviour from F5.09 — so the context depends on an abstraction and Ecto lives in an adapter behind it (F6.03). This dive lines the three terms up, shows how they layer in a real application, and resolves the one question that trips people moving between the two worlds: where does Ecto go?"

Kicker (verbatim): "Four parts: the three terms side by side, how a real app layers web over facade over contexts over adapters, the facade delegating in code, and where Ecto sits once a port is in play."

## Sections

In order (four `<section>`s):

1. `#same` — "Three terms, one boundary": **context** (Phoenix's word), **facade** (F5's word for the same module), **port** (the deeper seam). Carries the `vfSel` interactive. Takeaway: "Do not let the vocabulary multiply the concept. If a teammate says "context" and the F5 docs say "facade," they mean the same module — a public API over a slice. The port is the only genuinely extra idea, and it is optional."
2. `#layers` — "How they layer": web → facade → contexts → adapters, the database four steps removed from a controller. Carries a static SVG ("web → facade → contexts → adapters"). Takeaway: "Phoenix's default collapses the bottom two layers — the context calls Ecto directly. The F5 design keeps them apart with a port, which is what made the in-memory adapter for tests and the Postgres adapter for production interchangeable in F6.03."
3. `#delegate` — "The facade delegates": the thin `Portal` facade `defdelegate`-ing to its contexts (first `pre.code` block). Takeaway: "The facade owns no logic; each context does. That keeps the single entry point convenient for the web layer without turning `Portal` into a god module — it is a table of contents, not a chapter."
4. `#ecto` — "Where Ecto goes": stock Phoenix (context → `Repo`) versus this course (context → `Portal.EventStore` port, Ecto in the adapter) in the second `pre.code` block, then a `.bridge` ("stock Phoenix" → "this course").

Running example: the `Portal` facade delegating to `Catalog` / `Enrollment` / `Accounts`, and the `Portal.Enrollment` context reading/appending through the `Portal.EventStore` port rather than naming `Repo`.

Real Elixir code shown:
- Code block 1 (`#delegate`): `defmodule Portal` — `@moduledoc`, `alias Portal.{Catalog, Enrollment, Accounts}`, then `defdelegate list_courses(), to: Catalog`, `defdelegate get_course!(id), to: Catalog`, `defdelegate enroll(user_id, course_id), to: Enrollment`, `defdelegate courses_of(user_id), to: Enrollment`, `defdelegate get_user(id), to: Accounts`.
- Code block 2 (`#ecto`): `defmodule Portal.Enrollment` — `alias Portal.EventStore` (the F5.09 port, not Repo), `alias Portal.Enrollment.Enrolled`, then `enroll/2` (builds `%Enrolled{...}` and calls `EventStore.append("enrollment:#{user_id}", [event])`) and `courses_of/1` (`EventStore.read_stream(...)` then `Enum.map(...) |> Enum.uniq()`).

## The interactives

This dive carries one selector figure plus the footer build-stamp decoder. The "web → facade → contexts → adapters" SVG is static (no controls).

### Figure — "One boundary, three terms · select one" (`#vfTitle`, `#vfSel` selector + `#vfOut` readout)

- `<figure class="fig" aria-labelledby="vfTitle">`. Control group `#vfSel` (`role="group"`, label "Term for the boundary"), three `<button>`s with `data-k`: `context` (label "context"), `facade` (label "facade", starts `active`), `port` (label "port"). (No `data-c` colour attribute.)
- SVG row ids: `#vfRow_context`, `#vfRow_facade`, `#vfRow_port`. Readout ids: `#vfOut`, `#vfRole`, `#vfResult`.
- Pure function: `pick(k)` over `TERMS` — toggles each button's `active`/`aria-pressed`, restrokes/refills each row (`BLUE_MUTE` `#5a87c4` + `#11203a` on, `#3a4263` + `#10162b` off), sets `#vfRole` to the term name and `#vfResult` to its `is`, and writes the term into `#vfOut.innerHTML`. Initial call `pick('facade')`.
- `TERMS` dataset (verbatim `name` / `is` / `desc`):
  - context — name "Context", is "Phoenix's name for it", desc "Phoenix's word: a module that groups related functionality and exposes a public API. Generated by mix phx.gen.context, it is where the framework expects your domain logic to live."
  - facade — name "Facade", is "F5's name for it", desc "The F5 word for the same module: the one public entry the web layer is allowed to call — Portal. Same boundary, same public-API-over-a-slice idea, arrived at from hexagonal architecture."
  - port — name "Port", is "the seam to an adapter", desc "The one genuinely extra idea: a behaviour the context depends on, so its implementation can be swapped. Portal.EventStore from F5.09 is the port; Ecto is one adapter behind it."
- Static labels below the SVG default to: `term:` `Facade`; `is:` `F5's name for it`.

### Degrade behaviour

Controls, the SVG, and the default `facade` readout are present in static markup; JS only re-applies the default (`pick('facade')`). The page respects `prefers-reduced-motion` globally; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id `TSK0NdRI0xj9VI` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 22:24:08 UTC". Decoded by `decodeBranded` (base62 over `B62`, `EPOCH_MS = 1704067200000`): ns `TSK`, snowflake `319964361563045888`, node `0`, seq `0`, timestamp `2026-06-01 22:24:08 UTC`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (`#refs`, verbatim)

This dive has no `#refs` / References section in its markup. The References block lives on the module hub (`/elixir/phoenix/contexts`); this page carries no Sources or Related-in-this-course list. (Sibling cross-links appear only inline: the `#ecto` `.note` points to `/elixir/phoenix/contexts/composition`, and the pager links back to `/elixir/phoenix/contexts/boundaries` and forward to `/elixir/phoenix/contexts/composition`.)

## Wiring

- route-tag: `/` `elixir` `/` `phoenix` `/` `contexts` `/` `vs-facade` — `elixir`, `phoenix`, and `contexts` are `<a>` links; `vs-facade` is `<span class="rcur">`.
- crumbs: `F6` → `/elixir/phoenix` · sep `/` · `F6.04` → `/elixir/phoenix/contexts` · sep `/` · here `vs-facade` (no link).
- toc-mini: `#same` ("Three terms, one boundary") · `#layers` ("How they layer") · `#delegate` ("The facade delegates") · `#ecto` ("Where Ecto goes").
- pager: prev → `/elixir/phoenix/contexts/boundaries` ("← F6.04.1 · context boundaries"); next → `/elixir/phoenix/contexts/composition` ("Next · composing contexts →").
- footer (`foot-nav`, 3 columns) — identical to the chapter footer:
  - Brand: `.foot-logo` → `/elixir`; tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters column: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
  - Header `.brand` → `/elixir`; `Contents` nav link → `/elixir/course`.
- Page meta: `<title>` "Contexts vs the F5 facade — F6.04.2 · jonnify"; `<meta description>` "A Phoenix context and the F5 Portal facade are the same idea — a public API over a slice of the domain. How they layer (web → facade → contexts → adapters), where Phoenix's default puts Ecto in the context, and how this course keeps Ecto behind the F6.03 port so a context calls the port, not the Repo."

## Build instruction

To rebuild this page, copy the `<head>`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent BUILT blue-accent sibling on this chapter — the natural model is this dive's siblings `elixir/phoenix/contexts/boundaries.html` or `elixir/phoenix/contexts/composition.html` (same head/header/footer/scripts, four sections, one `vf*`/`bd*`/`cp*` selector figure, two `pre.code` blocks); change only the `<title>`/`<meta description>`, the `.route-tag`, the crumbs/pager, and the `<main>` body. Use only the real Portal surfaces as written: the `Portal` facade `defdelegate`-ing to `Catalog` / `Enrollment` / `Accounts`, the `Portal.EventStore` port (F5.09) with `append/2` and `read_stream/1`, the Postgres/InMemory adapters chosen by config, and the closed `%Portal.Error{}` set; cite the companion course for OTP and hexagonal internals and do not re-teach them; invent no route, id, readout string, code token, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of "just", "simply", or "obviously". Model sibling to copy from: `elixir/phoenix/contexts/boundaries.html`.
