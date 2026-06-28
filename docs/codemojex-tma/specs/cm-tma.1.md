# cm-tma.1 — The self-contained edge build (vendor `phoenix` + `phoenix_live_view` as TS under `assets/packages/` · **pnpm** workspace `@codemojex/edge` · **es2024** · **vitest** · self-contained Docker context · awscli pre-staged)

> The first **codemojex-tma** (Telegram Mini App / front-end tier) spec rung. It does not touch the game
> engine (`lib/codemojex/**`) or the always-on engine release — it makes the **edge game-bundle build**
> reliable and the **front end developable on its own**, by removing the one coupling that drags the whole
> umbrella into the front-end build: the `file:../../../deps/phoenix*` npm links.
>
> The **body wins** on any disagreement with the brief ([`cm-tma.1.llms.md`](./cm-tma.1.llms.md)) or the
> stories ([`cm-tma.1.stories.md`](./cm-tma.1.stories.md)). **NO-INVENT:** every file/line cited below was
> re-probed on disk. Framing: third person; no first-person-agent narration.
>
> **As-built / forward-tense split (re-probed this session — the Operator has prepared the packages):**
> The two vendored packages are **present on disk** (`assets/packages/phoenix` = `@echo/phoenix` v1.8.8,
> `assets/packages/phoenix_live_view` = `@echo/phoenix_live_view` v1.2.3) and `assets/package.json` is already
> renamed `@codemojex/edge` with a **pnpm** engine and `@echo/*` deps — those are stated **present-tense**.
> What remains **forward-tense** (this rung completes it): the `pnpm-workspace.yaml` + `pnpm-lock.yaml`, the
> **es2024** cutover of the three *root* build configs, the `@echo/phoenix_live_view` `package.json`
> **jest→vitest + npm→pnpm** cleanup, the self-contained `Dockerfile`/`fly.toml` rewrite, the relocated
> `assets/bin/edge-deploy.sh`, and the `dist/awscli-*` pre-stage. **npm is retired** — no `package-lock.json`,
> no `npm ci`/`npm run` anywhere in the end state.
>
> **Shipped status (cm-tma.1 — backward-reconciled to the as-built after the build):** cm-tma.1 **shipped at
> 13/14 front-end gates green** (A1–A12, A14 + the load-bearing A4 runtime boot-smoke, mutation-proven). **A13
> is DEFERRED to cm-tma.2** — the `package.json` end-state is jest-free, but the vendored `test/*.test.ts` files
> are still upstream-jest-shaped and do not yet run (§10 A13). Two toolchain facts were folded back from the
> build: the es2024 target **forced `vite ^5.4.0 → ^6.0.0`** (§es-build · §9), and the rebuilt served LiveView
> bundle `priv/static/assets/app.js` was **left unrefreshed** (outside the `assets/**` boundary; §9).
>
> **Grounding caveat (doc drift):** the narrative docs [`codemoji.static-edge.md`](../codemoji.static-edge.md)
> and [`codemojex-tma.roadmap.md`](../codemojex-tma.roadmap.md) still say `static.codemoji.games` + `board` +
> `assets/react/`. The **as-built** (and this rung) use `edge.codemoji.games` + the **game** bundle
> (`game-<hash>.js`) + `Codemojex.Edge.game_url/0` + `assets/src/`. This spec grounds in the as-built; the
> narrative docs are stale and out of scope here.

## 1. The rung in one paragraph

The codemojex front end lives in `echo/apps/codemojex/assets/` and builds **two** independent bundles with
vite: the **LiveView client** (`js/app.js` → `priv/static/assets`, via `vite.client.config.ts`) and the
**edge React game** (`src/index.tsx` → `priv/static/game`, via `vite.config.ts`). Historically
`assets/package.json` declared `phoenix` / `phoenix_html` / `phoenix_live_view` as `file:../../../deps/phoenix*`
— Elixir-managed dependency directories reached by climbing three levels out of `assets/`. That single fact
forced the edge Docker build context to the **umbrella root** (so `echo/deps/` was reachable), made `npm ci`
require a prior `mix deps.get`, and blocked anyone from building or iterating the front end without the whole
BEAM project on disk — even though the **edge game bundle imports none of them** (`src/index.tsx` is pure
React). This rung **vendors** the Phoenix client as dependency-pinned TypeScript packages under
`assets/packages/` — **two** packages (`@echo/phoenix`, `@echo/phoenix_live_view`; `phoenix_html`'s surface is
folded into LV as `src/phoenix_html.ts`, not a standalone package) — turns `assets/` into a **pnpm** workspace
named `@codemojex/edge` (**npm retired**), moves the whole build to a **modern es2024** target, runs the
vendored packages' own test suites on **vitest** (the upstream **jest** retired), and **relocates the edge
build artifacts into `assets/`** (`Dockerfile`, `fly.toml`, `bin/edge-deploy.sh`) so the edge image builds from
a **self-contained `assets/` context** with no umbrella, no `deps/`, and no `file:../` links. It also makes the
edge image's awscli download reliable inside Fly's network by fetching a **pre-staged** bundle from the edge
bucket itself (`edge.codemoji.games/dist/awscli-<awsarch>.zip`) instead of the public AWS origin.

