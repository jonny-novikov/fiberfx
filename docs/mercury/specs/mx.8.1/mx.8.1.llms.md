# mx.8.1 — build brief (for the implementor)

Working notes for building [`mx.8.1.md`](./mx.8.1.md) — the Storybook enrichment **foundations slice** (the
Palette + Roundings brand-only globals · the foundations variant audit · ≥2 foundations-in-context scenes ·
the book-wide gate). Root = `mercury/`. The body is authoritative; this derives from it and from the parent
epic [`../mx.8/mx.8.md`](../mx.8/mx.8.md) (§6 recipes, §7 invariants). **This brief is write-ready** — the
exact code is inlined below, so the first actions are writes, not a subsystem read. **NO-INVENT:** every
ramp/radius/token/prop name here is a live name traced from source (verified this rung).

**The `@mercury/ui` barrel + every component file is FROZEN.** The only `packages/mercury-ui/src/**` edits are
`components/foundations/*/*.stories.tsx`. Everything else is `apps/storybook/**`. No actions dep (K-4 deferred).

## References (read first — capped at these; the code is below)

1. [`mx.8.1.md`](./mx.8.1.md) — the authoritative body (Deliverables D1–D5, Invariants INV1–INV8, the ruled
   decisions).
2. The live host to EXTEND: `apps/storybook/.storybook/preview.tsx` — the `withTheme` decorator + the `theme`
   `globalType` (the exact pattern the two new globals generalize). ~50 lines; the whole file's shape is
   reproduced in the recipe below.
3. The parent mechanism (reference, do not re-derive): [`../mx.8/mx.8.md`](../mx.8/mx.8.md) §6.1 (palette
   table) / §6.2 (roundings) / §7 (invariants). The brand-only palette table below is the grounded,
   **complete** version (adds `--fg-brand-hover`, found in `tokens.css`).
4. The variant-audit exemplar: `packages/mercury-ui/src/components/actions/Button/Button.stories.tsx` (the
   typed-union `argTypes` shape) — and the host-home cross-cutting `apps/storybook/stories/Tokens.stories.tsx`
   (the no-`component` `title:`-only shape the scenes follow).
5. The five foundations stories to audit + their `.tsx` (the exported unions are truth):
   `packages/mercury-ui/src/components/foundations/{Icon,Heading,Text,Divider,Separator}/<Name>.{tsx,stories.tsx}`.
6. The scene grounding (read-only): `apps/mobile/src/screens/Profile.tsx` +
   `packages/mercury-ds/project/ui_kits/mercury_app/screens.jsx` (the `ProfileScreen` + the display-type screen
   headers).

## Ground facts (verified this rung — trust, then re-probe at build)

- **Stack:** Vite ^6, React 19, Node 22.18, pnpm 10.17.1, TypeScript ^5.6.3. `verbatimModuleSyntax: true` (use
  `import type` for types), `strict` + `noUncheckedIndexedAccess`.
- **The host IS edited this rung** (a toolbar global needs a `preview.tsx` change) — in scope. What stays
  frozen is the `@mercury/ui` surface. `main.ts` needs **no** glob edit (its `"../stories/**/*.stories.@(tsx|ts)"`
  already spans `stories/scenes/**`).
- **`sb:typecheck` is the authoritative NO-INVENT gate** — the host `tsc` is the only one that checks the
  enriched stories + scenes (the library `tsc` excludes `**/*.stories.tsx`).
- **Palette grounding (the 9 real brand aliases, from `tokens.css`).** `--bg-brand: var(--iris-9)` ·
  `--bg-brand-hover: var(--iris-10)` · `--bg-brand-pressed: var(--iris-11)` · `--bg-brand-subtle: var(--iris-3)`
  · `--bg-brand-muted: var(--iris-4)` · `--fg-brand: var(--iris-11)` · `--fg-brand-hover: var(--iris-10)` ·
  `--border-brand: var(--iris-9)` · `--fg-on-brand: var(--slate-1)`. **Ramp step coverage:** `iris`/`indigo`
  ship full 1–12; **`green`/`orange`/`plum`/`red` ship ONLY `-3`/`-9`/`-11`** — no `-10`, no `-4`. A remap to
  `--green-10`/`--plum-4` is an undefined property → broken color. Use the fallbacks in the table below.
  **Brand-only:** do NOT re-point the `--bg-active` family (iris = identity / indigo = interaction).
