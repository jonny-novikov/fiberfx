# mx.7.4 · Import batch 4 — the overlay-floor + the dialog family

> **Status: 📋 PLANNED — build-ready; batch 4 of the mx.7 import epic.** Inherits the epic frame
> [`../mx.7/mx.7.md`](../mx.7/mx.7.md) (the four cross-batch forks, the cadence, the shared translation
> contract). This batch builds the **overlay-floor primitive** and imports the **3 net-new blocking / anchored
> overlays** it defines and first-exercises — `Dialog · AlertDialog · Popover` — translated from the bundle's
> inline-style prototypes into `@mercury/ui`'s `.mx-*` + token idiom, additively. The floor is **built here and
> consumed by [`../mx.7.5/mx.7.5.md`](../mx.7.5/mx.7.5.md)** (the six menu / hover / nav overlays). These
> **compose mx.7.1**: an overlay title is a `Heading`, a close control is an `IconButton`.
>
> **Risk: HIGH.** The batch stands up a **new shared `@mercury/core` primitive** (portal/focus-trap/dismiss/
> anchored-position) and the focus-trap/dismiss a11y state machines, plus a public-surface (+3 ui, + the core
> floor) growth. It ships **Squad-tier: the verifier is MANDATORY** (not the optional fast-finisher of a normal
> Mercury rung) — exactly the high-risk surface the verifier gate exists for.
>
> **Inherited, not re-argued here** (epic §4/§5): translate to `.mx-*` + tokens (Cross-fork I); additive-only
> token/font policy (Cross-fork II); never rename an existing export (Cross-fork III); design flows DOWN, no
> `/design-sync` (INV-DOWN); the 4-file home + the additive barrel + the gate.
>
> **Three open calls shape this batch (Operator rules each) — they are §A, §C, §D, BEFORE §0.** §A (the
> overlay-floor ADR) gates the batch and its consumer 7.5; §C (the `Dialog`↔`Modal` collision, **reconciled to
> the real monolithic prototype**); §D (a positioning npm dep, **resolved against the evidence: no prototype
> uses one**). **§B (the 7.4|7.5 split) is RESOLVED — Operator-approved 2026-06-29** (see §B).

Canon: [`../../mercury.design.md`](../../mercury.design.md) · epic: [`../mx.7/mx.7.md`](../mx.7/mx.7.md) ·
contract template: [`../../contracts.md`](../../contracts.md) · acceptance:
[`mx.7.4.stories.md`](./mx.7.4.stories.md) · build context: [`mx.7.4.llms.md`](./mx.7.4.llms.md). Prior batch:
[`../mx.7.1/mx.7.1.md`](../mx.7.1/mx.7.1.md) (the `accent`-class translation pattern). Next batch (consumes the
floor): [`../mx.7.5/mx.7.5.md`](../mx.7.5/mx.7.5.md).

---

## A · The batch-gating open call — the overlay-floor ADR (Operator rules)

**The first decision; it shapes all overlays in 7.4 AND 7.5.** A `Dialog`, a `Popover`, a `Dropdown`, a
`Menubar` each need the same four behaviors: **portal** (escape the overflow/stacking context, mount at
`document.body`), **focus-trap + focus-return** (Tab cycles within an open blocking surface; focus returns to
the trigger on close), **dismiss** (outside-click + `Escape`), and **anchored positioning** (place the panel
relative to its trigger). Where does that floor live?

- **Rationale.** The bundle prototypes each **re-implement** dismiss/positioning inline and **none focus-trap**
  (verified: `overlay/Dialog/Dialog.tsx` listens for `Escape` only; `overlay/Popover/Popover.tsx` and
  `Dropdown` re-roll the same `mousedown`-outside + `keydown`-Escape effect). Translating nine copies of a
  half-built a11y state machine is nine drift surfaces. **`@mercury/core` already carries the building blocks**
  as `internal/` files — `focus.ts` (`FocusableTarget`), `should-enable-focus-trap.ts`,
  `use-arrow-navigation.ts` (full Arrow/Home/End menu navigation), `use-id.ts`, `dom.ts` — but its public barrel
  is **minimal by law (D-5)**: it surfaces only `cx` + the date formatters today, and the CLAUDE.md directs
  "surface explicitly only when a consumer needs it; do not widen the barrel to dump all of `internal/`." Nine
  overlays (3 here + 6 in 7.5) needing one floor IS that trigger.
