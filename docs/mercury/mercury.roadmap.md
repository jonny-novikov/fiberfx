# Mercury UI — the modular design-system roadmap

This roadmap is the **forward** plan for shipping **Mercury UI** as a modular design system. The
architecture canon (the topology, the laws, the decisions) lives in
[`mercury.design.md`](./mercury.design.md); the live dashboard is
[`mercury.progress.md`](./mercury.progress.md); the build loop is
[`program/mercury.program.md`](./program/mercury.program.md). The destination is **a per-component
Design System Storybook** standing on a clean three-package topology.

## The epic

**One design system, three movements: a UI-free `@mercury/core`; a Claude-Design-structured
`@mercury/ui` with a hand-authored contract beside every component; and a Storybook that documents
them all.**

- **Why.** Mercury's reusable foundation — the headless primitives (`internal/`), the reuse barrel
  (`shared/`), the helpers (`utils/`), and `cx`/`date`/`types` — is **trapped inside
  `@mercury/ui`**, yet `@mercury/effector` already reaches across the package boundary to use it.
  And `@mercury/ui`'s components are **flat aggregate files** (`Selection.tsx` holds five controls,
  `DataDisplay.tsx` four), which neither match how a design system is browsed nor map onto story
  files. A scratch package, `packages/mercury-ds`, holds a generated Claude-Design export plus a few
  hand-authored extras; it is **ephemeral**. Until the foundation is hoisted out and the components
  are one-folder-per-component, a faithful Storybook can't be built cleanly.
- **What.** Three packages under `mercury/packages/`: **`@mercury/core`** (NEW — the UI-free
  foundation: utils, types, headless hooks; zero components), **`@mercury/ui`** (components,
  re-organized the Claude-Design way — `src/components/<group>/<Name>/`), and **`@mercury/effector`**
  (the state adapters, unchanged role). `packages/mercury-ds` is **salvaged then deleted**. Then a
  **hand-authored contract** (`<Name>.prompt.md`) beside every component — the authoritative usage
  surface, grounded in real call sites and cross-linked. Then a **Storybook** that renders every
  component with its variants, controls, actions, and Effector-wired live state. Every structural
  move is **internal** — `@mercury/ui`'s public export surface never changes (the master invariant).
- **Who.** The Operator owns the goal and the forks; Claude Code ships the rungs through the
  standard loop (plan → build → gate → commit-when-asked). The consumers are the five workspace
  apps (`apps/{catalogue,docs,echomq,mobile,showcase}`) — they resolve packages from **source** via
  vite alias, so a package edit is live in dev with no prebuild.
- **When.** **Movements I + II are built; Movement III is the active frontier.** `mx.0`–`mx.2` are
  built (docs floor · the structural rung · the contract layer). In **Movement III (the Storybook +
  the design-system import + the showcase, now `mx.3`–`mx.9`)**, `mx.3` (host), `mx.4` (component
  stories), and `mx.5` (effector-powered stories) **are built**. `mx.6` (apps-side Pages) is
  **DROPPED** (Operator-ruled "skip apps", 2026-06-29). The frontier is the new tail: **`mx.7` —
  import the Claude-Design bundle's net-new components (a 5-batch epic, `mx.7.1`–`mx.7.5`)**, **`mx.8`**
  (enrich the Storybook stories — palette/roundings/variants/actions/scenes), **`mx.9`** (one
  comprehensive showcase application replacing the retired apps). Design flows DOWN from Claude Web
  only — `/design-sync` is forbidden (the import is one-way).
- **Where.** Code: `mercury/packages/{mercury-core,mercury-ui,mercury-effector}`, `mercury/apps/*`.
  Specs: `docs/mercury/` (this roadmap · the design canon · the progress dashboard · the rung
  triads under [`specs/`](./specs/)).

## The architecture — one mental model

Mercury is a **token-driven, presentational** React design system: components carry no app state,
style through enum props + CSS custom-property tokens (the `.mx-*` internal classes are private),
and default to the light theme (`dark-theme` on an ancestor flips every token). The modular
topology draws one new line — **the foundation is a package, not a folder**:

