# mx.7.3.2 · acceptance stories

Given/When/Then for [`mx.7.3.2.md`](./mx.7.3.2.md). **Coverage:** K-1 → S-1 ; K-2 → S-2 ; K-3/K-4/K-6 → S-1 ;
K-5 → S-1,S-3 ; K-7 → S-4 ; K-8 → S-5 ; K-9 → S-6.

## S-1 · Calendar is a month-grid picker, accent class-driven, on the ruled date arm (K-1, K-3, K-4, K-5, K-6)
*As a **scheduling author**, I want a `Calendar` grid to pick a day and page months, so that I have a visual date
picker.*
**Given** `inputs/Calendar/` (4 files), **when** `<Calendar accent="indigo">` renders and prev/next is pressed or
a day chosen, **then** `.mx-calendar` draws the month grid with today / selected / outside-month states, paging
works, selection is controlled (`value`) + uncontrolled (`defaultValue`), the nav chevron is the **live `Icon`** (a
real glyph, not invented), `accent` resolves via `.mx-calendar--accent-*` (no inline color, no raw hex, no
`mercAccent`), the date arithmetic comes from the **ruled A2 arm** with **no direct `@internationalized/date`
import** in `@mercury/ui` (INV-6), and the contract cross-links `DateField` + `Popover` + `Icon`. *(Proves INV-2 +
INV-4 + INV-5 + INV-6 + INV-8.)*

## S-2 · The barrel grows +1 additively (K-2)
*As a **downstream consumer**, I want every prior export preserved.* **Given** the barrel before/after, **when**
the resolved export set is compared (TS `getExportsOfModule`), **then** it is a superset — 0 removed, 0 renamed —
with `Calendar` + `CalendarProps` (+ the arm's value type) added. *(Proves INV-1.)*

## S-3 · The date layer is consumed without a hidden dependency edge (K-5)
*As a **package owner**, I want no surprise external dependency on `@mercury/ui`.* **Given** the ruled A2 arm,
**when** the deps are read, **then** `grep "@internationalized/date" packages/mercury-ui/src` is empty and
`mercury-ui/package.json` deps are unchanged — unless arm (b) was ruled (one explicit edge); if arm (a),
`pnpm --filter @mercury/core typecheck` exits 0. *(Proves INV-6.)*

## S-4 · The 1:1 story↔folder invariant holds (K-7)
*As a **Storybook maintainer**, I want one co-located story.* **Given** the new folder, **when** `pnpm sb:typecheck`
+ `pnpm sb:build` run, **then** `sb:typecheck` exits 0, the folder holds one `*.stories.tsx`, and `sb:build`
registers prior + 1. *(Proves INV-9.)*

## S-5 · The token/font reconcile is additive-only (K-8)
*As a **token owner**, I want no existing value changed.* **Given** `tokens.css` + the font layer, **when**
`git diff` is read, **then** any change is an added line. *(Proves INV-10.)*

## S-6 · The gate is green; design flowed DOWN (K-9)
*As a **Director**, I want the gate green and no push.* **Given** the net-new `Calendar`, **when** the gate runs
(packages typecheck/build · apps `!@mercury/storybook` build · sb:typecheck · sb:build), **then** every command
exits 0, the barrel-diff is +1/0-removed, the idiom/hex/`mercAccent`/framing greps are empty, and no
`/design-sync`/`DesignSync` ran. *(Proves INV-11 + INV-12.)*
