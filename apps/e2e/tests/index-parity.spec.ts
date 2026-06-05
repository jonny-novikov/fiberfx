import { test, expect, type Page } from "@playwright/test";

/**
 * F6.5.5 — two-origin index parity gate.
 *
 * Proves each published Phoenix index renders identically to its static Fiber
 * original, on COMPUTED STYLE + GEOMETRY (not pixel snapshots, f0.roadmap.md M5),
 * and that internal links resolve per the remap rule. Two routes, each at two
 * origins:
 *
 *   /        Phoenix :4000/        vs  Fiber :8765/courses   (html/courses.html)
 *   /elixir  Phoenix :4000/elixir  vs  Fiber :8765/elixir    (elixir/index.html)
 *
 * The Fiber origin is Playwright's baseURL (E2E_BASE_URL || :8765); the Phoenix
 * origin is driven by ABSOLUTE page.goto from PORTAL_BASE_URL (default :4000),
 * since one baseURL cannot serve both. Run order:
 *
 *   # baseline — confirms the spec is correct against the live static pages
 *   E2E_BASE_URL=http://localhost:8765 npx playwright test index-parity
 *   # parity   — confirms Phoenix matches (boot the node first)
 *   PORTAL_BASE_URL=http://localhost:4000 npx playwright test index-parity
 *
 * The clamp guard the baseline (elixir-hero.spec.ts) encodes — h1 > 70px,
 * .prose p > 18px — is asserted on /elixir at BOTH origins: a Phoenix h1
 * collapsing to 32px is a dropped/unspaced clamp and fails here.
 */

const DESKTOP = { width: 1440, height: 1300 };

const FIBER_BASE = process.env.E2E_BASE_URL || "http://localhost:8765";
const PORTAL_BASE = process.env.PORTAL_BASE_URL || "http://localhost:4000";

// The same route on each origin: Fiber serves /courses + /elixir; Portal serves
// / + /elixir. Absolute URLs drive both sides off Playwright's single baseURL.
const COURSES = {
  fiber: `${FIBER_BASE}/courses`,
  portal: `${PORTAL_BASE}/`,
};
const ELIXIR = {
  fiber: `${FIBER_BASE}/elixir`,
  portal: `${PORTAL_BASE}/elixir`,
};

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
// Count anchors whose href starts with a prefix, in the rendered DOM.
async function hrefCount(page: Page, prefix: string): Promise<number> {
  return page.evaluate(
    (p) =>
      Array.from(document.querySelectorAll("a[href]")).filter((a) =>
        (a.getAttribute("href") || "").startsWith(p),
      ).length,
    prefix,
  );
}

test.describe("F6.5.5 · / (courses index) parity — Phoenix vs Fiber", () => {
  test.use({ viewport: DESKTOP });

  for (const [origin, url] of Object.entries(COURSES)) {
    test(`type scale: .hero-title renders large + .hero-sub present (${origin})`, async ({
      page,
    }) => {
      await page.goto(url);
      const title = await styleOf(page, ".hero-title");
      expect(title, ".hero-title must exist").not.toBeNull();
      // courses.html .hero-title clamp max is 4.4rem (~70px @1440); a dropped clamp
      // would collapse it to the 32px UA default. Guard well above that.
      expect(title!.fontSize).toBeGreaterThan(40);
      const sub = await styleOf(page, ".hero-sub");
      expect(sub, ".hero-sub must exist (courses.html has no .prose)").not.toBeNull();
    });

    test(`geometry: hero sits above #series; the two .series-card share a row (${origin})`, async ({
      page,
    }) => {
      await page.goto(url);
      const hero = await rectOf(page, ".hero.hub-hero");
      const series = await rectOf(page, "#series");
      expect(hero && series, "hero + #series must exist").toBeTruthy();
      expect(series!.y).toBeGreaterThan(hero!.y); // hero above the course grid

      const cards = await page.evaluate(() =>
        Array.from(document.querySelectorAll(".series-card")).map((el) => {
          const r = el.getBoundingClientRect();
          return { x: Math.round(r.x), y: Math.round(r.y) };
        }),
      );
      expect(cards.length).toBe(2);
      expect(cards[0].y).toBe(cards[1].y); // same row (desktop)
      expect(cards[1].x).toBeGreaterThan(cards[0].x); // side by side
    });
  }

  // The remap is a PORTAL-rendering property — the Fiber baseline serves the
  // un-remapped originals (relative deep links it actually serves), so the remap
  // assertion runs on the Portal origin ONLY.
  test("remap (portal): agile card → production, / and /elixir relative", async ({
    page,
  }) => {
    await page.goto(COURSES.portal);
    // The agile card link is production (Portal does not serve /course/...).
    expect(
      await hrefCount(page, "https://jonnify.fly.dev/course/agile-agent-workflow"),
    ).toBe(1);
    // No un-remapped /course/ deep link survives.
    expect(await hrefCount(page, "/course/")).toBe(0);
    // The routes Portal serves stay relative.
    expect(await hrefCount(page, "/elixir")).toBeGreaterThan(0);
    const elixirCard = await page.getAttribute(
      '.series-card[data-tags="elixir"]',
      "href",
    );
    expect(elixirCard).toBe("/elixir");
    const brand = await page.getAttribute(".brand", "href");
    expect(brand).toBe("/");
  });
});

