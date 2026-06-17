# A5.8 — Workshop: briefing the agent for Portal · module hub

- **Route:** `/course/agile-agent-workflow/brief/workshop`
- **File:** `html/agile-agent-workflow/brief/workshop/index.html`
- **Eyebrow:** `A5.8 · module hub`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) /
  A5 · The agent brief (`/course/agile-agent-workflow/brief`) / A5.8 · Workshop.
- **Route-tag:** `course/agile-agent-workflow` (link) / `brief` (link) / `workshop` (rcur).
- **Pager:** prev `/course/agile-agent-workflow/brief` · next `/course/agile-agent-workflow/brief/workshop/brief-the-rung`.

## Lead

A5.1–A5.7 built the brief part by part and named the practice and the thesis behind it. A5.8 is the chapter's
capstone: it runs the whole A5 sequence on the Portal's real engine briefs — write the references, requirements,
topology, agent stories, and the implementation prompt; run a Claude Author; and verify the increment against the
Definition of Done. It is the proof that the method produces a verified increment, not a description of one.

The workshop's worked rung is **F5.2 — Model the Portal domain** (`f5.2.llms.md`): the seven entity structs with
`@enforce_keys`, the three bounded contexts, and the per-context public API. The worked *shape* of a fully-assembled
brief — references → requirements → topology → agent stories → the comprehensive implementation prompt — is the one
`f6.1.llms.md` carries. The workshop writes the F5.2 brief in that shape, runs it, and checks the result against the
spec's Definition of Done.

## Precise definition

Three stages, run in order, each closing on a gate:

1. **Brief the rung** — assemble all five parts of the brief for one real engine rung. A brief missing a part is not
   runnable. (A5.8.1 dive.)
2. **Run the agent** — run the implementation prompt in task order, the tree compiling after each step, supervising
   each step's gate. (A5.8.2 dive.)
3. **Verify the increment** — review the output against the Definition of Done, not the agent's self-report. The
   increment is done when it is provably done. (A5.8.3 dive.)

## Worked F5/F6 example (exact ids quoted)

From `f5.2.llms.md` (the rung the workshop briefs):

- `F5.2-R1` — seven entity structs (`User`, `Session`, `Course`, `Lesson`, `Page`, `Enrollment`, `Progress`), each
  with `@enforce_keys`, `defstruct`, and a `@type t`; `id`/`*_id` fields are branded-id strings; `@enforce_keys`
  lists every field except `progress` (default `0`, type `0..100`).
- `F5.2-R3` — the documented public API per context, each function with an `@spec`, all other functions private:
  `Accounts.user/1 :: {:ok, %User{}} | :error`; `Catalog.course/1`, `Catalog.lesson/1` likewise;
  `Learning.enroll/2 :: {:ok, %Enrollment{}} | {:error, atom}`; `Learning.courses_of/1 :: [%Enrollment{}]`.
- The F5.2 task topology `T1 → T2 → T3 → T4 → T5 → T6` (each step leaves the app compiling), the touched-file list
  (`lib/portal/<context>/<entity>.ex` + the three context modules), the three agent stories `F5.2-AS1…AS3`, and the
  comprehensive implementation prompt with its six numbered build steps.

`Portal.ID.generate/1` (freely-nameable) is the surface used to mint a branded id in the worked walkthrough prose;
the real F5 surfaces (`Portal.Store`, `Portal.ID.new/1`) are cited only as they appear in `f5.2.llms.md`.

The worked *shape* of the full brief is from `f6.1.llms.md`: References → Requirements (`F6.1-R1…R8`) → Execution
topology (the `T1→T7` task DAG) → Agent stories (`F6.1-AS1…AS4`) → the Comprehensive implementation prompt that
ends on the Definition of Done.

## Hero interactive (framing) — the five parts, assembled for a rung

