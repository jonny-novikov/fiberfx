# MX.4 — build context (for the implementor + the story-author waves)

Working notes for building [`mx.4.md`](./mx.4.md) — the 31 component stories + the focused-trio
enhancement. Root = `mercury/`. The body is authoritative; this file derives from it. **NO-INVENT:**
every `@mercury/ui` name cited here is a real barrel export; every path is real; every prop is verified
in the component's `.tsx` before a story uses it.

## Ground facts (re-probe before trusting)

- **Stack:** Vite **^6.0.0**, React **19**, Node **22.18**, pnpm **10.17.1**, TypeScript ^5.6.3.
  `tsconfig.base.json`: `target/lib ES2024`, `moduleResolution: "Bundler"`, `jsx: "react-jsx"`,
  `verbatimModuleSyntax: true` (so `import type` for types), `isolatedModules`, `strict` +
  `noUncheckedIndexedAccess`.
- **The host (mx.3, `D-9`):** `apps/storybook/` on Storybook **10.4.6** (`@storybook/react-vite`).
  Its `.storybook/main.ts` glob already spans `packages/mercury-ui/**/*.stories.@(tsx|ts)` — **every
  new co-located story is picked up with no host edit** (INV-6). The CSF3 import is
  `import type { Meta, StoryObj } from "@storybook/react-vite";` (see the exemplars).
- **The library `tsc` already excludes stories (mx.3 `D-9`/INV-8):**
  `packages/mercury-ui/tsconfig.json` excludes `**/*.stories.tsx` (`tsconfig.build.json` inherits it).
  **Do NOT touch any `tsconfig`** — the new stories (incl. the two new components') are already
  covered.
- **The exemplars to imitate exactly** (the shape, the NO-INVENT comments, the typed enum arrays):
  - `packages/mercury-ui/src/components/foundations/Icon/Icon.stories.tsx`
  - `packages/mercury-ui/src/components/actions/Button/Button.stories.tsx`
- **The contracts (the gating dependency — mx.2):** every component has a hand-authored
  `<group>/<Name>/<Name>.prompt.md`. Each story's controls are a *rendered restatement* of that
  contract; read the `.prompt.md` **and** verify the prop against the `.tsx` beside it (the `.tsx` is
  truth; the contract is the control language).
- **Theme:** the mx.3 decorator wraps every story in a `light-theme`/`dark-theme` ancestor and loads
  the `@mercury/ui` stylesheet; a story authors no theme wiring — it just renders the component.
- **The barrel** `packages/mercury-ui/src/index.ts` re-exports every component via `export * from
  "./components/<group>/<Name>"`. mx.4 adds **two** lines (ListRow, MoneyInput) — additive only.

## The file tree (what to create / edit)

```
# Stream A — 31 co-located stories (one per existing component without one):
packages/mercury-ui/src/components/actions/Link/Link.stories.tsx
packages/mercury-ui/src/components/foundations/Divider/Divider.stories.tsx
packages/mercury-ui/src/components/inputs/{Input,Textarea,Search,Select,AuthCode}/<Name>.stories.tsx
packages/mercury-ui/src/components/selection/{Checkbox,Radio,Switch,Segmented,Slider,Toggle}/<Name>.stories.tsx
packages/mercury-ui/src/components/feedback/{Alert,Progress,PasswordStrength}/<Name>.stories.tsx
packages/mercury-ui/src/components/data-display/{Chip,Tag,Badge,Avatar,Card,Table,Stat,Chart,Checklist}/<Name>.stories.tsx
packages/mercury-ui/src/components/navigation/{Tabs,Accordion,Pagination}/<Name>.stories.tsx
packages/mercury-ui/src/components/overlay/{Modal,Tooltip}/<Name>.stories.tsx
packages/mercury-ui/src/components/layout/AuthLayout/AuthLayout.stories.tsx

# Stream C — two new components (full package) + Card edit:
packages/mercury-ui/src/components/data-display/ListRow/{ListRow.tsx,index.ts,ListRow.prompt.md,ListRow.stories.tsx}
packages/mercury-ui/src/components/inputs/MoneyInput/{MoneyInput.tsx,index.ts,MoneyInput.prompt.md,MoneyInput.stories.tsx}
packages/mercury-ui/src/components/data-display/Card/Card.tsx          # + title/actions props
packages/mercury-ui/src/components/data-display/Card/Card.prompt.md    # + the two new props
packages/mercury-ui/src/components/data-display/Card/Card.stories.tsx  # + a header story (Stream A's Card story)

# Wiring:
packages/mercury-ui/src/index.ts        # + 2 additive `export *` lines (ListRow, MoneyInput)
packages/mercury-ui/src/styles/         # + .mx-card__header/.mx-card__title, .mx-listrow*, .mx-money* (mercury.css or additions.css)
```

No host edit, no app edit, no `tsconfig` edit, no apps-side story (mx.5).

## The story-shape recipe (two classes — pick per component)

Both classes follow the exemplars: `import type { Meta, StoryObj } from "@storybook/react-vite";`, a
typed `meta` with `title: "<Group>/<Name>"` + `component`, a `Playground: Story = {}` (args-driven),
and ≥1 extra story. **Type every enum option array by the component's exported union** so an invented
member fails to compile (the Button/Icon pattern: `const TONES: AlertTone[] = [...]`).

### Class 1 — enum / boolean component (controls-driven Playground + a grid)

For components whose surface is enum/boolean props with no required structured data:
`Link · Divider · Input · Textarea · Search · AuthCode · Checkbox · Radio · Switch · Toggle · Alert ·
Progress · PasswordStrength · Chip · Tag · Badge · Avatar · Card · Modal · Tooltip · AuthLayout ·
MoneyInput`.

- `argTypes`: a `select`/`inline-radio` for each enum prop (options = the typed union array);
  `boolean` for each boolean prop; **`control: false`** for `leading`/`trailing`/ReactNode slots
  (drive them with a story arg rendering a real `<Icon/>` — never a raw control).
- Stories: `Playground` (args) + a grid story iterating the enum (e.g. `Tones`/`Variants`/`Sizes`/
  `States`) — the Button `Variants` (six × three) shape.
- Overlay note (Modal/Tooltip): render with a trigger + open state in the story's `render` (these are
  not pure args-driven); ground the open/close props in the `.tsx`.

