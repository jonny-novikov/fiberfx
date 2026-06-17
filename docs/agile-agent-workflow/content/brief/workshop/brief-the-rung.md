# A5.8.1 — Brief the rung

- **Route:** `/course/agile-agent-workflow/brief/workshop/brief-the-rung`
- **File:** `html/agile-agent-workflow/brief/workshop/brief-the-rung.html`
- **Eyebrow:** `A5.8.1 · dive 1/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) /
  A5 · The agent brief (`/course/agile-agent-workflow/brief`) / Brief the rung.
- **Route-tag (segmented):** `course/agile-agent-workflow` (link) / `brief` (link) / `workshop` (link) /
  `brief-the-rung` (rcur).
- **Pager:** prev `/course/agile-agent-workflow/brief/workshop` · next `/course/agile-agent-workflow/brief/workshop/run-the-agent`.

## Lead

The workshop opens by briefing one real engine rung end to end. The rung is **F5.2 — Model the Portal domain**, the
first chapter dive of the F5 engine briefs. Briefing it is the whole of A5.1–A5.5 applied once: write the
references the Author reads, the numbered testable requirements, the execution topology, the agent stories, and the
implementation prompt. The five parts together are the brief; a brief missing one part is not runnable.

## The precise definition

**Briefing a rung** is assembling the five parts of an `.llms.md` for one specified slice, each part filled from the
slice's spec and stories, until all five are present. The five parts, in order:

1. **References** — the sources the Author reads first, links first. For F5.2: Elixir structs and `@enforce_keys`;
   typespecs and `@spec`; "make illegal states unrepresentable"; the F0 design system; the upstream `Portal.Store`
   (`get/2`, `all/2`, `put/1`) and `Portal.ID`.
2. **Requirements** — numbered, testable, each traced to a user story. For F5.2: `F5.2-R1` through `F5.2-R6`.
3. **Execution topology** — the runtime shape (here: plain modules over the F4 store, no new processes), the
   build-order task DAG `T1→T6`, and the touched-file list.
4. **Agent stories** — `F5.2-AS1…AS3`, each a Directive plus an Acceptance gate.
5. **The implementation prompt** — the single prompt that runs the stories in task order and ends on the
   verification gates, with the Definition of Done as the acceptance checklist.

A brief is complete when all five parts are present. Drop one and the Author is left to decide what the part would
have fixed — drop the topology and it has the requirements but no build order or file list.

## The worked F5/F6 example (exact ids quoted)

Grounded on the real `docs/elixir/specs/pragmatic/f5.2.llms.md`.

- **References quoted:** Elixir structs and `@enforce_keys`; typespecs (`@type`, `@spec`); "make illegal states
  unrepresentable"; the F0 design system; the upstream `Portal.Store` (`get/2`, `all/2`, `put/1`) and `Portal.ID`.
- **`F5.2-R1` (quoted):** seven entity structs (`User`, `Session`, `Course`, `Lesson`, `Page`, `Enrollment`,
  `Progress`), each with `@enforce_keys`, `defstruct`, and a `@type t`; `id`/`*_id` fields are branded-id strings;
  `@enforce_keys` lists every field except `progress` (default `0`, type `0..100`). [US: F5.2-US1]
- **`F5.2-R3` (quoted verbatim, the requirement the workshop writes):** the documented public API per context, each
  function with an `@spec`, all other functions private: `Accounts.user/1 :: {:ok, %User{}} | :error`;
  `Catalog.course/1`, `Catalog.lesson/1` likewise; `Learning.enroll/2 :: {:ok, %Enrollment{}} | {:error, atom}`;
  `Learning.courses_of/1 :: [%Enrollment{}]`. [US: F5.2-US3]
- **Topology quoted:** plain modules over the F4 store, no new processes; the task DAG
  `T1 entity structs → T2 context modules → T3 public APIs → T4 reads via Portal.Store; enroll mints ENR + put →
  T5 typespecs → T6 verify`, each step leaving the app compiling.
- **Agent stories quoted:** `F5.2-AS1` (entities that cannot be built incomplete), `F5.2-AS2` (bounded contexts),
  `F5.2-AS3` (public APIs over the store).
- The branded-id mint in the worked walkthrough is named `Portal.ID.generate/1` (freely nameable). The real F5
  surfaces `Portal.Store`, `Portal.ID`, `%Enrollment{}` are cited only as they appear in `f5.2.llms.md`.

## Hero interactive — assemble the five parts

- **Move it teaches:** how a brief is built up, part by part, from nothing to runnable — the order
  references → requirements → topology → stories → prompt.
- **Elements:** `#asmSel` (a stepper: a "back" and "advance" button + a "fill all" button), the SVG `#asm`
  (five stacked part-bands, each lit when filled), `#asmCount` (the filled count), readout `#asmOut`.