- **Arms (4-part).**
  - **(a) A shared headless floor in `@mercury/core`, surfaced through the barrel [Steward].**
    *Rationale:* it is the `@mercury/core` charter — headless behavior hooks, zero JSX — and it makes the
    a11y/dismiss contract **identical** across all nine (DRY; one place to harden). *5W:* the floor (proposed
    surface — Mars confirms the exact names against the existing `internal/`): `useFocusTrap(ref, { active,
    returnFocusTo })`, `useDismiss(ref, { onDismiss, outsideClick, escapeKey })`, an anchored-position helper
    `useAnchoredPosition(...)`, the existing `useArrowNavigation` for menus, and `useId` for `aria-*` wiring —
    each **composing** the present `internal/` files, not reinventing them. *Steelman of the cost:* this
    **widens the `@mercury/core` public barrel** (a D-5-governed surface change) and `createPortal` cannot live
    in core (core is JSX-free + `react`-peer-only, no `react-dom`), so a thin presentational `<Portal>` /
    overlay-content wrapper still lands in `@mercury/ui`. *Steward:* the widening is exactly the D-5 "surface
    when a consumer needs it" path; the split (behavior in core, `createPortal` in ui) is clean.
  - **(b) A per-overlay floor — each component inlines its own portal/trap/dismiss.** *Rationale:* maximal
    isolation; no `@mercury/core` barrel change. *Cost:* the bundle's exact duplication, carried forward; nine
    copies to harden and keep in sync; the a11y bar (focus-trap) likely under-met per the prototype.
  - **(c) A shared floor that lives in `@mercury/ui` (an overlay-internal `_overlay/` module), not core.**
    *Rationale:* DRY without touching core's barrel. *Cost:* behavior hooks in a UI library invert the layering
    the `@mercury/core` charter draws (headless behavior belongs below the components); the core `internal/`
    helpers would be imported up into ui anyway.
  - **(d) Adopt a third-party floor (Radix / Floating-UI primitives).** *Rationale:* battle-tested a11y. *Cost:*
    a new npm dependency against `@mercury/ui`'s no-extra-npm posture (epic Cross-fork I; §D) — the largest
    surface change, and the prototypes prove a hand-roll suffices.
