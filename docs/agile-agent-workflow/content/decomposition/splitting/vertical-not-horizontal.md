# A2.05.3 · Vertical, not horizontal — deep dive

- **Route:** `/course/agile-agent-workflow/decomposition/splitting/vertical-not-horizontal`
- **File:** `html/agile-agent-workflow/decomposition/splitting/vertical-not-horizontal.html`
- **Accent:** gold (right cut) versus burgundy (wrong cut) over the system
- **Model copied from:** `html/agile-agent-workflow/why/two-layers/spec.html` (lesson)

## Lead

Every pattern in the previous dive cut vertically — down through store, domain, and surface — for a
reason. A split has a direction, and only one direction yields stories. Cut **vertically** and each
slice is a whole thread a role can demo. Cut **horizontally** — the database, then the API, then the
UI — and each slice is one layer that no role can use until the last one lands. The wrong cut is
small but produces fragments; the right cut is small and produces stories. This dive draws the
contrast and ties it to A2.01.3, the vertical slice.

## Precise definitions

- **vertical slice** — one thin thread through every Portal layer (store, domain, surface) for a
  single story: enough of each layer to let a role do one new thing. Demoable, because it is end to
  end (the A2.01.3 definition).
- **horizontal slice** — one whole layer across the system (all the tables, or the whole API, or the
  entire page). Each is real and small, and none is demoable alone: there is no end-to-end thread.
- **fragment** — the output of a horizontal cut: a slice only another slice can use. It passes Small
  but fails Independent and, because it ships nothing a role can see, fails Valuable.
- **demoable end to end** — the property a split must preserve: each resulting slice can be shown to
  some role on its own. It is the test that tells a value slice from a layer.

## Worked Portal example

"manage the catalogue", cut the right way, becomes the value ladder: browse → enrol → open a lesson
→ track progress. Each rung threads all three layers for one story, so each is demoable the day it
lands. Cut the wrong way, the same work becomes the courses table → the courses API → the courses
page: three slices, each one layer, none demoable on its own — the table serves no learner, the API
serves no learner, and only when the page lands does anyone see anything. Same destination, same
total work, but the vertical cut keeps every slice shippable in isolation. The ids the slices rest on
are already minted with `Portal.ID.generate/1` and read back with `Portal.ID.decode/1`, so no slice
waits on another to define identifiers; what makes a horizontal slice wait is the layer boundary, not
the data. The /elixir course teaches the Portal's internals.

## Interactive 1 — hero (the wrong cut vs the right cut)

A direction toggle over one story.
- Controls (`#vnhCut`): `cut horizontally` (burgundy), `cut vertically` (gold).
- Pure function: `cut(direction) -> { slices:[{name, demoable}], demoableCount, total }` over a fixed
  dataset: horizontal → courses table / courses API / courses page (all not demoable); vertical →
  browse / enrol / open / track (all demoable).
- The figure renders one row per slice, tagged "demoable" (gold) or "fragment" (burgundy).
- Readout (aria-live): "cut horizontally → 3 slices, 0 demoable end to end. Each is a layer; no role
  can use one alone." / "cut vertically → 4 slices, 4 demoable end to end. Each threads all layers; a
  role can use every one."
- Sample readout: `cut horizontally -> 3 slices, 0 demoable. Each a layer, no role can use it alone.`

## Interactive 2 — main (which role can demo each slice)

A role-reach check across the slices of each cut.
- Control (`#vnhSlice`): a selector over the six slices (3 horizontal + 4 vertical, labelled by cut).
- Pure function: `reach(sliceKey) -> { cut, role, demoable }` — a vertical slice names the role it
  serves; a horizontal slice names "no role yet".
- The figure shows the selected slice, its cut, and whether any role can demo it.
- Readout: "browse the catalogue (vertical) → a learner can demo it. A whole capability." /
  "the courses API (horizontal) → no role can demo it yet. A fragment until the page lands."
- Sample readout: `the courses API (horizontal) -> no role can demo it. A fragment until the UI lands.`

## The principle -> practice bridge

- **Principle:** a split must stay vertical — every slice demoable end to end. Splitting by horizontal
  layer (DB / API / UI) yields fragments no role can use.
- **On the Portal:** "manage the catalogue" cut vertically is browse → enrol → open → track, each
  demoable; cut horizontally it is table → API → page, three fragments.

## Recap + forward pointer

A split has a direction. Vertical cuts thread all the Portal's layers for one story, so each slice is
a whole capability a role can demo; horizontal cuts take one layer at a time and leave fragments no
role can use until the last lands. The test is demoable-end-to-end: a slice a role could be shown is a
story; a slice only another slice can use is a layer. That closes A2.05: the signal to split is an
INVEST failure, the patterns name the seam, and the cut must always run vertically. The next module
turns ready, well-sliced stories into acceptance criteria.

## References — Sources (real, vetted)

- User Stories Applied — https://www.mountaingoatsoftware.com/books/user-stories-applied — splitting along value, not along components.
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/ — thin, complete stories over layered work.
- Specification by Example — https://gojko.net/books/specification-by-example/ — each slice carries demonstrable behaviour.

## Wiring

- Crumbs: jonnify / Agile Agent Workflow / A2 · Decomposition / A2.05 / A2.05.3 · Vertical, not horizontal
- Pager: prev = `/decomposition/splitting/split-patterns` ; next = `/decomposition/splitting` (back to hub)
- Related (built routes only): `/decomposition/splitting`, `/decomposition/value/vertical-slice`,
  `/decomposition/value`, `/decomposition/invest`, `/decomposition`, `/elixir/course`.
