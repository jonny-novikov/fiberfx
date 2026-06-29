# mx.7.3 · Import batch 3 — input / selection composites

> **Status: 📋 PLANNED — build-ready; batch 3 of the mx.7 import epic.** Inherits the epic frame
> [`../mx.7/mx.7.md`](../mx.7/mx.7.md) (the cross-batch forks, the cadence, the shared translation contract).
> This batch imports the **input / selection composites** — the date primitives + the managed
> checkbox / radio / toggle sets — translated from the bundle's inline-style prototypes into `@mercury/ui`'s
> `.mx-*` + token idiom, additively. Builds on mx.7.1 (`Label`, the `accent`-class pattern) and composes the
> live `Checkbox` / `Radio` / `Textarea` / `ToggleGroup` primitives.
>
> **⚠ Pre-build reconcile correction (lag-1, vs as-built — the epic's §1 count is STALE here).** The epic
> table lists this batch as **8 components, 7 net-new + 1 fold (`TextArea`)**. The as-built grep contradicts it
> on one row: **`ToggleGroup` is ALREADY a live export** — it is defined and exported inside
> `selection/Toggle/Toggle.tsx` (lines 41–113: `ToggleGroup` + `ToggleGroupType` / `ToggleGroupItem` /
> `ToggleGroupProps`) and re-exported by the barrel via `export * from "./components/selection/Toggle"`. So
> `ToggleGroup` is **a second fold, not a 7th net-new** (creating a `selection/ToggleGroup/` folder that
> re-exports `ToggleGroup` would be a **duplicate export** — a master-invariant / build break). The corrected
> batch shape is **6 net-new exports + 2 folds** (`TextArea`→`Textarea`, `ToggleGroup`→live `ToggleGroup`). This
> is recorded as the §A·A3 fork for the Operator and folded into the epic table at ship.
>
> **Risk: NORMAL-to-ELEVATED.** Four of the six net-new are managed wrappers over a shipped primitive
> (low risk); **two are stateful keyboard machines** — `DateField` (a segmented mm/dd/yyyy spinbutton with
> caret hand-off + arrow increment) and `Calendar` (a month grid with paging + controlled/uncontrolled
> selection). Load-bearing hazards: (a) the date-primitives' lib — the bundle prototypes use **native `Date` /
> string segments**, while `@mercury/core` already carries `@internationalized/date` + a headless date-field
> machine, and **`@internationalized/date` is NOT a visible dependency of `@mercury/ui`** (§A·A2 — a F6.7-class
> dep-graph-visibility fork, Operator rules); (b) the `*Cards` composition — compose the live primitive vs a
> standalone card-select impl (§A·A1); (c) the `accent` prop — live `Checkbox` / `Radio` / `Toggle` have **no
> `accent` prop**, so a group realizes it as a wrapper class, **never** by forwarding `accent` to the primitive
> (an INVENTED surface) and never via `mercAccent`.
>
> **Inherited, not re-argued** (epic §4/§5): translate to `.mx-*` + tokens; additive-only tokens/fonts; never
> rename an existing export; design flows DOWN (no `/design-sync`); the 4-file home + additive barrel + the gate.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · epic: [`../mx.7/mx.7.md`](../mx.7/mx.7.md) ·
prior batch: [`../mx.7.2/mx.7.2.md`](../mx.7.2/mx.7.2.md) · contract template:
[`../../contracts.md`](../../contracts.md) · acceptance: [`mx.7.3.stories.md`](./mx.7.3.stories.md) · build
context: [`mx.7.3.llms.md`](./mx.7.3.llms.md).

---

## A · The open calls in this batch (Operator rules each)

Policy is ruled in the epic (Cross-fork III: **never rename / never duplicate an existing export** — fold or
add-distinct). These specific calls land here because their components land here. The styling-idiom / token /
git forks are inherited from the epic §4 and not re-framed.

### A1 — the `*Cards` composition: **compose the live primitive** (Steward = compose)

- **Rationale.** The bundle `CheckboxCards` / `RadioCards` (`selection/CheckboxCards.tsx` /
  `selection/RadioCards.tsx`) **do not** compose `Checkbox` / `Radio` — each builds a `role="checkbox"` /
  `role="radio"` `<div>` with its own check-glyph / dot span and hand-rolled Space/Enter handling. The live
  library already ships `selection/Checkbox` (native `<input type="checkbox">` + `.mx-cb__box`) and
  `selection/Radio` (native `<input type="radio">` + `.mx-rd__dot`). Re-drawing the indicator duplicates a
  shipped primitive (a DRY + package/app-split tension).
- **Arms.** **(a) Compose the live primitive inside a selectable card shell (RECOMMENDED)** — the card is the
  label; a click toggles the wrapped `Checkbox` / `Radio`; the indicator + native input semantics + keyboard
  come free from the primitive; the card adds the surface (`.mx-checkbox-cards` shell, `columns`, `size`,
  `description`, leading `icon`, the selected ring). **(b) Standalone card-select impl** (the bundle's
  `role="checkbox"` div) — self-contained, full control of card-wide a11y, but re-implements the indicator the
  primitive already draws and a second keyboard path to maintain.
- **Steward / recommendation: (a)** — DRY + the package/app split (a composite composes primitives). **Operator
  rules** (a a11y-locality vs self-containment call).

### A2 — the date primitives' lib: **reuse `@mercury/core`'s date layer via a curated barrel hook** (Steward = reuse core)

This is the batch's load-bearing fork and carries a **dep-graph-visibility** sub-finding (F6.7 class).

- **Rationale + ground truth.** The bundle `DateField` models the value as `{ month, day, year }` **strings**;
  the bundle `Calendar` uses native **`Date`**. Neither uses `@internationalized/date`. But `@mercury/core`
  **already** depends on `@internationalized/date@^3.8.2` and carries a headless date-field machine
  (`src/internal/date-time/field/{segments,parts,helpers,types,time-helpers}.ts` + `placeholders.ts` /
  `utils.ts` / `time-value.ts`) — the UI-free foundation built exactly for this. **Crucially:** `@mercury/ui`'s
  ONLY dependency is `@mercury/core` (`workspace:*`); **`@internationalized/date` is NOT a dependency of
  `@mercury/ui`** and is NOT on its barrel. So "reuse core" has a real HOW.
- **Arms.** **(a) Surface a curated headless date hook through `@mercury/core`'s barrel; `@mercury/ui` consumes
  it via `@mercury/core` (RECOMMENDED).** Core adds a minimal, explicit export (a `useDateField` /
  `useCalendar`-style hook + the `CalendarDate` / `DateValue` types it needs), exactly as its `CLAUDE.md`
  sanctions ("surfaced explicitly only when a consumer needs it" — NOT a wholesale barrel widen, which `D-5`
  forbids); `DateField` / `Calendar` import the hook from `@mercury/core` the way every component imports `cx`.
  **No new external dependency edge on `@mercury/ui`; the date math stays in the UI-free layer that owns it.**
  **(b) `@mercury/ui` adds `@internationalized/date` as its own dependency** + imports it directly. Cost: a
  **new external dependency edge** (an Operator-owned fork per AAW law) and date logic leaking into the UI layer
  core already owns (DRY loss). **(c) Native `Date` / string segments** (port the bundle prototype as-is). Cost:
  re-implements validity / locale / calendar-system handling the core date layer already does correctly — the
  exact i18n-correctness + DRY loss the foundation was built to prevent.
- **Steward / recommendation: (a)** — it is why core carries `@internationalized/date`. **Operator rules** the
  arm. **Either way, a hard build invariant holds (INV-6): `@mercury/ui` must NOT `import "@internationalized/date"`
  directly** (it is not a visible dep — a strict-`node_modules` build would not resolve it; a hoisted resolve is
  a drift surface). Consume the date layer **through `@mercury/core`** — unless the Operator rules arm (b).

### A3 — the `ToggleGroup` collision (reconcile-surfaced): **fold, no new export** (Steward = fold)

- **Rationale.** Per the pre-build reconcile, **`ToggleGroup` is already a live export** (inside
  `selection/Toggle/Toggle.tsx`). The bundle `selection/ToggleGroup.tsx` is a richer prototype of the same
  component (adds `accent?` and a group-level `disabled?`; uses `onChange` where live uses `onValueChange`, and
  `"aria-label"` where live uses `ariaLabel`). The names are identical, so the master invariant **forbids** a
  rename and a second `ToggleGroup` export is a duplicate (build break).
- **Arms.** **(a) Fold the bundle's enhancements INTO the live `ToggleGroup`, add NO new export, create NO
  `selection/ToggleGroup/` folder (RECOMMENDED)** — add `accent?` (realized as `.mx-tgl-grp--accent-<id>`) +
  optional group-level `disabled?` to the live interface; **keep** the live prop names (`onValueChange`,
  `ariaLabel`) — adding props is additive, renaming an existing prop is not. **(b) Leave the live `ToggleGroup`
  as-is, skip the bundle enhancements** — no surface change, but the Claude-Design `accent`/group-`disabled`
  capability is absent. (No "add-distinct" arm exists — the name is taken.)
- **Steward / recommendation: (a)** — parallel to the `TextArea` fold; folding is exactly what the master
  invariant makes free. **Operator rules** (parity vs minimal-change).

### Recorded resolutions (ruled by the epic — not re-litigated here)

- **`TextArea` fold (epic Cross-fork III row).** `TextArea` (bundle) ≡ `Textarea` (live) — **fold**: translate
  the bundle's net enrichment **`size?: "sm"|"md"|"lg"`** into the live `Textarea` (the rest of the bundle's
  surface — `label`/`hint`/`value`/`rows`/`maxLength`/`disabled`/`readOnly`/`placeholder` — is already present
  on live, mostly via `extends TextareaHTMLAttributes`). **Add NO new export; rename nothing.** Recorded here as
  the resolution of the epic's TextArea row.

