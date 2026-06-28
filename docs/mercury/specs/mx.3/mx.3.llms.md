# MX.3 — build context (for the implementor)

Working notes for building [`mx.3.md`](./mx.3.md) — the Storybook host + the first three foundation
stories. Root = `mercury/`. The body is authoritative; this file derives from it. **NO-INVENT:** every
`@mercury/ui` name cited here is a real barrel export; every path is real.

## Ground facts (re-probe before trusting)

- **Stack:** Vite **^6.0.0**, React **19**, Node **22.18**, pnpm **10.17.1**, TypeScript ^5.6.3.
  `tsconfig.base.json`: `target/lib ES2024`, `moduleResolution: "Bundler"`, `jsx: "react-jsx"`,
  `verbatimModuleSyntax: true`, `isolatedModules`, `strict` + `noUncheckedIndexedAccess`.
- **5 product apps** under `apps/`: `catalogue · docs · echomq · mobile · showcase`, each with
  `src/{App.tsx, main.tsx}` + `index.html` → `/src/main.tsx`. The host joins as a **6th** app
  (`apps/storybook/`), auto-matched by the `apps/*` glob in `pnpm-workspace.yaml`.
- **Source-resolution pattern (mirror this):** `apps/showcase/vite.config.ts` aliases the three
  packages to source; `apps/showcase/tsconfig.json` mirrors them in `paths`. Copy both verbatim into
  the host (only the title/entry differ).
- **The barrel** `packages/mercury-ui/src/index.ts` exports `Button` (`./components/actions/Button`)
  and `Icon` (`./components/foundations/Icon`) and **imports `./styles/index.css`** as a side effect —
  so importing any `@mercury/ui` component pulls the stylesheet. The host preview must ensure the CSS
  loads (import `@mercury/ui` for its side-effect CSS, or import the stylesheet directly).
- **The contracts (the gating dependency — mx.2):** each story's controls are a *rendered restatement*
  of the component's `<Name>.prompt.md`:
  - `packages/mercury-ui/src/components/foundations/Icon/Icon.prompt.md`
  - `packages/mercury-ui/src/components/actions/Button/Button.prompt.md`
  Read these; do not invent controls. (The prop sources are `Icon.tsx` / `Button.tsx` beside them.)
- **Theme mechanism:** `@mercury/effector`'s `theme.ts` applies `light-theme`/`dark-theme` to
  `document.documentElement`; the token override block is `packages/mercury-ui/src/styles/tokens.css`
  `.dark-theme { … }` (default light is `:root`). Custom properties cascade, so a `dark-theme` class on
  **any ancestor** (a story wrapper div) flips the descendants — that is the canon §0 "ancestor carries
  `dark-theme`" mechanism. **Do not** depend on `@mercury/effector`'s `initTheme()` for the decorator;
  set the class yourself in the decorator (a wrapper div is cleanest — scoped, no cross-story leakage).
- **`ds-bundle/` is currently ABSENT on disk** (gitignored + regenerable by `/design-sync`). The
  `.gitignore` already has a **bare `ds-bundle/`** rule that matches at any depth. "Relocate" here
  means: establish `apps/storybook/ds-bundle/` as the new `/design-sync` `localDir` and add the
  `.gitignore` policy; if a `mercury/ds-bundle/` exists at build time, move it (the move is
  git-invisible — it is ignored). The full `/design-sync` pipeline re-align is **mx.6**.

## The file tree to create under `apps/storybook/`

```
mercury/apps/storybook/
  package.json            # name @mercury/storybook, private, type:module; @mercury/* workspace:*; storybook devDeps
  vite.config.ts          # mirror apps/showcase/vite.config.ts EXACTLY (the @mercury/* alias block)
  tsconfig.json           # extends ../../tsconfig.base.json; paths to the 3 packages; include .storybook + stories + the package stories
  .storybook/
    main.ts               # @storybook/react-vite framework, CSF3, the forward-compatible stories glob
    preview.tsx           # global theme decorator + globalTypes toolbar; load the @mercury/ui stylesheet
  stories/
    Tokens.stories.tsx    # host-local "Foundations/Tokens" — token swatches + type ramp (no single component)
  ds-bundle/              # the relocated /design-sync localDir (gitignored)
```

Co-located library stories (NOT under the host):

```
mercury/packages/mercury-ui/src/components/foundations/Icon/Icon.stories.tsx
mercury/packages/mercury-ui/src/components/actions/Button/Button.stories.tsx
```

## Storybook version guidance

- Install **`storybook` + `@storybook/react-vite` ≥ 8.4** (the floor with Vite 6 + React 19 support).
  **Confirm the latest stable at build:** `pnpm view @storybook/react-vite version` and pick the latest
  stable that supports Vite 6 + React 19 (the current 8.x or 9.x line; Storybook 9 consolidated many
  packages into the `storybook` core — follow its install/migration notes). Use CSF3.
