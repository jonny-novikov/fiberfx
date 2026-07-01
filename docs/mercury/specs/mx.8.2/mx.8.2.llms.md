# mx.8.2 — build brief (for the implementor)

Working notes for building [`mx.8.2.md`](./mx.8.2.md) — the Storybook enrichment **actions slice** (the three
`actions` stories' variant audit · the zero-dep `fn()` action spies · ≥1 actions-led scene · the zero-dep gate).
Root = `mercury/`. The body is authoritative; this derives from it and from the parent epic
[`../mx.8/mx.8.md`](../mx.8/mx.8.md) (§6.3 audit, §6.4 actions, §6.5 scenes, §7 invariants) and the sibling
[`../mx.8.1/mx.8.1.md`](../mx.8.1/mx.8.1.md) (the slice template + the inherited globals). **This brief is
write-ready** — the exact code is inlined below, so the first actions are writes, not a subsystem read.
**NO-INVENT:** every prop/enum/token name here is traced from the live `.tsx` (re-probe at build).

**The `@mercury/ui` barrel + every component file is FROZEN.** The only `packages/mercury-ui/src/**` edits are
`components/actions/*/*.stories.tsx`. The scene is `apps/storybook/stories/scenes/`. **`preview.tsx` is NOT
edited** (the Palette/Roundings globals are inherited from mx.8.1 host-wide). **No dependency manifest** —
`package.json` / `pnpm-lock.yaml` / `.storybook/main.ts` untouched (the `fn`/Actions panel are SB 10.4.6 core).

## References (read first — capped; the code is inlined below)

1. [`mx.8.2.md`](./mx.8.2.md) — the authoritative body (Deliverables D1–D4, Invariants INV1–INV8, the ruled
   decisions).
2. **The three actions components + their current stories (the audit truth — the exported unions are law):**
   `packages/mercury-ui/src/components/actions/{Button,IconButton,Link}/<Name>.{tsx,stories.tsx}` (6 small
   files). Read these to confirm the audit arrays + the handler wiring below.
3. The sibling slice's scene shape (reference, do not re-derive): `apps/storybook/stories/scenes/Profile.stories.tsx`
   / `Article.stories.tsx` (the `title:"Scenes/<Name>"`, no-`component` host-home CSF3 shape mx.8.2 follows) +
   the scene grounding (read-only): `apps/mobile/src/screens/*` +
   `packages/mercury-ds/project/ui_kits/mercury_app/screens.jsx`.

## Ground facts (verified this rung — trust, then re-probe at build)

- **Stack:** Vite ^6, React 19, Node 22.18, pnpm 10.17.1, TypeScript ^5.6.3. `verbatimModuleSyntax: true` (use
  `import type` for types), `strict` + `noUncheckedIndexedAccess`.
- **`preview.tsx` is INHERITED, not edited.** The mx.8.1 Palette + Roundings toolbar globals already wrap every
  story (the `withTheme` decorator re-skins the `--bg-brand` family + the `--radius` steps host-wide). mx.8.2
  consumes them — a `Button variant="primary"` under `Palette=green` already computes green-9. **Do not touch
  `preview.tsx`**; if a gap surfaces, FLAG it.
- **`main.ts` needs NO glob edit** — its `stories/**/*.stories.@(tsx|ts)` already spans `stories/scenes/**`.
- **`sb:typecheck` is the authoritative NO-INVENT gate** — the host `tsc` is the only one that checks the
  enriched stories + scenes (the library `tsc` excludes `**/*.stories.tsx`).
- **Actions = ZERO-DEP core (the Fork-5 resolution).** Storybook **10.4.6** ships the spy + logger + Actions
  panel in **core**: `storybook/test` exports `fn` (a jest-style spy), `storybook/actions` exports `action`,
  and the Actions panel is a core panel (no `@storybook/addon-actions`, no `main.ts` `addons` entry).
  Director-verified: `require.resolve("storybook/test")` and `require.resolve("storybook/actions")` resolve from
  `apps/storybook/` (both under the installed core `storybook` package). **Add no dependency.**
- **The actions handler surface (K-4 targets — verify against the `.tsx`):**
  - `Button` — `interface ButtonProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "type">` →
    **inherits `onClick`** (+ native button handlers); no explicit `on*` in the interface body.
  - `IconButton` — same `extends Omit<ButtonHTMLAttributes<…>, "type">` → **inherits `onClick`**.
  - `Link` — declares **`onClick?: (e: MouseEvent) => void`** explicitly (≈ `Link.tsx:15`).
    `Link.stories.tsx` already has `onClick: { control: false }` — the `fn()` spy goes on `args`, NOT the
    control (keep the slot controls `control: false`).
- **The exported unions (the audit truth — CONFIRMED against the `.tsx` this rung):**
  - `Button` (`Button.tsx`): `ButtonVariant` = `"primary"|"secondary"|"outline"|"ghost"|"destructive"|"inverse"`
    (**6**, lines 5-11) · `ButtonSize` = `"sm"|"md"|"lg"`. Booleans: `loading` · `fullWidth` · `disabled`
    (`disabled` inherited). Slots: `leading` · `trailing`.
  - `IconButton` (`IconButton.tsx`): `IconButtonVariant` = `"primary"|"secondary"|"outline"|"ghost"|"destructive"`
    (**5**, line 7) · `IconButtonSize` = `"sm"|"md"|"lg"` · `IconButtonShape` = `"circle"|"square"`. Boolean:
    `disabled`. `icon: IconName` (required) is a **curated glyph select** (`IconName = keyof ICONS` widens to
    `string` — a MANUAL list, not a typed union); `label: string` (required, → aria-label).
  - `Link` (`Link.tsx`): `LinkSize` = `"sm"|"md"` (line 4) · `type` = `"button"|"submit"|"reset"` (inline).
    Booleans: `muted` · `disabled`. Slots: `leading` · `trailing`. `onClick` already `control: false`.
- **RECONCILE FINDING — the D1 audit is ALREADY complete for all three (mx.4).** Every exported union above is
  already exposed as a typed `select`/`inline-radio` control, slots are already `control: false`, booleans are
  already `control: "boolean"` (see `Button.stories.tsx` / `IconButton.stories.tsx` / `Link.stories.tsx`). **No
  audit top-up is needed** — D1 is a VERIFY. The only per-story edit this rung is D2's `fn()` spy (the import +
  `args: { onClick: fn() }`, and — for `Button`/`IconButton` — a new `onClick: { control: false }` argType;
  `Link` already has it). Keep every mx.4 grid/state story (`Button`: `Variants`·`WithIcon`; `IconButton`:
  `Variants`·`SizesAndShapes`; `Link`: `Sizes`·`States`) + each `Playground`.

