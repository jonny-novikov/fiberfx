# MX.6 · acceptance stories

Given/When/Then for [`mx.6.md`](./mx.6.md). Each story is in Connextra form, names the deliverable it
realizes and the invariant(s) it proves, and states concrete, checkable criteria — "done" is a closure over
these checks, not prose. **Coverage:** K-1 → S-1..S-5 ; K-2 → S-1..S-5 ; K-3 → S-1..S-5 ; K-4 → S-6 ; K-5 →
S-7 ; K-6 → S-8 ; K-7 → S-9.

> One story per app (S-1..S-5) proves that app's page deliverable (a story file that exists, renders the real
> `<App/>`, brings the app's CSS, and composes only real Mercury surface). S-6..S-9 are the rung-wide gates
> (surface frozen · no source rewrite · type gate live · gate green). Stories assume the recommended forks
> (A = App-level, B = render `<App/>` + app CSS, C = freeze, D = D1 co-located + the two config edits); if the
> Operator rules Fork D = D2 (host-home), S-1..S-5 re-home to `apps/storybook/stories/apps/` and S-8's edits
> drop — the body re-derives, the acceptance shape is unchanged.

## S-1 · The Showcase page story renders the real shell + routed pages (K-1, K-2, K-3)
*As a **design-system browser**, I want a story that renders the real Showcase `<App/>` — its `Shell` chrome,
the store-routed pages, the wired modals and `Toaster` — so that a whole product page built from Mercury is
visible at page scale.*
**Given** `apps/showcase/src/App.stories.tsx` — CSF3, `title: "Apps/Showcase"`, `import { App } from "./App"`,
`import "./showcase.css"` — **when** the `Default` story renders, **then** the real `<App/>` mounts (sidebar +
topbar + the `useRoute()`-selected page, composed from `@mercury/ui` + `@mercury/effector`), the sidebar
navigates between pages within the one story, and the story authors **no** chrome or screen of its own (it
imports and renders the shipped `App`). *(Proves INV-3 + INV-6.)*

## S-2 · The EchoMQ page story renders the real dashboard + Tabs-routed views (K-1, K-2, K-3)
*As a **dashboard reviewer**, I want a story that renders the real EchoMQ `<App/>` — the `.eqd` frame, the
`MetricStrip`, the `Tabs` over the five views — so that the dashboard composed from Mercury is browsable.*
**Given** `apps/echomq/src/App.stories.tsx` (`title: "Apps/EchoMQ"`, `import { App } from "./App"`,
`import "./echomq.css"`), **when** the `Default` story renders, **then** the real `<App/>` mounts (Sidebar /
Topbar / MetricStrip + a `Tabs<View>` over `Overview·Jobs·Groups·Batches·Processors`), the tabs switch views
within the story, and every wired surface is a real `@mercury/ui`/`@mercury/effector` export — no invented
prop. *(Proves INV-3 + INV-6.)*

## S-3 · The Mobile page story renders the real phone frame + screens (K-1, K-2, K-3)
*As a **mobile reviewer**, I want a story that renders the real Mobile `<App/>` — the phone frame, the auth +
tab router, the `Toaster` — so that the fintech mock built on Mercury is interactive in the Storybook.*
**Given** `apps/mobile/src/App.stories.tsx` (`title: "Apps/Mobile"`, `import { App } from "./App"`,
`import "./mobile.css"`), **when** the `Default` story renders, **then** the real `<App/>` mounts (`.em-phone`
frame; `$authed` default `true` → `Home`; bottom-nav tabs switch screens; `Send` overlay reachable; `Login`
reachable by logging out), the story mutates **no** module-global store at mount (leak-free — §6.3), and every
wired surface is real. *(Proves INV-3 + INV-6 + INV-7.)*

## S-4 · The Catalogue page story renders the monolithic app with no CSS import (K-1, K-2, K-3)
*As a **token reviewer**, I want a story that renders the real Catalogue `<App/>` — its colors/type/components
pages and theme switch — so that the inline-styled, token-only catalogue is browsable.*
**Given** `apps/catalogue/src/App.stories.tsx` (`title: "Apps/Catalogue"`, `import { App } from "./App"`,
**no** app-CSS import — catalogue has no stylesheet), **when** the `Default` story renders, **then** the real
`<App/>` mounts (sidebar + the `useState`-switched `colors`/`type`/`components` pages + a `Segmented` theme
switch wired to `useTheme`/`setTheme`), it renders correctly on tokens alone (the preview already loads the
`@mercury/ui` stylesheet), and the story imports no CSS. *(Proves INV-3 + INV-6 + INV-7.)*

