# A1.01.3 — Thin slices

- **Route:** `/course/agile-agent-workflow/why/failure-modes/thin-slices`
- **File:** `html/agile-agent-workflow/why/failure-modes/thin-slices.html`
- **Place in the module:** the third dive and the **resolution** of A1.01 "The two failure modes". A1.01.1 was too
  little plan (vibe coding); A1.01.2 was too much (the big-bang spec); this is the unit between them.
- **Accent word (`.ex`):** "slice".

## Lead

A thin slice is the unit that escapes both failures: one vertical cut through every layer that delivers a small
piece of real, acceptable value — specified only enough to be proven, shipped before the next begins.

## The idea, defined precisely

- **thin slice** — one VERTICAL cut through every layer (interface, logic, data) that delivers one small, usable,
  acceptable piece of value. Opposed to a HORIZONTAL layer (all of one tier — shippable to no one).
- **INVEST** — the test of a good slice: **I**ndependent, **N**egotiable, **V**aluable, **E**stimable, **S**mall,
  **T**estable.
- **tracer bullet** — a minimal end-to-end path built first, wired through every layer, so the architecture is
  proven early on something real (Hunt & Thomas).
- **walking skeleton** — the smallest implementation that exercises the whole system end to end, then grows.

## Why it works — four forces, each answering a failure

1. **Provable** — small enough to specify only enough and prove. Answers vibe coding's "no definition of done":
   the slice carries the checks that accept it.
2. **Feedback now** — each slice returns reality immediately. Answers the big-bang spec's silence: the first
   answer arrives in week one, not at the end.
3. **Correct by definition** — accepted before the next begins, so correctness is a property held at every step,
   never deferred.
4. **Compounding correctness** — each slice is built on an already-accepted one. The exact mirror of vibe coding's
   compounding entropy: confidence accumulates instead of leaking.

## Worked Portal example

The first rung is not "the store". It is **one branded Snowflake id** — specified by its invariants (a 14-char
`TSK…`-style id whose embedded timestamp, node, and sequence decode back correctly and never collide within a
node-millisecond), proven by one test, and shipped. The next slice — say, storing one event — is built on that
accepted rung. Each rung is a vertical cut: it touches the id format (data), the generator (logic), and the value
a caller receives (interface). Keep Portal references consistent with the established branded-id convention; do not
invent unrelated APIs. A minimal illustrative code block is welcome (an id and an assertion that it decodes).

## The two interactives (different teaching moves)

- **Hero figure — vertical vs horizontal (the SHAPE).** A small grid: rows = layers (interface / logic / data),
  columns = features. A `.solid-select` toggle switches between a HORIZONTAL selection (one full row — every
  feature's data layer) and a VERTICAL selection (one column — one feature through all three layers). Highlight the
  selected cells; compute shippable value truthfully: vertical = 1 working, acceptable feature; horizontal = 0
  shippable features (nothing a user can use yet). Readout states which delivers value and why.
- **Content figure — the value ladder (the CONSEQUENCE).** A slider for "increment now built" (1…6). For the
  thin-slice plan, cumulative shipped, accepted value rises one rung at a time from week one; for a big-bang plan,
  it stays at zero until the final release, then jumps (if it works at all). Plot both as step functions; the
  readout states the accepted value shipped so far under each plan. Truthful pure function: `thinValue = builtRungs`,
  `bigValue = (builtRungs >= total ? total : 0)`.

## The bridge (principle → Portal)

- **principle:** value is delivered in thin, vertical, provable slices — specified only enough, proven, then the
  next.
- **on the Portal:** the first rung is one branded id, specified by its invariants, proven by a test, shipped;
  every later rung is a slice built on an accepted one.
- **take:** a thin slice is small enough to prove and large enough to matter — the only unit that is both shippable
  and certain.

## Recap (synthesis of the module)

Too little plan ships the unspecifiable; too much plan ships nothing. The slice is the minimum between them: the
smallest vertical cut that is still worth shipping and still possible to prove. It is the shape every later rung in
the course takes — and the unit the whole Author/Operator loop exists to produce.

## References

**Sources (real — do not fabricate):**
- Cohn, M. — *User Stories Applied* — INVEST and the thin, vertical slice of value.
  (https://www.mountaingoatsoftware.com/books/user-stories-applied)
- Hunt & Thomas — *The Pragmatic Programmer* — tracer bullets and walking skeletons.
- Adzic, G. — *Specification by Example* — specify by concrete, acceptable examples.
  (https://gojko.net/books/specification-by-example/)

**Related in this course:**
- A1.01.1 · Vibe coding — `/course/agile-agent-workflow/why/failure-modes/vibe-coding`
- A1.01.2 · Big-bang specs — `/course/agile-agent-workflow/why/failure-modes/big-bang-specs`
- A1.01 · The two failure modes (hub) — `/course/agile-agent-workflow/why/failure-modes`
- A0.2.1 · The two-layer model — `/course/agile-agent-workflow/what/two-layer-model`
- A1 · Why an agile agent workflow — `/course/agile-agent-workflow/why`

## Wiring

- **route-tag:** `/course/agile-agent-workflow/why/failure-modes/thin-slices`
- **crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) / A1 · Why (`/why`) /
  A1.01 (`/why/failure-modes`) / here "A1.01.3 · Thin slices"
- **pager:** ghost prev → `/course/agile-agent-workflow/why/failure-modes/big-bang-specs` "A1.01.2 · Big-bang specs";
  solid next → `/course/agile-agent-workflow/why/failure-modes` "A1.01 · Module overview".
