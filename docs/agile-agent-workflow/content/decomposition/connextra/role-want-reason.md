# A2.02.1 · Role, want, reason — the Connextra template

- **Route:** `/course/agile-agent-workflow/decomposition/connextra/role-want-reason`
- **File:** `html/agile-agent-workflow/decomposition/connextra/role-want-reason.html`
- **Position:** A2.02 · The Connextra form and the three Cs · dive 1
- **Accent:** gold (the `<span class="ex">` accent word: "template")

## Lead

The Connextra template is one sentence with three slots: "As a `<role>`, I want
`<capability>`, so that `<benefit>`." Each slot has a job. The role names *for
whom*; the capability names *what they can do*; the benefit names *why it
matters*. When a slot does its job the story stays small and testable; when a
slot is filled wrong the story drifts into one of three anti-patterns.

## Precise definition

- **role** — the actor who gains the value. A human (or another system) that the
  capability serves. On the Portal: learner, instructor, admin.
- **capability** — what that actor can now do, stated as an observable
  behaviour, not as an implementation. "Browse the catalogue", not "add a SQL
  index".
- **benefit** — why the capability matters to the role: the outcome that makes
  the work worth doing. It is the test of whether the capability is the right
  one.

## The three anti-patterns

1. **System as the role** — "As the system, I want to cache the catalogue…".
   The role slot holds an implementation detail, not an actor who gains value.
   No human benefits, so there is no story.
2. **A solution smuggled into the want** — "As a learner, I want a Redis cache,
   so that pages load fast." The capability names a mechanism, not a behaviour.
   It over-specifies the *how* and forecloses the conversation.
3. **A missing reason** — "As a learner, I want to browse the catalogue."
   Without a benefit there is no test of value: the story cannot be ordered
   against others, and you cannot tell when it is worth stopping.

## Worked Portal example

Take the Portal rung "the catalogue". The well-formed card:

> As a **learner**, I want to **browse the catalogue**, so that **I can choose a
> course**.

- role = learner (an actor who gains value)
- capability = browse the catalogue (an observable behaviour)
- benefit = choose a course (the outcome that justifies the work)

Contrast each anti-pattern: "As the system, I want to cache the catalogue" (no
actor), "As a learner, I want a Redis cache" (a solution, not a behaviour), "As
a learner, I want to browse the catalogue" with no `so that` (no test of value).

## Interactives

**Hero (the three slots):** render the Connextra sentence as three labelled slots
for a fixed Portal story; the readout names the question each slot answers. Pure
function `slots(storyKey) -> {role, capability, benefit, q1, q2, q3}` over a
fixed dataset of two Portal stories (browse, enrol).

- control ids: `#rwrStory` button group (`data-k` = `browse|enrol`)
- pure signature: `slots(k) -> {role, capability, benefit}`
- sample readout: "As a learner, I want to browse the catalogue, so that I can
  choose a course. Three slots, three questions: for whom · what they can do ·
  why it matters."

**Content (the anti-pattern detector):** select one of four cards (one
well-formed, three anti-patterns); the SVG marks which slot is malformed and the
readout names the anti-pattern and the repair. Pure function
`grade(cardKey) -> {roleOk, wantOk, reasonOk, name, fix}` over a fixed dataset.

- control ids: `#rwrCard` button group (`data-k` = `good|sysrole|solution|noreason`)
- pure signature: `grade(k) -> {roleOk, wantOk, reasonOk, name, fix}`
- sample readout: "system as the role: the role slot holds an implementation,
  not an actor who gains value. Repair — name the human the capability serves."

## Principle ↔ practice bridge

- **Principle:** a requirement is best stated as who gains, what they can do, and
  why — behaviour and value, never mechanism.
- **Portal practice:** every Portal card names a learner/instructor/admin, an
  observable capability (browse, enrol, open, track), and a benefit — so the
  Author builds the behaviour and the Operator can accept the value.

## References

Sources (real, vetted, from the registry):

- User-story template (Connextra) → https://www.agilealliance.org/glossary/user-story-template/
- User Stories Applied → https://www.mountaingoatsoftware.com/books/user-stories-applied
- Extreme Programming Explained → https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/

Related: the hub, A2.02.2 three-cs, A1.04.2 spec, A2 landing.

## Wiring

- crumbs: jonnify / AAW / A2 / A2.02 / **A2.02.1 · here**
- pager prev: hub `/course/agile-agent-workflow/decomposition/connextra`
- pager next: `/course/agile-agent-workflow/decomposition/connextra/three-cs`