- **CSF3 auto-wiring (the spy liveness mechanism).** When a story sets `component` and has **no** custom
  `render`, Storybook renders `<Component {...args} />`, so `args: { onClick: fn() }` auto-wires the spy to the
  rendered handler — a click logs to the Actions panel with zero extra code. If a story uses a **custom
  `render`**, the render MUST pass `onClick={args.onClick}` (or spread `{...args}`) or the spy is a no-op
  (INV-7 LOUD failure). Verify `Link.stories.tsx`'s render before relying on auto-spread.

## Requirements

- **mx.8.2-R1** — expose the full exported-union control surface on the three
  `actions/{Button,IconButton,Link}/<Name>.stories.tsx` (per the audit table); slots/handlers `control: false`,
  booleans `control: "boolean"`; keep the mx.4 grid/state stories. [US: mx.8.2-US1]
- **mx.8.2-R2** — wire a zero-dep `fn()` spy on each story `meta` (`import { fn } from "storybook/test";` +
  `args: { onClick: fn() }`), reaching the rendered handler; add no dependency. [US: mx.8.2-US2]
- **mx.8.2-R3** — add ≥1 host-home actions-led `apps/storybook/stories/scenes/<Name>.stories.tsx`, composing
  only real `@mercury/ui` exports, with a lead comment citing a real screen/pattern; no `Scenes/*` collision.
  [US: mx.8.2-US3]
