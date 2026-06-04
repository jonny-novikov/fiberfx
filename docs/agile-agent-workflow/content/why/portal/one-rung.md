# A1.06.3 — One rung at a time

**Route:** `/course/agile-agent-workflow/why/portal/one-rung`
**Position:** A1.06 · Meet the project: Portal · dive 3 (the module's resolution).
**Accent word:** `rung`.

## Lead

The Portal is not poured in one go. It is climbed: one rung, then the next, each rung a thin slice
run through the Author/Operator loop until it is accepted. This dive resolves the module — the Portal
is the running project the rest of the course builds, one provable rung at a time.

## The definition

A rung is one accepted increment of the Portal. It is sharpened by the Operator, built and shipped by
the Author, demoed and reviewed by the Operator, and closed by feedback that edits the spec (the A1.03
loop). Nothing about the Portal lands except as a rung, and no rung lands until it is accepted.

The climb has two properties the rest of the course leans on:

- **One rung at a time** — the work advances in thin slices, each provable on its own. The Portal is
  never half-poured; it is exactly as tall as the last accepted rung.
- **Rungs accumulate, the core stays one facade** — every rung adds to a platform that already runs.
  The engine stays behind one facade; each surface (store, web, bot, dashboard) stacks onto it. The
  Portal accumulates instead of resetting.

## Worked Portal example — one rung, the loop runs

Take the branded-id rung: a typed id minted only via `Portal.ID.generate/1` and read only via
`Portal.ID.decode/1` (`.type`, `.timestamp`). One turn of the loop carries it from sharpened to
accepted, six stages, each with an owner (the A1.03 split, exact):

1. **sharpen** — Operator. Scope the rung and fix what "done" means: a 14-char id that decodes to its type.
2. **build** — Author. Spec the rung, then build `Portal.ID.generate/1` from the spec and the brief.
3. **ship** — Author. Ship the increment so it runs; the Author never decides the goal.
4. **demo** — Operator. Exercise it on something real: mint an id, decode it, read `.type`.
5. **review** — Operator. Judge the increment against the spec — accept, or send it round again.
6. **feedback** — Operator. Record the edit; it lands in the spec, and the next rung starts from it.

The Operator owns sharpen, demo, review, feedback (intent and judgement) and never writes code; the
Author owns build and ship (production) and never decides the goal. Feedback edits the spec, not the
code — the single source of truth from A1.04.

## The two interactives (different moves)

**Hero — one rung on the Portal.** Step through a single rung (the branded-id rung) running the loop:
sharpen → build → ship → demo → review → feedback. The readout names the current stage, its owner, and
its output. Pure: a fixed six-stage dataset, a `stageOf(i)` selector. This frames the move: one rung is
one turn of the loop, end to end.

**Main — rungs accumulate.** A stepper that adds rungs to the Portal one at a time: store → engine →
web → bot → dashboard. The readout shows the platform growing while the core stays one facade and each
earlier concept stacks (the id authority from A1.06, the loop from A1.03, the spec from A1.04). Pure: a
fixed five-rung dataset, `climbedThrough(n)` returns the accumulated surfaces and the facade count
(always 1). This proves the consequence: the Portal accumulates instead of resetting.

The two teach different moves — the hero frames one rung as one turn; the main proves that rungs stack
onto a platform that already runs.

## The principle → practice bridge

- **Principle:** build software in thin, provable increments; each tracer slice runs end to end and the
  next is added without rewriting the last (the Pragmatic / Continuous Delivery thesis).
- **Practice on the Portal:** every Portal surface lands as one accepted rung through the loop; the
  engine stays behind one facade, and store, web, bot, and dashboard stack onto it. The platform is
  always running and always exactly as tall as the last accepted rung.

## Recap — the module resolves

The Portal is the running project the rest of the course builds, one provable rung at a time. A0 named
the artifacts; A1.01–A1.05 named the unit, the principles, the loop, the two layers, and what "done"
means; this module made the project concrete. Each rung is sharpened, built, shipped, demoed, reviewed,
and closed by feedback — and the rungs accumulate onto one facade. A page may call a rung "correct by
definition" once its checks close, but that closure is A1.05's subject, not this one. The next stop is
the module overview, which lists the dives that built this picture.

## References

Sources (real external links only):
- The Pragmatic Programmer → https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
  — tracer slices: build thin, end-to-end increments.
- Anthropic — Building effective agents → https://www.anthropic.com/engineering/building-effective-agents
  — the agent as an implementer of well-specified, bounded work.
- Continuous Delivery → https://continuousdelivery.com/ — keep the system always releasable as it grows.

Related in this course:
- A1.06 hub → /course/agile-agent-workflow/why/portal
- A1.03 · The Author/Operator loop → /course/agile-agent-workflow/why/loop
- A1.04 · Two layers → /course/agile-agent-workflow/why/two-layers
- A1 · Why an Agile Agent Workflow → /course/agile-agent-workflow/why

## Pager

- prev → /course/agile-agent-workflow/why/portal/zero-to-production ("A1.06.2 · Zero to production")
- next → /course/agile-agent-workflow/why/portal ("A1.06 · Module overview")
