# MX.8 · Storybook enrichment — palette · roundings · variant switching · actions · real-world scenes

> **Status: 📐 SPECCED — SOLID-FORWARD (authored 2026-06-29, NOT built).** The third rung of the
> **Movement-III tail** (mx.7 import · **mx.8 stories** · mx.9 showcase). mx.8 **enriches** the stories the
> earlier rungs authored — it does **not** write the first ones. mx.3 landed the **host**
> (`apps/storybook/`, Storybook 10.4.6, source-resolved, a light/`dark-theme` toolbar global + a scoped
> wrapper decorator); mx.4 gave **every** live component a co-located `<Name>.stories.tsx` (typed-union
> `argTypes` + a Playground + a grid); mx.5 added the host-home **effector** stories. mx.7 (4 batches,
> 7.1–7.4) imports the 31 net-new Claude-Design components into `@mercury/ui`, each with its **basic**
> mx.4-shape story. **mx.8 ladders behind the completed mx.7.4** and adds the five enrichment dimensions
> the Operator named: **palette switching · roundings switching · variant switching · actions ·
> example real-world usage.**
>
> **This triad is SOLID-FORWARD and is RE-SHARPENED at its own ship.** It is authored now so the ladder
> is legible, but the exact **library inventory** (the post-mx.7.4 component set + barrel size), the
> **product-app list**, and the **scene roster** are reconciled against the as-built tree at ship — mx.7
> is not yet built, so this body pins **mechanism and contract**, not counts. Every count below is written
> as "reconciled at ship", and every token name is the **real** live name (NO-INVENT, traced from source).
>
> **Risk: NORMAL — and the `@mercury/ui` public surface is FROZEN this rung.** Unlike mx.4 (which grew the
> barrel), mx.8 adds **no** export and changes **no** component `.tsx`/`index.ts`/`.prompt.md`/style: the
> `@mercury/ui` barrel is **byte-identical** to HEAD (INV-1). It DOES edit the **host config** (the
> `.storybook/` preview + globals) — that is in scope this rung (a toolbar global needs a decorator) — and
> it DOES edit the co-located `*.stories.tsx` (the variant/action enrichment), but a story is excluded from
> the library `tsc` and adds no export, so the surface stays frozen. Load-bearing hazards: (a) a palette
> remap that cites a ramp step the live tokens do **not** define (`--green-10`/`--plum-4` — the status
> ramps ship only `-3/-9/-11`; §3) → an undefined custom property → a broken color; (b) a roundings switch
> assuming a single `--radius` base (there is none — components read specific `--radius-N` steps; §3) or
> clobbering `--radius-full` (avatars/switches/chips read it for their circular shape); (c) a global that
> **compiles but does not drive the token** — a no-op decorator that registers the picker yet never
> overrides the variable (the gate MUST prove the override fires; INV-6).
>
> **The decisions this rung carries (Operator-ruled — recorded VERBATIM for ratification at ship):**
> - **mx.8 = the Storybook enrichment ONLY** — "integrate `.stories` for components to Storybook
>   supporting **palette, roundings, variant switching, actions, example real-world usage**." (Operator.)
> - **mx.8 does NOT touch `@mercury/ui`'s public surface** — the barrel stays byte-identical; no component
>   `.tsx`/`index.ts`/`.prompt.md`/style edit. The enrichment lives in **host config + story files only**.
> - **mx.8 ladders behind the COMPLETED import (mx.7.4)** — it documents the post-mx.7.4 library; the
>   showcase application is **mx.9**. (mx.7 epic §6, verbatim.)
> - **Design flows DOWN** (inherited mx.7 INV-8): no `/design-sync`, no `DesignSync`, no push to Claude Web.
>
> These scope decisions are RULED — this triad does not re-litigate them. The open call is the **switching
> mechanism fork** (§A) plus four lighter placement/wiring forks; all are surfaced, none decided.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · roadmap:
[`../../mercury.roadmap.md`](../../mercury.roadmap.md) · dashboard:
[`../../mercury.progress.md`](../../mercury.progress.md) · prior triad (the import end-state):
[`../mx.7/mx.7.md`](../mx.7/mx.7.md) + [`../mx.7.4/mx.7.4.md`](../mx.7.4/mx.7.4.md) · format exemplar:
[`../mx.5/mx.5.md`](../mx.5/mx.5.md) · host + story conventions:
[`../mx.3/mx.3.md`](../mx.3/mx.3.md) + [`../mx.4/mx.4.md`](../mx.4/mx.4.md) · contract template:
[`../../contracts.md`](../../contracts.md) · method:
[`../../../aaw/aaw.framework.md`](../../../aaw/aaw.framework.md) · architect approach:
[`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) · acceptance:
[`mx.8.stories.md`](./mx.8.stories.md) · build context: [`mx.8.llms.md`](./mx.8.llms.md).

---

## A · The forks — the Operator rules the mechanism; the Director ratifies the rest

### Fork 1 (LOAD-BEARING — the Operator rules) — the palette + roundings switching MECHANISM

The five enrichments split into **two cross-cutting re-skins** (palette, roundings — they touch *every*
story uniformly) and **three per-component dimensions** (variants, actions, scenes). The load-bearing
call is *how the two cross-cutting re-skins are switched.* Three arms; the choice governs the whole rung's
shape.

- **Rationale.** mx.3 already ships the precedent: a `theme` **toolbar global** + a single `withTheme`
  decorator that applies `${theme}-theme` to a scoped wrapper (`apps/storybook/.storybook/preview.tsx`).
  Theme, palette, and roundings are the same *kind* of thing — one global control that re-skins the live
  CSS-variable layer for every story at once, with **zero per-story authoring**. Palette and roundings are
  pure token re-points (§3, §6): a palette swap re-points the `--bg-brand`/`--bg-active` semantic family to
  a chosen ramp; a roundings swap re-scales the `--radius-*` steps. Both are exactly what a wrapper-level
  custom-property override does.
- **5W.** *Who:* the host owner (Director) + the Operator. *What:* whether palette/roundings switch from a
  global toolbar, from per-story controls, or both. *When:* this rung. *Where:* `.storybook/preview.tsx`
  (globals + decorator) vs every `<Name>.stories.tsx` (`args`/`argTypes`). *Why:* one re-skin surface for
  the whole book vs per-story latitude.

| Arm | Mechanism | Steelman | Cost |
|---|---|---|---|
| **(a) toolbar GLOBALS** *(Steward)* | Add `palette` + `radius` `globalTypes` pickers; extend the mx.3 decorator to also apply the chosen ramp + radius scale to the one wrapper. | The exact mx.3 `withTheme` pattern, generalized — **one control re-skins every story** (live + imported), zero per-story edit, host-config-only, and it composes with the existing `theme` global on the same wrapper. The cleanest parallel to what already ships. | Host `preview.tsx` edit (in scope this rung). |
| **(b) per-story args/controls** | Each story exposes `palette`/`radius` as `args` with a `select` control. | Per-story latitude; a story can pin a palette. | Re-authors **every** story (live + imported) to add two args + the wiring; massive surface, easy drift, no single re-skin of the book. |
| **(c) BOTH** | Global toolbar for theme/palette/roundings **and** per-story variant controls. | The toolbar carries the cross-cutting re-skins; per-story `argTypes` carry the component-specific *variants*. | This is really **(a) for palette/roundings + the §Fork-4 variant audit** — the two are orthogonal, not a third mechanism. |

> **Steward recommendation: Arm (a) — toolbar globals — for palette + roundings.** It mirrors the shipped
> theme mechanism exactly, re-skins the entire book from one control, and keeps the rung host-config-only.
> *Variant switching* is a **separate** dimension that naturally lives in per-story `argTypes` (Fork 4) —
> so the practical end-state reads like (c), but the *palette/roundings mechanism itself* is (a). **The
> Operator rules.** (Whether the palette also re-points the `--bg-active` family, or brand-only, is the
> §6.1 sub-note — the Operator named both; the caveat is the canon's iris=identity / indigo=interaction
> split.)

### Fork 2 (Director-ratifiable) — the real-world scenes' HOME

- **Arms:** **(a) host-home `apps/storybook/stories/scenes/`** *(Steward)* — a scene composes *many*
  components (a settings page, an auth screen, a dashboard), so it is cross-component and belongs in the
  host home, exactly where the mx.5 `stories/effector/` and the `Tokens` story already live; it keeps the
  mx.4 1:1 `count(component *.stories.tsx) == count(component folders)` invariant intact (no scene is added
  under a component folder). **(b) co-located** — would break the 1:1 count and mis-attribute a
  multi-component scene to one folder.
- **Steward: host-home `stories/scenes/`.** *(Director-ratifiable.)*

### Fork 3 (Director-ratifiable) — the story-source for the enrichment

- **Arms:** **(a) extend the live mx.4 co-located stories** *(Steward)* — add the variant `argTypes` audit
  + action args to each existing `<Name>.stories.tsx`; **DRY** (one story home per component) and consistent
  with the mx.4 shape. **(b) import the bundle `mercury-ds/.../<Name>.stories.tsx`** — REJECTED: the bundle
  stories use the bundle's own CSF conventions (globally-unique export-name prefixing, inlined `meta`, the
  `window.<Namespace>` hoist — `mercury-ds/project/CLAUDE.md` §4) and the inline-style/`_ds_bundle` idiom
  that mx.7 deliberately translated **away**; importing them re-introduces the framing and fights the host's
  real `@storybook/react-vite` CSF. Design flows DOWN — never up.
- **Steward: extend the live co-located stories; never import the bundle stories.** *(Director-ratifiable.)*

### Fork 4 (Director-ratifiable) — "variant switching": per-component audit vs a global grid

- **Arms:** **(a) per-component `argTypes` coverage audit** *(Steward)* — every component's story exposes
  its full `variant`/`size`/`tone`/`align`/… enum surface as a typed `select`/`inline-radio` control
  (typed by the component's **exported union**, so an invented option is a compile error). The Controls
  panel *is* the variant switcher; mx.4 already does this for some (Button is complete) — mx.8 audits the
  whole set and tops up the gaps. **(b) a single global "variants grid" host story** — redundant with the
  per-component grid stories mx.4 already ships, and it cannot drive a live control.
- **Steward: per-component `argTypes` audit (top up the gaps); keep the mx.4 grids.** *(Director-ratifiable.)*

### Fork 5 (Operator/Director — has a host-dep cost) — the actions wiring

- **Arms:** **(a) explicit `fn()` spies on the interaction args** *(Steward, minimal)* — set
  `args: { onClick: fn(), onChange: fn(), … }` on the interactive stories so each handler is logged in the
  Storybook **Actions** panel; the spy utility ships with Storybook's test package (the exact import —
  `storybook/test` in the SB10 line — is **verified against the then-installed Storybook at build**, since
  none is installed today). **(b) `@storybook/addon-actions`** — a new host devDep + an `addons:` entry in
  `main.ts` + a lockfile move. **(c) the legacy `parameters.actions.argTypesRegex: "^on[A-Z].*"`** — a
  one-line preview param that auto-wires every `on*` arg, **iff** the SB10 line still honors it (it was
  deprecated in the SB8 line; verify or discard at build).
- **Steward: (a) explicit `fn()` spies, grounded at build to the installed Storybook test util** — no new
  addon dep, the minimal host touch. **Note:** if the Actions *panel* needs an addon registered, that
  `main.ts` `addons` line is a minimal in-scope host-config edit — surfaced, not silent. **The Operator
  rules** the new-dependency question (a host devDep is a dependency fork).

---

## 0 · The slice — what mx.8 builds, and why enrichment after the import

Movement III's destination is a complete, browsable Design System Storybook. mx.3–mx.5 built the host and
the first stories; mx.7 imports the full Claude-Design component set, each with a **basic** story. A basic
story renders a component in isolation under the default (iris) brand, the default (8px) radius, and a
fixed set of args. mx.8 adds the **five dimensions a design system is actually browsed for**:

1. **Palette switching** — re-skin the brand (and active) family to any of the six real ramps from one
   toolbar control, so a viewer sees the whole library in green/orange/plum/… without editing a story.
2. **Roundings switching** — re-scale the radius steps (Sharp / Default / Round) from one toolbar control,
   leaving the circular `--radius-full` affordances intact.
3. **Variant switching** — every component's full enum surface exposed as a live Controls-panel control.
4. **Actions** — interaction handlers logged in the Actions panel, so a viewer confirms a click/change
   fires.
5. **Example real-world usage** — host-home **scene** stories composing many components into the real
   screens the apps ship (an auth screen, a send/payment screen, a settings list, a dashboard).

What mx.8 is **not**: it adds **no** `@mercury/ui` surface (barrel byte-identical), and it is **not** the
showcase application (mx.9). The whole diff is **host config** (the `.storybook/` globals + decorator),
the **co-located story enrichment** (variant `argTypes` + action args), the **new host-home scene
stories**, and this triad.

## 1 · Goal

After mx.8, the Storybook carries **two new toolbar globals — `Palette` and `Roundings`** — that re-skin
**every** story (live + imported) via a single extended decorator, composing with the existing `Theme`
global; **every component story exposes its full variant/size/tone enum surface** as typed Controls and
**logs its interaction handlers** to the Actions panel; and a host-home **`Scenes/`** group composes the
real app screens from real `@mercury/ui` components. Concretely:

- `apps/storybook/.storybook/preview.tsx` gains `palette` + `radius` `globalTypes` and one extended
  decorator that applies the chosen ramp + radius scale (and the existing theme) to the story wrapper via
  **real** token overrides (§6).
- The co-located `<Name>.stories.tsx` for every component (the post-mx.7.4 set — count reconciled at ship)
  carries a complete typed-union `argTypes` set and `fn()`-spied interaction args (Forks 3–5).
- A host-home `apps/storybook/stories/scenes/` group adds **≥4** scene stories grounded in cited real app
  screens (§6.5).
- `pnpm sb:typecheck` exits 0 (the authoritative NO-INVENT gate); `pnpm sb:build` exits 0 and registers
  the prior homes **unchanged** + the new `Scenes/*` homes (count reconciled at ship); the packages
  typecheck/build and the product apps build, undisturbed. **The `@mercury/ui` barrel is byte-identical to
  HEAD; no component `.tsx`/`index.ts`/`.prompt.md`/style is edited.** And — the load-bearing proof — the
  new globals **actually drive the tokens** (INV-6): selecting a palette/roundings changes the computed
  style of a probe element, a no-op decorator is a LOUD failure.

## 2 · Rationale (5W)

- **Why.** A design system Storybook earns trust by letting a viewer *interrogate* the surface, not just
  look at a default render. The Operator's five dimensions are precisely the interrogations a designer or a
  coding agent runs: *does the whole library hold together under a different brand ramp?* (palette) *under
  sharper/rounder corners?* (roundings) *across every variant?* (variant switching) *do the handlers
  fire?* (actions) *what does it look like assembled into a real screen?* (scenes). The earlier rungs prove
  each component renders; mx.8 makes the **system** browsable.
- **What.** Two cross-cutting toolbar globals (palette, roundings) + one extended decorator; a
  per-component `argTypes`/actions enrichment of the existing co-located stories; a host-home scene group;
  the gate (incl. the render-check that the globals drive the tokens).
- **Who.** *Authored by* Claude Code as Director-led architect (this triad) + the enrichment wave(s).
  *Consumed by* — (1) Mercury contributors + the Claude Design agent browsing the library under different
  palettes/roundings; (2) **mx.9** (the showcase application), which composes the scenes into the shipped
  site; (3) the canon's re-skin/token story, which these globals make demonstrable.
- **When.** Now (specced), **built after mx.7.4** (the import must be complete so the enrichment spans the
  whole library) and **re-sharpened at its ship** against the as-built inventory.
- **Where.** `apps/storybook/.storybook/` (the globals + decorator), `apps/storybook/stories/scenes/`
  (new), the post-mx.7.4 co-located `packages/mercury-ui/src/components/<group>/<Name>/<Name>.stories.tsx`
  (enriched — stories only, no surface), and `docs/mercury/specs/mx.8/`.

## 3 · The token vocabulary — RECONCILED (read the live `tokens.css`, not the bundle)

The palette + roundings mechanism is grounded in the **live** token layer
(`packages/mercury-ui/src/styles/tokens.css`) — the single source of truth (the bundle
`mercury-ds/.../colors_and_type.css` carries identical values per the mx.1/mx.7 finding; the live file is
authoritative). Two findings are load-bearing and correct the task hint's loose phrasing:

### 3.1 · Palette — the brand family is a semantic indirection over a ramp; the status ramps are PARTIAL

Components read **semantic aliases**, not raw ramps: `--bg-brand` (15 uses) · `--fg-brand` (7) ·
`--bg-brand-subtle` (3) · `--bg-brand-hover`/`--bg-brand-pressed` (1 each) · `--border-brand` ·
`--fg-on-brand`. Each resolves to a ramp step: `--bg-brand: var(--iris-9)`, `--bg-brand-subtle:
var(--iris-3)`, `--fg-brand: var(--iris-11)`, … So a **palette swap = re-point those aliases to a different
ramp** (override the alias on the wrapper). The six real ramps (`_lib/accent.ts` `MERC_ACCENTS`):
`iris · indigo · green · orange · plum · red`.

> **NO-INVENT hazard (load-bearing):** the ramps have **unequal step coverage** in `tokens.css`.
> `iris` and `indigo` ship the **full 1–12** scale; **`green`/`orange`/`plum`/`red` ship ONLY `-3`, `-9`,
> `-11`** (the extra status scales). There is **no** `--green-10`, `--plum-4`, `--orange-10`, … A palette
> remap that points `--bg-brand-hover → --green-10` resolves to an **undefined** custom property → a broken
> color. The remap MUST use only steps that exist for the chosen ramp, mirroring the bundle's own
> `mercAccent` helper (which uses only `-9` solid + `-11` fg + alpha tints). §6.1 gives the safe table.

### 3.2 · Roundings — there is NO `--radius` base; components read specific `--radius-N` steps

The radius scale is exactly **`--radius-2/4/6/8/12/16/20/24/32/full`** (10 named steps; **no** bare
`--radius` or `--radius-base` exists). Live components read specific steps: `--radius-8` (the default,
11 uses) · `--radius-12` (6) · `--radius-6` (5) · `--radius-full` (4 — avatars/switches/chips/icon-buttons,
the *circular* affordances) · `--radius-4` (2). So a global roundings switch **cannot** "set the `--radius`
base" (the task hint's phrasing) — there is none. The grounded mechanism: **override the `--radius-2 …
--radius-32` steps on the wrapper** (a preset scale: Sharp ⇒ ~0, Default ⇒ live values, Round ⇒ enlarged).
Because components read `var(--radius-N)`, overriding those custom properties on an ancestor re-skins them
with **zero component edit** — exactly how `.dark-theme` overrides the ramps. **`--radius-full` is
EXCLUDED** from the remap (clobbering it turns circular avatars/switches into squares). §6.2 gives the
preset table.

## 4 · Host wiring — what mx.8 edits (the contrast with mx.5)

mx.5 froze the host (it added only story files). **mx.8 edits the host config** — a toolbar global is a
`preview.tsx` change by construction — and that is **in scope** this rung. What stays frozen is the
**`@mercury/ui` surface** (the barrel + every component file). The host claims:

| Host claim | As-built (cited) | Verdict / action |
|---|---|---|
| The theme global + scoped-wrapper decorator exist to extend | `apps/storybook/.storybook/preview.tsx` `withTheme` + `globalTypes.theme` | MATCH — **extend** it (add `palette`/`radius` globals + the ramp/radius overrides on the same wrapper) |
| The story glob already spans the scenes home | `apps/storybook/.storybook/main.ts` `"../stories/**/*.stories.@(tsx|ts)"` | MATCH — `stories/scenes/**` is covered; **no `main.ts` glob edit** |
| `sb:typecheck`/`sb:build` exist | root `package.json` `sb:typecheck`/`sb:build` (mx.4 `D-10`) | MATCH — the gate scripts are present |
| An actions spy/addon is installed | **none** found (`storybook/test`, `@storybook/test`, `@storybook/addon-actions` all absent) | **GAP — Fork 5.** The actions mechanism is verified/installed at build; a host dep is the Operator's call |
| The host depends on `@mercury/ui` from source | `apps/storybook/vite.config.ts` alias + `tsconfig.json` paths (mx.3/mx.4) | MATCH — the enriched co-located stories resolve from source |

> **If the build reveals a host edit beyond the globals/decorator/scenes/actions-wiring above, STOP and
> report it** — anything touching the `@mercury/ui` surface is out of scope (barrel frozen). The
> actions-dep question (Fork 5) is surfaced, not an implementor call.

## 5 · Deliverables

- **K-1 — the `Palette` toolbar global + decorator.** A `palette` `globalType` (a picker over the six real
  ramps + a "Brand (iris)" default) and the extended decorator that re-points the `--bg-brand` family (and,
  per the §6.1 sub-note, optionally `--bg-active`) to the chosen ramp **using only steps the ramp defines**
  (§3.1, §6.1). Applied to the existing wrapper; composes with `theme`.
- **K-2 — the `Roundings` toolbar global + decorator.** A `radius` `globalType` (Sharp / Default / Round,
  default Default) and the extended decorator that overrides `--radius-2 … --radius-32` on the wrapper per
  the §6.2 preset table, **leaving `--radius-full` untouched**.
- **K-3 — variant switching (the per-component `argTypes` audit).** Every component story (the post-mx.7.4
  set) exposes its full `variant`/`size`/`tone`/… enum surface as a typed `select`/`inline-radio` control,
  each option array typed by the component's **exported union** (NO-INVENT). Gaps in the mx.4/mx.7 basic
  stories are topped up; the mx.4 grids are kept.
- **K-4 — actions.** Every interactive component story logs its handlers (`onClick`/`onChange`/`onSubmit`/…)
  to the Actions panel via the Fork-5 mechanism (the `fn()` spy on `args`, grounded to the installed
  Storybook). A click/change in the Controls/canvas produces an Actions-panel entry.
- **K-5 — real-world scenes.** A host-home `apps/storybook/stories/scenes/` group with **≥4** CSF3 scene
  stories, each composing **only** real `@mercury/ui` exports into a real app screen, grounded in a **cited**
  live screen (`apps/mobile/src/screens/*` and/or the bundle `ui_kits/mercury_app/screens.jsx`) — §6.5. The
  exact roster is reconciled at ship against the post-mx.7.4 library.
- **K-6 — the gate is green AND the globals drive the tokens.** §7: `sb:typecheck` 0 · `sb:build` exit 0
  (prior homes unchanged + the new `Scenes/*`) · packages typecheck/build 0 · the product apps build ·
  barrel byte-identical · the NO-INVENT/token greps empty · **the render-check (INV-6): a chosen
  palette/roundings demonstrably changes a probe element's computed style; a no-op is a LOUD failure.**

**Coverage:** K-1 → S-1 ; K-2 → S-2 ; K-3 → S-3 ; K-4 → S-4 ; K-5 → S-5 ; K-6 → S-6, S-7, S-8 (surface
frozen · gate green · globals-drive-tokens render-check).

## 6 · The mechanisms — GROUNDED (real token names; implementor latitude on preset values)

### 6.1 · Palette remap (the safe cross-ramp table)

For a chosen ramp `R ∈ {iris, indigo, green, orange, plum, red}`, the decorator overrides these aliases on
the wrapper `style` (React passes custom properties through: `style={{ "--bg-brand": "rgb(var(--green-9))" }
as CSSProperties}`). Only steps defined for **all six** ramps (`-3 · -9 · -11`) are used unconditionally;
`-10`/`-4` (iris/indigo only) are used **only when defined**, else they fall back — mirroring `mercAccent`:

| Alias | Remap to | All-six-safe? |
|---|---|---|
| `--bg-brand` | `var(--R-9)` | ✅ |
| `--bg-brand-hover` | `var(--R-10)` if R∈{iris,indigo} else `var(--R-9)` | -10 partial → fallback |
| `--bg-brand-pressed` | `var(--R-11)` | ✅ |
| `--bg-brand-subtle` | `var(--R-3)` | ✅ |
| `--bg-brand-muted` | `var(--R-3)` (no `-4` for status ramps) | -4 partial → `-3` |
| `--fg-brand` | `var(--R-11)` | ✅ |
| `--border-brand` | `var(--R-9)` | ✅ |
| `--fg-on-brand` | `var(--slate-12)` if R == orange else `var(--slate-1)` | mirrors `mercAccent.onSolid` |

> **§6.1 sub-note (Fork-1 caveat — Operator rules).** The Operator named "`--bg-brand`/`--bg-active`". The
> table above re-points the **brand** family. Re-pointing the **active** family too (`--bg-active`,
> `--bg-active-hover→-10|−9`, `--bg-active-subtle→-3`, `--fg-active→-11`, `--border-active`/`--border-focus
> →-9`) gives a *fuller* re-skin but collapses the canon's **iris = identity / indigo = interaction** split
> (CLAUDE.md §5). Steward: re-skin **brand only** by default (keep interaction indigo); include active iff
> the Operator wants a total re-skin. Either way, the same all-six-safe step discipline applies.

### 6.2 · Roundings remap (the preset table — values are implementor latitude)

The decorator overrides the box-radius steps on the wrapper; `--radius-full` is **never** overridden.

| Preset | `--radius-2 … --radius-32` | `--radius-full` |
|---|---|---|
| **Sharp** | all → `0px` (or ≤`2px`) | untouched (pills/avatars stay round) |
| **Default** | no override (live `2/4/6/8/12/16/20/24/32`) | untouched |
| **Round** | each step enlarged (~1.5–2×, e.g. `--radius-8 → 14px`) | untouched |

Exact Sharp/Round values are the implementor's latitude; the **mechanism** (override the 2…32 steps, never
`--radius-full`, never touch `@mercury/ui`) is fixed.

