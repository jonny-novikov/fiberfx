# MX.9.5 · build context (the agent brief)

Build context for [`mx.9.5.md`](./mx.9.5.md) (authoritative body) + [`mx.9.5.stories.md`](./mx.9.5.stories.md).
The body wins on any disagreement. **BUILD-GRADE** — re-sharpened at ship 2026-07-02: the seed census ran, the
Operator ruled the skin scope (body §7: **Arm A — the clean token skin; F1–F4 declined; zero new token, zero
new dependency**), and this brief carries the distilled region table. The builder's first actions are WRITES.

> **Framing (propagate — do not drop):** no gendered pronouns for agents; no perceptual or interior-state
> verbs; no first-person narration. State each surface as a contract.

## References (pre-ground — read ≤3 files, then write)

1. **The donor** — `mercury/packages/mercury-ds/project/showcase/app.css` (453 lines; read-only, untracked,
   out of every pathspec). Already 100% `rgb(var(--token))` — patterns TRANSFER; never copy the file, never
   import a seed path. The region table below cites it by line.
2. **The target** — `mercury/apps/showcase/src/showcase.css` (308 as-built lines: the mx.9.2 structural shell
   + the mx.9.3 story card + the mx.9.4 markdown blocks; line 1 names this rung as the deferred skin) + the
   two shell files `src/shell/Home.tsx` (static inline layout to absorb) and `src/shell/Topbar.tsx` (title hook).
3. **The token truth** — `mercury/packages/mercury-ui/src/styles/tokens.css`; the palette facts below are
   pre-verified (2026-07-02) — re-grep only on doubt.

**Preconditions:** mx.9.3 + mx.9.4 SHIPPED (both hold). **Formation: Squad + Apollo (ELEVATED closer)** —
Apollo runs the doc-source-of-truth and package/app-split adversarial probes; the Director re-runs the gate
independently. **Inherited rulings:** B · C · D · E; **ship ruling Arm A (body §7)**.

## The pre-verified token facts (`tokens.css`, 2026-07-02 — cite, do not re-derive)

- Surfaces `--bg-primary/secondary/tertiary` (:154–156) · `--bg-brand` (:171) · `--bg-brand-subtle` (:174 —
  = `--iris-3`, which **flips in dark**, :325) · the hover scrim `--bg-hover` (:164; dark :341).
- Text `--fg-primary/secondary/tertiary` (:195–197) · `--fg-on-brand` (:200) · `--fg-brand` (:207).
- Borders `--border-primary` (:220) · `--border-secondary` (:221) · `--border-focus` (:224).
- Raw ramps (texture/swatch use only, as the donor itself does): `--slate-3/6/7` (:88–92; **dark overrides
  exist**, :312–316 — the scrollbar + crosshatch flip automatically). `--indigo-3` (:116) has **NO dark
  override** (the dark block redefines only `--indigo-9..12`) — the EXPECTED citation (INV-2).
- **The type scale is a `-size`/`-lh` PAIR convention** — there is NO bare `--text-heading-300` token; a bare
  `var(--text-heading-300)` is a silent CSS no-op. Always use BOTH:
  `font-size: var(--text-heading-300-size); line-height: var(--text-heading-300-lh);` (36px/40px, :257).
- Weights (:242–246): `--fw-regular` 400 · `--fw-medium` 500 · **`--fw-semi-bold` 600 (hyphenated — NOT
  `--fw-semibold`)** · `--fw-bold` 700.
- `--radius-2/4/6/8/12/16/full` (:262–271) · spacing `--space-2..128` (`--space-24` :276; `--space-40/48`
  :277; `--space-80/96/128` :278) · `--shadow-100..600` (:281–295; dark :352–357) · fonts
  `--font-primary/secondary/display` (:238–240).

## Requirements (each traced: story ⇠ requirement ⇢ invariant)

