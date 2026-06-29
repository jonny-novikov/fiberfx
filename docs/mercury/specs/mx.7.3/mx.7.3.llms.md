# mx.7.3 — build context (batch 3: input / selection composites)

Working notes for [`mx.7.3.md`](./mx.7.3.md). Root = `mercury/`. The body is authoritative; this derives from
it. **NO-INVENT:** every bundle prop cited is verified in the bundle `.tsx`; every live target + token is real.
**Edit ONLY** `packages/mercury-ui/src/` (the 6 net-new folders + the 2 fold files + `src/index.ts` +
`src/styles/additions.css`) + `docs/mercury/specs/mx.7.3/` — **and**, only if the Operator rules §A·A2 arm (a),
a curated additive export in `packages/mercury-core/src/` (the date hook). The bundle `packages/mercury-ds/` is
**read-only**.

## Inherited from the epic + mx.7.1/7.2 (read first)

[`../mx.7/mx.7.md`](../mx.7/mx.7.md) §4 (the four cross-batch forks) + §5 (what every batch inherits), and
[`../mx.7.1/mx.7.1.llms.md`](../mx.7.1/mx.7.1.llms.md) (the translation recipe + the `.mx-<name>--accent-<id>`
class pattern, re-used here). Do not re-decide the cross-batch forks. In one line: translate to `.mx-*` +
tokens; additive-only tokens/fonts; never rename / duplicate an existing export; design flows DOWN (no
`/design-sync`); the 4-file home + the additive barrel + the gate.

## ⚠ Read the three §A open calls before building (the Operator rules each)

The body §A carries three calls the Director relays to the Operator; **build to the ruled arm**, not the
default:

1. **A1 — `*Cards` composition** (Steward: compose the live `Checkbox`/`Radio` in a card shell).
2. **A2 — date-primitives' lib** (Steward: reuse `@mercury/core`'s date layer via a curated barrel hook; ui
   consumes via `@mercury/core`). **Hard invariant either way (INV-6): `@mercury/ui` must NOT
   `import "@internationalized/date"` directly** — it is not a visible dependency of `@mercury/ui`.
3. **A3 — `ToggleGroup` fold** (Steward: fold into the live `ToggleGroup`; no new export; no folder).

## References (read in order)

1. [`mx.7.3.md`](./mx.7.3.md) — the body (§3 surfaces + §4 translation notes + §A arms are the build target).
2. The bundle prototypes (the prop-surface seed — translate, don't drop in):
   `packages/mercury-ds/project/components/{inputs/DateField,inputs/Calendar,inputs/TextArea,selection/CheckboxGroup,
   selection/CheckboxCards,selection/RadioGroup,selection/RadioCards,selection/ToggleGroup}/<Name>.tsx`
   (+ each `<Name>.prompt.md` as the prop-list seed only — strip runtime framing).
3. The live compose / fold targets (the surfaces to compose + enrich — verified):
   - `packages/mercury-ui/src/components/selection/Checkbox/Checkbox.tsx` — props `checked`/`onChange:(boolean)`/
     `label`/`indeterminate`/`disabled`/`name`/`value`/`id`. **No `accent` prop.** `CheckboxGroup`/`CheckboxCards`
     compose this.
   - `packages/mercury-ui/src/components/selection/Radio/Radio.tsx` — props `checked`/`onChange:(value)`/`label`/
     `value`/`name`/`disabled`/`id`. **No `accent` prop.** `RadioGroup`/`RadioCards` compose this.
   - `packages/mercury-ui/src/components/inputs/Textarea/Textarea.tsx` — the **fold target** (extends
     `TextareaHTMLAttributes`; has `label`/`hint`/`error`/`resizable` + the count footer). Add `size` only.
   - `packages/mercury-ui/src/components/selection/Toggle/Toggle.tsx` — **already exports `ToggleGroup`** (the
     fold target; props `items`/`type`/`value`/`defaultValue`/`onValueChange`/`size`/`className`, per-item
     `ariaLabel`). Add `accent` + group `disabled`; keep `onValueChange`/`ariaLabel`.
   - `packages/mercury-ui/src/components/foundations/Icon/` — the live `Icon` + `IconName` (`Calendar` nav
     chevron, the `*Cards` leading icon — use a **real glyph name**, verify against the set).
4. The core date layer (for §A·A2): `packages/mercury-core/src/date.ts` (the current barrel surface — the
   `createFormatter`/`createTimeFormatter` formatters, already re-exported by `@mercury/ui`) and
   `packages/mercury-core/src/internal/date-time/` (the headless date-field machine — `field/{segments,parts,
   helpers,types,time-helpers}.ts` + `placeholders.ts`/`utils.ts`/`time-value.ts`, built on
   `@internationalized/date`). Per arm (a), surface a **curated** hook from here through
   `packages/mercury-core/src/index.ts` — do NOT widen the barrel wholesale (`D-5`).
5. Styles: `packages/mercury-ui/src/styles/additions.css` (add the new `.mx-*` rules + the accent ramps —
   reuse the mx.7.1 ramp set), `tokens.css` (the `--border-primary`/`--border-focus`/`--ring-focus` families,
   the radius scale, `--font-secondary` DM Mono for `DateField`).
6. The contract format: [`../../contracts.md`](../../contracts.md) + any mx.2 `<Name>.prompt.md` as a shape
   exemplar.

## Ground facts (re-probe before trusting)

- **Stack:** Vite ^6, React 19, Node 22, pnpm 10.17, TypeScript ^5.6; `tsconfig.base.json` `verbatimModuleSyntax`
  (`import type` for types), `strict` + `noUncheckedIndexedAccess`, `jsx: react-jsx`. Guard React-19 nullable
  `useRef().current` (the `DateField` segment refs).
- **`ToggleGroup` is ALREADY a live export** — in `selection/Toggle/Toggle.tsx`. **Fold**; do NOT create a
  `selection/ToggleGroup/` folder (duplicate export = build break). The epic §1 "7 net-new" count is STALE on
  this row; the real shape is **6 net-new + 2 folds**.
- **No `accent` prop on live `Checkbox`/`Radio`/`Toggle`** — a group realizes `accent` as a wrapper class
  (`.mx-<group>--accent-<id>`), **never** by forwarding `accent` to the wrapped primitive (INVENTED surface),
  **never** via `mercAccent` (Cross-fork I).
- **`@mercury/ui`'s only dependency is `@mercury/core` (`workspace:*`)** — `@internationalized/date` is a dep of
  `@mercury/core`, NOT of `@mercury/ui`. Consume the date layer **through `@mercury/core`** (per A2). A direct
  `@internationalized/date` import in `@mercury/ui` may not resolve under a strict install — INV-6.
- **`@mercury/core` barrel is minimal (`D-5`).** Today it exposes `cx` + the date formatters only. If A2 arm (a)
  is ruled, add **one curated** date hook export — not a wholesale widen of `internal/`.
- **The `*Cards` compose the live primitive (A1 arm (a))** — the card wraps `Checkbox`/`Radio`; the indicator +
  native input + keyboard come from the primitive. The card's `icon` is the *leading* content glyph (the live
  `Icon`), distinct from the selection indicator the primitive draws.
