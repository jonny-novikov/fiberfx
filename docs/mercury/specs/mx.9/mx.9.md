# MX.9 · The Mercury showcase — one comprehensive application for the library

> **Status: 📐 SOLID-FORWARD (specced 2026-06-29, NOT yet built).** The **closer of the Movement-III tail**
> (`mx.7` import · `mx.8` stories · **`mx.9` showcase application**, per the
> [`../mx.7/mx.7.md`](../mx.7/mx.7.md) epic, which supersedes the roadmap's dropped mx.6). mx.9 stands up **one
> real Mercury application** — `apps/showcase/` — that **composes** `@mercury/ui` from source and serves the
> whole library as a single browsable, documented surface: **the components, their documentation, their API,
> their do/don't, and their recipes**. It RE-FOUNDS the documentation surface the retired `apps/{showcase,
> catalogue,docs}` once carried (those three are already gone from the workspace); it deletes no live app.
>
> **This body is authored at SOLID-FORWARD grain** — complete and coherent, but it ladders behind the
> **completed import** (`mx.7.4`) and the **enriched stories** (`mx.8`), so it will be **re-sharpened at its own
> ship** against the as-built `@mercury/ui` surface those rungs land. Treat every count and component reference
> as DERIVED-at-build, never hardcoded (INV-6).
>
> **Risk: SQUAD-TIER at ship.** mx.9 stands up a **real workspace app that builds and joins the apps gate** —
> not a docs file, not an additive story. A verifier is **mandatory** at ship (independent gate re-run + an
> adversarial probe of the doc-source-of-truth and package/app-split invariants). The load-bearing hazards: (a)
> the new app **leaking a reusable component** back into an app (the package/app-split law — INV-4); (b) the
> showcase **re-authoring doc prose** that forks from the `.prompt.md` contract (the doc-source-of-truth law —
> INV-5); (c) the registry **hardcoding** a component list that drifts from the real `@mercury/ui` surface
> (INV-6); (d) the app **perturbing the barrel** (it must not — INV-1).
>
> **The decisions this rung carries are FORKS for the Operator** (§7), framed never decided. mx.9 founds an
> app but is **not** a system-spec founding, so the forks sit inline (§7) with a Steward recommendation each;
> the Operator rules at the ship's sharpen stage.

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
  renderer, ported, zero new dependency), and a **theme flip** loading `@mercury/ui`'s stylesheet. Plus the
  wiring: the app auto-joins `build:apps`; the stale root `dev:showcase` script (currently dangling at the
  retired app) is reconciled to the reborn app.
- **Who.** *Authored by* the Mercury spec-steward (this triad) + the implementor wave (the app). *Consumed by* —
  (1) Mercury contributors and product teams browsing/learning the library; (2) a design/coding agent
  discovering `@mercury/ui`'s surface, props, and recipes; (3) the Operator, accepting Movement III at the app
  boundary.
- **When.** After **mx.7.4** (the import complete — the ~66-component surface the browser renders) and **mx.8**
  (the enriched stories). It closes Movement III. (At SOLID-FORWARD grain now; re-sharpened at ship against the
  as-built surface.)
- **Where.** New: `mercury/apps/showcase/**`. Wiring: `mercury/package.json` (reconcile the `dev:showcase`
  script to the reborn app; the new app auto-joins `build:apps` with no edit). `mercury/pnpm-lock.yaml` **only
  if** a dependency moves — the recommended engine reuses `apps/echomq`'s exact dep set, so ideally **no new
  dependency** (a new dependency is itself an Operator fork — §7-E). The design seeds
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
  showcase auto-covers the whole post-mx.7 surface (~66 components) and any later addition with **no
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
  and `@mercury/ui`'s stylesheet is loaded so `rgb(var(--token))` resolves. Observable: a rendered component's
  surface inverts between the two states.
- **INV-9 · Scope discipline.** The rung touches only: `mercury/apps/showcase/**` (new); `mercury/package.json`
  (the `dev:showcase` reconcile); and `mercury/pnpm-lock.yaml` **only if** a real dependency moved (ideally
  none). **No** `packages/*` edit, **no** other app, **no** story added to `@mercury/ui` (the package/app split
  — the showcase consumes the package stories, it authors none). The design seeds stay untracked and out of the
  commit pathspec.

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | The **`apps/showcase/` app scaffold** — `package.json` (`@mercury/showcase`, the `apps/echomq` dep set, `@mercury/*` `workspace:*`) · `vite.config.ts` (source-resolution alias, byte-mirror) · `tsconfig.json` (`paths` mirror) · `index.html` · `src/main.tsx` + `src/App.tsx` | INV-2 + INV-3; the app builds and resolves the packages from source |
| K-2 | The **derived registry + shell** — a glob-built component list grouped by category (the bundle `CAT_ORDER`), a sidebar + topbar, a component page with **Stories** / **Docs** tabs | INV-6; nav comes from the real `@mercury/ui` tree, no hardcoded list; the post-mx.7 surface appears whole |
| K-3 | The **story renderer** — a small CSF3 interpreter (the bundle `StoryBlock` pattern: `render`→mount, `args`→`createElement(component, args)`), rendering each component's live `*.stories.tsx` with **no Storybook runtime dependency** (the `import type { Meta, StoryObj }` is erased at build) | INV-5; a component's stories render in the page; no `@storybook/*` runtime import |
| K-4 | The **contract renderer + the four doc views** — the `.prompt.md` imported live (`?raw`) and rendered as markdown (the bundle `library.jsx` compact renderer, ported, zero new dependency); the **Docs / API / do-don't / recipes** surfaces are **cuts of that one rendered contract** | INV-5; every doc surface traces to the `.prompt.md`; no in-app authored API table |
| K-5 | The **theme flip + chrome** — a light/`dark-theme` toggle + the `@mercury/ui` stylesheet loaded; the chrome skinned from the design seeds (the bundle `app.css` / the `apps/website` docs aesthetic — §7-C/§7-D) | INV-8; a component inverts between themes; the stylesheet resolves the token swatches |
| K-6 | The **gate + wiring** — the app joins `pnpm --filter "./apps/*" build`; the stale root `dev:showcase` script reconciled to the reborn app; the barrel byte-identical; the consume-down greps empty | INV-1 + INV-3 + INV-7 + INV-9; the gate is green with three product apps and an untouched barrel |

## 5 · The method (build order)

A small task DAG; the scaffold lands first, the engine fills it, the gate closes it.

1. **Scaffold the app.** Create `apps/showcase/{package.json, vite.config.ts, tsconfig.json, index.html}` +
   `src/{main.tsx, App.tsx}`. `package.json` name `@mercury/showcase`, `private`, `type: module`, scripts
   `dev`/`build`/`preview`/`typecheck` (mirror [`apps/echomq/package.json`](../../../../mercury/apps/echomq/package.json)),
   the **same** dep/devDep set as `apps/echomq` (no new dependency — §7-E). `vite.config.ts` **byte-mirrors** the
   apps' alias block; `tsconfig.json` extends `../../tsconfig.base.json` with the same `paths`. Install (writes
   `pnpm-lock.yaml` only if a dep actually moved).
2. **Derive the registry.** Build the component list from a glob over the real `@mercury/ui` tree —
   `import.meta.glob("../../packages/mercury-ui/src/components/**/*.stories.tsx")` and the sibling `*.prompt.md`
   (`?raw`) — grouped by the `<group>/` segment (the bundle `CAT_ORDER`/`CAT_LABEL`, library.jsx). **No
   hardcoded list** (INV-6). Derive the showcase's own registry from `@mercury/ui`, **not** the bundle's
   `packages/mercury-ds/project/components/registry.ts` (that path-list uses the bundle's grouping, not the live
   library's).
3. **Build the shell.** A grouped sidebar (the derived registry), a topbar (the theme toggle), and a component
   page with **Stories** / **Docs** tabs — the proven shape of the bundle
   [`library.jsx`](../../../../mercury/packages/mercury-ds/project/showcase/library.jsx), reimplemented as a
   typed React app (not ported verbatim — it is JSX-on-`window` for the in-browser loader).
4. **Port the story interpreter.** Reimplement the bundle `StoryBlock` (library.jsx): read `mod.default`
   (the CSF meta — `component`, `parameters.summary`), iterate the named exports, render `story.render()` as its
   own component or `createElement(meta.component, story.args)`, wrap each in an error boundary. The story files'
   `import type { Meta, StoryObj } from "@storybook/react-vite"` is **type-only** (erased at build) — **no
   Storybook runtime is pulled** (INV-5/K-3).
5. **Port the markdown renderer + cut the four views.** Reimplement the bundle compact markdown renderer
   (library.jsx `renderMarkdown`, zero new dependency) over the `?raw`-imported `.prompt.md`. The **Docs** view
   is the full contract; the **API** view cuts `## Props`; the **do/don't** view cuts `## The enum language` +
   `## Notes`; the **recipes** view cuts `## Examples`. All four are cuts of the one rendered contract (INV-5).
   *(Whether the four views are sub-tabs of one Docs page or top-level — a §7-A grain choice, ruled at ship.)*
6. **Theme flip + stylesheet + chrome.** Wire the light/`dark-theme` toggle (the canon §0 mechanism) and load
   `@mercury/ui`'s stylesheet so tokens resolve; skin the chrome from the design seeds (§7-C/§7-D).
7. **Gate + wiring.** Run the package gate (unchanged), the apps build **including** showcase, the barrel-diff
   (byte-identical), and the consume-down greps (INV-7). Reconcile the root `dev:showcase` script to the reborn
   app. (`dev:catalogue` / `dev:docs` remain stale — those apps stay retired — a Director roadmap/wiring fold,
   **out of mx.9 scope**.)

Grounding sources (re-probe before trusting, per [`mx.9.llms.md`](./mx.9.llms.md)): the apps' vite alias +
tsconfig `paths`; the barrel `packages/mercury-ui/src/index.ts`; the contract format
[`../../contracts.md`](../../contracts.md) + an exemplar `Button.prompt.md`; a live `*.stories.tsx` (the CSF3
object shape); the bundle showcase engine (the `StoryBlock` + `renderMarkdown` patterns to reimplement); the
theme mechanism in `packages/mercury-ui/src/styles/tokens.css`.

## 6 · Dependencies

- **Hard-gates on:** **mx.7.4** (the import complete — the full `@mercury/ui` surface the browser renders) and
  **mx.8** (the enriched stories rendered by the Stories tab). Soft: **mx.2** (the `<Name>.prompt.md` contracts
  the Docs/API/do-don't/recipes views render) and **mx.3** (the source-resolved-app precedent — the apps' alias
  + `tsconfig paths` this app mirrors).
- **Unblocks:** if the Operator rules **MVP-first** (§7-A), the follow-on **dedicated-surface** rungs (a
  standalone API explorer / a do-don't gallery / a recipes cookbook, each a purpose-built re-cut of the same
  contract source). Either way, mx.9 **closes Movement III**.
- **Touches:** `mercury/apps/showcase/**` (new app); `mercury/package.json` (the `dev:showcase` reconcile);
  `mercury/pnpm-lock.yaml` (only if a dependency moved — ideally none). The design seeds
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

### Fork B — app location/name: **`apps/showcase` (reborn)** · *Steward: showcase*

- **Arms.** `apps/showcase` (the bundle's own name for this engine, the Operator's word "showcase", and the
  existing — currently stale — root `dev:showcase` script, which a reborn `@mercury/showcase` **repairs** for
  free) · `apps/docs` (reads as docs-only — too narrow for "comprehensive") · `apps/mercury` (reads as the
  umbrella — collides with the workspace name `@mercury/*`).
- **Steward: `apps/showcase` / `@mercury/showcase`** — it matches the bundle's vocabulary and the Operator's own
  word, and reusing the name turns the dangling `dev:showcase` script back into a valid one (gate/wiring win).

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

> **Fork E (minor, ruled at ship) — a new dependency is the Operator's call.** The recommended engine (§7-C
> Arm B) reuses `apps/echomq`'s exact dep set and the bundle's **hand-rolled** compact markdown renderer — so
> **no new dependency**. Pulling a markdown library (e.g. a `react-markdown`) instead would be a **dependency
> fork** (the package/app-split + the standing laws make a new dependency an Operator decision). Steward: keep
> the zero-dependency ported renderer; surface a markdown library only if the Operator prefers it at ship.

> **Framing (propagate to any brief derived from this spec):** no gendered pronouns for agents; no perceptual or
> interior-state verbs ("sees" / "wants" / "feels"); no first-person narration ("we" / "I think"). State each
> surface as a contract (precondition / postcondition / invariant) so acceptance is at the boundary, not by
> re-reading the diff.
