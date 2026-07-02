# Mac client setup

Connect Claude Code on a Mac to the Figma MCP bridge running on the Windows host.

## Topology

```
Mac (Claude Code)           Windows PC (192.168.1.120)
┌────────────────┐          ┌──────────────────────────┐
│ figma-local    │  HTTP    │ bridge-server.js         │
│   mcp.js       │ ───────► │   :3001 (HTTP API)       │
│ (stdio)        │  3001    │   :3000 (WS, local only) │
└────────────────┘          │        ▲                 │
                            │        │ WS (localhost)  │
                            │ Figma Desktop + plugin   │
                            └──────────────────────────┘
```

The Mac only talks to the bridge's HTTP API on `:3001`. The Figma Desktop plugin connects to the bridge over loopback `:3000`; the Mac never touches it.

## Prerequisites

- Windows host:
  - Bridge server running (`pnpm bridge` in `C:\dev\figma-mcp`).
  - Figma Desktop + plugin connected (UI shows "Connected to bridge").
  - Inbound firewall rule for TCP 3001 from the LAN subnet — created in `Configure-Firewall.ps1`.
- Mac:
  - Node.js 18+ and `pnpm`.
  - Claude Code CLI (`claude`) installed.
  - Same LAN as the PC (192.168.3.0/24).

## 1. Verify reachability from the Mac

```bash
curl http://192.168.1.120:3001/health
# expect: {"status":"ok","connected":true,"hasDocument":true}
```

If this fails: check the firewall rule on the PC (see [Firewall](#firewall) below) and that the bridge is up.

## 2. Get the client files on the Mac

Only `mcp.js` + its `node_modules` are needed — the plugin and bridge stay on the PC.

```bash
git clone <your-repo-or-share> ~/figma-mcp
cd ~/figma-mcp
pnpm install
```

If you don't have a git remote, `scp` is enough:

```bash
scp -r <pc-user>@192.168.1.120:/c/dev/figma-mcp/{mcp.js,package.json,pnpm-lock.yaml} ~/figma-mcp/
cd ~/figma-mcp && pnpm install
```

## 3. Register the MCP server in Claude

```bash
claude mcp add -s user figma-local \
  -e FIGMA_BRIDGE_URL=http://192.168.1.120:3001 \
  -- node ~/figma-mcp/mcp.js
```

`FIGMA_BRIDGE_URL` overrides the default `http://localhost:3001` in `mcp.js`.

Verify:

```bash
claude mcp list | grep figma
# expect: figma-local: node ~/figma-mcp/mcp.js - ✓ Connected
```

Open a new Claude Code session and the figma tools (`get-figma-document`, `get-selection`, `find-nodes`, `export-node`, …) become available.

## Firewall

The PC-side rule is `Figma MCP Bridge (HTTP 3001)` — Inbound, TCP/3001, Private profile, RemoteAddress `192.168.3.0/24`.

Recreate on a fresh PC (elevated PowerShell):

```powershell
New-NetFirewallRule `
  -DisplayName 'Figma MCP Bridge (HTTP 3001)' `
  -Direction Inbound -Action Allow `
  -Protocol TCP -LocalPort 3001 `
  -Profile Private `
  -RemoteAddress 192.168.3.0/24
```

Remove:

```powershell
Remove-NetFirewallRule -DisplayName 'Figma MCP Bridge (HTTP 3001)'
```

## Security notes

- The bridge has **no authentication**. The firewall rule is the only access control. Any device on `192.168.3.0/24` that can reach `:3001` can drive Figma through the connected plugin.
- Keep the rule scoped to the LAN subnet (or tighter — e.g., the Mac's specific IP).
- Do **not** publish `:3001` to the public internet.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `curl` from Mac times out | Firewall rule missing or Mac not in `192.168.3.0/24` | Verify rule with `Get-NetFirewallRule -DisplayName 'Figma MCP Bridge*'`; check Mac IP with `ipconfig getifaddr en0` |
| `curl` returns `"connected":false` | Plugin not running in Figma | In Figma: Plugins → Development → Figma MCP Bridge |
| MCP shows `Failed to connect` in `claude mcp list` | Node/path/permissions | Run `node ~/figma-mcp/mcp.js` directly — it should exit cleanly (stdio closes) |
| Tool calls hang | Bridge process died | `curl http://192.168.1.120:3001/health` from PC; restart `pnpm bridge` |
| Wrong `BRIDGE_URL` baked in | Env var not picked up | Re-add the MCP: `claude mcp remove figma-local && claude mcp add -s user figma-local -e FIGMA_BRIDGE_URL=http://192.168.1.120:3001 -- node ~/figma-mcp/mcp.js` |
