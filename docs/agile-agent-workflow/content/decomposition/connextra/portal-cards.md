# A2.02.3 · Portal cards — write real stories in the form

- **Route:** `/course/agile-agent-workflow/decomposition/connextra/portal-cards`
- **File:** `html/agile-agent-workflow/decomposition/connextra/portal-cards.html`
- **Position:** A2.02 · The Connextra form and the three Cs · dive 3
- **Accent:** gold (the `<span class="ex">` accent word: "cards")

## Lead

The form and the three Cs become useful when real stories are written in them.
This dive takes the Portal's one-line vision and turns it into cards: each a
Connextra sentence with a confirmation, and the confirmation written so it
foreshadows the Given/When/Then acceptance criteria of A2.04.

## Precise definition

- **From a vision to a card** — the Portal vision is "a learning platform where a
  learner can find, take, and finish a course." Each verb in the vision becomes
  a capability, attached to a role and a benefit: find → browse the catalogue,
  take → enrol, study → open a lesson, finish → track progress.
- **A confirmation that foreshadows Given/When/Then** — the Confirmation C is an
  acceptance check; written in the shape "given a state, when an action, then an
  observable result", it is already the skeleton of the A2.04 Gherkin scenario.

## Worked Portal example — the four canonical cards

1. As a **learner**, I want to **browse the catalogue**, so that **I can choose a
   course**. — Confirmation: given courses exist, when the learner opens the
   catalogue, then every published course is listed.
2. As a **learner**, I want to **enrol in a course**, so that **I can study it**.
   — Confirmation: given a learner not enrolled, when they enrol, then they are
   enrolled exactly once.
3. As a **learner**, I want to **open a lesson**, so that **I can learn its
   content**. — Confirmation: given an enrolment, when the learner opens a
   lesson in that course, then its content is shown.
4. As a **learner**, I want to **track my progress**, so that **I can see what is
   left**. — Confirmation: given lessons completed, when the learner views
   progress, then the count of completed lessons is shown.

These are written against `Portal.ID.generate/1` / `Portal.ID.decode/1` only;
the OTP internals are the companion `/elixir` course's subject, cited not
re-taught.

## Interactives

**Hero (vision → cards):** the Portal vision sentence at the top; buttons select
one verb of the vision and render the card it becomes (role, capability,
benefit). Pure function `cardFor(verb) -> {role, capability, benefit, readout}`
over the fixed four-card dataset.

- control ids: `#pcVerb` button group (`data-k` = `find|take|open|finish`)
- pure signature: `cardFor(k) -> {role, capability, benefit}`
- sample readout: "find → As a learner, I want to browse the catalogue, so that
  I can choose a course. One verb of the vision becomes one card."

**Content (the card and its confirmation → Given/When/Then):** select a card;
render its Connextra line and its confirmation, and split the confirmation into
its given / when / then parts to show the A2.04 skeleton. Pure function
`confirm(cardKey) -> {given, when, then, readout}` over the fixed dataset.

- control ids: `#pcCard` button group (`data-k` = `browse|enrol|open|track`)
- pure signature: `confirm(k) -> {given, when, then}`
- sample readout: "enrol · confirmation: given a learner not enrolled, when they
  enrol, then they are enrolled exactly once. The confirmation is already a
  Given/When/Then skeleton (A2.04)."

## Principle ↔ practice bridge

- **Principle:** a vision becomes a backlog by writing each unit of value as a
  card with a confirmation; the confirmation is the seed of the acceptance test.
- **Portal practice:** the Portal vision splits into four learner cards (browse,
  enrol, open, track), each carrying a confirmation that A2.04 turns into a
  Given/When/Then scenario the Author builds to and the Operator accepts against.

## References

Sources (real, vetted):

- User Stories Applied → https://www.mountaingoatsoftware.com/books/user-stories-applied
- Specification by Example → https://gojko.net/books/specification-by-example/
- User-story template (Connextra) → https://www.agilealliance.org/glossary/user-story-template/

Related: the hub, A2.02.2 three-cs, A1.04.2 spec, A2 landing, /elixir/course.

## Wiring

- crumbs: jonnify / AAW / A2 / A2.02 / **A2.02.3 · here**
- pager prev: `/course/agile-agent-workflow/decomposition/connextra/three-cs`
- pager next: hub `/course/agile-agent-workflow/decomposition/connextra`
