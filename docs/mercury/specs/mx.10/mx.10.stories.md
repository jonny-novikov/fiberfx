# MX.10 · acceptance stories

Given/When/Then for [`mx.10.md`](./mx.10.md). Each story is in Connextra form, names the deliverable it realizes
and the invariant(s) it proves, and states concrete, checkable criteria — "done" is a closure over these checks,
not prose. Authored at **SOLID-FORWARD** grain; re-sharpened at the rung's ship against the as-built manifest set
and the installed vite/vitest versions. **Coverage:** K-1 → S-1; K-2 → S-2; K-3 → S-3, S-4; K-4 → S-5;
K-5 → S-6; K-6 → S-7, S-8.

## S-1 · The catalog declares each version once (K-1)
*As a **Mercury maintainer**, I want one place that declares each shared toolchain version, so that the versions
are policy, not the accident of a dedup.*
**Given** `mercury/pnpm-workspace.yaml`, **when** a maintainer reads its `catalog:` block, **then** it declares
exactly seven entries — `typescript ~5.9.3`, `vite ^7`, `vitest ^4`, `react ^19`, `react-dom ^19`, `jsdom ^26`,
and `@vitejs/plugin-react` at a vite-7-compatible version — **and** those literals appear **nowhere else** in the
in-scope manifest set. *(Proves INV-2.)*

## S-2 · Every in-scope manifest references the catalog, with no override (K-2)
*As a **library maintainer**, I want each package to defer to the catalog, so that no manifest can silently pin a
different version.*
**Given** the in-scope manifests (`packages/*/package.json`, `apps/*/package.json`, the root
`package.json`), **when** a reviewer greps them for the seven catalog deps, **then** each declares `"catalog:"`
and **no** manifest declares a literal or caret for any of the seven —
`grep -rE '"(typescript|vite|vitest|react|react-dom|jsdom|@vitejs/plugin-react)"\s*:\s*"[~^0-9]'` over the
in-scope set is **empty**. *(Proves INV-2 + INV-5.)*

## S-3 · The build runs on vite 7 (K-3)
*As a **Mercury contributor**, I want the packages and apps built on vite 7, so that the toolchain is current
and the Environment API / Rollup 4 line is available.*
**Given** the catalog `vite ^7` and a `vite-7`-compatible `@vitejs/plugin-react`, **when** `pnpm run
verify:mercury` and `pnpm --filter "./apps/*" build` run, **then** both exit 0, **and** `pnpm --filter
@mercury/ui exec vite --version` prints a `7.` line — the mercury manifests resolve `vite@7.x`. *(Proves INV-3.)*

## S-4 · The Storybook builder builds on vite 7 (K-3)
*As a **design-system author**, I want the Storybook host to build on vite 7, so that the largest vite consumer
does not block the lift.*
**Given** `apps/storybook` on the `@storybook/react-vite` builder, **when** `pnpm run sb:build` runs on the
vite-7 toolchain, **then** it exits 0 and produces the Storybook `dist/`. **And** the liveness proof: if the
installed `@storybook/react-vite` does **not** admit vite 7, the rung records that as a named blocker (a
Storybook bump joins the rung or the fork is escalated) — never a silent downgrade of `vite` back to 6.
*(Proves INV-3.)*

## S-5 · The vitest dual-major is gone (K-4)
*As a **contributor running tests**, I want one vitest major in the install, so that `@testing-library/jest-dom`
stops colliding across a version boundary.*
**Given** the root `vitest` converged to the catalog `^4` (from `^3.0.0`), **when** a reviewer inspects
`pnpm-lock.yaml`, **then** the in-scope importers all resolve a single `vitest@4.x`, and **no** in-scope importer
pulls `vitest@3.x` — any residual `3.x` traces to a `codemojex/**` importer only (the bounded transitional state
until the sibling `/cm-ship` rung). *(Proves INV-4.)*

## S-6 · TypeScript is tilde-pinned uniform; react and jsdom aligned (K-5)
*As a **Mercury maintainer**, I want TypeScript pinned by tilde and react/jsdom uniform, so that a type-checking-
breaking minor cannot enter on an install and the shared test deps stop splitting.*
**Given** the catalog, **when** a reviewer reads its `typescript` entry, **then** it begins `~` (`~5.9.3` — a
patch-only pin, because TypeScript is not semver), `react`/`react-dom` are `^19`, and `jsdom` is `^26` — **and**
the S-2 grep confirms no in-scope manifest overrides any of them with a caret. *(Proves INV-5.)*

## S-7 · The barrel is untouched and no codemojex manifest changed (K-6)
*As a **Director**, I want the dependency rung to move zero exports and stay inside the ruled boundary, so that
the design system's public surface and the sibling island are both undisturbed.*
**Given** the completed rung, **when** the gate runs the barrel-diff and the boundary check, **then**
`diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` is **empty**
(byte-identical — 0 removed/renamed), **and** `git diff --name-only -- 'mercury/codemojex/**/package.json'` is
**empty**, **and** `git diff -- 'mercury/**/src/**'` is **empty** (no code change). *(Proves INV-1 + INV-6 +
INV-7.)*

## S-8 · Green on the new toolchain, pre-existing reds baselined (K-6)
*As an **AAW implementor**, I want the gate green on vite 7 / vitest 4 with pre-existing reds baselined, so that
the lift is proven and no prior failure is charged to it.*
**Given** a pre-rung baseline of `pnpm --filter "./packages/*" build` (recording any package already red from
HEAD, e.g. `@echo/fx`), **when** `pnpm run verify:mercury` + `pnpm --filter "./apps/*" build` + `pnpm run
sb:build` run on the vite-7 / vitest-4 toolchain, **then** they exit 0 for the `@mercury/*` set and the apps,
**and** the post-rung red set **equals** the baseline — the lift introduces **no new red**, and the pre-existing
`@echo/fx` red is neither fixed nor regressed. *(Proves INV-8.)*
