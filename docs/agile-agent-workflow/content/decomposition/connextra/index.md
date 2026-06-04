# A2.02 · The Connextra form and the three Cs — module hub

- **Route:** `/course/agile-agent-workflow/decomposition/connextra`
- **File:** `html/agile-agent-workflow/decomposition/connextra/index.html`
- **Chapter:** A2 · Decomposition · module 2 of 7
- **Accent:** gold (chapter A2's accent; the title accent word is in `<span class="ex">`)

## Lead

A user story is written in one sentence and carries a whole way of working. The
sentence is the **Connextra form** — "As a `<role>`, I want `<capability>`, so
that `<benefit>`." — and the way of working is the **three Cs**: Card,
Conversation, Confirmation. A story is a promise of value with a conversation
attached, not a contract frozen up front. This module takes the form apart slot
by slot, then the three Cs, then writes real Portal stories in the form.

## Precise definitions

- **Connextra form / user-story template** — the three-slot sentence "As a
  `<role>`, I want `<capability>`, so that `<benefit>`." Each slot answers a
  question: role = *for whom*, capability = *what they can do*, benefit = *why
  it matters*. Named for the company whose team is credited with the template.
- **The three Cs** (Ron Jeffries) — Card, Conversation, Confirmation. The Card
  is a written placeholder, deliberately short. The Conversation is where the
  detail lives, deferred on purpose to the moment of building. The Confirmation
  is the acceptance check that says when the story is done.
- **A story is a promise, not a contract** — the card promises a future
  conversation about a unit of value; it does not freeze every detail in
  advance. The detail is filled in by talk and pinned by acceptance.

## The three dives (the module's `.mods` grid — arc: form → Cs → practice)

1. **A2.02.1 · `role-want-reason`** — the Connextra template, slot by slot, and
   the three anti-patterns: the system as the role, a solution smuggled into the
   want, a missing reason. Route
   `/course/agile-agent-workflow/decomposition/connextra/role-want-reason`.
2. **A2.02.2 · `three-cs`** — Card, Conversation, Confirmation: a story is a
   promise plus a conversation, not a contract frozen up front. Route
   `/course/agile-agent-workflow/decomposition/connextra/three-cs`.
3. **A2.02.3 · `portal-cards`** — write real Portal stories in the form; from a
   one-line vision to a card; how Confirmation foreshadows the Given/When/Then
   of A2.04. Route
   `/course/agile-agent-workflow/decomposition/connextra/portal-cards`.

## Framing interactive (hub)

A **slot inspector** for the Connextra form. A fixed dataset of three canonical
Portal stories (browse the catalogue, enrol, track progress). Buttons select a
story; the SVG renders its three slots — role / capability / benefit — and the
readout names what each slot answers. Pure function: `slotsOf(storyKey)` returns
`{role, capability, benefit, readout}` from the fixed dataset. Degrades: the
first story is drawn in static SVG; JS only swaps the labels and readout.

- control ids: `#cxStory` button group (`data-k` = `browse|enrol|progress`)
- pure signature: `slotsOf(k) -> {role, capability, benefit, ok}`
- sample readout: "As a learner, I want to browse the catalogue, so that I can
  choose a course. role = for whom · capability = what they can do · benefit =
  why it matters. All three slots filled."

## Principle ↔ practice bridge

- **Principle:** a requirement is best carried as a short promise of value plus a
  conversation, not a long contract written before the work.
- **Portal practice:** the Portal backlog is a stack of Connextra cards — browse,
  enrol, open a lesson, track progress — each a one-line promise whose detail is
  settled in conversation and pinned by a confirmation when the rung is built.

## References

Sources (all from the course-home registry — real, vetted):

- User-story template (Connextra) → https://www.agilealliance.org/glossary/user-story-template/
- User Stories Applied → https://www.mountaingoatsoftware.com/books/user-stories-applied
- Extreme Programming Explained → https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/

Related in this course: the three dive routes, A2 landing
(`/course/agile-agent-workflow/decomposition`), A1.04.2
(`/course/agile-agent-workflow/why/two-layers/spec`).

## Wiring

- crumbs: jonnify / Agile Agent Workflow / A2 · Decomposition / **A2.02 · here**
- pager prev: `/course/agile-agent-workflow/decomposition/value` (A2.01 —
  parallel sibling, links FAIL expected until it lands)
- pager next: `/course/agile-agent-workflow/decomposition/invest` (A2.03 —
  parallel sibling, links FAIL expected until it lands)
- `.mods` grid → the three dive routes (resolve within this batch)
