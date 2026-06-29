# mx.7.5 — build context (batch 5: menus, hover cards & nav — consume the floor)

Working notes for [`mx.7.5.md`](./mx.7.5.md). Root = `mercury/`. The body is authoritative; this derives from
it. **NO-INVENT:** every bundle prop cited is verified in the bundle `.tsx`; every live target + token + floor
hook is real. **Edit ONLY** `packages/mercury-ui/src/` (the 6 component folders + `src/index.ts` +
`src/styles/additions.css`) + `docs/mercury/specs/mx.7.5/`. **No `@mercury/core` change is expected** — the
floor is already published by 7.4 (a floor addendum is a called-out one-line widening, not a re-home). The bundle
`packages/mercury-ds/` is **read-only**. Everything else in the `jonnify` root is out of bounds.

## The one precondition: the 7.4 overlay-floor is built and published

This batch **hard-gates on [`../mx.7.4/mx.7.4.md`](../mx.7.4/mx.7.4.md)** — it composes the floor
(`useDismiss`/`useAnchoredPosition`/`useArrowNavigation`/`useId`/`<Portal>`, in the home the Operator ruled in
7.4 §A). It re-frames **none** of 7.4's §A/§C/§D ADRs. The only batch-level open call is the **`Menubar`/`TabNav`
group placement** (`navigation/` [recommended] vs `overlay/`) — a D-4-class navigability choice, not correctness.

## Inherited from the epic + 7.4 (read first)

[`../mx.7/mx.7.md`](../mx.7/mx.7.md) §4/§5 (the cross-batch forks + the shared contract) + the 7.4 floor + the
mx.7.1 `accent`-class pattern. In one line: translate to `.mx-*` + tokens; the `accent` prop as
`.mx-<name>--accent-<id>` classes (no `mercAccent`); additive-only tokens/fonts; never rename an existing export;
compose the 7.4 floor (no inline re-roll); design flows DOWN (no `/design-sync`); the 4-file home + additive
barrel + the gate.

## References (read in order)

1. [`mx.7.5.md`](./mx.7.5.md) — the body (§3 prop surfaces, §4 the floor consumption, §5 translation notes,
   §7 the map).
