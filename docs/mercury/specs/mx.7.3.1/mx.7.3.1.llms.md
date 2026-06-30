# mx.7.3.1 — build context (sub-batch 1: DateField)

Working notes for [`mx.7.3.1.md`](./mx.7.3.1.md). Root = `mercury/`. The body is authoritative; this derives
from it. **NO-INVENT:** every bundle prop cited is verified in the bundle `.tsx`; every live target + token is
real. **Edit:** `packages/mercury-ui/src/components/inputs/DateField/` + `src/index.ts` (+1 line) +
`src/styles/additions.css` **+** `packages/mercury-core/src/` (the curated `useDateField` composable + value kit —
A2 ruled arm (a)) + `docs/mercury/specs/mx.7.3.1/`. The bundle `packages/mercury-ds/` is **read-only** (anatomy seed).

## Read first (inherited)

- The sub-epic [`../mx.7.3/mx.7.3.md`](../mx.7.3/mx.7.3.md) (the split + the routed forks) and the mx.7 epic
  [`../mx.7/mx.7.md`](../mx.7/mx.7.md) §4 (cross-batch forks) + §5 (what every batch inherits). Do not re-decide
  the cross-batch forks.
- [`../mx.7.1/mx.7.1.llms.md`](../mx.7.1/mx.7.1.llms.md) — the translation recipe (read it).

## A2 RULED — arm (a): `DateField` composes Mercury's owned date foundation

The body §A·A2 is **RULED (Operator, 2026-06-30): arm (a)** — `DateField` is built on Mercury's mature, owned date
foundation (the `@mercury/core` formatters + the `internal/date-time` machinery + the shared composables) via a
**curated, reusable `useDateField` composable**. The bundle is the **anatomy / visual / a11y seed only**, NOT a
value-logic source — its `{m,d,y}` / `parseInt` / `bump` math is dropped. arm (c) native-throwaway is OFF; arm (b)
ui-direct is OFF.

- **Build TWO halves:** (1) the curated `useDateField` composable + the value kit in `@mercury/core` (over the
  existing machinery — a **compose**, not a re-derivation), surfaced via the core barrel (`D-5`, curated); (2) the
  `DateField` home in `@mercury/ui` that consumes it. The compose-target map is in **The value model** section.
- **Hard invariant (INV-6): `@mercury/ui` must NOT `import "@internationalized/date"` directly** — it imports
  `useDateField` + `type DateValue` (+ the value kit `CalendarDate`/`parseDate`) **through `@mercury/core`**.

## References (read in order)

1. [`mx.7.3.1.md`](./mx.7.3.1.md) — the body (§A·A2 ruled arm (a) + §3 surface + §4 translation notes are the target).
2. The bundle prototype (the **anatomy/visual/a11y seed** — translate the shell, drop the value logic):
   `packages/mercury-ds/project/components/inputs/DateField/DateField.tsx` (78 lines; the segmented `<label>` shell,
   `SEGMENTS` widths/min/hi, the geometry, the spinbutton a11y) + its `DateField.prompt.md` (prop-list seed only —
   strip runtime framing).
3. The owned date foundation the composable composes (A2 arm (a)):
   `packages/mercury-core/src/internal/date-time/field/{segments,parts,helpers,types}.ts` + `placeholders.ts` +
   `formatter.ts` (the segment machinery + display formatter, on `@internationalized/date`) and
   `packages/mercury-core/src/date.ts` (the current barrel — `createFormatter`/`createTimeFormatter`, already
   re-exported by `@mercury/ui`). **No React hook exists yet** — this rung builds the curated `useDateField` over the
   machinery. Surface it `D-5` from `packages/mercury-core/src/index.ts` (curated, never a wholesale widen);
   boundary-reachable files import **relative**, not `@/`.
4. The cross-link target: `packages/mercury-ui/src/components/inputs/Input/` (the typed-input idiom + tokens to
   match) — `DateField` cross-links `Input` in its contract.
5. Styles: `packages/mercury-ui/src/styles/additions.css` (add the `.mx-datefield` rules), `tokens.css` (the
   `--border-primary`/`--border-focus`/`--ring-focus`/`--bg-primary`/`--fg-primary`/`--fg-tertiary` families, the
   radius scale, `--font-secondary` DM Mono, `--font-primary`). **All present — no fold needed (INV-10 clean).**