- **mx.8.2-R4** — the full gate ladder exits 0; the barrel diff is empty; INV-7 (a click logs an Actions-panel
  entry in the running SB) is POSITIVE; INV-6 (zero-dep resolve, no manifest in the diff) holds; the inherited
  globals re-confirm (Palette=green ⇒ Button green-9). [US: mx.8.2-US4]

## Execution topology

```text
runtime — the Storybook host (apps/storybook) resolves @mercury/ui FROM SOURCE (vite alias + tsconfig paths).
  preview.tsx: `decorators: [withTheme]` ALREADY wraps every story in the mx.8.1 theme+palette+radius wrapper
  (INHERITED — not edited). The actions stories add a `fn()` spy on meta.args + full argTypes; the SB core
  Actions panel logs each spied call. The scene registers via main.ts's existing `stories/**` glob (no glob
  edit). Nothing touches @mercury/ui, preview.tsx, or any dependency manifest.
```

```text
tasks (build-order DAG)
  T1  actions/{Button,IconButton,Link}/<Name>.stories.tsx: full-union argTypes + `import { fn } from
      "storybook/test"` + args:{ onClick: fn() }  ── (D1,D2) ──►  gate: sb:typecheck 0 ; barrel-diff empty ;
                                    running-SB: a click on each logs an Actions-panel entry (INV-7)
  T2  stories/scenes/<Name>.stories.tsx (NEW, actions-led, cited)  ── (D3) ──►  gate: sb:build registers
                                    Scenes/<Name> ; hex/bundle/effector greps empty
  T3  full gate + barrel byte-identical + zero-dep resolve + inherited-globals re-confirm  ── (D4) ──►  ship
```

`Touched files:` `packages/mercury-ui/src/components/actions/Button/Button.stories.tsx` (audit + spy) ·
`packages/mercury-ui/src/components/actions/IconButton/IconButton.stories.tsx` (audit + spy) ·
`packages/mercury-ui/src/components/actions/Link/Link.stories.tsx` (audit + spy) ·
`apps/storybook/stories/scenes/<Name>.stories.tsx` (NEW — the ratified scene) · `docs/mercury/specs/mx.8.2/`
(this triad). **Frozen:** `packages/mercury-ui/src/index.ts` · any component `.tsx`/`index.ts`/`.prompt.md`/
`styles/**` · `apps/storybook/.storybook/preview.tsx` · `.storybook/main.ts` · `apps/storybook/package.json` ·
`pnpm-lock.yaml`.

## The `fn()`-spy recipe (D2 — zero-dep, one import + one `args` line per story)

Storybook 10.4.6 ships the spy in **core** — import from `storybook/test` (NOT `@storybook/test`, NOT a new
dep). Add to each `meta`; the CSF3 auto-spread wires it to the rendered handler:

```tsx
import { fn } from "storybook/test"; // SB 10.4.6 CORE subpath — zero new dependency (mx.8.2-INV6)

const meta: Meta<typeof Button> = {
  title: "Actions/Button",
  component: Button,
  args: { onClick: fn() },            // the spy — logs to the SB core Actions panel on click (mx.8.2-INV7)
  argTypes: {
    onClick: { control: false },      // the handler is spied via args, not a control widget
    // …the full-union controls below (D1)
  },
};
```

> **Liveness (INV-7):** `component: Button` + no custom `render` ⇒ SB renders `<Button {...args} />`, so the spy
> reaches the rendered `onClick` automatically — a click logs to the Actions panel. If a story has a **custom
> `render`**, it MUST pass `onClick={args.onClick}` (or `{...args}`) — a spy in `args` that never reaches a
> rendered handler is a no-op (a LOUD failure). Verify `Link.stories.tsx`'s render.

## The variant-audit recipe (D1 — VERIFY-only; the audit is ALREADY complete)

**All three stories already expose their full exported-union surface (mx.4) — this recipe is VERIFY, not
top-up.** The confirmed arrays below already exist in each `.stories.tsx`, typed by the exported literal union
(an invented member fails `sb:typecheck`); slots/handlers are already `control: false`; booleans are already
`control: "boolean"`; the mx.4 grids are kept. **The only per-story edit is D2's `fn()` spy.** Confirm the
existing arrays match:

```tsx
// Button.stories.tsx (EXISTS — CONFIRMED full): ButtonVariant has 6 members incl. "inverse".
const VARIANTS: ButtonVariant[] = ["primary","secondary","outline","ghost","destructive","inverse"];
const SIZES: ButtonSize[] = ["sm","md","lg"];
// argTypes already: variant→select, size→inline-radio, loading/fullWidth/disabled→boolean,
//                   leading/trailing→control:false.  ADD (D2): onClick→control:false.

// IconButton.stories.tsx (EXISTS — CONFIRMED full):
const IB_VARIANTS: IconButtonVariant[] = ["primary","secondary","outline","ghost","destructive"];
const IB_SIZES: IconButtonSize[] = ["sm","md","lg"];
const IB_SHAPES: IconButtonShape[] = ["circle","square"];
// argTypes already: variant/size/shape→inline-radio, disabled→boolean,
//                   icon→select (curated glyph list; IconName widens to string — MANUAL NO-INVENT),
//                   label→text.  ADD (D2): onClick→control:false.

// Link.stories.tsx (EXISTS — CONFIRMED full):
const SIZES_L: LinkSize[] = ["sm","md"];
const TYPES: NonNullable<LinkProps["type"]>[] = ["button","submit","reset"];
// argTypes already: size→inline-radio, type→inline-radio, muted/disabled→boolean,
//                   href/target/rel/aria-label/children→text, leading/trailing/onClick→control:false.
//                   (onClick ALREADY control:false — D2 only adds args:{ onClick: fn() }.)
```

> If a build re-probe surfaces a genuine gap (an added union member since mx.4), top it up + FLAG it — but the
> reconcile this rung found **none**.

## The scene recipe (D3 — host-home, actions-led, cited)

CSF3, `title: "Scenes/<Name>"`, no `component:` field (the mx.8.1 scene shape). Compose ONLY real `@mercury/ui`
exports; the actions components LEAD; imports only `@mercury/ui` (+ `react`/`@storybook/react-vite`) — no
`@mercury/effector`, no app import, no `window.MercuryUI`/`_ds_bundle`. Do not collide with
`Scenes/Profile`/`Scenes/Article`.

**The scene is a FORK the Director ratifies (name + roster) — build it only after the ruling.** Venus
recommends `Scenes/Confirm` (alternative `Scenes/Wallet`; see `mx.8.2.md` §D3). Write-ready skeleton for the
recommendation:

```tsx
// apps/storybook/stories/scenes/Confirm.stories.tsx
import type { Meta, StoryObj } from "@storybook/react-vite";
import { Badge, Button, Card, Divider, Heading, IconButton, Link, Text } from "@mercury/ui";
// Scenes/Confirm — a confirmation / action-sheet where the ACTIONS lead: an IconButton header toolbar
// (icon-only — its natural usage), a Heading + summary Text of what is being confirmed (presentational,
// NO inputs — inputs are a later slice), a footer Button action bar showing the variant spread
// (primary·outline·ghost·destructive), and Link affordances. Grounded in
// apps/mobile/src/screens/Send.tsx:56-63 (the real outline "Cancel" + primary "Send $X" footer action bar)
// + apps/mobile/src/screens/Home.tsx:33 (the inline "See all" <a onClick> → Link). Presentational; imports
// only @mercury/ui. NO-INVENT: every IconButton `icon` (close · copy · cog) is a real curated glyph; compose
// each component per its .tsx/.prompt.md surface; pass only real props.
const meta: Meta = { title: "Scenes/Confirm" };
export default meta;
export const Confirm: StoryObj = { render: () => (/* header: Heading "Confirm transfer" + an IconButton
  toolbar (close·copy·cog); a Card with a Text summary ("$420.00 to Ana Ruiz") + a Badge "Instant" + a
  Divider; a footer action bar: Button primary "Confirm & send" · outline "Cancel" · ghost "Save as draft" ·
  destructive "Cancel transfer"; a Link "Change recipient" + a muted Link "How fees work" */ null) };
