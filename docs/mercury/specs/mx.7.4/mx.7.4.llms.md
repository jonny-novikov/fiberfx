# mx.7.4 — build context (batch 4: the overlay-floor + the dialog family + the Effector bridge & showcase foundation)

Working notes for [`mx.7.4.md`](./mx.7.4.md). Root = `mercury/`. The body is authoritative; this derives from
it. **NO-INVENT:** every bundle prop cited is verified in the bundle `.tsx`; every live target + token + core
helper is real. **Edit ONLY** (all rulings folded — §A shared `@mercury/core`, §C `Dialog` net-new, §D
hand-roll):
- **Commit #1 (the packages):** `packages/mercury-ui/src/` (the 3 component folders + the floor `<Portal>` +
  `src/index.ts` + `src/styles/additions.css`) · `packages/mercury-core/src/` (the floor hooks + the one-line
  barrel widening) · `packages/mercury-effector/src/disclosure.ts` + `src/index.ts` (+1 barrel line) ·
  `apps/storybook/stories/effector/Overlay.stories.tsx` (the `Effector/Overlay` story — §E).
- **Commit #2 (the showcase):** `mercury/apps/showcase/**` (a new app — §F).
- Plus `docs/mercury/specs/mx.7.4/`.

The bundle `packages/mercury-ds/` is **read-only**. Everything else in the `jonnify` root is out of bounds.

## The batch-shaping calls — all RULED (Operator, 2026-07-01); build to these

- **§A (overlay-floor home) → arm (a): a shared headless floor in `@mercury/core`.** The behavior hooks compose
  the existing `internal/` helpers, surfaced through the D-5 barrel; the `<Portal>` lives in `@mercury/ui`.
- **§C (`Dialog`↔`Modal`) → arm (a): add `Dialog` net-new, keep `Modal`.** `Dialog` is monolithic (**not**
  composable-parts); `Modal` is **never** renamed.
- **§D (positioning) → hand-roll `useAnchoredPosition`.** No positioning npm dependency.
- **§B (the 7.4|7.5 split) is RESOLVED — Operator-approved.** **The floor is published for
  [`../mx.7.5/`](../mx.7.5/mx.7.5.md).**

