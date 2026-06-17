# A5.2.1 — References first

- **Route:** `/course/agile-agent-workflow/brief/references-requirements/references-first`
- **File:** `html/agile-agent-workflow/brief/references-requirements/references-first.html`
- **Eyebrow:** `A5.2.1 · dive 1/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Parent hub:** `/course/agile-agent-workflow/brief/references-requirements` (A5.2).
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) /
  A5 · The agent brief (`/course/agile-agent-workflow/brief`) / References first.
- **Route-tag (segmented):** `course/agile-agent-workflow` (link) / `brief` (link) /
  `references-requirements` (link) / `references-first` (rcur).
- **Pager:** prev `/course/agile-agent-workflow/brief/references-requirements` (hub) ·
  next `/course/agile-agent-workflow/brief/references-requirements/numbered-requirements`.

## Lead

References is the first part of the brief — the reading list the agent works through before it reads any
requirement. It front-loads every source the build depends on, and each one is named to a single reading. This
dive grounds on the real `f6.1.llms.md` References block: six entries, links first, including the upstream
`Portal` facade contract that is also a constraint.

## Precise definition

**References (the first part of an `.llms.md` brief)** is a links-first list of every source the agent must read
before it acts — the framework docs it calls, the upstream contract it must not modify, the design system it
renders in, and the spec system it works within. It is the reading list a requirement cites; a requirement whose
source is not in References is a requirement read blind.

## The worked F6 example — `f6.1.llms.md`'s `## References`

The Portal's web bootstrap, `f6.1.llms.md`, opens with a `## References` block of six entries, links first:

1. **Phoenix endpoint** — the plug stack and `socket/3`: `https://hexdocs.pm/phoenix/Phoenix.Endpoint.html`.
2. **Phoenix router** — `pipeline`, `pipe_through`, `scope`, `get`: `https://hexdocs.pm/phoenix/Phoenix.Router.html`.
3. **Phoenix controllers** — actions, `render/3`, `put_status/2`: `https://hexdocs.pm/phoenix/Phoenix.Controller.html`.
4. **Plug** — `Plug.Static`, `Plug.RequestId`, `Plug.Telemetry`, `Plug.Parsers`, `Plug.Session`:
   `https://hexdocs.pm/plug/readme.html`.
5. **The design system** every page renders in — its tokens, page anatomy, and the nine A+ gates: `F0 · The
   Design System` (`../design/f0.md`).
6. **Upstream contract (do not modify).** The `Portal` facade — query `courses_of/1 :: {:ok, [%Enrollment{}]}`
   (as-built and **total / success-only**: the wrapped list, no bare-list arm) … and the closed error set
   `%Portal.Error{code, message, field}`.

The entry quoted verbatim as the example of a reference that is **also a constraint** is the sixth — the
"Upstream contract (do not modify)" line. It does not merely point the agent at a source; it pins what the agent
must not change. The facade `courses_of/1` returns `{:ok, [%Enrollment{}]}`, the controller still pattern-matches
the `{:error, %Portal.Error{} = e}` arm defensively, and the supervision tree keeps the three F5 children with
Bandit dropped. A reference that is a constraint front-loads a boundary, not only a doc.

Every requirement reads one of these sources. `F6.1-R4` (the controller calls only `Portal.courses_of/1`; a
domain error renders 422) and `F6.1-R8` (an expected failure yields a 422, never a 500) both read the upstream
facade contract — entry 6. Drop that one reference and both are left with no source.

## Interactive 1 — HERO (framing): kinds of reference

- **Teaches:** the *mix* of reference kinds the agent reads first — not all references are the same shape.
- **Element ids:** selector `#kindSel` (buttons `data-kind="all" | framework | contract`); SVG `#kindFig`;
  per-row kind labels `#kind-tag-0` … `#kind-tag-5`; count `#kind-count`; readout `#kindOut`.
- **Dataset (fixed):** the six `f6.1.llms.md` References entries, each tagged by kind:
  - 0 Phoenix endpoint → `framework`
  - 1 Phoenix router → `framework`
  - 2 Phoenix controllers → `framework`
  - 3 Plug → `framework`
  - 4 F0 design system → `design`
  - 5 Upstream `Portal` facade contract → `contract`
  - (the spec-system entry → `spec` is named in prose; the dataset carries the six core build references.)