6. The contract format: [`../../contracts.md`](../../contracts.md) + any mx.2 `<Name>.prompt.md` as a shape exemplar.

## Ground facts (re-probe before trusting)

- **Stack:** Vite ^6, React 19, Node 22, pnpm 10.17, TypeScript ^5.6; `verbatimModuleSyntax` (`import type` for
  types), `strict` + `noUncheckedIndexedAccess`, `jsx: react-jsx`. **Guard React-19 nullable `useRef().current`**
  on the segment refs.
- **`@mercury/ui`'s only dependency is `@mercury/core` (`workspace:*`)** — `@internationalized/date` is a dep of
  `@mercury/core`, NOT of `@mercury/ui`. A direct `@internationalized/date` import in `@mercury/ui` may not
  resolve under a strict install — INV-6. The new value kit (`CalendarDate`/`parseDate`/`type DateValue`)
  re-exported through core is how ui/apps construct + type a value with no direct dep.
- **The date foundation exists; the hook composes it (A2 ruled arm (a)).** `internal/date-time/field/*` is the
  segment machinery (value math on `@internationalized/date`); there is no React hook yet — build a curated
  `useDateField` over it (a **compose**, not a re-derivation) + surface it `D-5`. The one genuinely-new piece is the
  per-keystroke segment reducer.
- **`@mercury/core` barrel is minimal (`D-5`)** — today `cx` + the date formatters only. arm (a) adds exactly the
  curated `useDateField` + the value kit, never a wholesale widen of `internal/`.
- **No `accent` on `DateField`** (the bundle has none) — do not invent it (NO-INVENT). Accent on dates is a
  `Calendar` surface (mx.7.3.2).
- **`sb:typecheck` is the authoritative story NO-INVENT gate** — the library `tsc` excludes `**/*.stories.tsx`
  (`D-9`); a wrong prop/symbol fails there, not in `pnpm --filter @mercury/ui typecheck`.

## The file tree (create / edit exactly these)

```
# @mercury/core — the curated composable + value kit (A2 ruled arm (a)):
packages/mercury-core/src/<hook file>            # useDateField over internal/date-time (a compose; e.g. internal/date-time/field/use-date-field.ts)
packages/mercury-core/src/index.ts               # + curated barrel: useDateField + type DateValue + CalendarDate/parseDate (D-5, NOT a wholesale widen)

# @mercury/ui — the DateField home that consumes the composable:
packages/mercury-ui/src/components/inputs/DateField/{DateField.tsx,index.ts,DateField.prompt.md,DateField.stories.tsx}
packages/mercury-ui/src/index.ts                 # +1 barrel line: export * from "./components/inputs/DateField"  (becomes line #51; baseline 50)
packages/mercury-ui/src/styles/additions.css     # + the .mx-datefield rule block
```

## The DateField component shell (the `@mercury/ui` half — value-model-agnostic)

The component shell, a11y, styling, barrel, contract, and story below are the `@mercury/ui` half; they consume the
composable's output for the value. Build, in order (same recipe as [`../mx.7.1/mx.7.1.llms.md`](../mx.7.1/mx.7.1.llms.md)):

1. **Read the bundle** `DateField.tsx` (the anatomy + geometry source). Extract the prop surface + structure;
   **drop** every inline `style={{}}` color value **and** the native value logic (`update`/`bump`/`SEGMENTS` math) —
   the value comes from the composable.
