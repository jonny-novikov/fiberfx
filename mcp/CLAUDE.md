# CLAUDE.md — `mcp/` · the figma-local MCP + the Figma→React export program

> Navigation for Claude agents working anything under `mcp/`. The **figma-local MCP**
> (`figma-mcp/`) is the load-bearing surface; this file is *how to work it without breaking the
> wire or the deploy*. **Operating the server** — install · change a tool · deploy to the Windows
> box — is `mcp/docs/figma-local/` (setup · update · deploy); **using** the tools is
> `mcp/docs/figma-local.md`. The **design canon** (the `figl.*` program) is the **repo-root**
> `docs/figma-local/`; the Figma→React knowledge is `docs/codemojex-tma/kb/figma-livesync/`. Read
> those for *what*; read this for *where and how*. Voice + fork method: `docs/aaw/aaw.architect-approach.md`.

## Scope — the tree

| Path | What it is | Edit? |
|---|---|---|
| `figma-mcp/` | The **figma-local MCP**: a stdio MCP server (Mac) ↔ a no-auth bridge (Windows) ↔ a Figma plugin. The real surface. | Yes — under the deploy discipline below |
| `figma-mcp/mcp.js` | The MCP server (Mac side). Registers tools, forwards to the bridge over HTTP, writes export bytes to a bounded temp dir. | Yes |
| `figma-mcp/figure.js` | **Pure Mac-side projection** (figl.6) — the `export-figure` FigureBundle transforms (RGBA→hex · fills→background · auto-layout→flex · humanized egress). No figma, no I/O; unit-tested. | Yes |
| `figma-mcp/figure.test.mjs` | The projection's regression test (`node figure.test.mjs`) — this surface's only automated test. | Yes |
| `figma-mcp/bridge-server.js` | The bridge. WS `:3000` ↔ plugin, HTTP `:3001` ↔ `mcp.js`. A **dumb relay** keyed by `requestId` — it does NOT switch on action names. | Rarely |
| `figma-mcp/figma-plugin/code.ts` | **The plugin source of truth.** The action `switch` + every handler. `tsc` compiles it → `code.js`. | Yes — but mind the drift hazard |
| `figma-mcp/figma-plugin/code.js` | The **compiled bundle Figma actually runs** (manifest `main`). | Never by hand — regenerate from `code.ts` |
| `figma-mcp/figma-plugin/ui.html` | The plugin iframe; owns the real WebSocket (the plugin main thread cannot open sockets). | Rarely |
| `figma-mcp/figma-plugin/manifest.json` | Plugin manifest (`id: figma-mcp-bridge`, legacy `api:1.0.0`, `allowedDomains:["*"]`). | Rarely |
| `react-figma/` | **Vendored upstream npm `react-figma` v0.31.0 — NOT an in-house project.** It renders **React → Figma** (the *inverse* of export). Not git-tracked, wired into nothing. Mine its `src/styleTransformers/` + `src/mixins/` + `src/types.ts` for the Figma↔CSS-prop mapping vocabulary; never treat it as a Figma→React exporter. | Read-only / harvest |
| `e2e/` | Headless Playwright figure validator (`figures.suite.js`) for static SVG figures (label-overflow / edge-overlap via `getBBox`). | Yes |
| `docs/figma-local.md` | Agent-facing **usage** guide — the 12 tools + budget rules (as-built). | — |
| `docs/figma-local/` | **Operator/dev lifecycle docs** — `index.md` · `setup.md` · `update.md` · `deploy.md`. | Yes |

## The figma-local architecture — one mental model

Three processes, two transports, one live document:

```
[Mac]   mcp.js  ──HTTP :3001──▶  bridge-server.js  ──WS :3000──▶  ui.html  ──postMessage──▶  code.js
       (MCP tools)  POST /request   (Windows, no auth)   request frame   (plugin iframe)      (plugin main, figma.*)
```

- Request/response is correlated by a monotonic `requestId`; the bridge times out at **30s**.
- The plugin **main thread cannot open sockets** — `ui.html` holds the WebSocket and shuttles frames via `postMessage` (reconnects every 3s on close).
- `FIGMA_BRIDGE_URL` (default `http://192.168.3.120:3001`) is set in the MCP registration (`~/.claude.json`, server `figma-local`). The Mac reaches the Windows box over the LAN; **no auth** (a standing Operator-accepted risk — figl seam S-1).
- Pre-flight every session: `check-bridge-status` → expect `{status:"ok", connected:true, hasDocument:true}`. `connected:false` = plugin not running; a failed call = bridge down. **Neither is fixable from the Mac.**

## The deploy discipline (load-bearing — get this wrong and the plugin silently lies)

- **The plugin deploys on the WINDOWS Figma machine, NOT the Mac.** The Mac can edit `code.ts` / `mcp.js` and reconnect, but it **cannot rebuild or reload the plugin**.
- Build = `pnpm build-plugin` (≡ `cd figma-plugin && tsc` → regenerates `code.js` from `code.ts`).
- Reload = a **human** in Figma Desktop: *Plugins → Development → Figma MCP Bridge* (re-run loads the new `code.js`), then confirm "Connected to bridge". An agent cannot click this.
- **Reverting source is not enough** — the deployed artifact is `code.js`; you must rebuild **and** reload for any change (or revert) to take effect.
- **⚠ THE DRIFT HAZARD:** `code.js` is generated but **committed**, so it can be hand-edited and silently diverge from `code.ts` — and the next `pnpm build-plugin` then **reverts the hand-edit with no error**. This bit once (scale was hand-edited into `code.js` while `code.ts` stayed 1×); **figl.6 / Phase 0 closed that instance** by porting scale into `code.ts`. The **rule stands**: **`code.ts` is the source of truth — port any `code.js` change back into `code.ts` before anyone rebuilds.** Check with `grep -n exportAsync figma-plugin/code.*` (must agree). *(Note: `figma-mcp/.gitignore` lists `figma-plugin/*.js`, yet `code.js` is tracked — flipping it to a pure build artifact is an Operator call, not a silent one.)*