> **Effort-rebalance observation (surfaced for the Operator's between-batch feedback — NOT a re-decision).** The
> epic §1 flags mx.7.3 as **over-band (~7–8 units), dominated by `Calendar` + `DateField`**, and offers shedding
> them into their own date batch. The A2 finding **sharpens** that: the recommended date arm (a) is the heaviest
> item in the batch — it is not a translate-in-place but a **curated `@mercury/core` headless-hook build** atop
> the existing date-field machine, with its own dep-graph + i18n surface. If the Operator prefers a tighter
> batch, **shedding `Calendar` + `DateField` into a dedicated date batch** leaves mx.7.3 as the four selection
> composites (`CheckboxGroup` / `CheckboxCards` / `RadioGroup` / `RadioCards`) + the two folds — squarely in band
> and pure-presentational. The Operator rebalances in the seat; this triad records the starting shape as the
> epic ruled it and the shed as available.

## 0 · The slice

Batch 3 — the input / selection composites. Six net-new: the two date primitives (`DateField`, `Calendar`) and
the four managed selection sets (`CheckboxGroup`, `CheckboxCards`, `RadioGroup`, `RadioCards`); plus two folds
that enrich shipped exports (`Textarea`, `ToggleGroup`). The selection sets **compose** the live `Checkbox` /
`Radio` (per §A·A1); the date primitives **consume `@mercury/core`'s date layer** (per §A·A2). All translate
into the live `.mx-*` + token idiom and export additively; the two folds add **no** new export. `DateField` and
`Calendar` are the only stateful keyboard machines — the elevated-verify focus of the batch.

## 1 · Goal

After mx.7.3, `@mercury/ui` exports **6 new components** — `DateField · Calendar · CheckboxGroup · CheckboxCards
· RadioGroup · RadioCards` — each a translated 4-file home (`.mx-*` + tokens · hand-authored contract · CSF3
story), and the live `Textarea` + `ToggleGroup` are **enriched in place** (size; accent + group-disabled) with
**no new export**. The barrel is strictly additive (+6 + their `Props`; 0 removed/renamed; **exactly one**
`ToggleGroup` export). The full package gate is green; `sb:build` registers prior + 6 homes (the `Textarea` +
`Toggle` stories refreshed in place); `@mercury/ui` gains **no direct `@internationalized/date` import** (per
INV-6, unless the Operator rules A2 arm (b)).

## 2 · Rationale (5W)

- **Why.** Forms need managed selection (a checkbox set, a radio set, selectable cards) and date entry (a typed
  field + a picker grid). These are the composite layer mx.9's showcase + the apps' forms compose, built on the
  mx.7.1 `Label` + the shipped `Checkbox` / `Radio` primitives — not re-drawn.
- **What.** The 6 translated net-new homes, the 2 folds (enrich `Textarea` with `size`; enrich `ToggleGroup`
  with `accent` + group-`disabled`), the barrel +6, the `.mx-*` rules in `additions.css` (incl. the
  `.mx-<name>--accent-<id>` ramps reused from mx.7.1), and the date arm ruled in §A·A2.
- **Who.** *Authored by* the architect (this triad) + the batch's build / verify agents (epic §2 cadence).
  *Consumed by* mx.7.4 (none directly — independent), mx.8 (their stories), mx.9 (the showcase forms), and the
  workspace consumers.
- **When.** Batch 3 — after mx.7.2, with the Operator in the loop before mx.7.4.
- **Where.** Only `packages/mercury-ui/src/` (the 6 new folders + the 2 fold files `inputs/Textarea/Textarea.tsx`
  + `selection/Toggle/Toggle.tsx` + barrel + `additions.css`) + `docs/mercury/specs/mx.7.3/` — **and**, only if
  the Operator rules A2 arm (a), a curated additive export in `packages/mercury-core/src/` (the date hook). The
  bundle `packages/mercury-ds/` is read-only.

## 3 · The component set (grounded — bundle prop surface verified in source)

| Component | Bundle source | Prototype prop surface (verified — the seed) | Live action |
|---|---|---|---|
| `DateField` | `inputs/DateField/DateField.tsx` | `value?: DateValue` · `defaultValue?: Partial<DateValue>` · `onChange?: (DateValue) => void` · `label?` · `disabled?` (`DateValue = {month,day,year}` strings; segmented mm/dd/yyyy spinbutton, arrow ±) | **net-new** `inputs/DateField` |
| `Calendar` | `inputs/Calendar/Calendar.tsx` | `value?: Date\|null` · `defaultValue?: Date\|null` · `onChange?: (Date) => void` · `accent?: AccentId` (month grid; prev/next paging; composes live `Icon`) | **net-new** `inputs/Calendar` |
| `CheckboxGroup` | `selection/CheckboxGroup/CheckboxGroup.tsx` | `items: {value,label?,disabled?}[]` · `value?: string[]` · `defaultValue?: string[]` · `onChange?: (string[]) => void` · `accent?` · `orientation?: vertical\|horizontal` · `disabled?` (composes the **live `Checkbox`**) | **net-new** `selection/CheckboxGroup` |
| `CheckboxCards` | `selection/CheckboxCards/CheckboxCards.tsx` | `items: {value,label?,description?,icon?: IconName,disabled?}[]` · `value?: string[]` · `defaultValue?: string[]` · `onChange?` · `accent?` · `columns?=1` · `size?: sm\|md\|lg` | **net-new** `selection/CheckboxCards` |
| `RadioGroup` | `selection/RadioGroup/RadioGroup.tsx` | `items: {value,label?,disabled?}[]` · `value?: string` · `defaultValue?: string` · `onChange?: (string) => void` · `name?` · `accent?` · `orientation?` · `disabled?` (composes the **live `Radio`**) | **net-new** `selection/RadioGroup` |
| `RadioCards` | `selection/RadioCards/RadioCards.tsx` | `items: {value,label?,description?,icon?: IconName,disabled?}[]` · `value?: string` · `defaultValue?: string` · `onChange?` · `accent?` · `columns?=1` · `size?` | **net-new** `selection/RadioCards` |
| `TextArea`* | `inputs/TextArea/TextArea.tsx` | `value`/`defaultValue`/`onChange` · `placeholder` · `rows?=4` · `size?: sm\|md\|lg` · `disabled` · `readOnly` · `invalid?` · `resize?: none\|vertical\|both` · `maxLength` · `label`/`hint` | **FOLD** → enrich live `inputs/Textarea` (net add: `size`) — **no new export** |
| `ToggleGroup`* | `selection/ToggleGroup/ToggleGroup.tsx` | `type?: single\|multiple` · `items: {value,label?,icon?,"aria-label"?}[]` · `value?`/`defaultValue?: string\|string[]` · `onChange?` · `size?` · `accent?` · `disabled?` | **FOLD** → enrich live `ToggleGroup` (in `selection/Toggle/Toggle.tsx`; net add: `accent`, group-`disabled`) — **no new export** |

`*` `TextArea` and `ToggleGroup` are **folds** of existing live exports (`Textarea`, `ToggleGroup`) — batch work
items that enrich the live component, adding **no** new export (renaming / duplicating either is forbidden —
master invariant).

> **Group note (D-4-class, not a blocker):** `Calendar` sits in `inputs` (the bundle's group; it pairs with a
> `Popover` for a date picker — that pairing is mx.7.4 / mx.9, not here). `DateField` is `inputs`. The export
> name is what the barrel encodes; the group is a navigability choice, not a correctness one.

## 4 · Translation notes (the deltas beyond the epic / mx.7.1 idiom)

- **The `accent` prop has NO live primitive prop to forward to — realize it at the GROUP.** Live `Checkbox` /
  `Radio` / `Toggle` carry **no `accent` prop** (verified). So `CheckboxGroup` / `RadioGroup` must **not** pass
  `accent` to the wrapped primitive (that is an INVENTED surface — NO-INVENT). Realize `accent` as a group
  wrapper class `.mx-checkbox-group--accent-<id>` / `.mx-radio-group--accent-<id>` that sets the token color the
  child indicator reads (the mx.7.1 `.mx-<name>--accent-<id>` ramp pattern, `iris|indigo|green|orange|plum|red`).
  Same for `CheckboxCards` / `RadioCards` (the card shell carries the class) and the `ToggleGroup` fold
  (`.mx-tgl-grp--accent-<id>`). **No `mercAccent` import** anywhere (Cross-fork I).
- **`CheckboxGroup` / `RadioGroup` — compose the live primitive directly.** `import { Checkbox } from
  "../Checkbox"` / `import { Radio } from "../Radio"`. Forward `checked` / `disabled` / `label` / (`name`/`value`
  for Radio) — **not** `accent`. The live `Checkbox.onChange` is `(checked: boolean) => void`, live
  `Radio.onChange` is `(value: string) => void`; the group ignores the arg and toggles by `item.value` (matches
  the bundle). `orientation` → a `.mx-*-group--horizontal` flex-direction modifier.
- **`CheckboxCards` / `RadioCards` — compose the live primitive in a card shell (per §A·A1 arm (a)).** The card
  `<div className="mx-checkbox-cards__card">` wraps the live `Checkbox` / `Radio` (the indicator + native input
  + keyboard come from the primitive); the shell adds `columns` (grid), `size` (sm/md/lg paddings), a leading
  `icon` (the live `Icon`, a **real glyph** — verify against the live Icon set, mx.7.2 established this), a
  `description`, and the selected ring (`box-shadow: inset 0 0 0 2px` reading the accent token). Multi-select
  (`string[]`) for cards, single (`string`) for radio cards.
- **`DateField` — translate the segmented spinbutton; consume the date layer per §A·A2.** Keep the
  controlled (`value`) + uncontrolled (`defaultValue`) split and the a11y shape (`role="spinbutton"`,
  `aria-label` per segment, `aria-valuenow`, `inputMode="numeric"`, caret hand-off on fill, ArrowUp/Down
  increment with min/max wrap). Style via `.mx-datefield` reading `--border-primary`/`--border-focus`/
  `--ring-focus` + `--font-secondary` (DM Mono) — **no inline color literal**. The value model + arithmetic
  come from the ruled date arm (the core hook), **not** a hand-rolled `Date` (unless the Operator rules A2 (c)).
  Guard React-19 nullable `useRef().current`.
- **`Calendar` — translate the month grid; `accent` class-driven; composes live `Icon`.** Controlled +
  uncontrolled selection; prev/next month paging; today / selected / outside-month cell states. The nav chevron
  is the live `Icon` (a real glyph — bundle uses `chev`; verify the live name). The selected-day fill +
  today-ring read `.mx-calendar--accent-<id>` token classes (**not** `mercAccent`). Date arithmetic per §A·A2.
- **The `Textarea` fold — add `size` only.** Add `size?: "sm"|"md"|"lg"` to `TextareaProps` + the
  `.mx-ta--<size>` rules (the bundle's `PAD`/`FS` scale → token-driven padding / font-size). Keep every existing
  prop and the `error`/`hint`/`maxLength` count footer; **rename nothing; add no export**.
- **The `ToggleGroup` fold — add `accent` + group `disabled`.** Add `accent?: "iris"|…|"red"` (→
  `.mx-tgl-grp--accent-<id>`) and an optional group-level `disabled?` to the live `ToggleGroupProps`; keep
  `onValueChange` / `ariaLabel` (do **not** adopt the bundle's `onChange` / `"aria-label"` names — adding a prop
  is additive, renaming one is not). **Add no export; create no `selection/ToggleGroup/` folder.**

## 5 · Deliverables

- **K-1 — 6 net-new translated 4-file homes** under `packages/mercury-ui/src/components/<group>/<Name>/`
  (`DateField` · `Calendar` in `inputs/`; `CheckboxGroup` · `CheckboxCards` · `RadioGroup` · `RadioCards` in
  `selection/`): `<Name>.tsx` translated · `index.ts` · `<Name>.prompt.md` hand-authored · `<Name>.stories.tsx`
  CSF3.
- **K-2 — 2 folds, NO new export** (Cross-fork III + §A·A3): enrich live `inputs/Textarea/Textarea.tsx` (add
  `size`) and live `ToggleGroup` in `selection/Toggle/Toggle.tsx` (add `accent` + group-`disabled`); rename /
  duplicate nothing; **no `selection/ToggleGroup/` folder**.
- **K-3 — the barrel grows +6 additively** (`DateField`/`Calendar`/`CheckboxGroup`/`CheckboxCards`/`RadioGroup`/
  `RadioCards` + their `Props`); every prior export byte-preserved; **exactly one** `ToggleGroup`; barrel-diff 0
  removed/renamed.
- **K-4 — the live idiom** (Cross-fork I): `.mx-*` classes + tokens; no inline color literal; no raw hex; the
  `accent` prop via `.mx-*--accent-<id>` classes (no `mercAccent` import).
- **K-5 — composition is real, accent at the group** (§A·A1): `CheckboxGroup`/`RadioGroup` + the `*Cards`
  compose the live `Checkbox`/`Radio`; `accent` is realized as a group/card wrapper class, **never** forwarded
  to the primitive (which has no `accent` prop).
- **K-6 — the date-lib per the ruled arm** (§A·A2): the date value model + arithmetic come from
  `@mercury/core`'s date layer (arm (a)/(b)); `@mercury/ui` adds **no direct `@internationalized/date` import**
  and **no new external dependency edge** unless the Operator rules arm (b)/(c).
- **K-7 — a hand-authored contract per net-new component + the two folds refreshed** (D-7): mx.2 format; no
  bundle runtime framing; cross-links (`CheckboxGroup`↔`Checkbox`; `RadioGroup`↔`Radio`; `CheckboxCards`/
  `RadioCards`↔their group + `Card`; `DateField`↔`Calendar`+`Input`; `Calendar`↔`DateField`+`Popover`;
  `ToggleGroup`↔`Toggle`+`Segmented`; `Textarea`↔`Input`).
- **K-8 — the 1:1 story↔folder invariant holds** (mx.4 S-1): each net-new folder one co-located story;
  `sb:build` registers prior + 6; the `Textarea` + `Toggle` stories are refreshed in place (no net home change).
- **K-9 — token/font additive-only** (Cross-fork II) · **the gate is green** (§7) · **design flowed DOWN** (no
  `/design-sync`).

**Coverage:** K-1 → S-1..S-6 ; K-2 → S-7,S-8 ; K-3 → S-9 ; K-4 → S-1..S-8 ; K-5 → S-3..S-6 ; K-6 → S-1,S-2 ;
K-7 → S-1..S-8 ; K-8 → S-10 ; K-9 → S-11,S-12.

## 6 · The per-component translation map (grounded — see §3 for the surfaces)

- **DateField** (`inputs/DateField` → `inputs/DateField`). `.mx-datefield`; segmented mm/dd/yyyy spinbutton,
  caret hand-off, arrow ± wrap, focus ring; controlled+uncontrolled; value model via the core date layer (§A·A2).
  DM Mono. Cross-link `Calendar` + `Input`.
- **Calendar** (`inputs/Calendar` → `inputs/Calendar`). `.mx-calendar`; month grid + prev/next paging, today /
  selected / outside cells; controlled+uncontrolled; `accent` via `.mx-calendar--accent-<id>`; composes live
  `Icon` (real glyph). Cross-link `DateField` + `Popover` (mx.7.4).
- **CheckboxGroup** (`selection/CheckboxGroup` → `selection/CheckboxGroup`). `.mx-checkbox-group`; composes live
  `Checkbox`; multi-select controlled+uncontrolled; `orientation`; `accent` at the group class. Cross-link
  `Checkbox`.
- **CheckboxCards** (`selection/CheckboxCards` → `selection/CheckboxCards`). `.mx-checkbox-cards`; composes live
  `Checkbox` in a card shell (§A·A1); `columns`/`size`/`icon`/`description`/selected ring; multi-select.
  Cross-link `CheckboxGroup` + `Card`.
- **RadioGroup** (`selection/RadioGroup` → `selection/RadioGroup`). `.mx-radio-group`; composes live `Radio`;
  single-select controlled+uncontrolled; `orientation`; `accent` at the group class. Cross-link `Radio`.
- **RadioCards** (`selection/RadioCards` → `selection/RadioCards`). `.mx-radio-cards`; composes live `Radio` in a
  card shell; `columns`/`size`/`icon`/`description`/selected ring; single-select. Cross-link `RadioGroup`+`Card`.
- **Textarea** (FOLD). Add `size?: sm|md|lg` + `.mx-ta--<size>`; keep all else. No export.
- **ToggleGroup** (FOLD, in `selection/Toggle/Toggle.tsx`). Add `accent?` + `.mx-tgl-grp--accent-<id>` + group
  `disabled?`; keep `onValueChange`/`ariaLabel`. No export. Cross-link `Toggle` + `Segmented`.

## 7 · Invariants — as runnable gates (run from `mercury/`)

- **INV-1 — master invariant, additive.** Resolved export set after = superset of before; **0 removed/renamed**,
  +6 (+ `Props`); the two folds add **0** new export. (TS `getExportsOfModule`, not a text-diff.)
- **INV-2 — live idiom, no inline color leak.** `grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})"` over the 6
  net-new dirs + the two fold files → **empty** (dynamic non-color inline — grid `columns`, cell sizing — is
  allowed; color literals are the fail).
- **INV-3 — no raw hex.** `grep -rnE "#[0-9a-fA-F]{3,8}\b"` over the 6 new dirs + the two fold files + the new
  `additions.css` rules → **empty**.
- **INV-4 — no `mercAccent` import.** `grep -rn "mercAccent\|_lib/accent" packages/mercury-ui/src/components` →
  **empty** (every `accent` is class-driven).
- **INV-5 — composition real, accent NOT forwarded to the primitive.** `CheckboxGroup`/`RadioGroup` + the
  `*Cards` import the live `Checkbox`/`Radio` (grep the import resolves); **no `accent={` is passed to a
  `<Checkbox`/`<Radio` element** (the live primitives have no `accent` prop) —
  `grep -rnE "<(Checkbox|Radio)[^>]*accent=" packages/mercury-ui/src/components/selection` → **empty**.
- **INV-6 — date-lib dep-graph-visibility** (§A·A2). `grep -rn "@internationalized/date"
  packages/mercury-ui/src` → **empty** (consume the date layer via `@mercury/core`); `packages/mercury-ui/package.json`
  `dependencies` unchanged (only `@mercury/core`) — **unless the Operator ruled A2 arm (b)**, in which case the
  one added edge is the only change and is explicit.
- **INV-7 — exactly one `ToggleGroup`; no duplicate folder.** The resolved export set contains `ToggleGroup`
  **once**; `test ! -d packages/mercury-ui/src/components/selection/ToggleGroup` (no such folder created).
- **INV-8 — D-7 contract, no bundle framing.** Each net-new `.prompt.md` (+ the refreshed `Textarea`/`Toggle`
  contracts) has the mx.2 sections; `grep -rniE "check_design_system|pixel-perfect|/design-sync|showcase/"` over
  the new/changed contracts → **empty**.
- **INV-9 — 1:1 story↔folder + `sb:typecheck` clean.** `count(*.stories.tsx) == count(component folders)`;
  `pnpm sb:typecheck` exits 0 (the authoritative story NO-INVENT gate); `pnpm sb:build` registers prior + 6.
- **INV-10 — token/font additive-only** (Cross-fork II): a `tokens.css`/font edit is an added line, never a
  changed value.
- **INV-11 — design flows DOWN.** No `/design-sync`/`DesignSync` in the work; `git diff` touches no
  `mercury/.design-sync/` path; nothing pushes up.
- **INV-12 — the package gate.** `pnpm --filter "./packages/*" typecheck`/`build` = 0 · `pnpm --filter "./apps/*"
  --filter "!@mercury/storybook" build` = 0 (`echomq`+`mobile`) · `pnpm sb:build` = 0. If A2 arm (a) is ruled,
  `pnpm --filter @mercury/core typecheck` = 0 (the curated date-hook export).

## 8 · The batch loop (epic §2) — Operator → Agent-1 → Agent-2 → Operator

Operator sharpens this triad (carrying mx.7.2's lessons + ruling §A·A1/A2/A3) → **Agent-1** reconciles (lag-1 vs
the as-built `@mercury/ui` + the bundle), builds the 6 homes + the 2 folds, and (if A2 arm (a)) the curated core
date hook → **Agent-2** re-runs the gate, reconciles spec↔code, hardens (the date keyboard machines + the
dep-graph check), classifies every promise MATCH/STALE/INVENTED/MISSING, fills §9 → Operator reviews the +6
Storybook homes + the refreshed `Textarea`/`Toggle` + the gate, then **carries the lessons into mx.7.4's brief**
and releases batch 4. Feedback edits this spec, never the code directly.

> **Verify depth (NORMAL-to-ELEVATED).** The four selection sets are pure-presentational wrappers (NORMAL). The
> two date primitives are stateful keyboard machines — verify the controlled/uncontrolled split, the segment
> caret hand-off + arrow-wrap (`DateField`), the month-paging + selected/today/outside states (`Calendar`), and
> the **INV-6 dep-graph compile** (a clean install resolves with no direct `@internationalized/date` edge on
> `@mercury/ui`). A dedicated evaluator (Apollo) is **optional** on this batch but recommended for the two date
> components.

## 9 · As-built (the verifier — filled post-build)

> Classify K-1..K-9 / INV-1..INV-12 / S-1..S-12 MATCH/STALE/INVENTED/MISSING; record the ratified §A·A1/A2/A3
> arms; list the 6 net-new folders shipped + the two folds applied (the exact props added — `Textarea.size`,
> `ToggleGroup.accent`/`disabled`); reproduce the gate (EXIT 0) incl. the barrel-diff (0 removed/renamed, +6,
> exactly one `ToggleGroup`), the `sb:build` +6 home delta, and the idiom/hex/mercAccent/accent-not-forwarded/
> dep-graph/no-duplicate-folder/framing/no-design-sync greps (empty). **Record the A2 outcome explicitly:** the
> ruled arm, and (arm (a)) the curated `@mercury/core` date-hook export, or (arm (b)) the one added
> `@mercury/ui` dependency edge. Carry forward to mx.7.4 the date-state-machine + dep-graph-visibility lessons.