## 2. The problem (what the vendoring solves)

The pre-rung `assets/package.json` `dependencies` (the coupling being removed):

```json
"dependencies": {
  "phoenix":           "file:../../../deps/phoenix",
  "phoenix_html":      "file:../../../deps/phoenix_html",
  "phoenix_live_view": "file:../../../deps/phoenix_live_view",
  "react": "^18.3.1", "react-dom": "^18.3.1"
}
```

Four failures followed, each load-bearing — they are the justification for the vendoring:

1. **The build context could not be `assets/`.** The edge `Dockerfile` had to `COPY deps/phoenix deps/phoenix`
   (×3) into the image so `npm ci` resolved the `file:../../../deps/*` links, which is only possible if the
   Docker build context is the **umbrella root** `echo/`.
2. **`npm ci` required the Elixir toolchain to have run.** `echo/deps/phoenix*` only exists after
   `mix deps.get` — so the front-end build inherited a hard dependency on a BEAM step it does not use.
3. **The front end was not developable standalone.** A designer or front-end engineer could not
   `cd assets && pnpm install && pnpm dev` on a checkout without the umbrella + `mix deps.get` — the package
   manager could not resolve the `file:` links.
4. **Dead weight on the hot path.** The edge **game** bundle (`src/index.tsx`, re-probed lines 5-9) imports
   only `react-dom/client` + `@/GameEdge` + `@/types` — **no phoenix**. The three Phoenix file-deps existed
   solely for the **LiveView client** (`js/app.js:5-6`), yet `npm ci` validated every declared dependency, so
   they taxed the game-bundle image build for nothing.

A fifth, independent reliability gap: the edge `Dockerfile` fetched the AWS CLI v2 zip from
`https://awscli.amazonaws.com/awscli-exe-linux-<awsarch>.zip` at image-build time. That public origin is **not
reliably reachable from inside Fly's build/runtime network**, so the edge image build is flaky for a reason
unrelated to the app.

**As-built progress (re-probed this session):** the Operator has already vendored the two packages and
converted `assets/package.json` off the `file:` links — `assets/package.json:15-20` now reads
`"phoenix": "@echo/phoenix"` / `"phoenix_live_view": "@echo/phoenix_live_view"` (no `file:../`), with a `pnpm`
engine (`:6-9`) and `name "@codemojex/edge"` (`:2`). This rung **finishes** that conversion to the clean,
shippable end state below.

## 3. Ground truth (re-probed on disk — cite the file:line; the as-built wins)