- **Steward / recommendation: (a)** — a shared headless floor in `@mercury/core` (behavior), with the thin
  `<Portal>` in `@mercury/ui`. It is the package's charter, it makes the a11y contract one artifact, core
  already holds the parts, **and nine overlays across two batches now consume it — the DRY case is doubled.**
  **Operator rules** (a public-surface posture call on `@mercury/core`'s D-5 barrel).
- **This spec is authored under arm (a)** (§4 details the floor; §6 K-1 + §8 INV-FLOOR/INV-A11Y assume it).
  **If the Operator rules (b)/(c)/(d), only the floor's *home* moves** — the a11y acceptance is written
  behavior-first and is unchanged; the build re-homes the four behaviors without re-deriving them. **mx.7.5
  consumes whatever home is ruled.**

## B · The 7.4 | 7.5 split — RESOLVED (Operator-approved 2026-06-29)

The epic flagged the original 9-overlay batch at ≈10–12 units (~2× the ~4–6 band) and recommended a split. **The
Operator approved it.** This batch (mx.7.4) is the floor + the dialog family; the six menu / hover / nav
overlays are [`../mx.7.5/mx.7.5.md`](../mx.7.5/mx.7.5.md). The ruled boundary:

| Batch | Components | Why this cut |
|---|---|---|
| **mx.7.4** (this) | the **overlay-floor primitive** + `Dialog` · `AlertDialog` · `Popover` | The floor + the three pure *blocking / single-anchored-panel* surfaces that **define and first-exercise** it — `Dialog`/`AlertDialog` prove focus-trap + focus-return (modal); `Popover` proves anchored, non-modal dismiss. ~5–6 units. All land in `overlay/`. |
| **mx.7.5** | `Dropdown` · `ContextMenu` · `HoverCard` · `LinkPreview` · `Menubar` · `TabNav` | The six *menu / hover / nav* surfaces that **compose the proven floor** and add family-specific machinery (`useArrowNavigation` + `aria-haspopup`/`aria-expanded`; hover/focus open-delays; link-nav with `aria-current`). ~5–6 units. |

The floor proven by the dialog family here is the contract 7.5's menus compose; the `accent`-class +
a11y-assertion patterns carry forward into 7.5's brief.

## C · The `Dialog` ↔ `Modal` collision — reconciled to the real prototype (Operator rules; epic Cross-fork III)

> **[RECONCILE — NO-INVENT correction.]** The upstream framing described `Dialog` as a **Radix-style
> composable-parts** API (`Dialog.Root/Trigger/Content/Title/Description/Close`). **The bundle ships no such
> thing.** Verified in `overlay/Dialog/Dialog.tsx`: `Dialog` is **monolithic / prop-driven** — `open` ·
> `onClose?` · `title?` · `description?` · `children?` · `footer?` · `size?: "sm"|"md"|"lg"` · `showClose?`. It
> is essentially the **live `Modal` + `description` + `showClose`** (live `Modal`: `open · onClose? · title? ·
> footer? · size? · children?`, `overlay/Modal/Modal.tsx`). The arms below are framed against that real shape.

- **Arms.**
  - **(a) Add `Dialog` net-new (monolithic), keep `Modal` [Steward].** Both export; `Dialog` carries the
    Claude-Design name + the `description`/`showClose` capability; it composes the **same overlay-floor** and
    reuses the `.mx-modal`-class styling family, so it is a thin component, not a re-implementation. The two
    contracts cross-link (`Dialog` "a richer Modal with a description slot"; `Modal` ↔ `Dialog`).
  - **(b) Alias `export { Modal as Dialog }`.** One implementation, two names — but `Dialog` then **lacks** the
    bundle's `description`/`showClose`, losing documented capability.
  - **(c) Fold `description`/`showClose` into `Modal` (additive optional props), then add `Dialog`.** Most-DRY:
    one dialog implementation; `Dialog` becomes the parity-named surface (alias or thin wrapper) over the
    enriched `Modal`. Additive-legal (optional props don't break `Modal`'s surface; renaming `Modal` stays
    forbidden).
- **Steward / recommendation: (a)** — add `Dialog` net-new (honoring the Claude-Design name + its API), sharing
  the floor + the `.mx-modal` style family so duplication is minimal; **(c)** is the DRY-purist alternative if
  the Operator prefers a single dialog implementation. Either way **`Modal` is never renamed** (master
  invariant). **Operator rules** (parity-naming vs single-implementation).

## D · The positioning-dependency open call — hand-roll vs adopt (Operator rules)

- **Rationale (evidence-backed).** Every overlay prototype **hand-rolls placement** with CSS absolute/fixed
  positioning + a `placement` enum — verified across both batches' prototypes: `Popover`
  (`bottom-start|bottom-end|top-start|top-end`), `HoverCard` (`top|bottom|left|right`), `Dropdown`/`Menubar`
  (`align: start|end`), `ContextMenu` (pointer-anchored `position: fixed` clamped to the viewport). **None
  imports a positioning library.** `@mercury/ui`'s posture is no-extra-npm (epic Cross-fork I).
- **Arms.** **(a) Hand-roll a minimal anchored-position helper in the overlay-floor [Steward]** — port the
  prototypes' enum placement into `useAnchoredPosition`; zero new dependency; serves both batches. **(b) Adopt
  `@floating-ui/react`** — flip/shift/collision-aware positioning for free, at the cost of a runtime npm dep +
  the bundle-size and the layering question. **(c) Adopt Radix overlays wholesale** — solves §A+§D together but
  is the largest surface change (see §A arm (d)).
- **Steward / recommendation: (a)** — hand-roll; the prototypes prove it suffices for the enum placements the
  bundle ships. Adopt only if the Operator wants collision-aware auto-flip (a capability the prototypes do not
  have). **Operator rules** (a new-dependency call — epic discipline: a new dep is the Operator's, never the
  agent's).

## 0 · The slice

The fourth import batch: the overlay-floor + the surfaces that **float, trap, and anchor**. Three blocking /
anchored-panel surfaces — `Dialog` and `AlertDialog` (modal, focus-trapping) and `Popover` (anchored,
non-modal) — all built on **one overlay-floor** (§A) that this batch stands up. Each is translated into the
live `.mx-*` + token idiom, hardened to the canon's a11y bar (focus-trap/return, `Escape`/outside-click
dismiss, `aria-*`), and exported additively. This batch composes mx.7.1 (`Heading` titles · `IconButton`
closes) and **publishes the floor that mx.7.5's six menu/hover/nav overlays consume**, and that mx.8 (stories)
and mx.9 (the showcase) exercise.

## 1 · Goal

After mx.7.4, `@mercury/ui` exports **3 new components** — `Dialog · AlertDialog · Popover` (+ their `Props`
and enum types) — each a translated 4-file home (`.mx-*` + tokens · hand-authored contract · CSF3 story), and
the **shared overlay-floor** (per §A) centralizing portal + focus-trap + focus-return + dismiss + anchored
positioning is published for mx.7.5 to consume. The barrel is **strictly additive** (`Modal`/`Tooltip` and
every prior export byte-preserved; +3 names + their types). The full package gate is green (incl. `@mercury/core`
— the floor); `sb:build` registers the prior homes + 3; the barrel-diff shows 0 removed/renamed. **Design
flowed DOWN only** (no `/design-sync`).

## 2 · Rationale (5W)

- **Why.** The dialog family is where "a11y is part of the component" (canon §8) is load-bearing: a blocking
  dialog that does not trap focus or return it is a defect, not a style miss. Building it on one floor — proven
  here by the simplest blocking + anchored surfaces — makes that bar provable once and gives mx.7.5's menus a
  hardened contract to compose.
- **What.** The overlay-floor primitive (§4), the 3 translated 4-file homes, the `@mercury/ui` barrel grown +3,
  the `.mx-*` overlay rules in `src/styles/additions.css` (incl. static `@keyframes` replacing the prototypes'
  runtime style injection), and — if §A=shared — the one-line `@mercury/core` barrel widening for the floor.
- **Who.** *Authored by* the architect (this triad) + the batch's build/verify agents (epic §2 cadence,
  Squad-tier — verifier mandatory). *Consumed by* mx.7.5 (the floor), mx.8 (the stories), mx.9 (the showcase),
  and the workspace apps.
