# A5.6.1 — Briefing

- **Route:** `/course/agile-agent-workflow/brief/running-agents/briefing`
- **File:** `html/agile-agent-workflow/brief/running-agents/briefing.html`
- **Eyebrow:** `A5.6.1 · dive 1/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Parent hub:** `/course/agile-agent-workflow/brief/running-agents` (A5.6 · Running Claude agents well).
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) / A5 · The agent
  brief (`/course/agile-agent-workflow/brief`) / Briefing.
- **Route-tag:** `course/agile-agent-workflow` (link) / `brief` (link) / `running-agents` (link) / `briefing` (rcur).
- **Pager:** prev `/course/agile-agent-workflow/brief/running-agents` · next
  `/course/agile-agent-workflow/brief/running-agents/supervising`.

## Lead

Running an agent well begins before the agent runs: the brief is the act of handing the agent everything it needs
and nothing it must decide. The dive teaches what a good brief carries — and, just as load-bearing, what it does
**not** carry, because that part is already durable in the agent's standing definition.

## The precise idea

A brief is complete when the agent left to read it has no remaining how-to-build decision. A spec says *what* and
*why* and *done*; the four parts of the brief (references, requirements, topology, agent stories) plus the prompt
fix *how*. When all of that is fixed, the agent **implements a plan**; when any of it is open, the agent
**improvises an architecture** — and that architecture is the Operator's call, taken by the implementer.

The second, less obvious move: a good spawn is short. The standing discipline — cite-don't-invent, the master
invariant, the determinism gate, the report format — has one authority, the agent definition. The spawn carries
only the **rung delta**: the surface, the pinned contract, the gates. DRY applied one level up.

## The worked Portal example (grounded on `f6.6.prompt.md`)

`docs/elixir/specs/phoenix/f6.6.prompt.md`, "Why the prompts are short" (verbatim):

> F6.5's Mars prompt ran ~180 lines — the full contract plus every discipline (cite-don't-invent, the master
> invariant, the `@enforce_keys` trap, the determinism gate, framing, the report format). F6.6's Mars prompt is
> ~12, because all of that now lives in `mars.md`. The spawn carries only what is *new about this rung*. That is
> DRY applied one level up: the "how the agent works" fact has one authority (the agent definition), and the
> prompt carries only the delta.

The F6.6 Mars build spawn (its Stage 2 spawn body, real) carries only the rung delta — the surface
(`PortalWeb.CatalogLive`, `mount/3` two-stage, `handle_event/3`), the pinned search fn
(`Portal.search_courses/1`), the route reconcile (`live "/courses"` supersedes the index), and the gates
(`mix compile --warnings-as-errors`, the determinism loop). Everything else — the master invariant INV1, "no
CoreComponents" INV6, the report format — is in `mars.md`, the standing discipline. The brief is short because
the discipline is durable.

## Hero interactive (framing) — complete brief vs open goal

- **Teaches:** a complete brief leaves the agent zero decisions; an open goal leaves many.
- **Dataset:** the four how-to-build decisions a brief fixes — `sources`, `runtime shape`, `build order`,
  `proof gates` — plus the Definition of Done. Two inputs: a **complete brief** (all fixed) vs an **open goal**
  ("make the catalog interactive", all open).
- **Controls:** `#briefSel` two buttons — `data-view="brief"` (complete brief, active) / `data-view="goal"`
  (open goal). SVG `#brief-cell-0..3` rows (each a decision, marked fixed/open) + `#brief-count` + `#brief-dod`.
- **Pure fns:**
  - `decisionsLeft(view)` → `0` for `brief`, `DECISIONS.length` (4) for `goal`.
  - `dodKnown(view)` → `true` for `brief` (the DoD is in the brief), `false` for `goal`.
  - `briefReadout(view)` → the readout string.
- **Readout (default, brief):** `Complete brief — how-to-build decisions left to the agent: 0 of 4; Definition
  of Done: stated. The agent implements the fixed plan — sources, runtime shape, build order, and proof gates
  are all pinned.`
- **Readout (goal):** `Open goal ("make the catalog interactive") — decisions left to the agent: 4 of 4;
  Definition of Done: not stated. The agent must decide the sources, the runtime shape, the build order, and the
  gates — and decide when it is done.`

## Content interactive (teaching) — what the spawn carries

- **Teaches (a different move):** a good spawn carries only the rung delta; the standing discipline lives in the
  agent definition, so the spawn stays short.
- **Dataset:** the six items in the F6.6 Mars spawn picture, each tagged `delta` (carried in the spawn) or
  `durable` (lives in `mars.md`):
  - the surface (`CatalogLive`, the two-stage mount) — `delta`
  - the pinned search fn (`Portal.search_courses/1`) — `delta`
  - the route reconcile (`live "/courses"` supersedes the index) — `delta`
  - the gates (warnings-as-errors + the determinism loop) — `delta`
  - the master invariant (facade-only / no CoreComponents) — `durable`
  - the report format + cite-don't-invent — `durable`
- **Controls:** `#spawnSel` two buttons — `data-view="delta"` (rung delta, active) / `data-view="durable"`
  (standing discipline). SVG `#spawn-item-0..5` rows highlighting the items in the selected class + `#spawn-count`.
- **Pure fns:**
  - `inSpawn(item)` → `true` when the item's class is `delta` (carried in the spawn), else `false`.
  - `countOf(view)` → number of items in the selected class (4 delta, 2 durable).
  - `spawnReadout(view)` → the readout string.
- **Readout (default, delta):** `Rung delta — items the F6.6 Mars spawn carries: 4 of 6 (the surface, the pinned
  search fn, the route reconcile, the gates). The spawn names only what is new about this rung — ~12 lines.`
- **Readout (durable):** `Standing discipline — items the spawn does NOT carry: 2 of 6 (the master invariant, the
  report format). These live in mars.md once, so every spawn stays short — DRY one level up.`

## Bridge + take

- **Principle (`.cell.idea`):** brief the agent with a complete, unambiguous brief so it implements rather than
  decides.
- **Portal practice (`.cell.elix`):** the F6.6 Mars spawn is ~12 lines because the discipline lives in `mars.md`;
  the spawn carries only the rung delta — the surface, the pinned contract, the gates.
- **Take:** A good brief is the difference between an agent that implements a fixed plan and one that improvises
  an architecture.

## Cross-links

- **In-prose `/elixir`:** `/elixir/phoenix/liveview/mount` — the F6.6 LiveView `mount/3` the brief specifies.
- **Related in this course:** `/elixir/phoenix` (the Phoenix chapter of the worked brief);
  `/course/agile-agent-workflow/brief/running-agents` (the module hub);
  `/course/agile-agent-workflow/brief/implementation-prompt` (A5.5 — the prompt this brief runs);
  `/course/agile-agent-workflow/brief` (the chapter landing).

## References — Sources (3, real, vetted)

- Anthropic — *Building effective agents* → `https://www.anthropic.com/engineering/building-effective-agents`
- Anthropic — *Claude Code best practices* → `https://www.anthropic.com/engineering/claude-code-best-practices`
- The Pragmatic Programmer → `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
