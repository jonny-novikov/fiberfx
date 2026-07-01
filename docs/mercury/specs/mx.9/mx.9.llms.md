# MX.9 · build context (the agent brief)

> **EPIC-LEVEL after the 2026-07-02 split** ([`mx.9.md`](./mx.9.md) is now the SUB-EPIC frame): **no agent
> builds from this file alone** — the build-grade briefs live with the sub-rungs
> ([`../mx.9.1/mx.9.1.llms.md`](../mx.9.1/mx.9.1.llms.md) · [`../mx.9.2/mx.9.2.llms.md`](../mx.9.2/mx.9.2.llms.md)
> · [`../mx.9.3/mx.9.3.llms.md`](../mx.9.3/mx.9.3.llms.md) · [`../mx.9.4/mx.9.4.llms.md`](../mx.9.4/mx.9.4.llms.md)
> · [`../mx.9.5/mx.9.5.llms.md`](../mx.9.5/mx.9.5.llms.md)). The S-n routing: S-1, S-2 → mx.9.1 · S-3, S-4 → mx.9.2 ·
> S-5 → mx.9.3 · S-6, S-7 → mx.9.4 · S-8 → mx.9.2 (mechanism) + mx.9.5 (acceptance) · S-9, S-10 → mx.9.1
> (join/wiring) + mx.9.5 (closure re-run). Where a sentence below disagrees with the reconciled body (the
> `dev:showcase` ADD · the 11 `storybook/test` value-imports + the shim · the lockfile importer posture · the
> automatic stylesheet · the 65 count), **the body wins**.

Build context for [`mx.9.md`](./mx.9.md) (authoritative body) + [`mx.9.stories.md`](./mx.9.stories.md)
(acceptance). The body wins on any disagreement; this brief lags it. **SOLID-FORWARD** — re-sharpened at the
rung's ship against the as-built `@mercury/ui` (mx.7.4 import + mx.8 stories). **NO-INVENT**: every public call
names a real surface; re-probe each grounding path before trusting it.

> **Framing (propagate — do not drop):** no gendered pronouns for agents; no perceptual or interior-state verbs
> ("sees" / "wants" / "feels"); no first-person narration. State each surface as a contract (precondition /
> postcondition / invariant) so acceptance is at the boundary.

## References — read first, in this order

1. **The body + acceptance** — [`mx.9.md`](./mx.9.md) (§0 the slice, §3 invariants, §7 the forks) +
   [`mx.9.stories.md`](./mx.9.stories.md).
2. **The ladder context** — [`../mx.7/mx.7.md`](../mx.7/mx.7.md) (the import epic; the mx.7→8→9 ladder; the
   consume-down + design-flows-DOWN laws) and [`../mx.8/mx.8.md`](../mx.8/mx.8.md) (the enriched stories the
   showcase renders — author-of-record for the story shapes).
3. **The source-resolved-app precedent** — [`../mx.3/mx.3.md`](../mx.3/mx.3.md) (a NEW app resolving `@mercury/*`
   from source) and the **real configs to byte-mirror**:
   [`apps/echomq/vite.config.ts`](../../../../mercury/apps/echomq/vite.config.ts) ·
   [`apps/echomq/package.json`](../../../../mercury/apps/echomq/package.json) ·
   [`apps/storybook/tsconfig.json`](../../../../mercury/apps/storybook/tsconfig.json) (the `paths` + `extends`
   shape) · [`apps/mobile/vite.config.ts`](../../../../mercury/apps/mobile/vite.config.ts).
4. **The doc source of truth** — [`../../contracts.md`](../../contracts.md) (`D-7`, the six contract sections)
   + an exemplar `packages/mercury-ui/src/components/actions/Button/Button.prompt.md`; and a live
   `*.stories.tsx` (e.g. `.../actions/Button/Button.stories.tsx`) for the **CSF3 object shape** the interpreter
   reads (`import type { Meta, StoryObj }` is type-only — erased at build).
