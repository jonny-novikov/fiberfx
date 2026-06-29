# cm-tma.2 — Vendored test suites jest→vitest (INV-VITEST) · close the cm-tma.1 A13 deferral

> The second **codemojex-tma** (front-end tier) spec rung. It does not touch the game engine
> (`lib/codemojex/**`), the always-on engine release, the served bundles, or the swap ABI. It ports the
> **two vendored packages' own test suites** from upstream **jest** to **vitest** so
> `pnpm -C packages/phoenix test` and `pnpm -C packages/phoenix_live_view test` both run **green** — closing
> the **A13 deferral** cm-tma.1 left open (the `package.json` end-state is jest-free, but the vendored
> `test/*.test.ts` files are still upstream-jest-shaped and do not run).
>
> The **body wins** on any disagreement with the brief ([`cm-tma.2.llms.md`](./cm-tma.2.llms.md)) or the
> stories ([`cm-tma.2.stories.md`](./cm-tma.2.stories.md)). **NO-INVENT:** every file/line cited below was
> re-probed on disk this session (the probe diverged from the queued estimate in three load-bearing places —
> see §3 and §8). Framing: third person; no first-person-agent narration.
>
> **The packages** (re-probed): `echo/apps/codemojex/assets/packages/phoenix` = `@echo/phoenix` v1.8.8 and
> `echo/apps/codemojex/assets/packages/phoenix_live_view` = `@echo/phoenix_live_view` v1.2.3. Both ship a
> `vitest.config.ts` and a jest-free `package.json` (devDeps + scripts cleaned in cm-tma.1); only the
> `test/*.test.ts` files (and the LV `test/tsconfig.json`) remain unported. Toolchain on disk: node v22.18.0,
> pnpm 10.17.1, **vitest 4.1.9** / vite 6.4.3 (the installed `assets/node_modules`).
>
> **One fork is SURFACED, not decided (§8 — the typecheck dimension).** The vendored `packages/*/src` are the
> upstream Phoenix **JavaScript** client renamed `.ts` (transpile-only via esbuild); `tsc --noEmit` over them
> is **449 errors loose / 688 strict** and leaks into any test-scoped typecheck. So "per-package typecheck
> green" is **not** reachable by declaring a handful of missing types — it is a fork for the Operator to rule.
> The rung's **core** (the suites run green on vitest; jest retired) is independent of that ruling.

## 1. The rung in one paragraph

cm-tma.1 vendored `@echo/phoenix` + `@echo/phoenix_live_view` as TypeScript packages and cleaned their
`package.json` files to a jest-free, vitest-named end state — but the **test files themselves** were never
ported: they still `import {jest} from "@jest/globals"`, call `jest.fn` / `jest.useFakeTimers` / `jest.spyOn`
(~319 call-sites), import from stale module paths (`../js/phoenix*` in phoenix; the bare
`phoenix_live_view/*` subpath alias in LV), the LV `test/tsconfig.json` `extends` a file that does not exist
(`packages/tsconfig.json`), and **jsdom is not installed**. So both suites collect **0 passing tests and
fail** (re-probed: phoenix → `Cannot find package '@jest/globals'` + `Cannot find module '../js/phoenix'`;
LV → `TSConfckParseError: failed to resolve "extends":"../../tsconfig.json"`, **all 14 `.test.ts` suites**).
This rung **ports both suites to vitest**: swap the jest API to `vi.*`, fix the import paths to the vendored
`src/` layout, repair the LV `test/tsconfig.json`, add a **jsdom** devDep + the environment config, broaden
the collection glob so no intended test file is silently skipped, and update the one stale `// fallback for
jest` comment in `rendered.js`. Done when `pnpm -C packages/phoenix test` and
`pnpm -C packages/phoenix_live_view test` both run **green with the full intended file set collected**, and
`grep -rniE '\bjest\b' echo/apps/codemojex/assets/packages` → **0** — the cm-tma.1 A13 deferral closed. The
**runtime** faithfulness invariant (INV-VENDORED-FAITHFUL — the cm-tma.1 A4 boot smoke) must not regress:
this rung edits only test files, test config, and byte-neutral comments; the vendored `src/**` **runtime
bytes** are unchanged.

## 2. The problem (what cm-tma.1 deferred)

cm-tma.1 §10 A13 ("VITEST — jest retired") was **DEFERRED to cm-tma.2** by Operator ruling (cm-tma.1
ledger D-5). The deferral text, verbatim intent:

> the `package.json` end-state is jest-free for **both** packages (devDeps, scripts, and config cleaned),
> **but** the vendored `test/*.test.ts` files remain upstream-jest-shaped — both suites collect 0 and fail
> … **cm-tma.2** ports both suites jest→vitest: rewrite the jest call-sites, fix the `../src` import paths +
> the `test/tsconfig.json` `extends` + add the jsdom env; then both `pnpm -C packages/* test` green and
> `grep '\bjest\b' packages` → 0.

cm-tma.1 shipped at **13/14** front-end gates on the strength of **A4** (INV-VENDORED-FAITHFUL, the runtime
LiveSocket-boot smoke, **mutation-proven**) carrying the faithfulness proof. A13 — the **unit**-level
faithfulness proof that *complements* A4 (the suites pin the unit behavior; the smoke pins the integration) —
is this rung's whole deliverable.

The A13 letter (the gate this rung must satisfy), from cm-tma.1 §10:

```
pnpm -C packages/phoenix test           # vitest, passes
pnpm -C packages/phoenix_live_view test  # vitest, passes
grep -rniE '\bjest\b' echo/apps/codemojex/assets/packages   # → 0
each package has a vitest.config.ts                          # (already true)
```

## 3. Ground truth (re-probed on disk this session — cite the file:line; the as-built wins)

| Fact | Where (re-probed) |
|---|---|
| The vendored `phoenix` package | `packages/phoenix/package.json` — `@echo/phoenix` v1.8.8; `scripts.test "vitest"` (`:23`), `scripts.typecheck "tsc --noEmit"` (`:27`); devDeps `@types/node`/`esbuild`/`mock-socket ^9.3.1`/`tsx`/`typescript ~5.9.3`/`vitest ^4.0.16` (`:29-36`) — **no jest, no jsdom** |
| The vendored `phoenix` vitest config | `packages/phoenix/vitest.config.ts` — alias `@`→`./src` (`:6-8`); `test.include ['test/**/*.test.ts','src/**/*.spec.ts']` (`:11`); **no `globals`, no `environment`** |
| The vendored `phoenix_live_view` package | `packages/phoenix_live_view/package.json` — `@echo/phoenix_live_view` v1.2.3; `exports` `.`+`./phoenix_html` (`:11-14`); deps `morphdom 2.7.8` + `phoenix "workspace:@echo/phoenix@*"` (`:20-23`); devDeps `@types/node`/`typescript ^5.8.3`/`vitest ^4.0.16` (`:24-28`) — **no jest, no jsdom**; `scripts.test "vitest"` (`:30`), `typecheck` (`:32`) |
| The LV vitest config | `packages/phoenix_live_view/vitest.config.ts` — same shape as phoenix (alias `@`→`./src`; same `include`; **no `globals`, no `environment`**) |
| **Class 4 — the LV test tsconfig is broken** | `packages/phoenix_live_view/test/tsconfig.json:2` — `"extends": "../../tsconfig.json"` resolves to **`packages/tsconfig.json` which does NOT exist** (re-probed absent) → vitest fails to transform: `TSConfckParseError: failed to resolve "extends":"../../tsconfig.json"`, **all 14 `.test.ts` suites fail**. Also `paths` map `phoenix_live_view*`→`../js/phoenix_live_view/*` (**stale**, `:12-13`); `types ["jest","jsdom"]` (`:15`) |
| **Class 1 — `@jest/globals` imports (phoenix)** | `channel.test.ts:1`, `longpoll.test.ts:1`, `socket.test.ts:1` — `import {jest} from "@jest/globals"` (3 sites). LV test files import nothing (rely on implicit jest globals) |
| **Class 1 — jest API call-sites (both pkgs, distinct, counted)** | `jest.fn`×94 · `jest.spyOn`×64 · `jest.advanceTimersByTime`×62 · `jest.runAllTimers`×39 · `jest.useFakeTimers`×19 · `jest.useRealTimers`×17 · `jest.advanceTimersToNextFrame`×10 · `jest.runOnlyPendingTimers`×2 · `jest.restoreAllMocks`×2 — all map to `vi.*`. Total `\bjest\b` in test files: phoenix 215 + LV 104 = **319** |
| **Class 2 — phoenix stale module paths** | `channel.test.ts:2` (`../js/phoenix`), `presence.test.ts:1`, `serializer.test.ts:6`, `socket.test.ts:4` (`../js/phoenix`) + `:5` (`../js/phoenix/constants`), `socket_http.test.ts:5` → all must become `../src` / `../src/constants`. `longpoll.test.ts:2-5` **already uses `../src`** — leave it |
| **Class 2 — LV stale subpath alias** | **38** `from "phoenix_live_view/…"` imports across the LV test files (`utils`/`debounce`/`browser`/`live_socket`/`index`/`js`/`view`/`hooks`/`dom`/`entry_uploader`/`modify_root`/`phx_skip_js_id`/`hook_types`/`event` + `integration/*` + `test_helpers.ts:1` + `rendered_test.ts`). The vitest config aliases only `@`→`./src`, so these do **not** resolve. **`test_helpers.ts:2`** also imports `../../package.json` for `version` (needs `resolveJsonModule` + JSON import support) |
| **Class 2 — the LV typo** | `event.test.ts:6` — `import { HooksOptions } from "phoenix_live_viewview_hook"` (a **missing slash**; should be `phoenix_live_view/view_hook`) |
| **Class 3 — jsdom is NOT installed** | re-probed: no `jsdom` directory anywhere under `assets/`. Neither package declares it. The DOM-heavy suites cannot run without it (see §6) |
| **Class 3 — env docblocks (phoenix)** | `serializer.test.ts:2` `@jest-environment node`; `socket_http.test.ts:2` `@jest-environment jsdom` + `:3` `@jest-environment-options {"url": "http://example.com/"}`. No other phoenix test carries a docblock |
| **The collection gap (a liveness hazard — §7)** | the vitest `include` glob `test/**/*.test.ts` does **not** match LV's `test/integration/{event,metadata,portal}_test.ts` (3) + `test/rendered_test.ts` (1) — **4 LV test files silently uncollected**. 14 LV `.test.ts` are collected; 6 phoenix `.test.ts` are collected. `phoenix/test/serializer.ts` + `phoenix_live_view/test/{test_helpers.ts,globals.d.ts}` are helpers (correctly not test files) |
| **The benign src jest comment** | `packages/phoenix_live_view/src/rendered.js:283` — `// fallback for jest` (a **comment only**; the code is a `structuredClone`/`JSON.parse` fallback — re-probed, **no runtime `jest` reference anywhere in src**). This is the only `\bjest\b` in `src/`, and it blocks the A13 `grep → 0` (§8) |
| **The typecheck reality (§8 fork)** | neither package has its own `tsconfig.json`; `pnpm -C packages/phoenix typecheck` runs `tsc --noEmit`, which **climbs to `assets/tsconfig.json`** and checks `assets/src/*` (e.g. `GameEdge.tsx`) — **not** the package's own `src` → trivially green (a no-op). `tsc --noEmit` over `packages/phoenix/src` is **688 errors strict / 449 loose** (TS2339 fields-assigned-not-declared, TS7006 untyped params); a test-scoped typecheck **leaks** them (212 from `socket.ts`, 94 from `channel.ts`, …). The vendored `src` is upstream JS renamed `.ts`, **transpile-only via esbuild** |
| The LV type-test file | `hook_types.test.ts` — a compile-time type test (imports `type { Hook, HooksOptions }`) with a **dummy runtime test** `test("hook types compile correctly", …)` (`:127-129`) so vitest collects it (its own comment `:126` notes it "satisfies Jest's requirement for at least one test"). Needs the test globals + the type imports resolvable |
| The LV ambient | `test/globals.d.ts` — declares `let LV_VSN: string` globally (keep) |