- **Roundings grounding.** The scale is `--radius-2/4/6/8/12/16/20/24/32/full` — no `--radius` base. Override
  only `--radius-2 … --radius-32`; **never** `--radius-full` (`9999px` — avatars/switches/chips read it).
- **INV-6 render triplets (exact).** `--bg-brand` default = iris-9 = `rgb(91, 91, 214)`; green-9 =
  `rgb(48, 164, 108)`. `--radius-8` = `8px`; `--radius-full` = `9999px`. The probes are book-wide surfaces
  (`Button variant="primary"` reads `--bg-brand`; `Card` reads `--radius-8`; `Avatar` reads `--radius-full`) —
  all three are shipped barrel exports. The foundations primitives do **not** read the brand/radius families,
  so a bare foundations story shows NO change under Palette/Roundings BY DESIGN — probe Button/Card/Avatar.
- **Foundations surfaces (the audit truth).** `HeadingSize` (1–9), `HeadingWeight`, `HeadingAlign`, **`HeadingTag`**
  (`h1`…`h6`|`div`), Heading `accent` (`iris`|`indigo`|`green`|`orange`|`plum`|`red`) — all exported literal
  unions. `TextVariant` (11 members) + Text `accent` (same 6). `SeparatorOrientation`. `DividerProps["orientation"]`
  (inline union — no standalone type). **`IconName = keyof (ICONS: Record<string, ReactNode>)` widens to
  `string`** — the illusory gate: an invented icon name type-checks, so the `ICON_NAMES` array is a MANUAL
  set-equality check against the `ICONS` keys (38 glyphs).
- **The one real audit gap:** the Heading story is MISSING the `as`/`HeadingTag` control (size=9 ✓, accent=6 ✓);
  Text/Icon/Divider/Separator are already full-union complete (verify, top up only if a gap surfaces at build).
- **Actions util NOT installed** and NOT needed this rung — K-4 deferred (foundations declare no `on[A-Z]`
  handler). Add no dep.

## Requirements

- **mx.8.1-R1** — extend `apps/storybook/.storybook/preview.tsx` with a `palette` `globalType` + the brand-only
  `--bg-brand`-family remap on the wrapper, using only steps the chosen ramp defines; `--bg-active` untouched;
  `Brand (iris)` default = no override. [US: mx.8.1-US1]
- **mx.8.1-R2** — extend `preview.tsx` with a `radius` `globalType` + the `--radius-2 … --radius-32` override
  (Sharp/Default/Round); `--radius-full` never overridden. [US: mx.8.1-US2]
- **mx.8.1-R3** — add the `as`/`HeadingTag` control to `Heading.stories.tsx`; verify Text/Icon/Divider/Separator
  expose their full exported-union surface; correct the Icon `name` NO-INVENT comment (manual set-equality, not
  a compile error). [US: mx.8.1-US3]
- **mx.8.1-R4** — add ≥2 host-home `apps/storybook/stories/scenes/*.stories.tsx`, foundations-led, composing
  only real `@mercury/ui` exports, each with a lead comment citing a real screen/pattern. [US: mx.8.1-US4]
- **mx.8.1-R5** — the full gate ladder exits 0; the barrel diff is empty; the NO-INVENT/partial-ramp/handler
  greps are empty; the INV-6 render-check is POSITIVE on Button/Card/Avatar. [US: mx.8.1-US5]

## Execution topology

