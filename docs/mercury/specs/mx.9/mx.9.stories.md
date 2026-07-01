# MX.9 · acceptance stories

> **EPIC-LEVEL after the 2026-07-02 split** ([`mx.9.md`](./mx.9.md) is now the SUB-EPIC frame): these stories
> route to the sub-rungs that realize them — **S-1, S-2 → mx.9.1** · **S-3, S-4 → mx.9.2** · **S-5 → mx.9.3**
> · **S-6, S-7 → mx.9.4** · **S-8 → mx.9.2** (the toggle mechanism) **+ mx.9.5** (the dual-theme acceptance)
> · **S-9, S-10 → mx.9.1** (the join/wiring) **+ mx.9.5** (the whole-epic closure re-run). Each sub-rung's own
> `.stories.md` is the acceptance face at its ship; this file is the epic contract, re-verified whole at the
> mx.9.5 closer. Where a sentence below disagrees with the reconciled body (the `dev:showcase` ADD · the 11
> `storybook/test` value-imports + the shim · the lockfile importer posture · the automatic stylesheet · the
> 65 count), **the body wins**.

Given/When/Then for [`mx.9.md`](./mx.9.md). Each story is in Connextra form, names the deliverable it
realizes and the invariant(s) it proves, and states concrete, checkable criteria — "done" is a closure over
these checks, not prose. Authored at **SOLID-FORWARD** grain; re-sharpened at the rung's ship against the
as-built `@mercury/ui` surface (mx.7.4 + mx.8). **Coverage:** K-1 → S-1, S-2; K-2 → S-3, S-4; K-3 → S-5;
K-4 → S-6, S-7; K-5 → S-8; K-6 → S-9, S-10.

## S-1 · The showcase app builds (K-1)
*As a **Mercury contributor**, I want a real `apps/showcase/` app that builds, so that the design system has
one deployable, browsable home.*
**Given** a new `apps/showcase/` with `package.json` (`@mercury/showcase`, `@mercury/*` as `workspace:*`, the
`apps/echomq` dep set), `vite.config.ts`, `tsconfig.json`, `index.html`, and `src/{main.tsx,App.tsx}`,
**when** `pnpm --filter @mercury/showcase build` runs, **then** it exits 0 and produces `apps/showcase/dist/`
(an `index.html` + assets). *(Proves INV-3.)*

## S-2 · The app resolves the packages from source (K-1)
*As a **Mercury contributor**, I want the showcase to render live package source, so that a component edit is
visible with no prebuild.*
**Given** the app's `vite.config.ts` and `tsconfig.json`, **when** a reviewer reads `resolve.alias` and the
tsconfig `paths`, **then** both map `@mercury/ui`, `@mercury/effector`, and `@mercury/core` to
`../../packages/<pkg>/src/index.ts` (byte-mirroring `apps/echomq/vite.config.ts`), **and** the app renders a
component with **no** package `dist/` present. *(Proves INV-2.)*

## S-3 · The nav is derived from the real library, not hardcoded (K-2)
*As a **library maintainer**, I want the showcase nav built from the real `@mercury/ui` tree, so that it
covers the whole surface and never drifts.*
**Given** the running showcase, **when** a reviewer inspects how the sidebar is built, **then** the component
list comes from a **glob** over `packages/mercury-ui/src/components/**/*.stories.tsx` (+ the sibling
`*.prompt.md`), grouped by the `<group>/` segment — **and** there is **no** hardcoded component-name array in
`apps/showcase/src/**`. **And** the liveness proof: adding a throwaway component folder to `@mercury/ui` makes
a new nav entry appear with **no** edit to `apps/showcase/src/**` (revert after). *(Proves INV-6.)*

## S-4 · Every post-import component appears, grouped (K-2)
*As a **design-system browser**, I want every `@mercury/ui` component navigable under its group, so that the
showcase is the comprehensive home the mandate names.*
**Given** the completed import (mx.7.4) and the derived registry, **when** the showcase loads, **then** the
sidebar lists **every** component that has a `*.stories.tsx` in `@mercury/ui`, grouped (Foundations · Actions ·
Inputs · Selection · Data display · Feedback · Overlay · Navigation · Layout), and selecting one opens its
component page. **And** the count of nav entries equals the count of `@mercury/ui` story files (no component
silently dropped, none invented). *(Proves INV-6 + the comprehensive-coverage goal.)*