## 4. The work — four failure classes (smallest-change-first)

The port decomposes into four mechanical classes plus the §8 fork. Each is independently checkable.

1. **Class 1 — jest API → vitest API (~319 call-sites).** Delete the 3 `import {jest} from "@jest/globals"`
   lines (phoenix); rewrite every `jest.<fn>` to `vi.<fn>` (the table in §3 is the full surface). With
   `globals: true` (§8 ruling), `vi`, `describe`, `it`, `test`, `expect`, `beforeEach`, `afterEach` are
   available without per-file imports — no new import lines needed.
2. **Class 2 — module-path drift.** phoenix: `../js/phoenix*` → `../src` / `../src/constants` (5 sites; leave
   `longpoll.test.ts`). LV: resolve the **38** `phoenix_live_view/*` subpath imports to the vendored `src/`
   — the clean mechanism is a vitest **alias** `phoenix_live_view` → `resolve(__dirname, './src')` in
   `vitest.config.ts` (one config edit) **plus** fixing the `event.test.ts:6` typo (the alias cannot rescue a
   missing slash). `test_helpers.ts:2`'s `../../package.json` import resolves once `resolveJsonModule` is set.
3. **Class 3 — environment + jsdom.** Add `jsdom` as a devDep to **both** packages (`pnpm install` →
   regenerate `assets/pnpm-lock.yaml`). Set the environment (§6). Convert the `@jest-environment*` docblocks
   to their vitest form.