| Fact | Where (re-probed) |
|---|---|
| The host package | `assets/package.json` — `name "@codemojex/edge"` (`:2`), `type:"module"`, `engines.pnpm ">=10.0.0"` (`:6-9`); scripts `build`=`vite build` (`:11`), `build:client`=`vite build --config vite.client.config.ts` (`:12`), `dev`=`build:client --watch` (`:13`); deps `phoenix`/`phoenix_live_view` → `@echo/*` (`:16-17`, **no `file:`**), react/react-dom `^18.3.1` (`:18-19`) |
| The vendored `phoenix` | `assets/packages/phoenix/package.json` — `name "@echo/phoenix"` v1.8.8, `type:"module"`, `exports "."→./src/index.ts`; `scripts.test "vitest"` (`:23`); devDeps **vitest** only (`:35`) — **no jest**. `src/*.ts` (channel/socket/serializer/…) + `test/*.test.ts` + `vite.config.ts` (`target:"es2024"`) + `vitest.config.ts` |
| The vendored `phoenix_live_view` (at reconcile) | `assets/packages/phoenix_live_view/package.json` — `name "@echo/phoenix_live_view"` v1.2.3; `dependencies.morphdom "2.7.8"` (`:20`); at reconcile it **still carried the upstream jest toolchain** — `jest`/`jest-environment-jsdom`/`ts-jest`/`@types/jest`/`eslint-plugin-jest` devDeps + a registry `"phoenix":"1.7.21"` devDep (`:40`) + `js:test`/`test` scripts calling `jest` via `npm run` (`:36-58`). `src/*.ts` (incl. `src/phoenix_html.ts`) + `test/*.test.ts` + `vite.config.ts` (`target:"es2024"`) + `vitest.config.ts` already present. **Shipped:** the build dropped the jest devDeps + the registry `phoenix` shadow, added `phoenix` (`workspace:@echo/phoenix@*`) + the `./phoenix_html` subpath export, set `test:"vitest"`, fixed `types`/`files` — **but the `test/*.test.ts` files remain unported upstream jest, so A13 is DEFERRED to cm-tma.2** (§10 A13) |
| The ONLY phoenix consumer | `assets/js/app.js:5-6` — `import { Socket } from "@echo/phoenix"` + `import { LiveSocket } from "@echo/phoenix_live_view"` (**scoped** names); boots `new LiveSocket("/live", Socket, { params, hooks:{ EdgeReact } })` + `liveSocket.connect()` (`:62-67`) |
| LV → phoenix (internal) | `assets/packages/phoenix_live_view/src/*.ts` import **bare** `"phoenix"` — **2 real imports** (`view.ts:1` a value `import { Channel }`; `live_socket.ts:1` a type-only `import { type Socket }`; the other 3 `"phoenix"` strings are JSDoc at `live_socket.ts:311,314,329`) + `"morphdom"` (2 files) — so within the workspace `@echo/phoenix_live_view` resolves bare `phoenix` to the workspace `@echo/phoenix`. The `view.ts` **value** import is load-bearing: it is why dropping the registry `"phoenix":"1.7.21"` LV devDep (so it cannot shadow `workspace:@echo/phoenix@*`) matters |
| The game = no phoenix | `assets/src/index.tsx:5-9` — `react-dom/client` + `@/GameEdge` + `@/types`; exports `mount(el, props, bridge)` returning `{update, unmount}` |
| The swap contract | `assets/src/types.ts` — `GameProps` (`view`/`leaderboard`/`history`/`me`) + `Bridge` (`pushEvent`/`onServerEvent`); kept in lockstep with `GameLive.game_props/3` |
| The build target (laggards) | `assets/tsconfig.json:3,5` — `target:"ES2020"` + `lib:["ES2020",…]`; `assets/vite.config.ts:24` + `assets/vite.client.config.ts:11` — `target:"es2020"`. (The *package* vite configs already target `es2024`.) |
| The edge Dockerfile | `assets/Dockerfile` — `node:22-bookworm-slim`; awscli from amazonaws.com (`:23-32`); `COPY deps/phoenix*` (`:39-41`); `COPY apps/codemojex/{assets,scripts}` (`:44-45`); `ENTRYPOINT ["/app/apps/codemojex/scripts/edge-deploy.sh"]` (`:51`) — **not yet rewritten** |
| The edge fly config | `assets/fly.toml` — app `codemojex-edge-deliver`, region `fra`, a TASK (no `[[services]]`); `[build] dockerfile = "Dockerfile.edge"` (`:24`, **stale name**); deploy-from-umbrella-root command in the header (`:12-16`) |
| The publish script | `apps/codemojex/scripts/edge-deploy.sh` — `cd "$(dirname "$0")/../assets"` (`:91`); `npm ci && npm run build` (`:93-94`); `OUT=../priv/static/game` (`:95`); upload `game-*` immutable (`:113-128`); flip `manifest.json` short-cache LAST (`:63-73`,`:130-132`); `--dry-run` / `--rollback`; HOST default `edge.codemoji.games` (`:47`) — **not yet moved** |
| The runtime resolver | `lib/codemojex/edge.ex` — `Codemojex.Edge.game_url/0` GETs `https://${GAME_EDGE_HOST}/manifest.json` (`%{"game"=>url}`), `:persistent_term` 10s TTL, falls back to `GAME_ASSET_URL`. **Unchanged by this rung.** |
| The bucket setup | `echo/docs/edge-deliver/edge-bucket-setup.md` — the public Tigris bucket at `edge.codemoji.games`; `TIGRIS_EDGE_*` env; the deploy + rollback steps |
| The engine release (separate) | `echo/Dockerfile` + `echo/fly.toml` — the always-on `codemoji.games` machine. **Out of scope; untouched.** |

**Absent on disk (forward-tense — this rung creates them):** `assets/pnpm-workspace.yaml`,
`assets/pnpm-lock.yaml`, `assets/bin/` (the relocated script). No `package-lock.json` exists (npm already
retired in `package.json`).

## 4. The target layout — `assets/` is the **pnpm** workspace root; `packages/*` are the vendored libs

```
echo/apps/codemojex/assets/            ← the pnpm workspace ROOT (@codemojex/edge) + the edge Docker build context
  pnpm-workspace.yaml    ← NEW: packages: ["packages/*"]
  pnpm-lock.yaml         ← NEW: the committed lockfile (npm's package-lock.json retired)
  packages/
    phoenix/             package.json (name "@echo/phoenix"),            src/… + test/*.test.ts + vitest.config.ts
    phoenix_live_view/   package.json (name "@echo/phoenix_live_view"),  src/… (incl. phoenix_html.ts) + test/*.test.ts + vitest.config.ts
  bin/
    edge-deploy.sh       ← relocated from apps/codemojex/scripts/ (§7, APPROVED)
  js/app.js              ← imports the vendored libs by their @echo/* names (as-built)
  src/                   ← the GameEdge React island (ABI unchanged)
  Dockerfile             ← self-contained edge image (§6)
  fly.toml               ← edge task config (§6)
  package.json           ← @codemojex/edge; @echo/* deps via workspace:* (no file:../)
  tsconfig.json · vite.config.ts · vite.client.config.ts   ← es2024 (§ es-build)
```

