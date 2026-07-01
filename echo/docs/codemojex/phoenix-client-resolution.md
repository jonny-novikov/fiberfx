# Codemojex · How the Phoenix JS Client Resolves (`@echo/phoenix` · `@echo/phoenix_live_view` · `phoenix_html`)

How a front-end `import { LiveSocket } from "…"` actually finds the Phoenix LiveView JavaScript, in
**two** worlds: the **upstream** world (`echo/deps/phoenix_live_view/`, the way a stock Phoenix app
resolves it) and the **Jonnify Echo Team Pragmatic Approach** (the vendored `@echo/*` workspace under
`assets/packages/`, the cm-tma.1 direction). It also answers the load-bearing question this raises:
with only **two** scoped entries, where does `phoenix_html.js` go?

> **TL;DR.** Upstream, `import "phoenix_live_view"` resolves to a **prebuilt bundle** the Hex package
> ships in its `priv/static/` (`phoenix_live_view.esm.js`, ~239 KB) — the host imports an *artifact*,
> built by the library's own toolchain, which is why the front-end build needs `mix deps.get` + the
> umbrella. The Jonnify approach **vendors the source instead of the artifact**: `@echo/phoenix` and
> `@echo/phoenix_live_view` export `./src/index.ts` directly, so the host's **vite** compiles them
> in-tree (one build, es2024, real tree-shaking, no `deps/`). `phoenix_html` becomes **not a third
> package** but a companion module inside LiveView — resolved via a **subpath export**
> `@echo/phoenix_live_view/phoenix_html`, opted into explicitly. (Today it is vendored but unwired —
> §4.)

This pairs with the cm-tma.1 spec
([`docs/codemojex-tma/specs/cm-tma.1.md`](../../../docs/codemojex-tma/specs/cm-tma.1.md)) and the render
stack ([`render-stack.md`](render-stack.md)).

---

## 1. The fork: ship the *artifact*, or ship the *source*?

A "Phoenix JS library" is unusual: it is an **Elixir Hex package that also behaves as an npm package**.
`mix deps.get` fetches it into `echo/deps/<lib>/`, and that directory contains *both* the TypeScript
source **and** a set of pre-bundled JavaScript artifacts. So a host app has two ways to consume it:

- **Consume the prebuilt artifact** (the upstream default): link the dep by path and let the bundler
  resolve `package.json` → `priv/static/<lib>.esm.js`. The library was already built by *its* maintainers.
- **Consume the source** (the Jonnify approach): copy the `.ts` into a workspace package that exports
  `./src/index.ts`, and let *your* bundler build it as part of *your* build.

The rest of this doc walks both, then states the convention for `phoenix_html`.

## 2. The upstream flow — `deps/phoenix_live_view/` resolves a *prebuilt* bundle

### 2.1 The dual Hex/npm package on disk

`echo/deps/phoenix_live_view/` (re-probed) carries three things:

```
deps/phoenix_live_view/
  package.json                         ← the npm entry map (points at priv/static/*)
  assets/js/phoenix_live_view/*.ts     ← the TypeScript SOURCE (index.ts, live_socket.ts, dom.ts, …)
  assets/js/types/*.d.ts               ← the shipped type declarations
  priv/static/
    phoenix_live_view.esm.js   (239 KB)  ← the PREBUILT ESM bundle  ← what a host actually imports
    phoenix_live_view.cjs.js             ← the CJS build (require)
    phoenix_live_view.min.js             ← the IIFE/CDN build (unpkg/jsdelivr)
    *.map                                ← source maps back to the .ts
```

The source is shipped for **types and source-maps**, but it is *not* what the host compiles — the host
imports the already-bundled artifact.

### 2.2 The entry map decides the resolution target

`package.json` `exports`/`module`/`main` are what a Node-style resolver reads (real values, re-probed):

| Package (Hex+npm) | Version | `import` (ESM) resolves to | `require` (CJS) | Runtime deps |
|---|---|---|---|---|
| `phoenix` | 1.8.7 | `priv/static/phoenix.mjs` | `priv/static/phoenix.cjs.js` | — |
| `phoenix_live_view` | 1.2.3 | `priv/static/phoenix_live_view.esm.js` | `…cjs.js` | `morphdom@2.7.8` |
| `phoenix_html` | 4.3.0 | *(no `exports`/`module`)* → `main`: `priv/static/phoenix_html.js` | — | — |