### 6.3 · Variant switching (the per-component audit)

The shape is the mx.4 exemplar (`Button.stories.tsx`): a typed const-array per enum
(`const VARIANTS: ButtonVariant[] = [...]`) feeding `argTypes: { variant: { control: "select", options:
VARIANTS } }`. mx.8 audits every component's story for **full** coverage of its exported unions and tops up
the gaps; `ReactNode` slots stay driven by a story arg rendering a real `<Icon/>` (never a raw control, the
mx.4 rule). The exported union types the array, so an invented option fails `sb:typecheck` (NO-INVENT).

### 6.4 · Actions (the Fork-5 mechanism)

Set the interaction handlers as spies on `args` (e.g. `args: { onClick: fn() }`) so the Actions panel logs
each call; the `fn` import is grounded to the installed Storybook test util at build (§A Fork 5). A handler
arg is **not** a `ReactNode` slot — keep slots as `control: false`.

### 6.5 · Real-world scenes (host-home, grounded)

Each scene is a CSF3 host-home story (`title: "Scenes/<Name>"`, no `component:` field, like `Tokens`)
composing **only** real `@mercury/ui` exports into a real screen, grounded in a **cited** source. The
candidate roster (reconciled at ship against the post-mx.7.4 library):

| Scene | Composes (real exports) | Grounded in (cited) |
|---|---|---|
| `Scenes/SignIn` | `Input` · `Button` · `PasswordStrength` · `AuthCode` · `Callout`/`Alert` | `apps/mobile/src/screens/Login.tsx` |
| `Scenes/SendMoney` | `MoneyInput` · `Button` · `ListRow` · `Callout` | `apps/mobile/src/screens/Send.tsx` |
| `Scenes/Profile` | `Avatar` · `ListRow` · `Switch` · `Separator`/`Divider` · `Badge` | `apps/mobile/src/screens/Profile.tsx` |
| `Scenes/Dashboard` | `Stat` · `Chart` · `Table` · `Card` · `Tabs` | `apps/mobile/src/screens/{Home,Wallet,Activity}.tsx` + `ui_kits/mercury_app/screens.jsx` |