**Why under `assets/` and not `apps/codemojex/packages/`:** `assets/` is already the workspace root
(`package.json`, `node_modules`, both vite configs, `tsconfig.json` live there). **pnpm workspaces require
every member to live under the directory that holds `pnpm-workspace.yaml`** — so `packages/` belongs at
`assets/packages/`. Placing it at the app root would force a `package.json` sibling to `mix.exs` (a JS
workspace root jammed into the Elixir app root) and widen the Docker context back out to include
`lib/`/`priv/`/`test/`. `assets/packages/` keeps the context the single self-contained `assets/` tree.

**The pnpm workspace wiring** (the npm→pnpm finish):

- `assets/pnpm-workspace.yaml` declares the members:
  ```yaml
  packages:
    - "packages/*"
  ```
- `assets/package.json` `dependencies` reference the vendored libs by their **scoped names via the
  `workspace:*` protocol** (replacing the current `"phoenix": "@echo/phoenix"` alias keys):
  ```json
  "dependencies": {
    "@echo/phoenix": "workspace:*",
    "@echo/phoenix_live_view": "workspace:*",
    "react": "^18.3.1", "react-dom": "^18.3.1"
  }
  ```
  so `js/app.js`'s `import … from "@echo/phoenix"` / `"@echo/phoenix_live_view"` resolve to `packages/*`.
- `@echo/phoenix_live_view`'s `package.json` declares its own resolution for its **bare** internal imports —
  `morphdom` (a normal registry dependency, `2.7.8`) and `phoenix` **aliased to the workspace package**
  (`"phoenix": "workspace:@echo/phoenix@*"`) so its 5 `from "phoenix"` imports resolve to `@echo/phoenix`.
- `pnpm install` writes `assets/pnpm-lock.yaml` (committed); `pnpm install --frozen-lockfile` (the script + the
  image) installs the workspace deterministically. **No path escapes `assets/`.**

## 5. The vendored packages — the faithfulness contract (the load-bearing invariant)

Each `packages/<lib>/` is a TypeScript package whose `package.json` `name` is the scoped specifier its
consumers import. The rewrite is faithful when it preserves **the exact public surface `js/app.js` consumes** —
this is the one place a green build can still ship a broken lobby, so the contract is pinned here, not left to
the build:

- **`@echo/phoenix`** — the named export **`Socket`** (the class), constructable as `new Socket("/live", opts)`
  and behaving as the transport `LiveSocket` drives. Surface used: `app.js:5,62`
  (`import { Socket } from "@echo/phoenix"`; `new LiveSocket("/live", Socket, …)`). **Dependency-free.**
