# mx.7.3.1 · acceptance stories

Given/When/Then for [`mx.7.3.1.md`](./mx.7.3.1.md). Connextra form; each names its deliverable + the
invariant(s) it proves. **Coverage:** K-1 → S-1 ; K-2 → S-2 ; K-3/K-6 → S-1 ; K-4 → S-1,S-3 ; K-5 → S-1 ;
K-7 → S-4 ; K-8 → S-5,S-6 ; K-9 → S-6.

## S-1 · DateField is a segmented date input composing the @mercury/core useDateField composable (K-1, K-3, K-4, K-5, K-6)
*As a **form author**, I want a `DateField` I can type mm/dd/yyyy into or arrow each part, so that I can enter a
date with the keyboard.*
**Given** `inputs/DateField/` (4 files), **when** `<DateField defaultValue={…}>` renders and a segment is typed
or arrowed, **then** it styles via `.mx-datefield` (no inline color, no raw hex, no `mercAccent`), keeps
`role="spinbutton"` per segment with `aria-label`/`aria-valuenow`/`aria-valuemin`/`aria-valuemax`/`inputMode="numeric"`,
filters to digits, hands the caret to the next segment on fill, increments/wraps on ArrowUp/Down, drives controlled
(`value`) + uncontrolled (`defaultValue`) use, and takes its value model + arithmetic from the curated
`@mercury/core` **`useDateField`** composable (A2 ruled arm (a)) — exposing a mature **`DateValue`**, with **no
direct `@internationalized/date` import** in `@mercury/ui` (INV-6), and its hand-authored contract cross-links
`Calendar` + `Input`. *(Proves INV-2 + INV-4 + INV-6 + INV-8.)*

## S-2 · The barrel grows +1 additively (K-2)
*As a **downstream consumer**, I want every prior export preserved, so that nothing I import breaks.*
**Given** the `@mercury/ui` barrel before/after, **when** the resolved export set is compared (TS
`getExportsOfModule`, not a text-diff), **then** it is a **superset** — 0 removed, 0 renamed — with exactly the
new `DateField` + `DateFieldProps` added (the `DateValue` value type + the date kit live on the `@mercury/core`
barrel, not `@mercury/ui`). *(Proves INV-1.)*

## S-3 · The date layer is composed through @mercury/core, no hidden dependency edge (K-4)
*As a **package owner**, I want the mature date foundation reused through `@mercury/core` with no surprise external
dependency on `@mercury/ui`, so that a strict install resolves and the date logic stays in the layer that owns it.*
**Given** the ruled A2 arm (a), **when** the build runs and the deps are read, **then** `@mercury/core` surfaces a
curated `useDateField` composable + the date value kit (`type DateValue` / `CalendarDate` / `parseDate`) over
`internal/date-time` (`D-5`: curated, no wholesale widen; no `@/` in a barrel-reachable file), `pnpm --filter
@mercury/core typecheck` exits 0, `grep "@internationalized/date" packages/mercury-ui/src` is **empty**, and
`mercury-ui/package.json` `dependencies` is unchanged (only `@mercury/core`). *(Proves INV-6.)*

## S-4 · The 1:1 story↔folder invariant holds (K-7)
*As a **Storybook maintainer**, I want the new component to carry exactly one co-located story, so that the mx.4
invariant stays intact.*
**Given** the new folder, **when** `pnpm sb:typecheck` + `pnpm sb:build` run, **then** `sb:typecheck` exits 0 (the
NO-INVENT story gate), the folder holds exactly one `*.stories.tsx`, and `sb:build` registers exactly the prior
homes + 1. *(Proves INV-9.)*

## S-5 · The token/font reconcile is additive-only (K-8)
*As a **token owner**, I want no existing token value changed, so that the rest of the library is undisturbed.*
**Given** `tokens.css` + the font layer, **when** `git diff` is read, **then** any change is an **added** line,
never a changed value. *(Proves INV-10.)*

## S-6 · The gate is green; design flowed DOWN (K-8, K-9)
*As a **Director**, I want the full package gate green and no design push, so that the batch ships clean.*
**Given** the net-new `DateField` (+ any ruled core edit), **when** the gate runs — `pnpm --filter "./packages/*"
typecheck`/`build` · `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` · `pnpm sb:typecheck` ·
`pnpm sb:build` — **then** every command exits 0, the barrel-diff is 0 removed/renamed (+1), the
idiom/hex/`mercAccent`/framing greps are empty, and **no** `/design-sync`/`DesignSync` invocation occurred.
*(Proves INV-11 + INV-12.)*