Scenes are **presentational compositions** — a scene may hold local `useState` for demo interactivity, but
it imports only `@mercury/ui` (+ `react`/`@storybook/react-vite`); no `@mercury/effector` (that is mx.5's
home), no app import, no `window.MercuryUI`/`_ds_bundle`.

## 7 · Invariants — as runnable gates

Run from `mercury/`. Each invariant is the check that proves it.

- **INV-1 — the barrel is byte-identical (the master invariant, strongest form).**
  `diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` → **empty**.
  mx.8 adds no `@mercury/ui` export.
- **INV-2 — the `@mercury/ui` PRODUCTION surface is untouched; only stories + host config change.**
  `git diff --name-only` shows **no** edit to any `packages/mercury-ui/src/**` file **except**
  `*.stories.tsx`; the other changed paths are `apps/storybook/.storybook/**`,
  `apps/storybook/stories/scenes/**`, and (Fork 5) possibly `apps/storybook/{package.json}` +
  `pnpm-lock.yaml`. No component `.tsx`/`index.ts`/`.prompt.md`/`styles/**` edit. (Any unavoidable
  non-story `mercury-ui` change is flagged + surfaced — never silent.)
- **INV-3 — `sb:typecheck` clean (the authoritative NO-INVENT gate).** `pnpm sb:typecheck` exits 0 — every
  enum option array is typed by the component's exported union; every wired prop is real; the scene imports
  resolve. (The library `tsc` excludes `**/*.stories.tsx`, so the host `tsc` is the only one that checks
  the enriched stories — mx.3 `D-9`/mx.4 `D-10`.)