2. **Write `DateField.tsx`** — `import type` from react; `import { cx } from "@mercury/core"`; `import { useDateField,
   type DateValue } from "@mercury/core"`; a **function component** (the bundle renders a `<label>` wrapper and
   forwards no ref — do **not** add `forwardRef`); drive the segments + value from the hook (controlled `value` +
   uncontrolled `defaultValue` are the hook's concern); `className={cx("mx-datefield", disabled && "mx-datefield--disabled",
   className)}`. Guard the React-19 nullable `useRef().current` on the segment refs (`refs[idx+1].current?.focus()`).
3. **The keyboard machine + per-segment a11y** (render the hook's segment descriptors + prop-getters): each segment
   `role="spinbutton"`, `aria-label` per segment (`"month"`/`"day"`/`"year"`), `aria-valuenow`/`aria-valuemin`/
   `aria-valuemax`, `inputMode="numeric"`; digit-only filtering; **caret hand-off** to the next segment on fill;
   **ArrowUp/Down** ± with **wrap**; month/day 2-wide zero-padded, year 4-wide. The a11y `valuemin`/`valuemax` come
   from the segment descriptors (the hook derives them — month 1–12, day 1–31, year per range); note in the
   contract that they are derived, not bundle-copied (the bundle carries only `aria-valuenow`).
4. **The `.mx-datefield` rule** in `additions.css` — `rgb(var(--token))` only, **no raw hex**. The complete token
   set (verified in the bundle): box bg `--bg-primary`; border `--border-primary`→`--border-focus` (focused) + a
   `--ring-focus` 3px ring; `--font-secondary` (DM Mono) field text/glyphs; `--fg-primary` field text **and** label;
   `--fg-tertiary` the `/` separators; `--font-primary` (500) the label; disabled `opacity ~0.6` + `cursor:
   not-allowed`. Geometry from the bundle (box height 40 · padding `0 14px` · radius 8 · box width 232 · label gap)
   goes in the rule; the **per-segment character width** (`seg.w` 24/24/44) stays dynamic-inline (allowed by INV-2).
5. **`index.ts`** = `export * from "./DateField";`. Add the +1 barrel line to `src/index.ts`:
   `export * from "./components/inputs/DateField";` (barrel line #51; baseline is 50).
6. **`DateField.prompt.md`** — hand-author (D-7, mx.2 format; [`../../contracts.md`](../../contracts.md)):
   role · `## Props` (from the translated `.tsx`; value type `DateValue`) · `## Composition` (cross-link `Calendar`
   [mx.7.3.2, a gap until built] + `Input`; note it composes `@mercury/core`'s `useDateField`) · `## Examples` ·
   `## Notes` (the aria-valuemin/max derivation + the React-19 ref guard + the `DateValue`-via-core / INV-6 note).
   Strip ALL bundle runtime framing.
7. **`DateField.stories.tsx`** — CSF3 (`Meta`/`StoryObj`, `title: "Inputs/DateField"`): Playground + a controlled +
   an uncontrolled state (seed with `CalendarDate`/`parseDate` from `@mercury/core`). Basic mx.4 shape (mx.8 enriches).

## The value model — arm (a) RULED: the curated `useDateField` composable (the build target)

Build the date logic as a curated, reusable composable in `@mercury/core` over the **existing** `internal/date-time`
machinery — a **compose, not a re-derivation**. Two halves:

**Half 1 — `@mercury/core`: the `useDateField` composable + the value kit.**
- New file (e.g. `packages/mercury-core/src/internal/date-time/field/use-date-field.ts`) — a React hook owning the
  segment **state container** + the per-keystroke **reducer** + the **prop-getters**, **composing** the machinery
  (import these — do NOT re-derive):
  - `field/helpers.ts`: `initializeSegmentValues(granularity)` (seed the segment map) · `createContent(...)` (the
    locale-correct per-segment display + ordered parts) · `getValueFromSegments(...)` (segments → a `DateValue`) ·
    `areAllSegmentsFilled(...)` (commit-on-fill gate) · `inferGranularity(...)` · `isAcceptableSegmentKey`.
  - `field/segments.ts`: `getSegments` / `getNextSegment` / `getPrevSegment` / `handleSegmentNavigation` /
    `isSegmentNavigationKey` (caret hand-off + Arrow/Home/End navigation across the segment DOM nodes).
  - `field/parts.ts` (`DATE_SEGMENT_PARTS`) + `field/types.ts` (`SegmentValueObj`/`SegmentState`) + `placeholders.ts`
    (placeholder glyphs) + `formatter.ts`'s `createFormatter` (display — already barrel-surfaced).
  - Value arithmetic is `@internationalized/date`'s own: `CalendarDate#cycle(field, ±1, { round })` (ArrowUp/Down
    wrap) + `#set(...)`. **The one genuinely-new piece** is the per-keystroke segment reducer (digit entry with
    `lastKeyZero` / overflow → caret hand-off + backspace) — the field's irreducible behavior.
- Curated barrel additions to `packages/mercury-core/src/index.ts` (`D-5` — exactly these, never a wholesale widen):
  `export { useDateField }` + `export type { DateValue }` + the **value kit** `export { CalendarDate, parseDate }`
  (re-exported from `@internationalized/date`) so `@mercury/ui` + apps construct/type a value with **no** direct
  `@internationalized/date` dep. Boundary-reachable files import **relative**, never `@/` (the mx.1 landmine —
  `grep -rn "@/" <the new hook file>` → empty).
