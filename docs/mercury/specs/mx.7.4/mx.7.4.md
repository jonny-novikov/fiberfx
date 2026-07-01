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
> **The four batch-shaping calls are now RULED (Operator, 2026-07-01) — §A, §C, §D, BEFORE §0; §B earlier.**
> §A (the overlay-floor ADR) → **arm (a): a shared headless floor in `@mercury/core`**; §C (the `Dialog`↔`Modal`
> collision) → **arm (a): add `Dialog` net-new, keep `Modal`**; §D (positioning) → **hand-roll
> `useAnchoredPosition`, no npm dep**. **§B (the 7.4|7.5 split) is RESOLVED — Operator-approved 2026-06-29**. The
> arm analyses stay below as the record; each carries its RULED line.
>
> **Two NET-NEW scope axes were added (Operator, 2026-07-01) — §E and §F.** §E (the **strong Effector bridge**:
> a `createDisclosure()` adapter + a global overlay-stack / body-scroll-lock model — the overlays' optional
> driver, `@mercury/ui` untouched). §F (**deliverable-2, a separate commit**: the **showcase foundation** — a new
> `mercury/apps/showcase/` app shell + the new overlays as its first live demo; the full per-component Reference
> stays mx.9). The rung now ships **two sequenced commits**: #1 the packages (K-1..K-11), #2 the showcase (K-12).

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
- **RULED (Operator, 2026-07-01): arm (a) — a shared headless floor in `@mercury/core`.** The behavior hooks
  (`useFocusTrap` · `useDismiss` · `useAnchoredPosition`, + the reused `useArrowNavigation` · `useId`) compose the
  existing `internal/` helpers (verified present: `focus.ts`, `should-enable-focus-trap.ts`,
  `use-arrow-navigation.ts`, `use-id.ts`, `dom.ts`, plus `attrs.ts`/`elements.ts`/`get-directional-keys.ts`/
  `kbd.ts`) and surface through the D-5 barrel (the `useDateField`/`useCalendar` pattern); the `<Portal>` wrapper
  lives in `@mercury/ui` (`overlay/_overlay/Portal.tsx`). **Build the WHOLE floor** — incl. the cases mx.7.5 needs
  — so 7.5 consumes a complete contract. §4/§6 K-1/§8 INV-FLOOR are authored to this arm.
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
- **RULED (Operator, 2026-07-01): arm (a) — add `Dialog` net-new, keep `Modal`.** `Dialog` is **monolithic**
  (`open · onClose? · title? · description? · children? · footer? · size?: sm|md|lg · showClose?`), carries the
  Claude-Design name + `description`/`showClose`, composes the **same overlay-floor** and reuses the `.mx-modal`
  style family (a thin component, not a re-implementation). **`Modal` is NEVER renamed** (master invariant); the
  two contracts cross-link.

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
- **RULED (Operator, 2026-07-01): arm (a) — hand-roll `useAnchoredPosition`, no npm dependency.** Port the
  prototypes' enum placement (the `top/bottom × start/end`, `top/bottom/left/right`, and pointer-`fixed` cases)
  into one floor helper; build the full helper (incl. the cases mx.7.5's menus/cards need). **No positioning
  library is added.**

## E · The strong Effector bridge — the disclosure adapter + the overlay-stack scroll-lock (NEW; Operator-added 2026-07-01)

**A scope axis added by the Operator.** The overlays this batch ships (`Dialog`/`AlertDialog`/`Popover`) are
**presentational** — they expose controlled state as props (`open`/`onOpenChange`/`onClose`) and hold no
application state (the `@mercury/effector` posture). §E adds the **optional driver**: an `@mercury/effector`
adapter that *produces* that controlled state and manages the cross-overlay concerns a single presentational
component cannot — exactly as `theme`/`toast` drive their components from the outside. The Operator chose the
**richer** of the two options — **both parts below**.

**Grounding (verified).** `mercury/packages/mercury-effector/src/` ships **7 adapter modules today**
(`channel · cooldown · form · formatter · strength · theme · toast`; the barrel `src/index.ts` = 7 `export *`
lines). `disclosure` is the **8th** — additive (`+ export * from "./disclosure"`). Peer deps `effector >=23` +
`effector-react >=23` + `react >=18` + `@mercury/ui workspace:*` are **already present** (`package.json`) — **no
new dependency**. Two idioms to mirror: the **singleton** model (`theme.ts` — module-scope `createEvent`/
`createStore` + an idempotent `initTheme()` starter + a `useTheme = () => useUnit($theme)` hook) and the
**factory** model (`cooldown.ts` — `createCooldown()` returns `{ $store, …actions, useHook }`). `toast.tsx` is
the one adapter that renders JSX.

### E.1 · `createDisclosure()` — the per-overlay controlled-state factory
A **factory** (the `createCooldown` idiom), one call per overlay instance, producing the controlled-state model a
consumer wires into a presentational overlay:
- **Contract (postcondition):** `createDisclosure(opts?: { defaultOpen?: boolean })` → `{ $open, open, close,
  toggle, useOpen }` — `$open: Store<boolean>`; `open`/`close`/`toggle` events; `useOpen = () => useUnit($open)`
  (the `useTheme`/`useCooldown` hook idiom). *(Exact member names are Mars's to finalize against the
  `cooldown.ts`/`form.ts` factory idiom; the body fixes the **contract** — a controlled boolean + open/close/
  toggle + a read hook — not the bikeshed.)*
- **Wiring (what the story exercises):** `const dlg = createDisclosure()` → `<Dialog open={dlg.useOpen()}
  onClose={dlg.close}>`; `<Popover open={p.useOpen()} onOpenChange={(o) => (o ? p.open() : p.close())}>`. The
  overlay stays the source of truth for its DOM; the model is the source of truth for *whether it is open*.

### E.2 · The overlay-stack + body-scroll-lock model (the "strong" part — a GLOBAL singleton)
A **singleton** model (the `theme` idiom — module scope, an idempotent starter) tracking every open overlay and
locking body scroll while any is open:
- **Contract:** a `$openOverlays: Store<OverlayId[]>` **stack** (push on open, pop on close — LIFO, so the last
  opened is topmost for `Escape`-topmost + z-ordering); events `pushOverlay(id)` / `popOverlay(id)`; derived
  `$anyOverlayOpen = $openOverlays.map((s) => s.length > 0)` and `$topOverlay` (`.at(-1) ?? null`); a read hook
  `useAnyOverlayOpen()`.
- **Body-scroll-lock (postcondition):** an idempotent `initOverlayLock()` starter (the `initTheme` idiom) watches
  `$anyOverlayOpen`; on `true` it locks `document.body` (`overflow: hidden` + padding-compensation for the removed
  scrollbar width, so the layout does not shift); on the **last** close it releases (restores the prior inline
  `overflow`/`padding-right`). SSR-guarded (`typeof document !== "undefined"` — the `theme.ts` guard idiom).
- **Where it lives:** entirely in `@mercury/effector`. `@mercury/ui`'s overlays do NOT import it and do NOT
  scroll-lock themselves — the lock is the adapter's job (a `Dialog` used *without* the bridge simply does not
  scroll-lock, exactly as a component used without `theme` simply does not persist a theme).

