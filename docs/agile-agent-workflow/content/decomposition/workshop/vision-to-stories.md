# A2.07.1 · Vision to stories

- **Route:** `/course/agile-agent-workflow/decomposition/workshop/vision-to-stories`
- **File:** `html/agile-agent-workflow/decomposition/workshop/vision-to-stories.html`
- **Role:** dive 1 of the workshop — *what & why*. Read the one-line F6 vision into its ladder of REAL
  stories. Grounded in the Portal's actual F6 (Phoenix) web decomposition, not a toy vision.
- **Accent:** elixir-purple.
- **Source of truth:** `docs/elixir/content/phoenix/index.md` (the nine-rung ladder) + `rungs.md` (the
  verbatim story + Given/When/Then per rung). Every story printed is quoted character-for-character from
  `rungs.md`; nothing is paraphrased.

## Lead

A unit of value is a change in what a role can do. The F6 web chapter is one product vision — **serve the
Portal to people** — and it decomposes into **nine rungs**, each a real user story owned by a real role:
operator, visitor, learner, developer, architect. Reading the vision into that ladder is the *what & why* of
decomposition: name the change each role gains, not the table or route the change happens to need.

## Worked Portal example (the nine-rung ladder)

The vision does not name a slice; it names a destination. Decompose it by asking, for each rung, *which role
gains what capability*. The answer is the rung's Connextra story, quoted verbatim from `f6.N.stories.md`:

1. **F6.1-US1 — operator.** "As an **operator**, I want the Portal to boot as a Phoenix application, so that
   I can run and serve it with the standard Elixir/Phoenix toolchain." The first rung is not "wire up an
   endpoint" — it is an operator who can now run the platform.
2. **F6.2-US4 — developer.** "As a **developer**, I want every internal URL verified at compile time, so that
   a renamed or mistyped route is a build error, not a broken link in production."
3. **F6.3-US1 — operator.** "As an **operator**, I want catalog and event data stored in PostgreSQL, so that
   nothing is lost when a node restarts or a new release is deployed." The value is durability, not a table.
4. **F6.4-US4 — developer.** "As a **developer**, I want contexts to call each other only through public
   functions, so that boundaries hold and the dependency graph stays acyclic."
5. **F6.5-US5 — learner.** "As a **learner**, I want validation errors shown on the form, so that I can fix a
   bad submission without losing context."
6. **F6.6-US1 — learner.** "As a **learner**, I want the course list to filter as I type, so that I find a
   course without submitting or reloading."
7. **F6.7-US1 — learner.** "As a **learner**, I want the catalog to update when someone else changes it, so
   that what I see stays fresh without reloading."
8. **F6.8-US1 — learner.** "As a **learner**, I want to create an account and sign in, so that I have a real
   identity on the platform."
9. **F6.9-US1 — operator.** "As an **operator**, I want course and enrollment counts that seed once and then
   update live, so that I read platform activity as it happens without ever re-querying."

Two more real roles appear off the spine and surface in the value/task classifier: a **visitor** (F6.1-US2,
"open a course page for a given user") and an **architect** (F6.5-US0, "each URL named after the resource it
returns"). Each rung calls only the unchanged `Portal` facade — the chapter built it in the companion
`/elixir/phoenix` course (F6.6's live search lands at `/elixir/phoenix/liveview`); here the work is reading
the vision into stories, not the code behind them.

## Hero interactive — vision → role-story reader

**Read the vision into one rung's real story.** A slider selects a rung (1–9). The figure highlights that rung
on the ladder and the readout prints its VERBATIM `As a <role>, I want… so that…` line plus the owning role,
straight from the nine-story dataset transcribed from `rungs.md`. The move is *reading*: the vision is one
sentence, each rung is a story a named role can use.

- control ids: `#v2sRung` (`<input type=range>` 1–9) + `#v2sRungVal` (the `F6.N` label)
- pure function: `storyFor(n) -> { id, role, story }` over the fixed nine-story dataset
- sample readout: "F6.6 · learner — As a learner, I want the course list to filter as I type, so that I find a
  course without submitting or reloading. (F6.6-US1, verbatim from f6.6.stories.md)"

## Main interactive — value vs. task classifier

**Test a line for value.** A segmented control presents candidate lines: real F6 stories (an operator who can
run the platform; a learner who sees errors inline; a visitor who can open a course page) mixed with
tautological task-phrasings ("add a courses table", "wire up a Phoenix route"). The classifier runs one test —
*does the line name a change a role can do?* — and the readout reports the verdict: a role-facing change passes
and is a story; a task names a chore with no role and fails. This is distinct from the hero (the hero *reads* a
known story; this *tests* an arbitrary line for value).

- control ids: `#v2sLine` (segmented, `data-k` = boot|errors|visit|table|route|search)
- pure function: `classify(key) -> { kind:'story'|'task', role|null, change|null, verdict }`
- sample readout: "\"add a courses table\" — TASK. Names a database chore, not a change a role can do: no role,
  no capability. Restate it as the value it serves before it becomes a story."

## Principle ↔ practice bridge

- principle (`.cell.idea`): a unit of value is a change in what a role can do — name the capability a role
  gains, never the table, route, or schema the change happens to need.
- practice (`.cell.elix`): the F6 vision "serve the Portal to people" reads into nine rungs, each a real
  user story owned by a real role — F6.6-US1, a learner who filters the catalog as they type.
- take: a vision becomes a backlog when every rung names a role and a change that role can use, quoted not
  invented.

## References (Sources — real, vetted; reuse the hub's three)

- Cohn, M. — *User Stories Applied* — https://www.mountaingoatsoftware.com/books/user-stories-applied
- Adzic, G. — *Specification by Example* — https://gojko.net/books/specification-by-example/
- Humble & Farley — *Continuous Delivery* — https://continuousdelivery.com/

## Related (internal — must resolve)

- `/elixir/phoenix` (the F6 chapter that builds the nine rungs)
- `/elixir/phoenix/liveview` (where F6.6's live search is built)
- workshop hub; A2.07.2 split-and-test (next dive); A2.01 value; A2.02 connextra; A2.03 invest; A2 landing
- `/elixir/course` (the Portal's internals)

## Pager (keep exact)

- prev: workshop hub `/course/agile-agent-workflow/decomposition/workshop`
- next: `/course/agile-agent-workflow/decomposition/workshop/split-and-test`
