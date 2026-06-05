# A5.7.3 — The failure mode

- **Route:** `/course/agile-agent-workflow/brief/the-thesis/the-failure-mode` · file `…/the-thesis/the-failure-mode.html`
- **Eyebrow:** `A5.7.3 · dive 3/3`
- **Parent hub:** `/course/agile-agent-workflow/brief/the-thesis`
- **Crumbs:** `jonnify` (`/elixir`) / `Agile Agent Workflow` (`/course/agile-agent-workflow`) / `A5 · The agent brief` (`/course/agile-agent-workflow/brief`) / `The failure mode`
- **Route-tag (segmented):** `course/agile-agent-workflow` (link) / `brief` (link) / `the-thesis` (link) / `the-failure-mode` (rcur)
- **Pager:** prev `…/the-thesis/where-value-is-real` · next `/course/agile-agent-workflow/brief/the-thesis` (back to hub)
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.

## Lead

The two earlier dives showed the thesis from the side where it pays off: the pairing (speed from the agent,
direction from the human) and where the value is real (a well-specified, thin, gated slice the agent's speed
multiplies into progress). This dive shows the side where it fails. The failure mode is an **under-specified
slice**: the agent has nothing to implement, so it improvises — and because the agent is fast, its speed multiplies
whichever direction the gap sets. A small slip, run fast, becomes a large step in the wrong direction. The fix is
never to slow the agent down; it is upstream, in the spec.

## Precise claim

The outcome of a slice is `speed × direction`. The agent supplies the speed; the spec sets the direction. On a
well-specified slice `direction = +1` and high speed is a large step toward done. On an under-specified slice the
agent invents the missing decisions, and any one wrong invention sets `direction = −1` — so the same high speed is a
large step away from done. Speed is not the hazard; an unset direction is. The remedy is to specify the slice, not
to restrain the implementer.

## Worked Portal example — the f6.1.llms.md risk register

`f6.1.llms.md` is the Portal's web-bootstrap brief: a slice specified down to `F6.1-R1…R8`, the `T1→T7` task DAG,
and per-story Acceptance gates. Its risk register names exactly the two hazards an under-specified or unverified
slice produces — quoted verbatim:

- **RK-1 — the opened-gap.** *"The opened-gap: the tree omits `Portal.Store`. Dropping the Store `courses_of/1`
  reads → every course render is a dead-process crash, not a 404."* This is the under-specified hazard: leave the
  supervision tree's child list open and an agent assembling a "three-child" tree can omit the one child every
  render depends on. The brief closes it by pinning the tree — `Portal.Application` keeps exactly
  `[Portal.Store, Portal.EventStore.adapter(), {Portal.Engine, []}]` — and the Apollo gate makes a real
  `Portal.courses_of/1` render, not merely a boot. The boundary RK-1 protects is the one the companion course draws
  at `/elixir/phoenix/contexts/vs-facade`: the web touches only the `Portal` facade, never the Store directly, so
  the Store must be present for the facade to read.
- **RK-3 — loss of independent verification.** *"Loss of independent verification (the solo-topology hazard — the
  same context that builds also judges)."* This is the unverified hazard: when the context that builds the slice is
  the same one that reviews it, a fast build is graded by the same fast assumptions that produced it. The brief
  closes it by restoring an independent evaluator — a different context than the builder adversarially verifies and
  mutation-probes the work.

Both risks are what speed multiplies when the slice is under-specified or unverified. Neither is fixed by a slower
agent; both are fixed upstream, in the brief and in an independent review.

## Hero interactive — under-specified → improvise

- **id root:** `impSel` (toggle: `under-specified` / `well-specified`) + `impOut` (`.geo-readout`) + four SVG
  decision cells + an "invented by the agent" count.
- **Dataset (fixed):** the four how-to-build decisions a spec leaves open (from `/brief/why`, grounded on
  `f6.1.llms.md`):
  1. which sources to read (References),
  2. the runtime shape (Execution topology),
  3. the build order (the task DAG `T1→T7`),
  4. the proof gates (the Acceptance gates).
- **Pure fns:** `decisionsLeft(spec)` — `under-specified` leaves all four open (the agent must invent each);
  `well-specified` leaves none (the brief fixes them); `improvisedCount(spec)`; `heroReadout(spec)`.
- **Sample readout (under-specified):** `Under-specified brief — how-to-build decisions the agent must invent: 4 of
  4. With the decisions left open, the agent fills each with a choice the Operator should own; an under-specified
  slice does not stop the agent, it hands it the architecture.`

This figure teaches a *different* move from the content figure: it counts what an under-specified brief leaves the
agent to invent (the cause). The content figure shows the consequence — speed times that wrong direction.

## Content interactive — speed multiplies the wrong direction

- **id root:** `mulSpd` (range: the agent's speed, low↔high) + `mulOut` (`.geo-readout`) + an SVG vector/bar whose
  signed magnitude is `speed × direction`.
- **Dataset (fixed):** the `outcome(spec) = speed × direction` model with `direction = −1` (under-specified). Speed
  is the agent's, varied low → high.
- **Pure fns:** `direction(spec)` returns `−1` for under-specified; `outcome(speed, dir)` returns `speed × dir` (a
  signed magnitude); `magnitudeLabel(out)`; `contentReadout(speed)`.
- **Sample readout (high speed):** `Under-specified, high speed: outcome = high speed × −1 = a large step in the
  wrong direction — the agent's speed multiplies the error, it does not cause it. The fix is upstream: specify the
  slice, do not slow the agent.`

## Principle → Portal practice (bridge)

- **Principle:** the failure mode is an under-specified slice — the agent improvises, and its speed multiplies the
  wrong direction; the fix is upstream, in the spec, not in the agent.
- **On the Portal:** `f6.1.llms.md`'s RK-1 (omit `Portal.Store` and every course render crashes) and RK-3 (the
  builder also judges) are exactly the under-specified / unverified hazards the brief and an independent review
  close — by pinning the tree and restoring a separate evaluator.
- **Take:** When an agent goes wrong fast, the cause is almost always a slice that was not specified — fix the
  brief, not the agent.

## References

- **Sources (3):**
  - The Pragmatic Programmer (`https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`)
    — design by contract: every decision the builder must not be left to invent.
  - Anthropic — Building effective agents (`https://www.anthropic.com/engineering/building-effective-agents`) — why
    an open-ended goal, not an explicit task, is where an agent improvises.
  - Extreme Programming Explained (`https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/`)
    — fast feedback and small, specified steps as the guard against fast error.
- **Related in this course:** `/course/agile-agent-workflow/brief/the-thesis` (hub);
  `/course/agile-agent-workflow/brief/the-thesis/where-value-is-real` (the prior dive — the value side);
  `/course/agile-agent-workflow/brief/why` (the four how-to-build decisions); `/elixir/phoenix/contexts/vs-facade`
  (the boundary RK-1 protects); `/elixir/phoenix` (the companion chapter whose `f6.1.llms.md` this grounds on).
- **In-prose `/elixir` cross-link:** `/elixir/phoenix/contexts/vs-facade`.
- **`#refs` in `.toc-mini`:** yes.
