# Mercury UI — the design canon

The single source of truth for Mercury's **architecture, laws, and decisions**. The forward plan is
[`mercury.roadmap.md`](./mercury.roadmap.md); the dashboard is
[`mercury.progress.md`](./mercury.progress.md). Where this canon and a rung spec disagree, the rung
spec's *body* is authoritative for that rung; this canon is the durable frame.

## §0 · What Mercury is

A **token-driven, presentational** React design system in a pnpm monorepo (Vite · Effector ·
TypeScript, Node ≥22, pnpm ≥10.17). Components carry no application state, style through **enum
props + design tokens** (never utility classes; the internal `.mx-*` classes are private), default
to the light theme, and flip to dark when an ancestor carries `dark-theme`. Fonts ship with the
bundle (DM Sans `--font-primary`, DM Mono `--font-secondary`, DM Serif Display `--font-display`).

## §1 · The package topology (the modular split)

Three packages, one new line drawn — **the foundation is a package, not a folder**:

| Package | Role | Depends on | Distribution |
|---|---|---|---|
| **`@mercury/core`** | UI-free foundation: headless primitives, the reuse barrel, helpers, `cx`/`date`/`types`. **Zero components, zero JSX.** | — (React only as a *peer* dep, for headless hooks) | source-consumed (`exports → ./src/index.ts`) — `D-3` |
| **`@mercury/ui`** | The component library, Claude-Design grouped. Design tokens (`src/styles/`) live here. | `@mercury/core` | dist build (`vite` lib + `tsc`) — unchanged |
| **`@mercury/effector`** | Effector state adapters (theme · toast · form · strength · cooldown · formatter). Components stay presentational. | `@mercury/core` + `@mercury/ui` | dist build — unchanged |

`packages/mercury-ds` is **ephemeral** and is deleted in `mx.1` (`D-2`). Apps consume `@mercury/*`
from **source** via vite alias (`apps/*/vite.config.ts`), so a package edit is live in dev with no
prebuild — the Storybook host (Movement II) follows the same convention.

### §1.1 · The dependency rule

`@mercury/core` sits beneath everything and imports nothing in-workspace. `@mercury/ui` and
`@mercury/effector` both depend on it. **No cycle**: `@mercury/core` never imports `@mercury/ui`.
The headless hooks (`useId`, `use-arrow-navigation`) make React a *peer* dependency of core — core
ships behavior, not UI.

## §2 · The master invariant — the public surface holds

**Every named value and type exported from `@mercury/ui`'s `src/index.ts` before a rung is still
exported after it, with the same name and the same type.** Core extraction and component regrouping
are *internal moves*; the five apps and any downstream consumer never break.