- **When.** Batch 4 — after 7.1/7.2/7.3, with the Operator in the loop before it and between 7.4 and 7.5.
- **Where.** `packages/mercury-ui/src/` (the 3 folders + the `<Portal>` + barrel + `additions.css`) **and**
  `packages/mercury-core/src/` (the overlay-floor hooks + the one-line barrel widening, **if §A=shared**) +
  `docs/mercury/specs/mx.7.4/`. The bundle `packages/mercury-ds/` is read-only. Everything else in the `jonnify`
  root is out of bounds (the Mercury island).

## 3 · The component set (grounded — bundle prop surface verified in source)

Every prop below is verified in the cited bundle `.tsx`. **NO-INVENT:** no prop, type, or default is asserted
that the source does not show.

| Component | Bundle source | Verified prototype prop surface (the seed) | Live target group |
|---|---|---|---|
| `Dialog` | `overlay/Dialog/Dialog.tsx` | `open` · `onClose?` · `title?: ReactNode` · `description?: ReactNode` · `children?` · `footer?: ReactNode` · `size?: "sm"\|"md"\|"lg"` · `showClose?` (monolithic — §C) | `overlay` (beside `Modal`) |
| `AlertDialog` | `overlay/AlertDialog/AlertDialog.tsx` | `open` · `title?` · `description?` · `children?` · `confirmLabel?="Confirm"` · `cancelLabel?="Cancel"` · `destructive?` · `onConfirm?` · `onCancel?` | `overlay` |
| `Popover` | `overlay/Popover/Popover.tsx` | `trigger: ReactNode` · `children?` · `open?` · `defaultOpen?=false` · `onOpenChange?` · `placement?: "bottom-start"\|"bottom-end"\|"top-start"\|"top-end"` · `width?=280` (controlled + uncontrolled) | `overlay` |

