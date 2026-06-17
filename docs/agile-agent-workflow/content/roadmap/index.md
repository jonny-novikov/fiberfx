# A3 · The roadmap layer: Agile delivery & iteration (chapter landing)

- **Route:** `/course/agile-agent-workflow/roadmap`
- **File:** `html/agile-agent-workflow/roadmap/index.html`
- **Role:** chapter landing — a recap of A0→A2 plus a deep expert 5W overview that orients the reader for the
  upcoming A3.1–A3.8 modules (not yet built — described in prose, none linked). It also frames three orientation
  dives, authored next in parallel and linked here.
- **Accent:** elixir-purple (`.ex`), the course signature — consistent with the A2 landing.

## Lead

Decomposition (A2) produced a backlog: a dependency-ordered value ladder of small, valuable, testable user
stories. A3 plans its **delivery**. A backlog says *what* is worth building; a roadmap says *in what order, in what
size, and to what milestone* it ships. The unit stays the same — a thin slice of value, specified only enough,
proven before the next begins — but the question changes from "what are the slices" to "how do we sequence them
into robust increments and re-order them as feedback arrives." That sequencing is the roadmap layer, and the
cadence that runs it is the inspect-and-adapt loop.

## Precise definition

The **roadmap layer** is the coarse, re-orderable plan of *how we deliver*. It is a `roadmap.md`: an ordered list
of thin-but-robust increments grouped into milestones, each pointing at a spec but defining no behaviour itself.
It sits **over** the spec layer (A1.04) and references it; the spec layer remains the single source of truth.
The Operator sequences and prioritises the roadmap; the Author builds each rung against its spec. The roadmap is
re-ordered by feedback between rungs — never the spec, which only feedback edits — so delivery order and definition
of done stay decoupled. This is the separation A1.04 named (how vs what), now given its own artifact and cadence.

## The framing interactive — the course "where we are" arc (the recap)

**Where we are in the course.** An SVG spine of the eight parts A0–A7 laid left to right, each a node; a segmented
selector walks it. The live `.geo-readout` reports the selected part's title, what it delivers, and its build
status. The default selected node is **A3** (you are here). The dataset is fixed and real:

- A0 · Foundations — `/what` — the framework in three questions (why, what, who). — BUILT
- A1 · Why — `/why` — the thesis: thin, provable slices beat vibe-coding and big-bang specs. — BUILT
- A2 · Decomposition — `/decomposition` — vision → a value ladder of small, testable user stories. — BUILT
- A3 · The roadmap layer — `/roadmap` — plan delivery: thin-but-robust increments, the inspect-and-adapt loop. — YOU ARE HERE
- A4 · The spec layer — `/spec` — define and prove each slice (acceptance, Given/When/Then). — planned
- A5 · The agent brief — `/brief` — the `.llms.md` and the implementation pass. — planned
- A6 · Reliability & correctness — `/reliability` — proven-not-asserted, gates, the closure. — planned
- A7 · Portal exemplar — `/portal` — the whole workflow on the Portal, zero to production. — planned

- control id: `#arcSel` (segmented `.solid-select`; eight `button[data-part]`, A3 pre-`active`). `#arcOut` is the
  live `.geo-readout`.
- pure function: `readoutFor(i)` → the readout string for part index `i` from the fixed `PARTS` array (no side
  effects); `partsBefore(i)` → how many parts ship before `i` (the "built so far" count). `paint(i)` lights node
  `i`, dims the rest, and writes `#arcOut` — the only DOM-touching wrapper.
- supporting data: `var PARTS` (8 entries: `id`, `title`, `route`, `delivers`, `status`).
- sample readout (A3, default): "A3 · The roadmap layer — /roadmap. Delivers: a delivery plan — thin-but-robust
  increments, grouped into milestones, run through the inspect-and-adapt loop. Status: you are here. · 3 of 8
  parts built before this one; the backlog from A2 is the input this chapter sequences."
- take: "A0–A2 settled why, what, and which slices; A3 settles the order and size they ship in. The roadmap is the
  layer between a backlog and a built system."

The interactive degrades: the SVG spine and the eight-button selector are present in static markup with A3 lit and
a correct A3 readout; JS only enhances. It honours `prefers-reduced-motion` (transitions are CSS-only on
fill/stroke; the dashed connector animation is gated behind `no-preference`) and uses no browser storage.

## Recap section — "Where we are"