5. **The engine to reimplement (read, do not port verbatim)** — the bundle showcase
   [`packages/mercury-ds/project/showcase/library.jsx`](../../../../mercury/packages/mercury-ds/project/showcase/library.jsx)
   (the `StoryBlock` story interpreter · `renderMarkdown` compact markdown renderer · `CAT_ORDER`/`CAT_LABEL`
   grouping · the sidebar/topbar/Docs-Stories-tabs shell) and `app.css` (the chrome). The bundle
   `loader.js` is the **rejected** engine (§7-C Arm A) — read it to understand why vite supersedes it; do not
   ship it.
6. **Chrome seeds (optional skin)** — `apps/website/{index.html,docs.html,styles.css}` (a docs-shell aesthetic)
   and `apps/marketing-site/` (a landing). Untracked, read-only, **out of the commit pathspec**.
7. **The barrel + the theme mechanism** — `packages/mercury-ui/src/index.ts` (the master invariant surface) and
   `packages/mercury-ui/src/styles/tokens.css` (the `.dark-theme` block).

**Workspace state to re-confirm before building** (`ls mercury/apps/` + a `package.json` check): the **real**
apps are `echomq` · `mobile` · `storybook`; `showcase` · `catalogue` · `docs` are **already retired** (gone);
`website` + `marketing-site` are **untracked prototypes** (no `package.json`). mx.9 **re-founds** the retired
documentation surface as one app; it deletes **no** live app.

## Requirements (each traced: story ⇠ requirement ⇢ invariant/check)

| # | Requirement | Story | Invariant / check |
|---|---|---|---|
| R-1 | A new `apps/showcase/` app (`@mercury/showcase`) builds to `dist/` and joins the apps gate | S-1, S-9 | INV-3 |
| R-2 | It resolves `@mercury/ui|effector|core` from source via a byte-mirror alias + tsconfig `paths` | S-2 | INV-2 |
| R-3 | The component nav is **derived** (glob over the real `@mercury/ui` tree), never a hardcoded list | S-3, S-4 | INV-6 |
| R-4 | Each component's live `*.stories.tsx` render via a small CSF interpreter — **no** Storybook runtime | S-5 | INV-5, K-3 |
| R-5 | The `.prompt.md` contract is **rendered** (`?raw` → markdown); the app authors **no** parallel doc prose | S-6 | INV-5 |
| R-6 | The API / do-don't / recipes surfaces are **cuts** of that one rendered contract | S-7 | INV-5 |
| R-7 | A light/`dark-theme` toggle inverts a component; `@mercury/ui`'s stylesheet is loaded | S-8 | INV-8 |
| R-8 | The barrel is **byte-identical**; the app **houses no reusable component** (package/app split) | S-9 | INV-1, INV-4 |
| R-9 | Consume-down: no `/design-sync`, no in-browser raw-`.tsx` transpiler, no runtime global; `dev:showcase` reconciled | S-10 | INV-7, INV-9 |

## Execution topology

**Runtime shape.** A single-page vite/React app. Boot (`src/main.tsx`) → `createRoot` → `<App/>`. `<App/>`
holds route + theme (the bundle `library.jsx` shape: `localStorage`-persisted route + theme). A **derived
registry** (a module that runs `import.meta.glob` over the `@mercury/ui` component tree) produces the grouped
nav. The shell = a grouped **sidebar** (from the registry) + a **topbar** (theme toggle) + a **component page**
with **Stories** / **Docs** tabs. The **Stories** tab feeds the selected component's `*.stories.tsx` module
through the **CSF interpreter** (`StoryBlock` pattern). The **Docs** tab feeds its `*.prompt.md` (`?raw`)
through the **markdown renderer**, with API / do-don't / recipes as cuts of the parsed sections. `@mercury/ui`'s
stylesheet is loaded once so tokens resolve; the theme toggle sets `light-theme`/`dark-theme` on
`documentElement`.

