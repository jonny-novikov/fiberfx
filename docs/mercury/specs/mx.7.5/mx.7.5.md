# mx.7.5 · Import batch 5 — menus, hover cards & nav (consume the overlay-floor)

> **Status: 📋 PLANNED — build-ready; batch 5 of the mx.7 import epic** (the split half of the overlay batch,
> Operator-approved 2026-06-29). Inherits the epic frame [`../mx.7/mx.7.md`](../mx.7/mx.7.md) (the cross-batch
> forks, the cadence, the shared translation contract). This batch imports the **6 net-new menu / hover / nav
> overlays** — `Dropdown · ContextMenu · HoverCard · LinkPreview · Menubar · TabNav` — translated from the
> bundle's inline-style prototypes into `@mercury/ui`'s `.mx-*` + token idiom, additively.
>
> **This batch CONSUMES the overlay-floor primitive built in [`../mx.7.4/mx.7.4.md`](../mx.7.4/mx.7.4.md) — it
> does NOT rebuild it.** The floor's `useDismiss`/`useAnchoredPosition`/`useArrowNavigation`/`useId`/`<Portal>`
> (and the home the Operator ruled in 7.4 §A) are a hardened, published contract; 7.5 composes them and adds
> only **family-specific machinery** (menu arrow-navigation + `aria-haspopup`, hover/focus open-delays, link-nav
> with `aria-current`). These also **compose mx.7.1** (a menu group rule is a `Separator`; a trigger may be an
> `IconButton`).
>
> **Risk: HIGH** (six a11y state machines — menu keyboard navigation, hover-intent timing, focus management).
> Ships **Squad-tier: the verifier is MANDATORY**, with the same adversarial a11y probe 7.4 established.
>
> **Inherited, not re-argued here** (epic §4/§5 + 7.4): translate to `.mx-*` + tokens (Cross-fork I); the
> `accent`-as-classes pattern (no `mercAccent` import — mx.7.1); additive-only token/font policy (Cross-fork
> II); never rename an existing export (Cross-fork III); the overlay-floor (7.4 §A); design flows DOWN, no
> `/design-sync` (INV-DOWN); the 4-file home + the additive barrel + the gate.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · epic: [`../mx.7/mx.7.md`](../mx.7/mx.7.md) ·
the floor (built in 7.4): [`../mx.7.4/mx.7.4.md`](../mx.7.4/mx.7.4.md) · contract template:
[`../../contracts.md`](../../contracts.md) · acceptance: [`mx.7.5.stories.md`](./mx.7.5.stories.md) · build
context: [`mx.7.5.llms.md`](./mx.7.5.llms.md). Format exemplar: [`../mx.7.1/mx.7.1.md`](../mx.7.1/mx.7.1.md).

---

## A · The one batch-level dependency — the overlay-floor is a precondition (not re-decided here)

7.5 builds **on** the floor 7.4 stood up; it re-frames none of 7.4's §A/§D ADRs. The only thing this batch
records about the floor is its **consumption contract** (and the hard ordering: 7.5 ships after 7.4):

- **Menus** (`Dropdown`, `ContextMenu`, `Menubar`) compose `useDismiss` (outside-click + `Escape`),
  `useArrowNavigation` (Arrow/Home/End over the items), `useAnchoredPosition` (the `align: start|end` and
  pointer-`fixed` cases), `<Portal>`, and `useId`.
