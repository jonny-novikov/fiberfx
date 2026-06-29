# MX.8 · acceptance stories

Given/When/Then for [`mx.8.md`](./mx.8.md). Each story is in Connextra form, names the deliverable it
realizes and the invariant(s) it proves, and states concrete, checkable criteria — "done" is a closure
over these checks, not prose. **SOLID-FORWARD:** the counts (component homes, product apps) reconcile at
ship; the *mechanism* criteria below are fixed now. **Coverage:** K-1 → S-1 ; K-2 → S-2 ; K-3 → S-3 ;
K-4 → S-4 ; K-5 → S-5 ; K-6 → S-6, S-7, S-8.

> S-1..S-5 prove the five enrichment dimensions (palette · roundings · variants · actions · scenes).
> S-6 is the **load-bearing gate-liveness** story (the globals must actually drive the tokens — a no-op
> fails). S-7..S-8 are the rung-wide gates (surface frozen · gate green).

## S-1 · The Palette toolbar global re-skins the whole library from one control (K-1)
*As a **design-system browser**, I want a `Palette` toolbar picker that re-points the brand family to any
of the six real ramps, so that I can see the entire library under a different brand without editing a
story.*
**Given** `apps/storybook/.storybook/preview.tsx` with a `palette` `globalType` (a picker over
`iris · indigo · green · orange · plum · red`, default iris) and the extended decorator, **when** the
viewer selects a non-default palette, **then** the decorator overrides the `--bg-brand` family on the story
wrapper to the chosen ramp **using only steps that ramp defines** (§6.1 table — `-9`/`-3`/`-11`, with the
iris/indigo-only `-10`/`-4` falling back), every brand-colored surface in every story re-skins, **and** the
decorator cites **no** `--<status-ramp>-10`/`-4` (the partial-ramp guard). *(Proves INV-3 + INV-6 + INV-8.)*

## S-2 · The Roundings toolbar global re-scales the radius, keeping circles round (K-2)
*As a **design-system browser**, I want a `Roundings` toolbar picker (Sharp / Default / Round), so that I
can see the library at different corner radii without editing a story.*
**Given** the `radius` `globalType` + the extended decorator, **when** the viewer selects `Sharp` (or
`Round`), **then** the decorator overrides `--radius-2 … --radius-32` on the wrapper per the §6.2 preset
(Sharp ⇒ ~0, Round ⇒ enlarged), every box-radius surface re-skins, **and** `--radius-full` is **left
untouched** so avatars/switches/chips stay circular — the decorator targets no `--radius-full` override and
makes **no** `@mercury/ui` edit. *(Proves INV-2 + INV-3 + INV-6.)*

## S-3 · Every component story exposes its full variant surface as a typed control (K-3)
*As a **component reviewer**, I want each component's full `variant`/`size`/`tone` enum exposed as a live
Controls-panel control, so that I can switch every variant without writing code.*
**Given** the post-mx.7.4 co-located `<Name>.stories.tsx` set, **when** the audit runs, **then** every
component's story declares `argTypes` covering its complete exported enum surface, each option array typed
by the component's **exported union** (`const VARIANTS: ButtonVariant[] = [...]`, the mx.4 exemplar), a
`ReactNode` slot stays `control: false` driven by a real `<Icon/>` arg, **and** an invented option is a
`sb:typecheck` compile error. The mx.4 grid stories are kept. *(Proves INV-3 + INV-8.)*

## S-4 · Interactive stories log their handlers to the Actions panel (K-4)
*As a **component reviewer**, I want a click/change to appear in the Actions panel, so that I can confirm
the handler fires.*
**Given** an interactive component story with its handler set as a spy on `args`
(`args: { onClick: fn(), … }`, the `fn` grounded to the installed Storybook test util — §A Fork 5),
**when** the control/canvas invokes the handler, **then** an entry appears in the Storybook **Actions**
panel, **and** the handler arg is a spy (not a `ReactNode` slot). If the Actions panel needs a host addon
registered, that minimal `main.ts`/`package.json` edit is flagged in the report, never silent.
*(Proves INV-7 + INV-2.)*

