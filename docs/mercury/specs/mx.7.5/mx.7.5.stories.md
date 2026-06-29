# mx.7.5 · acceptance stories

Given/When/Then for [`mx.7.5.md`](./mx.7.5.md). Connextra form; each names the deliverable + the invariant(s)
it proves. **Coverage:** K-1 → S-2..S-7 ; K-2 → S-1, S-8 ; K-3 → S-9 ; K-4 → S-2..S-7, S-10 ; K-5 → S-8 ; K-6 →
S-2..S-7 ; K-7 → S-11 ; K-8 → S-7 ; K-9 → S-10 ; K-10 → S-10.

## S-1 · The menus & cards compose the 7.4 floor — no re-roll (K-2)
*As an **overlay author**, I want every menu and hover card to reuse the floor 7.4 proved, so that dismiss,
positioning, and arrow-navigation are one hardened contract, not six inline copies.*
**Given** the 7.4 overlay-floor is published (`useDismiss`/`useAnchoredPosition`/`useArrowNavigation`/`useId`/
`<Portal>`, in the ruled home), **when** `Dropdown`/`ContextMenu`/`HoverCard`/`LinkPreview`/`Menubar` are built,
**then** each imports those floor hooks (no inline `mousedown`-outside / `keydown`-Escape effect copied per
component), the menus use `useArrowNavigation` for item focus, and `TabNav` (inline link-nav) uses **none** of
the floor. *(Proves INV-FLOOR-CONSUMED.)*

## S-2 · Dropdown is a keyboard-navigable command menu (K-1, K-4, K-6)
*As an **actions author**, I want a `Dropdown` of items/labels/separators/checks, so that a trigger reveals a
keyboard-navigable command menu.*
**Given** `overlay/Dropdown/`, **when** `<Dropdown trigger={…} items={…} accent="iris" align="end">` renders,
**then** rows map to `role="menuitem"`/`menuitemcheckbox`, the trigger carries `aria-haspopup="menu"`/
`aria-expanded`, `ArrowDown`/`ArrowUp`/`Home`/`End` move item focus (`useArrowNavigation`), `accent` resolves
via `.mx-dropdown--accent-*` classes (**no `mercAccent`**), a `separator` row is a `Separator`, and `Escape`/
outside-click dismiss. *(Proves INV-2 + INV-4 + INV-A11Y.)*

## S-3 · ContextMenu opens at the pointer (K-1, K-4, K-6)
*As a **canvas author**, I want a right-click `ContextMenu` positioned at the pointer, so that contextual
commands appear where the user clicked.*
**Given** `overlay/ContextMenu/`, **when** the user right-clicks the wrapped area, **then** the menu opens
pointer-anchored (`position: fixed`, viewport-clamped) via the floor's pointer case, a `danger` item reads
`--fg-negative` via `.mx-ctx__item--danger` (not an inline literal), and it dismisses on `Escape`, outside-click,
**and** scroll. *(Proves INV-2 + INV-A11Y.)*

## S-4 · HoverCard is the interactive hover preview (K-1, K-4, K-6)
*As a **profile author**, I want a `HoverCard` that opens on hover **and focus**, so that a rich preview is
reachable by keyboard, unlike a Tooltip.*
**Given** `overlay/HoverCard/`, **when** the anchor is hovered or focused, **then** the card opens after
`openDelay`, closes after `closeDelay`, positions via `useAnchoredPosition(placement: top/bottom/left/right)`,
is non-modal (`role="dialog"`, no focus-trap), guards its React-19 nullable `timer.current` ref, and its
contract cross-links `Tooltip` (interactive vs static). *(Proves INV-2 + INV-A11Y.)*

## S-5 · LinkPreview reveals a link's preview on hover (K-1, K-4, K-6)
*As a **content author**, I want a `LinkPreview` that reveals a rich card for an inline link, so that a reader
previews a destination without leaving the page.*
**Given** `overlay/LinkPreview/`, **when** the inline trigger is hovered or focused, **then** the card opens
after `openDelay` at `placement: top/bottom`, shares the hover-card style family (`.mx-*` + tokens, static
`@keyframes`), and its contract cross-links `HoverCard`/`Link`. *(Proves INV-2 + INV-4.)*