- **INV-4 — `sb:build` registers the prior homes unchanged + the new `Scenes/*` homes.** `pnpm sb:build`
  exits 0; the built index lists every prior component/foundation/effector home **unchanged** and adds the
  `Scenes/<Name>` homes. (The exact prior count = the post-mx.7.4 number, reconciled at ship; the **delta**
  is the scene homes — basic component stories are *enriched in place*, not added, so they do not change the
  home count.)
- **INV-5 — packages typecheck/build + the product apps build, undisturbed.**
  `pnpm --filter "./packages/*" typecheck` = 0 · `pnpm --filter "./packages/*" build` = 0 ·
  `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` = 0. (The product-app set —
  currently `echomq · marketing-site · mobile · website` — is reconciled at ship; do not pin the count.)
- **INV-6 — the globals DRIVE the tokens (gate-liveness; a no-op is a LOUD failure).** Selecting a non-
  default `Palette` or `Roundings` **measurably changes a probe element's computed style** — the proof is
  POSITIVE, not "it compiles": with `Palette = green`, a `--bg-brand` surface (e.g. `Button
  variant="primary"`) computes the **green-9** triplet `rgb(48, 164, 108)`, **not** iris-9
  `rgb(91, 91, 214)`; with `Roundings = Sharp`, a `--radius-8` surface (e.g. a `Card`) computes
  `border-radius: 0px`, **not** `8px`, **while** an `Avatar` (`--radius-full`) stays `9999px` (the
  full-radius exclusion proof). A decorator that registers the picker but does not override the variable
  fails this check. (Exercised at ship via a computed-style probe / play function — the harness is chosen
  at ship; the spec fixes the expected values.)
