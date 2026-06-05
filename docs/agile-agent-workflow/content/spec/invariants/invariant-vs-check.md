# A4.5.1 · Invariant vs check — dive

- **Route:** `/course/agile-agent-workflow/spec/invariants/invariant-vs-check`
- **File:** `html/agile-agent-workflow/spec/invariants/invariant-vs-check.html`
- **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`
- **Model:** lesson ← `why/two-layers/spec.html`

## Lead

Two statements can both be true of an increment and still be different kinds of claim. "For every request, the
web layer calls only the facade" is universal — it quantifies over all inputs. "For an unknown user id, the page
renders the empty state" is one example — it names a single scenario. The first is an **invariant**; the second is
an **acceptance check**. Telling them apart is how a spec names the rules a slice must never break, separately
from the examples that prove it behaves.

## Precise definition

- **Invariant** — universally quantified ("for all values, at all times"). Named once in the spec's Invariants
  section; exercised by checks, never restated per scenario.
- **Acceptance check** — existentially scoped ("for this one case"). Written as a Given/When/Then on a story;
  proves one example.
- A spec carries both: the Invariants section pins the universal rules; the `.stories.md` carries the
  scenario-level checks. They cover different things.

## Worked Portal example

From the real F6.1 triad:

- **Invariant (F6.1-INV1, master):** "The web layer calls only the `Portal` facade and renders only the closed
  `%Portal.Error{}` set." True for every request. Quoted verbatim.
- **Check (F6.1-US5, first Given/When/Then):** "Given an authenticated learner with no enrollments, when I request
  `GET /my/courses` (the learner's own courses, protected), then the page renders the empty state — a clean `200`."
  One scenario.

  > **Ground-truth note (route vs function).** The F6.1 draft named a `/courses/:user_id` page; F6.5 renamed that
  > surface to the protected `/my/courses` — a learner's own enrollments, with the authenticated id read from the
  > session and no `:user_id` in the URL. Only the **route** retired; the facade function it calls, `Portal.courses_of/1`,
  > is real and as-built — keep it where it appears.

`pre.code`: a markdown fragment — the Invariants line and the Given/When/Then scenario, side by side, rendered
with `.cmt`/`.str`/`.res` spans. No Elixir source.

## Hero interactive — classify

- **Move:** classify each statement as *invariant* or *check*.
- **Control ids:** `ivcSel` (`.solid-select` of statements, each `data-c`).
- **Dataset:** master invariant (invariant), "the error set is closed" (invariant), "unknown id → 200" (check),
  "a known user renders their courses" (check).
- **Pure:** `classify(i)` → kind; `readoutFor(i)` → readout naming kind + the quantifier (for all / for this).
- **Sample readout:** `Check · holds for one scenario. "An authenticated learner with no enrollments sees the empty state (a 200) at /my/courses" is F6.1-US5's first Given/When/Then. It proves one example behaves; it does not state a universal rule.`

## Main interactive — the spec section each belongs in

- **Move (different):** for a statement, name which spec artifact and section it is written in — the Invariants
  section of `f6.1.md`, or a Given/When/Then on a story in `f6.1.stories.md`.
- **Control ids:** `ivcWhere` (`.solid-select`).
- **Pure:** `whereFor(i)` → `{artifact, section}`; readout names the home of the claim.
- **Sample readout:** `An invariant lives in the Invariants section of f6.1.md — named once, exercised by checks. A check lives as a Given/When/Then on a story in f6.1.stories.md — one scenario.`

## Bridge

- principle: name the universal rules apart from the example checks — different claims, different homes.
- Portal: F6.1-INV1 (the master invariant) is named once in `f6.1.md`; F6.1-US5's "empty `/my/courses` → 200" is a
  Given/When/Then in `f6.1.stories.md`.

## Spec citation — the F6.1 chip

Where the page first names the first web rung F6.1 (in the "On the Portal" section), the bare rung reference is a
clickable `.specref` chip labelled **"F6.1 · Bootstrap the Phoenix Portal"**. Its tooltip carries the one-sentence
description plus the route reconcile (the F6.1 draft named a `/courses/:user_id` page; F6.5 renamed it to the
protected `/my/courses` — a learner's own enrollments) and a link to the spec-ladder viewer at
`/course/agile-agent-workflow/spec/specimens` (bare-route href + `data-sr-hash="f6-1"`; JS appends `#f6-1` on
click). The literal chip markup lives only in the `.html`.

## References

- Sources: Specification by Example, Continuous Delivery, Gherkin reference.
- Related: hub `/course/agile-agent-workflow/spec/invariants`, `/course/agile-agent-workflow/spec`,
  `/course/agile-agent-workflow/why/correct`, `/elixir/phoenix`.

## Pager

- prev = `/course/agile-agent-workflow/spec/invariants`
- next = `/course/agile-agent-workflow/spec/invariants/the-master-invariant`