**Source resolution.** vite alias (`vite.config.ts`) + tsconfig `paths` — byte-identical to
`apps/echomq`/`apps/storybook`. The alias is what makes the in-browser `loader.js` unnecessary: vite resolves +
transpiles `@mercury/ui` source directly (typed, HMR). The glob + `?raw` are vite features — no new dependency.

**Build-order task DAG** (mirror [`mx.9.md`](./mx.9.md) §5):
`scaffold (R-1,R-2)` → `derived registry (R-3)` → `shell` → `CSF interpreter (R-4)` ∥ `markdown renderer +
cuts (R-5,R-6)` → `theme flip + stylesheet + chrome (R-7)` → `gate + dev:showcase reconcile (R-8,R-9)`.

**EXACT files touched** (the whole pathspec):
- **New** — `mercury/apps/showcase/`: `package.json` · `vite.config.ts` · `tsconfig.json` · `index.html` ·
  `src/main.tsx` · `src/App.tsx` · `src/registry.ts` (the glob-derived nav) · `src/lib/storyRender.tsx` (the
  CSF interpreter) · `src/lib/markdown.tsx` (the compact renderer) · `src/components/{Sidebar,Topbar,
  ComponentPage,Docs}.tsx` · `src/showcase.css` (the chrome). *(Exact file split is Mars's call within this
  shape — the contract is the surfaces, not the filenames.)*
- **Edited** — `mercury/package.json` (reconcile the `dev:showcase` script to the reborn app). The new app
  **auto-joins** `build:apps` (it is not `@mercury/storybook`) — **no** script edit for the gate.