- **`sb:typecheck` is the authoritative story NO-INVENT gate** (the library `tsc` excludes `**/*.stories.tsx`,
  `D-9`). A wrong prop/symbol fails there, not in `pnpm --filter @mercury/ui typecheck`.

## The file tree (create / edit exactly these)

```
# net-new (6 four-file homes):
packages/mercury-ui/src/components/inputs/DateField/{DateField.tsx,index.ts,DateField.prompt.md,DateField.stories.tsx}
packages/mercury-ui/src/components/inputs/Calendar/{Calendar.tsx,index.ts,Calendar.prompt.md,Calendar.stories.tsx}
packages/mercury-ui/src/components/selection/CheckboxGroup/{CheckboxGroup.tsx,index.ts,CheckboxGroup.prompt.md,CheckboxGroup.stories.tsx}
packages/mercury-ui/src/components/selection/CheckboxCards/{CheckboxCards.tsx,index.ts,CheckboxCards.prompt.md,CheckboxCards.stories.tsx}
packages/mercury-ui/src/components/selection/RadioGroup/{RadioGroup.tsx,index.ts,RadioGroup.prompt.md,RadioGroup.stories.tsx}
packages/mercury-ui/src/components/selection/RadioCards/{RadioCards.tsx,index.ts,RadioCards.prompt.md,RadioCards.stories.tsx}

# folds (enrich in place — NO new folder, NO new export):
packages/mercury-ui/src/components/inputs/Textarea/Textarea.tsx        # + size?: sm|md|lg  (refresh Textarea.prompt.md + Textarea.stories.tsx)
packages/mercury-ui/src/components/selection/Toggle/Toggle.tsx         # + accent? + group disabled?  (refresh Toggle.prompt.md/.stories.tsx)

packages/mercury-ui/src/index.ts                 # +6 barrel lines (additive) — NO ToggleGroup/TextArea line
packages/mercury-ui/src/styles/additions.css     # +6 .mx-* rule blocks (+ accent ramps, + the .mx-ta--<size> / .mx-tgl-grp--accent rules)

# ONLY if the Operator rules A2 arm (a):
packages/mercury-core/src/index.ts               # + one curated date-hook export (NOT a wholesale widen)
packages/mercury-core/src/<the hook file>        # the headless useDateField/useCalendar atop internal/date-time
```

