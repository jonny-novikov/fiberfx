# A5.2.3 — Traceability

- **Route:** `/course/agile-agent-workflow/brief/references-requirements/traceability`
- **File:** `html/agile-agent-workflow/brief/references-requirements/traceability.html`
- **Eyebrow:** `A5.2.3 · dive 3/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Parent hub:** `/course/agile-agent-workflow/brief/references-requirements` (A5.2).
- **Pager:** prev `…/references-requirements/numbered-requirements` · next `…/references-requirements` (back to hub).

## Lead

The third dive of A5.2 closes the requirements part of the brief. A5.2.1 placed References first; A5.2.2 numbered
the requirements so each is a single checkable line. This dive adds the link that makes the list accountable:
**every requirement names the user story it serves and the check it satisfies.** A requirement with no story is
work no one asked for; a requirement with no check is a wish. Traceability turns "done" into a closure over checks,
not an opinion — and it flags any line that escaped a story.

## Precise definition

A requirement is **traced** when it carries a `[US: …]` annotation naming the user story (or stories) it serves,
and when that requirement is itself a testable statement (a check, an invariant, or a grep). In the Portal's real
`f6.1.llms.md`, every requirement ends with such a trace. The full map (verbatim from the file):

| Requirement | Trace | What it serves |
|---|---|---|
| `F6.1-R1` (endpoint plug stack + LiveView socket) | `[US: F6.1-US1]` | serve the Portal as a Phoenix app |
| `F6.1-R2` (the tree splits across two `:one_for_one` supervisors) | `[US: F6.1-US1, F6.1-US3, F6.1-US4]` | boot, boundary, self-heal |
| `F6.1-R3` (`:browser` pipeline + `get "/courses/:user_id"`) | `[US: F6.1-US2]` | see a user's courses |
| `F6.1-R4` (controller calls only `Portal.courses_of/1`; 422 on error) | `[US: F6.1-US2, F6.1-US3, F6.1-US5]` | render, boundary, fail soft |
| `F6.1-R5` (`CourseHTML` renders from assigns only) | `[US: F6.1-US2]` | see a user's courses |
| `F6.1-R6` (`GET /health` returns 200 "ok") | `[US: F6.1-US1]` | serve the Portal as a Phoenix app |
| `F6.1-R7` (no `Portal.Engine`/`Repo`/`GenServer.call` under `apps/portal_web/lib/`) | `[US: F6.1-US3]` | hold the boundary |
| `F6.1-R8` (expected failure → 422 not 500; endpoint restarts) | `[US: F6.1-US4, F6.1-US5]` | self-heal, fail soft |

The spec emphasizes the five most load-bearing traces: **R1→US1, R3→US2, R4→US2/US3/US5, R7→US3, R8→US4/US5.**
An **untraced** requirement — one with no `[US: …]` — is flagged: the agent would build work no story asked for,
and the reviewer would have nothing to close it against.

## Worked Portal example

`F6.1-R4` is the densest trace in the brief: *"`PortalWeb.CourseController.index/2` calls only
`Portal.courses_of/1`; on success it `render(conn, :index, courses: courses)`; on `{:error, %Portal.Error{} = e}`
it `conn |> put_status(422) |> render(:error, error: e)`. No other module is called for domain data. [US:
F6.1-US2, F6.1-US3, F6.1-US5]"*. One requirement, three stories: it renders a user's courses (US2), it holds the
boundary by calling only the facade (US3), and it fails soft with a 422 render (US5). The check that closes it is a
controller test over `Portal.courses_of/1` plus the master-invariant grep. The companion course builds this exact
controller at `/elixir/phoenix/lifecycle`.

`F6.1-R7` is the master invariant and is purely a check — *"no module under `apps/portal_web/lib/` contains the
strings `Portal.Engine`, `Repo`, or `GenServer.call`. [US: F6.1-US3]"* — satisfied by an empty
`grep -rE "Portal\.Engine|Repo|GenServer\.call" apps/portal_web/lib/`. It traces to US3 (hold the boundary): the
story it serves and the runnable check that closes it are both named on the same line.

## Interactives

### Hero (framing) — requirement → story

- **Element ids:** `#trSel` (selector buttons, one per requirement `R1…R8`), SVG `#trSvg`, readout `#trOut`.
- **Dataset:** `R1…R8`, each with its `[US: …]` trace verbatim from `f6.1.llms.md`.
- **Pure fns:**
  - `storiesFor(reqId)` → array of user-story ids the requirement serves (e.g. `storiesFor('R4') = ['US2','US3','US5']`).
  - `traceLabel(reqId)` → the joined `[US: …]` string.
  - `trReadout(reqId)` → the readout string.
- **Sample readout:** `"F6.1-R4 → US2, US3, US5. One requirement, three stories: it renders a user’s courses (US2), holds the boundary (US3), and fails soft (US5). Each requirement names the story it serves."`
- **Move taught:** read the *forward* link — pick a requirement, see the stories it is accountable to.

### Content (teaching) — find the untraced

- **Element ids:** `#unSel` (toggle: "as shipped" vs "inject an untraced requirement"), SVG `#unSvg`, count `#un-count`, readout `#unOut`.
- **Dataset:** `R1…R8` (all traced) + one synthetic `R9*` with no `[US: …]` injected by the toggle.
- **Pure fns:**
  - `untraced(reqs)` → the subset with an empty story list.
  - `untracedCount(mode)` → `0` for "shipped", `1` for "injected".
  - `unReadout(mode)` → the readout string.
- **Sample readout (injected):** `"Inject an untraced requirement — requirements with no story: 1 of 9 (R9*). The agent would build work no story asked for; the reviewer has nothing to close it against. Trace it or drop it."`
- **Move taught:** read the *gap* — a requirement with no story is flagged as unaccountable. (Different move from the hero: the hero reads a present trace forward; the content figure detects an absent one.)

## Bridge + take

- **Principle (`.cell.idea`):** trace each requirement to the story it serves and the check it satisfies; an
  untraced requirement is unaccountable.
- **Portal (`.cell.elix`):** every `f6.1.llms.md` requirement ends `[US: F6.1-USn]`, so each line of work is
  accountable to a story and each story to a check (R4 → three stories + a controller test; R7 → US3 + an empty grep).
- **Take:** Traceability makes "done" a closure over checks, not an opinion — and flags any work no story asked for.

## Cross-links

- **In-prose `/elixir`:** `/elixir/phoenix/lifecycle` (where these requirements are built).
- **Related in this course:** `/elixir/phoenix/lifecycle`; the A5.2 hub; A5.2.2 (numbered requirements); A4 (the spec
  whose user stories these requirements trace to); A4 traceability.

## References — Sources (3, registry URLs only)

- User Stories Applied → `https://www.mountaingoatsoftware.com/books/user-stories-applied`
- The `llms.txt` convention → `https://llmstxt.org/`
- The Pragmatic Programmer → `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`

`#refs` link present in `.toc-mini`.
