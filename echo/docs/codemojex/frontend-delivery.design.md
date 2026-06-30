# Codemojex · Frontend Delivery — the Dynamic Load (design + Mars brief)

> **Status:** design BUILD-GRADE. One genuine fork for the Operator (the **pull mode**, §3) +
> two minor forks (§6). Mars builds from §5. Author: Venus. Implementor: Mars. The Director
> verifies + commits when asked.

How the codemojex browser frontend is built and delivered after the source reorg
(`echo/apps/codemojex/assets/` → `mercury/codemojex/apps/game/` + `mercury/packages/phoenix*`).
Three tiers, two homes:

| Tier | Asset | Built in | Committed to git? | Changes |
|---|---|---|---|---|
| **phoenix\*** (ship-with) | `phoenix.js` · `phoenix_live_view.js` | Mercury (build **once**) | **yes** → `echo/apps/codemojex/priv/static/assets/` | rarely (lib bump) |
| **host** (boot) | `app.js` (trivial init) · `app.css` | hand-authored (no bundle) | **yes** → same dir | rarely |
| **game** (dynamic load) | `game-<hash>.js` | Mercury | **no** → pushed to Tigris, **pulled** by Phoenix | often (every iteration) |

The Operator's intent, decoded and confirmed by the reconcile (§0):

1. **phoenix\* = build-once, commit-to-git.** `@echo/phoenix`/`@echo/phoenix_live_view` are the
   successors to Phoenix's Hex-shipped `phoenix.js`/`phoenix_live_view.js`. They are built **once**
   in Mercury as standalone ESM modules and the **built modules are committed**. `app.js` becomes a
   trivial initializer that *imports* them via an **import map** — not a fat IIFE that inlines them.
2. **game = push/pull split.** A deliver script builds `@codemojex/game` and **pushes** it to the
   Tigris edge bucket (Operator-run, **never on app boot**). Separately, **Phoenix pulls** the new
   version and **safe-hot-replaces** the served game bundle — no restart, no half-served file.
3. **All JS tooling stays in `mercury/`.** Both build scripts live in Mercury and write into
   `echo/apps/codemojex/priv/static/...` via **absolute** paths (never a fragile `../priv`).

---

## 0. Reconcile — as-built vs the gap

The reorg moved the frontend source but left the build configs and several docs carrying **stale
relative paths** that assumed the old `assets/` home. The last-good build *outputs* are still
committed in `priv/static/` (so the app still serves), but every config that rebuilds them is broken.

**Delta table** (every claim cited; classify MATCH / STALE / BUG / SUPERSEDED / MISSING):