test.describe("F6.5.5 · /elixir (course index) parity — Phoenix vs Fiber", () => {
  test.use({ viewport: DESKTOP });

  for (const [origin, url] of Object.entries(ELIXIR)) {
    test(`type scale: h1 > 70px + .prose p > 18px — the clamp guard (${origin})`, async ({
      page,
    }) => {
      await page.goto(url);
      const h1 = await styleOf(page, "h1");
      expect(h1, "h1 must exist").not.toBeNull();
      // elixir/index.html h1 clamp max is 5.1rem (~81.6px @1440); the no-space-clamp
      // bug collapsed it to the 2em (32px) UA default.
      expect(h1!.fontSize).toBeGreaterThan(70);
      const body = await styleOf(page, ".prose p");
      expect(body, ".prose p must exist").not.toBeNull();
      expect(body!.fontSize).toBeGreaterThan(18); // ~18.88px @1440
    });

    test(`geometry: the arc figure sits above the first .chap; .mods grid multi-column (${origin})`, async ({
      page,
    }) => {
      await page.goto(url);
      // The arc figure is the figure.fig that contains the .arc-node buttons.
      const arc = await page.evaluate(() => {
        const fig = Array.from(document.querySelectorAll("figure.fig")).find(
          (f) => f.querySelector(".arc-node"),
        );
        if (!fig) return null;
        const r = fig.getBoundingClientRect();
        return { y: Math.round(r.y) };
      });
      const firstChap = await rectOf(page, ".chap");
      expect(arc, "the arc figure must exist").not.toBeNull();
      expect(firstChap, "the first .chap must exist").not.toBeNull();
      expect(firstChap!.y).toBeGreaterThan(arc!.y); // arc above the chapter directory

      // The .mods grid is multi-column on desktop: the .mod cards in a chapter
      // occupy more than one distinct x.
      const modXs = await page.evaluate(() => {
        const chap = document.querySelector(".chap");
        if (!chap) return [];
        return Array.from(chap.querySelectorAll(".mod")).map((el) =>
          Math.round(el.getBoundingClientRect().x),
        );
      });
      expect(new Set(modXs).size).toBeGreaterThan(1);
    });
  }

  // The remap is a PORTAL-rendering property — the Fiber baseline serves the
  // un-remapped original (relative /elixir/... deep links it actually serves), so
  // the remap + arc-route assertions run on the Portal origin ONLY.
  test("remap (portal): zero /elixir/ deep links; deep hrefs → production; bare /elixir relative", async ({
    page,
  }) => {
    await page.goto(ELIXIR.portal);
    // The load-bearing assertion: no un-remapped deep /elixir/ link survives.
    expect(await hrefCount(page, "/elixir/")).toBe(0);
    // Every deep link is production.
    expect(
      await hrefCount(page, "https://jonnify.fly.dev/elixir/"),
    ).toBeGreaterThan(0);
    // The bare /elixir self-links stay relative.
    const bareCount = await page.evaluate(
      () =>
        Array.from(document.querySelectorAll("a[href]")).filter(
          (a) => a.getAttribute("href") === "/elixir",
        ).length,
    );
    expect(bareCount).toBe(3);
    // Spot-check: a hero CTA and a .mod card both resolve to production.
    const heroCta = await page.getAttribute(".hero .cta-row a.btn", "href");
    expect(heroCta).toMatch(/^https:\/\/jonnify\.fly\.dev\/elixir\//);
    const modCard = await page.getAttribute("a.mod", "href");
    expect(modCard).toMatch(/^https:\/\/jonnify\.fly\.dev\/elixir\//);
    // The in-page skip anchor stays untouched.
    const skip = await page.getAttribute("a.skip", "href");
    expect(skip).toBe("#main");
  });

  test('arc selector (portal): switching a chapter points "Open Fn" at production', async ({
    page,
  }) => {
    await page.goto(ELIXIR.portal);
    // Select F2 via its arc node; the arc readout's open link is built from the
    // remapped CH "route" field, so it must resolve to production.
    await page.click('.arc-node[data-ch="F2"]');
    const openHref = await page.getAttribute("#arcOpen a", "href");
    expect(openHref).toMatch(/^https:\/\/jonnify\.fly\.dev\/elixir\//);
  });
});
