# A5.5 — The comprehensive implementation prompt · module hub

- **Route:** `/course/agile-agent-workflow/brief/implementation-prompt`
- **File:** `html/agile-agent-workflow/brief/implementation-prompt/index.html`
- **Eyebrow:** `A5.5 · module hub`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Title:** `A5.5 — The comprehensive implementation prompt · Agile Agent Workflow · jonnify`
- **Meta:** A5.5 module hub — the brief's fifth part: the single prompt an agent runs to build the increment in
  task order, ending on the verification gates, with the Definition of Done as the acceptance checklist. Grounded
  on the Portal's real `f6.1.llms.md` implementation prompt and the `f6.6`/`f6.7` ship prompts.

## Lead

The four prior parts — references, requirements, topology, agent stories — are inert until something runs them.
The fifth part is that runner: the **comprehensive implementation prompt**. It is a single instruction an Author
follows top to bottom, building the increment in task-DAG order and ending on the verification gates, with the
spec's Definition of Done as the acceptance checklist. The prompt fixes no decision the spec has not already
fixed; it assembles the decisions already made and turns them into one runnable pass.

## The precise definition

The implementation prompt is the part of an `.llms.md` brief that:

1. **Assembles** the four prior parts — names the sources to read first, the requirements to satisfy, the runtime
   shape and build order, and the agent stories to run.
2. **Runs in task order** — executes the agent stories in the task-DAG sequence (`F6.1-AS1…AS4` over `T1→T7`),
   keeping the tree compiling after each step.
3. **Ends on the gates** — closes on the verification step (compile clean, boot, `/health` 200, the injected-error
   → 422 render, endpoint self-heal, the empty invariant grep), reported against the spec's Definition of Done.

A prompt missing its verification step is **incomplete**: the agent builds with no signal of done.

## The worked Portal example — `f6.1.llms.md`'s comprehensive implementation prompt

The real artifact is the `## Comprehensive implementation prompt` block of `f6.1.llms.md`. Its preamble (quoted
verbatim on the page):

> You are implementing spec F6.1 (Bootstrap the Phoenix Portal) as a NEW umbrella app `apps/portal_web` … Read
> `specs/phoenix/f6.1.md`, `specs/phoenix/f6.1.stories.md`, and `specs/design/f0.md` first. Do not change anything
> under the Portal facade … Build in this order, keeping the umbrella compiling after each step.

Its seven numbered steps, each mapped to a task and its requirements:

| Step | Task | Requirements | What it builds |
|---|---|---|---|
| 1 Foundation | T1 | — | the new app, `portal_web.ex` helpers, Telemetry, endpoint config |
| 2 Endpoint | T2 | R1 | `PortalWeb.Endpoint` — the plug stack + the LiveView socket |
| 3 Supervision | T3 | R2 | wire the Endpoint after the engine; drop Bandit from `Portal.Application` |
| 4 Router | T4 | R3, R6 | the `:browser` pipeline, the courses route, `GET /health` |
| 5 Controller | T5 | R4, R8 | `CourseController.index/2` over `Portal.courses_of/1` only |
| 6 View | T6 | R5 | `CourseHTML` + the two `.heex` templates, assigns only |
| 7 Verify | T7 | R7, R8 + DoD | the verification gates, reported against the F6.1 Definition of Done |

The prompt closes: "Stop when the Definition of Done in `specs/phoenix/f6.1.md` is fully checked."

The multi-agent variant is the `f6.6.prompt.md` / `f6.7.prompt.md` orchestration brief: the same assembly, run
across a lead-team (Venus reconcile + brief → Mars build → Apollo verify) with a Director in the loop at each
gate. The single-agent prompt is the fallback for a trivial re-run; the orchestration prompt is the recommended
execution for a risky seam.

## The three dives

- `A5.5.1 · /brief/implementation-prompt/assembling-the-prompt` — *Assembling the prompt* — the prompt gathers the
  four prior parts: references, requirements, topology, agent stories.
- `A5.5.2 · /brief/implementation-prompt/task-order` — *Task order* — the prompt runs the agent stories in the
  task-DAG order, keeping the tree compiling at each step.
- `A5.5.3 · /brief/implementation-prompt/definition-of-done` — *Definition of Done* — the prompt ends on the
  verification gates; a prompt missing its gates is incomplete.

## Hero interactive (framing): the prompt's five inputs

- **id:** `inputSel` (selector) + `inputs` SVG (five stacked bands) + `inputOut` (`.geo-readout`, `aria-live`).
- **Dataset:** the five inputs the prompt carries — references, requirements, topology, agent stories, Definition
  of Done — each with the guarantee it gives the prompt.
- **Pure fn:** `inputPresent(i)` returns whether prior part `i` is carried into the prompt (true for all five);
  `inputReadout(i)` builds the readout string.
- **Static default:** input 0 (references) lit; its readout rendered server-side.
- **Sample readout:** `Input 1 · References — the sources the agent reads first. Carried into the prompt: yes. The
  prompt is the assembly point — every prior part folded into one runnable instruction, no decision left open.`
- **Teaches:** the prompt is the *gather-point* of the whole brief.

## Content interactive (teaching): complete or incomplete

- **id:** `vsSel` (two buttons: "with the verify step" / "drop step 7") + `vs` SVG (seven steps, the last toggling)
  + `vsOut` (`.geo-readout`, `aria-live`).
- **Dataset:** the `f6.1.llms.md` prompt's seven steps (Foundation … Verify), with step 7 carrying the four gates
  (compile clean, `/health` 200, the invariant grep empty, endpoint self-heal).
- **Pure fn:** `endsOnGates(mode)` returns whether the prompt carries step 7; `gatesCount(mode)` returns 4 with the
  verify step, 0 without; `vsReadout(mode)` builds the readout.
- **Static default:** "with the verify step" active; readout shows the complete prompt.
- **Sample readout:** `With step 7, the prompt ends on the gates (compile clean, /health 200, the invariant grep
  empty, endpoint self-heal). Drop it and the prompt is incomplete — the agent builds with no signal of done.`
- **Teaches:** a different move from the hero — not *what the prompt assembles* but *where the prompt stops*, and
  that a prompt without its gates cannot close. Mirrors A5.5's acceptance: a prompt missing its acceptance gates is
  flagged incomplete.

## Bridge + take

- **Principle:** the implementation prompt assembles the four prior parts into one run, in task order, ending on
  the gates — and fixes no decision the spec has not already fixed.
- **Portal:** `f6.1.llms.md`'s prompt runs `F6.1-AS1…AS4` over `T1→T7` and closes on `mix compile` clean,
  `/health` 200, an empty invariant grep, and endpoint self-heal, with the F6.1 Definition of Done as the
  checklist.
- **Take:** The prompt is the brief made runnable — every part folded into one pass that ends when the gates pass.

## Cross-links

- In-prose `/elixir/phoenix/lifecycle` (the rung this prompt builds) and `/elixir/phoenix/liveview` (the F6.6 ship
  prompt's rung).
- Related-in-course: `/elixir/phoenix/lifecycle`.

## References — Sources (3)

- Anthropic — Claude Code best practices → `https://www.anthropic.com/engineering/claude-code-best-practices`
- The `llms.txt` convention → `https://llmstxt.org/`
- The Pragmatic Programmer → `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`

## Pager

- prev `/course/agile-agent-workflow/brief`
- next `/course/agile-agent-workflow/brief/implementation-prompt/assembling-the-prompt`
