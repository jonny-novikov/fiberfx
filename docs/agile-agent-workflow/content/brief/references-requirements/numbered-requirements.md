# A5.2.2 — Numbered requirements

- **Route:** `/course/agile-agent-workflow/brief/references-requirements/numbered-requirements`
- **File:** `html/agile-agent-workflow/brief/references-requirements/numbered-requirements.html`
- **Eyebrow:** `A5.2.2 · dive 2/3`
- **Parent hub:** A5.2 — References and requirements (`/course/agile-agent-workflow/brief/references-requirements`)
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.

## Crumbs

jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) / A5 · The agent brief
(`/course/agile-agent-workflow/brief`) / Numbered requirements (here).

## Route-tag (segmented, clickable)

`course/agile-agent-workflow` (link `/course/agile-agent-workflow`) / `brief` (link
`/course/agile-agent-workflow/brief`) / `references-requirements` (link
`/course/agile-agent-workflow/brief/references-requirements`) / `numbered-requirements` (rcur).

## Pager

- prev: `/course/agile-agent-workflow/brief/references-requirements/references-first` (A5.2.1 · References first)
- next: `/course/agile-agent-workflow/brief/references-requirements/traceability` (A5.2.3 · Traceability)

(Both siblings may still be building in parallel — a `links` FAIL naming only those two routes is expected until
they land.)

## Lead

References first tell the agent what to read. The second part of the brief tells it what to build — as numbered,
testable requirements. The Portal's web bootstrap brief, `f6.1.llms.md`, carries eight of them: `F6.1-R1` through
`F6.1-R8`. Each is a single statement the agent can satisfy and the reviewer can check. Numbering is not a tidy
habit; it turns a paragraph of intent into a checklist the build and the review share.

## Precise definition

A **numbered requirement** is one checkable statement, given an id, that names exactly one thing the agent must
build and exactly one check that closes it. It is the unit the brief decomposes the work into. The discipline has
two parts:

1. **One statement, one check.** A requirement names a single observable fact and the kind of check that proves it
   — a boot, a render, a grep, a restart. If you cannot say what check closes a line, it is a wish, not a
   requirement.
2. **Numbered, so each is addressable.** `R1`, `R4`, `R7` are addresses. The build cites them; the task DAG cites
   them; the agent stories cite them; the review walks them. A paragraph of prose is one ambiguous unit; eight
   numbered lines are eight separately-checkable ones.

## The worked Portal example — `F6.1-R1…R8` (verbatim from `f6.1.llms.md`)

Quoted verbatim from `docs/elixir/specs/phoenix/f6.1.llms.md` `## Requirements`:

- **F6.1-R1** — `PortalWeb.Endpoint` exists as the outermost plug with `Plug.Static`, `Plug.RequestId`,
  `Plug.Telemetry`, `Plug.Parsers` (urlencoded/multipart/json via `Jason`), `Plug.Session`, and `plug
  PortalWeb.Router` last; it declares `socket "/live", Phoenix.LiveView.Socket`. [US: F6.1-US1]
- **F6.1-R6** — `GET /health` returns `200` with body `ok` and performs no domain call. [US: F6.1-US1]
- **F6.1-R7** — no module under `apps/portal_web/lib/` contains the strings `Portal.Engine`, `Repo`, or
  `GenServer.call` (the master invariant, statically checkable). [US: F6.1-US3]
- **F6.1-R8** — an expected domain failure yields a `422`, never a `500`; killing the endpoint restarts it under
  the supervisor. [US: F6.1-US4, F6.1-US5]

The grep that closes R7 (verbatim, the master invariant from `F6.1-AS3`):
`grep -rE "Portal\.Engine|Repo|GenServer\.call" apps/portal_web/lib/` must return nothing.

Each requirement's **check kind** (the dataset for the hero interactive), read from the requirement text:

| id | what it asserts | check kind |
|---|---|---|
| R1 | the Endpoint plug stack + the LiveView socket | boot (the endpoint compiles and boots with the stack) |
| R2 | the tree splits across two `:one_for_one` supervisors | boot (the tree boots store → engine → endpoint) |
| R3 | the `:browser` pipeline + the courses route | render (the route dispatches to the controller) |
| R4 | the controller calls only `Portal.courses_of/1`; a domain error renders 422 | render |
| R5 | `CourseHTML` renders purely from assigns | render |
| R6 | `GET /health` returns 200 "ok", no domain call | render |
| R7 | no `Portal.Engine` / `Repo` / `GenServer.call` under `apps/portal_web/lib/` | grep (static) |
| R8 | expected failure → 422 not 500; killing the endpoint restarts it | restart (self-heal) |

## Interactive 1 — hero, framing: "one statement, one check"

Teaches that each requirement is a single, numbered, checkable line — pairing the id to its check kind.

- **Element ids:** selector `#ckSel` (buttons over the eight requirement ids, plus an "all eight" overview);
  SVG `#ckSvg` with per-requirement rows `#ck-row-0…#ck-row-7` and the check-kind label `#ck-kind`; readout
  `#ckOut` (`aria-live="polite"`).
- **Dataset:** `REQS = [{id:'R1', kind:'boot', what:'the Endpoint plug stack + the LiveView socket'}, … R8 …]`
  (the eight rows above; fixed, derived from `f6.1.llms.md`).
