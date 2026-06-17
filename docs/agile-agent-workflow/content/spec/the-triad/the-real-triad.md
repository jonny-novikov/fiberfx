# A4.2.2 · The real triad — `f6.1.{md,stories.md,llms.md}`

- **Route:** `/course/agile-agent-workflow/spec/the-triad/the-real-triad`
- **Pager:** prev = `.../the-triad/which-question` · next = `.../the-triad/the-course-itself`
- **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`

## Ground-truth note (refinement pass — spec citation chip)

Where the lead names the rung **F6.1**, that citation is framed with an inline `.specref` chip (label
"F6.1 · Bootstrap the Phoenix Portal", id `sr-realtriad-f61`) rather than a bare filename. The chip carries a
one-sentence tooltip — "The first web rung: stand the F5 engine up as a Phoenix app, with one facade-backed route
and a liveness route." — and a link to the spec-ladder viewer at `/course/agile-agent-workflow/spec/specimens`. The
link's href is the **bare** viewer route plus `data-sr-hash="f6-1"`; the page JS (`bindSpecrefs()`) appends the
`#f6-1` rung anchor on click, so it deep-links when enhanced and still resolves with JS off. The three file names
`f6.1.md` / `f6.1.stories.md` / `f6.1.llms.md` remain named in prose — they are the page's subject, the three
artifacts the chip's rung is specified by.

## Lead

The three questions are real files on the Portal. The first web rung — the **F6.1 · Bootstrap the Phoenix Portal**
spec citation chip — is specified by `f6.1.md`, `f6.1.stories.md`, and `f6.1.llms.md`. This dive reads each: its
scope, its audience, and its key sections, all verbatim from the `specs.approach.md` artifact table. The point is
not the Phoenix detail; it is that one rung's specification is exactly three files, and each file is shaped for one
reader.

## Precise definition

The artifact table, verbatim, with the F6.1 instance for each row:

- **`f6.1.md`** (the spec) — scope: one rung; audience: humans (author, reviewer); answers *what & why & done*; key
  sections: Goal · Rationale (5W) · Scope (In/Out) · Deliverables · Invariants · Definition of Done. On F6.1 its Goal
  reads "After F6.1, the Portal runs as a Phoenix app …"; it lists deliverables F6.1-D1…D7 and invariants
  F6.1-INV1…INV5, closing on the Definition of Done.
- **`f6.1.stories.md`** (the stories) — scope: one rung; audience: humans (product, QA); answers *who wants what, and
  how we'll know*; key sections: Connextra user stories · Given/When/Then acceptance · INVEST + `encodes` invariant
  link · the Coverage line. On F6.1 it carries five stories F6.1-US1…US5 and ends with the Coverage line
  `D1→US1 · D2→US1,US3,US4 · D3→US2 · D4→US2,US3,US5 · D5→US2 · D6→US1 · D7→US4,US5`.
- **`f6.1.llms.md`** (the agent brief) — scope: one rung; audience: a coding agent; answers *how to build it, with
  proof gates*; key sections: References · Requirements · Execution topology · Agent stories · the implementation
  prompt. On F6.1 it lists requirements F6.1-R1…R8, each carrying its `[US: …]` trace.

## Hero interactive — select an artifact, read its row (the framing move)

Select one of the three real files; the readout names its scope, audience, and key sections from the artifact table,
naming the F6.1 instance.

- Control ids: `<div class="solid-select" id="rtSel">` buttons `data-a="md|stories|llms"`, `data-c="elixir"`.
- SVG: three file cards (`#rt-md`, `#rt-stories`, `#rt-llms`); the selected card is lit, the other two dim.
- Pure functions over a fixed dataset:
  - `TRIAD = [{key:"md", file:"f6.1.md", scope:"one rung", audience:"humans (author, reviewer)", answers:"what & why & done", sections:"Goal · Rationale · Scope · Deliverables · Invariants · DoD", instance:"Goal: the Portal runs as a Phoenix app; D1…D7; INV1…INV5"}, ...]`
  - `rowFor(key)` returns the readout string.
- Live region: `<div class="geo-readout" id="rtOut" aria-live="polite">` — static default reads the `.md` row.
- Sample readout: `"f6.1.md (the spec) · scope: one rung · audience: humans (author, reviewer) · answers: what & why & done · sections: Goal · Rationale · Scope · Deliverables · Invariants · DoD · on F6.1: Goal \"the Portal runs as a Phoenix app\", deliverables D1…D7, invariants INV1…INV5."`

## Main interactive — locate a real F6.1 id in its file (proves a consequence)

Given a fixed set of real F6.1 ids (D6, INV1, US2, R1, the Coverage line), select one; the readout names which of the
three files holds it and what it says — proving the three files partition the whole specification with no overlap.

- Control ids: `<div class="solid-select" id="rtId">` buttons `data-i="0..4"`, `data-c="gold"`.
- A fixed dataset of five real F6.1 ids, each tagged with its file and a verbatim phrase:
  - `F6.1-D6` → `f6.1.md` — "a liveness route `get \"/health\", …` returning `200` … without touching the domain".
  - `F6.1-INV1` → `f6.1.md` — "PortalWeb calls only the Portal facade and renders only the closed %Portal.Error{} set".
  - `F6.1-US2` → `f6.1.stories.md` — "As a visitor, I want to open a course page for a given user".
  - `Coverage` → `f6.1.stories.md` — "D1→US1 · D2→US1,US3,US4 · …".
  - `F6.1-R1` → `f6.1.llms.md` — "PortalWeb.Endpoint exists as the outermost plug … [US: F6.1-US1]".
- Pure function `homeFor(i)` over `IDS[i]` returns `{file, text}`.
- Live region: `<div class="geo-readout" id="rtIdOut" aria-live="polite">`.
- Sample readout: `"F6.1-D6 lives in f6.1.md (the spec): \"a liveness route get /health returning 200 without touching the domain\". A deliverable — what we build — so it is in the contract file, not the stories or the brief."`

## pre.code (NO CODE — a spec/stories markdown fragment)

A fragment of the artifact-table rows: three lines, the file in `.str`, the question in `.cmt`, the F6.1 instance in
`.res`. No Elixir; this is markdown spec text only.

## The take and bridge

- `.take`: "One rung, three files — f6.1.md the contract, f6.1.stories.md the user's side, f6.1.llms.md the agent's brief — partitioning the whole specification with no overlap."
- `.bridge`: principle (a rung's specification is three files, one per question) → Portal practice (F6.1 is specified
  by exactly `f6.1.md` / `f6.1.stories.md` / `f6.1.llms.md`; every id sorts to one of the three).

## References

- Sources: Specification by Example (gojko.net), User Stories Applied (mountaingoatsoftware.com), Connextra template (agilealliance.org).
- Related: hub, the two sibling dives, `/spec`, `/what/four-artifacts`, `/why/two-layers`, `/elixir/phoenix`.
</content>
