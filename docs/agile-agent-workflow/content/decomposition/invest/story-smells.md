# A2.03.2 · Story smells — dive

- **Route:** `/course/agile-agent-workflow/decomposition/invest/story-smells`
- **File:** `html/agile-agent-workflow/decomposition/invest/story-smells.html`
- **Accent:** gold
- **Position:** A2.03 · INVEST · dive 2

## Lead

INVEST is also a diagnostic. When a story fails its readiness gate, it fails in one of a
few recurring ways — a "smell". Name the smell, read off the INVEST letters it fails, and
the rewrite follows.

## The four smells

1. **Too big** — fails **S** and **E** (and usually drags **I** down). The story spans
   many turns; no one can estimate it. Repair: split into thinner stories (A2.05).
2. **Untestable** — fails **T**. The story has no concrete confirmation of done — "improve
   the experience". Repair: state the observable behaviour that proves it.
3. **Coupled** — fails **I**. The story cannot ship until another is finished. Repair:
   invert the order, stub the dependency, or merge the inseparable pair.
4. **Purely technical** — fails **V** and **T-as-value**. The sentence names work, not a
   change a user can do — "add the courses DB table". Repair: name the user-visible
   capability the work serves, and let the table fall out as part of building it.

## Worked Portal example (the rewrite)

Smelly: "add the courses DB table." Fails V (no user gains anything), fails T-as-value (a
green migration is not a demonstrable behaviour). Rewrite to the story it serves: "As a
learner, I can browse the catalogue so that I can see what courses exist." Now V passes
(the learner can do something new), T passes (the catalogue list contains the seeded
courses), and the table is built as part of the rung — a means, not the goal.

## Hero interactive (frames the idea)

A smell picker: choose one of the four smells; the figure highlights the INVEST letters it
fails and shows the smelly Portal sentence. The readout names the failing letters and the
one-line repair.
- Dataset: four smells, each `{label, sentence, fails:[letters], repair}`.
- Pure function: `diagnose(smellKey) -> {fails, sentence, repair}`.
- Sample readout: "Purely technical — fails V (Valuable) and T (Testable as value). Repair: name the capability it serves; let the table fall out of building it."

## Main interactive (proves a consequence)

A before/after rewrite toggle on the "add the courses DB table" case: switch between the
smelly sentence and its rewrite; the figure recomputes the INVEST pass count for each.
This proves that the rewrite is not cosmetic — it moves two letters from fail to pass.
- Pure function: `rewriteScore(state) -> {pass, fail:[letters], sentence}` for
  `state ∈ {smelly, rewritten}`.
- Sample readout (smelly): "add the courses DB table — passes 3 / 6 (V, T fail). A task, not a story."
- Sample readout (rewritten): "browse the catalogue — passes 6 / 6. V and T now pass; the table is built as part of the rung."

## Bridge

- **principle:** A failing story has a smell; the smell names the INVEST letters, and the
  letters name the rewrite.
- **practice (Portal):** "add the courses DB table" smells purely technical; rewritten to
  "browse the catalogue" it passes V and T, and the table is built on the way.

## References

Sources:
- INVEST in Good Stories — https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/
- User Stories Applied — https://www.mountaingoatsoftware.com/books/user-stories-applied
- Specification by Example — https://gojko.net/books/specification-by-example/

Related:
- /course/agile-agent-workflow/decomposition/invest (hub)
- /course/agile-agent-workflow/decomposition/invest/six-tests (prev)
- /course/agile-agent-workflow/decomposition/invest/small-and-independent (next)
- /course/agile-agent-workflow/why/two-layers (A1.04)
- /course/agile-agent-workflow/decomposition (A2)
- /elixir/course

## Wiring

- Pager: prev = `/decomposition/invest/six-tests`; next = `/decomposition/invest/small-and-independent`.
- Crumbs: jonnify / Agile Agent Workflow / A2 / A2.03 / A2.03.2 · Story smells.