```
packages/
  mercury-core/      @mercury/core      UI-free foundation — no components, no JSX.
                     src/{internal,shared,utils} · cx · date · types · css.d.ts
                     React only as a peerDependency (headless hooks: useId, use-arrow-navigation…)
  mercury-ui/        @mercury/ui        components, Claude-Design grouped.
                     src/components/<group>/<Name>/<Name>.tsx (+ .prompt.md, + index)
                     src/styles/ (design tokens stay here)        →  depends on @mercury/core
  mercury-effector/  @mercury/effector  Effector state adapters (theme · toast · form · …)
                                                                  →  depends on @mercury/core
  (mercury-ds — DELETED after mx.1 salvage)
```

**The master invariant — the public surface holds.** Every named value and type exported from
`@mercury/ui`'s `src/index.ts` before a rung is still exported after it, same name + same type. Core
extraction and component regrouping are **internal moves**; the five apps and any downstream
consumer never break. **Corollary** (the standing Mercury rule): reusable, ready-to-use components
live ONLY in `packages/*` — apps only *compose* them; they never house a reusable component.

## The movements

### Movement I · The modular foundation & the Claude-Design structure

Hoist the foundation into `@mercury/core`, re-organize `@mercury/ui` one-folder-per-component
grouped by category, fold the salvage out of the ephemeral `mercury-ds`, and delete it — all behind
a stable public barrel. This is the floor the Storybook stands on.

### Movement II · The authored contract layer

Hand-author a `<Name>.prompt.md` beside every component — the authoritative usage contract the canon
promised (§4, §6): a grounded prop table, the enum language tied to the token families, a Composition
section that cross-links the siblings it feeds, and Examples drawn from real call sites. The contracts
feed each other and are reconciled against source + the reference apps (the contract-set method,
[`../aaw/aaw.architect-approach.md`](../aaw/aaw.architect-approach.md)). This is the surface the
Storybook renders and the Claude Design agent builds from — authored, not extracted.

### Movement III · The Storybook, the design-system import & the showcase

