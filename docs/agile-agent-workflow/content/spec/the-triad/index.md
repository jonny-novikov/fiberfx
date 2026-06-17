# A4.2 · The triad: spec, stories, agent brief — module hub

- **Route:** `/course/agile-agent-workflow/spec/the-triad`
- **File:** `html/agile-agent-workflow/spec/the-triad/index.html`
- **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`
- **Pager:** prev = `/course/agile-agent-workflow/spec` · next = `/course/agile-agent-workflow/spec/the-triad/which-question`

## Ground-truth note (refinement pass)

The bare-filename citation of the spec in the kicker carries a **`.specref` chip** — frame label
**F6.1 · Bootstrap the Phoenix Portal**, a click-to-expand one-sentence description, and a link to the spec-ladder
viewer at `/course/agile-agent-workflow/spec/specimens`. The chip link is a **bare route** plus `data-sr-hash="f6-1"`
(JS appends `#f6-1` on click; no `#fragment` in the static href, so the `links` gate passes). The chip id is
`sr-triad-f61`. F6.1 is the first web rung: the F5 engine stood up as a Phoenix app with one facade-backed route and
a liveness route.

## Lead

A rung is not specified by one document. It is specified by **three**, each answering exactly one question.
`fN.M.md` answers *what & why & done*. `fN.M.stories.md` answers *who wants what, and how we will know*.
`fN.M.llms.md` answers *how to build it, with proof gates*. Cram all three into one file and the file serves no
reader well: the contract drowns in build steps, the stories drown in references. Keep them apart and each reads for
one audience and one purpose. The real triad to map is **F6.1 · Bootstrap the Phoenix Portal** —
`f6.1.{md,stories.md,llms.md}`, the spec for the Portal's first web rung (in the page, F6.1 is the `.specref` chip
that links into the spec-ladder viewer). The second triad, fittingly, is the course's own
`a4.{md,stories.md,llms.md}`: this chapter is a worked example of the artifact it teaches.

## Precise definition

The **triad** is the three-file specification of one rung. From the `specs.approach.md` artifact table, verbatim:

| File | Answers | Key sections |
| --- | --- | --- |
| `fN.M.md` | what & why & done | Goal · Rationale (5W) · Scope (In/Out) · Deliverables · Invariants · Definition of Done |
| `fN.M.stories.md` | who wants what, and how we'll know | User stories (Connextra) · acceptance (Given/When/Then) · INVEST + `encodes` invariant link · Coverage line |
| `fN.M.llms.md` | how to build it, with proof gates | References · Requirements · Execution topology · Agent stories · the implementation prompt |

In the file's own words: "The `.md` is the contract. The `.stories.md` makes the contract concrete from the user's
side. The `.llms.md` is the agent-facing brief."

## The framing interactive (hero) — question → artifact

Pick one of three questions; the readout names the artifact that answers it, over a fixed three-artifact dataset.

- Control ids: `<div class="solid-select" id="trqSel">` with three buttons `data-q="what|who|how"`, each `data-c="elixir"`.
- SVG: three stacked nodes (`#trq-md`, `#trq-stories`, `#trq-llms`); the selected one is lit elixir-purple, the others dim.
- Pure function over a fixed dataset:
  - `QMAP = { what: {file:".md", q:"what & why & done", ...}, who: {file:".stories.md", ...}, how: {file:".llms.md", ...} }`
  - `readoutForQuestion(q)` returns the readout string naming the artifact, its question, and its real F6.1 instance.
- Live region: `<div class="geo-readout" id="trqOut" aria-live="polite">` — static default answers *what & why & done* → `f6.1.md`.
- Sample readout: `"What & why & done → f6.1.md (the spec) · Goal, Rationale, Scope, Deliverables, Invariants, Definition of Done · the contract a Claude Author builds to and an Operator accepts by."`

## The take and bridge

- `.take`: "Three questions, three files — and a rung is specified only when all three are answered apart, not crammed into one."
- `.bridge`: principle (one artifact per question, no document crammed) → Portal practice (`f6.1.{md,stories.md,llms.md}` maps the three questions; this course's own `a4.*` is the same triad).

## References

- Sources (real, vetted): Specification by Example (gojko.net), User Stories Applied (mountaingoatsoftware.com), the Connextra template (agilealliance.org).
- Related in this course: the three dives, the landing `/spec`, `/what/four-artifacts`, `/why/two-layers`, `/elixir/phoenix`.
</content>
</invoke>
