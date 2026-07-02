# mx.9.6 — visual parity + the visual-regression harness

> **Status: ✅ BUILT** (2026-07-02 · `apps/showcase` visual remediation · Director + Mars two waves + a live interaction probe).
> **Relationship to mx.9.5.** mx.9.5 shipped a *token-valid* chrome skin and **deferred its visual acceptance to
> "the `:5176` human-eye pixel pass — the Operator residual by design."** That pass was run and revealed the skin
> was fitted to the wrong donor (`packages/mercury-ds/project/showcase/app.css`), so its selectors/values did not
> match the *actual* design reference `mercury/static/showcase.html` — the app rendered half-baked (mono display
> titles, an over-strong crosshatch, a stub Home, a bare page header, no sidebar brand). **mx.9.5's record stands
> unchanged** (it did ship a valid, dark-correct token sheet); mx.9.6 supersedes only the *visual acceptance* it
> deferred — achieving true parity **and** converting the manual pixel pass into a mechanical gate so it cannot
> silently regress again. The mx.9 feature epic remains COMPLETE; mx.9.6 is its **visual close**.

## Why this rung exists — the gate was blind

The mercury-ship gate ladder is `tsc --noEmit` + `vite build` + the barrel-diff + negative greps. Those verify
CSS **parses** and TS **type-checks** — they are structurally blind to whether a skin selector matches the live
DOM, whether a `rgb(var(--token))` resolves, or whether the rendered chrome matches the reference. **A skin sheet
can be 100% green and 0% rendered.** That is exactly how mx.9.5 shipped green yet half-baked. The cure is not more
build gating — it is **pixel truth in the loop**.

## Deliverables

- **K-1 · The harness (the durable capability).** `apps/showcase/visual/shoot.mjs` + the `visual` package script
  + `visual/README.md`: a Playwright headless-Chromium harness that drives the **live app** and, side-by-side,
  the served **static reference** across `route × theme` and writes comparable PNGs. Reuses the global browser
  cache (no per-run download). This is the missing pixel gate.
- **K-2 · Visual parity (two Mars waves, harness-verified).** The `apps/showcase` chrome brought to stylistic
  parity with `static/showcase.html` — parity of **style**, not content (the app stays a *derived* showcase;
  the sidebar grouping stays registry-derived per the Operator carve-out).
- **K-3 · Dual-theme.** Parity holds in light AND dark; the fixes are token-expressed, so the flip is automatic.
- **K-4 · Interaction proof.** A live probe confirms the derived Home group-card → route → sidebar-sync path.

## The defect catalog → fixes (pixel-diagnosed, both themes)

| # | Defect (mx.9.5 as-shipped) | Root cause | Fix (app-side, tokens-only) |
|---|---|---|---|
| A | Chrome display titles render in **DM Mono** | `packages/…/tokens.css` sets bare `h1,h2,h3 { font-family: var(--font-secondary=DM Mono) }` by design; the app's `<hN>` chrome headings inherit it | app-side `font-family: var(--font-primary)` on the showcase chrome heading classes (mirrors the reference's `.ptitle`). **DS token layer untouched.** |
| B | Page header = one crumb-duplicating line | never built past the mx.9.2 stub | ComponentPage → **eyebrow (group) + 40px sans ptitle (name) + lede** |
| C | Home = the mx.9.1 "— the spine" stub | never built | Home → real overview: eyebrow + title + lede + **hero (pitch + 65/9/3 metrics)** + "Everything inside" + a **group-card grid derived from `REGISTRY`** (each card navigates) |
| D | Crosshatch stage far too strong | mx.9.5 painted the hatch layers FIRST (on top) | reorder to the reference: **opaque `linear-gradient(bg,bg)` FIRST, hatch LAST** → a whisper of texture |
| E | Sidebar bare (no brand, no dots, tight items) | mx.9.2 structural only | brand block (token-tinted mark + "mercury" + "Design system · v2.4"), dotted items, the reference `.sb-link` metrics + tinted active pill |
| F | Topbar full-width blurred bar | mx.9.5 chrome mismatch | **inset, solid `bg-primary`**, uppercase crumb + a `.tb-btn` toggle |
| G | Layout column (topbar over a 240px body) | mx.9.2 | the reference **grid**: full-height 272px sidebar beside a `.main` column (inset topbar + scroll) |

## Boundary · gate · invariants (held)

- **Edit surface:** exactly `apps/showcase/src/**` (6 files) + the `apps/showcase/visual/` tooling + `package.json`
  (the `playwright` devDep + `visual` script). `packages/**` FROZEN — the heading fix is an **app-side override**,
  never a DS token edit. `pnpm-lock.yaml` left for the Operator.
- **INV-1 tokens:** 0 raw hex across the changed files; every color `rgb(var(--token))`.
- **Master invariant:** the `@mercury/ui` barrel byte-identical (packages untouched).
- **Gate:** `pnpm --filter @mercury/showcase typecheck && … build` green; then the visual harness (the new pass).

## As-built record

- **Product (Mars, 2 waves):** `src/App.tsx` (grid + Home wiring), `shell/Sidebar.tsx` (brand + dots),
  `shell/Topbar.tsx` (inset crumb), `shell/ComponentPage.tsx` (eyebrow/title/lede header), `shell/Home.tsx`
  (overview), `showcase.css` (the skin; A + D fixed in place). All harness-verified vs the reference in both
  themes; gate green pass-1 each wave.
- **Tooling (Director):** `visual/shoot.mjs`, `visual/README.md`, `visual/.gitignore` (shots are WRITE-ONLY),
  `package.json` (`visual` script + `playwright`).
- **Interaction probe:** clicking the Home **"Actions"** group-card landed on **"Button"** (that group's first
  entry) with the sidebar active item syncing to "Button" — `{cards: 9, clicked: Actions, landed: Button}`.
- **Metrics** in the hero are DERIVED (65 = `TOTAL`, 9 = `REGISTRY.length`, 3 = the `--font-*` families) — nothing
  invented; the reference's date eyebrow / "View tokens" / per-card prose were **omitted rather than invented**
  (no tokens page, no registry description field).

## Residuals (deliberate, non-blocking)

- Card **hover** states + the theme-toggle animation are declared per the reference but not screenshot-captured
  (the harness shoots static + one click path; hover/animation coverage is a future harness enrichment).
- The in-card story caption ("Playground"/"States") stays mono — it reads as the reference's mono label bar.
- `--indigo-3` soft-bg limitation from mx.9.5 remains documented-but-unused (the chrome never invokes it).

## The guardrail (proposed, Operator-applied)

The durable lesson — **the mercury-ship gate ladder must include a visual pass** — is proposed as a skill edit
(the harness as a required gate stage for any rung touching `showcase.css`/shell chrome), PROPOSE-ONLY because the
skill files are Operator-owned.
