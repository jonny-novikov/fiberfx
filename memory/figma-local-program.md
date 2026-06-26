---
name: figma-local-program
description: "figma-local MCP enhancement program — design ruled (docs/figma-local), deploys on the Windows Figma machine NOT the Mac; toolkit node/codemoji-design"
metadata: 
  node_type: memory
  type: project
  originSessionId: 466fdd7e-18b5-4685-aa04-c820181e763a
---

**figma-local** = the local-Figma MCP (read a live Figma desktop session, no API key) and its enhancement program. Three components across two machines: `mcp.js` (stdio MCP, runs on the **Mac**, this repo at `mcp/figma-mcp/`), `bridge-server.js` + `figma-plugin/` (run on the **Windows Figma machine** `192.168.3.120`, checkout `C:\dev\figma-mcp`). The bridge is a **no-auth** LAN relay (firewall is the only control). `mcp/` is git-ignored in jonnify; `figma-mcp` builds the plugin via `tsc`→`code.js` (`pnpm build-plugin`), bridge via `pnpm bridge`.

**Design RULED 2026-06-25; figl.1–5 BUILT + committed; Mac side (mcp.js) DEPLOYED + verified live (export-node egress, depth param, cleanup-renders); Windows PLUGIN RELOAD PENDING — resolve-variables + get-batch-nodes return "Unknown action" until the plugin is rebuilt (pnpm build-plugin) + reloaded in Figma (Operator-gated).** A two-architect debate (Venus-A capability vs Venus-B steward, per [[../aaw…]] aaw.architect-approach) over 6 forks, grounded in a REAL extraction of the CODEMOJIES screen (`94:2974`, 77 nodes). Docs in `docs/figma-local/`: `figma-local.md` (index) · `figl.design.md` (forks staged + 8 ADRs with CHOSEN-AGAINST) · `figl.roadmap.md` (ladder + Seams + RULED ledger) · `figl.prompt.md` (enhance+deploy runbook for the WINDOWS box).

**The 5-rung ladder (figl.1–5):** (1) drop the dead `get-batch-nodes`/`export-batch-nodes` tools — Mac-only, no deploy; (2) base64 image egress `{path,w,h,byteLen}` (kills the ~1M-token int-array) + advertised==live capability handshake; (3) targeted node enrichment (cornerRadius/auto-layout/bbox, `figma.mixed`-guarded) + real `get-batch-nodes`; (4) bounded `depth` param on `get-node-properties`; (5) `resolve-variables` (the ONE capability the Mac client can't supply — `resolveForConsumer` needs a node) + async `getNodeByIdAsync` hardening.

**Load-bearing facts:** deploy ALWAYS on the Windows machine, never the Mac (Mac can't reload a Figma plugin); no CI on the box → the handshake IS the regression test; plugin runs LEGACY mode (no `documentAccess` key) so sync `getNodeById` works today (async swap is latent hardening); B2 (bridge file-write) hard-vetoed while no-auth stands; get-component-instances DEFERRED (seam S-2 — toolkit already dedups). The toolkit `node/codemoji-design/` (`@codemoji/design`, untracked) is BOTH the Mac extraction CLI and the reference implementation of every proposed tool (`figma/<screen>/manifest.json → gaps` tags each fork). Deploy is Operator-gated → see [[operator-runs-deploys]]. Consumers/scope: figma-local usage is for `echo/apps/codemojex` or `node/codemoji-app` ONLY → [[codemojex-program]].

Owed: the Windows figma-local PLUGIN RELOAD (rebuild `pnpm build-plugin` + reload in Figma) to make `resolve-variables`/`get-batch-nodes` live — Operator-gated [[operator-runs-deploys]]. DONE: mcp/docs usage guide; 3 CLAUDE.md pointers; CODEMOJIES spec into @codemoji/design; post-deploy verification. The toolkit `node/codemoji-design` is now also a Storybook design system → [[codemoji-design-system]].