### E.3 · INV-EFFECTOR (see §8) — the overlays stay presentational; the bridge is the optional driver
In one line: the overlays' prop surface (`open`/`onOpenChange`/`onClose`) is **unchanged** by the bridge;
`@mercury/ui` gains **no dependency** on `@mercury/effector` (the arrow is effector → ui, never the reverse); and
the bridge is **proven live** by a `sb:build` `Effector/Overlay` story (the mx.5 pattern —
`apps/storybook/stories/effector/Overlay.stories.tsx`, joining Theme/Toast/Form/Strength/Cooldown/Formatter) that
wires `createDisclosure` + the scroll-lock model to a real `Dialog` + `Popover`.

## F · Deliverable-2 — the showcase foundation (NEW; Operator-added 2026-07-01; a SEPARATE commit)

**A scope axis added by the Operator, sequenced as commit #2.** mx.7.4's packages (the overlays + the floor + the
Effector bridge — §§0–8, K-1..K-11) ship gate-green as **commit #1**; then a **showcase foundation** ships as
**commit #2**. This does not fold the whole Developer Reference (that stays mx.9, registry §4) — it stands up the
**app shell + the new overlays as the first live demo**, so the Reference has a real home to grow into.

**Grounding (verified).** There is **no `mercury/apps/showcase/` yet** (the real `mercury/apps/` holds
`echomq · mobile · storybook` — three `package.json`). `pnpm-workspace.yaml` already globs `apps/*`, so a new
`apps/showcase/` is **auto-included — no workspace-file edit needed**. North star:
`docs/mercury/mercury-ui.registry.md` §4 (the planned Developer Reference) — §4.1 (scaffold from the prototype),
§4.3 (the sidebar IA). Prototype (read-only): `mercury/packages/mercury-ds/project/showcase/` — `index.html` (the
in-browser-babel host — NOT translated), `app.jsx` (the shell: `Sidebar` brand+nav-groups, `Topbar`
breadcrumb+theme-toggle, `App` route+theme state), `app.css` (the chrome — translate to tokens), `loader.js` (the
in-browser transpiler — prototype-only, replaced by Vite).