- Adding Storybook devDeps **will change `pnpm-lock.yaml`** — that is a legitimate part of this rung's
  commit (a real dep moved; CLAUDE.md excludes `pnpm-lock.yaml` from a commit *unless* a real dep
  moved — here one did).
- `apps/storybook/package.json` scripts: `"dev": "storybook dev -p 6006"`, `"build": "storybook build"`.
  Dev-only deps live here, not in any `packages/*`.

## The vite alias to mirror (from `apps/showcase/vite.config.ts`)

```ts
// apps/storybook/vite.config.ts — same alias block as the apps; storybook-react-vite auto-merges it.
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@mercury/ui": resolve(__dirname, "../../packages/mercury-ui/src/index.ts"),
      "@mercury/effector": resolve(__dirname, "../../packages/mercury-effector/src/index.ts"),
      "@mercury/core": resolve(__dirname, "../../packages/mercury-core/src/index.ts"),
    },
  },
});
```

If the installed Storybook version does not auto-merge `vite.config.ts`, add the **same** alias in a
`viteFinal(config)` hook in `.storybook/main.ts` (merge into `config.resolve.alias`). The alias
**values are fixed**; only the mechanism is implementor's latitude.

## `.storybook/main.ts` — the forward-compatible stories glob

```ts
import type { StorybookConfig } from "@storybook/react-vite";

const config: StorybookConfig = {
  framework: "@storybook/react-vite",
  stories: [
    "../stories/**/*.stories.@(tsx|ts)",                       // host-local (Tokens) — this rung
    "../../../packages/mercury-ui/src/**/*.stories.@(tsx|ts)", // the library — this rung fills Icon/Button
    "../../*/src/**/*.stories.@(tsx|ts)",                      // the apps — EMPTY until mx.4 (forward)
  ],
  // addons: keep minimal for mx.3 (controls/actions ship in core for SB ≥ 8).
};
export default config;
```

The third glob is **forward-compatible** (INV-6) — it spans the `apps/*/src/**` tree so mx.4's
apps-side stories drop in with no host edit. It resolves from `.storybook/` (so `../../*/src/**` =
`apps/*/src/**`); it does not match `apps/storybook/ds-bundle/` or `node_modules`.

## `.storybook/preview.tsx` — the theme decorator + stylesheet

- **Load the stylesheet** so tokens resolve in every story (incl. the Tokens story):
  `import "@mercury/ui";` (side-effect CSS via the barrel) or the stylesheet directly.
- A **`globalTypes` toolbar** entry `theme` with items `light` / `dark` (default `light`).
- A **global decorator** that wraps each story in an element carrying `light-theme` or `dark-theme`
  per the global (a wrapper `<div className={theme + "-theme"}>` is cleanest — scoped, no leakage),
  and sets the canvas background to match (`rgb(var(--bg-primary))`). Toggling the toolbar must
  re-render the story dark (INV-5).

## The MANDATORY library-gate fix (do not skip — it is INV-8)

Co-locating `*.stories.tsx` under `packages/mercury-ui/src/` means the library's own `tsc` would try
to typecheck them — and the library carries **no** Storybook types, so `pnpm --filter @mercury/ui
typecheck` and `build` (`vite build && tsc -p tsconfig.build.json`) would **fail**. Fix it by
excluding stories from the library `tsc`:

```jsonc
// packages/mercury-ui/tsconfig.json — add (tsconfig.build.json extends this, so it inherits the exclude)
{
  "include": ["src"],
  "exclude": ["**/*.stories.tsx", "**/*.stories.ts"]
}
```

The vite **lib** build (`vite build`, entry `src/index.ts`) never imports stories, so it is already
unaffected — this `exclude` only stops `tsc` from typechecking/emitting declarations for the stories.
The host's `tsconfig.json` covers the package stories for typechecking instead (add
`"../../packages/mercury-ui/src/**/*.stories.tsx"` to its `include`).

## The gate (from `mercury/`)

**Per-rung ladder (the standard gate — storybook EXCLUDED so it stays fast):**

```bash
pnpm --filter "./packages/*" typecheck                              # 3 packages clean
pnpm --filter "./packages/*" build                                  # 3 packages build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build       # the FIVE product apps only
# barrel-diff — 0 removed/renamed (docs/stories add no export):
diff <(git show HEAD:packages/mercury-ui/src/index.ts | grep -oE 'export .*') \
     <(grep -oE 'export .*' packages/mercury-ui/src/index.ts)
```

**Storybook smoke (the Director runs at SHIP — NOT part of the per-rung apps gate):**

```bash
pnpm sb:build       # ≡ pnpm --filter @mercury/storybook build  → apps/storybook/storybook-static/
```

Root `package.json` script additions:

```jsonc
{
  "scripts": {
    "sb:build": "pnpm --filter @mercury/storybook build",
    "sb:dev": "pnpm --filter @mercury/storybook dev",
    // update the existing convenience script so "build all apps" stays the FIVE product apps:
    "build:apps": "pnpm --filter \"./apps/*\" --filter \"!@mercury/storybook\" --if-present build"
  }
}
```

> **pnpm filter note:** combining `--filter "./apps/*"` (path glob) with `--filter "!@mercury/storybook"`
> (name negation) selects all `apps/*` packages **minus** the storybook app. `./apps/*` matches only the
> workspace-root apps (the five + storybook), **not** the `codemojex-node/apps/*` sub-workspace. As a
> fallback, enumerate the five by name. Never use a blind `pnpm -r`.

## `.gitignore` additions (to `mercury/.gitignore`)

```gitignore
# Storybook (mx.3) — build output + the co-located /design-sync bundle
apps/storybook/storybook-static/
apps/storybook/ds-bundle/
```

The existing bare `ds-bundle/` rule already matches `apps/storybook/ds-bundle/` at any depth; the
explicit entry documents intent. `.vite` and `node_modules` (Storybook's vite/cache lives under
`node_modules/.cache`) are already ignored.

## The `ds-bundle` relocation step

`apps/storybook/` becomes the single `/design-sync` `localDir`. `/design-sync` (the DesignSync tool)
defaults `localDir` to cwd and **rejects any uploaded `localPath` outside `localDir`** — co-locating
the bundle under the host is what makes "run `/design-sync` from `apps/storybook/`" work with one
`writes:["**"]` plan. The bundle's shape is unchanged (`shape:"package"`, `_ds_bundle.*`,
`components/`, `tokens/`, `guidelines/`). If `mercury/ds-bundle/` exists at build time, move it to
`apps/storybook/ds-bundle/` (git-invisible — it is ignored); if absent, just establish the path + the
`.gitignore` policy. **The full `/design-sync` pipeline re-align (config `localDir`, regenerate from
the grouped structure) is `mx.6`** — mx.3 only relocates the bundle and points the host at it.

## Story shapes (controls grounded in the contract — NO-INVENT)

- **`Button.stories.tsx`** (CSF3): `meta` `title: "Actions/Button"`, `component: Button`. `argTypes`:
  `variant` → `{ control: "select", options: ["primary","secondary","outline","ghost","destructive","inverse"] }`,
  `size` → `{ control: "inline-radio", options: ["sm","md","lg"] }`, `loading`/`fullWidth`/`disabled`
  → `{ control: "boolean" }`. A `Playground` story (args-driven), plus a `Variants` grid story
  iterating the six variants × three sizes, and one `WithIcon` story rendering
  `leading={<Icon name="download" size={14} />}` (real, per `Button.prompt.md`). Do not expose
  `leading`/`trailing` as raw controls — drive them with a story arg.
- **`Icon.stories.tsx`** (CSF3): `title: "Foundations/Icon"`, `component: Icon`. `argTypes`:
  `name` → `{ control: "select", options: [/* the IconName set from Icon.prompt.md */] }`,
  `size` → `{ control: "number" }`, `strokeWidth` → `{ control: "number" }`. A `Playground` story +
  a `Gallery` grid story rendering every `IconName` with its label.
- **`Tokens.stories.tsx`** (host-local, CSF3): `title: "Foundations/Tokens"`. No `component`; a
  `render`-based story showing the canon §6 swatches — surfaces (`--bg-*`), text (`--fg-*`), borders
  (`--border-*`), the six status families, and the type ramp (`--font-primary|secondary|display`) —
  each drawn with `rgb(var(--token))` so the theme decorator visibly flips them dark.

## Gotchas

- **Stories add no export** — the barrel is byte-stable (INV-1). A story imports the existing surface;
  it never touches `src/index.ts`.
- **The library tsc exclude is mandatory** (INV-8) — without it the packages gate fails on the
  co-located stories' Storybook imports.
- **Verify props against the live `.tsx`** (truth) **and** the `.prompt.md` (the control language) —
  not a stale memory. Icon has no `variant`; Button's `loading` hides `leading`/`trailing`.
- **The host stays out of the per-rung apps gate** (INV-3 exclusion) — the `sb:build` smoke is the
  ship-time proof, run separately by the Director.
- **Commit only when asked, pathspec only.** The host + the two stories + the `.gitignore`/root
  `package.json`/`tsconfig` edits + `pnpm-lock.yaml` are one concern; re-verify
  `git diff --cached --name-only` is purely the mx.3 surface (everything under `mercury/`) before any
  commit. Never `git add -A`; never `pnpm -r`.
- **Framing (propagate):** no gendered pronouns for agents; no perceptual/interior-state verbs; no
  first-person narration. State each surface as a contract.
