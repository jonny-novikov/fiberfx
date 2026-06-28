# MX.2 — build context (for the implementor / author waves)

Working notes for building [`mx.2.md`](./mx.2.md). The method is the contract set in
[`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md). Root = `mercury/`.

## Ground facts (re-probe before trusting)

- **33 component folders, 9 groups**, under `packages/mercury-ui/src/components/<group>/<Name>/`, each
  with `<Name>.tsx` + `index.ts`, **0 `.prompt.md` today**. The target: one `<Name>.prompt.md` per
  folder.
  - `actions`: Button · Link
  - `foundations`: Icon · Divider
  - `inputs`: Input · Textarea · Search · Select · AuthCode
  - `selection`: Checkbox · Radio · Switch · Segmented · Slider · Toggle
  - `feedback`: Alert · Progress · PasswordStrength
  - `data-display`: Chip · Tag · Badge · Avatar · Card · Table · Stat · Chart · Checklist
  - `navigation`: Tabs · Accordion · Pagination
  - `overlay`: Modal · Tooltip
  - `layout`: AuthLayout
- **The generated seeds** survive at `mercury/ds-bundle/components/<group>/<Name>/<Name>.prompt.md`
  for the **23 original** components (not the 10 net-new/salvaged). Treat them as a *seed for the
  prop list only* — re-author the prose, drop the `window.MercuryUI`/`_ds_bundle` runtime framing,
  add Composition + grounded Examples. Verify every prop against the live `.tsx`, not the stub.
- **Apps resolve `@mercury/ui` from source** (vite alias). The two grounding apps:
  `apps/showcase/src/**` and `codemojex-node/apps/economy/src/**` (the latter is 3× `../` deep).

## The contract template (freeze it in `docs/mercury/contracts.md` from the Button exemplar)

```markdown
# <Name> — <one-line role>

<One sentence: what it is and when to reach for it.> Import: `import { <Name> } from "@mercury/ui"`.

## Props
| Prop | Type | Default | Notes |
|---|---|---|---|
<every prop from <Name>.tsx — name, type, default, one-line note. Group required first.>

## The enum language
<the variant/size/tone props and the token families they resolve to (canon §6). Omit if none.>

## Composition
- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) (the `leading`/`trailing` slot), …
- **Composed by:** [AuthLayout](../../layout/AuthLayout/AuthLayout.prompt.md), [Table](../../data-display/Table/Table.prompt.md) cells, …
<cross-links by real relative path to sibling .prompt.md; this is the "feeds each other" edge.>

## Examples
<2–4 grounded snippets. Each MUST be a real usage — cite the call site as a trailing comment:>
```tsx
<Button variant="destructive" leading={<Icon name="trash" size={14} />}>Delete</Button>
// showcase/src/pages/components/ButtonPage.tsx
```

## Notes
<a11y, gotchas, the nullable-ref idiom where relevant, "no app call site — grounded in source" where true.>
```

Section order is load-bearing (it is the exemplar's contract). Keep it identical across the set.

## Grounding inventory (real call sites — captured mx.2; ground Examples here, NO-INVENT)

**Rich, both apps:**
- **Button** — `variant` primary|secondary|outline|ghost|destructive|inverse · `size` sm|md|lg ·
  `loading` · `disabled` · `fullWidth` · `leading`/`trailing` (Icon). showcase ButtonPage + economy
  BalanceSimPanel.
- **Input** — `label` · `type` email|password|number|search|text · `placeholder` · `leading`/`trailing` ·
  `hint` · `error` · `value`/`onChange`/`onBlur` · `min`/`step`/`inputMode` (number). showcase InputPage +
  economy CalibrationForm/BalanceSimPanel.
- **Card** — `variant` flat|raised|floating · `padding` (number). economy (10 call sites) + showcase
  SignInPage/DashboardPage.
- **Segmented** — `segments` [{label,value}] · `value`/`onChange` · `size` sm · `fullWidth`. showcase
  Topbar/Dashboard + economy RevenueFlow/RailPanel/CalibrationForm.
- **Divider** — `label` · `orientation` horizontal|vertical. both.
- **Tag** — `tone` neutral|brand|positive|negative|caution|info|discovery · `dot`. economy RevenueFlow +
  showcase tables.
- **Icon** — `name` · `size` (number). both, ubiquitous.
- **Tabs** — `tabs` [{label,value}] · `value`/`onChange` · `variant` underline|pills. showcase TabsPage +
  economy App.

**economy (data + inputs surface — richest for these):**
- **Stat** — `label` · `value` · `delta` · `deltaTone` brand|positive|negative · `hint`. KpiRow,
  BalanceSimPanel, PrizePoolTable.
- **Chart** — `viewBox` · `series` · `gridY` · `yTicks`/`xTicks` · `gradients` · `markers` [{y}] ·
  `ariaLabel`. HousePctCurve/PoolGrowthCurve/MarginCurve.
- **Table** — `columns` Column<T>[] ({key,label,align,render}) · `data` · `striped` · `getRowKey`.
  RailPanel/SplitLadderTable/MarginTable/PrizePoolTable + showcase.
- **Slider** — `label` · `unit` · `min`/`max`/`step` · `showValue` · `value`/`onChange`. CalibrationForm.
- **Select** — `label` · `options` · `value`/`onChange`. CalibrationForm.
- **Alert** — `tone` info|success|warning|danger · `title`. economy MarginTable + showcase AlertPage.

**showcase:**
- **Badge** — `variant` negative|caution|positive|brand|info. ChipBadgePage/Dashboard.
- **Chip** — `variant` (7 tones) · `size` sm|md|lg · `selected` · `onRemove` · `onClick`. ChipBadgePage.
- **Avatar** — `name` · `size` (number) · `status` positive|caution|negative|info. AvatarPage/Table.
- **Checkbox** — `checked`/`onChange` · `label` · `disabled`. SelectionPage/SignIn.
- **Radio** — `name`/`value` · `label` · `checked`/`onChange`. SelectionPage.
- **Switch** — `label` · `checked`/`onChange`. SelectionPage.
- **Progress** — `value` (0–100) · `size` sm|md|lg · `variant` brand|positive|caution|negative.
  ProgressPage/Dashboard.
- **Modal** — `open` · `onClose` · `title` · `footer` · `size` sm. Shell.
- **Tooltip** — `content` · children. ModalPage.
- **Link** — `href` · `size` sm|md · `muted` · `disabled` · `leading`/`trailing` · `type`. LinkPage/auth.
- **AuthCode** — `value`/`onChange` · `onComplete` · `length` · `error`. AuthFlowPage.
- **AuthLayout** — `eyebrow` · `heading` · `subheading` · `footer` · children. AuthFlowPage (5 screens).
- **Checklist** — `items` [{label,met}]. AuthFlowPage.
- **PasswordStrength** — `score` · `label` · `variant`. AuthFlowPage.

**No app call site — ground in `.tsx` source alone, and say so in Notes:**
`Textarea` · `Search` · `Toggle` · `Accordion` · `Pagination`. (Read the source interface; for the
salvaged three, mind the React-19 nullable-`useRef().current` idiom already in `Accordion.tsx`.)

## The gate (from `mercury/`)

```bash
# INV-2 coverage — counts must match (33 = 33):
find packages/mercury-ui/src/components -name '*.prompt.md' | wc -l               # contracts
find packages/mercury-ui/src/components -mindepth 2 -maxdepth 2 -type d | wc -l   # component folders (each = one <Name>.tsx)
# INV-3 no extractor framing leaked in:
grep -rl 'window.MercuryUI\|_ds_bundle' packages/mercury-ui/src/components && echo "FAIL: extractor framing" || echo "clean"
# INV-1/INV-6 build undisturbed:
pnpm -r typecheck && pnpm -r build && pnpm --filter "./apps/*" build
diff <(git show HEAD:packages/mercury-ui/src/index.ts | grep -oE 'export .*') \
     <(grep -oE 'export .*' packages/mercury-ui/src/index.ts)   # 0 removed/renamed
```

## Gotchas

- **A contract is docs, not code** — it adds no export and must not perturb `tsc`/`vite`. If a hoist
  (K-3) is ruled, *that* is the only source change, and it is additive (INV-1 forbids removals/renames,
  not additions).
- **Verify props against the live `.tsx`, never the seed stub** — the generated seed can lag the source
  (it was extracted at an earlier point). The `.tsx` is truth (INV-3).
- **Cross-link by real relative path** between co-located contracts (e.g. Button→Icon is
  `../../foundations/Icon/Icon.prompt.md`); a broken link fails INV-4.
- **Examples must be real** — cite the call site. If you cannot find a real one (the 5 ungrounded
  components), construct the minimal valid usage from the source and label it *"(source-grounded; no app
  call site)"* — do not fabricate an app citation.
- **Author in waves, ≤2 heavy authors at once** (the concurrency cadence). The exemplar (Button) +
  `docs/mercury/contracts.md` land first; everything else imitates them.
- **Commit only when asked**, pathspec only; the 33 `.prompt.md` + the canon updates are one concern,
  but re-verify `git diff --cached --name-only` before any commit.