| # | Claim / surface | Cite | Class | Correction |
|---|---|---|---|---|
| R1 | game island outDir `../priv/static/game` | `mercury/codemojex/apps/game/vite.config.ts:21` | **STALE** | from the new home resolves to `mercury/codemojex/apps/priv/...`; retarget to the absolute echo path via the existing `r()` helper |
| R2 | host build `input:"js/app.js"`, `outDir:"../priv/static/assets"`, IIFE | `mercury/codemojex/apps/game/vite.client.config.ts:9,13` | **STALE → RETIRE** | both paths broken from the new home; the new design serves `app.js` raw (no bundle) — retire this config |
| R3 | `phoenix_live_view` vite emits `fileName:()=>"phoenix.js"`, no `external` | `mercury/packages/phoenix_live_view/vite.config.ts:18` | **BUG** | name collision with phoenix.js; must emit `phoenix_live_view.js` **and** externalize `phoenix` |
| R4 | phoenix vite emits `phoenix.js`, no outDir (→ `dist/`), no external | `mercury/packages/phoenix/vite.config.ts:18` | **MATCH** (phoenix has zero deps) | leave the lib config; the orchestration script copies `dist/phoenix.js` → echo |
| R5 | LV imports `phoenix` **type-only**; `morphdom` real | `phoenix_live_view/src/live_socket.ts:1`, `dom_patch.ts:27` | **MATCH** (informs R3) | externalize `phoenix` (defensive + correct); **bundle** morphdom |
| R6 | deliver script `cd …/.. ; OUT="../priv/static/game"` | `mercury/codemojex/apps/game/bin/edge-deploy.sh:95,99` | **STALE** | retarget OUT to the absolute echo path (same break as R1) |
| R7 | deliver-script header cites `assets/bin/edge-deploy.sh`, `echo/docs/edge-deliver/…` | `edge-deploy.sh:13,15,17,19` | **STALE** | fix the header to the Mercury home |
| R8 | `Edge.game_url/0` resolves the **cross-origin** edge URL (= Arm A) | `echo/apps/codemojex/lib/codemojex/edge.ex:28-33` | **MATCH** (status quo) | Arm B adds a same-origin serve layer behind it (§3) |
| R9 | `GameLive` `game_bundle: Edge.game_url()` → `data-bundle` | `…/live/game_live.ex:33,48` | **MATCH** | Arm B changes only the **string** returned; the hook contract is unchanged |
| R10 | `root/1` loads `app.js` as a classic script (`type="text/javascript"`) | `…/components/layouts.ex:22` | **MATCH** | refactor to `type="module"` + an import map + modulepreload (§1, §2) |
| R11 | "**No** committed prebuilt `priv/static/<lib>.esm.js`" (INV-1) | `phoenix-client-resolution.md:282` | **SUPERSEDED** | the new direction **commits** `phoenix.js`/`phoenix_live_view.js`; that doc's §6 INV-1/§3.4 must be reconciled |
| R12 | `edge.ex` moduledoc + `edge-bucket-setup.md` cite `scripts/edge-deploy.sh` | `edge.ex:12,17`; `edge-bucket-setup.md:5,139` | **STALE** doc cites | follow-on doc-sync (low priority; Operator decides scope) |
| R13 | Tigris edge bucket = `codemojex-edge-deliver` | `edge-bucket-setup.md:38,59` | **MATCH** | the Operator's word "codemojex-edge-deliver" = this bucket/op; the deliver script keeps its proven discipline |

**New surfaces this design introduces** (forward-tense, MISSING → to build): the import map in
`root/1`; the committed `phoenix.js`/`phoenix_live_view.js`; the phoenix-modules build script;
and — **only if Arm B is chosen** — `Codemojex.GameBundle` (pull + in-memory cache + safe swap),
`CodemojexWeb.GameBundleController`, and a `/game-bundle/:file` route.

