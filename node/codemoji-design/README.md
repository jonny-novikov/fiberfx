# @codemoji/design

Design-system package for Codemoji. Two halves share one package:

1. the **design system** — the token source of truth (`tokens/tokens.mjs`), a
   theme generator that emits Tailwind v4 CSS-first text (`dist/theme.css`), and
   a **Storybook** that dogfoods both (see [Design system](#design-system) below
   and [`THEMING.md`](THEMING.md));
2. the **figma-local extraction toolkit** (the rest of this README): a Mac-side
   CLI that pulls a Figma screen straight from the figma-local bridge.

## Design system

The design system owns the Codemoji tokens. `tokens/tokens.mjs` is the
structured source of truth (the base oklch palette copied verbatim from the app,
the `--text-*` scale, `--font-sans`, the three `accentThemes`, and the `gold`
treatment). `codemoji-design theme` emits `dist/theme.css` — a drop-in for the
token surface of `codemoji-app/src/styles.css`, with a **single themeable
`--accent`** channel and three `[data-theme]` blocks (orange / blue / green).
Storybook (`@storybook/react-vite`, React 19 + Vite 7 + Tailwind v4) imports that
generated CSS, so its foundations / components / golden / screens stories show
the live tokens.

```bash
pnpm theme            # regenerate dist/theme.css from tokens/tokens.mjs (offline)
pnpm storybook        # Storybook dev server on :6006 (live accent theming)
pnpm build-storybook  # static build -> storybook-static/
```

- **Stories.** Foundations (Colors / Typography / Themes), Components (Button /
  Badge — self-contained CVA primitives that mirror the app's `cn`), Golden (the
  formalized `--gradient-gold` treatment), and Screens (the game-screen catalog
  read from `gameplay/manifest.json`, each screen its reference PNG + metadata).
- **Adoption + the gold treatment** that supersedes `gold.png` + the inline
  gradient: [`THEMING.md`](THEMING.md) (the FUTURE integration; not applied yet).
- **Exports.** `@codemoji/design/theme.css` → `dist/theme.css`;
  `@codemoji/design/tokens` → `tokens/tokens.mjs`.

---

## figma-local extraction toolkit

The rest of this package is the **figma-local extraction toolkit**: a Mac-side CLI that pulls a Figma screen (structure + reference renders + a token map) straight from the figma-local bridge and sorts it into reviewable artifacts.

It doubles as a **reference implementation of the proposed figma-local MCP enhancements** — every place the current MCP is too lossy or too heavy, the toolkit works around it and records the gap (see `manifest.json` → `gaps` and `docs/figma-local/`).

## Topology

Mac (this toolkit) → HTTP `FIGMA_BRIDGE_URL` (default the Windows Figma machine `http://192.168.1.120:3001`) → bridge → Figma plugin. Image bytes flow bridge → toolkit → disk; they never pass through an agent's context.

## Usage

```bash
node bin/codemoji-design.mjs doctor             # probe the bridge + which actions the live plugin backs
node bin/codemoji-design.mjs extract            # extract the currently-selected Figma node
node bin/codemoji-design.mjs extract 94:2974    # …or a specific node (the CODEMOJIES game screen)
node bin/codemoji-design.mjs sortout figma/codemojies   # re-generate manifest/spec/tokens from an extraction
```

Override the host: `FIGMA_BRIDGE_URL=http://host:3001 node bin/codemoji-design.mjs …`.

## Output (per screen, under `figma/<screen>/`)

```
manifest.json     index: screen, figures (ordered top-to-bottom), counts, gaps
spec.md           figure-by-figure spec (sizes, colors, type, effects, render links)
tokens.md         Figma colors/type → codemoji-app src/styles.css tokens
reference/*.png   per-figure renders — the source of truth for radius/spacing the JSON omits
structure/        summary.json (compact nodes) + renders.json
```

## Why this is "crucial to improve the MCP server"

The toolkit runs on the **6 live** plugin actions only; the friction it hits is the figma-local MCP backlog, recorded in every `manifest.json` (`gaps`):

| gap | today (live plugin) | fix (fork) |
|---|---|---|
| image egress | `export-node` returns a JSON int-array (~1M tokens for a screen) | base64 + Mac-side write (Fork 2 / B1) |
| subtree fetch | ~1 `get-node-properties` call per node | `get-node-tree` over `exportAsync({format:'JSON_REST_V1'})` (Fork 3 / C1) |
| node props | no cornerRadius / auto-layout / typography | enrich `serializeNodeDetailed` (+ `figma.mixed` guard, `getStyledTextSegments`) (Fork 1 / A1) |
| tokens | raw `VariableID` aliases | `resolve-variables` via `resolveForConsumer` — plugin-only (Fork 4 / D1) |
| instances | ~150 repeated tiles, no dedup | `get-component-instances` via `getMainComponentAsync` (Fork 4 / D1) |
| dead tools | `get-batch-nodes` / `export-batch-nodes` advertised but unimplemented | implement or drop registrations (stabilize) |

Design rationale, the surfaced forks, and the rung ladder live in **`docs/figma-local/`**. The enhancements deploy on the **Windows Figma machine** (Operator-owned); this toolkit is the on-Mac client + the spec's working proof.