- **`@echo/phoenix_live_view`** — the named export **`LiveSocket`** (the class) with `connect()` and the **hook
  lifecycle** the `EdgeReact` hook relies on: `this.el`, `this.el.dataset`, `this.pushEvent(event, payload)`,
  `this.handleEvent(name, cb)` (returning an unsubscribe), and the `mounted()`/`destroyed()` callbacks.
  Surface used: `app.js:6,11-51,62-66`. **Depends on `morphdom` (registry) + `@echo/phoenix` (workspace
  alias).** Carries `src/phoenix_html.ts` so the `phoenix_html` side-effects (`data-confirm` / method-link
  behavior) exist within the LV package, **resolved via a subpath export** — `@echo/phoenix_live_view`'s
  `package.json` declares `"exports": { ".": "./src/index.ts", "./phoenix_html": "./src/phoenix_html.ts" }`,
  imported as `import "@echo/phoenix_live_view/phoenix_html"` for its side effect **only where
  `data-method`/`data-confirm` links exist** (mirroring upstream's explicit `import "phoenix_html"`). There is
  **no standalone `phoenix_html` package or host dependency**; the decision is unchanged — this states the
  resolution mechanism. The host keeps it **inert today** (`app.js` does **not** import the subpath, and stays
  byte-unchanged); the import line is added the day such links appear. Grounding:
  [`phoenix-client-resolution.md §4`](../../../echo/docs/codemojex/phoenix-client-resolution.md).

> **Not literally "dependency-free."** The original aim was zero deps, but the as-built keeps `morphdom`
> (LiveView genuinely needs it for DOM patching) and the intra-workspace `phoenix` edge. The real removed
> coupling is the **`file:../` umbrella escape**, not all dependencies — A1 (`grep file:..` → 0) is the
> invariant, not a zero-dep count.

**The vitest faithfulness layer (jest retired).** The vendored packages carry their **own ported test suites**
(`packages/*/test/*.test.ts`) run on **vitest** (`vitest.config.ts` in each), migrated from the upstream
**jest**. `@echo/phoenix`'s `package.json` is the **cleaned reference** — `test: "vitest"`, vitest the only test devDep,
no jest *(backward-reconcile: the package.json is jest-free, but the `test/*.test.ts` files in **both** packages
remain upstream-jest-shaped and do not yet run — see the A13 deferral below)*. `@echo/phoenix_live_view` has its `vitest.config.ts` + `*.test.ts` in place but its `package.json` still
ships the upstream jest devDeps (`jest`, `jest-environment-jsdom`, `ts-jest`, `@types/jest`,
`eslint-plugin-jest`) and the upstream `js:test`/`test`/`e2e:*` scripts that call `jest` and `mix`/`playwright`
via `npm run`. This rung **completes the jest→vitest + npm→pnpm conversion on the LV package**: drop the jest
devDeps, set `test: "vitest"` (+ `typecheck`), prune the upstream `e2e:*`/`mix`/`npm run` scripts to the
vendored package's needs, and fix the `types`/`files` fields to the vendored `src/` layout. A green vitest run
of **both** packages (`pnpm -C packages/<lib> test`) is the **A13** faithfulness proof that **complements** the
runtime boot smoke (A4) — the suites pin the unit behavior; the smoke pins the integration. **As shipped, A13 is
DEFERRED to cm-tma.2:** the package.json config is jest-free, but the `test/*.test.ts` files in both packages
remain upstream-jest-shaped (both suites collect 0 and fail) — porting the ~320 jest call-sites (the `../src`
import paths, the `test/tsconfig.json` `extends`, the jsdom env) is a separable concern, so cm-tma.1 ships with
**A4 as the load-bearing faithfulness proof** (mutation-proven) and the unit suites following in cm-tma.2.

**INV-VENDORED-FAITHFUL:** after the wiring, `import { Socket } from "@echo/phoenix"` and
`import { LiveSocket } from "@echo/phoenix_live_view"` resolve to `packages/*`, the LiveView client builds
(`pnpm build:client`), the vendored packages' vitest suites pass, and **the LiveSocket connects and the
`EdgeReact` hook mounts the game island exactly as before** (the lobby is live; the board loads). A build that
compiles but breaks the runtime boot **fails** this rung. The verify therefore includes a **runtime boot
smoke**, not only a compile (§10 A4).

The basis for the rewrite is the upstream Phoenix JS client these `deps/` carry; the rung re-expresses that
surface in TS. The internal implementation is the build's to choose; the **contract above** is fixed.

## 6. The self-contained edge image — `assets/Dockerfile` + `assets/fly.toml`

**Build context becomes `echo/apps/codemojex/assets/`** (was the umbrella root). The rewritten
`assets/Dockerfile` (forward-tense target):

- `FROM node:22-bookworm-slim`; install `curl ca-certificates unzip bash` (as today); enable **pnpm** via
  `corepack enable` (or a pinned `corepack prepare pnpm@<v> --activate`) — the image's package manager is
  pnpm, **never npm**.
- **awscli from the pre-staged bundle** (§8): `curl -fsSL "https://edge.codemoji.games/dist/awscli-${awsarch}.zip"`
  (arch-mapped `amd64→x86_64` / `arm64→aarch64`), unzip, `./aws/install`. **No** amazonaws.com.
- **Drop** the three `COPY deps/phoenix*` lines entirely.
- `WORKDIR /app`; `COPY . .` — the whole **self-contained** `assets/` tree (incl. `packages/`, `bin/`,
  `pnpm-workspace.yaml`, `pnpm-lock.yaml`). Nothing outside `assets/` is referenced.
- `RUN chmod +x bin/edge-deploy.sh`; `ENTRYPOINT ["/app/bin/edge-deploy.sh"]`.

The image runs **no package install itself** — the script does `pnpm install --frozen-lockfile && pnpm build`
at runtime. With the workspace, `pnpm install` resolves `@echo/*` from `packages/*` locally; nothing reaches
for `deps/`. The game build writes to `../priv/static/game` (relative to `assets/`), a scratch path created by
vite inside the ephemeral image, uploaded to the bucket, then discarded — so the `../priv` output never needs
to pre-exist.

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
- **The package manager** (`:93-94`): `npm ci && npm run build` → `pnpm install --frozen-lockfile && pnpm build`
  (**npm retired**).
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

> **Changed by this rung (not in the unchanged set):** `js/app.js` (already on the `@echo/*` scoped imports);
> `assets/tsconfig.json` + `assets/vite.config.ts` + `assets/vite.client.config.ts` (es2020 → **es2024**);
> `assets/package.json` (the `workspace:*` finish **+ the forced `vite ^5.4.0 → ^6.0.0`** bump, §es-build);
> `@echo/phoenix_live_view`'s `package.json` (jest→vitest + npm→pnpm cleanup). `src/index.tsx` + `src/types.ts`
> (the swap ABI) **are** byte-unchanged.
>
> **Deferred — the served LiveView bundle is not refreshed by this rung.** `pnpm build:client` rebuilds the
> **committed** served bundle `priv/static/assets/app.js` at the new es2024/vite-6 bytes, but `priv/` is
> **outside** the `assets/**` boundary (§15), so the rebuilt artifact was **reverted** — the rung's diff is the
> source + build config, not the rebuilt output. Consequence: the engine serves the **previous**
> es2020/file-dep-built `priv/static/assets/app.js` until it is deliberately rebuilt and committed on the new
> toolchain (an Operator step at deploy; `js/app.js` **source** is byte-unchanged, so the old bundle stays
> functionally valid in the meantime).

## es-build — the modern es2024 target (NEW)

The build moves to a **modern es2024** target. The *package* vite configs already target `es2024`
(`packages/phoenix/vite.config.ts:13`, `packages/phoenix_live_view/vite.config.ts:13`); the three **root**
configs are the laggards and this rung brings them up:

- `assets/tsconfig.json:3` — `"target": "ES2020"` → `"ES2024"`; `:5` — `"lib": ["ES2020", …]` →
  `["ES2024", "DOM", "DOM.Iterable"]`.
- `assets/vite.config.ts:24` — `target: "es2020"` → `"es2024"` (the edge game bundle).
- `assets/vite.client.config.ts:11` — `target: "es2020"` → `"es2024"` (the LiveView client).

**INV-ES2024:** after the cutover, `grep -rniE 'es2020' assets/tsconfig.json assets/vite.config.ts
assets/vite.client.config.ts` → **0**, and each of the four sites names es2024 (§10 A12). Both bundles must
still build green (A3) and the lobby must still boot (A4) at the new target.

> **Shipped consequence — the forced `vite` bump (D-3).** es2024 is not reachable on the as-prepped toolchain:
> root `vite ^5.4.0` bundles `esbuild 0.21.5`, which rejects `target: "es2024"` (esbuild added es2024 in 0.24.0;
> vite 6 bundles esbuild 0.25.x; the pinned `vitest ^4` peer also requires vite 6). So the build bumped
> `assets/package.json` devDeps **`vite ^5.4.0 → ^6.0.0`** (the lockfile resolves `vite@6.4.3` + `esbuild@0.25.12`
> + `vitest@4.1.9`; `@vitejs/plugin-react ^4.3.1` supports vite 6). **es2024 ⟹ vite 6** — a necessary
> consequence of an in-spec requirement, not a new arbitrary dependency; A9 holds (game/client bundle shapes
> unchanged) and `mix.lock` is untouched.

## 10. Acceptance (the runnable gate — each invariant a check; a no-op must not satisfy its letter)

- **A1 — DEP-FREE (no umbrella escape).** `grep -nE 'file:\.\.' echo/apps/codemojex/assets/package.json` →
  **0 matches**; the `@echo/*` deps are `workspace:*` references. (INV-DEP-FREE)
- **A2 — WORKSPACE RESOLUTION.** `assets/pnpm-workspace.yaml` lists `packages/*`; after `pnpm install`,
  `node_modules/.pnpm` links `@echo/phoenix` + `@echo/phoenix_live_view` to `packages/*`
  (`pnpm why @echo/phoenix` / `pnpm ls -r` resolves to the workspace, not `deps/`); LV's bare `phoenix`
  resolves to the workspace `@echo/phoenix`.
- **A3 — STANDALONE BUILD (no umbrella).** From a tree with **no `echo/deps/`** present (or a fresh checkout),
  `cd echo/apps/codemojex/assets && pnpm install && pnpm build && pnpm build:client` all succeed; nothing
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
  the four bridge events are byte-unchanged; `pnpm build` still emits `game-<hash>.js` + a vite manifest.
- **A10 — ENGINE + BOUNDARY.** `echo/Dockerfile`, `echo/fly.toml`, `lib/codemojex/**`, `mix.lock`, and every
  sibling umbrella app have **zero diff**; the rung's changes are confined to
  `echo/apps/codemojex/assets/**` + `echo/docs/edge-deliver/edge-bucket-setup.md` + these specs.
- **A11 — THE DRY-RUN RELIABILITY GATE.** The edge deploy completes end-to-end as a dry run
  (`bin/edge-deploy.sh --dry-run` green, and a fly `--build-only` of the self-contained context succeeds) —
  the canonical "the edge build is reliable" signal.
- **A12 — ES2024 TARGET.** `grep -rniE 'es2020' assets/tsconfig.json assets/vite.config.ts
  assets/vite.client.config.ts` → **0**; all four sites name es2024; both bundles build green at the new
  target. (INV-ES2024)
- **A13 — VITEST (jest retired). [DEFERRED to cm-tma.2 — cm-tma.1 ships 13/14.]** Target:
  `pnpm -C packages/phoenix test` and `pnpm -C packages/phoenix_live_view test` run vitest and pass;
  `grep -rniE '\bjest\b' echo/apps/codemojex/assets/packages` → **0**; each package has a `vitest.config.ts`.
  (INV-VITEST) **As shipped:** the `package.json` end-state is jest-free for **both** packages (devDeps,
  scripts, and config cleaned), **but** the vendored `test/*.test.ts` files remain upstream-jest-shaped — both
  suites collect 0 and fail (`@echo/phoenix`: `@jest/globals` + a stale `../js/phoenix`; `@echo/phoenix_live_view`:
  the jest API + a broken `test/tsconfig.json` `extends` + a missing jsdom env), so the `grep '\bjest\b'` over
  the **test files** is non-zero. The Operator ruled A13 DEFERRED (the rung's value — the self-contained edge
  build — is complete, and A4, the §14-primary faithfulness gate, is mutation-proven). **cm-tma.2** ports both
  suites jest→vitest: rewrite the ~320 jest call-sites, fix the `../src` import paths + the `test/tsconfig.json`
  `extends` + add the jsdom env; then both `pnpm -C packages/* test` green and `grep '\bjest\b' packages` → 0.
- **A14 — PNPM (npm retired).** `assets/pnpm-workspace.yaml` + `assets/pnpm-lock.yaml` exist; **no**
  `package-lock.json` anywhere under `assets/`; `grep -rniE 'npm ci|npm run|npm install' assets/Dockerfile
  assets/bin/edge-deploy.sh` → **0** (the image + script use pnpm). (INV-PNPM)

## 11. Given / When / Then (headlines — the full set is [`cm-tma.1.stories.md`](./cm-tma.1.stories.md))

- **S1** — *A front-end engineer builds the bundles on a checkout with no `mix deps.get`* → `pnpm install` +
  both `pnpm build*` succeed (A3).
- **S2** — *`pnpm install` runs in the edge image with context `assets/`* → resolves `@echo/*` from
  `packages/*`, copies nothing from `deps/` (A1/A2/A5/A14).
- **S3** — *The lobby loads after the vendoring* → the `LiveSocket` connects and the board island mounts (A4).
- **S5** — *The edge image fetches awscli inside Fly* → from `edge.codemoji.games/dist/`, never amazonaws.com
  (A6).
- **S7** — *A player loads a game after the rung* → identical bundle behavior; `Codemojex.Edge` resolves the
  same pointer; no player-visible change (A8/A9).
- **S9** — *The build runs at a modern target; the vendored suites run on vitest* → es2020 gone (A12); both
  packages' vitest suites green, no jest (A13).

## 12. Scope In

- Vendor `phoenix` (`@echo/phoenix`) + `phoenix_live_view` (`@echo/phoenix_live_view`) as TS packages under
  `assets/packages/*` (the faithfulness contract, §5); `phoenix_html` folded into LV as `src/phoenix_html.ts`
  and resolved via the **subpath export** `@echo/phoenix_live_view/phoenix_html` (§5), **no standalone package**
  (kept inert — `app.js` unchanged). *(The packages are present on disk; this rung completes their wiring + cleanup.)*
- Make `assets/` a **pnpm** workspace — add `pnpm-workspace.yaml` (`packages: ["packages/*"]`); convert
  `assets/package.json` deps to `@echo/* : workspace:*`; commit `pnpm-lock.yaml`. **npm retired** (no
  `package-lock.json`, no `npm ci`/`npm run`).
- Complete the **jest→vitest** migration on `@echo/phoenix_live_view`'s `package.json` (drop the jest
  toolchain; `test: "vitest"`; prune the upstream `npm run`/`mix`/`e2e` scripts; fix `types`/`files`).
