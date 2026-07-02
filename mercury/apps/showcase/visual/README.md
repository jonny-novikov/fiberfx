# Visual-regression harness (`@mercury/showcase`)

**Why this exists.** The build gate (`tsc --noEmit` + `vite build`) verifies that CSS *parses* and TS
*type-checks*. It is structurally **blind** to whether a skin selector matches the live DOM, whether a
`rgb(var(--token))` resolves, or whether the rendered chrome matches the design reference. A skin sheet can be
100% green and 0% rendered — that is exactly how the mx.9.5 "chrome skin" shipped green yet half-baked. This
harness closes the gap: it drives a real headless Chromium over the **live app** (and, side-by-side, the static
design **reference**) across `route × theme` and writes PNGs a human or agent can compare.

## Run

```bash
# from mercury/ — the dev server must be up on :5176 (pnpm --filter @mercury/showcase dev)
pnpm --filter @mercury/showcase visual                       # app only

# app + the design reference (serve mercury/static first):
python3 -m http.server 8799 --directory mercury/static &
SHOTS_DIR=/tmp/mx-shots REF_URL=http://localhost:8799/showcase.html \
  pnpm --filter @mercury/showcase visual
```

Then open / `Read` the PNGs in `SHOTS_DIR` and compare `app-*` to `ref-*`.

## Env knobs
| Var | Default | Meaning |
|---|---|---|
| `APP_URL` | `http://localhost:5176` | the live showcase origin |
| `REF_URL` | *(unset → skipped)* | the served `static/showcase.html`, e.g. `http://localhost:8799/showcase.html` |
| `SHOTS_DIR` | `visual/__shots__/` | output dir — **WRITE-ONLY artifacts; never commit them** |

## What it captures
- **App:** `app-home-{light,dark}`, `app-stories-{light,dark}`, `app-docs-{light,dark}` — drives the shell by
  seeding `localStorage` (`mx-showcase.theme.v1`, `mx-showcase.route.v1`), clicking the first nav item + the Docs tab.
- **Reference** (when `REF_URL` set): `ref-{overview,button,colors}-{light,dark}` — seeds the reference's own
  `ms-theme` / `ms-route` keys.

Browsers reuse the global Playwright cache (`~/Library/Caches/ms-playwright`); no per-run download. Theme is a
CSS class (`.dark-theme`/`.light-theme`) driven via `localStorage`, not `prefers-color-scheme` — the harness sets
it before load so first paint carries the theme.

## Extending
Add routes/pages in `shoot.mjs` (`shootApp` / `shootRef`). Keep it dependency-light and side-effect-free so it
can front a real assertion layer later (pixel-diff thresholds, per-region crops) without a rewrite.
