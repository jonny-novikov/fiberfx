# figma-local — setup (first-time install)

> Install the bridge + plugin on the **Windows** Figma machine and the MCP client on the **Mac**.
> Architecture + the doc map: [index.md](index.md). The original Mac-only deep-dive (firewall
> PowerShell, `scp` fallback, security) is [`MAC-CLIENT.md`](../../figma-mcp/docs/MAC-CLIENT.md) —
> this page is the end-to-end version covering both machines.

The two halves are independent installs that meet over the LAN:

| Machine | Runs | Install §|
|---|---|---|
| **Windows** (`192.168.1.120`) | `bridge-server.js` + the Figma plugin (`code.js` / `ui.html`) | [§A](#a-windows-the-bridge--the-plugin) |
| **Mac** (this repo) | `mcp.js` (the stdio MCP) + `figure.js` | [§B](#b-mac-the-mcp-client) |

> **Windows checkout path.** This guide uses `C:\dev\jonnify\mcp\figma-mcp` (the canon
> `figl.prompt.md`). Some older notes say `C:\dev\figma-mcp`; **confirm the real path with the
> Operator** and substitute it below. The Mac checkout is this repo: `/Users/jonny/dev/jonnify/mcp/figma-mcp`.

## Prerequisites

- **Both:** Node 18+ and `pnpm`; both machines on the same LAN (`192.168.3.0/24`).
- **Windows:** Figma **Desktop** (the plugin needs the desktop app, not the browser).
- **Mac:** the Claude Code CLI (`claude`).

---

## A. Windows — the bridge + the plugin

All commands run in the Windows checkout (`C:\dev\jonnify\mcp\figma-mcp`).

### 1. Install + build

```bash
pnpm install
pnpm build-plugin        # ≡ cd figma-plugin && tsc  → regenerates code.js from code.ts
```

`build-plugin` compiles `figma-plugin/code.ts` → `figma-plugin/code.js` (the manifest's `main`).
The plugin **runs `code.js`**, so this step is mandatory before the first load and after every
`code.ts` change.

### 2. Import the plugin into Figma Desktop

1. Open Figma Desktop.
2. **Plugins → Development → Import plugin from manifest…**
3. Select `figma-plugin/manifest.json` (id `figma-mcp-bridge`, name **Figma MCP Bridge**).
4. The plugin now appears under **Plugins → Development**.

### 3. Start the bridge

```bash
pnpm bridge              # ≡ node bridge-server.js
```

This starts the WebSocket server on `ws://localhost:3000` (the plugin dials in here) and the HTTP
API on `http://localhost:3001` (the Mac calls here). Leave it running.

### 4. Run the plugin

Open any Figma file → **Plugins → Development → Figma MCP Bridge**. The plugin's small UI window
should show **"Connected to bridge"**. (`ui.html` holds the socket and reconnects every 3 s, so it
will re-attach if you restart the bridge.)

### 5. Open the firewall for the Mac (one-time)

The Mac reaches `:3001` over the LAN. In an **elevated PowerShell**:

```powershell
New-NetFirewallRule `
  -DisplayName 'Figma MCP Bridge (HTTP 3001)' `
  -Direction Inbound -Action Allow `
  -Protocol TCP -LocalPort 3001 `
  -Profile Private `
  -RemoteAddress 192.168.3.0/24
```

> **Security.** The bridge has **no authentication** (a standing accepted risk — `figl` seam S-1).
> The firewall rule is the *only* access control: any host on `192.168.3.0/24` that reaches `:3001`
> can drive Figma. Keep it scoped to the LAN (or tighter — the Mac's IP). **Never** publish `:3001`
> to the internet. Details: [`MAC-CLIENT.md`](../../figma-mcp/docs/MAC-CLIENT.md#security-notes).

WS `:3000` stays **loopback-only** (plugin ↔ bridge on the same box); do not open it.

---

## B. Mac — the MCP client

The Mac needs only the client half — `mcp.js`, **`figure.js`** (imported by `mcp.js` since figl.6),
`package.json`, `pnpm-lock.yaml`, and `node_modules`. The plugin + bridge stay on Windows.

### 1. Get the files

On this Mac the client lives in-repo at `/Users/jonny/dev/jonnify/mcp/figma-mcp` — just install deps:

```bash
cd /Users/jonny/dev/jonnify/mcp/figma-mcp
pnpm install
```

For a **standalone** Mac (no full repo), copy the client set and install:

```bash
mkdir -p ~/figma-mcp
scp <win-user>@192.168.1.120:/c/dev/jonnify/mcp/figma-mcp/{mcp.js,figure.js,package.json,pnpm-lock.yaml} ~/figma-mcp/
cd ~/figma-mcp && pnpm install
```

> ⚠ `mcp.js` does `import { buildFigureBundle } from "./figure.js"` — **`figure.js` must sit next to
> `mcp.js`** or the server won't start. (Older notes that say "only `mcp.js` is needed" predate figl.6.)

### 2. Register the MCP server

```bash
claude mcp add -s user figma-local \
  -e FIGMA_BRIDGE_URL=http://192.168.1.120:3001 \
  -- node /Users/jonny/dev/jonnify/mcp/figma-mcp/mcp.js
```

`FIGMA_BRIDGE_URL` overrides the `mcp.js` default of `http://localhost:3001`. Verify:

```bash
claude mcp list | grep figma
# expect: figma-local: node …/mcp.js - ✓ Connected
```

Open a **new** Claude Code session for the tools to load.

---

## C. End-to-end verification

From the Mac, with the bridge up and the plugin running in Figma:

```bash
curl http://192.168.1.120:3001/health
# expect: {"status":"ok","connected":true,"hasDocument":true,"backedActions":[ … ]}
```

Then from a Claude session, the canonical pre-flight:

- `check-bridge-status` → `{status:"ok", connected:true, hasDocument:true, handshake:{status:"ok"}}`
  and a `backedActions` array. `connected:false` ⇒ the plugin isn't running; a failed call ⇒ the
  bridge is down. **Neither is fixable from the Mac.**
- `get-selection` (select something in Figma first) → returns the selected node(s).

If the handshake reports `warn`, the Mac advertises a tool the deployed plugin doesn't back yet —
the plugin needs a rebuild + reload (see [deploy.md](deploy.md)).

## Environment variables

| Var | Default | Set on | Purpose |
|---|---|---|---|
| `FIGMA_BRIDGE_URL` | `http://localhost:3001` | Mac (MCP registration) | Where `mcp.js` finds the bridge — the Windows LAN IP. |
| `FIGMA_MCP_RENDER_ROOT` | `os.tmpdir()/figma-mcp-renders` | Mac | Bounded dir for `export-node` renders (`cleanup-renders` prunes it). |
| `FIGMA_MCP_ASSET_ROOT` | `<RENDER_ROOT>/assets` | Mac | Stable, humanized `export-figure` assets (figl.6) — **not** swept by `cleanup-renders`. |

Next: [update.md](update.md) to change the surface, or [deploy.md](deploy.md) to ship one.