```text
runtime — the Storybook host (apps/storybook) resolves @mercury/ui FROM SOURCE (vite alias + tsconfig paths).
  preview.tsx: `decorators: [withTheme]` wraps EVERY story in one scoped `${theme}-theme` <div>. The two new
  globals (palette, radius) feed extra CSS-custom-property overrides onto that same wrapper's inline `style`,
  so every descendant story re-skins with zero per-story edit (exactly how `.dark-theme` overrides the ramps).
  The scenes register via main.ts's existing `stories/**` glob (no glob edit). Nothing touches @mercury/ui.
```

```text
tasks (build-order DAG)
  T1  preview.tsx: add palette+radius to initialGlobals+globalTypes; extend withTheme with paletteVars()+
      radiusVars()  ── (D1,D2) ──►  gate: sb:typecheck 0 ; INV-6 render-check (green⇒rgb(48,164,108);
                                    Sharp⇒Card 0px, Avatar 9999px)
  T2  Heading.stories.tsx: +`as` control (HeadingTag) ; Icon.stories.tsx: fix the NO-INVENT comment ;
      verify Text/Divider/Separator full-union  ── (D3) ──►  gate: sb:typecheck 0 ; barrel-diff empty
  T3  stories/scenes/Profile.stories.tsx + Article.stories.tsx (NEW, ≥2)  ── (D4) ──►  gate: sb:build
      registers Scenes/* ; hex/bundle/effector greps empty
  T4  full gate + barrel byte-identical + partial-ramp + handler greps + INV-6 book-wide  ── (D5) ──►  ship
```

`Touched files:` `apps/storybook/.storybook/preview.tsx` (EXTEND) · `packages/mercury-ui/src/components/foundations/Heading/Heading.stories.tsx` (add `as`) · `packages/mercury-ui/src/components/foundations/Icon/Icon.stories.tsx` (comment) · `apps/storybook/stories/scenes/Profile.stories.tsx` (NEW) · `apps/storybook/stories/scenes/Article.stories.tsx` (NEW) · `docs/mercury/specs/mx.8.1/` (this triad). **Verify-only (no expected edit; top up + flag if a gap surfaces):** `foundations/{Text,Divider,Separator}/<Name>.stories.tsx`. **Frozen:** `packages/mercury-ui/src/index.ts` · any component `.tsx`/`index.ts`/`.prompt.md`/`styles/**` · `.storybook/main.ts` · `apps/storybook/package.json` · `pnpm-lock.yaml`.

## The decorator recipe (extend `withTheme` — one wrapper, three globals)

Add `import type { CSSProperties } from "react";` (Separator.tsx uses this idiom). Keep the existing
`background`/`color`/`minHeight`/`padding`/`fontFamily` lines; merge the palette + radius overrides into the
same `style`:

```tsx
type Ramp = "iris" | "indigo" | "green" | "orange" | "plum" | "red";
const HAS_10: Ramp[] = ["iris", "indigo"]; // the only ramps that ship a -10 step (tokens.css)

// Brand-only palette re-skin (grounded in tokens.css; iris = default ⇒ no override).
// Uses only steps the ramp defines: -3/-9/-11 for all six; -10 for iris/indigo, else the -9 fallback.
function paletteVars(palette: string): Record<string, string> {
  if (!palette || palette === "iris") return {};
  const R = palette as Ramp;
  const hover = HAS_10.includes(R) ? `rgb(var(--${R}-10))` : `rgb(var(--${R}-9))`;
  return {
    "--bg-brand": `rgb(var(--${R}-9))`,
    "--bg-brand-hover": hover,
    "--bg-brand-pressed": `rgb(var(--${R}-11))`,
    "--bg-brand-subtle": `rgb(var(--${R}-3))`,
    "--bg-brand-muted": `rgb(var(--${R}-3))`,   // no -4 for status ramps → -3
    "--fg-brand": `rgb(var(--${R}-11))`,
    "--fg-brand-hover": hover,
    "--border-brand": `rgb(var(--${R}-9))`,
    "--fg-on-brand": R === "orange" ? "rgb(var(--slate-12))" : "rgb(var(--slate-1))",
    // NB: DO NOT re-point the --bg-active family (brand-only; interaction stays indigo).
  };
}

// Roundings (values = latitude; the mechanism is fixed). Default = no override; --radius-full NEVER touched.
const RADIUS_STEPS = [2, 4, 6, 8, 12, 16, 20, 24, 32] as const;
const ROUND: Record<(typeof RADIUS_STEPS)[number], string> =
  { 2: "4px", 4: "8px", 6: "12px", 8: "14px", 12: "20px", 16: "26px", 20: "32px", 24: "38px", 32: "48px" };
function radiusVars(radius: string): Record<string, string> {
  if (radius === "sharp") return Object.fromEntries(RADIUS_STEPS.map((n) => [`--radius-${n}`, "0px"]));
  if (radius === "round") return Object.fromEntries(RADIUS_STEPS.map((n) => [`--radius-${n}`, ROUND[n]]));
  return {}; // default — live values
}

const withTheme: Decorator = (Story, context) => {
  const theme = context.globals.theme === "dark" ? "dark" : "light";
  const palette = String(context.globals.palette ?? "iris");
  const radius = String(context.globals.radius ?? "default");
  return (
    <div
      className={`${theme}-theme`}
      style={{
        background: "rgb(var(--bg-primary))",
        color: "rgb(var(--fg-primary))",
        minHeight: "100vh",
        padding: "24px",
        fontFamily: "var(--font-primary)",
        ...paletteVars(palette),
        ...radiusVars(radius),
      } as CSSProperties}
    >
      <Story />
    </div>
  );
};
```

Then extend `initialGlobals` + `globalTypes` (keep the `theme` global as-is):

```tsx
initialGlobals: { theme: "light", palette: "iris", radius: "default" },
globalTypes: {
  theme: { /* unchanged */ },
  palette: {
    description: "Brand ramp — re-skins the --bg-brand family (brand-only; interaction stays indigo)",
    toolbar: { title: "Palette", icon: "paintbrush", dynamicTitle: true, items: [
      { value: "iris", title: "Brand (iris)" }, { value: "indigo", title: "Indigo" },
      { value: "green", title: "Green" }, { value: "orange", title: "Orange" },
      { value: "plum", title: "Plum" }, { value: "red", title: "Red" },
    ] },
  },
  radius: {
    description: "Roundings — re-scales --radius-2…-32 (--radius-full preserved)",
    toolbar: { title: "Roundings", icon: "grid", dynamicTitle: true, items: [
      { value: "sharp", title: "Sharp" }, { value: "default", title: "Default" }, { value: "round", title: "Round" },
    ] },
  },
},
```

> Toolbar `icon` ids (`paintbrush`/`grid`) are cosmetic — any valid `@storybook/icons` id; verify against the
> installed Storybook 10 at build (the `theme` global uses `"mirror"`). Not load-bearing.

## The variant-audit recipe (D3 — top up the ONE gap; verify the rest)

Heading.stories.tsx — add `HeadingTag` to the type import + a `TAGS` array + the `as` argType:

```tsx
import type { HeadingProps, HeadingSize, HeadingTag, HeadingWeight } from "@mercury/ui";
const TAGS: HeadingTag[] = ["h1", "h2", "h3", "h4", "h5", "h6", "div"];
// …in argTypes, beside align:
as: { control: "select", options: TAGS }, // the render tag (HeadingTag) — the one mx.8.1 gap
```

Icon.stories.tsx — correct the misleading NO-INVENT comment (the array is already the full set):

```tsx
// The full IconName set, traced from Icon.tsx (the ICONS keys) and restated in Icon.prompt.md.
// NO-INVENT (mx.8.1-INV8): IconName = keyof (ICONS: Record<string, ReactNode>) widens to `string`,
// so an unknown name is NOT a compile error — this array is verified against the ICONS keys by
// hand (set-equality), not the type.
```

Text (`TextVariant` 11 + accent 6), Divider (`orientation` + `label`), Separator (`orientation` + `label` +
`decorative`) — VERIFY full-union coverage; they are already complete (no edit expected). Keep every mx.4
grid/state story (`Sizes`/`Accents`/`Variants`/`Gallery`/`States`).

## The scenes recipe (D4 — host-home, foundations-led, cited)

CSF3, `title: "Scenes/<Name>"`, no `component:` field (the `Tokens` shape). Compose ONLY real `@mercury/ui`
exports; a scene may hold local `useState` for demo interactivity but imports only `@mercury/ui`
(+ `react`/`@storybook/react-vite`) — no `@mercury/effector`, no app import, no `window.MercuryUI`/`_ds_bundle`.
The foundations primitives LEAD; Card/ListRow/Badge/Avatar/Button add realism. Two grounded scenes:

```tsx
// apps/storybook/stories/scenes/Profile.stories.tsx
import type { Meta, StoryObj } from "@storybook/react-vite";
import { Avatar, Badge, Button, Card, Heading, Icon, ListRow, Separator, Text } from "@mercury/ui";
// Scenes/Profile — a profile/account screen where the foundations LEAD: the name Heading, the
// "Verified · Member since 2023" Text, Separator section rules, and inline Icon affordances; Avatar/
// Card/ListRow/Badge/Button add realism. Grounded in apps/mobile/src/screens/Profile.tsx +
// packages/mercury-ds/project/ui_kits/mercury_app/screens.jsx (ProfileScreen). Presentational; imports
// only @mercury/ui. NO-INVENT: every Icon name (shield · credit-card · bell · globe · help-circle) is a
// real ICONS key; compose each component per its .tsx/.prompt.md surface.
const meta: Meta = { title: "Scenes/Profile" };
export default meta;
export const Profile: StoryObj = { render: () => (/* header: Avatar + Heading + Text + Badge; Card of
  ListRows each with a leading <Icon name="…" />; Separator rules; a ghost Button "Sign out" */ null) };
