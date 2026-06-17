# A2.05.1 · When to split — deep dive

- **Route:** `/course/agile-agent-workflow/decomposition/splitting/when-to-split`
- **File:** `html/agile-agent-workflow/decomposition/splitting/when-to-split.html`
- **Accent:** burgundy (the failing-signal colour) over the gold/sage system
- **Model copied from:** `html/agile-agent-workflow/why/two-layers/spec.html` (lesson)

## Lead

A split is a repair, and like every repair it has a trigger. The trigger is an INVEST failure:
a story that fails **Small** or **Estimable** is too big for one rung and must be split before it
is handed to the Author. This dive reads the signal — the failing letter — and shows that a
too-big story almost always hides a third symptom: it bundles several behaviours behind one
sentence, so nobody can say what "done" means.

## Precise definitions

- **the split signal** — a user story fails INVEST-Small (does not fit one rung) or
  INVEST-Estimable (its size makes the cost a guess). Either No is the trigger to split, read
  before any code is generated (ties A2.03, the readiness gate).
- **hidden behaviours** — a too-big story bundles several distinct behaviours behind one verb
  ("manage", "handle", "support"). Each hidden behaviour is a story in its own right; the count of
  them is the count of slices the split will produce.
- **the budget** — one rung is one turn of the Author/Operator loop: small enough to specify,
  build, and demo in one pass. A story over budget cannot be specified once, so it cannot be
  accepted once.

## Worked Portal example

On the Portal, "manage the whole catalogue" fails Small and Estimable. Read the verb: "manage"
hides four behaviours — browse, add, edit, remove a course. That is why it is unestimable: the
cost is the sum of four guesses, and a sum of guesses is a guess. The signal (fails S and E) and
the cause (four hidden behaviours) are the same fact seen twice. Contrast "enrol in a course",
which carries one behaviour, passes S and E, and ships as one rung. The ids the rungs rest on are
already minted — `Portal.ID.generate/1` hands back a typed id and `Portal.ID.decode/1` reads its
`.type` back — so the trigger is never "the identifiers are missing"; it is always "the story is
too big". The Portal's OTP internals are taught by the companion /elixir course.

## Interactive 1 — hero (the readiness gate rejects an oversize story)

A two-letter gate: Small and Estimable, scored for the selected story.
- Controls (`#wtsStory`): `enrol in a course` (gold), `browse the catalogue` (gold),
  `manage the whole catalogue` (burgundy), `manage one course` (burgundy).
- Pure function: `gate(storyKey) -> { small, estimable, pass }` over a fixed dataset of the four
  stories, each carrying `{small, estimable, behaviours}`.
- The two tiles (S, E) light when the story passes, dim when it fails.
- Readout (aria-live): passing → "enrol in a course — Small: pass, Estimable: pass. Fits one rung;
  hand over." failing → "manage the whole catalogue — Small: fail, Estimable: fail. Over budget;
  this is the signal to split."
- Sample readout: `manage the whole catalogue — Small: fail, Estimable: fail. Over budget; the signal to split.`

## Interactive 2 — main (count the hidden behaviours)

A behaviour counter: the same story, with its hidden behaviours revealed one per row.
- Control (`#wtsBeh`, slider 1..4): how many of the story's bundled behaviours to reveal.
- Pure function: `hidden(storyKey)` returns the ordered behaviour list; `verdict(n, total)` reports
  whether the count exceeds one rung.
- The figure stacks rows (browse / add / edit / remove for "manage the whole catalogue") and a
  one-rung budget line; crossing it flips a PASS/FAIL marker.
- Readout: "manage the whole catalogue bundles 4 behaviours behind one verb. 4 > 1 rung — split
  into 4. The failing letter S named the repair."
- Sample readout: `4 behaviours behind one verb · 4 > 1 rung — split into 4.`

## The principle -> practice bridge

- **Principle:** a story too big for one rung fails Small and Estimable; the failing letter is the
  trigger to split, and the hidden behaviours are the slice count.
- **On the Portal:** "manage the whole catalogue" fails S and E because "manage" hides four
  behaviours; the split produces four rungs. "enrol in a course" carries one and ships as is.

## Recap + forward pointer

The signal to split is an INVEST failure on Small or Estimable, read before any code is generated.
A too-big story hides several behaviours behind one verb, and the count of them is the count of
slices. Next in A2.05: A2.05.2 · Split patterns — the four vertical-slice patterns that turn the
signal into the cut.

## References — Sources (real, vetted)

- User Stories Applied — https://www.mountaingoatsoftware.com/books/user-stories-applied — when a story is too big, and how to keep it small.
- INVEST in Good Stories — https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/ — Small and Estimable as named tests.
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/ — splitting stories that do not fit an iteration.

## Wiring

- Crumbs: jonnify / Agile Agent Workflow / A2 · Decomposition / A2.05 / A2.05.1 · When to split
- Pager: prev = `/decomposition/splitting` (hub) ; next = `/decomposition/splitting/split-patterns`
- Related (built routes only): `/decomposition/splitting`, `/decomposition/invest`,
  `/decomposition/invest/small-and-independent`, `/decomposition/value`, `/decomposition`, `/elixir/course`.
