# cm-tma.2 · build runbook / next-session handoff

> The authoritative **run scope** for building cm-tma.2 (the vendored-suite jest→vitest port that closes the
> cm-tma.1 A13 deferral). The spec **body** [`cm-tma.2.md`](./cm-tma.2.md) wins on any disagreement; this
> runbook captures the re-probed disk state so a fresh session builds without re-deriving. **Re-probe
> `echo/apps/codemojex/assets/packages/` before editing** — the Operator changes that tree out-of-band.

Repo: `/Users/jonny/dev/jonnify` · branch `echo_mq` · spec triad authored + reconciled (Venus, this session).

## State

- **Spec triad AUTHORED**: `cm-tma.2.{md,stories.md,llms.md}` — the jest→vitest port of both vendored packages.
  The `.md` body is the source of truth. Risk = NORMAL test-tooling with ONE adjacency to the frozen
  INV-VENDORED-FAITHFUL `src` surface.
- **The deferral being closed**: cm-tma.1 §10 A13 (Operator-ruled DEFERRED, cm-tma.1 ledger D-5) — the
  `package.json` end-state is jest-free, but the `test/*.test.ts` files are unported upstream jest.
- **One fork SURFACED (body §8 — the typecheck dimension)** — awaiting the Operator's ruling (A / B / C);
  **B (defer typecheck) is RECOMMENDED**. The rung's core (suites green; jest gone) is independent of it.

## As-built reality (re-probe first — confirmed this session)

`echo/apps/codemojex/assets/packages/` (vitest 4.1.9 / vite 6.4.3 / node 22.18.0 / pnpm 10.17.1):

- **Both `package.json` jest-free** (cm-tma.1); both have `vitest.config.ts` with alias `@`→`./src`,
  `include ['test/**/*.test.ts','src/**/*.spec.ts']`, **no `globals`, no `environment`**.
- **Baseline FAILS** (re-probed): `pnpm -C packages/phoenix test` → `Cannot find package '@jest/globals'`
  (channel/longpoll/socket) + `Cannot find module '../js/phoenix'` (presence/serializer/socket/socket_http);
  `pnpm -C packages/phoenix_live_view test` → `TSConfckParseError: failed to resolve "extends":"../../tsconfig.json"`,
  **all 14 `.test.ts` suites** (the LV `test/tsconfig.json` extends the **non-existent** `packages/tsconfig.json`).
- **jsdom is NOT installed** anywhere under `assets/`; neither package declares it.
- **The 4 failure classes** (body §3/§4): (1) ~319 jest call-sites + 3 `@jest/globals` imports; (2) phoenix
  `../js/phoenix*` (5 sites) + LV `phoenix_live_view/*` subpath alias (38) + the `event.test.ts:6` typo
  `phoenix_live_viewview_hook`; (3) jsdom missing + the `@jest-environment` docblocks; (4) the broken LV
  `test/tsconfig.json`.
- **Collection gap** (liveness hazard, body §7): the `test/**/*.test.ts` glob MISSES LV's
  `test/integration/{event,metadata,portal}_test.ts` + `test/rendered_test.ts` (4 `*_test.ts` files) — they
  are jsdom-runnable and must run. Expected counts: **phoenix 6**, **LV 18**.
- **The src jest comment**: `packages/phoenix_live_view/src/rendered.js:283` `// fallback for jest` (a comment,
  the only `\bjest\b` in `src`) — blocks the A13 `grep → 0`; update it (byte-neutral).
- **Typecheck reality** (body §8 fork): neither package has its own `tsconfig.json`; `tsc --noEmit` climbs to
  `assets/tsconfig.json` (checks `assets/src/*`, NOT the package) → trivially green no-op. Over the package
  `src` it is **688 errors strict / 449 loose** (upstream JS renamed `.ts`, transpile-only); a test-scoped
  typecheck leaks them. **NOT fixable by declaring a few types** → Operator fork.

## Next task

