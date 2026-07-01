# mx.7.4 · acceptance stories

Given/When/Then for [`mx.7.4.md`](./mx.7.4.md). Connextra form; each names the deliverable + the invariant(s)
it proves. **Coverage:** K-1 → S-1, S-7 ; K-2 → S-2..S-4 ; K-3 → S-5 ; K-4 → S-2..S-4, S-8 ; K-5 → S-7 ; K-6 →
S-2..S-4 ; K-7 → S-6 ; K-8 → S-2, S-5 ; K-9 → S-8 ; K-10 → S-8 ; **K-11 → S-9 ; K-12 → S-10**.

## S-1 · The overlay-floor is one shared primitive, published for 7.5 (K-1)
*As an **overlay author**, I want portal + focus-trap + focus-return + dismiss + anchored-positioning as one
floor, so that every overlay's a11y/dismiss contract is identical, hardened in one place, and reusable by the
menu/nav batch.*
**Given** the as-built `@mercury/core` carries `internal/{focus, should-enable-focus-trap, use-arrow-navigation,
use-id, dom}` and the bundle re-rolls dismiss inline across nine files, **when** the floor lands (per §A arm (a))
as `useFocusTrap`/`useDismiss`/`useAnchoredPosition` (+ the reused `useArrowNavigation`/`useId`) **composing**
those existing helpers, plus a `<Portal>` in `@mercury/ui`, **then** no overlay re-implements the outside-click
effect (it routes through `useDismiss`), the `@mercury/core` barrel is widened by the floor hooks **only** (not
all of `internal/`), and the whole floor — including `useArrowNavigation`, unused by the 3 dialogs — is
**published for mx.7.5's menus** to consume. *(Proves INV-FLOOR.)* *(If §A=b/c, the floor's home moves; this
behavior contract is unchanged.)*

## S-2 · Dialog lands net-new without renaming Modal (K-2, K-4, K-6, K-8)
*As a **product author**, I want a `Dialog` with the Claude-Design name + a `description` slot, so that I have a
richer modal — **without losing `Modal`**.*
**Given** the live barrel exports `Modal` (`open · onClose? · title? · footer? · size? · children?`), **when**
mx.7.4 adds `Dialog` (the monolithic `open · onClose? · title? · description? · children? · footer? · size? ·
showClose?` — §C) per the Operator's arm, **then** `Modal` is **unedited and still exported** (no rename —
master invariant), `Dialog` exports additively, composes the floor + the `.mx-modal` style family + mx.7.1
(`Heading` title, `IconButton` close), styles via `.mx-dialog` (no inline colour, no raw hex), and its contract
cross-links `Modal`. *(Proves INV-1 + INV-2 + the §C ruling.)*

## S-3 · AlertDialog is the explicit-choice confirmation (K-2, K-5, K-6)
*As a **destructive-action author**, I want an `AlertDialog` that demands a choice, so that a dangerous action
cannot be dismissed by a stray backdrop click.*
**Given** `overlay/AlertDialog/`, **when** `<AlertDialog open title="Delete?" destructive confirmLabel="Delete"
onConfirm onCancel>` renders, **then** it emits `role="alertdialog"` + `aria-modal`, composes `Button` (the
`destructive` confirm) + `Heading`, takes **initial focus on the confirm action**, dismisses on `Escape` but
**not** on backdrop click, and its contract cross-links `Dialog`+`Button`. *(Proves INV-2 + INV-5 + INV-A11Y.)*

## S-4 · Popover is the anchored interactive panel (K-2, K-4, K-5)
*As a **toolbar author**, I want a `Popover` anchored to a trigger holding arbitrary interactive content, so
that controls can live in a dismissible floating panel.*
**Given** `overlay/Popover/`, **when** `<Popover trigger={…} placement="bottom-end">…</Popover>` opens, **then**
it supports controlled + uncontrolled (`open`/`defaultOpen`/`onOpenChange`), positions via
`useAnchoredPosition(placement)` (hand-rolled — no positioning dep), the trigger is a real `<button>` carrying
`aria-haspopup="dialog"`/`aria-expanded`, focus moves into the panel and returns on close, and outside-click +
`Escape` dismiss. *(Proves INV-2 + INV-A11Y + the §D ruling.)*

## S-5 · The barrel grows +3 additively (K-3)
*As a **downstream consumer**, I want every prior export preserved, so that nothing I import breaks.*
**Given** the `@mercury/ui` barrel before/after, **when** the resolved export set is compared (TS
`getExportsOfModule`, not a text-diff), **then** it is a **superset** — 0 removed, 0 renamed — with exactly the
3 new component names + their `Props`/enum types added (`Dialog`/`DialogProps`/`DialogSize`,
`AlertDialog`/`AlertDialogProps`, `Popover`/`PopoverProps`/`PopoverPlacement`), and `Modal`/`Tooltip`
byte-present. *(Proves INV-1.)*

