# mx.7.3.1 · DateField — the segmented date input

> **Status: 📋 PLANNED — build-ready; A2 RULED (arm a — compose Mercury's owned date foundation); sub-batch 1
> of the mx.7.3 split (the FIRST to ship).** Inherits the
> sub-epic [`../mx.7.3/mx.7.3.md`](../mx.7.3/mx.7.3.md) (the split + the routed forks) and the mx.7 epic
> [`../mx.7/mx.7.md`](../mx.7/mx.7.md) (the cross-batch forks + the shared translation contract). This batch
> imports **one** net-new component — `DateField`, a segmented mm/dd/yyyy spinbutton — translated from the
> bundle's inline-style prototype into `@mercury/ui`'s `.mx-*` + token idiom, additively. It is a **stateful
> keyboard machine** (caret hand-off on fill + arrow increment with wrap), the elevated-verify focus.
>
> **The batch's one load-bearing call, A2 — the date-lib (§A), is RULED (Operator, 2026-06-30): arm (a) —
> `DateField` composes Mercury's mature, owned date foundation** (the `@mercury/core` formatters + the
> `internal/date-time` machinery + the shared composables) via a curated, reusable `useDateField` composable; the
> bundle is the anatomy/visual/a11y seed only. arm (c) native-throwaway + arm (b) ui-direct are OFF. INV-6 holds
> (ui consumes the date layer through `@mercury/core`, never imports `@internationalized/date`).
>
> **Inherited, not re-argued** (mx.7 epic §4/§5): translate to `.mx-*` + tokens; additive-only tokens/fonts;
> never rename an existing export; design flows DOWN (no `/design-sync`); the 4-file home + additive barrel + the
> gate.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · sub-epic: [`../mx.7.3/mx.7.3.md`](../mx.7.3/mx.7.3.md)
· prior batch: [`../mx.7.2/mx.7.2.md`](../mx.7.2/mx.7.2.md) · contract template:
[`../../contracts.md`](../../contracts.md) · acceptance: [`mx.7.3.1.stories.md`](./mx.7.3.1.stories.md) · build
context: [`mx.7.3.1.llms.md`](./mx.7.3.1.llms.md).

---

## A · The ruled call in this batch (Operator RULED 2026-06-30)

### A2 — RULED: arm (a) — `DateField` composes Mercury's mature, owned date foundation

The batch's sole fork is **ruled**. The Operator's standard: `DateField` is built on **Mercury's robust,
reusable, owned date foundation** — the `@mercury/core` formatters + the `internal/date-time` segment machinery +
the shared composables — **not** the bundle's throwaway `{m,d,y}` / `parseInt` / `bump` logic. "Translate the
prototype" means its **anatomy / visual / structure + the per-segment spinbutton a11y**; the **value / validity /
arithmetic** is the mature foundation's, exposed through a curated, reusable composable.

- **RULED — arm (a): compose, do not reinvent.** Build a curated `useDateField` composable in `@mercury/core`
  over the existing machinery. It is a **compose**, not a from-scratch derivation — the value object, locale-correct
  segment order + per-segment display, fill-detection, value reconstruction, navigation, parsing, defaults,
  placeholders, and the `@internationalized/date` `.cycle()`/`.set()` arithmetic **already exist** (mapped in
  [`mx.7.3.1.llms.md`](./mx.7.3.1.llms.md)); the hook adds the React state container + the per-keystroke segment
  reducer + the prop-getters. `DateField` consumes it through `@mercury/core`. The public value type is the
  **mature `DateValue`** (re-exported through `@mercury/core`), never the bundle's strings.
