# mx.7.3.3 · the selection composites + the two folds

> **Status: 📋 PLANNED — build-ready; sub-batch 3 of the mx.7.3 split (ships after the date pair).** Inherits the
> sub-epic [`../mx.7.3/mx.7.3.md`](../mx.7.3/mx.7.3.md) and the mx.7 epic [`../mx.7/mx.7.md`](../mx.7/mx.7.md).
> This batch imports the **four managed selection sets** — `CheckboxGroup` · `CheckboxCards` · `RadioGroup` ·
> `RadioCards` — translated into `@mercury/ui`'s `.mx-*` + token idiom, additively, **composing the live
> `Checkbox` / `Radio` primitives**; plus the **two folds** that enrich shipped exports (`Textarea` += `size`;
> `ToggleGroup` += `accent` + group-`disabled`) with **no new export**. It is **pure-presentational** (NORMAL
> risk) — the heavy date machines were shed into mx.7.3.1 / mx.7.3.2.
>
> **Inherited, not re-argued** (mx.7 epic §4/§5): translate to `.mx-*` + tokens; additive-only tokens/fonts;
> never rename / duplicate an existing export; design flows DOWN; the 4-file home + additive barrel + the gate.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · sub-epic: [`../mx.7.3/mx.7.3.md`](../mx.7.3/mx.7.3.md)
· contract template: [`../../contracts.md`](../../contracts.md) · acceptance:
[`mx.7.3.3.stories.md`](./mx.7.3.3.stories.md) · build context: [`mx.7.3.3.llms.md`](./mx.7.3.3.llms.md).

---

## A · The open calls in this batch (Operator rules each)

### A1 — the `*Cards` composition: **compose the live primitive** (Steward = compose)

- **Rationale.** The bundle `CheckboxCards` / `RadioCards` **do not** compose `Checkbox` / `Radio` — each builds a
  `role="checkbox"` / `role="radio"` `<div>` with its own check-glyph / dot span + hand-rolled Space/Enter
  handling. The live library already ships `selection/Checkbox` (native `<input type="checkbox">` + `.mx-cb__box`)
  and `selection/Radio` (native `<input type="radio">` + `.mx-rd__dot`). Re-drawing the indicator duplicates a
  shipped primitive (a DRY + package/app-split tension).
