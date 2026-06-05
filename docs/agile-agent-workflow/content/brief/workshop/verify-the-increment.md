# A5.8.3 — Verify the increment

- **Route:** `/course/agile-agent-workflow/brief/workshop/verify-the-increment`
- **File:** `html/agile-agent-workflow/brief/workshop/verify-the-increment.html`
- **Eyebrow:** `A5.8.3 · dive 3/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) / A5 · The agent brief
  (`/course/agile-agent-workflow/brief`) / Verify the increment.
- **Route-tag:** `course/agile-agent-workflow` (link) / `brief` (link) / `workshop` (link) / `verify-the-increment`
  (rcur).
- **Pager:** prev `/course/agile-agent-workflow/brief/workshop/run-the-agent` · next
  `/course/agile-agent-workflow/brief/workshop` (back to the hub).

## Lead

The workshop's last move. The agent reports the rung built. A report is not a closure. The increment is verified
only when the human runs the Definition of Done and the rung's checks pass — compile clean, the node boots,
`GET /health` returns `200`, a real `courses_of/1` render plus an empty state, an injected `%Portal.Error{}`
renders `422` not `500`, killing the endpoint self-heals under `:one_for_one`, and the master-invariant grep over
`apps/portal_web/lib/` is empty. Beyond the suite there is the liveness criterion: `mix test` runs `server: false`
under `config/test.exs`, so a green suite does **not** prove the dev server boots — the human boots the node and
`curl :4000/health` is `200`, and the live two-window update works.

## Precise definition

To **verify the increment** is to run the spec's Definition of Done against the built code and confirm every check
passes — not to accept the agent's self-report. The verification is a closure over runnable checks: each one is
either green or it is not, and the increment is done only when all of them are green. The DoD checks are the F6.1
verify step (T7); the liveness criterion is the standing F6.7 gate that a green suite cannot satisfy.

## Worked Portal example (grounded on the real artifacts)

From `f6.1.llms.md`, the verify step (T7 → R7, R8 + DoD), quoted verbatim:

> Verify (T7 → R7, R8 + DoD). Confirm: mix compile is clean; the app boots; GET /health is 200; GET
> /courses/:user_id renders a known user's courses and an empty state for none or for an unknown/malformed id; the
> 422 render path is unit-verified via an injected %Portal.Error{}; killing PortalWeb.Endpoint restarts it (under
> PortalWeb.Application, :one_for_one) and a later request succeeds. Run `grep -rE
> "Portal\.Engine|Repo|GenServer\.call" apps/portal_web/lib/` and confirm it is empty. Report each result against
> the F6.1 Definition of Done.

The Acceptance gate of `F6.1-AS4` (Self-heal and fail soft) closes the same checks: killing the endpoint restarts
it and a later request succeeds; an unknown/malformed user id renders the empty state (`200`); the `422` render
path is unit-verified via an injected `%Portal.Error{}` with a message from the closed set.

From `f6.7.prompt.md`, the liveness criterion, quoted verbatim:

> `mix test` alone does NOT satisfy the liveness criterion (the endpoint runs `server: false` under test). If
> BUILD-GRADE **and live**, one commit

and:

> the LIVENESS check (the standing criterion): boot the node (iex -S mix / mix phx.server) and curl :4000/health ->
> 200, plus a two-window live-update smoke — mix test runs server:false (config/test.exs), so a green suite does
> NOT prove the dev server boots.

The seven DoD checks for this increment:

1. `mix compile` clean.
2. the app boots; tree order store → engine → endpoint.
3. `GET /health` returns `200` (no domain call).
4. a real `courses_of/1` render + an empty state for none / unknown id (`200`).
5. an injected `%Portal.Error{}` renders `422`, never `500`.
6. killing `PortalWeb.Endpoint` self-heals under `:one_for_one`; a later request succeeds.
7. the master-invariant grep over `apps/portal_web/lib/` is empty (`Portal.Engine` / `Repo` / `GenServer.call`).

Beyond the suite: the **liveness check** — boot the node, `curl :4000/health` is `200`, the two-window live update
works (`mix test` runs `server: false`).

Only `Portal.ID.generate/1` is freely nameable; every other surface above is quoted as it appears in the source.

## Hero interactive (framing) — the increment against the DoD

- **Move:** run the Definition-of-Done check set against the built increment; the increment is verified only when
  every check passes.
- **Dataset:** `DOD` — the seven DoD checks above, each with a state.
- **Controls:** `#dodSel` — two buttons, `data-view="all-pass"` (default, active) and `data-view="one-fails"`
  (flips check 5, the `422` path, to failing).
