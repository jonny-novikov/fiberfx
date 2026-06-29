# mx.7.3 · acceptance stories

Given/When/Then for [`mx.7.3.md`](./mx.7.3.md). Connextra form; each names its deliverable + the invariant(s)
it proves. **Coverage:** K-1 → S-1..S-6 ; K-2 → S-7,S-8 ; K-3 → S-9 ; K-4/K-7 → S-1..S-8 ; K-5 → S-3..S-6 ;
K-6 → S-1,S-2 ; K-8 → S-10 ; K-9 → S-11,S-12. Every component story proves INV-2 (live idiom) + INV-8 (D-7
contract) unless noted.

## S-1 · DateField is a segmented date input on the core date layer (K-1, K-4, K-6, K-7)
*As a **form author**, I want a `DateField` I can type mm/dd/yyyy into or arrow each part, so that I can enter a
date with the keyboard.*
**Given** `inputs/DateField/` (4 files), **when** `<DateField defaultValue={…}>` renders and a segment is typed
or arrowed, **then** it styles via `.mx-datefield` (no inline color, no raw hex), keeps `role="spinbutton"` per
segment with `aria-label`/`aria-valuenow`/`inputMode="numeric"`, hands the caret to the next segment on fill,
increments/wraps on ArrowUp/Down, drives controlled (`value`) + uncontrolled (`defaultValue`) use, and takes its
value model + arithmetic from **`@mercury/core`'s date layer** — with **no direct `@internationalized/date`
import** in `@mercury/ui` (per the ruled A2 arm). *(Proves INV-2 + INV-6.)*

## S-2 · Calendar is a month-grid picker, accent class-driven (K-1, K-4, K-6, K-7)
*As a **scheduling author**, I want a `Calendar` grid to pick a day and page months, so that I have a visual date
picker.*
**Given** `inputs/Calendar/`, **when** `<Calendar accent="indigo">` renders and prev/next is pressed or a day
chosen, **then** `.mx-calendar` draws the month grid with today / selected / outside-month states, paging works,
selection is controlled + uncontrolled, the nav chevron is the **live `Icon`** (a real glyph, not invented),
`accent` resolves via `.mx-calendar--accent-*` (no `mercAccent`), and the date arithmetic comes from the core
date layer. *(Proves INV-2 + INV-4 + INV-6.)*

## S-3 · CheckboxGroup composes the live Checkbox, multi-select (K-1, K-4, K-5, K-7)
*As a **form author**, I want a `CheckboxGroup` of `items`, so that I can manage a set where zero-or-more are
checked.*
**Given** `selection/CheckboxGroup/`, **when** `<CheckboxGroup items={…} defaultValue={["a"]} accent="green">`
toggles an item, **then** it **composes the live `Checkbox`** (imported from `../Checkbox`), drives multi-select
controlled (`value`) + uncontrolled (`defaultValue`) state, lays out by `orientation`, realizes `accent` as a
group wrapper class (`.mx-checkbox-group--accent-green`) — **never forwarded to `Checkbox`** (which has no
`accent` prop) and **never** via `mercAccent`. *(Proves INV-4 + INV-5.)*

## S-4 · CheckboxCards composes the live Checkbox in a card shell (K-1, K-4, K-5, K-7)
*As a **form author**, I want selectable `CheckboxCards` with a label, description and icon, so that I can offer
rich multi-select options.*
**Given** `selection/CheckboxCards/`, **when** `<CheckboxCards items={…} columns={2} size="md">` selects a card,
**then** the card shell (`.mx-checkbox-cards`) **wraps the live `Checkbox`** (the indicator + native input +
keyboard come from the primitive — §A·A1 arm (a)), the leading `icon` is the **live `Icon`** (a real glyph),
`columns`/`size`/`description`/the selected ring style via tokens, multi-select state is controlled +
uncontrolled, and the contract cross-links `CheckboxGroup` + `Card`. *(Proves INV-5.)*

## S-5 · RadioGroup composes the live Radio, single-select (K-1, K-4, K-5, K-7)
*As a **form author**, I want a `RadioGroup` of `items`, so that I can manage a set where exactly one is chosen.*
**Given** `selection/RadioGroup/`, **when** `<RadioGroup items={…} defaultValue="a" name="plan">` selects an
item, **then** it **composes the live `Radio`** (from `../Radio`), drives single-select controlled +
uncontrolled state, shares the `name`, lays out by `orientation`, and realizes `accent` as a group class —
**never forwarded to `Radio`**, never via `mercAccent`. *(Proves INV-4 + INV-5.)*