- **Pure functions:**
  - `checkKind(id) -> 'boot' | 'render' | 'grep' | 'restart'` — maps a requirement id to its check kind.
  - `kindGloss(kind) -> string` — a one-phrase description of the check (e.g. grep → "a static grep over
    apps/portal_web/lib/").
  - `ckReadout(id) -> string` — the readout sentence for a single requirement (or the overview when `id === 'all'`).
- **Static default (degrades, JS off):** the "all eight" overview is active, the SVG shows all eight rows with their
  check kinds, and `#ckOut` already reads the overview sentence.
- **Sample readout (single):** `"F6.1-R7 — one numbered statement, one check: a static grep over
  apps/portal_web/lib/ for Portal.Engine, Repo, or GenServer.call returns nothing. Each requirement is a single
  checkable line."`
- **Sample readout (overview):** `"F6.1-R1…R8 — eight numbered requirements, each a single checkable line:
  4 render checks, 2 boot checks, 1 static grep, 1 restart. Every line names what to build and the check that
  closes it."`

## Interactive 2 — content, teaching: "coverage of the eight"

Teaches that numbering keeps the requirements separately checkable — merge them into prose and the checkable count
falls.

- **Element ids:** selector `#cvSel` (toggle: "numbered" / "merge R7 + R8 into one paragraph"); SVG `#cvSvg` with
  eight cells `#cv-cell-0…#cv-cell-7` and a count `#cv-count`; readout `#cvOut` (`aria-live="polite"`).
- **Dataset:** `R1…R8` each tagged `buildable: true` (each names a check). The "merge" view folds R7 and R8 into a
  single ambiguous prose unit.
- **Pure functions:**
  - `buildable(view) -> number` — the count of separately-checkable requirements; `8` when numbered, `7` when R7
    and R8 are merged into one paragraph (two checks collapse into one ambiguous unit).
  - `mergedPair(view) -> [string, string] | null` — returns `['R7','R8']` in the merge view, `null` otherwise.
  - `cvReadout(view) -> string` — the readout sentence.
- **Static default (degrades, JS off):** the "numbered" view is active, all eight cells lit, `#cv-count` reads
  `8 of 8`, and `#cvOut` reads the numbered sentence.
- **Sample readout (numbered):** `"Numbered: 8 separately-checkable requirements. Each line — R1 boot, R4 render,
  R7 grep, R8 restart — is one statement the build satisfies and the review checks."`
- **Sample readout (merge):** `"Merge R7 and R8 into one paragraph and the checkable count drops to 7 — one
  paragraph is one ambiguous unit. The static grep and the 422/self-heal check now read as a single line of
  intent, not two checks."`

The two interactives teach different moves: the hero pairs each id to its **kind of check** (one statement, one
check); the content interactive shows that **numbering keeps the checks separable** (merge and the count falls).

## Bridge + take

- **Principle (`.cell.idea`):** number the requirements so each is a single statement the agent can satisfy and the
  reviewer can check.
- **→ Portal practice (`.cell.elix`):** `f6.1.llms.md` numbers `R1…R8`; R7 is a literal grep
  (`grep -rE "Portal.Engine|Repo|GenServer.call" apps/portal_web/lib/` is empty), and R8 is a literal
  observation — an expected failure renders 422, never 500, and a killed endpoint restarts under its supervisor.
- **Take:** Numbering turns a paragraph of intent into a checklist the build and the review share.

## `/elixir` cross-link

- In-prose: `/elixir/phoenix/lifecycle/controllers` — the controller that builds R4 (the `index/2` action calling
  `Portal.courses_of/1`, rendering 422 on `%Portal.Error{}`).
- Related-in-course: `/elixir/phoenix/lifecycle`.

## References

### Sources (3)

- llmstxt.org — *The /llms.txt convention* — `https://llmstxt.org/` — the links-first machine-brief form whose
  second part is the numbered requirements list.
- Cohn, M. — *User Stories Applied* — `https://www.mountaingoatsoftware.com/books/user-stories-applied` — a
  requirement is testable only when it names the check that closes it; the discipline behind a numbered, checkable
  line.
- Hunt, A. & Thomas, D. — *The Pragmatic Programmer* — 
  `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/` — design by contract:
  state each obligation precisely so the builder satisfies it rather than interprets it.

### Related in this course

- `/course/agile-agent-workflow/brief/references-requirements` — A5.2 · the module hub.
- `/course/agile-agent-workflow/brief/references-requirements/references-first` — A5.2.1 · the sources read first.
- `/course/agile-agent-workflow/brief/references-requirements/traceability` — A5.2.3 · each requirement traced to a
  story and a check.
- `/course/agile-agent-workflow/spec` — A4 · the spec a requirement derives from.
- `/elixir/phoenix/lifecycle` — Companion · the real rung whose `f6.1.llms.md` carries `R1…R8`.

## Gate-invisible self-checks

- Clamp spacing spaced (`clamp(2.7rem,1.9rem + 4.2vw,5.1rem)` etc.) — copied verbatim from the model page.
- Route-tag is the exact four-segment form; crumbs + pager parent = A5.2 hub / the two siblings.
- Every Sources `<li>` carries `href="http`. Both inline scripts parse (`node --check`).
- Both interactives render a correct default with JS disabled.
