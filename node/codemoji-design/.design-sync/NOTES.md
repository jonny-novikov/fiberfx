# design-sync NOTES — @codemoji/design

Durable gotchas + decisions for re-syncs. Subagents read this verbatim.

## Shape & build (how this repo is wired)

- **Co-located components, no published entry.** React components live at `stories/<group>/<Name>.tsx` beside their `<Name>.stories.tsx` (the story imports its sibling relatively). `package.json` exposes only `./theme.css` + `./tokens` — there is **no component dist bundle**. So the sync bundles a **synthesized barrel**, `.design-sync/entry.tsx` (committed), which `export *`s every component file. `cfg.entry` points at it.
- `[GENERAL]` **`package.json` has `"types": ".design-sync/entry.tsx"`** — added by the sync. Without it `exportedNames()` resolves no type entry → the export set is empty → every storybook title is dropped as `[TITLE_UNMAPPED]` (0 components). Pointing `types` at the barrel lets ts-morph follow `export *` to enumerate the components **and** extract real props/`.d.ts`. Inert for consumers (no `.` export; `private: true`). **Keep this field.**
- `[GENERAL]` **`cfg.provider = {component: "PreviewProvider"}`** — the `.storybook/preview.tsx` decorators can't be auto-bundled (preview.css does `@import 'tailwindcss'` + an absolute `url('/assets/gold.png')`, neither esbuild-resolvable). `PreviewProvider` (in the barrel) reproduces them: `<I18nextProvider>` + `<div data-theme="orange" className="font-sans bg-gradient-to-b from-bg-from to-bg-to text-muted">`. Default theme `orange`, default locale `ru` (i18n `fallbackLng`) — matches the storybook reference defaults so captures line up.
- **CSS is `[CSS_FROM_STORYBOOK]`** — Tailwind v4 compiles at build; the converter scrapes the compiled CSS out of `.design-sync/sb-reference`. Do NOT set `cfg.cssEntry` to `dist/theme.css` (that's raw, unexpanded `@theme`/`@utility`).
- `titleMap: {AnswerReveal: GoldenAnswerReveal}` — the only title whose last segment doesn't match its export (`Golden Game/Answer Reveal`).

## Scope decisions

- **27 reusable components synced** (components/board/board-lib/golden-game/lobby). These are the design system.
- **9 render-only composite stories dropped** (`[TITLE_UNMAPPED]`): 3 section Overviews (gallery pages that render a screen component each — `Board/Overview`=BoardScreen etc. — but all collapse to one "Overview" name, can't `titleMap`-split, and duplicate the individual cards), 3 Foundations (Colors/Themes/Typography token galleries), 4 Screens (Catalog/Game (Free)/Golden Game/Rooms (Lobby) — full-screen demos; Catalog renders static reference PNGs), and Golden/Treatment. They are showcase/doc stories, not reusable components, and have no clean component export. Foundations' design language goes in `conventions.md` instead.

## Resolved global fixes (do NOT re-fix in fan-out)

- `[GENERAL]` **All brand image assets — RESOLVED via the css-fallback fork** (`.design-sync/overrides/css-fallback.mjs`, declared in `cfg.libOverrides`). It data-URL-inlines local image refs so they render in previews **and** post-upload. It covers THREE reference forms:
  1. **CSS** `url()` — `--gold-texture: url(../assets/gold.png)` (Button `golden`, Badge `gold`). Uses `.design-sync/inline-assets/gold.png` (320px ~80K override) in place of the 1.3M source.
  2. **JS complete literal** — `'/assets/emoji/01-emoji-set.png'` in `SpriteEmoji` (inline-style `backgroundImage`), used by EmojiSlots, EmojiKeyboard, GuessHistory, BoardTabs, PreviousAttempt (sprite-CODE emoji like `'0800'`). Inlined from the 130K sheet.
  3. **JS `${VAR}/file.ext` template** — NavPhonePanel's 4 status-bar PNGs (`${ASSET}/iphone-topbar.png` etc.), resolved by unique basename under sb-reference/assets.
  The fork rewrites `_ds_bundle.js` between `bundleToIife` (writes it) and `stampHeader` (re-reads from disk) — verified: `anchor matches the bundle`. **CORRECTION:** an earlier note here wrongly said gameplay emoji / status-bar PNGs were "Unicode glyphs, not referenced" — WRONG, two waves confirmed they are real JS assets (now fixed). The `?` placeholder / 🔑 / tab icons / EmojiTile's States story ARE literal Unicode (those always rendered).
- `[GENERAL]` **i18n + theme + provider work.** `PreviewProvider` renders the gradient surface + Russian i18n; GameRules' Russian copy matched exactly. No per-component provider fixes needed.
- **Note for re-grade:** editing `.design-sync/overrides/css-fallback.mjs` cleared ALL grades once (forks are in the grade contract). The fork is now STABLE — future rebuilds carry grades.

## Open issues

- `GuessActions` `[GRID_OVERFLOW] wide` → `cfg.overrides.GuessActions.cardMode: "column"` (RESOLVED — applied; no overflow on rebuild).
- **Font (not a defect):** `--font-sans: 'Noto Sans Mono', monospace`, no `@font-face` shipped. The PREVIEW renders Noto Sans Mono correctly (body + headings); the storybook-static REFERENCE renders serif headings (its webfont didn't load for headings in the static build) — so the preview is the *more* correct render, and the difference is a reference-side artifact, NOT `[FONT_MISSING]` (the two sides differ; they don't both fall back the same). Design-tool users get Noto Sans Mono if present, else the monospace fallback — fine for a monospace-by-design system. Documented in conventions.md. Optional future polish: a Google-Fonts `@import` for Noto Sans Mono — deferred (a css-fallback fork edit re-clears all grades, not worth it for a mono-with-mono-fallback design).

## Status

**All 27 components graded MATCH** (image-judged primaries + sibling-trusted, per §4). No owned previews were needed — every component rendered faithfully once the global fixes (provider, gold CSS inline, JS-asset inline) landed.

## Re-sync risks (what the next sync must watch)

- **`package.json` `"types": ".design-sync/entry.tsx"` is load-bearing.** Remove it and the export set goes empty → 0 components. If the Operator reverts it, re-add.
- **The barrel (`.design-sync/entry.tsx`) is hand-maintained.** A NEW component file under `stories/<group>/<Name>.tsx` won't be synced until a `export * from '../stories/<group>/<Name>'` line is added (and a new story title appears in the index). Removed components leave a dead export (harmless).
- **The css-fallback fork inlines by basename.** `inlineBundleAssets` resolves `${VAR}/file.ext` templates by *unique* basename under `sb-reference/assets`; if two assets ever share a basename, that ref is skipped (logged `[CSS_ASSETS]`). The gold override `.design-sync/inline-assets/gold.png` is a **resized copy** of the 1.3M source — if `public/assets/gold.png` is re-arted, regenerate the override (`sips -Z 320 …`) or it ships the old foil. Size cap is 300K; a new >300K asset needs an override.
- **Assets come from `sb-reference`, not `public/` directly.** The reference must be rebuilt (`npx storybook build -c .storybook -o .design-sync/sb-reference`) after any `public/assets/**` or DS-source change, or the inliner reads stale art.
- **Font:** Noto Sans Mono is NOT bundled (no `@font-face`); design-tool users see it only if installed, else the monospace fallback (acceptable — see Open issues).
- **Partial verification:** Button's 7th story ("Color overrides") is sibling-trusted, not individually image-judged (a low-risk swatch row). `[STORY_CAP]` is 6 by default; raise `--max-stories` if a component's tail stories carry distinct variants.
- **9 composites deliberately excluded** (`[TITLE_UNMAPPED]`: Overviews/Foundations/Screens/Treatment) — render-only showcase stories with no component export. Re-including any needs a synthetic barrel export + titleMap; foundations' design language lives in `conventions.md` instead.
- **Toolchain assumed:** node ≥22.12, pnpm ≥10, no lockfile committed (deps resolved from the existing `node_modules`). Editing the fork (`.design-sync/overrides/*`) clears all grades once (it's in the grade contract) → a one-time full re-verify.
