# Codemoji · codemojex-tma — Build-Track Roadmap

> The **build track** of the Codemoji Telegram Mini App front end — the `cm-tma.*` rung ladder that makes the
> `echo/apps/codemojex/assets/` front end self-contained and then builds the TMA UI on it. It is **distinct
> from** the two companion roadmaps: the stale three-tier *rendering* narrative
> [`codemojex-tma.roadmap.md`](codemojex-tma.roadmap.md) (how each tier renders — pending its own §13
> docs-reconcile) and the *design-system* ladder
> [`design/codemojex.design.roadmap.md`](design/codemojex.design.roadmap.md) (the `cmd.*` Figma-reconcile
> rungs). This file owns the `cm-tma.*` build rungs only. Spec triads live under [`specs/`](specs/); per-rung
> audit ledgers under [`specs/progress/`](specs/progress/).

## The ladder

| Rung | Title | Status |
|---|---|---|
| **cm-tma.1** | The self-contained edge build | **SHIPPED — 13/14 front-end gates** |
| **cm-tma.2** | Vendored test suites jest→vitest (INV-VITEST) | **QUEUED** |

### cm-tma.1 — The self-contained edge build · **SHIPPED (13/14 front-end gates)**

Spec: [`specs/cm-tma.1.md`](specs/cm-tma.1.md) · ledger
[`specs/progress/cm-tma-1.progress.md`](specs/progress/cm-tma-1.progress.md).

Removed the `file:../../../deps/phoenix*` coupling that dragged the whole BEAM umbrella into the front-end
build:

- **pnpm workspace `@codemojex/edge`** — `assets/` is its own workspace; the vendored `@echo/phoenix` +
  `@echo/phoenix_live_view` resolve via `workspace:*` (+ the `./phoenix_html` subpath export); npm retired.
- **es2024** target across the root build configs — which **forced `vite ^5 → ^6`** (esbuild gained the
  `es2024` target in 0.24.0; vite 6 bundles esbuild 0.25.x; the lockfile resolves `vite@6.4.3`).
- **Self-contained `Dockerfile`** — build context `assets/`; no `deps/` COPY; awscli fetched from the edge
  bucket `dist/` pre-stage (not the public AWS origin); `ENTRYPOINT bin/edge-deploy.sh`.
- **Relocated `bin/edge-deploy.sh`** — moved under `assets/` so the whole edge surface is one self-contained
  tree.

**A4** (INV-VENDORED-FAITHFUL — the runtime LiveSocket-boot smoke, the §14-primary gate) is **mutation-proven**.
**A13** (INV-VITEST) is **DEFERRED → cm-tma.2**: the `package.json` end-state is jest-free, but the vendored
`test/*.test.ts` files are unported upstream jest.

### cm-tma.2 — Vendored test suites jest→vitest (INV-VITEST) · **QUEUED**

Port the vendored `@echo/phoenix` + `@echo/phoenix_live_view` test suites from upstream jest to vitest:
rewrite the ~320 jest call-sites (`@jest/globals` → vitest, `jest.fn` → `vi.fn`), fix the `../src` import
paths + the `test/tsconfig.json` `extends`, and add a jsdom env. Done when both `pnpm -C packages/* test` run
green and `grep -rniE '\bjest\b' assets/packages` → 0 — closing the A13 deferral from cm-tma.1.

## Forward

Later `cm-tma.*` rungs are the **TMA UI** rungs — the player-facing Mini App screens — built on this
self-contained front end, consuming the `cmd.*` design-system components from the design track.

## Map

Spec triads: [`specs/`](specs/) · ledgers: [`specs/progress/`](specs/progress/) · the rendering narrative:
[`codemojex-tma.roadmap.md`](codemojex-tma.roadmap.md) (§13-deferred) · the design-system ladder:
[`design/codemojex.design.roadmap.md`](design/codemojex.design.roadmap.md).
