# MCP5 · user stories

> Who wants this, what they need, and how we will know it works — the acceptance face of the
> Reconcile tool rung (mcp5.md). Stories are split by audience: `US-A[N]` the agent (the session
> peers who run the reconcile inside their loops), `US-D[N]` the developer (the human who maintains
> the server and its spec corpus).

## MCP5-US-A1 — the pre-build reconcile in one command
As an agent stewarding a rung's spec against HEAD (the pre-build sharpening pass), I want one command
to extract every claim a spec makes and probe it against the tree, so that the mechanical half of the
reconcile is machine work and my judgment is spent on the semantic half.

Acceptance criteria
- Given a rung spec carrying `file:line` cites, relative links, and backticked workspace paths, when
  `aaw -workspace <dir> reconcile <spec>` runs, then every claim appears once in the delta table with
  its kind and a MATCH / STALE / MISSING status, and the tallies sum to the claim count.
- Given an unchanged tree, when the same command runs twice, then the two outputs are byte-identical.

INVEST — independent of mcp2–mcp4; testable by a fixture-spec run plus a double-run comparison; encodes
MCP5-INV1.
Priority: must · Size: 5 · Implements deliverables: MCP5-D1, MCP5-D2.

## MCP5-US-A2 — a scriptable drift gate
As an agent directing a rung close (the pre-ratify drift gate), I want the reconcile verdict as an exit
code and machine-readable output, so that a pre-ratify drift check is one script line, not a reading
exercise.

Acceptance criteria
- Given a spec whose cites all resolve, when the command runs, then it exits 0; given one STALE or
  MISSING claim, then it exits 1 and the table names the claim; given a bad invocation or an
  out-of-workspace input, then it exits 2.
- Given `-json`, when the command runs, then the claims, statuses, tallies, and the limit line arrive
  as one machine-readable document.

INVEST — independent; testable by exit-code assertions over fixture specs; encodes MCP5-INV1.
Priority: must · Size: 3 · Implements deliverables: MCP5-D3.

## MCP5-US-D1 — honest about what a MATCH means
As the developer reading a clean reconcile report, I want the report itself to state that MATCH covers
existence and line-range only, so that nobody mistakes a green table for semantic verification.

Acceptance criteria
- Given any run, when the report renders (text or `-json`), then it carries the limit line naming the
  boundary: existence + line-range is the machine's verdict; semantic agreement is the reconciling
  agent's.
- Given a claim whose file exists but whose cited line is out of range, when classified, then the
  status is STALE — never MATCH, never a softer wording.

INVEST — independent; testable by output-content assertions; encodes MCP5-INV5.
Priority: must · Size: 2 · Implements deliverables: MCP5-D4.

## MCP5-US-D2 — safe to run anywhere, changes nothing
As the developer, I want the reconcile run to be read-only and workspace-contained, so that running it
against any corpus is risk-free.

Acceptance criteria
- Given any run over any input, when it completes, then the tree is byte-identical to before the run.
- Given an input path or a probe target resolving outside `-workspace`, when the command runs, then it
  refuses with exit 2 (input) or reports the target contained-refused (probe) — nothing outside the
  workspace is read.

INVEST — independent; testable by a tree-hash comparison and an escape fixture; encodes MCP5-INV2,
MCP5-INV4.
Priority: must · Size: 2 · Implements deliverables: MCP5-D4.

## MCP5-US-A3 — the locked catalog stays locked
As an agent holding the server's tool schemas (a deferred-schema client), I want this rung to change
no tool surface, so that the locked catalog stays locked and every shape held stays valid.

Acceptance criteria
- Given `aaw selftest` after the rung, when it runs, then the tool count is still 18 and every schema
  is unchanged.

INVEST — independent; testable by the selftest pin; encodes MCP5-INV3.
Priority: must · Size: 1 · Implements deliverables: MCP5-D4.

## MCP5-US-D3 — the grammar is pinned, not folklore
As the developer, I want the claim grammar and the classifier pinned by committed fixtures and goldens,
so that a regression in extraction or classification fails a test instead of silently shrinking the
reconcile's coverage.

Acceptance criteria
- Given the committed fixture set (including one STALE line cite and one MISSING path), when the golden
  test runs, then extraction, classification, tallies, and the limit line all match the goldens.
- Given the test suite, when it runs under `go test -race -count=1`, then it is green, and the
  determinism case compares two runs byte-equal.

INVEST — independent; testable by the goldens themselves; encodes MCP5-INV1, MCP5-INV5.
Priority: must · Size: 3 · Implements deliverables: MCP5-D5.

---
Coverage: D1→US-A1 · D2→US-A1 · D3→US-A2 · D4→US-D1,US-D2,US-A3 · D5→US-D3.  Spec: mcp5.md · Agent brief: mcp5.llms.md.
