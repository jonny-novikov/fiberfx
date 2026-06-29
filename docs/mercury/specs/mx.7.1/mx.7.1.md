# mx.7.1 · Import batch 1 — foundational primitives

> **Status: 📋 PLANNED — build-ready; batch 1 of the mx.7 import epic.** Inherits the epic frame
> [`../mx.7/mx.7.md`](../mx.7/mx.7.md) (the cross-batch forks, the cadence, the shared translation contract).
> This batch imports the **5 foundational primitives** everything else composes — `Heading · Text · Label ·
> IconButton · Separator` — translated from the bundle's inline-style prototypes into `@mercury/ui`'s `.mx-*`
> + token idiom, additively. **Foundational-first:** later batches (and mx.8/mx.9) compose these.
>
> **Risk: NORMAL (a small, pure-presentational growth rung).** Five primitives, no portal/focus-trap/state
> machine. Load-bearing hazards: (a) the `Separator`↔`Divider` collision (§A — Operator rules; never rename
> `Divider`); (b) the bundle's `accent?: AccentId` prop on `Heading`/`Text`/`Label` carrying the bundle-local
> `mercAccent` helper into the library (Cross-fork I forbids it — realize `accent` as `.mx-*--accent-*` token
> classes); (c) `IconButton` re-implementing `Button` instead of reusing the shared button tokens.
>
> **Inherited, not re-argued here** (see the epic §4/§5): translate to `.mx-*` + tokens (Cross-fork I);
> additive-only token/font policy (Cross-fork II); never rename an existing export (Cross-fork III); design
> flows DOWN, no `/design-sync` (INV-8); the 4-file home + the additive barrel + the gate.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · epic: [`../mx.7/mx.7.md`](../mx.7/mx.7.md) ·
contract template: [`../../contracts.md`](../../contracts.md) · acceptance:
[`mx.7.1.stories.md`](./mx.7.1.stories.md) · build context: [`mx.7.1.llms.md`](./mx.7.1.llms.md).

---

## A · The one open call in this batch — the `Separator` ↔ `Divider` collision (Operator rules)

Policy is ruled in the epic (Cross-fork III): **never rename an existing export.** The specific call lands here
because `Separator` lands here.

- **Rationale.** Live `@mercury/ui` exports `Divider` (`foundations/Divider`, `<hr className="mx-divider">` +
  vertical + labelled variants). The bundle's `Separator` (`layout/Separator`) is the same role with a slightly
  richer API (`orientation` · `label` · `size` · `decorative`). Adding `Separator` while `Divider` exists is
  additive-legal; renaming `Divider` → `Separator` is **forbidden** (master invariant).
- **Arms.** **(a) Add `Separator` net-new + keep `Divider` (RECOMMENDED)** — both export; `Separator` carries the
  Claude-Design name + the `decorative`/`size`/vertical API; the two contracts cross-link. **(b) Keep `Divider`
  only, skip `Separator`** — no new surface, but the bundle's API + the Claude-Design name are absent. **(c) Add
  `Separator` as the alias `export { Divider as Separator }`** — one impl, two names, but `Separator`'s API then
  equals `Divider`'s (not the bundle's richer one).
- **Steward / recommendation: (a)** — additive is exactly what the master invariant makes free. **Operator
  rules** (a public-surface posture call: parity-naming vs minimal-surface).

## 0 · The slice

The first import batch. The five components are the primitives the rest of the library + the apps compose:
`Heading`/`Text` (the type primitives), `Label` (form captions), `IconButton` (icon-only actions),
`Separator` (the rule). Each is translated into the live idiom and exported additively; nothing portals,
traps focus, or holds async state — the lowest-risk wave, shipped first so mx.7.2–7.4 and mx.8/mx.9 build on it.

## 1 · Goal

After mx.7.1, `@mercury/ui` exports **5 new components** — `Heading · Text · Label · IconButton · Separator`
(per Fork A) — each a translated 4-file home (`.mx-*` + tokens · hand-authored contract · CSF3 story). The
barrel is **strictly additive** (every prior export byte-preserved; +5 names + their `Props`). The full package
gate is green; `sb:build` registers exactly the prior homes + 5; the barrel-diff shows 0 removed/renamed.

## 2 · Rationale (5W)

- **Why.** These primitives are the foundation later batches compose (a `Dialog` title is a `Heading`; a Card
  field is a `Label` + `Text`; an overlay close is an `IconButton`; a menu group ends with a `Separator`).
  Importing them first de-risks every later batch.
- **What.** The five translated components (4-file homes), the barrel grown +5, the `.mx-*` rules in
  `src/styles/additions.css`, and (only if a component needs weight 600) the additive DM Sans 600 `@font-face`.
