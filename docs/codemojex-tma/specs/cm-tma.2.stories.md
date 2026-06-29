# cm-tma.2 — Stories (the acceptance face)

> The Operator's verifiable acceptance for **cm-tma.2**, derived from [`cm-tma.2.md`](./cm-tma.2.md) (the body
> wins on any disagreement). The model is the **vendored-suite jest→vitest port**: the two vendored packages
> in `echo/apps/codemojex/assets/packages/` (`@echo/phoenix` v1.8.8, `@echo/phoenix_live_view` v1.2.3) get
> their own `test/*.test.ts` suites ported from upstream **jest** to **vitest**, so `pnpm -C packages/phoenix
> test` and `pnpm -C packages/phoenix_live_view test` both run **green**, the jest references are **gone**
> (`grep '\bjest\b' packages` → 0), and the cm-tma.1 **A13 deferral** closes — **without** regressing
> INV-VENDORED-FAITHFUL (the lobby still boots; the vendored `src/**` runtime bytes are unchanged).
>
> Each story is Connextra + Given/When/Then; each names the invariant(s) it exercises and the surface that
> closes it. **A gate must EXERCISE its outcome — a no-op must not satisfy a story's letter** (S2's collection
> count and S3's jest-grep are written so a green-but-empty/incomplete run fails). Framing: third person; no
> first-person-agent narration. **NO-INVENT:** every cite re-probed on disk this session.
>
> **One fork is SURFACED (S7 — the typecheck dimension, body §8).** The vendored `src` is upstream JS renamed
> `.ts` (449–688 `tsc` errors); "per-package typecheck green" is the Operator's call (Option A include it /
> Option B defer it / Option C reject). The rung's core (S1–S6) is independent of that ruling.

## Roles

- **A front-end engineer** — runs the vendored packages' unit suites to trust a change to the client. Wants
  `pnpm -C packages/<lib> test` to **run green** with every intended test file actually executing.
- **The Operator** — rules the typecheck fork (S7) and accepts the rung. Wants the jest toolchain **fully
  gone** (no surviving reference a green suite could hide) and the faithful surface unregressed.
- **A player** — loads the lobby and the game. Must see **identical behavior**: the port touches test files,
  not the client's runtime bytes (the cm-tma.1 boot smoke still passes).
- **The reviewer (Director / Apollo)** — verifies the boundary and that the port **translated** assertions
  rather than deleting them (the mutation spot-check).

---

## S1 — The phoenix suite runs green on vitest

*As a front-end engineer, I want `@echo/phoenix`'s ported test suite to pass on vitest, so that the vendored
transport client's unit behavior is pinned without the upstream jest.*

**Exercises:** INV-VITEST (A1); the env config (A6). **Surface:** `packages/phoenix/test/*.test.ts` (6 files,
ported `vi.*` + `../src` imports), `packages/phoenix/vitest.config.ts` (`environment:'jsdom'`, `globals:true`),
the `jsdom` devDep.

- **Given** the phoenix test files ported to vitest (the 3 `@jest/globals` imports removed, `jest.*` → `vi.*`,
  `../js/phoenix*` → `../src`), jsdom installed, the config defaulting to jsdom with `serializer.test.ts`
  overridden to `node`
- **When** `pnpm -C packages/phoenix test --run` runs
- **Then** it exits 0, **all 6 `.test.ts` suites pass** (`channel`, `longpoll`, `presence`, `serializer`,
  `socket`, `socket_http`), and **> 0 tests are collected** — no suite errored or empty,
- **And** the **negative check:** the pre-port suite (`@jest/globals` + `../js/phoenix`) **fails to collect**
  (re-probed baseline: `Cannot find package '@jest/globals'` + `Cannot find module '../js/phoenix'`) — proving
  the port is what made it run.

## S2 — The LV suite runs green AND collects every intended file (no silent skip)

*As a front-end engineer, I want `@echo/phoenix_live_view`'s full suite to run green — including the
integration and `rendered_test` files — so that a green result is not hiding silently-skipped tests.*

