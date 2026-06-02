import { test, expect, type Page } from "@playwright/test";

/**
 * E8 — Elixir hero & typography BASELINE.
 *
 * Captures the baseline rendering contract of the static /elixir course: the
 * responsive type scale, the lesson-hero layout, subheader sizing, and lede style.
 * Written against COMPUTED STYLES and GEOMETRY (not pixel snapshots) so the same
 * spec validates the planned Phoenix/Portal migration:
 *
 *   # baseline (this static server)
 *   npm test -- elixir-hero
 *   # migrated Portal app — parity check
 *   E2E_BASE_URL=https://<portal-host> npm test -- elixir-hero
 *
 * Passing against both means the migration preserved the design contract. In
 * particular this guards the no-space `clamp()` regression: every heading once
 * silently fell back to the UA `2em` (32px) default — h1 must render large.
 */

const DESKTOP = { width: 1440, height: 1300 };
const MOBILE = { width: 430, height: 1600 };

const HUB = "/elixir/phoenix/heex"; // two-column lesson hub (.hero-copy + .hero-art + full-width .hero-lede)
const DIVE = "/elixir/phoenix/heex/templates"; // single-column lesson dive
const LANDING_SHORT = "/elixir/algebra"; // 26-word lede — keeps the italic display deck
const LANDING_LONG = "/elixir/phoenix"; // 132-word lede — de-walled to upright prose

type Style = { fontSize: number; fontStyle: string; fontFamily: string };
async function styleOf(page: Page, sel: string): Promise<Style | null> {
  return page.evaluate((s) => {
    const el = document.querySelector(s);
    if (!el) return null;
    const c = getComputedStyle(el);
    return {
      fontSize: parseFloat(c.fontSize),
      fontStyle: c.fontStyle,
      fontFamily: c.fontFamily.split(",")[0].replace(/["']/g, ""),
    };
  }, sel);
}
async function rectOf(page: Page, sel: string) {
  return page.evaluate((s) => {
    const el = document.querySelector(s);
    if (!el) return null;
    const r = el.getBoundingClientRect();
    return { x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width) };
  }, sel);
}

test.describe("E8 typography scale renders (no-space clamp regression guard)", () => {
  test.use({ viewport: DESKTOP });

  test("h1 renders at display size, not the 32px UA fallback", async ({ page }) => {
    await page.goto(LANDING_SHORT);
    const h1 = await styleOf(page, "h1");
    expect(h1, "h1 must exist").not.toBeNull();
    // restored clamp max is 5.1rem (~81.6px @1440); the no-space-clamp bug collapsed it to 2em (32px)
    expect(h1!.fontSize).toBeGreaterThan(70);
  });

  test("body text renders at the responsive size, not the 16px fallback", async ({ page }) => {
    await page.goto(LANDING_SHORT);
    const body = await styleOf(page, ".prose p");
    expect(body!.fontSize).toBeGreaterThan(18); // ~18.88px @1440
  });
});

test.describe("E8 lesson hub hero: wireframe layout + subheader sizing", () => {
  test.use({ viewport: DESKTOP });

  test("subheader (.hero-lede .lede) equals main-content size and is upright", async ({ page }) => {
    await page.goto(HUB);
    const lede = await styleOf(page, ".hero-lede .lede");
    const prose = await styleOf(page, ".prose p");
    expect(lede, ".hero-lede .lede must exist").not.toBeNull();
    expect(lede!.fontSize).toBeCloseTo(prose!.fontSize, 1); // same size as main content
    expect(lede!.fontStyle).toBe("normal"); // readable, not the italic deck
    expect(lede!.fontFamily).toBe("PT Serif");
  });

  test("lede is a full-width row below the copy | art columns", async ({ page }) => {
    await page.goto(HUB);
    const copy = await rectOf(page, ".hero-copy");
    const art = await rectOf(page, ".hero-art");
    const lede = await rectOf(page, ".hero-lede");
    expect(copy && art && lede, "hero parts must exist").toBeTruthy();
    expect(art!.x).toBeGreaterThan(copy!.x); // top row = two columns side by side
    expect(lede!.y).toBeGreaterThan(copy!.y); // lede is the second row
    expect(lede!.y).toBeGreaterThan(art!.y);
    expect(lede!.w).toBeGreaterThan(copy!.w); // and spans wider than either column
    expect(lede!.w).toBeGreaterThan(art!.w);
  });
});

test.describe("E8 lesson hub hero: mobile stacks copy -> lede -> art", () => {
  test.use({ viewport: MOBILE });

  test("single column in reading order: title, intro, widget", async ({ page }) => {
    await page.goto(HUB);
    const copy = await rectOf(page, ".hero-copy");
    const lede = await rectOf(page, ".hero-lede");
    const art = await rectOf(page, ".hero-art");
    expect(copy!.y).toBeLessThan(lede!.y);
    expect(lede!.y).toBeLessThan(art!.y);
  });
});

test.describe("E8 lede style by page type (italic deck only for short landings)", () => {
  test.use({ viewport: DESKTOP });

  test("dive page lede is upright body prose", async ({ page }) => {
    await page.goto(DIVE);
    const lede = await styleOf(page, ".lede");
    const prose = await styleOf(page, ".prose p");
    expect(lede!.fontStyle).toBe("normal");
    expect(lede!.fontSize).toBeCloseTo(prose!.fontSize, 1);
  });

  test("short chapter landing keeps the italic display deck", async ({ page }) => {
    await page.goto(LANDING_SHORT);
    const lede = await styleOf(page, ".hero .lede");
    expect(lede!.fontStyle).toBe("italic");
    expect(lede!.fontSize).toBeGreaterThan(20); // display size, not body
  });

  test("long chapter landing was de-walled to upright prose", async ({ page }) => {
    await page.goto(LANDING_LONG);
    const lede = await styleOf(page, ".hero .lede");
    expect(lede!.fontStyle).toBe("normal");
  });
});
