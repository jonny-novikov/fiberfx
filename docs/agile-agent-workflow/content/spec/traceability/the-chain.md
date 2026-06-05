# A4.6.1 · The chain — `the-chain`

- **Route:** `/course/agile-agent-workflow/spec/traceability/the-chain`
- **File:** `html/agile-agent-workflow/spec/traceability/the-chain.html`
- **Pager:** prev = `/course/agile-agent-workflow/spec/traceability` (hub) · next = `.../the-closure`.

## Lead

The traceability chain is the spine of "correct by definition". It links every artifact id from intent to proof:
a Deliverable is realized by a User story, the story is accepted by Given/When/Then and encodes an Invariant; the
Deliverable is also built by an Agent story governed by a Requirement, and the Requirement is proven by an
invariant or an acceptance test. This dive reads the chain link by link over F6.1's real ids.

## The chain (verbatim, rendered as a pre.code markdown diagram)

```
Deliverable (fN.M.md  · FN.M-D#)
   └─ realized by → User story (fN.M.stories.md · FN.M-US#)
        ├─ accepted by → Acceptance criteria (Given/When/Then on the story)
        └─ encodes     → Invariant (fN.M.md · FN.M-INV#)
   └─ built by   → Agent story (fN.M.llms.md · FN.M-AS#)
        └─ governed by → Requirement (fN.M.llms.md · FN.M-R#)
             └─ proven by → Invariant (FN.M-INV#)  or  an acceptance test
```

## Worked Portal example — walk F6.1

- **Deliverable F6.1-D4** — `PortalWeb.CourseController.index/2` reads `user_id`, calls only `Portal.courses_of/1`,
  renders the view.
- **realized by → F6.1-US2** "See a user's courses" (the visitor opens `/courses/:user_id`).
- **accepted by →** the Given/When/Then: "Given a known user id with enrollments, when I request the page, then it
  renders that user's courses."
- **encodes → F6.1-INV1 (master)** — the web layer calls only the `Portal` facade and renders only the closed
  `%Portal.Error{}` set.
- **built by → an Agent story** that implements US2; **governed by → a Requirement** carrying `[US: F6.1-US2]`;
  **proven by →** F6.1-INV1 or an acceptance test.

## Hero interactive — step each link of the chain

- **Element ids:** `<div class="solid-select" id="tcStep">` buttons `data-k="realized|accepted|encodes|built|governed|proven"`, `data-c="elixir"`. SVG `class="dq"` nodes `s-del`, `s-story`, `s-accept`, `s-inv`, `s-as`, `s-req`, `s-proof`; links `e-realized`, `e-accepted`, `e-encodes`, `e-built`, `e-governed`, `e-proven`. Readout `id="tcStepOut"`.
- **Pure functions:** `stepFor(key)` over a fixed `STEP` dataset (the six chain edges, each with its F6.1 ids and a verbatim verb) → `{lit:[ids], text}`.
- **Sample readout:** "encodes → F6.1-US2 encodes F6.1-INV1 (the master invariant), named on the story's INVEST line — so every invariant is reachable from a story."
- **Static default:** `realized` pre-lit.

## Main interactive — resolve a link from the text

- **Element ids:** `<div class="solid-select" id="resKey">` buttons `data-k="d4|us2|inv1"` (`data-c="gold|blue|elixir"`). Readout `id="resOut"`. A `pre.code` block carries the F6.1-D4 / F6.1-US2 / F6.1-INV1 lines verbatim.
- **Pure functions:** `resolveFor(id)` over a fixed `IDS` dataset → `{kind, where, links, text}` (e.g. `d4` → realized by US2, US3, US5 per the Coverage line `D4→US2,US3,US5`).
- **Sample readout:** "F6.1-D4 · a Deliverable in f6.1.md · realized by US2, US3, US5 (the Coverage line). Resolved from the text — no judgement needed."
- **Static default:** `d4` pre-lit.

## The bridge

- **idea:** Every artifact carries a stable id, so the path from intent to proof is explicit and walkable from the
  text — not inferred.
- **practice:** F6.1's ids (D4 → US2 → its Given/When/Then → INV1, and the Agent story → Requirement → proof) form
  one walkable chain over the real triad `f6.1.{md,stories.md,llms.md}`.

## Take

A chain of stable ids makes a rung readable end to end: pick any deliverable and you can walk it forward to the
check and the invariant that prove it, without guessing.

## References — Sources

- Specification by Example — `https://gojko.net/books/specification-by-example/`
- User Stories Applied — `https://www.mountaingoatsoftware.com/books/user-stories-applied`
- Continuous Delivery — `https://continuousdelivery.com/`

## Related

- `/course/agile-agent-workflow/spec/traceability` (hub)
- `/course/agile-agent-workflow/why/correct` (A1.05)
- `/course/agile-agent-workflow/decomposition/acceptance` (A2.04)
- `/elixir/phoenix`