`phoenix_live_view`'s map is conditional, with a `types` branch:

```json
"exports": {
  "import": { "types": "./assets/js/types/index.d.ts", "default": "./priv/static/phoenix_live_view.esm.js" },
  "require": "./priv/static/phoenix_live_view.cjs.js"
}
```

### 2.3 The resolution walk (stock Phoenix app)

The host links the dep by relative path — historically `assets/package.json` carried
`"phoenix_live_view": "file:../../../deps/phoenix_live_view"` — then:

```
app.js:  import { LiveSocket } from "phoenix_live_view"
   │
   ▼  bundler module resolution
1. follow the `file:` link → echo/deps/phoenix_live_view/
2. read package.json, pick the ESM condition → exports.import.default
3. resolve → priv/static/phoenix_live_view.esm.js          ← a 239 KB PREBUILT bundle
4. (types come from the `types` condition → assets/js/types/index.d.ts)
   │
   ▼
the host bundles an already-bundled module (opaque to the host's tree-shaker)
```

`morphdom` is declared a runtime dependency of the library; the prebuilt artifact is the shipped unit.
The host never touches the `.ts` source in step 3.

### 2.4 `phoenix_html` upstream — a separate package, a side-effect import

`phoenix_html` is its own package with **no `Socket`/`LiveSocket`-style exports** — its
`priv/static/phoenix_html.js` is a hand-written IIFE that, on load, installs a global `click` listener
to turn `data-method` / `data-confirm` / `data-to` links into real form submits/confirms
(re-probed: `deps/phoenix_html/priv/static/phoenix_html.js:1-84`). A stock app opts in with a **bare
side-effect import** in `app.js`:

```js
import "phoenix"            // Socket
import "phoenix_html"       // ← side effect only: the data-method/confirm link handler
import { LiveSocket } from "phoenix_live_view"
```

LiveView does **not** import `phoenix_html` — the two are independent (the upstream
`phoenix_live_view/.../index.ts` imports only its own modules: `live_socket`, `dom`, `view`, …).

### 2.5 What the upstream resolution costs

Because the resolution target lives in `deps/`, four things follow (the cm-tma.1 §2 problem):

1. **The build context must be the umbrella root** — the image has to `COPY deps/phoenix*` so the
   `file:` links resolve.
2. **`mix deps.get` is a prerequisite** — `deps/phoenix*` only exists after the Elixir step.
3. **No standalone front-end dev** — you cannot build `assets/` on a checkout without the BEAM project.
4. **The bundle is opaque** — a 239 KB pre-bundled ESM module the host can neither re-target (it is
   whatever the library built) nor tree-shake into.

## 3. The Jonnify Echo Team Pragmatic Approach — vendor the *source*, two scoped entries

### 3.1 The creed

> **Vendor the source, not the artifact. The brand is the entry. Build once — at the host's target.
> Own faithfulness; don't assume it.**