- **Dataset:** `PARTS = ['references', 'requirements', 'execution topology', 'agent stories', 'implementation prompt']`,
  each with the F5.2 content it carries.
- **Pure functions:**
  - `partFilled(step, i)` → boolean: part `i` is filled when `i < step` (the stepper has reached it).
  - `filledCount(step)` → integer 0..5.
  - `briefReady(step)` → boolean: true only when `step === PARTS.length`.
  - `asmReadout(step)` → the readout string.
- **Sample readout (step 5):** `"Brief assembled — five of five parts filled: references, requirements, execution
  topology, agent stories, the implementation prompt. The brief is ready to run."`
- **Static default (JS off):** the stepper starts at step 5 (all five filled), the SVG shows five lit bands, the
  count reads `5 of 5`, the readout reports the brief is ready.

## Content interactive — completeness check (`briefComplete`)

- **Move it teaches (different from the hero):** the hero builds the brief up in order; this one tests whether a
  brief is *complete* by checking every part is present, and shows what a missing part costs — dropping the topology
  leaves the requirements without a build order or file list.
- **Elements:** `#compSel` (toggle: "all five present" vs "drop the topology"), the SVG `#comp` (five part rows,
  each present/absent), `#compState` (the complete/incomplete verdict), readout `#compOut`.
- **Dataset:** `PART_LABELS` (the five parts) with, for each, what an absent part leaves undecided.
- **Pure functions:**
  - `presentSet(view)` → array of booleans for the five parts (all true for `full`; topology false for `drop`).
  - `briefComplete(parts)` → boolean: true only when every part is present.
  - `missingParts(parts)` → array of the absent part labels.
  - `compReadout(view)` → the readout string.
- **Sample readout (drop the topology):** `"Drop the topology and the brief is incomplete — the agent has the
  requirements but no build order or file list. A brief is runnable only when all five parts are present."`
- **Static default (JS off):** the toggle starts on "all five present", the SVG shows five present rows, the verdict
  reads "complete", the readout reports the brief is runnable.

## Bridge + take

- **Principle (`.cell.idea`):** brief the rung by filling all five parts; a brief missing one is not runnable.
- **Practice (`.cell.elix`):** the workshop writes the F5.2 brief — References (structs, typespecs), `F5.2-R1…R6`,
  the modules-over-the-store topology, the agent stories `F5.2-AS1…AS3`, and the implementation prompt.
- **Take:** Briefing the rung is the whole of A5.1–A5.5, applied once to a real rung.

## Cross-links

- **In-prose `/elixir`:** `/elixir/phoenix/contexts` (the contexts the engine briefs define).
- **Related in this course:** `/elixir/course` (the companion course that builds the engine), plus the A5 routes
  the five parts came from.

## References — Sources (3, real, vetted)

- The Pragmatic Programmer → `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
- User Stories Applied → `https://www.mountaingoatsoftware.com/books/user-stories-applied`
- The `llms.txt` convention → `https://llmstxt.org/`
