# A3 · Where we are — the journey A0→A2 recapped

- **Route:** `/course/agile-agent-workflow/roadmap/where-we-are`
- **File:** `html/agile-agent-workflow/roadmap/where-we-are.html`
- **Numbering:** A3 · orientation dive 1 (of 3)
- **Accent:** elixir-purple (`.ex`)
- **Stamp:** `TSK0Ng9hnHJgW0`

## Lead

The first orientation dive of A3. Before the roadmap layer is unpacked, the reader needs to know
where they stand and who acts. This dive recaps the journey — A0 Foundations framed the method, A1
Why made the case for thin, provable slices and named the Author/Operator loop, A2 Decomposition
produced a value ladder of user stories — and locates A3: the layer that plans the *delivery* of
that backlog. It foregrounds **WHERE** the roadmap sits (over the spec layer; it points down, it
never defines behaviour — A1.04) and **WHO** acts (the Operator sequences and prioritises; the
Author builds each rung — A1.03 / A0.2.3).

## Precise definition

A recap is not new material; it is a locator. Two facts are load-bearing for everything A3 teaches:

- **WHERE the roadmap sits.** The roadmap layer is *over* the spec layer. It points down at specs
  and never defines behaviour of its own (A1.04, two layers). Re-ordering the roadmap touches the
  roadmap; it cannot edit a spec. The spec is the single source of truth; only feedback edits it.
- **WHO does the work.** The human **Operator** owns judgement, decomposition, sequencing, and
  acceptance. The Claude **Author** owns fast, well-specified implementation of one rung at a time.
  Re-ordering and prioritising are Operator moves. Defining behaviour is a spec move (owned by the
  Operator through feedback). Accepting is an Operator move. The Author builds.

The course is one argument across eight parts, A0–A7. Three are built (A0, A1, A2); A3 is the
current part; A4–A7 build on top of it.

## The journey so far (the recap)

- **A0 — Foundations** (`/course/agile-agent-workflow/what`) framed the method in three questions —
  why it works, what we build, who does the work — and named the two roles the rest of the course
  runs on: the Operator and the Author. The Author/Operator loop (A0.2.3 /
  `/what/author-operator-loop`) is the cadence that runs one rung end to end.
- **A1 — Why an Agile Agent Workflow** (`/course/agile-agent-workflow/why`) made the case: neither
  no-plan vibe-coding nor an all-plan big-bang ships reliable software; the unit that does is a
  thin, provable slice. The Author/Operator loop (A1.03, `/why/loop`) is its cadence; Two layers
  (A1.04, `/why/two-layers`) drew the roadmap/spec line A3 inherits.
- **A2 — Decomposition** (`/course/agile-agent-workflow/decomposition`) produced the backlog: value
  not tasks, the Connextra form, INVEST, Given/When/Then acceptance, splitting, and ordering into a
  value ladder. The A2.07 workshop (`/decomposition/workshop`) ran the whole sequence on the
  Portal's web surface to yield its nine-rung F6 ladder — the backlog A3 now plans to deliver.

A3 plans the delivery of that backlog.

## Worked Portal example

Take the Portal's F6 web backlog from the A2 workshop — nine rungs of user stories, ordered into a
value ladder. A2 answered *what is worth building*. A3 turns that ladder into a `roadmap.md` that
*points at* each rung's spec, groups the rungs into shippable milestones, and is re-ordered by
feedback between rungs. The `roadmap.md` defines no behaviour; every behaviour lives in a spec the
roadmap line points at. The Operator sequences the ladder; the Author builds each rung against its
spec.

## Interactive 1 — hero — the course-arc "you are here" map (locate the reader)

- **Move:** locate the reader. Where does this dive sit in the eight-part arc?
- **Markup:** a compact SVG spine of eight nodes A0–A7. A0/A1/A2 lit `done` (sage), A3 highlighted
  `active` (elixir). A `.solid-select` of eight buttons (A0–A7) + each SVG node is selectable.
- **Control ids:** `arcSel` (the button group), nodes `arc-0`…`arc-7`, readout `arcOut`.
- **Pure functions over a fixed `PARTS` array (id/title/route/delivers/status):**
  - `partsBefore(i) -> int` — count of `status === "built"` parts before index `i`.
  - `readoutFor(i) -> string` — the full readout for part `i`: id · title — route · Delivers · Status · tail.
