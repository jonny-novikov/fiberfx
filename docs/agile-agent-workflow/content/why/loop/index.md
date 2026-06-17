# A1.03 — The Author/Operator loop (module hub)

- **Route:** `/course/agile-agent-workflow/why/loop`
- **File:** `html/agile-agent-workflow/why/loop/index.html`
- **Place in the chapter:** the third module of A1. A1.01 named the unit (the thin slice); A1.02 re-read the
  principles that keep it ownable; A1.03 is the **motion** — the cycle, with its two roles, that produces one
  accepted rung and then the next.
- **Accent word (`.ex`):** "loop".

## Lead

The workflow has a shape you repeat: a loop between two roles. The Operator (human) sharpens, demos, reviews, and
gives feedback; the Author (Claude agent) turns the sharpened rung into a spec, builds it, and ships it. They meet
on the spec, and feedback edits that spec each turn. This module is the full treatment of that motion (A0.2.3
sketched it).

## The framing idea — two roles, one cycle, one meeting point

Ground every word in the established definitions (A0.2.3 is the source — do not redefine the roles):

- **Operator** — the human: the source of intent, judgement, and acceptance. Sharpens the next rung, demos,
  reviews, decides whether it is done. **Never writes the code.**
- **Author** — the Claude agent: the source of production. Turns the sharpened rung into a spec, builds the
  increment from the spec and brief, ships it — fast and exact. **Never decides the goal.**
- **Spec** — the contract both roles meet on (the A1.02.2 contract). Neither side proceeds on anything else.
- **Six stages**, owned by role: `sharpen` (O) → `build` (A) → `ship` (A) → `demo` (O) → `review` (O) →
  `feedback` (O), then the dashed **adapt** return: feedback edits the spec, and the loop runs again on the next
  rung.

## The framing figure (static, frames the module)

A vertical/looping figure of the six stages with the dashed `adapt` return from `feedback` to `sharpen`. Stages
are colour-coded by role — Operator stages gold, Author stages blue — with a central `spec` node where the two
roles meet. A legend names the role colours and the adapt return ("feedback edits the spec"). No controls — a hub
frames with one static figure; the lessons carry the live ones. Full `aria-label`.

## The three dives (the `.mods` grid)

- **A1.03.1 · The two roles** — `/why/loop/roles` — who owns what: the Operator decides the goal and acceptance;
  the Author produces the spec and the code. Neither crosses the line.
- **A1.03.2 · One turn of the loop** — `/why/loop/turn` — a single rung through the six stages, the handoffs
  between the roles, and what breaks when a stage is skipped.
- **A1.03.3 · Adapt: feedback edits the spec** — `/why/loop/adapt` — the return arc: feedback edits the spec, not
  the code, so the single source of truth stays intact and the loop compounds.

## Bridge / note / references

- **bridge:** principle — a repeatable cycle between a deciding role and a producing role → Portal — each rung
  (one branded id, then one stored event) runs the same loop: Operator sharpens + accepts, Author specs + builds.
- **note (forward, no dangling link):** mention the next module, **A1.04 · Two layers: roadmap and specs**, in
  prose; link only back to the A1 navigation (`/why`). Do not link A1.04 (not built).
- **sources (real):** Beck, *Extreme Programming Explained* (the planning/feedback loop, small releases);
  Schwaber & Sutherland, *The Scrum Guide* (the iterative cycle: review → retrospective → adapt); Anthropic,
  "Building effective agents" (the human-in-the-loop agent pattern).
- **related:** the three subpages; A0.2.3 (the loop sketch); A1.01 (the slice the loop produces); A1 (the chapter).

## Wiring

- route-tag `/course/agile-agent-workflow/why/loop`; crumbs jonnify / AAW / A1 (`/why`) / here.
- pager: prev → `/why` (A1 navigation); next → `/why/loop/roles` (A1.03.1).
- copy the head + header + 3-column footer + both trailing scripts verbatim from
  `html/agile-agent-workflow/why/pragmatic/index.html`. Spaced clamps; `.kicker` = serif/cream.
