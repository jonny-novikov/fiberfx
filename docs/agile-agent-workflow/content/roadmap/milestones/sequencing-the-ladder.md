# A3.5.3 · Sequencing the ladder — dive 3

- **Route:** `/course/agile-agent-workflow/roadmap/milestones/sequencing-the-ladder`
- **File:** `html/agile-agent-workflow/roadmap/milestones/sequencing-the-ladder.html`
- **Model copied verbatim:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/what-it-carries.html` (lesson).
- **Stamp:** `TSK0Ng9hnHJgW0`.

## Lead

The rungs are not ordered by whim. The ladder is sequenced by two forces at once: **dependency** (a rung that
needs another's output comes after it) and **product priority** (the most valuable, least risky thread ships
first). Re-sequencing is a roadmap edit — it never touches a spec.

## Precise definition

Order the rungs so each is buildable (its dependencies done) and the highest value-per-risk thread leads. F6
ships the tracer (F6.1: request → facade → render) first to de-risk integration, then persistence (F6.3) and the
rendered catalog (F6.5) — the first deployable product — before interactivity (F6.6–F6.7) and auth/deploy
(F6.8–F6.9). Re-ordering rungs edits the roadmap; the `f6.N.md` specs are untouched, and a "spec edits" counter
held at zero proves it.

## The two interactives

### Hero (`.fig`) — re-sequence the ladder (spec edits held at 0)
- **Control:** a move-up / move-down stepper (`#seqUp` / `#seqDown`) over a selected rung, plus a `reset`
  (`#seqReset`). Buttons, not `.solid-select`, so no `data-c` needed.
- **SVG:** the nine-rung ladder; moving a rung re-draws the order; a persistent badge shows `spec edits: 0`.
- **Pure function:** `reorder(order, i, dir) -> order'` (returns a new array, never mutating; out-of-range = no-op)
  and `specEdits(order) -> 0` (a constant — re-ordering edits the roadmap, not a spec).
- **Readout id `seqOut`:** the current order and `spec edits: 0`.
- **Static default:** the canonical f6.1…f6.9 order, spec edits 0, correct without JS.

### Content — value × risk sorter
- **Control:** `.solid-select#vrPick`, buttons `f6.1, f6.3, f6.5, f6.8`, `data-c` set.
- **Pure function:** `valueRisk(rung) -> {value, risk, score}` over a FIXED dataset where `score = value − risk`;
  `leadRung(set) -> rung` returns the highest-score rung (the most valuable, least risky thread to lead with).
- **Readout id `vrOut`:** the rung's value, risk, score, and whether it is the lead thread.
- Teaches a DIFFERENT move: the hero re-orders while holding spec edits at zero; this scores each rung by value
  minus risk to find which thread leads.

## Worked Portal example

F6.1 (the tracer) is low value on its own but very low risk and unblocks everything, so it leads. The rendered
catalog (F6.5) is high value and moderate risk, so it leads its milestone once persistence is in. Auth and deploy
(F6.8) are high value but high risk, so they follow once the live catalog has earned feedback. Re-ordering these
in the roadmap leaves every spec exactly as written — spec edits stay at zero.

## Bridge

- **idea:** Order the ladder by dependency and product priority — the most valuable, least risky thread first —
  and re-sequencing is a roadmap edit.
- **elix:** F6 leads with the tracer, then the deployable catalog, then live, then auth. Re-ordering rungs edits
  the roadmap, never a spec — the spec-edits counter stays at zero.
- **take:** Sequence so each rung is buildable and the best value-per-risk thread leads; moving rungs edits the
  roadmap, not the specs.

## References

### Sources
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Continuous Delivery — https://continuousdelivery.com/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/

### Related in this course
- `/course/agile-agent-workflow/roadmap/milestones` (hub)
- `/course/agile-agent-workflow/roadmap/milestones/the-iteration-loop` (prev)
- `/course/agile-agent-workflow/roadmap/roadmap-anatomy/the-iteration-table`
- `/course/agile-agent-workflow/roadmap/xp-small-batches`
- `/elixir/phoenix`

## Pager

- prev: `/course/agile-agent-workflow/roadmap/milestones/the-iteration-loop` (A3.5.2)
- next (back to hub): `/course/agile-agent-workflow/roadmap/milestones`
