# mx.7.3.2 · Calendar — the month-grid date picker

> **Status: 📋 PLANNED — build-ready; sub-batch 2 of the mx.7.3 split (ships after mx.7.3.1).** Inherits the
> sub-epic [`../mx.7.3/mx.7.3.md`](../mx.7.3/mx.7.3.md) and the mx.7 epic [`../mx.7/mx.7.md`](../mx.7/mx.7.md).
> This batch imports **one** net-new component — `Calendar`, a month grid with prev/next paging + controlled /
> uncontrolled day selection — translated into `@mercury/ui`'s `.mx-*` + token idiom, additively. It is a
> **stateful grid machine** (the elevated-verify focus) and composes the **live `Icon`** for its nav chevrons.
>
> **Inherited, not re-argued** (mx.7 epic §4/§5): translate to `.mx-*` + tokens; additive-only tokens/fonts;
> never rename an existing export; design flows DOWN; the 4-file home + additive barrel + the gate.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · sub-epic: [`../mx.7.3/mx.7.3.md`](../mx.7.3/mx.7.3.md)
· batch 1: [`../mx.7.3.1/mx.7.3.1.md`](../mx.7.3.1/mx.7.3.1.md) · contract template:
[`../../contracts.md`](../../contracts.md) · acceptance: [`mx.7.3.2.stories.md`](./mx.7.3.2.stories.md) · build
context: [`mx.7.3.2.llms.md`](./mx.7.3.2.llms.md).

---

## A · The open call in this batch (Operator rules)

### A2 — the date-lib (Calendar) — ruled per machine, grounded as in mx.7.3.1 §A·A2

`Calendar` has its **own** date-math need (a month-grid `Date` + paging), distinct from `DateField`'s segmented
value, so A2 is ruled here independently (the Operator may match or diverge from the mx.7.3.1 ruling). The same
grounded arms apply:

- **(a) Build / reuse a curated `@mercury/core` calendar hook** (a `useCalendar`-style month-grid generator over
  the `internal/date-time` machinery), surfaced through core's barrel; `Calendar` consumes it via `@mercury/core`.
  Real i18n / first-day-of-week / calendar-system validity; **heaviest** (a from-scratch hook — none exists). If
  mx.7.3.1 ruled arm (a), `Calendar` may **reuse the same date layer** the DateField hook established.
- **(b) `@mercury/ui` takes `@internationalized/date` directly.** New dep edge on ui — **violates INV-6**; only
  if explicitly ruled.
- **(c) Native `Date`** — translate the bundle prototype's month-grid `Date` math faithfully. Lightest;
  epic-consistent; pure-presentational; no core edit; INV-6 free; no i18n validity (no regression vs the bundle).
- **Steward (grounded):** as in mx.7.3.1 — **arm (c)** is the in-band epic-consistent default; **arm (a)** only
  if the Operator wants i18n-correct dates now (and ideally consistent with the mx.7.3.1 ruling). **Operator
  rules.** **INV-6 holds under (a) and (c).**

## 0 · The slice

Sub-batch 2 — **`Calendar`** alone: a month grid + prev/next paging + today / selected / outside-month cell
states + controlled/uncontrolled selection + class-driven `accent`, composing the **live `Icon`** for the nav
chevrons. Translated into the live `.mx-*` + token idiom, exported additively as a 4-file home. Date arithmetic
per the ruled A2 arm.

## 1 · Goal

After mx.7.3.2, `@mercury/ui` exports **1 new component** — `Calendar` (+ `CalendarProps` + the arm's value type)
— a translated 4-file home (`.mx-calendar` + tokens · hand-authored contract · CSF3 story). The barrel is strictly
additive (+1; 0 removed/renamed). The full package gate is green; `sb:build` registers prior + 1; `@mercury/ui`
gains **no direct `@internationalized/date` import** (INV-6) unless the Operator rules A2 arm (b).

## 2 · Rationale (5W)

- **Why.** Forms + scheduling need a visual day picker — a month grid to click a day and page months. It is the
  picker half of the date pair (the typed half is mx.7.3.1 `DateField`); mx.7.4's `Popover` + mx.9's showcase
  compose them into a date-picker.
- **What.** The translated `Calendar` home, the barrel +1, the `.mx-calendar` rules (incl. the
  `.mx-calendar--accent-<id>` ramps reused from mx.7.1), and the date arithmetic per the ruled A2 arm.
- **Who.** *Authored by* the architect + the batch's build/verify agents. *Consumed by* mx.7.4 (`Popover` pairs
  it), mx.8 (its story), mx.9 (the showcase date-picker).
- **When.** Sub-batch 2 — after mx.7.3.1, with the Operator in the loop before mx.7.3.3.
- **Where.** Only `packages/mercury-ui/src/components/inputs/Calendar/` + `src/index.ts` (+1) +
  `src/styles/additions.css` + `docs/mercury/specs/mx.7.3.2/` — **and**, if A2 arm (a), a curated
  `packages/mercury-core/src/` export. The bundle `packages/mercury-ds/` is read-only.

## 3 · The component (grounded — bundle prop surface verified in source)

| Component | Bundle source | Prototype prop surface (the seed) | Live action |
|---|---|---|---|
| `Calendar` | `inputs/Calendar/Calendar.tsx` | `value?: Date\|null` · `defaultValue?: Date\|null` · `onChange?: (Date) => void` · `accent?: AccentId` (month grid; prev/next paging; composes the nav chevron) | **net-new** `inputs/Calendar` |

