import { test, expect } from "@playwright/test";
import {
  gotoMap,
  allRealUrls,
  realNodes,
  realUrls,
  plannedNodes,
} from "../fixtures/mindmap";

/**
 * E1 — Links: the page's allRealUrls() hook enumerates every real node url. Each
 * must resolve to 200. The planned id must 404 on the server and must never
 * appear in allRealUrls(). The no-JS #sitemap-fallback must link every real
 * node so crawlers and keyboard-only users reach the whole site without JS.
 */

test.describe("E1 links: real urls resolve, planned never navigates", () => {
  test("allRealUrls covers exactly the dataset's real nodes", async ({ page }) => {
    await gotoMap(page);
    const urls = await allRealUrls(page);
    // The hook returns node.url for each real node, matching the loader.
    expect([...urls].sort()).toEqual([...realUrls].sort());
    expect(urls.length).toBe(realNodes.length);
  });

  test("every real url returns 200", async ({ page, request }) => {
    await gotoMap(page);
    const urls = await allRealUrls(page);
    expect(urls.length).toBeGreaterThan(0);

    for (const url of urls) {
      const response = await request.get(url);
      expect(response.status(), `${url} should respond 200`).toBe(200);
    }
  });

  test("each planned id 404s and is absent from allRealUrls", async ({
    page,
    request,
  }) => {
    await gotoMap(page);
    const urls = await allRealUrls(page);

    expect(plannedNodes.length).toBeGreaterThan(0);
    for (const planned of plannedNodes) {
      const wouldBe = "/" + planned.id;
      expect(
        urls,
        `planned node ${planned.id} must not be a real url`,
      ).not.toContain(wouldBe);
      const response = await request.get(wouldBe);
      expect(response.status(), `${wouldBe} should 404`).toBe(404);
    }
  });

  test("no-JS sitemap fallback links every real node", async ({ browser }) => {
    const context = await browser.newContext({ javaScriptEnabled: false });
    const page = await context.newPage();
    await page.goto("/map");

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
