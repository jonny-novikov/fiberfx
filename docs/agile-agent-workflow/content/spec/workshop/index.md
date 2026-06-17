# A4.7 · Workshop — specifying Portal's engine (module hub)

- **Route:** `/course/agile-agent-workflow/spec/workshop`
- **File:** `html/agile-agent-workflow/spec/workshop/index.html`
- **Role:** module hub — the A4 capstone. Runs the whole spec layer (A4.1–A4.6) on the Portal's engine
  chapter and reproduces a closed, acceptable spec.
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0` (reused). **Model:** `roadmap/workshop/index.html`
  (the A3 "run the whole sequence" hub) + `spec/index.html` (tone).
- **Pager:** prev `/course/agile-agent-workflow/spec` · next `the-engine-deliverables`.
- **Crumbs:** jonnify (`/elixir`) → Agile Agent Workflow (`/course/agile-agent-workflow`) → A4 (`/spec`) →
  here.

## Grounding (no-invent — verbatim from `docs/elixir/specs/pragmatic/f5.1.{md,stories.md}`)

F5.1 "Start thin: a running Portal" is the engine chapter's first rung — the F5 origin of the F6 master
invariant. F5.1-INV1 is named "(replaceable seam · seed of the master invariant)": "the web layer holds no
domain logic … so F6 can replace `Bandit` with Phoenix untouched". Deliverables F5.1-D1…D7; invariants
F5.1-INV1…INV5. Coverage line (verbatim):
`Coverage: D1→US1 · D2→US2 · D3→US1 · D4→US1,US3 · D5→US1,US4 · D6→US3,US5 · D7→US4.`

## Lead

Six modules taught one move each: specification by example, the triad, the anatomy of a spec, deriving the
stories file, invariants, and the traceability closure. The capstone runs all six on one real target — the
Portal's engine chapter, named in prose as **F5.1 — Portal's engine-facade rung** (the engine chapter's first
rung, the seed of the F6 master invariant) and planned in the companion course at `/elixir/phoenix` — and
produces a spec and a `.stories.md` whose traceability chain closes. The worked output is not invented; it
reproduces the real `pragmatic/f5.1.md` and `f5.1.stories.md` (the engine deliverables the workshop specifies),
including the Coverage line above.

> Workshop ground-truth note (refinement pass): F5.1 sits **below** the F6 web ladder the `/spec/specimens`
> viewer shows — there is no `#f5-1` viewer stop — so this page carries **no** `.specref` chip to the viewer.
> Bare-filename prose citations of `f5.1.md`/`f5.1.stories.md` are de-bared to the named reference
> **F5.1 — Portal's engine-facade rung**; the `/elixir` cross-links (`/elixir/phoenix`, `/elixir/course`) carry
> the place the engine is actually taught. Filename mentions that label a figure, a readout, or the deliverables
> the workshop reproduces stay as-is.

## Framing interactive (hero) — the workshop sequence

The hero figure runs the full A4 sequence as six stacked stages over F5.1's deliverables:
by-example → triad → anatomy → stories → invariants → traceability. Pick a stage; the readout reports the
stage, the artifact it produces (grounded in `f5.1.md`/`f5.1.stories.md`), and the running closure state
(how many deliverables are covered so far, the closure not declared closed until traceability runs last).

- Fixed dataset `STAGES` (six entries, ordered): each carries `rect` id, accent, `produces` string, and a
  `closed` flag (only the final `traceability` stage reports the chain closed).
- Pure `stageArtifact(key)` → the readout string for that stage.
- Static default: stage 1 (by-example) lit; readout reports the worked-examples artifact.
- Control ids: `wsSel` (six buttons `data-k=byexample|triad|anatomy|stories|invariants|trace`,
  `data-c=elixir`); SVG rects `ws-byexample`…`ws-trace`; readout `wsOut` (`aria-live`).
- Degrades: SVG + selector static (stage 1 pre-lit, readout default present); JS only enhances.

## Bridge (hub)

- **The principle** — the full A4 sequence run end to end on one chapter reproduces a closed, acceptable
  spec: examples become checks, invariants are stated, every deliverable traces to a story.
- **On the Portal** — the workshop reproduces the real `f5.1.md` + `f5.1.stories.md`; its Coverage line
  `D1→US1 · D2→US2 · …` closes, so the engine chapter's first rung is acceptable as written.
- **Take** — the workshop is the spec layer applied once on the Portal's engine — the contracts Part V then
  hands an Author to build.

## The three dives (`.mods`)

1. **A4.7.1 — The engine deliverables** (`the-engine-deliverables`) — read F5.1's seven deliverables and the
   master-invariant seed (F5.1-INV1) section by section; what each deliverable constrains.
2. **A4.7.2 — Run the sequence** (`run-the-sequence`) — step the six A4 moves over the F5.1 triad and watch
   the spec take shape, stage by stage, with the closure tracked.
3. **A4.7.3 — The closed spec** (`the-closed-spec`) — check the produced Coverage line against the real one;
   the spec is acceptable only when the chain closes and no deliverable is left without a story.

## References

- Sources: Specification by Example (`gojko.net`), User Stories Applied (`mountaingoatsoftware.com`),
  Continuous Delivery (`continuousdelivery.com`).
- Related: `/course/agile-agent-workflow/spec`, `/course/agile-agent-workflow/roadmap/workshop`,
  `/course/agile-agent-workflow/why/correct`, `/elixir/phoenix`, `/elixir/course`.
