# A4.2.1 · Which question? — deep-dive lesson

- **Route:** `/course/agile-agent-workflow/spec/the-triad/which-question`
- **Pager:** prev = hub `/course/agile-agent-workflow/spec/the-triad` · next = `.../the-triad/the-real-triad`
- **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`

## Lead

Each file in the triad answers one question and only one. Before naming the three real files, fix the three
questions. A specification of a rung must say: *what we build, and why, and when it is done*; *who wants it, and how
we will know it works*; and *how an agent builds it, with the proof gates*. Three questions — and one file per
question, so no document carries two jobs. The discipline is sorting a statement to the question it answers, then to
the file that owns that question.

## Precise definition

The three questions, drawn verbatim from the `specs.approach.md` artifact table:

- **what & why & done** — the contract. Answered by `fN.M.md` (Goal, Rationale, Scope, Deliverables, Invariants,
  Definition of Done). Audience: humans (author, reviewer).
- **who wants what, and how we'll know** — the user's side. Answered by `fN.M.stories.md` (Connextra stories,
  Given/When/Then, INVEST, Coverage). Audience: humans (product, QA).
- **how to build it, with proof gates** — the agent's side. Answered by `fN.M.llms.md` (References, Requirements,
  Execution topology, Agent stories, the implementation prompt). Audience: a coding agent.

A statement belongs to exactly one question. "An expected domain failure renders a `422`, never a `500`" answers
*what is done* (an invariant) — it is `.md`. "As a visitor, I want to open a course page" answers *who wants what* —
it is `.stories.md`. "Read the Phoenix endpoint docs first" answers *how to build* — it is `.llms.md`.

## Hero interactive — abstract question vs. one answer (the framing move)

The hero contrasts a vague "one big spec" with the three questions resolved. Select a **question**; the readout
collapses from "could be any of three files" to the single file that answers it.

- Control ids: `<div class="solid-select" id="wqSel">` with three buttons `data-q="what|who|how"`, `data-c="elixir"`.
- SVG: a single "one document?" block above three candidate files; selecting a question lights exactly one file and
  dims the other two — many candidates collapse to one.
- Pure functions over a fixed dataset:
  - `QUESTIONS = [{key:"what", file:"fN.M.md", ...}, {key:"who", file:"fN.M.stories.md", ...}, {key:"how", file:"fN.M.llms.md", ...}]`
  - `answerFor(key)` returns the one file + its real F6.1 instance + the audience.
- Live region: `<div class="geo-readout" id="wqOut" aria-live="polite">` — static default answers *what & why & done*.
- Sample readout: `"Question: what & why & done. One file answers it: fN.M.md — the spec (f6.1.md). For humans (author, reviewer). The other two files answer other questions; this one is not crammed with them."`

## Main interactive — sort a statement to its file (proves a consequence)

Given a fixed set of real statements, classify each as `.md` / `.stories.md` / `.llms.md`. The readout reports the
owning file and why — proving the per-question separation is checkable, not a slogan.

- Control ids: `<div class="solid-select" id="wqStmt">` buttons `data-s="0..4"`, `data-c="gold"`.
- A fixed dataset of five real statements drawn from the F6.1 triad (an invariant, a Connextra story, a deliverable,
  a Given/When/Then line, a Requirement), each tagged with its owning file.
- Pure function `fileFor(i)` over `STATEMENTS[i]` returns `{file, question, why}`.
- Live region: `<div class="geo-readout" id="wqStmtOut" aria-live="polite">`.
- Sample readout: `"\"PortalWeb calls only the Portal facade\" → answers what is done (an invariant) → lives in f6.1.md. A property, not a scenario; not a story, not a build step."`

## pre.code (NO CODE — a spec/stories markdown fragment)

A fragment showing one line per question, each tagged with its file — `.cmt` for the question, `.str` for the file,
`.res` for the F6.1 instance. No Elixir.

## The take and bridge

- `.take`: "One question per file: the spec says what is done, the stories say who wants it, the brief says how to build it — and a statement sorts to exactly one."
- `.bridge`: principle (a statement answers one question, so it lives in one file) → Portal practice (the F6.1 triad
  sorts cleanly — INV1 to `f6.1.md`, US2 to `f6.1.stories.md`, R1 to `f6.1.llms.md`).

## References

- Sources: Specification by Example (gojko.net), User Stories Applied (mountaingoatsoftware.com), Connextra template (agilealliance.org).
- Related: hub, the two sibling dives, `/spec`, `/what/four-artifacts`, `/why/two-layers`, `/elixir/phoenix`.
</content>
