# A1.04 — Two layers: roadmap and specs (module hub)

- **Route:** `/course/agile-agent-workflow/why/two-layers`
- **File:** `html/agile-agent-workflow/why/two-layers/index.html`
- **Place in the chapter:** the fourth module of A1. A1.03 set the loop in motion; A1.04 names the two planning
  layers the loop runs over — a roadmap that plans delivery, and a spec that defines and proves each rung.
- **Accent word (`.ex`):** "layers".

## Lead

The framework has two layers, and keeping them apart is the whole discipline. A roadmap plans *how we deliver* —
the sequence of rungs, coarse and re-plannable. A spec defines *what we build and how we know it is right* — fine,
authoritative, the single source of truth. The roadmap plans the spec; the spec builds the system.

## The framing idea — two layers over a core (ground in A0.2.1; do not redefine)

- **Roadmap layer** — answers *how we deliver*: milestones, iterations, the Author/Operator loop. It **points at**
  the spec; it **never defines behaviour**. Coarse and mutable.
- **Spec layer** — answers *what we build and how we know it is right*: for each rung, a precise spec, its user
  stories, and the agent brief. The **single source of truth**, **edited only by feedback**. Fine and authoritative.
- The relationship: the roadmap **plans** the spec; the spec **builds** the domain core. Derived from the spec —
  the user stories and the agent brief — and nothing edits those directly. The two layers move at different rates
  and answer different questions; conflating them is the failure this module guards against.

## The framing figure (static, frames the module)

A vertical stack of two layers over a base: **roadmap** (top, blue — "how we deliver") → **spec** (middle, gold,
marked "the single source of truth — what we build + prove") → **domain core** (base — "what ships"). Arrows:
"the roadmap plans the spec; the spec builds the core." A side note: user stories + agent brief derive from the
spec; feedback edits the spec. No controls — a hub frames with one static figure. Full `aria-label`.

## The three dives (the `.mods` grid)

- **A1.04.1 · The roadmap layer** — `/why/two-layers/roadmap` — *how we deliver*: the coarse, re-orderable plan of
  rungs that points at specs and never defines behaviour.
- **A1.04.2 · The spec layer** — `/why/two-layers/spec` — *what we build + prove*: the single source of truth, the
  hub every artifact (user stories, agent brief, code, tests) derives from.
- **A1.04.3 · The single source of truth** — `/why/two-layers/source` — the rule that keeps the layers stable: only
  feedback edits the spec; the two cadences; and what conflating the layers costs.

## Bridge / note / references

- **bridge:** principle — separate the plan of delivery from the definition of correctness → Portal — a roadmap of
  rungs (one id, then one stored event, …) over a spec per rung (the id contract), with the spec authoritative.
- **note (forward, no dangling link):** mention the next module, **A1.05 · Correct by definition**, in prose; link
  only back to the A1 navigation (`/why`). Do not link A1.05 (not built).
- **sources (real):** Cohn, *Agile Estimating and Planning* (release planning over a backlog); Schwaber &
  Sutherland, *The Scrum Guide* (the ordered product backlog vs the increment); Hunt & Thomas, *The Pragmatic
  Programmer* (the single source of truth).
- **related:** the three subpages; A0.2.1 (the two-layer model sketch); A1.03.3 (feedback edits the spec); A1.

## Wiring

- route-tag `/course/agile-agent-workflow/why/two-layers`; crumbs jonnify / AAW / A1 (`/why`) / here.
- pager: prev → `/why` (A1 navigation); next → `/why/two-layers/roadmap` (A1.04.1).
- copy the head + header + 3-column footer + both trailing scripts verbatim from
  `html/agile-agent-workflow/why/loop/index.html`. Spaced clamps; `.kicker` = serif/cream.