| # | Requirement | Story | Invariant |
|---|---|---|---|
| R-1 | The eight-region skin (topology table below) lands in `showcase.css`, token-expressed, donor-cited per region; no raw hex; no seed copy | S-1 | INV-1 |
| R-2 | Off-scale literals snap to the scale: radii 10/14 → `--radius-8/12/16`; space 88/144 → `--space-80/96/128`; an oversized ambient shadow → `--shadow-600`. **Layout dimensions stay literals** (the 240px column, max-width 1080/760px, the 12px crosshatch interval, min-height 160px) | S-1 | INV-1 |
| R-3 | Motion: 150–200ms ease on bg/color/shadow/opacity for interactive elements (the donor's 120ms snaps UP into the DS band); no infinite decorative loops, no bounces | S-1 | INV-1 |
| R-4 | Home: the STATIC inline layout styles absorb into new `.showcase-home-*` classes; the DYNAMIC per-swatch background style stays inline (token-resolved, runtime-varying, not a hex literal — exact form under EDIT 2) | S-1 | INV-1, INV-4 |
| R-5 | The dual-theme acceptance across groups + both surfaces; the `--indigo-3` soft-bg noted EXPECTED, never failed-on, never RGB-patched | S-2 | INV-2 |
| R-6 | The whole-epic closure re-run: epic INV-1..9 + S-9/S-10 as written; the Apollo probes; the Director independent re-run | S-3 | INV-3 |
| R-7 | Scope: exactly `src/showcase.css` + `src/shell/Home.tsx` (+ optionally `src/shell/Topbar.tsx`); no `packages/**`, no root, no lockfile, zero new dependency | S-3 | INV-4 |

## Execution topology — the region table (donor → target, token-mapped)

**EDIT 1 · `src/showcase.css`** (grow the 308-line sheet; keep the mx.9.2/9.3/9.4 section comments; add a
`/* mx.9.5 — the chrome skin */` layer, editing existing rules in place where a region restyles one):

| # | Region (target selectors) | Directive (donor cite) | Tokens |
|---|---|---|---|
| A | Canvas — new global scrollbar rules | `::-webkit-scrollbar` 10px; thumb `--slate-6`, hover `--slate-7`, track transparent; thumb radius `--radius-8` (donor :11–14) | `--slate-6/7` |
| B | Topbar — `.showcase-topbar`, `.showcase-title` | sticky top-0 z-10; translucent `rgb(var(--bg-primary) / 0.85)` + `backdrop-filter: saturate(150%) blur(12px)` (+ `-webkit-` twin); border-bottom → `--border-secondary` (donor `.topbar` :88–97). Title → the brand wordmark: `--fw-bold`, 16px, `letter-spacing: -0.02em` (donor `.sidebar-brand .name` :44–48); optionally a `.showcase-crumb` span (uppercase, 2px tracking, `--fg-tertiary` — donor `.crumb` :98–102) if the Topbar hook is added. **KEEP the `@mercury/ui` `<Button>` toggle** — composition, never a re-skin | `--bg-primary / 0.85`, `--border-secondary`, `--fw-bold`, `--fg-tertiary` |
| C | Sidebar — `.showcase-sidebar`, `.showcase-nav-label`, `.showcase-nav-item` | right border `--border-primary` → `--border-secondary` (donor :24); nav-label → `--fw-bold` + `letter-spacing: 2px` (donor `.sidebar-group` :55–60); hover → the `--bg-hover` scrim (donor :74); **active: REPLACE the solid `--bg-brand`/`--fg-on-brand` (current :84–87) with the subtle tint `--bg-brand-subtle` + `--fg-brand` + `--fw-semi-bold`** (donor `.sidebar-link.is-active` :75–79); add `transition: background 150ms ease, color 150ms ease` | `--bg-brand-subtle`, `--fg-brand`, `--fw-semi-bold`, `--bg-hover`, `--border-secondary` |
| D | Page — `.showcase-page`, `.showcase-page-header h2` | the reading column: `max-width: 1080px` (literal) + `padding: var(--space-48) var(--space-40) var(--space-96)` (donor `.page` :130–133); the title → `font-size: var(--text-heading-300-size); line-height: var(--text-heading-300-lh); font-weight: var(--fw-bold); letter-spacing: -0.025em` (donor `.page-title` :140–145, its 40px snapped to the heading-300 pair) | `--space-40/48/96`, the heading-300 pair, `--fw-bold` |
| E | Home — `shell/Home.tsx` + new `.showcase-home-*` classes | absorb the STATIC inline layout (`padding: 24` → `var(--space-24)`; `maxWidth: 720` stays a literal; the swatch `padding: 8` / `marginTop: 8` → `--space-8`) into classes; the swatch row may take the donor `.token-row`/`.token-sw` grid shape (:335–351 — `--radius-8`, `--border-secondary`, `--font-secondary` label). The dynamic swatch background STAYS inline (R-4) | `--space-8/24`, `--radius-8`, `--border-secondary` |
| F | Story card + stage — `.showcase-story`, `.showcase-story-stage` | card: add `box-shadow: var(--shadow-100)`; stage → the donor crosshatch canvas: `background: linear-gradient(rgb(var(--bg-primary)), rgb(var(--bg-primary))), repeating-linear-gradient(45deg, rgb(var(--slate-3)) 0 1px, transparent 1px 12px), repeating-linear-gradient(-45deg, rgb(var(--slate-3)) 0 1px, transparent 1px 12px)` + `min-height: 160px` + centered flex (donor `.demo-stage` :178–189) — the signature move that frames the live component | `--shadow-100`, `--slate-3`, `--bg-primary` |
| G | Tabs + subtabs — `.showcase-tab`, `.showcase-md-subtab` | add the missing `:hover` (`color: rgb(var(--fg-primary))`) + `transition: color 150ms ease, border-color 150ms ease` on both | `--fg-primary/secondary` |
| H | Docs prose — `.showcase-md-h1/h2/h3` | add `font-weight: var(--fw-bold)` to all three (weights only — the mx.9.4 block is otherwise already skinned) | `--fw-bold` |

**EDIT 2 · `src/shell/Home.tsx`** — className adds + static-style removal only (R-4). The `@mercury/ui`
value imports (`Badge, Button, Card`) and the SWATCHES map stay. The one inline style that REMAINS is the
dynamic per-swatch `` style={{ background: `rgb(var(${token}))` }} `` — token-resolved and runtime-varying;
its static siblings (`padding`, `marginTop`) move into the class.

**EDIT 3 (optional) · `src/shell/Topbar.tsx`** — a wordmark/crumb hook only if region B uses one; the
`<Button>` toggle and its props are untouched.

**Dual-theme is automatic** — semantic tokens flip via the `.dark-theme` ramps; the skin adds NO per-theme
rule. Prefer `--bg-brand-subtle` (flips) for tints; if a surface genuinely uses `--bg-active-subtle` /
`--bg-info-subtle` (= `--indigo-3`), cite it EXPECTED (INV-2) — never patch, never invent a dark RGB.

**Micro-craft is the builder's** within the token medium (exact ramp paddings, focus-ring consistency,
density rhythm) — the table fixes the direction and the tokens; it does not fix every declaration.

