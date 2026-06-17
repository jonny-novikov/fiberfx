---
name: aaw-mcp-server-ladder
description: "apps/aaw MCP server build ladder (docs/aaw/mcp): MCP1 single-writer store SHIPPED 7972859f; tiered-formation calibration (settled/standard/full); mcp2 next = standard tier; live server runs pre-rung binary until Operator restart"
metadata: 
  node_type: memory
  type: project
  originSessionId: b2ed0d69-4a2e-47c2-baa5-399a3ea29bd6
---

**The aaw MCP server build ladder** lives at `docs/aaw/mcp/` (design corpus in `design/`, rung specs in
`specs/`, ledger `aaw-mcp.progress.md`, scope `aaw-mcp` on the server). The server itself = `apps/aaw`
(Go, vendored SDK `apps/mcp-go` — first-party, modifiable only at the transport rung).

- **MCP1 SHIPPED 2026-06-11, commit `7972859f`** (settled-tier close): per-scope serialization domain
  (`saveRegistry` unexported), persisted `next_ccl` mint + re-spawn identity continuity + legacy seed
  (max-suffix+1, test-pinned against the live duplicate ccl-aaw-mcp-6), `writeFileAtomic`
  (tmp+fsync+rename) for index/registry/ledger, pure read-through index (out-of-band edits honored),
  flock instance guard (`INSTANCE_LOCKED`, holder in probe). 17-tool surface unchanged. 14 race-clean
  tests + parse-compat goldens over the two live ledgers.
- **The live server runs the PRE-rung binary until restarted** — restarting severs the running session's
  MCP connection, so timing is the Operator's; files lose nothing.
- **The tiered-formation calibration (aaw-mcp ledger D-10, Operator-ordered):** ceremony scales with rung
  size — *Settled* (settled design, no open fork, one-package diff → one implementor pass + Director gate
  re-run + pathspec commit; NO separate harden/verify spawns) · *Standard* (new package/tool/contract →
  build + ONE second context, harden OR verify) · *Full* (open fork / auth-data-deploy / system spec →
  full pipeline or Design Phase). Rule lives in `aaw.mcp.roadmap.md` "How the roadmap runs"; offered (not
  yet applied) to hoist into x.md/x-mode globally.
- **Next rung: MCP2** (standard tier, pinned in `mcp2.specs.md`): actor attribution, `agent_heartbeat`
  (+1 tool → 18), three-source liveness fusion, `aaw_status` gate console, advisory FAKE-N/V-SOLO-1
  signals to `.claude/audit.log`. `mcp2.llms.md` exists; no runbook (two-file shape).
- Residuals routed: ScopeNames swallows index errors (error-vocab rung); stale-tmp sweep (config rung);
  dir-fsync power-loss promotion (Operator call); CLI flags-after-mode silently no-op — flags-first
  invocation mandatory (`aaw -addr … -workspace … serve`).

Related: [[echo-flame-agile-specs-initiative]] (the AAW framework).