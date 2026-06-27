# figma-local — operator & developer guide

> The figma-local MCP lets an agent on the **Mac** read — and (figl.6) export from — a **live Figma
> Desktop session** running on a **Windows** machine: no Figma API key, no rate limits, real-time
> access to whatever is open. This directory is the comprehensive guide to **installing, changing,
> and deploying** it.
>
> - **Using** the tools from an agent → [`../figma-local.md`](../figma-local.md) (pre-flight + the 12 tools + budget rules).
> - **Designing** the surface (the `figl` program — ADRs, rungs, seams) → [`docs/figma-local/`](../../../docs/figma-local/).
> - **This set** is the *how-to-run-it*: [setup](setup.md) · [update](update.md) · [deploy](deploy.md).

## The doc map

| Doc | Read it when |
|---|---|
| [setup.md](setup.md) | **First-time install** — the bridge + plugin on Windows, the MCP client on the Mac, the firewall. |
| [update.md](update.md) | **Changing or adding a tool** — the dev loop, the `code.ts`→`code.js` source-of-truth rule, Mac-side testing. |
| [deploy.md](deploy.md) | **Shipping a change** — the two-part deploy, the capability handshake, the smoke-test, rollback. |
| [../figma-local.md](../figma-local.md) | **Using** the tools — pre-flight, the 12 tools, the token-budget rules, the `@codemoji/design` toolkit. |
| [../../CLAUDE.md](../../CLAUDE.md) | Agent navigation for the whole `mcp/` tree (deploy discipline, drift hazard, 3-site registration). |
| [../../../docs/figma-local/](../../../docs/figma-local/) | The **design canon**: `figl.design.md` (ADRs), `figl.roadmap.md` (rungs/seams), `figl.prompt.md` (the Windows build ladder). |
| [../../figma-mcp/docs/MAC-CLIENT.md](../../figma-mcp/docs/MAC-CLIENT.md) | The original Mac-client deep-dive — firewall PowerShell, the `scp` fallback, security notes. |

## Architecture in one mental model

Three processes, two machines, one live document:

```
[Mac]                              [Windows — 192.168.3.120]
mcp.js  ──HTTP POST /request──▶  bridge-server.js  ──WS :3000──▶  ui.html  ──postMessage──▶  code.js
(stdio MCP server,                (:3001 HTTP / :3000 WS,           (plugin iframe,            (plugin main thread,
 12 tools, this repo) ◀─{result}─  pure relay, 30 s timeout,         holds the socket)          the figma.* API)
                                   NO AUTH — firewall is the gate)
```

- The Mac speaks **only** to the bridge's HTTP `:3001`. Each call is `POST /request {action, params}`,
  correlated by a monotonic `requestId`; the bridge times out at **30 s** (`bridge-server.js:153`).
- The plugin **main thread cannot open sockets** — `ui.html` holds the WebSocket and shuttles frames
  via `postMessage`. The bridge is a **pure relay**: it never switches on action names; it forwards
  `{action, params}` verbatim and caches just two things — the last `document-update` and the plugin's
  `backed-actions` list (`bridge-server.js:24,29`).
- One plugin connection at a time (last-wins); on disconnect the bridge drops the document + the
  backed-actions, so `check-bridge-status` reports `connected:false`.

## The 12 tools (as-built, figl.1–6)

**Plugin-backed (9)** — forwarded to Figma over the bridge (`ADVERTISED_ACTIONS`, `mcp.js:20`):
`get-current-page` · `get-selection` · `get-all-pages` · `find-nodes` ·
`get-node-properties(nodeId?, depth?, maxNodes?)` · `export-node(…, scale?)` · `get-batch-nodes` ·
`resolve-variables` · **`export-figure`** *(figl.6 — built; live after the next Windows deploy)*

**Mac-side (3)** — served by `mcp.js` directly, no plugin round-trip:
`get-figma-document` (cached `/document`) · `check-bridge-status` (`/health` + the handshake) ·
`cleanup-renders` (prunes the bounded render dir)

Full reference, return shapes, and budget rules: [../figma-local.md](../figma-local.md).

## The golden rules (violate these and the plugin silently lies)

1. **The plugin deploys on Windows, never the Mac.** The Mac edits `code.ts`/`mcp.js`/`figure.js`; it
   **cannot** rebuild or reload the Figma plugin. → [deploy.md](deploy.md).
2. **`code.ts` is the source of truth; `code.js` is the compiled artifact.** `tsc` builds one from the
   other. Never hand-edit `code.js` — a rebuild reverts it. → [update.md](update.md).
3. **Read-only against the live design.** No tool mutates the Figma document.
4. **No CI on the deploy box.** The capability **handshake** (`advertised ⊆ backed`) is the standing
   regression test — verify it after every deploy. **NO-INVENT** every `figma.*` call (cite
   `@figma/plugin-typings`).
5. **Selection-first, paths-not-bytes.** Heavy payloads route to disk (`{path,…}`), never into the
   tool result (a raw full-screen export ≈ ~1M context tokens).

## Prerequisites at a glance

- **Windows host:** Figma Desktop · Node 18+ · `pnpm` · the repo checkout · an inbound firewall rule
  for TCP **3001** scoped to the LAN.
- **Mac:** Node 18+ · `pnpm` · the Claude Code CLI · the repo (the MCP needs `mcp.js` **and**
  `figure.js` + `node_modules`) · the same LAN as the Windows host.

Start at [setup.md](setup.md).
