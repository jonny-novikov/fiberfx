# A4.4.3 · INVEST and invariants

- **Route:** `/course/agile-agent-workflow/spec/to-stories/invest-and-invariants`
- **File:** `html/agile-agent-workflow/spec/to-stories/invest-and-invariants.html`
- **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`
- **Pager:** prev = `the-coverage-line` · next = hub `/spec/to-stories`

## Lead

A story is more than its Connextra sentence. Each carries an **INVEST line** — the six properties (Independent,
Negotiable, Valuable, Estimable, Small, Testable) compressed to a short gloss — and on it the story names the
invariants it `encodes` and a Priority and Size. The two parts of the line that matter for the spec contract:
**which invariants the story exercises**, and **whether it is testable**. A story that encodes no invariant and
is not testable accepts nothing.

## The worked example — F6.1-US2's INVEST line (verbatim)

US2: "valuable on its own (the first real page); testable by rendered output for the three cases; encodes
F6.1-INV1. Priority: must · Size: 3 · Implements deliverables: F6.1-D3, F6.1-D4, F6.1-D5." F6.1-INV1 is the
master invariant: "PortalWeb calls only the Portal facade and renders only the closed %Portal.Error{} set." The
`pre.code` block carries US2's INVEST line as markdown — no Elixir source.

## Hero interactive — read a story's INVEST line

**Intent:** frame the line itself. The reader picks US1…US5; the readout names the invariants the story encodes,
its Priority and Size, and whether it is testable (all verbatim from the F6.1 file).

- **Element ids:** `investPick` (US1…US5 buttons, first `active` with `data-c="elixir"`), `investOut` (readout),
  SVG ids `i-us1`…`i-us5`.
- **Fixed dataset:** `STORY = {us1:{enc:["INV2","INV3"],pri:"must",size:3,testable:true},
  us2:{enc:["INV1"],pri:"must",size:3,testable:true}, us3:{enc:["INV1","INV2"],pri:"must",size:2,testable:true},
  us4:{enc:["INV2"],pri:"should",size:2,testable:true}, us5:{enc:["INV4","INV5"],pri:"should",size:2,testable:true}}`
  — from each F6.1 story's INVEST line.
- **Pure functions:** `encodesFor(key)`, `readoutFor(key)`.
- **Sample readout:** `US2 encodes F6.1-INV1 (the master invariant). Priority: must · Size: 3 · Testable: yes.`

## Main interactive — does a story exercise this invariant?

**Intent:** prove the consequence — the encodes link is what ties a story to the rule it must not break. The
reader picks an invariant INV1…INV5; the readout names which stories encode it (the inverse of the encodes map)
and whether that invariant is therefore exercised by at least one story. The master invariant INV1 is encoded by
US2 and US3.

- **Element ids:** `invPick` (INV1…INV5 buttons), `encOut` (readout), SVG ids `v-inv1`…`v-inv5`.
- **Fixed dataset:** the inverse of STORY.enc — `ENCODED = {inv1:["US2","US3"], inv2:["US1","US3","US4"],
  inv3:["US1"], inv4:["US5"], inv5:["US5"]}`.
- **Pure functions:** `storiesEncoding(key)`, `isExercised(key)`, `readoutFor(key)`.
- **Sample readout:** `F6.1-INV1 (the master invariant) is encoded by US2, US3 — exercised by 2 stories, so it is
  pinned by a check.`

## The bridge

- **Principle:** each story names the invariants it encodes and whether it is testable; an invariant encoded by no
  testable story is unexercised.
- **On the Portal:** F6.1-US2 encodes the master invariant INV1 and is testable by rendered output — so the rule
  "the web layer calls only the facade" is pinned by an acceptance check, not merely asserted.

## References

- Sources: INVEST in Good Stories, User Stories Applied, Specification by Example.
- Related: hub, `the-coverage-line`, `deliverable-to-story`, `/decomposition/invest`, `/spec`, `/elixir/phoenix`.
