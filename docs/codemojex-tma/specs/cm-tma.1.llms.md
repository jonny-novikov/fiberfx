# cm-tma.1 — The self-contained edge build · agent brief (compact)

> The one-screen brief, derived from [`cm-tma.1.md`](./cm-tma.1.md) (**the body wins**). Acceptance:
> [`cm-tma.1.stories.md`](./cm-tma.1.stories.md). Framing: third person; **forward-tense** for the unbuilt
> surface; **NO-INVENT** (every cite re-probed on disk). As-built naming: `edge.codemoji.games` + the **game**
> bundle (`game-<hash>.js`) + `Codemojex.Edge.game_url/0` — **not** the narrative docs' stale
> `static.codemoji.games`/`board`/`assets/react`.

## What

Make the **edge game-bundle build self-contained and the front end developable on its own** by removing the
`file:../../../deps/phoenix*` coupling in `echo/apps/codemojex/assets/package.json` (`:11-14`). **Vendor**
`phoenix` / `phoenix_html` / `phoenix_live_view` as dependency-free **TypeScript** packages under
`assets/packages/*`, make `assets/` the npm **workspace root**, and **relocate the edge build into `assets/`**
(`Dockerfile`, `fly.toml`, `bin/edge-deploy.sh`) so the edge image builds from a **self-contained `assets/`
context** — no umbrella, no `echo/deps/`, no `file:../` links. Also fetch the image's awscli installer from a
**pre-staged** `edge.codemoji.games/dist/awscli-<awsarch>.zip` (reliable inside Fly) instead of
`awscli.amazonaws.com`. The engine (`lib/codemojex/**`), the runtime resolver `Codemojex.Edge`, the manifest
pointer, the swap ABI, and the always-on engine release stay **unchanged**.

## References (read first)

- **The narrative why (stale naming, read for intent):** [`codemoji.static-edge.md`](../codemoji.static-edge.md)
  — the edge-vs-embedded rationale (uses `static.codemoji.games`/`board`; the as-built is
  `edge.codemoji.games`/`game`).
- **The bucket setup (this rung extends it):** [`echo/docs/edge-deliver/edge-bucket-setup.md`](../../../echo/docs/edge-deliver/edge-bucket-setup.md)
  — the public Tigris bucket at `edge.codemoji.games`, `TIGRIS_EDGE_*`, deploy + rollback. **Gains** the
  awscli `dist/` pre-stage step.
- **The as-built front end (re-probe before editing):** `assets/package.json:6-14` (scripts + the `file:`
  deps), `assets/js/app.js:5-6,62-67` (the ONLY phoenix consumer — `Socket` + `LiveSocket` + the hook
  lifecycle), `assets/src/index.tsx:5-9` (the game bundle — `mount(el,props,bridge)`, **no phoenix**),
  `assets/src/types.ts` (`GameProps`/`Bridge`), `assets/vite.config.ts` (game → `../priv/static/game`),
  `assets/vite.client.config.ts` (LiveView → `../priv/static/assets`).
- **The edge artifacts to rewrite/move:** `assets/Dockerfile` (`:23-32` awscli, `:39-41` `COPY deps/`,
  `:51` ENTRYPOINT), `assets/fly.toml` (`:24` `dockerfile = "Dockerfile.edge"`),
  `apps/codemojex/scripts/edge-deploy.sh` (`:91` `cd ../assets`, `:93-94` `npm ci && npm run build`).
- **Unchanged contract:** `lib/codemojex/edge.ex` (`game_url/0`, the pointer, 10s TTL, `GAME_ASSET_URL`
  fallback).

## Requirements (each → a story → an invariant)

1. Vendor `phoenix` / `phoenix_html` / `phoenix_live_view` as dep-free TS packages under `assets/packages/*`,
   preserving the §5 public surface (`Socket`; `LiveSocket` + the hook lifecycle; `phoenix_html`
   side-effects). → S3 / A4 (INV-VENDORED-FAITHFUL — the load-bearing one).
2. Convert `assets/package.json` to an npm workspace (`"workspaces": ["packages/*"]`; `phoenix*` → `"*"`);
   regenerate `package-lock.json`. → S1, S2 / A1, A2, A3 (INV-DEP-FREE, INV-STANDALONE-DEV).
3. Rewrite `assets/Dockerfile` self-contained — context `assets/`; drop the three `COPY deps/phoenix*`;
   `COPY . .`; `ENTRYPOINT bin/edge-deploy.sh`. Update `assets/fly.toml` (`dockerfile = "Dockerfile"`; the
   deploy command). → S4 / A5 (INV-SELF-CONTAINED-CONTEXT).
4. awscli from the edge bucket — Dockerfile fetches `https://edge.codemoji.games/dist/awscli-${awsarch}.zip`
   (not amazonaws.com); document the two `dist/awscli-<awsarch>.zip` uploads in `edge-bucket-setup.md`. →
   S5 / A6 (INV-AWSCLI-PRESTAGED).
5. Relocate `scripts/edge-deploy.sh` → `assets/bin/edge-deploy.sh` (APPROVED); fix the `cd`
   (`../assets` → `..`) + the header doc-links; the build→upload→flip→verify contract byte-stable. → S6 /
   A7, A11.
