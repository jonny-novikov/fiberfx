# MX.3 · acceptance stories

Given/When/Then for [`mx.3.md`](./mx.3.md). Each story is in Connextra form, names the deliverable it
realizes and the invariant(s) it proves, and states concrete, checkable criteria — "done" is a
closure over these checks, not prose. **Coverage:** K-1 → S-1, S-2; K-2 → S-3, S-4; K-3 → S-5;
K-4 → S-6, S-7, S-8; K-5 → S-9.

## S-1 · The host builds to a static bundle (K-1)
*As a **Mercury contributor**, I want a `@storybook/react-vite` host that builds, so that the design
system has a deployable, browsable home.*
**Given** a new `apps/storybook/` with `package.json` (`@mercury/storybook`, Storybook devDeps,
`@mercury/*` as `workspace:*`), `.storybook/main.ts` (`@storybook/react-vite`, CSF3), and
`.storybook/preview.tsx`, **when** the Director runs `pnpm sb:build`, **then** the command exits 0 and
produces `apps/storybook/storybook-static/` (an `index.html` + assets). *(Proves INV-3.)*

## S-2 · The host resolves the packages from source (K-1)
*As a **Mercury contributor**, I want the Storybook to render the live package source, so that a
component edit is visible in the story with no prebuild.*
**Given** the host's `vite.config.ts`, **when** a reviewer reads its `resolve.alias`, **then** it maps
`@mercury/ui`, `@mercury/effector`, and `@mercury/core` to `../../packages/<pkg>/src/index.ts`
(byte-mirroring `apps/showcase/vite.config.ts`), **and** `@storybook/react-vite` consumes that alias
(the `vite.config.ts` auto-merge, or a `viteFinal` in `main.ts`), **and** the Icon/Button stories
render without any package `dist/` present. *(Proves INV-4.)*

## S-3 · The three foundation stories render (K-2)
*As a **design-system browser**, I want Icon, tokens, and Button as the first stories, so that the
host is proven against a leaf, the token vocabulary, and a rich enum component.*
**Given** the built host, **when** it loads, **then** exactly three story homes appear —
`Foundations/Icon` (from `packages/mercury-ui/src/components/foundations/Icon/Icon.stories.tsx`),
`Foundations/Tokens` (from `apps/storybook/stories/Tokens.stories.tsx`), and `Actions/Button` (from
`packages/mercury-ui/src/components/actions/Button/Button.stories.tsx`) — each a CSF3 file, each
importing only real `@mercury/ui` exports (`Icon`, `Button`). **And** no other component or app-screen
story is present (host + foundations only). *(Proves INV-7 presence + INV-8 scope.)*

## S-4 · Story controls are grounded in the contract, not invented (K-2)
*As an **AAW implementor**, I want each story's controls to restate the component's `<Name>.prompt.md`,
so that the story and the contract never drift.*
**Given** the Icon and Button stories, **when** a reviewer checks each `argTypes` entry against the
component's `.prompt.md` and `.tsx`, **then** every control name and option set is present in both:
Button's `variant` options are exactly `primary|secondary|outline|ghost|destructive|inverse` and
`size` is `sm|md|lg` (per `Button.prompt.md`); Icon's `name` options are the `IconName` set and `size`
is a number (per `Icon.prompt.md`). **And** no story passes a prop the source does not define, and no
story contains the string `window.MercuryUI` or `_ds_bundle`. *(Proves INV-7.)*

## S-5 · The theme decorator flips light/dark (K-3)
*As a **design reviewer**, I want a global light/dark toggle, so that I can verify every component
under the canon's `dark-theme` flip.*
**Given** the host with a global decorator and a `globalTypes` toolbar toggle, **when** a viewer
switches the toolbar from light to dark, **then** the story re-renders under a `dark-theme` ancestor
(the canon §0 mechanism; the `.dark-theme` token block in
`packages/mercury-ui/src/styles/tokens.css`) and the Button story's surface/foreground inverts. **And**
the `@mercury/ui` stylesheet is loaded in the preview, so the Tokens story's `rgb(var(--token))`
swatches resolve in both states. *(Proves INV-5.)*

## S-6 · The per-rung apps gate excludes the host and stays green (K-4)
*As a **Director**, I want the standard ladder to build only the five product apps, so that adding the
Storybook does not slow every rung.*
**Given** the new host in the `apps/*` glob, **when** the per-rung gate runs
`pnpm --filter "./packages/*" typecheck`, `pnpm --filter "./packages/*" build`, and
`pnpm --filter "./apps/*" --filter "!@mercury/storybook" build`, **then** all exit 0, the apps step
builds exactly the **five** product apps (`catalogue`, `docs`, `echomq`, `mobile`, `showcase`) and
**not** `@mercury/storybook`, **and** the root `build:apps` script carries the same exclusion. *(Proves
INV-2 + INV-3-exclusion + INV-8.)*

## S-7 · The library gate is undisturbed by the co-located stories (K-4)
*As a **package maintainer**, I want `@mercury/ui`'s own build to ignore story files, so that a
co-located `*.stories.tsx` (which imports Storybook types the library does not carry) never breaks the
packages gate.*
**Given** `Icon.stories.tsx` and `Button.stories.tsx` co-located under
`packages/mercury-ui/src/components/`, **when** `pnpm --filter @mercury/ui typecheck` and
`pnpm --filter @mercury/ui build` run, **then** both exit 0 because
`packages/mercury-ui/tsconfig.json` excludes `**/*.stories.tsx` (and `tsconfig.build.json`, which
extends it, inherits the exclude) — the library `tsc` never sees a Storybook import. *(Proves INV-8 +
INV-2.)*

## S-8 · The bundle is relocated and the host is the `/design-sync` localDir (K-4)
*As a **Mercury maintainer**, I want the design-sync bundle co-located under the host, so that
`/design-sync` runs from `apps/storybook/` with one `writes:["**"]` plan.*
**Given** that `/design-sync` defaults `localDir` to cwd and rejects any uploaded `localPath` outside
`localDir`, **when** the `ds-bundle/` is relocated to `apps/storybook/ds-bundle/`, **then**
`apps/storybook/` is the single `/design-sync` `localDir`, **and** `mercury/.gitignore` ignores
`apps/storybook/storybook-static/` and the relocated `apps/storybook/ds-bundle/` (the existing bare
`ds-bundle/` rule already covers any location; the explicit entry documents intent). **And** the spec
states the full `/design-sync` pipeline re-align is **mx.6**, not this rung. *(Proves INV-8 + the
relocation contract.)*

## S-9 · The host is built to receive the mx.4 apps-side stories (K-5)
*As the **mx.4 implementor**, I want mx.3's glob to already span the apps tree, so that the apps-side
fan-out drops in without re-touching the host.*
**Given** `.storybook/main.ts`, **when** a reviewer reads its `stories` array, **then** it covers
**all three** roots — the host's own `stories/**`, `packages/mercury-ui/**/*.stories.@(tsx|ts)`
(filled this rung), **and** `apps/**/*.stories.@(tsx|ts)` (empty until mx.4) — **and** the spec §6
records the mx.4 mandate quote-faithfully (apps-side Pages from the real composed screens, wiring real
`@mercury/ui` + `@mercury/effector`, **plus** the additive `@mercury/ui` enhancement under the master
invariant). *(Proves INV-6 + the forward mandate.)*
