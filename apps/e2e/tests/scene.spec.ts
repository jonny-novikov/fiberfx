import { test, expect } from "@playwright/test";
import {
  gotoMap,
  enterSeries,
  enterSeriesAndSettle,
  back,
  view,
  sceneNodeIds,
  activate,
  nodeLocator,
  childIdsOf,
  allRealUrls,
  plannedNodes,
} from "../fixtures/mindmap";

/**
 * E3 — Scene: entering a series mounts its hub plus children as 3D nodes with
 * CSS2D HTML labels; the labels carry [data-id] and the right roles. Activating
 * a leaf navigates to its clean url; back() returns to the root. Planned nodes
 * are inert and excluded from allRealUrls(). A pointer drag on the canvas
 * reorients the camera, which moves a known label's projected screen position.
 */

test.describe("E3 scene: enter, mount, drill, navigate, back, orbit", () => {
  test("entering a series mounts the hub's children as scene nodes", async ({
    page,
  }) => {
    await gotoMap(page);
    expect(await sceneNodeIds(page)).toEqual([]);

    await enterSeriesAndSettle(page, "school");
    expect(await view(page)).toBe("scene");

    const ids = await sceneNodeIds(page);
    // The hub's direct children are present in the scene at the first depth.
    for (const childId of childIdsOf("school")) {
      expect(ids, `scene must include ${childId}`).toContain(childId);
    }
  });

  test("a scene leaf has a CSS2D anchor label and navigates on activation", async ({
    page,
  }) => {
    await gotoMap(page);
    await enterSeriesAndSettle(page, "school");

    const leaf = nodeLocator(page, "school/kiselev");
    await expect(leaf).toBeVisible();
    // The leaf label is a real anchor to the clean url.
    expect(await leaf.evaluate((el) => el.tagName.toLowerCase())).toBe("a");
    await expect(leaf).toHaveAttribute("href", "/school/kiselev");

    // Programmatic activation routes through the same logic as a click/raycast.
    await activate(page, "school/kiselev");
    // Wait for the navigation to commit, not the destination's CDN subresources.
    await page.waitForURL("**/school/kiselev", { waitUntil: "commit" });
    expect(new URL(page.url()).pathname).toBe("/school/kiselev");

    const response = await page.request.get("/school/kiselev");
    expect(response.status()).toBe(200);
  });

  test("an expandable node label carries button semantics and drills the scene", async ({
    page,
  }) => {
    await gotoMap(page);
    await enterSeriesAndSettle(page, "school");

    const subHub = nodeLocator(page, "school/sharygin-pokolenia");
    await expect(subHub).toBeVisible();
    await expect(subHub).toHaveAttribute("role", "button");
    await expect(subHub).toHaveAttribute("aria-expanded", /true|false/);
    await expect(subHub).toHaveAttribute("tabindex", "0");

    await activate(page, "school/sharygin-pokolenia");
    // Drilling rebuilds the scene around the sub-hub; its children now mount.
    await expect
      .poll(async () => {
        const ids = await sceneNodeIds(page);
        return childIdsOf("school/sharygin-pokolenia").every((id) =>
          ids.includes(id),
        );
      })
      .toBe(true);
    expect(await view(page)).toBe("scene");
  });

  test("back() returns the scene to the root view", async ({ page }) => {
    await gotoMap(page);
    await enterSeriesAndSettle(page, "school");
    expect(await view(page)).toBe("scene");

    await back(page);
    await expect.poll(() => view(page)).toBe("root");
    expect(await sceneNodeIds(page)).toEqual([]);
    await expect(page.locator("#root-view")).toBeVisible();
  });

  test("the visible back control returns to root on click", async ({ page }) => {
    await gotoMap(page);
    await enterSeriesAndSettle(page, "school");

    const backButton = page.locator("#btn-back");
    await expect(backButton).toBeVisible();
    await backButton.click();
    await expect.poll(() => view(page)).toBe("root");
  });

  test("a planned node does not navigate and is absent from allRealUrls", async ({
    page,
  }) => {
    await gotoMap(page);

    const planned = plannedNodes[0];
    expect(planned, "the dataset has a planned node").toBeDefined();
    const plannedUrl = "/" + planned.id;

    // The planned id is never advertised as a real url.
    expect(await allRealUrls(page)).not.toContain(plannedUrl);

    // Enter the series that parents the planned node, then activate it.
    await enterSeriesAndSettle(page, planned.series);
    const before = page.url();
    await activate(page, planned.id);
    // Activation of a planned node is a no-op: the url must not change.
    await expect.poll(() => page.url()).toBe(before);
    expect(await view(page)).toBe("scene");
  });

  test("if present, a planned node label is non-anchor and aria-disabled", async ({
    page,
  }) => {
    await gotoMap(page);
    const planned = plannedNodes[0];
    await enterSeriesAndSettle(page, planned.series);

    const label = nodeLocator(page, planned.id);
    // The planned node may sit one drill below the hub; surface it if so.
    if ((await label.count()) === 0) {
      const parent = planned.parent;
      if (parent) {
        await activate(page, parent);
        await expect.poll(() => label.count()).toBeGreaterThan(0);
      }
    }
    if ((await label.count()) > 0) {
      await expect(label).toHaveAttribute("aria-disabled", "true");
      await expect(label).toHaveAttribute("data-planned", "true");
      expect(await label.evaluate((el) => el.tagName.toLowerCase())).not.toBe("a");
    }
  });

  test("a pointer drag on the canvas reorients the camera", async ({ page }) => {
    await gotoMap(page);
    await enterSeriesAndSettle(page, "school");

    const canvas = page.locator("#gl");
    await expect(canvas).toBeVisible();
    const box = await canvas.boundingBox();
    expect(box).not.toBeNull();

    // Sample a known label's projected screen position before and after a drag.
    // Under automation auto-motion is frozen, so any change in a label's screen
    // position is attributable to the orbit, which keeps this assertion stable.
    const labelId = "school/kiselev";
    const probe = nodeLocator(page, labelId);
    await expect(probe).toBeVisible();
    const before = await probe.boundingBox();
    expect(before).not.toBeNull();

    const cx = box!.x + box!.width / 2;
    const cy = box!.y + box!.height / 2;
    await page.mouse.move(cx, cy);
    await page.mouse.down();
    await page.mouse.move(cx + 160, cy + 40, { steps: 12 });
    await page.mouse.up();

    // The orbit moved the camera, so the label's projected position shifts.
    await expect
      .poll(async () => {
        const now = await probe.boundingBox();
        if (!now || !before) return 0;
        return Math.hypot(now.x - before.x, now.y - before.y);
      })
      .toBeGreaterThan(1);
  });
});
