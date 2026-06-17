# AAW4 · The validation run
> The reverse playbook run end-to-end against the production `echo/apps/echomq` library — a retrospective spec
> chapter plus a hardening pass — so the framework's reverse capability is proven by one complete run, not asserted.

## Goal
The reverse playbook of [aaw.reverse.md](aaw.reverse.md) is executed once against a real production tree:
`echo/apps/echomq` is specified as the chapter `docs/echomq/specs/core/` (index, roadmap, progress, seven
triads), its groundings verified convergently, and every invariant mapped to a running check or an explicit
recorded gap — leaving the framework's reverse direction demonstrated by execution.

## Rationale (5W)
- **Why**   — AAW3 defines the code→spec capability but proves nothing; a framework that claims a reverse
  direction must run it once against production code, surface real deltas, and harden real gaps, or the
  capability is theory.
- **What**  — the seven-stage reverse run instantiated for `echo/apps/echomq`: the chapter instruments, seven
  `c1`–`c7` triads of as-built surfaces, convergent expert verification, the invariant→check hardening, and
  the fold-back into the playbook and the rules.
- **Who**   — the Operator (proof the framework solves the reverse task before trusting it on other trees), the
  echomq maintainer (as-built behavior pinned by specs and running checks), the Director (the run composes the
  two formations without breaking the git discipline), the domain experts (deltas recorded, never silently
  synced).
- **When**  — the fourth and final rung of the framework ladder; depends on AAW1 (the definition), AAW2 (the
  rules and the two formations), and AAW3 (the playbook this rung executes). It is the M2 milestone.
- **Where** — the output lands under `docs/echomq/specs/core/` (the index `core.md`, the roadmap
  `core.roadmap.md`, the durable record `core.progress.md`, and the triads `c1`–`c7`); the verification target
  is `echo/apps/echomq` (`lib/`, `priv/scripts/`, `test/`); the hardening edits `echo/apps/echomq` only through
  the lead-team. The fold-back edits [aaw.reverse.md](aaw.reverse.md) and [aaw.rules.md](aaw.rules.md).

## Scope
- **In**  — the validation run end-to-end: the chapter instruments (AAW4-D1), the seven as-built triads
  (AAW4-D2), convergent grounding verification (AAW4-D3), the invariant→check hardening (AAW4-D4), and the
  fold-back plus the index flip to `built` (AAW4-D5).
- **Out** — the other umbrella apps (`portal`, `echo_data`, `echo_bot`) as reverse targets — named future runs
  in [aaw.roadmap.md](aaw.roadmap.md); any course HTML; any `echo/apps/echomq/lib/` change outside a lead-team
  rung; the sibling spec families under `docs/echomq/specs/` (`emq/`, `reference/`,
  `trading/`), which this run does not touch.

## Deliverables
- **AAW4-D1** — the chapter instruments at `docs/echomq/specs/core/`: `core.md` (the as-built subsystem ladder
  C1–C7, the library-intrinsic master invariant, the rate-limiting cross-cutting invariant, the as-shipped
  error vocabulary), `core.roadmap.md` (the reconcile-and-harden plan with its iteration table), and
  `core.progress.md` (the mandatory durable record: verification notes, delta records, the invariant→check
  table) — authored by the orchestrator per stages 2–3 of the playbook.
- **AAW4-D2** — seven reverse triads `c1`–`c7` on the playbook's re-keyed template: C1 keys plus the
  protocol/Lua floor · C2 the job model · C3 the scripts execution layer · C4 the worker plus the lock · C5 the
  queue facade · C6 scheduling plus flows · C7 events plus cancellation, the stalled checker, backoff, and
  telemetry — every surface cited as `Module.fun/arity` with its `file:line`, fanned out at most two concurrent
  with the heaviest rung alone.
- **AAW4-D3** — convergent adversarial grounding verification: two independent domain experts re-verify every
  triad (no-invent · exact-arity · `file:line`-resolves · real Lua and key names), with findings recorded as
  delta-taxonomy entries in `core.progress.md`; an INVENTED or STALE entry loops back to re-authoring the
  triad before any hardening runs.
- **AAW4-D4** — the hardening: the invariant→check table written md-first into `core.progress.md`;
  `core.h1.prompt.md` (the lead-team runbook); and the lead-team rung(s) closing the chosen gaps — the four
  untagged concurrency test files plus the untagged stress file that hang a plain `mix test`, missing property
  tests, doc-comment defects, and any genuinely failing invariant in `lib/` — each rung closed by one Director
  pathspec commit touching the echo tree only.
- **AAW4-D5** — the fold-back: the run's findings folded into [aaw.reverse.md](aaw.reverse.md) and
  [aaw.rules.md](aaw.rules.md) as inspect-and-adapt edits, and the AAW4 ladder row in [aaw.md](aaw.md) flipped
  from `in progress` to `built` at close.

## Invariants
- **AAW4-INV1** — no-invent and exact-arity hold across the chapter: every cited surface exists in the tree at
  its cited location with its true arity, and the playbook's four added gates (grounding · no-invent ·
  exact-arity · `file:line`-resolves) pass for every triad.
- **AAW4-INV2** — code-canonical discipline: no intent-level divergence is silently synced in either artifact;
  every such doubt is a recorded delta surfaced to the Operator, never a quiet correction in the spec or the
  code.
- **AAW4-INV3** — every invariant defined in `c1`–`c7` maps to a running check (cited `file:line`) or to an
  explicit recorded gap in the invariant→check table; the echo tree is edited only through the lead-team
  formation.
- **AAW4-INV4** — the run composes the two formations per [aaw.rules.md](aaw.rules.md): fan-out work runs no
  git (the Operator commits batches out-of-band), and each lead-team hardening rung closes with exactly one
  Director pathspec commit.

## Definition of Done
- [ ] `docs/echomq/specs/core/` present with `core.md`, `core.roadmap.md`, `core.progress.md`, and the seven triads `c1`–`c7`
- [ ] every surface cited as `Module.fun/arity` with a `file:line` that resolves; the four reverse gates pass for every triad (AAW4-INV1)
- [ ] expert verification convergent; deltas recorded in `core.progress.md`, INVENTED/STALE looped back before hardening (AAW4-INV2, AAW4-INV3)
- [ ] the invariant→check table complete; each chosen hardening gap closed by one Director pathspec commit on the echo tree (AAW4-INV3, AAW4-INV4)
- [ ] the findings folded into the playbook and the rules; the AAW4 index row reads `built`

Stories: ./aaw4.stories.md · Agent brief: ./aaw4.llms.md · Index: ./aaw.md · Approach: ../elixir/specs/specs.approach.md