**BUILD cm-tma.2** to the spec build brief (§16) + acceptance A1–A9 (A5 `[FORK-PENDING]`). Order:

1. **Unblock LV transform** — fix `phoenix_live_view/test/tsconfig.json` (`extends`/`paths`/`types`). (A2)
2. **jsdom + config** — `jsdom` devDep (both); `environment:'jsdom'` + `globals:true` (both); LV alias
   `phoenix_live_view`→`./src` + broadened `include` (`test/**/*_test.ts`); `serializer`→node;
   `socket_http` jsdom URL (verify `@vitest-environment-options` vs vitest 4.1.9); `pnpm install` →
   `pnpm-lock.yaml`. (A6/A8)
3. **Import paths** — phoenix `../js/phoenix*`→`../src` (5); LV typo `event.test.ts:6`; JSON import. (A1/A2)
4. **jest API sweep** — drop 3 `@jest/globals`; `jest.*`→`vi.*`; **translate** assertions, never delete. (A1/A2/A3)
5. **A13 grep honest** — `rendered.js:283` comment. (A3)
6. **[Operator Option A only]** per-package `typecheck` scope + `@ts-nocheck` src. (A5)
7. **Gate** — see below.

**GATE = the FRONT-END test gate (spec A1–A9), NOT the mix gate:** `cd echo/apps/codemojex/assets`;
`pnpm -C packages/phoenix test --run` (6 files green, >0 tests, A1); `pnpm -C packages/phoenix_live_view test
--run` (**18 files**, count pinned, no silent skip, A2/A8); `grep -rniE '\bjest\b' packages` → 0 +
`grep -rniE '@jest-environment' packages` → 0 (A3/A6); **the cm-tma.1 runtime boot smoke still green + the
`git diff packages/*/src/**` is comment/type-only + `js/app.js`/`src/**` zero diff (A4 — load-bearing; the
Director mutation-spot-checks a ported assertion: a no-op port that deletes assertions must FAIL)**; boundary
`git diff` confined to `packages/**` + jsdom-only `pnpm-lock.yaml` + specs (A7); ≥5 consecutive green runs +
seed sweep, honest determinism posture, **no ≥100 loop** (A9). May orchestrate via `/codemojex-ship cm-tma.2`,
but hold the FRONT-END test gate above (the skill's mix gate does not apply — this rung never touches
`lib/codemojex/**`).

## Constraints (load-bearing)

- **Boundary** = `echo/apps/codemojex/assets/packages/**` + `echo/apps/codemojex/assets/pnpm-lock.yaml`
  (jsdom devDep only) + the specs. **OUT:** `lib/codemojex/**`, `assets/js/app.js`, `assets/src/**`,
  `assets/package.json`, the root build configs, the edge image surface, `echo/Dockerfile`, `echo/fly.toml`,
  `mix.lock`, sibling apps.
- **INV-VENDORED-FAITHFUL:** the port touches test files, test config, and byte-neutral comments only — the
  vendored `src/**` runtime bytes are unchanged and the cm-tma.1 A4 boot smoke must hold. A "green" suite that
  deleted assertions is a FAIL (the mutation spot-check).
- **Liveness law (§7):** a green run that silently skips files proves nothing — A8 pins the collected-file
  count (phoenix 6, LV 18).
- **The typecheck fork (§8) is the Operator's** — surface A/B/C, do not decide. RECOMMEND B (defer).
- **Operator runs ALL deploys**; no deploy here (test-only rung).
- **Commit pathspec-only** (never `git add -A`); **ask before push**; the tree is entangled (Operator works
  out-of-band) — verify `git diff --cached --name-only` is purely the rung first.
- **Sources of truth:** [`cm-tma.2.md`](./cm-tma.2.md) (body wins) · [`cm-tma.1.md`](./cm-tma.1.md) §10 A13 ·
  the cm-tma.1 ledger [`progress/cm-tma-1.progress.md`](./progress/cm-tma-1.progress.md) · the roadmap
  [`../cm-tma.roadmap.md`](../cm-tma.roadmap.md).
