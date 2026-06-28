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
- **When.** **Movement I + II are built; Movement III is the frontier.** `mx.0` (docs floor), `mx.1`
  (the structural rung), and **`mx.2` — the contract layer — are built**: all 33 components carry a
  hand-authored, grounded, cross-linked `<Name>.prompt.md`. **Movement III (the Storybook,
  `mx.3`–`mx.6`) is now the active frontier** — each story writes its controls from the contract
  `mx.2` fixed.
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

### Movement III · The Design System Storybook

A `@storybook/react-vite` host that resolves `@mercury/ui` + `@mercury/core` from source (mirroring
the apps), with a global theme decorator, per-component stories across all groups (variants,
`argTypes`/controls written from the contract, actions), Effector-powered live-state stories, and a
deployable static build that re-aligns with the Claude-Design (`.design-sync`) export.

## The rung ladder

| Rung | Movement | Ships (scope) | Status |
|---|---|---|---|
| **mx.0** | I | **Program docs floor** — this roadmap · the design canon · the progress dashboard · the program manual · the `mx.1` spec triad | ✅ **SHIPPED** (2026-06-28) |
| **mx.1** | I | **The structural rung** — extract `@mercury/core` (utils/types/hooks); regroup `@mercury/ui` into `src/components/<group>/<Name>/` (split the 5 aggregates); salvage `mercury-ds`'s real source (`Accordion`/`Toggle`/`Pagination`); **delete `mercury-ds`**. Public barrel byte-stable (91 → 103, additive). | ✅ **BUILT** (gate-green 2026-06-28; commit pending) |
| **mx.2** | II | **The contract layer** — hand-author a co-located `<Name>.prompt.md` for all 33 components (grounded prop table · enum language · Composition cross-links · real-call-site examples); ratify the app/library split by audit | ✅ **BUILT** — 33/33 contracts, gate-green (2026-06-28; commit pending) ([`specs/mx.2/mx.2.md`](./specs/mx.2/mx.2.md)) |
| **mx.3** | III | **Storybook host + foundations stories** — `apps/storybook/` (`@storybook/react-vite` 10.4.6), source-resolved packages, CSF3, a light/`dark-theme` decorator, first stories (Icon · tokens · Button) | ✅ **BUILT** (gate-green 2026-06-28; `/mercury-ship mx.3`) ([`specs/mx.3/mx.3.md`](./specs/mx.3/mx.3.md)) |
| **mx.4** | III | **Component stories + the focused-trio enhancement** — a co-located `<Name>.stories.tsx` for all 33 components (CSF3, controls from the contract, variant/states grids; data-prop stories grounded in real call sites); **+ the additive `@mercury/ui` enhancement**: `Card` `title`/`actions` header props + new `ListRow` + new `MoneyInput` (barrel +4 names, additions-only) | ✅ **BUILT** (gate-green 2026-06-29; `/mercury-ship mx.4`) ([`specs/mx.4/mx.4.md`](./specs/mx.4/mx.4.md)) |
| **mx.5** | III | **Effector-powered stories + the apps-side Pages** — stories wiring `@mercury/effector` (theme · toast · `createForm` · `createCooldown`) **and** brand-new Pages built from the apps' real composed screens (`apps/{catalogue,echomq,showcase,mobile,docs}`) wiring real `@mercury/ui` + `@mercury/effector` (the apps-side mandate re-sequenced here from mx.4 — Operator-ruled) | 📋 PLANNED |
| **mx.6** | III | **Build/deploy + design-sync reconcile** — static Storybook build + deploy; regenerate the Claude-Design export from the grouped structure; re-align the `.design-sync` pipeline | 📋 PLANNED |

> **Re-sequencing is Operator-ruled.** Movement II (contracts) is laddered behind `mx.1` because a
> contract grounds in the component's source + folder; Movement III (Storybook) is laddered behind
> `mx.2` because each story writes its controls from the contract. The ladder is fixed at this
> checkpoint; the Operator may re-order, and rungs are revisable, not deleted. *(The contract layer
> was inserted as Movement II on 2026-06-28, shifting the Storybook rungs from `mx.2`–`mx.5` to
> `mx.3`–`mx.6`.)*

## How the program runs

Each rung is one shippable increment, run through a small fixed loop:

1. **Sharpen** — confirm the rung's scope against this roadmap + the design canon; author/refresh
   the [`specs/<rung>/`](./specs/) triad (`<rung>.md` body · `.stories.md` acceptance · `.llms.md`
   build context).
2. **Build** — implement to the spec; move (don't rewrite) where the rung relocates code; keep the
   diff inside `mercury/packages/*` (+ the app `vite.config.ts` aliases a package rung touches).
3. **Gate** (the ladder, run from the workspace root):
   - `pnpm -r typecheck` and `pnpm -r build` green for every package.
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
- **S-4 · design-sync output path.** `packages/mercury-ds` appears to be a stale/relocated
  design-sync bundle; deleting it is safe (re-generable). `mx.1` confirms `.design-sync/config.json`'s
  output target; the pipeline re-alignment is `mx.5`.

## Map

This roadmap · the design canon [`mercury.design.md`](./mercury.design.md) · the dashboard
[`mercury.progress.md`](./mercury.progress.md) · the build loop
[`program/mercury.program.md`](./program/mercury.program.md) · the rung triads under
[`specs/`](./specs/). Code: [`../../mercury/packages`](../../mercury/packages). The Claude-Design
conventions Mercury exports to: `mercury/.design-sync/conventions.md`.
