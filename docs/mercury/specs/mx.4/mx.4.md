# MX.4 · Component stories + the focused-trio enhancement

> **Status: ✅ BUILT — gate-green 2026-06-29 (shipped via `/mercury-ship mx.4`).** The second rung of **Movement III (the Design System Storybook)**.
> mx.3 landed the **host** (`apps/storybook/`, Storybook 10.4.6, source-resolved, a light/`dark-theme`
> decorator) and proved it against **three foundation stories** (Icon · tokens · Button). mx.4 fills the
> library side of the host's glob: a co-located `<Name>.stories.tsx` for **every remaining component**
> (31 of 33) plus an **additive `@mercury/ui` enhancement** — the "focused trio" (Card header props · a
> new `ListRow` · a new `MoneyInput`) — that grows the library to cover controls/cases the real app
> screens hand-roll today. The apps-side effector-wired **Pages are DEFERRED to mx.5** (§6).
>
> **Risk: NORMAL — but barrel-touching (additive only).** Stream A (the 31 stories) is fully additive
> and perturbs no export. Stream C **grows** the barrel: two new components add the export names
> `ListRow`/`ListRowProps` and `MoneyInput`/`MoneyInputProps`; Card gains optional props but **no new
> export name**. Under the master invariant additions are allowed and removals/renames are not, so the
> barrel-diff is an **additions-only** check (0 removed/renamed; the new names enumerated EXACTLY). The
> load-bearing hazards: (a) a story citing a prop the `.tsx` does not define, or an extractor runtime
> framing (`window.MercuryUI`/`_ds_bundle`) — NO-INVENT, caught by the contract/source trace; (b) a
> new component's co-located story re-entering the `@mercury/ui` library `tsc` — already held by the
> mx.3 `**/*.stories.tsx` exclude (`D-9`); (c) the barrel-diff read as a hard byte-diff and tripping on
> the legitimate new `export *` lines — it must be an additions-only check.
>
> **The decisions this rung carries (Operator-ruled — recorded for ratification at ship):** mx.4 is
> **Stream A (the 31 component stories) + Stream C (the focused-trio enhancement)**; the apps-side
> Pages + the effector-wired stories are **mx.5**, not this rung. The two new components are the only
> new public surface; both ship additively with the full component package (`.tsx` · `index.ts` ·
> hand-authored `<Name>.prompt.md` · barrel export · co-located `.stories.tsx` · any `.mx-*` styles).
> **Group placement** — `ListRow → data-display`, `MoneyInput → inputs` — is a placement judgment
> (`D-4` class), **proposed** here and **Director-ratifiable**, not a correctness claim (§6).
>
> **As-built (2026-06-29, BUILD-GRADE).** Shipped via `/mercury-ship mx.4` (Director-led: venus → mars-1
> build → Director verify → mars-2 harden → Apollo evaluator post-build reconcile). **Coverage:** the
> 31 remaining components each gained a co-located CSF3 `<Name>.stories.tsx`, so all **35** component
> folders now carry **exactly one** story (`count(*.stories.tsx) == count(folders) == 35`); `pnpm
> sb:build` exits 0 and registers **36** distinct story homes (the 35 component stories + the host-local
> `Foundations/Tokens`), with the **data-display** group unified to **10** (Avatar · Badge · Card ·
> Chart · Checklist · Chip · ListRow · Stat · Table · Tag). **The trio's final shapes:** `Card` gained
> optional `title?: ReactNode` + `actions?: ReactNode` — `CardProps` now `extends Omit<HTMLAttributes<
> HTMLDivElement>, "title">` (the native string `title` attr is dropped so the header prop can be a
> `ReactNode`; **no app call site used the native `title=`**, so back-compat holds), rendering a
> `.mx-card__header` row (`.mx-card__title` left, `.mx-card__actions` right, `space-between` +
> `margin-left:auto`) **only when** `title != null || actions != null` — absent ⇒ byte-identical output,
> **no new export name**. `ListRow` (group `data-display`) ships `label` (required) · `leading?` ·
> `description?` · `value?` · `trailing?` · `onClick?`, a **polymorphic root** — `<button type="button">`
> when `onClick` is set, else a `<div>` — and is a plain function component (no `forwardRef`, since one
> ref type cannot address both roots), `Omit<HTMLAttributes<HTMLElement>, "onClick">` rest, `.mx-listrow*`
> styles. `MoneyInput` (group `inputs`) **composes `Input`** via its `leading` slot — `currency?` (default
> `"$"`) · `label?`/`hint?`/`error?` (inherited from `Input`) · `inputMode` defaulting `"decimal"` ·
> `forwardRef` to the inner `<input>`, `Omit<InputHTMLAttributes<HTMLInputElement>, "size">` rest,
> `.mx-money__ccy` affix. Both ship the full additive package (`.tsx` · `index.ts` · hand-authored D-7
> six-section `.prompt.md` grounded in the `.tsx` + cited real call sites · barrel export · co-located
> story · token-only `.mx-*` styles). **The barrel grew additively** — exactly the two new `export *`
> lines → the four new names `ListRow`/`ListRowProps`/`MoneyInput`/`MoneyInputProps`; **0 removed/renamed**
> (source-resolved export set = 97). **The gate addition the harden pass found:** a new root `package.json`
> `sb:typecheck` script (`pnpm --filter @mercury/storybook typecheck`) — the authoritative compile-time
> NO-INVENT enforcement, since the library `tsc` excludes `**/*.stories.tsx` (mx.3 `D-9`), the stories
> are only type-checked by the host's `tsc`. Gate green (Apollo independent re-run): `sb:typecheck` 0 ·
> `@mercury/ui typecheck` 0 · `pnpm sb:build` exit 0 / 36 homes · the **additions-only** barrel-diff
> (only the two `export *` lines, 0 removed) · token-discipline + `window.MercuryUI`/`_ds_bundle` greps
> empty · every story imports only `@mercury/ui` (+ `react`/`@storybook/react-vite`). **Open (Director,
> at commit):** the working-tree `vitest.config.ts` adds a `packages/*/src/**/*.test.{ts,tsx}` include
> glob that currently matches **zero** files (inert) — outside the stated mx.4 surface; decide include vs.
> revert in the pathspec.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · roadmap:
[`../../mercury.roadmap.md`](../../mercury.roadmap.md) · dashboard:
[`../../mercury.progress.md`](../../mercury.progress.md) · prior triad:
[`../mx.3/mx.3.md`](../mx.3/mx.3.md) · contract template:
[`../../contracts.md`](../../contracts.md) · method:
[`../../../aaw/aaw.framework.md`](../../../aaw/aaw.framework.md) · acceptance:
[`mx.4.stories.md`](./mx.4.stories.md) · build context: [`mx.4.llms.md`](./mx.4.llms.md).