4. **Class 4 — the LV `test/tsconfig.json`.** Fix the `extends` target (it points at the non-existent
   `packages/tsconfig.json`); repair the stale `paths` (`../js/phoenix_live_view/*`) to the vendored `../src`
   layout (or drop them in favor of the vitest alias); set `types` to `["vitest/globals","jsdom","node"]`
   (drop `"jest"`). This is the **gating** fix: until it resolves, **all 14** LV `.test.ts` suites fail to
   transform.

## 5. The faithfulness contract — INV-VENDORED-FAITHFUL must not regress

This rung's edits are confined to **test files, test config, and byte-neutral comments**. The vendored
`src/**` **runtime behavior** — the public surface `js/app.js` consumes (`Socket`; `LiveSocket` + the hook
lifecycle; the `phoenix_html` side-effects) — is **unchanged**, and the cm-tma.1 **A4 boot smoke** (the
LiveSocket connects; the `EdgeReact` hook mounts the game island) must still pass. The one `src` touch this
rung makes is the stale `// fallback for jest` comment in `rendered.js:283` (§8) — a **comment**, stripped by
esbuild, with **zero** runtime effect.

**INV-VENDORED-FAITHFUL (this rung):** `git diff` on `src/**` is **comments / type-only at most** (no
executable-byte change); the built bundle's runtime behavior is unchanged; the cm-tma.1 A4 posture is not
regressed (§10 A4). A port that makes a suite "green" by **deleting assertions** rather than translating them
**fails** this rung — the Director mutation-spot-checks a ported assertion (a no-op port must die under a
seeded source mutation).

## 6. Environment + jsdom (the §3 Class 3 detail — diverges from the queued estimate)

The queued estimate suggested "phoenix: per-file pragma; LV: jsdom default." The disk evidence **diverges**:
phoenix's `channel.test.ts` (2 DOM/global refs), `longpoll.test.ts` (19), and `socket.test.ts` (24) carry
**no** environment docblock yet touch `window`/`document`/`WebSocket`/`navigator` — under vitest's **`node`**
default they would fail. So **both** packages need **`environment: 'jsdom'` as the config default**, with one
per-file override:

- **phoenix** — `vitest.config.ts` `test.environment: 'jsdom'`; the single override is
  `serializer.test.ts` → `// @vitest-environment node` (it is environment-agnostic, 0 DOM refs, and was
  explicitly `node` upstream). `socket_http.test.ts`'s `@jest-environment jsdom` becomes
  `// @vitest-environment jsdom` (redundant with the default but faithful to the upstream intent).
- **phoenix_live_view** — `vitest.config.ts` `test.environment: 'jsdom'` (the whole suite is DOM-driven;
  `test_helpers.ts` and the integration tests use `global.document`).

**The jsdom URL option (RISK — §8 R-2).** `socket_http.test.ts` needs jsdom's `url: http://example.com/`.
vitest's per-file `@vitest-environment-options` support must be **verified against vitest 4.1.9**; the
documented fallback is `test.environmentOptions.jsdom.url` in the config (it only affects the few jsdom tests
that read `window.location`, of which `socket_http` is the one that cares). Mars rules the mechanism after
verifying; the **outcome** is fixed: `socket_http.test.ts` runs under jsdom with the expected document URL.

## 7. Test-collection completeness — the liveness law (a gate must exercise its outcome)

A green test run that silently **skips** files proves nothing about those files — a no-op satisfies a naive
"`pnpm test` exits 0." The §3 collection gap is exactly this hazard: the `test/**/*.test.ts` glob misses LV's
`test/integration/{event,metadata,portal}_test.ts` + `test/rendered_test.ts` (4 files named `*_test.ts`, not
`*.test.ts`). Re-probed: `integration/metadata_test.ts` uses `global.document` + a mock `pushEvent` — it is
**jsdom-runnable**, not a live-server test; the same holds for its siblings. So they **should** run.

**The build must collect every intended test file**, the cleanest way being to broaden the LV `include` glob
to `['test/**/*.test.ts','test/**/*_test.ts','src/**/*.spec.ts']` (covers `rendered_test.ts` + the 3
integration tests), **or** rename the 4 files to `*.test.ts`. The glob-broadening is preferred (it keeps the
vendored filenames upstream-identical). Either way, **the acceptance pins the collected-file count** so a
silent under-collection is a LOUD failure, not a false green (§10 A8). After broadening, the 4 newly-collected
files must pass too.

> Expected collected file set (re-probed; Mars re-pins the exact count after the port):
> **phoenix = 6** `.test.ts` (`channel`, `longpoll`, `presence`, `serializer`, `socket`, `socket_http`);
> **LV = 18** (14 `.test.ts` + `rendered_test.ts` + `integration/{event,metadata,portal}_test.ts`).
> `phoenix/test/serializer.ts`, `phoenix_live_view/test/{test_helpers.ts,globals.d.ts}` are helpers, **not**
> counted.

