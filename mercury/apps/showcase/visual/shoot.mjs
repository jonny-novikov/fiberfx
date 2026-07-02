// Visual-regression harness for @mercury/showcase.
//
// WHY THIS EXISTS: the build gate (`tsc --noEmit` + `vite build`) verifies that
// CSS parses and TS type-checks — it is structurally blind to whether a skin
// selector matches the live DOM, whether a `rgb(var(--token))` resolves, or
// whether the rendered chrome matches the design reference. A skin sheet can be
// 100% green and 0% rendered. This harness closes that gap: it drives a real
// headless Chromium over the LIVE app (and, optionally, the static reference)
// across route × theme and writes PNGs a human/agent can compare.
//
// Usage:
//   node visual/shoot.mjs                          # shoot the live app on :5176
//   APP_URL=http://localhost:5176 node …           # override the app origin
//   REF_URL=http://localhost:8799/showcase.html node …   # also shoot the reference
//   SHOTS_DIR=/path/to/out node …                  # override the output dir
//
// Browsers reuse the global Playwright cache (~/Library/Caches/ms-playwright);
// no per-run download. Output PNGs are WRITE-ONLY artifacts — do not commit them.

import { chromium } from "playwright";
import { mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const HERE = dirname(fileURLToPath(import.meta.url));
const OUT = process.env.SHOTS_DIR ?? join(HERE, "__shots__");
mkdirSync(OUT, { recursive: true });

const APP_URL = process.env.APP_URL ?? "http://localhost:5176";
const REF_URL = process.env.REF_URL ?? null;
const THEMES = ["light", "dark"];
const VIEWPORT = { width: 1440, height: 1200 };

// The app persists these (App.tsx): theme is a raw string, route is JSON.
const APP_THEME_KEY = "mx-showcase.theme.v1"; // "light" | "dark"
const APP_ROUTE_KEY = "mx-showcase.route.v1"; // JSON { group, name, tab }
const APP_READY = ".showcase-layout";

// The reference (static/showcase.html) persists these (its DC logic).
const REF_THEME_KEY = "ms-theme"; // "light" | "dark"
const REF_ROUTE_KEY = "ms-route"; // e.g. "overview" | "components/button"
const REF_READY = ".app";

async function newPage(browser) {
  const ctx = await browser.newContext({ viewport: VIEWPORT, deviceScaleFactor: 2 });
  return { ctx, page: await ctx.newPage() };
}

// vite keeps an HMR websocket open, so `networkidle` never fires — wait on the
// mounted-shell selector + a short settle instead.
async function settle(page, ready) {
  await page.waitForSelector(ready, { timeout: 20000 });
  await page.waitForTimeout(450);
}

async function shootApp(browser) {
  for (const theme of THEMES) {
    const { ctx, page } = await newPage(browser);
    await page.goto(APP_URL, { waitUntil: "load" });
    await page.evaluate(
      ([tk, t, rk]) => {
        localStorage.setItem(tk, t);
        localStorage.removeItem(rk);
      },
      [APP_THEME_KEY, theme, APP_ROUTE_KEY],
    );

    // HOME (no route)
    await page.reload({ waitUntil: "load" });
    await settle(page, APP_READY);
    await page.screenshot({ path: join(OUT, `app-home-${theme}.png`) });

    // FIRST COMPONENT — stories tab
    await page.locator(".showcase-nav-item").first().click();
    await page.waitForTimeout(700);
    await page.screenshot({ path: join(OUT, `app-stories-${theme}.png`) });

    // DOCS tab
    const docs = page.getByRole("tab", { name: "Docs" });
    if (await docs.count()) {
      await docs.first().click();
      await page.waitForTimeout(700);
      await page.screenshot({ path: join(OUT, `app-docs-${theme}.png`) });
    }

    await ctx.close();
    console.log(`✓ app · ${theme}`);
  }
}

async function shootRef(browser) {
  // The reference routes worth a side-by-side against the app's chrome.
  const ROUTES = [
    ["overview", "overview"],
    ["components/button", "button"],
    ["foundations/colors", "colors"],
  ];
  for (const theme of THEMES) {
    for (const [route, label] of ROUTES) {
      const { ctx, page } = await newPage(browser);
      await page.goto(REF_URL, { waitUntil: "load" });
      await page.evaluate(
        ([tk, t, rk, r]) => {
          localStorage.setItem(tk, t);
          localStorage.setItem(rk, r);
        },
        [REF_THEME_KEY, theme, REF_ROUTE_KEY, route],
      );
      await page.reload({ waitUntil: "load" });
      await settle(page, REF_READY);
      await page.screenshot({ path: join(OUT, `ref-${label}-${theme}.png`) });
      await ctx.close();
      console.log(`✓ ref · ${label} · ${theme}`);
    }
  }
}

const browser = await chromium.launch();
try {
  await shootApp(browser);
  if (REF_URL) await shootRef(browser);
} finally {
  await browser.close();
}
console.log(`done → ${OUT}`);
