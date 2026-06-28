# cm-tma.1 — The self-contained edge build · agent brief (compact)

> The one-screen brief, derived from [`cm-tma.1.md`](./cm-tma.1.md) (**the body wins**). Acceptance:
> [`cm-tma.1.stories.md`](./cm-tma.1.stories.md). Framing: third person; **NO-INVENT** (every cite re-probed on
> disk). **npm is retired** — pnpm everywhere. As-built naming: `edge.codemoji.games` + the **game** bundle
> (`game-<hash>.js`) + `Codemojex.Edge.game_url/0` — **not** the narrative docs' stale
> `static.codemoji.games`/`board`/`assets/react`.

## What

Make the **edge game-bundle build self-contained and the front end developable on its own** by removing the
`file:../../../deps/phoenix*` coupling. **Vendor** the Phoenix client as TypeScript packages under
`assets/packages/*` — **two** packages, **`@echo/phoenix`** + **`@echo/phoenix_live_view`** (`phoenix_html`
folded into LV as `src/phoenix_html.ts`, resolved via the subpath export `@echo/phoenix_live_view/phoenix_html`,
**no standalone package**) — make `assets/` a **pnpm** workspace
(`@codemojex/edge`), move the build to a modern **es2024** target, run the vendored packages' suites on
**vitest** (the upstream **jest** retired), and **relocate the edge build into `assets/`** (`Dockerfile`,
`fly.toml`, `bin/edge-deploy.sh`) so the edge image builds from a **self-contained `assets/` context** — no
umbrella, no `echo/deps/`, no `file:../` links, no npm. Also fetch the image's awscli installer from a
**pre-staged** `edge.codemoji.games/dist/awscli-<awsarch>.zip` (reliable inside Fly) instead of
`awscli.amazonaws.com`. The engine (`lib/codemojex/**`), the runtime resolver `Codemojex.Edge`, the manifest
pointer, the swap ABI, and the always-on engine release stay **unchanged**.

**As-built (re-probed):** the packages are **prepared on disk** and `assets/package.json` is already
`@codemojex/edge` with `@echo/*` deps + a pnpm engine. This rung **completes** the wiring: `pnpm-workspace.yaml`
+ `pnpm-lock.yaml`, the es2024 root-config cutover, the LV `package.json` jest→vitest+pnpm cleanup, the
Dockerfile/fly.toml rewrite, the `bin/` relocation, and the awscli docs.

## References (read first)

- **The narrative why (stale naming, read for intent):** [`codemoji.static-edge.md`](../codemoji.static-edge.md)
  — the edge-vs-embedded rationale (uses `static.codemoji.games`/`board`; the as-built is
  `edge.codemoji.games`/`game`).
- **The bucket setup (this rung extends it):** [`echo/docs/edge-deliver/edge-bucket-setup.md`](../../../echo/docs/edge-deliver/edge-bucket-setup.md)
  — the public Tigris bucket at `edge.codemoji.games`, `TIGRIS_EDGE_*`, deploy + rollback. **Gains** the
  awscli `dist/` pre-stage step.
- **The as-built front end (re-probe before editing):** `assets/package.json` (`@codemojex/edge`, pnpm engine,
  `@echo/*` deps), `assets/js/app.js:5-6,62-67` (the ONLY phoenix consumer — `Socket`/`LiveSocket` via the
  **scoped** `@echo/*` imports + the hook lifecycle), `assets/src/index.tsx:5-9` (the game bundle —
  `mount(el,props,bridge)`, **no phoenix**), `assets/src/types.ts` (`GameProps`/`Bridge`), `assets/vite.config.ts`
  (game → `../priv/static/game`, `target:es2020`), `assets/vite.client.config.ts` (LiveView →
  `../priv/static/assets`, `target:es2020`), `assets/tsconfig.json` (`target:ES2020`).
- **The vendored packages (present):** `assets/packages/phoenix` = `@echo/phoenix` v1.8.8 (vitest, dep-free);
  `assets/packages/phoenix_live_view` = `@echo/phoenix_live_view` v1.2.3 (deps `morphdom` + bare `phoenix`;
  `src/phoenix_html.ts`; vitest.config.ts + `*.test.ts` present but `package.json` still ships the upstream
  jest toolchain + `npm run` scripts).
- **The edge artifacts to rewrite/move:** `assets/Dockerfile` (`:23-32` awscli, `:39-41` `COPY deps/`,
  `:51` ENTRYPOINT), `assets/fly.toml` (`:24` `dockerfile = "Dockerfile.edge"`),
  `apps/codemojex/scripts/edge-deploy.sh` (`:91` `cd ../assets`, `:93-94` `npm ci && npm run build`).
- **Unchanged contract:** `lib/codemojex/edge.ex` (`game_url/0`, the pointer, 10s TTL, `GAME_ASSET_URL`
  fallback).

## Requirements (each → a story → an invariant)

