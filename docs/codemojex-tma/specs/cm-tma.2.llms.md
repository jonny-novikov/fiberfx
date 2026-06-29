# cm-tma.2 — Vendored test suites jest→vitest · agent brief (compact)

> The one-screen brief, derived from [`cm-tma.2.md`](./cm-tma.2.md) (**the body wins**). Acceptance:
> [`cm-tma.2.stories.md`](./cm-tma.2.stories.md). Framing: third person; **NO-INVENT** (every cite re-probed
> on disk this session). Toolchain on disk: node 22.18.0, pnpm 10.17.1, **vitest 4.1.9** / vite 6.4.3.

## What

Port the **two vendored packages' own test suites** from upstream **jest** to **vitest** so
`pnpm -C packages/phoenix test` and `pnpm -C packages/phoenix_live_view test` both run **green** and
`grep -rniE '\bjest\b' echo/apps/codemojex/assets/packages` → **0** — closing the cm-tma.1 **A13 deferral**.
cm-tma.1 cleaned both `package.json` files to jest-free, but the `test/*.test.ts` files are still
upstream-jest-shaped and **do not run** (re-probed baseline: phoenix → `Cannot find package '@jest/globals'` +
`Cannot find module '../js/phoenix'`; LV → `TSConfckParseError` on the broken `test/tsconfig.json` `extends`,
**all 14 `.test.ts` suites fail**). The port edits **test files, test config, and byte-neutral comments
only** — the vendored `src/**` **runtime bytes are unchanged**, and the cm-tma.1 **A4 boot smoke** (the lobby
boots; the board mounts) must not regress.

**One fork is SURFACED, not decided — the typecheck dimension (§8).** The vendored `src` is the upstream
Phoenix **JavaScript** client renamed `.ts` (transpile-only via esbuild); `tsc --noEmit` over it is **449
errors loose / 688 strict** and leaks into any test-scoped typecheck. So "per-package typecheck green" is the
Operator's call: **A** = scope typecheck to the test files + `@ts-nocheck` the src (byte-neutral); **B** =
defer typecheck **[RECOMMENDED]**; **C** = re-type the src **[rejected]**. The rung's core (the suites green;
jest gone) is independent of the ruling. Do not pick — the Director routes it to the Operator.

## References (read first)

- **The deferral being closed:** [`cm-tma.1.md`](./cm-tma.1.md) §10 A13 + the cm-tma.1 ledger D-5 / P-1
  ([`progress/cm-tma-1.progress.md`](./progress/cm-tma-1.progress.md)) — the A13 letter and why it was deferred.
- **The two packages (re-probe before editing):**
  - `packages/phoenix/package.json` (`@echo/phoenix` v1.8.8; `test "vitest"` `:23`; devDeps `vitest`/`mock-socket`/`tsx`/`esbuild`/`@types/node`/`typescript` — **no jest, no jsdom**).
  - `packages/phoenix/vitest.config.ts` (alias `@`→`./src`; `include ['test/**/*.test.ts','src/**/*.spec.ts']`; **no globals, no environment**).
  - `packages/phoenix_live_view/package.json` (`@echo/phoenix_live_view` v1.2.3; deps `morphdom 2.7.8` + `phoenix workspace:@echo/phoenix@*`; devDeps `vitest`/`typescript`/`@types/node` — **no jest, no jsdom**).
  - `packages/phoenix_live_view/vitest.config.ts` (same shape as phoenix).
  - `packages/phoenix_live_view/test/tsconfig.json` (the **broken** `extends:"../../tsconfig.json"`; stale `paths`; `types:["jest","jsdom"]`).
- **The faithful surface (do NOT change runtime bytes):** `packages/*/src/**`; the cm-tma.1 A4 boot harness
  (`node/codemojex-e2e` or a headless `app.js` boot asserting `window.liveSocket` connects).

## Requirements (each → a story → an invariant)

1. **Class 1 — jest API → `vi.*` (~319 sites).** Delete the 3 `@jest/globals` imports (`channel.test.ts:1`,
   `longpoll.test.ts:1`, `socket.test.ts:1`); rewrite `jest.fn`(94)/`jest.spyOn`(64)/`jest.advanceTimersByTime`(62)/`jest.runAllTimers`(39)/`jest.useFakeTimers`(19)/`jest.useRealTimers`(17)/`jest.advanceTimersToNextFrame`(10)/`jest.runOnlyPendingTimers`(2)/`jest.restoreAllMocks`(2) → `vi.*`. **Translate** assertions; never delete them. → S1/S2/S3 / A1/A2/A3.