**Two Operator-added scope axes (§E, §F):** §E the **strong Effector bridge** (a `createDisclosure()` adapter +
a global overlay-stack / body-scroll-lock singleton — the overlays' optional driver; `@mercury/ui` untouched);
§F **deliverable-2** the **showcase foundation** (a new `mercury/apps/showcase/` shell + the new overlays as its
first live demo — a **separate commit #2**). Recipes below.

## Inherited from the epic (read first)

[`../mx.7/mx.7.md`](../mx.7/mx.7.md) §4 (the four cross-batch forks) + §5 (what every batch inherits). Do not
re-decide them here. In one line: translate to `.mx-*` + tokens; additive-only tokens/fonts; never rename an
existing export; design flows DOWN (no `/design-sync`); the 4-file home + the additive barrel + the gate.

## References (read in order)

1. [`mx.7.4.md`](./mx.7.4.md) — the body (§3 prop surfaces, §4 the floor, §5 translation notes, §7 the map).
2. The bundle prototypes (the prop-surface seed — translate, don't drop in):
   `mercury-ds/project/components/overlay/{Dialog,AlertDialog,Popover}/<Name>.tsx` (+ each `<Name>.prompt.md` as
   the prop-list seed only).
3. The collision target + the live overlay idiom: `packages/mercury-ui/src/components/overlay/Modal/Modal.tsx`
   (`createPortal` to `document.body`, `role="dialog"`+`aria-modal`, the `.mx-modal` style family `Dialog`
   reuses).
4. The floor's existing building blocks in `@mercury/core` (compose, do not reinvent):
   `packages/mercury-core/src/internal/{focus.ts, should-enable-focus-trap.ts, use-arrow-navigation.ts,
   use-id.ts, dom.ts}` + the minimal barrel `packages/mercury-core/src/index.ts` (D-5 — widen by the floor
   hooks ONLY). Build the **whole** floor (incl. `useArrowNavigation` passthrough) so mx.7.5's menus consume it.
5. The styles: `packages/mercury-ui/src/styles/additions.css` (add the `.mx-*` rules + the static `@keyframes`
   here), `mercury.css` (the live `.mx-modal` rules to imitate), `tokens.css` (surfaces `--bg-elevated`/
   `--bg-backdrop`, shadows `--shadow-300`/`--shadow-500`, the ring/border focus tokens).
6. The contract format: [`../../contracts.md`](../../contracts.md) + `actions/Button/Button.prompt.md` +
   `foundations/Icon/Icon.prompt.md` (the exemplar pair); mx.7.1's `IconButton.prompt.md` (the close-button
   cross-link target) once batch 1 lands.
7. **The Effector idiom (§E — read these two, ≤2 files):** `packages/mercury-effector/src/theme.ts` (the
   **singleton** model — module-scope events/store + an idempotent `initTheme()` starter + a `useUnit` hook) +
   `packages/mercury-effector/src/cooldown.ts` (the **factory** model — `createCooldown()` returns `{ $store,
   …actions, useHook }`). Barrel `packages/mercury-effector/src/index.ts` (7 `export *` lines → +1). The story
   siblings: `apps/storybook/stories/effector/{Theme,Toast,Cooldown,Form,Strength,Formatter}.stories.tsx`
   (mirror one for `Overlay.stories.tsx`). *(`toast.tsx` is the only adapter that renders — read only if the
   scroll-lock needs a render reference; it does not.)*
8. **The showcase scaffold (§F — mirror one app):** `apps/mobile/{vite.config.ts, tsconfig.json, package.json,
   src/main.tsx}` (the from-source alias + `paths` + `initTheme()` idiom to byte-mirror) · the prototype shell
   `packages/mercury-ds/project/showcase/{app.jsx, index.html, app.css, loader.js}` (read-only — `app.jsx` is
   the Sidebar/Topbar/App to translate; `loader.js`/`index.html`'s in-browser babel is **dropped**, Vite
   replaces it) · the north star [`../../mercury-ui.registry.md`](../../mercury-ui.registry.md) §4
   (§4.1 scaffold, §4.3 sidebar IA).

## Ground facts (re-probe before trusting)

- **Stack:** Vite ^6, React 19, Node 22, pnpm 10.17, TypeScript ^5.6; `tsconfig.base.json` `verbatimModuleSyntax`
  (`import type` for types), `strict` + `noUncheckedIndexedAccess`, `jsx: react-jsx`.
- **`react-dom` is available to `@mercury/ui`** (`peerDependencies: react-dom >=18`, dev `^19`) — so
  `createPortal` lives UI-side. **`@mercury/core` has `react` peer ONLY (no `react-dom`)** — the floor's
  behavior hooks are JSX/portal-free; the `<Portal>` wrapper is a `@mercury/ui` component.
- **The bundle `Dialog` is monolithic, not composable-parts** (verified `overlay/Dialog/Dialog.tsx`): `open ·
  onClose? · title? · description? · children? · footer? · size? · showClose?` — it is `Modal` + `description` +
  `showClose`. The §C arms are framed against that.
- **No prototype uses a positioning library** — `Popover` hand-rolls the `bottom-start|…|top-end` enum. §D arm
  (a) = port that into `useAnchoredPosition` (build the full helper, incl. the cases 7.5's menus/cards need).
- **Runtime `@keyframes` injection must go** — `Dialog`/`Popover` call `ensureKeyframes()`
  (`document.createElement("style")` → `<head>`). Translate to static `@keyframes` in `additions.css`.
- **`sb:typecheck` is the authoritative story NO-INVENT gate** (the library `tsc` excludes `**/*.stories.tsx`,
  D-9). A wrong prop/symbol fails there, not in `pnpm --filter @mercury/ui typecheck`.
- **`@mercury/core` boundary imports must be RELATIVE** through the barrel (the mx.1 landmine: an `@/` import
  resolves inside core but breaks in a consumer with no `@` alias — tree-shaking hid it once). The floor hooks
  surfaced through the barrel use relative paths.

## The file tree (create exactly these; nothing else)

```
# @mercury/ui — the 3 homes (4 files each)
packages/mercury-ui/src/components/overlay/Dialog/{Dialog.tsx, index.ts, Dialog.prompt.md, Dialog.stories.tsx}
packages/mercury-ui/src/components/overlay/AlertDialog/{AlertDialog.tsx, index.ts, AlertDialog.prompt.md, AlertDialog.stories.tsx}
packages/mercury-ui/src/components/overlay/Popover/{Popover.tsx, index.ts, Popover.prompt.md, Popover.stories.tsx}
packages/mercury-ui/src/components/overlay/_overlay/Portal.tsx     # the createPortal wrapper (floor, UI-side)
packages/mercury-ui/src/index.ts                                   # +3 barrel lines (additive)
packages/mercury-ui/src/styles/additions.css                      # +3 .mx-* blocks + static @keyframes

# @mercury/core — the floor behavior (§A RULED: shared) — built whole, published for 7.5
packages/mercury-core/src/internal/use-focus-trap.ts               # composes focus.ts + should-enable-focus-trap.ts
packages/mercury-core/src/internal/use-dismiss.ts                  # outside-click + Escape (+ optional scroll for 7.5's ContextMenu)
packages/mercury-core/src/internal/use-anchored-position.ts        # the enum/pointer placement (all cases)
packages/mercury-core/src/index.ts                                 # widen by the floor hooks ONLY (D-5, relative paths)

# @mercury/effector — the disclosure bridge (§E) — commit #1
packages/mercury-effector/src/disclosure.ts                        # createDisclosure() + overlay-stack + scroll-lock singleton
packages/mercury-effector/src/index.ts                             # +1: export * from "./disclosure"  (7 → 8, additive)
apps/storybook/stories/effector/Overlay.stories.tsx                # title "Effector/Overlay" — wires the bridge to Dialog + Popover

# @mercury/showcase — the foundation (§F) — commit #2 (a NEW app; mirror apps/mobile)
apps/showcase/package.json                                         # name "@mercury/showcase", private, mirror apps/mobile
apps/showcase/vite.config.ts                                       # react() + resolve.alias @mercury/* → ../../packages/*/src/index.ts
apps/showcase/tsconfig.json                                        # extends tsconfig.base.json + paths mirror
apps/showcase/index.html                                           # <div id="root"> + module script
apps/showcase/src/main.tsx                                         # initTheme(); createRoot(#root).render(<StrictMode><App/></StrictMode>)
apps/showcase/src/App.tsx                                          # the shell: Sidebar + Topbar (theme toggle) + the overlay demo
apps/showcase/src/showcase.css                                     # app-local layout only (tokens; never a reusable component)
# NOTE: pnpm-workspace.yaml already globs apps/* — do NOT edit it.
```

(Exact hook names are Mars's to finalize against the existing `internal/` files; the body fixes the
**contract** — what the floor centralizes — not the bikeshed.)

## The dialog family ↔ the floor

- **`Dialog`/`AlertDialog`** exercise `useFocusTrap` + `useDismiss` + `<Portal>` (blocking, modal).
- **`Popover`** exercises `useAnchoredPosition` + `useDismiss` + focus in/return (anchored, non-modal).
- The floor's `useArrowNavigation` is **built and published** here but **unused by the 3 dialogs** — mx.7.5's
  menus consume it. Building it now means 7.5 composes a complete contract, not a half-floor.

## The translation recipe (every component)

1. Read the bundle `.tsx` → extract the prop surface + anatomy (ignore the inline `style={{}}` values + the
   `ensureKeyframes` injection).
2. Write `<Name>.tsx`: `import type { … } from "react"`, `import { cx } from "@mercury/core"` + the floor hooks
   (per §A), a `forwardRef`/function component extending the HTML attrs, `className={cx("mx-<name>", …modifiers,
   className)}`. Route portal/trap/dismiss/position through the floor — do **not** re-roll the inline effects.
3. Add the `.mx-<name>` rules + the static `@keyframes` to `src/styles/additions.css` — `rgb(var(--token))`
   only, no raw hex.
4. `index.ts` = `export * from "./<Name>";`. Add the line to `src/index.ts` (additive — never remove/rename).
5. `<Name>.prompt.md` — hand-author (mx.2 format): role · `## Props` · `## The enum language` · `## Composition`
   (cross-links by real relative path) · `## Examples` (net-new → end each with "(source-grounded; no app call
   site)") · `## Notes` (a11y + the React-19 nullable-ref guard). Strip all bundle framing.
6. `<Name>.stories.tsx` — CSF3 (`Meta`/`StoryObj`), `title: "Overlay/<Name>"`, a Playground + a states grid +
   **the a11y assertion INV-A11Y requires** (below). (mx.8 enriches later — keep it the basic mx.4 shape now.)

## The a11y hardening checklist (the HIGH-risk core; canon §8)

- **Dialog / AlertDialog (blocking):** `role="dialog"`/`alertdialog` + `aria-modal="true"`; `aria-labelledby`/
  `aria-describedby` wired via `useId`; **focus-trap + focus-return** (added — the prototypes do not trap);
  initial focus (`AlertDialog` → confirm); `Escape` dismiss; `Dialog` dismisses on backdrop, `AlertDialog` does
  NOT. Portal via `<Portal>`.
- **Popover:** `role="dialog"`; real `<button>` trigger with `aria-haspopup="dialog"`+`aria-expanded`; focus
  in-on-open / return-on-close; outside-click + `Escape`.

## The Effector-bridge recipe (§E — commit #1, Wave 3)

`packages/mercury-effector/src/disclosure.ts` — one file, mirror the two idioms in ref 7.

1. **`createDisclosure(opts?)` — the factory** (the `createCooldown` shape — a store with `.on` reducers + a
   `useUnit` hook):
   ```ts
   import { createEvent, createStore } from "effector";
   import { useUnit } from "effector-react";
   export function createDisclosure(opts?: { defaultOpen?: boolean }) {
     const open = createEvent(); const close = createEvent(); const toggle = createEvent();
     const $open = createStore(opts?.defaultOpen ?? false)
       .on(open, () => true).on(close, () => false).on(toggle, (o) => !o);
     const useOpen = () => useUnit($open);
     return { $open, open, close, toggle, useOpen };
   }
   ```
   *(A sketch — finalize member names against `cooldown.ts`/`form.ts`; the contract is a controlled boolean +
   open/close/toggle + a read hook.)*
2. **The global overlay-stack + body-scroll-lock — a singleton** (the `theme.ts` shape: module-scope units + an
   idempotent `init`): `$openOverlays` (a LIFO stack of ids) + `pushOverlay`/`popOverlay`; derived
   `$anyOverlayOpen = $openOverlays.map((s) => s.length > 0)` + `$topOverlay`; `useAnyOverlayOpen()`. Then an
   **idempotent `initOverlayLock()`** (a module `started` flag, like `initTheme`) that `$anyOverlayOpen.watch(...)`:
   on `true` capture the scrollbar width (`window.innerWidth - document.documentElement.clientWidth`) and set
   `document.body.style.overflow = "hidden"` + `paddingRight`; on `false` **restore** the captured prior values.
   Guard `typeof document !== "undefined"` (the `theme.ts` SSR guard).
3. **Barrel:** append `export * from "./disclosure";` to `src/index.ts` (7 → 8; never reorder/remove the prior 7).
4. **The live proof** — `apps/storybook/stories/effector/Overlay.stories.tsx`, CSF3, `title: "Effector/Overlay"`,
   mirror `Theme.stories.tsx`/`Cooldown.stories.tsx`. A `render` story mounts a REAL `<Dialog>` + `<Popover>` from
   `@mercury/ui`, wires `createDisclosure` + `initOverlayLock`, and exercises open/close + the stack-lock (open
   two). A render-only story that never opens an overlay does **not** satisfy INV-EFFECTOR.
5. **INV-EFFECTOR guard:** do NOT add `@mercury/effector` to `packages/mercury-ui/package.json`; no `@mercury/ui`
   component imports `@mercury/effector`. The arrow is effector → ui only; the overlays' props are unchanged.

## The showcase-foundation recipe (§F — commit #2, Wave 4; a SEPARATE commit)

A new `mercury/apps/showcase/` — byte-mirror `apps/mobile`'s config, translate the prototype shell.

1. **The config (mirror `apps/mobile` exactly):** `package.json` (`name: "@mercury/showcase"`, `private`, the
   dev/build/preview/typecheck scripts, deps `@mercury/ui` + `@mercury/effector` `workspace:*` +
   effector/effector-react/react/react-dom — copy mobile's, change the name) · `vite.config.ts` (byte-copy — the
   three `@mercury/*` aliases to `../../packages/*/src/index.ts`) · `tsconfig.json` (byte-copy — extends base,
   `paths` mirror, `include: ["src"]`) · `index.html` (`<div id="root">` + `<script type="module"
   src="/src/main.tsx">`) · `src/main.tsx` (the mobile idiom: `import { initTheme } from "@mercury/effector";
   initTheme();` then `createRoot(#root).render(<StrictMode><App/></StrictMode>)` — plus `initOverlayLock()` once).
2. **The shell (`src/App.tsx`) — translate `project/showcase/app.jsx`:** a `Sidebar` (brand + nav — for THIS
   foundation a single "Components → Overlays" entry is enough; the full IA is mx.9) + a `Topbar` (breadcrumb + a
   **theme toggle** via the `@mercury/effector` `theme` adapter — `const theme = useTheme(); onClick={() =>
   toggleTheme()}`, NOT the prototype's hand-rolled `useState`+`useEffect`) + the demo body mounting
   `<Dialog>`/`<AlertDialog>`/`<Popover>` driven by `createDisclosure()` models (opening two proves the lock).
3. **Composition only (canon §7 `D-8`):** import components from `@mercury/ui`, state from `@mercury/effector`;
   write only app-local layout (the chrome). Define **NO** reusable component under `apps/showcase/src` — if a
   piece feels reusable it belongs in a package (a fork), not here.
4. **Styling:** tokens only (`rgb(var(--token))`) + the `.light-theme`/`.dark-theme` class the theme adapter
   flips; translate `app.css`'s chrome into a small app-local `showcase.css`; drop the prototype's
   `colors_and_type.css` link (the `@mercury/ui` source import carries the tokens, as in `apps/mobile`).
5. **Do NOT** edit `pnpm-workspace.yaml` (`apps/*` already globs it) or touch the prototype (read-only). **Gate:**
   `pnpm --filter @mercury/showcase build` = 0 (INV-SHOWCASE).

## The wave plan (mx.7.4 build order)

Squad-tier, write-ready dispatch — short waves, **write-first**, heartbeat per file, recover-from-tree (a peer
that dies mid-wave leaves files on disk). Each wave gates before the next; the reconcile (lag-1) runs first.

- **Wave 1 — the core floor** (`@mercury/core`): `internal/use-focus-trap.ts` · `internal/use-dismiss.ts` ·
  `internal/use-anchored-position.ts` — compose the existing `internal/` helpers (do NOT reinvent); widen
  `src/index.ts` by the floor hooks ONLY (D-5; **relative paths** — the mx.1 `@/`-import landmine). **Gate:**
  `pnpm --filter @mercury/core typecheck && pnpm --filter @mercury/core build`.
- **Wave 2 — the ui overlays** (`@mercury/ui`): `overlay/_overlay/Portal.tsx`; the 3 four-file homes
  `overlay/{Dialog,AlertDialog,Popover}/` (`.tsx` translated · `index.ts` · hand-authored `.prompt.md` — D-7,
  strip bundle framing · `.stories.tsx` CSF3 **with** the INV-A11Y assertions); the `.mx-*` rules + static
  `@keyframes` in `src/styles/additions.css`; barrel `src/index.ts` +3 additive. **Gate:** `pnpm sb:typecheck` ·
  `pnpm --filter @mercury/ui typecheck && build` · barrel-diff (0 removed/renamed, +3).
- **Wave 3 — the Effector bridge** (`@mercury/effector`): `src/disclosure.ts` + barrel +1;
  `apps/storybook/stories/effector/Overlay.stories.tsx`. **Gate:** `pnpm --filter @mercury/effector typecheck &&
  build` · `pnpm sb:build` (prior + 3 + `Effector/Overlay`) · INV-EFFECTOR grep. → **COMMIT #1** (K-1..K-11).
- **Wave 4 — deliverable-2, the showcase foundation** (`apps/showcase/`, a SEPARATE commit): the config (mirror
  `apps/mobile`) + the shell + the overlay demo. **Gate:** `pnpm --filter @mercury/showcase build` = 0
  (INV-SHOWCASE). → **COMMIT #2** (K-12).

## The gate (run from `mercury/`)

```bash
pnpm --filter "./packages/*" typecheck                          # incl. @mercury/core (floor) + @mercury/effector (disclosure)
pnpm --filter "./packages/*" build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build   # echomq + mobile (+ showcase at commit #2)
pnpm sb:typecheck                                                # authoritative story NO-INVENT gate
pnpm sb:build                                                    # prior homes + 3 + the Effector/Overlay story

# --- commit #2 (the showcase foundation) ---
pnpm --filter @mercury/showcase build                           # = 0, resolves @mercury/* from source (INV-SHOWCASE)

# barrel additive (resolve the full set, not a text-diff):
#   @mercury/ui: 0 removed/renamed, +3 (+ Props/enum types), Modal/Tooltip byte-present.
#   @mercury/effector: 7 → 8 `export *` lines, prior 7 byte-present.
# idiom + hygiene greps — expect EMPTY:
grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})" packages/mercury-ui/src/components/overlay/{Dialog,AlertDialog,Popover}
grep -rnE "#[0-9a-fA-F]{3,8}\b" packages/mercury-ui/src/components/overlay/{Dialog,AlertDialog,Popover} packages/mercury-ui/src/styles/additions.css
grep -rn  "createElement(\"style\")\|ensureKeyframes" packages/mercury-ui/src/components/overlay/{Dialog,AlertDialog,Popover}
grep -rniE "check_design_system|pixel-perfect|/design-sync|showcase/|window\.Mercury|_ds_bundle" packages/mercury-ui/src/components/overlay/{Dialog,AlertDialog,Popover}
#   ^ the `showcase/` token here targets the BUNDLE prototype's framing; the overlay contracts cite NO app call
#     site this rung ("(source-grounded; no app call site)"), so it stays empty — the real apps/showcase is §F.
# INV-EFFECTOR — the arrow is effector → ui only (expect EMPTY):
grep -n "@mercury/effector" packages/mercury-ui/package.json
# INV-SHOWCASE — the app composes, never houses; imports only @mercury/* + react (expect only @mercury/* + react):
grep -rn "from \"" apps/showcase/src | grep -vE "@mercury/(ui|effector|core)|[\"']react"
```

## Gotchas

- **Never rename `Modal`/`Tooltip`** (master invariant). §C is **RULED arm (a): add `Dialog` net-new, keep
  `Modal` untouched** — `Dialog` composes the floor + reuses the `.mx-modal` style family (thin, not a
  re-implementation).
- **INV-EFFECTOR: the arrow is effector → ui only.** Do NOT add `@mercury/effector` to
  `packages/mercury-ui/package.json`; no `@mercury/ui` component imports `@mercury/effector`. The overlays' props
  (`open`/`onOpenChange`/`onClose`) do not change — the bridge is the OPTIONAL driver, like `theme`/`toast`.
- **The `@mercury/effector` barrel is additive (7 → 8).** Append `export * from "./disclosure"`; never reorder or
  remove the prior 7 (`channel · cooldown · form · formatter · strength · theme · toast`).
- **The showcase COMPOSES, never houses (canon §7 D-8).** No reusable component under `apps/showcase/src` — the
  master invariant (`@mercury/ui` barrel unchanged) holds. Do NOT edit `pnpm-workspace.yaml` (`apps/*` globs it).
  Do NOT edit the prototype (`packages/mercury-ds/` read-only). The showcase is **commit #2** — keep it out of
  commit #1's pathspec.
- **The showcase theme toggle is the `@mercury/effector` `theme` adapter** (`useTheme`/`toggleTheme`/`initTheme`),
  NOT the prototype's hand-rolled `useState`+`useEffect` — that logic moved into the adapter.
- **The bundle `Dialog` is monolithic, NOT composable-parts** — do not invent `Dialog.Root/Trigger/Content`.
- **Compose the floor; do not re-roll the inline dismiss/positioning effects** — that is the whole point of §A.
- **Build the floor WHOLE** (incl. `useArrowNavigation`/`useAnchoredPosition` cases 7.5 needs) — mx.7.5 consumes
  it, so a half-floor forces a 7.5-time floor edit. Compose core's existing `internal/` helpers; don't reinvent.
- **No runtime `@keyframes` injection** (static CSS).
- **`@mercury/core` barrel: widen by the floor hooks ONLY (D-5)** — do not dump `internal/`; use relative paths.
- **The INV-A11Y gate must EXERCISE the behavior** — a story that renders a `Dialog` but never asserts the trap
  fires / focus returns does NOT satisfy it. Assert the outcome (Tab wraps, focus returns, backdrop no-dismiss).
- **Squad-tier at ship:** the verifier is MANDATORY (HIGH risk — a shared primitive + a11y state machines + a
  +3 surface + the published floor). It adversarially re-runs the a11y proofs.
- **Commit hygiene:** the bundle `packages/mercury-ds/` stays OUT of the commit; `mercury/…` pathspec only;
  never `git add -A`; never `pnpm -r` (use `--filter`). The Director commits; agents run no git.
- **Framing (propagate into every contract):** no gendered pronouns for agents; no perceptual/interior-state
  verbs; no first-person narration; state each surface as a contract (precondition / postcondition / invariant).

## Lessons carried from the prior batch

> The Director fills this from mx.7.1/7.2/7.3 as-built at release. Known carry-forwards: the live-idiom
> translation recipe proven across batches 1–3; the React-19 nullable-ref guard; any added font weight.

## When this batch later ships

Its aaw scope slug is the **dashed** form `mx-7-4` (never `mx.7.4` — a dot split-brains the aaw registry). The
next batch (the floor's consumer) is `mx-7-5`. No team is created at authoring time.

**Two sequenced commits (Director, at ship — pathspec only, never `git add -A`):** **#1 the packages** —
`mercury/packages/mercury-{ui,core,effector}/… mercury/apps/storybook/stories/effector/Overlay.stories.tsx
docs/mercury/specs/mx.7.4/` (K-1..K-11, gate-green); **#2 the showcase** — `mercury/apps/showcase/` (K-12). Keep
the bundle `packages/mercury-ds/` and every sibling program out of both. The Director folds the roadmap/progress/
design/registry §4 at ship (the 7.4 row → BUILT; a `D-` per ruled §A/§C/§D; the running barrel-jump;
**reconcile registry §4's stale apps list** — it names `fx-demo · marketing-site · website`, which do not exist;
the real apps are `echomq · mobile · storybook`).