- Move the build to **es2024** — `assets/tsconfig.json` + `assets/vite.config.ts` + `assets/vite.client.config.ts`
  (es2020 → es2024).
- Rewrite `assets/Dockerfile` self-contained (context `assets/`; drop the `deps/` COPYs; awscli from the edge
  `dist/`; pnpm via corepack; `ENTRYPOINT bin/edge-deploy.sh`). Update `assets/fly.toml`
  (`dockerfile = "Dockerfile"`; the deploy command).
- Relocate `scripts/edge-deploy.sh` → `assets/bin/edge-deploy.sh` (fix the `cd`; `npm ci && npm run build` →
  `pnpm install --frozen-lockfile && pnpm build`; the header doc-links).
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
(grep/build/context/test-runner); the npm→pnpm, es2020→es2024, and jest→vitest moves are mechanical and
grep-checkable. The load-bearing risk is **INV-VENDORED-FAITHFUL** (§5): a phoenix/phoenix_live_view rewrite
can compile green yet break the live lobby at runtime — gate-invisible to a pure `vite build`. So the verify
**must** include a runtime LiveSocket-boot smoke (A4), and the edge path is exercised with the `--dry-run`
reliability gate (A11). **As shipped (13/14):** A4 is the load-bearing gate and was mutation-proven; the
vendored vitest suites (A13) are **DEFERRED to cm-tma.2** (the `test/*.test.ts` files are unported upstream
jest — §10 A13), so A4 carries the INV-VENDORED-FAITHFUL faithfulness for this rung. Secondary external-facing concern: the edge
**publish** path — mitigated because the publish contract (pointer, cache, ABI) is held byte-stable (§9) and
the deploy stays the Operator's.

