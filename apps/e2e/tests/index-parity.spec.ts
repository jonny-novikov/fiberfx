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
 *
 * CONFIGURABLE NAV BASE (F6.5.5-D9 / INV9(a)). The remapped deep-link host is
 * application config (`PortalWeb.deep_link_base/0`), default https://jonnify.fly.dev.
 * The remap assertions assert NAV_BASE (PORTAL_DEEP_LINK_BASE, same default), so
 * "configurable" is a CHECKED claim: boot the node with DEEP_LINK_BASE_URL set to a
 * test host AND run with PORTAL_DEEP_LINK_BASE the same value, and the rendered
 * markup deep-links AND the JS-built arc link both carry the override — while the
 * asset-locality test (INV9(b)) proves the override never sweeps an /assets/* ref.
 *
 *   DEEP_LINK_BASE_URL=https://example.test mix phx.server   # boot the node with it
 *   PORTAL_BASE_URL=http://localhost:4000 PORTAL_DEEP_LINK_BASE=https://example.test \
 *     npx playwright test index-parity                       # assert the override re-renders
 */

const DESKTOP = { width: 1440, height: 1300 };

const FIBER_BASE = process.env.E2E_BASE_URL || "http://localhost:8765";
const PORTAL_BASE = process.env.PORTAL_BASE_URL || "http://localhost:4000";
// The configurable deep-link base the Portal is expected to render (F6.5.5-D9). The
// default matches config.exs; set PORTAL_DEEP_LINK_BASE to the host the node was
// booted with (DEEP_LINK_BASE_URL) to prove the swap re-renders both nav surfaces.
const NAV_BASE = process.env.PORTAL_DEEP_LINK_BASE || "https://jonnify.fly.dev";

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
    // The agile card link carries the configurable base (Portal does not serve
    // /course/...). NAV_BASE proves the swap: set PORTAL_DEEP_LINK_BASE to the host
    // the node was booted with and this asserts the override, not a baked literal.
    expect(
      await hrefCount(page, NAV_BASE + "/course/agile-agent-workflow"),
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

  // INV9(b): the configurable base touches CATEGORY-4 nav links ONLY — the page's
  // OWN assets (category 2) stay Portal-local. A page pulling its CSS/JS from the
  // base would visually match yet be a hollow shell + a liveness regression.
  test("asset-locality (portal): courses.css/js are root-relative /assets, never the base", async ({
    page,
  }) => {
    await page.goto(COURSES.portal);
    const css = await page.getAttribute('link[rel="stylesheet"][href^="/assets/"]', "href");
    expect(css).toBe("/assets/courses.css");
    const js = await page.getAttribute('script[src^="/assets/"]', "src");
    expect(js).toBe("/assets/courses.js");
    // No asset ref was ever swept into the base / any external host.
    expect(await hrefCount(page, NAV_BASE + "/assets")).toBe(0);
    const swept = await page.evaluate(() =>
      Array.from(
        document.querySelectorAll('link[href*="/assets/"], script[src*="/assets/"]'),
      ).filter((el) => {
        const u = el.getAttribute("href") || el.getAttribute("src") || "";
        return /^https?:\/\//.test(u); // any absolute /assets/ URL is a regression
      }).length,
    );
    expect(swept).toBe(0);
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
    // Every deep link carries the configurable base (NAV_BASE proves the swap).
    expect(await hrefCount(page, NAV_BASE + "/elixir/")).toBeGreaterThan(0);
    // The bare /elixir self-links stay relative.
    const bareCount = await page.evaluate(
      () =>
        Array.from(document.querySelectorAll("a[href]")).filter(
          (a) => a.getAttribute("href") === "/elixir",
        ).length,
    );
    expect(bareCount).toBe(3);
    // Spot-check: a hero CTA and a .mod card both carry the configurable base.
    const heroCta = await page.getAttribute(".hero .cta-row a.btn", "href");
    expect(heroCta!.startsWith(NAV_BASE + "/elixir/")).toBe(true);
    const modCard = await page.getAttribute("a.mod", "href");
    expect(modCard!.startsWith(NAV_BASE + "/elixir/")).toBe(true);
    // The in-page skip anchor stays untouched.
    const skip = await page.getAttribute("a.skip", "href");
    expect(skip).toBe("#main");
  });

  test('arc selector (portal): switching a chapter builds "Open Fn" from the configurable base', async ({
    page,
  }) => {
    await page.goto(ELIXIR.portal);
    // Select F2 via its arc node; the arc readout's open link is built by the static
    // JS from the injected base + the (now relative) CH "route" field — so it must
    // carry NAV_BASE, proving the injected value (not a baked literal) drives it.
    await page.click('.arc-node[data-ch="F2"]');
    const openHref = await page.getAttribute("#arcOpen a", "href");
    expect(openHref!.startsWith(NAV_BASE + "/elixir/")).toBe(true);
  });

  // INV9(b): elixir-index.css/js stay Portal-local; the injected deep-link base
  // reaches the JS's ~6 nav routes ONLY, NEVER an asset fetch.
  test("asset-locality (portal): elixir-index.css/js are root-relative /assets, never the base", async ({
    page,
  }) => {
    await page.goto(ELIXIR.portal);
    const css = await page.getAttribute('link[rel="stylesheet"][href^="/assets/"]', "href");
    expect(css).toBe("/assets/elixir-index.css");
    const js = await page.getAttribute('script[src^="/assets/"]', "src");
    expect(js).toBe("/assets/elixir-index.js");
    expect(await hrefCount(page, NAV_BASE + "/assets")).toBe(0);
    const swept = await page.evaluate(() =>
      Array.from(
        document.querySelectorAll('link[href*="/assets/"], script[src*="/assets/"]'),
      ).filter((el) => {
        const u = el.getAttribute("href") || el.getAttribute("src") || "";
        return /^https?:\/\//.test(u);
      }).length,
    );
    expect(swept).toBe(0);
  });
});