- **Who.** *Authored by* the architect (this triad) + the batch's build/verify agents (epic §2 cadence).
  *Consumed by* mx.7.2–7.4, mx.8 (their stories), mx.9 (the showcase), and the workspace consumers.
- **When.** Batch 1 — first in the import epic, with the Operator in the loop before mx.7.2.
- **Where.** Only `packages/mercury-ui/src/` (the 5 folders + barrel + `additions.css`; + a font line if needed)
  + `docs/mercury/specs/mx.7.1/`. The bundle `packages/mercury-ds/` is read-only.

## 3 · The component set (grounded — bundle prop surface verified in source)

| Component | Bundle source | Prototype prop surface (verified — the seed) | Live target group |
|---|---|---|---|
| `Heading` | `foundations/Heading/Heading.tsx` | `size?: 1..9` · `weight?: regular\|medium\|semibold\|bold` · `align?` · `as?: h1..h6\|div` · `color?` · `accent?: AccentId` · `truncate?` | `foundations` |
| `Text` | `foundations/Text/Text.tsx` | `variant?: TextVariant` · `color?` · `accent?: AccentId` · `italic?` · `align?` | `foundations` |
| `Label` | `inputs/Label/Label.tsx` | `htmlFor?` · `required?` · `optional?` · `disabled?` · `size?: sm\|md\|lg` · `accent?='red'` · `hint?` | `inputs` |
| `IconButton` | `actions/IconButton/IconButton.tsx` | `icon` · `label` (aria) · `variant?: primary\|secondary\|outline\|ghost\|destructive` · `size?: sm\|md\|lg` · `shape?: circle\|square` · `disabled?` · `type?` | `actions` |
| `Separator` | `layout/Separator/Separator.tsx` | `orientation?: horizontal\|vertical` · `label?` · `size?` · `decorative?=true` | `foundations` (beside `Divider`) or `layout` — group note |

> **Group note (D-4-class, not a blocker):** `Separator` may sit in `foundations` (beside `Divider`, its sibling)
> or `layout` (the bundle's group). Recommend `foundations` for the cross-link locality; the export name is what
> the barrel encodes, so the group is a navigability choice, not a correctness one.

## 4 · Translation notes (the deltas beyond the epic's shared idiom)

- **The `accent?: AccentId` prop (Heading/Text/Label) — realize WITHOUT `mercAccent`.** The bundle resolves
  `accent` at runtime via `_lib/accent.ts` `mercAccent(id)`. Per Cross-fork I, **do not import `mercAccent` into
  `@mercury/ui`.** Realize the capability as enum-driven token classes: `cx("mx-<name>", accent &&
  \`mx-<name>--accent-${accent}\`)` with `.mx-<name>--accent-iris { color: rgb(var(--iris-11)); }` … one rule per
  ramp (`iris\|indigo\|green\|orange\|plum\|red`, the `mercAccent` set, all real token ramps). This preserves the
  bundle's capability in the live idiom with zero new runtime helper. *(Director-ratifiable; the alternative —
  dropping `accent` — loses a documented capability and is not recommended.)*
- **Heading — the canon's DM Mono display face.** Per canon §type, the large heading sizes are set in **DM Mono**
  (`--font-secondary`), not DM Sans — the distinctive Mercury "technical headline". The `.mx-heading--<size>`
  rules pick `--font-secondary` at the display sizes and `--font-primary` at the small ones. Map the bundle's
  `size: 1..9` onto the canon scale (18/24/36/48/72 … per the bundle README type scale).
- **IconButton — reuse the button token surface, do not re-implement `Button`.** `IconButton`'s
  `variant`/`size` unions are **identical** to `ButtonProps`' (`primary\|secondary\|outline\|ghost\|destructive`
  × `sm\|md\|lg`). Translate to `.mx-icon-btn` reading the same button tokens (or share `.mx-btn--<variant>`),
  **always `--radius-full`** for `shape="circle"` (canon: icon buttons are fully round), `--radius-8`/`--radius-6`
  for `shape="square"`. **a11y:** `label` → `aria-label` (icon-only controls require it — canon §8).
- **Label — the required marker.** The bundle tints the `*` via `mercAccent("red").fg`; translate to
  `.mx-label__req { color: rgb(var(--red-11)); }`. `optional` renders a muted `(optional)` in `--fg-tertiary`.
- **Text/Separator** — straight idiom translation (Text: `.mx-text--<variant>` reading the `--fg-*` families;
  Separator: `.mx-separator` reading `--border-secondary`, the labelled + vertical variants from the prototype).

## 5 · Deliverables