## 4 · The overlay-floor primitive (authored under §A arm (a); the build target — published for mx.7.5)

The floor centralizes the four behaviors the prototypes each half-build. **Behavior lives in `@mercury/core`
(headless, JSX-free), `createPortal` lives in `@mercury/ui`** (core has `react` peer only, no `react-dom`).
This batch builds the **whole** floor (not just the parts the 3 dialogs use) so mx.7.5's menus consume a
complete, hardened contract.

- **`useFocusTrap(ref, { active, returnFocusTo })`** — while `active`, `Tab`/`Shift+Tab` cycle within `ref`'s
  focusable descendants; on deactivate, focus returns to `returnFocusTo` (the trigger). Composes the existing
  `internal/focus.ts` (`FocusableTarget`) + `internal/should-enable-focus-trap.ts` + `internal/dom.ts`. Used by
  the **blocking** surfaces (`Dialog`, `AlertDialog`) and on-open by `Popover`.
- **`useDismiss(ref, { onDismiss, outsideClick, escapeKey })`** — the one true outside-`mousedown` + `Escape`
  effect, replacing the inline copies (3 here, 6 in 7.5). `AlertDialog` opts **out** of `outsideClick` (it
  demands an explicit choice — the prototype deliberately omits backdrop dismiss).
- **`useAnchoredPosition(anchorRef, floatRef, { placement, align, width })`** — ports the prototypes' enum
  placement (the `top/bottom × start/end`, `top/bottom/left/right`, and pointer-`fixed` cases) into one helper.
  Hand-rolled (§D); **no positioning npm dep.** `Popover` exercises it here; the menus/hover-cards exercise the
  remaining cases in 7.5.
- **`useArrowNavigation`** — already public-ready in `internal/use-arrow-navigation.ts`; **not used by the 3
  dialogs**, but published by the floor for mx.7.5's menus (`Dropdown`/`ContextMenu`/`Menubar`).
- **`useId`** — `internal/use-id.ts`, for stable `aria-labelledby`/`aria-describedby`/`aria-controls` wiring.
- **`<Portal>`** (in `@mercury/ui`, e.g. `overlay/_overlay/Portal.tsx`) — a thin `createPortal(children,
  document.body)` wrapper, SSR-guarded (`typeof document !== "undefined"`), used by the blocking surfaces and
  the floating panels that must escape an overflow/stacking context.

**The barrel impact (two barrels):** the **`@mercury/ui`** barrel grows +3 (the master invariant — §8 INV-1).
The **`@mercury/core`** barrel grows by the floor hooks (a D-5-governed widening — surfaced because nine
consumers across 7.4+7.5 need it; the `<Portal>` is internal to ui, not a core export). If §A resolves to
(b)/(c), the core barrel is untouched and the four behaviors inline per-overlay / in a ui-internal module; the
a11y acceptance is unchanged, and mx.7.5 consumes whatever home is ruled.

## 5 · Translation notes (the deltas beyond the epic's shared idiom)