> The public value type follows the ruled A2 arm (arm (c): native `Date`; arm (a): the core hook's
> `CalendarDate`/`DateValue`). The export name is `Calendar` + `CalendarProps`. **Group = `inputs`** (the bundle's
> group; it pairs with `Popover` for a date picker in mx.7.4 — a navigability choice, not a correctness one).

## 4 · Translation notes

- **Translate the month grid; the date math comes from the ruled A2 arm.** Controlled (`value`) + uncontrolled
  (`defaultValue`) selection; prev/next month **paging**; the 7-column day grid with weekday headers; **today** /
  **selected** / **outside-month** cell states.
- **`accent` is class-driven at the root** (`.mx-calendar--accent-<id>`, the mx.7.1 ramp set
  `iris|indigo|green|orange|plum|red`) — the selected-day fill + today-ring read the accent token. **No
  `mercAccent` import** (epic Cross-fork I).
- **The nav chevrons are the live `Icon`** — a **real glyph** (verify against the live Icon set; the live
  disclosure/nav glyph is `"chevron-left"`/`"chevron-right"` — confirm names; the bundle's `chev` is not a live
  name). mx.7.2 L5: bundle glyph names ≠ the live set — remap.
- **Style via `.mx-calendar`** reading the surface/border/`--fg-*` token families — no inline color literal, no
  raw hex. Dynamic non-color inline (grid template) is allowed.
- **Guard React-19 nullable `useRef().current`** if the grid keeps refs.

## 5 · Deliverables

- **K-1 — 1 net-new translated 4-file home** `inputs/Calendar/` (`.tsx` · `index.ts` · `.prompt.md` D-7 ·
  `.stories.tsx` CSF3).
- **K-2 — the barrel grows +1 additively** (`Calendar` + `CalendarProps` [+ the arm's value type]); 0
  removed/renamed.
- **K-3 — the live idiom** (Cross-fork I): `.mx-calendar` + tokens; `accent` via `.mx-calendar--accent-<id>`; no
  inline color literal; no raw hex; no `mercAccent`.
- **K-4 — composition real:** the nav chevron is the live `Icon` (a real glyph, verified).
- **K-5 — the date-lib per the ruled A2 arm:** value model + arithmetic from the ruled arm; `@mercury/ui` adds
  **no direct `@internationalized/date` import** and no new dep edge unless arm (b).
- **K-6 — a hand-authored contract** (D-7): mx.2 format; no bundle framing; cross-links `DateField` (mx.7.3.1) +
  `Popover` (mx.7.4) + `Icon`.
- **K-7 — the 1:1 story↔folder invariant holds**; `sb:build` registers prior + 1.
- **K-8 — token/font additive-only** · **design flowed DOWN**.
- **K-9 — the gate is green** (§7).

**Coverage:** K-1 → S-1 ; K-2 → S-2 ; K-3 → S-1 ; K-4 → S-1 ; K-5 → S-1,S-3 ; K-6 → S-1 ; K-7 → S-4 ; K-8 →
S-5 ; K-9 → S-6.

## 6 · The per-component translation map

- **Calendar** (`inputs/Calendar` → `inputs/Calendar`). `.mx-calendar`; month grid + prev/next paging, today /
  selected / outside cells; controlled + uncontrolled; `accent` via `.mx-calendar--accent-<id>`; composes the live
  `Icon` (a real glyph); date arithmetic per §A·A2. Cross-link `DateField` (mx.7.3.1) + `Popover` (mx.7.4).

## 7 · Invariants — as runnable gates (run from `mercury/`)

- **INV-1 — master invariant, additive.** Resolved export set after = superset; **0 removed/renamed**, +1
  (`Calendar` + `CalendarProps` [+ the arm's value type]).
- **INV-2 — no inline color leak.** `grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})"
  packages/mercury-ui/src/components/inputs/Calendar` → empty.
- **INV-3 — no raw hex.** over the folder + the new `additions.css` rules → empty.
- **INV-4 — no `mercAccent` import.** over the folder → empty (accent is class-driven).
- **INV-5 — real glyph.** the nav chevron resolves to a live `IconName` (no invented glyph).
- **INV-6 — date-lib dep-graph-visibility.** `grep -rn "@internationalized/date" packages/mercury-ui/src` → empty;
  `mercury-ui/package.json` deps unchanged — unless the Operator ruled A2 arm (b).
- **INV-8 — D-7 contract, no bundle framing.** the framing grep over the folder → empty.
- **INV-9 — 1:1 story↔folder + `sb:typecheck` clean.** one story; `pnpm sb:typecheck` exits 0; `sb:build` prior + 1.
- **INV-10 — token/font additive-only.** **INV-11 — design flows DOWN.**
- **INV-12 — the package gate** (typecheck/build · apps `!@mercury/storybook` · sb:typecheck · sb:build = 0; if
  arm (a), `pnpm --filter @mercury/core typecheck` = 0).

## 8 · The batch loop — Trio (Operator-directed; Apollo recommended for the grid machine)

As mx.7.3.1 §8 (the REAL aaw Trio, scope slug `mx-7-3-2`), carrying mx.7.3.1's date-state-machine + dep-graph
lessons (incl. whether arm (a)'s core date hook is reused). Verify the controlled/uncontrolled split, month
paging, the today/selected/outside cell states, the real-glyph nav chevron, and the INV-6 dep-graph compile.

## 9 · As-built (the verifier — filled post-build)

> Classify K-1..K-9 / INV-1..INV-12 / S-1..S-6; **record the ruled A2 arm** + its outcome (and whether it reused
> the mx.7.3.1 date layer); list the home shipped + the public value type + the live `IconName` used for the nav
> chevron; reproduce the gate (EXIT 0). Carry forward to mx.7.3.3 any token/font lines added (reuse, don't re-add).
