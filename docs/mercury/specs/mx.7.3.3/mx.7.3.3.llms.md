# mx.7.3.3 — build context (sub-batch 3: selection composites + folds)

Working notes for [`mx.7.3.3.md`](./mx.7.3.3.md). Root = `mercury/`. The body is authoritative. **NO-INVENT.**
**Edit ONLY** `packages/mercury-ui/src/` (the 4 new folders + the 2 fold files + `src/index.ts` +
`src/styles/additions.css`) + `docs/mercury/specs/mx.7.3.3/`. The bundle `packages/mercury-ds/` is **read-only**.

## Read first (inherited)

The sub-epic [`../mx.7.3/mx.7.3.md`](../mx.7.3/mx.7.3.md) + the mx.7 epic [`../mx.7/mx.7.md`](../mx.7/mx.7.md)
§4/§5 + [`../mx.7.1/mx.7.1.llms.md`](../mx.7.1/mx.7.1.llms.md) (the translation recipe + the
`.mx-<name>--accent-<id>` ramp pattern, re-used here).

## ⚠ Rule §A·A1 + §A·A3 before building

- **A1 — `*Cards` composition** (Steward: compose the live `Checkbox`/`Radio` in a card shell).
- **A3 — `ToggleGroup` fold** (Steward: fold into the live `ToggleGroup`; no new export; no folder — forced by the
  master invariant). The **TextArea fold** is epic-ruled (enrich `Textarea` with `size`).

## References (read in order)