## 0 · The slice — what mx.4 builds, and why stories + a focused enhancement together

Movement III's destination is a per-component Design System Storybook (roadmap §The movements). mx.3
proved the host renders the library from source under a theme decorator, with three foundation stories
as the exemplar shape. mx.4 is the **fan-out plus the first additive growth**:

- **Stream A — the 31 component stories.** A co-located `<group>/<Name>/<Name>.stories.tsx` for every
  component that does not yet have one (33 components, 2 done in mx.3 → 31 remaining). Each story is a
  **rendered restatement of the component's `<Name>.prompt.md`** (the hand-authored contract mx.2
  fixed): typed enum const-arrays, a `Playground` (args-driven) story, and at least one
  grid/states/variant story — the exact shape the Icon/Button exemplars set. For a **data-prop**
  component (Select, Segmented, Slider, Table, Stat, Chart, Checklist, Tabs, Accordion, Pagination,
  and the new ListRow), a `render`-based story carries realistic sample data **grounded in a real app
  call site** (cited).
- **Stream C — the focused-trio enhancement.** The mx.3 forward mandate is *"mx.4 ENHANCES
  `@mercury/ui` additively to cover more controls, more cases, and more pages those screens need."*
  Three additive surfaces, each grounded in a recurring hand-rolled app pattern: **Card header props**
  (`title`/`actions` — the card-header row the economy panels rebuild 5+ times), **`ListRow`** (the
  mobile settings/activity row), and **`MoneyInput`** (the mobile currency-amount field). Each ships
  with its own story, so the host stays 1:1.

What mx.4 is **not**: it adds **no app-screen story** and **no apps-side Page** — those are mx.5 (the
effector-wired apps fan-out). The host glob already spans `apps/**/*.stories.tsx` (mx.3 INV-6); mx.4
leaves that side empty.

