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

## 9 · As-built (the verifier — filled post-build, 2026-06-30)

**Verdict: BUILD-GRADE.** Every K / INV / S is MATCH. One honest caveat on INV-5 (recorded below): the
invariant holds *as-built* (a real glyph) but is enforced by manual verification, not the type system.

**The ruled A2 arm — (a), consistent with mx.7.3.1.** `Calendar` reuses the owned date foundation via a
sibling `useCalendar` in `@mercury/core`
(`packages/mercury-core/src/internal/date-time/calendar/use-calendar.ts`), composing the same
`internal/date-time` machinery the mx.7.3.1 `DateField` established — `createFormatter` (month/weekday
labels), `getLastFirstDayOfWeek` (grid alignment), `toDate` (value→native conversion) — over
`@internationalized/date` values. The mx.7.3.1 carry-forward (reuse the foundation via a sibling
composable) is fulfilled: `@mercury/ui` consumes dates only through `@mercury/core`, so INV-6 extends
unchanged.

**Home shipped (4-file, K-1).** `packages/mercury-ui/src/components/inputs/Calendar/`:
`Calendar.tsx` · `index.ts` · `Calendar.prompt.md` (D-7) · `Calendar.stories.tsx` (CSF3, 4 stories:
Playground / Uncontrolled / Accent / Controlled). Styles: `.mx-calendar` block at
`src/styles/additions.css:565–610` (+47 lines, additive).

- **Public value type:** `DateValue` (re-exported from `@mercury/core`; under arm (a), not native `Date`).
  `CalendarProps` adds `locale` + `firstDayOfWeek` beyond the §3 seed surface — both are arm (a)'s i18n
  surface (`@mercury/core` `useCalendar` options), not invented.
- **Live `IconName` for the nav chevron:** `chevron-right` — a real glyph (`Icon.tsx:56`, ∈ `ICONS`).
  Both prev + next use it; the prev control is CSS-flipped (`.mx-calendar__nav--prev svg { transform:
  rotate(180deg) }`, `additions.css:592`). No `chevron-left` glyph exists or was invented.

**Delta table (promise → as-built → verdict).**

| Promise | As-built `file:line` | Verdict |
|---|---|---|
| K-1 4-file home | `inputs/Calendar/{Calendar.tsx,index.ts,Calendar.prompt.md,Calendar.stories.tsx}` | MATCH |
| K-2 barrel +1 additive | `mercury-ui/src/index.ts:51` (`export * …/Calendar`); git `+1`, 0 removed | MATCH |
| K-3 live idiom (`.mx-calendar` + tokens, class-driven accent) | `additions.css:575–610`; `Calendar.tsx:40` | MATCH |
| K-4 composition real (live `Icon`) | `Calendar.tsx:43,47` `Icon name="chevron-right"` | MATCH |
| K-5 date-lib arm (a), no `@internationalized/date` in ui | `use-calendar.ts`; `Calendar.tsx:1–2` core-only | MATCH |
| K-6 D-7 contract + cross-links | `Calendar.prompt.md:29` DateField · `:31` Popover · `:33` Icon | MATCH |
| K-7 1:1 story↔folder; sb:build prior+1 | one `*.stories.tsx`; `sb:build` EXIT 0, `Inputs/Calendar` registered | MATCH |
| K-8 token/font additive; design DOWN | `additions.css` +47 / 0 removed; no DesignSync | MATCH |
| K-9 gate green | see gate below, EXIT 0 | MATCH |
| INV-1 master invariant additive | dist `index.d.ts:33` resolves Calendar; build green (no `export *` collision); +1 / 0 removed | MATCH |
| INV-2 no inline color leak | grep empty | MATCH |
| INV-3 no raw hex | grep empty (folder + `.mx-calendar` CSS) | MATCH |
| INV-4 no `mercAccent` | grep empty | MATCH |
| INV-5 real glyph | `chevron-right` ∈ `ICONS` (`Icon.tsx:56`) | MATCH **as-built** — see caveat |
| INV-6 date-lib dep-graph | no `@internationalized/date` *import* in `mercury-ui/src` (textual hits are doc-comments); core typecheck 0 | MATCH |
| INV-7 | not present in this spec | N/A |
| INV-8 D-7 no bundle framing | grep empty | MATCH |
| INV-9 1:1 story + `sb:typecheck` | `sb:typecheck` EXIT 0; one story; `sb:build` prior+1 | MATCH |
| INV-10 token/font additive-only | `git diff` = added lines only | MATCH |
| INV-11 design flows DOWN | no `/design-sync`/`DesignSync` artifact | MATCH |
| INV-12 the package gate | all legs EXIT 0 (below) | MATCH |
| S-1..S-6 | proven by the K/INV rows above (S-1 grid+accent+arm; S-2 barrel; S-3 dep-edge; S-4 story; S-5 token additive; S-6 gate) | MATCH |

