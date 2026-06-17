# MCP1 · user stories

> Who wants this, what they need, and how we will know it works — the acceptance face of the
> single-writer store discipline (mcp1.md).

## MCP1-US1 — concurrent spawns never lose an agent
As a Director running the parallel-ceremony formation, I want two peers spawning at once to both land in
the registry with distinct CCL-ids, so that the registry is trustworthy LAW-1 evidence.

Acceptance criteria
- Given a scope with a registered director, when two `aaw_spawn` calls run concurrently, then both agent
  rows persist and their CCL-ids differ.
- Given the same race repeated under a property generator, when N spawns run in parallel, then the registry
  holds N rows and N distinct CCL-ids every time.

INVEST — independent of MCP2; testable by a concurrency property over the registry; encodes MCP1-INV1,
MCP1-INV5.
Priority: must · Size: 5 · Implements deliverables: MCP1-D1, MCP1-D2.

## MCP1-US2 — a crash never truncates the audit trail
As a maintainer, I want a process kill mid-write to leave every server file whole, so that the ledger is a
trustworthy history and never a torn record.

Acceptance criteria
- Given a write in progress to the ledger, registry, or index, when the process is killed before the
  rename, then a reader observes the complete prior file, not a truncated one.
- Given the write completes, when a reader opens the file, then it observes the complete new file.

INVEST — independent; testable by an atomicity/crash-injection test over each whole-file writer; encodes
MCP1-INV2.
Priority: must · Size: 3 · Implements deliverables: MCP1-D3.

## MCP1-US3 — a hand-edited index stays edited
As the Operator, I want a row I delete from `.aaw/scopes.json` to stay deleted, so that files are truth and
the server never resurrects my edit.

Acceptance criteria
- Given a running server, when a scope row is removed from `.aaw/scopes.json` out of band, then the next
  tool call against that scope reports it not initialized — the row is not resurrected.
- Given an out-of-band edit to a different row, when the next tool call runs, then the edited value is
  honored on that call with no restart.

INVEST — independent; testable by an out-of-band-edit golden against the read-through index; encodes
MCP1-INV3.
Priority: must · Size: 3 · Implements deliverables: MCP1-D4.

## MCP1-US4 — one enforcer per workspace
As a maintainer, I want a second server on the same workspace to refuse to boot, so that the in-process
per-scope lock is sufficient and two processes never race the files.

Acceptance criteria
- Given a server holding the workspace flock, when a second server boots against the same workspace, then
  it exits non-zero with `INSTANCE_LOCKED` and the first server keeps serving.
- Given a server is running, when `probe` is called, then it reports the holder instance id and pid.

INVEST — independent; testable by a two-process flock test; encodes MCP1-INV4.
Priority: must · Size: 3 · Implements deliverables: MCP1-D5.

## MCP1-US5 — the existing ledgers still work
As a maintainer, I want the hardened store to parse and continue the live hand-written ledgers, so that the
upgrade is transparent to the running formations.

Acceptance criteria
- Given the committed exemplar ledgers, when the store parses them and appends, then numbering continues
  correctly per prefix and every prior entry's bytes survive verbatim.
- Given the 17-tool selftest, when it runs against a hermetic temp workspace, then every tool and every
  refusal behaves as before this rung.

INVEST — independent; testable by the parse-compat golden + the selftest; encodes MCP1-INV1, MCP1-INV2.
Priority: must · Size: 2 · Implements deliverables: MCP1-D1, MCP1-D3.

---
Coverage: D1→US1,US5 · D2→US1 · D3→US2,US5 · D4→US3 · D5→US4.  Spec: mcp1.md · Agent brief: mcp1.llms.md.
