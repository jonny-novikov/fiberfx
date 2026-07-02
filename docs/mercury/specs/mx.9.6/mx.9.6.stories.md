# mx.9.6 — acceptance stories

## S-1 · The harness is a real, reusable pixel gate
**Given** the live showcase on `:5176` and the reference served on `:8799`,
**When** I run `pnpm --filter @mercury/showcase visual` (with `REF_URL` set),
**Then** it writes `app-{home,stories,docs}-{light,dark}` + `ref-{overview,button,colors}-{light,dark}` PNGs,
reusing the global browser cache (no download), so any agent/human can compare app-to-reference. ✅

## S-2 · The two mx.9.5 regressions are gone (both themes)
**Given** the app's rendered chrome,
**When** I read `app-stories-{light,dark}` next to `ref-button-{light,dark}`,
**Then** the display titles are **DM Sans** (not mono) and the story **stage is near-solid** (no bold hatch) —
proven in pixels, in light and dark. ✅

## S-3 · The Home reads like the reference overview
**Given** the Home route,
**When** I read `app-home-{light,dark}` next to `ref-overview-{light,dark}`,
**Then** it shows a brand eyebrow, a 40px sans title, a lede, a hero (pitch + **65 / 9 / 3** derived metrics),
and an "Everything inside" grid of the 9 registry groups — dark flips token-clean. ✅

## S-4 · The chrome frame matches
**Given** any route,
**Then** the sidebar carries the **brand block + dotted items + tinted active pill**, and the **inset solid
topbar** shows the uppercase crumb — the full-height 272px grid of the reference. ✅

## S-5 · The derived group-card actually navigates
**Given** the Home overview,
**When** the "Actions" group-card is clicked,
**Then** the app routes to that group's first entry ("Button") and the sidebar active item syncs — verified by a
live Playwright probe, not just types. ✅

## S-6 · The boundary held
**Given** the change,
**Then** exactly `apps/showcase/src/**` (6 files) + the `visual/` tooling + `package.json` changed; `packages/**`
untouched, the `@mercury/ui` barrel byte-identical, **0 raw hex**, typecheck + build green. ✅