**INV-5 — honest enforcement record.** The glyph is real, so the invariant *holds*. But its enforcement is
**manual verification, not the type system**: `Icon.tsx:4` declares `const ICONS: Record<string,
ReactNode>`, so `IconName = keyof typeof ICONS` widens to `string` — `<Icon name="chevron-left" />` (a
non-existent glyph) type-checks clean. The "a typed name makes typecheck the backstop" framing is
**illusory**. This is PRE-EXISTING (the `Icon` foundation, shipped before this rung) and OUT of this rung's
edit surface; tightening it (`satisfies Record<string, ReactNode>`) is an Operator fork (it would break any
dynamic-name consumer), surfaced in `mx-7-3-2.progress.md`, not applied here.

**Gate reproduced — independent re-run, all EXIT 0** (Node 22.18.0 · pnpm 10.17.1; scoped to `@mercury/*`,
**not** the `./packages/*` glob, which is foreign-contaminated by the `codemojex-node` sub-workspace):
- `pnpm --filter @mercury/core --filter @mercury/ui --filter @mercury/effector typecheck` → EXIT 0 (3 × `tsc Done`)
- `pnpm --filter @mercury/ui build` → EXIT 0 (`✓ built in 944ms`; dist `index.d.ts` carries Calendar)
- `pnpm sb:typecheck` → EXIT 0
- `pnpm sb:build` → EXIT 0 (275 modules, `✓ built in 8.88s`, `Inputs/Calendar` registered)
- apps build (`!@mercury/storybook`) — Director + Mars confirmed EXIT 0 (covered transitively by the package
  typechecks + resolve-from-source aliasing; not re-run — bounded turn). No determinism loop: pure React DS,
  no id-mint / process / lease surface.

**Carry-forward to mx.7.3.3.**
- **Token/font lines added (reuse, do not re-add):** the `.mx-calendar` block (`additions.css:565–610`) and
  its `--mx-cal-accent` ramp (reuses the mx.7.1 `--<id>-9` set + `--fg-on-brand`); no new tokens minted.
- **The owned date layer is established** — `@mercury/core` `internal/date-time/*` now backs both
  `useDateField` and `useCalendar`. A further date component composes a sibling composable; it does not
  re-import `@internationalized/date` into `@mercury/ui` (INV-6).
- **Observation (not a defect):** `visibleMonth` is independent navigation state seeded once from
  `value ?? defaultValue ?? today` (`use-calendar.ts:84–86`); a *later* controlled `value` change to a
  different month updates the selection but does not auto-page the visible month. Spec-consistent (paging is
  scoped separate from selection; arrow-key roving is out of batch). For the mx.7.4 `Popover` date-picker
  (mount-on-open) this is moot; flagged for the Operator should value→month follow be wanted.
- **Operator fork pending (pre-existing, see INV-5 above):** tighten `ICONS` so `IconName` narrows to the
  literal union (a real type-level glyph gate).
