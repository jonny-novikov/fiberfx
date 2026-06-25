# figma-local MCP — usage guide

> **Scope rule (read first).** Use the `mcp__figma-local__*` tools **only** when working
> `echo/apps/codemojex` (the Phoenix game) or `node/codemoji-app` (the React frontend) — to read
> the Codemoji design from Figma. Do **not** use them for any other jonnify work.
>
> **What it is.** A local stdio MCP → an unauthenticated LAN bridge on the Windows Figma machine
> (`FIGMA_BRIDGE_URL`, default `http://192.168.3.120:3001`) → the live Figma desktop session. No
> API key; it reads whatever is open in Figma. Topology, firewall, and Mac setup:
> `mcp/figma-mcp/docs/MAC-CLIENT.md`. The enhancement design + roadmap: `docs/figma-local/`.

## Pre-flight (always, before any other call)

Call `check-bridge-status` first → expect `{"status":"ok","connected":true,"hasDocument":true}`.
If `connected` is false, the Figma plugin is not running; if the call fails, the bridge is down —
neither is fixable from the Mac (see `MAC-CLIENT.md`).

## The tools (10 registered; 2 are dead)

| group | tools |
|---|---|
| discovery | `get-selection` · `find-nodes` · `get-current-page` · `get-all-pages` · `get-figma-document` |
| detail | `get-node-properties` |
| export | `export-node` |
| health | `check-bridge-status` |
| **dead — do not call** | `get-batch-nodes` · `export-batch-nodes` (advertised but throw `"Unknown action"`; fixed by the `figl` ladder) |

Node ids accept either `94:2974` or `94-2974` (normalized server-side).

## Token-budget rules (load-bearing — violating these blows the context window)

1. **Never call `export-node` raw for anything sizeable.** It returns a decimal **int-array**
   (`{data:[…]}`) ≈ ~1M tokens for a full screen. Use the **toolkit** (below), which routes image
   bytes bridge→disk so they never enter context. (The `figl.2` rung will replace this with a
   `{path,w,h,byteLen}` contract.)
2. **`get-node-properties` returns one level only** and omits cornerRadius, auto-layout
   (padding/itemSpacing/layoutMode), and resolved variable values. Do **not** naive-recurse it
   (that is N calls for N nodes) — use the toolkit's bounded walk, and read radius/spacing from the
   reference PNGs until `figl.3`/`figl.4` land.
3. **Avoid whole-page dumps** (`get-current-page`, `get-figma-document`) — they are large. Prefer
   **selection-first**: `get-selection` to find the node, then targeted `get-node-properties`.
4. **Variable bindings arrive unresolved** — fills carry raw `VariableID:…` aliases; the baked hex
   is *not* the token. Resolution is plugin-only (`resolve-variables`, the `figl.5` rung); until
   then, map by value and flag the binding.

## The efficient path: the `@codemoji/design` toolkit

For any real extraction, **do not drive the raw tools** — use the Mac-side CLI at
`node/codemoji-design/`. It wraps the live tools, writes renders to disk (never into context), and
emits a reviewable spec:

```bash
node bin/codemoji-design.mjs doctor          # probe the bridge + which actions the plugin backs
node bin/codemoji-design.mjs extract         # extract the current Figma selection
node bin/codemoji-design.mjs extract 94:2974 # …or a specific node id
```

Output per screen → `figma/<screen>/`: `manifest.json` (figures top-to-bottom + a `gaps[]`
backlog), `spec.md` (figure-by-figure), `tokens.md` (Figma colors/type → `codemoji-app`
`src/styles.css` tokens), `reference/*.png` (the source of truth for radius/spacing the JSON
omits). The `CODEMOJIES` game screen is already extracted at `figma/codemojies/`.

## Quick recipe (matching a React slice to Figma)

1. `check-bridge-status` → confirm connected.
2. In Figma, select the screen/frame; `node bin/codemoji-design.mjs extract`.
3. Read `figma/<screen>/spec.md` + open the `reference/*.png` for the figure you are building.
4. Map colors/type via `tokens.md` to `node/codemoji-app/src/styles.css`; build the slice under
   `node/codemoji-app/src/{widgets,pages,entities,shared}`.

## Where this is going

The MCP is being enhanced (base64 image egress, a `depth` subtree param, `resolve-variables`, and
an advertised==live capability handshake), deployed on the Windows machine. Until those rungs
land, the toolkit is the efficient client. Design + ladder: `docs/figma-local/figl.design.md`,
`docs/figma-local/figl.roadmap.md`.
