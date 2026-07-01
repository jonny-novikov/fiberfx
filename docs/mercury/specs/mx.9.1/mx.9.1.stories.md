# MX.9.1 · acceptance stories

Given/When/Then for [`mx.9.1.md`](./mx.9.1.md) (the body wins on any disagreement). Each story is in
Connextra form, names the deliverable it realizes, the invariant(s) it proves, and the epic story it
realizes (traceability into [`../mx.9/mx.9.stories.md`](../mx.9/mx.9.stories.md)). **Coverage:** K-1 → S-1;
K-2, K-3, K-4 → S-2; K-5 → S-1, S-2; K-6 → S-3, S-4.

## S-1 · The showcase app builds (K-1, K-5 · epic S-1)

*As a **Mercury contributor**, I want a real `apps/showcase/` app that builds, so that the design system has
the workspace home every later showcase surface lands in.*

**Given** the seven-file scaffold (`package.json` `@mercury/showcase` with the exact `apps/echomq` dep set ·
`vite.config.ts` · `tsconfig.json` · `index.html` · `src/main.tsx` · `src/App.tsx` ·
`src/shims/storybook-test.ts`) and a completed `pnpm install`,
**when** `pnpm --filter @mercury/showcase typecheck` and `pnpm --filter @mercury/showcase build` run from
`mercury/`,
**then** both exit 0 and the build produces `apps/showcase/dist/` (an `index.html` + assets).
*(Proves INV-3.)*

## S-2 · The app resolves the packages from source; the shim is wired (K-2, K-3, K-4, K-5 · epic S-2)

*As a **Mercury contributor**, I want the showcase to render live package source through the byte-mirrored
alias — with the `storybook/test` shim already in place — so that a component edit is visible with no
prebuild and the mx.9.2 registry can lazy-load story modules without a resolution failure.*

**Given** the app's `vite.config.ts` and `tsconfig.json`,
**when** a reviewer diffs the three `@mercury/*` alias lines against `apps/echomq/vite.config.ts` and reads
the `paths` block,
**then** both map `@mercury/ui` / `@mercury/effector` / `@mercury/core` to
`../../packages/<pkg>/src/index.ts` byte-identically, **and** `vite.config.ts` carries exactly one additional
alias entry — `storybook/test` → `src/shims/storybook-test.ts` — whose module exports exactly six names
(`fn` callable-no-op + `expect`/`userEvent`/`fireEvent`/`waitFor`/`within` loud-throw play-only stubs).
**And given** no package `dist/` present, **when** `pnpm run dev:showcase` serves the app, **then** the
sanity page renders `Button`, `Card`, and `Badge` from `@mercury/ui` and the four token swatches
(`--bg-brand` · `--bg-brand-subtle` · `--fg-on-brand` · `--indigo-3`) resolve to painted color — the
stylesheet having arrived through the barrel's side-effect import, with no explicit css import in the app.
*(Proves INV-2 + INV-4 presence/shape + the stylesheet-automatic reconcile; shim LIVENESS is mx.9.3's gate.)*

## S-3 · The app joins the apps gate; the barrel is untouched (K-6 · epic S-9)

*As a **Director**, I want the showcase to join the product-apps gate without perturbing the library, so that
the spine ships as a pure addition.*

**Given** the new app in the `apps/*` glob,
**when** the gate runs `pnpm --filter "./packages/*" typecheck`, `pnpm --filter "./packages/*" build`, and
`pnpm --filter "./apps/*" --filter "!@mercury/storybook" build`,
**then** all exit 0 and the apps step builds exactly **three** product apps (`echomq` · `mobile` ·
`showcase`) with no root script edit, **and** the barrel-diff
`diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` is empty
(Director-run).
*(Proves INV-1 + INV-3.)*

## S-4 · The wiring lands clean: `dev:showcase`, consume-down, lockfile posture (K-6 · epic S-10)

*As a **Mercury maintainer**, I want the workspace wiring to be exactly one script line and one importer
block, so that the spine's diff is reviewable at a glance.*

**Given** the edited `mercury/package.json`,
**when** a reviewer greps it and boots the script,
**then** it carries `"dev:showcase": "pnpm --filter @mercury/showcase exec vite --port 5176 --strictPort"`
(a fresh ADD — no prior script existed) and the dev server answers on `:5176` (strictPort: a port collision
fails loudly instead of drifting).
**And** `grep -RnE "design-sync|DesignSync|@babel/standalone|window\.MercuryUI|_ds_bundle" apps/showcase` is
**empty**,
**and** the `mercury/pnpm-lock.yaml` delta attributable to this rung is the `@mercury/showcase` importer
block with **no new external dependency versions** (Director-verified at commit; the worktree lockfile is
routinely dirty from sibling programs and is partitioned there).
*(Proves INV-6 + INV-7 + the K-6 wiring.)*