## S-6 · RadioCards composes the live Radio in a card shell (K-1, K-4, K-5, K-7)
*As a **form author**, I want selectable `RadioCards`, so that I can offer rich single-select options.*
**Given** `selection/RadioCards/`, **when** `<RadioCards items={…} columns={2}>` selects a card, **then** the
card shell (`.mx-radio-cards`) **wraps the live `Radio`** (§A·A1 arm (a)), exactly one card is chosen
(controlled + uncontrolled), `columns`/`size`/`icon`/`description`/the selected ring style via tokens, and the
contract cross-links `RadioGroup` + `Card`. *(Proves INV-5.)*

## S-7 · TextArea folds into the live Textarea — no new export (K-2)
*As a **downstream consumer**, I want the bundle's `TextArea` enhancement folded into the existing `Textarea`, so
that I gain `size` without a renamed or duplicated export.*
**Given** the live barrel exports `Textarea`, **when** the fold lands, **then** `inputs/Textarea/Textarea.tsx`
gains `size?: "sm"|"md"|"lg"` + the `.mx-ta--<size>` rules, **every existing prop is preserved**, **no
`TextArea` export is added** and `Textarea` is **not renamed** (master invariant), and its contract is refreshed.
*(Proves INV-1 + INV-8.)*

## S-8 · ToggleGroup folds into the live ToggleGroup — no new export, no duplicate (K-2)
*As a **downstream consumer**, I want the bundle's `ToggleGroup` enhancements folded into the existing
`ToggleGroup`, so that the export surface gains nothing duplicate.*
**Given** the live `ToggleGroup` already exported from `selection/Toggle/Toggle.tsx` (the pre-build reconcile),
**when** the fold lands, **then** `ToggleGroup` gains `accent?` (→ `.mx-tgl-grp--accent-<id>`) + an optional
group-level `disabled?`, the live prop names `onValueChange`/`ariaLabel` are **kept** (not renamed to the
bundle's `onChange`/`"aria-label"`), **no `selection/ToggleGroup/` folder is created**, and the resolved export
set contains `ToggleGroup` **exactly once**. *(Proves INV-1 + INV-7.)*

## S-9 · The barrel grows +6 additively (K-3)
*As a **downstream consumer**, I want every prior export preserved, so that nothing I import breaks.*
**Given** the `@mercury/ui` barrel before/after, **when** the resolved export set is compared (TS
`getExportsOfModule`, not a text-diff), **then** it is a **superset** — 0 removed, 0 renamed — with exactly the 6
new component names (`DateField`/`Calendar`/`CheckboxGroup`/`CheckboxCards`/`RadioGroup`/`RadioCards`) + their
`Props` added, and the two folds add **0** new names. *(Proves INV-1.)*

## S-10 · The 1:1 story↔folder invariant holds (K-8)
*As a **Storybook maintainer**, I want each new component to carry exactly one co-located story, so that the mx.4
invariant stays intact.*
**Given** the 6 new folders, **when** `pnpm sb:typecheck` + `pnpm sb:build` run, **then** `sb:typecheck` exits 0
(the NO-INVENT story gate), `count(*.stories.tsx) == count(component folders)`, `sb:build` registers exactly the
prior homes + 6, and the `Textarea` + `Toggle` stories are refreshed in place (no net home change for the
folds). *(Proves INV-9.)*

## S-11 · The token/font reconcile is additive-only (K-9)
*As a **token owner**, I want no existing token value changed, so that the rest of the library is undisturbed.*
**Given** `tokens.css` + the font layer, **when** `git diff` is read, **then** any change is an **added** line,
never a changed value. *(Proves INV-10.)*

## S-12 · The gate is green; design flowed DOWN; the dep-graph is clean (K-9)
*As a **Director**, I want the full package gate green, no design push, and no hidden dependency edge, so that the
batch ships clean.*
**Given** the 6 net-new components + the 2 folds, **when** the gate runs — `pnpm --filter "./packages/*"
typecheck`/`build` · `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` · `pnpm sb:typecheck` ·
`pnpm sb:build` — **then** every command exits 0, the barrel-diff is 0 removed/renamed (+6, one `ToggleGroup`),
the idiom/hex/`mercAccent`/accent-not-forwarded/framing greps are empty, **`grep "@internationalized/date"
packages/mercury-ui/src` is empty** with `mercury-ui/package.json` deps unchanged (unless the Operator ruled A2
arm (b)), and **no** `/design-sync`/`DesignSync` invocation occurred. *(Proves INV-6 + INV-11 + INV-12.)*
