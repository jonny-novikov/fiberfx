# A2.05 · Splitting stories that are too big — module hub

- **Route:** `/course/agile-agent-workflow/decomposition/splitting`
- **File:** `html/agile-agent-workflow/decomposition/splitting/index.html`
- **Numbering:** A2.05 (chapter A2 Decomposition, module 5)
- **Accent:** gold (module signature); each dive carries its own interactive colour
- **Model copied from:** `html/agile-agent-workflow/why/two-layers/index.html` (module hub)

## Lead

INVEST (A2.03) reads a story before it is built and returns a verdict. When a story fails
**Small** or **Estimable** it is too big for one rung — and the repair is not to shrink the
words but to *split* the story into several that each still deliver value. This module is the
how of that split: the vertical-slice patterns that cut a large story into shippable ones
without slicing it into horizontal layers no role can demo. It is the payoff of the forward
pointer A2.03.3 left ("the mechanics of the cut are A2.05").

## What the module argues

A split is a transformation on a story: one too-big story in, several ready stories out, and
the sum of the parts is the whole. A good split has two properties: every part passes Small and
Estimable (so it fits one rung), and every part is still **valuable** and **demoable end to end**
(so it is a story, not a fragment). The patterns in this module — by workflow step, by business
rule, by happy and sad path, by operation — all cut **vertically**, down through the Portal's
store, domain, and surface, so each slice is a whole capability. The anti-pattern, splitting by
horizontal layer (the courses table, then the API, then the page), is small but leaves fragments
no role can use — the subject of the closing dive.

## The framing interactive (hub)

A story-size meter over the Portal ladder. Controls: pick one of four candidate stories
(`browse the catalogue`, `enrol in a course`, `manage the whole catalogue`, `manage one course`).
The figure reports the story's rung-count estimate against the one-rung budget and whether it must
be split. Pure function `splitVerdict(storyKey) -> { rungs, fits, verdict }` over a fixed dataset;
live `.geo-readout` (aria-live). Small stories report "fits one rung — hand over"; too-big stories
report "exceeds one rung — split into N rungs". Degrades: the SVG and the default story render in
static markup; JS only re-renders on selection. The hub interactive frames *when* a split is
needed; the dives prove *how* it is done and *which way* it must cut.

## The three dives (the "Dives into" grid)

1. **A2.05.1 · `when-to-split`** → `/decomposition/splitting/when-to-split`
   The signal to split: a story fails INVEST-Small or INVEST-Estimable (ties A2.03) — too big for
   one rung, impossible to estimate, hiding multiple behaviours behind one sentence. The repair is
   a split, read off the failing letter.

2. **A2.05.2 · `split-patterns`** → `/decomposition/splitting/split-patterns`
   The four vertical-slice patterns: by workflow step, by business rule, by happy and sad path, by
   operation (browse / add / edit / remove). Each pattern produces stories that each still deliver
   value.

3. **A2.05.3 · `vertical-not-horizontal`** → `/decomposition/splitting/vertical-not-horizontal`
   Every slice must stay demoable end to end (ties A2.01.3 vertical slice). Splitting by horizontal
   layer (DB / API / UI) yields fragments no role can use. The wrong cut versus the right cut.

## Wiring

- **Crumbs:** jonnify / Agile Agent Workflow / A2 · Decomposition / A2.05 · Splitting stories that are too big
- **Pager:** prev = `/course/agile-agent-workflow/decomposition` ; next = `/course/agile-agent-workflow/decomposition/splitting/when-to-split`
- **Related in this course (already-built routes only):** `/decomposition`, `/decomposition/invest`,
  `/decomposition/value`, `/why/two-layers`, `/elixir/course`.
- Sibling modules being built in parallel (acceptance, value-ladder, workshop) are referenced in
  prose only — never linked.

## References — Sources (real, vetted)

- User Stories Applied — https://www.mountaingoatsoftware.com/books/user-stories-applied — splitting a story along value.
- Specification by Example — https://gojko.net/books/specification-by-example/ — slices defined by concrete behaviour.
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/ — small stories as the unit of planning.