- The hook's contract: input `{ value?: DateValue; defaultValue?: DateValue; onChange?: (v: DateValue | undefined)
  => void; locale?: string (default "en"); granularity: "day" }`; output `{ segments (descriptor + display +
  a11y valuemin/now/max per part), fieldProps, segmentProps(part), value }`. `minValue`/`maxValue` exist in the
  machinery but are **deferred** from the public surface (additive later — do not gold-plate).

**Half 2 — `@mercury/ui`: `DateField.tsx` consumes the composable** (the shell above), driven by the hook's
`segments` + prop-getters; public surface `DateField` + `DateFieldProps` (value type `DateValue`). **No**
`@internationalized/date` import anywhere in `@mercury/ui/src` (INV-6).

**REUSE (the heart of the ruling):** `Calendar` (mx.7.3.2) composes the **grid** slice of the **same** foundation
(month/days-in-month/first-day-of-week from `internal/date-time/utils.ts`) + the **same** value kit via a sibling
`useCalendar` — no second machinery copy, no god-hook. Keep `useDateField` focused on the field.

## The gate (run from `mercury/`)

```bash
pnpm --filter "./packages/*" typecheck            # incl. @mercury/core (the new composable + value kit)
pnpm --filter "./packages/*" build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build   # echomq + mobile
pnpm sb:typecheck                                                # authoritative story NO-INVENT gate
pnpm sb:build                                                    # prior homes + 1

# barrel additive (resolve the full set, not a text-diff): 0 removed/renamed, +1 (DateField + DateFieldProps)
# idiom + hygiene greps — expect EMPTY:
NEW=packages/mercury-ui/src/components/inputs/DateField
grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})" $NEW
grep -rnE "#[0-9a-fA-F]{3,8}\b" $NEW packages/mercury-ui/src/styles/additions.css
grep -rn  "mercAccent\|_lib/accent" $NEW
grep -rn  "@internationalized/date" packages/mercury-ui/src                  # INV-6: empty (consumed via @mercury/core)
grep -rn  "@/" packages/mercury-core/src/internal/date-time/field/use-date-field.ts   # boundary import safety: empty
grep -rniE "check_design_system|pixel-perfect|/design-sync|showcase/" $NEW
```

## Gotchas

- **A2 is RULED arm (a)** — build the curated `useDateField` composable over the existing `internal/date-time`
  machinery (a **compose**, not a re-derivation); do **not** hand-roll native `{m,d,y}`/`Date` math, and **never**
  import `@internationalized/date` into `@mercury/ui` (INV-6 — consume via `@mercury/core`).
- **Curated core barrel (`D-5`)** — add exactly `useDateField` + `type DateValue` + `CalendarDate`/`parseDate`; do
  NOT dump `internal/`. Boundary-reachable files use relative imports, never `@/`.
- **Dynamic non-color inline is allowed** (a segment's character width) — the INV-2 grep flags color literals
  only; never a raw hex.
- **Commit hygiene:** the bundle `packages/mercury-ds/` stays OUT of the commit; `mercury/…` pathspec only; never
  `git add -A`; never `pnpm -r` (use `--filter`). The Director commits; agents run no git.
- **Framing (propagate into the contract):** no gendered pronouns for agents; no perceptual / interior-state
  verbs; no first-person narration; state each surface as a contract (pre/post/invariant).

## Lessons carried from mx.7.2

- **Ground in the bundle `.tsx`, not a §3/§4 summary** (mx.7.2 L4) — the segment geometry + caret hand-off live in
  the prototype; read it (but the value logic is the foundation's, not the bundle's — arm (a)).
- **Translate runtime `<style>`/inline injection OUT into `additions.css`** (mx.7.2 L6) — the bundle's inline
  `style={{}}` becomes the `.mx-datefield` rule; nothing injects at runtime.
- The disclosure controlled/uncontrolled pattern (`Collapsible`) → the controlled/uncontrolled split is now the
  hook's concern (`value` vs `defaultValue`).

## When this batch ships

Its aaw scope slug is the **dashed** form `mx-7-3-1` (never `mx.7.3.1` — a dot split-brains the aaw registry).
The Operator ordered a **REAL aaw Trio** (`aaw_init` + registered `venus`/`mars` + `agent_send`/broadcast).
