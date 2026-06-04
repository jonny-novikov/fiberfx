# A2.07.2 · Split and test

- **Route:** `/course/agile-agent-workflow/decomposition/workshop/split-and-test`
- **File:** `html/agile-agent-workflow/decomposition/workshop/split-and-test.html`
- **Role:** dive 2 of the workshop. Apply splitting (A2.05) to the too-big stories; re-test each slice
  against INVEST until rung-sized.
- **Accent:** elixir-purple.

## Lead

The first story set left one story flagged too-big: "a learner tracks progress through a course." This dive
applies splitting to it, then re-tests every slice against INVEST. A split is finished not when the story is
smaller but when each slice passes the six tests on its own.

## Worked Portal example

The too-big story — "track progress through a course" — fails Small because it spans every lesson, the web
surface, the bot, and the dashboard at once. Split it **vertically**, by workflow step, so each slice still
delivers a usable change:

- slice A — "mark one lesson complete" (a learner finishes a lesson; it is recorded). Passes all six.
- slice B — "see a course's completion count" (a learner sees how many lessons are done). Passes all six.
- slice C — "see completed courses on the dashboard" (the dashboard surface). Passes all six.

Each slice is a vertical cut — a change a role can demonstrate — not a horizontal layer like "add a progress
table" that no one can demo. Re-tested against INVEST, the three slices each pass 6/6, where the parent
passed 4/6. The split is done.

The contrast that must be shown: a **horizontal** split ("the schema", "the context function", "the
LiveView") fails Valuable and Testable per slice — it slices the work, not the value. Splitting in this
workflow always cuts vertically.

## Hero interactive — split the too-big story

**Cut the parent into slices.** A control toggles between the un-split parent and the three vertical slices.
The figure shows the parent (INVEST 4/6, fails S) decomposing into three slices, each re-scored. The readout
reports the parent's failing letters and each slice's pass count.

- control ids: `#satView` (segmented, `data-k` = parent|sliceA|sliceB|sliceC)
- pure function: `sliceScore(key) -> { label, pass:int, fail:[letters], vertical:bool }`
- sample readout: "slice A — mark one lesson complete: a vertical slice, INVEST 6/6. The parent failed S (Small) and E (Estimable); this slice fits one rung."

## Main interactive — vertical vs horizontal split

**Choose the cut.** A control switches the same parent between a vertical split (three demoable slices) and a
horizontal split (schema / context / view). For each, the readout scores the slices against Valuable and
Testable and reports which cut yields rung-sized, demoable stories.

- control ids: `#satCut` (segmented, `data-k` = vertical|horizontal)
- pure function: `cutResult(kind) -> { demoableSlices:int, totalSlices:int, note }`
- sample readout: "horizontal cut — 0 of 3 slices are demoable on their own: a schema, a context function, and a view each fail Valuable and Testable. A horizontal cut slices the work, not the value."

## Principle ↔ practice bridge

- principle: a split is finished when every slice passes INVEST on its own, and a slice is a vertical cut of
  value, never a horizontal layer.
- practice: "track progress" splits into mark-complete, completion-count, and dashboard — three vertical
  slices, each INVEST 6/6; the horizontal alternative fails every slice.
- take: splitting converges when the slices pass the same readiness gate the parent failed — and only a
  vertical cut gets there.

## References (Sources — real, vetted)

- Cohn, M. — *User Stories Applied* — https://www.mountaingoatsoftware.com/books/user-stories-applied
- Adzic, G. — *Specification by Example* — https://gojko.net/books/specification-by-example/
- Humble & Farley — *Continuous Delivery* — https://continuousdelivery.com/

## Related (internal — must resolve)

- A2.03 invest; workshop hub; A2 landing; `/elixir/course`
- A2.07.1 vision-to-stories (prev), A2.07.3 order-the-backlog (next)
- (A2.05 splitting and A2.04 acceptance named in prose only — not linked.)

## Pager

- prev: `/course/agile-agent-workflow/decomposition/workshop/vision-to-stories`
- next: `/course/agile-agent-workflow/decomposition/workshop/order-the-backlog`