- **K-1 — 5 translated 4-file homes** under `packages/mercury-ui/src/components/<group>/<Name>/`
  (`<Name>.tsx` translated · `index.ts` · `<Name>.prompt.md` hand-authored · `<Name>.stories.tsx` CSF3).
- **K-2 — the barrel grows +5 additively** (`Heading`/`Text`/`Label`/`IconButton`/`Separator` + their `Props`);
  every prior export byte-preserved; barrel-diff 0 removed/renamed.
- **K-3 — the live idiom** (Cross-fork I): `.mx-*` classes + tokens; no inline color literal; no raw hex; the
  `accent` prop via `.mx-*--accent-*` classes (no `mercAccent` import).
- **K-4 — a hand-authored contract per component** (D-7): mx.2 format; no bundle runtime framing; cross-links
  (`Heading`↔`Text`; `IconButton`↔`Button`+`Icon`; `Separator`↔`Divider`; `Label`↔the inputs it captions).
- **K-5 — the 1:1 story↔folder invariant holds** (mx.4 S-1): each folder one co-located story; `sb:build` +5
  homes.
- **K-6 — the `Separator` collision is ruled, no rename** (Fork A): `Divider` untouched; `Separator` per the
  Operator's arm.
- **K-7 — the token/font reconcile is additive-only** (Cross-fork II): a `tokens.css`/font edit is a new line
  (the DM Sans 600 candidate, only if `Heading`/`Label` need weight 600), never a value change.
- **K-8 — the gate is green** (§7) and **design flowed DOWN only** (no `/design-sync`).

**Coverage:** K-1 → S-1..S-5 ; K-2 → S-6 ; K-3 → S-1..S-5 ; K-4 → S-1..S-5 ; K-5 → S-7 ; K-6 → S-3(Separator) ;
K-7 → S-8 ; K-8 → S-9.

## 6 · The per-component translation map (grounded)

- **Heading** (`foundations/Heading` → `foundations/Heading`). `.mx-heading` + `--<size>` (1..9 → the canon
  18..72 scale) + `--<weight>`; DM Mono at the display sizes; `as`/auto h-level; `accent` via `.mx-heading--accent-*`;
  `truncate` → ellipsis. Cross-link `Text`.
- **Text** (`foundations/Text` → `foundations/Text`). `.mx-text` + `--<variant>` reading `--fg-*`; `italic`/`align`;
  `accent` via classes. Cross-link `Heading`.
- **Label** (`inputs/Label` → `inputs/Label`). `.mx-label` (`<label htmlFor>`); `required` marker (`--red-11`),
  `optional` muted, `hint` in `--fg-tertiary`; `size` sm/md/lg. Cross-link the input components.
- **IconButton** (`actions/IconButton` → `actions/IconButton`). `.mx-icon-btn` sharing the button tokens;
  `variant`/`size` = Button's unions; `shape` circle(`--radius-full`)/square; `label`→`aria-label`. Cross-link
  `Button` + `Icon`.
- **Separator** (`layout/Separator` → `foundations/Separator`, group note). `.mx-separator` reading
  `--border-secondary`; `orientation`/`label`/`size`/`decorative`. Cross-link `Divider`.

## 7 · Invariants — as runnable gates (run from `mercury/`)

- **INV-1 — master invariant, additive.** Resolved export set after = superset of before; **0 removed/renamed**,
  +5 (+ `Props`). (TS `getExportsOfModule`, not a text-diff.)
- **INV-2 — live idiom, no inline color leak.**
  `grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})" packages/mercury-ui/src/components/{foundations/Heading,foundations/Text,foundations/Separator,inputs/Label,actions/IconButton}` → **empty**.
- **INV-3 — no raw hex.** `grep -rnE "#[0-9a-fA-F]{3,8}\b"` over the 5 new dirs + the new `additions.css` rules →
  **empty**.
- **INV-4 — no `mercAccent` import into the library.**
  `grep -rn "mercAccent\|_lib/accent" packages/mercury-ui/src/components` → **empty** (the `accent` prop is class-driven).
- **INV-5 — D-7 contract, no bundle framing.** Each new `.prompt.md` has the mx.2 sections;
  `grep -rniE "check_design_system|pixel-perfect|/design-sync|showcase/" <new contracts>` → **empty**.
- **INV-6 — 1:1 story↔folder + `sb:typecheck` clean.** `count(*.stories.tsx) == count(component folders)`;
  `pnpm sb:typecheck` exits 0 (the authoritative story NO-INVENT gate); `pnpm sb:build` registers prior + 5.
- **INV-7 — token/font additive-only.** `git diff …/styles/tokens.css` shows added lines only (no changed value).
- **INV-8 — design flows DOWN.** No `/design-sync`/`DesignSync` in the work; `git diff` touches no
  `mercury/.design-sync/` path; nothing pushes up.
