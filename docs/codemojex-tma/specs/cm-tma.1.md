# cm-tma.1 — The self-contained edge build (vendor `phoenix*` as TS under `assets/packages/` · self-contained Docker context · awscli pre-staged)

> The first **codemojex-tma** (Telegram Mini App / front-end tier) spec rung. It does not touch the game
> engine (`lib/codemojex/**`) or the always-on engine release — it makes the **edge game-bundle build**
> reliable and the **front end developable on its own**, by removing the one coupling that drags the whole
> umbrella into the front-end build: the `file:../../../deps/phoenix*` npm links.
>
> The **body wins** on any disagreement with the brief ([`cm-tma.1.llms.md`](./cm-tma.1.llms.md)) or the
> stories ([`cm-tma.1.stories.md`](./cm-tma.1.stories.md)). **Forward-tense** for the unbuilt surface (the
> vendored `packages/*`, the self-contained `Dockerfile`, the relocated `bin/edge-deploy.sh`).
> **NO-INVENT:** every file/line cited below was re-probed on disk; an unbuilt path is named forward-tense,
> never asserted as present. Framing: third person; no first-person-agent narration.
>
> **Grounding caveat (doc drift):** the narrative docs [`codemoji.static-edge.md`](../codemoji.static-edge.md)
> and [`codemojex-tma.roadmap.md`](../codemojex-tma.roadmap.md) still say `static.codemoji.games` + `board` +
> `assets/react/`. The **as-built** (and this rung) use `edge.codemoji.games` + the **game** bundle
> (`game-<hash>.js`) + `Codemojex.Edge.game_url/0` + `assets/src/`. This spec grounds in the as-built; the
> narrative docs are stale and out of scope here.

## 1. The rung in one paragraph

The codemojex front end lives in `echo/apps/codemojex/assets/` and builds **two** independent bundles with
vite: the **LiveView client** (`js/app.js` → `priv/static/assets`, via `vite.client.config.ts`) and the
**edge React game** (`src/index.tsx` → `priv/static/game`, via `vite.config.ts`). `assets/package.json`
declares `phoenix` / `phoenix_html` / `phoenix_live_view` as `file:../../../deps/phoenix*` — Elixir-managed
dependency directories reached by climbing three levels out of `assets/`. That single fact forces the edge
Docker build context to the **umbrella root** (so `echo/deps/` is reachable), makes `npm ci` require a prior
`mix deps.get`, and blocks anyone from building or iterating the front end without the whole BEAM project on
disk — even though the **edge game bundle imports none of the three** (`src/index.tsx` is pure React). This
rung **vendors** the three Phoenix client libraries as dependency-free TypeScript packages under
`assets/packages/`, turns `assets/` into the npm **workspace root**, and **relocates the edge build artifacts
into `assets/`** (`Dockerfile`, `fly.toml`, `bin/edge-deploy.sh`) so the edge image builds from a
**self-contained `assets/` context** with no umbrella, no `deps/`, and no `file:../` links. It also makes the
edge image's awscli download reliable inside Fly's network by fetching a **pre-staged** bundle from the edge
bucket itself (`edge.codemoji.games/dist/awscli-<awsarch>.zip`) instead of the public AWS origin.

## 2. The problem (what is broken today)

`assets/package.json:11-14` (re-probed):

```json
"dependencies": {
  "phoenix":           "file:../../../deps/phoenix",
  "phoenix_html":      "file:../../../deps/phoenix_html",
  "phoenix_live_view": "file:../../../deps/phoenix_live_view",
  "react": "^18.3.1", "react-dom": "^18.3.1"
}
```

Four failures follow, each load-bearing:

1. **The build context cannot be `assets/`.** `assets/Dockerfile:36-41` must `COPY deps/phoenix deps/phoenix`
   (×3) into the image so `npm ci` resolves the `file:../../../deps/*` links, which is only possible if the
   Docker build context is the **umbrella root** `echo/`. The Dockerfile's own comment says it plainly:
   *"Replicate the umbrella layout so `assets/package.json`'s `file:../../../deps/*` resolve at `npm ci` time."*
2. **`npm ci` requires the Elixir toolchain to have run.** `echo/deps/phoenix*` only exists after
   `mix deps.get` — so the front-end build inherits a hard dependency on a BEAM step it does not use.
