# MX.9 · SUB-EPIC — the Mercury showcase (split into mx.9.1 … mx.9.5)

> **Status: SUB-EPIC — Operator-ruled SPLIT 2026-07-02 into mx.9.1–mx.9.5** (specced 2026-06-29 at
> SOLID-FORWARD; decomposed before build — nothing at this epic level is buildable on its own). The **closer
> of the Movement-III tail** (`mx.7` import · `mx.8` stories · **`mx.9` showcase application**, per the
> [`../mx.7/mx.7.md`](../mx.7/mx.7.md) epic): **one real Mercury application** — `apps/showcase/` — composing
> `@mercury/ui` from source and serving the whole library as a single browsable, documented surface (**the
> components, their documentation, their API, their do/don't, and their recipes**). It RE-FOUNDS the
> documentation surface the retired `apps/{showcase,catalogue,docs}` once carried; it deletes no live app.
> The split axis is the **layered engine** — the spine lands first, each surface deepens it in its own
> in-band ship:
>
> | Sub-rung | Scope | Epic K / INV focus | Stories | Grain | Risk / formation |
> |---|---|---|---|---|---|
> | **[mx.9.1](../mx.9.1/mx.9.1.md)** | The **spine** — the `apps/showcase` scaffold (the source alias + the `storybook/test` shim), a sanity page, the `dev:showcase` ADD, the apps-gate join (2→3) | K-1 + K-6 (wiring) · INV-1/2/3/9 | S-1, S-2, S-9, S-10 | **✅ BUILT 2026-07-02** | NORMAL · Duo+ (as-run) |
> | **[mx.9.2](../mx.9.2/mx.9.2.md)** | The **derived registry + shell** — the two lazy globs, the grouped sidebar + topbar, the persisted route, Stories/Docs tab stubs, the theme-toggle mechanism | K-2 + K-5 (mechanism) · INV-4/6 | S-3, S-4, S-8 (mechanism) | **BUILD-READY** | NORMAL · Trio |
> | **[mx.9.3](../mx.9.3/mx.9.3.md)** | The **live-stories surface** — the CSF interpreter (the bundle `StoryBlock` pattern) + the shim liveness proof | K-3 · INV-5 (render path) | S-5 | SOLID-FORWARD | ELEVATED · Trio + deepened verify |
> | **[mx.9.4](../mx.9.4/mx.9.4.md)** | The **contract surface** — the compact markdown renderer; Docs / API / do-don't / recipes as cuts | K-4 · INV-5 | S-6, S-7 | SOLID-FORWARD | NORMAL · Trio |
> | **[mx.9.5](../mx.9.5/mx.9.5.md)** | The **chrome + theme acceptance + epic closure** — the seed-skinned chrome, dual-theme acceptance, the whole-epic gate re-run | K-5 · INV-8 + the INV-1..9 closure re-run | S-8 (acceptance), S-9, S-10 (re-run) | SOLID-FORWARD | **ELEVATED closer · Squad + Apollo** |
>
> **Grain + risk.** mx.9.1/9.2 are authored BUILD-READY; mx.9.3–9.5 are SOLID-FORWARD, **re-sharpened at each
> own ship**. The risk tiers are Director-triaged; the Operator may override at each ship. The prior
> SQUAD-TIER banner is superseded by the per-rung tiers above — the epic's **verifier mandate is honored at
> the mx.9.5 closer** (an independent whole-app gate re-run + the adversarial doc-source-of-truth and
> package/app-split probes). Treat every count and component reference as DERIVED-at-build, never hardcoded
> (INV-6).
>
> **Fork routing (each ruling dated 2026-07-02, inherited by every sub-rung — recorded under §7):** Fork A
> (content scope) is **resolved BY the split itself** — the staged, spine-first decomposition IS the
> MVP-first arm. Forks **B** (`apps/showcase` / `@mercury/showcase`), **C** (Arm B — a conventional
> vite/React app on the source alias — with Arm C's chrome composed; `loader.js`/`@babel/standalone`
> REJECTED), **D** (the prototypes stay untracked read-only design seeds), and **E** (zero new dependency)
> are **RULED** — no sub-rung re-opens them.
>
> **This body remains the epic-level architecture** (§0–§7) the sub-rungs cite for inherited law. Stale
> claims found by the 2026-07-02 Director reconcile are corrected in place, each marked
> `[RECONCILED 2026-07-02]`; the buildable grain lives in the sub-rung triads (the Map, end of file).

Canon: [`../../mercury.design.md`](../../mercury.design.md) · roadmap:
[`../../mercury.roadmap.md`](../../mercury.roadmap.md) · dashboard:
[`../../mercury.progress.md`](../../mercury.progress.md) · prior triad (the import epic):
[`../mx.7/mx.7.md`](../mx.7/mx.7.md) · the stories rung: [`../mx.8/mx.8.md`](../mx.8/mx.8.md) · format exemplar
(a source-resolved app): [`../mx.3/mx.3.md`](../mx.3/mx.3.md) · contract template (`D-7`):
[`../../contracts.md`](../../contracts.md) · method:
[`../../../aaw/aaw.framework.md`](../../../aaw/aaw.framework.md) · architect approach:
[`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) · acceptance:
[`mx.9.stories.md`](./mx.9.stories.md) · build context: [`mx.9.llms.md`](./mx.9.llms.md).

## 0 · The slice — what mx.9 builds, and why one app over five surfaces

Movement III's destination is a browsable, trustworthy home for the surface mx.1/mx.2 built and mx.7/mx.8
grew. mx.3 landed the **Storybook host** (the per-component author/review tool); mx.9 lands the **product** —
**one comprehensive application** a human or a design/coding agent opens to discover, read, and trust
`@mercury/ui`. The Operator's mandate (quote-faithful):

> mx.9 = a **NEW Component showcase** replacing the retired apps (including docs and catalogue) — **the single
> comprehensive application** to serve the **components, documentation, API, do/don't, recipes**.

The deliverable is **one real Mercury app**, `apps/showcase/` (vite/React), resolving `@mercury/*` **from
source** via the vite alias + tsconfig `paths` exactly as the other workspace apps do
([`apps/echomq/vite.config.ts`](../../../../mercury/apps/echomq/vite.config.ts) ·
[`apps/mobile/vite.config.ts`](../../../../mercury/apps/mobile/vite.config.ts) ·
[`apps/storybook/vite.config.ts`](../../../../mercury/apps/storybook/vite.config.ts) — a byte-identical alias
block). It **composes** `@mercury/ui`; under the package/app-split law (canon §1) an app **never houses or
reimplements a reusable component** — the showcase only *composes + documents* what `packages/*` owns.

**The five surfaces are one source rendered five ways, not five authored bodies.** A component's
`<Name>.prompt.md` contract (`D-7`, [`../../contracts.md`](../../contracts.md)) already carries every surface
the mandate names — `## Props` is the **API**, `## The enum language` + `## Notes` are the **do/don't**,
`## Examples` are the **recipes**, the role line + `## Notes` are the **documentation** — and the
`<Name>.stories.tsx` are the **live components**. So mx.9 does not author a parallel docs body; it **renders the
contract + the stories** (INV-5). That is the whole architecture: a registry derived from the real `@mercury/ui`
tree (INV-6), a component page with a **Stories** tab (a tiny CSF interpreter — the bundle's `StoryBlock`
pattern, no Storybook runtime) and a **Docs** tab (the `.prompt.md` rendered as markdown), under the canon's
light/`dark-theme` flip.

**Why a showcase, not a Storybook re-skin.** The Storybook host (mx.3/mx.8) is the **author/review** tool — one
component, every state, controls. The showcase is the **product** — the whole library as a navigable site with
prose docs, recipes, and do/don't beside each component, themeable, deployable. They share **one story source**
(the co-located `*.stories.tsx`): the Storybook host renders it with Storybook's runtime; the showcase renders
it with its own small interpreter. One source, two renderers — DRY.

## 1 · Goal

A vite/React app exists at `apps/showcase/` (`@mercury/showcase`) and **builds** (`pnpm --filter
@mercury/showcase build` → `dist/`, exit 0), joining the per-rung apps gate. It resolves
`@mercury/ui`/`@mercury/effector`/`@mercury/core` **from source** via a vite alias + tsconfig `paths`
byte-mirroring the workspace apps. Its navigation is **derived** from the real `@mercury/ui` component tree (a
glob over `*.prompt.md` / `*.stories.tsx`), so it covers the whole post-mx.7 surface with **no per-component
edit**. Each component page renders **its live stories** (a small CSF interpreter, no Storybook dependency) and
**its `.prompt.md` contract** as markdown — the **API** (Props), **do/don't** (enum language + Notes), and
**recipes** (Examples) are cuts of that one rendered contract, never re-authored prose. A light/`dark-theme`
toggle renders every component in both themes. The app **houses no reusable component** (package/app split) and
**changes no export** — the `@mercury/ui` barrel is **byte-identical** before and after (the master invariant
holds).

## 2 · Rationale (5W)

- **Why.** Movement III is the program's destination — a single, deployable place where the whole `@mercury/ui`
  surface is browsable with its docs, API, do/don't, and recipes beside it. The retired `apps/{showcase,
  catalogue,docs}` once split that across prototypes; mx.9 re-founds it as **one** app, grounded in the
  contracts (`D-7`) so the documentation can never drift from the source — it *is* the source, rendered.
- **What.** A new `apps/showcase/` app: `package.json` (`@mercury/showcase`, the same dep/devDep set as
  `apps/echomq`, `@mercury/*` as `workspace:*`), `vite.config.ts` (the source-resolution alias, byte-mirror),
  `tsconfig.json` (the `paths` mirror), `index.html`, `src/main.tsx` + `src/App.tsx`, and a small `src/` engine:
  a **derived registry** (glob), a **shell** (grouped sidebar + topbar + a Stories/Docs component page), a
  **CSF interpreter** (renders a story object's `render`/`args` — the bundle `StoryBlock` pattern), a **compact
  markdown renderer** (the `.prompt.md` → the Docs/API/do-don't/recipes views — the bundle `library.jsx`
  renderer, ported, zero new dependency), and a **theme flip** (the `@mercury/ui` stylesheet arrives
  automatically — the barrel side-effect-imports `./styles/index.css` at `packages/mercury-ui/src/index.ts:12`
  `[RECONCILED 2026-07-02]`). Plus the wiring: the app auto-joins `build:apps`; a fresh root `dev:showcase`
  script is **ADDED** — none exists today, the old one was removed with the retired apps
  `[RECONCILED 2026-07-02]`.
- **Who.** *Authored by* the Mercury spec-steward (this triad) + the implementor wave (the app). *Consumed by* —
  (1) Mercury contributors and product teams browsing/learning the library; (2) a design/coding agent
  discovering `@mercury/ui`'s surface, props, and recipes; (3) the Operator, accepting Movement III at the app
  boundary.
- **When.** After **mx.7.4** (the import complete) and **mx.8** (the enriched stories) — both SHIPPED, so the
  hard gates are satisfied: the as-built surface is **65 story-backed components** (the 2026-07-02 verified
  count — DERIVED-at-build, never hardcoded) `[RECONCILED 2026-07-02]`. The epic closes Movement III via the
  mx.9.1→9.5 ladder.
- **Where.** New: `mercury/apps/showcase/**`. Wiring: `mercury/package.json` (**ADD** the `dev:showcase`
  script — none exists; the new app auto-joins `build:apps` with no edit) `[RECONCILED 2026-07-02]`.
  `mercury/pnpm-lock.yaml` **gains the `@mercury/showcase` importer block** — a new workspace package always
  adds its importer entry (cf. the `apps/echomq:` importer) even with an identical dep set; **no new external
  dependency versions** (a new dependency is itself an Operator fork — §7-E, RULED: none)
  `[RECONCILED 2026-07-02]`. The design seeds
  (`packages/mercury-ds/project/showcase/`, `apps/website/`, `apps/marketing-site/`) are **read-only inputs**,
  untracked, **out of the commit pathspec**.

## 3 · Invariants (runnable checks)

- **INV-1 · The master invariant holds — the barrel is byte-identical.** mx.9 adds an app that *composes*
  `@mercury/ui`; it touches **no** component source and adds **no** export. The barrel-diff (canon §2, the
  master invariant) shows **0 removed/renamed**, and ideally byte-identical. Mechanical:
  `diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` is empty. When in
  doubt resolve the full export set (TS `getExportsOfModule`), not a text-diff.
- **INV-2 · The app resolves `@mercury/ui` from source.** `apps/showcase/vite.config.ts` aliases
  `@mercury/ui|effector|core → ../../packages/<pkg>/src/index.ts` (byte-mirroring
  [`apps/echomq/vite.config.ts`](../../../../mercury/apps/echomq/vite.config.ts)), and `tsconfig.json` mirrors
  the same in `paths`. A component edit in `packages/*` is live in the showcase with **no prebuild**; no package
  `dist/` is required to render.
- **INV-3 · The app builds and joins the apps gate.** `pnpm --filter @mercury/showcase build` exits 0 and
  produces `apps/showcase/dist/`; the per-rung apps gate `pnpm --filter "./apps/*" --filter "!@mercury/storybook"
  build` (now `echomq` + `mobile` + **`showcase`**) exits 0. The showcase is a **product app** (it is **not**
  excluded like the Storybook host).
- **INV-4 · Package/app split — the app composes, never houses.** Every reusable surface stays in `packages/*`;
  `apps/showcase/src/**` defines **no** component that belongs in `@mercury/ui` and **re-exports/reimplements
  no** `@mercury/ui` export. The shell pieces it owns (sidebar, topbar, the story/markdown renderers) are
  **app chrome**, not reusable library components. (canon §1; the standing law.)
- **INV-5 · Doc source of truth — render the contract, never re-author it.** Every documentation surface — the
  **Docs** view, the **API** view (Props), the **do/don't** view (enum language + Notes), the **recipes** view
  (Examples) — is **rendered from the live `<Name>.prompt.md`** (`D-7`) and the `<Name>.stories.tsx`. The app
  contains **no** hand-written, per-component API table or prose body that duplicates a contract (such a copy is
  the drift surface the law forbids). Observable: each surface is a cut of the fetched/imported `.prompt.md` +
  story module; grep finds no in-app authored component-API markdown.
- **INV-6 · The registry is DERIVED, not hardcoded.** The component nav is built from a **glob** over the real
  `@mercury/ui` tree (`packages/mercury-ui/src/components/**/*.prompt.md` and `**/*.stories.tsx`, via
  `import.meta.glob`), or an equivalent generated index — **not** a hand-maintained component-name array. So the
  showcase auto-covers the whole post-mx.7 surface (65 story-backed components at the 2026-07-02 verified
  count — DERIVED-at-build, never hardcoded `[RECONCILED 2026-07-02]`) and any later addition with **no
  per-component edit**. Observable: adding a component folder to `@mercury/ui` makes it appear with no showcase
  source change; grep finds no hardcoded component-list literal.
- **INV-7 · Consume down only — no design-sync, no raw-path transpiler, no runtime framing.** The app uses
  **vite source resolution** (the alias); it does **not** ship the bundle's `loader.js` in-browser Babel
  transpiler reaching raw `.tsx` paths (vite supersedes it — §7-C), does **not** invoke `/design-sync` or the
  `DesignSync` MCP or push anything to Claude Web (design flows DOWN — inherited from the mx.7 epic), and
  contains **no** `window.MercuryUI` / `_ds_bundle` runtime-global framing. Grep: empty for `design-sync`,
  `DesignSync`, `window.MercuryUI`, `_ds_bundle`, and `@babel/standalone`.
- **INV-8 · The theme flip works.** A toggle sets the canon's `light-theme`/`dark-theme` class on an ancestor
  (the §0 dark mechanism; the `.dark-theme` token block in
  [`packages/mercury-ui/src/styles/tokens.css`](../../../../mercury/packages/mercury-ui/src/styles/tokens.css)),
  and the `@mercury/ui` stylesheet is **already loaded by the alias** — the barrel side-effect-imports
  `./styles/index.css` (`packages/mercury-ui/src/index.ts:12`), so any app resolving `@mercury/ui` from source
  carries the full stylesheet + tokens with **no explicit css import** `[RECONCILED 2026-07-02]`. Observable:
  rendered token swatches resolve, and a rendered component's surface inverts between the two states.
- **INV-9 · Scope discipline.** The epic touches only: `mercury/apps/showcase/**` (new); `mercury/package.json`
  (the `dev:showcase` ADD); and `mercury/pnpm-lock.yaml` (the `@mercury/showcase` importer block — an
  unavoidable, dependency-neutral delta `[RECONCILED 2026-07-02]`). **No** `packages/*` edit, **no** other app, **no** story added to `@mercury/ui` (the package/app split
  — the showcase consumes the package stories, it authors none). The design seeds stay untracked and out of the
  commit pathspec.

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | The **`apps/showcase/` app scaffold** — `package.json` (`@mercury/showcase`, the `apps/echomq` dep set, `@mercury/*` `workspace:*`) · `vite.config.ts` (source-resolution alias, byte-mirror) · `tsconfig.json` (`paths` mirror) · `index.html` · `src/main.tsx` + `src/App.tsx` | INV-2 + INV-3; the app builds and resolves the packages from source |
| K-2 | The **derived registry + shell** — a glob-built component list grouped by category (the bundle `CAT_ORDER`), a sidebar + topbar, a component page with **Stories** / **Docs** tabs | INV-6; nav comes from the real `@mercury/ui` tree, no hardcoded list; the post-mx.7 surface appears whole |
| K-3 | The **story renderer** — a small CSF3 interpreter (the bundle `StoryBlock` pattern: `render`→mount, `args`→`createElement(component, args)`), rendering each component's live `*.stories.tsx` with **no Storybook runtime dependency**. `[RECONCILED 2026-07-02]` The `import type { Meta, StoryObj }` IS erased at build, but **11 of the 65 story files carry VALUE imports from the bare specifier `storybook/test`** (the mx.8.2 `fn()` spy + play helpers) — resolved by the **app-local no-op shim** behind a vite `resolve.alias` entry (baked in at mx.9.1; liveness proved at mx.9.3). `storybook/test` is not `@storybook/*` scope, so the no-value-import-from-`@storybook/*` grep still holds | INV-5; a component's stories render in the page; no `@storybook/*` runtime import; the shim resolves `storybook/test` to app-local code |
| K-4 | The **contract renderer + the four doc views** — the `.prompt.md` imported live (`?raw`) and rendered as markdown (the bundle `library.jsx` compact renderer, ported, zero new dependency); the **Docs / API / do-don't / recipes** surfaces are **cuts of that one rendered contract** | INV-5; every doc surface traces to the `.prompt.md`; no in-app authored API table |
| K-5 | The **theme flip + chrome** — a light/`dark-theme` toggle (the stylesheet arrives automatically via the barrel's side-effect import — `packages/mercury-ui/src/index.ts:12` `[RECONCILED 2026-07-02]`); the chrome skinned from the design seeds (the bundle `app.css` / the `apps/website` docs aesthetic — §7-C/§7-D) | INV-8; a component inverts between themes; the rendered token swatches resolve |
| K-6 | The **gate + wiring** — the app joins `pnpm --filter "./apps/*" build`; a fresh root `dev:showcase` script **ADDED** (none exists — the old one was removed with the retired apps `[RECONCILED 2026-07-02]`); the barrel byte-identical; the consume-down greps empty | INV-1 + INV-3 + INV-7 + INV-9; the gate is green with three product apps and an untouched barrel |

## 5 · The method (build order)

A small task DAG; the scaffold lands first, the engine fills it, the gate closes it.

1. **Scaffold the app.** Create `apps/showcase/{package.json, vite.config.ts, tsconfig.json, index.html}` +
   `src/{main.tsx, App.tsx}`. `package.json` name `@mercury/showcase`, `private`, `type: module`, scripts
   `dev`/`build`/`preview`/`typecheck` (mirror [`apps/echomq/package.json`](../../../../mercury/apps/echomq/package.json)),
   the **same** dep/devDep set as `apps/echomq` (no new dependency — §7-E). `vite.config.ts` **byte-mirrors** the
   apps' alias block **plus one showcase-specific entry** — `storybook/test` → the app-local no-op shim
   (`src/shims/storybook-test.ts`) `[RECONCILED 2026-07-02]`; `tsconfig.json` extends `../../tsconfig.base.json`
   with the same `paths`. Install (writes the `@mercury/showcase` importer block into `pnpm-lock.yaml` — a new
   workspace package always adds its importer entry; no new external dependency versions
   `[RECONCILED 2026-07-02]`). → **mx.9.1**.
2. **Derive the registry.** Build the component list from a glob over the real `@mercury/ui` tree —
   `import.meta.glob("../../../packages/mercury-ui/src/components/**/*.stories.tsx")` (relative to
   `apps/showcase/src/registry.ts` — three segments up to the workspace root `[RECONCILED 2026-07-02]`) and the
   sibling `*.prompt.md` (`{ query: "?raw", import: "default" }`) — grouped by the `<group>/` segment (the
   bundle `CAT_ORDER`/`CAT_LABEL` pattern ADAPTED to the real 9 group segments — a fixed group-order/label map
   keyed by segments is app chrome, not a component list). **No hardcoded list** (INV-6). → **mx.9.2**. Derive the showcase's own registry from `@mercury/ui`, **not** the bundle's
   `packages/mercury-ds/project/components/registry.ts` (that path-list uses the bundle's grouping, not the live
   library's).
3. **Build the shell.** A grouped sidebar (the derived registry), a topbar (the theme toggle), and a component
   page with **Stories** / **Docs** tabs — the proven shape of the bundle
   [`library.jsx`](../../../../mercury/packages/mercury-ds/project/showcase/library.jsx), reimplemented as a
   typed React app (not ported verbatim — it is JSX-on-`window` for the in-browser loader).
4. **Port the story interpreter.** Reimplement the bundle `StoryBlock` (library.jsx): read `mod.default`
   (the CSF meta — `component`, `parameters.summary`), iterate the named exports, render `story.render()` as its
   own component or `createElement(meta.component, story.args)`, wrap each in an error boundary. The story files'
   `import type { Meta, StoryObj } from "@storybook/react-vite"` is **type-only** (erased at build), and the
   **11 files that VALUE-import `storybook/test`** resolve through the mx.9.1 shim — only `fn()` executes at
   module top level (in `args`); the play helpers are referenced solely inside `play` bodies the showcase never
   runs `[RECONCILED 2026-07-02]` — **no Storybook runtime is pulled** (INV-5/K-3). → **mx.9.3** (this step
   proves the shim's liveness across all 65 story modules).
5. **Port the markdown renderer + cut the four views.** Reimplement the bundle compact markdown renderer
   (library.jsx `renderMarkdown`, zero new dependency) over the `?raw`-imported `.prompt.md`. The **Docs** view
   is the full contract; the **API** view cuts `## Props`; the **do/don't** view cuts `## The enum language` +
   `## Notes`; the **recipes** view cuts `## Examples`. All four are cuts of the one rendered contract (INV-5).
   *(Whether the four views are sub-tabs of one Docs page or top-level — a §7-A grain choice, ruled at ship.)*
6. **Theme flip + chrome.** Wire the light/`dark-theme` toggle (the canon §0 mechanism — the class flip on
   `documentElement`); the stylesheet is **already delivered by the alias** (the barrel side-effect import,
   `packages/mercury-ui/src/index.ts:12`), so the acceptance is that rendered token swatches resolve
   `[RECONCILED 2026-07-02]`; skin the chrome from the design seeds (§7-C/§7-D). → toggle mechanism **mx.9.2**;
   chrome + dual-theme acceptance **mx.9.5**.
7. **Gate + wiring.** Run the package gate (unchanged), the apps build **including** showcase, the barrel-diff
   (byte-identical), and the consume-down greps (INV-7). **ADD** the root `dev:showcase` script —
   `"dev:showcase": "pnpm --filter @mercury/showcase exec vite --port 5176 --strictPort"` (no such script
   exists; `dev:catalogue`/`dev:docs` are equally gone — removed with the retired apps, nothing to reconcile)
   `[RECONCILED 2026-07-02]`. → wiring **mx.9.1**; the whole-epic closure re-run **mx.9.5**.

Grounding sources (re-probe before trusting, per [`mx.9.llms.md`](./mx.9.llms.md)): the apps' vite alias +
tsconfig `paths`; the barrel `packages/mercury-ui/src/index.ts`; the contract format
[`../../contracts.md`](../../contracts.md) + an exemplar `Button.prompt.md`; a live `*.stories.tsx` (the CSF3
object shape); the bundle showcase engine (the `StoryBlock` + `renderMarkdown` patterns to reimplement); the
theme mechanism in `packages/mercury-ui/src/styles/tokens.css`.

## 6 · Dependencies

- **Hard-gates on:** **mx.7.4** (the import complete) and **mx.8** (the enriched stories rendered by the
  Stories tab) — **both SHIPPED; satisfied** (the as-built surface: 65 `*.stories.tsx` + 65 `*.prompt.md`
  across the 9 groups, verified 2026-07-02) `[RECONCILED 2026-07-02]`. Soft: **mx.2** (the `<Name>.prompt.md`
  contracts the Docs/API/do-don't/recipes views render) and **mx.3** (the source-resolved-app precedent — the
  apps' alias + `tsconfig paths` this app mirrors). **Within the epic:** mx.9.2 hard-gates on mx.9.1; mx.9.3
  and mx.9.4 on mx.9.2; mx.9.5 closes.
- **Unblocks:** if the Operator rules **MVP-first** (§7-A), the follow-on **dedicated-surface** rungs (a
  standalone API explorer / a do-don't gallery / a recipes cookbook, each a purpose-built re-cut of the same
  contract source). Either way, mx.9 **closes Movement III**.
- **Touches:** `mercury/apps/showcase/**` (new app); `mercury/package.json` (the `dev:showcase` ADD);
  `mercury/pnpm-lock.yaml` (the importer block only — no new external dependency versions
  `[RECONCILED 2026-07-02]`; note the worktree lockfile is routinely dirty from sibling programs — the
  Director partitions at commit). The design seeds
  (`packages/mercury-ds/project/showcase/`, `apps/website/`, `apps/marketing-site/`) are read-only, untracked,
  out of pathspec. Canon §7 / the roadmap / the progress dashboard: the Director folds at ship (the roadmap's
  superseded mx.6/mx.7 rows reconciled to the mx.7→8→9 ladder; a `D-` for each ruled fork).

## 7 · Forks for the Operator (framed, never decided — ruled at the ship's sharpen stage)

Each fork carries steelmanned arms and a one-line **Steward** recommendation. The Operator rules.

### Fork A — content scope: **MVP-first (the browser spine), then dedicated surfaces** · *Steward: A*

- **Arm A — MVP-first.** Ship the **component-library browser spine** first: every `@mercury/ui` component → its
  stories (the **Stories** tab) and its `.prompt.md` rendered (the **Docs** tab, with the **API / do-don't /
  recipes** as cuts of the contract). Because the five surfaces are all views over the one contract+stories
  source (§0), the spine **already serves all five** at rendered-contract fidelity. Follow-on rungs add
  **dedicated, purpose-built** surfaces (a standalone API explorer, a do/don't gallery, a recipes cookbook) that
  re-cut the same source. **It is a big app; ship the provable spine first, elevate the surfaces next.**
- **Arm B — all five dedicated surfaces in one rung.** Build the browser **and** the four purpose-built surfaces
  in mx.9. Steelman: one comprehensive ship matches the mandate's "single comprehensive application" literally,
  no follow-on. Cost: a much larger first rung (Squad-tier, higher build/verify risk), and the dedicated
  surfaces are polish over a source the spine already renders.
- **Steward: A** — the spine serves all five surfaces as contract cuts on day one; dedicated surfaces are
  additive polish, not a precondition for "comprehensive."

> **RULED (2026-07-02): resolved BY the split itself.** The Operator's decomposition directive stages the
> spine first — the mx.9.1→9.5 ladder IS the MVP-first arm realized; dedicated-surface polish remains
> follow-on, after the epic closes.

### Fork B — app location/name: **`apps/showcase` (reborn)** · *Steward: showcase*

- **Arms.** `apps/showcase` (the bundle's own name for this engine and the Operator's word "showcase";
  `[RECONCILED 2026-07-02]` the old root `dev:showcase` script is **gone** — removed with the retired apps —
  so the name costs one fresh script ADD, not a repair) · `apps/docs` (reads as docs-only — too narrow for
  "comprehensive") · `apps/mercury` (reads as the umbrella — collides with the workspace name `@mercury/*`).
- **Steward: `apps/showcase` / `@mercury/showcase`** — it matches the bundle's vocabulary and the Operator's own
  word.

> **RULED (2026-07-02):** `apps/showcase` / `@mercury/showcase` — the Steward arm.

### Fork C — engine/sources: **a conventional vite/React app (alias-resolved), reusing the bundle SHELL** · *Steward: B*

- **Arm A — port the bundle `loader.js` live-`.tsx` engine.** The bundle fetches raw `.tsx` and transpiles it
  in-browser with `@babel/standalone` because it has **no build step**. Steelman: zero-build, serve-anywhere.
  Cost: **redundant** in a real vite app (vite already resolves + transpiles the same source, typed, with HMR);
  it reaches **raw `.tsx` paths**, not the barrel, so it bypasses `@mercury/ui`'s public surface and ships an
  in-browser transpiler inside a real build — a NO-INVENT/maintenance hazard (INV-7).
- **Arm B — a conventional React app importing `@mercury/ui` from source via the alias**, reusing the bundle
  showcase's **shell pattern** (registry-driven sidebar, Stories/Docs tabs, `StoryBlock` story interpreter,
  compact `renderMarkdown`) reimplemented as typed React. The alias does exactly what `loader.js` hand-rolls —
  live source, typed, HMR.
- **Arm C — adopt the `apps/website` static docs design as the chrome.** Not exclusive: a chrome/aesthetic
  choice that **composes with Arm B** (mine the website's `docs-shell` look for the skin).
- **Steward: B** (with C as the optional chrome skin) — the alias supersedes the in-browser loader natively;
  reuse the bundle's proven UX, not its no-build transpiler.

> **RULED (2026-07-02):** Arm B — a conventional vite/React app on the source alias — **with Arm C composed**
> (the chrome skinned from the bundle shell / the `apps/website` docs aesthetic; lands at mx.9.5). The
> `loader.js` / `@babel/standalone` engine (Arm A) is **REJECTED**.

### Fork D — the retired prototypes' fate (`apps/website`, `apps/marketing-site`) · *Steward: design seeds, untracked*

- **Arms.** **(a)** Mine their aesthetic for mx.9's chrome and **leave them untracked** (Operator decides
  deletion later) · **(b)** delete them in mx.9 (they are untracked `.html`/`.jsx`/`.css` with **no
  `package.json`**, design seeds only) · **(c)** promote them to real apps (a marketing landing) — scope creep
  beyond the showcase mandate.
- **Gate impact (call-out).** Neither prototype affects the gate today (no `package.json` → not in the apps
  glob). The **only** gate growth is the **one new product app**: the apps gate goes from `echomq` + `mobile`
  (2) to `echomq` + `mobile` + `showcase` (3). The showcase authors **no** new `*.stories.tsx`, so the Storybook
  globs (`sb:build`/`sb:typecheck`) and the **barrel** are **unchanged** (master invariant holds).
- **Steward: (a)** — treat both as design seeds (like the bundle showcase): read-only, untracked, out of the
  commit pathspec; the Operator rules deletion separately. They are not real apps, so they neither block nor join
  the gate.

> **RULED (2026-07-02):** (a) — `apps/website` + `apps/marketing-site` (**+ `apps/fx-demo`**, the third
> `package.json`-less prototype) stay untracked, read-only design seeds, out of every pathspec; deletion is a
> separate Operator call.

> **Fork E (minor, ruled at ship) — a new dependency is the Operator's call.** The recommended engine (§7-C
> Arm B) reuses `apps/echomq`'s exact dep set and the bundle's **hand-rolled** compact markdown renderer — so
> **no new dependency**. Pulling a markdown library (e.g. a `react-markdown`) instead would be a **dependency
> fork** (the package/app-split + the standing laws make a new dependency an Operator decision). Steward: keep
> the zero-dependency ported renderer; surface a markdown library only if the Operator prefers it at ship.
>
> **RULED (2026-07-02):** **zero new dependency** — the ported hand-rolled compact markdown renderer + the
> `apps/echomq` dep set; the lockfile gains only the `@mercury/showcase` importer block.

> **Framing (propagate to any brief derived from this spec):** no gendered pronouns for agents; no perceptual or
> interior-state verbs ("sees" / "wants" / "feels"); no first-person narration ("we" / "I think"). State each
> surface as a contract (precondition / postcondition / invariant) so acceptance is at the boundary, not by
> re-reading the diff.

## Map — the sub-rung triads

BUILD-READY (authored 2026-07-02): [`../mx.9.1/mx.9.1.md`](../mx.9.1/mx.9.1.md) (the spine — scaffold ·
shim · sanity page · wiring) · [`../mx.9.2/mx.9.2.md`](../mx.9.2/mx.9.2.md) (the derived registry + shell).
SOLID-FORWARD (authored 2026-07-02; re-sharpened at each own ship):
[`../mx.9.3/mx.9.3.md`](../mx.9.3/mx.9.3.md) (the live-stories surface + the shim liveness gate) ·
[`../mx.9.4/mx.9.4.md`](../mx.9.4/mx.9.4.md) (the contract surface) ·
[`../mx.9.5/mx.9.5.md`](../mx.9.5/mx.9.5.md) (chrome + theme acceptance + the epic closure). Epic
acceptance: [`mx.9.stories.md`](./mx.9.stories.md) (EPIC-LEVEL, routed to the sub-rungs); epic build
context: [`mx.9.llms.md`](./mx.9.llms.md) (EPIC-LEVEL — no agent builds from it alone).