A `@storybook/react-vite` host that resolves `@mercury/ui` + `@mercury/core` from source (mirroring
the apps), with a global theme decorator, per-component stories across all groups, and Effector-powered
live-state stories (`mx.3`–`mx.5`, built). Then the **design-system import** (`mx.7`, a 5-batch epic):
the Operator authors the design system in Claude Web and exports a handoff bundle to
`packages/mercury-ds/`; mx.7 translates its **net-new** components into `@mercury/ui` (the `.mx-*` +
token idiom, additive), batch by batch with the Operator in the loop. Then `mx.8` **enriches** the
stories (palette · roundings · variant switching · actions · real-world scenes), and `mx.9` stands up
**one comprehensive showcase application** (library · docs · API · do/don't · recipes) replacing the
retired apps. **Design flows DOWN from Claude Web only — `/design-sync` and the `DesignSync` MCP are
forbidden** (the import is one-way).

## The rung ladder

| Rung | Movement | Ships (scope) | Status |
|---|---|---|---|
| **mx.0** | I | **Program docs floor** — this roadmap · the design canon · the progress dashboard · the program manual · the `mx.1` spec triad | ✅ **SHIPPED** (2026-06-28) |
| **mx.1** | I | **The structural rung** — extract `@mercury/core` (utils/types/hooks); regroup `@mercury/ui` into `src/components/<group>/<Name>/` (split the 5 aggregates); salvage `mercury-ds`'s real source (`Accordion`/`Toggle`/`Pagination`); **delete `mercury-ds`**. Public barrel byte-stable (91 → 103, additive). | ✅ **BUILT** (gate-green 2026-06-28; commit pending) |
| **mx.2** | II | **The contract layer** — hand-author a co-located `<Name>.prompt.md` for all 33 components (grounded prop table · enum language · Composition cross-links · real-call-site examples); ratify the app/library split by audit | ✅ **BUILT** — 33/33 contracts, gate-green (2026-06-28; commit pending) ([`specs/mx.2/mx.2.md`](./specs/mx.2/mx.2.md)) |
| **mx.3** | III | **Storybook host + foundations stories** — `apps/storybook/` (`@storybook/react-vite` 10.4.6), source-resolved packages, CSF3, a light/`dark-theme` decorator, first stories (Icon · tokens · Button) | ✅ **BUILT** (gate-green 2026-06-28; `/mercury-ship mx.3`) ([`specs/mx.3/mx.3.md`](./specs/mx.3/mx.3.md)) |
| **mx.4** | III | **Component stories + the focused-trio enhancement** — a co-located `<Name>.stories.tsx` for all 33 components (CSF3, controls from the contract, variant/states grids; data-prop stories grounded in real call sites); **+ the additive `@mercury/ui` enhancement**: `Card` `title`/`actions` header props + new `ListRow` + new `MoneyInput` (barrel +4 names, additions-only) | ✅ **BUILT** (gate-green 2026-06-29; `/mercury-ship mx.4`) ([`specs/mx.4/mx.4.md`](./specs/mx.4/mx.4.md)) |
| **mx.5** | III | **Effector-powered stories** — a host-home `Effector/<Adapter>` story for **all six** `@mercury/effector` adapters (`theme · toast · createForm · strength · createCooldown · formatter`), each wiring the adapter's live Effector state (`effector-react` hooks; models at module scope) into the real `@mercury/ui` component(s) at the real prop surface; the `@mercury/ui` surface frozen **byte-identical** (no barrel change), zero host-config edit, `sb:build` 36 → 42 homes | ✅ **BUILT** (gate-green 2026-06-29; `/mercury-ship mx.5`) ([`specs/mx.5/mx.5.md`](./specs/mx.5/mx.5.md)) |
| **mx.6** | III | **Apps-side Pages — DROPPED** (Operator-ruled "skip apps at all", 2026-06-29). Superseded by the mx.7/8/9 tail; the component-documentation value moves to the mx.9 showcase. See [`specs/mx.6/mx.6.md`](./specs/mx.6/mx.6.md) | ❌ **DROPPED** |
| **mx.7** | III | **Import the Claude-Design bundle's net-new components into `@mercury/ui`** — a **5-batch epic** (30 net-new + 2 folds), translating the bundle's inline-style prototypes into the `.mx-*` + token idiom, additively (master invariant holds); design flows DOWN only (`/design-sync` forbidden). Epic: [`specs/mx.7/mx.7.md`](./specs/mx.7/mx.7.md) | ✅ **BUILT** (epic COMPLETE 2026-07-01 — 30 net-new + 2 folds across 5 batches 7.1/7.2/7.3.{1,2,3}/7.4/7.5; barrel additive, 0 removed) |
| ↳ **mx.7.1** | III | foundational primitives — `Heading · Text · Label · IconButton · Separator` (+5) | ✅ **BUILT** (gate-green 2026-06-30; `/mercury-ship mx.7.1`; barrel 107→127, 0 removed) ([`specs/mx.7.1/mx.7.1.md`](./specs/mx.7.1/mx.7.1.md)) |
| ↳ **mx.7.2** | III | feedback/display + layout — `Callout · Spinner · Skeleton · Blockquote · DataList · Code · Kbd · AspectRatio · Collapsible · ScrollArea` (+10) | ✅ **BUILT** (gate-green 2026-06-30; barrel 127→160, 0 removed) ([`specs/mx.7.2/mx.7.2.md`](./specs/mx.7.2/mx.7.2.md)) |
| ↳ **mx.7.3** | III | input/selection composites — **SUB-EPIC, Operator-split 2026-06-30** into 7.3.1/7.3.2/7.3.3 (the heavy date pair shed one machine each). Sub-epic: [`specs/mx.7.3/mx.7.3.md`](./specs/mx.7.3/mx.7.3.md) | 🪟 SPLIT |
| ↳↳ **mx.7.3.1** | III | `DateField` — the segmented date input (+1) — composes `@mercury/core` `useDateField` (A2 arm a); barrel 50→51; REAL aaw Trio, 2 mars waves (x.md §5 LAW-1b) | ✅ **BUILT** (gate-green 2026-06-30) ([`specs/mx.7.3.1/mx.7.3.1.md`](./specs/mx.7.3.1/mx.7.3.1.md)) |
| ↳↳ **mx.7.3.2** | III | `Calendar` — the month-grid picker (+1) — composes `@mercury/core` `useCalendar` (A2 arm a, reuses the mx.7.3.1 date layer); barrel +1; grid machine — REAL aaw Trio + Apollo, write-ready waves (x.md §5 LAW-1b) | ✅ **BUILT** (gate-green 2026-06-30) ([`specs/mx.7.3.2/mx.7.3.2.md`](./specs/mx.7.3.2/mx.7.3.2.md)) |
| ↳↳ **mx.7.3.3** | III | the selection composites — `CheckboxGroup · CheckboxCards · RadioGroup · RadioCards` (+4) + folds `Textarea`(+`size`)/`ToggleGroup`(+`accent`/group-`disabled`) — NORMAL | ✅ **BUILT** (gate-green 2026-07-01; `/mercury-ship mx.7.3.3`; Duo+ (Director+Mars two-pass), NORMAL → no in-pipeline Apollo; **A1** compose the live `Checkbox`/`Radio` in a card shell · **A3** fold into live `ToggleGroup`; barrel +4/−0 → **65 folders**, folds add 0 export; LAW-1a mutation (`accent="chartreuse"`→TS2322); **closes the mx.7 import epic**) ([`specs/mx.7.3.3/mx.7.3.3.md`](./specs/mx.7.3.3/mx.7.3.3.md)) |
| ↳ **mx.7.4** | III | the **overlay-floor primitive** (`@mercury/core`, headless) + `Dialog · AlertDialog · Popover` (+3, `@mercury/ui`) + the **strong effector bridge** (`createDisclosure` + a scroll-lock singleton) — Squad-tier | ✅ **BUILT** (gate-green 2026-07-01; `/mercury-ship mx.7.4`; §A shared `@mercury/core` floor · §C `Dialog` net-new · §D hand-roll · §E richer bridge; barrels @ui +3 / @core +floor / @effector +`disclosure`; Apollo adversarial a11y, 1 block remediated; showcase foundation = commit #2) |
| ↳ **mx.7.5** | III | menus/hover/nav (consume the floor) — `Dropdown · ContextMenu · HoverCard · LinkPreview · Menubar · TabNav` (+6) — Squad-tier | ✅ **BUILT** (gate-green 2026-07-01; `/mercury-ship mx.7.5`; Squad + Apollo adversarial-a11y = **BUILD-GRADE**; barrel +6/−0 → 61 folders; the 7.4 overlay-floor consumed (no re-roll), `navigation/` group ruled; **the mx.7 import's overlay·menu·nav batches COMPLETE — only `mx.7.3.3` (selection composites) remains**) |
| **mx.8** | III | **Enrich the Storybook stories** — palette · roundings · variant switching · actions · real-world scenes (host-config + co-located enrichment; `@mercury/ui` surface frozen byte-identical). Now an **epic**, sliced by component group (like mx.7); the cross-cutting globals build host-wide on the first slice. [`specs/mx.8/mx.8.md`](./specs/mx.8/mx.8.md) | 🪟 EPIC (open) |
| ↳ **mx.8.1** | III | **foundations slice** — the `Palette` + `Roundings` **brand-only toolbar globals** (host-wide) + the foundations variant/options audit (`Icon · Divider · Separator · Heading · Text`; the `Heading` `as` gap filled) + 2 **foundations-in-context** scenes (`Scenes/Profile · Scenes/Article`); barrel byte-identical; K-4 actions deferred (presentational primitives declare no handler). [`specs/mx.8.1/mx.8.1.md`](./specs/mx.8.1/mx.8.1.md) | ✅ **BUILT** (gate-green 2026-07-01; `/mercury-ship mx.8.1`; Trio; INV-6 render-check + LAW-1a mutation) |
| ↳ **mx.8.2** | III | **actions slice** — the `actions` group (`Button · IconButton · Link`) variant/options audit (a **VERIFY** — already full-union from mx.4) + **K-4 actions ACTIVATED** as a **zero-dep `fn()` spy** (SB 10.4.6 core `storybook/test`; the mx.8 Fork-5 dependency-fork **dissolved** — no host dep) + 1 **actions-in-context** scene (`Scenes/Confirm`); Palette/Roundings globals **inherited** (`preview.tsx` unedited); barrel byte-identical. [`specs/mx.8.2/mx.8.2.md`](./specs/mx.8.2/mx.8.2.md) | ✅ **BUILT** (gate-green 2026-07-01; `/mercury-ship mx.8.2`; Trio; LAW-1a mutation; +1 host-tsc `paths` alias for the first `storybook/test` import) |
| ↳ **mx.8.3+** | III | the remaining interactive groups' variant/actions audit + scenes (`selection · inputs · feedback · data-display · navigation · overlay`), **one group per slice**, inheriting the zero-dep `fn()` pattern; sliced as `mx.7.4/7.5` land the full library | 📋 PLANNED |
| **mx.9** | III | **One comprehensive showcase application** — `apps/showcase/` (vite/React, source-resolved) serving the library · documentation · API · do/don't · recipes, replacing the retired apps; Squad-tier. [`specs/mx.9/mx.9.md`](./specs/mx.9/mx.9.md) | 📋 PLANNED |
| **mx.10** | — (toolchain) | **Workspace dependency reconciliation + the vite 7 lift** — a pnpm `catalog:` single-sources the shared toolchain versions (`typescript ~5.9.3` · `vite ^7` · `vitest ^4` · `react ^19` · `jsdom ^26` · `@vitejs/plugin-react`) across `packages/*` + `apps/*` + the workspace root (**NOT** `codemojex/**` — a sibling `/cm-ship` rung migrates it); lifts vite 6→7, converges the vitest dual-major, tilde-pins TS. **Orthogonal to Movement III** (a toolchain rung, not a feature rung); the barrel stays byte-identical. [`specs/mx.10/mx.10.md`](./specs/mx.10/mx.10.md) | 📐 SPECCED (2026-07-01) |

> **Re-sequencing is Operator-ruled.** Movement II (contracts) is laddered behind `mx.1` because a
> contract grounds in the component's source + folder; Movement III (Storybook) is laddered behind
> `mx.2` because each story writes its controls from the contract. The ladder is fixed at this
> checkpoint; the Operator may re-order, and rungs are revisable, not deleted. *(The contract layer
> was inserted as Movement II on 2026-06-28, shifting the Storybook rungs from `mx.2`–`mx.5` to
> `mx.3`–`mx.6`. On 2026-06-29 `mx.5` was split — effector-powered stories stay `mx.5`; the apps-side
> Pages re-sequenced to `mx.6`; build/deploy + design-sync to `mx.7` — Operator-ruled. Later on
> 2026-06-29 the tail was **re-scoped** (Operator-ruled): `mx.6` (apps-side Pages) **DROPPED**
> ("skip apps"); the new tail is `mx.7` (the Claude-Design import — a 5-batch epic `mx.7.1`–`mx.7.5`,
> the overlay batch split 7.4→7.4+7.5), `mx.8` (enrich the stories), `mx.9` (the showcase
> application). The old build/deploy + design-sync re-align is retired — design now flows DOWN from
> Claude Web only.)*
>
> **`mx.10` is a cross-cutting TOOLCHAIN rung (2026-07-01), not a Movement III feature rung** — the
> pnpm-`catalog:` dependency reconciliation + the vite 6→7 lift. It sits *beneath* the ladder (the
> build tooling every rung stands on), so it is **orthogonal**: shippable independent of `mx.7.3.3` /
> `mx.8` / `mx.9`, and **recommended before `mx.9`** so the new showcase app inherits a clean, current
> toolchain. Its scope is `packages/*` + `apps/*` + root (the codemojex sub-workspace is a sibling
> `/cm-ship` migration); the master invariant (the `@mercury/ui` barrel) holds byte-identical.

## How the program runs

Each rung is one shippable increment, run through a small fixed loop:

1. **Sharpen** — confirm the rung's scope against this roadmap + the design canon; author/refresh
   the [`specs/<rung>/`](./specs/) triad (`<rung>.md` body · `.stories.md` acceptance · `.llms.md`
   build context).
2. **Build** — implement to the spec; move (don't rewrite) where the rung relocates code; keep the
   diff inside `mercury/packages/*` (+ the app `vite.config.ts` aliases a package rung touches).
3. **Gate** (the ladder, run from `mercury/`):
   - `pnpm --filter "./packages/*" typecheck` and `pnpm --filter "./packages/*" build` green for every
     package (never a blind `pnpm -r` — it walks the `codemojex-node` sub-workspace, the wrong scope).
   - **Barrel-diff** — the set of named exports from `@mercury/ui` is identical before/after the
     rung (the master invariant, mechanically checked).
   - Every app still builds (`pnpm --filter "./apps/*" build`), resolving packages via alias.
   - No dangling import to a deleted/moved path.
4. **Demo → review → record** — update [`mercury.progress.md`](./mercury.progress.md); record any
   decision as a `D-` entry in [`mercury.design.md`](./mercury.design.md).
5. **Commit** — only when the Operator asks; pathspec only (never `git add -A`); split an entangled
   tree into scoped commits.

## Seams & open decisions

- **S-1 · `@mercury/core` distribution.** Recommended **source-consumed** (`exports → ./src/index.ts`,
  like `@echo/core`) so apps + Storybook resolve it from source with no prebuild; the alternative is
  a dist build matching `@mercury/ui`/`@mercury/effector`. Ruled in `mx.1` (`D-3`).
- **S-2 · Net-new component group placement.** `PasswordStrength` (feedback vs inputs), `AuthLayout`
  (a new `layout`/`templates` group), `Accordion` (navigation vs a `disclosure` group), `Toggle`
  (selection vs actions) — placement is a judgment call, not a correctness one. Ruled in `mx.1`
  (`D-4..`).
- **S-3 · Token handoff.** `mercury-ds/handoff/tokens.css` (19K) may carry newer tokens than
  `@mercury/ui/src/styles/tokens.css`; `mx.1` diffs and folds in do-no-harm. Whether design tokens
  later migrate down into `@mercury/core` is a **deferred** question (out of scope for `mx.1`,
  Operator-revisable).
- **S-4 · the `mercury-ds` bundle (the import source).** `packages/mercury-ds/` is a **new, untracked
  Claude-Design handoff** (created 2026-06-29 — NOT the old ephemeral one deleted in mx.1): 53 component
  prototypes + tokens/fonts + a live-`.tsx` showcase engine. It is `mx.7`'s read-only **import source**.
  Its git fate is an open fork (mx.7 epic §4: gitignore-regenerable [Steward] vs delete-after-7.5 vs
  track); it stays OUT of every commit pathspec regardless.
- **S-5 · design flows DOWN only — `/design-sync` is forbidden.** The Operator authors the design
  system in Claude Web (project `…/22dd5e3f-…`) and exports the bundle down to `packages/mercury-ds/`.
  `mx.7` translates it **into** `@mercury/ui`; **the `DesignSync` MCP + the `/design-sync` skill (which
  push local→remote) are forbidden** this program. The old design-sync re-align (the prior `mx.7`) is
  retired — the import is one-way.

## Map

This roadmap · the design canon [`mercury.design.md`](./mercury.design.md) · the dashboard
[`mercury.progress.md`](./mercury.progress.md) · the **component registry & developer reference**
[`mercury-ui.registry.md`](./mercury-ui.registry.md) (the as-built index of every component, its
Storybook status, and the `apps/showcase` plan) · the build loop
[`program/mercury.program.md`](./program/mercury.program.md) · the rung triads under
[`specs/`](./specs/). Code: [`../../mercury/packages`](../../mercury/packages). The Claude-Design
conventions Mercury exports to: `mercury/.design-sync/conventions.md`.
