# A2.02.2 · Card, Conversation, Confirmation — the three Cs

- **Route:** `/course/agile-agent-workflow/decomposition/connextra/three-cs`
- **File:** `html/agile-agent-workflow/decomposition/connextra/three-cs.html`
- **Position:** A2.02 · The Connextra form and the three Cs · dive 2
- **Accent:** gold (the `<span class="ex">` accent word: "Cs")

## Lead

Ron Jeffries named the three parts a story has: Card, Conversation,
Confirmation. The Card is a written placeholder — short on purpose. The
Conversation is where the detail lives, deferred deliberately to the moment of
building. The Confirmation is the acceptance check. Together they make a story a
**promise of value plus a conversation**, not a contract frozen up front.

## Precise definitions

- **Card** — the written placeholder: the Connextra sentence, plus enough notes
  to remember the intent. It is deliberately too short to build from alone; its
  job is to hold a place in the backlog and trigger a conversation, not to
  specify everything.
- **Conversation** — the talk between Operator and Author (and stakeholders)
  that fills in the detail the card omits. Deferred on purpose: detail decided
  too early is detail decided with the least information. The conversation
  happens when the rung is about to be built.
- **Confirmation** — the acceptance check: how both sides agree the story is
  done. It pins the conversation's conclusions to something observable, so
  "done" is a fact rather than an opinion. (It foreshadows the Given/When/Then
  of A2.04.)

## The core claim — promise, not contract

A contract tries to fix every detail before any work. A story fixes only the
promise of value (the card) and the test of done (the confirmation), and leaves
the rest to the conversation. This is deliberate: deferring detail to the latest
responsible moment means it is decided with the most information. A frozen
contract written first is the big-bang spec failure of A1.01.2.

## Worked Portal example

The Portal rung "enrol in a course":

- **Card:** "As a learner, I want to enrol in a course, so that I can study it."
  Plus a note: enrolment is once per learner per course.
- **Conversation:** what happens on a second enrol? Is there a confirmation step?
  The detail is settled in talk when the rung is built — not guessed up front.
- **Confirmation:** "Given a learner not enrolled, when they enrol, then they are
  enrolled exactly once; a second enrol does not change the count." An
  observable acceptance check.

## Interactives

**Hero (the three Cs of one card):** render a Portal card and light each of its
three Cs in turn; the readout names what each C carries and that the card alone
is a placeholder. Pure function `cOf(which) -> {label, carries, readout}` over a
fixed dataset for the enrol story.

- control ids: `#tcWhich` button group (`data-k` = `card|conv|conf`)
- pure signature: `cOf(k) -> {label, carries, note}`
- sample readout: "Card: the written placeholder — the Connextra sentence, short
  on purpose. It holds a place and triggers a conversation; it does not specify
  everything."

**Content (promise vs contract — detail-decided-when):** a slider over the
fraction of detail fixed up front (0–100%); compute "information available when
decided" as an inverse function and a "rework risk" that rises as more is fixed
early. Pure function `decide(frac) -> {fixedEarly, infoAtDecision, reworkRisk,
verdict}` over the fixed model. At 0% all detail is deferred to the conversation
(promise); at 100% it is a frozen contract (big-bang).

- control ids: `#tcFrac` range input
- pure signature: `decide(frac) -> {fixedEarly, infoAtDecision, reworkRisk}`
- sample readout: "30% of detail fixed up front · 70% deferred to the
  conversation. Information at decision time: high. Rework risk: low. A promise
  with a conversation attached."

## Principle ↔ practice bridge

- **Principle:** carry a requirement as a promise plus a conversation; defer
  detail to the latest responsible moment, and pin done with a confirmation.
- **Portal practice:** each Portal card is a one-line promise; the detail of
  enrol, browse, or track is settled in conversation when the rung is built, and
  a confirmation makes "done" observable.

## References

Sources (real, vetted):

- User Stories Applied → https://www.mountaingoatsoftware.com/books/user-stories-applied
- Extreme Programming Explained → https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- Specification by Example → https://gojko.net/books/specification-by-example/

Related: the hub, A2.02.1 role-want-reason, A2.02.3 portal-cards, A1.04.2 spec,
A2 landing.

## Wiring

- crumbs: jonnify / AAW / A2 / A2.02 / **A2.02.2 · here**
- pager prev: `/course/agile-agent-workflow/decomposition/connextra/role-want-reason`
- pager next: `/course/agile-agent-workflow/decomposition/connextra/portal-cards`