## S-5 · A component's live stories render — no Storybook runtime (K-3)
*As a **design reviewer**, I want each component's stories rendered in its page, so that I see the real
component in its states without leaving the showcase.*
**Given** a component page, **when** its **Stories** tab is open, **then** the page renders the component's
`*.stories.tsx` named exports — `story.render()` mounted as its own component, or `createElement(meta.component,
story.args)` — each in an error boundary, using the live `@mercury/ui` source. **And** the app pulls **no
Storybook runtime**: the story's `import type { Meta, StoryObj } from "@storybook/react-vite"` is type-only
(erased at build), and grep of `apps/showcase/src/**` finds no value import from `@storybook/*`. *(Proves INV-5
render-path + K-3.)*

## S-6 · The contract is rendered, never re-authored (K-4)
*As an **AAW implementor**, I want the docs rendered from the `.prompt.md` contract, so that the documentation
can never fork from the source.*
**Given** a component page's **Docs** tab, **when** it loads, **then** it renders that component's
`<Name>.prompt.md` (imported `?raw`) as markdown — and the rendered prose matches the contract file byte-for-
content (headings, the Props table, the Examples). **And** the negative proof: `apps/showcase/src/**` contains
**no** hand-written per-component API table or doc body that duplicates a contract (grep finds no in-app
component-API markdown). *(Proves INV-5.)*

## S-7 · API, do/don't, and recipes are cuts of the one contract (K-4)
*As a **library consumer**, I want the API, do/don't, and recipes surfaces, so that I can use a component
correctly — all from one trustworthy source.*
**Given** a component with a `.prompt.md`, **when** the showcase presents its **API**, **do/don't**, and
**recipes** surfaces, **then** the **API** view is the contract's `## Props`, the **do/don't** view is its
`## The enum language` + `## Notes`, and the **recipes** view is its `## Examples` — each a **cut of the same
rendered contract**, not separately authored. **And** a component whose contract lacks a section (e.g. no
`## The enum language`) shows that surface as empty/absent, never as invented content. *(Proves INV-5 + the
five-surface mandate.)*

## S-8 · The theme flip inverts a component (K-5)
*As a **design reviewer**, I want a light/dark toggle, so that I can verify every component under the canon's
`dark-theme` flip.*
**Given** the showcase with a theme toggle, **when** a viewer switches it from light to dark, **then** the
shown component re-renders under a `dark-theme` ancestor (the canon §0 mechanism; the `.dark-theme` block in
`packages/mercury-ui/src/styles/tokens.css`) and its surface/foreground **visibly inverts**. **And**
`@mercury/ui`'s stylesheet is loaded so `rgb(var(--token))` resolves in both states. *(Proves INV-8.)*

## S-9 · The app joins the apps gate; the barrel is untouched (K-6)
*As a **Director**, I want the showcase to join the product-apps gate without perturbing the library, so that
Movement III closes green.*
**Given** the new app in the `apps/*` glob, **when** the gate runs `pnpm --filter "./packages/*" typecheck`,
`pnpm --filter "./packages/*" build`, and `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build`,
**then** all exit 0, the apps step builds exactly **three** product apps (`echomq`, `mobile`, `showcase`),
**and** the barrel-diff `diff <(git show HEAD:packages/mercury-ui/src/index.ts)
packages/mercury-ui/src/index.ts` is **empty** (master invariant: 0 removed/renamed, byte-identical). *(Proves
INV-1 + INV-3 + INV-4.)*

## S-10 · Consume-down: no design-sync, no raw-path transpiler, no runtime framing (K-6)
*As a **Mercury maintainer**, I want the showcase to consume the library cleanly, so that it never pushes
design up or smuggles a runtime global.*
**Given** the built app, **when** a reviewer greps `apps/showcase/**`, **then** it is **empty** for
`design-sync`, `DesignSync`, `@babel/standalone`, `window.MercuryUI`, and `_ds_bundle` — the app resolves
`@mercury/ui` through the vite alias (the public barrel), not through the bundle's in-browser `.tsx` loader or
a runtime global, and pushes nothing to Claude Web. **And** the stale root `dev:showcase` script is reconciled
to the reborn `@mercury/showcase`. *(Proves INV-7 + INV-9 + the K-6 wiring.)*
