# MCP4 · user stories

> Who wants this, what they need, and how we will know it works — the acceptance face of the
> config, ports & wire-contract rung (mcp4.md). Stories are split by audience: `US-D[N]` the
> developer (the human who boots, configures, and audits the server), `US-A[N]` the agent (the
> session peers who dial the tools).

## MCP4-US-D1 — policy I can tune in a committed file
As the developer, I want the liveness window, the director threshold, the quiet cap, and the dedup
window in a tree-visible `.aaw/config.json` I edit without a restart, with no environment layer, so
that policy is files-truth and reviewable in git.

Acceptance criteria
- Given a `.aaw/config.json` edit to W, K, or the cap, when the next evaluation runs, then the new
  value takes effect with no restart and `probe.effective_config` reports it with `file` as the source.
- Given an environment variable named like a policy knob, when the server runs, then it has no effect —
  no env layer exists — and the converted `.gitignore` (`.aaw/*` + `!.aaw/config.json`) keeps the
  policy file committable.

INVEST — independent; testable by a config read-through test + a no-env assertion; encodes MCP4-INV2.
Priority: must · Size: 5 · Implements deliverables: MCP4-D1.

## MCP4-US-D2 — two servers never split a port
As the developer running more than one workspace, I want a busy port to refuse with a diagnosis rather
than half-bind, so that two instances never each hold one loopback family behind one URL.

Acceptance criteria
- Given a port already held, when the server boots on `localhost`, then it binds both families or exits
  with `PORT_BUSY`, never one family only.
- Given the refusal, when the holder answers as an aaw instance, then the message names its workspace
  and version; when foreign, it gives `lsof` guidance — and the holder probe is capped (~500 ms) and
  runs on the refusal path only.

INVEST — independent; testable by a two-instance bind test; encodes MCP4-INV1.
Priority: must · Size: 3 · Implements deliverables: MCP4-D2.

## MCP4-US-D3 — the wire contract is checked, never written
As the developer, I want the server to validate `.mcp.json` against its bound address and refuse a
mismatch by default, but never edit my config, so that a stale contract is caught at boot and my file
stays mine.

Acceptance criteria
- Given `-wire-check strict` (the default) and a `.mcp.json` that disagrees with the bound address,
  when the server boots, then it refuses with `WIRE_MISMATCH` and prints the fix in both directions.
- Given any wire-check state, when the server runs, then it never generates or edits `.mcp.json` — a
  byte-comparison shows the file untouched across every state.

INVEST — independent; testable by the wire-verdict matrix + a `.mcp.json` byte-comparison; encodes
MCP4-INV3.
Priority: must · Size: 3 · Implements deliverables: MCP4-D3.

## MCP4-US-A1 — the wire verdict in the calls already made
As an agent dialing the server, I want `probe` and `aaw_status` to carry the computed `wire_contract`
verdict, so that a stale wire contract is visible in-band before it costs a failed dial.

Acceptance criteria
- Given any wire-check state, when `probe` or `aaw_status` returns, then it reports the computed
  verdict `agree|mismatch|absent|unparseable|skipped` — the field the MCP2 console omitted, now
  present and never defaulted.
- Given `-wire-check warn` and a disagreeing `.mcp.json`, when the server runs, then the reported
  verdict is `mismatch` — the only mode that can carry it (`strict` refuses boot first).

INVEST — independent of the boot-refusal path; testable by the wire-verdict matrix read through the
two tools; encodes MCP4-INV3.
Priority: must · Size: 2 · Implements deliverables: MCP4-D3.

## MCP4-US-D4 — the model on the record
As the developer auditing a formation, I want each agent's model recorded on its row and shown in
status, so that LAW-2 evidence is on the record without changing any behavior.

Acceptance criteria
- Given `aaw_spawn`/`agent_register` with a `model`, when the row is read, then `model` is recorded and
  the `aaw_status` liveness row shows it.
- Given a re-spawn or re-register without `model`, when the row is read, then the stored value is kept;
  no behavior branches on `model` and a client holding MCP3 shapes stays valid.

INVEST — independent; testable by a model additive/continuity test over the as-built field; encodes
MCP4-INV4.
Priority: should · Size: 2 · Implements deliverables: MCP4-D4.

## MCP4-US-D5 — an honest boot in one read
As the developer booting the server, I want the banner to report each listener, the wire verdict, and
the resolved workspace, so that the whole boot surface is verifiable in one read with no greps.

Acceptance criteria
- Given a clean boot, when the banner prints, then it carries one line per listener plus the wire
  verdict and the resolved absolute workspace.
- Given the standing Operator grant, when the rung closes, then the `.claude/commands/x.md:123`
  bootstrap signature carries `ledger_dir`; absent the grant, the edit is held and reported — never
  made without it.

INVEST — independent; testable by a banner assertion plus the grant-held check; encodes MCP4-INV3.
Priority: should · Size: 2 · Implements deliverables: MCP4-D5.

## MCP4-US-A2 — the boot surface in one tool call
As an agent, I want `probe` to carry the boot observability fields, so that the server's identity,
listeners, config sources, and wire verdict are readable in-band with no shell access.

Acceptance criteria
- Given a `probe` call, when it returns, then `started_at`, the listener addresses, the instance id,
  per-scope `reopened_at`, `effective_config` with winning sources, and `wire_contract` arrive in one
  payload.

INVEST — independent; testable by a probe-shape assertion; encodes MCP4-INV2, MCP4-INV3.
Priority: should · Size: 2 · Implements deliverables: MCP4-D5.

---
Coverage: D1→US-D1 · D2→US-D2 · D3→US-D3,US-A1 · D4→US-D4 · D5→US-D5,US-A2.  Spec: mcp4.md · Agent brief: mcp4.llms.md.