**Build order:** regions A→H in one pass over `showcase.css` → the Home absorption → the optional Topbar
hook → self-gate → the closure ladder.

## Agent stories (Directive → Acceptance gate)

- **AS-1 · Skin the eight regions** (Mars-1). *Directive:* land the region table in `showcase.css` — the
  donor pattern per region, the tokens per the mapping, snap rules R-2, motion R-3. *Gate:* the hex grep
  empty; `pnpm --filter @mercury/showcase typecheck && build` green; every region visibly changed on `:5176`.
- **AS-2 · Absorb the Home inline layout** (Mars-1). *Directive:* R-4 exactly. *Gate:* no static layout
  `style={{…}}` remains in `Home.tsx` except the dynamic swatch background; typecheck green.
- **AS-3 · The dual-theme pass** (Mars-1 evidence → Apollo acceptance). *Directive:* toggle light↔dark over
  a sampled cross-group spread, both surfaces (Stories + Docs). *Gate:* the chrome + a rendered component
  surface visibly invert; `rgb(var(--token))` resolves in both states; `--indigo-3` noted EXPECTED where
  sampled (S-2).
- **AS-4 · The whole-epic closure** (Director + Apollo). *Directive:* the ladder below + epic INV-1..9 +
  S-9/S-10 as written + the two adversarial probes. *Gate:* all green, independently re-run (S-3).

## The gate ladder (run from `mercury/` — NEVER `pnpm -r`)

```bash
pnpm --filter "./packages/*" typecheck && pnpm --filter "./packages/*" build   # unchanged (no pkg edit)
pnpm --filter @mercury/showcase typecheck && pnpm --filter @mercury/showcase build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build                  # exactly 3 product apps
grep -rnE "#[0-9a-fA-F]{3,8}\b" apps/showcase/src                              # → empty (token law)
grep -rnE "design-sync|DesignSync|@babel/standalone|window\.MercuryUI|_ds_bundle" apps/showcase  # → empty
grep -rnE "from \"@storybook/" apps/showcase/src                               # → empty (re-run)
find apps/showcase/src -name "*.md"                                            # → empty (re-run)
diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts  # → empty (barrel)
# Whole-epic closure (Director + Apollo): INV-6 registry liveness probe (a throwaway @mercury/ui component
# folder → the nav entry appears with NO apps/showcase/src edit → revert) · INV-5 doc-source-of-truth
# sample · INV-4 package/app-split audit · INV-2 source resolution (no package dist/ consumed) · the
# dual-theme sampled inversion (indigo-3 EXPECTED) · the net-zero mutation spot-check (Director) ·
# dev:showcase live on :5176 · epic S-9/S-10 as written.
```

## The prompt (every decision this spec has already fixed)

Skin the showcase from the sanctioned bundle-shell donor under the Arm A ruling (body §7): grow
`src/showcase.css` by the eight-region table — the scrollbar chrome, the translucent sticky topbar, the
subtle-tint sidebar active state, the 1080px reading column with the heading-300 pair, the Home class
absorption (the dynamic swatch background stays inline), the shadow-100 card + the crosshatch stage, the tab
hovers, the docs heading weights — existing tokens only, off-scale literals snapped, 150–200ms motion, no
per-theme rule. Touch exactly `showcase.css` + `Home.tsx` (+ optionally `Topbar.tsx`); no package edit, no
lockfile delta, zero new dependency; F1–F4 remain declined — a residual new-token need STOPS and surfaces.
Then accept the epic: the dual-theme pass across the 9 groups and both surfaces (`--indigo-3` EXPECTED,
never patched); the whole gate — epic INV-1..9, S-9/S-10 as written — under Squad + Apollo (the
doc-source-of-truth + package/app-split probes; the Director's independent re-run + net-zero mutation
spot-check). Movement III closes on this rung's green — record the evidence; the roadmap/progress folds are
the Director's at ship.
