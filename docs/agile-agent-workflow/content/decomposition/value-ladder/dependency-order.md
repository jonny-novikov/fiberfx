# A2.06.2 · Dependency order — deep-dive

- **Route:** `/course/agile-agent-workflow/decomposition/value-ladder/dependency-order`
- **File:** `html/agile-agent-workflow/decomposition/value-ladder/dependency-order.html`
- **Chapter:** A2 · Decomposition — **Position:** A2.06 · dive 2 of 3
- **Accent:** gold (valid order); burgundy (a dependency points upward — violation)

## Lead

Composing the ladder kept the rungs that are capabilities. This dive fixes the order between
them. The rule is one line: **each rung may depend only on the rungs below it.** A ladder that
obeys it is a topological order of the dependency graph — and a single edge that points upward
breaks it.

## Precise definition

A ladder `r₁ … rₙ` is in **dependency order** when, for every rung `rᵢ`, every rung it depends on
appears below it: `deps(rᵢ) ⊆ {r₁, …, rᵢ₋₁}`. This is exactly a topological order of the
dependency graph. **Value accrues bottom-up**: rung 1 is usable alone, rung 2 adds to it, and so
on, so the lowest-numbered rungs are the foundation.

Two sorts are in play, and they are not the same:
- **by dependency** — the hard constraint; a rung cannot precede something it needs.
- **by value** — the soft preference; ship the most valuable usable rung first.

They reconcile by precedence: **dependency wins where they conflict** (an order that violates a
dependency cannot be built), and value chooses the order *among rungs that do not depend on each
other*. A topological sort that breaks ties by value gives both.

## Portal grounding (no-invent)

The Portal dependency graph: browse ← enrol ← open lesson ← track progress (each arrow "depends
on"). The only valid linearisation is `browse, enrol, open lesson, track progress` — because the
graph is a chain, dependency order is total here. Swap any adjacent pair and a dependency points
upward: put *enrol* before *browse* and enrol depends on a rung not yet below it; the order is no
longer a ladder. Id authority: `Portal.ID.generate/1`, `Portal.ID.decode/1` (`.type`,
`.timestamp`). OTP cited to `/elixir`.

## Hero interactive (frames the idea: every dependency points down)

A **dependency-direction map**. The four rungs stacked, with dependency arrows drawn between
them; a toggle reads the order top-down or as the dependency graph. The readout reports, for the
valid order, that every dependency arrow points downward (each rung rests on rungs below it).
Pure function: `arrowsDownward(order) -> {allDown, count}`. Frames the invariant.

## Main interactive (proves the consequence: reorder to expose a violation)

A **reorder-to-expose-violation checker** — the central, different-from-the-landing interactive.
A row of swap controls reorders the four rungs; for each permutation the checker validates
dependency order and, on a violation, names the first rung whose dependency now points upward and
paints it burgundy. Pure function: `validateOrder(perm) -> {ok, firstViolation}` where `perm` is
a permutation of the four story keys and `firstViolation` is the offending rung (or none). The
landing reads a fixed ascending ladder; this one lets the reader *break* the order and watch the
violation surface — a topological-order checker, not a stepper.

## Worked example (prose + code)

Dependency order as a predicate over a candidate order:

    deps = %{browse: [], enrol: [:browse], open: [:enrol], track: [:open]}

    valid_order? = fn order ->
      Enum.with_index(order)
      |> Enum.all?(fn {rung, i} ->
        below = Enum.take(order, i)            # rungs strictly below this one
        Enum.all?(deps[rung], &(&1 in below))  # every dependency is below
      end)
    end

    valid_order?.([:browse, :enrol, :open, :track])   # => true
    valid_order?.([:enrol, :browse, :open, :track])   # => false — enrol needs browse below it

## Bridge

- **principle:** Each rung depends only on rungs below it; the ladder is a topological order, and
  where value and dependency disagree, dependency wins.
- **practice (Portal):** browse, enrol, open a lesson, track progress is the only order that
  builds; reorder enrol before browse and the dependency points upward — no longer a ladder.

## Recap

Dependency order is the rule that each rung rests only on rungs below it, so value accrues from
the bottom up. With the order fixed, the last property follows: every prefix of the ladder runs.

## References

Sources (real, vetted — from the registry):
- Continuous Delivery — https://continuousdelivery.com/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- User Stories Applied — https://www.mountaingoatsoftware.com/books/user-stories-applied

Related in this course:
- /course/agile-agent-workflow/decomposition/value-ladder (A2.06 hub)
- /course/agile-agent-workflow/decomposition/value-ladder/compose-the-ladder (previous dive)
- /course/agile-agent-workflow/decomposition/value-ladder/always-runnable (next dive)
- /course/agile-agent-workflow/decomposition/invest (A2.03, Independent)
- /course/agile-agent-workflow/why/two-layers (A1.04, roadmap/spec)
- /elixir/course

## Wiring

- Crumbs: jonnify / Agile Agent Workflow / A2 · Decomposition / A2.06 / A2.06.2 · Dependency order
- Pager: prev = `/course/agile-agent-workflow/decomposition/value-ladder/compose-the-ladder`;
  next = `/course/agile-agent-workflow/decomposition/value-ladder/always-runnable`.
