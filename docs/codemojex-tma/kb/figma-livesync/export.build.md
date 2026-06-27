# figma-livesync · export build brief — figl.6 (RULED: Bundle, staged)

> **Authority:** `./export.design.md` (the ruling) + the figl program (`docs/figma-local/`). The Operator
> ruled **Arm Bundle (staged)** on 2026-06-27. This brief is the authoritative *scope* for the build
> team; it does not re-open the fork. **NO-INVENT** holds: every `figma.*` call is verified against
> `@figma/plugin-typings` at a cited line (start from the design doc's consolidated ledger).

## One increment, two phases

### Phase 0 — the S-5 scale drift repair (shared floor; do FIRST)

The scale support is live in the **deployed** `code.js:213-215` but **absent from `code.ts`** (the
source of truth), so `pnpm build-plugin` reverts Retina (`mcp/CLAUDE.md:44`).

- Port into `code.ts`: `exportNode(nodeId, format='PNG', scale=1)` + the guard
  `(format === 'SVG' || s === 1) ? { format } : { format, constraint: { type: 'SCALE', value: s } }`,
  and forward `params.scale` in the `switch` (`code.ts:51`).
- **Acceptance:** `grep -n exportAsync figma-plugin/code.*` shows `code.ts` and `code.js` agree; a fresh
  `pnpm build-plugin` no longer reverts scale. No new action, no handshake change (`mcp.js` already
  plumbs `scale`).

### Phase 1 — the `export-figure` FigureBundle IR

A **projector over shipped reads** — adds no new `figma.*` capability beyond the `SVG_STRING` overload.

- **PLUGIN (`code.ts` → rebuild → `code.js`):** new `case 'export-figure'` → handler `exportFigure`
  composing `serializeNodeDetailed` (`code.ts:363` — geometry/fills/strokes/effects/cornerRadius/
  auto-layout/`absoluteBoundingBox`) + `resolveVariables` (`code.ts:268` — the token *name* per binding)
  + per-leaf `exportAsync({format:'SVG_STRING'})` for vectors / scaled raster for rasters; bounded by the
  existing `maxNodes`/`truncated` cap (`code.ts:188-211`). Add `'export-figure'` to `BACKED_ACTIONS`.
- **MCP (`mcp.js`):** add `'export-figure'` to `ADVERTISED_ACTIONS`; `registerTool("export-figure", …)`
  with Zod `{ nodeId?, depth?, scale?, svg? }`; raster assets → `RENDER_ROOT` via the existing
  `renderFilename`/`writeFileSync`; **result = FigureBundle JSON with `{path,…}` asset refs + inline
  `svg` strings, NEVER raw bytes** (ADR-1).

## The FigureBundle schema (the frozen contract — design with care; additive-minor thereafter)

```
FigureBundle { root: FigureNode, truncated?: boolean, assets: Asset[] }
Asset        { id, path, scale, w, h, byteLen }                    // rasters only
FigureNode   {
  id, name, type,
  layout: { x, y, w, h, display?: 'flex', flexDirection?, gap?, padding?, … },  // auto-layout → flex
  style:  { background?: { token?, value }, border?, borderRadius?, boxShadow?, opacity? },
  text?:  { characters, runs? },
  svg?:   string,        // inline SVG_STRING for a vector leaf
  assetRef?: string,     // → assets[].id for a raster leaf
  children?: FigureNode[]
}
```

- **Token rule (the decisive design choice):** every resolved-variable-bound value carries
  `{ token: "--name", value: "#hex" }` so the consumer's `tokens.md` → `styles.css @theme` map decides
  the class. Do **not** bake a hex when a token name exists. This is why Bundle won the fork.
- **Style-prop mapping:** harvest/invert the vocabulary from `mcp/react-figma/src/styleTransformers/`
  (RGB→hex, fills→background) — **read, never run** (react-figma is the inverse direction, not git-tracked).

## 3-site coherence checklist (`mcp/CLAUDE.md:46-54`)

| Site | Phase 0 | Phase 1 |
|---|---|---|
| `code.ts` switch + handler | `exportNode` scale port | `case 'export-figure'` + `exportFigure` |
| `BACKED_ACTIONS` (`code.ts`/`code.js`) | — | `+ 'export-figure'` |
| `mcp.js` `ADVERTISED_ACTIONS` + `registerTool` | — | `+ 'export-figure'` + tool |

## Gate ladder (no CI on the deploy box — verify what the Mac can)

- `node --check mcp.js`; exercise the Mac-side `mcp.js` paths + the FigureBundle JSON shape against a
  recorded/mock bridge response where feasible (the MCP server is Node, runnable on the Mac).
- NO-INVENT each `figma.*` against `@figma/plugin-typings` (cite path:line). The plugin itself cannot be
  run/tested on the Mac — that is the Windows hand-off below.

## The Windows-deploy hand-off (HARD external dependency — Operator-only)

The Phase 0 + Phase 1 **plugin** changes need `pnpm build-plugin` + a manual Figma reload on the
**WINDOWS** machine (*Plugins → Development → Figma MCP Bridge*). **No agent — Mac or otherwise — can do
this.** The build team edits source on the Mac; the **Operator** deploys + reloads on Windows, then
verifies `check-bridge-status` shows `export-figure` as `advertised ⊆ backed`. Until reloaded,
`export-figure` is "Unknown action" on the live plugin (handshake WARN, never a hard fail).

## Recommended formation

- **Venus** (figl-architect lens): finalize the FigureBundle schema; register **figl.6** in
  `docs/figma-local/figl.roadmap.md` (additive rung note).
- **Mars**: build Phase 0 + Phase 1 on the Mac (`code.ts` + `mcp.js`); reconcile `code.ts`↔`code.js`.
- **Director**: review the schema freeze, 3-site coherence, the NO-INVENT ledger, the drift repair.
- **Operator**: the Windows build+reload + live `check-bridge-status` verification.
- **Apollo** (optional): post-build reconcile + the roadmap/KB sync.

## Deferred (named seam) — Arm Codegen

The Mac-side `export-react` codegen scaffold reads this FigureBundle and emits `.tsx` — additive on top,
no rework. Revisit when a second consumer/extraction proves the Tailwind target is stable enough to
freeze. `CHOSEN-AGAINST` rationale: `./export.design.md`.