- **a11y is the component (canon §8) — the hardening per family, beyond what the prototype ships:**
  - **Blocking (`Dialog`, `AlertDialog`):** `role="dialog"`/`role="alertdialog"` + `aria-modal="true"`,
    `aria-labelledby`/`aria-describedby` wired (via `useId`) to the title/description, **focus-trap +
    focus-return** (the prototypes do NOT trap — this is added), initial focus (`AlertDialog` → the confirm
    action, per the prototype's `confirmWrap` focus), `Escape` dismiss. `Dialog` dismisses on backdrop;
    `AlertDialog` does **not** (explicit choice).
  - **Anchored panel (`Popover`):** `role="dialog"`, `aria-haspopup="dialog"` + `aria-expanded` on the trigger,
    focus moves into the panel on open + returns on close, outside-click + `Escape` dismiss.
- **`@keyframes` in CSS, not injected at runtime.** The dialog/popover prototypes call `ensureKeyframes()` —
  `document.createElement("style")` appended to `<head>` (`merc-dialog-fade`, `merc-pop-in`). Translate to
  **static `@keyframes` blocks in `additions.css`**; the `.mx-*` rules reference them. No runtime style
  injection (it is the inline-idiom equivalent the live layer forbids).
- **Portal the blocking surfaces.** The prototypes render inline in the React tree; the live `Modal`
  `createPortal`s to `document.body`. Translate `Dialog`/`AlertDialog` (and `Popover` where an overflow/stacking
  context would clip) through the floor's `<Portal>`.
- **React-19 nullable `useRef().current`.** Guard `ref.current` reads (the idiom `Checkbox`/`Accordion` use).
- **Compose mx.7.1.** The title is a `Heading`, the close is an `IconButton` (`label="Close"` → `aria-label`) —
  cross-link these in the contracts.

## 6 · Deliverables

- **K-1 — the overlay-floor primitive** (per §A): `useFocusTrap` + `useDismiss` + `useAnchoredPosition` (+ the
  reused `useArrowNavigation`/`useId`) composing core's existing `internal/` helpers, surfaced per the ruled
  arm; the `<Portal>` wrapper in `@mercury/ui`. One a11y/dismiss contract, **published for mx.7.5**.
- **K-2 — 3 translated 4-file homes** under `packages/mercury-ui/src/components/overlay/{Dialog,AlertDialog,
  Popover}/` (`<Name>.tsx` translated · `index.ts` · `<Name>.prompt.md` hand-authored · `<Name>.stories.tsx`
  CSF3).
- **K-3 — the `@mercury/ui` barrel grows +3 additively** (`Dialog`/`DialogProps`/`DialogSize`, `AlertDialog`/
  `AlertDialogProps`, `Popover`/`PopoverProps`/`PopoverPlacement`); **`Modal`/`Tooltip` and every prior export
  byte-preserved**; barrel-diff 0 removed/renamed.
- **K-4 — the live idiom** (Cross-fork I): `.mx-*` classes + tokens; no inline colour literal; no raw hex;
  static `@keyframes` (no runtime injection).
- **K-5 — a11y is part of the component** (canon §8): the per-family hardening of §5 realized — `role`/`aria-*`,
  focus-trap + focus-return (blocking), anchored dismiss (`Popover`).
- **K-6 — a hand-authored contract per overlay** (D-7; 3): mx.2 format, no bundle runtime framing, cross-links
  (`Dialog`↔`Modal`; `AlertDialog`↔`Dialog`+`Button`; the close↔`IconButton`). Each says "(source-grounded; no
  app call site)" — these are net-new.
- **K-7 — the 1:1 story↔folder invariant holds** (mx.4): each folder one co-located story; `sb:typecheck`
  clean; `sb:build` prior + 3.
- **K-8 — the `Dialog`↔`Modal` collision is ruled, no rename** (§C): `Modal` untouched (or additively enriched
  under arm (c)); `Dialog` per the Operator's arm.
- **K-9 — the token/font reconcile is additive-only** (Cross-fork II): a `tokens.css`/font edit is a new line
  only, never a value change. (No new weight is anticipated for this batch.)
