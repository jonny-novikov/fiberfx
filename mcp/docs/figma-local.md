# figma-local MCP — usage guide

> **Scope rule (read first).** Use the `mcp__figma-local__*` tools **only** when working
> `echo/apps/codemojex` (the Phoenix game) or `node/codemoji-app` (the React frontend) — to read the
> Codemoji design from Figma. Do **not** use them for any other jonnify work.
>
> **What it is.** A local stdio MCP → an unauthenticated LAN bridge on the Windows Figma machine
> (`FIGMA_BRIDGE_URL`, default `http://192.168.1.120:3001`) → the live Figma desktop session. No API
> key; it reads whatever is open in Figma. **Install / change / ship it:** [`figma-local/`](figma-local/)
> (setup · update · deploy). **Design canon:** the repo-root [`docs/figma-local/`](../../docs/figma-local/).

## Pre-flight (always, before any other call)

`check-bridge-status` → expect `{"status":"ok","connected":true,"hasDocument":true,"handshake":{"status":"ok"}}`.
`connected:false` ⇒ the plugin isn't running; a failed call ⇒ the bridge is down — **neither is
fixable from the Mac** ([troubleshooting](figma-local/deploy.md#troubleshooting)).

## The tools (12 registered)

| group | tools |
|---|---|
| discovery | `get-selection` · `find-nodes` · `get-current-page` · `get-all-pages` · `get-figma-document` |
| detail | `get-node-properties(nodeId?, depth?, maxNodes?)` · `get-batch-nodes(nodeIds[])` · `resolve-variables(nodeId?)` |
| export | `export-node(nodeId?, format?, scale?)` → `{path,…}` · `export-figure(nodeId?, depth?, scale?, maxNodes?, svg?)` → FigureBundle |
| ops | `check-bridge-status` · `cleanup-renders(keepLast?, keepSince?, dryRun?)` |

Node ids accept `94:2974` or `94-2974` (normalized server-side). Omit `nodeId` on the node tools to
fall back to the **current selection** (exactly one node; multi-selection is an error).

## Token-budget rules (load-bearing — violating these blows the context window)

These are about **LLM context tokens** — what a tool *result* costs when it lands in the agent's
context — **not** Figma/API/money cost. The bridge↔Figma link is local and free.

1. **Exports return a disk path, never bytes.** `export-node` writes to `FIGMA_MCP_RENDER_ROOT` and
   returns `{path, w, h, byteLen}`; `export-figure` writes humanized assets to `FIGMA_MCP_ASSET_ROOT`
   and returns `{path,…}` refs. Never re-inline them — a raw full-screen export was ~1M tokens.
2. **`get-node-properties` is one level by default.** Pass `depth` for a bounded subtree in one call;
   `maxNodes` (default 500) caps it (the root then carries `truncated`/`nodeCount`). Don't naive-recurse N nodes.
3. **Avoid whole-page dumps** (`get-current-page`, `get-figma-document`). **Selection-first:**
   `get-selection` to find the node → targeted `get-node-properties` / `export-figure`.
4. **Resolve tokens with `resolve-variables`** (or read them pre-resolved inside an `export-figure`
   bundle as `{token,value}`). A node's baked hex is *not* its token binding.

## `export-figure` — the React-suitable bundle (figl.6)

Returns a thin **FigureBundle**: a structural tree (`layout` incl. auto-layout→flex, CSS-style props
with token references `{token,value}`, text) + humanized **on-disk** assets — a vector subtree → one
`.svg`, an image leaf → `.png` — under `<FIGMA_MCP_ASSET_ROOT>/<screen-slug>/<layer-slug>`. Heavy
bytes are never in the result. `svg:'inline'` keeps small vector markup inline instead of a file.
It's the structured path for rendering a Figma screen into React (`node/codemoji-app`).

> **Live after the next Windows deploy.** Until then `check-bridge-status` shows it
> advertised-but-not-backed (handshake `warn`). → [figma-local/deploy.md](figma-local/deploy.md).

## The efficient path: the `@codemoji/design` toolkit

For a full extraction, don't drive the raw tools — use the Mac-side CLI at `node/codemoji-design/`. It
wraps the live tools, routes renders to disk, and emits a reviewable spec:

```bash
node bin/codemoji-design.mjs doctor          # probe the bridge + which actions the plugin backs
node bin/codemoji-design.mjs extract 94:2974 # extract a node (or the current selection)
```

Output per screen → `figma/<screen>/`: `manifest.json` (figures + a `gaps[]` backlog), `spec.md`,
`tokens.md` (Figma colors/type → `node/codemoji-app/src/styles.css`), `reference/*.png`.

## Recipe — matching a React slice to Figma

1. `check-bridge-status` → confirm connected.
2. In Figma, select the screen/frame; `export-figure` (or `node bin/codemoji-design.mjs extract`).
3. Map the bundle's token refs to `node/codemoji-app/src/styles.css`; drop the humanized `.svg`
   assets into the slice (`vite-plugin-svgr`); build under `node/codemoji-app/src/{widgets,…}`.

---

**Operating the server itself** (install, change a tool, deploy to the Windows box):
[setup](figma-local/setup.md) · [update](figma-local/update.md) · [deploy](figma-local/deploy.md).
**Designing the surface** (ADRs, rungs, seams): the repo-root [`docs/figma-local/`](../../docs/figma-local/).
