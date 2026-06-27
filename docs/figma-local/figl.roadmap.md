# figma-local — roadmap (`figl`)

> The single rung ladder for the figma-local enhancement, plus the open seams the Operator
> deferred. The design and the ADRs are in [figl.design.md](figl.design.md); the overview is
> [figma-local.md](figma-local.md). Every rung is **forward-tense** — none is built. The ladder
> is the two architects' ladders (Venus-A: 7 rungs; Venus-B: 5) collapsed by the four Operator
> rulings of 2026-06-25.
>
> **Deploy law.** The Mac side is this repo. The plugin + bridge are **hand-deployed on the
> Windows Figma machine with no CI** — so each rung names its deploy property, and any rung that
> changes a wire contract updates the Mac toolkit (`node/codemoji-design/src/*.mjs`) in
> **lockstep** so the working client never breaks on the un-tested box.

## Master invariants (hold on every rung)

- **The bridge stays a pure relay** — no rung makes it stateful or a file server (ADR-1, ADR-7).
- **Advertised == live** — `mcp.js` advertises only actions the deployed plugin backs; from
  `figl.2` this is *checked*, not hoped (ADR-5).
- **`figma.mixed` is guarded** — any property that can return the `unique symbol`
  (`plugin-api.d.ts:909`) is guarded before serialization; an unguarded read mangles the whole
  payload to `{}` (ADR-3).
- **Writes are bounded** — the Mac-side file write (`figl.2`) targets a specified
  `RENDER_ROOT` (`FIGMA_MCP_RENDER_ROOT` or `os.tmpdir()/figma-mcp-renders`); cleanup is an
  **explicit MCP tool** (`cleanup-renders`) the agent invokes — no background sweep, no daemon
  state, never an implicit deletion (Operator 2026-06-26, ADR-1 addendum).
- **The handshake flags, never bricks** — a version/capability mismatch degrades to a warning on
  `check-bridge-status`, never a hard failure against an older deployed plugin (ADR-5).

## The ladder

### `figl.1` — Stabilize advertised==live (Mac-only, **no deploy**)
- **Do:** delete the dead `get-batch-nodes` / `export-batch-nodes` registrations
  (`mcp.js:170-202`). Restores advertised==live instantly (ADR-6).
- **Deploy:** none — this repo only. Proves the loop before the Windows box is touched.
- **Verify:** reconnect the MCP; the two tools no longer appear; the remaining 8 still respond;
  `check-bridge-status` unchanged.
- **Risk:** lowest in the program (a deletion on a version-controlled file).

### `figl.2` — Egress + the capability handshake + cleanup tool (**first Windows deploy**)
- **Do (egress, B1 / ADR-1):** `code.ts` `exportNode` returns `figma.base64Encode(bytes)`
  (`plugin-api.d.ts:1886`) instead of `Array.from(bytes)` (`code.ts:141`); `mcp.js` base64-decodes,
  writes to `RENDER_ROOT` (`FIGMA_MCP_RENDER_ROOT` or `os.tmpdir()/figma-mcp-renders`), returns
  `{path, nodeId, format, w, h, byteLen}`. Update `extract.mjs:97`
  (`Buffer.from(res.data)` → `Buffer.from(res.data, 'base64')`) in **lockstep**.
- **Do (cleanup, ADR-1 addendum):** a new `cleanup-renders` MCP tool — explicit (no background
  sweep). Params: `keepLast` (int) and/or `keepSince` (`"1h"` / `"30m"` / `"24h"` / `"7d"`); a
  file is kept if it satisfies either rule. `dryRun: true` previews without deleting. At least
  one rule is required.
