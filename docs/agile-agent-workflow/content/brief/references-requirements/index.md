# A5.2 — References and requirements (module hub)

- **Route:** `/course/agile-agent-workflow/brief/references-requirements`
- **File:** `html/agile-agent-workflow/brief/references-requirements/index.html`
- **Eyebrow:** `A5.2 · module hub`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Grounds on:** `docs/elixir/specs/phoenix/f6.1.llms.md` — its `## References` block (six entries) and
  `## Requirements` (`F6.1-R1` through `F6.1-R8`, each ending `[US: F6.1-USn]`).

## Lead

The first two parts of an agent brief are the references the agent reads and the requirements it satisfies.
References come first — the sources the agent reads before any narrative. Requirements come second — numbered,
testable, and each one a single statement the agent can satisfy and a reviewer can check. This module is the hub
for three dives that teach the two parts in order: references first, then numbered requirements, then the
traceability that ties each requirement to the story it serves.

## Precise definition

- **References (part one)** are the exact sources the agent reads before it builds: framework docs, the upstream
  contract it must not modify, the design system, the spec system. They come first because an agent acts on links,
  not prose.
- **A requirement (part two)** is a numbered, testable statement of one thing the agent must produce, ending in a
  trace to the user story it serves. `f6.1.llms.md` numbers eight of them, `F6.1-R1` through `F6.1-R8`. A statement
  that names no check is a wish, not a requirement.

## Worked Portal example (verbatim from f6.1.llms.md)

The brief opens with its `## References` block — six entries, links first:

1. Phoenix endpoint — the plug stack and `socket/3`: hexdocs.
2. Phoenix router — `pipeline`, `pipe_through`, `scope`, `get`: hexdocs.
3. Phoenix controllers — actions, `render/3`, `put_status/2`: hexdocs.
4. Plug — `Plug.Static`, `Plug.RequestId`, `Plug.Telemetry`, `Plug.Parsers`, `Plug.Session`: hexdocs.
5. The design system every page renders in — `F0 · The Design System`.
6. **Upstream contract (do not modify).** The `Portal` facade — `courses_of/1 :: {:ok, [%Enrollment{}]}` (total /
   success-only); the closed error set `%Portal.Error{code, message, field}`.

Then its `## Requirements`, numbered and each traced. Two quoted verbatim:

- **F6.1-R4** — `PortalWeb.CourseController.index/2` calls only `Portal.courses_of/1`; on success it `render(conn,
  :index, courses: courses)`; on `{:error, %Portal.Error{} = e}` it `conn |> put_status(422) |> render(:error,
  error: e)`. No other module is called for domain data. [US: F6.1-US2, F6.1-US3, F6.1-US5]
- **F6.1-R7** — no module under `apps/portal_web/lib/` contains the strings `Portal.Engine`, `Repo`, or
  `GenServer.call` (the master invariant, statically checkable). [US: F6.1-US3]

And the eight requirements by check kind:

| Req | Check kind | Statement (paraphrase of the verbatim line) |
|---|---|---|
| F6.1-R1 | boot (plug stack) | `PortalWeb.Endpoint` exists as the outermost plug with the full stack + `socket "/live"`. |
| F6.1-R2 | boot (tree split) | the tree splits across two `:one_for_one` app supervisors; `Portal.Application` keeps the F5 three. |
| F6.1-R3 | render (route) | `PortalWeb.Router` defines a `:browser` pipeline and `get "/courses/:user_id"`. |
| F6.1-R4 | render (controller) | `index/2` calls only `Portal.courses_of/1`; the `{:error, %Portal.Error{}}` arm renders 422. |
| F6.1-R5 | render (template) | `CourseHTML` renders purely from `assigns`; no engine or repo symbol in any template. |
| F6.1-R6 | boot (health) | `GET /health` returns `200` "ok" with no domain call. |
| F6.1-R7 | grep (invariant) | no module under `apps/portal_web/lib/` names `Portal.Engine`, `Repo`, or `GenServer.call`. |
| F6.1-R8 | restart (fail-soft) | an expected failure yields a `422`, never a `500`; killing the endpoint restarts it. |

## The three dives (`.mods` grid)