## 15. Boundary

`echo/apps/codemojex/assets/**` (the workspace, `pnpm-workspace.yaml`, `pnpm-lock.yaml`, `packages/*`,
`tsconfig.json`, both vite configs, `Dockerfile`, `fly.toml`, `bin/edge-deploy.sh`) +
`echo/docs/edge-deliver/edge-bucket-setup.md` (the awscli pre-stage step) + these specs
(`docs/codemojex-tma/specs/cm-tma.1.*`). **Out of bounds:** `lib/codemojex/**`, the engine release
(`echo/Dockerfile`, `echo/fly.toml`), every sibling umbrella app, `mix.lock`, and the umbrella `config/`. A
change reaching the engine or a sibling app is out of scope — stop and re-scope.

## 16. Build brief

The packages are **prepared on disk**; this rung **completes** the wiring + cleanup + relocation.
Smallest-change-first, each step independently checkable:

1. **Workspace** — add `assets/pnpm-workspace.yaml` (`packages: ["packages/*"]`); convert `assets/package.json`
   deps to `@echo/* : workspace:*`; ensure `@echo/phoenix_live_view` declares `morphdom` + `phoenix`
   (`workspace:@echo/phoenix@*`); `pnpm install` → commit `pnpm-lock.yaml`. (A1/A2/A14)
