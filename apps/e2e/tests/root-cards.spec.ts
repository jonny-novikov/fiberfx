import { test, expect } from "@playwright/test";
import {
  gotoMap,
  modcard,
  view,
  hubIds,
  seriesIds,
  seriesColor,
  nodeById,
} from "../fixtures/mindmap";

/**
 * E2 — Root view: the map's root presents a .modgrid of exactly five .modcard
 * anchors, one per series in dataset hub order [school, geometria, future, edu,
 * ege]. Each card is a real focusable <a> (href = the hub's url) carrying
 * data-series and a
 * per-series top-border accent color. The chrome (topbar, footer, legend) and
 * body background image are present. Activating a card transitions ROOT ->
 * SCENE. Screenshots at desktop and mobile sizes are captured for reference.
 */

/** Parses an rgb()/rgba() computed color into integer channel triples. */
function rgbChannels(color: string): [number, number, number] | null {
  const match = color.match(/rgba?\(([^)]+)\)/);
  if (!match) return null;
  const parts = match[1].split(",").map((p) => parseFloat(p.trim()));
  if (parts.length < 3 || parts.some((n) => Number.isNaN(n))) return null;
  return [parts[0], parts[1], parts[2]];
}

test.describe("E2 root: modgrid of five series cards and chrome", () => {
  test("root view holds a modgrid of exactly five modcards", async ({ page }) => {
    await gotoMap(page);

    await expect(page.locator("#root-view")).toBeVisible();
    const grid = page.locator("#root-view .modgrid");
    await expect(grid).toBeVisible();
    await expect(grid.locator(".modcard")).toHaveCount(5);
  });

  test("the four scene/root containers exist and exactly root is active", async ({
    page,
  }) => {
    await gotoMap(page);
    // Both container ids must exist in the DOM regardless of active view.
    await expect(page.locator("#root-view")).toBeAttached();
    await expect(page.locator("#scene-view")).toBeAttached();
    // At the landing root, the root view is visible and the scene is inactive.
    await expect(page.locator("#root-view")).toBeVisible();
    await expect(page.locator("#scene-view")).toBeHidden();
    expect(await view(page)).toBe("root");
  });

  test("each modcard is a visible anchor in hub order with matching data-series and href", async ({
    page,
  }) => {
    await gotoMap(page);

    // Cards appear in dataset hub order [school, geometria, future, edu, ege].
    const order = await page.locator("#root-view .modcard").evaluateAll((els) =>
      els.map((el) => el.getAttribute("data-series")),
    );
    expect(order).toEqual(hubIds);

    for (const series of seriesIds) {
      const card = modcard(page, series);
      await expect(card).toBeVisible();
      // A real anchor so the card works with JS off. href is the hub's url
      // ("/school" etc.; the geometria hub overrides to "/school/geometria").
      expect(await card.evaluate((el) => el.tagName.toLowerCase())).toBe("a");
      const expectedHref = nodeById(series)?.url ?? `/${series}`;
      await expect(card).toHaveAttribute("href", expectedHref);
      await expect(card).toHaveAttribute("data-series", series);
      // Required card content per the contract.
      await expect(card.locator(".mnum")).toBeVisible();
      await expect(card.locator("h4")).toBeVisible();
      await expect(card.locator("p")).toBeVisible();
      await expect(card.locator(".go")).toBeVisible();
    }
  });

  test("each card's top-border accent matches its series token color", async ({
    page,
  }) => {
    await gotoMap(page);

    for (const series of seriesIds) {
      const card = modcard(page, series);
      const borderColor = await card.evaluate(
        (el) => getComputedStyle(el).borderTopColor,
      );
      // Resolve the series hex token to the same rgb() form the browser computes
      // by painting it onto a throwaway element, so the comparison is agnostic
      // to whether the card uses the literal hex or a var(--token).
      const expected = await page.evaluate((hex) => {
        const probe = document.createElement("span");
        probe.style.color = hex;
        document.body.appendChild(probe);
        const out = getComputedStyle(probe).color;
        probe.remove();
        return out;
      }, seriesColor[series]);

      const got = rgbChannels(borderColor);
      const want = rgbChannels(expected);
      expect(got, `border-top-color for ${series} parses as rgb`).not.toBeNull();
      expect(want).not.toBeNull();
      // Allow a tiny per-channel tolerance for any alpha-compositing rounding.
      for (let i = 0; i < 3; i++) {
        expect(
          Math.abs(got![i] - want![i]),
          `${series} border channel ${i}: got ${borderColor}, want ${expected}`,
        ).toBeLessThanOrEqual(4);
      }
    }
  });

  test("body carries a background image and chrome regions are present", async ({
    page,
  }) => {
    await gotoMap(page);

    const backgroundImage = await page.evaluate(
      () => getComputedStyle(document.body).backgroundImage,
    );
    expect(backgroundImage).not.toBe("none");

    await expect(page.locator("#topbar")).toBeVisible();
    await expect(page.locator("#footer")).toBeVisible();
    await expect(page.locator("#legend")).toBeVisible();
  });

  test("activating a card transitions the root view into the 3D scene", async ({
    page,
  }) => {
    await gotoMap(page);
    expect(await view(page)).toBe("root");

    // A real user click on the card (JS on) expands it and enters the scene.
    // The href guarantees the JS-off path still navigates to /school.
    await modcard(page, "school").click();
    await expect.poll(() => view(page)).toBe("scene");
    await expect(page.locator("#scene-view")).toBeVisible();
    await expect(page.locator("#gl")).toBeVisible();
  });

  test("captures full-page screenshots at desktop and mobile sizes", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await gotoMap(page);
    await page.screenshot({
      path: "test-results/root-desktop-1440x900.png",
      fullPage: true,
    });

    await page.setViewportSize({ width: 390, height: 844 });
    await gotoMap(page);
    await page.screenshot({
      path: "test-results/root-mobile-390x844.png",
      fullPage: true,
    });
  });
});
