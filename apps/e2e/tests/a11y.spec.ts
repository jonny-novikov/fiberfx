import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";
import {
  gotoMap,
  enterSeries,
  enterSeriesAndSettle,
  modcard,
  nodeLocator,
  view,
  motionRunning,
  childIdsOf,
  realNodes,
} from "../fixtures/mindmap";

/**
 * E4 — Accessibility: keyboard operation of the modcards and scene labels, an
 * automated axe scan of the root view with color-contrast retained, the
 * reduced-motion contract, and the no-JS sitemap fallback.
 */

test.describe("E4 a11y: keyboard, axe, reduced motion, no-JS", () => {
  test("keyboard: a focused modcard enters the scene on Enter", async ({
    page,
  }) => {
    await gotoMap(page);

    const card = modcard(page, "school");
    await card.focus();
    await expect(card).toBeFocused();
    expect(await view(page)).toBe("root");

    await page.keyboard.press("Enter");
    // With JS on, Enter on the focused card anchor enters the scene; the href
    // keeps the JS-off path a plain navigation to /school.
    await expect.poll(() => view(page)).toBe("scene");
  });

  test("keyboard: a scene leaf label is a focusable anchor and Enter navigates", async ({
    page,
  }) => {
    await gotoMap(page);
    await enterSeriesAndSettle(page, "school");

    const leaf = nodeLocator(page, "school/kiselev");
    await expect(leaf).toBeVisible();
    expect(await leaf.evaluate((el) => el.tagName.toLowerCase())).toBe("a");
    await leaf.focus();
    await expect(leaf).toBeFocused();

    await page.keyboard.press("Enter");
    await page.waitForURL("**/school/kiselev", { waitUntil: "commit" });
    expect(new URL(page.url()).pathname).toBe("/school/kiselev");
  });

  test("keyboard: Escape in the scene returns to the root view", async ({
    page,
  }) => {
    await gotoMap(page);
    await enterSeriesAndSettle(page, "school");
    expect(await view(page)).toBe("scene");

    // The back control is reachable and Escape is bound to back().
    await page.locator("#btn-back").focus();
    await page.keyboard.press("Escape");
    await expect.poll(() => view(page)).toBe("root");
  });

  test("axe reports zero serious or critical violations on the root view", async ({
    page,
  }) => {
    await gotoMap(page);
    expect(await view(page)).toBe("root");

    // color-contrast is intentionally retained. The disabled rules below cover
    // landmark/region structure that axe flags as advisory on this single-stage
    // layout; none mask interactive-control issues on the modcards.
    const results = await new AxeBuilder({ page })
      .disableRules(["region", "landmark-unique"])
      .analyze();

    const blocking = results.violations.filter(
      (violation) =>
        violation.impact === "serious" || violation.impact === "critical",
    );

    expect(
      blocking,
      `axe blocking violations: ${blocking.map((v) => v.id).join(", ")}`,
    ).toEqual([]);
  });

  test("reduced-motion: render loop stays idle and entering a series still works", async ({
    browser,
  }) => {
    const context = await browser.newContext({ reducedMotion: "reduce" });
    const page = await context.newPage();
    await gotoMap(page);

    expect(await motionRunning(page)).toBe(false);

    await enterSeries(page, "school");
    // Expansion/navigation still function; the scene mounts the hub's children.
    await expect
      .poll(async () => {
        const ids = await page.evaluate(() => window.__mindmap.sceneNodeIds());
        return childIdsOf("school").every((id) => ids.includes(id));
      })
      .toBe(true);
    expect(await view(page)).toBe("scene");
    // Reduced motion: the loop renders only on interaction, never continuously.
    expect(await motionRunning(page)).toBe(false);

    await context.close();
  });

  test("no-JS: sitemap fallback is visible and links every real node", async ({
    browser,
  }) => {
    const context = await browser.newContext({ javaScriptEnabled: false });
    const page = await context.newPage();
    await page.goto("/");

    const fallback = page.locator("#sitemap-fallback");
    await expect(fallback).toBeVisible();

    const hrefs = await fallback
      .locator("a[href]")
      .evaluateAll((anchors) =>
        anchors.map((anchor) => anchor.getAttribute("href") ?? ""),
      );

    for (const node of realNodes) {
      expect(
        hrefs,
        `fallback must link real node ${node.id}`,
      ).toContain(node.url as string);
    }

    await context.close();
  });
});
