# cm-tma.1 — Stories (the acceptance face)

> The Operator's verifiable acceptance for **cm-tma.1**, derived from [`cm-tma.1.md`](./cm-tma.1.md) (the body
> wins on any disagreement). The model is the **self-contained edge build**: the codemojex front end in
> `echo/apps/codemojex/assets/` becomes its own **pnpm** workspace (`@codemojex/edge`; the Phoenix client libs
> vendored under `packages/*` as `@echo/phoenix` + `@echo/phoenix_live_view`), the build runs at a modern
> **es2024** target, the vendored packages' suites run on **vitest** (the upstream **jest** retired), the edge
> image builds from a **self-contained `assets/` context** (no umbrella, no `deps/`), the publish script lives
> at `assets/bin/edge-deploy.sh`, and the image's awscli installer is fetched from a **pre-staged**
> `edge.codemoji.games/dist/awscli-<awsarch>.zip`. Each story is Connextra + Given/When/Then; each names the
> invariant(s) it exercises and the surface that closes it. A gate must **exercise** its outcome — a no-op must
> not satisfy a story's letter.
>
> **npm is retired:** the package manager is **pnpm** everywhere (`pnpm install` / `pnpm install
> --frozen-lockfile` / `pnpm build`); the lockfile is `pnpm-lock.yaml`; there is no `package-lock.json`.
>
> **As-built / forward-tense split:** the vendored `packages/{phoenix,phoenix_live_view}` are **present on
> disk** and `assets/package.json` is already `@codemojex/edge` with `@echo/*` deps (present-tense). The
> `pnpm-workspace.yaml` + `pnpm-lock.yaml`, the es2024 root-build cutover, the LV `package.json` jest→vitest
> cleanup, the self-contained `Dockerfile`, the relocated `bin/edge-deploy.sh`, and the `dist/awscli-*`
> pre-stage are **forward-tense**. Framing: third person; no first-person-agent narration. As-built naming:
> `edge.codemoji.games` + the **game** bundle (`game-<hash>.js`) + `Codemojex.Edge.game_url/0` (not the
> narrative docs' stale `static.codemoji.games`/`board`).

## Roles

- **A front-end engineer** — builds and iterates the front end on a checkout. Wants
  `cd assets && pnpm install && pnpm dev` to work with **no umbrella and no `mix deps.get`**.
- **The Operator** — provisions the edge bucket + pre-stages the awscli zips, runs the edge deploy, and rules
  the file placement. Wants the edge image build to be **reliable inside Fly's network** and the publish
  surface self-contained.
- **The edge image** — the ephemeral one-shot Fly task (`codemojex-edge-deliver`) that builds the game bundle,
  uploads it immutable, flips the pointer, and exits. Builds from the `assets/` context alone, with pnpm.
- **`Codemojex.Edge`** — the engine's runtime resolver (`lib/codemojex/edge.ex`, `game_url/0`). Its pointer
  contract must hold **unchanged** across this rung.
- **A player** — loads the lobby and the game. Must see **identical behavior**: the `LiveSocket` connects and
  the React board mounts exactly as before the vendoring.

---

## S1 — Standalone front-end build (no umbrella, no `mix deps.get`)

*As a front-end engineer, I want to build the bundles on a plain checkout without the Elixir toolchain, so
that front-end iteration does not require the whole BEAM project.*

**Exercises:** INV-STANDALONE-DEV (A3); INV-PNPM (A14); the removal of the `file:../../../deps/*` coupling.
**Surface:** the pnpm workspace (`assets/pnpm-workspace.yaml` + `assets/package.json` `@echo/* : workspace:*`) +
`assets/packages/*`.

- **Given** a checkout where `echo/deps/` is absent (no `mix deps.get` has run)
- **When** `cd echo/apps/codemojex/assets && pnpm install && pnpm build && pnpm build:client`
- **Then** all commands succeed, nothing resolves a `../../../deps` path, and both bundles emit
  (`priv/static/game/game-<hash>.js` + `priv/static/assets/app.js`),
- **And** the **negative check:** with the pre-rung `file:../../../deps/*` `package.json`, an install against
  an absent `deps/` **fails** — proving the workspace is what removed the coupling.

## S2 — Dep-free `package.json`; pnpm workspace resolution to `packages/*`

*As the Operator, I want zero `file:../` links in the front-end manifest, so that the build context never
reaches outside `assets/`.*

**Exercises:** INV-DEP-FREE (A1); workspace resolution (A2); INV-PNPM (A14). **Surface:**
`assets/pnpm-workspace.yaml` (`packages: ["packages/*"]`) + `assets/package.json` (`@echo/* : workspace:*`) +
the committed `pnpm-lock.yaml`.

- **Given** the converted workspace
- **When** `grep -nE 'file:\.\.' echo/apps/codemojex/assets/package.json` runs, and `pnpm why @echo/phoenix
  @echo/phoenix_live_view` (and `pnpm ls -r`) is inspected after `pnpm install`
- **Then** the grep returns **0 matches**, no `package-lock.json` exists, and the two libs resolve to
  **`packages/*`** (linked in `node_modules/.pnpm`), not to `deps/` — and LV's bare `phoenix` resolves to the
  workspace `@echo/phoenix`.

## S3 — The vendored client is faithful: the lobby boots (THE headline)

*As a player, I want the lobby and board to work exactly as before the vendoring, so that swapping the Phoenix
client for the vendored TS packages is invisible to me.*

**Exercises:** INV-VENDORED-FAITHFUL (A4) — the one invariant a green build can still violate.
**Surface:** `assets/packages/{phoenix,phoenix_live_view}` exposing `Socket` + `LiveSocket` + the hook
lifecycle (`js/app.js:5-6,11-66`, the **scoped** `@echo/*` imports).

- **Given** the LiveView client built from the vendored packages (`pnpm build:client`)
- **When** the app serves it and a player opens the lobby
- **Then** `import { Socket } from "@echo/phoenix"` and `import { LiveSocket } from "@echo/phoenix_live_view"`
  resolved to `packages/*`, the `LiveSocket` **connects** (`window.liveSocket` live), and entering a room
  **mounts the game island** via the `EdgeReact` hook (`this.pushEvent` / `this.handleEvent` work),
- **And** the **runtime guard:** this is proven by a runtime boot smoke (the `node/codemojex-e2e` path or a
  headless `app.js` boot), **not** by a green `vite build` alone — a bundle that compiles but fails to connect
  MUST fail this story.

## S4 — The edge image builds from a self-contained `assets/` context

*As the Operator, I want the edge image to build from `assets/` alone, so that the build needs no umbrella
checkout and no `deps/`.*

**Exercises:** INV-SELF-CONTAINED-CONTEXT (A5); INV-PNPM (A14). **Surface:** the rewritten `assets/Dockerfile`
(no `deps/` COPYs; corepack/pnpm; `COPY . .`; `ENTRYPOINT bin/edge-deploy.sh`) + `assets/fly.toml`
(`dockerfile = "Dockerfile"`).

- **Given** the rewritten `assets/Dockerfile`
- **When** an image is built with context `apps/codemojex/assets`
  (`docker build apps/codemojex/assets -f apps/codemojex/assets/Dockerfile`, or the fly `--build-only`)
- **Then** the build succeeds copying nothing from outside `assets/`, and
  `grep -nE 'COPY +deps/|\.\./' assets/Dockerfile` returns **0**,
- **And** at runtime the entrypoint's `pnpm install --frozen-lockfile` resolves `@echo/*` from `packages/*`
  (no `deps/` present in the image, no `npm`).

## S5 — awscli pre-staged: the image fetches it reliably inside Fly

*As the Operator, I want the image's awscli installer to come from the edge bucket, so that the build does not
flake on an origin Fly's network cannot reliably reach.*

**Exercises:** INV-AWSCLI-PRESTAGED (A6). **Surface:** the Dockerfile awscli step
(`curl https://edge.codemoji.games/dist/awscli-${awsarch}.zip`) + the `dist/` uploads documented in
`edge-bucket-setup.md`.

- **Given** the awscli v2 zips pre-staged at `edge.codemoji.games/dist/awscli-x86_64.zip` and
  `…/awscli-aarch64.zip` (immutable cache)
- **When** the edge image builds (either arch)
- **Then** it fetches the installer from `edge.codemoji.games/dist/awscli-<awsarch>.zip`,
  `grep awscli.amazonaws.com assets/Dockerfile` returns **0**, and `edge-bucket-setup.md` documents the two
  uploads,
- **And** a public `curl -fsSI https://edge.codemoji.games/dist/awscli-x86_64.zip` returns **200** (verified
  after the Operator pre-stages).

## S6 — The publish script lives at `assets/bin/edge-deploy.sh` (approved); `--dry-run` is green

*As the Operator, I want the publish script under `assets/bin/`, so that the whole edge surface (Dockerfile,
fly.toml, script, inputs) lives in one self-contained tree.*

**Exercises:** the relocation (A7) + the reliability gate (A11) + INV-PNPM (A14). **Surface:**
`assets/bin/edge-deploy.sh` (moved from `scripts/`; `cd "$(dirname "$0")/.."`; `pnpm install
--frozen-lockfile && pnpm build`).

- **Given** the relocated script
- **When** `bin/edge-deploy.sh --dry-run` runs (from the `assets/` tree, env sourced)
- **Then** it `cd`s to `assets/`, builds the game bundle with **pnpm**, and prints the would-upload/would-flip
  plan **without** writing to the bucket; the old `apps/codemojex/scripts/edge-deploy.sh` no longer exists,
- **And** the script's build → upload-immutable → flip-pointer-last → verify contract (and `--rollback`) is
  byte-stable aside from the `cd`, the `npm`→`pnpm` swap, and the header doc-links.

## S7 — The pointer + swap ABI are unchanged (no player-visible change)

*As `Codemojex.Edge`, I want the manifest pointer and the bundle ABI to be exactly what I resolve today, so
that the engine needs no change and no player sees a difference.*

**Exercises:** INV-POINTER-UNCHANGED (A8) + the swap ABI (A9). **Surface:** `manifest.json` =
`{"game": …}` (short cache) + hashed files immutable; `src/index.tsx` `mount(el,props,bridge)` + `types.ts`
`GameProps`/`Bridge`.

- **Given** the rung complete
- **When** the engine resolves the pointer and a game mounts
- **Then** `git diff --stat lib/codemojex/edge.ex` is **empty**, `manifest.json` still names
  `https://edge.codemoji.games/game-<hash>.js` with the short cache, and `mount(el,props,bridge)` +
  `GameProps` + the bridge events (`game:update`/`guess_rejected`/`revealed`/`golden_win`) are byte-unchanged,
- **And** `pnpm build` still emits `game-<hash>.js` + a vite manifest.

## S8 — The engine + the boundary are untouched

*As the Operator, I want this rung confined to the front-end build surface, so that it carries zero risk to
the always-on engine.*

**Exercises:** INV-ENGINE-UNTOUCHED + the boundary (A10). **Surface:** the diff scope.

- **Given** the rung complete
- **When** the diff is reviewed
- **Then** `echo/Dockerfile`, `echo/fly.toml` (the always-on `codemoji.games` release), all of
  `lib/codemojex/**`, `mix.lock`, and every sibling umbrella app have **zero diff**,
- **And** the changes are confined to `echo/apps/codemojex/assets/**` +
  `echo/docs/edge-deliver/edge-bucket-setup.md` + `docs/codemojex-tma/specs/cm-tma.1.*`.
- **Note:** the in-`assets/` files that **do** change are expected — `js/app.js` (the `@echo/*` imports,
  already as-built), `tsconfig.json` + both vite configs (es2024), `package.json` + `pnpm-*.yaml`, and
  `@echo/phoenix_live_view`'s `package.json` (jest→vitest). `src/**` (the swap ABI) stays byte-unchanged.

## S9 — Modern es2024 target; the vendored suites run on vitest (jest retired)

*As a front-end engineer, I want the build at a modern es2024 target and the vendored packages tested on
vitest, so that the toolchain is current and the package behavior is pinned without the upstream jest.*

**Exercises:** INV-ES2024 (A12); INV-VITEST (A13). **Surface:** `assets/tsconfig.json` (`target`/`lib`) +
`assets/vite.config.ts` + `assets/vite.client.config.ts` (es2024); `packages/*/vitest.config.ts` +
`packages/*/test/*.test.ts`; `@echo/phoenix_live_view`'s cleaned `package.json`.

- **Given** the rung complete
- **When** `grep -rniE 'es2020' assets/tsconfig.json assets/vite.config.ts assets/vite.client.config.ts` runs,
  and `pnpm -C packages/phoenix test` + `pnpm -C packages/phoenix_live_view test` run, and
  `grep -rniE '\bjest\b' assets/packages` runs
- **Then** the es2020 grep returns **0** (all four sites name es2024), both vitest suites **pass**, and the
  jest grep returns **0** (no jest devDeps, scripts, or config remain — each package has a `vitest.config.ts`),
- **And** both bundles still build green at the new target (A3) and the lobby still boots (A4).