### Class 2 — data-prop component (a `render` story with real sample data)

For components that require structured data props, author a `render`-based story whose sample data is
**grounded in a real app call site (cited in a trailing comment)** and shaped to the prop type
(typed by the component's exported data type). Plus a `Playground` where an args-driven view is
meaningful.

| Component | Data prop(s) (verify the exact name/type in the `.tsx`) | Ground the sample data in |
|---|---|---|
| `Select` | options array (`SelectOption[]`) | `codemojex-node/apps/economy/src/components/CalibrationForm.tsx` (CalibrateView) |
| `Segmented` | `segments` (`Segment[]`) + `value`/`onChange` | `apps/showcase` Topbar/Dashboard + economy `RevenueFlow.tsx` |
| `Slider` | `value`/`onChange` (+ min/max/step) | economy `CalibrationForm.tsx` (CalibrateView) |
| `Table` | `columns` (`Column[]`) + `data` + `getRowKey` | economy `RailPanel`/`SplitLadderTable`/`MarginTable`/`PrizePoolTable` + showcase `TablePage` |
| `Stat` | label/value (+ `tone: StatTone`) | economy `KpiRow`/`BalanceSimPanel` |
| `Chart` | `series` (`ChartSeries[]`) + `viewBox`/`markers` (`ChartMarker[]`) | economy `HousePctCurve`/`PoolGrowthCurve`/`MarginCurve` |
| `Checklist` | `items` (`ChecklistItem[]`) | showcase (verify a call site; else source-ground + say so) |
| `Tabs` | `tabs` (`Tab[]`) + active state | showcase `TabsPage` + economy |
| `Accordion` | `items` (`AccordionItemData[]`) | **no app call site** — ground in `Accordion.tsx`; say so |
| `Pagination` | page/total/onChange | **no app call site** — ground in `Pagination.tsx`; say so |
| `ListRow` (new) | `label`/`leading`/`description`/`value`/`trailing`/`onClick` | mobile `chrome/Row.tsx` + `chrome/ActivityList.tsx` |

**No-call-site components** (`Accordion · Pagination · Search · Textarea · Toggle`): ground the story
in the component's `.tsx` and add the comment `// source-grounded; no app call site` (the same line the
contracts use).

