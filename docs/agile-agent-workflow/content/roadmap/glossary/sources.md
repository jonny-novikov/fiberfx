# A3.9.2 · The annotated sources — the bibliography

- **Route:** `/course/agile-agent-workflow/roadmap/glossary/sources`
- **File:** `html/agile-agent-workflow/roadmap/glossary/sources.html`
- **Numbering:** A3.9 · dive 2 (of 3)
- **Accent:** elixir-purple (`.ex`)
- **Stamp:** `TSK0Ng9hnHJgW0`

## Lead

The annotated bibliography. Every vetted Source the course cites, each with an abstract and the modules
that draw on it — one place to read deeper on any technique. The sources are the canon; the abstracts
say what each one gives the workflow.

## Precise definition (the `SOURCES` dataset)

A source entry is `{title, author, url, abstract, citedBy[]}`. The ten vetted sources, each a real
external link from the course-home registry:

1. **The Pragmatic Programmer** (Hunt & Thomas) — pragprog.com — the source of tracer bullets, the
   single source of truth, DRY, and design by contract. Cited by: A1 (Why), A3 (roadmap), A3.9 (this module).
2. **Extreme Programming Explained** (Beck) — oreilly.com — small batches, iterations, continuous
   feedback, the inspect-and-adapt loop. Cited by: A1, A3, A3.1, A3.2.
3. **Specification by Example** (Adzic) — gojko.net — the spec as executable, shared truth; the four
   artifacts. Cited by: A1.04, A3.3, A3.9.1.
4. **User Stories Applied** (Cohn) — mountaingoatsoftware.com — the Connextra story form, value over
   tasks, the value ladder. Cited by: A2, A3.9.1.
5. **Continuous Delivery** (Humble & Farley) — continuousdelivery.com — keeping the system releasable at
   every increment; the roadmap as the delivery plan. Cited by: A3, A3.9, A3.9.1.
6. **INVEST in Good Stories** (Wake) — xp123.com — the six tests of a good story. Cited by: A2.
7. **Gherkin reference** (Cucumber) — cucumber.io — the Given/When/Then form of an acceptance criterion.
   Cited by: A2, A3.9.1.
8. **User-story template (Connextra)** — agilealliance.org — "As a … I want … so that …". Cited by: A2.
9. **The llms.txt convention** — llmstxt.org — a machine-readable map of a site or course for agents.
   Cited by: A0, A3.9 (the agent brief format).
10. **Anthropic — Building effective agents** — anthropic.com/engineering — the agent as an implementer of
    well-specified, decomposed work; the Author/Operator division. Cited by: A0, A1.03, A3.9.1.

## Worked Portal example

The Portal's F6 web chapter is built straight off this canon: its `phoenix.roadmap.md` is Continuous
Delivery (releasable at every rung); its master invariant is The Pragmatic Programmer (design by contract);
its rungs are User Stories Applied (a value ladder); its acceptance is Specification by Example
(Given/When/Then). The bibliography is not decoration — it is the set of ideas the framework was built to.

## Interactive 1 — hero — the source picker (abstract + who cites it)

- **Move:** select a source, read its abstract and the modules that cite it.
- **Markup:** a `.solid-select` of source buttons over an SVG/HTML panel that renders the chosen source's
  abstract and a citedBy list. Every source title + abstract present in static markup (degrades).
- **Control ids:** `srcSel` (button group, one per source key), panel `srcPanel`, readout `srcOut`.
- **Pure functions over `SOURCES`:**
  - `citeCount(key) -> int` — how many modules cite the source.
  - `readoutFor(key) -> string` — the title, abstract, and citedBy list.
- **Default selection:** The Pragmatic Programmer.
- **Sample readout:** `The Pragmatic Programmer (Hunt & Thomas): tracer bullets, the single source of
  truth, design by contract. Cited by 3 modules: A1, A3, A3.9.`

## Interactive 2 — main — the coverage map (distinct move: which module → which sources)

- **Move:** flip the index the other way — pick a module, see which sources it draws on. Distinct from
  picking a source and seeing its citers.
- **Markup:** a `.solid-select` of module buttons (A1 · A2 · A3 · A3.9); the chosen module lights the
  sources it cites in an SVG row of source nodes, and the readout lists them.
- **Control ids:** `modSel` (button group), source nodes `src-node-<key>`, readout `coverOut`.
- **Pure functions over the inverted `SOURCES.citedBy`:**
  - `sourcesFor(module) -> [key]` — the sources a module cites.
  - `readoutFor(module) -> string` — the module, its source count, and the titles.
- **Sample readout:** `A2 · Decomposition draws on 4 sources: User Stories Applied, INVEST in Good
  Stories, the Gherkin reference, and the Connextra template — the decomposition canon.`

## Principle ↔ practice bridge

- **.cell.idea (principle):** a bibliography is a two-way index — every source to the work that cites it,
  every module to the sources it stands on.
- **.arrow**
- **.cell.elix (Portal practice):** the Portal's F6 chapter is built straight off this canon — Continuous
  Delivery for the roadmap, The Pragmatic Programmer for the invariant, User Stories Applied for the ladder.
- **.take:** the sources are the canon the framework was built to — every source a real link, every link to
  a real book or reference.

## References

### Sources
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Continuous Delivery — https://continuousdelivery.com/
- Specification by Example — https://gojko.net/books/specification-by-example/
- Anthropic — Building effective agents — https://www.anthropic.com/engineering/building-effective-agents

### Related in this course
- A3.9 — Glossary (hub) (`/course/agile-agent-workflow/roadmap/glossary`)
- A3.9.1 — The glossary (`/course/agile-agent-workflow/roadmap/glossary/glossary`)
- A3.9.3 — The idea→framework crosswalk (`/course/agile-agent-workflow/roadmap/glossary/crosswalk`)
- A1 — Why an Agile Agent Workflow (`/course/agile-agent-workflow/why`)
- F6 — The Portal on the web (`/elixir/phoenix`)

## Wiring

- Route-tag (5 segments): `course/agile-agent-workflow`(link) · `roadmap`(link) · `glossary`(link) · `sources`(`.rcur`).
- Pager: prev = `/course/agile-agent-workflow/roadmap/glossary/glossary` · next = `/course/agile-agent-workflow/roadmap/glossary/crosswalk`.
- Footer: canonical `.foot-cols` + stamp `TSK0Ng9hnHJgW0`.