```

```tsx
// apps/storybook/stories/scenes/Article.stories.tsx
import type { Meta, StoryObj } from "@storybook/react-vite";
import { Badge, Blockquote, Callout, Code, Divider, Heading, Icon, Separator, Text } from "@mercury/ui";
// Scenes/Article — a long-form editorial/doc layout where the foundations LEAD: a display Heading title,
// a `lead` Text intro, section Headings, `body`/`quote`/`code` Text, Divider label section breaks, and an
// Icon-led inline note; Blockquote/Callout/Badge/Code add realism. Grounded in the editorial variant set
// the foundations document (foundations/Text + Heading stories: display/lead/body/quote/code, the display
// size scale) + the display-type screen headers in
// packages/mercury-ds/project/ui_kits/mercury_app/screens.jsx (the var(--font-display) title pattern).
const meta: Meta = { title: "Scenes/Article" };
export default meta;
export const Article: StoryObj = { render: () => (/* Heading size=8 title; Text variant="lead"; section
  Heading + body/quote/code Text; Divider label="…"; an Icon + Callout note */ null) };
```

Ground each composed component (`Avatar`/`Badge`/`Button`/`Card`/`ListRow`/`Callout`/`Blockquote`/`Code`)
against its `.tsx`/`.prompt.md` before use — pass only real props. Replace the `null` render bodies with the
real composition.

## Agent stories

- **mx.8.1-AS1** `[implements mx.8.1-US1]` — **Directive:** add the `palette` global + `paletteVars()` per the
  recipe. **Acceptance gate:** *pre* — only ramp steps that exist (`-3`/`-9`/`-11`, `-10` iris/indigo only);
  *post* — `sb:typecheck` 0, the partial-ramp grep empty, INV-6 green ⇒ `rgb(48,164,108)`; *invariant* —
  `--bg-active` unchanged.
- **mx.8.1-AS2** `[implements mx.8.1-US2]` — **Directive:** add the `radius` global + `radiusVars()`.
  **Acceptance gate:** *post* — INV-6 Sharp ⇒ Card `0px` while Avatar stays `9999px`; *invariant* —
  `--radius-full` never in the override object.
- **mx.8.1-AS3** `[implements mx.8.1-US3]` — **Directive:** add Heading's `as` control; fix the Icon comment;
  verify the other three. **Acceptance gate:** *post* — `sb:typecheck` 0; a bogus literal-union option fails
  typecheck; the Icon set-equality (ICON_NAMES vs ICONS keys) is empty; *invariant* — barrel diff empty.
- **mx.8.1-AS4** `[implements mx.8.1-US4]` — **Directive:** author ≥2 host-home scenes, foundations-led, cited,
  real exports only. **Acceptance gate:** *post* — `sb:build` registers `Scenes/Profile` + `Scenes/Article`;
  the hex/bundle/effector greps over `stories/scenes` empty; *invariant* — no non-`@mercury/ui` runtime import.
- **mx.8.1-AS5** `[implements mx.8.1-US5]` — **Directive:** run the full gate; prove liveness; prove the
  deferral. **Acceptance gate:** *post* — the gate ladder exits 0, the barrel diff empty, INV-6 positive on
  Button/Card/Avatar, the foundations-handler grep empty and no actions dep added.

## Execution plan — first two stories (write-ready)

1. **AS1 + AS2 together (one `preview.tsx` edit).** Open `apps/storybook/.storybook/preview.tsx`; add
   `import type { CSSProperties } from "react";`; paste `paletteVars`/`radiusVars`/`HAS_10`/`RADIUS_STEPS`/
   `ROUND` above `withTheme`; spread `...paletteVars(palette)` + `...radiusVars(radius)` into the wrapper
   `style` (cast `as CSSProperties`); add `palette`+`radius` to `initialGlobals` + `globalTypes`. Run
   `pnpm sb:typecheck` → 0. Start `pnpm sb:dev`, pick `Palette = green` on a `Button` story, probe
   `getComputedStyle(button).backgroundColor === "rgb(48, 164, 108)"`; pick `Roundings = Sharp` on a `Card`,
   probe `0px`, and on an `Avatar`, probe `9999px`. A no-op decorator FAILS here — fix before proceeding.
2. **AS3 (the audit).** Edit `Heading.stories.tsx` (add `HeadingTag` import + `TAGS` + the `as` argType) and
   `Icon.stories.tsx` (the comment). Run `pnpm sb:typecheck` → 0; run the barrel diff → empty. Read
   Text/Divider/Separator stories; confirm full-union; if all complete, no edit (flag any gap you top up).

Then AS4 (the two scenes) and AS5 (the full gate).

## The gate (run from `mercury/`, all EXIT 0)

```bash
pnpm sb:typecheck                                               # host tsc — the NO-INVENT gate
pnpm --filter "./packages/*" typecheck                         # packages clean
pnpm --filter "./packages/*" build                             # packages build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build  # product apps build (glob-driven; set reconciled at build)
pnpm sb:build                                                  # static build; prior homes unchanged + Scenes/Profile + Scenes/Article