- **K-10 — the gate is green** (§8) and **design flowed DOWN only** (no `/design-sync`/`DesignSync`).

**Coverage:** K-1 → S-1, S-7 ; K-2 → S-2..S-4 ; K-3 → S-5 ; K-4 → S-2..S-4, S-8 ; K-5 → S-7 ; K-6 →
S-2..S-4 ; K-7 → S-6 ; K-8 → S-2, S-5 ; K-9 → S-8 ; K-10 → S-8.

## 7 · The per-component translation map (grounded)

- **Dialog** (`overlay/Dialog` → `overlay/Dialog`). Monolithic; composes the floor (`<Portal>` + `useFocusTrap`
  + `useDismiss{outsideClick,escapeKey}`) + mx.7.1 (`Heading` title, `IconButton` close when `showClose`).
  `.mx-dialog` reusing the `.mx-modal` style family; `size` → `--<width>`; `description` slot; `aria-modal`,
  `aria-labelledby`/`describedby`. Cross-link `Modal`.
- **AlertDialog** (`overlay/AlertDialog` → `overlay/AlertDialog`). `role="alertdialog"`; floor minus
  `outsideClick`; initial focus → confirm; `destructive` → the confirm `Button variant="destructive"`. Composes
  `Button` + `Heading`. `.mx-alert-dialog`. Cross-link `Dialog`+`Button`.
- **Popover** (`overlay/Popover` → `overlay/Popover`). Controlled+uncontrolled (`open`/`defaultOpen`/
  `onOpenChange`); `useAnchoredPosition(placement)`; `useDismiss`; focus in/out. `.mx-popover` reading
  `--bg-elevated`/`--shadow-300`. `aria-haspopup="dialog"`/`aria-expanded` on the real `<button>` trigger.

## 8 · Invariants — as runnable gates (run from `mercury/`)

- **INV-1 — master invariant, additive (`@mercury/ui`).** Resolved export set after = superset of before;
  **0 removed/renamed**, +3 (+ their `Props`/enum types). `Modal`/`Tooltip` byte-present. (TS
  `getExportsOfModule`, not a text-diff.)
- **INV-FLOOR — the floor is shared + composes the existing core helpers (if §A=a).** The four behaviors live
  in one place; `grep -rn "addEventListener(\"mousedown\"\|addEventListener('mousedown'" packages/mercury-ui/src/components/overlay` shows the inline outside-click effect is **not** copied per-overlay (it routes through
  `useDismiss`). The floor hooks import from `internal/{focus,should-enable-focus-trap,use-arrow-navigation,
  use-id,dom}` (reuse, not reinvent). `@mercury/core` barrel widened by the floor hooks only (not all of
  `internal/`).
- **INV-A11Y — the a11y gate exercises its own outcome (a no-op must not satisfy it).** The story-level checks
  must **prove the behavior fires**, never render-and-pass: a `Dialog` story asserts `role="dialog"` +
  `aria-modal="true"`, that `Tab` from the last focusable wraps to the first (trap **fires**), and that on
  close focus **returns** to the trigger; an `AlertDialog` story asserts a backdrop click does **not** dismiss
  while `Escape` does; a `Popover` story asserts `aria-expanded` toggles and outside-click dismisses. A
  render-only story that touches none of these does not satisfy INV-A11Y.
- **INV-2 — live idiom, no inline colour leak.**
  `grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})" packages/mercury-ui/src/components/overlay/{Dialog,AlertDialog,Popover}`
  → **empty**.
- **INV-3 — no raw hex.** `grep -rnE "#[0-9a-fA-F]{3,8}\b"` over the 3 new dirs + the new `additions.css` rules
  → **empty**.
- **INV-4 — no runtime `@keyframes` injection.**
  `grep -rn "createElement(\"style\")\|ensureKeyframes" packages/mercury-ui/src/components/overlay/{Dialog,AlertDialog,Popover}` → **empty** (`@keyframes` are static in CSS).