The mechanical check (the **barrel-diff**, in every package rung's gate): the set of `export` names
from `@mercury/ui` is identical before/after. `@mercury/ui` keeps `cx`/`date`/the shared types in
its barrel by **re-exporting them from `@mercury/core`** — the symbol moves house, the surface does
not.

**Corollary (the standing Mercury rule):** reusable, ready-to-use components live ONLY in
`packages/*`. Apps only *compose* them with the `@mercury/effector` plug — an app never houses or
reimplements a reusable component.

## §3 · The `@mercury/core` extraction inventory

`@mercury/core` is **hoisted, not rewritten** — these already exist inside `@mercury/ui/src` and are
moved verbatim (`D-1`, Operator-confirmed scope: utils/types/hooks only; design tokens stay in
`@mercury/ui` for now; `@mercury/effector` stays a separate package):

| Moved from `mercury-ui/src/` | What it is |
|---|---|
| `internal/` | Headless behavior primitives — `focus`, `use-arrow-navigation`, `use-id`, `get-directional-keys`, `kbd`, `dom`, `math`, `clamp`, `debounce`, `locale`, `css-escape`, `attrs`, `arrays`, `is`, `warn`, `noop`, `date-time/`, `types` (incl. their `.test.ts`) |
| `shared/` | The curated reuse barrel (`shared/index.ts`) — the `Without`/`WithChild`/`WithChildren`/`WithElementRef` type kit, date types, `mergeProps`, `useId`, value types (`Selected`, `Orientation`, `Direction`, `StyleProperties`, `SliderThumbPositioning`, `SegmentPart`…) |
| `utils/` | `clsx`, `merge-props`, `events`, `event-list`, `execute-callbacks`, `style`, `style-to-css`, `strings`, `after-sleep`, `dom`, `is` |
| `cx.ts` · `date.ts` · `types.ts` · `css.d.ts` | The tiny `cx` join, the locale-aware date wrappers, the top-level type utilities, the CSS module ambient types |

After the move: `@mercury/ui`'s internal `@/internal`, `@/utils`, `@/shared` imports repoint to
`@mercury/core`; `@mercury/effector`'s cross-package `date`/util imports repoint to `@mercury/core`;
`@mercury/ui`'s barrel **re-exports** `cx`/`date`/the shared types from `@mercury/core` (§2).

## §4 · The Claude-Design grouped-component layout (the law)

`@mercury/ui` adopts the structure Claude Design consumes — **one folder per component, grouped by
category**:

```
mercury-ui/src/components/
  <group>/
    <Name>/
      <Name>.tsx         the component (forwardRef, HTML-attr extension, .mx-* className styling)
      <Name>.prompt.md   the usage contract (hand-authored, mx.2) — props · variants · composition · examples
      index.ts           re-exports <Name>
```

This replaces the **flat aggregate files** (`Selection.tsx`, `Overlay.tsx`, `DataDisplay.tsx`,
`Feedback.tsx`, `Input.tsx` each hold several components). The grouping makes the library browsable,
co-locates each component's contract beside its source, and gives Movement III a 1:1 home for
`<Name>.stories.tsx`. The eight groups are inherited from the `mercury-ds` taxonomy, with one added
(`layout`).

The contract beside each component is **hand-authored** (Movement II / `mx.2`, `D-7`) via the AAW
*contract-set* method ([`../aaw/aaw.architect-approach.md`](../aaw/aaw.architect-approach.md)) — each
contract a hypothesis fed by its siblings and reconciled against source + the real call sites. A
generated stub is a seed for the prop list, never the contract.

### §4.1 · The component → group mapping (verified against source)

| Group | Components | Source today (in `@mercury/ui`) |
|---|---|---|
| `actions` | Button · **Link** | `Button.tsx` · `Link.tsx` (net-new) |
| `foundations` | Icon · **Divider** | `Icon.tsx` · `Divider.tsx` (net-new) |
| `inputs` | Input · Textarea · Search · Select · AuthCode | `Input.tsx` (aggregate → split) · `Select.tsx` · `AuthCode.tsx` |
| `selection` | Checkbox · Radio · Segmented · Slider · Switch · **Toggle** | `Selection.tsx` (aggregate → split) · `Toggle` (salvage) |
| `feedback` | Alert · Progress · **PasswordStrength** | `Feedback.tsx` (aggregate → split) · `PasswordStrength.tsx` (net-new) |
| `data-display` | Avatar · Badge · Chip · Tag · Card · Table · **Stat · Chart · Checklist** | `DataDisplay.tsx` (aggregate → split) · `Card.tsx` · `Table.tsx` (standalone, no overlap) · net-new |
| `navigation` | Tabs · **Pagination · Accordion** | `Tabs.tsx` · Pagination/Accordion (salvage) |
| `overlay` | Modal · Tooltip | `Overlay.tsx` (aggregate → split) |
| `layout` (new) | **AuthLayout** | `AuthLayout.tsx` (net-new) |

Notes (from the forensic inventory):
- **Aggregates to split:** `Selection` → {Checkbox, Radio, Segmented, Slider, Switch}; `Overlay` →
  {Modal, Tooltip}; `DataDisplay` → {Avatar, Badge, Chip, Tag}; `Feedback` → {Alert, Progress};
  `Input` → {Input, Textarea, Search}.
- **`Card`/`Table` are standalone files** with **no export overlap** — `DataDisplay.tsx` does not
  export them — so they drop cleanly under `data-display/`.
- **Net-new in `@mercury/ui`, no `mercury-ds` folder:** Link, Divider, PasswordStrength, Stat,
  Chart, Checklist, AuthLayout — they postdate the export and need a group (above).
- **Salvaged real source from `mercury-ds/mercury-components/`:** Accordion, Pagination, Toggle (the
  only runtime `.tsx` in `mercury-ds`; everything in `mercury-ds/components/` is a generated stub).

## §5 · `mercury-ds` — ephemeral, salvage then delete (`D-2`)

`packages/mercury-ds` is a scratch Claude-Design export. Its `components/<group>/<Name>/` dirs hold
**only generated artifacts** (`.jsx` stubs re-exporting `window.MercuryUI`, `.html` preview cards,
`.d.ts`, `.prompt.md`) — **no runtime source**; deleting them breaks nothing. `mx.1` salvages:

1. **Real source** — `mercury-components/{Accordion,Toggle,Pagination}.tsx` (+ `mercury-additions.css`)
   → their `@mercury/ui` groups, then exported.
2. **Contracts** — *deferred* in `mx.1`: the generated `<Name>.prompt.md` were extractor output (a
   `window.MercuryUI` runtime note), not authored contracts, so they were **not** ported. The
   co-located contract is **hand-authored in `mx.2`** (the contract layer, `D-7`). The generated
   seeds survive in `mercury/ds-bundle/components/<group>/<Name>/` for their prop lists.
3. **Tokens** — `handoff/tokens.css` diffed against `mercury-ui/src/styles/tokens.css`; newer tokens
   folded in do-no-harm (`S-3`).

Then `packages/mercury-ds` is **deleted in full** (generated stubs, `_vendor/`, `_ds_*`, `_preview/`,
`templates/`, `handoff/`). The Claude-Design export is re-generable by `.design-sync` on demand
(its bundle dir, confirmed in `mx.1`; the pipeline re-alignment is `mx.7`).

## §6 · The token vocabulary (ported from `.design-sync/conventions.md`)

Style **components through enum props**; style **your own layout with tokens**, written
`rgb(var(--token))` (values are raw RGB triplets; add ` / .5` for alpha):

- **Surfaces** `--bg-primary|secondary|tertiary|elevated|brand-subtle` · **Text**
  `--fg-primary|secondary|tertiary|brand` · **Borders** `--border-primary|secondary|strong|focus`.
- **Status families** (each ships `--bg-*`, `--fg-*`, `--border-*`, `--bg-*-subtle`): `positive` ·
  `negative` · `caution` · `info` · `discovery` · `brand`. Brand accent is **iris/indigo**.
- **Ramps** `--{slate,iris,indigo,green,red,orange,plum}-1..12` · **Type**
  `var(--font-primary|secondary|display)` · **Radii** `var(--radius-2..32 | --radius-full)` ·
  **Shadows** `var(--shadow-100..600)`.

The enum-prop language per family: `Button` `variant=primary|secondary|outline|ghost|destructive|inverse`
`size=sm|md|lg`; `Alert` `tone=info|success|warning|danger`; `Tag`/`Chip`
`tone=neutral|brand|positive|negative|caution|info|discovery`; `Card` `variant=flat|raised|floating`;
`Badge`/`Progress` `variant=brand|negative|positive|caution|info`. Each component's `<Name>.prompt.md`
+ `<Name>.d.ts` is the authoritative contract.

## §7 · Decisions

| # | Decision | Status |
|---|---|---|
| **D-1** | `@mercury/core` scope = **utils/types/hooks only** (`internal`+`shared`+`utils`+`cx`/`date`/`types`). Design tokens stay in `@mercury/ui`; `@mercury/effector` stays a separate package. *(As-built: `src/css.d.ts` — the `*.css` ambient — stayed in `@mercury/ui` since it serves the stylesheet import; `shared/css.d.ts` — the csstype augmentation — moved with `shared/`.)* | ✅ Operator-confirmed |
| **D-2** | `mercury-ds` is **ephemeral** → salvage real source (`Accordion`/`Toggle`/`Pagination`) + contracts + token handoff into `@mercury/ui`, then **delete** the package. *(As-built: `mercury-ds` was untracked → deletion is git-invisible; salvage lands as new files.)* | ✅ Operator-confirmed |
| **D-3** | `@mercury/core` is **source-consumed** (`exports`/`main`/`types` → `./src/index.ts`, `private`), React a **peer** dep + `@internationalized/date` a runtime dep — apps + Storybook resolve it from source, no prebuild. | ✅ ruled in `mx.1` (built 2026-06-28) |
| **D-4** | Group placement (final): `PasswordStrength`→`feedback`, `AuthLayout`→`layout` (new group), `Accordion`/`Pagination`→`navigation`, `Toggle`→`selection`. Placement only, not correctness. | ✅ ruled in `mx.1` |
| **D-5** | `@mercury/core`'s **public barrel is minimal** — `cx`/`ClassValue` + the `date` formatters (exactly what crosses into `@mercury/ui`'s surface); `@mercury/ui` re-exports them **explicitly** so the barrel stays decoupled from core's breadth. The moved foundation's `@/` imports were converted to **relative** so vite (no `@` alias in apps) bundles the date chain through the package boundary. | ✅ ruled in `mx.1` |
| **D-6** | `mercury-ds/handoff/tokens.css` **not folded** — its only delta vs `@mercury/ui`'s `tokens.css` was `/* @kind color */` design-sync annotations (identical values, zero net-new tokens); do-no-harm. The salvaged `mercury-additions.css` (the Accordion/Toggle/Pagination styles) became `styles/additions.css`, `@import`ed by `styles/index.css`. The salvaged `Accordion` was hardened to React 19's nullable `useRef().current`. | ✅ ruled in `mx.1` |
| **D-7** | The **component contract** is a co-located, **hand-authored** `<Name>.prompt.md` (never the design-sync stub) with a fixed six-section shape (role · Props · enum language · Composition · Examples · Notes), grounded in the `.tsx` + ≥1 real call site, cross-linked to siblings by relative path. Template frozen at [`contracts.md`](./contracts.md) from the `Button` exemplar. The contract-set method is [`../aaw/aaw.architect-approach.md`](../aaw/aaw.architect-approach.md). | ✅ ruled in `mx.2` |
| **D-9** | The **Storybook host is a workspace _app_** (`apps/storybook/` · `@mercury/storybook`), not a `packages/*` member — a Storybook ships nothing, it *composes* `@mercury/ui` like the five apps. It resolves `@mercury/*` **from source** (a vite alias mirroring the apps), is **excluded from the per-rung `apps/*` gate** (a separate `pnpm sb:build` smoke proves it), and is the single `/design-sync` `localDir` (the `ds-bundle/` relocates under it; the full pipeline re-align is `mx.7`). Built on **Storybook 10.4.6** (latest stable on Vite 6 + React 19). Co-located `*.stories.tsx` are excluded from `@mercury/ui`'s own `tsc` (the library carries no Storybook types — without the exclude the packages gate fails; proven load-bearing). | ✅ ruled in `mx.3` (built 2026-06-28) |
| **D-8** | The **app/library split holds by audit** — the reference apps (`showcase`, `economy`) are pure composers; the marginal hoist candidates (`showcase` `Demo`/`PropsTable`, `economy` `Mono`) stay **internal** (app-specific, or too thin to earn a public surface). A future genuinely-reusable element hoists **additively** with its own contract; an app never houses a reusable component (§2 corollary). | ✅ ruled in `mx.2` |
| **D-10** | **mx.4 — story coverage + the first additive growth.** Every component carries a co-located CSF3 `<Name>.stories.tsx` (35 component homes + the host `Foundations/Tokens` = 36 registered by `sb:build`); controls restate the mx.2 contract, and the **story-typecheck** (`sb:typecheck` — `@mercury/storybook`'s `tsc --noEmit`, which alone type-checks the stories; `sb:build`/esbuild strips types) is the compile-time NO-INVENT enforcement, **added to the gate ladder** this rung. The **focused-trio enhancement** grows `@mercury/ui` additively: `Card` gains optional `title`/`actions` header props (header rendered only when `title \|\| actions`; back-compat — and `CardProps` `Omit<…,"title">` shadows the native attr, verified no call site uses it; **no new export name**); two new components — `ListRow` (group `data-display`) + `MoneyInput` (group `inputs`, composing `Input` via its `leading` slot) — add **exactly** the export names `ListRow`/`ListRowProps`/`MoneyInput`/`MoneyInputProps` (barrel additions-only, 0 removed/renamed). Multi-word group titles are Title-Cased hyphen→space (`data-display` → `"Data Display"`). The apps-side effector-wired Pages were **re-sequenced to mx.5**. | ✅ ruled in `mx.4` (built 2026-06-29) |
| **D-11** | **mx.5 — effector-powered stories (surface frozen).** A host-home `Effector/<Adapter>` story for **all six** `@mercury/effector` adapters (`theme · toast · createForm · strength · createCooldown · formatter` — the roadmap row had lagged at four; canon §1 names six), each wiring the adapter's live Effector state (`effector-react` hooks; models at **module scope**, hooks in the render component) into the real `@mercury/ui` component(s) at the real prop surface. Stories live in the **host home** `apps/storybook/stories/effector/` (cross-component patterns, like `Tokens.stories.tsx`; preserves the mx.4 1:1 component↔story count) — **Arm B**; **one file per adapter** (six files) — **Arm C**; the Theme story **augments** (a local `${theme}-theme` wrapper, never `initTheme()`) rather than replacing the mx.3 toolbar decorator — **Arm A**. `sb:build` 36 → **42** homes. The **`@mercury/ui` public surface is frozen byte-identical** this rung (mx.4 grew it; mx.5 does not — the strongest form of the master invariant), and the host needed **zero** config edit (the effector dep/alias/path/glob/scripts were already present from mx.4). The **apps-side Pages** (the mandate carried from mx.4) were re-sequenced to **mx.6** (model: page-level `*.stories.tsx` in `apps/*/src/`; the five apps are being rewritten on Mercury DS, then retired; `economy` out of scope) and build/deploy + design-sync to **mx.7** — Operator-ruled. | ✅ ruled in `mx.5` (built 2026-06-29) |
| **D-12** | **mx.10 — the toolchain single-source + the vite 7 lift.** A pnpm **`catalog:`** block in `pnpm-workspace.yaml` (7 entries: `typescript ~5.9.3` — a **tilde**, TypeScript is not semver · `vite ^7` · `vitest ^4` · `react`/`react-dom ^19` · `jsdom ^26` · `@vitejs/plugin-react ^4.3.3`) single-sources the shared toolchain; every in-scope manifest (`packages/*` + `apps/*` + root — **NOT** `codemojex/**`, a sibling `/cm-ship` migrates it) references `"catalog:"` (**dev/direct deps only; peer ranges untouched**). Lifts **vite 6→7** (7.3.6; Fork A = the new `build.target` default, the 4 pre-existing `es2024` config pins kept) + **vitest 3→4** (4.1.9; the dual-major closed) + retires **`@testing-library/jest-dom`** (Operator-ruled fold-in: root devDep + `vitest.setup.ts` removed + `Button.test.tsx` → plain-DOM matchers). One lift-forced change: `@types/node` + `"node"` on `@mercury/core`'s tsconfig — vitest 4 severed the ambient `NodeJS` leak that had hidden a latent `NodeJS.Timeout` in `debounce.ts` (INV-7 forbade the `src` fix; the real dep declared instead). The `@mercury/ui` barrel is **byte-identical** — a dependency rung moves no export. | ✅ ruled in `mx.10` (built 2026-07-02) |

## Map

[`mercury.roadmap.md`](./mercury.roadmap.md) · [`mercury.progress.md`](./mercury.progress.md) ·
[`program/mercury.program.md`](./program/mercury.program.md) · the `mx.1` triad
[`specs/mx.1/mx.1.md`](./specs/mx.1/mx.1.md). Code:
[`../../mercury/packages`](../../mercury/packages).
