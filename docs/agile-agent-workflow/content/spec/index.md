# A4 · The spec layer — chapter landing (md source of record)

> Route: `/course/agile-agent-workflow/spec` · file `html/agile-agent-workflow/spec/index.html` · the chapter
> keystone, built first and modelled on the A3 landing. This md is the source of record; the HTML is hand-built
> from it. Spec: [`a4.md`](../../specs/a4.md) · stories: [`a4.stories.md`](../../specs/a4.stories.md) · brief:
> [`a4.llms.md`](../../specs/a4.llms.md).

## Hero

- **Eyebrow:** A4 · chapter overview
- **H1:** The spec **layer** (accent on "layer")
- **Lede:** A roadmap ordered the work; a spec defines it. The spec layer is *what we build and how we accept it* —
  examples that double as checks, invariants that must always hold, and a traceability chain that makes "done" a
  closure rather than an opinion.
- **Kicker:** A3 produced a delivery plan: thin-but-robust rungs, each pointing at a spec it does not contain. This
  chapter is that spec — precise enough that a Claude **Author** can build it and an **Operator** can accept it by
  proof, *correct by definition*. Every technique lands on the Portal's real rung triads.

## Sections

1. **Where we are** — the eight-part course arc interactive (A0–A3 built, A4 here, A5–A7 planned). Pure functions
   over a fixed `PARTS` dataset; the readout is derived, never canned; the SVG + selector degrade without JS.
2. **The journey so far** — recap A0 (foundations) → A1 (why; A1.05 correct-by-definition + A1.04 two layers) → A2
   (decomposition; A2.04 acceptance) → A3 (the roadmap layer). The `.bridge`: a roadmap rung points at a spec →
   the Portal's rung **triad** (`f6.N.md`, `f6.N.stories.md`, `f6.N.llms.md`) defines it by example.
3. **The spec layer, in five questions** — What (spec + stories), Why (buildable by proof, not opinion), Who
   (Operator writes/accepts, Author reads/self-checks), When (after the roadmap, before the brief; changes only by
   feedback), Where (under the roadmap, over the brief/code), How (specification by example + invariants distinct
   from checks + traceability closing "done").
4. **The chapter modules: A4.1–A4.7** — the seven module cards (start as `soon`, relinked `built` by the Operator
   as each ships): by-example, the-triad, spec-anatomy, to-stories, invariants, traceability, workshop.
5. **References** — Sources: Specification by Example (Adzic), User Stories Applied (Cohn), Gherkin reference.
   Related: A3 roadmap, A1.05 correct, A1.04 two-layers, A2.04 acceptance, A0.2.2 four-artifacts, /elixir/phoenix.

## Pager

- Prev: A3 · The roadmap layer (`/course/agile-agent-workflow/roadmap`).
- Next: A4.1 · Specification by Example (`/course/agile-agent-workflow/spec/by-example`) — resolves once A4.1 ships.

## Notes (gate-invisible, locked)

- Segmented clickable route-tag with `spec` as `.rcur`; canonical 3-column `.foot-cols` footer; stamp `TSK0Ng9hnHJgW0`.
- No orientation-dive section (unlike A3): A4 goes straight from the five-questions overview to the seven module
  cards. Accent: elixir-purple. No Elixir source code anywhere on the chapter's pages — the worked examples are
  *spec/stories text* (the `.md`/`.stories.md`), never `def`/`defmodule`.
