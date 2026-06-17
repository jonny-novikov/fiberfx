---
name: aaw-mcp-design-phase
description: aaw MCP server v2 Design Phase COMPLETE 2026-06-11 — design+roadmap pair awaiting Operator approval; formation locks D-7/D-8; build entry = MCP-1
metadata: 
  node_type: memory
  type: project
  originSessionId: fd8e59f9-959f-4161-9b2a-e7c224c8c48b
---

**aaw MCP server v2 — Design Phase (scope `aaw-mcp`) COMPLETE 2026-06-11, awaiting Operator approval.** Supersedes the "next = Design Phase" tail of [[echo-flame-agile-specs-initiative]].

- **Deliverables (gate-verified, NOT yet canon):** `docs/aaw/mcp/aaw.mcp.design.md` (675 ln: master invariant, AD-1…AD-12, 22-tool catalog, EBNF ledger grammar, closed 16-code error vocabulary, `aaw audit` CLI, four-tier conformance, D-5 SDK policy, donor-pointer decision record) + `aaw.mcp.roadmap.md` (296 ln: thin-rung ladder MCP-1…MCP-8, milestones M1–M4) + `design/x-mode.design.md` (protocol record, parallel Director thread). Evidence base: venus-1 (33 ADRs) · venus-2 (25 ADRs) · 2 cross-reviews · apollo.evaluation.md (DESIGN-GRADE) · ledger `aaw-mcp.progress.md` D-1…D-9 / L-1…L-3 / Z-1 / Y-1.
- **Settled synthesis:** base=venus-1 + 14 venus-2 grafts (apollo §7.1); picks: `agent_heartbeat`, `channel_poll`, no-env/no-per-knob config (identity=flags, policy=`.aaw/config.json`, W-3 = `.aaw/*` + `!.aaw/config.json` glob pair — bare negation under directory-form ignore is a git no-op), tokenless v2 (D-4), stateless + C-1 harness-dial probe at MCP-4 (failure flips stateful), W-1 V-SOLO-2 evidence-only, retry-dups accepted, policy W=45/K=3/cap=240. 22 tools = 17 v1 names + heartbeat/resonance/channel_publish/poll/list. tool_memory_* omitted everywhere (D-3).
- **Formation locks:** **D-7 = Apollo REMOVED from Design Phases** (Venus-1↔Venus-2 cross-review IS the evaluation; Apollo's home = Flat-L2 inter-Mars rung evaluation; applies to the paused emq-design too — after the venus-2 review re-drive, straight to synthesis). **D-8 = synthesis authored by the REAL `venus` agent type** (a general-purpose agent wearing the venus charter ≈ V-SOLO-4; the operator rejected that spawn live). Protocol-doc edits (x.md §12, SKILL §2b, F-2 x.md:123 ledger_dir, apollo.md narrowing) are Operator-fenced — itemized in x-mode.design.md, land only under grant.
- **Live learnings:** L-3 = the PoC's `len(r.Agents)+1` CCL re-mint fired on the phase's own ceremony (two parallel Director sessions re-minted Venus-3 ccl-5→ccl-6; one Director session per scope until MCP-2). Hot-ledger discipline: the operator + parallel threads append live — re-read before every write; numbering is collision-safe by construction.
- **Why:** the design gates the build — no production code before Operator approval; the picks/locks above are re-litigation-proof.
- **How to apply:** on approval, build starts at **MCP-1** (committed goldens + parse-compat over the two hand-written exemplar ledgers, zero production lines), lead-team per the roadmap; diff boundary extends to `apps/mcp-go` only where a rung names it (D-5).