- **Maybe** — `mercury/pnpm-lock.yaml` **only if** a dependency actually moved (the recommended engine reuses
  `apps/echomq`'s set → ideally untouched).
- **Out of pathspec / untouched** — `packages/**` (no edit; the barrel must stay byte-identical); any other
  `apps/*`; the design seeds (`packages/mercury-ds/`, `apps/website/`, `apps/marketing-site/` — read-only,
  untracked); `dev:catalogue` / `dev:docs` (stale, but those apps stay retired — a Director fold, not mx.9).

## Agent stories — Directive + Acceptance gate

Each surface is a contract: a **Directive** (what Mars builds) closed by an **Acceptance gate** (the check).

- **AS-1 · Scaffold the source-resolved app.** *Directive:* create `apps/showcase/` mirroring
  `apps/echomq` — `package.json` (`@mercury/showcase`, `private`, `type:module`, scripts
  `dev`/`build`/`preview`/`typecheck`, the echomq dep/devDep set, `@mercury/*` `workspace:*`); `vite.config.ts`
  byte-mirroring the apps' alias block; `tsconfig.json` extending `../../tsconfig.base.json` with the same
  `paths`; `index.html` + `src/main.tsx` + `src/App.tsx`. *Acceptance:* `pnpm --filter @mercury/showcase build`
  exits 0 → `apps/showcase/dist/`; the alias + `paths` map the three packages to `../../packages/<pkg>/src/
  index.ts`; renders with no package `dist/` present. *(INV-2, INV-3.)*
- **AS-2 · Derive the registry.** *Directive:* build the grouped component list from
  `import.meta.glob("../../packages/mercury-ui/src/components/**/*.stories.tsx")` + the sibling `*.prompt.md`
  (`?raw`), grouped by the `<group>/` path segment (the bundle `CAT_ORDER`/`CAT_LABEL`). No hardcoded
  component-name array. *Acceptance:* the nav lists every `@mercury/ui` story file, grouped; adding a throwaway
  component folder makes a nav entry appear with no `apps/showcase/src/**` edit (revert after). *(INV-6.)*
- **AS-3 · Render the live stories (no Storybook runtime).** *Directive:* reimplement the bundle `StoryBlock` —
  read `mod.default` (CSF meta), iterate named exports, mount `story.render()` as its own component or
  `createElement(meta.component, story.args)`, wrap each in an error boundary. *Acceptance:* a component page's
  **Stories** tab shows the component's stories from live source; grep of `apps/showcase/src/**` finds no value
  import from `@storybook/*`. *(INV-5, K-3.)*
- **AS-4 · Render the contract; cut the four views.** *Directive:* import each `<Name>.prompt.md` `?raw`, render
  it with the ported compact markdown renderer; the **Docs** view is the full contract, **API** = `## Props`,
  **do/don't** = `## The enum language` + `## Notes`, **recipes** = `## Examples`. *Acceptance:* the Docs tab
  matches the contract file content; the four views trace to the contract sections; `apps/showcase/src/**` has
  no hand-authored component-API table (grep). A missing section renders empty, never invented. *(INV-5.)*
- **AS-5 · Theme flip + stylesheet + chrome.** *Directive:* a toggle setting `light-theme`/`dark-theme` on
  `documentElement`; load `@mercury/ui`'s stylesheet; skin the chrome from the bundle `app.css` / the
  `apps/website` docs aesthetic. *Acceptance:* a shown component inverts between themes; `rgb(var(--token))`
  swatches resolve in both. *(INV-8.)*
- **AS-6 · Gate + wiring + consume-down.** *Directive:* run the package gate (unchanged) + the apps build
  including showcase + the barrel-diff; reconcile the root `dev:showcase` script; verify the consume-down greps.
  *Acceptance:* `pnpm --filter "./packages/*" typecheck|build` + `pnpm --filter "./apps/*" --filter
  "!@mercury/storybook" build` (3 apps) exit 0; the barrel-diff is empty (byte-identical); grep of
  `apps/showcase/**` is empty for `design-sync|DesignSync|@babel/standalone|window.MercuryUI|_ds_bundle`.
  *(INV-1, INV-3, INV-4, INV-7, INV-9.)*

**The gate ladder (run from `mercury/`):**
```bash
pnpm --filter "./packages/*" typecheck            # packages clean (unchanged by mx.9)
pnpm --filter "./packages/*" build                # packages build (unchanged)
pnpm --filter @mercury/showcase typecheck         # the new app typechecks against source
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build   # echomq + mobile + showcase
# barrel-diff: diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts → empty
# consume-down greps over apps/showcase/**: design-sync · DesignSync · @babel/standalone · window.MercuryUI · _ds_bundle → empty
```
**Squad-tier at ship:** a real app build → a verifier is mandatory (independent gate re-run + an adversarial
probe that the doc surfaces trace to the contract and that no reusable component leaked into the app).

## The prompt (leaves no decision the spec has not fixed)

Build **one** Mercury application, `apps/showcase/` (`@mercury/showcase`), that **composes** `@mercury/ui` from
source and serves the whole library as a single browsable, documented site — the components, their
documentation, their API, their do/don't, and their recipes. Mirror `apps/echomq` for the scaffold (the same
dep set, the same vite alias + tsconfig `paths`, byte-identical) so the packages resolve from source with no
prebuild. **Derive** the component nav from the real `@mercury/ui` tree (a glob over `*.stories.tsx` +
`*.prompt.md`) — never hardcode a list. Each component page renders its **live stories** through a small CSF
interpreter (the bundle `StoryBlock` pattern — **no** Storybook runtime; the story's `import type` is erased)
and its **`.prompt.md` contract** through a ported compact markdown renderer (**no** new dependency); the API,
do/don't, and recipes surfaces are **cuts of that one rendered contract** — author **no** parallel doc prose
(the contract is the source of truth, `D-7`). Add a light/`dark-theme` toggle and load `@mercury/ui`'s
stylesheet. The app **houses no reusable component** (package/app split — reusable surface stays in
`packages/*`) and **changes no export** (the barrel is byte-identical — the master invariant). Touch only
`apps/showcase/**` + the `dev:showcase` script reconcile; keep the design seeds (`packages/mercury-ds/`,
`apps/website/`, `apps/marketing-site/`) read-only and out of the commit pathspec; never `/design-sync`, never
push design up, never `pnpm -r` (use `--filter`); commit `mercury/…` pathspec only when asked.