1. [`mx.7.3.3.md`](./mx.7.3.3.md) — the body (§3 surfaces + §4 translation notes + §A arms).
2. The bundle prototypes (the prop-surface seed — translate, don't drop in):
   `packages/mercury-ds/project/components/{selection/CheckboxGroup,selection/CheckboxCards,selection/RadioGroup,
   selection/RadioCards,selection/ToggleGroup,inputs/TextArea}/<Name>.tsx` (+ each `.prompt.md` as the prop-list
   seed only — strip framing).
3. The live compose / fold targets (verified):
   - `packages/mercury-ui/src/components/selection/Checkbox/Checkbox.tsx` — props `checked`/`onChange:(boolean)`/
     `label`/`indeterminate`/`disabled`/`name`/`value`/`id`. **No `accent` prop.** Groups + CheckboxCards compose it.
   - `packages/mercury-ui/src/components/selection/Radio/Radio.tsx` — props `checked`/`onChange:(value)`/`label`/
     `value`/`name`/`disabled`/`id`. **No `accent` prop.** RadioGroup + RadioCards compose it.
   - `packages/mercury-ui/src/components/inputs/Textarea/Textarea.tsx` — the **fold target** (extends
     `TextareaHTMLAttributes`; has `label`/`hint`/`error`/`resizable` + the count footer). Add `size` only.
   - `packages/mercury-ui/src/components/selection/Toggle/Toggle.tsx` — **already exports `ToggleGroup`** (the fold
     target; props `items`/`type`/`value`/`defaultValue`/`onValueChange`/`size`/per-item `ariaLabel`). Add `accent`
     + group `disabled`; keep `onValueChange`/`ariaLabel`.
   - `packages/mercury-ui/src/components/foundations/Icon/` — the live `Icon` + `IconName` (the `*Cards` leading
     icon — a **real glyph name**, verify against the set).
   - `packages/mercury-ui/src/components/data-display/Card/` — the cross-link target for the `*Cards` contracts.
4. Styles: `packages/mercury-ui/src/styles/additions.css` (the new `.mx-*` rules + the accent ramps — reuse the
   mx.7.1 set; the `.mx-ta--<size>` + `.mx-tgl-grp--accent` rules), `tokens.css`.
5. The contract format: [`../../contracts.md`](../../contracts.md).

## Ground facts (re-probe before trusting)

- **Stack** as the other batches (React 19, TS ^5.6 `verbatimModuleSyntax`/`strict`/`noUncheckedIndexedAccess`).
  Guard React-19 nullable `useRef().current`.
- **`ToggleGroup` is ALREADY a live export** — in `selection/Toggle/Toggle.tsx`. **Fold**; do NOT create a
  `selection/ToggleGroup/` folder (duplicate export = build break).
- **No `accent` on live `Checkbox`/`Radio`/`Toggle`** — realize `accent` as a wrapper class
  (`.mx-<group>--accent-<id>`), **never** forwarded to the wrapped primitive, **never** via `mercAccent`.
- **The `*Cards` compose the live primitive (A1 arm (a))** — the card wraps `Checkbox`/`Radio`; the card's `icon`
  is the *leading* content glyph (the live `Icon`), distinct from the selection indicator the primitive draws.
- **`sb:typecheck` is the authoritative story NO-INVENT gate** (library `tsc` excludes `**/*.stories.tsx`).

## The file tree (create / edit exactly these)

```
# net-new (4 four-file homes):
packages/mercury-ui/src/components/selection/CheckboxGroup/{CheckboxGroup.tsx,index.ts,CheckboxGroup.prompt.md,CheckboxGroup.stories.tsx}
packages/mercury-ui/src/components/selection/CheckboxCards/{CheckboxCards.tsx,index.ts,CheckboxCards.prompt.md,CheckboxCards.stories.tsx}
packages/mercury-ui/src/components/selection/RadioGroup/{RadioGroup.tsx,index.ts,RadioGroup.prompt.md,RadioGroup.stories.tsx}
packages/mercury-ui/src/components/selection/RadioCards/{RadioCards.tsx,index.ts,RadioCards.prompt.md,RadioCards.stories.tsx}

# folds (enrich in place — NO new folder, NO new export):
packages/mercury-ui/src/components/inputs/Textarea/Textarea.tsx     # + size?: sm|md|lg  (refresh .prompt.md + .stories.tsx)
packages/mercury-ui/src/components/selection/Toggle/Toggle.tsx      # + accent? + group disabled?  (refresh .prompt.md/.stories.tsx)

packages/mercury-ui/src/index.ts                 # +4 barrel lines (additive) — NO ToggleGroup/TextArea line
packages/mercury-ui/src/styles/additions.css     # +4 .mx-* rule blocks (+ accent ramps, + .mx-ta--<size> / .mx-tgl-grp--accent)
```

## The gate (run from `mercury/`)

```bash
pnpm --filter "./packages/*" typecheck && pnpm --filter "./packages/*" build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build
pnpm sb:typecheck && pnpm sb:build
# barrel additive: +4 (+ Props), 0 removed/renamed, exactly ONE ToggleGroup
W="packages/mercury-ui/src/components/selection/CheckboxGroup packages/mercury-ui/src/components/selection/CheckboxCards packages/mercury-ui/src/components/selection/RadioGroup packages/mercury-ui/src/components/selection/RadioCards"
F="packages/mercury-ui/src/components/inputs/Textarea/Textarea.tsx packages/mercury-ui/src/components/selection/Toggle/Toggle.tsx"
grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})" ${=W} ${=F}        # zsh: ${=VAR} word-splits
grep -rnE "#[0-9a-fA-F]{3,8}\b" ${=W} ${=F} packages/mercury-ui/src/styles/additions.css
grep -rn  "mercAccent\|_lib/accent" packages/mercury-ui/src/components
grep -rnE "<(Checkbox|Radio)[^>]*accent=" packages/mercury-ui/src/components/selection   # accent NOT forwarded
test ! -d packages/mercury-ui/src/components/selection/ToggleGroup                        # no duplicate folder
grep -rniE "check_design_system|pixel-perfect|/design-sync|showcase/" ${=W}
```

## Gotchas

- **`ToggleGroup`/`TextArea` are FOLDS** — never a new folder/export; master invariant forbids rename/duplicate.
- **No `accent` on the primitives** — realize at the group/card class; never forward; never `mercAccent`.
- **`*Cards` compose the live primitive** — don't re-draw the check/dot the `Checkbox`/`Radio` already render.
- **zsh** does not word-split unquoted vars — use `${=VAR}` (the grep blocks above) or list paths explicitly.
- **Dynamic non-color inline allowed** (grid `columns`); never a raw hex.
- **Commit hygiene:** bundle OUT of the pathspec; `mercury/…` pathspec only; never `git add -A`; never `pnpm -r`.
- **Framing:** no gendered pronouns / perceptual verbs / first-person in the contracts.

## Lessons carried from the date batches (mx.7.3.1/.2)

The Director fills this at release — expected: which token/font lines the date batches added (reuse, don't re-add),
the real-glyph Icon rule (for the `*Cards` icon), and the contract framing standard.

## When this batch ships

aaw scope slug `mx-7-3-3` (dashed). REAL aaw Trio (`aaw_init` + registered `venus`/`mars`); pure-presentational →
NORMAL verify, no Apollo.
