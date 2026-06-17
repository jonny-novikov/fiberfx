# A3.3.1 · What it carries — dive

- **Route:** `/course/agile-agent-workflow/roadmap/roadmap-anatomy/what-it-carries`
- **File:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/what-it-carries.html`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Pager:** prev = `…/roadmap-anatomy` (hub); next = `…/roadmap-anatomy/the-iteration-table`.

## Lead

A complete chapter roadmap carries six parts, each answering a different question, and none of them defining
behaviour. Read them in order in the real `phoenix.roadmap.md` and the shape of the document becomes a template.

## The six parts (verbatim section names + a verbatim phrase from `phoenix.roadmap.md`)

1. **What we are delivering** — the deliverable. Verbatim: "The Portal, served to people: a real web application
   that renders the catalog, lets learners enroll and progress…".
2. **Where this starts and ends** — the start/end handoff. Verbatim: "Start (the F5 handoff)." and "End (after
   F6.9)."
3. **Architecture decision — standard Phoenix on the BEAM** — the structural choice. Verbatim: "The stack is
   standard Phoenix, Ecto, and LiveView on the BEAM — the conventional, well-supported path — with no separate
   frontend application."
4. **The delivery arc** — the milestones. Verbatim row headers: "1 · Ship the catalog", "2 · Make it live",
   "3 · Ship to users".
5. **Per-rung iterations** — the per-iteration table (the A3.3.2 dive).
6. **Seams & open decisions** — the open decisions (the A3.3.3 dive).

The master invariant (verbatim): "The web layer calls only the `Portal` facade and renders only the closed
`%Portal.Error{}` set. No controller, LiveView, plug, or template names `Portal.Engine`, a repo, or
`GenServer.call`." Verbatim consequence: "This single rule is what makes the ladder cheap".

## Hero interactive — decompose one real roadmap line

- **What it frames.** One real `roadmap.md` line decomposes into {rung, milestone, the spec it points at,
  behaviour = none}. A rung line orders and points; it never defines.
- **Element ids:** controls `#lineRung` (buttons over a fixed set of real rungs: f6.1, f6.3, f6.5, f6.6),
  SVG `#lineMap`, readout `#lineOut` (`aria-live="polite"`).
- **Pure function:** `decomposeLine(rung) -> {rung, milestone, spec, behaviour}` over a fixed `RUNGS` dataset, where
  `behaviour` is always the constant `"none"`. Readout composed from the four fields.
- **Sample readout:** "f6.3 → milestone 1 · Ship the catalog · points at spec f6.3.md · behaviour defined: none. The
  line orders and points; the spec defines."

## Main interactive — the part picker over the six section names

- **What it proves.** Each of the six parts answers a distinct question; selecting a part shows its question, its
  role, and a verbatim phrase. Distinct move from the hero (the hero decomposes a single line; this walks the whole
  anatomy).
- **Element ids:** controls `#partPick` (six buttons, `data-k` ∈ {delivering, handoff, arch, milestones, table,
  decisions}), readout `#partOut` (`aria-live="polite"`), an SVG `#partList` outline of the six parts.
- **Pure function:** `partInfo(key) -> {name, question, quote}` over a fixed `PARTS` dataset. Readout = the three
  fields.
- **Sample readout:** "Architecture decision — standard Phoenix on the BEAM · question: what one structural choice
  shapes the chapter? · verbatim: 'with no separate frontend application'."

## Bridge

- **Principle:** A roadmap carries six parts — deliverable, handoff, architecture decision, milestones, the
  per-iteration table, the open decisions — and none defines behaviour.
- **Portal practice:** `phoenix.roadmap.md` carries all six; each rung points at its `f6.N.md` spec; the master
  invariant holds at every rung.

## References — Sources (verbatim, real URLs)

- Continuous Delivery — https://continuousdelivery.com/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/

## Related (resolving)

- `/course/agile-agent-workflow/roadmap/roadmap-anatomy` — the hub.
- `/course/agile-agent-workflow/roadmap/the-roadmap-layer` — the anatomy expanded.
- `/course/agile-agent-workflow/why/two-layers` — roadmap over spec.
- `/elixir/phoenix` — the real F6 chapter.