1. **Source, not artifact.** Each `@echo/*` package exports its **TypeScript `./src/index.ts`** — so
   there is *one* build (the host's vite), at *one* target (**es2024**), with real tree-shaking and
   debuggable source. No `priv/static/` prebuild, no `mix deps.get` for the front end.
2. **Two scoped entries.** `@echo/phoenix` (channels/`Socket`) and `@echo/phoenix_live_view`
   (`LiveSocket` + the hook lifecycle). A small companion like `phoenix_html` is **not a new package** —
   it folds into the package it belongs with, exposed as a **subpath** (§4).
3. **Self-contained.** `assets/` is its own pnpm workspace (`@codemojex/edge`); nothing escapes it
   (`file:../` is gone), so the edge image builds from `assets/` alone.
4. **Faithfulness is owned.** The vendored source must preserve the exact public surface `app.js`
   consumes — pinned by the packages' **vitest** suites *and* a runtime LiveSocket-boot smoke
   (INV-VENDORED-FAITHFUL); a green `vite build` alone is not sufficient.

### 3.2 The two packages on disk (re-probed)

```
assets/packages/
  phoenix/             package.json  name "@echo/phoenix"            v1.8.8   exports "." → ./src/index.ts
    src/index.ts       exports { Channel, LongPoll, Presence, Serializer, Socket }
  phoenix_live_view/   package.json  name "@echo/phoenix_live_view"  v1.2.3   exports "." → ./src/index.ts
    src/index.ts       exports { LiveSocket, isUsedInput, createHook, ViewHook, Hook, getFileURLForUpload }
    src/phoenix_html.ts  ← the data-method/confirm IIFE, vendored as a companion (see §4)
    (deps: morphdom@2.7.8 registry · phoenix bare → the workspace @echo/phoenix)
```

Each package's entry map points at **source**:

```json
// @echo/phoenix/package.json
"exports": { ".": "./src/index.ts" },
"main": "./src/index.ts",
"types": "./src/index.ts"
```

### 3.3 The resolution walk (vendored)

`liveview-boot/app.ts` imports the **scoped** names (re-probed `app.js:5-6`):

```js
import { Socket } from "@echo/phoenix"
import { LiveSocket } from "@echo/phoenix_live_view"
```

```
vite build (host)
   │
1. read pnpm-workspace.yaml → packages/* are workspace members, linked into node_modules
2. "@echo/phoenix"            → exports["."] → packages/phoenix/src/index.ts            (TS SOURCE)
3. "@echo/phoenix_live_view"  → exports["."] → packages/phoenix_live_view/src/index.ts  (TS SOURCE)
       │  inside it:  import … from "phoenix"   → resolved by the LV package's own dep:
       │                                          phoenix → workspace:@echo/phoenix@*  → @echo/phoenix/src
       │              import … from "morphdom"  → the registry dependency
4. vite compiles the WHOLE graph as one program, tree-shakes it, targets es2024
   │
   ▼
emits the single LiveView client bundle → priv/static/assets/app.js  (IIFE)
```

The host owns every byte of this build: the target, the minification, the shake.

### 3.4 The enabling caveat — `exports` may point at `.ts` *because the host always bundles*

Pointing `exports["."]` at a `.ts` file is a **bundler-only** convention. `vite` / `esbuild` / `rollup`
resolve a package's `exports` to a `.ts` entry and compile it; **Node's native ESM loader would not**
(it cannot execute `.ts`). This is safe here precisely because the codemojex front end is *always* built
through vite — both the LiveView boot (`liveview-boot/vite.config.ts`) and the edge game
(`vite.config.ts`) — and never `import`-ed by a raw Node runtime. Types flow for free: because the entry
*is* TypeScript, the consumer type-checks against the real source (no separate `.d.ts` needed).

> **Cleanup the cm-tma.1 rung carries:** `@echo/phoenix_live_view/package.json` still has upstream-shaped
> `types`/`files` fields pointing at a non-existent `assets/js/types/` — they should point at `src/` (or
> be dropped, since the `.ts` source is the type source). Same rung retires its leftover jest toolchain.

## 4. Resolving `phoenix_html.js` with a single entry (the recommended convention)

This is the question the two-package shape forces. Upstream, `phoenix_html` is its own package
(§2.4). The Jonnify approach keeps **only two** packages, so the companion has to live somewhere.

**Where it lives today:** as `assets/packages/phoenix_live_view/src/phoenix_html.ts` — a faithful copy
of the upstream IIFE. **What imports it today:** *nothing.* `app.js` does not import it, and the LV
`index.ts` does not reference it (re-probed). So the `data-method`/`data-confirm` link behavior is
currently **inert** in codemojex. That is *acceptable for the current surface* — the Mini App is
LiveView + a React island and does not server-render `data-method` links — but the resolution must be a
deliberate choice, not an accident.

**The convention — a subpath export, opted into explicitly (RECOMMENDED):**

Expose the companion as a subpath of the package it belongs with, and import it for its side effect only
where needed — mirroring upstream's explicit `import "phoenix_html"` while staying at two packages:

```json
// @echo/phoenix_live_view/package.json
"exports": {
  ".":             "./src/index.ts",
  "./phoenix_html": "./src/phoenix_html.ts"
}
```

```js
// assets/js/app.js — add ONLY if the app uses data-method/data-confirm links
import "@echo/phoenix_live_view/phoenix_html"   // side effect: the link/confirm handler
```

```
import "@echo/phoenix_live_view/phoenix_html"
   │
   ▼
exports["./phoenix_html"] → packages/phoenix_live_view/src/phoenix_html.ts
   │  (vite compiles the IIFE; on load it installs the global click listener)
   ▼
data-method / data-confirm / data-to links work, exactly as upstream phoenix_html.js
```

Why this is the pragmatic default:

- **Two packages, no third** — the companion rides inside the package it semantically belongs with.
- **Explicit opt-in** — matches upstream's "you choose to install the handler" semantics; the side
  effect is never smuggled in by an unrelated import. You add the line the day you add such links.
- **Unambiguous resolution** — `@echo/phoenix_live_view/phoenix_html` names exactly one file.

**The alternative — always-on via the index** (document, not default):

```ts
// @echo/phoenix_live_view/src/index.ts  (top of file)
import "./phoenix_html"   // every @echo/phoenix_live_view import now installs the handler
```

Simpler (no app-side import, no subpath), but it **couples the side effect to any LiveView import** and
departs from upstream's separation — pick it only if the team wants the link/confirm behavior on
wherever LiveView is. Prefer the subpath for explicitness.

## 5. The two flows side by side

| Axis | Upstream (`deps/`, `file:` link) | Jonnify (`@echo/*` workspace) |
|---|---|---|
| Resolution target | prebuilt `priv/static/*.esm.js` | TS `src/index.ts` |
| Who builds the lib JS | the library's toolchain (shipped in Hex) | the host's **vite**, in-tree |
| Build target / tree-shake | fixed by the library | the host's — **es2024**, real shake |
| Needs `mix deps.get` | **yes** (artifacts live in `deps/`) | **no** |
| Build context | umbrella root (`COPY deps/phoenix*`) | self-contained `assets/` |
| `phoenix` reference | `import "phoenix"` → prebuilt `.mjs` | `@echo/phoenix` → `src/index.ts` |
| `phoenix_html` | separate package, `import "phoenix_html"` | LV subpath `@echo/phoenix_live_view/phoenix_html` |
| Source debuggability | maps back to a prebuilt bundle | direct TS source |
| Test runner for the lib | the library's (jest, upstream) | the vendored package's **vitest** |
| Faithfulness | trusted (upstream artifact) | **owned** — vitest suites + boot smoke |

## 6. Invariants (carried by any change to the vendored client)

1. **Single source of build.** The `@echo/*` packages export `./src/*.ts`; the host's vite is the only
   thing that compiles them. No committed prebuilt `priv/static/<lib>.esm.js` in the workspace.
2. **Bundler-only entry.** `.ts` `exports` are valid because the front end is always vite-built; never
   `import` an `@echo/*` package from raw Node.
3. **The public surface is the contract.** `@echo/phoenix` ⇒ `{ Socket, Channel, … }`;
   `@echo/phoenix_live_view` ⇒ `{ LiveSocket, createHook, ViewHook, … }` + the hook lifecycle
   (`pushEvent`/`handleEvent`/`mounted`/`destroyed`) `GameIsland` relies on. Changing it is breaking
   (INV-VENDORED-FAITHFUL — verify with a runtime LiveSocket-boot smoke, not just a green build).
4. **`phoenix_html` is a deliberate subpath**, not a stray module — resolved via
   `@echo/phoenix_live_view/phoenix_html`, imported only where `data-method`/`data-confirm` links exist.
5. **Intra-workspace `phoenix`** — LiveView's bare `import "phoenix"` resolves to the workspace
   `@echo/phoenix` (pnpm alias `workspace:@echo/phoenix@*`), never to a registry `phoenix`.

## 7. Map

Source: the vendored packages [`packages/phoenix`](../../../mercury/packages/phoenix) ·
[`packages/phoenix_live_view`](../../../mercury/packages/phoenix_live_view); the consumer
[`liveview-boot/app.ts`](../../../mercury/codemojex/apps/liveview-boot/src/app.ts). Upstream reference:
[`deps/phoenix_live_view`](../../deps/phoenix_live_view) · [`deps/phoenix`](../../deps/phoenix) ·
[`deps/phoenix_html`](../../deps/phoenix_html). Spec:
[`docs/codemojex-tma/specs/cm-tma.1.md`](../../../docs/codemojex-tma/specs/cm-tma.1.md) (the vendoring +
pnpm + es2024 + vitest rung). Adjacent: [`render-stack.md`](render-stack.md) ·
[`livereact-hot-swap.md`](livereact-hot-swap.md) · [`dev-and-testing.md`](dev-and-testing.md).