6. Hold the unchanged contracts — `Codemojex.Edge.game_url/0` + the `manifest.json {"game":…}` pointer + the
   cache policy + the `mount(el,props,bridge)`/`GameProps`/bridge-events ABI + the engine release +
   `mix.lock`. → S7, S8 / A8, A9, A10.

## Execution topology + build order (smallest-change first)

1. **Vendor** `assets/packages/{phoenix,phoenix_html,phoenix_live_view}/` — TS, dependency-free; each
   `package.json` `name` = the bare specifier; basis = the upstream client in `deps/`, re-expressed in TS to
   the §5 surface.
2. **Workspace** — `assets/package.json` (`"workspaces"`, `phoenix*` → `"*"`); regenerate `package-lock.json`.
3. **Prove standalone** — `rm -rf node_modules && npm install && npm run build && npm run build:client` with
   no `deps/` reachable (A1/A2/A3), then the **runtime boot smoke** (A4 — `node/codemojex-e2e` or a headless
   `app.js` boot asserting `window.liveSocket` connects). This is the gate the build alone cannot give.
4. **Self-contained image** — rewrite `assets/Dockerfile` (drop `deps/` COPYs; awscli from edge `dist/`;
   `ENTRYPOINT bin/edge-deploy.sh`); update `assets/fly.toml` (A5/A6).
5. **Relocate** `scripts/edge-deploy.sh` → `assets/bin/edge-deploy.sh` (fix `cd` + doc-links) (A7).
6. **Pre-stage docs** — add the awscli `dist/` upload step to `edge-bucket-setup.md` (A6); the upload itself
   is the Operator's.
7. **Gate** — A1–A11; the `--dry-run` + fly `--build-only` reliability gate (A11) is the canonical green; the
   boundary check (A10) proves the engine + `lib/` + `mix.lock` untouched.

**Files** (boundary `echo/apps/codemojex/assets/**` + the bucket doc + these specs): `packages/*` (new) ·
`package.json` + `package-lock.json` (workspace) · `Dockerfile` (rewrite) · `fly.toml` (rewrite) ·
`bin/edge-deploy.sh` (moved from `scripts/`, with the `cd` fix) · `echo/docs/edge-deliver/edge-bucket-setup.md`
(the awscli pre-stage step). **Unchanged:** `js/app.js`, `src/**`, `vite.config.ts`, `vite.client.config.ts`,
`tsconfig.json`, `lib/codemojex/edge.ex`, `echo/Dockerfile`, `echo/fly.toml`, `mix.lock`.

## Cite-map (every surface → its real file)

| Surface | File / site |
|---|---|
| the coupling removed | `assets/package.json:11-14` (`file:../../../deps/phoenix*`) → workspace `"*"` |
| the only phoenix consumer | `assets/js/app.js:5-6` (`Socket`/`LiveSocket` imports), `:62-67` (`new LiveSocket("/live", Socket, {hooks:{EdgeReact}})` + `connect`) |
| the game bundle (no phoenix) | `assets/src/index.tsx:5-9` (`mount(el,props,bridge)`); the ABI `assets/src/types.ts` (`GameProps`/`Bridge`) |
| the edge image | `assets/Dockerfile` (`:23-32` awscli, `:39-41` `COPY deps/`, `:51` ENTRYPOINT) |
| the edge task | `assets/fly.toml:24` (`dockerfile`) |
| the publish script | `apps/codemojex/scripts/edge-deploy.sh:91-94` → `assets/bin/edge-deploy.sh` |
| the runtime resolver (unchanged) | `lib/codemojex/edge.ex` (`game_url/0`, pointer 10s TTL) |
| the bucket setup (extended) | `echo/docs/edge-deliver/edge-bucket-setup.md` (+ the `dist/awscli-*` pre-stage) |

## Gate ladder (front-end build surface — NOT the umbrella mix gate)

`cd echo/apps/codemojex/assets` · `grep -nE 'file:\.\.' package.json` → **0** (A1) · `npm install` resolves
`phoenix*` to `packages/*` (A2) · `npm run build` + `npm run build:client` green with **no `echo/deps/`
present** (A3) · the **runtime boot smoke** — the `LiveSocket` connects + the game island mounts (A4, the
load-bearing check; a green `vite build` is **not** sufficient) · `grep -nE 'COPY +deps/|\.\./' Dockerfile` →
**0** + a build with context `apps/codemojex/assets` succeeds (A5) · `grep awscli.amazonaws.com Dockerfile` →
**0**, `grep edge.codemoji.games/dist/awscli Dockerfile` → present (A6) · `bin/edge-deploy.sh --dry-run` green +
the old `scripts/edge-deploy.sh` gone (A7/A11) · `git diff --stat lib/codemojex/edge.ex echo/Dockerfile
echo/fly.toml mix.lock` → empty (A8/A10) · the swap ABI byte-unchanged (A9). **Risk:** NORMAL build-tooling
with ONE high-stakes runtime invariant (A4 — adversarially verify the lobby boots; a faithful-looking rewrite
can break the live socket gate-invisibly). **Boundary:** `echo/apps/codemojex/assets/**` + the bucket doc +
these specs; the engine + the engine release + sibling apps untouched; provisioning/deploy is the Operator's.