- **arm (c) native-throwaway is OFF** (the bundle's `{m,d,y}` / `parseInt` / `bump` is the anatomy seed only).
  **arm (b) ui-direct is OFF** (INV-6).
- **The curated core surface (`D-5`, minimal):** `useDateField` (the composable) + `type DateValue` (the public
  value type) + the value kit `CalendarDate` / `parseDate` (so `@mercury/ui` and apps construct a value with **no**
  direct `@internationalized/date` dep — reused by `Calendar`). The deep `internal/date-time` machinery stays
  internal; only the hook + value kit cross the barrel. Boundary imports the consumer pulls are relative / `#`-subpath
  (mirroring the already-barrel-surfaced `date.ts`/`formatter.ts`), **never `@/`** (the mx.1 landmine).
- **REUSE plan (the heart of the ruling).** The shared core is the `internal/date-time` foundation itself.
  `Calendar` (mx.7.3.2) composes the **grid** slice (`Month` / `getLastFirstDayOfWeek` / `getDaysInMonth`) + the
  **same** value kit via a sibling `useCalendar` — **no second machinery copy, no god-hook**. Two thin curated
  composables over one owned foundation.
- **INV-6 (hard, holds):** `@mercury/ui` must **not** `import "@internationalized/date"` directly — it imports
  `useDateField` + `type DateValue` (+ the value kit) **through `@mercury/core`**. A type/constructor re-exported
  through core carries no `@internationalized/date` specifier in `@mercury/ui/src`, so the INV-6 grep stays empty.
- **Effort honesty.** This is the heaviest item in the sub-epic (why it was split out): a real core composable, not
  a 10-line wrapper. But it is a **compose** — the one piece of genuinely new logic is the per-keystroke segment
  reducer (digit entry with `lastKeyZero`/overflow + `.cycle()` arrow wrap + backspace), the field's irreducible
  behavior; everything beneath it is the existing foundation. **No machinery gap forces re-derivation** (if one
  surfaces mid-build, Mars flags it — it is not expected).

## 0 · The slice

Sub-batch 1 — **`DateField`** alone: a segmented mm/dd/yyyy spinbutton, translated into the live `.mx-*` + token
idiom, exported additively as a 4-file home that **composes a curated `useDateField` composable** built (this rung)
in `@mercury/core` over the mature `internal/date-time` foundation (A2 ruled arm (a)). The value model + arithmetic
are the foundation's, surfaced through the composable; the public value type is the mature `DateValue`. It is the
only stateful keyboard machine in this batch — the elevated-verify focus.

## 1 · Goal

After mx.7.3.1, `@mercury/ui` exports **1 new component** — `DateField` (+ `DateFieldProps`; the public value type
is `DateValue`, re-exported through `@mercury/core`) — a translated 4-file home (`.mx-datefield` + tokens ·
hand-authored contract · CSF3 story); **and `@mercury/core` exports a curated, reusable `useDateField` composable +
the date value kit** (`type DateValue` + `CalendarDate` / `parseDate`) over the existing `internal/date-time`
machinery (`D-5`: curated, never a wholesale widen). The `@mercury/ui` barrel is strictly additive (+1 component
name + `DateFieldProps`; 0 removed/renamed). The full package gate is green incl. `pnpm --filter @mercury/core
typecheck`; `sb:build` registers prior homes + 1; `@mercury/ui` gains **no direct `@internationalized/date` import**
(INV-6) and **no new external dependency edge** (the date dep stays on `@mercury/core`, where it already lives).

## 2 · Rationale (5W)

- **Why.** Forms need keyboard date entry — a field you type `mm/dd/yyyy` into or arrow each part. It is the
  typed half of the date pair (the picker grid is mx.7.3.2 `Calendar`); mx.9's showcase forms compose it.
- **What.** The curated `@mercury/core` `useDateField` composable (+ the date value kit) over the mature
  `internal/date-time` foundation, the translated `DateField` home that composes it, the barrel +1, and the
  `.mx-datefield` rules in `additions.css`.
- **Who.** *Authored by* the architect (this triad) + the batch's build/verify agents (the Trio). *Consumed by*
  mx.7.3.2 (`Calendar` cross-links it; independent), mx.8 (its story), mx.9 (showcase forms), and consumers.
- **When.** Sub-batch 1 of the mx.7.3 split — ships first, with the Operator in the loop before mx.7.3.2.
- **Where.** `packages/mercury-ui/src/components/inputs/DateField/` (the 4-file home) + `src/index.ts` (+1 line) +
  `src/styles/additions.css` (the `.mx-datefield` rules) + `docs/mercury/specs/mx.7.3.1/` — **and** (A2 ruled
  arm (a)) `packages/mercury-core/src/` (the new `useDateField` composable file + the curated `src/index.ts` barrel
  additions: the hook + `type DateValue` + the value kit). The bundle `packages/mercury-ds/` is read-only (anatomy
  seed).

## 3 · The component (grounded — bundle prop surface verified in source)

| Component | Bundle source | Prototype prop surface (verified — the seed) | Live action |
|---|---|---|---|
| `DateField` | `inputs/DateField/DateField.tsx` (78 lines) | `value?: DateValue` · `defaultValue?: Partial<DateValue>` · `onChange?: (DateValue) => void` · `label?: ReactNode` · `disabled?: boolean` — where bundle `DateValue = { month: string; day: string; year: string }`; segments `[{month,mm,1–12},{day,dd,1–31},{year,yyyy,1–9999}]`; digit-only input, caret hand-off on fill, ArrowUp/Down ± with wrap | **net-new** `inputs/DateField` |

> **RULED arm (a):** the **public** value type `DateField` exposes is the mature **`DateValue`** (re-exported
> through `@mercury/core`): `value?: DateValue` · `defaultValue?: DateValue` · `onChange?: (value: DateValue |
> undefined) => void`, produced by the curated `useDateField` composable; `label?: ReactNode` · `disabled?:
> boolean` carry over, plus `locale?: string` (the hook needs it; default `"en"`). The bundle's `{month,day,year}`
> string model + `SEGMENTS` / `bump` are the **anatomy / visual seed only** — the value, arithmetic, locale-correct
> segment order, and placeholders come from the foundation. `minValue` / `maxValue` are available on the hook but
> **deferred** from the public surface (additive later — do not gold-plate). Export names: `DateField` +
> `DateFieldProps`.

## 4 · Translation notes (the deltas beyond the epic / mx.7.1 idiom)

- **Translate the segmented spinbutton; the value model comes from the ruled A2 arm.** Keep the controlled
  (`value`) + uncontrolled (`defaultValue`) split and the a11y shape: each segment `role="spinbutton"`,
  `aria-label` per segment (`"month"`/`"day"`/`"year"`), `aria-valuenow`/`aria-valuemin`/`aria-valuemax`,
  `inputMode="numeric"`; digit-only filtering; **caret hand-off** to the next segment when a segment fills;
  **ArrowUp/Down** increment with min/max **wrap**; the year segment is 4-wide, month/day 2-wide zero-padded.
- **Style via `.mx-datefield` — no inline color literal, no raw hex.** The `.mx-datefield` rule reads the
  **complete** token set the bundle reads (verified in `DateField.tsx`): field box background `--bg-primary`; box
  border `--border-primary` (resting) → `--border-focus` (focused) with a `--ring-focus` 3px focus ring;
  `--font-secondary` (DM Mono) for the field text + segment glyphs; `--fg-primary` for the field text **and** the
  label; `--fg-tertiary` for the `/` segment separators; `--font-primary` (weight 500) for the label; the disabled
  state is `opacity ~0.6` + `cursor: not-allowed`. **All are present in `tokens.css` — no fold needed (INV-10
  stays clean).** The bundle's inline `style={{ font, color, … }}` values are **dropped** in favour of the
  `.mx-datefield` rule. **Dynamic non-color inline is allowed** (a segment's character width — bundle `seg.w`
  24/24/44) — color literals are the INV-2 fail.
- **Guard React-19 nullable `useRef().current`** on the segment refs (the `if (ref.current)` idiom the live
  `Checkbox`/`Accordion` use).
- **`accent`?** The bundle `DateField` has **no** `accent` prop — do **not** invent one (NO-INVENT). (Accent on
  the date pair is a `Calendar`-only surface, mx.7.3.2.)

## 5 · Deliverables

- **K-1 — 1 net-new translated 4-file home** `packages/mercury-ui/src/components/inputs/DateField/`:
  `DateField.tsx` (translated) · `index.ts` (`export * from "./DateField"`) · `DateField.prompt.md`
  (hand-authored, D-7) · `DateField.stories.tsx` (CSF3, mx.4 shape).
- **K-2 — the barrel grows +1 additively** (`DateField` + `DateFieldProps` [+ the arm's value type]); every prior
  export byte-preserved; barrel-diff 0 removed/renamed.
- **K-3 — the live idiom** (epic Cross-fork I): `.mx-datefield` + tokens; no inline color literal; no raw hex; no
  `mercAccent` import.
- **K-4 — the curated core composable (A2 ruled arm (a)):** `@mercury/core` gains a curated, reusable
  `useDateField` composable + the date value kit (`type DateValue` + `CalendarDate` / `parseDate`) over the
  existing `internal/date-time` machinery — curated barrel additions, **never** a wholesale widen (`D-5`); boundary
  imports relative / `#`-subpath, never `@/`. `DateField`'s value model + arithmetic are the composable's output (a
  `DateValue`). `@mercury/ui` adds **no direct `@internationalized/date` import** (INV-6) and **no new external
  dependency edge** (the date dep stays on `@mercury/core`).
- **K-5 — the keyboard machine is faithful:** controlled + uncontrolled; per-segment spinbutton a11y; caret
  hand-off on fill; ArrowUp/Down ± wrap; digit-only input.
- **K-6 — a hand-authored contract** (D-7): mx.2 format; no bundle runtime framing; cross-links
  (`DateField`↔`Calendar` [mx.7.3.2] + `Input`).
- **K-7 — the 1:1 story↔folder invariant holds** (mx.4 S-1): one co-located story; `sb:build` registers prior + 1.
- **K-8 — token/font additive-only** (epic Cross-fork II) · **design flowed DOWN** (no `/design-sync`).
- **K-9 — the gate is green** (§7).

**Coverage:** K-1 → S-1 ; K-2 → S-2 ; K-3 → S-1 ; K-4 → S-1,S-3 ; K-5 → S-1 ; K-6 → S-1 ; K-7 → S-4 ; K-8 →
S-5,S-6 ; K-9 → S-6.

## 6 · The per-component translation map

- **DateField** (`inputs/DateField` → `inputs/DateField`). `.mx-datefield`; segmented mm/dd/yyyy spinbutton, caret
  hand-off, arrow ± wrap, focus ring; controlled + uncontrolled; value model via the curated `useDateField`
  composable (A2 ruled arm (a), §A·A2) — locale-correct segment order + placeholders + `.cycle()` arithmetic from
  the `@mercury/core` foundation; public type `DateValue`; DM Mono glyphs. Cross-link `Calendar` (mx.7.3.2, reuses
  the same foundation) + `Input`.

## 7 · Invariants — as runnable gates (run from `mercury/`)

- **INV-1 — master invariant, additive.** Resolved export set after = superset of before; **0 removed/renamed**,
  +1 (`DateField` + `DateFieldProps` [+ the arm's value type]). (TS `getExportsOfModule`, not a text-diff.)
- **INV-2 — live idiom, no inline color leak.** `grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})"
  packages/mercury-ui/src/components/inputs/DateField` → **empty** (dynamic non-color inline — segment width — is
  allowed).
- **INV-3 — no raw hex.** `grep -rnE "#[0-9a-fA-F]{3,8}\b" packages/mercury-ui/src/components/inputs/DateField`
  + the new `additions.css` rules → **empty**.
- **INV-4 — no `mercAccent` import.** `grep -rn "mercAccent\|_lib/accent"
  packages/mercury-ui/src/components/inputs/DateField` → **empty**.
- **INV-6 — date-lib dep-graph-visibility** (§A·A2, ruled arm (a)). `grep -rn "@internationalized/date"
  packages/mercury-ui/src` → **empty** (consume the date layer — `useDateField` + `type DateValue` + the value kit —
  **through `@mercury/core`**); `packages/mercury-ui/package.json` `dependencies` unchanged (only `@mercury/core`).
  The new `@mercury/core` barrel additions are curated (`D-5`) and any file reachable from the core barrel uses
  relative / `#`-subpath imports, **never `@/`** (`grep -rn "@/" packages/mercury-core/src/<the new hook file>` →
  empty).
- **INV-8 — D-7 contract, no bundle framing.** `DateField.prompt.md` has the mx.2 sections; `grep -rniE
  "check_design_system|pixel-perfect|/design-sync|showcase/" packages/mercury-ui/src/components/inputs/DateField`
  → **empty**.
- **INV-9 — 1:1 story↔folder + `sb:typecheck` clean.** One `*.stories.tsx` in the folder; `pnpm sb:typecheck`
  exits 0 (the authoritative story NO-INVENT gate); `pnpm sb:build` registers prior + 1.
- **INV-10 — token/font additive-only:** a `tokens.css`/font edit is an added line, never a changed value.
- **INV-11 — design flows DOWN.** No `/design-sync`/`DesignSync`; `git diff` touches no `mercury/.design-sync/`
  path.
- **INV-12 — the package gate.** `pnpm --filter "./packages/*" typecheck`/`build` = 0 · `pnpm --filter "./apps/*"
  --filter "!@mercury/storybook" build` = 0 (`echomq`+`mobile`) · `pnpm sb:typecheck` = 0 · `pnpm sb:build` = 0 ·
  `pnpm --filter @mercury/core typecheck` = 0 (the curated `useDateField` composable + value kit).

## 8 · The batch loop — the REAL aaw Trio (Operator-directed)

Operator sharpens this triad (+ rules A2) → **`venus`** (architect) reconciles lag-1 vs the as-built `@mercury/ui`
+ the bundle + the core date layer, frames A2 with the grounded cost, authors the build brief → **Director rules
A2** (`AskUserQuestion`) → **`mars`** (implementor) builds the `DateField` home + the contract + the story + the
styles (+ if arm (a), the curated core hook) to the ruled arm, runs the gate → **Director verify** (independent
gate re-run + barrel-diff + the INV-6 dep-graph compile + ≥1 adversarial probe on the keyboard machine + a
net-zero mutation spot-check) → **`mars`** hardens → **Director ship** (gate + commit when asked + record fold).
Apollo is **optional but recommended** for the keyboard machine. The team is a **REAL aaw team** (`aaw_init` +
registered peers + `agent_send`/broadcast), scope slug **`mx-7-3-1`** (dashed — a dot split-brains the registry).

> **Verify depth (ELEVATED).** `DateField` is a stateful keyboard machine **and** this rung adds a new
> `@mercury/core` composable — verify the controlled/uncontrolled split, the per-segment spinbutton a11y, the caret
> hand-off on fill, the ArrowUp/Down `.cycle()` wrap, digit-only input, the composable's value reconstruction
> (commits a `DateValue` on fill via `getValueFromSegments`/`areAllSegmentsFilled`), the curated core barrel
> (`D-5`, no wholesale widen; no `@/` in a barrel-reachable file), and the **INV-6 dep-graph compile** (a clean
> build resolves with no direct `@internationalized/date` edge on `@mercury/ui`). Apollo is **recommended** here.

## 9 · As-built (the verifier — filled post-build)

> Classify K-1..K-9 / INV-1..INV-12 / S-1..S-6 MATCH/STALE/INVENTED/MISSING; **record the A2 ruled arm (a)
> outcome:** the curated `@mercury/core` surface shipped (the `useDateField` composable signature + the value kit
> `type DateValue` / `CalendarDate` / `parseDate`) and the `internal/date-time` functions it composed; list the
> `DateField` home shipped + the exact public type (`DateValue`); reproduce the gate (EXIT 0) incl. `pnpm --filter
> @mercury/core typecheck`, the barrel-diff (+1, 0 removed/renamed), the `sb:build` +1 home delta, and the
> idiom/hex/mercAccent/dep-graph/framing/no-design-sync greps (empty). **Carry forward to mx.7.3.2:** the
> `useDateField` composable's shape + which `internal/date-time` slice `Calendar` reuses via a sibling `useCalendar`
> over the **same** foundation + value kit (no second machinery copy), plus the date-state-machine +
> dep-graph-visibility lessons.