## S-5 · The Docs page story renders the real docs site (K-1, K-2, K-3)
*As a **docs reviewer**, I want a story that renders the real Docs `<App/>` — its nav, sections, the in-page
`createForm` settings demo, the `Toaster`, and the scroll-spy — so that the documentation app built on Mercury
is browsable.*
**Given** `apps/docs/src/App.stories.tsx` (`title: "Apps/Docs"`, `import { App } from "./App"`,
`import "./docs.css"`), **when** the `Default` story renders, **then** the real `<App/>` mounts (nav + sections
+ the module-scope `createForm` demo + `toast`/`Toaster`; the scroll-spy `useEffect` adds and cleans up its
`window` listener without error), and every wired surface is real. *(Proves INV-3 + INV-6.)*

## S-6 · The @mercury/ui public surface is byte-identical (K-4)
*As a **downstream consumer**, I want mx.6 to add no public surface, so that nothing I import changes.*
**Given** the `@mercury/ui` barrel before and after mx.6, **when**
`diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` runs, **then** it is
**empty** (byte-identical, not merely additions-only) **and** no path under `packages/mercury-ui/src/` is
changed — any unavoidable non-export-changing fix is explicitly flagged in the report, never silent.
*(Proves INV-1 + INV-2.)*

## S-7 · No app source is rewritten — only new stories (+ Fork-D config) (K-5)
*As an **app maintainer**, I want mx.6 to add only story files, so that the apps' shipped behavior is
untouched.*
**Given** the five apps before mx.6, **when** `git diff --name-only` runs, **then** the only added/changed
paths are the five new `apps/*/src/App.stories.tsx`, the host `apps/storybook/tsconfig.json` (one `include`
line) and the five app `tsconfig.json` (one `exclude` line each) — **no** edit to any existing app `.tsx`/`.css`
and **no** edit under `packages/mercury-ui/src/`. If a render forces an app-source edit, the build STOPS and
surfaces it as a scope fork. *(Proves INV-2.)*

## S-8 · The NO-INVENT type gate is made LIVE on the apps-side stories (K-6)
*As a **Director**, I want `sb:typecheck` to actually compile the new apps-side stories, so that an invented
prop cannot ship green (the gate proves its own liveness).*
**Given** Fork D = D1 — the host `apps/storybook/tsconfig.json` `include` extended with
`"../*/src/**/*.stories.tsx"` and each app `tsconfig.json` `exclude` extended with `"**/*.stories.tsx"` —
**when** `pnpm sb:typecheck` runs, **then** it exits 0 **and the five new stories are in its program** (a
deliberate bad prop in any apps-side story turns it RED — the liveness proof — then is reverted), **and** each
app's own `pnpm typecheck` stays 0 (the app `exclude` keeps a co-located story out of the app `tsc`). A
present story is **compiled with a positive proof**, never skipped. *(Proves INV-3 + INV-5.)*

## S-9 · The gate is green — typecheck, build, 47 homes (K-7)
*As a **Director**, I want the rung to pass the full per-rung gate, so that it ships without regression.*
**Given** the five page stories (+ Fork-D config), **when** the gate runs from `mercury/` —
`pnpm sb:typecheck` · `pnpm --filter "./packages/*" typecheck` · `pnpm --filter "./packages/*" build` ·
`pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` ·
`pnpm --filter "./apps/*" --filter "!@mercury/storybook" typecheck` · `pnpm sb:build` — **then** every command
exits 0; `sb:build` registers **exactly 47** story homes (the prior 42 unchanged + the five new
`Apps/{Catalogue,Docs,EchoMQ,Mobile,Showcase}`); the NO-INVENT grep
(`window.MercuryUI`/`_ds_bundle` over `apps/*/src/*.stories.tsx`) and the raw-hex grep over the story files are
both **empty**. *(Proves INV-3 + INV-4 + INV-5 + INV-6 + INV-7.)*