**Exercises:** INV-VITEST (A2); the collection-completeness liveness law (A8); Class 4 (the `test/tsconfig.json`
fix). **Surface:** `packages/phoenix_live_view/test/**` (14 `.test.ts` + 4 `*_test.ts`),
`packages/phoenix_live_view/test/tsconfig.json` (repaired `extends`/`paths`/`types`),
`packages/phoenix_live_view/vitest.config.ts` (`environment:'jsdom'`, `globals:true`, the
`phoenix_live_view`→`./src` alias, the broadened `include`).

- **Given** the LV `test/tsconfig.json` `extends` fixed (it pointed at the non-existent `packages/tsconfig.json`,
  failing **all 14** `.test.ts` suites with `TSConfckParseError`), the 38 `phoenix_live_view/*` subpath
  imports resolved by the vitest alias, the `event.test.ts:6` typo fixed, jest API → `vi.*`, and the `include`
  broadened to also match `test/**/*_test.ts`
- **When** `pnpm -C packages/phoenix_live_view test --run` runs
- **Then** it exits 0 and **all 18 intended files** pass — the 14 `.test.ts` **plus** `rendered_test.ts` and
  `integration/{event,metadata,portal}_test.ts`,
- **And** the **liveness guard (A8):** the run reports the **expected file count (18)** — a build that leaves
  the 4 `*_test.ts` files uncollected **fails this story even though the exit code is 0** (the integration
  tests are jsdom-runnable via `global.document`, re-probed — they must actually run).

## S3 — Jest is fully retired (no surviving reference a green suite could hide)

*As the Operator, I want zero `jest` references anywhere under `packages/`, so that "the suites are green" and
"jest is gone" are both true — not one masking the other.*

**Exercises:** INV-VITEST / jest-retired (A3); the env-docblock conversion (A6). **Surface:** the ported test
files, the converted `@vitest-environment` docblocks, the LV `test/tsconfig.json` `types` (drop `"jest"`), and
the `rendered.js:283` comment.

- **Given** the suites ported and the stale `// fallback for jest` comment in `src/rendered.js:283` updated
- **When** `grep -rniE '\bjest\b' echo/apps/codemojex/assets/packages` and `grep -rniE '@jest-environment'
  echo/apps/codemojex/assets/packages` run (over the whole packages tree: test, config, **and** src)
- **Then** both return **0**,
- **And** because S1 + S2 require the suites **green** with **jest gone**, a no-op that left jest in place
  cannot satisfy both — the green-and-jest-free pair is the proof.

## S4 — The vendored client is still faithful: the lobby boots (the load-bearing guard)

*As a player, I want the lobby and board to work exactly as before the test port, so that touching the test
files never changed the client's runtime behavior.*

**Exercises:** INV-VENDORED-FAITHFUL (A4) — the one invariant a green test run could still let slip. **Surface:**
`packages/*/src/**` (runtime bytes unchanged; only comments / type-only edits), the cm-tma.1 A4 boot smoke,
`js/app.js` + `src/index.tsx` + `src/types.ts` (zero diff).

- **Given** the port complete
- **When** the cm-tma.1 runtime boot smoke runs (the `node/codemojex-e2e` path or the headless `app.js` boot)
  and `git diff packages/*/src/**` is inspected
- **Then** the `LiveSocket` **connects** and the `EdgeReact` hook **mounts** the game island exactly as in
  cm-tma.1; the `src/**` diff is **comments / type-only at most** (no executable-byte change); and `js/app.js`,
  `src/index.tsx`, `src/types.ts` have **zero diff**,
- **And** the **mutation guard:** the Director seeds a source mutation in a covered path and confirms a ported
  assertion **kills** it — a port that went green by **deleting** assertions MUST fail this story.

## S5 — The DOM suites run under jsdom

*As a front-end engineer, I want the DOM-touching tests to run under jsdom, so that the un-annotated phoenix
tests and the DOM-driven LV tests have a `window`/`document` to run against.*

**Exercises:** the environment + jsdom config (A6). **Surface:** the `jsdom` devDep on both packages, both
`vitest.config.ts` `environment:'jsdom'`, `serializer.test.ts`'s `node` override, `socket_http.test.ts`'s
jsdom URL.

