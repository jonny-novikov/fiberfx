import { test, expect } from "@playwright/test";

/**
 * E9 — Elixir branding & course-navigation footer BASELINE.
 *
 * Header identity ("elixir", not "knowledge map"), the UX/SEO footer that links every
 * chapter from every page, and the copyright line. Same E2E_BASE_URL contract as
 * elixir-hero.spec.ts: re-run against the migrated Phoenix/Portal app to prove the
 * branding and internal-link structure survive the migration.
 *
 *   npm test -- elixir-branding
 *   E2E_BASE_URL=https://<portal-host> npm test -- elixir-branding
 */

const PAGE = "/elixir/algorithms/dynamic-programming"; // representative content page
const CHAPTERS = [
  "/elixir/algebra",
  "/elixir/functional",
  "/elixir/language",
  "/elixir/algorithms",
  "/elixir/pragmatic",
  "/elixir/phoenix",
];

test.describe("E9 header identity", () => {
  test("logo sub reads 'elixir', and 'knowledge map' is gone", async ({ page }) => {
    await page.goto(PAGE);
    const sub = (await page.locator("header.site .brand .sub").textContent()) ?? "";
    expect(sub.trim().toLowerCase()).toBe("elixir");
    await expect(page.locator("body")).not.toContainText("knowledge map");
  });
});

test.describe("E9 course-navigation footer (UX + SEO)", () => {
  test("footer links every chapter (internal link equity from every page)", async ({ page }) => {
    await page.goto(PAGE);
    const nav = page.locator("footer.site-foot nav.foot-nav");
    await expect(nav).toBeVisible();
    for (const href of CHAPTERS) {
      await expect(nav.locator(`a[href="${href}"]`), `footer must link ${href}`).toHaveCount(1);
    }
    // /elixir is linked by both the brand logo and the "Course home" link — at least once
    expect(await nav.locator('a[href="/elixir"]').count()).toBeGreaterThanOrEqual(1);
    await expect(nav.locator('a[href="/elixir/course"]')).toHaveCount(1); // contents
  });

  test("copyright reads '(c) jonnify' on the bottom bar", async ({ page }) => {
    await page.goto(PAGE);
    const cc = page.locator("footer.site-foot .foot-cc");
    await expect(cc).toContainText("jonnify");
    await expect(cc).toContainText("©"); // ©
  });

  test("the branded build stamp is preserved in the new footer", async ({ page }) => {
    await page.goto(PAGE);
    await expect(page.locator("footer.site-foot #stampId")).toHaveCount(1);
  });
});

test.describe("E9 course-root pager label", () => {
  test("pager reads 'jonnify · Functional Programming in Elixir' (no 'knowledge map')", async ({ page }) => {
    await page.goto("/elixir");
    const pleft = page.locator(".pager .p-left").first();
    await expect(pleft).toContainText("jonnify");
    await expect(pleft).toContainText("Functional Programming in Elixir");
    await expect(pleft).not.toContainText("knowledge map");
  });
});
