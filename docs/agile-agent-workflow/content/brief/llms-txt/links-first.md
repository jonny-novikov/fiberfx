# A5.1.1 — Links first

- **Route:** `/course/agile-agent-workflow/brief/llms-txt/links-first`
- **File:** `html/agile-agent-workflow/brief/llms-txt/links-first.html`
- **Eyebrow:** `A5.1.1 · dive 1/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) /
  A5 · The agent brief (`/course/agile-agent-workflow/brief`) / Links first.
- **Route-tag (segmented):** `course/agile-agent-workflow` (link) / `brief` (link) / `llms-txt` (link) /
  `links-first` (rcur).
- **Pager:** prev `/course/agile-agent-workflow/brief/llms-txt` (hub) · next
  `/course/agile-agent-workflow/brief/llms-txt/every-reference-exact`.

## Lead

A brief is read by an agent, not a person, and an agent acts on links before it acts on prose. The first dive of
the `llms.txt` module teaches the single most consequential move in writing for a machine reader: **front-load the
exact links so the agent never has to guess a source.** A reference the agent has to hunt for is a decision handed
to it by omission — and a decision an agent makes is a decision the Operator did not.

## Precise definition

A machine brief opens with a **References** block: the exact sources the agent reads, named and linked, before any
requirement or narrative. The agent reads that block first, then acts. When every source carries an exact link,
the count of sources the agent must guess is zero. Strip the links and that count rises to the number of references
— each one now an improvisation the agent makes alone.

## Worked Portal example — `f6.1.llms.md` References (grounded, verbatim)

The Portal's web bootstrap ships from a real brief, `f6.1.llms.md`. Its top-of-file blockquote sets the reading
order in one line:

> Read the references first, satisfy the requirements, build in task-topology order, and close each agent story on
> its gate. This brief is self-contained …

Its `## References` block names each source to a precision the agent cannot misread. Two lines, quoted verbatim:

- *"Phoenix endpoint — the plug stack and `socket/3`: `https://hexdocs.pm/phoenix/Phoenix.Endpoint.html`."* — an
  exact hexdocs link, not "the Phoenix docs."
- *"**Upstream contract (do not modify).** The `Portal` facade — query `courses_of/1 :: {:ok, [%Enrollment{}]}` …"*
  — a reference that is also a constraint, pinned to its exact return shape.

The References block carries six entries the agent reads before the first requirement: the endpoint, router, and
controller hexdocs; the Plug docs; the F0 design system; and the upstream `Portal` facade contract. With all six
linked, the agent reads every source first, then acts. None is left to guess.

In-prose `/elixir` cross-link: `/elixir/phoenix/lifecycle/endpoint` — the real endpoint doc the first reference
points at.

## Interactive 1 — hero (framing): where the agent looks first

- **Teaches:** the *order* an agent reads a brief in — References at index 0, before any requirement.
- **Dataset:** the brief's section sequence, `['References', 'Requirements', 'Execution topology', 'Agent stories',
  'the implementation prompt']` (from `f6.1.llms.md`'s skeleton).
- **Controls:** `#orderSel` — a stepper that advances a marker down the section sequence (buttons: "first read",
  "next").
- **Pure functions:**
  - `readOrder()` → returns the array with `References` at index 0.
  - `sectionAt(i)` → returns the section at position `i` in read order.
  - `firstRead()` → returns `'References'` (index 0).
  - `orderReadout(i)` → the readout string for the marked section.
- **SVG:** five stacked bands (the sections) with a "read marker" arrow on the left; the References band lit.
- **Readout (`#orderOut`, default at index 0):** *"Read order — section 1 of 5: References (links). The agent
  reads the sources before any requirement; References sits at index 0 of the brief."*

## Interactive 2 — content (teaching): resolve-or-guess

- **Teaches:** the *consequence* of front-loading links — how many sources the agent must guess with links present
  vs. stripped. (A different move from the hero, which teaches read order.)
- **Dataset:** the six References entries of `f6.1.llms.md`, each flagged `hasLink: true` (endpoint, router,
  controller, Plug, F0 design system, the `Portal` facade contract).
- **Controls:** `#resolveSel` — toggle "with links" vs "links stripped" (`data-view="with"` / `data-view="stripped"`).
- **Pure functions:**
  - `unresolved(view)` → counts entries the agent would have to guess: `0` with links, `REFS.length` (6) when stripped.
  - `resolveReadout(view)` → the readout string.
- **SVG:** six reference rows, each with a link chip (lit green when present, red "guess" when stripped) and an
  unresolved-count tally at the foot.
- **Readout (`#resolveOut`, default "with"):** *"With links: sources the agent must guess: 0 of 6 — every
  reference resolves to one exact source. Strip the links: 6 of 6 — the agent improvises a source for each."*

## Bridge + take

- **`.cell.idea` (principle):** Front-load the links so the agent never guesses a source. A machine reader acts on
  exact references before prose; the References block is the first part to fill.
- **`.cell.elix` (Portal):** `f6.1.llms.md`'s References names the exact endpoint/router/controller hexdocs and the
  `Portal` facade contract `courses_of/1 :: {:ok, [%Enrollment{}]}`, links first — so the controller reads the
  contract before it is built, never guessing it.
- **`.take`:** A reference the agent has to hunt for is a decision you handed it by omission.

## References

### Sources (3, real, vetted)

- llmstxt.org — *The /llms.txt convention* → `https://llmstxt.org/` — a links-first, machine-readable document an
  agent reads before prose; the form the brief takes.
- Anthropic — *Building effective agents* → `https://www.anthropic.com/engineering/building-effective-agents` —
  why a coding agent needs an explicit, well-structured task with its sources named, not an open-ended goal.
- Hunt, A. & Thomas, D. — *The Pragmatic Programmer* →
  `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/` — design by contract:
  pinning every source and decision the builder must not have to invent.

### Related in this course

- `/course/agile-agent-workflow/brief/llms-txt` — A5.1 · the module hub (the `llms.txt` convention).
- `/course/agile-agent-workflow/brief` — A5 · The agent brief (the chapter landing).
- `/course/agile-agent-workflow/brief/why` — A5 orientation · why a brief deserves a layer.
- `/elixir/phoenix/lifecycle` — Companion · the real chapter whose `f6.1.llms.md` this dive grounds on.

## Wiring

- `#refs` link present in `.toc-mini`.
- Both `<script>` blocks copied verbatim from the model lesson + the page's own interactive script.
- Gate command (zsh):
  `FLAGS="--routes-from /course/agile-agent-workflow=html/agile-agent-workflow --chapter-alias a0=what,a1=why,a2=decomposition,a3=roadmap,a4=spec,a5=brief,a6=reliability,a7=portal --require-refs"`
  `apps/jonnify-cms/bin/cms check ${=FLAGS} html/agile-agent-workflow/brief/llms-txt/links-first.html`
- Parallel-sibling note: pager `next` (`/brief/llms-txt/every-reference-exact`) and the hub (`/brief/llms-txt`) are
  built in parallel; a `links` FAIL naming ONLY those is expected until they land.
