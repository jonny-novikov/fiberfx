# A4.7.2 · Run the sequence (dive 2)

- **Route:** `/course/agile-agent-workflow/spec/workshop/run-the-sequence`
- **File:** `html/agile-agent-workflow/spec/workshop/run-the-sequence.html`
- **Pager:** prev `the-engine-deliverables` · next `the-closed-spec`.
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`. **Model:** `why/two-layers/spec.html` (lesson).

## Grounding (verbatim from `f5.1.md` + `f5.1.stories.md`)

Workshop citation rule: F5.1 is the Portal ENGINE rung, which sits below the F6 web ladder the spec-ladder
viewer shows — there is no `#f5-1` viewer stop, so this page adds **no** `.specref` chip to `/spec/specimens`.
Instead, the prose names it once with a named reference — **F5.1 — Portal's engine-facade rung** (the engine
chapter's first rung; the seed of the F6 master invariant) — so the rung is framed, not a bare filename. The
`f5.1.md` / `f5.1.stories.md` mentions elsewhere are the illustrated subject (the spec the sequence reads and
reproduces, named in figures, the readout, and the code excerpt), and stay as-is. The engine itself is taught
in the companion `/elixir` course (`/elixir/phoenix` / `/elixir/course`), kept as a cross-link in References.

The six A4 moves run on the F5.1 triad:

1. **By-example** — replace abstract requirements with worked cases (F5.1-US1's three: boot, `POST /enroll`
   → `422 :not_implemented`, an unknown path → `404`).
2. **The triad** — `f5.1.{md, stories.md, llms.md}` answer *what & why & done* · *who wants what* · *how to
   build with proof gates*.
3. **Anatomy** — `f5.1.md` carries Goal · Rationale (5W) · Scope · Deliverables (D1…D7) · Invariants
   (INV1…INV5) · Definition of Done.
4. **Stories** — `f5.1.stories.md` carries five Connextra stories US1…US5, each with Given/When/Then and an
   INVEST line.
5. **Invariants** — F5.1-INV1 (the replaceable seam), INV2 (identity), INV3 (supervision), INV4 (pure id
   functions), INV5 (functional core).
6. **Traceability** — the Coverage line maps every deliverable to its stories:
   `Coverage: D1→US1 · D2→US2 · D3→US1 · D4→US1,US3 · D5→US1,US4 · D6→US3,US5 · D7→US4.`

## Lead

The spec layer is six moves; the workshop runs them in order on one chapter. Each move produces a named part
of the spec, and the parts accumulate until the rung is fully defined and provable. This dive steps the
pipeline over the F5.1 triad and watches the spec take shape — the abstract requirement collapsing into
worked examples, the triad splitting the work across three files, the anatomy filling section by section, the
stories deriving from the deliverables, the invariants stated, and the chain closed. The output is the real
`f5.1.md` and `f5.1.stories.md`, reproduced not invented.

## Hero interactive — step the six moves, watch the spec fill

Hero figure: the six stages as an ordered pipeline. Step forward; the readout names the current move, the
artifact it produces (grounded in `f5.1`), and the running completion — how many of the six parts of the spec
are in place so far. Teaches the sequence and the accumulation.

- Fixed dataset `MOVES` (six entries): each carries `rect` id, accent, `produces` string.
- Pure `movesDone(i)` (count of stages at or before index i) and `moveReadout(i)` → string.
- Static default: stage 1 (by-example) lit; readout reports the worked-examples move and "1 of 6 in place".
- Control ids: `mvSel` (six buttons + a step control); SVG rects `mv-1`…`mv-6`; readout `mvOut`
  (`aria-live`). A `data-c=elixir` on the active button.

## Main interactive — one deliverable through the chain

Main figure: pick one F5.1 deliverable (D1…D7); the readout walks it through the chain — the story that
realizes it (from the Coverage line), the acceptance it earns (a Given/When/Then from that story), and the
invariant it touches where one applies. Teaches the consequence: each move connects to the next, so a
deliverable is not "done" until it has a story and a check. Different move from the hero (which steps the
whole pipeline once); this traces one item end to end.

- Fixed dataset `D2S` (deliverable → stories), drawn verbatim from the Coverage line; plus a short
  acceptance gloss per deliverable from `f5.1.stories.md`.
- Pure `chainReadout(key)` → string.
- Static default: D4 selected (it maps to US1,US3); readout reports its stories and acceptance.
- Control ids: `chSel` (seven buttons `data-k=d1…d7`, `data-c=elixir`); SVG rows `ch-deliv`, `ch-story`,
  `ch-check`; readout `chOut` (`aria-live`).

## pre.code (markdown only)

An excerpt: the six A4 moves as a comment list, then the `f5.1.stories.md` Coverage line verbatim — rendered
with `.cmt`/`.str`/`.res` spans. No Elixir source.

## Bridge

- **The principle** — the spec layer is six ordered moves; run them on a chapter and each produces a named
  part, until the rung is fully defined and provable.
- **On the Portal** — the six moves over **F5.1 — Portal's engine-facade rung** reproduce `f5.1.md` and
  `f5.1.stories.md` — Goal through DoD, five stories, five invariants, and the Coverage line that closes them.
- **Take** — the workshop is the sequence applied once: examples to checks, deliverables to stories,
  invariants stated, the chain closed.

## References

- Sources: Specification by Example (`gojko.net`), User Stories Applied (`mountaingoatsoftware.com`),
  Continuous Delivery (`continuousdelivery.com`).
- Related: hub, `/course/agile-agent-workflow/spec`, `/course/agile-agent-workflow/roadmap/workshop`,
  `/elixir/phoenix`, `/elixir/course`.
