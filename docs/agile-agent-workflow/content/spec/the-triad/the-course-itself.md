# A4.2.3 · The course itself — `a4.{md,stories.md,llms.md}`

- **Route:** `/course/agile-agent-workflow/spec/the-triad/the-course-itself`
- **Pager:** prev = `.../the-triad/the-real-triad` · next = hub `/course/agile-agent-workflow/spec/the-triad`
- **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`

## Lead

The triad is not only the shape of a Portal rung's spec. It is the shape of this chapter's own spec. Chapter A4 — the
spec layer you are reading — is itself specified by three files: `a4.md` (the chapter contract), `a4.stories.md` (who
wants the chapter and how we'll know), and `a4.llms.md` (the brief a Claude Author builds the pages from). The course
is a worked example of the artifact it teaches: the same three questions, the same three files, one level up.

## Precise definition

The self-referential second triad maps to the same artifact table:

- **`a4.md`** answers *what & why & done* for the chapter: its Goal ("After A4, the reader can write a spec for a rung
  and the stories that accept it"), its Rationale (5W), Scope, Deliverables (the landing plus modules A4.1–A4.7),
  Invariants, and Definition of Done.
- **`a4.stories.md`** answers *who wants what, and how we'll know*: Connextra stories for three roles — the learner,
  the developer, and the Claude Author — each with Given/When/Then acceptance, at chapter, module, and dive levels.
- **`a4.llms.md`** answers *how to build it, with proof gates*: the references, the module structure, the no-invent
  grounding, and the gate command an Author runs to verify each page.

So the same triad describes a Portal rung (`f6.1.*`) and a course chapter (`a4.*`). The questions do not change with
the subject. A specification of *anything buildable and acceptable* is what-and-why-and-done, who-wants-what, and
how-to-build — three files.

## Hero interactive — the two triads side by side (the framing move)

Select a **question**; the readout names both instances at once — the Portal rung file and the course chapter file —
showing the triad is the same shape at two levels.

- Control ids: `<div class="solid-select" id="ciSel">` buttons `data-q="what|who|how"`, `data-c="elixir"`.
- SVG: two columns of three nodes — left "a Portal rung" (`#ci-f-md`, `#ci-f-stories`, `#ci-f-llms`), right "this
  course" (`#ci-a-md`, `#ci-a-stories`, `#ci-a-llms`); selecting a question lights the matching row across both columns.
- Pure functions over a fixed dataset:
  - `PAIRS = { what: {portal:"f6.1.md", course:"a4.md", q:"what & why & done"}, who: {portal:"f6.1.stories.md", course:"a4.stories.md", ...}, how: {portal:"f6.1.llms.md", course:"a4.llms.md", ...} }`
  - `pairFor(q)` returns the readout string naming both files and the question.
- Live region: `<div class="geo-readout" id="ciOut" aria-live="polite">` — static default reads the *what* row.
- Sample readout: `"What & why & done → the .md file. On a Portal rung: f6.1.md (the spec). On this course: a4.md (the chapter spec). Same question, same file role, two levels — a rung and a chapter."`

## Main interactive — does the chapter's own triad close? (proves a consequence)

A4's Definition of Done says the chapter is done when its own triad reads as a spec that passes the traceability
rule. Step the three files of `a4.*` and the readout reports whether each question is answered — proving the course
holds itself to the artifact it teaches.

- Control ids: `<div class="solid-select" id="ciCheck">` buttons `data-f="md|stories|llms"`, `data-c="gold"`.
- A fixed dataset of the three `a4.*` files, each with the question it answers and whether it is present (all three
  present → the triad is closed).
- Pure function `closureFor(key)` over `A4_FILES[key]` returns `{answered, note}`, and a `closedCount()` reporting
  3-of-3.
- Live region: `<div class="geo-readout" id="ciCheckOut" aria-live="polite">`.
- Sample readout: `"a4.stories.md answers who wants what (the learner, the developer, the Claude Author) — present. The chapter's triad: 3 of 3 questions answered. The course is specified by the artifact it teaches."`

## pre.code (NO CODE — a spec/stories markdown fragment)

A fragment lining up the two triads: `f6.1.*` and `a4.*`, three rows, the question in `.cmt`, the files in `.str`.
No Elixir; markdown spec text only.

## The take and bridge

- `.take`: "The same three questions specify a Portal rung and this chapter — a4.md, a4.stories.md, a4.llms.md are the triad, one level up."
- `.bridge`: principle (the triad specifies anything buildable and acceptable, at any level) → Portal practice (the
  Portal rung F6.1 and the course chapter A4 are each specified by the same three-file triad; the course is a worked
  example of its own lesson).

## References

- Sources: Specification by Example (gojko.net), User Stories Applied (mountaingoatsoftware.com), Connextra template (agilealliance.org).
- Related: hub, the two sibling dives, `/spec`, `/what/four-artifacts`, `/why/two-layers`, `/elixir/phoenix`.
</content>
