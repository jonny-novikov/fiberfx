# figma-livesync · export design — the Figma→React figure-export fork

> **Status:** RULED 2026-06-27 — **Arm Bundle (staged)**: ship the S-5 scale floor + the `export-figure`
> FigureBundle IR; defer the codegen layer behind a named seam. Build brief: `./export.build.md`.
> **Method:** `docs/aaw/aaw.architect-approach.md` — a two-architect debate (the high-stakes path,
> for a soon-to-be-frozen public surface). **Venus-Export-Codegen** argued from the consumer / DX
> lens; **Venus-Export-Bundle** from the spec-steward / maintainer lens. Each argued *both* arms in
> four parts (Rationale · 5W · Steelman · Steward), ranked them, and pre-empted the opposing lens.
> The Director synthesizes below; **the Operator rules** — this doc does not pick the winner.
> **Grounding:** `mcp/CLAUDE.md` · `docs/figma-local/figl.{design,roadmap}.md` (seams S-2/S-5) ·
> the as-built export path (`mcp/figma-mcp/mcp.js`, `figma-plugin/code.{ts,js}`) · the consumer
> (`node/codemoji-app/CLAUDE.md`) · the extractor (`node/codemoji-design/`).

## The need

"Export raw figures in a format suitable to render React components" — **both the plugin side and the
MCP side** — plus **high-fidelity (Retina/scale) export**. Today the last pipeline step is manual: a
human reads `spec.md` + a reference PNG and hand-writes JSX into `node/codemoji-app/src/widgets/*`
(`figma-livesync/index.md`). The fork is over *what the exporter emits*; the fidelity half is shared.

## Phase 0 — the shared floor (pre-fork, both arms inherit; no ruling needed)

Both architects verified the same fact: **the Retina/scale work is already half-built and is a drift
repair, not new design.**

- `mcp.js` plumbs `scale` end-to-end (Zod param → `requestFigma` → reported back), and the **deployed
  `code.js:213-215`** already attaches the constraint: `(format === 'SVG' || s === 1) ? { format } :
  { format, constraint: { type: 'SCALE', value: s } }`. Verified against the typings:
  `ExportSettingsImage.constraint: { type: 'SCALE'|'WIDTH'|'HEIGHT', value }` (`plugin-api.d.ts:4880-4922`);
  SVG export interfaces carry **no** constraint field, so scale is correctly a no-op there.
- **But `code.ts` (the source of truth) is stale** — `exportNode(nodeId, format='PNG')` with bare
  `exportAsync({ format })` (`code.ts:213`), and the `switch` does not forward `params.scale`
  (`code.ts:51`). A `pnpm build-plugin` silently reverts Retina (the live drift hazard, `mcp/CLAUDE.md:44`).

**Phase-0 work (whichever arm wins):** port the `code.js` scale edit back into `code.ts` (`exportNode`
signature + the SCALE-constraint guard + the `switch` forward of `params.scale`), confirm
`grep -n exportAsync figma-plugin/code.*` agrees, then one Windows build+reload. This is the true
"figl.6 floor." It must land before any React-export rung consumes a @2x raster.

## The two arms

| | **Arm Bundle** (figure IR) | **Arm Codegen** (React/JSX source) |
|---|---|---|
| **Emits** | One resolved JSON `FigureBundle` per node: bounded subtree of resolved nodes, each with `layout` (box + auto-layout→flex), `style` (resolved fills/strokes/effects/radius as CSS-prop-shaped values **carrying the token name**, not just hex), `text` runs, and `assets[]` (`{path,scale,w,h,byteLen}` raster refs + inline `svg` strings). | Ready-to-render React/TSX source for the node, with a `styleTarget` (`inline` / `css-module` / `tailwind`), assets inlined as `import x from './x.svg?react'` / `<img src={path}>`. |
| **Closes the gap by** | Re-basing the manual step from "read a PNG by eye" to "read a resolved tree" — transcription-free wiring, reliable for an agent. | Deleting the manual JSX step — drop-in `<Header/>` into `widgets/*`. |
| **Frozen surface** | One JSON schema + one plugin projector. Grows additively (unknown field ignored). | A code generator + a frozen **styling target** + an open-ended emission tail (mixed text, nested instances, gradients, blend modes). |
| **Token handling** | By **reference**: `resolveForConsumer` returns the variable *name* (`code.ts:289`); the bundle carries `{ token, value }` and the consumer's existing `tokens.md`→`styles.css @theme` map decides the class — theme changes never strand baked hex. | By **value/guess**: must map an `#FF8400` fill to a Tailwind class at generation time; survives only while the consumer's conventions hold. |
| **Where codegen/IR lives** | Plugin projector (`serializeFigure`) over the shipped `serializeNodeDetailed` + `resolveVariables`; assembled Mac-side. | **Mac-side, version-controlled** template over the same resolved payload — *not* in the frozen plugin (both architects agree on this). |
| **Liability (CI-less box)** | Mid — additive, composes shipped reads, no new `figma.*` capability beyond the `SVG_STRING` overload. | High — freezes an output language + styling system that rots silently against consumer churn with no CI to catch it. |