## 1 · Goal

After mx.4, **every component in `@mercury/ui` has a co-located CSF3 story** and the host renders all
of them under the mx.3 theme decorator. Concretely: the 31 remaining existing components each gain a
`<group>/<Name>/<Name>.stories.tsx` whose controls restate the component's `<Name>.prompt.md`; two new
components — **`ListRow`** (group `data-display`) and **`MoneyInput`** (group `inputs`) — ship the full
additive component package (`.tsx` · `index.ts` · hand-authored `.prompt.md` · barrel export ·
co-located `.stories.tsx` · `.mx-*` styles); and **`Card`** gains additive optional `title`/`actions`
props (header row) with its contract + story updated. The `@mercury/ui` barrel **grows additively** —
the new export names are **exactly** `ListRow`, `ListRowProps`, `MoneyInput`, `MoneyInputProps`; **0
removed/renamed**; Card adds no export name. `pnpm sb:build` registers **every** component's story (35
component story homes + the host `Foundations/Tokens` story = **36** story homes) and exits 0. The
five product apps + the three packages still build; the host needs no `.storybook/` edit (the mx.3
glob already covers `packages/mercury-ui/**/*.stories.tsx`). **No component behavior regresses; no
export is removed or renamed; the master invariant holds (additively).**

## 2 · Rationale (5W)

- **Why.** A Storybook is only as trustworthy as its coverage — a host with three stories proves the
  wiring; a host with a story per component is the actual deliverable a human or design/coding agent
  browses. Pairing the fan-out with the **first additive enhancement** discharges the mx.3 forward
  mandate at the same time the stories reveal the gaps: the economy panels and the mobile screens
  hand-roll a card header, a list row, and a money field that belong in `@mercury/ui`. Landing those
  three additively (under the master invariant) turns three app-local patterns into library surface,
  and each new component's story keeps the host 1:1.
- **What.** (Stream A) 31 co-located `<Name>.stories.tsx`, CSF3, controls a rendered restatement of
  each `<Name>.prompt.md`; data-prop stories carry real-call-site sample data. (Stream C) the Card
  `title`/`actions` additive props + a new `ListRow` + a new `MoneyInput`, each with the full
  component package and a story; the barrel grows by exactly four export names.
- **Who.** *Authored by* Claude Code as Director-led architect (this triad) + the implementor (the
  enhancement components) + the story-author waves (the 31 + 2 stories). *Consumed by* — (1) Mercury
  contributors and the Claude Design agent browsing the library; (2) the mobile/economy apps, which
  in a later rung swap their hand-rolled card-header / row / money-field for the new surfaces;
  (3) **mx.5** (the apps-side Pages + effector-wired stories), which inherit the now-complete
  component coverage; (4) any AAW implementor verifying a component visually.
- **When.** Now — the second rung of Movement III, hard-gating on **mx.3** (the host + glob +
  decorator — met) and **mx.2** (the 33 contracts each story restates — met). It unblocks **mx.5**
  (the effector-wired apps-side Pages) and **mx.6** (build/deploy + the `.design-sync` re-align).
- **Where.** New stories: `packages/mercury-ui/src/components/<group>/<Name>/<Name>.stories.tsx` for
  the 31 remaining components + the 2 new ones. New components:
  `packages/mercury-ui/src/components/data-display/ListRow/**` and
  `packages/mercury-ui/src/components/inputs/MoneyInput/**`. Edited:
  `packages/mercury-ui/src/components/data-display/Card/Card.tsx` (+ its `.prompt.md` + `.stories.tsx`),
  `packages/mercury-ui/src/index.ts` (two additive `export *` lines), and
  `packages/mercury-ui/src/styles/` (the card-header + ListRow + MoneyInput `.mx-*` rules). **No host
  edit; no app edit; no `tsconfig`/gate edit** (the mx.3 stories-exclude + glob already hold).

## 3 · Invariants (runnable checks)