**Verdict: BUILD-GRADE.** The phoenix\* tier (§1) and the app.js refactor (§2) are **fork-free** —
Mars can build them immediately. The game pull tier (§3) waits on the Operator's arm choice; Arm B
is recommended and low-regret (it matches the Operator's words and is additive behind `Edge`).

---

## 1. The phoenix\* "ship-with" tier

**Goal:** two standalone, committed ESM modules in `echo/apps/codemojex/priv/static/assets/`:
`phoenix.js` (the `Socket`/channels client) and `phoenix_live_view.js` (`LiveSocket` + the hook
lifecycle). Built **once** in Mercury; `app.js` imports them by their bare specifiers, resolved by an
import map.

### 1a. The externalization contract (one phoenix instance — load-bearing)

`phoenix.js` has **zero dependencies** (`@echo/phoenix/package.json` declares none), so it is
self-contained — no externals, no bare imports survive. `mercury/packages/phoenix/vite.config.ts` is
correct as-is; the build emits `dist/phoenix.js`.

`phoenix_live_view.js` depends on `morphdom` (registry) and `phoenix` (workspace). Its source imports
`phoenix` **type-only** (`import { type Socket, type Channel } from "phoenix"` — erased at compile)
and `morphdom` at runtime (`import morphdom from "morphdom"`). The fix to
`mercury/packages/phoenix_live_view/vite.config.ts`:

```ts
build: {
  target: "es2024",
  cssCodeSplit: false,
  lib: {
    entry: resolve(__dirname, "src/index.ts"),
    formats: ["es"],
    fileName: () => "phoenix_live_view.js",   // ← was "phoenix.js" (collision)
  },
  rollupOptions: {
    external: ["phoenix"],                     // ← the one committed phoenix.js, via the import map
  },
}
// morphdom stays BUNDLED (not external) — only LiveView uses it; simplest, no second import-map entry.
```

Why externalize `phoenix` even though its current imports are type-only: it is **correct and
defensive**. If any runtime `phoenix` import exists now or later, externalizing forces the browser to
resolve it through the import map to the **single** committed `phoenix.js` — never a second bundled
copy (two `Socket` classes = a `LiveSocket` that cannot authenticate the socket it was handed). If
no runtime import survives, the external is simply unused. Either way: **exactly one phoenix
instance.** (Mars verifies this empirically — §5 gate G4.)

### 1b. The import map (in `Layouts.root/1`)

The browser resolves the bare specifiers `app.js` imports. The map is server-rendered in `<head>`
and **must precede** the first `type="module"` script. Use Phoenix verified routes (`~p"/assets/…"`)
so cache-busting matches today's `app.js` exactly:

```heex
<script type="importmap">
  {
    "imports": {
      "@echo/phoenix": "<%= ~p"/assets/phoenix.js" %>",
      "@echo/phoenix_live_view": "<%= ~p"/assets/phoenix_live_view.js" %>",
      "phoenix": "<%= ~p"/assets/phoenix.js" %>"
    }
  }
</script>
```

(`"phoenix"` is mapped defensively per §1a; harmless if unused. The exact HEEx interpolation form is
Mars's to settle against the sigil — the contract is **these three keys → these two files**.)

**Cache story — fixed names, not content-hashed.** These modules are stable (change only on a lib
bump). Fixed names (`phoenix.js`, `phoenix_live_view.js`) keep the import map static and the diff
trivial. Cache invalidation rides the **same mechanism as the existing `app.js`**: the `~p` verified
route + `phx-track-static`, so a committed change busts the cache exactly as an `app.js` change does
today — no new machinery. (Content-hashing is the §6 minor fork; fixed-name is recommended.)

---

## 2. The `app.js` boot refactor (player UX is the goal)

`app.js` keeps its **canonical source** at `echo/apps/codemojex/assets/js/app.js` (plain ESM, no
TS/JSX). It is no longer bundled — it is the Operator's "trivial initialization": it imports phoenix +
phoenix_live_view (resolved by the import map), defines the `EdgeReact` hook, and boots `LiveSocket`.
**The body of `app.js` does not change** — only how it is delivered:

- It is **copied raw** (no transpile) into `priv/static/assets/app.js` by the build script (§4b),
  replacing the 137 KB IIFE with the ~2.4 KB module.
- The `vite.client.config.ts` IIFE builder is **retired** (R2); the `build:client`/`dev` package
  scripts that point at it are removed or repointed (§4b).

### 2a. The `<head>` boot sequence (the Operator's "boot and import efficiently for the player")

Edit `Layouts.root/1` (`layouts.ex:11-30`). Target order in `<head>`:

```heex
<meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
<.live_title default="Codemoji">{assigns[:page_title]}</.live_title>

<%!-- warm the phoenix modules in PARALLEL with app.js (HTTP/2 multiplexed) — kills the waterfall --%>
<link rel="modulepreload" href={~p"/assets/phoenix.js"} />
<link rel="modulepreload" href={~p"/assets/phoenix_live_view.js"} />

<%!-- the import map MUST precede the first module script --%>
<script type="importmap"> … (§1b) … </script>

<script src="https://telegram.org/js/telegram-web-app.js"></script>
<link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />

<%!-- module scripts defer by default; keep phx-track-static --%>
<script type="module" phx-track-static src={~p"/assets/app.js"}></script>
```

**Why this is fast for the player:**

- **No waterfall.** Without `modulepreload`, the browser discovers `phoenix.js`/`phoenix_live_view.js`
  only *after* fetching and parsing `app.js` — a serial chain (html → app.js → phoenix → LV). The two
  `modulepreload` links let the browser fetch all three modules **concurrently** over the one HTTP/2
  connection, so the LiveSocket boot graph is in cache by the time `app.js` runs.
- **Module scripts are deferred by default** — `app.js` runs after the document parses, so first
  paint (the LiveView-rendered shell) is never blocked by the socket boot.
- **The game island stays lazy.** `EdgeReact.mounted()` still `await import(bundle)`s the game only
  after `#game-root` mounts (post-first-paint). Under Arm B (§3) that import is **same-origin**, so
  the player's critical path carries no cross-origin DNS/TLS handshake to `edge.codemoji.games`.
- **Optional game preload.** In `GameLive.render/1` (`game_live.ex:41`), emit
  `<link rel="modulepreload" href={@game_bundle} />` beside `#game-root` so the resolved game bytes
  warm while LiveView boots. Cheap, strictly additive.
- **Optional (3rd-party):** `telegram-web-app.js` is render-blocking today (no `defer`). Adding
  `defer` would unblock parse; defer it only if the app reads `window.Telegram.WebApp` no earlier
  than the (deferred) `app.js`/the React mount — which is the case. Flagged as a boot-UX nicety, not
  required; it is a 3rd-party contract, so leave it unless the Operator wants the tweak.

---

## 3. The game tier — deliver + pull + safe hot replace (THE dynamic load)

Two **decoupled** halves. **Delivery never happens on app boot/restart; Phoenix only ever pulls.**

### 3a. Deliver (push) — Operator-run

`codemojex-edge-deliver` (the evolution of `bin/edge-deploy.sh`, §4a) builds `@codemojex/game` and
uploads to the `codemojex-edge-deliver` Tigris bucket, preserving the proven discipline already in the
script: **upload every `game-<hash>.js` immutably FIRST, flip `manifest.json` (short cache) LAST**, so
the pointer never names a missing file; `--dry-run` and `--rollback game-<hash>.js` retained. Only the
**paths** change for the Mercury home (§4a). This publishes to a live bucket — the **Operator runs
it**, never the app.

### 3b. THE FORK — how Phoenix gets the new bundle

The Operator's words — *"Phoenix pull new version and safe hot replace Game bundle… delivered with
app"* — describe a server-side pull and a same-origin serve. The status quo does **not** do that (the
browser imports cross-origin straight from the edge). This is the one genuine fork.

**Arm A — cross-origin pointer (status quo, minimal).** Keep `Edge.game_url/0` resolving the edge URL;
the browser imports cross-origin; "hot replace" = the pointer flip + the 10 s TTL.
- *Pro:* zero new surface; no prod-fs/memory concerns.
- *Con:* a cross-origin DNS/TLS handshake to `edge.codemoji.games` on **every** page-load's critical
  path; depends on edge reachability per page-load; it is **not** "delivered with app" / same-origin.

**Arm B — server-side pull → serve same-origin (RECOMMENDED).** Phoenix pulls the hashed bundle
**bytes** from Tigris and serves them **same-origin**, swapping the served version atomically. This is
what the Operator described, and it is the better player experience.
- *Pro:* same-origin import (no cross-origin handshake on the critical path — the win on slow Telegram
  mobile); survives edge blips after the first pull (resilience); "delivered with app".
- *Con:* a small new surface (a cache + a controller + a route); Phoenix does egress to Tigris at
  **pull time** (not per page-load).

**Where the pulled bytes live (Arm B sub-option) — in-memory (RECOMMENDED).** Hold the bytes in
`:persistent_term`; serve from a tiny controller. **No writable dir** — the Phoenix release bakes
`priv/static` at image build (there is no JS build step in the image — `livereact-hot-swap.md §1`),
and a runtime FS is ephemeral / not shared across machines, so writing pulled bytes back to disk is
fragile. ~190 KB in memory per machine is nothing. "Safe hot replace" = **fetch fully, then atomic
`:persistent_term.put`** — the old bytes keep serving until the new bytes are completely in hand; a
half-fetched bundle is never served. The alternative (a writable runtime dir + `Plug.Static{at:"/…",
from: dir}` + write-temp→rename) is heavier and needs a writable mount; documented, not recommended.

> **Recommendation: Arm B, in-memory.** It matches the Operator's words, gives the player a same-origin
> critical path, and the in-memory sub-option sidesteps the read-only/ephemeral-fs question entirely.

### 3c. Arm B design (concrete; the engine contract is unchanged)

```
codemojex-edge-deliver (Operator)         Phoenix (Codemojex.GameBundle)            browser
  build @codemojex/game ──► upload          read manifest.json pointer (httpc) ──┐
  game-<hash>.js immutable                  GET game-<hash>.js BYTES from edge   │ fetch FULLY
  flip manifest.json (last) ──────────────► atomic :persistent_term.put {hash,bytes}  ← SWAP
                                            serve same-origin via the controller ──► import(/game-bundle/…)
```

- **`Codemojex.Edge`** stays the pointer resolver (it already reads `manifest.json` → the current
  hash via `:httpc`, cached 10 s; `edge.ex:28-66`). **Reuse it unchanged** to learn *which* hash is
  current.
- **`Codemojex.GameBundle`** (NEW, forward-tense) — the pull + cache + swap:
  - learns the current hash from `Edge` (the pointer), then GETs the `game-<hash>.js` **bytes** from
    the edge host (`:httpc`, reusing `:inets`/`:ssl` exactly as `Edge` does — **no new dependency**);
  - holds `{hash, bytes, content_type}` in `:persistent_term`; **safe swap** = put the new tuple only
    after the full body is fetched (refresh lazily on a TTL on the render path, mirroring `Edge`, or
    on a small interval — Mars's call within this contract);
  - exposes `src/0` → the **same-origin** path `~p"/game-bundle/#{file}"` for the current hash (the
    string that goes into `data-bundle`), and `fetch/1` for the controller.
- **`CodemojexWeb.GameBundleController.show/2`** (NEW) — serves the cached bytes for `:file` with
  `content-type: text/javascript` and a **long immutable** cache (the filename is content-hashed →
  immutable; only the *pointer* moves, resolved server-side). Same-origin ⇒ no CORS.
- **Route (NEW) — mind the collision.** `live "/game/:gam"` already exists (`router.ex:42`), so a
  `/game/<hash>.js` path would be **captured by the LiveView route** (`gam = "game-<hash>.js"`). Mount
  the bundle under a **distinct prefix**: `get "/game-bundle/:file", GameBundleController, :show` in a
  **public** scope (no `:browser`/auth — a JS module needs no session and should be cacheable). It is
  not under `/assets` (Plug.Static) and not under `/game` (LiveView), so it collides with neither.
- **`GameLive`** (`game_live.ex:33`): the **one-line** change `game_bundle: Edge.game_url()` →
  `game_bundle: Codemojex.GameBundle.src()`. `data-bundle`, the `EdgeReact` hook, `game_props`, and
  the `mount(el, props, bridge)` engine contract are **all unchanged** — the cross-swap contract
  (`mount` signature · `GameProps` · the bridge events · `apiVersion`) is exactly as
  `livereact-hot-swap.md §7` states.
- **Failure stays non-fatal:** if the pull fails, serve the last-good cached bytes; if the cache is
  empty (cold start before any pull), `src/0` returns `nil` → `data-bundle` empty → the shell renders,
  the game does not mount (the existing deferred state). The `GAME_ASSET_URL` fallback semantics in
  `Edge` are preserved as the cold-start/escape hatch.

> **Migration note:** today the app is effectively **Arm A**. Arm B is **additive behind `Edge`** —
> `GameLive` flips one assign source; nothing else in the render/hook path moves. If the Operator
> picks Arm A, drop §3c entirely and ship only §1+§2+§4.

---

## 4. The two build-script contracts (both in `mercury/`, cwd-independent, absolute outputs)

Both scripts live under **`mercury/codemojex/apps/game/bin/`** (the codemojex-specific home — the
Operator's "JS tooling stays in mercury", co-located with the existing `edge-deploy.sh`). Both derive
an **absolute** script dir (`SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"`) and absolute echo targets —
never a fragile `../priv`. A path constant both share:

```
ECHO_STATIC="$SCRIPT_DIR/../../../../../echo/apps/codemojex/priv/static"   # Mars VERIFIES this resolves
```

> Mars must **verify the relative depth empirically** (`cd "$SCRIPT_DIR" && realpath …`), not trust
> the count — `mercury/codemojex/apps/game/bin` → repo root is the load-bearing hop.

### 4a. `codemojex-edge-deliver` — game → Tigris (evolve `bin/edge-deploy.sh`)

Keep the existing script's whole body and its proven discipline; **change only the paths** (R6, R7):

- the build step `OUT=` → `"$ECHO_STATIC/game"` (absolute), replacing `cd …/.. ; OUT="../priv/static/game"`;
- the vite manifest read (`$OUT/.vite/manifest.json`) and the `game-*` upload loop unchanged;
- fix the header comment block (canonical path, the setup-doc link) to the Mercury home;
- retain `--dry-run`, `--rollback game-<hash>.js`, the upload-immutable-then-flip-pointer-last order,
  the `TIGRIS_EDGE_*` env contract.
- **It also refreshes what Phoenix pulls:** the `manifest.json` pointer flip *is* that refresh — under
  Arm B, Phoenix re-reads the same pointer to learn the new hash. No extra step; the pointer is the
  single source of "what's current" for both arms.

Naming: keep the file `bin/edge-deploy.sh` (preserves git history + the `--dry-run`/`--rollback`
contract); expose the Operator-facing verb via a package script (§4c). Literal rename to
`codemojex-edge-deliver` is the §6 minor fork.

### 4b. `phoenix-modules-build` — phoenix\* → committed ESM (+ copy app.js)

A new script `mercury/codemojex/apps/game/bin/phoenix-modules-build.sh`. Contract:

```
1. build both lib packages (each emits dist/<name>.js per §1):
     pnpm --filter @echo/phoenix build              → mercury/packages/phoenix/dist/phoenix.js
     pnpm --filter @echo/phoenix_live_view build     → mercury/packages/phoenix_live_view/dist/phoenix_live_view.js
2. copy the two dist modules into the committed home (absolute paths):
     cp mercury/packages/phoenix/dist/phoenix.js                       "$ECHO_STATIC/assets/phoenix.js"
     cp mercury/packages/phoenix_live_view/dist/phoenix_live_view.js   "$ECHO_STATIC/assets/phoenix_live_view.js"
3. copy app.js RAW (no transpile) into the committed home:
     cp echo/apps/codemojex/assets/js/app.js                          "$ECHO_STATIC/assets/app.js"
4. (optional) print the resulting byte sizes for the commit message.
```

**Why a copy step, not a package `outDir` into echo:** the phoenix\* packages are app-agnostic
vendored libs — they must not hardcode a codemojex output path. The **codemojex-specific** wiring (the
copy into codemojex's `priv/static`) lives in the **codemojex** game workspace, where it belongs.
"Build once… keep in git" → the three copied files are committed.

### 4c. Package scripts (the Operator-facing verbs)

In `mercury/codemojex/apps/game/package.json` `scripts`:

- replace the retired `build:client`/`dev` (R2) with `"deliver": "bin/edge-deploy.sh"` (or
  `codemojex-edge-deliver` per the §6 rename) and `"phoenix:build": "bin/phoenix-modules-build.sh"`;
- keep `"build": "vite build"` (the game island, now writing to the absolute `$ECHO_STATIC/game` via
  the R1-fixed `vite.config.ts`).

Recommendation: the two **shell scripts in `bin/`** are the source of truth (they own the path logic
and the env contract); the `package.json` entries are thin verbs that call them. Honors "JS tooling
stays in mercury".

---

## 5. The Mars brief — ordered, gated build checklist

Build in this order; each step cites the file it touches. **Stop at the §3/§6 forks** until the
Operator rules — but §1–§2 + §4b are fork-free, build them first.

**Wave 1 — phoenix\* ship-with tier (fork-free)**
1. Fix `mercury/packages/phoenix_live_view/vite.config.ts:18` → `fileName: () => "phoenix_live_view.js"`
   + add `rollupOptions: { external: ["phoenix"] }` (§1a). Leave `mercury/packages/phoenix/vite.config.ts`.
2. Write `mercury/codemojex/apps/game/bin/phoenix-modules-build.sh` (§4b); make it executable.
   Run it; confirm `phoenix.js`, `phoenix_live_view.js`, `app.js` land in
   `echo/apps/codemojex/priv/static/assets/`.

**Wave 2 — app.js boot + import map (fork-free)**
3. Edit `Layouts.root/1` (`echo/apps/codemojex/lib/codemojex_web/components/layouts.ex:11-30`): add
   the `modulepreload` links + the import map (§1b) **before** the script, change the `app.js` tag to
   `type="module"` (§2a). (Leave `app.js`'s source body unchanged.)
4. Retire `mercury/codemojex/apps/game/vite.client.config.ts` (R2); fix the game island outDir in
   `mercury/codemojex/apps/game/vite.config.ts:21` to the absolute `$ECHO_STATIC/game` (R1); update
   `package.json` scripts (§4c).

**Wave 3 — game deliver (fork-free path fix)**
5. Fix the paths + header in `mercury/codemojex/apps/game/bin/edge-deploy.sh` (§4a, R6/R7). Do **not**
   change the upload/flip logic.

**Wave 4 — game pull + safe hot replace (BUILD ONLY IF Operator picks Arm B, §3)**
6. Add `Codemojex.GameBundle` (pull + `:persistent_term` cache + atomic swap + `src/0`) reusing the
   `Edge` httpc pattern — **no new dep** (§3c).
7. Add `CodemojexWeb.GameBundleController.show/2` + `get "/game-bundle/:file", …` in a **public** scope
   (`echo/apps/codemojex/lib/codemojex_web/router.ex` — **not** under `/game` or `/assets`, §3c).
8. `GameLive` (`game_live.ex:33`): `game_bundle: Edge.game_url()` → `Codemojex.GameBundle.src()`.
   Optional: the game `modulepreload` in `render/1` (§2a).

### Verification gate (Mars passes ALL before reporting)

| G | Check | How |
|---|---|---|
| G1 | the two phoenix modules build + land committed | run `phoenix-modules-build.sh`; `ls priv/static/assets/{phoenix,phoenix_live_view,app}.js` |
| G2 | distinct filenames, no collision | `phoenix_live_view.js` ≠ `phoenix.js`; both non-empty |
| G3 | morphdom is **bundled** into LV | `grep -E 'from ?"morphdom"' priv/static/assets/phoenix_live_view.js` → **0** hits |
| G4 | **one phoenix instance** | `grep -E 'from ?"phoenix"' priv/static/assets/phoenix_live_view.js` → either 0 (type-erased) or only the externalized bare `"phoenix"` the import map covers; **no inlined second Socket** |
| G5 | the import map resolves | the three keys (`@echo/phoenix`, `@echo/phoenix_live_view`, `phoenix`) → the two real files; map precedes the module script |
| G6 | app.js serves as a module | `priv/static/assets/app.js` is the ~2.4 KB raw module (not the 137 KB IIFE); tag is `type="module"` |
| G7 | the game still mounts via `mount(el,props,bridge)` | the `index.tsx` export + `EdgeReact` path unchanged |
| G8 | deliver runs clean | `bin/edge-deploy.sh --dry-run` builds + lists the upload/flip with the **correct absolute** `priv/static/game` path (no `mercury/.../apps/priv`) |
| G9 | **(Arm B)** pull+swap exercised | a unit/integration check: seed two hashes, assert `src/0` flips atomically and the controller serves the cached bytes with `content-type: text/javascript`; no half-served bundle |
| G10 | Elixir gates | from `echo/apps/codemojex`: `TMPDIR=/tmp mix compile --warnings-as-errors` + `TMPDIR=/tmp mix test` clean |
| G11 | Mercury gates | from `mercury/`: `pnpm --filter @echo/phoenix build` + `--filter @echo/phoenix_live_view build` + `--filter @codemojex/game build` clean |

**Boundaries:** Mercury changes → a `mercury/...` pathspec commit; echo changes → a separate
`echo/...` pathspec commit (the git root is `jonnify`; never `git add -A`). `TMPDIR=/tmp` for all
`mix`. **Commits are Director-run, only when asked.** Mars edits no spec/design doc (that is Venus).
Framing in any sub-brief: no gendered pronouns for agents; no perceptual/interior-state verbs; no
first-person narration.

---

## 6. Forks for the Operator

**F1 — Pull mode (the genuine one, §3).** *Rationale:* "delivered with app / Phoenix pull / safe hot
replace" vs minimal change. *Arms:* **A** cross-origin pointer (status quo, zero new surface, but a
cross-origin handshake on every page-load and not same-origin) · **B** server-side pull → same-origin
serve, **in-memory** (matches the Operator's words, best player critical path, ~190 KB/machine, a small
new surface). *Recommendation:* **Arm B, in-memory** — it is what the Operator described and the
in-memory sub-option moots the read-only-fs question. *One-line why:* same-origin import removes a
cross-origin DNS/TLS hop from the player's critical path and "delivers with the app".

**F2 — phoenix module cache strategy (minor).** *Arms:* **fixed-name** `phoenix.js`/`phoenix_live_view.js`
+ `~p`/`phx-track-static` busting (mirrors `app.js`, static import map) · **content-hashed**
(`phoenix-<hash>.js`, longest cache, but the import map must be regenerated each lib bump).
*Recommendation:* **fixed-name** — these modules change rarely; simplicity wins, and busting already
works for `app.js`.

**F3 — deliver-script name (minor).** *Arms:* keep `bin/edge-deploy.sh` (preserves git history + the
`--dry-run`/`--rollback` contract; expose the verb via a `deliver` package script) · rename the file to
`codemojex-edge-deliver` to match the Operator's word literally. *Recommendation:* **keep the filename,
add the `deliver` verb** — same behavior, no history churn. Trivial to flip if the Operator prefers the
literal name.

---

## 7. Map

Reconciled-against (as-built): `mercury/codemojex/apps/game/{vite.config.ts, vite.client.config.ts,
bin/edge-deploy.sh, package.json, src/index.tsx}` · `mercury/packages/{phoenix,phoenix_live_view}/{vite.config.ts,
package.json}` · `echo/apps/codemojex/assets/js/app.js` · `echo/apps/codemojex/lib/codemojex_web/{components/layouts.ex,
live/game_live.ex, router.ex}` · `echo/apps/codemojex/lib/codemojex/edge.ex`.
Superseded/owed doc-sync: `phoenix-client-resolution.md` (§6 INV-1, §3.4) · `livereact-hot-swap.md`
(the `assets/` paths) · `edge-bucket-setup.md` + `edge.ex` moduledoc (the `scripts/edge-deploy.sh`
cites). Adjacent: `render-stack.md` · `rendering.md` · `dev-and-testing.md`.
