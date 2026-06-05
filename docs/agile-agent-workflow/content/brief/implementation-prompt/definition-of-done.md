# A5.5.3 — Definition of Done

- **Route:** `/course/agile-agent-workflow/brief/implementation-prompt/definition-of-done`
- **File:** `html/agile-agent-workflow/brief/implementation-prompt/definition-of-done.html`
- **Eyebrow:** `A5.5.3 · dive 3/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) / A5 · The agent brief
  (`/course/agile-agent-workflow/brief`) / Definition of Done.
- **Route-tag (segmented):** `course/agile-agent-workflow` (link) / `brief` (link) / `implementation-prompt`
  (link) / `definition-of-done` (rcur).
- **Pager:** prev `/course/agile-agent-workflow/brief/implementation-prompt/task-order` · next
  `/course/agile-agent-workflow/brief/implementation-prompt` (back to the hub).

## Lead

The implementation prompt does not end when the agent has written the files. It ends on the **Definition of
Done** — the verification gates the prompt's last step makes the agent run and report. A prompt that stops at
"build the files" hands back an opinion ("done"); a prompt that ends on the Definition of Done hands back
evidence. The gates are the only place an agent's "done" is allowed to mean done.

This dive is distinct from its two siblings. A5.5.1 (assembling the prompt) showed the prompt gathers the four
prior parts. A5.5.2 (task order) showed the prompt runs them in the task-DAG order so the tree compiles at every
step. A5.5.3 — this dive — closes the prompt: it ends on a runnable Definition of Done, and a prompt missing its
verify step is incomplete.

## Precise definition

The **Definition of Done** is the closing checklist of the implementation prompt: a set of runnable checks the
agent executes after the build, reporting each result rather than asserting completion. In the brief, the prompt's
final step folds the spec's Definition of Done into the run, so the agent self-checks against the gates and stops
only when every one passes.

A prompt that ends on its Definition of Done is **complete**: the agent finishes by producing evidence. A prompt
with no verify step is **incomplete**: the agent reports "done" with nothing to back it.

## Worked F6 example — `f6.1.llms.md`, step 7 (verbatim grounding)

The Portal's web bootstrap brief, `f6.1.llms.md`, ends its seven-step implementation prompt on a verify step.
Step 7 (T7 → R7, R8 + DoD) reads, verbatim:

> Confirm: `mix compile` is clean; the app boots; `GET /health` is 200; `GET /courses/:user_id` renders a known
> user's courses and an empty state for none or for an unknown/malformed id; the 422 render path is unit-verified
> via an injected `%Portal.Error{}`; killing `PortalWeb.Endpoint` restarts it (under `PortalWeb.Application`,
> `:one_for_one`) and a later request succeeds. Run `grep -rE "Portal\.Engine|Repo|GenServer\.call"
> apps/portal_web/lib/` and confirm it is empty. Report each result against the F6.1 Definition of Done.

The prompt then closes:

> Stop when the Definition of Done in `specs/phoenix/f6.1.md` is fully checked.

The seven verify checks the agent reports against (the gate dataset for the interactives):

1. `mix compile` is clean.
2. the app boots.
3. `GET /health` is 200 (no domain call).
4. `GET /courses/:user_id` renders a known user's courses and an empty state for none / an unknown or malformed id.
5. the 422 render path is unit-verified via an injected `%Portal.Error{}` (a domain failure renders 422, never 500).
6. killing `PortalWeb.Endpoint` restarts it under `:one_for_one`, and a later request succeeds.
7. the invariant grep `grep -rE "Portal\.Engine|Repo|GenServer\.call" apps/portal_web/lib/` is empty.

These map to requirements `F6.1-R7` (the static-grep invariant) and `F6.1-R8` (expected failure → 422, endpoint
self-heals), and they close the agent stories' Acceptance gates. No surface beyond the verbatim F6.1 brief is
named: `Portal.courses_of/1`, `PortalWeb.Endpoint`, `PortalWeb.Application`, `%Portal.Error{}`, the `f6.1.md`
Definition of Done — all quoted as they appear in `f6.1.llms.md`. (`Portal.ID.generate/1` / `Portal.ID.decode/1`
are the only free-to-name surfaces; they are not used here.)

## Interactive 1 (hero, framing) — the gates the prompt ends on

- **Element ids:** selector `#gateSel` (steps walk via `prev`/`next` buttons `#gatePrev` / `#gateNext`); SVG
  `#gateFig` with a row per gate (`#gate-row-0..6`) and a "step i of 7" label `#gate-step`; readout `#gateOut`
  (`aria-live="polite"`).
