# A2.03.1 · The six tests — dive

- **Route:** `/course/agile-agent-workflow/decomposition/invest/six-tests`
- **File:** `html/agile-agent-workflow/decomposition/invest/six-tests.html`
- **Accent:** gold
- **Position:** A2.03 · INVEST · dive 1

## Lead

INVEST reads as one word, but it is six independent yes/no questions. Asking them one at
a time turns a vague feeling that a story is "not ready" into a precise verdict: which of
the six it fails, and therefore what to fix.

## The six questions (each a yes/no)

- **Independent** — Can this be built and shipped without first finishing another story?
- **Negotiable** — Is the detail still open to a conversation, not frozen?
- **Valuable** — Does it change what a user can do, demonstrably?
- **Estimable** — Can the cost be guessed with any confidence?
- **Small** — Does it fit one rung — one build-and-demo turn?
- **Testable** — Is there a concrete way to confirm it is done?

A story that answers Yes to all six is ready to hand to the Author. One No is a repair
order, not a rejection.

## Worked Portal example

"As a learner, I can enrol in a course so that its lessons open for me."
- Independent: Yes — needs only a course id and a learner id, both already minted.
- Negotiable: Yes — the confirmation copy and the duplicate-enrol rule are still open.
- Valuable: Yes — the learner gains access they did not have.
- Estimable: Yes — one stored event plus a read check; a guessable cost.
- Small: Yes — one rung, demonstrable in a single turn.
- Testable: Yes — after enrol, the learner's enrolment list contains the course.

Six of six. Contrast "manage the whole catalogue": Independent No, Estimable No, Small No
— three letters fail at once, because size drags the others down.

## Hero interactive (frames the idea)

A six-letter INVEST strip. The reader switches which Portal story is under test; each of
the six tiles renders pass (lit) or fail (dim) for that story, and the readout reports the
pass count and the first failing letter.
- Dataset: four ladder stories (browse, enrol, open, track) + "manage the whole catalogue"
  + "add the courses DB table", each with a fixed six-boolean record.
- Pure function: `score(storyKey) -> {pass:int, fail:[letters], firstFail:letter|null}`.
- Sample readout: "enrol in a course — passes 6 / 6. Ready to hand over."
- Sample readout (fail): "manage the whole catalogue — passes 3 / 6. First failing letter: S (Small). Split it before handing over."

## Main interactive (proves a consequence)

A single-letter inspector: pick one of the six letters and read its yes/no question plus
the Portal story that most cleanly passes it and the one that most cleanly fails it. This
proves the consequence the hero only frames: each letter is a separate gate, so a story
can pass five and still be blocked by the sixth.
- Pure function: `letterCase(letter) -> {question, passStory, failStory, why}`.
- Sample readout: "S — Small: does it fit one rung? PASS: open a lesson. FAIL: manage the whole catalogue (months of work, not one turn)."

## Bridge

- **principle:** Read the six tests one at a time; the first No is the most useful output —
  it names the repair.
- **practice (Portal):** "enrol in a course" scores 6/6 and is built; "add the courses DB
  table" scores low on V and T-as-value, so it is folded back into the story it serves.

## References

Sources:
- INVEST in Good Stories — https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/
- User Stories Applied — https://www.mountaingoatsoftware.com/books/user-stories-applied
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/

Related:
- /course/agile-agent-workflow/decomposition/invest (hub)
- /course/agile-agent-workflow/decomposition/invest/story-smells (next)
- /course/agile-agent-workflow/why/two-layers (A1.04)
- /course/agile-agent-workflow/decomposition (A2)
- /elixir/course

## Wiring

- Pager: prev = hub (`/decomposition/invest`); next = `/decomposition/invest/story-smells`.
- Crumbs: jonnify / Agile Agent Workflow / A2 / A2.03 / A2.03.1 · The six tests.