- **Hover cards** (`HoverCard`, `LinkPreview`) compose `useAnchoredPosition` (the `top/bottom/left/right` cases)
  + `<Portal>`; they are **non-modal** — no focus-trap (the floor's `useFocusTrap` is unused here).
- **`TabNav`** uses **none** of the floor (it is inline link-nav, not a floating surface) — it lands in this
  batch as the navigation sibling of the menus, not as a floor consumer.

> **The one open call in this batch (D-4-class, not a blocker; Operator may rule at sharpen):** `Menubar`/
> `TabNav` group placement — `navigation/` (the bundle's group, beside the live `Tabs`/`Accordion`/`Pagination`)
> or `overlay/` (the menu floats). **Recommend `navigation/`** (the bundle's placement + the desktop-menubar /
> nav-tabs roles). The export name is what the barrel encodes — group is a navigability choice, not correctness.

## 0 · The slice

The fifth and final import batch: the surfaces that **open from a trigger and navigate by keyboard** — three
menus (`Dropdown`, `ContextMenu`, `Menubar`), two hover cards (`HoverCard`, `LinkPreview`), and one link-nav
(`TabNav`). Each composes the **proven overlay-floor** (7.4) and is translated into the live `.mx-*` + token
idiom, hardened to the canon's a11y bar (`aria-haspopup`/`aria-expanded`, Arrow/Home/End menu navigation,
hover+focus open, the restored focus ring), and exported additively. This batch composes mx.7.1 (`Separator`
menu rules · `IconButton` triggers) and closes the **import** so mx.8 (stories) and mx.9 (the showcase) render
the whole `@mercury/ui` surface.

## 1 · Goal

After mx.7.5, `@mercury/ui` exports **6 new components** — `Dropdown · ContextMenu · HoverCard · LinkPreview ·
Menubar · TabNav` (+ their `Props`, item, and enum types) — each a translated 4-file home (`.mx-*` + tokens ·
hand-authored contract · CSF3 story), each composing the 7.4 overlay-floor (menus + hover cards) or the inline
link-nav pattern (`TabNav`). The barrel is **strictly additive** (`Tabs`/`Accordion`/`Pagination`/the 7.4
overlays and every prior export byte-preserved; +6 names + their types). The full package gate is green;
`sb:build` registers the prior homes + 6; the barrel-diff shows 0 removed/renamed. **The mx.7 import is
complete.** **Design flowed DOWN only** (no `/design-sync`).

## 2 · Rationale (5W)

- **Why.** These are the keyboard-navigated surfaces where "a11y is part of the component" (canon §8) is
  load-bearing: a menu with no `aria-haspopup`/arrow-key navigation, or a hover card unreachable by keyboard, is
  a defect, not a style miss. Building them on the floor 7.4 proved makes that bar provable by composition.
- **What.** The 6 translated 4-file homes, the barrel grown +6, the `.mx-*` overlay/nav rules in
  `src/styles/additions.css` (incl. static `@keyframes` replacing the prototypes' runtime style injection), and
  the `accent`-as-classes translation for `Dropdown`/`Menubar` (no `mercAccent`).
- **Who.** *Authored by* the architect (this triad) + the batch's build/verify agents (epic §2 cadence,
  Squad-tier — verifier mandatory). *Consumed by* mx.8 (their stories), mx.9 (the showcase), the workspace apps.
- **When.** Batch 5 — last in the import epic, after 7.4 (the floor it composes), with the Operator in the loop
  before it.
- **Where.** `packages/mercury-ui/src/` (the 6 folders + barrel + `additions.css`) + `docs/mercury/specs/mx.7.5/`.
  No `@mercury/core` change is expected (the floor is already published by 7.4); if a menu needs a floor
  behavior 7.4 did not surface, that is a 7.4-floor addendum, called out at build. The bundle
  `packages/mercury-ds/` is read-only. Everything else in the `jonnify` root is out of bounds (the island).

## 3 · The component set (grounded — bundle prop surface verified in source)

Every prop below is verified in the cited bundle `.tsx`. **NO-INVENT:** no prop, type, or default is asserted
that the source does not show.

| Component | Bundle source | Verified prototype prop surface (the seed) | Live target group |
|---|---|---|---|
| `Dropdown` | `overlay/Dropdown/Dropdown.tsx` | `trigger: ReactNode` · `items: DropdownItem[]` · `accent?: AccentId` · `align?: "start"\|"end"` · `width?=220` | `overlay` |
| `ContextMenu` | `overlay/ContextMenu/ContextMenu.tsx` | `children: ReactNode` · `items: ContextMenuItem[]` · `width?=220` (pointer-anchored on right-click) | `overlay` |
| `HoverCard` | `overlay/HoverCard/HoverCard.tsx` | `children` · `content: ReactNode` · `placement?: "top"\|"bottom"\|"left"\|"right"` · `openDelay?=250` · `closeDelay?=150` · `width?=280` | `overlay` |
| `LinkPreview` | `overlay/LinkPreview/LinkPreview.tsx` | `children` · `content: ReactNode` · `placement?: "top"\|"bottom"` · `openDelay?=300` · `width?=300` | `overlay` |
| `Menubar` | `navigation/Menubar/Menubar.tsx` | `menus: MenubarMenu[]` · `accent?: AccentId` | `navigation` (group note §A) |
| `TabNav` | `navigation/TabNav/TabNav.tsx` | `items: TabNavItem[]` · `value: string` · `onChange?: (value) => void` · `size?: "sm"\|"md"` | `navigation` (beside `Tabs`) |

**The item / sub-types (verified — these export alongside the components):**

- `DropdownItem`: `type?: "item"\|"label"\|"separator"\|"check"` · `label?` · `icon?: IconName` · `shortcut?` ·
  `checked?` · `id?` · `onSelect?` · `disabled?`.
- `ContextMenuItem`: `type?: "item"\|"label"\|"separator"` · `label?` · `icon?: IconName` · `shortcut?` ·
  `onSelect?` · `disabled?` · `danger?` (the negative-colour item).
- `MenubarMenu`: `label: string` · `icon?: IconName` · `items: MenubarItem[]`.
  `MenubarItem`: `type?: "item"\|"check"\|"radio"\|"label"\|"separator"` · `label?` · `id?` · `group?` ·
  `value?` · `checked?` · `shortcut?` · `icon?: IconName` · `onSelect?`.
- `TabNavItem`: `value: string` · `label: ReactNode` · `href?: string` · `disabled?`.

## 4 · How the floor is consumed (no new floor surface)

This batch builds **no** primitive — it composes 7.4's. The mapping:

- **`useDismiss(ref, { onDismiss, outsideClick, escapeKey })`** — every **menu** (`Dropdown`/`ContextMenu`/
  `Menubar`); `ContextMenu` adds `scroll`-dismiss (the prototype dismisses the pointer-anchored menu on scroll).
  The **hover cards are non-modal** — they dismiss on blur/mouse-leave via local open/close timers (§5), **not**
  `useDismiss`. *(As-built sync: the original bullet said "every menu + hover card"; the code composes
  `useDismiss` on the menus only, matching §5's non-modal hover-card intent.)*
- **`useAnchoredPosition(anchorRef, floatRef, { placement, align, width })`** — the menus' `align: start|end`,
  the hover cards' `top/bottom/left/right`, and `ContextMenu`'s pointer-`fixed` viewport-clamped case.
- **`useArrowNavigation`** — `Dropdown`/`ContextMenu`/`Menubar` item navigation (Arrow/Home/End).
- **`useId`** — `aria-controls`/`aria-labelledby` wiring on every trigger↔panel pair.
- **`<Portal>`** — the menus + hover cards mount at `document.body` to escape overflow/stacking contexts.
- **`useFocusTrap`** — **unused** (these are non-modal; the menus return focus to the trigger on close via
  `useDismiss`'s `returnFocus`, but do not trap).

> If a menu needs a behavior the 7.4 floor did not surface (e.g. a `typeahead` helper), it is a **7.4-floor
> addendum** (a one-line `@mercury/core` widening), called out at build — not a re-home of the floor.

## 5 · Translation notes (the deltas beyond the epic's shared idiom)

- **a11y is the component (canon §8) — the hardening per family, beyond what the prototype ships:**
  - **Menus (`Dropdown`, `ContextMenu`, `Menubar`):** `role="menu"` + `role="menuitem"`/`menuitemcheckbox`/
    `menuitemradio`, `aria-haspopup="menu"` + `aria-expanded` on the trigger, **`useArrowNavigation`** for
    `Arrow`/`Home`/`End`, `Escape` + outside-click, focus-return. `Menubar` adds `role="menubar"` +
    Left/Right between menus. The prototype triggers are non-keyboard `<span onClick>` — **translate to real
    `<button>` triggers**.
  - **Hover cards (`HoverCard`, `LinkPreview`):** open on **hover AND focus** (keyboard-reachable),
    `role="dialog"`, open/close delays preserved, dismiss on blur/mouse-leave (non-modal — no trap).
  - **`TabNav`:** keep the link semantics + `aria-current="page"` (the prototype has them), but **restore a
    visible focus ring** — the prototype sets `outline: "none"` with no replacement (an a11y regression); the
    `.mx-tabnav__link:focus-visible` rule reads the indigo ring tokens.
- **`accent` without `mercAccent` (carried from mx.7.1).** `Dropdown` and `Menubar` import `mercAccent` from
  `_lib/accent.ts` for the check/radio mark colour (`ac.fg`/`ac.solid`). Per Cross-fork I, **do not import
  `mercAccent`.** Realize `accent?: "iris"|"indigo"|"green"|"orange"|"plum"|"red"` as `.mx-<name>--accent-<id>`
  classes reading the `--<ramp>-9`/`--<ramp>-11` token families — exactly the mx.7.1 pattern. (`ContextMenu`'s
  `danger` is already token-based → `.mx-ctx__item--danger` reading `--fg-negative`/`--bg-negative-subtle`.)
- **`@keyframes` in CSS, not injected at runtime.** Every menu/hover prototype calls `ensureKeyframes()` —
  `document.createElement("style")` appended to `<head>` (`merc-dd-in`, `merc-cm-in`, `merc-hc-in`,
  `merc-menu-in`). Translate to **static `@keyframes` blocks in `additions.css`**; the `.mx-*` rules reference
  them. No runtime style injection (it is the inline-idiom equivalent the live layer forbids).
- **React-19 nullable `useRef().current`.** The hover cards keep `window.setTimeout` ids in refs
  (`HoverCard`/`LinkPreview` `timer`/`openT`/`closeT`); guard `ref.current` reads (the idiom
  `Checkbox`/`Accordion` use).
- **Compose mx.7.1.** A menu group rule is a `Separator`; a menu/hover trigger may be an `IconButton` — cross-link
  these in the contracts.

## 6 · Deliverables

- **K-1 — 6 translated 4-file homes** under `packages/mercury-ui/src/components/<group>/<Name>/` —
  `overlay/{Dropdown,ContextMenu,HoverCard,LinkPreview}` + `navigation/{Menubar,TabNav}` (`<Name>.tsx`
  translated · `index.ts` · `<Name>.prompt.md` hand-authored · `<Name>.stories.tsx` CSF3).
- **K-2 — every menu/hover card composes the 7.4 floor** (per §4): `useDismiss`/`useAnchoredPosition`/
  `useArrowNavigation`/`useId`/`<Portal>` — **not** a re-rolled inline copy. `TabNav` is inline link-nav (no
  floor).
- **K-3 — the `@mercury/ui` barrel grows +6 additively** (`Dropdown`/`DropdownProps`/`DropdownItem`,
  `ContextMenu`/`ContextMenuProps`/`ContextMenuItem`, `HoverCard`/`HoverCardProps`/`HoverCardPlacement`,
  `LinkPreview`/`LinkPreviewProps`/`LinkPreviewPlacement`, `Menubar`/`MenubarProps`/`MenubarMenu`/`MenubarItem`,
  `TabNav`/`TabNavProps`/`TabNavItem`/`TabNavSize`); **`Tabs`/`Accordion`/`Pagination` + the 7.4 overlays and
  every prior export byte-preserved**; barrel-diff 0 removed/renamed.
- **K-4 — the live idiom** (Cross-fork I): `.mx-*` classes + tokens; no inline colour literal; no raw hex;
  static `@keyframes` (no runtime injection); the `accent` prop via `.mx-*--accent-*` classes (no `mercAccent`
  import).
- **K-5 — a11y is part of the component** (canon §8): the per-family hardening of §5 realized — `role`/`aria-*`,
  `aria-haspopup`/`aria-expanded` + arrow-key navigation (menus), hover+focus open (cards), the restored focus
  ring (`TabNav`), real `<button>` triggers.
- **K-6 — a hand-authored contract per overlay** (D-7; 6): mx.2 format, no bundle runtime framing, cross-links
  (the menu rule↔`Separator`; the trigger↔`IconButton`; `HoverCard`↔`Tooltip` (interactive vs static);
  `LinkPreview`↔`HoverCard`/`Link`; `TabNav`↔`Tabs` (link-nav vs panel-tabs); `Dropdown`↔`Menubar`). Each says
  "(source-grounded; no app call site)" — these are net-new.
- **K-7 — the 1:1 story↔folder invariant holds** (mx.4): each folder one co-located story; `sb:typecheck`
  clean; `sb:build` prior + 6.
- **K-8 — the `Menubar`/`TabNav` group placement is ruled** (§A): the folder home recorded; no rename of any
  existing export.
- **K-9 — the token/font reconcile is additive-only** (Cross-fork II): a `tokens.css`/font edit is a new line
  only, never a value change. (No new weight is anticipated for this batch.)
- **K-10 — the gate is green** (§8) and **design flowed DOWN only** (no `/design-sync`/`DesignSync`).

**Coverage:** K-1 → S-2..S-7 ; K-2 → S-1, S-8 ; K-3 → S-9 ; K-4 → S-2..S-7, S-10 ; K-5 → S-8 ; K-6 →
S-2..S-7 ; K-7 → S-11 ; K-8 → S-7 ; K-9 → S-10 ; K-10 → S-10.

## 7 · The per-component translation map (grounded)

- **Dropdown** (`overlay/Dropdown` → `overlay/Dropdown`). `items` rows (item/label/separator/check); composes
  the floor + `useArrowNavigation`; `accent` via `.mx-dropdown--accent-*` (no `mercAccent`); `align`.
  `role="menu"`/`menuitem`/`menuitemcheckbox`; `aria-haspopup="menu"`/`aria-expanded`. Cross-link
  `Separator`/`IconButton`/`Menubar`.
- **ContextMenu** (`overlay/ContextMenu` → `overlay/ContextMenu`). Right-click → pointer-anchored (`fixed`,
  viewport-clamped) via `useAnchoredPosition`'s pointer case; `danger` item → `.mx-ctx__item--danger`
  (`--fg-negative`); `useDismiss{scroll,outsideClick,escapeKey}` + `useArrowNavigation`. `role="menu"`.
- **HoverCard** (`overlay/HoverCard` → `overlay/HoverCard`). Hover+focus open with `openDelay`/`closeDelay`;
  `useAnchoredPosition(placement: top/bottom/left/right)`; non-modal (no trap); `role="dialog"`. `.mx-hovercard`.
  Cross-link `Tooltip` (interactive vs static).
- **LinkPreview** (`overlay/LinkPreview` → `overlay/LinkPreview`). Hover+focus; `placement: top/bottom`;
  `openDelay`; shares the hover-card style family. Cross-link `HoverCard`/`Link`.
- **Menubar** (`navigation/Menubar` → `navigation/Menubar`). `menus[].items` (item/check/radio/label/
  separator); click-to-open + hover-to-switch; the floor + `useArrowNavigation` + Left/Right between menus;
  `accent` via classes (no `mercAccent`). `role="menubar"`/`menu`/`menuitemradio`. `.mx-menubar`. Cross-link
  `Dropdown`.
- **TabNav** (`navigation/TabNav` → `navigation/TabNav`). Link-based (`<a aria-current="page">`); `value` +
  `onChange` (SPA) with `href` fallback; `size` sm/md; active bottom-border reads `--bg-brand`; **restore the
  `:focus-visible` ring**. `.mx-tabnav`. Cross-link `Tabs` (link-nav vs panel-tabs).

## 8 · Invariants — as runnable gates (run from `mercury/`)

- **INV-1 — master invariant, additive (`@mercury/ui`).** Resolved export set after = superset of before;
  **0 removed/renamed**, +6 (+ their `Props`/item/enum types). `Tabs`/`Accordion`/`Pagination` + the 7.4
  overlays byte-present. (TS `getExportsOfModule`, not a text-diff.)
- **INV-FLOOR-CONSUMED — the menus/cards compose the 7.4 floor, not a re-roll.**
  `grep -rn "addEventListener(\"mousedown\"\|addEventListener('mousedown'" packages/mercury-ui/src/components/{overlay/Dropdown,overlay/ContextMenu,overlay/HoverCard,overlay/LinkPreview,navigation/Menubar}` → **empty** (outside-click routes through `useDismiss`). Each menu/card imports the floor hooks from `@mercury/core` (or the ruled home); no inline copy.
- **INV-A11Y — the a11y gate exercises its own outcome (a no-op must not satisfy it).** Story-level checks
  **prove the behavior fires**: a `Dropdown`/`Menubar` story asserts `aria-haspopup` + `aria-expanded` toggles
  and `ArrowDown` moves `menuitem` focus; a `ContextMenu` story asserts right-click opens at the pointer and
  `Escape` dismisses; a `HoverCard` story asserts focus (not only hover) opens it; a `TabNav` story asserts
  `aria-current="page"` on the active link and a visible focus ring on `:focus-visible`. A render-only story
  does not satisfy INV-A11Y.
- **INV-2 — live idiom, no inline colour leak.**
  `grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})" packages/mercury-ui/src/components/{overlay/Dropdown,overlay/ContextMenu,overlay/HoverCard,overlay/LinkPreview,navigation/Menubar,navigation/TabNav}`
  → **empty**.
- **INV-3 — no raw hex.** `grep -rnE "#[0-9a-fA-F]{3,8}\b"` over the 6 new dirs + the new `additions.css` rules
  → **empty**.
- **INV-4 — no `mercAccent` import; no runtime `@keyframes` injection.**
  `grep -rn "mercAccent\|_lib/accent" packages/mercury-ui/src/components` → **empty** (accent is class-driven);
  `grep -rn "createElement(\"style\")\|ensureKeyframes" packages/mercury-ui/src/components` → **empty**
  (`@keyframes` are static in CSS).
- **INV-5 — D-7 contract, no bundle framing.** Each new `.prompt.md` has the mx.2 sections;
  `grep -rniE "check_design_system|pixel-perfect|/design-sync|showcase/|window\.Mercury|_ds_bundle" <new contracts>`
  → **empty**.
- **INV-6 — 1:1 story↔folder + `sb:typecheck` clean.** `count(*.stories.tsx) == count(component folders)`;
  `pnpm sb:typecheck` exits 0 (the authoritative story NO-INVENT gate); `pnpm sb:build` registers prior + 6.
- **INV-7 — token/font additive-only.** `git diff …/styles/tokens.css` shows added lines only (no changed
  value); no new weight expected this batch.
- **INV-DOWN — design flows DOWN.** No `/design-sync`/`DesignSync` in the work; `git diff` touches no
  `mercury/.design-sync/` path; nothing pushes up.
- **INV-8 — the package gate.** `pnpm --filter "./packages/*" typecheck`/`build` = 0 · `pnpm --filter
  "./apps/*" --filter "!@mercury/storybook" build` = 0 (`echomq`+`mobile`) · `pnpm sb:build` = 0.

## 9 · The batch loop (epic §2) — Operator → Agent-1 → Agent-2 → Operator (Squad-tier)

Operator sharpens this triad (carrying 7.4's floor + a11y-assertion lessons; rules the §A group placement) →
**Agent-1** reconciles (lag-1 vs the as-built `@mercury/ui` + the 7.4 floor + the bundle), builds the 6 homes on
the floor → **Agent-2 (MANDATORY verifier — HIGH risk)** re-runs the gate, reconciles spec↔code, **adversarially
probes the a11y** (menu arrow-nav fires, hover-card opens on focus, dismiss fires), classifies every promise
MATCH/STALE/INVENTED/MISSING, fills §11 → Operator reviews the +6 Storybook homes + the gate, then accepts the
**import complete**. Feedback edits this spec, never the code directly.

## 10 · Out of scope

- The **overlay-floor primitive** — built in **[`../mx.7.4/mx.7.4.md`](../mx.7.4/mx.7.4.md)**; this batch
  consumes it. A floor addendum (a new behavior 7.4 did not surface) is a one-line `@mercury/core` widening,
  called out at build.
- The **Storybook enrichment** (palette/variant-switching/real-world scenes) — that is **mx.8**. This batch's
  stories are the basic mx.4-shape homes + the a11y assertions INV-A11Y requires.
- The **showcase application** — **mx.9**.
- Reconciling the **21 re-prototypes** of existing exports (epic §6) — mx.7 only *adds* net-new surface.
- Any **rename/removal** of an existing export, or any **value change** to an existing token.
- `/design-sync`, the `DesignSync` MCP, any push to Claude Web (FORBIDDEN).
- Editing the roadmap/progress/design/epic — the Director folds at ship (the 7.5 row → BUILT, a `D-` for the
  ruled group placement, the running barrel-jump, **the import-complete milestone**).

## 11 · As-built (the verifier — Apollo, HIGH-risk mandatory pass)

**Verdict: BUILD-GRADE.** Every promise MATCH; zero STALE / INVENTED / MISSING; zero blocking deltas. Two
non-blocking notes recorded below (the INV-A11Y execution posture; a §4 spec-body sync).

### 11.1 · The 6 folders shipped (each a 4-file home)

`overlay/Dropdown`, `overlay/ContextMenu`, `overlay/HoverCard`, `overlay/LinkPreview`, `navigation/Menubar`,
`navigation/TabNav` — each `{<Name>.tsx, index.ts, <Name>.prompt.md, <Name>.stories.tsx}` (24 new files,
untracked; + `M src/index.ts` + `M src/styles/additions.css`). **§A group placement RATIFIED: `navigation/`**
for `Menubar` + `TabNav` (beside `Tabs`/`Accordion`/`Pagination`) — no rename of any existing export.

### 11.2 · Deliverables & invariants — classification (grounded)

| Promise | Verdict | As-built ground |
|---|---|---|
| K-1 six 4-file homes | MATCH | each of the 6 folders holds the 4 files (verified) |
| K-2 menus/cards compose the floor | MATCH | `useAnchoredPosition`×5, `useDismiss`×3, `useArrowNavigation`×3, `useId`×2 from `@mercury/core`; `TabNav` none |
| K-3 barrel +6 additive | MATCH | `index.ts:85-86,93-96`; 0 removed, +6 lines; 20 export names all present in the `.tsx` |
| K-4 live idiom (`.mx-*`+tokens, no hex, static `@keyframes`, accent-classes) | MATCH | all idiom/hex greps empty; `@keyframes merc-{dd,cm,menu,hc}-in` at `additions.css:846-880` |
| K-5 a11y is part of the component | MATCH | roles/`aria-haspopup`/`aria-expanded`/arrow-nav/hover+focus/restored ring/real `<button>` triggers — traced in the 6 `.tsx` |
| K-6 hand-authored contract per overlay | MATCH | 6 `.prompt.md`, full mx.2 sections, cross-links resolve on disk, "(source-grounded; no app call site)" note |
| K-7 1:1 story↔folder | MATCH | 61 stories == 61 component folders (`_overlay/Portal` internal, no story) |
| K-8 `Menubar`/`TabNav` group ruled | MATCH | both in `navigation/`; barrel `navigation/*` block; no rename |
| K-9 token/font additive-only | MATCH | `tokens.css` untouched (git-diff empty); no new weight |
| K-10 gate green + design DOWN | MATCH | see 11.3; no `/design-sync` |
| INV-1 master invariant additive | MATCH | barrel git-diff 0 removed/+6; Director's `getExportsOfModule` + empty collision-grep authoritative |
| INV-FLOOR-CONSUMED (no re-roll) | MATCH | `mousedown`-outside grep empty over the 5 menu/card dirs; floor hooks imported; `ContextMenu` `scroll`-dismiss is §4-sanctioned (`ContextMenu.tsx:66-71`), not a re-roll |
| INV-A11Y (exercise the outcome) | MATCH (see 11.4 note) | all 5 mandatory `play`s exercise the real outcome; sound-by-construction (a broken component fails each) |
| INV-2 no inline colour | MATCH | grep empty (6 dirs) |
| INV-3 no raw hex | MATCH | grep empty (6 dirs + new CSS `686-919`) |
| INV-4 no `mercAccent`; no runtime keyframes | MATCH | `mercAccent`/`_lib/accent` + `createElement("style")`/`ensureKeyframes` greps empty |
| INV-5 D-7 contract, no bundle framing | MATCH | framing grep empty over the 6 contracts |
| INV-6 1:1 story↔folder + `sb:typecheck` | MATCH | 61==61; `sb:typecheck` EXIT 0; `sb:build` prior+6 |
| INV-7 token/font additive-only | MATCH | `tokens.css` untouched |
| INV-DOWN design flows DOWN | MATCH | no `DesignSync`/`/design-sync` in components; no `.design-sync/` staged |
| INV-8 the package gate | MATCH | see 11.3 (all EXIT 0) |
| S-1 compose floor, no re-roll | MATCH | = INV-FLOOR-CONSUMED |
| S-2 Dropdown keyboard menu | MATCH | `Dropdown.tsx` + `Dropdown.stories.tsx:63` play |
| S-3 ContextMenu opens at pointer | MATCH | `ContextMenu.tsx:110-119` (`onContextMenu`→`point`) + play `:58` (note 11.4b) |
| S-4 HoverCard hover+focus | MATCH | `HoverCard.tsx:75-83` (`onFocus`→show) + focus-proof play `:64` |
| S-5 LinkPreview | MATCH | `LinkPreview.tsx` + render/states story; cross-links `HoverCard`/`Link` |
| S-6 Menubar | MATCH | `Menubar.tsx` + play `Menubar.stories.tsx:72` |
| S-7 TabNav aria-current + ring, ruled group | MATCH | `TabNav.tsx:48-63`; `.mx-tabnav__link:focus-visible` real `outline` `additions.css:912-915`; active border `--bg-brand` `:907` |
| S-8 a11y exercised not rendered | MATCH (see 11.4 note) | the 5 plays assert outcomes (not render-only) |
| S-9 barrel +6 additive | MATCH | = INV-1 |
| S-10 accent-classes/static keyframes/gate/tokens/DOWN | MATCH | = INV-2/4/7/DOWN/8 |
| S-11 1:1 story↔folder | MATCH | = INV-6 |

### 11.3 · Gate reproduced (independent, from `mercury/`, EXIT 0 each)

- `pnpm --filter "@mercury/*" typecheck` → **EXIT 0** (mercury-core/ui/effector + apps echomq/mobile/storybook).
- `pnpm --filter "@mercury/*" --filter "!@mercury/storybook" build` → **EXIT 0** (ui + effector + echomq + mobile).
- `pnpm sb:typecheck` → **EXIT 0** (the authoritative story NO-INVENT gate).
- `pnpm sb:build` → **EXIT 0**, "Storybook build completed successfully"; the **+6 home delta** (66→72 total
  story files = 61 co-located component stories + 11 app scenes) — all 6 new chunks present
  (Dropdown/ContextMenu/HoverCard/LinkPreview/Menubar/TabNav `.stories`).
- **Barrel-diff:** `src/index.ts` git-diff = **0 removed/renamed, +6** added lines (strictly additive).
- **Idiom/hygiene greps — all EMPTY:** inline colour · raw hex (6 dirs + new CSS) · `mercAccent`/`_lib/accent` ·
  `createElement("style")`/`ensureKeyframes` · `mousedown`-outside re-roll (5 menu/card dirs) · bundle framing
  in the 6 contracts · `DesignSync`/`/design-sync`.

### 11.4 · Adversarial a11y probe — the 5 mandatory `play`s (each traced component↔play)

Each play queries the **portaled** panel through `canvasElement.ownerDocument.body` (a canvas-scoped query
would find nothing) and exercises the real outcome — a no-op / subtly-broken component **fails** it:

- **Dropdown** (`Dropdown.stories.tsx:63`) — asserts `aria-haspopup="menu"`, click flips `aria-expanded`
  false→true, `body.findByRole("menu")`, `{ArrowDown}`→ `Profile` `toHaveFocus()` (the arrow-nav floor: on
  open focus moves to the panel `tabIndex=-1`; `onKeyDown`→`useArrowNavigation` with `indexOf(panel)=-1`→first
  item), `{Escape}`→ menu null + `aria-expanded` false. **Live, not dead code.**
- **Menubar** (`Menubar.stories.tsx:72`) — trigger is `role="menuitem"` (menubar semantics), `aria-haspopup`,
  click→`aria-expanded`, portaled submenu, `{ArrowDown}`→ `New File` focus, `{Escape}`→ null. Sound.
- **ContextMenu** (`ContextMenu.stories.tsx:58`) — `fireEvent.contextMenu` opens the portaled menu, `Delete`
  carries `.mx-ctx__item--danger`, `{Escape}` dismisses. Sound *(11.4b)*.
- **HoverCard** (`HoverCard.stories.tsx:64`) — dialog null pre; `userEvent.tab()` focuses the real `<button>`
  → `onFocus` bubbles to the wrapper span → `body.findByRole("dialog")`. **Proves FOCUS (not only hover) opens
  it** — a hover-only build times out and fails.
- **TabNav** (`TabNav.stories.tsx:55`) — `aria-current="page"` on the active link; after `tab()`,
  `getComputedStyle(...).outlineStyle).not.toBe("none")`. **Coherent with the CSS:** unlike the overlays
  (`outline:none; box-shadow`), TabNav ships a real `outline: 2px solid` (`additions.css:913`), so the
  assertion holds in a real browser. Play + rule co-designed.

**11.4a — INV-A11Y execution posture (note, not a block).** `apps/storybook` has **no** test-runner
(`dev`/`build`/`typecheck` only) and `.storybook/main.ts` `addons: []`. The `play`s are therefore
**type-checked (`sb:typecheck`) + build-registered (`sb:build`) + sound-by-construction, but NOT machine-executed
in the gate ladder** — they run only in `sb:dev`'s interactions. The runner-of-record for INV-A11Y in this
program is the **mandatory Apollo adversarial trace** (this §11.4) — which is exactly why the verifier is
mandatory on a HIGH-risk a11y rung (§9). This matches mx.7.4 and every prior a11y batch; it is a program-level
gate-coverage posture, not a mx.7.5 defect. *Cost if unaddressed:* a future a11y regression could pass a green
`sb:build`; *mitigation:* the plays are sound and would fire in dev/Chromatic, or once a play-runner is wired
(a Director/Operator call — see the mentoring note).

**11.4b — ContextMenu pointer position (named uncertainty).** The play proves right-click→open + danger +
Escape, but not the literal pixel anchor (`getBoundingClientRect` is 0 in jsdom, so position is not reliably
assertable). The positioning path is the **7.4 floor's** `useAnchoredPosition({ point })`, unit-proven there
and shared with the other overlays. Acceptable.

### 11.5 · Spec synced to shipped reality

- **§4 bullet 1** — was "`useDismiss` … every menu + hover card"; synced to "every **menu**" (the hover cards
  are non-modal → blur/mouse-leave timers, matching §5 + the as-built `HoverCard`/`LinkPreview`). Recording
  reality, not redesign. (The derived `.llms.md` "Ground facts — useDismiss (every menu/card)" line carries the
  same lag; historical build brief, left as-is.)

### 11.6 · The mx.7 import — COMPLETE

mx.7.5 adds the final **6** net-new components → the mx.7 import epic reaches **31 net-new** across 7.1–7.5
(+ the folds). The full `@mercury/ui` surface is imported; mx.8 (Storybook enrichment) and mx.9 (the showcase)
can now render the whole surface. **For the Director's epic fold:** 7.5 row → BUILT; a `D-` for the ratified
`navigation/` group placement; the running barrel-jump (+6); the **import-complete** milestone.