- **A5.2.1 · References first** — `/brief/references-requirements/references-first` — every source the agent reads,
  before any requirement.
- **A5.2.2 · Numbered requirements** — `/brief/references-requirements/numbered-requirements` — `F6.1-R1…R8`:
  numbered, testable, each one a single checkable statement.
- **A5.2.3 · Traceability** — `/brief/references-requirements/traceability` — each requirement names the story it
  serves and the check it satisfies; an untraced requirement is flagged.

## Interactive 1 — hero (framing): the two parts

- **Element ids:** `#twoSel` (solid-select: `references` / `requirements`), SVG `.anat`, readout `#twoOut`.
- **Dataset:** the six References entries + the eight Requirements `R1…R8` of `f6.1.llms.md`, each tagged with its
  part.
- **Pure functions:**
  - `partOf(item)` → `'references' | 'requirements'` — classifies one item by its part.
  - `countPart(part)` → number of items in that part (6 references, 8 requirements).
  - `twoReadout(part)` → readout string.
- **Sample readout (references):** `Part 1 · References — 6 sources the agent reads first (endpoint, router,
  controllers, Plug, the F0 design system, the Portal facade contract), before any requirement. The brief's first
  two parts are "sources read, then numbered checks."`
- **Sample readout (requirements):** `Part 2 · Requirements — 8 numbered, testable statements (F6.1-R1…R8), each
  read after its source. The brief's first two parts are "sources read, then numbered checks."`

## Interactive 2 — content (teaching): testable or not

- **Element ids:** `#testSel` (solid-select: `as written` / `blur R7 to a goal`), SVG grid of 8 cells, readout
  `#testOut`.
- **Dataset:** `F6.1-R1…R8`, each tagged with its check kind (boot / render / grep / restart) and a `testable`
  flag (true as written).
- **Pure functions:**
  - `isTestable(req)` → boolean — true when the requirement names a check.
  - `testableCount(reqs)` → count of testable requirements (8 as written; 7 once R7 is blurred to a vague goal).
  - `testReadout(mode)` → readout string.
- **Sample readout (as written):** `f6.1.llms.md — requirements with a named check: 8 of 8. R7 is a literal grep
  (grep -rE "Portal\.Engine|Repo|GenServer\.call" apps/portal_web/lib/ is empty). Each one is a single checkable
  statement.`
- **Sample readout (blurred):** `Blur R7 to a goal ("keep the boundary clean") and the count drops to 7 of 8 — a
  goal names no check, so the reviewer cannot run it and the agent cannot satisfy it.`

## Bridge

- **Principle (`.cell.idea`):** references first, then numbered testable requirements; a requirement names a check
  or it is a wish.
- **Practice (`.cell.elix`):** `f6.1.llms.md` lists the exact sources, then `F6.1-R1…R8`, each a single checkable
  statement (e.g. R6: `GET /health` returns 200 "ok").
- **Take:** A requirement the agent can run a check against is buildable; one it can only interpret is not.

## Cross-link

- In-prose `/elixir/phoenix/lifecycle` (where these requirements are built).

## References

### Sources

- llmstxt.org — *The /llms.txt convention* — `https://llmstxt.org/`
- Cohn, M. — *User Stories Applied* — `https://www.mountaingoatsoftware.com/books/user-stories-applied`
- Hunt, A. & Thomas, D. — *The Pragmatic Programmer* —
  `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`

### Related in this course

- `/course/agile-agent-workflow/brief/references-requirements/references-first`
- `/course/agile-agent-workflow/brief/references-requirements/numbered-requirements`
- `/course/agile-agent-workflow/brief/references-requirements/traceability`
- `/course/agile-agent-workflow/brief` — A5 · The agent brief
- `/course/agile-agent-workflow/brief/llms-txt` — A5.1 · the convention
- `/elixir/phoenix/lifecycle` — the request lifecycle these requirements build
- `/elixir/phoenix` — the companion Phoenix chapter

## Pager

- prev `/course/agile-agent-workflow/brief` (A5 · The agent brief)
- next `/course/agile-agent-workflow/brief/references-requirements/references-first` (A5.2.1, first dive)

## Crumbs

jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) / A5 · The agent brief
(`/course/agile-agent-workflow/brief`) / here.