- **INV-1 · The barrel grows additively (additions-only).** The `@mercury/ui` export-name set after
  mx.4 is a **superset** of the set before, with **0 removed/renamed**. The **new** names are
  **exactly** `ListRow`, `ListRowProps`, `MoneyInput`, `MoneyInputProps` (Card adds optional props, so
  `CardProps` gains members but **no new export name**; stories add no export). Mechanical: the
  first-line check
  `diff <(git show HEAD:packages/mercury-ui/src/index.ts | grep -oE 'export .*') <(grep -oE 'export .*' packages/mercury-ui/src/index.ts)`
  shows **only added lines** (the two new `export *` lines), no deletions; the authoritative resolved
  export set (TS `getExportsOfModule` / `dist/index.d.ts`) shows the four new names and nothing
  removed. **This is an additions-only diff, never a byte-identical diff** (mx.3's was byte-identical;
  mx.4's is not).
- **INV-2 · The five product apps + the three packages still build.** `pnpm --filter "./packages/*"
  typecheck` and `pnpm --filter "./packages/*" build` exit 0; the **five** product apps build via
  `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` (exit 0). The two new components and
  the Card props are presentational and additive — no consumer breaks.
- **INV-3 · The library gate is undisturbed by the co-located stories.** `pnpm --filter @mercury/ui
  typecheck` and `build` exit 0 because `packages/mercury-ui/tsconfig.json` already excludes
  `**/*.stories.tsx` (mx.3 `D-9`/INV-8; `tsconfig.build.json` inherits it). mx.4 adds **no**
  `tsconfig`/gate edit — the exclude + the host glob from mx.3 already cover every new story.
- **INV-4 · `sb:build` registers every component's story (coverage, not a magic number).** Every
  component folder under `packages/mercury-ui/src/components/<group>/<Name>/` has exactly one
  `<Name>.stories.tsx` — i.e. `count(*.stories.tsx) == count(component folders) == 35` (33 existing +
  ListRow + MoneyInput). `pnpm sb:build` exits 0 and registers **36** story homes: the 35 component
  stories (31 authored this rung + Button + Icon from mx.3 + ListRow + MoneyInput) **plus** the
  host-local `Foundations/Tokens` story. No host edit is required (INV-6).
- **INV-5 · Stories are grounded in the contract/source, not invented.** Each story's
  `argTypes`/controls restate the component's `<Name>.prompt.md` (and the `.tsx` it grounds): every
  control name + its option set appears in both; enum option arrays are typed by the component's
  exported union (e.g. `const TONES: AlertTone[] = [...]`) so an invented member is a compile error.
  A **data-prop** story's sample data is a usage that exists at the **cited** real call site
  (`apps/showcase` or `codemojex-node/apps/economy`); a component with **no** app call site
  (Accordion · Pagination · Search · Textarea · Toggle) is grounded in its `.tsx` and **says so** in a
  comment. `leading`/`trailing`/ReactNode slots are driven by a story arg rendering a real `<Icon/>`,
  **never a raw control** (the Button exemplar). No story contains `window.MercuryUI` or `_ds_bundle`,
  and no story uses a prop the source does not define.
- **INV-6 · The host needs no edit.** mx.3's `.storybook/main.ts` glob already spans
  `packages/mercury-ui/**/*.stories.@(tsx|ts)`; every new co-located story (incl. the two new
  components) is matched automatically. `git diff` touches **no** file under `apps/storybook/`.
- **INV-7 · Each new surface ships the full additive component package.** `ListRow` and `MoneyInput`
  each have: `<Name>.tsx` (`forwardRef` where a ref is meaningful, HTML-attr extension, `.mx-*`
  className styling, token-only) · `index.ts` (`export * from "./<Name>"`) · a **hand-authored**
  `<Name>.prompt.md` (`D-7`, the six-section shape, grounded in the `.tsx` + the cited app call site +
  cross-linked siblings) · a barrel export in `src/index.ts` · a co-located `<Name>.stories.tsx` · any
  `.mx-*` rule in `src/styles/`. `Card` ships the additive `title`/`actions` props + an updated
  `Card.prompt.md` (the new props documented) + an updated `Card.stories.tsx` (a header story).
- **INV-8 · Token discipline on the new surfaces.** The new components and the card-header style
  through the canon §6 vocabulary — `rgb(var(--token))` for layout, the status/surface/border families
  for color, the type ramp for text — **never a raw hex/RGB** and **never a utility class**; the
  private `.mx-*` classes carry the recipe. Observable: under the mx.3 `dark-theme` decorator a
  `ListRow`/`MoneyInput`/`Card`-header story flips dark with the tokens.
- **INV-9 · Scope discipline.** The rung touches only: the 31 + 2 new `<Name>.stories.tsx`; the two
  new component folders (`data-display/ListRow/**`, `inputs/MoneyInput/**`); `Card.tsx` +
  `Card.prompt.md` + `Card.stories.tsx`; `packages/mercury-ui/src/index.ts` (two additive `export *`
  lines); and `packages/mercury-ui/src/styles/` (the new `.mx-*` rules). **No** host edit, **no** app
  edit, **no** `tsconfig`/gate edit, **no** app-screen story, **no** apps-side Page (mx.5). Everything
  stays inside `mercury/packages/mercury-ui/`.

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | **Stream A — the 31 component stories.** A co-located `<group>/<Name>/<Name>.stories.tsx` (CSF3) for every component without one: `actions/Link` · `foundations/Divider` · `inputs/{Input,Textarea,Search,Select,AuthCode}` · `selection/{Checkbox,Radio,Switch,Segmented,Slider,Toggle}` · `feedback/{Alert,Progress,PasswordStrength}` · `data-display/{Chip,Tag,Badge,Avatar,Card,Table,Stat,Chart,Checklist}` · `navigation/{Tabs,Accordion,Pagination}` · `overlay/{Modal,Tooltip}` · `layout/AuthLayout`. Each: typed enum const-arrays + a `Playground` story + ≥1 grid/states/variant story; controls restate the `<Name>.prompt.md`. | INV-4 + INV-5; each control/option traces to the contract + `.tsx`; the story registers and renders |
| K-2 | **Data-prop story grounding.** For Select · Segmented · Slider · Table · Stat · Chart · Checklist · Tabs · Accordion · Pagination · ListRow, a `render`-based story with realistic sample data **grounded in a real app call site** (cited per the §llms map); a no-call-site component (Accordion · Pagination · Search · Textarea · Toggle) is grounded in source and says so. | INV-5; every data shape matches the prop type; the cited call site exists |
| K-3 | **Stream C.1 — Card header props (additive).** `Card` gains optional `title?: ReactNode` + `actions?: ReactNode` rendering a header row (title left, actions right; `justify:space-between, align:center`) above `children`; absent ⇒ no header (back-compat). `Card.prompt.md` + `Card.stories.tsx` updated; a `.mx-card__header`/`.mx-card__title` style added. | INV-1 (no new export) + INV-7 + INV-8; existing Cards unchanged; a header story renders |
| K-4 | **Stream C.2 — `ListRow` (new component, group `data-display`).** `<Name>.tsx` + `index.ts` + hand-authored `.prompt.md` + barrel export + co-located `.stories.tsx` + `.mx-*` styles. A horizontal item row: `leading?` · `label` · `description?` · `value?` · `trailing?` · optional `onClick`. | INV-1 (exports `ListRow`/`ListRowProps`) + INV-5 + INV-7 + INV-8; the row renders the mobile settings/activity shape |
| K-5 | **Stream C.3 — `MoneyInput` (new component, group `inputs`).** `<Name>.tsx` + `index.ts` + hand-authored `.prompt.md` + barrel export + co-located `.stories.tsx` + `.mx-*` styles. A currency-amount field: a `currency` prefix + decimal entry + `label`/`hint`/`error` like `Input`, controlled `value`/`onChange`. | INV-1 (exports `MoneyInput`/`MoneyInputProps`) + INV-5 + INV-7 + INV-8; the field renders the Send-screen amount shape |
| K-6 | **The additive barrel + the coverage smoke.** `src/index.ts` grows by exactly two `export *` lines (four new names); the additions-only barrel-diff shows 0 removed/renamed; `pnpm sb:build` registers all 36 story homes (exit 0); the five product apps + three packages build. | INV-1 + INV-2 + INV-3 + INV-4 + INV-6; the gate (§llms) is green |

## 5 · The method (build order)

A small DAG: the enhancement components land first (they create new story homes); the story fan-out
follows in waves; the barrel + gate close it.

1. **Stream C first — the three additive surfaces** (the implementor):
   - **Card header props.** Add optional `title`/`actions` to `CardProps`; render a `.mx-card__header`
     row (title left via `.mx-card__title`, `actions` right) **only when** `title || actions`; keep
     `children` below. Existing call sites (no `title`/`actions`) render byte-identically. Add the
     `.mx-card__header`/`.mx-card__title` rule to `styles/` (`rgb(var(--token))` only). Update
     `Card.prompt.md` (the two new props) + `Card.stories.tsx` (a header story).
   - **`ListRow`.** New folder `data-display/ListRow/`: `ListRow.tsx` (the prop shape in §6 below;
     interactive `<button>` when `onClick`, else a `<div>`), `index.ts`, the `.mx-listrow*` styles,
     then the barrel export. (The hand-authored `.prompt.md` is authored against the built source.)
   - **`MoneyInput`.** New folder `inputs/MoneyInput/`: `MoneyInput.tsx` (the prop shape in §6 below;
     a currency prefix + `inputMode="decimal"` numeric entry + `label`/`hint`/`error` like `Input` —
     composing `Input` via its `leading` slot is the suggested path, implementor's latitude),
     `index.ts`, the `.mx-money*` styles (or reuse the `.mx-in*` recipe), then the barrel export.
2. **The barrel grows additively.** Add `export * from "./components/data-display/ListRow";` and
   `export * from "./components/inputs/MoneyInput";` — the only two new `export *` lines. Run the
   additions-only barrel-diff (0 removed/renamed; the four new names present).
3. **Stream A — the story fan-out, in waves (≤2 heavy story-authors concurrent).** Each author is
   scoped to one or two groups, reads the Icon/Button exemplars + the group's `<Name>.prompt.md` + the
   `.tsx`, and emits CSF3 stories per the §llms recipe (enum class vs data-prop class). The Director
   reconciles + gates each wave (coverage count, the NO-INVENT grep, the undisturbed build) before the
   next. The two new components' stories (ListRow, MoneyInput) land with their components or in the
   same wave.
4. **Gate + smoke.** Run the per-rung ladder (packages typecheck/build + the five product apps build
   with the storybook exclusion + the **additions-only** barrel-diff), then the separate `pnpm
   sb:build` coverage smoke (36 story homes, exit 0). All green.

Grounding sources (re-probe before trusting, per [`mx.4.llms.md`](./mx.4.llms.md)): the Icon/Button
exemplar stories; each component's `<Name>.prompt.md` + `.tsx`; the Card/Input source; the cited app
call sites (the economy `*Curve`/`*Panel`/`*Table` + `KpiRow` + `CalibrationForm`, the showcase
`TablePage`/`TabsPage`/`Topbar`/`DashboardPage`, the mobile `chrome/Row`/`chrome/ActivityList`/
`screens/Send`).

## 6 · The enhancement contract shapes (proposed — mars authors the `.prompt.md` against the built source)

These are the **target prop shapes** for the Director and the implementor; the hand-authored
`<Name>.prompt.md` is written by the implementor against the *built* `.tsx` (`D-7`), not copied from
here. Grounded in the live source cited.

### Card — additive header props (no new export name)

Add to `CardProps` (extends `HTMLAttributes<HTMLDivElement>`):

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | `ReactNode` | — | When present, renders a header row above `children`. Left-aligned. Absent ⇒ no header (back-compat). |
| `actions` | `ReactNode` | — | Right-aligned slot in the header row (`justify:space-between, align:center`). Renders the header even if `title` is absent. |

Grounding (the recurring hand-rolled pattern this absorbs): the economy card headers —
`MarginCurve.tsx:10` and `RevenueFlow.tsx:17` wrap `<p className="ecn-card-title">` (title, left) + a
legend/`<Segmented/>` (actions, right) in a `display:flex; justify-content:space-between` div; the same
shape recurs in `BalanceSimPanel`, `PrizePoolTable`, `MarginTable`, `RailPanel`, `SplitLadderTable`,
`HousePctCurve`, `PoolGrowthCurve` (the `.ecn-card-title` class,
`codemojex-node/apps/economy/src/economy.css:61`).

### `ListRow` (new, group `data-display`) — exports `ListRow`, `ListRowProps`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | `ReactNode` | — *(required)* | The primary text. |
| `leading` | `ReactNode` | — | A leading glyph/avatar slot — drive with a real `<Icon/>`/`<Avatar/>`. |
| `description` | `ReactNode` | — | Secondary text below `label` (the "meta"/subtitle). |
| `value` | `ReactNode` | — | Trailing value text (right-aligned) — e.g. a settings value or an amount. |
| `trailing` | `ReactNode` | — | A trailing affordance after `value` (a chevron/action). |
| `onClick` | `(e) => void` | — | When present, the row is interactive (rendered as a `<button>`); else a non-interactive container. |
| …rest | `HTMLAttributes` | — | Native attrs pass through. |

Grounding: the mobile chrome — `apps/mobile/src/chrome/Row.tsx` (a `<button>` with icon + label + value
+ chevron) and `apps/mobile/src/chrome/ActivityList.tsx` (icon + title/meta + amount inside a
`@mercury/ui` `Card`). `ListRow` generalizes both (leading icon/avatar · label + description · value
and/or trailing).

### `MoneyInput` (new, group `inputs`) — exports `MoneyInput`, `MoneyInputProps`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `currency` | `string` | `"$"` | The currency prefix rendered as a leading affix (e.g. `$` or `USD`). |
| `label` | `string` | — | Field label (like `Input`). |
| `hint` | `string` | — | Helper text below (like `Input`). |
| `error` | `string` | — | Error text + `aria-invalid` (like `Input`). |
| `value` / `onChange` | controlled | — | Numeric/decimal entry; the inner `<input>` sets `inputMode="decimal"`. |
| …rest | `Omit<InputHTMLAttributes<HTMLInputElement>, "size">` | — | Native input attrs pass through (mirrors `InputProps`). |

Grounding: `apps/mobile/src/screens/Send.tsx` (the `.em-amt` block: `<span className="em-amt-ccy">USD</span>`
+ `<input inputMode="decimal">` + a hint/error line). `MoneyInput` absorbs exactly this; the suggested
build path composes `Input` with the currency in its `leading` slot (implementor's latitude).

## 7 · Dependencies

- **Hard-gates on:** `mx.3` (the host + the forward-compatible glob + the theme decorator + the
  library `tsconfig` stories-exclude `D-9` — met) and `mx.2` (the 33 hand-authored `<Name>.prompt.md`
  each story restates — met).
- **Unblocks:** `mx.5` (the apps-side effector-wired Pages — see the deferral below) and `mx.6`
  (build/deploy + the `.design-sync` re-align). The now-complete component coverage is the floor the
  apps-side Pages compose against.
- **Touches:** `packages/mercury-ui/src/components/<group>/<Name>/<Name>.stories.tsx` (31 + 2 new);
  the two new folders `data-display/ListRow/**` + `inputs/MoneyInput/**`;
  `data-display/Card/{Card.tsx,Card.prompt.md,Card.stories.tsx}`;
  `packages/mercury-ui/src/index.ts` (two additive `export *` lines);
  `packages/mercury-ui/src/styles/` (the card-header + ListRow + MoneyInput `.mx-*` rules). No host,
  app, `tsconfig`, or gate edit. Canon §7 + the roadmap/progress fold at ship.

### Deferred to mx.5 (do not build here)

The apps-side **effector-wired Pages** — brand-new Pages per app
(`apps/{catalogue,echomq,showcase,mobile,docs}`) built on the apps' existing REAL composed screens,
wiring REAL `@mercury/ui` + `@mercury/effector` — are **mx.5**, not this rung. mx.4 completes the
component-story coverage and the additive library growth those Pages will compose against; it adds no
app-screen story and no apps-side Page. (This re-sequences the roadmap's mx.5 — "Effector-powered
stories" — to absorb the apps-side Pages; Operator-ruled.)

### Placement flag (Director-ratifiable, not an Operator fork)

`ListRow → data-display` and `MoneyInput → inputs` are **proposed** group placements (`D-4` class — a
placement judgment, not a correctness claim). Both fit their group's existing membership (data-display
holds Avatar/Badge/Card/Table; inputs holds Input/Textarea/Search/Select/AuthCode). Surfaced for the
Director to ratify at ship; no behavior depends on it.

> **Framing (propagate to any brief derived from this spec):** no gendered pronouns for agents; no
> perceptual or interior-state verbs; no first-person narration. State each surface as a contract
> (precondition / postcondition / invariant) so acceptance is at the boundary, not by re-reading the diff.
