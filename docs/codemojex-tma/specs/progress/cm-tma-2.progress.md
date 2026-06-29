# cm-tma-2 — AAW scope ledger

> Per-rung audit ledger for **cm-tma.2 — Vendored test suites jest→vitest (INV-VITEST)**. The spec body
> [`../cm-tma.2.md`](../cm-tma.2.md) is authoritative; this ledger records the run (Venus reconcile → Mars
> build → Director verify → Mars-2 harden → Apollo/ship). Hand-written; the build agents append.

## Acceptance checklist (UNVERIFIED — the build fills these)

| Check | Invariant | Target | Status |
|---|---|---|---|
| **A1** | INV-VITEST (phoenix) | `pnpm -C packages/phoenix test --run` → 6 `.test.ts` suites pass, >0 tests | ☐ UNVERIFIED |
| **A2** | INV-VITEST (LV) | `pnpm -C packages/phoenix_live_view test --run` → all **18** intended files pass, >0 tests | ☐ UNVERIFIED |
| **A3** | jest retired | `grep -rniE '\bjest\b' echo/apps/codemojex/assets/packages` → 0 (incl. `rendered.js:283`) | ☐ UNVERIFIED |
| **A4** | INV-VENDORED-FAITHFUL | cm-tma.1 boot smoke still green; `git diff packages/*/src/**` comment/type-only; `js/app.js`+`src/**` 0 diff | ☐ UNVERIFIED |
| **A5** | INV-TYPES `[FORK-PENDING §8]` | (Option A only) `pnpm -C packages/* typecheck` green + checks the test files | ☐ FORK-PENDING |
| **A6** | environment/jsdom | jsdom devDep (both); `environment:'jsdom'`; `serializer`→node; `socket_http` jsdom URL; `grep '@jest-environment'` → 0 | ☐ UNVERIFIED |
| **A7** | boundary | diff = `packages/**` + jsdom-only `pnpm-lock.yaml` + specs; engine/served-bundles/swap-ABI/`mix.lock` 0 diff | ☐ UNVERIFIED |
| **A8** | collection completeness | run reports the expected file count (phoenix 6, LV 18); no silent skip | ☐ UNVERIFIED |
| **A9** | determinism posture | ≥5 consecutive green runs + seed sweep; no id-mint/lease ⇒ no ≥100 loop | ☐ UNVERIFIED |

## {cm-tma-2-thinking} Thinking

### T-1 — Bootstrap derivation + lag-1 reconcile (Venus, this session)

5W: **WHO** the front-end engineers/reviewers who need a running unit floor for the vendored Phoenix client;
**WHAT** port both vendored packages' `test/*.test.ts` suites jest→vitest so `pnpm -C packages/* test` runs
green + `grep '\bjest\b' packages` → 0 (close the cm-tma.1 A13 deferral); **WHERE** boundary =
`echo/apps/codemojex/assets/packages/**` + `assets/pnpm-lock.yaml` (jsdom devDep only) + the cm-tma.2 specs;
**WHEN** now (cm-tma.1 shipped 13/14 with A13 deferred, Operator D-5); **WHY** A4 (runtime boot smoke) carries
integration faithfulness but the unit suites — the complementary INV-VENDORED-FAITHFUL proof — never ran.

Solution space: (A) port both suites to the brief §16 6-step order + gate A1–A9 [chosen]; (B) do-nothing
(leaves A13 open, no unit floor); (C) port phoenix only, defer LV — rejected (LV is the harder/larger half and
the deferral names both). Risk = NORMAL test-tooling with ONE adjacency to the frozen INV-VENDORED-FAITHFUL
`src` surface (the comment / type-only edits must be byte-neutral; A4 holds; Director mutation-spot-checks a
ported assertion).

**Lag-1 reconcile verdict: BUILD-GRADE with one SURFACED FORK (typecheck).** Every §3 ground-truth claim is
MATCH (re-probed on disk this session). Three load-bearing **divergences from the queued estimate**, all
folded into the body:

| Estimate | Disk reality | Resolution in the body |
|---|---|---|
| env: phoenix per-file pragma; LV jsdom default | phoenix `channel`(2)/`socket`(24)/`longpoll`(19) touch DOM with **no** docblock → need jsdom DEFAULT too | §6: `environment:'jsdom'` default on **both**; `serializer`→node the sole override |
| typecheck: declare missing types ({Channel}) → green | vendored `src` is upstream JS renamed `.ts`; `tsc` = 688 strict / 449 loose; climbs to `assets/tsconfig.json` today (no-op); leaks into test-scoped typecheck | §8 FORK (A/B/C); RECOMMEND B (defer); A5 `[FORK-PENDING]` |
| ~320 jest call-sites | 319 `\bjest\b` in test files (215 phoenix + 104 LV) — counts match the table | §3 table (full API surface) |

**New findings the estimate missed** (folded in): (1) the **collection gap** — the `test/**/*.test.ts` glob
silently skips LV's `integration/{event,metadata,portal}_test.ts` + `rendered_test.ts` (4 `*_test.ts` files,
jsdom-runnable) → §7 liveness law + A8 (pinned file count); (2) `src/rendered.js:283` `// fallback for jest`
is the only `\bjest\b` in `src` and blocks A13's grep → §8 (byte-neutral comment fix); (3) the LV subpath
drift is **38** `phoenix_live_view/*` imports (not just `test_helpers`), cleanly resolved by ONE vitest alias;
(4) `event.test.ts:6` typo `phoenix_live_viewview_hook`; (5) `hook_types.test.ts` is a type-test with a dummy
runtime test (`:127-129`) so vitest collects it.

Baselines re-probed (NO-INVENT): phoenix → `Cannot find package '@jest/globals'` + `Cannot find module
'../js/phoenix'`; LV → `TSConfckParseError` on `extends:"../../tsconfig.json"` (`packages/tsconfig.json`
absent), all 14 `.test.ts` suites. jsdom absent. tsc-over-src = 688 strict / 449 loose; test-scoped typecheck
leaks 212 (socket.ts) + 94 (channel.ts) + … Toolchain: node 22.18.0, pnpm 10.17.1, vitest 4.1.9, vite 6.4.3.

Two RISKs flagged for Mars to verify against vitest 4.1.9: **R-1** `vi.advanceTimersToNextFrame` exists (10
call-sites depend on it); **R-2** the per-file `@vitest-environment-options` jsdom URL mechanism (fallback
`test.environmentOptions.jsdom.url`).

### T-2 — SETUP reconciliation (post-Phase-A, this session)

Phase A (Operator-ruled, supersedes stale §8 text) declared **real TypeScript types across both packages'
`src/`** — the §8/S7 typecheck fork is RESOLVED toward "declare types" (NOT Option B defer). phoenix `src` is
already committed; LV `src` is typed **on disk** (uncommitted) — so the LV `src/**` diff vs HEAD is Phase A's
type-only annotations (esbuild-stripped) PLUS this rung's single comment edit; A4 byte-neutrality holds.
Consequences folded into SETUP: (1) the lone `src` jest reference moved `rendered.js:283` →
**`rendered.ts:291`** (Phase A renamed the 5 LV `.js`→`.ts`); updated byte-neutrally to `// fallback for
non-DOM environments`. (2) Phase A CREATED per-package `packages/{phoenix,phoenix_live_view}/tsconfig.json`,
so the LV `test/tsconfig.json` Class-4 fix is now `extends → "../tsconfig.json"` (the real per-package config),
not `../../tsconfig.json`; stale `paths` dropped; `types → ["vitest/globals","jsdom"]` (jest dropped).
(3) cm-tma.2 now ADDITIONALLY delivers the deferred **test type safety**: a mirrored
`packages/phoenix/test/tsconfig.json` was added so both packages' ported test files typecheck on the typed
`src`. A5/INV-TYPES is no longer FORK-PENDING for the test scope.

## {cm-tma-2-decisions} Decisions

_(the build appends D-n here)_

## {cm-tma-2-learnings} Learnings

_(the build appends L-n here)_

## {cm-tma-2-progress} Progress

_(the build appends P-n here)_

## {cm-tma-2-report} Report

_(the build appends Y-n here)_

## {cm-tma-2-complete} Complete

_(the Director appends Z-n at ship)_