# barrel BYTE-IDENTICAL (master invariant, strongest form) — expect EMPTY:
diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts

# surface frozen — only foundations *.stories.tsx under mercury-ui; the rest is apps/storybook + docs:
git diff --name-only

# NO-INVENT / token / design-sync / partial-ramp greps — expect EMPTY:
grep -rnE "#[0-9a-fA-F]{3,8}\b" apps/storybook/stories/scenes apps/storybook/.storybook
grep -rn "window.MercuryUI\|_ds_bundle\|design-sync\|DesignSync" apps/storybook/stories apps/storybook/.storybook
grep -rnE "\-\-(green|orange|plum|red)-(10|4)\b" apps/storybook/.storybook

# K-4 deferral is grounded — no foundations interaction handler, no actions dep — expect EMPTY:
grep -rnE "on[A-Z][A-Za-z]*\??:" packages/mercury-ui/src/components/foundations/*/*.tsx
git diff --name-only -- apps/storybook/package.json pnpm-lock.yaml apps/storybook/.storybook/main.ts

# Icon set-equality (IconName widens to `string` — a MANUAL gate, not typecheck) — expect EMPTY diff:
#   compare the ICON_NAMES array members to the ICONS object keys (sort -u both, diff)

# INV-6 render-check (gate-liveness; a no-op FAILS) — via a play function / getComputedStyle probe:
#   Palette=green ⇒ Button(primary) backgroundColor rgb(48, 164, 108)  [not iris rgb(91, 91, 214)]
#   Roundings=Sharp ⇒ Card borderRadius 0px  AND  Avatar borderRadius 9999px
```

## Comprehensive implementation prompt

```
Build the mx.8.1 foundations slice of the mx.8 Storybook enrichment, per mx.8.1.md (authoritative) and the
recipes above. Root = mercury/. Edit EXACTLY: apps/storybook/.storybook/preview.tsx (EXTEND — add the palette
+ radius globalTypes and generalize withTheme with paletteVars()/radiusVars(), brand-only, --bg-active and
--radius-full untouched); packages/mercury-ui/src/components/foundations/Heading/Heading.stories.tsx (add the
`as`/HeadingTag control); packages/mercury-ui/src/components/foundations/Icon/Icon.stories.tsx (correct the
NO-INVENT comment — IconName widens to string, so `name` is manually verified, not a compile error);
apps/storybook/stories/scenes/Profile.stories.tsx and Article.stories.tsx (NEW — ≥2 host-home foundations-led
scenes composing only real @mercury/ui exports, each citing a real screen/pattern in a lead comment). VERIFY
Text/Divider/Separator stories are full-union complete (top up + flag only if a gap surfaces). The @mercury/ui
barrel is BYTE-IDENTICAL to HEAD; the ONLY packages/mercury-ui/src/** edits are foundations/*/*.stories.tsx;
add NO actions dependency (K-4 deferred — foundations declare no on[A-Z] handler); do NOT touch main.ts,
package.json, pnpm-lock.yaml, any component .tsx/index.ts/.prompt.md/styles, or the --bg-active/--radius-full
tokens. NO-INVENT: every ramp/radius/token/prop/Icon-name is real (traced from source); never emit
--(green|orange|plum|red)-(10|4); design flows DOWN (no /design-sync, no window.MercuryUI/_ds_bundle). Run the
full gate from mercury/ (sb:typecheck, packages typecheck+build, apps build minus storybook, sb:build), the
barrel byte-identical diff, the NO-INVENT/partial-ramp/handler greps, the Icon set-equality, and the INV-6
book-wide render-check (Palette=green ⇒ Button rgb(48,164,108); Roundings=Sharp ⇒ Card 0px + Avatar 9999px — a
no-op decorator is a LOUD failure). Framing: no gendered pronouns for agents; no perceptual/interior-state
verbs on software (components re-skin/override/resolve/compute/render); no first person. Report the gate
output, the barrel-diff result, the INV-6 measured values, and the exact touched-files diff. Run no git.
```
