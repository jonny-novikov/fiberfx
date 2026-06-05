# A4.6 · Traceability — correct by definition (module hub)

- **Route:** `/course/agile-agent-workflow/spec/traceability`
- **File:** `html/agile-agent-workflow/spec/traceability/index.html`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Pager:** prev = `/course/agile-agent-workflow/spec` · next = `/course/agile-agent-workflow/spec/traceability/the-chain`.

## Lead

A roadmap ordered the work; a spec defines it; stories accept it; invariants pin it. A4.6 closes the chapter's
argument: completion is not a claim a person makes, it is a **closure** a rule verifies. The traceability chain is
the ledger that makes "done" checkable from the text alone — every deliverable realized by a story, every story
accepted by a check, every invariant proven, every requirement satisfied. When the chain closes, the rung is
"correct by definition"; when one link is missing, it is not done — and the gap is named, not guessed.

## Definition

**Traceability** is the property that every artifact carries a stable id and every id is reachable from intent to
proof. The chain (verbatim from `specs.approach.md`) runs:

```
Deliverable (fN.M.md  · FN.M-D#)
   └─ realized by → User story (fN.M.stories.md · FN.M-US#)
        ├─ accepted by → Acceptance criteria (Given/When/Then on the story)
        └─ encodes     → Invariant (fN.M.md · FN.M-INV#)
   └─ built by   → Agent story (fN.M.llms.md · FN.M-AS#)
        └─ governed by → Requirement (fN.M.llms.md · FN.M-R#)
             └─ proven by → Invariant (FN.M-INV#)  or  an acceptance test
```

The **completion rule** (verbatim): "A rung is done only when (a) every Deliverable maps to at least one User
story, (b) every User story's acceptance criteria pass, (c) every Requirement is satisfied, and (d) every
Invariant holds under test. 'Correct by definition' means exactly this closure: there is no behavior in the
increment that is not pinned by an acceptance check or an invariant, and no gate that is merely asserted rather
than run." This ties back to **A1.05** — "done" is a closure over traced, executed checks.

## Worked Portal example (F6.1, real ids — invent nothing)

The chapter's exemplar is the Portal's first web rung, F6.1. Its deliverables are D1…D7; its stories US1…US5; its
invariants INV1…INV5. The stories file ends with the Coverage line, verbatim:
`Coverage: D1→US1 · D2→US1,US3,US4 · D3→US2 · D4→US2,US3,US5 · D5→US2 · D6→US1 · D7→US4,US5.`
Every deliverable appears in that line, so the first clause of the completion rule holds for F6.1.

**Ground-truth note on F6.1-US2 (the route reconcile).** F6.1-US2 was first written as the draft user story "see a
user's courses", whose draft acceptance read "given a user id, when the page renders, then it lists that user's
courses". That draft named a `/courses/:user_id` page (one learner viewing an arbitrary user id's courses). F6.5
reconciled the surface to the protected `/my/courses` — a learner's own enrollments, read from the session, served
facade-only over the real function `Portal.courses_of/1`. The hero readouts for the `story` and `accept` links
frame F6.1-US2 as that F6.1 draft and carry the one-line F6.5 reconcile; the function `Portal.courses_of/1` is real
and unchanged — only the route name moved.

## Framing interactive (hero) — step the chain

- **Element ids:** `<div class="solid-select" id="tcLink">` with buttons `data-k="deliverable|story|accept|invariant|requirement"`, each `data-c="elixir"` (active first). SVG `class="dq"` with nodes `n-del`, `n-story`, `n-accept`, `n-inv`, `n-req` and link lines `l-del-story`, `l-story-accept`, `l-story-inv`, `l-del-req`, `l-req-proof`. Readout `id="tcOut"` (`aria-live="polite"`).
- **Pure functions:** `linkInfo(key)` over a fixed `LINK` dataset → `{lit:[nodeIds], text}`. The dataset names the five rungs of the chain with the real F6.1 ids (`F6.1-D4`, `F6.1-US2`, the Given/When/Then, `F6.1-INV1`, `F6.1-R#`).
- **Sample readout:** "deliverable → story · F6.1-D4 (the controller) is realized by F6.1-US2 — every deliverable maps to at least one story. The chain's first link holds."
- **Static default:** the `deliverable` step pre-lit; readout carries that line.

## Main interactive — break a link

- **Element ids:** `<div class="solid-select" id="tcBreak">` with buttons `data-k="whole|drop-story|drop-encodes"` (active = `whole`, `data-c="sage"` on whole, `data-c="burg"` on the break buttons). SVG `id="brSvg"` showing the F6.1 coverage as deliverable→story rows; the broken link renders dashed/red. Readout `id="brOut"`.
- **Pure functions:** `closureFor(mode)` over a fixed `COVERAGE` dataset (D1…D7 → stories, plus an encodes map) → `{done:boolean, gap:string, text}`. `whole` → done; `drop-story` removes D7's stories (an uncovered deliverable) → not done; `drop-encodes` removes a story's encodes link (an unreachable invariant) → not done.
- **Sample readout:** "Drop the story for F6.1-D7 → not done. D7 maps to no user story, so the completion rule's clause (a) fails. The chain has a hole; completion is a closure, not a claim."
- **Static default:** `whole` pre-lit; readout = "The chain closes: every deliverable maps to a story, every story to a check, every invariant is proven. Correct by definition."

## The bridge (principle → Portal practice)

- **idea:** Completion closes by a rule, not a claim — every deliverable traces to a story, an acceptance check,
  and an invariant; no behavior is unpinned, no gate merely asserted.
- **practice:** F6.1's Coverage line maps D1…D7 to US1…US5 and each story names the invariant it `encodes`; the
  rung is done only when the chain closes — read it, do not assert it.

## Take

Traceability turns "done" from an opinion into a closure: when every link in the chain resolves, the rung is
correct by definition; when one is missing, the rung is not done, and the gap is named.

## References — Sources (real, vetted)

- Specification by Example — `https://gojko.net/books/specification-by-example/`
- Continuous Delivery — `https://continuousdelivery.com/`
- User Stories Applied — `https://www.mountaingoatsoftware.com/books/user-stories-applied`

## Related in this course (resolving only)

- `/course/agile-agent-workflow/spec` (chapter landing)
- `/course/agile-agent-workflow/why/correct` (A1.05)
- `/course/agile-agent-workflow/decomposition/acceptance` (A2.04)
- `/elixir/phoenix` (the real F6 chapter)
- the three dives: `the-chain`, `the-closure`, `a-broken-link`
