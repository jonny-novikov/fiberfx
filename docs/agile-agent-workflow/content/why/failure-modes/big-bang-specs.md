# A1.01.2 — Big-bang specs

- **Route:** `/course/agile-agent-workflow/why/failure-modes/big-bang-specs`
- **File:** `html/agile-agent-workflow/why/failure-modes/big-bang-specs.html`
- **Place in the module:** the second dive of A1.01 "The two failure modes" — the **over-plan** failure.
- **Accent word (`.ex`):** "spec".

## Lead

One exhaustive specification, written before any code and before any feedback. The failure is not in specifying —
it is in the bigness and the timing.

## Definition

- **big-bang spec** — a complete specification authored up front, before any code and before any feedback. Large,
  and ageing from the moment it is declared done.
- **thin spec** (the contrast) — only enough definition for one slice: one behaviour, its invariants, its checks;
  small enough to ship and be answered within the week.
- The lesson is precise: this is **not** an argument against specifying. The failure is two properties of the
  big-bang form — its **bigness** and its **timing**.

## Why it fails — four forces

1. **Never finished** — completeness is unbounded, so the spec expands against a moving target.
2. **It drifts** — a document written before reality parts from reality and from the code; nothing re-checks it.
3. **No feedback until the end** — the cost of delay: every assumption stays unvalidated until the one big release.
4. **Risk is discovered last** — integration risk lands at the end, in one collision, where it is most expensive.

## Worked Portal example

A forty-page Portal specification that fixes the whole platform up front. For months it ships nothing; the
requirements move while it is written; by the time code starts it disagrees with the world and with itself (an
early section assumes one event shape, a later one another, with no executed check to reconcile them). Every force
visible at once. Portal references conceptual; no invented APIs.

## The two interactives

- **Hero figure — two timings of the first answer (the FRAME).** Two delivery lanes over the same span: big-bang
  returns its first feedback only at the end; thin slices return it in week one, then repeat. A static framing
  figure beside the hero.
- **Content figure — first-feedback timeline (the MEASURE).** Slider: weeks of spec before the first shippable
  increment (1…16). Plots when the first real feedback arrives for each plan; the band between is the weeks of
  assumptions carried unvalidated. `gap = weeks − 1`. (A future pass may make the hero figure interactive too.)

## Bridge / recap / references

- **bridge:** principle — a specification with no feedback is a guess that grows → Portal — the forty-page spec
  that ships nothing while the world moves.
- **take:** a plan you cannot test is not a plan you can trust; the longer it grows untested, the more confidently
  it points the wrong way.
- **sources (real):** Beck, *Extreme Programming Explained*; Humble & Farley, *Continuous Delivery*; Adzic,
  *Specification by Example*.
- **related:** A1.01.1 vibe-coding, A1.01.3 thin-slices, the A1.01 hub, A1.

## Wiring

- route-tag `/course/agile-agent-workflow/why/failure-modes/big-bang-specs`; crumbs jonnify / AAW / A1 (`/why`) /
  A1.01 (`/why/failure-modes`) / here. Pager: prev → A1.01.1 vibe-coding; next → A1.01.3 thin-slices.