(`Calendar` group = `inputs` per the body's group note.)

## The translation recipe (every net-new component)

Same as [`../mx.7.1/mx.7.1.llms.md`](../mx.7.1/mx.7.1.llms.md) (read it): read the bundle `.tsx` → extract the
prop surface + anatomy (ignore the inline `style={{}}` color values) → write `<Name>.tsx` (`import type` from
react, `import { cx } from "@mercury/core"`, a function/`forwardRef` component, `className={cx("mx-<name>",
…modifiers, className)}`) → add the `.mx-<name>` rules to `additions.css` (`rgb(var(--token))` only; accent
ramps as `.mx-<name>--accent-<id>`) → `index.ts` = `export * from "./<Name>";` + the barrel line → hand-author
`<Name>.prompt.md` (mx.2 format; strip bundle framing) → `<Name>.stories.tsx` CSF3 (Playground + states grid;
basic mx.4 shape — mx.8 enriches later). For the **two folds**, enrich the existing `.tsx` + refresh its
`.prompt.md`/`.stories.tsx` — **no new folder, no new barrel line**.

## The gate (run from `mercury/`)

```bash
pnpm --filter "./packages/*" typecheck
pnpm --filter "./packages/*" build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build   # echomq + mobile
pnpm sb:typecheck                                                # authoritative story NO-INVENT gate
pnpm sb:build                                                    # prior homes + 6

# barrel additive (resolve the full set, not a text-diff): 0 removed/renamed, +6 (+ Props), exactly ONE ToggleGroup
# idiom + hygiene greps — expect EMPTY:
NEW="packages/mercury-ui/src/components/{inputs/DateField,inputs/Calendar,selection/CheckboxGroup,selection/CheckboxCards,selection/RadioGroup,selection/RadioCards}"
FOLD="packages/mercury-ui/src/components/inputs/Textarea/Textarea.tsx packages/mercury-ui/src/components/selection/Toggle/Toggle.tsx"
grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})" $NEW $FOLD
grep -rnE "#[0-9a-fA-F]{3,8}\b" $NEW $FOLD packages/mercury-ui/src/styles/additions.css
grep -rn  "mercAccent\|_lib/accent" packages/mercury-ui/src/components
grep -rnE "<(Checkbox|Radio)[^>]*accent=" packages/mercury-ui/src/components/selection   # accent NOT forwarded to the primitive
grep -rn  "@internationalized/date" packages/mercury-ui/src                              # date layer consumed via @mercury/core
test ! -d packages/mercury-ui/src/components/selection/ToggleGroup                       # no duplicate folder
grep -rniE "check_design_system|pixel-perfect|/design-sync|showcase/" $NEW
```

## Gotchas

- **`ToggleGroup` is a FOLD, not net-new** — it is already exported from `selection/Toggle/Toggle.tsx`. No new
  folder, no new barrel line. `TextArea` is a FOLD into `inputs/Textarea` (add `size`). Master invariant: never
  rename / duplicate an existing export.
- **No `accent` on live `Checkbox`/`Radio`/`Toggle`** — realize `accent` at the group/card class; never forward
  it to the primitive; never import `mercAccent`.
- **No direct `@internationalized/date` in `@mercury/ui`** — it is not a visible dep; consume the date layer via
  `@mercury/core` (A2). If A2 arm (a), the curated core hook is the only `@mercury/core` edit (gate
  `pnpm --filter @mercury/core typecheck`).
- **`*Cards` compose the live primitive** (A1 arm (a)) — do not re-draw the check/dot the `Checkbox`/`Radio`
  already render.
- **Dynamic non-color inline is allowed** (grid `columns`, cell sizing) — the INV-2 grep flags color literals
  only; never a raw hex.
- **Commit hygiene:** the bundle `packages/mercury-ds/` stays OUT of the commit; `mercury/…` pathspec only; never
  `git add -A`; never `pnpm -r` (use `--filter`). The Director commits; agents run no git.
- **Framing (propagate into every contract):** no gendered pronouns for agents; no perceptual / interior-state
  verbs; no first-person narration; state each surface as a contract (pre/post/invariant).

## Lessons carried from mx.7.2

The Director fills this at release from mx.7.2's as-built — expected: the disclosure-state-machine +
Icon-composition lessons (the `Collapsible` controlled/uncontrolled pattern → reused by `DateField`/`Calendar`
+ the four selection sets; the real-glyph Icon rule → reused by `Calendar` + the `*Cards`), and which token /
font lines mx.7.1/7.2 already added (reuse; do not re-add).

## When this batch later ships

Its aaw scope slug is the **dashed** form `mx-7-3` (never `mx.7.3` — a dot split-brains the aaw registry). No
team is created at authoring time.