- **Default selection:** A3 (index 3) — the part this dive belongs to.
- **Sample readout:** `A3 · The roadmap layer — /roadmap. Delivers: a delivery plan — thin-but-robust
  increments grouped into milestones, run through the inspect-and-adapt loop. Status: you are here.
  · 3 of 8 parts built before this one; the A2 backlog is the input this chapter sequences.`

## Interactive 2 — main — the layer-stack + ownership locator (prove WHERE + WHO)

- **Move:** prove WHERE and WHO. Which layer does an action touch, and who owns it?
- **Markup:** a 2-layer SVG — the roadmap layer (blue) drawn *over* the spec layer (elixir), with a
  downward "points at" arrow from roadmap to spec. An Operator/Author role toggle (`actorSel`) and a
  three-button action select (`actSel`): `re-order` / `define-behaviour` / `accept`. The chosen
  action highlights the layer it touches and reports the owner; if the selected role does not own the
  action, the readout says so.
- **Control ids:** `actorSel` (Operator/Author toggle), `actSel` (action buttons), layers
  `lyr-road` / `lyr-spec`, readout `ownOut`.
- **Pure functions over a fixed `ACTIONS` map:**
  - `layerFor(action) -> "roadmap" | "spec"` — re-order → roadmap; define-behaviour → spec; accept → roadmap (acceptance reads the demo against the roadmap rung).
  - `ownerFor(action) -> "Operator" | "Author"` — re-order/define-behaviour/accept are all Operator-owned; the Author builds the rung, never sequences or defines.
  - `readoutFor(action, role) -> string` — the layer touched, the owner, and whether the chosen role matches.
- **Invariant proven:** re-ordering touches the roadmap, never the spec; the Operator owns
  sequencing. The Author builds — it does not re-order, define behaviour, or accept.
- **Sample readout:** `Action "re-order the backlog" touches the roadmap layer — never the spec.
  Owner: the Operator. You are viewing as the Operator: this is your move. Re-ordering changes the
  delivery order; it cannot edit a spec.`

## Principle ↔ practice bridge

- **.cell.idea (principle):** A course is layers, each standing on the last. A0 framed the method,
  A1 made the case, A2 produced the slices — and A3 stands on all three.
- **.arrow**
- **.cell.elix (Portal practice):** A0–A2 produced a backlog of the Portal's slices; A3 turns it into
  a `roadmap.md` that points at specs — sequencing delivery without defining behaviour.
- **.take:** A0–A2 settled why, what, and which slices; A3 settles the order and size they ship in —
  the roadmap is the layer between a backlog and a built system, owned by the Operator.

## References

### Sources
- Continuous Delivery — https://continuousdelivery.com/ — keeping the system releasable at every
  increment; delivery as the discipline this layer plans.
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
  — small batches, iterations, and the inspect-and-adapt loop the roadmap runs through.
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
  — thin slices and the roles that build them.

### Related in this course
- A0 — Foundations (`/course/agile-agent-workflow/what`)
- A1 — Why an Agile Agent Workflow (`/course/agile-agent-workflow/why`)
- A2 — Decomposition (`/course/agile-agent-workflow/decomposition`)
- A1.03 — The Author/Operator loop (`/course/agile-agent-workflow/why/loop`)
- A1.04 — Two layers: roadmap and specs (`/course/agile-agent-workflow/why/two-layers`)
- A0.2.3 — The Author/Operator loop (`/course/agile-agent-workflow/what/author-operator-loop`)
- A2.07 — Workshop: decomposing Portal (`/course/agile-agent-workflow/decomposition/workshop`)
- A3 — The roadmap layer (`/course/agile-agent-workflow/roadmap`)
- Companion — Functional Programming in Elixir (`/elixir/course`)

## Wiring

- Route-tag (4 segments): `course/agile-agent-workflow`(link) · `roadmap`(link) · `where-we-are`(`.rcur`).
- Pager: prev = `/course/agile-agent-workflow/roadmap` · next = `/course/agile-agent-workflow/roadmap/the-roadmap-layer`.
- Footer: canonical `.foot-cols` + stamp `TSK0Ng9hnHJgW0`.
