# MCP3 · user stories

> Who wants this, what they need, and how we will know it works — the acceptance face of the
> error-vocabulary + ledger-grammar rung (mcp3.md).

## MCP3-US1 — a refusal the caller can branch on
As the harness routing a failed tool call, I want every refusal to carry a stable code, so that a
branch keys on the code and never on the English of the message.

Acceptance criteria
- Given any domain gate (bad slug, uninitialized scope, missing parent, zero-D complete), when it
  refuses, then the tool result is `IsError` with text `aaw: <CODE>: <detail>` and `<CODE>` is the
  matching closed-set code.
- Given the message detail is reworded, when the caller branches on `<CODE>`, then the branch is
  unaffected — the code is the contract, the detail is prose.

INVEST — independent of MCP4; testable by an exact-code assertion per gate; encodes MCP3-INV1.
Priority: must · Size: 5 · Implements deliverables: MCP3-D1, MCP3-D2.

## MCP3-US2 — no refusal escapes the vocabulary
As a maintainer, I want every domain refusal to come from the one closed set, so that the refusal
surface is enumerable and a stray free-text error cannot slip through.

Acceptance criteria
- Given the built server, when a grep scans the tool handlers and store for tool-result errors, then
  none returns a bare `fmt.Errorf` string — each routes through the one home (`internal/gates`).
- Given a new code is needed later, when it is added, then it is a new constant in the one home, and no
  existing code is renamed or removed.

INVEST — independent; testable by the grep gate + the constant-set test; encodes MCP3-INV1, MCP3-INV2.
Priority: must · Size: 3 · Implements deliverables: MCP3-D2, MCP3-D4.

## MCP3-US3 — the init flag stops being ambiguous
As a caller of `aaw_init`, I want to know whether the scope row was new and whether the ledger file was
created, so that re-open is distinguishable from first init — without breaking the v1 `created` flag.

Acceptance criteria
- Given a first `aaw_init` of a scope, when it returns, then `scope_created` and `ledger_created` are
  both true and `created` equals `scope_created`.
- Given a re-`aaw_init` of an existing scope with its ledger present, when it returns, then
  `scope_created` and `ledger_created` are both false and `created` equals `scope_created` — a client
  reading only `created` keeps the v1 meaning unchanged.

INVEST — independent; testable by a first-vs-reopen init assertion; encodes MCP3-INV3.
Priority: should · Size: 2 · Implements deliverables: MCP3-D3.

## MCP3-US4 — the codes are pinned by a test
As a maintainer, I want a running check to assert each refusal's exact code, so that a rename or a
regression fails the build instead of passing silently.

Acceptance criteria
- Given the selftest, when it triggers each refusal class, then it asserts the specific code, not
  `IsError` alone.
- Given the in-process round-trip tier, when each domain gate is exercised, then each refuses once with
  its exact §9 code asserted.

INVEST — independent; testable by the upgraded selftest + the in-process tier; encodes MCP3-INV4.
Priority: must · Size: 3 · Implements deliverables: MCP3-D5.

## MCP3-US5 — protocol errors stay where they belong
As a maintainer, I want malformed-request and unknown-tool failures to keep the SDK's handling, so that
the domain vocabulary stays scoped to domain refusals and does not absorb transport concerns.

Acceptance criteria
- Given a malformed JSON-RPC request or an unknown tool name, when it fails, then the failure is the
  SDK's protocol error, not an `aaw:` domain code.
- Given a domain refusal, when it returns, then it is an `aaw: <CODE>: <detail>` tool result — the two
  planes never blur.

INVEST — independent; testable by an unknown-tool round-trip plus a domain-refusal contrast; encodes
MCP3-INV5.
Priority: should · Size: 2 · Implements deliverables: MCP3-D5.

## MCP3-US6 — a hand-written heading is tolerated, reported, and never gates
As a maintainer hand-writing a `### ADR-3` heading into a scope ledger, I want the grammar to accept it
as a first-class entry, report its prefix in parse-health, and gate nothing on it, so that hand-written
history stays first-class and the formal grammar describes the file I actually have.

Acceptance criteria
- Given a scope ledger holding a hand-written `### ADR-3` heading, when any ledger writer appends and
  `aaw_status` runs, then the append succeeds, parse-health reports `ADR` among the unknown prefixes
  (separate from the closed-prefix tallies), and no gate refuses.
- Given a ledger holding lenient forms (a `#`-level section heading, a `##`-level entry heading), when
  a tool appends to it, then every prior entry's bytes survive verbatim, the new entry is emitted in
  the strict canonical form (`##` section, `###` entry), and per-prefix numbering continues across
  hand-written and tool-written entries.

INVEST — independent of the refusal sweep; testable by the lenient-in/strict-out golden over the
committed exemplars plus an unknown-prefix status assertion; encodes MCP3-INV6, MCP3-INV7.
Priority: must · Size: 3 · Implements deliverables: MCP3-D6, MCP3-D7.

## MCP3-US7 — out-of-root paths refuse at the door; legacy scopes keep working
As an Operator running the server over a workspace, I want a new scope's paths contained under the
workspace root while pre-existing out-of-tree scopes keep working with an advisory trail, so that the
corpus stays inside the tree without a retroactive break.

Acceptance criteria
- Given a first `aaw_init` whose `ledger_dir` (or an `aaw_spawn` whose `deliverable`) resolves outside
  the workspace root, when the call runs, then it refuses with `aaw: PATH_ESCAPE: <detail>` and no row
  or file is created.
- Given an index row whose `ledger_dir` already sits outside the workspace root (a legacy scope), when
  a writing tool targets it, then the call proceeds and one deduplicated `CONTAINMENT` advisory line
  lands in `.claude/audit.log` — reported, never refused.
- Given the upgraded selftest against a live server, when it runs, then its ledger dir derives from
  `probe.workspace` and the old out-of-root temp dir is the `PATH_ESCAPE` exact-code assertion.

INVEST — independent of the sweep; testable by the door refusal, the legacy-row advisory, and the
selftest assertion; encodes MCP3-INV8.
Priority: must · Size: 3 · Implements deliverables: MCP3-D8.

---
Coverage: D1→US1 · D2→US1,US2 · D3→US3 · D4→US2 · D5→US4,US5 · D6→US6 · D7→US6 · D8→US7.  Spec: mcp3.md · Agent brief: mcp3.llms.md.