- **INV-5 — D-7 contract, no bundle framing.** Each new `.prompt.md` has the mx.2 sections;
  `grep -rniE "check_design_system|pixel-perfect|/design-sync|showcase/|window\.Mercury|_ds_bundle" <new contracts>`
  → **empty**.
- **INV-6 — 1:1 story↔folder + `sb:typecheck` clean.** `count(*.stories.tsx) == count(component folders)`;
  `pnpm sb:typecheck` exits 0 (the authoritative story NO-INVENT gate); `pnpm sb:build` registers prior + 3.
- **INV-7 — token/font additive-only.** `git diff …/styles/tokens.css` shows added lines only (no changed
  value); no new weight expected this batch.
- **INV-DOWN — design flows DOWN.** No `/design-sync`/`DesignSync` in the work; `git diff` touches no
  `mercury/.design-sync/` path; nothing pushes up.
- **INV-8 — the package gate.** `pnpm --filter "./packages/*" typecheck`/`build` = 0 (incl. `@mercury/core` —
  the floor) · `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` = 0 (`echomq`+`mobile`) ·
  `pnpm sb:build` = 0.

## 9 · The batch loop (epic §2) — Operator → Agent-1 → Agent-2 → Operator (Squad-tier)

Operator sharpens this triad (and rules §A, §C, §D) → **Agent-1** reconciles (lag-1 vs the as-built
`@mercury/ui` + `@mercury/core` + the bundle), builds the floor + the 3 homes → **Agent-2 (MANDATORY verifier —
HIGH risk)** re-runs the gate, reconciles spec↔code, **adversarially probes the a11y floor** (proves the
trap/return/dismiss fire, not just render), classifies every promise MATCH/STALE/INVENTED/MISSING, fills §11 →
Operator reviews the +3 Storybook homes + the gate, then **carries the floor's API + the `accent`-class +
a11y-assertion patterns into mx.7.5's brief** and releases batch 5. Feedback edits this spec, never the code
directly.

## 10 · Out of scope

- The **six menu / hover / nav overlays** (`Dropdown`, `ContextMenu`, `HoverCard`, `LinkPreview`, `Menubar`,
  `TabNav`) — those are **[`../mx.7.5/mx.7.5.md`](../mx.7.5/mx.7.5.md)**, which consumes this batch's floor.
- The **Storybook enrichment** (palette/variant-switching/real-world scenes) — that is **mx.8**. This batch's
  stories are the basic mx.4-shape homes + the a11y assertions INV-A11Y requires.
- The **showcase application** — **mx.9**.
- Reconciling the **21 re-prototypes** of existing exports (epic §6) — mx.7 only *adds* net-new surface.
- Any **rename/removal** of an existing export (`Modal`/`Tooltip` included), or any **value change** to an
  existing token.
- Collision-aware auto-flip positioning (a `@floating-ui` capability) — only if the Operator rules §D arm (b).
- `/design-sync`, the `DesignSync` MCP, any push to Claude Web (FORBIDDEN).
- Editing the roadmap/progress/design/epic — the Director folds at ship (the 7.4 row → BUILT, a `D-` per ruled
  §A/§C/§D call, the running barrel-jump).

## 11 · As-built (the verifier — filled post-build)

> Classify K-1..K-10 / INV-1..INV-8 + INV-FLOOR/INV-A11Y/INV-DOWN / S-1..S-8 MATCH/STALE/INVENTED/MISSING;
> record the ratified §A (floor home), §C (Dialog arm), §D (positioning) arms; list the 3 folders + the floor
> files shipped; reproduce the gate (EXIT 0) incl. the barrel-diff (0 removed/renamed, +3), the `sb:build` +3
> home delta, and the idiom/hex/keyframe/framing/no-design-sync greps (empty); **reproduce the INV-A11Y proofs**
> (trap fires, focus returns, dismiss/no-dismiss). Carry forward to mx.7.5 the floor's API + the `accent`-class
> + a11y-assertion patterns.