```

Ground each composed export (`Badge`/`Button`/`Card`/`Divider`/`Heading`/`IconButton`/`Link`/`Text`) against
its `.tsx`/`.prompt.md` before use — pass only real props (`IconButton` needs `icon` + `label`). A scene may
hold local `useState` for demo interactivity but imports only `@mercury/ui`. Replace the `null` render body with
the real composition. (The `fn()` spy is a per-story concern, D2 — a scene needs no spy.)

## Agent stories

- **mx.8.2-AS1** `[implements mx.8.2-US1]` — **Directive:** expose the full exported-union control surface on
  the three actions stories per the audit recipe. **Acceptance gate:** *pre* — options typed by the real
  exported unions; *post* — `sb:typecheck` 0, a bogus literal-union option fails typecheck; *invariant* — slots
  `control:false`, barrel diff empty, mx.4 grids kept.
- **mx.8.2-AS2** `[implements mx.8.2-US2]` — **Directive:** wire the zero-dep `fn()` spy on each `meta`.
  **Acceptance gate:** *pre* — `import { fn } from "storybook/test"` (core, no dep add); *post* — the running
  SB logs an Actions-panel entry on a click of each spied control (INV-7); *invariant* — no
  `package.json`/`pnpm-lock.yaml`/`main.ts` change (INV-6).
- **mx.8.2-AS3** `[implements mx.8.2-US3]` — **Directive:** author ≥1 host-home actions-led scene, cited, real
  exports only. **Acceptance gate:** *post* — `sb:build` registers `Scenes/<Name>`; the hex/bundle/effector
  greps over `stories/scenes` empty; *invariant* — no non-`@mercury/ui` runtime import; no `Scenes/*` collision.
- **mx.8.2-AS4** `[implements mx.8.2-US4]` — **Directive:** run the full gate; prove liveness; prove zero-dep;
  re-confirm the inherited globals. **Acceptance gate:** *post* — the gate ladder exits 0, the barrel diff
  empty, INV-7 positive (each spy fires), INV-6 holds (`fn` resolves core, no manifest in the diff), Palette=green
  ⇒ Button `rgb(48,164,108)` on the actions surface (`preview.tsx` unedited).

## Execution plan — first steps (write-ready)

1. **AS1 + AS2 together (per-story, three files).** For each of `Button` / `IconButton` / `Link`
   `<Name>.stories.tsx`: add `import { fn } from "storybook/test";`, add `args: { onClick: fn() }` to `meta`,
   and add the full-union `argTypes` (import the exported union types; type each options array by its union;
   slots/handlers `control:false`, booleans `control:"boolean"`). Run `pnpm sb:typecheck` → 0. Start
   `pnpm sb:dev`; on each story, click the rendered control and confirm an entry appears in the Actions panel
   (INV-7); a no-op spy FAILS here — fix (check the render wiring) before proceeding. Confirm the barrel diff is
   empty.
2. **AS3 (the scene).** Author the ratified actions-led scene under `apps/storybook/stories/scenes/`; compose
   only real `@mercury/ui` exports (ground each against its `.tsx`/`.prompt.md`); add the cited-screen lead
   comment. Run `pnpm sb:build` → registers `Scenes/<Name>`; the hex/bundle greps empty.

Then AS4 (the full gate + the zero-dep resolve + the inherited-globals re-confirm).

## The gate (run from `mercury/`, all EXIT 0)

```bash
pnpm sb:typecheck                                               # host tsc — the NO-INVENT gate
pnpm --filter "./packages/*" typecheck                         # packages clean
pnpm --filter "./packages/*" build                             # packages build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build  # product apps build (glob-driven)
pnpm sb:build                                                  # static build; prior homes unchanged + Scenes/<Name>

# barrel BYTE-IDENTICAL (master invariant) — expect EMPTY:
diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts

# surface frozen — only actions *.stories.tsx under mercury-ui; the scene under apps/storybook; the rest is docs:
git diff --name-only

# ZERO-DEP (Fork-5 resolution) — no dependency manifest in the diff (expect EMPTY) + fn resolves as SB core:
git diff --name-only -- apps/storybook/package.json pnpm-lock.yaml apps/storybook/.storybook/main.ts
node -e "require.resolve('storybook/test'); require.resolve('storybook/actions'); console.log('core-ok')"
grep -rn "storybook/test" packages/mercury-ui/src/components/actions/*/*.stories.tsx   # exactly the core subpath

