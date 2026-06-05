# A4.7.3 · The closed spec (dive 3)

- **Route:** `/course/agile-agent-workflow/spec/workshop/the-closed-spec`
- **File:** `html/agile-agent-workflow/spec/workshop/the-closed-spec.html`
- **Pager:** prev `run-the-sequence` · next hub `/course/agile-agent-workflow/spec/workshop`.
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`. **Model:** `why/two-layers/spec.html` (lesson).

## Ground-truth note — F5.1 reference, no spec-ladder chip

This is a workshop page. It cites **F5.1 — Portal's engine-facade rung** (the engine chapter's first rung; the
seed of the F6 master invariant), which sits *below* the F6 web ladder shown by the `/spec/specimens` viewer.
There is no `#f5-1` stop on that viewer, so this page carries **no `.specref` chip**. F5.1 is named in prose
instead — "F5.1 — Portal's engine-facade rung" — and the engine it specifies is implemented in the companion
`/elixir` course (`/elixir/phoenix`, `/elixir/course`), kept as cross-links in References. The `f5.1.stories.md`
filename still appears as the page's illustrated subject (the Coverage line the figures render and the code block
quotes verbatim); those are figure/code labels, not bare citations.

## Grounding (verbatim from `f5.1.stories.md`)

The real Coverage line, verbatim:
`Coverage: D1→US1 · D2→US2 · D3→US1 · D4→US1,US3 · D5→US1,US4 · D6→US3,US5 · D7→US4.`

Every deliverable D1…D7 appears on the left of an arrow, so every deliverable is realized by at least one
story — the closure condition. A produced Coverage line is acceptable only when (a) every deliverable maps to
at least one story and (b) the chain holds; a deliverable absent from the map is a deliverable with no
covering story — the spec is not closed.

## Lead

A spec is acceptable not when its author declares it done but when it closes: every deliverable maps to a
story, every story has acceptance, and no gate is merely asserted. The workshop's last move checks that
closure on the produced Coverage line for **F5.1 — Portal's engine-facade rung** (the engine chapter's first
rung, the seed of the F6 master invariant) against the real one. If they match and every deliverable is
present, the spec is closed and acceptable — the engine chapter's first rung is ready for an Author. If a
deliverable is missing from the map, the readout names the gap. This is "correct by definition" (A1.05) made
operational on a real rung.

## Hero interactive — check the produced Coverage line

Hero figure: the seven deliverables D1…D7 with their covering stories from the Coverage line, plus a toggle
to drop one deliverable's story (simulate an incomplete `.stories.md`). The readout reports "closed /
acceptable" when all seven are covered, or names the uncovered deliverable when one is dropped. Teaches: the
spec closes by a rule over the text, not by a claim.

- Fixed dataset `COVER` (seven entries from the Coverage line): D1→US1, D2→US2, D3→US1, D4→US1,US3,
  D5→US1,US4, D6→US3,US5, D7→US4.
- Pure `uncovered(dropped)` (returns the list of deliverables with no story) and `closureReadout(dropped)`
  → string.
- Static default: nothing dropped; readout reports "closed · acceptable · 7 of 7 deliverables covered".
- Control ids: `covSel` (eight buttons: "none" + d1…d7, `data-c=elixir|gold`); SVG rows `cov-d1`…`cov-d7`;
  readout `covOut` (`aria-live`).

## Main interactive — match the produced line against the real one

Main figure: the produced Coverage line beside the real one. Toggle between a faithful reproduction and a
drifted one (one arrow altered, e.g. D6→US3 only, dropping US5). The readout reports "matches the real
`f5.1.stories.md` · acceptable" or names the divergence. Teaches the consequence: the workshop output is
acceptable only when it reproduces the real line — the spec is checked against ground truth, never asserted.
Different move from the hero (which tests coverage completeness); this tests fidelity to the real artifact.

- Fixed dataset: the real Coverage string, and one drifted variant.
- Pure `matchReadout(variant)` → string.
- Static default: `faithful` selected; readout reports a match.
- Control ids: `mchSel` (two buttons `data-k=faithful|drift`, `data-c=elixir|gold`); SVG rows `mch-prod`,
  `mch-real`; readout `mchOut` (`aria-live`).

## pre.code (markdown only)

The real Coverage line plus the completion rule sentence from the F5.1 grounding — rendered with
`.cmt`/`.str`/`.res` spans. No Elixir source.

## Bridge

- **The principle** — a spec closes by a rule over its text: every deliverable maps to a story, the chain
  holds, no gate is merely asserted. Completion is a closure, not a claim.
- **On the Portal** — the produced Coverage line reproduces the real `f5.1.stories.md`
  (`D1→US1 · D2→US2 · …`); all seven deliverables are covered, so F5.1 is acceptable as written.
- **Take** — the workshop ends when the chain closes and matches ground truth — the engine chapter's first
  rung, correct by definition.

## References

- Sources: Specification by Example (`gojko.net`), Continuous Delivery (`continuousdelivery.com`), User
  Stories Applied (`mountaingoatsoftware.com`).
- Related: hub, `/course/agile-agent-workflow/spec`, `/course/agile-agent-workflow/why/correct`,
  `/elixir/phoenix`, `/elixir/course`.
