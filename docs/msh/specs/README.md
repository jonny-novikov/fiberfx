# msh — the specs layer

> The rung triads of the forward msh program. The contract is
> [aaw.specs-approach](../../aaw/aaw.specs-approach.md) — this file adopts it and fixes the local layout;
> the triads derive from the ruled [../msh.design.md](../msh.design.md) (never the reverse), and the ladder
> is [../msh.roadmap.md](../msh.roadmap.md).

## Layout (flat; the echo_mq-canon shape)

- `msh2.N.md` — the rung spec: goal, agent stories' contract, invariants, the gate list, boundary.
- `msh2.N.stories.md` — the acceptance stories (given/when/then over the rung's public surface).
- `msh2.N.llms.md` — the brief an implementor loads: the surface table + the citations + the gates, nothing
  restated that the spec owns.
- `msh2.N.prompt.md` — optional: the run's orchestration runbook when a rung needs one.
- `progress/<scope>.progress.md` + `progress/<scope>.registry.json` — the aaw run ledger + roster for each
  ship run (machine artifacts; the genesis scope is `msh-genesis`, a rung run's scope is `msh2-N`).

## The laws

- A triad is authored by Venus AFTER the design ruling it builds on; a triad that contradicts the design is
  a defect in the triad.
- NO-INVENT: every named surface in a triad carries a design § or a verified `file:line`; forward-tense for
  the rung's own new surface.
- The rung ids are `msh2.N` (D-4); `msh.0–msh.6` belong to the frozen as-built record at
  [docs/go/msh](../../go/msh/msh.roadmap.md) and are never reused.
- A rung closes only with its triad present, its gates green, its progress row updated, and its LAW-4
  commit made ([../program/msh.program.md](../program/msh.program.md) §5).