3. **The front end is not developable standalone.** A designer or front-end engineer cannot
   `cd assets && npm install && npm run dev` on a checkout without the umbrella + `mix deps.get` — `npm`
   fails to resolve the `file:` links.
4. **Dead weight on the hot path.** The edge **game** bundle (`src/index.tsx`, re-probed lines 5-7) imports
   only `react-dom/client` + `@/GameEdge` + `@/types` — **no phoenix**. The three Phoenix file-deps exist
   solely for the **LiveView client** (`js/app.js:5-6`), yet `npm ci` validates every declared dependency, so
   they tax the game-bundle image build for nothing (the Dockerfile comment admits *"the game bundle imports
   none of them, but `npm ci` validates every dependency"*).

A fifth, independent reliability gap: `assets/Dockerfile:23-32` fetches the AWS CLI v2 zip from
`https://awscli.amazonaws.com/awscli-exe-linux-<awsarch>.zip` at image-build time. That public origin is **not
reliably reachable from inside Fly's build/runtime network**, so the edge image build is flaky for a reason
unrelated to the app.

## 3. Ground truth (re-probed on disk — cite the file:line; the as-built wins)

| Fact | Where (re-probed) |
|---|---|
| The two build graphs | `assets/package.json:6-9` — `build` = `vite build` (game, `vite.config.ts`); `build:client` = `vite build --config vite.client.config.ts` (LiveView); `dev` = `build:client --watch` |
| The game bundle | `assets/vite.config.ts` — input `src/index.tsx` (`:26`), `@`→`./src` alias (`:18`), `outDir ../priv/static/game` (`:21`), `manifest: true`, `game-[hash].js` (`:29`) |
| The LiveView client | `assets/vite.client.config.ts` — input `js/app.js` (`:13`), `outDir ../priv/static/assets` (`:9`), iife `app.js` |
| The ONLY phoenix consumer | `assets/js/app.js:5-6` — `import { Socket } from "phoenix"` + `import { LiveSocket } from "phoenix_live_view"`; boots `new LiveSocket("/live", Socket, { params, hooks: { EdgeReact } })` + `liveSocket.connect()` (`:62-67`) |
| The game = no phoenix | `assets/src/index.tsx:5-9` — `react-dom/client` + `@/GameEdge` + `@/types`; exports `mount(el, props, bridge)` returning `{update, unmount}` |
| The swap contract | `assets/src/types.ts` — `GameProps` (`view`/`leaderboard`/`history`/`me`) + `Bridge` (`pushEvent`/`onServerEvent`); kept in lockstep with `GameLive.game_props/3` |
| The edge Dockerfile | `assets/Dockerfile` — `node:22-bookworm-slim`; awscli from amazonaws.com (`:23-32`); `COPY deps/phoenix*` (`:39-41`); `COPY apps/codemojex/{assets,scripts}` (`:44-45`); `ENTRYPOINT ["/app/apps/codemojex/scripts/edge-deploy.sh"]` (`:51`) |
| The edge fly config | `assets/fly.toml` — app `codemojex-edge-deliver`, region `fra`, a TASK (no `[[services]]`); `[build] dockerfile = "Dockerfile.edge"` (`:24`, **stale name**); deploy-from-umbrella-root command in the header (`:12-16`) |
| The publish script | `apps/codemojex/scripts/edge-deploy.sh` — `cd "$(dirname "$0")/../assets"` (`:91`); `npm ci && npm run build` (`:93-94`); `OUT=../priv/static/game` (`:95`); upload `game-*` immutable (`:113-128`); flip `manifest.json` short-cache LAST (`:63-73`,`:130-132`); `--dry-run` / `--rollback`; HOST default `edge.codemoji.games` (`:47`) |
| The runtime resolver | `lib/codemojex/edge.ex` — `Codemojex.Edge.game_url/0` GETs `https://${GAME_EDGE_HOST}/manifest.json` (`%{"game"=>url}`), `:persistent_term` 10s TTL, falls back to `GAME_ASSET_URL`. **Unchanged by this rung.** |
| The bucket setup | `echo/docs/edge-deliver/edge-bucket-setup.md` — the public Tigris bucket at `edge.codemoji.games`; `TIGRIS_EDGE_*` env; the deploy + rollback steps |
| The engine release (separate) | `echo/Dockerfile` + `echo/fly.toml` — the always-on `codemoji.games` machine. **Out of scope; untouched.** |

**In-progress move (re-probed this session):** the Operator has begun the relocation — `assets/Dockerfile`
and `assets/fly.toml` already exist (copied from the umbrella-root `Dockerfile.edge` / `fly.edge.toml`), and
`assets/packages/` exists but is **empty**. But the moved files are **not yet rewritten**: `assets/Dockerfile`
still `COPY deps/phoenix*` + still pulls awscli from amazonaws.com + still `ENTRYPOINT`s the `scripts/` path;
`assets/fly.toml` still names `Dockerfile.edge`; `assets/package.json` still has the `file:../../../deps/*`
links. This rung **completes** that move to the end state below.

## 4. The target layout — `assets/` is the npm workspace root; `packages/*` are the vendored libs

```
echo/apps/codemojex/assets/            ← the npm workspace ROOT + the edge Docker build context
  packages/
    phoenix/             package.json (name "phoenix"),            src/…  (TS, dependency-free)
    phoenix_html/        package.json (name "phoenix_html"),       src/…
    phoenix_live_view/   package.json (name "phoenix_live_view"),  src/…
  bin/
    edge-deploy.sh       ← relocated from apps/codemojex/scripts/ (§7, APPROVED)
  js/app.js              ← imports the vendored libs by BARE name (unchanged source)
  src/                   ← the GameEdge React island (unchanged)
  Dockerfile             ← self-contained edge image (§6)
  fly.toml               ← edge task config (§6)
  package.json           ← "workspaces": ["packages/*"]; phoenix* deps → "*" (no file:../)
  package-lock.json      ← regenerated for the workspace
  tsconfig.json · vite.config.ts · vite.client.config.ts
```

**Why under `assets/` and not `apps/codemojex/packages/`:** `assets/` is already the workspace root
(`package.json`, `node_modules`, both vite configs, `tsconfig.json` live there). **npm workspaces require
every member to be a subdirectory of the root** — so `packages/` belongs at `assets/packages/`. Placing it at
the app root would force a `package.json` sibling to `mix.exs` (a JS workspace root jammed into the Elixir app
root) and widen the Docker context back out to include `lib/`/`priv/`/`test/`. `assets/packages/` keeps the
context the single self-contained `assets/` tree.

**The `package.json` conversion** (`assets/package.json:11-14`): replace the three `file:../../../deps/*`
entries with workspace references —

```json
"dependencies": {
  "phoenix": "*", "phoenix_html": "*", "phoenix_live_view": "*",
  "react": "^18.3.1", "react-dom": "^18.3.1"
},
"workspaces": ["packages/*"]
```

— so `npm install` symlinks `node_modules/{phoenix,phoenix_html,phoenix_live_view}` → `packages/*`, bare
specifiers resolve normally, and **no path escapes `assets/`**. `package-lock.json` is regenerated so
`npm ci` (the script + the image) installs the workspace deterministically.

## 5. The vendored packages — the faithfulness contract (the load-bearing invariant)

Each `packages/<lib>/` is a **dependency-free TypeScript** package whose `package.json` `name` matches the
bare specifier the source imports. The rewrite is faithful when it preserves **the exact public surface
`js/app.js` consumes** — this is the one place a green build can still ship a broken lobby, so the contract is
pinned here, not left to the build:

- **`phoenix`** — the named export **`Socket`** (the class), constructable as `new Socket("/live", opts)` and
  behaving as the transport `LiveSocket` drives. Surface used: `app.js:62` (`new LiveSocket("/live", Socket, …)`).
- **`phoenix_live_view`** — the named export **`LiveSocket`** (the class) with `connect()` and the **hook
  lifecycle** the `EdgeReact` hook relies on: `this.el`, `this.el.dataset`, `this.pushEvent(event, payload)`,
  `this.handleEvent(name, cb)` (returning an unsubscribe), and the `mounted()`/`destroyed()` callbacks.
  Surface used: `app.js:11-51,62-66`.
- **`phoenix_html`** — the import side-effects (the `data-confirm` / method-link behavior). Declared in
  `package.json` (validated by `npm ci`) even though `app.js` does not import it directly today; the vendored
  package must exist and be importable so the dep resolves and any future `import "phoenix_html"` works.

**INV-VENDORED-FAITHFUL:** after the swap, `import { Socket } from "phoenix"` and
`import { LiveSocket } from "phoenix_live_view"` resolve to `packages/*`, the LiveView client builds
(`npm run build:client`), and **the LiveSocket connects and the `EdgeReact` hook mounts the game island
exactly as before** (the lobby is live; the board loads). A build that compiles but breaks the runtime boot
**fails** this rung. The verify therefore includes a **runtime boot smoke**, not only a compile (§10 A4).

The basis for the rewrite is the upstream Phoenix JS client these `deps/` carry; the rung re-expresses that
surface in TS with no external dependencies. The internal implementation is the build's to choose; the
**contract above** is fixed.

## 6. The self-contained edge image — `assets/Dockerfile` + `assets/fly.toml`

**Build context becomes `echo/apps/codemojex/assets/`** (was the umbrella root). The rewritten
`assets/Dockerfile` (forward-tense target):

- `FROM node:22-bookworm-slim`; install `curl ca-certificates unzip bash` (as today).
- **awscli from the pre-staged bundle** (§8): `curl -fsSL "https://edge.codemoji.games/dist/awscli-${awsarch}.zip"`
  (arch-mapped `amd64→x86_64` / `arm64→aarch64`), unzip, `./aws/install`. **No** amazonaws.com.
- **Drop** the three `COPY deps/phoenix*` lines entirely.
- `WORKDIR /app`; `COPY . .` — the whole **self-contained** `assets/` tree (incl. `packages/` and `bin/`).
  Nothing outside `assets/` is referenced.
- `RUN chmod +x bin/edge-deploy.sh`; `ENTRYPOINT ["/app/bin/edge-deploy.sh"]`.

The image runs **no `npm` itself** — the script does `npm ci && npm run build` at runtime (as today). With
the workspace, `npm ci` resolves `phoenix*` from `packages/*` locally; nothing reaches for `deps/`. The game
build writes to `../priv/static/game` (relative to `assets/`), a scratch path created by vite inside the
ephemeral image, uploaded to the bucket, then discarded — so the `../priv` output never needs to pre-exist.

**`assets/fly.toml`** (forward-tense target): `[build] dockerfile = "Dockerfile"` (was `Dockerfile.edge`);
the header deploy command updates to the self-contained context —

```
fly deploy --build-only --push \
  -c apps/codemojex/assets/fly.toml \
  --dockerfile apps/codemojex/assets/Dockerfile \
  apps/codemojex/assets            # ← the build context is assets/, not the umbrella root
```

— app/region/VM/secrets unchanged (`codemojex-edge-deliver`, `fra`, the EDGE-bucket keypair only, no Fly
token). **The Operator runs the deploy** (the standing rule); this rung authors the files + the dry-run gate.

## 7. The publish script — relocate to `assets/bin/edge-deploy.sh` (APPROVED)

`apps/codemojex/scripts/edge-deploy.sh` **moves to `apps/codemojex/assets/bin/edge-deploy.sh`** so the entire
edge surface lives under the one self-contained `assets/` context (Dockerfile + fly.toml + script + inputs).
This placement is **ruled for this rung** (the Operator's directive). Required edits on the move:

- **The build `cd`** (`:91`): `cd "$(dirname "$0")/../assets"` → `cd "$(dirname "$0")/.."` (from
  `assets/bin/` up to `assets/`). All downstream paths (`OUT=../priv/static/game`, the `game-*` glob, the
  vite manifest read) are unchanged — they are already relative to `assets/`.
- **The header doc-links** (`:13`,`:20`): repoint to `echo/docs/edge-deliver/edge-bucket-setup.md` (the
  current location) and note the new self-contained deploy command.
- **The contract is otherwise byte-stable:** build → upload every `game-*` immutable
  (`Cache-Control: public,max-age=31536000,immutable`) → flip `manifest.json`
  (`{"game":"https://edge.codemoji.games/game-<hash>.js"}`, short cache) **last** → verify; `--dry-run` and
  `--rollback game-<hash>.js` unchanged. The pointer-flip-last ordering (the bundle exists before the pointer
  names it) is preserved.

## 8. The awscli pre-stage requirement (NEW — reliable download inside Fly)

The public AWS origin (`awscli.amazonaws.com`) is not reliably reachable from Fly's build/runtime network, so
the image build is flaky. The fix: **serve the awscli installer from the edge bucket the image already
trusts.**

- **Pre-stage (Operator infra step, in advance):** upload the AWS CLI v2 zip for **both** architectures to the
  edge bucket under `dist/`, reachable publicly as:
  - `https://edge.codemoji.games/dist/awscli-x86_64.zip`
  - `https://edge.codemoji.games/dist/awscli-aarch64.zip`
  uploaded with a long immutable cache (the installer is versioned/static), e.g.
  `aws s3 cp awscli-exe-linux-x86_64.zip s3://$TIGRIS_EDGE_BUCKET/dist/awscli-x86_64.zip --cache-control "public,max-age=31536000,immutable" --content-type application/zip`.
- **The Dockerfile fetches from the bucket:** `curl -fsSL "https://edge.codemoji.games/dist/awscli-${awsarch}.zip"`
  (the same arch mapping `amd64→x86_64` / `arm64→aarch64`). **INV-AWSCLI-PRESTAGED:** the image references
  `edge.codemoji.games/dist/awscli-*` and **no** `amazonaws.com`.
- **Document it** in `edge-bucket-setup.md`: a new "Pre-stage the awscli installer" step (the two uploads),
  so the bucket the image depends on is provisioned before the first edge deploy. (The doc edit is a
  deliverable of this rung; the upload itself is the Operator's, like the bucket creation.)

> Honest dependency note: this makes the edge image's awscli download depend on the **edge bucket** — the
> same origin the image's whole job is to publish to. That is acceptable and intentional: the bucket is the
> one external origin the edge surface already requires, fetched over the same trusted custom domain; pulling
> the installer from there trades an unreliable third-party origin for the dependency the task already has.

## 9. What stays unchanged (contracts this rung must NOT break)

- **The runtime pointer contract:** `Codemojex.Edge.game_url/0`, `https://${GAME_EDGE_HOST}/manifest.json`
  shape `%{"game"=>url}`, the 10s `:persistent_term` TTL, the `GAME_ASSET_URL` fallback. `lib/codemojex/edge.ex`
  has **zero diff**.
- **The cache policy:** hashed `game-*` immutable; `manifest.json` short-cache; the upload-then-flip order.
- **The swap ABI:** `src/index.tsx`'s `mount(el, props, bridge)` + `GameProps`/`Bridge` (`types.ts`) + the
  bridge events (`game:update`, `guess_rejected`, `revealed`, `golden_win` — `app.js:38-45`). The game bundle
  still builds to `game-[hash].js` with a vite manifest.
- **The engine release:** `echo/Dockerfile` + `echo/fly.toml` (the always-on `codemoji.games` machine) and
  all of `lib/codemojex/**` are untouched. `mix.lock` is untouched (no Elixir dep moved).

## 10. Acceptance (the runnable gate — each invariant a check; a no-op must not satisfy its letter)

- **A1 — DEP-FREE.** `grep -nE 'file:\.\.' echo/apps/codemojex/assets/package.json` → **0 matches**; the
  three phoenix deps are workspace references. (INV-DEP-FREE)
- **A2 — WORKSPACE RESOLUTION.** `assets/package.json` has `"workspaces": ["packages/*"]`; after
  `npm install`, `node_modules/{phoenix,phoenix_html,phoenix_live_view}` are symlinks into `packages/*`
  (`npm ls phoenix phoenix_live_view phoenix_html` resolves to the workspace, not `deps/`).
- **A3 — STANDALONE BUILD (no umbrella).** From a tree with **no `echo/deps/`** present (or a fresh checkout),
  `cd echo/apps/codemojex/assets && npm install && npm run build && npm run build:client` all succeed; nothing
  resolves a `../../../deps` path. (INV-STANDALONE-DEV)
- **A4 — VENDORED-FAITHFUL (runtime, not just compile).** The LiveView client built from the vendored
  packages **boots**: the `LiveSocket` connects and the `EdgeReact` hook mounts the game island. Proven by a
  runtime smoke (the `node/codemojex-e2e` Playwright path, or a headless boot of the built `app.js` asserting
  `window.liveSocket` connects), **not** by a green `vite build` alone. (INV-VENDORED-FAITHFUL)
- **A5 — SELF-CONTAINED CONTEXT.** `grep -nE 'COPY +deps/|\.\./' assets/Dockerfile` → **0**; a build with
  context `apps/codemojex/assets` (`docker build apps/codemojex/assets -f apps/codemojex/assets/Dockerfile`,
  or the fly build-only) succeeds with nothing copied from outside `assets/`. (INV-SELF-CONTAINED-CONTEXT)
- **A6 — AWSCLI PRE-STAGED.** `grep awscli.amazonaws.com assets/Dockerfile` → **0**;
  `grep 'edge.codemoji.games/dist/awscli' assets/Dockerfile` → **present**; `edge-bucket-setup.md` documents
  the two `dist/awscli-<awsarch>.zip` uploads; a public `curl -fsSI https://edge.codemoji.games/dist/awscli-x86_64.zip`
  → 200 (verified after the Operator pre-stages). (INV-AWSCLI-PRESTAGED)
- **A7 — SCRIPT RELOCATED.** `assets/bin/edge-deploy.sh` exists and is the canonical path; the old
  `apps/codemojex/scripts/edge-deploy.sh` is removed; the script's `cd` resolves to `assets/` from
  `assets/bin/`; `bin/edge-deploy.sh --dry-run` builds + prints the would-upload/flip plan **without** writing
  to the bucket.
- **A8 — POINTER CONTRACT UNCHANGED.** `git diff --stat lib/codemojex/edge.ex` → empty; the script still
  writes `manifest.json = {"game": …}` with the short cache and hashed files immutable.
- **A9 — SWAP ABI UNCHANGED.** `src/index.tsx` `mount(el,props,bridge)` + `types.ts` `GameProps`/`Bridge` +
  the four bridge events are byte-unchanged; `npm run build` still emits `game-<hash>.js` + a vite manifest.
- **A10 — ENGINE + BOUNDARY.** `echo/Dockerfile`, `echo/fly.toml`, `lib/codemojex/**`, `mix.lock`, and every
  sibling umbrella app have **zero diff**; the rung's changes are confined to
  `echo/apps/codemojex/assets/**` + `echo/docs/edge-deliver/edge-bucket-setup.md` + these specs.
- **A11 — THE DRY-RUN RELIABILITY GATE.** The edge deploy completes end-to-end as a dry run
  (`bin/edge-deploy.sh --dry-run` green, and a fly `--build-only` of the self-contained context succeeds) —
  the canonical "the edge build is reliable" signal.

## 11. Given / When / Then (headlines — the full set is [`cm-tma.1.stories.md`](./cm-tma.1.stories.md))

- **S1** — *A front-end engineer builds the bundles on a checkout with no `mix deps.get`* → `npm install` +
  both `npm run build*` succeed (A3).
- **S2** — *`npm ci` runs in the edge image with context `assets/`* → resolves `phoenix*` from `packages/*`,
  copies nothing from `deps/` (A1/A2/A5).
- **S3** — *The lobby loads after the vendoring* → the `LiveSocket` connects and the board island mounts (A4).
- **S5** — *The edge image fetches awscli inside Fly* → from `edge.codemoji.games/dist/`, never amazonaws.com
  (A6).
- **S7** — *A player loads a game after the rung* → identical bundle behavior; `Codemojex.Edge` resolves the
  same pointer; no player-visible change (A8/A9).

## 12. Scope In

- Vendor `phoenix` / `phoenix_html` / `phoenix_live_view` as dependency-free TS packages under
  `assets/packages/*` (the faithfulness contract, §5).
- Convert `assets/package.json` to an npm workspace; drop the `file:../../../deps/*` links; regenerate
  `package-lock.json`.
- Rewrite `assets/Dockerfile` self-contained (context `assets/`; drop the `deps/` COPYs; awscli from the edge
  `dist/`; `ENTRYPOINT bin/edge-deploy.sh`). Update `assets/fly.toml` (`dockerfile = "Dockerfile"`; the
  deploy command).
- Relocate `scripts/edge-deploy.sh` → `assets/bin/edge-deploy.sh` (fix the `cd` + the header doc-links).
- Document the awscli pre-stage requirement in `edge-bucket-setup.md` (the two `dist/awscli-<awsarch>.zip`
  uploads).

## 13. Scope Out

- **The game engine** (`lib/codemojex/**`), `Codemojex.Edge`, the manifest/pointer contract, the swap ABI —
  read-only; unchanged.
- **The engine release** (`echo/Dockerfile`, `echo/fly.toml`, the always-on `codemoji.games` machine) — not
  touched.
- **Provisioning + deploying** (creating the bucket, uploading the awscli zips, running `fly deploy`) — the
  **Operator's**, per the standing rule. This rung authors the files, the docs, and the dry-run gate.
- **Reconciling the stale narrative docs** (`codemoji.static-edge.md`, `codemojex-tma.roadmap.md`:
  `static.codemoji.games`/`board`) — a separate docs-reconcile rung.
- The `node/codemoji-app` React frontend and any repo-level sharing of the vendored libs — out (these
  packages are codemojex's own, under `assets/`, per the "in `echo/apps/codemojex/`" scoping).

## 14. The rung (placement + risk)

**Track:** `codemojex-tma` (the Telegram Mini App / front-end tier), rung **1** — it establishes the
self-contained front-end build the later TMA UI rungs (the `cmd.*` design-system work) build on.
**Risk:** **NORMAL build-tooling, with ONE high-stakes invariant.** Most acceptance is mechanical
(grep/build/context). The load-bearing risk is **INV-VENDORED-FAITHFUL** (§5): a phoenix/phoenix_live_view
rewrite can compile green yet break the live lobby at runtime — gate-invisible to a pure `vite build`. So the
verify **must** include a runtime LiveSocket-boot smoke (A4), and the edge path is exercised with the
`--dry-run` reliability gate (A11). Secondary external-facing concern: the edge **publish** path — mitigated
because the publish contract (pointer, cache, ABI) is held byte-stable (§9) and the deploy stays the
Operator's.

## 15. Boundary

`echo/apps/codemojex/assets/**` (the workspace, `packages/*`, `Dockerfile`, `fly.toml`, `bin/edge-deploy.sh`)
+ `echo/docs/edge-deliver/edge-bucket-setup.md` (the awscli pre-stage step) + these specs
(`docs/codemojex-tma/specs/cm-tma.1.*`). **Out of bounds:** `lib/codemojex/**`, the engine release
(`echo/Dockerfile`, `echo/fly.toml`), every sibling umbrella app, `mix.lock`, and the umbrella `config/`. A
change reaching the engine or a sibling app is out of scope — stop and re-scope.

## 16. Build brief

Smallest-change-first, each step independently checkable:

1. **Vendor** `assets/packages/{phoenix,phoenix_html,phoenix_live_view}/` — each a dep-free TS package whose
   `package.json` `name` is the bare specifier, exposing the §5 surface (`Socket`; `LiveSocket` + the hook
   lifecycle; `phoenix_html` side-effects). Basis = the upstream client in `deps/`; re-expressed in TS.
2. **Workspace** — `assets/package.json`: `"workspaces": ["packages/*"]`; `phoenix*` → `"*"`; regenerate
   `package-lock.json`.
3. **Prove standalone** — `rm -rf node_modules && npm install && npm run build && npm run build:client` with
   no `deps/` reachable (A1/A2/A3); then the **runtime boot smoke** (A4).
4. **Self-contained image** — rewrite `assets/Dockerfile` (context `assets/`; drop `deps/` COPYs; awscli from
   the edge `dist/`; `ENTRYPOINT bin/edge-deploy.sh`); update `assets/fly.toml` (A5/A6).
5. **Relocate** `scripts/edge-deploy.sh` → `assets/bin/edge-deploy.sh` (fix the `cd`, the doc-links) (A7).
6. **Pre-stage docs** — add the awscli `dist/` upload step to `edge-bucket-setup.md` (A6).
7. **Gate** — A1–A11; the `--dry-run` reliability gate (A11) is the canonical green; the boundary check (A10)
   confirms the engine + `lib/` + `mix.lock` are untouched.

**Files (boundary `echo/apps/codemojex/assets/**` + the bucket doc + these specs):** `packages/*` (new) ·
`package.json` + `package-lock.json` (workspace) · `Dockerfile` (rewrite) · `fly.toml` (rewrite) ·
`bin/edge-deploy.sh` (moved from `scripts/`) · `echo/docs/edge-deliver/edge-bucket-setup.md` (the pre-stage
step). **Unchanged:** `js/app.js`, `src/**`, both `vite.*.config.ts`, `tsconfig.json`, `lib/codemojex/edge.ex`.