## S-6 · The 1:1 story↔folder invariant holds (K-7)
*As a **Storybook maintainer**, I want each new component to carry exactly one co-located story, so that the
mx.4 invariant stays intact.*
**Given** the 3 new folders, **when** `pnpm sb:typecheck` + `pnpm sb:build` run, **then** `sb:typecheck` exits 0
(the NO-INVENT story gate — a wrong prop/symbol fails here), `count(*.stories.tsx) == count(component folders)`,
and `sb:build` registers exactly the prior homes + 3. *(Proves INV-6.)*

## S-7 · The a11y floor is exercised, not merely rendered (K-1, K-5) — the liveness-bearing gate
*As an **accessibility owner**, I want each overlay's a11y behavior **proven by an assertion that runs it**, so
that a render-only story cannot pass while proving nothing.*
**Given** the translated dialogs + their stories, **when** the a11y checks run, **then** each **exercises its
own outcome**: a `Dialog` story asserts `role="dialog"`+`aria-modal`, that `Tab` from the **last** focusable
**wraps to the first** (the trap **fires**), and that on close focus **returns to the trigger**; an
`AlertDialog` story asserts a backdrop click does **not** dismiss while `Escape` does; a `Popover` story asserts
`aria-expanded` toggles and outside-click dismisses. A present precondition runs the assertion with a **positive
proof**; a story that touches none of these does **not** satisfy this gate. *(Proves INV-A11Y — a check counts
only if it RUNS.)*

## S-8 · The gate is green; keyframes static; tokens additive-only; design flowed DOWN (K-4, K-9, K-10)
*As a **Director**, I want the full package gate green, animations as static CSS, no token value changed, and no
design push, so that the batch ships clean.*
**Given** the floor + the 3 translated dialogs, **when** the gate runs — `pnpm --filter "./packages/*"
typecheck`/`build` (incl. `@mercury/core`) · `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` ·
`pnpm sb:typecheck` · `pnpm sb:build` — **then** every command exits 0, the barrel-diff is 0 removed/renamed,
the animations are **static `@keyframes` in `additions.css`** (no `document.createElement("style")`/
`ensureKeyframes` in any component), any `tokens.css` change is an **added** line only (no changed value), the
idiom/hex/framing greps are empty, and **no** `/design-sync`/`DesignSync` invocation occurred. *(Proves INV-2 +
INV-4 + INV-7 + INV-DOWN + INV-8.)*

## S-9 · The Effector disclosure bridge drives the overlays from outside (K-11) — commit #1
*As a **product author**, I want an Effector adapter that produces an overlay's open/close state and locks body
scroll while any overlay is open, so that I can drive `Dialog`/`Popover` from my app's state — without the
overlays holding application state.*
**Given** the presentational overlays (`open`/`onOpenChange`/`onClose`) and the 7-module `@mercury/effector`
barrel, **when** `disclosure.ts` lands as `createDisclosure()` (the `createCooldown` factory idiom → `{ $open,
open, close, toggle, useOpen }`) **plus** a global overlay-stack + body-scroll-lock singleton (`$openOverlays`
LIFO, `$anyOverlayOpen`, an idempotent `initOverlayLock()` that padding-compensates + releases on the last
close), **then** the `@mercury/effector` barrel grows **additively** (7 → 8 `export *`, prior byte-present),
`@mercury/ui`'s `package.json` gains **no** `@mercury/effector` dep (the arrow is effector → ui), the overlays'
prop surface is **unchanged**, and `apps/storybook/stories/effector/Overlay.stories.tsx` (`Effector/Overlay`)
wires `createDisclosure` + the scroll-lock model to a real `Dialog` + `Popover`, registered by `pnpm sb:build`.
*(Proves INV-EFFECTOR — the bridge is proven **live**; a story that renders neither does not satisfy it.)*

## S-10 · The showcase foundation is a from-source app that composes, never houses (K-12) — commit #2
*As a **developer learning Mercury**, I want a showcase app whose shell and first demo run against the live
`@mercury/*` source, so that the Developer Reference has a real, theme-toggling home to grow into.*
**Given** no `apps/showcase/` exists and `pnpm-workspace.yaml` already globs `apps/*`, **when** the foundation
lands as a new `mercury/apps/showcase/` (mirroring `apps/mobile`'s vite alias + tsconfig `paths` + package shape)
with the translated shell (sidebar + topbar + the `@mercury/effector` **theme toggle**) and the new overlays as
the first live demo driven by the §E disclosure adapter, **then** `pnpm --filter @mercury/showcase build` exits 0
resolving `@mercury/*` **from source**, the app imports only from `@mercury/{ui,effector,core}` + React and
defines **no** reusable component app-side (canon §7 `D-8` — composes, never houses), it adds **nothing** to the
`@mercury/ui` barrel, and **no** `pnpm-workspace.yaml` edit was needed. *(Proves INV-SHOWCASE + the §F
theme-adapter composition; this is commit #2 — commit #1 is K-1..K-11, gate-green.)*