## S-5 · A Scenes group composes real components into the real app screens (K-5)
*As a **design-system browser / mx.9 author**, I want host-home scene stories that assemble many components
into real screens, so that I can see the system used, not just its parts.*
**Given** `apps/storybook/stories/scenes/` with **≥4** CSF3 scene stories (`title: "Scenes/<Name>"`, no
`component:` field), **when** the Storybook builds, **then** each scene composes **only** real `@mercury/ui`
exports into a real screen grounded in a **cited** source (`apps/mobile/src/screens/*` and/or
`ui_kits/mercury_app/screens.jsx` — §6.5 roster), each scene re-skins live under the Palette/Roundings/Theme
globals, **and** no scene imports `@mercury/effector`, an app, or `window.MercuryUI`/`_ds_bundle`. The
roster is reconciled at ship against the post-mx.7.4 library. *(Proves INV-3 + INV-4 + INV-8.)*

## S-6 · The globals DRIVE the tokens — a no-op decorator is a LOUD failure (K-6, gate-liveness)
*As a **Director**, I want a positive proof that the palette/roundings globals actually change the rendered
tokens, so that a decorator which compiles but does nothing cannot pass.*
**Given** the built Storybook, **when** a computed-style probe (a play function / `getComputedStyle` check,
harness chosen at ship) runs, **then** with `Palette = green` a `--bg-brand` surface (e.g. `Button
variant="primary"`) computes **`rgb(48, 164, 108)`** (green-9), **not** `rgb(91, 91, 214)` (iris-9); with
`Roundings = Sharp` a `--radius-8` surface (e.g. a `Card`) computes **`border-radius: 0px`**, **not**
`8px`, **while** an `Avatar` (`--radius-full`) stays **`9999px`**; **and** a decorator that registers the
picker but never overrides the variable **fails** this check (the probe still reads iris-9 / 8px). The
present-global precondition MUST exercise the override with a positive assertion — an absent/no-op override
is a loud failure, never a silent pass. *(Proves INV-6.)*

## S-7 · The @mercury/ui surface is frozen — only stories + host config change (K-6)
*As a **downstream consumer**, I want mx.8 to add no public surface, so that nothing I import changes.*
**Given** the `@mercury/ui` barrel + components before and after mx.8, **when**
`diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` and
`git diff --name-only` run, **then** the barrel diff is **empty** (byte-identical), and the only
`packages/mercury-ui/src/**` changes are `*.stories.tsx` (the variant/action enrichment) — **no** component
`.tsx`/`index.ts`/`.prompt.md`/`styles/**` edit; the other changed paths are `apps/storybook/.storybook/**`,
`apps/storybook/stories/scenes/**`, and (Fork 5) possibly `apps/storybook/package.json` + `pnpm-lock.yaml`.
Any unavoidable non-story `mercury-ui` change is explicitly flagged. *(Proves INV-1 + INV-2.)*

## S-8 · The gate is green — typecheck, build, packages, apps (K-6)
*As a **Director**, I want the rung to pass the full per-rung gate, so that it ships without regression.*
**Given** the enriched stories + the host globals + the scenes, **when** the gate runs from `mercury/` —
`pnpm sb:typecheck` · `pnpm --filter "./packages/*" typecheck` · `pnpm --filter "./packages/*" build` ·
`pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` · `pnpm sb:build` — **then** every command
exits 0; `sb:build` registers the prior homes **unchanged** + the new `Scenes/*` homes (the home delta is
exactly the scenes — enriched component stories add no home); the NO-INVENT/token/design-sync greps (§INV-8)
are **empty**. *(Proves INV-3 + INV-4 + INV-5 + INV-8.)*
