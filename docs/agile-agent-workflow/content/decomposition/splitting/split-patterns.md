# A2.05.2 · Split patterns — deep dive

- **Route:** `/course/agile-agent-workflow/decomposition/splitting/split-patterns`
- **File:** `html/agile-agent-workflow/decomposition/splitting/split-patterns.html`
- **Accent:** sage (the constructive-pattern colour) over the gold system
- **Model copied from:** `html/agile-agent-workflow/why/two-layers/spec.html` (lesson)

## Lead

The signal says split; the patterns say where to cut. There are four reliable seams along which a
large story divides into smaller ones that each still deliver value: by workflow step, by business
rule, by happy and sad path, and by operation. Each is a vertical cut — down through store, domain,
and surface — so every slice is a whole capability a role can use, not a layer.

## Precise definitions (the four patterns)

- **by workflow step** — a story that walks a multi-step flow splits into one slice per step, each
  a complete thread. (Enrol → confirm → notify becomes three slices, each demoable.)
- **by business rule** — a story that holds several rules splits into one slice per rule: the base
  rule first, each refinement after. (Enrol with no limit, then enrol-with-a-seat-limit.)
- **by happy and sad path** — a story that has a success case and one or more failure cases splits
  into the happy path first, then each sad path. (Enrol successfully, then block a double enrolment.)
- **by operation** — a story that says "manage" splits into the CRUD operations it bundles: browse,
  add, edit, remove. Each operation is one rung.

Every pattern shares one rule: each resulting slice is **vertical and valuable** — small enough for
one rung, and still a story a role could be shown. A cut that yields a fragment (a layer) is the
wrong seam; that is the next dive.

## Worked Portal example

Two of the locked Portal stories carry two of the patterns. "manage the whole catalogue" splits **by
operation** into browse / add / edit / remove a course — each demoable, each one rung. "enrol in a
course" splits **by happy and sad path** into enrol successfully versus block a double-enrolment —
two slices, each a whole behaviour with its own acceptance. The other two patterns appear on the
same domain: enrol → confirm → notify is a workflow-step split; enrol-no-limit then
enrol-with-a-seat-limit is a business-rule split. Across all four, the slices rest on ids that are
already minted: `Portal.ID.generate/1` returns a typed id, `Portal.ID.decode/1` reads its `.type`
back. The /elixir course teaches the OTP internals; this course cuts the stories.

## Interactive 1 — hero (pick a pattern, read the slices)

A pattern selector over one too-big story.
- Controls (`#spPattern`): `by operation` (sage), `by happy / sad path` (sage), `by workflow step`
  (sage), `by business rule` (sage).
- Pure function: `slicesFor(patternKey) -> { story, slices:[name], count }` over a fixed dataset
  mapping each pattern to its Portal slice list.
- The figure renders one row per resulting slice, each tagged "1 rung".
- Readout (aria-live): "by operation → 'manage the whole catalogue' splits into 4 slices: browse,
  add, edit, remove. Each is one rung and demoable."
- Sample readout: `by operation -> 4 slices: browse, add, edit, remove. Each one rung, demoable.`

## Interactive 2 — main (every slice still delivers value)

A per-slice value check across the slices the chosen pattern produced.
- Control (`#spSlice`, slider over the slices of a fixed pattern — the operation split): step
  through browse / add / edit / remove.
- Pure function: `valueOf(sliceKey) -> { role, canDemo, value }` — each slice carries the role it
  serves and a yes/no "a role can demo this alone".
- The figure shows the selected slice, the role it serves, and a VALUE: yes marker (all four pass,
  because the seam was chosen to keep value intact).
- Readout: "add a course — serves the editor; a role can demo it alone → delivers value. 4 / 4
  slices deliver value."
- Sample readout: `add a course — serves the editor; demoable alone -> value. 4/4 slices deliver value.`

## The principle -> practice bridge

- **Principle:** a large story divides along one of four seams — workflow step, business rule,
  happy/sad path, operation — and each seam yields vertical slices that each still deliver value.
- **On the Portal:** "manage the whole catalogue" cuts by operation into browse/add/edit/remove;
  "enrol in a course" cuts by happy/sad path into enrol versus block-double-enrolment.

## Recap + forward pointer

Four patterns, one rule: cut along a seam that leaves every slice vertical and valuable. By
operation splits a "manage" story into its CRUD verbs; by happy/sad path splits a behaviour into
success and failure; by workflow step and by business rule split a flow and a rule-set. Next in
A2.05: A2.05.3 · Vertical, not horizontal — why the cut must stay end to end, and what the wrong
seam (DB / API / UI) costs.

## References — Sources (real, vetted)

- User Stories Applied — https://www.mountaingoatsoftware.com/books/user-stories-applied — patterns for splitting a story by value.
- Specification by Example — https://gojko.net/books/specification-by-example/ — slices defined by concrete examples of behaviour.
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/ — small, complete stories as the planning unit.

## Wiring

- Crumbs: jonnify / Agile Agent Workflow / A2 · Decomposition / A2.05 / A2.05.2 · Split patterns
- Pager: prev = `/decomposition/splitting/when-to-split` ; next = `/decomposition/splitting/vertical-not-horizontal`
- Related (built routes only): `/decomposition/splitting`, `/decomposition/value`,
  `/decomposition/value/vertical-slice`, `/decomposition/invest`, `/decomposition`, `/elixir/course`.
