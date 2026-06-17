# MCP2 · user stories

> Who wants this, what they need, and how we will know it works — the acceptance face of the
> attribution, liveness, and gate-console rung (mcp2.md).

## MCP2-US1 — actor without touching the ledger
As a peer, I want to pass `actor` on a ledger write and have only my registry row advance, so that
attribution accrues without altering a byte of the audit trail.

Acceptance criteria
- Given a registered actor name, when a writing tool is called with `actor`, then that agent's
  `last_seen_at` and per-prefix activity counter advance and the appended entry header is the
  locked `### <PREFIX>-<n> — <title>` form.
- Given an unregistered actor name, when a writing tool is called with it, then the write proceeds,
  an `UNREGISTERED-ATTRIBUTION` advisory line lands in `.claude/audit.log`, and no registry row is
  created.

INVEST — independent of the signal rules; testable by an exemplar-ledger golden byte-identical with
and without `actor` plus an unregistered-actor test; encodes MCP2-INV1.
Priority: must · Size: 3 · Implements deliverables: MCP2-D1.

## MCP2-US2 — a long-authoring peer is not flagged
As a peer authoring a large design file, I want my deliverable's advancing mtime or my declared
quiet window to count as liveness, so that an hour of heads-down writing never reads as stale.

Acceptance criteria
- Given an agent whose spawn-declared `deliverable` mtime advanced within the window, when liveness
  is evaluated, then the verdict is active with the deliverable mtime named as the winning source —
  with zero tool calls made.
- Given an agent inside an unexpired declared-quiet window, when liveness is evaluated, then the
  verdict is quiet-declared with the window named as the winning source.
- Given an agent with no recent touch, no unexpired quiet window, and no mtime advance, when
  liveness is evaluated, then the verdict is stale.

INVEST — independent; testable by the Q-4 property over the three sources; encodes MCP2-INV2.
Priority: must · Size: 5 · Implements deliverables: MCP2-D2.

## MCP2-US3 — the pre-commit check in one call
As a Director closing a rung, I want `aaw_status` to answer the x.md §10 precondition in one call,
so that no grep stands between the gate and the commit.

Acceptance criteria
- Given a scope with at least one locked D entry and a Z entry, when `aaw_status` runs, then
  `gates.z_eligible` is true and `d_count`/`z_count` report the tallies.
- Given the same call, when the payload returns, then the per-agent liveness verdicts with winning
  sources and the open (unexpired) signals arrive in the same payload.

INVEST — independent; testable by a one-call assertion over a seeded scope; encodes MCP2-INV5.
Priority: must · Size: 3 · Implements deliverables: MCP2-D3.

## MCP2-US4 — honest, non-blocking signals
As a maintainer, I want formation signals emitted only on named machine-checked evidence and never
as blocks, so that the audit log stays trustworthy and no inference deadlocks a run.

Acceptance criteria
- Given registered > spawned, when `agent_register` returns, then one deduplicated FAKE-N line per
  (scope, code, evidence-window) lands in `.claude/audit.log` and the call is not refused.
- Given the R-4 degraded run (only the Director wrote ledger entries), when a Z appends, then no
  V-SOLO-2 line is emitted — the evidence is computed and held registry-side only.
- Given all non-director rows stale by the three-source rule and ≥K director-attributed entries
  within W, when `aaw_status` or a Z-append evaluates, then one V-SOLO-1 line is emitted in the
  fixed format.

INVEST — independent; testable by emission tests over the audit log including the degraded-run
case; encodes MCP2-INV3, MCP2-INV4.
Priority: must · Size: 5 · Implements deliverables: MCP2-D4.

## MCP2-US5 — attribution survives a crash without skewing evidence
As a maintainer, I want the attributed write ordered so the durable audit record leads, so that a
crash between the two files costs only advisory evidence and a retried call leaves visible history.

Acceptance criteria
- Given an attributed write, when it executes, then the ledger append lands before the registry
  counter update, both under the per-scope lock.
- Given a client retry after an ambiguous failure, when the retried call appends, then the
  duplicate is a visible entry under the next n — accepted, inspectable history — and the
  `aaw audit` tally-recount is the named detector for the cross-file drift.

INVEST — independent; testable by a write-order test plus the documented-acceptance check; encodes
MCP2-INV3.
Priority: must · Size: 3 · Implements deliverables: MCP2-D5.

---
Coverage: D1→US1 · D2→US2 · D3→US3 · D4→US4 · D5→US5.  Spec: mcp2.md · Agent brief: mcp2.llms.md.