## S-6 · Menubar is the desktop command bar (K-1, K-4, K-6)
*As an **app-shell author**, I want a `Menubar` of menus with checks/radios/shortcuts, so that a desktop-style
command bar is keyboard-navigable.*
**Given** `navigation/Menubar/`, **when** `<Menubar menus={…} accent="iris">` renders, **then** it emits
`role="menubar"` with `role="menu"`/`menuitemradio` items, opens on click + switches on hover, moves between
menus with Left/Right and within with `useArrowNavigation`, resolves `accent` via `.mx-menubar--accent-*`
classes (**no `mercAccent`**), and dismisses on `Escape`/outside-click. *(Proves INV-2 + INV-4 + INV-A11Y.)*

## S-7 · TabNav is route-level link navigation, in the ruled group (K-1, K-4, K-6, K-8)
*As a **page author**, I want a `TabNav` of links whose active tab reflects the route, so that page-level
navigation is real anchors, not panel tabs.*
**Given** `navigation/TabNav/` (the §A-ruled group home), **when** `<TabNav items={…} value="overview"
onChange={…} size="md">` renders, **then** each item is an `<a aria-current="page">` (with `href` fallback for
non-SPA), the active bottom border reads `--bg-brand`, the **focus ring is restored**
(`.mx-tabnav__link:focus-visible` reads the indigo ring tokens — fixing the prototype's `outline:none`), and its
contract cross-links `Tabs` (link-nav vs panel-tabs). *(Proves INV-2 + INV-5 + the §A group ruling.)*

## S-8 · The a11y is exercised, not merely rendered (K-2, K-5) — the liveness-bearing gate
*As an **accessibility owner**, I want each overlay's a11y behavior **proven by an assertion that runs it**, so
that a render-only story cannot pass while proving nothing.*
**Given** the translated menus/cards + their stories, **when** the a11y checks run, **then** each **exercises its
own outcome**: a `Dropdown`/`Menubar` story asserts `aria-haspopup`+`aria-expanded` toggles and `ArrowDown`
moves `menuitem` focus; a `ContextMenu` story asserts right-click opens at the pointer and `Escape` dismisses; a
`HoverCard` story asserts **focus** (not only hover) opens it; a `TabNav` story asserts `aria-current="page"` on
the active link and a visible ring on `:focus-visible`. A story that touches none of these does **not** satisfy
this gate. *(Proves INV-A11Y — a check counts only if it RUNS.)*

## S-9 · The barrel grows +6 additively (K-3)
*As a **downstream consumer**, I want every prior export preserved, so that nothing I import breaks.*
**Given** the `@mercury/ui` barrel before/after, **when** the resolved export set is compared (TS
`getExportsOfModule`, not a text-diff), **then** it is a **superset** — 0 removed, 0 renamed — with exactly the
6 new component names + their `Props`/item/enum types added, and `Tabs`/`Accordion`/`Pagination` + the 7.4
overlays byte-present. *(Proves INV-1.)*

## S-10 · Accent is class-driven; keyframes static; gate green; tokens additive; design DOWN (K-4, K-9, K-10)
*As a **token owner / Director**, I want `accent` realized as token classes, `@keyframes` as static CSS, the gate
green, no token value changed, and no design push, so that the batch ships clean.*
**Given** `Dropdown`/`Menubar` (which import `mercAccent` in the bundle) + every menu/card's `ensureKeyframes()`
injection, **when** they are translated and the gate runs, **then** `accent` resolves via `.mx-<name>--accent-<id>`
classes reading the `--<ramp>-9`/`--<ramp>-11` families (no `mercAccent`/`_lib/accent` import anywhere in
`packages/mercury-ui/src/components`), the animations are **static `@keyframes` in `additions.css`** (no
`document.createElement("style")`), the package + apps + `sb:typecheck` + `sb:build` commands exit 0, the
barrel-diff is 0 removed/renamed, any `tokens.css` change is an **added** line only, and **no**
`/design-sync`/`DesignSync` invocation occurred. *(Proves INV-2 + INV-4 + INV-7 + INV-DOWN + INV-8.)*

## S-11 · The 1:1 story↔folder invariant holds (K-7)
*As a **Storybook maintainer**, I want each new component to carry exactly one co-located story, so that the
mx.4 invariant stays intact.*
**Given** the 6 new folders, **when** `pnpm sb:typecheck` + `pnpm sb:build` run, **then** `sb:typecheck` exits 0
(the NO-INVENT story gate), `count(*.stories.tsx) == count(component folders)`, and `sb:build` registers exactly
the prior homes + 6. *(Proves INV-6.)*