- **Pure functions:**
  - `kindOf(i)` → returns the kind string for reference index `i` from the fixed `REFS` table.
  - `countOfKind(kind)` → returns how many of the six references carry `kind` (`'all'` → 6).
- **Toggle:** `all references` (default) · `framework docs` · `upstream contract`.
- **Sample readout (default `all`):** *"f6.1.llms.md — references the agent reads first: 6, across 3 kinds —
  4 framework docs, 1 design system, 1 upstream contract. The contract is a reference that is also a constraint:
  it pins what the agent must not change."*
- **Degrade:** static markup ships the `all` view lit and the `all` readout; JS only re-filters.

## Interactive 2 — CONTENT (teaching): read-order coverage

- **Teaches:** that every requirement's source must be present in References — a *different* move from kinds:
  here the test is coverage, and dropping one reference strands the requirements that cite it.
- **Element ids:** selector `#covSel` (buttons `data-mode="full" | drop-facade"`); SVG `#covFig`; per-row
  status `#cov-st-0` … `#cov-st-7` (one per `R1…R8`); uncovered count `#cov-count`; readout `#covOut`.
- **Dataset (fixed):** `F6.1-R1…R8`, each mapped to the single reference it reads:
  - R1 endpoint plug stack + LiveView socket → ref 0 (Phoenix endpoint)
  - R2 two-supervisor tree → ref 5 (upstream contract: the F5 tree it splits)
  - R3 `:browser` pipeline + courses route → ref 1 (Phoenix router)
  - R4 controller calls only `Portal.courses_of/1`; error → 422 → ref 5 (upstream facade contract)
  - R5 `CourseHTML` renders from assigns → ref 4 (design system / Phoenix controllers)
  - R6 `GET /health` → 200 → ref 1 (Phoenix router)
  - R7 master-invariant grep (no `Portal.Engine`/`Repo`/`GenServer.call`) → ref 5 (the contract boundary)
  - R8 expected failure → 422, never 500; endpoint restarts → ref 5 (upstream facade contract)
- **Pure functions:**
  - `sourceOf(r)` → the reference index `R<r>` reads (from the fixed `REQ_SRC` table).
  - `presentRefs(mode)` → the set of reference indices present in References under a mode (`'full'` → all six;
    `'drop-facade'` → all but index 5).
  - `uncovered(mode)` → the list of requirement labels whose `sourceOf` is **not** in `presentRefs(mode)`
    (`'full'` → `[]`; `'drop-facade'` → `['R2','R4','R7','R8']`).
  - *Spec note:* the spec calls out R4 and R8 explicitly as "the controller and fail-soft paths now read no
    contract"; the dataset also strands R2 and R7 (both read the same facade-contract entry). The readout names
    R4 and R8 as the spec's example and reports the full uncovered set truthfully.
- **Toggle:** `full references` (default) · `drop the facade contract`.
- **Sample readout (default `full`):** *"Full references — requirements left without a source: 0 of 8. Every
  requirement reads a reference that is on the list, so the agent reads its source before it builds."*
- **Drop readout:** *"Drop the facade contract reference — requirements left without a source: R2, R4, R7, R8.
  The controller (R4) and the fail-soft path (R8) now read no contract — the agent would build them blind."*
- **Degrade:** static markup ships the `full` view (all eight covered, count 0) and the `full` readout; JS only
  recomputes on toggle.

## Bridge + take

- **`.cell.idea` (principle):** every requirement's source belongs in References, read before the requirement.
- **`.arrow` →**
- **`.cell.elix` (Portal):** `f6.1.llms.md`'s References carries the `Portal` facade contract that `R4`/`R8`
  depend on, so the agent reads the contract before it builds the controller.
- **`.take`:** References is the reading list; a requirement with no source on it is a requirement read blind.

## Cross-links

- **In-prose `/elixir`:** `/elixir/phoenix/lifecycle/endpoint` — the endpoint doc the first reference points at.
- **Related in this course:** `/elixir/phoenix/lifecycle` (the rung whose `f6.1.llms.md` this grounds on),
  plus internal A5 / A0 routes.

## References (3 Sources, from the registry)

- `https://llmstxt.org/` — the `llms.txt` convention: links first, prose second; the form References takes.
- `https://www.mountaingoatsoftware.com/books/user-stories-applied` — User Stories Applied: a story (and the
  requirement that serves it) is grounded in concrete sources, not assumptions.
- `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/` — The Pragmatic
  Programmer: design by contract — name the source so the builder never has to guess it.