> **Verify the exact data type names against the `.tsx`/barrel before typing an array** — the inventory
> names (`SelectOption`, `Segment`, `Column`, `StatTone`, `ChartSeries`/`ChartMarker`, `ChecklistItem`,
> `Tab`, `AccordionItemData`, `AlertTone`, `ProgressVariant`, `StrengthVariant`, `ChipVariant`,
> `BadgeVariant`, `AvatarStatus`, `LinkSize`, `ToggleSize`/`ToggleGroupType`/`ToggleGroupItem`) are the
> map; the `.tsx` is truth. An import of a non-exported type is a compile error — that is the guard.

## The enhancement build (Stream C — the implementor, before the story waves)

### Card — additive `title`/`actions` (no new export name)

`CardProps` (extends `HTMLAttributes<HTMLDivElement>`) gains `title?: ReactNode` + `actions?:
ReactNode`. Render a header row **only when** `title || actions`:

```
[ <.mx-card__title>{title}</…>            {actions} ]   <- .mx-card__header: flex, space-between, center
  {children}
```

- Absent `title` && absent `actions` ⇒ render exactly today's output (back-compat — existing call
  sites byte-identical; verify against `Card.tsx`).
- Style: add `.mx-card__header` (`display:flex; justify-content:space-between; align-items:center`) +
  `.mx-card__title` (the `--fg-tertiary` uppercase label, mirroring economy `.ecn-card-title`) to
  `styles/` — `rgb(var(--token))` only, no raw hex.
