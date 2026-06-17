# A1.02 — Pragmatic Programming, revisited for agents (module hub)

- **Route:** `/course/agile-agent-workflow/why/pragmatic`
- **File:** `html/agile-agent-workflow/why/pragmatic/index.html`
- **Place in the chapter:** the second module of A1 "Why an Agile Agent Workflow". A1.01 named the two
  failure modes and the slice that escapes them; A1.02 re-reads the pragmatic canon for a world where an agent
  writes the code — what changes, and what does not.
- **Accent word (`.ex`):** "code".

## Lead

The Pragmatic Programmer's habits were written for a person typing every line. When a Claude agent types them
instead, the principles do not disappear — three of them get *more* important, because the cost of producing
code falls and the cost of owning it does not. This module re-reads the canon through that one inversion.

## The framing idea — the inversion

One sentence carries the module: **when generation is cheap, the things that were always expensive get
relatively more expensive.** Typing code, duplicating it, and adding surface area all got cheaper; keeping it
consistent, specifying it precisely, and bounding a change's blast radius did not. So three pragmatic
principles are re-weighted upward, each becoming a discipline the human owns and the agent is pointed at:

1. **DRY** → *the single source of truth*. Duplication is cheap to generate and expensive to reconcile; the
   human keeps one authority and points the agent at it.
2. **Design by Contract** → *the contract is the spec*. A precise pre/post/invariant triple is exactly the
   well-specified unit an agent implements and you accept against.
3. **Orthogonality** → *decoupling for review*. Independent modules keep a change's blast radius small enough
   that an agent's diff stays reviewable.

## The framing figure (static, frames the module)

A two-band figure titled "When generation is cheap, the bill moves." Top band, "cheaper to produce" (arrows
down): writing code, duplicating knowledge, adding surface area. Bottom band, "more expensive to own" (arrows
up): drift, ambiguity, blast radius. At the crossing sit the three principles (DRY / Contract / Orthogonality),
each a labelled node bridging the band it answers. No controls — a hub frames with one static figure; the
lessons carry the live ones. `aria-label` describes the inversion in full.

## The three dives (the `.mods` grid)

- **A1.02.1 · The single source of truth** — `/why/pragmatic/dry` — DRY re-read: duplication is a drift
  surface the agent creates for free and you reconcile by hand.
- **A1.02.2 · Design by contract** — `/why/pragmatic/contracts` — the pre/post/invariant triple as the precise
  specification an agent implements against and you accept against, without reading every line.
- **A1.02.3 · Orthogonality and blast radius** — `/why/pragmatic/orthogonality` — decoupling keeps a change's
  blast radius small, so an agent's diff stays inside what one human can review.

## Bridge / note / references

- **bridge:** principle — the pragmatic canon holds, but generation re-weights it → Portal — one id authority
  (`Portal.ID`), one id contract, surfaces behind facades.
- **note (forward, no dangling link):** mention the next module, **A1.03 · The Author/Operator loop**, in prose
  and link only back to the A1 navigation (`/why`). Do not link A1.03 (not built).
- **sources (real):** Hunt & Thomas, *The Pragmatic Programmer* (the canon: DRY, Design by Contract,
  Orthogonality); Meyer, *Object-Oriented Software Construction* (Design by Contract / Eiffel); Parnas,
  *On the Criteria To Be Used in Decomposing Systems into Modules* (CACM 1972, decoupling).
- **related:** the three subpages; A1.01 (the two failure modes); A1 (the chapter).

## Wiring

- route-tag `/course/agile-agent-workflow/why/pragmatic`; crumbs jonnify / AAW / A1 (`/why`) / here.
- pager: prev → `/why` (A1 navigation); next → `/why/pragmatic/dry` (A1.02.1).
- copy the head + header + 3-column footer + both trailing scripts verbatim from
  `html/agile-agent-workflow/why/failure-modes/index.html`. Spaced clamps; `.kicker` = serif/cream.