2. The bundle prototypes (the prop-surface seed — translate, don't drop in):
   `mercury-ds/project/components/overlay/{Dropdown,ContextMenu,HoverCard,LinkPreview}/<Name>.tsx` +
   `navigation/{Menubar,TabNav}/<Name>.tsx` (+ each `<Name>.prompt.md` as the prop-list seed only).
3. The published floor: the 7.4 as-built `@mercury/core` floor hooks (`useDismiss`/`useAnchoredPosition`/
   `useArrowNavigation`/`useId`, in the ruled home) + the `@mercury/ui` `overlay/_overlay/Portal.tsx`. **Re-probe
   the exact exported names from the 7.4 as-built before importing.**
4. The live idiom + contrast targets: `packages/mercury-ui/src/components/overlay/Tooltip/Tooltip.tsx` (the
   static-tooltip shape `HoverCard` contrasts with) and `navigation/Tabs/Tabs.tsx` (the panel-tabs `TabNav`
   contrasts with).
5. The styles: `packages/mercury-ui/src/styles/additions.css` (add the `.mx-*` rules + the static `@keyframes` +
   the accent ramps here), `tokens.css` (surfaces `--bg-elevated`, shadows `--shadow-300`, the ring/border focus
   tokens, the `--<ramp>-9`/`--<ramp>-11` accent ramps, `--fg-negative` for `ContextMenu`'s `danger`).
6. The contract format: [`../../contracts.md`](../../contracts.md) + the exemplar pair; mx.7.1's
   `Separator.prompt.md` + `IconButton.prompt.md` (the cross-link targets).

## Ground facts (re-probe before trusting)

- **Stack:** Vite ^6, React 19, Node 22, pnpm 10.17, TypeScript ^5.6; `verbatimModuleSyntax`, `strict` +
  `noUncheckedIndexedAccess`, `jsx: react-jsx`.
- **Compose the 7.4 floor — do NOT rebuild it.** `useDismiss` (every menu/card), `useAnchoredPosition` (the
  menus' `align`, the cards' `top/bottom/left/right`, `ContextMenu`'s pointer-`fixed`), `useArrowNavigation`
  (the menus), `<Portal>` (every floating panel). `useFocusTrap` is **unused** (these are non-modal).
- **`accent` (Dropdown, Menubar)**: the bundle imports `mercAccent` from `_lib/accent.ts` for the check/radio
  mark colour. **Do NOT import it** — realize `accent?: "iris"|"indigo"|"green"|"orange"|"plum"|"red"` as
  `.mx-<name>--accent-<id>` classes reading the `--<ramp>-9`/`--<ramp>-11` ramps (the mx.7.1 pattern). Only
  Dropdown + Menubar carry `accent`; `ContextMenu`'s `danger` is already token-based (`--fg-negative`).
- **Runtime `@keyframes` injection must go** — every menu/card calls `ensureKeyframes()`
  (`document.createElement("style")` → `<head>`: `merc-dd-in`, `merc-cm-in`, `merc-hc-in`, `merc-menu-in`).
  Translate to static `@keyframes` in `additions.css`.
- **The prototype triggers are non-keyboard `<span onClick>`** — translate menu triggers to real `<button>`s.
- **`TabNav` uses no floor** — it is inline link-nav (`<a aria-current="page">`); restore its `:focus-visible`
  ring (the prototype's `outline:"none"` has no replacement).
- **Hover cards keep `setTimeout` ids in refs** (`timer`/`openT`/`closeT`) — guard the React-19 nullable
  `ref.current` reads.
- **`sb:typecheck` is the authoritative story NO-INVENT gate** (the library `tsc` excludes `**/*.stories.tsx`).
- **`@mercury/core` imports are RELATIVE through the barrel** (the mx.1 `@/`-alias landmine).

## The file tree (create exactly these; nothing else)

```
# @mercury/ui — the 6 homes (4 files each)
packages/mercury-ui/src/components/overlay/Dropdown/{Dropdown.tsx, index.ts, Dropdown.prompt.md, Dropdown.stories.tsx}
packages/mercury-ui/src/components/overlay/ContextMenu/{ContextMenu.tsx, index.ts, ContextMenu.prompt.md, ContextMenu.stories.tsx}
packages/mercury-ui/src/components/overlay/HoverCard/{HoverCard.tsx, index.ts, HoverCard.prompt.md, HoverCard.stories.tsx}
packages/mercury-ui/src/components/overlay/LinkPreview/{LinkPreview.tsx, index.ts, LinkPreview.prompt.md, LinkPreview.stories.tsx}
packages/mercury-ui/src/components/navigation/Menubar/{Menubar.tsx, index.ts, Menubar.prompt.md, Menubar.stories.tsx}
packages/mercury-ui/src/components/navigation/TabNav/{TabNav.tsx, index.ts, TabNav.prompt.md, TabNav.stories.tsx}
packages/mercury-ui/src/index.ts                                   # +6 barrel lines (additive)
packages/mercury-ui/src/styles/additions.css                      # +6 .mx-* blocks + static @keyframes + accent ramps
```

(`Menubar`/`TabNav` group = `navigation` per the body §A note; `overlay` is the alternative if the Operator
prefers. No `@mercury/core` file unless a floor addendum is needed.)

## The translation recipe (every component)

1. Read the bundle `.tsx` → extract the prop surface + anatomy (ignore the inline `style={{}}` values + the
   `ensureKeyframes` injection).
2. Write `<Name>.tsx`: `import type { … } from "react"`, `import { cx } from "@mercury/core"` + the **7.4 floor
   hooks** + (menus) `<Portal>`, a `forwardRef`/function component extending the HTML attrs, `className={cx(
   "mx-<name>", …modifiers, className)}`. Route portal/dismiss/position/arrow-nav through the floor — do **not**
   re-roll the inline effects.
3. Add the `.mx-<name>` rules + the static `@keyframes` + the `.mx-<name>--accent-<id>` ramps to
   `src/styles/additions.css` — `rgb(var(--token))` only, no raw hex.
4. `index.ts` = `export * from "./<Name>";`. Add the line to `src/index.ts` (additive — never remove/rename).
5. `<Name>.prompt.md` — hand-author (mx.2 format): role · `## Props` · `## The enum language` · `## Composition`
   (cross-links by real relative path) · `## Examples` (net-new → end each with "(source-grounded; no app call
   site)") · `## Notes` (a11y + the React-19 nullable-ref guard). Strip all bundle framing.
6. `<Name>.stories.tsx` — CSF3 (`Meta`/`StoryObj`), `title: "<Group>/<Name>"`, a Playground + a states grid +
   **the a11y assertion INV-A11Y requires** (below). (mx.8 enriches later — keep the basic mx.4 shape now.)

## The a11y hardening checklist (per family — the HIGH-risk core; canon §8)

- **Dropdown / ContextMenu / Menubar (menus):** `role="menu"`/`menuitem`/`menuitemcheckbox`/`menuitemradio`;
  trigger `aria-haspopup="menu"`+`aria-expanded`; **`useArrowNavigation`** (Arrow/Home/End); `Escape` +
  outside-click; focus-return. `Menubar` adds `role="menubar"` + Left/Right between menus. `ContextMenu` adds
  scroll-dismiss. Translate the prototype's `<span onClick>` triggers to real `<button>`s.
- **HoverCard / LinkPreview (cards):** open on **hover AND focus**; `role="dialog"`; open/close delays preserved;
  non-modal (no trap); guard the nullable `timer`/`openT`/`closeT` refs.
- **TabNav:** keep `<a aria-current="page">`; **restore the `:focus-visible` ring** (read the indigo ring
  tokens).

## The gate (run from `mercury/`)

```bash
pnpm --filter "./packages/*" typecheck
pnpm --filter "./packages/*" build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build   # echomq + mobile
pnpm sb:typecheck                                                # authoritative story NO-INVENT gate
pnpm sb:build                                                    # prior homes + 6

# barrel additive (resolve the full set, not a text-diff): 0 removed/renamed, +6 (+ Props/item/enum types),
#   Tabs/Accordion/Pagination + the 7.4 overlays byte-present.
# idiom + hygiene greps — expect EMPTY:
grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})" packages/mercury-ui/src/components/{overlay/Dropdown,overlay/ContextMenu,overlay/HoverCard,overlay/LinkPreview,navigation/Menubar,navigation/TabNav}
grep -rnE "#[0-9a-fA-F]{3,8}\b" packages/mercury-ui/src/components/{overlay/Dropdown,overlay/ContextMenu,overlay/HoverCard,overlay/LinkPreview,navigation/Menubar,navigation/TabNav} packages/mercury-ui/src/styles/additions.css
grep -rn  "mercAccent\|_lib/accent" packages/mercury-ui/src/components
grep -rn  "createElement(\"style\")\|ensureKeyframes" packages/mercury-ui/src/components
grep -rniE "check_design_system|pixel-perfect|/design-sync|showcase/|window\.Mercury|_ds_bundle" packages/mercury-ui/src/components/{overlay/Dropdown,overlay/ContextMenu,overlay/HoverCard,overlay/LinkPreview,navigation/Menubar,navigation/TabNav}

# floor-consumed (no inline re-roll) — expect EMPTY:
grep -rn "addEventListener(\"mousedown\"\|addEventListener('mousedown'" packages/mercury-ui/src/components/{overlay/Dropdown,overlay/ContextMenu,overlay/HoverCard,overlay/LinkPreview,navigation/Menubar}
```

## Gotchas

- **Compose the 7.4 floor; do not re-roll the inline dismiss/positioning effects, and do not rebuild the floor.**
  If a behavior 7.4 didn't surface is needed, it is a one-line 7.4-floor addendum (a `@mercury/core` widening),
  called out at build — not a re-home.
- **No `mercAccent` in the library** (Dropdown/Menubar `accent` is class-driven); **no runtime `@keyframes`
  injection** (static CSS).
- **Translate `<span onClick>` triggers to real `<button>`s** (keyboard-reachable) — the prototypes' triggers
  are not.
- **`TabNav` is link-nav, not the panel `Tabs`** — distinct component, cross-link + disambiguate; restore its
  focus ring.
- **Never rename `Tabs`/`Accordion`/`Pagination` or any existing export** (master invariant).
- **The INV-A11Y gate must EXERCISE the behavior** — a story that renders a `Dropdown` but never asserts
  `ArrowDown` moves focus / `aria-expanded` toggles does NOT satisfy it.
- **Squad-tier at ship:** the verifier is MANDATORY (HIGH risk — six a11y state machines + a +6 surface). It
  adversarially re-runs the a11y proofs.
- **Commit hygiene:** the bundle `packages/mercury-ds/` stays OUT of the commit; `mercury/…` pathspec only;
  never `git add -A`; never `pnpm -r` (use `--filter`). The Director commits; agents run no git.
- **Framing (propagate into every contract):** no gendered pronouns for agents; no perceptual/interior-state
  verbs; no first-person narration; state each surface as a contract (precondition / postcondition / invariant).

## Lessons carried from the prior batch

> The Director fills this from mx.7.4 as-built at release. Known carry-forwards: the **overlay-floor API** (the
> exact `useDismiss`/`useAnchoredPosition`/`useArrowNavigation`/`<Portal>` names + signatures); the
> **a11y-assertion pattern** (exercise-the-outcome stories); the `accent`-class pattern (mx.7.1); the live-idiom
> translation recipe proven across batches 1–4.

## When this batch later ships

Its aaw scope slug is the **dashed** form `mx-7-5` (never `mx.7.5` — a dot split-brains the aaw registry). It
ships after `mx-7-4` (the floor it composes). No team is created at authoring time.