# preview.tsx UNEDITED (inherited globals) — expect EMPTY:
git diff --name-only -- apps/storybook/.storybook/preview.tsx

# NO-INVENT / token / design-sync greps — expect EMPTY:
grep -rnE "#[0-9a-fA-F]{3,8}\b" apps/storybook/stories/scenes packages/mercury-ui/src/components/actions/*/*.stories.tsx
grep -rn "window.MercuryUI\|_ds_bundle\|design-sync\|DesignSync" apps/storybook/stories packages/mercury-ui/src/components/actions

# INV-7 liveness (a wired-but-dead spy FAILS) — by inspection in the running SB (pnpm sb:dev):
#   click each spied Button/IconButton/Link ⇒ an entry appears in the core Actions panel
# Inherited-globals re-confirm (mx.8.1-INV6 inherited) — via getComputedStyle in sb:dev:
#   Palette=green ⇒ Button(variant="primary") backgroundColor rgb(48, 164, 108)   [preview.tsx unedited]
```

## Comprehensive implementation prompt

```
Build the mx.8.2 actions slice of the mx.8 Storybook enrichment, per mx.8.2.md (authoritative) and the recipes
above. Root = mercury/. Edit EXACTLY: packages/mercury-ui/src/components/actions/{Button,IconButton,Link}/
<Name>.stories.tsx (expose the full exported-union control surface — type each options array by the exported
literal union; slots/handlers control:false, booleans control:"boolean"; keep the mx.4 grid/state stories — AND
wire the zero-dep fn() spy: `import { fn } from "storybook/test";` + args:{ onClick: fn() } on each meta, reaching
the rendered handler); apps/storybook/stories/scenes/<Name>.stories.tsx (NEW — ≥1 host-home actions-led scene
composing only real @mercury/ui exports, citing a real screen/pattern in a lead comment, title:"Scenes/<Name>"
no component field, no collision with Scenes/Profile|Article). The @mercury/ui barrel is BYTE-IDENTICAL to HEAD;
the ONLY packages/mercury-ui/src/** edits are actions/*/*.stories.tsx; DO NOT edit preview.tsx (the mx.8.1
Palette/Roundings globals are inherited host-wide), main.ts, package.json, pnpm-lock.yaml, any component
.tsx/index.ts/.prompt.md/styles. Add NO dependency (fn + the Actions panel are SB 10.4.6 core — storybook/test
and storybook/actions resolve as core subpaths). NO-INVENT: every prop/enum/token/Icon-name is real (traced from
the .tsx); design flows DOWN (no /design-sync, no window.MercuryUI/_ds_bundle). Run the full gate from mercury/
(sb:typecheck, packages typecheck+build, apps build minus storybook, sb:build), the barrel byte-identical diff,
the zero-dep resolve (require.resolve storybook/test + storybook/actions) + no-manifest diff, the
NO-INVENT/hex/design-sync greps, and — in pnpm sb:dev — the INV-7 running-SB liveness (a click on each spied
Button/IconButton/Link logs a core Actions-panel entry; a wired-but-dead spy is a LOUD failure) and the
inherited-globals re-confirm (Palette=green ⇒ Button rgb(48,164,108), preview.tsx unedited). Framing: no gendered
pronouns for agents; no perceptual/interior-state verbs on software (components render/resolve/fire/log/compose);
no first person. Report the gate output, the barrel-diff result, the zero-dep resolve result, the INV-7 observed
Actions-panel entries, and the exact touched-files diff. Run no git.
```
