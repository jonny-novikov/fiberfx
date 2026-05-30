import { test, expect } from "@playwright/test";

/**
 * E2b — Root hub: "/" is the lightweight, mobile-friendly landing hub. It is
 * pure HTML/CSS — NO three.js, NO WebGL, NO window.__mindmap. The interactive
 * 3D orbital map lives at /map (covered by the gotoMap-based specs). This spec
 * guards the split: "/" presents the series cards and links into /map, and must
 * NOT carry the heavy map's hook or canvas.
 */

const SERIES_HREFS = [
  "/school",
  "/school/geometria",
  "/future",
  "/edu/finances",
  "/ege",
];

test.describe("E2b root hub: lightweight landing at /", () => {
  test("loads without the 3D map's hook, canvas, or root-view", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
    // None of the WebGL map machinery should be present on the landing.
    expect(await page.evaluate(() => "__mindmap" in window)).toBe(false);
    await expect(page.locator("canvas#gl")).toHaveCount(0);
    await expect(page.locator("#root-view")).toHaveCount(0);
  });

  test("presents real series-card anchors linking into each live series", async ({
    page,
  }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
    const grid = page.locator(".series-grid");
    await expect(grid).toBeVisible();
    for (const href of SERIES_HREFS) {
      const card = grid.locator(`a.series-card[href="${href}"]`);
      await expect(card, `series card for ${href}`).toHaveCount(1);
      await expect(card).toBeVisible();
    }
  });

  test("links to the 3D map", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
    const mapLinks = page.locator('a[href="/map"]');
    expect(await mapLinks.count(), "the hub must link to /map").toBeGreaterThan(0);
  });

  test("the linked series + map pages all resolve 200", async ({ request }) => {
    for (const href of [...SERIES_HREFS, "/map"]) {
      const response = await request.get(href);
      expect(response.status(), `${href} should respond 200`).toBe(200);
    }
  });
});