2. **jest→vitest + the subpath export** — on `@echo/phoenix_live_view`'s `package.json`: drop the jest
   devDeps **and the registry `"phoenix": "1.7.21"` devDep** (line 40 — it shadows the `workspace:@echo/phoenix@*`
   dependency added in step 1); extend `exports` to `{ ".": "./src/index.ts", "./phoenix_html": "./src/phoenix_html.ts" }`
   (the subpath that resolves `phoenix_html`, §5); set `test: "vitest"`; prune the upstream
   `npm run`/`mix`/`e2e`/playwright scripts; fix `types`/`files` to the vendored `src/` layout.
   the package.json end-state jest-free (`grep jest` over devDeps/scripts/config → 0). **A13 (both suites
   green) is DEFERRED to cm-tma.2** — the `test/*.test.ts` files remain unported upstream jest (§10 A13).
3. **es2024** — `assets/tsconfig.json` (`target`+`lib`) + `assets/vite.config.ts` + `assets/vite.client.config.ts`
   (es2020 → es2024); `grep es2020` → 0. (A12)
4. **Prove standalone** — `rm -rf node_modules && pnpm install && pnpm build && pnpm build:client` with no
   `deps/` reachable (A1/A2/A3); then the **runtime boot smoke** (A4).
5. **Self-contained image** — rewrite `assets/Dockerfile` (context `assets/`; corepack/pnpm; drop `deps/`
   COPYs; awscli from the edge `dist/`; `ENTRYPOINT bin/edge-deploy.sh`); update `assets/fly.toml` (A5/A6).
6. **Relocate** `scripts/edge-deploy.sh` → `assets/bin/edge-deploy.sh` (fix the `cd`; npm→pnpm; the doc-links)
   (A7).
7. **Pre-stage docs** — add the awscli `dist/` upload step to `edge-bucket-setup.md` (A6); the upload itself
   is the Operator's.
8. **Gate** — A1–A12 + A14 (**A13 DEFERRED to cm-tma.2**); the `--dry-run` reliability gate (A11) is the
   canonical green; the boundary check (A10) confirms the engine + `lib/` + `mix.lock` are untouched.

**Files (boundary `echo/apps/codemojex/assets/**` + the bucket doc + these specs):** `pnpm-workspace.yaml` +
`pnpm-lock.yaml` (new) · `package.json` (workspace finish) · `packages/phoenix_live_view/package.json`
(jest→vitest + pnpm) · `tsconfig.json` + `vite.config.ts` + `vite.client.config.ts` (es2024) · `Dockerfile`
(rewrite) · `fly.toml` (rewrite) · `bin/edge-deploy.sh` (moved from `scripts/`) ·
`echo/docs/edge-deliver/edge-bucket-setup.md` (the pre-stage step). **Unchanged:** `js/app.js` (already on the
`@echo/*` imports), `src/**` (the swap ABI), `lib/codemojex/edge.ex`, `echo/Dockerfile`, `echo/fly.toml`,
`mix.lock`.