- `Card.prompt.md`: document the two new props in the `## Props` table + a header `## Examples`
  snippet. `Card.stories.tsx` (Stream A's Card story): add a `WithHeader` story passing `title` +
  `actions={<Segmented .../>}` or a `<Button/>`.

### ListRow (new, `data-display`) and MoneyInput (new, `inputs`)

Build the `.tsx` to the §6 prop tables in `mx.4.md` (re-read them — they are the target shape). Then:
`index.ts` = `export * from "./<Name>";`; the `.mx-*` styles in `styles/`; the **barrel** export
(below); the co-located story (Class 1 shape — MoneyInput is enum/boolean+slots; ListRow is data-prop,
ground its story in the mobile chrome). The **hand-authored** `<Name>.prompt.md` is authored against
the *built* `.tsx` (`D-7`, the six-section shape from [`../../contracts.md`](../../contracts.md)) —
grounded in the `.tsx` + the cited app call site + cross-linked siblings (e.g. ListRow composes
Icon/Avatar; MoneyInput composes/relates to Input).

- **ListRow** — interactive `<button>` when `onClick` is set, else a non-interactive container; the
  React-19 nullable-ref idiom does not apply (no ref needed unless `forwardRef` is added for parity).
- **MoneyInput** — the cleanest path composes `Input` via its `leading` slot for the `currency` prefix
  and defaults the inner `inputMode="decimal"`; standalone is also fine (implementor's latitude).
  Mirror `InputProps`' `Omit<InputHTMLAttributes<HTMLInputElement>, "size">` extension for native-attr
  pass-through.

### The barrel growth (additive — the only `index.ts` edit)

Add (placed in the group order the barrel already uses):

```ts
// data-display group:
export * from "./components/data-display/ListRow";
// inputs group:
export * from "./components/inputs/MoneyInput";
```

That is the whole `index.ts` change. New export names resolved: `ListRow`, `ListRowProps`,
`MoneyInput`, `MoneyInputProps`. Nothing removed/renamed.

## The wave plan (Stream A — the Director gates each wave)

The implementor lands Stream C first (the two new components + the barrel + Card props). Then the
story fan-out runs in waves, **≤2 heavy story-authors concurrent** (the AAW cadence), each scoped to
one or two groups, reading the exemplars + the group's `.prompt.md`/`.tsx`:

- **Wave 1:** `actions/Link`, `foundations/Divider`, `inputs/{Input,Textarea,Search,Select,AuthCode}`.
- **Wave 2:** `selection/{Checkbox,Radio,Switch,Segmented,Slider,Toggle}`,
  `feedback/{Alert,Progress,PasswordStrength}`.
- **Wave 3:** `data-display/{Chip,Tag,Badge,Avatar,Card,Table,Stat,Chart,Checklist}` (+ the two new
  components' stories if not landed with their `.tsx`).
- **Wave 4:** `navigation/{Tabs,Accordion,Pagination}`, `overlay/{Modal,Tooltip}`, `layout/AuthLayout`.

The Director reconciles + gates each wave (coverage count, the NO-INVENT grep below, the undisturbed
build) before the next.

## The gate (from `mercury/`)

**Per-rung ladder (storybook EXCLUDED so it stays fast):**

```bash
pnpm --filter "./packages/*" typecheck                              # 3 packages clean
pnpm --filter "./packages/*" build                                  # 3 packages build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build       # the FIVE product apps only
# ADDITIONS-ONLY barrel-diff — only added lines, 0 removed/renamed:
diff <(git show HEAD:packages/mercury-ui/src/index.ts | grep -oE 'export .*') \
     <(grep -oE 'export .*' packages/mercury-ui/src/index.ts)
# expect: only the two new `export *` lines added (`>` lines); NO removed (`<`) line.
# authoritative when unsure: resolve the export set (getExportsOfModule / dist/index.d.ts) —
# the 4 new names present (ListRow/ListRowProps/MoneyInput/MoneyInputProps), nothing removed.
```

**Coverage + Storybook smoke (the Director runs at SHIP):**

```bash
# coverage: one story per component folder (expect 35 == folder count):
find packages/mercury-ui/src/components -name '*.stories.tsx' | wc -l   # 35
find packages/mercury-ui/src/components -mindepth 2 -maxdepth 2 -type d | wc -l   # 35
# NO-INVENT grep — must be EMPTY:
grep -rn "window.MercuryUI\|_ds_bundle" packages/mercury-ui/src/components --include='*.stories.tsx'
# the static build registers all 36 story homes (35 component + host Tokens):
pnpm sb:build       # ≡ pnpm --filter @mercury/storybook build → apps/storybook/storybook-static/, exit 0
```

## Gotchas

- **The barrel-diff is ADDITIONS-ONLY this rung** — mx.3's was byte-identical; mx.4 legitimately adds
  two `export *` lines. The check is "0 removed/renamed", not "no change". Reading it as a hard
  byte-diff is a false fail.
- **Type every enum option array by the exported union** (`const X: TName[] = [...]`) — that is the
  compile-time NO-INVENT guard. A non-exported type import or an invented member fails `tsc`.
- **Slots are story args, not raw controls** — `leading`/`trailing`/ReactNode get `control: false` and
  are driven by a story arg rendering a real `<Icon/>` (the Button exemplar). A raw ReactNode control
  is meaningless in the UI.
- **Verify props against the live `.tsx`** (truth) **and** the `.prompt.md` (the control language) —
  not a stale memory or the `ds-bundle/` seed. Card has no `tone`; Input's `leading`/`trailing` are
  slots, not enums; data types differ per component.
- **No host/`tsconfig`/app edit** — the mx.3 glob + stories-exclude already hold (INV-3/INV-6). If a
  story needs a host change, STOP — that is out of scope.
- **The two new components ship the FULL package** (INV-7): `.tsx` · `index.ts` · hand-authored
  `.prompt.md` · barrel export · story · `.mx-*` styles. A `.tsx` whose prop set drifts from its
  `.prompt.md` is a reconcile delta.
- **Token discipline** — new styles use `rgb(var(--token))` + the canon §6 families; never a raw hex,
  never a utility class. The `.mx-*` classes are private.
- **Commit only when asked, pathspec only.** Everything is under `mercury/packages/mercury-ui/` (+ the
  rung's `docs/mercury/specs/mx.4/`); re-verify `git diff --cached --name-only` is purely the mx.4
  surface before any commit. Never `git add -A`; never `pnpm -r`.
- **Framing (propagate):** no gendered pronouns for agents; no perceptual/interior-state verbs; no
  first-person narration. State each surface as a contract.