### F.1 · The app (the scaffold contract — mirror `apps/mobile` exactly)
A new Vite/React app `mercury/apps/showcase/` resolving `@mercury/*` **from source** (a package edit is live, no
prebuild):
- `vite.config.ts` — `react()` + `resolve.alias` mapping `@mercury/{ui,effector,core}` →
  `../../packages/*/src/index.ts` (byte-mirror `apps/mobile/vite.config.ts`).
- `tsconfig.json` — extend `../../tsconfig.base.json`, `noEmit`, `types: ["react","react-dom"]`, `paths`
  mirroring the aliases, `include: ["src"]` (byte-mirror `apps/mobile/tsconfig.json`).
- `package.json` — `name: "@mercury/showcase"`, `private: true`, the `dev`/`build`/`preview`/`typecheck`
  scripts, deps `@mercury/ui` + `@mercury/effector` (`workspace:*`) + `effector`/`effector-react`/`react`/
  `react-dom` (mirror `apps/mobile/package.json`).
- `index.html` + `src/main.tsx` — `createRoot(#root).render(<StrictMode><App/></StrictMode>)` after `initTheme()`
  (the `apps/mobile/src/main.tsx` idiom); styles resolve through the `@mercury/ui` source import as in the sibling
  apps (no extra step).

### F.2 · The foundation scope (THIS rung)
- **The shell** — translate `app.jsx`'s `Sidebar` + `Topbar` + `App` into a real `@mercury/*`-composing React
  app: a sidebar (brand + nav groups) + a topbar (breadcrumb + a **theme toggle driven by the `@mercury/effector`
  `theme` adapter** — `useTheme`/`toggleTheme`, NOT the prototype's hand-rolled `useState`+`useEffect`), styled
  through **tokens** (`rgb(var(--token))`) + the `.light-theme`/`.dark-theme` class the theme adapter flips.
- **The first live demo** — the **new overlays** (`Dialog`/`AlertDialog`/`Popover`) mounted as the foundation's
  first content, **driven by the §E disclosure adapter + the scroll-lock model** (open-buttons → the disclosure
  model → the overlays; the stack-lock proven by opening two).
- **Composition only** (the corollary invariant — canon §7 `D-8`): the showcase **composes** `@mercury/ui` +
  `@mercury/effector`; it **never houses a reusable component** — if the shell needs a piece it composes an
  existing `@mercury/ui` export or writes app-local layout, never a reusable one.
- **Adds nothing to the `@mercury/ui` barrel** — the showcase is a consumer; the master invariant holds.

### F.3 · Explicitly DEFERRED to mx.9 (registry §4)
The full per-component Developer Reference — the Components / Foundations / Patterns routes rendering every
contract's API/Props/Usage/Do-Don't/Composition + mounting the live stories (registry §4.2/§4.3) — stays **mx.9,
Squad-tier**. This rung ships only the shell + the overlay demo; it is the foundation those routes grow on.

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

Two Operator-added axes land with it. **§E — the strong Effector bridge:** `@mercury/effector` grows an 8th
adapter (`disclosure`, +1 barrel line) — a `createDisclosure()` factory + a global overlay-stack / body-scroll-
lock singleton — the overlays' **optional** driver; `@mercury/ui` gains no `@mercury/effector` dependency, and an
`Effector/Overlay` story proves the bridge live under `sb:build`. **§F — the showcase foundation (commit #2):** a
new `mercury/apps/showcase/` Vite app resolving `@mercury/*` from source — the shell (sidebar + topbar + the
theme toggle) + the new overlays as its first live demo driven by §E — that **composes** and houses no reusable
component. The rung ships as **two sequenced commits**: #1 the packages (K-1..K-11, gate-green), #2 the showcase
(K-12).

## 2 · Rationale (5W)

- **Why.** The dialog family is where "a11y is part of the component" (canon §8) is load-bearing: a blocking
  dialog that does not trap focus or return it is a defect, not a style miss. Building it on one floor — proven
  here by the simplest blocking + anchored surfaces — makes that bar provable once and gives mx.7.5's menus a
  hardened contract to compose.
- **What.** The overlay-floor primitive (§4), the 3 translated 4-file homes, the `@mercury/ui` barrel grown +3,
  the `.mx-*` overlay rules in `src/styles/additions.css` (incl. static `@keyframes` replacing the prototypes'
  runtime style injection), the one-line `@mercury/core` barrel widening for the floor (§A ruled shared), the
  `@mercury/effector` `disclosure` adapter + its `Effector/Overlay` story (§E), and — as commit #2 — the
  `mercury/apps/showcase/` foundation (§F).
- **Who.** *Authored by* the architect (this triad) + the batch's build/verify agents (epic §2 cadence,
  Squad-tier — verifier mandatory). *Consumed by* mx.7.5 (the floor), mx.8 (the stories), mx.9 (the showcase),
  and the workspace apps.
- **When.** Batch 4 — after 7.1/7.2/7.3, with the Operator in the loop before it and between 7.4 and 7.5.
- **Where.** *Commit #1 (packages):* `packages/mercury-ui/src/` (the 3 folders + the `<Portal>` + barrel +
  `additions.css`) · `packages/mercury-core/src/` (the overlay-floor hooks + the one-line barrel widening — §A
  ruled shared) · `packages/mercury-effector/src/disclosure.ts` + its barrel line · `apps/storybook/stories/
  effector/Overlay.stories.tsx` (§E). *Commit #2 (showcase):* `mercury/apps/showcase/**` (§F — a new app;
  `pnpm-workspace.yaml` already globs `apps/*`, so it is unchanged). Plus `docs/mercury/specs/mx.7.4/`. The bundle
  `packages/mercury-ds/` is **read-only**. Everything else in the `jonnify` root is out of bounds (the Mercury
  island).

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
- **K-11 — the Effector disclosure bridge** (§E; commit #1): `packages/mercury-effector/src/disclosure.ts` — the
  `createDisclosure()` factory (`{ $open, open, close, toggle, useOpen }`) **and** the global overlay-stack /
  body-scroll-lock singleton (`$openOverlays` LIFO · `pushOverlay`/`popOverlay` · `$anyOverlayOpen` · idempotent
  `initOverlayLock()`); the barrel grows +1 (`export * from "./disclosure"`, 7 → 8, prior byte-present); the
  `apps/storybook/stories/effector/Overlay.stories.tsx` (`Effector/Overlay`) story wires it to a real `Dialog` +
  `Popover`. The overlays stay presentational — `@mercury/ui` gains no `@mercury/effector` dep (INV-EFFECTOR).
- **K-12 — the showcase foundation** (§F; **commit #2**): a new `mercury/apps/showcase/` Vite app (mirror
  `apps/mobile`) resolving `@mercury/*` from source — the shell (sidebar + topbar + the `@mercury/effector`
  theme toggle) + the new overlays as the first live demo driven by the §E bridge. **Composes only; houses no
  reusable component; adds nothing to the barrel** (INV-SHOWCASE). The full per-component Reference is DEFERRED to
  mx.9.

**Coverage:** K-1 → S-1, S-7 ; K-2 → S-2..S-4 ; K-3 → S-5 ; K-4 → S-2..S-4, S-8 ; K-5 → S-7 ; K-6 →
S-2..S-4 ; K-7 → S-6 ; K-8 → S-2, S-5 ; K-9 → S-8 ; K-10 → S-8 ; **K-11 → S-9 ; K-12 → S-10**.

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
  the floor — and `@mercury/effector` — the disclosure adapter) · `pnpm --filter "./apps/*" --filter
  "!@mercury/storybook" build` = 0 (`echomq`+`mobile` at commit #1; **+`showcase` at commit #2**) ·
  `pnpm sb:build` = 0 (prior + the 3 overlay homes + the `Effector/Overlay` story).
- **INV-EFFECTOR — the overlays stay presentational; the bridge is the optional driver (§E; commit #1).** The
  overlays' prop surface (`open`/`onOpenChange`/`onClose`) is byte-unchanged by the bridge, and `@mercury/ui`
  gains **no** dependency on `@mercury/effector`:
  `grep -n "@mercury/effector" packages/mercury-ui/package.json` → **empty** (the arrow is effector → ui only).
  The `@mercury/effector` barrel is **additive** — `src/index.ts` gains exactly `export * from "./disclosure"`
  (7 → 8 `export *` lines; the prior 7 byte-present). The bridge is proven **live**, not asserted:
  `apps/storybook/stories/effector/Overlay.stories.tsx` (title `Effector/Overlay`) wires `createDisclosure` + the
  scroll-lock model to a real `Dialog` + `Popover`, and `pnpm sb:build` registers it — a no-op story that renders
  neither does **not** satisfy this gate.
- **INV-SHOWCASE — the showcase foundation builds from source and houses no reusable component (§F; commit #2).**
  `pnpm --filter @mercury/showcase build` exits 0, resolving `@mercury/*` from source via the vite alias; the app
  imports **only** from `@mercury/{ui,effector,core}` + React
  (`grep -rn "from \"" apps/showcase/src | grep -vE "@mercury/(ui|effector|core)|[\"']react"` → **empty** of
  other package imports), and defines **no** reusable component under `apps/showcase/src` (canon §7 `D-8` — the
  app composes, never houses); it adds **nothing** to the `@mercury/ui` barrel (INV-1 holds).
  `pnpm-workspace.yaml` is **unchanged** (`apps/*` already globs the new app).

## 9 · The batch loop (epic §2) — Operator → Agent-1 → Agent-2 → Operator (Squad-tier)

§A/§C/§D are **RULED** (see their headers) and §E/§F are folded → **Agent-1** reconciles (lag-1 vs the as-built
`@mercury/ui` + `@mercury/core` + `@mercury/effector` + the bundle), then builds along the **wave plan**
([`mx.7.4.llms.md`](./mx.7.4.llms.md)): Wave 1 the core floor → Wave 2 the 3 ui overlays → Wave 3 the Effector
bridge (**commit #1**, K-1..K-11) → Wave 4 the showcase foundation (**commit #2**, K-12) → **Agent-2 (MANDATORY
verifier — HIGH risk)** re-runs the gate, reconciles spec↔code, **adversarially probes the a11y floor** (proves
the trap/return/dismiss fire, not just render), **probes the bridge's liveness** (the `Effector/Overlay` story
drives real overlays under `sb:build`; `@mercury/ui` has no `@mercury/effector` dep) and **the showcase build**
(`--filter @mercury/showcase build` = 0, composes-not-houses), classifies every promise
MATCH/STALE/INVENTED/MISSING, fills §11 → Operator reviews the +3 Storybook homes + the bridge story + the
showcase + the gate, then **carries the floor's API + the `accent`-class + a11y-assertion patterns into mx.7.5's
brief** and releases batch 5. Feedback edits this spec, never the code directly.

## 10 · Out of scope

- The **six menu / hover / nav overlays** (`Dropdown`, `ContextMenu`, `HoverCard`, `LinkPreview`, `Menubar`,
  `TabNav`) — those are **[`../mx.7.5/mx.7.5.md`](../mx.7.5/mx.7.5.md)**, which consumes this batch's floor.
- The **Storybook enrichment** (palette/variant-switching/real-world scenes) — that is **mx.8**. This batch's
  stories are the basic mx.4-shape homes + the a11y assertions INV-A11Y requires.
- The **full per-component Developer Reference** — the showcase's Components / Foundations / Patterns routes that
  render every contract (API/Props/Usage/Do-Don't/Composition) + mount the live stories (registry §4.2/§4.3) —
  stays **mx.9, Squad-tier**. **In scope now (§F, commit #2):** only the showcase *foundation* — the app shell
  (sidebar + topbar + theme toggle) + the new overlays as its first live demo. The `@mercury/effector` adapters
  beyond `disclosure` (any further overlay-state helpers) are also out — §E ships `disclosure` only.
- Reconciling the **21 re-prototypes** of existing exports (epic §6) — mx.7 only *adds* net-new surface.
- Any **rename/removal** of an existing export (`Modal`/`Tooltip` included), or any **value change** to an
  existing token.
- Collision-aware auto-flip positioning (a `@floating-ui` capability) — only if the Operator rules §D arm (b).
- `/design-sync`, the `DesignSync` MCP, any push to Claude Web (FORBIDDEN).
- Editing the roadmap/progress/design/epic — the Director folds at ship (the 7.4 row → BUILT, a `D-` per ruled
  §A/§C/§D call, the running barrel-jump).

## 11 · As-built (the verifier — filled post-build)

> Classify K-1..K-12 / INV-1..INV-8 + INV-FLOOR/INV-A11Y/INV-DOWN/INV-EFFECTOR/INV-SHOWCASE / S-1..S-10
> MATCH/STALE/INVENTED/MISSING; record the ratified §A (floor home = shared `@mercury/core`), §C (Dialog = net-new
> arm (a)), §D (positioning = hand-roll) arms; list the 3 folders + the floor files + `disclosure.ts` + the
> `Effector/Overlay` story + the `apps/showcase/` tree shipped, and **which commit** (#1 packages / #2 showcase)
> each landed in. Reproduce the gate (EXIT 0) incl. the barrel-diff (`@mercury/ui` 0 removed/renamed, +3;
> `@mercury/effector` 7 → 8 `export *`, prior byte-present), the `sb:build` delta (+3 homes + `Effector/Overlay`),
> `--filter @mercury/showcase build` = 0, and the idiom/hex/keyframe/framing/no-design-sync greps (empty).
> **Reproduce the INV-A11Y proofs** (trap fires, focus returns, dismiss/no-dismiss), the **INV-EFFECTOR** proof
> (the bridge story drives real overlays; `@mercury/ui` has no `@mercury/effector` dep), and the **INV-SHOWCASE**
> proof (from-source build, composes-not-houses). Carry forward to mx.7.5 the floor's API + the `accent`-class +
> a11y-assertion patterns + the disclosure-bridge recipe.

### 11.1 · Verdict — BLOCKED (one delta: the `Dialog` focus-return assertion is absent)

Commit #1 (K-1..K-11, packages) is gate-green and reconciles clean **except INV-A11Y / S-7**: the `Dialog`
`A11yTrap` play proves `role="dialog"` + `aria-modal="true"` + the trap-wrap (`Tab` from the last focusable →
the first), but does **not** assert the required focus-**return** to the trigger on close. INV-A11Y §8 + S-7
require all three; the third is missing. The behavior IS implemented (`useFocusTrap` cleanup restores
`previouslyFocused.current`; `Dialog` passes no `returnFocusTo`, so focus returns to whatever held it when the
trap engaged = the trigger) and works at runtime — but no **running** check proves it, and INV-A11Y's own
charter is "a check counts only if it RUNS" (a code-read is exactly what the invariant deems insufficient).
**Fix:** ~4 lines appended to the existing `A11yTrap` play — close via `{Escape}`/Cancel, then
`await expect(openButton).toHaveFocus()`. Story-only; the behavior needs no change; routes to the implementor
via the Director; re-verify the play. **Commit #2** (K-12 / §F showcase) = DEFERRED (not yet built — the
sequenced-commits plan).

### 11.2 · Ratified arms (recorded)
- **§A** floor home = a shared headless floor in `@mercury/core` (arm a): behavior hooks in core `internal/`,
  the `<Portal>` in `@mercury/ui`.
- **§C** `Dialog` = net-new monolithic (arm a); `Modal` kept + byte-present (never renamed — master invariant).
- **§D** positioning = hand-rolled `useAnchoredPosition`, no npm dependency.
- **§E** (folded) = the disclosure bridge shipped in commit #1; **§F** (folded) = the showcase deferred to
  commit #2.

### 11.3 · Files shipped (commit #1)
- **Floor** (`packages/mercury-core/src/internal/`): `use-focus-trap.ts` · `use-dismiss.ts` ·
  `use-anchored-position.ts`, composing the pre-existing `use-id.ts` (a plain base36 counter — NOT a React
  hook, documented) · `use-arrow-navigation.ts` · `focus.ts` · `should-enable-focus-trap.ts` · `dom.ts`
  (`isClickTrulyOutside`); surfaced through the `@mercury/core` D-5 barrel.
- **Portal**: `packages/mercury-ui/src/components/overlay/_overlay/Portal.tsx`.
- **Overlays** (4-file homes): `overlay/{Dialog,AlertDialog,Popover}/` (`<Name>.tsx` · `index.ts` ·
  `<Name>.prompt.md` · `<Name>.stories.tsx`). Barrel `packages/mercury-ui/src/index.ts` +3 (folders).
- **Bridge**: `packages/mercury-effector/src/disclosure.ts` (`createDisclosure` factory + the
  `$openOverlays` LIFO stack / `pushOverlay`/`popOverlay` / `$anyOverlayOpen` / `$topOverlay` /
  `useAnyOverlayOpen` / idempotent reversible `initOverlayLock`) + barrel `+ export * from "./disclosure"`;
  story `apps/storybook/stories/effector/Overlay.stories.tsx` (`Effector/Overlay`).

### 11.4 · Gate reproduced (independent)
- `pnpm sb:typecheck` **EXIT 0** (re-run — the authoritative NO-INVENT + play-fn type gate).
- **INV-1** barrel (dist/index.d.ts L63-67 + the read named exports): `@mercury/ui` +3 folders → resolved names
  `Dialog·DialogProps·DialogSize · AlertDialog·AlertDialogProps · Popover·PopoverProps·PopoverPlacement`;
  `Modal`/`Tooltip` byte-present; **0 removed/renamed**.
- **INV-2/3/4/FLOOR/5** greps **EMPTY** (inline colour · raw hex · runtime `@keyframes` injection ·
  per-overlay `mousedown` · bundle framing in the 3 contracts).
- **INV-7** `tokens.css`: no removed/changed line. **INV-DOWN**: no `design-sync` path touched.
- **INV-EFFECTOR**: `@mercury/ui/package.json` carries no `@mercury/effector` dep; the effector barrel gains
  `disclosure` additively; the `Effector/Overlay` story drives real `Dialog`+`Popover` from outside (live, not
  asserted-only). **Caveat (commit hygiene):** `packages/mercury-effector/src/channel.ts` + its barrel line are
  ALSO untracked in the working tree and are **not** part of K-11; the committed prior (HEAD) barrel = **6**
  `export *` lines, so this spec's "prior 7 byte-present / +disclosure only" grounding is imprecise. The mx.7.4
  pathspec commit must include `disclosure` and **exclude** `channel` (a separate concern).
- **INV-6**: 5/5 overlay component folders ↔ 5 co-located stories.
- (The Director already reproduced the full green package/app/`sb:build` build; trusted + spot-confirmed.)

### 11.5 · INV-A11Y verdict per overlay — plays are NOT executed by any gate (no test-runner; play fns run in the interactions panel), so correctness is established by reading the floor + play logic
- **Dialog** — role+aria-modal: **PROVEN**. Trap-wrap (last→first): **PROVEN** (play focuses `Save`, tabs,
  asserts `Close`; exercises the `useFocusTrap` keydown wrap branch; `userEvent.tab()` respects the handler's
  `preventDefault`; `body`-scoped so it finds the portaled panel). Focus-return: **NOT ASSERTED** (implemented,
  unproven → the blocking delta).
- **AlertDialog** — backdrop-no-dismiss: **PROVEN** (clicks `alert.parentElement`, asserts still-open;
  `useDismiss` short-circuits on `outsideClick:false`). Escape-dismiss: **PROVEN** (asserts the panel unmounts).
  Full INV-A11Y clause satisfied.
- **Popover** — aria-expanded toggle: **PROVEN** (false→true on the real `<button>` trigger click).
  Outside-dismiss: **PROVEN** (clicks a real outside `<button>`; `useAnchoredPosition` clamps the panel rect to
  ≥8px, so `userEvent.click`'s default `(0,0)` coords satisfy `isClickTrulyOutside`, and the trigger is in the
  `ignore` list so it is not double-fired; dismiss fires). Full INV-A11Y clause satisfied.

### 11.6 · Reconcile classification
- **MATCH** — K-1, K-2, K-3, K-4, K-6, K-7, K-8, K-9, K-10, K-11 ; INV-1, INV-2, INV-3, INV-4, INV-5, INV-6,
  INV-7, INV-8, INV-FLOOR, INV-DOWN, INV-EFFECTOR (+ the AlertDialog & Popover INV-A11Y clauses) ; S-1, S-2,
  S-3, S-4, S-5, S-6, S-8, S-9.
- **BLOCKING (a MISSING check for a promised outcome)** — INV-A11Y (the `Dialog` focus-return assertion) →
  S-7 → the K-5 story-proof for `Dialog`. Implementation present; the running assertion absent.
- **DEFERRED (commit #2, expected)** — K-12, INV-SHOWCASE, S-10.

### 11.7 · Non-blocking notes (carry into the remediation wave / mx.7.5)
- **S-3 / S-4 broader coverage** — `AlertDialog` initial-focus-on-confirm (`initialFocus: confirmRef`) and
  `Popover` focus-in/return are implemented but not asserted by a running check (outside the INV-A11Y clause,
  so non-blocking). Fold these assertions into the same story wave as the `Dialog` focus-return fix.
- **`useId` naming** — `@mercury/core`'s `useId` is a plain counter, not a hook; `useState(() => useId())` is a
  correct lazy-init but trips `react-hooks/rules-of-hooks` by the `use*` convention. Documented in-source; note
  only.

### 11.8 · Remediation + final verdict — BUILD-GRADE (block resolved)
The §11.1 block was remediated by a **story-only** fix (behavior unchanged; routed to the implementor, then
Director-verified against source):
- **`Dialog` focus-return — now PROVEN.** `Dialog/Dialog.stories.tsx` `A11yTrap` opens from a real trigger (the
  focus origin), keeps the role/aria-modal + trap-wrap assertions, then `userEvent.keyboard("{Escape}")` +
  `await waitFor(() => expect(trigger).toHaveFocus())` — the running check the invariant required. INV-A11Y /
  S-7 / K-5 (`Dialog`) → **MATCH**. `Dialog` now proves all three a11y outcomes.
- **Bonus (§11.7, non-blocking):** `AlertDialog` initial-focus-on-confirm now asserted
  (`await waitFor(() => expect(confirm).toHaveFocus())`). `Popover` focus-return **intentionally NOT asserted** —
  the story dismisses via a real focusable `<button>` that grabs focus, racing the effect-cleanup's
  `triggerEl.focus()`; a flaky proof is worse than an honest gap, and `Popover`'s required INV-A11Y clause
  (aria-expanded + outside-dismiss) is already MATCH. Deferred to an Escape/non-focusable-target story later.
- **Re-verified (Director):** `pnpm sb:typecheck` **EXIT 0**; git-confirmed story-only (no component change).

**Final verdict (commit #1, K-1..K-11): BUILD-GRADE.** Shipped via the mx.7.4 pathspec — `disclosure` in,
`channel` EXCLUDED (the §11.4 caveat honored: the pre-existing untracked `channel` is a separate concern).
Commit #2 (K-12 / §F showcase foundation) follows per the sequenced-commits ruling.