### Four-part summaries

**Arm Bundle.** *Rationale:* finish the half-IR the extractor already emits (`manifest.json → figures[]`,
`manifest.json:15-169`) into a resolved, render-ready shape — a *projection of already-shipped reads*,
nothing invented. *5W:* one `export-figure` MCP tool returning a `FigureBundle`; produced plugin+MCP,
consumed by an agent or the `@codemoji/design` toolkit that writes the FSD slice; reached after the
figl resolution floor + Phase 0; projector in `code.ts`, tool in `mcp.js`. *Steelman:* the only arm
that extends a shape the program already froze and trusts; composes the consumer's token system **by
reference** (the decisive advantage — Codegen must guess the class, Bundle hands over the token name);
inline SVG via `exportAsync({format:'SVG_STRING'})` (returns `string`, `plugin-api.d.ts:8675`) needs no
base64/disk hop; schema ages by additive minor. *Steward:* one JSON schema + one projector, the same
liability class as `resolve-variables`; bounded by the existing `maxNodes`/`truncated` cap so a deep
figure can't blow the 30s bridge timeout; the cost it owns honestly — it lowers but does not eliminate
the JSX authoring step.

**Arm Codegen.** *Rationale:* the named gap is the manual JSX hand-write; emit the JSX directly.
*5W:* an `export-react` tool returning `{ tsx, styleTarget, assets }`; consumed drop-in into `widgets/*`;
same resolution floor; template + styling mapper Mac-side. *Steelman:* the consumer's slices are *named
and waiting for a component* (`codemoji-app/CLAUDE.md:56-63`); targeting Tailwind v4 keyed to the app's
own `@theme` tokens makes output idiomatic on day one; `vite-plugin-svgr` already in-stack makes an
emitted `?react` import genuinely drop-in; the styling target is *already singular and pinned*, so
codegen's classic risk (unknown target) does not apply; strictly additive + reversible if kept Mac-side.
*Steward:* the largest frozen liability on a no-CI box — it freezes a styling system, owns an
open-ended edge-case tail, and (per the Bundle lens) is the ADR-2 "second schema" mistake one level up
(a second *output language*). Both architects' mitigation: keep it Mac-side + version-controlled, build
it **on** the Bundle, and treat the `.tsx` as a scaffold the team edits — converting "generated code
drifts" from a silent bug into an expected hand-off.

## Director synthesis — the convergence and the residual fork

The two lenses, argued independently, **agree on the spine**:

1. **The resolved FigureBundle IR is stage one.** Codegen ranks it as the necessary input ("Codegen as
   a sequence, not a rivalry"); Bundle ranks it as the answer. Either way it is built first and
   forecloses nothing.
2. **Phase 0 (the `code.ts` scale drift repair) is the shared floor.**
3. **Codegen, if built, is a Mac-side, version-controlled, scaffold-not-frozen template on the Bundle.**
   Neither lens wants a code generator in the frozen plugin.

The **only genuine divergence** is narrow and is the Operator's to rule:

> **Build the Mac-side codegen template layer now, or stop at the IR and defer codegen behind a named seam?**

- **Codegen's case to build now:** the IR re-bases the manual step but does not delete it; only codegen
  closes the gap the program was opened to close, and the styling target is already pinned, so the
  classic risk is absent.
- **Bundle's case to defer:** freeze a data contract, not a styling system; let the consumer's own
  token map decide classes; add the codegen layer later if a *second* consumer or extraction proves the
  need — mirroring the figl S-2/S-5 "add only when a consumer needs it" discipline. Because codegen is
  additive on top of the IR, ruling Bundle-now does not block Codegen-later.

**Director recommendation (advice, not a decision):** the **staged path** — Phase 0 (scale repair) +
Phase 1 (the `export-figure` FigureBundle IR) now, **defer the codegen layer** behind a named seam.
The one reason that carries it: the IR captures most of the value (resolved, transcription-free input +
the consumer's own token map deciding classes) at the lowest frozen-surface cost, and the codegen layer
is strictly cheaper to add later — once a second consumer proves the styling target is stable enough to
freeze. The trade given up: drop-in JSX velocity now. If the Operator weighs that velocity above the
maintenance tail, the Codegen layer is the arm — and because it is additive and Mac-side, choosing it
costs no rework on the IR.

## The fork surface — **RULED** (Operator, 2026-06-27)

- **Arm Bundle** — ship the FigureBundle IR; defer codegen.  **`RULED: CHOSEN.`** Staged build: Phase 0
  (the `code.ts` scale drift-repair) + Phase 1 (the `export-figure` FigureBundle IR), both sides. The
  carrying reason: it freezes a data contract, not a styling system — the lowest frozen-surface cost on
  a CI-less box — and captures most of the value (resolved, transcription-free input + the consumer's
  own `@theme` map deciding classes) while foreclosing nothing.
- **Arm Codegen** — also ship the Mac-side `export-react` codegen scaffold on the IR.  **`RULED: DEFERRED`**
  (named seam, additive-on-top). **`CHOSEN-AGAINST:`** Codegen is the only arm that *deletes* the manual
  JSX step end-to-end, and its classic risk (an unknown styling target) is absent here — the consumer's
  Tailwind-v4 `@theme` target is already pinned. It was deferred, not rejected: on a no-CI box a frozen
  code generator owns a styling-system freeze + an open-ended emission tail, and because it is additive
  on the IR, ruling Bundle-now costs no rework if a second consumer later proves the target stable
  enough to freeze. Revisit as the figl seam after `export-figure` ships.

## Both-sides split (3-site rule, `mcp/CLAUDE.md:46-54`; Windows reload)

**Phase 0 (shared):** PLUGIN — port `scale` into `code.ts` `exportNode` + `switch` forward (drift
repair, **no** new action, no handshake change); one Windows build+reload.

**Bundle — PLUGIN:** one new `case 'export-figure'` in the `switch` + handler `exportFigure` (projector
over `serializeNodeDetailed` `code.ts:363` + `resolveVariables` `code.ts:268` + per-figure
`SVG_STRING`/scaled raster); add `'export-figure'` to `BACKED_ACTIONS`. **MCP:** add to
`ADVERTISED_ACTIONS`; `registerTool("export-figure", …)` (Zod `nodeId?`, `depth?`, `scale?`, `svg?`);
raster assets route to `RENDER_ROOT` via the existing `renderFilename`/`writeFileSync`, **never raw
bytes in the result** (ADR-1). Price: **one** frozen plugin action + **one** Windows deploy.

**Codegen (additive on Bundle):** the generator is a **Mac-side tool** (`export-react` in `mcp.js` or
`@codemoji/design`) reading the FigureBundle and emitting `.tsx` to `RENDER_ROOT` — like `cleanup-renders`
it is a Mac-only tool, so it adds **no** `BACKED_ACTIONS`/plugin surface; the frozen liability is the
emitted-source contract + the `styleTarget` enum, owned in version control with git, not on the deploy box.

## NO-INVENT ledger (consolidated; ✓ verified · ⊘ forward-tense/unbuilt)

- ✓ `export-node` egress `{path,nodeId,format,scale,w,h,byteLen}` — `mcp.js:195-226`; plugin `exportNode` scale path `code.js:201-230`.
- ✓ **S-5 scale lives in `code.js`, absent in `code.ts`** — `code.js:213-215` vs `code.ts:213,51` (live drift, `mcp/CLAUDE.md:44`).
- ✓ `ExportSettingsImage.constraint {type:'SCALE'|'WIDTH'|'HEIGHT', value}` — `plugin-api.d.ts:4880-4922`; `exportAsync` overloads image→`Uint8Array` `:8673`, `SVG_STRING`→`string` `:8675`, `JSON_REST_V1`→`Object` `:8677`; `figma.base64Encode` `:1886`.
- ✓ `serializeNodeDetailed` (fills/strokes/effects/cornerRadius+per-corner `figma.mixed`-guarded/auto-layout gated on `layoutMode!=='NONE'`/`absoluteBoundingBox`/TEXT) — `code.ts:363-424`; `resolveVariables` via `Variable.resolveForConsumer` `code.ts:268-343` (typing `plugin-api.d.ts:11432`).
- ✓ bounded subtree `maxNodes`/`truncated` (default 500) `code.ts:188-211`; 30s bridge timeout `bridge-server.js` (cited via figl, not re-verified this run).
- ✓ 3-site registration + handshake (WARN-not-fail) — `code.ts:6-15,34-61`, `mcp.js:20-29,260-285`; `RENDER_ROOT`/`renderFilename` `mcp.js:15-16,99-103,213-214`; Mac-only-tool precedent `cleanup-renders` `mcp.js:287`.
- ✓ extractor IR `figures[]` + `gaps[]` `manifest.json:15-209`; token map `sortout.mjs:7-38`; consumer FSD/`@theme`/svgr/Figure→slice `codemoji-app/CLAUDE.md:24,31-34,42-49,56-63`.
- ✓ `react-figma` is the **inverse** (CSS→Figma) and **not git-tracked** (`git ls-files mcp/react-figma`→empty); `colorToPaint` `transformColors.ts:46`, `transformGeometryStyleProperties.ts:24` — harvest/invert the *vocabulary*; vendoring/running = liability.
- ✓ deferred seams present but **not** required by either arm: `getStyledTextSegments` `plugin-api.d.ts:9809` (S-4 per-run text), `getMainComponentAsync` `:10788` (S-2 component identity).
- ⊘ `export-figure` / `serializeFigure` / the FigureBundle schema — proposed Bundle surface, unbuilt.
- ⊘ `export-react` / `styleTarget` contract — proposed Codegen surface, unbuilt.
- ⊘ S-5 `scale` as a *ruled `code.ts`-resident figl rung* — proven in `code.js`, not yet ruled/ported.