2. **Class 2 — module paths.** phoenix: `../js/phoenix*` → `../src`/`../src/constants` (`channel.test.ts:2`,
   `presence.test.ts:1`, `serializer.test.ts:6`, `socket.test.ts:4-5`, `socket_http.test.ts:5`; **leave**
   `longpoll.test.ts`). LV: a vitest **alias** `phoenix_live_view`→`resolve(__dirname,'./src')` resolves the
   **38** `phoenix_live_view/*` subpath imports in one edit; fix the `event.test.ts:6` typo
   `phoenix_live_viewview_hook` → `phoenix_live_view/view_hook`; `test_helpers.ts:2`'s `../../package.json`
   resolves with `resolveJsonModule`. → S1/S2 / A1/A2.
3. **Class 3 — jsdom + env/globals.** Add `jsdom` devDep to **both** packages (`pnpm install` → regenerate
   `pnpm-lock.yaml`). Both `vitest.config.ts`: `environment:'jsdom'` (default) + `globals:true`. Per-file:
   `serializer.test.ts` → `// @vitest-environment node`; `socket_http.test.ts` → jsdom with `url:
   http://example.com/` (**verify the per-file `@vitest-environment-options` mechanism against vitest 4.1.9**;
   fallback `test.environmentOptions.jsdom.url`). → S1/S5 / A6.
4. **Class 4 — the LV `test/tsconfig.json` (gating).** Repoint `extends` off the non-existent
   `packages/tsconfig.json`; repair/remove the stale `paths`; set `types:["vitest/globals","jsdom","node"]`
   (drop `"jest"`). Until fixed, **all 14** LV `.test.ts` suites fail to transform. → S2 / A2.
5. **Collection completeness (liveness).** The `include` glob `test/**/*.test.ts` MISSES LV's
   `test/integration/{event,metadata,portal}_test.ts` + `test/rendered_test.ts` (4 files, `*_test.ts`) — they
   are jsdom-runnable and **must** run. Broaden the LV `include` to also match `test/**/*_test.ts` (preferred,
   keeps upstream filenames) **or** rename. Pin the collected-file count. → S2 / A8.
6. **Honest A13 grep.** Update the stale `// fallback for jest` comment in `packages/phoenix_live_view/src/rendered.js:283`
   (the only `\bjest\b` in `src`; a comment, byte-neutral at runtime). → S3 / A3.
7. **Preserve INV-VENDORED-FAITHFUL.** `src/**` diff is **comment / type-only at most** (no executable-byte
   change); the cm-tma.1 A4 boot smoke still passes; `js/app.js` + `src/index.tsx` + `src/types.ts` zero diff.
   → S4 / A4.
8. **[FORK-PENDING, Option A only]** per-package `typecheck` scope + `@ts-nocheck` the vendored src (§8). → S7 / A5.

## Execution topology + build order (smallest-change-first)

1. **Unblock LV transform** — fix `phoenix_live_view/test/tsconfig.json` (`extends`/`paths`/`types`). (A2)
2. **jsdom + config** — `jsdom` devDep (both); `environment:'jsdom'` + `globals:true` (both); LV alias
   `phoenix_live_view`→`./src` + broadened `include`; `serializer`→node; `socket_http` jsdom URL;
   `pnpm install` → `pnpm-lock.yaml`. (A6/A8)
3. **Import paths** — phoenix `../js/phoenix*`→`../src` (5); LV typo `event.test.ts:6`; JSON import. (A1/A2)
4. **jest API sweep** — drop the 3 `@jest/globals`; `jest.*`→`vi.*`; translate assertions. (A1/A2/A3)
5. **A13 grep honest** — `rendered.js:283` comment. (A3)
6. **[Option A only]** per-package typecheck + `@ts-nocheck` src. (A5)
7. **Gate** — A1 (phoenix 6 files green) · A2 (LV 18 files green) · A3 (grep 0) · A4 (boot smoke + src diff
   comment/type-only) · A6 (jsdom) · A7 (boundary; lockfile jsdom-only) · A8 (count pinned) · A9 (≥5 runs +
   seed sweep). A5 only under Option A.