- **Do (handshake, E2 / ADR-5):** the plugin reports its backed-action list on `ws-connected`
  via a new `backed-actions` WS message; `bridge-server.js` caches it and `/health`
  (`bridge-server.js:76`) returns it as `backedActions`; `mcp.js` asserts advertised ⊆ backed
  and flags a mismatch via `check-bridge-status` (status `"warn"` with the missing list, never a
  throw). Selection-default (nodeId omitted on `get-node-properties` / `export-node` ⇒ the
  current page's **single** selected node; multi-selection is an error) rides along.
- **Deploy:** Windows (plugin + bridge `/health`). The egress is the worst live defect; the
  handshake is the guard every later rung relies on — they ship together so the box is never
  left advertising-unchecked.
- **Verify:** `export-node 94:2974` returns a `{path, w, h, byteLen}`, writes a non-empty PNG,
  returns no bytes; `check-bridge-status` lists `backedActions`, an `advertised` array, and a
  `handshake.status: "ok"`; calling `export-node` with no `nodeId` (and one Figma node selected)
  returns the rendered selection; `cleanup-renders { keepLast: 1 }` deletes all but the most
  recent render; the toolkit's `extract` still renders end-to-end against the new contract.

### `figl.3` — Targeted payload enrichment + re-implement `get-batch-nodes` (Windows deploy)
- **Do (A2 / ADR-3):** `serializeNodeDetailed` gains `cornerRadius` (+ per-corner
  `topLeftRadius` / `topRightRadius` / `bottomLeftRadius` / `bottomRightRadius`,
  `figma.mixed`-guarded — the unified value is emitted only when every corner agrees, the
  per-corner numbers are always concrete), the four auto-layout fields
  (`layoutMode`, `paddingTop|Right|Bottom|Left`, `itemSpacing`,
  `layoutSizingHorizontal|Vertical`) **emitted only when `layoutMode !== 'NONE'`**, and
  `absoluteBoundingBox` (`plugin-api.d.ts:6976`).
- **Do (`get-batch-nodes`):** re-add both halves — the plugin handler (loop
  `getNodeByIdAsync` → `serializeNodeDetailed`; missing nodes come back as `{id, error}`
  per-id rather than failing the batch) AND the `mcp.js` `registerTool` wrapper (figl.1
  dropped it Mac-side so `advertised==live` held while the handler was missing). Adds
  `'get-batch-nodes'` to both `BACKED_ACTIONS` (plugin) and `ADVERTISED_ACTIONS` (mcp.js).
- **Deploy:** Windows (plugin).
- **Verify:** a frame returns `cornerRadius` / padding where present and *omits* auto-layout
  on a `layoutMode: 'NONE'` node (so `get-selection` is not bloated); `get-batch-nodes`
  returns N enriched nodes in one call; the handshake now lists `get-batch-nodes` as backed
  and `advertised ⊆ backed` holds.

### `figl.4` — One-call bounded subtree (C2 / ADR-2) (Windows deploy)
- **Do:** `get-node-properties` gains an optional `depth` (absent ≡ today's single-node shape,
  EXACTLY — no extra fields) + a `maxNodes` cap (default 500, sized to keep the walk well
  under `bridge-server.js:148`'s ~30s). The plugin's new `serializeSubtree` recurses the
  *same* `serializeNodeDetailed` over children to `depth`, replacing the lite `{id,name,type}`
  child stubs with detailed children; when the cap is hit, the walk stops and the root carries
  `truncated: true` + `nodeCount`.
- **Deploy:** Windows (plugin) + Mac `mcp.js` (Zod schema picks up the new params).
- **Verify:** `depth` absent returns the byte-identical single-node shape (no `truncated` /
  `nodeCount` fields); `depth: 2` returns a bounded tree in one call; `maxNodes` truncates
  rather than exceeding the 30s bridge timeout; the toolkit's `boundedWalk` *can* collapse to
  one call (kept as N-calls today — the depth-collapsed walk is an optional future optimization
  the depth surface unblocks, not a `figl.4` deliverable).

### `figl.5` — `resolve-variables` (forced) + async hardening (D1 tokens / ADR-4, ADR-8) (Windows deploy)
- **Do (resolve-variables):** a new plugin action `resolve-variables` resolves a node's bound
  variables via `Variable.resolveForConsumer` (`plugin-api.d.ts:11432`) — the one capability the
  Mac client cannot supply (`valuesByMode` "will not resolve any aliases", `:11441`). Walks
  node-level `boundVariables` (scalar fields + multi-value arrays + `componentProperties`) AND
  per-paint `boundVariables` on `fills`/`strokes`/`effects`/`layoutGrids` (where the CODEMOJIES
  fill-color aliases live). Returns `{nodeId, bindings:[{field, variableId, name, value,
  resolvedType}|{...error}], count}` — per-binding errors do not fail the whole call. Variable
  lookup uses the async `getVariableByIdAsync` (`:2077`) for ADR-8 consistency.
- **Do (async hardening):** swap sync `figma.getNodeById` → `getNodeByIdAsync`
  (`plugin-api.d.ts:421`) at every surviving call site — `getNodeProperties` and `exportNode`
  (the `figl.3` `getBatchNodes` was async from day one). Behavior-preserving under legacy
  mode, defensive ahead of any dynamic-page adoption.
- **Deploy:** Windows (plugin) + Mac `mcp.js` (the new tool's registration).
- **Verify:** a bound `VariableID` resolves to a concrete value + `resolvedType`; the 14
  `CODEMOJIES` aliases (`node/codemoji-design/figma/codemojies/tokens.md`) resolve to real
  bindings via `resolve-variables`; every prior read (`get-node-properties`, `export-node`,
  `get-batch-nodes`) still works unchanged; `check-bridge-status` lists `resolve-variables`
  under `backedActions` with `handshake.status: "ok"`.

## The export + embed extension (`figl.6`–`figl.8` · 2026-06-27)

> `figl.1`–`figl.5` are **built and deployed** — the extraction floor (faithful reads · egress to
> disk · the handshake · token resolution). The Operator's 2026-06-27 ask extends the program from
> *faithful extraction* to **reusable, context-embeddable export**: turn a (user-selected) screen
> into a thin structural bundle + humanized on-disk assets, then roll those into an `llms.txt`
> payload an agent embeds **instead of re-querying Figma or loading a ~1M-token raw export**. The
> export-direction fork is **RULED Bundle (staged)** — IR now, codegen behind a named seam
> ([export.design.md](../codemojex-tma/kb/figma-livesync/export.design.md)); the new ADRs are
> ADR-9..ADR-12 ([figl.design.md](figl.design.md)). **Only `figl.6` deploys to Windows;** `figl.7`
> and `figl.8` are Mac-only orchestration over already-backed reads (like `figl.1`). The assets
> root is `FIGMA_MCP_ASSET_ROOT` (default `RENDER_ROOT/assets/`) — a stable subdir `cleanup-renders`
> never sweeps (it lists only top-level files, `mcp.js:305`).

### `figl.6` — Scale floor + `export-figure` FigureBundle (the screen import) (**Windows deploy**)
- **Do (S-5 scale floor; closes S-5):** port the deployed `code.js` scale hand-edit back into
  `code.ts` (the source of truth) — `exportNode(nodeId, format='PNG', scale=1)` + the typed two-call
  SCALE guard `(format==='SVG' || s===1) ? {format} : {format, constraint:{type:'SCALE', value:s}}`
  (`plugin-api.d.ts:4881`) + forward `params.scale` in the `switch`. Stops `pnpm build-plugin`
  silently reverting Retina (the drift hazard, `mcp/CLAUDE.md`). `mcp.js` already plumbs `scale`.
- **Do (`export-figure`, RULED Bundle):** a new plugin action composing **shipped reads** into a thin
  **FigureBundle IR** — `serializeNodeDetailed` (geometry/fills/strokes/effects/cornerRadius/
  auto-layout/`absoluteBoundingBox`) + `resolveVariables` (the token *name* per binding) + per-leaf
  `exportAsync({format:'SVG_STRING'})` for vectors / scaled raster for rasters; bounded by the existing
  `maxNodes`/`truncated` cap. Adds no new `figma.*` capability beyond the `SVG_STRING` overload. The
  token rule is the contract: every bound value carries `{token:"--name", value:"#hex"}` so the
  consumer's `@theme` map picks the class (why Bundle won the fork).
- **Do (humanized asset egress, ADR-10):** vectors (`.svg`) **and** rasters (`.png`/`.jpg`) write to a
  **stable, humanized** path `<ASSET_ROOT>/<screen-slug>/<layer-slug>[-<shortId>].<ext>` (slug from the
  Figma layer name; `<shortId>` appended only on collision) — distinct from the timestamped ephemeral
  `RENDER_ROOT`. The bundle carries **lightweight asset metadata only**
  (`{id, node, name, type, w, h, scale, byteLen, path}`) — never bytes; SVG defaults to a **file** ref,
  not inline (a `svg:'file'|'inline'` toggle, default `file`).
- **3-site registration:** `export-figure` → `code.ts` `switch`+handler + `BACKED_ACTIONS`;
  `ADVERTISED_ACTIONS` + `registerTool` in `mcp.js`. Toolkit (`node/codemoji-design/src/*.mjs`)
  reconciled in lockstep if it consumes the new action.
- **Deploy:** Windows (plugin + `mcp.js`); one reload lights the scale floor **and** `export-figure`.
- **Verify:** `export-figure 94:2974` returns a thin bundle (token refs + asset paths, no bytes, no
  ~1M-token blob); its vectors land as reusable `…/game-board/<layer>.svg`; a fresh `pnpm build-plugin`
  no longer reverts scale (`grep -n exportAsync code.*` agree); `check-bridge-status` lists
  `export-figure` under `backedActions` (`advertised ⊆ backed`).
- **Risk:** medium — the **one** new frozen plugin surface in this extension + a new persistent write
  root; both NO-INVENT-verified against the typings; **no Figma-document mutation**.
- **Status (2026-06-27): Mac-side BUILT + verified.** `code.ts` (`exportFigure` + `collectBoundVariables`
  refactor + vector-boundary helpers, all 6 `figma.*` calls cited to `plugin-typings@1.130.0`), `mcp.js`
  (`export-figure` tool + `ASSET_ROOT`), and a new pure `figure.js` projection module (RGBA→hex,
  fills→background, auto-layout→flex, box-shadow, token refs, humanized egress) **unit-tested on the Mac**
  (`figure.test.mjs`, 11 checks). `tsc` clean; `code.js` rebuilt (drift closed); handshake sets aligned.
  **Pending (Operator):** the Windows plugin reload (`pnpm build-plugin` + Figma re-run) **and** a Mac MCP
  reconnect to go live — until then `export-figure` is "Unknown action" on the live plugin (handshake WARN).

### `figl.7` — Screen registry: naming overrides + selection-driven batch (**Mac-only, no deploy**)
- **Do (registry):** a Mac-side, version-controllable map of **screen records**
  `{type:"screen", name:"Game Board", figure:"94:2974", slug:"game-board", updatedAt}` at
  `<ASSET_ROOT>/screens.json`. Two new **Mac-side** `mcp.js` tools (no plugin action — pure
  orchestration over shipped reads): `name-screen` (assign/override a human name + type for a node id →
  seeds the humanized asset slug of `figl.6`) and `list-screens` (read the registry). Naming is
  **Mac-side only — it never mutates the Figma document** (the read-only posture holds; write-back is
  deferred, S-7).
- **Do (selection-driven batch):** `name-screen` and `export-figure` **default to the live Figma
  selection** (`get-selection`, already backed) when `nodeId` is omitted — the user selects screens in
  Figma Desktop and the tools register/export them as a **context-aware batch** in one sweep (a *mode*
  of the existing surface, not a fourth tool — holding tool-count liability flat).
- **Deploy:** none — Mac-side `mcp.js` only (like `figl.1`); no Windows reload, no new plugin capability.
- **Verify:** select two frames → `name-screen` (no args) registers both from the selection;
  `list-screens` returns them; a subsequent `export-figure` uses the human slug for asset paths; the
  Figma document is byte-unchanged (no mutation).
- **Risk:** low — Mac-side state + orchestration over already-backed reads; no deploy, no frozen plugin
  surface, no doc mutation.

### `figl.8` — `llms.txt` generation: the context-embedding payload (**Mac-only, no deploy**)
- **Do:** a Mac-side `export-llms` tool composing the registry (`figl.7`) + per-screen FigureBundles
  (`figl.6`) + the humanized asset manifest into **two** files under `ASSET_ROOT`: an
  [llms.txt](https://llmstxt.org)-format **index** (H1 title · blockquote summary · H2 sections linking
  each named screen's bundle/assets/tokens with one-line descriptions) **and** a **payload**
  (`llms-full.txt`) that inlines the **compact structural skeleton + the token table + the asset
  manifest** (paths only — never bytes), so a single read embeds a whole screen's structure into an
  agent's context. Heavy bytes (SVG/PNG) stay strictly by-reference (ADR-1 carried to the payload).
  Embed depth is a knob (S-8; default skeleton + tokens + manifest).
- **Why (the north star):** "for efficient LLMs token usage." An agent reads one small index / payload
  to know every named screen, its structure, its tokens, and where its reusable assets live — instead
  of re-querying Figma or loading a raw export.
- **Deploy:** none — Mac-side `mcp.js`; composes shipped tool outputs + the registry into files.
- **Verify:** `export-llms` over a 2-screen registry emits a valid `llms.txt` (title/summary/sections)
  + a payload whose token count is a small fraction of the raw exports; asset links resolve to the
  humanized files on disk; an agent reading only the payload can name + locate every screen with no
  further Figma round-trip.
- **Risk:** low — Mac-side file composition over already-shipped reads.

## Seams & open decisions (deferred — surfaced, not resolved)

| id | seam | disposition |
|---|---|---|
| **S-1** | **No-auth bridge.** Any LAN host can drive Figma via `POST /request` (`bridge-server.js`, no token; CORS `*`). | **Accepted standing risk** (Operator, 2026-06-25). Mitigation on file: a one-line shared-secret header checked at `bridge-server.js`, sent by `mcp.js`. **B2 (bridge file-write) is hard-vetoed** while no-auth stands. Revisit if LAN exposure changes. |
| **S-2** | **`get-component-instances`.** Component identity (main component + overrides) for the ~150 repeated tiles, via `getMainComponentAsync` (`:10788`). | **Deferred** (Operator, 2026-06-25). The toolkit already dedups client-side (`extract.mjs:73-75`). Add only when a consumer needs identity — e.g. mapping one Figma component → one React component + N prop-sets for the codemoji-app build. Sibling: a `get-node-tree`/`JSON_REST_V1` tool (C1) if exact REST fidelity is later required. |
| **S-3** | **dynamic-page / `documentAccess`.** The plugin runs legacy mode; no key set. | **Not adopted.** Required only if instances (`getMainComponentAsync`) land. The `figl.5` async swap (ADR-8) prepares the read path so adoption would not break it. |
| **S-4** | **`getStyledTextSegments`.** Per-run typography for mixed text (`:9809`). | **Deferred** from A2 (ADR-3). Add when a TEXT consumer needs per-run styling beyond the current `fontSize`/`fontName`. |
| **S-5** | **Export scale/format options.** `ExportSettings { constraint: { type: 'SCALE'|'WIDTH'|'HEIGHT', value } }` (`:4881`). | **Closing in `figl.6`.** Shipped B1's `{path,...}` at 1×; the scale floor (the typed SCALE constraint, hand-edited live and now ported to `code.ts`) lands with `export-figure`. |
| **S-6** | **Transport F-direct.** Collapse the 3-hop bridge. | **Deferred.** No lived fact reopens the prior F-keep ruling; a plugin cannot host a server, so "direct" only relocates the relay. |
| **S-7** | **Figma write-back of screen names.** Renaming the Figma layer to the registry's human name (`figl.7`). | **Deferred (new risk class).** A write-back is a plugin **mutation** — the program is read-only to date and the `figl.7` registry is Mac-side. Add only if names must round-trip into the document; gate behind the no-auth seam (S-1). |
| **S-8** | **`llms.txt` embed depth.** How much per-node detail the `llms-full.txt` payload inlines (`figl.8`). | **Default skeleton + tokens + asset manifest;** a `depth` knob trades context cost for completeness. Surfaced; recommend skeleton — the FigureBundle JSON is the full-detail by-reference. |

## Decisions ledger (`RULED`)

| D-n | decision | ruling | record |
|---|---|---|---|
| D-1 | image egress | base64 + Mac-side write (B1) | convergent — ADR-1 |
| D-2 | subtree fetch | `depth` param on existing tool (C2) | convergent — ADR-2 |
| D-3 | node enrichment | targeted (A2), auto-layout gated on `layoutMode` | convergent — ADR-3 |
| D-4 | token resolution | `resolve-variables` only; instances client-side | Operator 2026-06-25 — ADR-4, S-2 |
| D-5 | handshake timing | early, with the egress rung | Operator 2026-06-25 — ADR-5 |
| D-6 | dead-tools floor | drop Mac-side first; `get-batch-nodes` re-added `figl.3` | Operator 2026-06-25 — ADR-6 |
| D-7 | transport / auth | keep bridge; no-auth accepted; B2 vetoed | Operator 2026-06-25 — ADR-7, S-1 |
| D-8 | async reads | `getNodeByIdAsync`, folded into `figl.5` | convergent — ADR-8 |
| D-9 | export direction | **Bundle (staged)** — IR now, codegen deferred to a named seam | Operator 2026-06-27 — ADR-9, export.design.md |
| D-10 | figure asset egress | humanized + stable + by-reference; SVG to disk, not inline | recommend (RULED-pending) — ADR-10 |
| D-11 | screen registry / naming | Mac-side, read-only (no Figma mutation) | recommend (RULED-pending) — ADR-11, S-7 |
| D-12 | `llms.txt` | index + embedded payload; bytes by-reference | recommend (RULED-pending) — ADR-12, S-8 |

## Verification posture (no CI on the deploy box)

There is no test harness on the Windows machine, so verification is **manual and per-rung**,
run from the Mac after each hand-deploy: reconnect the MCP, call `check-bridge-status` (from
`figl.2` it asserts advertised ⊆ backed), then exercise the rung's new surface against the live
`CODEMOJIES` screen and confirm the toolkit's `extract` still completes end-to-end. The handshake
(`figl.2`) is the closest this topology gets to a regression test: it is the standing check that
a future plugin/`mcp.js` drift can never again advertise a phantom tool. The enhance-and-deploy
runbook for the Windows box — per-rung edits, build/deploy primitives, and the verify steps — is
[figl.prompt.md](figl.prompt.md).

## References

- Design + ADRs: [figl.design.md](figl.design.md) · Overview: [figma-local.md](figma-local.md).
- Method: [aaw.architect-approach.md](../aaw/aaw.architect-approach.md) (surfaced-fork →
  "Seams & open decisions" → `RULED` ledger).
- Working reference implementation + the lived gaps: `node/codemoji-design/`.
- As-built MCP: `mcp/figma-mcp/`.