## Adding or changing a tool — the 3-site registration (all move together)

A plugin action lives in three lists that must stay in lockstep (a comment in `code.ts` says exactly this):

1. the `switch (action)` case + its handler in `code.ts` (→ rebuild → `code.js`);
2. `BACKED_ACTIONS` in `code.ts` / `code.js` (the plugin's self-reported capability list, sent on connect);
3. `ADVERTISED_ACTIONS` + a `server.registerTool(...)` in `mcp.js` (the MCP-facing tool).

The **capability handshake** reconciles (2) vs (3): the plugin sends `backed-actions`; `check-bridge-status` diffs `ADVERTISED_ACTIONS` against the live `backedActions` → `ok` / `warn` (a mismatch is a WARN, never a hard fail). Until the Windows human reloads, a newly-added action is **"Unknown action"** on the live plugin even though `mcp.js` already advertises it. Template to copy: `get-batch-nodes` / `resolve-variables` (the figl.3 / figl.5 additions).

## Export (the surface this program extends)

`export-node` (`mcp.js` + `code.js exportNode`): a node as **PNG / SVG / JPG** (+ `scale` for Retina @2x). The plugin returns **base64**; `mcp.js` decodes → **writes a file** under `FIGMA_MCP_RENDER_ROOT` and returns `{path, nodeId, format, scale, w, h, byteLen}` — a path, never bytes in context (figl.2 / ADR-1). `cleanup-renders` reclaims the dir.

**`export-figure`** (figl.6 — Mac-side built; **live after the next Windows deploy**): the structural/React-suitable export. Returns a thin **FigureBundle** IR (geometry + CSS-style props + token references `{token,value}` + text) plus humanized, reusable on-disk assets — a vector subtree → one `.svg`, an image leaf → `.png` — under `FIGMA_MCP_ASSET_ROOT` (default `RENDER_ROOT/assets`, **not** swept by `cleanup-renders`). The plugin (`code.ts exportFigure`) does only the figma.* gather; the pure projection is `figure.js` (Mac-unit-tested). Build brief: `docs/codemojex-tma/kb/figma-livesync/export.build.md`; rung + ADR-9/10: repo-root `docs/figma-local/`.

## Budget rules (Figma is a token minefield)

- Never `export-node` a sizeable node for its bytes — route to disk (the `{path,...}` contract already does; a raw full-screen int-array was ~1M tokens).
- `get-node-properties` is one level only; don't naive-recurse N nodes — use `get-batch-nodes` or the bounded `depth` subtree.
- Selection-first; avoid whole-page dumps (`get-current-page`, `get-figma-document`).
- Prefer the Mac-side CLI `node/codemoji-design` (`doctor` / `extract <id>`) — it routes bytes to disk and emits `manifest.json` + `spec.md` + `tokens.md` + `reference/*.png`.

## Verification posture (no test harness — every tool is a multi-year liability)

The public tool surface is frozen onto a hand-deployed box with **no CI**. So: **NO-INVENT** — verify every `figma.*` call against `@figma/plugin-typings` at a cited line; thin-but-robust; price each new tool as a long-term liability; **surface forks, never decide them** (`docs/aaw/aaw.architect-approach.md`). The `figl.*` program (repo-root `docs/figma-local/figl.{design,roadmap,prompt}.md`) is the design canon: **figl.1–figl.6 are BUILT** (figl.6 = `export-figure` + the scale floor, Mac-side built; live after the next Windows deploy). The **only automated test** on this surface is `figma-mcp/figure.test.mjs` (the figl.6 projection); everything else is verified by the **handshake** (`advertised ⊆ backed`) + a manual smoke-test against `94:2974`. Deferred seams (S-2 component identity, S-7 Figma write-back, S-8 llms.txt depth) stay in `figl.roadmap.md`.

## Map — read these for context

- **Run-it docs (this tree):** `mcp/docs/figma-local/` — `index.md` (hub) · `setup.md` · `update.md` · `deploy.md`; plus `mcp/docs/figma-local.md` (tool usage + budget).
- **Design canon (repo root):** `docs/figma-local/figl.design.md` (ADRs 1–12 + the surfaced forks), `figl.roadmap.md` (rungs figl.1–8 + seams S-1..S-8), `figl.prompt.md` (the Windows build/deploy runbook).
- **Consolidated Figma→React knowledge + the export fork (RULED Bundle):** `docs/codemojex-tma/kb/figma-livesync/` (`index.md` · `export.design.md` · `export.build.md`).
- **The consumer:** `node/codemoji-app/` (Vite 7 · React 19 · Tailwind v4 TMA; Feature-Sliced Design; the **Figure→slice map** + token bridge live in its `CLAUDE.md` / `src/styles.css`). **The extractor:** `node/codemoji-design/` (the `extract` CLI + its `manifest.json`/`spec.md`/`tokens.md` output shape).
- **The fork method:** `docs/aaw/aaw.architect-approach.md` (four-part arms · multi-architect debate · the Operator rules).
