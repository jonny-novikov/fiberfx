# mx.7.2 · Import batch 2 — simple feedback / display + layout

> **Status: 📋 PLANNED — build-ready; batch 2 of the mx.7 import epic.** Inherits the epic frame
> [`../mx.7/mx.7.md`](../mx.7/mx.7.md). Imports **10 simple primitives** — `Callout · Spinner · Skeleton ·
> Blockquote · DataList · Code · Kbd · AspectRatio · Collapsible · ScrollArea` — translated into the `.mx-*` +
> token idiom, additively. Builds on mx.7.1 (composes `Text`/`Heading`/`Icon`; reuses the mx.7.1 `accent`-class
> pattern).
>
> **Risk: NORMAL (mostly trivial primitives; two have light internals).** Eight are styled elements (`Code`,
> `Kbd`, `Blockquote`, `Spinner`, `Skeleton`, `AspectRatio`, `DataList`, `Callout`); **two carry internals** —
> `Collapsible` (a controlled/uncontrolled disclosure state machine that composes the live `Icon`) and
> `ScrollArea` (a custom-scrollbar container). No portal, no focus-trap. Load-bearing hazards: (a) `Callout`
> read as a duplicate of `Alert` (it is a distinct inline emphasis block — cross-link, don't merge); (b)
> `Collapsible` read as `Accordion` (single disclosure vs a set — distinct, no rename); (c) the `accent` prop
> re-introducing `mercAccent` (use the mx.7.1 class pattern).
>
> **Inherited, not re-argued** (epic §4/§5): translate to `.mx-*` + tokens; additive-only tokens/fonts; never
> rename an existing export; design flows DOWN (no `/design-sync`); the 4-file home + additive barrel + the gate.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · epic: [`../mx.7/mx.7.md`](../mx.7/mx.7.md) ·
prior batch: [`../mx.7.1/mx.7.1.md`](../mx.7.1/mx.7.1.md) · contract template:
[`../../contracts.md`](../../contracts.md) · acceptance: [`mx.7.2.stories.md`](./mx.7.2.stories.md) · build
context: [`mx.7.2.llms.md`](./mx.7.2.llms.md).

---

## A · The two distinctness calls in this batch (Director-ratifiable — both ADD net-new, no rename)

Policy ruled in the epic (Cross-fork III: never rename). Both items are **distinct** from an existing export, so
both **add net-new** — no collision, recorded so the verifier confirms intent:

- **`Callout` vs `Alert`.** `Alert` is a status message (a result of an action — info/success/warning/danger);
  `Callout` is an inline emphasis block (a note in the reading flow — `intent: info|brand|positive|caution|
  negative|discovery` × `variant: soft|surface|outline`). **Add `Callout` net-new**; the contracts cross-link.
- **`Collapsible` vs `Accordion`.** `Accordion` is a *set* of disclosures (one-open-at-a-time); `Collapsible` is a
  *single* disclosure (`title` + `open`/`defaultOpen`/`onOpenChange`). **Add `Collapsible` net-new**; cross-link.

## 0 · The slice

Batch 2 — the simple feedback/display/layout primitives. Most are one styled element + tokens (`Code`/`Kbd`/
`Blockquote`/`Spinner`/`Skeleton`/`AspectRatio`); `DataList` and `Callout` are small composites; `Collapsible`
and `ScrollArea` carry light internals (a disclosure state machine; a custom scrollbar). All translate into the
live idiom and export additively. They compose mx.7.1 (`Callout`/`Collapsible` titles are `Heading`/`Text`;
`Collapsible` composes the live `Icon`).

## 1 · Goal

After mx.7.2, `@mercury/ui` exports **10 new components**, each a translated 4-file home (`.mx-*` + tokens ·
hand-authored contract · CSF3 story). The barrel is strictly additive (+10 + their `Props`). The full package
gate is green; `sb:build` registers prior + 10; the barrel-diff is 0 removed/renamed.

## 2 · Rationale (5W)

- **Why.** These primitives are the everyday display/feedback vocabulary the apps + mx.9 docs need (loading
  states, code/keycaps, notes, term/description lists, ratio media boxes, disclosures, scroll regions).
- **What.** The 10 translated components, the barrel +10, the `.mx-*` rules in `additions.css`, reusing mx.7.1's
  `accent`-class pattern for the accent-bearing ones (`Callout`/`Spinner`/`Blockquote`/`Code`/`Collapsible`).
- **Who.** *Authored by* the architect (this triad) + the batch agents (epic §2). *Consumed by* mx.7.3/7.4 (their
  composites), mx.8 (stories), mx.9 (the showcase).
- **When.** Batch 2 — after mx.7.1, Operator in the loop before mx.7.3.
- **Where.** Only `packages/mercury-ui/src/` (10 folders + barrel + `additions.css`) + `docs/mercury/specs/mx.7.2/`.

## 3 · The component set (grounded — bundle prop surface verified in source)

| Component | Bundle source | Prototype prop surface (verified — the seed) | Live group |
|---|---|---|---|
| `Callout` | `feedback/Callout` | `intent?: info\|brand\|positive\|caution\|negative\|discovery` · `variant?: soft\|surface\|outline` · `size?` · icon/title/children | `feedback` |
| `Spinner` | `feedback/Spinner` | `size?: sm\|md\|lg\|number` · `accent?` · `label?="Loading"` (a11y) | `feedback` |
| `Skeleton` | `feedback/Skeleton` | width/height/radius/variant (pulse placeholder) | `feedback` |
| `Blockquote` | `data-display/Blockquote` | `size?` · `accent?` · `cite?` | `data-display` |
| `DataList` | `data-display/DataList` | `items: DataListEntry[]` · `orientation?: horizontal\|vertical` · `size?` | `data-display` |
| `Code` | `data-display/Code` | `variant?: soft\|solid\|outline\|ghost` · `size?` · `accent?` · `block?` (DM Mono) | `data-display` |
| `Kbd` | `data-display/Kbd` | `size?: sm\|md\|lg` (keycap) | `data-display` |
| `AspectRatio` | `layout/AspectRatio` | `ratio?=16/9` (CSS `aspect-ratio`) | `layout` |
| `Collapsible` | `layout/Collapsible` | `title` · `open?`/`defaultOpen?`/`onOpenChange?` · `bordered?` · `accent?` · composes `Icon` | `layout` |
| `ScrollArea` | `layout/ScrollArea` | `scrollbars?: vertical\|horizontal\|both` · `size?` · `maxHeight?` · `width?` | `layout` |

## 4 · Translation notes (the deltas beyond mx.7.1's established pattern)

- **The `accent`-class pattern carries forward** (mx.7.1 §4): `Callout`/`Spinner`/`Blockquote`/`Code`/`Collapsible`
  realize `accent` via `.mx-<name>--accent-<id>` token classes — **no `mercAccent` import**.
- **`Callout` tones → the semantic token families.** `intent` maps to the canon families: `info`→`--bg-info`,
  `brand`→`--bg-brand-subtle`, `positive`→`--bg-positive`, `caution`→`--bg-caution`, `negative`→`--bg-negative`,
  `discovery`→`--bg-discovery` (with the matching `--fg-*`/`--border-*`). `variant` (soft/surface/outline) picks
  the fill/border treatment. Cross-link `Alert`.
- **`Collapsible` — controlled + uncontrolled, composes the live `Icon`.** Translate the bundle's `useState`
  disclosure to the live idiom (controlled `open`/`onOpenChange`, uncontrolled `defaultOpen`); the chevron is the
  live `Icon` (`<Icon name="…">` — verify the icon name against the live Icon set, do not invent a glyph). Guard
  React-19 nullable refs. `.mx-collapsible`.
- **`ScrollArea` — custom scrollbar.** The bundle already uses a `merc-sa` className; translate to `.mx-scrollarea`
  + `--<size>` with `*::-webkit-scrollbar` styling reading tokens (webkit-only cosmetic; the canon's scrollbar
  rule). `scrollbars` picks the axes; `maxHeight`/`width` are dynamic inline (non-color — allowed by INV-2).
- **`AspectRatio`/`Skeleton`** use **dynamic non-color inline styles** (`aspect-ratio`, computed width/height) —
  allowed; the INV-2 grep targets color literals only.
- **`Code`/`Kbd`/`Blockquote`** are DM-Mono / rule primitives — straight idiom translation reading `--bg-tertiary`
  / `--border-secondary` / `--font-secondary`.

## 5 · Deliverables

- **K-1 — 10 translated 4-file homes** under `packages/mercury-ui/src/components/<group>/<Name>/`.
- **K-2 — the barrel grows +10 additively**; every prior export byte-preserved; barrel-diff 0 removed/renamed.
- **K-3 — the live idiom**: `.mx-*` + tokens; no inline color literal; no raw hex; `accent` class-driven (no
  `mercAccent`).
- **K-4 — a hand-authored contract per component** (D-7): mx.2 format; cross-links (`Callout`↔`Alert`;
  `Collapsible`↔`Accordion`; `Spinner`↔`Skeleton`↔`Button.loading`; `Code`↔`Kbd`; `DataList`↔`Stat`/`Table`);
  no bundle framing.
- **K-5 — the 1:1 story↔folder invariant** (mx.4 S-1): each folder one story; `sb:build` +10 homes.
- **K-6 — distinctness recorded** (Fork A): `Callout`/`Collapsible` added net-new, `Alert`/`Accordion` untouched.
- **K-7 — token/font additive-only** (Cross-fork II).
- **K-8 — the gate is green** (§7); design flowed DOWN only.

**Coverage:** K-1 → S-1..S-10 ; K-2 → S-11 ; K-3/K-4 → S-1..S-10 ; K-5 → S-12 ; K-6 → S-1(Callout)+S-9(Collapsible) ;
K-7 → S-13 ; K-8 → S-14.

## 6 · The per-component translation map (grounded — see §3 for the surfaces)

`Callout` (`.mx-callout`, tones→semantic families) · `Spinner` (`.mx-spinner`, 360°/1s spin, `label` a11y) ·
`Skeleton` (`.mx-skeleton`, 1.5s pulse) · `Blockquote` (`.mx-blockquote`, border-inline-start rule) · `DataList`
(`.mx-datalist`, `<dl>` term/desc) · `Code` (`.mx-code`, DM Mono on `--bg-tertiary`, `block` variant) · `Kbd`
(`.mx-kbd`, keycap) · `AspectRatio` (`.mx-aspect`, `aspect-ratio`) · `Collapsible` (`.mx-collapsible`,
controlled+uncontrolled, composes `Icon`) · `ScrollArea` (`.mx-scrollarea`, custom webkit scrollbar). Each
contract cross-links per K-4.

## 7 · Invariants — as runnable gates (run from `mercury/`)

- **INV-1 — master invariant, additive.** Resolved export set after = superset; 0 removed/renamed, +10 (+ `Props`).
- **INV-2 — live idiom, no inline color leak.** `grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})"` over the 10 new
  dirs → **empty** (dynamic `aspect-ratio`/`maxHeight`/`width` inline are allowed — color literals are the fail).
- **INV-3 — no raw hex.** Over the 10 dirs + the new `additions.css` rules → **empty**.
- **INV-4 — no `mercAccent` import.** `grep -rn "mercAccent\|_lib/accent" packages/mercury-ui/src/components` →
  **empty**.
- **INV-5 — Icon composition is real, not invented.** `Collapsible` imports the live `Icon` and uses a real glyph
  name (verify against the live Icon set); `grep` the `Collapsible.tsx` for the icon import resolves.
- **INV-6 — D-7 contract, no bundle framing.** mx.2 sections present; `grep -rniE
  "check_design_system|pixel-perfect|/design-sync|showcase/"` over the new contracts → **empty**.
- **INV-7 — 1:1 story↔folder + `sb:typecheck` clean.** `count(*.stories.tsx) == count(component folders)`;
  `pnpm sb:typecheck` 0; `pnpm sb:build` prior + 10.
- **INV-8 — token/font additive-only** (Cross-fork II). **INV-9 — design flows DOWN** (no `/design-sync`).
- **INV-10 — the package gate.** `pnpm --filter "./packages/*" typecheck`/`build` 0 · `pnpm --filter "./apps/*"
  --filter "!@mercury/storybook" build` 0 · `pnpm sb:build` 0.

## 8 · The batch loop (epic §2) — Operator → Agent-1 → Agent-2 → Operator

Operator sharpens (carrying mx.7.1's lessons) → Agent-1 reconciles + builds the 10 homes → Agent-2 verifies +
hardens + fills §9 → Operator reviews the +10 homes + gate, carries lessons into mx.7.3, releases batch 3.
Feedback edits this spec, never the code.

## 9 · As-built (verified — BUILD-GRADE)

**Verdict: BUILD-GRADE** (Director independent verify, 2026-06-30; built in two sequential mars waves of 5). All
K-1..K-8 / INV-1..INV-10 / S-1..S-14 **MATCH**. Fork A: `Callout` + `Collapsible` added **net-new**; `Alert` +
`Accordion` byte-unchanged.

**Shipped — 10 four-file homes** (40 files): `feedback/Callout` · `feedback/Spinner` · `feedback/Skeleton` ·
`data-display/Blockquote` · `data-display/DataList` · `data-display/Code` · `data-display/Kbd` ·
`layout/AspectRatio` · `layout/Collapsible` · `layout/ScrollArea`. Barrel **127 → 160** (+33 = 10 components +
10 `Props` + 13 aux types), **0 removed/renamed** (collision sweep empty + index.ts additions-only + no existing
folder edited). `additions.css` +2 wave blocks; `tokens.css` byte-unchanged (no DM Sans 600 — L2).

**Gate (re-run independently, EXIT 0):** packages typecheck/build · apps build (echomq + mobile) · `sb:typecheck`
· `sb:build` (50 homes). **Hygiene empty:** inline-color, raw-hex, `mercAccent`/`_lib/accent`, bundle-framing,
**runtime style injection** (`document.head`/`createElement`). **No `/design-sync`.** **Mutation spot-check:**
`ScrollArea` `size` default → invalid `"xl"` → `tsc` TS2322, restored net-zero — the gate has teeth.

**§3-vs-bundle reconciles (the bundle `.tsx` + real tokens win — NO-INVENT):**
1. **`Callout` has NO `accent`** — §3's grounded table + the bundle omit it (Callout colors via `intent` →
   semantic families `--bg-<intent>-subtle`/`--fg-<intent>`/`--border-<intent>`); §4's listing of Callout as an
   accent-bearer was a summary error.
2. **`Skeleton` has NO `variant`** — §3 listed a stray "variant"; the bundle surface is
   `width`/`height`/`radius`/`circle`. Built the real surface.
3. **`DataList` HAS `labelWidth?: number` (default 140)** — real in the bundle, omitted from §3; kept (the
   horizontal term-column width), realized as a non-color dynamic inline on the `<dt>`.

**Translation notes (built to intent):** `Code` `accent` = per-component inline union → `.mx-code--accent-<id>`
compounded with `--<variant>` (24 rules; the solid-fill ink uses `--slate-1`/`--slate-12` for contrast — a
canon-permitted low-level swatch, no semantic "ink-on-accent" alias exists). `ScrollArea`'s bundle `document.head`
`<style>` injection translated OUT into `.mx-scrollarea` webkit rules reading **semantic neutral tokens**
(`--border-primary`/`--border-strong`, not the bundle's raw `--slate` ramps) — no runtime injection. `Skeleton`'s
bundle keyframe injection likewise moved into `.mx-skeleton`. `Collapsible` chevron = `"chevron-down"` (the live
Icon name; the bundle's `chevDown`/`warning`/`circleHelp` are absent → Callout icons remapped to
`info`/`check`/`alert`/`help-circle`). `CollapsibleItem` (a bundle extra) NOT ported — out of the spec'd surface.

**Carry to mx.7.3:** **(L4)** **ground every prop in the bundle `.tsx`, not the §3 summary** — §3/§4 drifted 3×
this batch (Callout-accent, Skeleton-variant, DataList-labelWidth); the bundle source + real tokens are the
truth. **(L5)** **bundle glyph names ≠ the live Icon set** — remap to a real `keyof typeof ICONS` (typed, so
`sb:typecheck` backstops a miss). **(L6)** **translate runtime `<style>` injection OUT into `additions.css`** —
never `document.head.appendChild` in a component.