- **Given** jsdom installed and both configs defaulting to `environment:'jsdom'`
- **When** the suites run
- **Then** `channel`/`socket`/`longpoll` (which touch `window`/`document`/`WebSocket` with **no** docblock,
  re-probed) run under jsdom and pass; `serializer.test.ts` runs under `node` (its `// @vitest-environment
  node` override); and `socket_http.test.ts` runs under jsdom seeing the `http://example.com/` document URL,
- **And** `grep '@jest-environment' packages` → 0 (the docblocks were **converted** to `@vitest-environment`,
  not deleted).

## S6 — The boundary holds (test surface only)

*As the reviewer, I want this rung confined to the test surface, so that it carries zero risk to the engine,
the served bundles, the swap ABI, or the cm-tma.1 build config.*

**Exercises:** the boundary (A7). **Surface:** the diff scope.

- **Given** the rung complete
- **When** the diff is reviewed
- **Then** the changes are confined to `echo/apps/codemojex/assets/packages/**` + the regenerated
  `echo/apps/codemojex/assets/pnpm-lock.yaml` + these specs; and `lib/codemojex/**`, `assets/js/app.js`,
  `assets/src/**`, `assets/package.json`, the root build configs (`tsconfig.json`, both vite configs), the edge
  image surface (`Dockerfile`/`fly.toml`/`bin/edge-deploy.sh`), `echo/Dockerfile`, `echo/fly.toml`,
  `mix.lock`, and every sibling app have **zero diff**,
- **And** the `pnpm-lock.yaml` churn is **only** the added `jsdom` (+ its transitive deps) — no unrelated
  version movement.

## S7 — Typecheck is the Operator's call (the surfaced fork)

*As the Operator, I want to decide whether cm-tma.2 also makes per-package typecheck green, given that the
vendored `src` is transpile-only JS-as-`.ts` (449–688 `tsc` errors), so that the rung's scope reflects a real
choice and not an unachievable estimate.*

**Exercises:** INV-TYPES (A5) — **`[FORK-PENDING]`** (body §8). **Surface:** the per-package `typecheck` scope
+ `@ts-nocheck`'d vendored src (Option A only).

- **Given** the body §8 fork (A = scope typecheck to the test files + `@ts-nocheck` the src; B = defer
  typecheck to a later rung **[RECOMMENDED]**; C = fully re-type the src **[rejected]**)
- **When** the Operator rules
- **Then** under **Option A**, `pnpm -C packages/phoenix typecheck` and `pnpm -C packages/phoenix_live_view
  typecheck` exit 0 **and meaningfully check the ported test files** (`tsc --listFiles` resolves the package's
  own `test/*.test.ts`, not `assets/src/*`), with the vendored `src` `@ts-nocheck`'d (byte-neutral);
- **Or** under **Option B**, A5 is **struck** and the rung ships S1–S6 (A1–A4 + A6–A9) — the vendored-client
  typing becomes its own future rung,
- **And** in **either** case the A13 `grep '\bjest\b' → 0` letter is closed (the `rendered.js:283` comment is
  fixed regardless of the ruling).

---

## Coverage (every Deliverable → its story → its check)

| Deliverable (body §12) | Story | Check |
|---|---|---|
| Port the jest API → `vi.*` (~319 sites); drop `@jest/globals` | S1, S2, S3 | A1, A2, A3 |
| Fix import paths (phoenix `../src`; LV alias; the typo; the JSON import) | S1, S2 | A1, A2 |
| Add jsdom + env/globals config; convert the docblocks | S1, S5 | A6 |
| Repair the LV `test/tsconfig.json` (Class 4) | S2 | A2 |
| Broaden collection so no intended file is skipped | S2 | A8 |
| Update the `rendered.js:283` jest comment | S3 | A3 |
| Preserve INV-VENDORED-FAITHFUL (runtime bytes; the boot smoke) | S4 | A4 |
| Hold the boundary (test surface + jsdom-only lockfile churn) | S6 | A7 |
| Determinism posture (≥5 runs + seed sweep; no ≥100 loop) | S1, S2 | A9 |
| Typecheck dimension (the surfaced fork) | S7 | A5 `[FORK-PENDING]` |