- **INV-7 — actions fire.** An interactive story's handler, invoked, produces an **Actions-panel entry**
  (the `fn()` spy is on the arg; §6.4). Verified at ship in the running Storybook.
- **INV-8 — NO-INVENT + token discipline + design-flows-DOWN.** Every ramp/radius/token name in the
  decorator and stories is real (traced from `tokens.css`); no `--<ramp>-10`/`-4` for a status ramp; no raw
  hex; no story imports the bundle or cites `window.MercuryUI`/`_ds_bundle`; no `/design-sync`/`DesignSync`.
  Greps (run at ship over the touched paths):
  `grep -rnE "#[0-9a-fA-F]{3,8}\b" apps/storybook/stories/scenes apps/storybook/.storybook` → **empty**;
  `grep -rn "window.MercuryUI\|_ds_bundle\|design-sync\|DesignSync" apps/storybook/stories apps/storybook/.storybook`
  → **empty**;
  `grep -rnE "\-\-(green|orange|plum|red)-(10|4)\b" apps/storybook/.storybook` → **empty** (the partial-ramp
  guard).

## 8 · Out of scope (explicit)

- Any `@mercury/ui` component change, any new export, any `index.ts`/`.prompt.md`/style edit (mx.8 freezes
  the surface — the enrichment is host config + story files only).