**Files** (boundary `packages/**` + `pnpm-lock.yaml` + these specs): `packages/phoenix/{vitest.config.ts,package.json}`
+ `packages/phoenix/test/*.test.ts` (6) · `packages/phoenix_live_view/{vitest.config.ts,package.json}` +
`packages/phoenix_live_view/test/tsconfig.json` + `packages/phoenix_live_view/test/**/*` (14 `.test.ts` + 4
`*_test.ts`) + `packages/phoenix_live_view/src/rendered.js` (one comment) · `assets/pnpm-lock.yaml`
(jsdom only) · **[Option A only]** per-package `tsconfig.json` + `@ts-nocheck` src. **Unchanged:** `js/app.js`,
`src/**`, `assets/package.json`, the root build configs, the edge image surface, `lib/codemojex/**`,
`echo/Dockerfile`, `echo/fly.toml`, `mix.lock`.

## Cite-map (every surface → its real file)

| Surface | File / site |
|---|---|
| the A13 deferral being closed | `cm-tma.1.md` §10 A13 + ledger D-5/P-1 |
| phoenix `@jest/globals` (delete) | `phoenix/test/{channel,longpoll,socket}.test.ts:1` |
| phoenix stale paths → `../src` | `phoenix/test/channel.test.ts:2`, `presence.test.ts:1`, `serializer.test.ts:6`, `socket.test.ts:4-5`, `socket_http.test.ts:5` (leave `longpoll.test.ts:2-5`) |
| phoenix env docblocks | `phoenix/test/serializer.test.ts:2` (node), `socket_http.test.ts:2-3` (jsdom + url) |
| LV subpath imports (alias) | 38 `from "phoenix_live_view/…"` across LV test files |
| LV typo | `phoenix_live_view/test/event.test.ts:6` (`phoenix_live_viewview_hook`) |
| LV JSON version import | `phoenix_live_view/test/test_helpers.ts:2` (`../../package.json`) |
| LV broken tsconfig (gating) | `phoenix_live_view/test/tsconfig.json:2` (`extends` → absent `packages/tsconfig.json`); `:12-13` stale `paths`; `:15` `types` |
| the collection gap (4 files) | `phoenix_live_view/test/integration/{event,metadata,portal}_test.ts` + `test/rendered_test.ts` |
| the src jest comment | `phoenix_live_view/src/rendered.js:283` (`// fallback for jest`) |
| the type-test (collects via dummy test) | `phoenix_live_view/test/hook_types.test.ts:127-129` |
| the faithful surface (unchanged runtime) | `packages/*/src/**`; cm-tma.1 A4 boot harness |
| the typecheck reality (fork) | `tsc --noEmit` over `packages/phoenix/src` = 688 strict / 449 loose; climbs to `assets/tsconfig.json` today |

## Gate ladder (front-end test surface — NOT the umbrella mix gate; pnpm, vitest 4.1.9)

`cd echo/apps/codemojex/assets` · `pnpm -C packages/phoenix test --run` → 6 files green, >0 tests (A1) ·
`pnpm -C packages/phoenix_live_view test --run` → **18 files** green, count pinned, no silent skip (A2/A8) ·
`grep -rniE '\bjest\b' packages` → **0** + `grep -rniE '@jest-environment' packages` → **0** (A3/A6) · the
cm-tma.1 **runtime boot smoke** still green + `git diff packages/*/src/**` is comment/type-only + `js/app.js`/`src/**`
zero diff (A4, the load-bearing guard; the Director mutation-spot-checks a ported assertion) · jsdom devDep on
both; both configs `environment:'jsdom'` (A6) · `git diff` confined to `packages/**` + jsdom-only
`pnpm-lock.yaml` + specs; engine/served-bundles/swap-ABI/`mix.lock` zero diff (A7) · ≥5 consecutive green runs
+ a seed sweep, honest determinism posture, **no ≥100 loop** (A9) · **[Option A only]** `pnpm -C packages/*
typecheck` green + meaningfully checks the test files (A5). **Risk:** NORMAL test-tooling with ONE adjacency to
the frozen faithful surface (the `src` comment/`@ts-nocheck` edits must be byte-neutral; A4 holds). **Boundary:**
`packages/**` + the jsdom-only lockfile + these specs; the engine, the served bundles, the swap ABI, the root
build configs, the edge image, `mix.lock`, sibling apps untouched. **The typecheck fork (§8) is the Operator's
— surface it, do not decide.**
