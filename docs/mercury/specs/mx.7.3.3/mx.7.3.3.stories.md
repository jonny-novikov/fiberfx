# mx.7.3.3 · acceptance stories

Given/When/Then for [`mx.7.3.3.md`](./mx.7.3.3.md). **Coverage:** K-1 → S-1..S-4 ; K-2 → S-5,S-6 ; K-3 → S-7 ;
K-4/K-6 → S-1..S-6 ; K-5 → S-1..S-4 ; K-7 → S-8 ; K-8 → S-9 ; K-9 → S-10. Every component story proves INV-2
(idiom) + INV-8 (D-7 contract) unless noted.

## S-1 · CheckboxGroup composes the live Checkbox, multi-select (K-1, K-4, K-5, K-6)
*As a **form author**, I want a `CheckboxGroup` of `items`, so that I can manage a set where zero-or-more are
checked.* **Given** `selection/CheckboxGroup/`, **when** `<CheckboxGroup items={…} defaultValue={["a"]}
accent="green">` toggles an item, **then** it **composes the live `Checkbox`** (from `../Checkbox`), drives
multi-select controlled (`value`) + uncontrolled (`defaultValue`), lays out by `orientation`, realizes `accent` as
`.mx-checkbox-group--accent-green` — **never forwarded to `Checkbox`** (no `accent` prop) and **never** via
`mercAccent`. *(Proves INV-4 + INV-5.)*

## S-2 · CheckboxCards composes the live Checkbox in a card shell (K-1, K-4, K-5, K-6)
*As a **form author**, I want selectable `CheckboxCards` with a label, description and icon.* **Given**
`selection/CheckboxCards/`, **when** `<CheckboxCards items={…} columns={2} size="md">` selects a card, **then** the
shell (`.mx-checkbox-cards`) **wraps the live `Checkbox`** (indicator + native input + keyboard from the primitive
— §A·A1 (a)), the leading `icon` is the **live `Icon`** (a real glyph), `columns`/`size`/`description`/the selected
ring style via tokens, multi-select is controlled + uncontrolled, and the contract cross-links `CheckboxGroup` +
`Card`. *(Proves INV-5.)*

## S-3 · RadioGroup composes the live Radio, single-select (K-1, K-4, K-5, K-6)
*As a **form author**, I want a `RadioGroup` of `items`, so that exactly one is chosen.* **Given**
`selection/RadioGroup/`, **when** `<RadioGroup items={…} defaultValue="a" name="plan">` selects an item, **then**
it **composes the live `Radio`** (from `../Radio`), drives single-select controlled + uncontrolled, shares `name`,
lays out by `orientation`, realizes `accent` as a group class — **never forwarded to `Radio`**, never via
`mercAccent`. *(Proves INV-4 + INV-5.)*

## S-4 · RadioCards composes the live Radio in a card shell (K-1, K-4, K-5, K-6)
*As a **form author**, I want selectable `RadioCards`.* **Given** `selection/RadioCards/`, **when** `<RadioCards
items={…} columns={2}>` selects a card, **then** the shell (`.mx-radio-cards`) **wraps the live `Radio`** (§A·A1
(a)), exactly one card is chosen (controlled + uncontrolled), `columns`/`size`/`icon`/`description`/the selected
ring style via tokens, and the contract cross-links `RadioGroup` + `Card`. *(Proves INV-5.)*

## S-5 · TextArea folds into the live Textarea — no new export (K-2)
*As a **downstream consumer**, I want the bundle's `TextArea` enhancement folded into `Textarea`, so that I gain
`size` without a renamed/duplicated export.* **Given** the live barrel exports `Textarea`, **when** the fold lands,
**then** `inputs/Textarea/Textarea.tsx` gains `size?: "sm"|"md"|"lg"` + the `.mx-ta--<size>` rules, **every
existing prop is preserved**, **no `TextArea` export is added** and `Textarea` is **not renamed**, and its contract
is refreshed. *(Proves INV-1 + INV-8.)*

## S-6 · ToggleGroup folds into the live ToggleGroup — no new export, no duplicate (K-2)
*As a **downstream consumer**, I want the bundle's `ToggleGroup` enhancements folded in, so that the export surface
gains nothing duplicate.* **Given** the live `ToggleGroup` already exported from `selection/Toggle/Toggle.tsx`,
**when** the fold lands, **then** `ToggleGroup` gains `accent?` (→ `.mx-tgl-grp--accent-<id>`) + an optional group
`disabled?`, the live prop names `onValueChange`/`ariaLabel` are **kept** (not renamed), **no
`selection/ToggleGroup/` folder is created**, and the resolved export set contains `ToggleGroup` **exactly once**.
*(Proves INV-1 + INV-7.)*

## S-7 · The barrel grows +4 additively (K-3)
*As a **downstream consumer**, I want every prior export preserved.* **Given** the barrel before/after, **when**
the resolved export set is compared (TS `getExportsOfModule`), **then** it is a superset — 0 removed, 0 renamed —
with exactly the 4 new names (`CheckboxGroup`/`CheckboxCards`/`RadioGroup`/`RadioCards`) + their `Props` added, and
the two folds add **0** new names. *(Proves INV-1.)*

## S-8 · The 1:1 story↔folder invariant holds (K-7)
*As a **Storybook maintainer**, I want each new component to carry one co-located story.* **Given** the 4 new
folders, **when** `pnpm sb:typecheck` + `pnpm sb:build` run, **then** `sb:typecheck` exits 0,
`count(*.stories.tsx) == count(component folders)`, `sb:build` registers prior + 4, and the `Textarea` + `Toggle`
stories are refreshed in place. *(Proves INV-9.)*

## S-9 · The token/font reconcile is additive-only (K-8)
*As a **token owner**, I want no existing value changed.* **Given** `tokens.css` + the font layer, **when**
`git diff` is read, **then** any change is an added line. *(Proves INV-10.)*

## S-10 · The gate is green; design flowed DOWN (K-9)
*As a **Director**, I want the gate green and no push.* **Given** the 4 net-new + the 2 folds, **when** the gate
runs (packages typecheck/build · apps `!@mercury/storybook` build · sb:typecheck · sb:build), **then** every
command exits 0, the barrel-diff is 0 removed/renamed (+4, one `ToggleGroup`), the idiom/hex/`mercAccent`/
accent-not-forwarded/no-duplicate-folder/framing greps are empty, and no `/design-sync`/`DesignSync` ran. *(Proves
INV-11 + INV-12.)*