1. Vendor `@echo/phoenix` + `@echo/phoenix_live_view` under `assets/packages/*`, preserving the §5 public
   surface (`Socket`; `LiveSocket` + the hook lifecycle; `phoenix_html` side-effects via LV's
   `src/phoenix_html.ts`, exposed as the subpath `@echo/phoenix_live_view/phoenix_html` — kept inert, `app.js`
   unchanged). → S3 / A4 (INV-VENDORED-FAITHFUL — the load-bearing one).
2. Make `assets/` a **pnpm** workspace — add `pnpm-workspace.yaml` (`packages: ["packages/*"]`); convert
   `assets/package.json` deps to `@echo/* : workspace:*`; commit `pnpm-lock.yaml`; no `package-lock.json`. →
   S1, S2, S4 / A1, A2, A3, A14 (INV-DEP-FREE, INV-STANDALONE-DEV, INV-PNPM).
3. Complete the **jest→vitest** migration on `@echo/phoenix_live_view`'s `package.json` (drop jest devDeps;
   `test: "vitest"`; prune the `npm run`/`mix`/`e2e` scripts; fix `types`/`files`). **Shipped:** the package.json
   is jest-free; **A13 (both suites green) is DEFERRED to cm-tma.2** — the `test/*.test.ts` files remain unported
   upstream jest. → S9 / A13 (INV-VITEST).
4. Move the build to **es2024** — `assets/tsconfig.json` (`target`+`lib`) + `assets/vite.config.ts` +
   `assets/vite.client.config.ts` (es2020 → es2024). → S9 / A12 (INV-ES2024).
5. Rewrite `assets/Dockerfile` self-contained — context `assets/`; corepack/pnpm; drop the three
   `COPY deps/phoenix*`; `COPY . .`; `ENTRYPOINT bin/edge-deploy.sh`. Update `assets/fly.toml`
   (`dockerfile = "Dockerfile"`; the deploy command). → S4 / A5 (INV-SELF-CONTAINED-CONTEXT).
6. awscli from the edge bucket — Dockerfile fetches `https://edge.codemoji.games/dist/awscli-${awsarch}.zip`
   (not amazonaws.com); document the two `dist/awscli-<awsarch>.zip` uploads in `edge-bucket-setup.md`. →
   S5 / A6 (INV-AWSCLI-PRESTAGED).
7. Relocate `scripts/edge-deploy.sh` → `assets/bin/edge-deploy.sh` (APPROVED); fix the `cd`
   (`../assets` → `..`); `npm ci && npm run build` → `pnpm install --frozen-lockfile && pnpm build`; fix the
   header doc-links; the build→upload→flip→verify contract byte-stable. → S6 / A7, A11.
8. Hold the unchanged contracts — `Codemojex.Edge.game_url/0` + the `manifest.json {"game":…}` pointer + the
   cache policy + the `mount(el,props,bridge)`/`GameProps`/bridge-events ABI + the engine release +
   `mix.lock`. → S7, S8 / A8, A9, A10.

## Execution topology + build order (smallest-change first; packages already prepared)

1. **Workspace** — `assets/pnpm-workspace.yaml` (`packages/*`); `assets/package.json` deps → `@echo/* :
   workspace:*`; `@echo/phoenix_live_view` declares `morphdom` + `phoenix` (`workspace:@echo/phoenix@*`);
   `pnpm install` → commit `pnpm-lock.yaml`. (A1/A2/A14)
2. **jest→vitest** — clean `@echo/phoenix_live_view`'s `package.json` (drop jest; `test: "vitest"`; prune
   `npm run`/`mix`/`e2e`; fix `types`/`files`); `pnpm -C packages/* test` green; `grep jest packages` → 0. (A13)
3. **es2024** — `assets/tsconfig.json` + both root vite configs (es2020 → es2024); `grep es2020` → 0. (A12)
4. **Prove standalone** — `rm -rf node_modules && pnpm install && pnpm build && pnpm build:client` with no
   `deps/` reachable (A1/A2/A3), then the **runtime boot smoke** (A4 — `node/codemojex-e2e` or a headless
   `app.js` boot asserting `window.liveSocket` connects). This is the gate the build alone cannot give.
5. **Self-contained image** — rewrite `assets/Dockerfile` (corepack/pnpm; drop `deps/` COPYs; awscli from edge
   `dist/`; `ENTRYPOINT bin/edge-deploy.sh`); update `assets/fly.toml` (A5/A6).
6. **Relocate** `scripts/edge-deploy.sh` → `assets/bin/edge-deploy.sh` (fix `cd`; npm→pnpm; doc-links) (A7).
7. **Pre-stage docs** — add the awscli `dist/` upload step to `edge-bucket-setup.md` (A6); the upload itself
   is the Operator's.
8. **Gate** — A1–A14; the `--dry-run` + fly `--build-only` reliability gate (A11) is the canonical green; the
   boundary check (A10) proves the engine + `lib/` + `mix.lock` untouched.