- **INV-9 — the package gate.** `pnpm --filter "./packages/*" typecheck`/`build` = 0 · `pnpm --filter "./apps/*"
  --filter "!@mercury/storybook" build` = 0 (`echomq`+`mobile`) · `pnpm sb:build` = 0.

## 8 · The batch loop (epic §2) — Operator → Agent-1 → Agent-2 → Operator

Operator sharpens this triad → **Agent-1** reconciles (lag-1 vs the as-built `@mercury/ui` + the bundle) and
builds the 5 homes → **Agent-2** re-runs the gate, reconciles spec↔code, hardens, fills §9 → Operator reviews the
+5 Storybook homes + the gate, then **carries the lessons into mx.7.2's brief** and releases batch 2. Feedback
edits this spec, never the code directly.

## 9 · As-built (verified — BUILD-GRADE)

**Verdict: BUILD-GRADE** (Director independent verify, 2026-06-30). Fork A → **arm (a)**: `Separator` net-new in
`foundations`; `Divider` byte-unchanged. All K-1..K-8 / INV-1..INV-9 / S-1..S-9 **MATCH**.

**Shipped — 5 four-file homes** (20 files): `foundations/Heading` · `foundations/Text` · `foundations/Separator` ·
`inputs/Label` · `actions/IconButton`. Barrel +5 `export *` (additive, under the group comments); `additions.css`
+5 `.mx-*` blocks + the 6-ramp accent classes; `Divider.prompt.md` gained the reciprocal `Separator` sibling link.

**Gate (re-run independently, EXIT 0):** `pnpm --filter "./packages/*" typecheck` ✓ · `build` ✓ · `pnpm --filter
"./apps/*" --filter "!@mercury/storybook" build` ✓ (echomq + mobile) · `pnpm sb:typecheck` ✓ · `pnpm sb:build` ✓.
**Master invariant:** resolved export set **107 → 127** (+20 = 5 components + 5 `Props` + 10 aux enum types);
**0 removed/renamed** — proven by the collision sweep (no new name appears outside the 5 folders) + index.ts
additions-only + no existing folder edited. **Hygiene greps empty:** inline-color (INV-2), raw-hex (INV-3),
`mercAccent`/`_lib/accent` (INV-4), bundle-framing (INV-5). **No `/design-sync`** (INV-8). **Mutation spot-check:**
breaking `IconButton`'s `aria-label` → `tsc` TS2304, restored net-zero — the gate has teeth.

**INV-7 token/font — additive, nothing changed.** `tokens.css` byte-unchanged. The **DM Sans 600 `@font-face` was
NOT added**: `font-weight: 600` with `--font-primary` is already the live pattern (`.mx-money__ccy`,
`.mx-pag__btn.is-active`, `mercury.css` …) with no dedicated face — adding one for a nonexistent SemiBold woff2
would be harmful. INV-7's "fold only if the live layer lacks it" is satisfied.

**Realization deviations (built to intent — all verified defensible):**
1. **`color?` dropped** (Heading/Text) — the bundle's `color?: string` is an arbitrary-token → inline-`rgb()`
   escape hatch (forbidden by Cross-fork I / INV-2); §6 (the build target) omits it. Recolor via `accent`.
2. **`accent` is an inline per-component union, not an exported `AccentId`** — three `export type AccentId` via
   `export *` would collide in the barrel and **silently drop** the name. Identical surface, zero collision.
3. **`IconButton` shares `.mx-btn--<variant>`** (fill/ink) + own `.mx-icon-btn` geometry; CSS `:hover/:active`
   (no `useState`); no `inverse`. A cascade rule re-asserts the secondary/outline border.
4. **`Heading` size 1..9 → the 9-step canon scale topping at 72** (DM Sans 1–4, DM Mono 5–9; default 6). The
   spec §4 "18..72" note is reconciled to the exact as-built ramp (it starts at 14, not 18).
5. **`Text` `accent` on `quote`** recolors ink only; the inline-start rule stays `--border-strong`.

**Carry to mx.7.2:** **(L1)** realize a multi-component shared enum (like `accent`) as a **per-component inline
union**, never a shared `export type` — `export *` silently drops a duplicated type name (a gate-invisible barrel
removal). **(L2)** the **DM Sans 600 face is absent**; weight 600 rides `--font-primary` via the established
local()/synthesis pattern — do not add a `@font-face` for a missing woff2. **(L3)** a reciprocal cross-link to an
**existing** sibling contract (here `Divider`) is in-scope for the batch even though the sibling sits outside the
new folders — author both directions.