- Move taught: a brief is complete only when all five parts are present; the stepper assembles them one at a time.
- Element ids: figure `#assembleFig`; selector `#assembleSel` with five stepper buttons `data-step="0..4"` plus a
  "reset" affordance via re-selecting step 0; readout `#assembleOut`.
- Dataset: the five brief parts in order — `references`, `requirements`, `topology`, `agent stories`, `the prompt`
  — each carrying the F5.2 thing it holds (the structs/typespecs sources; `F5.2-R1…R6`; the `T1→T6` DAG + file list;
  `F5.2-AS1…AS3`; the six-step prompt).
- Pure functions:
  - `partReady(i, upTo)` → boolean: part `i` is filled once the stepper has reached step `upTo` (i.e. `i <= upTo`).
  - `readyCount(upTo)` → integer: how many of the five parts are filled at step `upTo`.
  - `assembleReadout(upTo)` → the readout string.
- Sample readout (step 4, all five filled): `"Brief assembled — 5 of 5 parts present: references, requirements,
  topology, agent stories, the prompt. The F5.2 brief is runnable; an Author can build it without deciding."`
- Static default (JS off): step 0 lit; readout reports `"1 of 5 parts present: references. Four parts still to
  assemble before the brief is runnable."`

## Content interactive (teaching) — the full pass

- Move taught: the A5 sequence is three gated stages; the increment is verified only when every stage's gate passes
  — a different move from the hero (assembling parts vs running the whole pass to a verified end state).
- Element ids: figure `#passFig`; selector `#passSel` with three buttons `data-stage="0..2"` (brief · run · verify);
  readout `#passOut`; stage rects `#pass-0`, `#pass-1`, `#pass-2`.
- Dataset: the three stages — `brief` (gate: all five parts present), `run` (gate: the tree compiles after each step;
  each agent story's Acceptance gate passes), `verify` (gate: the Definition of Done holds — enforce-keys raise,
  `enroll/2` round-trip, no cross-context struct reference). Each stage carries a `gate` state (`pass`) once the
  prior stage has passed.
- Pure functions:
  - `stageState(i, reached)` → `"pass" | "pending"`: stage `i` is `pass` once `i <= reached`, else `pending`.
  - `passedThrough(reached)` → integer count of stages whose gate has passed.
  - `passReadout(reached)` → the readout string.
- Sample readout (stage 2 reached): `"Verify reached — 3 of 3 stages gated: brief (five parts), run (compiles + the
  AS gates), verify (the F5.2 Definition of Done). The increment is verified, not merely reported done."`
- Static default (JS off): stage 0 lit; readout reports `"Brief stage gated — 1 of 3. Two stages remain: run the
  prompt, then verify against the Definition of Done."`

## Bridge + take

- **Principle:** run the whole A5 sequence on a real rung — brief, run, verify — a first full pass from spec to
  running code.
- **Portal practice:** the workshop briefs a real engine rung from `pragmatic/f5.*` (F5.2), runs the implementation
  prompt, and verifies the increment against its Definition of Done.
- **Take:** the workshop is the chapter's proof — the method, run end to end, produces a verified increment, not a
  description of one.

## /elixir cross-link

- In-prose: `/elixir/phoenix/lifecycle` (the worked web rung).
- Related in this course: `/elixir/course` (the companion course that builds the engine) + `/elixir/phoenix`.

## References — Sources (3)

- The Pragmatic Programmer → `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
- Anthropic — Building effective agents → `https://www.anthropic.com/engineering/building-effective-agents`
- The `llms.txt` convention → `https://llmstxt.org/`

## Dives into (3 cards)

- `A5.8.1 · /brief/workshop/brief-the-rung` — *Brief the rung* — assemble the five parts of the brief for one real
  engine rung.
- `A5.8.2 · /brief/workshop/run-the-agent` — *Run the agent* — run the implementation prompt in task order and
  supervise the gates.
- `A5.8.3 · /brief/workshop/verify-the-increment` — *Verify the increment* — review the output against the
  Definition of Done; the increment is verified, not merely reported done.
