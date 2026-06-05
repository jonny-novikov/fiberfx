# A3.9 · Glossary, references & where the framework implements each idea — module hub

- **Route:** `/course/agile-agent-workflow/roadmap/glossary`
- **File:** `html/agile-agent-workflow/roadmap/glossary/index.html`
- **Numbering:** A3.9 · module hub (chapter A3, The roadmap layer)
- **Accent:** elixir-purple (`.ex`)
- **Stamp:** `TSK0Ng9hnHJgW0`

## Lead

The reference module — the chapter's and the course's appendix. Where the teaching modules build the
argument, this one indexes it: every key term gets a one-line abstract, its Source, and a link to
where the framework (`/elixir`) implements the idea. The hub frames that promise and routes to three
dives — the glossary itself, the annotated sources, and the idea→framework crosswalk.

## Precise definition

A glossary is a closed, data-driven index: a fixed `TERMS` dataset where each entry carries a term, a
one-line abstract, a Source, and the `/elixir/phoenix/<sub>` route where the Portal implements it.
Closed because it indexes the course as built — no entry without a real abstract, a real Source, and a
real, resolving framework link. The reference module is the place to look a concept up and jump to its
real code, not the place to learn it for the first time.

## Worked Portal example

Take one term: **master invariant**. Its abstract: "one rule that holds at every rung — for the Portal's
web chapter, the web layer calls only the `Portal` facade and renders only the closed `%Portal.Error{}`
set." Its Source: Design by Contract / The Pragmatic Programmer. Where the framework implements it:
`/elixir/phoenix` (the F6 chapter), whose nine rungs all hold that one rule. The glossary entry is the
abstract; the link is the proof. Every term in the dataset has the same three faces.

## Interactive 1 — hero — the reference-module overview (count + categories)

- **Move:** frame the module. How big is the index, and what does it cover?
- **Markup:** an SVG bar/segment overview of the term dataset grouped into categories (decomposition ·
  delivery · spec · loop · framework), plus a `.solid-select` of category buttons. Selecting a category
  filters the count and lists the terms in it; "all" shows the total.
- **Control ids:** `catSel` (button group: all/decomposition/delivery/spec/loop), segments `seg-decomp`,
  `seg-deliver`, `seg-spec`, `seg-loop`, readout `catOut`.
- **Pure functions over a fixed `CATS` array (key/label/terms[]):**
  - `countIn(key) -> int` — number of terms in a category (or total for "all").
  - `readoutFor(key) -> string` — the category label, its count, the share of the total, and a sample term list.
- **Default selection:** all.
- **Sample readout:** `All categories: 15 terms indexed. Decomposition 4 · delivery 5 · spec 3 · loop 3.
  Each term carries an abstract, a Source, and the /elixir route where the framework implements it.`

## Interactive 2 — main — the three-dive router (pick what you came for)

- **Move:** route the reader. Which of the three dives answers the question they arrived with?
- **Markup:** an SVG of three dive nodes (the glossary · the sources · the crosswalk) with a `.solid-select`
  of three intent buttons (`look-up-a-term` / `read-a-source` / `find-the-code`). The chosen intent lights
  the dive that serves it and names its route.
- **Control ids:** `intentSel` (button group), nodes `dv-glossary`, `dv-sources`, `dv-crosswalk`, readout `routeOut`.
- **Pure functions over a fixed `DIVES` map (intent → dive id, label, route, what-it-gives):**
  - `diveFor(intent) -> "glossary" | "sources" | "crosswalk"`.
  - `readoutFor(intent) -> string` — the matched dive, its route, and what it gives.
- **Sample readout:** `To look a term up — open A3.9.1 the glossary (/roadmap/glossary/glossary): the full
  expandable accordion, each term with its abstract, Source, and the /elixir route that implements it.`

## Principle ↔ practice bridge

- **.cell.idea (principle):** a glossary is an index, not a tutorial — a fixed list of terms, each pointing
  outward to where it is defined and where it is used.
- **.arrow**
- **.cell.elix (Portal practice):** the index points at the real Portal: each term links to the
  `/elixir/phoenix/<sub>` chapter where the framework implements the idea, so a concept resolves to code.
- **.take:** the reference module turns the course into something you can look up — every term to an
  abstract, a Source, and the line of the framework that makes it real.

## References

### Sources
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- Continuous Delivery — https://continuousdelivery.com/

### Related in this course
- A3 — The roadmap layer (`/course/agile-agent-workflow/roadmap`)
- A2 — Decomposition (`/course/agile-agent-workflow/decomposition`)
- A1 — Why an Agile Agent Workflow (`/course/agile-agent-workflow/why`)
- F6 — The Portal on the web (`/elixir/phoenix`)
- Companion — Functional Programming in Elixir (`/elixir/course`)

## Wiring

- Route-tag (4 segments): `course/agile-agent-workflow`(link) · `roadmap`(link) · `glossary`(`.rcur`).
- Pager: prev = `/course/agile-agent-workflow/roadmap` · next = `/course/agile-agent-workflow/roadmap/glossary/glossary`.
- Dive cards: A3.9.1 glossary · A3.9.2 sources · A3.9.3 crosswalk.
- Footer: canonical `.foot-cols` + stamp `TSK0Ng9hnHJgW0`.