## 8. The typecheck dimension — [FORK: Operator-pending; recommendation below]

The queued estimate framed a **typecheck prerequisite**: "declare missing types so `pnpm -C packages/*
typecheck` is green," with `presence.ts`'s `@param {Channel}` JSDoc as the worked example. The re-probe shows
this is **not** achievable by declaring a few types, and the worked example is a red herring:

- Neither package has its own `tsconfig.json`; `pnpm -C packages/* typecheck` (`tsc --noEmit`) **climbs to
  `assets/tsconfig.json`** and checks `assets/src/*` — **not the package's own `src`** — so it is **green
  today only because it checks nothing in the package** (a no-op gate).
- Pointed at the package `src`, `tsc --noEmit` reports **688 errors strict / 449 loose** — the vendored files
  are the upstream Phoenix **JavaScript** client renamed `.ts` (class fields assigned-not-declared → TS2339;
  untyped params → TS7006; one file, `rendered.js`, is still literally `.js`). They are **transpile-only**
  (the build uses esbuild, which never type-checks). The `{Channel}` JSDoc is **not** the error (JSDoc types
  are not checked in `.ts` files).
- A **test-scoped** typecheck does not escape this: typechecking a test that imports `../src` **pulls the src
  into the program and reports its errors** (re-probed: 212 leaked from `socket.ts`, 94 from `channel.ts`, …).

So "per-package typecheck green" requires one of three things — **a fork the Operator owns**:

- **Option A — scope `typecheck` to the test files + `@ts-nocheck` the vendored src.** Add a per-package
  `tsconfig.json` (or repurpose the fixed `test/tsconfig.json`) that checks only the **ported test files**
  with the upstream-faithful loose posture (`allowJs`, `checkJs:false`, `noImplicitAny:false`, `skipLibCheck`,
  `types:["vitest/globals","jsdom","node"]`), and add a one-line `// @ts-nocheck` to each vendored `src` file
  so its (intended, transpile-only) loose typing does not pollute the gate. `@ts-nocheck` is a **comment**
  (esbuild-stripped → runtime-byte-neutral; INV-VENDORED-FAITHFUL/A4 preserved). The gate then **proves the
  ported tests type-check** — a real, achievable, liveness-bearing check. Cost: a comment line on ~13 phoenix
  + ~30 LV src files.
- **Option B — keep typecheck OUT of cm-tma.2 (RECOMMENDED).** Leave `typecheck` the existing climbs-to-root
  no-op (do not add A5); keep cm-tma.2 the focused **runtime** jest→vitest port that closes A13 (A1–A4, A6,
  A7, A8, A9). Re-typing the vendored client into genuinely `tsc`-clean TypeScript (449–688 fixes across
  ~43 files) is a **distinct, larger** concern — a future rung ("type the vendored client"), not a
  test-runner port. This keeps the rung tightly scoped to its named deliverable and avoids ~43 src touches.
- **Option C — fully re-type the vendored src.** REJECTED for this rung: 449–688 fixes across the faithful
  surface; a complete re-typing of the Phoenix client; far beyond jest→vitest and a needless risk to
  INV-VENDORED-FAITHFUL.

**Recommendation: Option B** (defer typecheck; ship the focused suite port). Either way, the rung must close
the A13 `grep '\bjest\b' → 0` letter, which the single `rendered.js:283` comment blocks. **Independent of the
fork**, update that one stale comment (`// fallback for jest` → e.g. `// fallback when structuredClone is
unavailable`) — it names a retired tool, the rewrite is byte-neutral at runtime, and it makes the A13 grep
honest. (If the Operator picks A, the `@ts-nocheck` comments are added too.)

**A5 below is written to Option A and marked `[FORK-PENDING]`; if the Operator rules B, A5 is struck and the
rung ships A1–A4 + A6–A9.**

## 9. What stays unchanged (contracts this rung must NOT break)

- **The runtime faithfulness surface:** the vendored `src/**` executable bytes (only comments / type-only
  edits permitted, §5/§8); the cm-tma.1 A4 boot smoke (the lobby boots; the board mounts) does not regress.
- **The served bundles + the swap ABI:** `js/app.js`, `src/index.tsx`, `src/types.ts`, the four bridge events
  — **zero diff**. The edge game build (`pnpm build`) + the LiveView client build (`pnpm build:client`) still
  emit their bundles. This rung touches **test** files, not build inputs.
- **The pnpm workspace + the build target:** `assets/package.json`, `pnpm-workspace.yaml`, the es2024 root
  configs, both vite configs — **unchanged** (the only lockfile churn is the added `jsdom` devDep, §10 A7).
- **The engine + the engine release:** `lib/codemojex/**`, `echo/Dockerfile`, `echo/fly.toml`, `mix.lock`,
  the edge `Dockerfile`/`fly.toml`/`bin/edge-deploy.sh` (cm-tma.1's surface) — **zero diff**.

## 10. Acceptance (the runnable gate — each invariant a check; a no-op must not satisfy its letter)

- **A1 — VITEST: phoenix green.** `pnpm -C packages/phoenix test --run` exits 0; **all 6 `.test.ts` suites
  pass** with **> 0 tests collected**; no suite is errored or empty. (INV-VITEST)
- **A2 — VITEST: phoenix_live_view green.** `pnpm -C packages/phoenix_live_view test --run` exits 0; **all 18
  intended files** (the 14 `.test.ts` + `rendered_test.ts` + the 3 `integration/*_test.ts`, §7) pass with
  **> 0 tests collected**; no suite is errored or empty. (INV-VITEST)
- **A3 — JEST RETIRED.** `grep -rniE '\bjest\b' echo/apps/codemojex/assets/packages` → **0** (over the whole
  packages tree: test files, config, **and** `src` — incl. the `rendered.js:283` comment fix, §8). This check
  **cannot** be satisfied by a no-op that also satisfies A1/A2 — green suites with zero jest is the point.
- **A4 — INV-VENDORED-FAITHFUL preserved (runtime, not just compile).** `git diff` on `packages/*/src/**`
  contains **only** comments / type-only edits — **no executable-byte change** (`git diff -G'.' -- '*/src/**'`
  shows no logic lines, or the diff is auditably comment/type-only); the cm-tma.1 **A4 boot smoke** (the
  LiveSocket connects + the `EdgeReact` hook mounts the game island, the `node/codemojex-e2e` path or the
  headless `app.js` boot) still passes; `js/app.js`, `src/index.tsx`, `src/types.ts` have **zero diff**.
  (INV-VENDORED-FAITHFUL)
- **A5 — INV-TYPES (typecheck green). `[FORK-PENDING` — §8; included only under Option A]** `pnpm -C
  packages/phoenix typecheck` and `pnpm -C packages/phoenix_live_view typecheck` exit 0 **and meaningfully
  check the ported test files** (`tsc --showConfig` / `--listFiles` resolves the package's own
  `test/*.test.ts`, **not** `assets/src/*`); the vendored `src` is `@ts-nocheck`'d (byte-neutral, §8). If the
  Operator rules **Option B**, this check is **struck** and the rung ships A1–A4 + A6–A9.
- **A6 — ENVIRONMENT + JSDOM.** `jsdom` is a devDep of **both** packages; both `vitest.config.ts` set
  `environment: 'jsdom'`; `serializer.test.ts` overrides to `// @vitest-environment node`; `socket_http.test.ts`
  runs under jsdom with the `http://example.com/` document URL; `grep -rniE '@jest-environment'
  echo/apps/codemojex/assets/packages` → **0** (subsumed by A3 but called out — the docblocks are converted,
  not deleted). (INV-VITEST)
- **A7 — BOUNDARY.** The diff is confined to `echo/apps/codemojex/assets/packages/**` + the regenerated
  `echo/apps/codemojex/assets/pnpm-lock.yaml` (the **only** change there being the added `jsdom` + its
  transitive deps — `git diff pnpm-lock.yaml` shows no unrelated version churn) + these specs. `lib/codemojex/**`,
  `assets/js/app.js`, `assets/src/**` (the swap ABI), `assets/package.json`, `assets/{tsconfig,vite.config,vite.client.config}.ts`,
  the edge `Dockerfile`/`fly.toml`/`bin/edge-deploy.sh`, `echo/Dockerfile`, `echo/fly.toml`, `mix.lock`, and
  every sibling umbrella app → **zero diff**.
- **A8 — COLLECTION COMPLETENESS (the liveness law, §7).** The vitest run reports the **expected file count**
  (phoenix 6; LV 18) — no intended test file is silently skipped. Pin the count in a re-probe (`vitest
  list` / the run summary's file tally); a build that leaves the 4 LV `*_test.ts` files uncollected **fails**
  A8 even if A2's exit code is 0. (This is the gate that stops a green-but-incomplete suite.)
- **A9 — DETERMINISM POSTURE (honest).** No id-mint / process / lease surface ⇒ **no ≥100 determinism loop
  required**. The fake-timer / async-heavy suites are ratified by **≥5 consecutive green runs** per package
  (catch order- or timer-flake) plus a vitest seed sweep (`--sequence.seed`); the report states the posture
  explicitly. (INV-VITEST stability)

## 11. Given / When / Then (headlines — the full set is [`cm-tma.2.stories.md`](./cm-tma.2.stories.md))

- **S1** — *A front-end engineer runs the phoenix suite* → `pnpm -C packages/phoenix test` is green, all 6
  files, > 0 tests (A1).
- **S2** — *…runs the LV suite* → `pnpm -C packages/phoenix_live_view test` is green, all 18 intended files
  collected and passing — the integration + `rendered_test` files **run**, not skipped (A2/A8).
- **S3** — *The Operator greps for jest* → `grep -rniE '\bjest\b' assets/packages` → 0; no green suite hides a
  surviving jest reference (A3).
- **S4** — *A player loads the lobby after the port* → identical behavior; the cm-tma.1 A4 boot smoke still
  passes; `src/**` runtime bytes unchanged (A4).
- **S5** — *The DOM suites run* → jsdom installed; both configs default to jsdom; `serializer` is node;
  `socket_http` sees `example.com` (A6).
- **S6** — *The reviewer checks the boundary* → the diff is `packages/**` + the jsdom-only `pnpm-lock.yaml`
  churn + these specs; the engine, the served bundles, the swap ABI, `mix.lock` are untouched (A7).
- **S7** — *(typecheck — §8 fork)* under Option A, `pnpm -C packages/* typecheck` is green and checks the
  ported tests (A5); under Option B, the typecheck gate is deferred to a later rung.

## 12. Scope In

- Port `packages/phoenix/test/*.test.ts` + `packages/phoenix_live_view/test/*.test.ts` (and the 4 LV
  `*_test.ts`) from jest to vitest: rewrite the ~319 jest call-sites to `vi.*`; delete the 3 `@jest/globals`
  imports; convert the `@jest-environment*` docblocks (§6).
- Fix the import paths (§4 Class 2): phoenix `../js/phoenix*` → `../src`; the LV `phoenix_live_view/*` subpath
  via a vitest alias `phoenix_live_view`→`./src`; the `event.test.ts:6` typo; the `test_helpers.ts:2` JSON
  import.
- Add `jsdom` devDep to both packages; set `environment: 'jsdom'` (both) + the one `node` override; configure
  globals (`globals: true` + `types:["vitest/globals"]`, §8) — regenerate `pnpm-lock.yaml`.
- Repair the LV `test/tsconfig.json` (`extends` target, stale `paths`, `types`) — the Class 4 gating fix.
- Broaden the LV `vitest.config.ts` `include` (or rename the 4 files) so every intended test file is
  collected (§7); pin the count.
- Update the stale `// fallback for jest` comment in `rendered.js:283` so the A13 grep is honest (§8).
- **[FORK-PENDING, Option A only]** add a per-package `typecheck` scope + `@ts-nocheck` the vendored src (§8).

## 13. Scope Out

- **Any `src/**` runtime change** — only comments / type-only edits permitted (§5/§8). The Phoenix client's
  behavior, public surface, and the `phoenix_html` mechanism are read-only.
- **The pnpm workspace, the es2024 cutover, the vite/jsdom-unrelated devDeps, both vite configs,
  `assets/package.json`** — cm-tma.1 surface; unchanged here (the only lockfile churn is `jsdom`).
- **The served bundles + the swap ABI** (`js/app.js`, `src/index.tsx`, `src/types.ts`), the edge image
  (`Dockerfile`/`fly.toml`/`bin/edge-deploy.sh`), the engine (`lib/codemojex/**`), the engine release
  (`echo/Dockerfile`/`echo/fly.toml`), `mix.lock`, every sibling app — untouched.
- **Fully typing the vendored client** (Option C / the 449–688 src fixes) — a separate future rung (§8).
- **Reconciling the stale narrative docs** (`codemoji.static-edge.md`, `codemojex-tma.roadmap.md`) — the
  standing separate docs-reconcile concern.

## 14. The rung (placement + risk)

**Track:** `codemojex-tma` (the front-end tier), rung **2** — it closes the cm-tma.1 A13 deferral and gives
the vendored client a running unit-test floor for the later TMA UI rungs.
**Risk:** **NORMAL test-tooling, with ONE adjacency to the frozen faithful surface.** Most acceptance is
mechanical (run the suites; grep; count files). The load-bearing risk is **INV-VENDORED-FAITHFUL** (§5): the
type-declaration / comment edits touch `src/**`, which is the cm-tma.1 faithfulness surface — they must be
**comment / type-only, byte-neutral at runtime**, and the A4 boot smoke must hold. The Director
**mutation-spot-checks a ported assertion** (a no-op port that deletes assertions to go green must FAIL).
Secondary: the **collection-completeness** hazard (§7) — a green-but-incomplete suite — is closed by A8's
pinned file count. **One fork is surfaced (§8 typecheck), not decided** — the Operator rules A/B/C; the rung's
core (A1–A4, A6–A9) is independent of that ruling. There is no id-mint / lease / process surface, so **no
≥100 determinism loop** (A9 states the honest posture).

## 15. Boundary

`echo/apps/codemojex/assets/packages/**` (both packages' `test/**`, `vitest.config.ts`, `test/tsconfig.json`,
`package.json`, and the byte-neutral `src` comment/`@ts-nocheck` edits) + `echo/apps/codemojex/assets/pnpm-lock.yaml`
(the jsdom devDep only) + these specs (`docs/codemojex-tma/specs/cm-tma.2.*` + the
`docs/codemojex-tma/specs/progress/cm-tma-2.progress.md` ledger). **Out of bounds:** `lib/codemojex/**`,
`assets/js/app.js`, `assets/src/**`, `assets/package.json`, the root build configs, the edge image surface,
`echo/Dockerfile`, `echo/fly.toml`, `mix.lock`, the umbrella `config/`, and every sibling app. A change
reaching the engine, the served bundles, the swap ABI, or a sibling app is out of scope — stop and re-scope.

## 16. Build brief

Smallest-change-first, each step independently checkable:

1. **Unblock LV transform (Class 4)** — fix `packages/phoenix_live_view/test/tsconfig.json`: repoint
   `extends` off the non-existent `packages/tsconfig.json`; repair/remove the stale `paths`; set
   `types:["vitest/globals","jsdom","node"]`. → the 14 LV `.test.ts` files transform (stop the
   `TSConfckParseError`).
2. **Add jsdom + the env/globals config (Class 3)** — `jsdom` devDep on **both** packages; both
   `vitest.config.ts`: `environment:'jsdom'`, `globals:true`, the LV alias `phoenix_live_view`→`./src`, and
   the broadened LV `include` (§7); `serializer.test.ts` → `// @vitest-environment node`; `socket_http.test.ts`
   jsdom URL (§6, verify the mechanism against vitest 4.1.9). `pnpm install` → regenerate `pnpm-lock.yaml`.
3. **Fix import paths (Class 2)** — phoenix `../js/phoenix*` → `../src`/`../src/constants` (5 sites); the LV
   `event.test.ts:6` typo; confirm `test_helpers.ts:2` JSON import resolves.
4. **Sweep the jest API (Class 1)** — delete the 3 `@jest/globals` imports; `jest.*` → `vi.*` across both
   suites (the §3 table is the full surface); **translate** assertions, never delete them.
5. **Honest A13 grep** — update the `rendered.js:283` `// fallback for jest` comment (§8). `grep -rniE
   '\bjest\b' packages` → 0.
6. **[FORK-PENDING, Option A only]** — per-package `typecheck` scope + `@ts-nocheck` the vendored src (§8).
7. **Gate** — A1 (phoenix green, 6 files) · A2 (LV green, 18 files) · A3 (jest grep 0) · A4 (boot smoke + the
   src diff is comment/type-only) · A6 (jsdom env) · A7 (boundary; lockfile = jsdom-only) · A8 (collection
   count pinned) · A9 (≥5 runs + seed sweep, honest posture). A5 only under Option A.

**Files (boundary `packages/**` + `pnpm-lock.yaml` + these specs):** `packages/phoenix/vitest.config.ts` ·
`packages/phoenix/package.json` (jsdom devDep) · `packages/phoenix/test/*.test.ts` (6) ·
`packages/phoenix_live_view/vitest.config.ts` · `packages/phoenix_live_view/package.json` (jsdom devDep) ·
`packages/phoenix_live_view/test/tsconfig.json` · `packages/phoenix_live_view/test/**/*` (the 14 `.test.ts`
+ the 4 `*_test.ts`) · `packages/phoenix_live_view/src/rendered.js` (the one comment) · `assets/pnpm-lock.yaml`
· **[Option A only]** the per-package `tsconfig.json` + the `@ts-nocheck` src comments. **Unchanged:**
`assets/js/app.js`, `assets/src/**`, `assets/package.json`, the root build configs, the edge image surface,
`lib/codemojex/**`, `echo/Dockerfile`, `echo/fly.toml`, `mix.lock`.
