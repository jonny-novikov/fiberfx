# figma-livesync — consolidated KB

> **Provenance.** This KB is **newly established** — the `figma-livesync/` directory did not exist
> before (the `codemojex-tma/kb/` folder held only frontend state-management research, and a
> repo-wide search for `livesync` returned nothing). It consolidates the Figma→React knowledge that
> the **export program** builds on, scattered today across `docs/figma-local/`, `node/codemoji-design/`,
> and `node/codemoji-app/`. Per `docs/aaw/aaw.architect-approach.md` (Voice / NO-INVENT) it **links**
> the canonical sources rather than restating them. Status: grounding for the export design fork.

## What "figma-livesync" names

The pipeline that keeps the **codemoji-app** React UI in step with the **Figma** design:

> read a Figma node → extract a faithful **figure** → land it as a React **slice**.

Today the last step is **manual**: a human reads `spec.md` + a reference PNG and hand-writes the JSX.
The export program automates the *extract → React-figure* step. Context: the parent program
(`docs/codemojex-tma/codemojex-tma.roadmap.md`) is a three-tier rendering pivot — Static welcome →
LiveView lobby → **LiveReact** board — so the React figures this pipeline produces are the
LiveReact-island content, not a standalone SPA.

## The three repos

| Repo | Role in the pipeline |
|---|---|
| `echo/apps/codemojex` | Elixir/Phoenix game backend (economy, ledgers, branded ids). **Not** in this pipeline. |
| `node/codemoji-app` | The React Telegram Mini App (Vite 7 · React 19 · TS · Tailwind v4 · Feature-Sliced Design). **Where figures land** — mostly `src/widgets/*`. Tokens live in `src/styles.css` `@theme`. Consumes design data **manually** today (no figure/manifest reader exists in `src/`). |
| `node/codemoji-design` | The Mac-side extraction CLI (`extract <nodeId>`). Emits per screen: `manifest.json` (ordered `figures[]` + a `gaps[]` backlog), `spec.md`, `tokens.md`, `reference/*.png`. The current "IR" is **geometry + raster**, not a component tree. |

## The current pipeline + its gaps

```
Figma (Windows)
  │  figma-local MCP / codemoji-design extract  (mcp/CLAUDE.md)
  ▼
manifest.json  +  spec.md  +  tokens.md  +  reference/*.png      ← descriptive geometry + 1× PNG
  │  HUMAN reads spec + PNG, maps Figure → FSD slice, writes JSX  ← the manual, un-automated step
  ▼
node/codemoji-app/src/widgets/*  (React)
```

Known gaps the export program closes (recorded in the extractor's `manifest.json → gaps[]` and `figl` seams):

- **Fidelity.** `export-node` renders **1× only** (no Retina). Scale/format is the deferred figl seam **S-5**.
- **Lossy structure.** `cornerRadius`, auto-layout spacing/padding, and resolved token values are absent from the JSON — today read from the reference PNG by eye.
- **No component identity.** Repeated tiles aren't mapped to one component + N prop-sets (deferred figl seam **S-2**: "one Figma component → one React component + N prop-sets for the codemoji-app build").
- **No React emission.** Nothing produces a render-able React artifact; the Figure→slice map in `node/codemoji-app/CLAUDE.md` is a human contract an exporter would formalize.

## The MCP / plugin surface it runs on

See `mcp/CLAUDE.md` for the full architecture, the **Windows-only deploy discipline**, the **`code.ts` vs `code.js` drift hazard**, and the **3-site action registration** pattern. In brief: stdio `mcp.js` (Mac) ↔ no-auth bridge (Windows `:3001` HTTP / `:3000` WS) ↔ Figma plugin. `export-node` today returns a disk **path** (`{path, format, scale, w, h, byteLen}`), never bytes. Any new export tool is **frozen public surface on a box with no CI** — priced as a multi-year liability.

## The design fork — RULED (Operator, 2026-06-27): **Bundle (staged)**

"Export raw figures in a format suitable to render React components" had two credible arms, argued via
the two-architect debate (`docs/aaw/aaw.architect-approach.md`) → `./export.design.md`. **The Operator
ruled Arm Bundle (staged):** ship the S-5 scale floor + the `export-figure` FigureBundle IR now; defer
the Codegen layer behind a named seam (additive-on-top). The build scope is `./export.build.md`.

| Arm | Lens (architect) | What it exports |
|---|---|---|
| **Bundle** | Venus-Export-Bundle (spec-steward / maintainer) | A structured figure **IR/bundle** — resolved geometry + React/CSS-style props + text runs + inline SVG + asset refs — that a renderer or agent turns into React. A data contract; lower frozen-surface liability. |
| **Codegen** | Venus-Export-Codegen (consumer / DX) | Ready-to-render **React/JSX component source** (+ a styling target: inline / CSS module / Tailwind) emitted directly from the node. Closest to "drop-in"; higher codegen + maintenance liability. |

`mcp/react-figma/` (the upstream React→Figma renderer — the *inverse* direction) contributes only its
**Figma↔CSS-prop mapping vocabulary** (`src/styleTransformers/`, `src/types.ts`), never its renderer.

## Sources — canonical (read, do not duplicate)

- **figl program:** `docs/figma-local/figl.{design,roadmap,prompt}.md` — figl.1–5 BUILT; seams S-2 (component identity) + S-5 (export scale/format) deferred.
- **MCP/plugin nav + deploy discipline + drift hazard:** `mcp/CLAUDE.md`.
- **Extractor + output format:** `node/codemoji-design/` (README + `figma/codemojies/manifest.json` example).
- **Consumer + Figure→slice map + token bridge:** `node/codemoji-app/CLAUDE.md`, `node/codemoji-app/src/styles.css`.
- **The fork method:** `docs/aaw/aaw.architect-approach.md`.
