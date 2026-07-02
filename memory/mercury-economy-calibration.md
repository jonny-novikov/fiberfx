---
name: mercury-economy-calibration
description: mercury/codemojex-node/apps/economy = Vite/React/Effector revenue-model calibration console (port 5180); the model formula + the workspace build gotchas
project: mercury
metadata: 
  node_type: memory
  type: project
  originSessionId: 874ee9ef-331a-49fc-82d7-80158cd7f6d8
---

`mercury/codemojex-node/apps/economy` (`@codemojex/economy`) = the codemojex revenue-model calibration console — Vite+React19+Effector, port **5180**, dark-first, reuses `@mercury/ui`+`@mercury/effector`. Built 2026-06-28. Tabs: Calibrate / Prize Pool / Advanced (multi-currency rail panel + WAC balance simulator).

**The model** (USD-canonical, `src/model/calc.ts`, verified 23/23 sanity targets via a Node re-derivation): `10💎=$1` is an input `diamondsPerUsd` (default 10 — NOT echo `economy.ex`'s stale `@cents_per_diamond 1.2`); `pool_diamonds = floor(basis_akp × guess_fee × pool_portion × dpu)`; `house = guess_value − pool_usd` (one-floor complement, residue→house); `squeeze% = margin / guess_value` (PINNED denominator — NOT /pool_owed; reproduces +1.3% mobile / +30.3% desktop). Net split basis sizes the pool off the worst-case (mobile) fee. Defaults: akp $0.15, fee 5, portion 0.70 → 5💎/$0.50 pool + $0.25 house.

**Two reusable primitives added to `@mercury/ui`**: `Chart` (geometry-dumb SVG curve/area, mirrors echomq's charts) + `Stat` (KPI tile); barrel `export *` in index.ts, `.mx-chart*`/`.mx-stat*` appended to mercury.css. Showcase/design-sync ceremony deferred to a follow-up.

**Workspace build gotchas (2026-06-28, Operator in-flight — NOT in economy code):** (1) `pnpm install` BLOCKED by `codemojex-node/apps/api` pinning a non-existent `@sinclair/typebox@1.3.0` (latest 0.34.49); a filtered install can't bypass it (pnpm resolves the whole-workspace lockfile first). (2) `tsc` reports 3 errors from the mercury-ui barrel's new `export * from "./date"` pulling in the untracked `internal/date-time/` tree (unresolved `@/shared/date/types`) — but `vite build` TREE-SHAKES it out and is GREEN (the app never uses date). economy app + Chart/Stat typecheck clean (0 errors). `economy/node_modules` was linked by the first partial install, so `node_modules/.bin/vite --port 5180` runs it NOW even before the api is fixed.

**Depth gotcha:** economy sits one level deeper than `mercury/apps/*` → the vite alias + tsconfig `paths`/`extends` need **three** `../` (not two) to reach `mercury/packages` + `tsconfig.base.json`. Extend mercury's React-typed base, `"types":["react","react-dom"]` (NOT codemojex-node's node base). Mercury status-token pattern: `--bg-{tone}-subtle` + `--fg-{tone}`; brand hue is `--iris-9` (no `--brand-9` scale). `Table<Row>` needs `Row extends Record<string,unknown>`; `createForm<V>` needs `V` to be a `type` alias (interface fails the constraint).

Revenue-model design canon: docs/codemojex/kb/revenue-model/. [[mercury-design-system]] [[codemojex-program]]