A0 framed the method in three questions (why it works, what we build, who does the work). A1 made the case: neither
no-plan vibe-coding nor an all-plan big-bang ships reliable software; the unit that does is a thin, provable slice,
and the Author/Operator loop (A1.03) is the cadence that runs one. A1.04 separated the two layers — the roadmap
(how we deliver) and the spec (what we build and prove) — which A3 now picks up and expands. A2 produced the
work the loop runs on: a backlog. It taught value-not-tasks, the Connextra form, INVEST, Given/When/Then, splitting,
and the value ladder, and the A2.07 workshop ran the whole sequence on the Portal's real web surface to yield the
nine-rung F6 ladder.

Cross-links placed here: A0 `/what`, A1 `/why`, A2 `/decomposition`; A1.03 the loop `/why/loop`, A1.04 two layers
`/why/two-layers`, A2.07 workshop `/decomposition/workshop`.

## The 5W overview — "The roadmap layer, in five questions"

- **What** — a `roadmap.md`: the coarse, re-orderable plan of *how we deliver*. An ordered list of thin-but-robust
  increments grouped into milestones, each pointing at a spec, defining no behaviour itself.
- **Why** — to separate delivery (how) from definition (what), so the spec stays the single source of truth
  (A1.04) and the order can change under feedback without touching what "done" means.
- **Who** — the Operator sequences and prioritises the roadmap; the Author builds each rung against its spec. The
  Operator owns order; the Author owns production (A1.03).
- **When** — after decomposition, before and between building. The roadmap is re-ordered by feedback between rungs,
  on a different cadence than the spec, which only feedback edits.
- **Where** — it sits *over* the spec layer and points at it, never defining behaviour. The roadmap references
  specs; the specs reference nothing above them.
- **How** — thin-but-robust increments grouped into milestones, run through an inspect-and-adapt iteration loop:
  ship a rung, demo it, take feedback, re-order the roadmap, build the next.

The three orientation dives are linked from this section.

## The three orientation dives (the `.mods` grid — linked)

1. **A3 · `where-we-are`** → `/course/agile-agent-workflow/roadmap/where-we-are` — "Where we are — the journey
   A0→A2 recapped." Focus: the recap, with Where + Who.
2. **A3 · `the-roadmap-layer`** → `/course/agile-agent-workflow/roadmap/the-roadmap-layer` — "Why a delivery layer,
   and what a roadmap.md is." Focus: Why + What.
3. **A3 · `the-road-ahead`** → `/course/agile-agent-workflow/roadmap/the-road-ahead` — "A deep overview of the
   eight A3 modules ahead." Focus: the eight A3.1–A3.8 modules, the When/How preview.

## The chapter ahead — A3.1–A3.8 (NON-link `.mod` cards, `soon` pills)

Described, never linked (unbuilt → would dangle):

- **3.1 Agile, distilled** — the values and the loop behind every later technique, stripped to essentials.
- **3.2 Extreme Programming for small batches** — the XP practices that survive when the batch is one thin slice.
- **3.3 Anatomy of a roadmap.md** — the artifact itself: rungs, milestones, the line that points at a spec.
- **3.4 Thin but robust** — a slice can be small and still production-grade; what "robust" adds to "thin."
- **3.5 Milestones and iterations** — grouping rungs into shippable milestones and the cadence that walks them.
- **3.6 The program roadmap** — sequencing many chapters of work; dependency and value across a whole program.
- **3.7 Tracer bullets and walking skeletons** — the first end-to-end increment that proves the architecture.
- **3.8 Workshop — roadmapping Portal** — the full sequence on the Portal: a backlog turned into a delivery plan.

## References (Sources — real, vetted)

- Humble & Farley — *Continuous Delivery* — https://continuousdelivery.com/ — keeping the system releasable at
  every increment; delivery as the discipline this layer plans.
- Beck, K. — *Extreme Programming Explained* — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
  — small batches, iterations, and the inspect-and-adapt loop.
- Hunt & Thomas — *The Pragmatic Programmer* — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
  — tracer bullets and walking skeletons: the first thin increment that runs end to end.

## Related in this course (internal — must resolve)

- A2 `/decomposition` — the backlog this chapter sequences.
- A1.04 `/why/two-layers` — the roadmap/spec separation A3 expands.
- A0.2.2 four artifacts `/what/four-artifacts` — the per-rung artifacts a roadmap line points at.
- The three dives: `/roadmap/where-we-are`, `/roadmap/the-roadmap-layer`, `/roadmap/the-road-ahead` (authored in
  parallel — a `links` FAIL on these three is expected until they land).
- `/elixir/phoenix` — the real F6 chapter built from a `phoenix.roadmap.md`; `/elixir/course` — the companion.

## Pager

- prev: `/course/agile-agent-workflow/decomposition` (A2 landing)
- next: `/course/agile-agent-workflow/roadmap/where-we-are` (the first orientation dive)
