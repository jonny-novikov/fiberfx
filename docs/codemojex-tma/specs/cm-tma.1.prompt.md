# cm-tma.1 · build runbook / next-session handoff

> The authoritative **run scope** for building cm-tma.1 (the self-contained edge build). The spec
> **body** [`cm-tma.1.md`](./cm-tma.1.md) wins on any disagreement; this runbook captures the
> half-finished `assets/` migration state so a fresh session finishes it without re-deriving. **Re-probe
> `echo/apps/codemojex/assets/` before editing** — the Operator changes that tree out-of-band, so every
> "as-built" line below is labelled by migration-state, not asserted as flat truth.

Repo: `/Users/jonny/dev/jonnify` · branch `echo_mq` · spec reconciled.

## State

- **Spec triad RECONCILED + committed**: `cm-tma.1.{md,stories.md,llms.md}` now
  specs a **pnpm** workspace (`@codemojex/edge`, npm retired), **TWO** vendored TS packages
  (`@echo/phoenix` + `@echo/phoenix_live_view`; `phoenix_html` **folded into LV**, not a 3rd package),
  **es2024** target, **jest→vitest**. The `.md` body is the source of truth.
- **Grounding doc** (committed separately this session): [`echo/docs/codemojex/phoenix-client-resolution.md`](../../../echo/docs/codemojex/phoenix-client-resolution.md)
  — upstream prebuilt-artifact resolution vs. vendored-source resolution; recommends resolving
  `phoenix_html` via a **subpath export** `@echo/phoenix_live_view/phoenix_html`.

## As-built reality (re-probe first — half-finished migration)

`echo/apps/codemojex/assets/`:

- `package.json`: already `@codemojex/edge` + pnpm engine + `@echo/*` deps (**no `file:` links**), but
  deps still use the npm-alias form `"phoenix":"@echo/phoenix"` — clean end-state is `@echo/*` keys with
  `"workspace:*"`.
- `packages/phoenix` (`@echo/phoenix` v1.8.8): **DONE** — vitest, dep-free, es2024.
- `packages/phoenix_live_view` (`@echo/phoenix_live_view` v1.2.3): `src/` + `vitest.config.ts` +
  `*.test.ts` present, es2024 — **BUT** `package.json` still ships the upstream **jest** toolchain +
  `js:test`/`e2e` scripts (`npm run`/`mix`) + stale `types`/`files`. Deps: `morphdom@2.7.8` + bare
  `phoenix` (5 src imports → needs alias `phoenix → workspace:@echo/phoenix@*`).
- Three **root** configs still **es2020**: `tsconfig.json` (`target`+`lib`), `vite.config.ts:24`,
  `vite.client.config.ts:11` (the package vite configs are already es2024).
- **MISSING** (forward-tense): `pnpm-workspace.yaml`, `pnpm-lock.yaml`, `assets/bin/`.
- `js/app.js` imports the **scoped** names; does **not** import `phoenix_html` → the
  data-method/confirm handler is **inert** today (acceptable for the current LiveView+React surface).
- `Dockerfile` + `fly.toml` + `scripts/edge-deploy.sh`: still umbrella-root form (`COPY deps/`, awscli
  from amazonaws.com, `Dockerfile.edge`, `npm ci`) — **not yet rewritten**.

## Next task (recommended: A)

**A. BUILD cm-tma.1** to the spec build brief (§16) + acceptance A1–A14:

1. `pnpm-workspace.yaml` (`packages: ["packages/*"]`) + `package.json` deps → `@echo/*:workspace:*` + LV
   declares `morphdom` + `phoenix`(`workspace:@echo/phoenix@*`); `pnpm install` → commit `pnpm-lock.yaml`.
2. **jest→vitest** cleanup on `@echo/phoenix_live_view/package.json` (drop jest, `test:"vitest"`, prune
   `npm`/`mix`/`e2e` scripts, fix `types`/`files`); `pnpm -C packages/* test` green; `grep jest packages` → 0.
3. **es2024** on the three root configs; `grep es2020` → 0.
4. **phoenix_html subpath export** (`exports "./phoenix_html":"./src/phoenix_html.ts"`) per
   `phoenix-client-resolution.md §4` — **and update the spec** to prescribe the subpath (it currently
   says "folded into LV" without the resolution mechanism).
5. **Self-contained Dockerfile** (context `assets/`, corepack pnpm, drop `deps/` COPY, awscli from
   `edge.codemoji.games/dist/`, `ENTRYPOINT bin/edge-deploy.sh`) + `fly.toml` (`dockerfile="Dockerfile"`).
6. **Relocate** `scripts/edge-deploy.sh` → `assets/bin/edge-deploy.sh` (cd fix; `npm`→`pnpm`; doc-links).
7. **awscli `dist/` pre-stage** step in `echo/docs/edge-deliver/edge-bucket-setup.md`.

**GATE = the FRONT-END gate (spec A1–A14), NOT the mix gate:** `cd assets`; `pnpm
install`/`build`/`build:client` with **no `echo/deps/` present**; **the runtime LiveSocket-boot smoke
(A4 — load-bearing; a green `vite build` is NOT sufficient; `node/codemojex-e2e` or a headless `app.js`
boot asserting `window.liveSocket` connects)**; grep gates (`file:..` / `es2020` / `jest` / `npm ci|run`
/ `COPY deps/` / `amazonaws` → 0); `bin/edge-deploy.sh --dry-run` green. May orchestrate via
`/codemojex-ship cm-tma.1`, but hold the FRONT-END gate above (the skill's mix gate does not apply).

**B.** Commit any remaining untracked supporting docs with a tight pathspec.

**C.** (separate engine track) ship **cm.8** — cash-out/treasury (the codemojex engine, mix gate).

## Constraints (load-bearing)

- **Boundary** = `echo/apps/codemojex/assets/**` + `echo/docs/edge-deliver/edge-bucket-setup.md` + the
  specs. **OUT:** `lib/codemojex/**`, `echo/Dockerfile`, `echo/fly.toml` (always-on engine release),
  sibling apps, `mix.lock`. The swap ABI (`src/index.tsx` + `types.ts`) stays **byte-unchanged**.
- **INV-VENDORED-FAITHFUL:** a faithful-looking phoenix/LV rewrite can compile green yet break the live
  lobby — A4's runtime boot smoke is the real gate.
- **Operator runs ALL deploys** (no `fly deploy`) — author files + the `--dry-run` gate only.
- **Commit pathspec-only** (never `git add -A`); **ask before push**; the tree is entangled (Operator
  works out-of-band) — verify `git diff --cached --name-only` is purely the rung first.
- **Sources of truth:** [`cm-tma.1.md`](./cm-tma.1.md) (body wins) ·
  [`echo/docs/codemojex/phoenix-client-resolution.md`](../../../echo/docs/codemojex/phoenix-client-resolution.md)
  · memory `MEMORY.md` "codemojex program" line.