- **Dataset:** the seven verify-step checks above (`GATES`), each `{ label, kind, req }`.
- **Pure functions:**
  - `gateAt(i)` → `GATES[i]` (the check at step `i`).
  - `gateCount()` → `GATES.length` (7).
  - `gateReadout(i)` → e.g. *"Gate 3 of 7 — `GET /health` is 200 (a runtime check). The prompt closes on a
    runnable Definition of Done: the agent reports each result, it does not assert done."*
- **Behaviour:** a stepper walks `gate 1 … gate 7`; each step lights its row and reports the check + that the
  prompt ends on a runnable Definition of Done. Static default: step 1 lit, its readout shown.
- **Teaches:** *what* the prompt ends on — the runnable gates themselves.

## Interactive 2 (content, teaching) — complete or incomplete prompt

- **Element ids:** selector `#dodSel` (`with verify step` / `no verify step`); SVG `#dodFig` (the seven build
  steps stacked, step 7 lit/struck; a `complete` / `incomplete` verdict cell `#dod-verdict` and a checks-count
  `#dod-count`); readout `#dodOut` (`aria-live="polite"`).
- **Dataset:** the `f6.1.llms.md` prompt's seven steps (`STEPS`), step 7 being the verify step that carries the
  DoD checks.
- **Pure functions:**
  - `endsOnGates(form)` → `true` when `form === 'verify'` (the prompt carries step 7), `false` for `'noverify'`.
  - `checksReported(form)` → `7` with the verify step, `0` without it (the gate dataset size when present).
  - `dodReadout(form)` → with verify: *"Ends on the DoD: complete — the agent self-checks against the gates
    (compile clean, `/health` 200, the invariant grep empty, endpoint self-heal). No verify step: incomplete — the
    agent reports done with no evidence."* (mirrors A5.5's acceptance check: a prompt missing its acceptance gates
    is flagged incomplete).
- **Behaviour:** toggle re-renders step 7 (lit + "complete" / struck + "incomplete") and the checks-reported
  count (7 / 0). Static default: `with verify step` → complete, 7 checks.
- **Teaches a different move:** not *what* the gates are (interactive 1) but the **consequence** of dropping them
  — a prompt with no verify step is incomplete.

## Bridge

- **Principle (`.cell.idea`):** the prompt ends on the Definition of Done — the verification gates the agent
  self-checks against; a prompt missing them is incomplete.
- **Practice (`.cell.elix`):** `f6.1.llms.md`'s prompt closes step 7 on `mix compile` clean, `/health` 200, the
  422 render via an injected `%Portal.Error{}`, endpoint self-heal under `:one_for_one`, and the empty invariant
  grep, reported against the F6.1 DoD.
- **Take:** The Definition of Done is where the prompt stops — and the only place the agent's "done" is allowed
  to mean done.

## `/elixir` cross-link

- In-prose: `/elixir/phoenix/lifecycle` (the rung whose Definition of Done this prompt closes).
- Related in this course: `/elixir/phoenix/lifecycle`.

## References

### Sources (3, real, vetted)

- Anthropic — *Claude Code best practices* → `https://www.anthropic.com/engineering/claude-code-best-practices` —
  end an agent prompt on the checks it must run, not on an open-ended goal.
- Hunt, A. & Thomas, D. — *The Pragmatic Programmer* →
  `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/` — "done" is a check that
  passes, not a feeling; pin the verification before the work.
- llmstxt.org — *The /llms.txt convention* → `https://llmstxt.org/` — a machine brief ends on the actionable
  checks the agent runs, not on prose.

### Related in this course

- `/course/agile-agent-workflow/brief/implementation-prompt` — A5.5 · the module hub.
- `/course/agile-agent-workflow/brief/implementation-prompt/task-order` — A5.5.2 · the order the prompt runs in.
- `/course/agile-agent-workflow/brief/agent-stories/acceptance-gates` — A5.4.3 · the gate that closes a story.
- `/course/agile-agent-workflow/spec` — A4 · the spec whose Definition of Done the prompt checks against.
- `/elixir/phoenix/lifecycle` — Companion · the real rung whose `f6.1.llms.md` Definition of Done this closes on.

## Wiring

- `#refs` is in the `.toc-mini`.
- Two inline `<script>` blocks copied verbatim from the model (the page logic + the JS-on / reveal block); the
  page logic block is replaced with the two pure-function interactives above and the verbatim Snowflake decoder.
- Clamp spacing kept spaced (`clamp(2.7rem,1.9rem + 4.2vw,5.1rem)`). No browser storage; `prefers-reduced-motion`
  honoured; both interactives render correctly with JS disabled (static default state + readout in markup).
