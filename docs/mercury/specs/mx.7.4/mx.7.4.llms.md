# mx.7.4 — build context (batch 4: the overlay-floor + the dialog family)

Working notes for [`mx.7.4.md`](./mx.7.4.md). Root = `mercury/`. The body is authoritative; this derives from
it. **NO-INVENT:** every bundle prop cited is verified in the bundle `.tsx`; every live target + token + core
helper is real. **Edit ONLY** `packages/mercury-ui/src/` (the 3 component folders + the floor `<Portal>` +
`src/index.ts` + `src/styles/additions.css`) **and** `packages/mercury-core/src/` (the floor hooks + the
one-line barrel widening, **if §A=shared**) + `docs/mercury/specs/mx.7.4/`. The bundle `packages/mercury-ds/` is
**read-only**. Everything else in the `jonnify` root is out of bounds.

## Three open calls gate this batch — do NOT proceed past them without the Operator's ruling

§A (overlay-floor home: shared `@mercury/core` [Steward] vs per-overlay vs ui-internal vs third-party) · §C
(`Dialog`↔`Modal`: add net-new [Steward] vs alias vs fold — **the bundle `Dialog` is monolithic, not
composable-parts**) · §D (positioning: hand-roll [Steward] vs `@floating-ui` vs Radix). **§B (the 7.4|7.5 split)
is RESOLVED — Operator-approved.** This triad is authored under the Steward arms; if the Operator rules
otherwise, only the floor's *home* / the Dialog *resolution* / the positioning *source* move — the a11y
acceptance is behavior-first and unchanged. **The floor is published for [`../mx.7.5/`](../mx.7.5/mx.7.5.md).**

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

# @mercury/core — the floor behavior (IF §A = shared) — built whole, published for 7.5
packages/mercury-core/src/internal/use-focus-trap.ts               # composes focus.ts + should-enable-focus-trap.ts
packages/mercury-core/src/internal/use-dismiss.ts                  # outside-click + Escape (+ optional scroll for 7.5's ContextMenu)
packages/mercury-core/src/internal/use-anchored-position.ts        # the enum/pointer placement (all cases)
packages/mercury-core/src/index.ts                                 # widen by the floor hooks ONLY (D-5)
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

## The gate (run from `mercury/`)

```bash
pnpm --filter "./packages/*" typecheck                          # incl. @mercury/core (the floor)
pnpm --filter "./packages/*" build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build   # echomq + mobile
pnpm sb:typecheck                                                # authoritative story NO-INVENT gate
pnpm sb:build                                                    # prior homes + 3

# barrel additive (resolve the full set, not a text-diff): 0 removed/renamed, +3 (+ Props/enum types),
#   Modal/Tooltip byte-present.
# idiom + hygiene greps — expect EMPTY:
grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})" packages/mercury-ui/src/components/overlay/{Dialog,AlertDialog,Popover}
grep -rnE "#[0-9a-fA-F]{3,8}\b" packages/mercury-ui/src/components/overlay/{Dialog,AlertDialog,Popover} packages/mercury-ui/src/styles/additions.css
grep -rn  "createElement(\"style\")\|ensureKeyframes" packages/mercury-ui/src/components/overlay/{Dialog,AlertDialog,Popover}
grep -rniE "check_design_system|pixel-perfect|/design-sync|showcase/|window\.Mercury|_ds_bundle" packages/mercury-ui/src/components/overlay/{Dialog,AlertDialog,Popover}
```

## Gotchas

- **Never rename `Modal`/`Tooltip`** (master invariant). Add `Dialog` (per §C); leave `Modal` untouched (or
  additively enriched under §C arm (c) — optional props only).
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
