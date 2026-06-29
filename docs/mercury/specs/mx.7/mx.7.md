# mx.7 · EPIC — Import the Claude-Design net-new components into `@mercury/ui`

> **Status: EPIC (5-batch) — Operator-ruled BATCHED 2026-06-29; the overlay batch split 7.4→7.4+7.5, Operator-approved.** The first stretch of the **Movement-III
> tail** (the new ladder mx.7 · mx.8 · mx.9, replacing the dropped mx.6). The bundle `packages/mercury-ds/`
> (the Operator's Claude-Design handoff) carries **53** components; the live `@mercury/ui` barrel exports
> **35**. mx.7 imports the **30 net-new** (+ 2 folds) into `@mercury/ui`, **translated** out of the
> bundle's inline-style prototype idiom into the library's `.mx-*` className + token convention, **additively**
> (the barrel master invariant holds: additions OK; never a removal or a rename).
>
> **This file is the EPIC FRAME, not a buildable rung.** It carries what all five batches inherit: the batch
> table (which components land where), the per-batch ship cadence, and the four cross-batch forks (framed once,
> ruled once, inherited by every batch). The buildable rungs are the five batch triads
> [`../mx.7.1/`](../mx.7.1/mx.7.1.md) · [`../mx.7.2/`](../mx.7.2/mx.7.2.md) ·
> [`../mx.7.3/`](../mx.7.3/mx.7.3.md) · [`../mx.7.4/`](../mx.7.4/mx.7.4.md) ·
> [`../mx.7.5/`](../mx.7.5/mx.7.5.md). There is **no** `.stories.md` /
> `.llms.md` at this epic level.
>
> **Design flows DOWN, never UP.** The bundle is a one-way handoff: Claude Web (the Operator's design project
> `https://claude.ai/design/p/22dd5e3f-ad2c-4d0a-948b-33e9ab1bed0d`) → the `mercury-ds` bundle → translated into
> `@mercury/*`. Every batch reads the bundle and writes `@mercury/ui`. **It is FORBIDDEN to run `/design-sync`**
> or invoke the `DesignSync` MCP or push anything back up. (Inherited as INV-8 in every batch.)
>
> **The decisions this epic carries (Operator-ruled — recorded VERBATIM):**
> - **The import is BATCHED into mx.7.1 · mx.7.2 · mx.7.3 · mx.7.4 · mx.7.5**, sized by **effort, not count**,
>   **foundational-first** (later batches compose earlier ones), with the **Operator in the feedback loop
>   between every batch**.
> - **mx.7 imports the bundle's net-new components → `@mercury/ui`.** The source of truth after translation is
>   the `@mercury/ui` library; the bundle `.tsx` is a prototype to translate, not to drop in.
> - **`/design-sync` is FORBIDDEN.** Design flows DOWN only.
> - **The ladder is mx.7 (import, 4 batches) → mx.8 (stories) → mx.9 (showcase application).** mx.8/mx.9 ladder
>   behind the **completed** import (mx.7.4). mx.6 (apps-side Pages) is DROPPED.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · roadmap:
[`../../mercury.roadmap.md`](../../mercury.roadmap.md) · dashboard:
[`../../mercury.progress.md`](../../mercury.progress.md) · prior triad:
[`../mx.5/mx.5.md`](../mx.5/mx.5.md) · contract template:
[`../../contracts.md`](../../contracts.md) · method:
[`../../../aaw/aaw.framework.md`](../../../aaw/aaw.framework.md) · architect approach:
[`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md).

---

## 1 · The batch table (Operator-ruled; rebalance between batches as effort warrants)

Sized by **effort**, **foundational-first**. The split is grounded in the registry-vs-barrel diff (§3). The
**effort-unit** column is a Venus estimate (1 unit ≈ one small presentational primitive fully translated +
contract + story); the Operator's target band is ~4–6 units/batch.

| Batch | Theme | Net-new components (the import set) | Count | Effort (est.) | Name-collision called out here |
|---|---|---|---|---|---|
| **mx.7.1** | foundational primitives (everything composes these) | `Heading` · `Text` · `Label` · `IconButton` · `Separator` | 5 | **~5** | `Separator` ↔ live `Divider` |
| **mx.7.2** | simple feedback/display + layout | `Callout` · `Spinner` · `Skeleton` · `Blockquote` · `DataList` · `Code` · `Kbd` · `AspectRatio` · `Collapsible` · `ScrollArea` | 10 | **~6–7** | `Collapsible` ↔ live `Accordion` (distinct, no rename) |
| **mx.7.3** | input/selection composites | `DateField` · `Calendar` · `CheckboxGroup` · `CheckboxCards` · `RadioGroup` · `RadioCards` (+ folds `TextArea`→`Textarea`, `ToggleGroup`→live) | 6 (+2 folds) | **~7–8** | `TextArea` & `ToggleGroup` ↔ live (folds — no new export) |
| **mx.7.4** | the overlay-floor + the dialog family | `Dialog` · `AlertDialog` · `Popover` (+ the shared overlay-floor primitive) | 3 | **~5–6** | `Dialog` ↔ live `Modal` |
| **mx.7.5** | menus, hover cards & nav (consume the floor) | `Dropdown` · `ContextMenu` · `HoverCard` · `LinkPreview` · `Menubar` · `TabNav` | 6 | **~5–6** | `Menubar`/`TabNav` group placement (D-4) |

**Folds (no new export):** `TextArea` ≡ live `Textarea`, and `ToggleGroup` ≡ the already-exported live
`ToggleGroup` (from `selection/Toggle`), are reconcile-surfaced existing exports — each a batch *work item* in
mx.7.3 (translate the bundle's enhancements into the live export), but adds **no** new export (renaming the live
export is forbidden — Cross-fork III). *(Reconcile finding: the original table listed `ToggleGroup` as net-new;
mx.7.3 verified it is already live — corrected to a fold, dropping the net-new count 31→30.)*

> **Effort-rebalance status (one ruled, one available).** **mx.7.4 is SPLIT — Operator-approved 2026-06-29:**
> the original ≈10–12-unit overlay batch is now **mx.7.4** (the overlay-floor primitive + `Dialog`/`AlertDialog`/
> `Popover`, ~5–6u) and **mx.7.5** (`Dropdown`/`ContextMenu`/`HoverCard`/`LinkPreview`/`Menubar`/`TabNav`, ~5–6u)
> — both in-band; the floor is built in 7.4 and consumed by 7.5. **One rebalance remains available** (a surfaced
> observation, not ruled): **mx.7.3 (~7–8u)** is over-band, dominated by `Calendar`+`DateField` (a date grid +
> `@internationalized/date` keyboard machinery); shedding those into their own date batch would leave 7.3 (the 4
> selection composites + the 2 folds) squarely in-band. The Operator rebalances in the seat between batches.

## 2 · The per-batch cadence — Operator → Agent → Agent → Operator

Every batch ships through the same loop, with the **Operator in the seat between batches** (this is the AAW-light
Duo/Trio, per [`../../../aaw/aaw.framework.md`](../../../aaw/aaw.framework.md)):

1. **Operator — sharpen.** Confirm/feedback the batch's scope against this epic + the prior batch's lessons.
   **Feedback edits the spec, never the code directly** (AAW law).
2. **Agent-1 — architect-reconcile + build.** Reconcile the batch triad against the as-built `@mercury/ui` +
   the bundle source (the lag-1 reconcile), then build the batch to the brief (translate the components, author
   the contracts, add the stories + styles, grow the barrel additively).
3. **Agent-2 — verify + harden.** Re-run the gate independently, reconcile spec↔code, harden, classify every
   promise MATCH/STALE/INVENTED/MISSING, fill the batch's §9 as-built.
4. **Operator — review/demo.** Accept at the boundary (the gate + the new Storybook homes), then **carry the
   batch's lessons forward** into the next batch's brief, and release the next batch.

**The batches feed each other.** A later batch composes earlier components (`mx.7.4` overlays compose `mx.7.1`
`IconButton`/`Heading`/`Separator`; `mx.7.3` Cards compose `mx.7.1` `Label` + the existing `Checkbox`/`Radio`).
Each batch's `.llms.md` carries a "lessons from the prior batch" slot the Director fills at release.

> **Naming.** Spec dirs/files stay **dotted** (`mx.7.1/mx.7.1.md`), matching the mx.5 convention. When a batch
> later ships and stands up an aaw team, its **scope slug is the dashed form** (`mx-7-1`, never `mx.7.1` — a dot
> split-brains the aaw registry). No teams are created at authoring time.

## 3 · The net-new inventory (reconciled — `mercury-ds/project/components/registry.ts` diff vs the live barrel)

The bundle `registry.ts` lists **53** components; the live barrel `packages/mercury-ui/src/index.ts` exports
**35** component folders. Verified name-by-name:

- **21 re-prototypes of an existing export** (same export name — **no new surface**; the bundle `.tsx` is a
  newer prototype, reconciling it is out of mx.7 scope): `Icon · Button · Input · Select · Slider · Checkbox ·
  Radio · Switch · Toggle · Segmented · Avatar · Badge · Chip · Progress · Table · Alert · Modal · Tooltip ·
  Tabs · Link · Card`.
  - **Group-difference notes (no barrel collision — same export name):** bundle `Link` is in `navigation/`
    (live `actions/Link`); bundle `Card` is in `layout/` (live `data-display/Card`); bundle `Slider` is in
    `inputs/` (live `selection/Slider`). The barrel encodes the **name**, not the group — keep the live
    placement; these are re-prototypes, not net-new. Group placement is a D-4-class judgment, not a correctness
    issue.
- **2 folds** (mx.7.3): bundle `TextArea` ≡ live `Textarea`, and bundle `ToggleGroup` ≡ the already-exported
  live `ToggleGroup` (`selection/Toggle`) — both folds, no new export. *(The second was reconcile-surfaced by
  mx.7.3, dropping the net-new count 31→30.)*
- **30 net-new by export name** — the import target, distributed across the five batches (the §1 table). The
  per-component bundle source path + live target group + translation notes live in **each batch's** `.md` §6
  (so the build-grade grounding sits with the buildable rung, not the epic).

## 4 · The four cross-batch forks — framed once, inherited by every batch

These are ruled **once, here**; no batch re-frames them. (The scope fork — "one rung vs batches" — is already
RESOLVED: batched. It is not re-litigated.)

### Cross-fork I — styling idiom: **translate to `.mx-*` + tokens** (Director-ratifiable; Steward = translate)

The bundle styles **inline** (`mercury-ds/.../Separator/Separator.tsx`:
`<div style={{ height: 1, background: "rgb(var(--border-secondary))" }} />`). Live `@mercury/ui` styles via a
**private `.mx-*` className** + a rule in `src/styles/` (`Divider.tsx`: `<hr className={cx("mx-divider", …)} />`).
**Every batch translates** each component into the live idiom — a `forwardRef`/function component, props
extending the HTML attrs, `cx("mx-<name>", …)` classes, and a `.mx-<name>` rule in `src/styles/additions.css`
reading `rgb(var(--token))`. Never adopt the inline-style idiom; never a raw hex (token discipline, canon §6).
The bundle README's own directive: "recreate pixel-perfectly … don't copy the prototype's internal structure."
The `_lib/accent.ts` `mercAccent` helper is **bundle-local** — a translated component uses the live token
families directly (`--bg-brand`, `--bg-active`, the `--<ramp>-9` scales) via its `.mx-*` rule; it does **not**
import `mercAccent` into `@mercury/ui`.

### Cross-fork II — token/font reconcile: **additive-only, do-no-harm** (Director-ratifiable; Steward = additive)

On the evidence this is a **non-event**. The live `tokens.css` already carries the bundle's semantic aliases at
**identical values** (verified: `--iris-9: 91 91 214`, `--bg-brand: var(--iris-9)`, `--bg-active-subtle:
var(--indigo-3)`, the full radius scale 2/4/6/8/12/16/20/24/32/full, and `@font-face` for all three DM families —
DM Sans 400/500/700, DM Mono 300/400/500, DM Serif Display 400 — already self-hosted under
`src/styles/fonts/`). The mx.1 finding stands: the only bundle delta is `/* @kind color */` design-sync
annotations (identical values), harmful noise to fold. So **every batch's token/font policy is: fold in a
token/weight ONLY if a translated component in that batch requires one the live layer lacks, and never change an
existing value.** The single known candidate is **DM Sans 600 (Semibold)** (the bundle ships
`DMSans-Semibold.woff2`; live self-hosts 400/500/700) — fold it the first batch a component needs weight 600.

### Cross-fork III — name-collision policy: **never rename an existing export; fold or add-distinct** (Operator rules each)

The master invariant **forbids renaming or removing an existing export**, so a collision is resolved by *folding
into the existing one* or *adding a distinct new name* — never by renaming the live export. The **policy** is
ruled here; each **specific** collision is called out in the batch where the component lands:

| Collision | Lands in | Resolution (Venus rec; Operator rules) |
|---|---|---|
| bundle `TextArea` ↔ live `Textarea` | mx.7.3 | **Fold** — case-difference of the same component; translate enhancements INTO `Textarea`; add **no** new export (renaming `Textarea` is forbidden). |
| bundle `Separator` ↔ live `Divider` | mx.7.1 | **Add `Separator` net-new + keep `Divider`** (additive; the bundle's richer vertical/labelled/`decorative` API under the Claude-Design name). Alt arms (alias, or skip) in mx.7.1 §A. **Operator rules.** |
| bundle `Dialog` ↔ live `Modal` | mx.7.4 | **Add `Dialog` net-new** (Radix-style composable parts) vs alias to `Modal` — ruled in mx.7.4 with the overlay-floor ADR. **Operator rules.** |
| bundle `Collapsible` ↔ live `Accordion` | mx.7.2 | **Add net-new** — distinct role (single disclosure vs a set); no rename, no true collision. |

### Cross-fork IV — the bundle's git fate: **leave untracked + ignored, regenerable** (Operator rules)

`packages/mercury-ds/` is a **new, untracked** handoff (~900 KB `_ds_bundle.js` + generated manifest + 53
prototypes), the Operator's, regenerable from Claude Web. Arms: **(a) leave untracked + add to the ROOT
`.gitignore`, regenerable (RECOMMENDED)** — the Operator regenerates on demand; each batch reads it and writes
`@mercury/ui`; the bundle never enters git (it would drift against Claude Web + bloat the repo). **Caveat:** the
jonnify root `.gitignore` has a bare `.gitignore` rule that swallows nested ignore files — add the `mercury-ds`
ignore to the **root** registry, verify with `git check-ignore -v`. **(b) Consumed-then-deleted** (the mx.1
precedent — mx.1 salvaged then deleted the prior ephemeral `mercury-ds`); delete after mx.7.4. **(c)
Tracked-vendored** — commit it; cost: ~900 KB of generated JS in git, guaranteed drift. **Steward: (a) during
the batches, folding into (b) — delete after mx.7.4.** **Operator rules** repo policy. (Every batch keeps the
bundle OUT of its commit pathspec regardless.)

## 5 · What every batch inherits (the shared contract — do not re-state per batch)

- **The translation idiom** (Cross-fork I): `.mx-<name>` classes + `cx` from `@mercury/core` + tokens via
  `rgb(var(--token))`; `forwardRef`; extend the HTML attrs; React-19 nullable-`useRef().current` guard.
- **The 4-file home** per component: `<Name>.tsx` (translated) · `index.ts` (`export * from "./<Name>"`) ·
  `<Name>.prompt.md` (**hand-authored**, mx.2 format / D-7 — the bundle `.prompt.md` is the prop-list seed only,
  strip all runtime framing) · `<Name>.stories.tsx` (CSF3, mx.4 shape — preserves the 1:1 story↔folder invariant).
- **The barrel grows additively** (master invariant, INV-1): every prior export byte-preserved; resolve the full
  export set (TS `getExportsOfModule`), not a text-diff.
- **The token/font policy** (Cross-fork II): additive-only, do-no-harm.
- **Design flows DOWN** (INV-8): no `/design-sync`, no `DesignSync`, no push up.
- **The gate** (run from `mercury/`): `pnpm --filter "./packages/*" typecheck`/`build` · `pnpm --filter
  "./apps/*" --filter "!@mercury/storybook" build` (the workspace apps `echomq` + `mobile`) · `pnpm sb:typecheck`
  (the authoritative story NO-INVENT gate) · `pnpm sb:build` (+ the batch's home count) · the barrel-diff (0
  removed/renamed) · the idiom/raw-hex/framing/no-design-sync greps (empty).
- **Commit hygiene:** the bundle `packages/mercury-ds/` stays out of the commit pathspec; `mercury/…` pathspec
  only; never `git add -A`; never `pnpm -r` (use `--filter`).

## 6 · Out of scope (epic-wide)

- The **Storybook enrichment** (palette/roundings/variant-switching/actions/real-world scenes) — that is
  **mx.8**, laddering behind the completed import. Each batch's stories are the basic mx.4-shape homes only.
- The **showcase application** — that is **mx.9**.
- Reconciling the **21 re-prototypes** of existing exports against their newer bundle `.tsx` (a separate
  reconcile; mx.7 only *adds* net-new surface).
- Any **rename/removal** of an existing export, or any **value change** to an existing token.
- `/design-sync`, the `DesignSync` MCP, any push to Claude Web (FORBIDDEN).
- Editing the roadmap/progress/design — the Director folds at each batch's ship (the 7.x row → BUILT, a `D-`
  per ruled collision, the running barrel-jump).

## Map

The five batch triads: [`../mx.7.1/mx.7.1.md`](../mx.7.1/mx.7.1.md) ·
[`../mx.7.2/mx.7.2.md`](../mx.7.2/mx.7.2.md) · [`../mx.7.3/mx.7.3.md`](../mx.7.3/mx.7.3.md) ·
[`../mx.7.4/mx.7.4.md`](../mx.7.4/mx.7.4.md) · [`../mx.7.5/mx.7.5.md`](../mx.7.5/mx.7.5.md). Then
[`../mx.8/mx.8.md`](../mx.8/mx.8.md) (stories) and
[`../mx.9/mx.9.md`](../mx.9/mx.9.md) (the showcase application). The bundle: `packages/mercury-ds/` (read-only
input). The live library: `packages/mercury-ui/src/components/` + the barrel `src/index.ts`.