**Files** (boundary `echo/apps/codemojex/assets/**` + the bucket doc + these specs): `pnpm-workspace.yaml` +
`pnpm-lock.yaml` (new) · `package.json` (workspace finish) · `packages/phoenix_live_view/package.json`
(jest→vitest + pnpm) · `tsconfig.json` + `vite.config.ts` + `vite.client.config.ts` (es2024) · `Dockerfile`
(rewrite) · `fly.toml` (rewrite) · `bin/edge-deploy.sh` (moved from `scripts/`, with the `cd`+pnpm fix) ·
`echo/docs/edge-deliver/edge-bucket-setup.md` (the awscli pre-stage step). **Unchanged:** `js/app.js` (already
on `@echo/*`), `src/**` (the swap ABI), `lib/codemojex/edge.ex`, `echo/Dockerfile`, `echo/fly.toml`, `mix.lock`.

## Cite-map (every surface → its real file)

| Surface | File / site |
|---|---|
| the coupling removed | `assets/package.json` `file:../../../deps/phoenix*` (pre-rung) → `@echo/* : workspace:*` |
| the host workspace | `assets/package.json:2` (`@codemojex/edge`), `:6-9` (pnpm engine), `:16-17` (`@echo/*` deps) |
| the vendored libs | `assets/packages/phoenix` (`@echo/phoenix` v1.8.8, vitest) · `assets/packages/phoenix_live_view` (`@echo/phoenix_live_view` v1.2.3, `morphdom`+bare `phoenix`, `src/phoenix_html.ts`, jest→vitest pending) |
| the only phoenix consumer | `assets/js/app.js:5-6` (`@echo/phoenix`/`@echo/phoenix_live_view` imports), `:62-67` (`new LiveSocket("/live", Socket, {hooks:{EdgeReact}})` + `connect`) |
| LV → phoenix (internal) | `packages/phoenix_live_view/src/*.ts` bare `from "phoenix"` — **2 real imports** (`view.ts:1` value `Channel` + `live_socket.ts:1` type-only `Socket`; 3 JSDoc) + `from "morphdom"` (2 files) |
| the game bundle (no phoenix) | `assets/src/index.tsx:5-9` (`mount(el,props,bridge)`); the ABI `assets/src/types.ts` (`GameProps`/`Bridge`) |
| the es2024 laggards | `assets/tsconfig.json:3,5` · `assets/vite.config.ts:24` · `assets/vite.client.config.ts:11` (all `es2020`) |
| the edge image | `assets/Dockerfile` (`:23-32` awscli, `:39-41` `COPY deps/`, `:51` ENTRYPOINT) |
| the edge task | `assets/fly.toml:24` (`dockerfile`) |
| the publish script | `apps/codemojex/scripts/edge-deploy.sh:91-94` → `assets/bin/edge-deploy.sh` |
| the runtime resolver (unchanged) | `lib/codemojex/edge.ex` (`game_url/0`, pointer 10s TTL) |
| the bucket setup (extended) | `echo/docs/edge-deliver/edge-bucket-setup.md` (+ the `dist/awscli-*` pre-stage) |

## Gate ladder (front-end build surface — NOT the umbrella mix gate; pnpm, npm retired)

`cd echo/apps/codemojex/assets` · `grep -nE 'file:\.\.' package.json` → **0** (A1) · `pnpm install` resolves
`@echo/*` to `packages/*`, no `package-lock.json` (A2/A14) · `pnpm build` + `pnpm build:client` green with **no
`echo/deps/` present** (A3) · the **runtime boot smoke** — the `LiveSocket` connects + the game island mounts
(A4, the load-bearing check; a green `vite build` is **not** sufficient) · `grep -rniE 'es2020' tsconfig.json
vite.config.ts vite.client.config.ts` → **0** (A12) · (A13 — **DEFERRED to cm-tma.2**: package.json jest-free but `test/*.test.ts` unported; target `pnpm -C
packages/* test` green + `grep '\bjest\b' packages` → 0) · `grep -nE 'COPY +deps/|\.\./' Dockerfile` → **0** + a build with context
`apps/codemojex/assets` succeeds (A5) · `grep awscli.amazonaws.com Dockerfile` → **0**, `grep
edge.codemoji.games/dist/awscli Dockerfile` → present (A6) · `bin/edge-deploy.sh --dry-run` green + the old
`scripts/edge-deploy.sh` gone (A7/A11) · `grep -rniE 'npm ci|npm run|npm install' Dockerfile bin/` → **0**
(A14) · `git diff --stat lib/codemojex/edge.ex echo/Dockerfile echo/fly.toml mix.lock` → empty (A8/A10) · the
swap ABI byte-unchanged (A9). **Risk:** NORMAL build-tooling with ONE high-stakes runtime invariant (A4 —
adversarially verify the lobby boots; a faithful-looking rewrite can break the live socket gate-invisibly).
**Boundary:** `echo/apps/codemojex/assets/**` + the bucket doc + these specs; the engine + the engine release +
sibling apps untouched; provisioning/deploy is the Operator's.