- **Pure functions:**
  - `dodCheck(view, i) -> boolean` — whether check `i` passes under the chosen view.
  - `passCount(view) -> number` — how many of the seven checks pass.
  - `verifiedByDod(view) -> boolean` — true only when `passCount(view) === DOD.length`.
  - `dodReadout(view) -> string`.
- **SVG ids:** `#dod-row-0`…`#dod-row-6` (rect + status text `#dod-st-0`…`#dod-st-6`), `#dod-count`.
- **Readout id:** `#dodOut` (`aria-live="polite"`). Default string: *"All checks pass: the increment is verified —
  7 of 7. Compile, boot, /health, the courses render and empty state, the 422 path, endpoint self-heal, and the
  invariant grep all pass. Done is a closure over checks, not a report."* One-fails string: *"One check fails: the
  increment is not verified — 6 of 7. The injected %Portal.Error{} renders a 500, not a 422 — the rung is reported
  done but it is not done."*

## Content interactive (teaching) — verified vs reported done, with the liveness check

- **Move (different from the hero):** contrast trusting the agent's self-report against running the DoD **plus the
  liveness check** — a green suite does not prove the dev server boots, because `mix test` runs `server: false`.
- **Dataset:** `MODES` — `report` (the agent says "done") and `dod` (the human runs the DoD + the liveness check).
- **Controls:** `#verSel` — `data-view="report"` (trust the report) and `data-view="dod"` (run the DoD), the latter
  default/active.
- **Pure functions:**
  - `verified(mode) -> boolean` — `false` for `report` (a report proves nothing), `true` for `dod`.
  - `provenBy(mode) -> number` — checks actually run under the mode (`0` for report; `8` for dod = the 7 DoD checks
    + the liveness check).
  - `verReadout(mode) -> string`.
- **SVG ids:** `#ver-report` and `#ver-dod` cells (status text `#ver-st-report`, `#ver-st-dod`), `#ver-proven`.
- **Readout id:** `#verOut`. Default (dod) string: *"Run the DoD: the increment is verified only when compile,
  /health, the 422 path, self-heal, the invariant grep, and the liveness check all pass — the report alone proves
  nothing."* Report string: *"Trust the report: checks the human actually ran: 0 — the agent says done, but mix
  test runs server: false, so a green suite does not even prove the dev server boots. A report is not a closure."*

## Bridge + take

- **Principle (`.cell.idea`):** Verify the increment against the Definition of Done and the liveness check; an
  increment is done when it is provably done, not when the agent says so.
- **Practice (`.cell.elix`):** `f6.1.llms.md`'s DoD (compile, boot, `/health` 200, the courses render + empty
  state, the `422` path, endpoint self-heal, the empty invariant grep) and F6.7's liveness gate (the node boots,
  `/health` is `200`, a live two-window update works) are the checks that turn a self-report into a verified
  increment.
- **Take:** The workshop ends where every increment should — on a Definition of Done that the human ran, not the
  agent reported.

## /elixir cross-link

- In-prose: `/elixir/phoenix/lifecycle` (the rung whose DoD closes the increment).
- Related in this course: `/elixir/course` (the companion course that builds the engine) + `/elixir/phoenix`.

## References — Sources (3, real, vetted)

- Anthropic — Building effective agents → `https://www.anthropic.com/engineering/building-effective-agents`.
- The Pragmatic Programmer → `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`.
- The `llms.txt` convention → `https://llmstxt.org/`.

## Related in this course

- A5.8.2 · Run the agent (prev) — the run whose output this verifies.
- A5.8 · Workshop (hub) — the full A5 sequence.
- A5.6 · Running Claude agents well — review against the spec's DoD, not the self-report.
- `/elixir/course` — the companion course that builds the engine.
- `/elixir/phoenix` — the real Phoenix chapter the DoD closes.