- **Arms.** **(a) Compose the live primitive inside a selectable card shell (RECOMMENDED)** — the card is the
  label; a click toggles the wrapped `Checkbox` / `Radio`; the indicator + native input semantics + keyboard come
  free from the primitive; the card adds the surface (`columns`, `size`, `description`, leading `icon`, the
  selected ring). **(b) Standalone card-select impl** (the bundle's `role="checkbox"` div) — self-contained, full
  card-wide a11y control, but re-implements the indicator the primitive already draws + a second keyboard path.
- **Steward / recommendation: (a)** — DRY + the package/app split. **Operator rules.**

### A3 — the `ToggleGroup` collision: **fold, no new export** (Steward = fold; forced by the master invariant)

- **Rationale.** `ToggleGroup` is **already a live export** (defined + exported inside
  `selection/Toggle/Toggle.tsx`, re-exported by the barrel via `export * from "./components/selection/Toggle"`).
  The bundle `selection/ToggleGroup.tsx` is a richer prototype (adds `accent?` + group `disabled?`; uses `onChange`
  where live uses `onValueChange`, `"aria-label"` where live uses `ariaLabel`). Names are identical → the master
  invariant **forbids** a rename and a second export is a duplicate (build break).
- **Arms.** **(a) Fold the enhancements INTO live `ToggleGroup`; add NO export; create NO `selection/ToggleGroup/`
  folder (RECOMMENDED)** — add `accent?` (→ `.mx-tgl-grp--accent-<id>`) + optional group `disabled?`; **keep** the
  live prop names (`onValueChange`, `ariaLabel`). **(b) Leave live `ToggleGroup` as-is** — no surface change, the
  Claude-Design `accent`/group-`disabled` capability absent. (No "add-distinct" arm — the name is taken.)
- **Steward / recommendation: (a)** — parallel to the `TextArea` fold; folding is what the master invariant makes
  free. **Operator rules** (parity vs minimal-change).

### Recorded resolution (epic-ruled — not re-litigated)

- **`TextArea` fold** (epic Cross-fork III row). bundle `TextArea` ≡ live `Textarea` — **fold**: translate the net
  enrichment **`size?: "sm"|"md"|"lg"`** into the live `Textarea` (the rest — `label`/`hint`/`value`/`rows`/
  `maxLength`/`disabled`/`readOnly`/`placeholder` — is already present, mostly via `extends TextareaHTMLAttributes`).
  **Add NO export; rename nothing.**

## 0 · The slice

Sub-batch 3 — the four managed selection sets (`CheckboxGroup`, `CheckboxCards`, `RadioGroup`, `RadioCards`),
**composing** the live `Checkbox`/`Radio` (§A·A1); plus two folds enriching shipped exports (`Textarea`,
`ToggleGroup`). All translate into the live `.mx-*` + token idiom; the four sets export additively, the two folds
add **no** new export. Pure-presentational.

## 1 · Goal

After mx.7.3.3, `@mercury/ui` exports **4 new components** — `CheckboxGroup · CheckboxCards · RadioGroup ·
RadioCards` — each a translated 4-file home; the live `Textarea` + `ToggleGroup` are **enriched in place** (size;
accent + group-disabled) with **no new export**. The barrel is strictly additive (+4 + their `Props`; 0
removed/renamed; **exactly one** `ToggleGroup` export). The full package gate is green; `sb:build` registers prior
+ 4 (the `Textarea` + `Toggle` stories refreshed in place).

## 2 · Rationale (5W)

- **Why.** Forms need managed selection — a checkbox set, a radio set, selectable cards — built on the mx.7.1
  `Label` + the shipped `Checkbox`/`Radio`, not re-drawn. The folds bring the bundle's `size`/`accent`
  enrichments to the live `Textarea`/`ToggleGroup`.
- **What.** The 4 translated homes, the 2 folds, the barrel +4, the `.mx-*` rules in `additions.css` (incl. the
  `.mx-<name>--accent-<id>` ramps reused from mx.7.1), per §A·A1.
- **Who.** *Authored by* the architect + the build/verify agents. *Consumed by* mx.8 (their stories), mx.9 (the
  showcase forms), and consumers.
- **When.** Sub-batch 3 — last of the mx.7.3 split, after the date pair.
- **Where.** Only `packages/mercury-ui/src/` — the 4 new folders + the 2 fold files
  (`inputs/Textarea/Textarea.tsx`, `selection/Toggle/Toggle.tsx`) + barrel + `additions.css` — +
  `docs/mercury/specs/mx.7.3.3/`. The bundle `packages/mercury-ds/` is read-only.

## 3 · The component set (grounded — bundle prop surface verified in source)

| Component | Bundle source | Prototype prop surface (the seed) | Live action |
|---|---|---|---|
| `CheckboxGroup` | `selection/CheckboxGroup/CheckboxGroup.tsx` | `items: {value,label?,disabled?}[]` · `value?: string[]` · `defaultValue?: string[]` · `onChange?: (string[]) => void` · `accent?` · `orientation?: vertical\|horizontal` · `disabled?` (composes **live `Checkbox`**) | **net-new** `selection/CheckboxGroup` |
| `CheckboxCards` | `selection/CheckboxCards/CheckboxCards.tsx` | `items: {value,label?,description?,icon?: IconName,disabled?}[]` · `value?: string[]` · `defaultValue?` · `onChange?` · `accent?` · `columns?=1` · `size?: sm\|md\|lg` | **net-new** `selection/CheckboxCards` |
| `RadioGroup` | `selection/RadioGroup/RadioGroup.tsx` | `items: {value,label?,disabled?}[]` · `value?: string` · `defaultValue?: string` · `onChange?: (string) => void` · `name?` · `accent?` · `orientation?` · `disabled?` (composes **live `Radio`**) | **net-new** `selection/RadioGroup` |
| `RadioCards` | `selection/RadioCards/RadioCards.tsx` | `items: {value,label?,description?,icon?: IconName,disabled?}[]` · `value?: string` · `defaultValue?` · `onChange?` · `accent?` · `columns?=1` · `size?` | **net-new** `selection/RadioCards` |
| `TextArea`* | `inputs/TextArea/TextArea.tsx` | `value`/`defaultValue`/`onChange` · `placeholder` · `rows?=4` · `size?: sm\|md\|lg` · `disabled` · `readOnly` · `invalid?` · `resize?` · `maxLength` · `label`/`hint` | **FOLD** → enrich live `inputs/Textarea` (net add: `size`) — **no new export** |
| `ToggleGroup`* | `selection/ToggleGroup/ToggleGroup.tsx` | `type?: single\|multiple` · `items: {value,label?,icon?,"aria-label"?}[]` · `value?`/`defaultValue?` · `onChange?` · `size?` · `accent?` · `disabled?` | **FOLD** → enrich live `ToggleGroup` (in `selection/Toggle/Toggle.tsx`; net add: `accent`, group-`disabled`) — **no new export** |

`*` folds of existing live exports (`Textarea`, `ToggleGroup`) — work items that enrich the live component, adding
**no** new export (renaming/duplicating either is forbidden — master invariant).

## 4 · Translation notes (the deltas beyond the epic / mx.7.1 idiom)

- **`accent` has NO live primitive prop to forward to — realize it at the GROUP.** Live `Checkbox` / `Radio` /
  `Toggle` carry **no `accent` prop** (verified). So a group must **not** pass `accent` to the wrapped primitive
  (an INVENTED surface — NO-INVENT). Realize `accent` as a group wrapper class
  (`.mx-checkbox-group--accent-<id>` / `.mx-radio-group--accent-<id>` / the card shell / `.mx-tgl-grp--accent-<id>`)
  that sets the token color the child indicator reads (the mx.7.1 `.mx-<name>--accent-<id>` ramp set
  `iris|indigo|green|orange|plum|red`). **No `mercAccent` import** anywhere (epic Cross-fork I).
- **`CheckboxGroup` / `RadioGroup` — compose the live primitive directly.** `import { Checkbox } from
  "../Checkbox"` / `import { Radio } from "../Radio"`. Forward `checked` / `disabled` / `label` / (`name`/`value`
  for Radio) — **not** `accent`. Live `Checkbox.onChange` is `(checked: boolean) => void`, live `Radio.onChange`
  is `(value: string) => void`; the group toggles by `item.value` (matches the bundle). `orientation` → a
  `.mx-*-group--horizontal` flex-direction modifier.
- **`CheckboxCards` / `RadioCards` — compose the live primitive in a card shell (per §A·A1 arm (a)).** The card
  `<div className="mx-checkbox-cards__card">` wraps the live `Checkbox` / `Radio` (indicator + native input +
  keyboard from the primitive); the shell adds `columns` (grid), `size` (paddings), a leading `icon` (the live
  `Icon`, a **real glyph** — verify against the live set, mx.7.2 L5), a `description`, and the selected ring
  (`box-shadow: inset 0 0 0 2px` reading the accent token). Multi-select (`string[]`) for checkbox cards, single
  (`string`) for radio cards.
- **The `Textarea` fold — add `size` only.** Add `size?: "sm"|"md"|"lg"` to `TextareaProps` + the `.mx-ta--<size>`
  rules (the bundle's `PAD`/`FS` scale → token-driven padding / font-size). Keep every existing prop + the
  `error`/`hint`/`maxLength` footer; **rename nothing; add no export.**
- **The `ToggleGroup` fold — add `accent` + group `disabled`.** Add `accent?: "iris"|…|"red"` (→
  `.mx-tgl-grp--accent-<id>`) + optional group `disabled?` to the live `ToggleGroupProps`; **keep**
  `onValueChange` / `ariaLabel` (do **not** adopt the bundle's `onChange` / `"aria-label"` — adding a prop is
  additive, renaming one is not). **Add no export; create no `selection/ToggleGroup/` folder.**

## 5 · Deliverables

- **K-1 — 4 net-new translated 4-file homes** under `selection/` (`CheckboxGroup` · `CheckboxCards` · `RadioGroup`
  · `RadioCards`): `<Name>.tsx` · `index.ts` · `<Name>.prompt.md` (D-7) · `<Name>.stories.tsx` (CSF3).
- **K-2 — 2 folds, NO new export** (§A·A3 + the TextArea row): enrich `inputs/Textarea/Textarea.tsx` (`size`) +
  live `ToggleGroup` in `selection/Toggle/Toggle.tsx` (`accent` + group-`disabled`); rename/duplicate nothing; **no
  `selection/ToggleGroup/` folder**.
- **K-3 — the barrel grows +4 additively** (+ their `Props`); every prior export byte-preserved; **exactly one**
  `ToggleGroup`; barrel-diff 0 removed/renamed.
- **K-4 — the live idiom** (Cross-fork I): `.mx-*` + tokens; no inline color literal; no raw hex; `accent` via
  `.mx-*--accent-<id>` (no `mercAccent`).
- **K-5 — composition real, accent at the group** (§A·A1): the groups + the `*Cards` compose the live
  `Checkbox`/`Radio`; `accent` is a group/card wrapper class, **never** forwarded to the primitive.
- **K-6 — a hand-authored contract per net-new + the two folds refreshed** (D-7): mx.2 format; no bundle framing;
  cross-links (`CheckboxGroup`↔`Checkbox`; `RadioGroup`↔`Radio`; `CheckboxCards`/`RadioCards`↔their group + `Card`;
  `ToggleGroup`↔`Toggle`+`Segmented`; `Textarea`↔`Input`).
- **K-7 — the 1:1 story↔folder invariant holds**; `sb:build` registers prior + 4; the `Textarea` + `Toggle`
  stories refreshed in place.
- **K-8 — token/font additive-only** · **design flowed DOWN**.
- **K-9 — the gate is green** (§7).

**Coverage:** K-1 → S-1..S-4 ; K-2 → S-5,S-6 ; K-3 → S-7 ; K-4 → S-1..S-6 ; K-5 → S-1..S-4 ; K-6 → S-1..S-6 ;
K-7 → S-8 ; K-8 → S-9 ; K-9 → S-10.

## 6 · The per-component translation map

- **CheckboxGroup** (`selection/CheckboxGroup`). `.mx-checkbox-group`; composes live `Checkbox`; multi-select
  controlled+uncontrolled; `orientation`; `accent` at the group class. Cross-link `Checkbox`.
- **CheckboxCards** (`selection/CheckboxCards`). `.mx-checkbox-cards`; composes live `Checkbox` in a card shell
  (§A·A1); `columns`/`size`/`icon`/`description`/selected ring; multi-select. Cross-link `CheckboxGroup` + `Card`.
- **RadioGroup** (`selection/RadioGroup`). `.mx-radio-group`; composes live `Radio`; single-select; `orientation`;
  `accent` at the group class. Cross-link `Radio`.
- **RadioCards** (`selection/RadioCards`). `.mx-radio-cards`; composes live `Radio` in a card shell; single-select.
  Cross-link `RadioGroup` + `Card`.
- **Textarea** (FOLD). Add `size?: sm|md|lg` + `.mx-ta--<size>`; keep all else. No export.
- **ToggleGroup** (FOLD, in `selection/Toggle/Toggle.tsx`). Add `accent?` + `.mx-tgl-grp--accent-<id>` + group
  `disabled?`; keep `onValueChange`/`ariaLabel`. No export. Cross-link `Toggle` + `Segmented`.

## 7 · Invariants — as runnable gates (run from `mercury/`)

- **INV-1 — master invariant, additive.** superset; **0 removed/renamed**, +4 (+ `Props`); the two folds add **0**
  new export. (TS `getExportsOfModule`.)
- **INV-2 — no inline color leak.** `grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})"` over the 4 new dirs + the
  two fold files → empty (dynamic non-color inline — grid `columns` — allowed).
- **INV-3 — no raw hex.** over the 4 new dirs + the two fold files + the new `additions.css` rules → empty.
- **INV-4 — no `mercAccent` import.** `grep -rn "mercAccent\|_lib/accent" packages/mercury-ui/src/components` → empty.
- **INV-5 — composition real, accent NOT forwarded.** the groups + `*Cards` import live `Checkbox`/`Radio`;
  `grep -rnE "<(Checkbox|Radio)[^>]*accent=" packages/mercury-ui/src/components/selection` → empty.
- **INV-7 — exactly one `ToggleGroup`; no duplicate folder.** the resolved export set contains `ToggleGroup`
  **once**; `test ! -d packages/mercury-ui/src/components/selection/ToggleGroup`.
- **INV-8 — D-7 contract, no bundle framing.** each net-new `.prompt.md` (+ refreshed `Textarea`/`Toggle`) has the
  mx.2 sections; the framing grep over the new/changed contracts → empty.
- **INV-9 — 1:1 story↔folder + `sb:typecheck` clean.** `count(*.stories.tsx) == count(component folders)`;
  `pnpm sb:typecheck` exits 0; `pnpm sb:build` registers prior + 4.
- **INV-10 — token/font additive-only.** **INV-11 — design flows DOWN.**
- **INV-12 — the package gate** (typecheck/build · apps `!@mercury/storybook` · sb:typecheck · sb:build = 0).

## 8 · The batch loop — Trio (Operator-directed)

As the sub-epic cadence (the REAL aaw Trio, scope slug `mx-7-3-3`), carrying the date batches' token/font lessons.
Pure-presentational → NORMAL verify (no Apollo needed); the Director's solo verify is the gate (composition-real +
accent-not-forwarded + the exactly-one-`ToggleGroup` barrel check + a net-zero mutation spot-check).

## 9 · As-built (the verifier — filled post-build)

> Classify K-1..K-9 / INV-1..INV-12 / S-1..S-10; record the ratified §A·A1/A3 arms; list the 4 net-new folders +
> the two folds applied (the exact props added — `Textarea.size`, `ToggleGroup.accent`/`disabled`); reproduce the
> gate (EXIT 0) incl. the barrel-diff (+4, exactly one `ToggleGroup`), the `sb:build` +4 home delta, and the
> idiom/hex/mercAccent/accent-not-forwarded/no-duplicate-folder/framing/no-design-sync greps (empty).