- The **showcase application** (the shipped site composing the scenes) — that is **mx.9**.
- Effector-wired stories (those are mx.5's `stories/effector/` — mx.8 scenes are presentational, no
  `@mercury/effector`).
- Reconciling the 21 re-prototypes of existing exports, or any rename/removal of an export, or any token
  value change (mx.7-epic out-of-scope, inherited).
- `/design-sync`, the `DesignSync` MCP, any push to Claude Web (FORBIDDEN — design flows DOWN).
- Editing the roadmap/progress/design/epic (the Director folds the roadmap mx.8 row → BUILT + a `D-` per
  ruled fork at ship).

## 9 · As-built (Apollo / the verifier — filled post-build at ship)

*(SOLID-FORWARD: empty until mx.8 is built. At ship, classify every promise K-1..K-6 / INV-1..INV-8 /
S-1..S-8 MATCH / STALE / INVENTED / MISSING; record the resolved palette/roundings preset values, the
final scene roster, the actions mechanism the installed Storybook supports, the post-mx.7.4 home count, and
the reproduced gate. Reconcile the §3 token findings against the as-built `tokens.css` at ship.)*

> **Framing (propagate to any brief derived from this spec):** no gendered pronouns for agents; no
> perceptual or interior-state verbs; no first-person narration. State each surface as a contract
> (precondition / postcondition / invariant) so acceptance is at the boundary, not by re-reading the diff.
