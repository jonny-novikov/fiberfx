import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";
import { tgInitCookie } from "../lib/initData";
import { botToken } from "../lib/env";
import { shoot } from "../lib/shoot";

// A distinct Telegram user per run-ish so repeated runs stay clean.
const TG_USER = { id: 770_001, first_name: "E2E", username: "e2e_player" };

function authCookie(baseURL: string) {
  return tgInitCookie(baseURL, botToken(), TG_USER);
}

test.describe("Codemojex · three-tier render", () => {
  // ── Story 1 ─ Tier 1: the static welcome ───────────────────────────────────
  test("Tier 1 — welcome shell renders the play entry", async ({ page }, testInfo) => {
    // The Tier-1 welcome (with the play link) is the static shell at
    // /welcome/index.html (edge-served in prod). "/" is the legacy API landing.
    await page.goto("/welcome/index.html");
    await expect(page.getByText("Играть")).toBeVisible();
    await shoot(page, testInfo, "01-welcome");
  });

  // ── Story 2 ─ the reported "redirect": it is the auth gate, by design ───────
  test("Tier 2 — /lobby WITHOUT a Telegram session redirects off the lobby (auth gate)", async ({
    page,
    context,
  }, testInfo) => {
    await context.clearCookies();
    await page.goto("/lobby");
    // LobbyLive.mount fails Session.resolve(nil) -> redirect(to: "/").
    await expect(page).toHaveURL(/\/$/);
    await expect(page).not.toHaveURL(/\/lobby$/);
    await shoot(page, testInfo, "02-lobby-redirect-gate");
  });

  // ── Story 3 ─ the proof: with a real signed session, the lobby renders ──────
  test("Tier 2 — /lobby WITH a valid Telegram session renders the rooms", async ({
    page,
    context,
    baseURL,
  }, testInfo) => {
    await context.addCookies([authCookie(baseURL!)]);
    await page.goto("/lobby");

    await expect(page).toHaveURL(/\/lobby$/);
    await expect(page.locator("h1.lobby__title")).toHaveText(/Выбери сейф/);
    await expect(page.locator(".room-card").first()).toBeVisible();
    await shoot(page, testInfo, "03-lobby-authenticated");
  });

  // ── Story 4 ─ Tier 3: entering a room reaches the GameLive board shell ───────
  // The React board itself is edge-delivered (static.codemoji.games) and is NOT
  // loaded in dev, so we assert the LiveView shell + mount point, not React UI.
  test("Tier 3 — entering a room navigates to the GameLive board shell", async ({
    page,
    context,
    baseURL,
  }, testInfo) => {
    await context.addCookies([authCookie(baseURL!)]);
    await page.goto("/lobby");
    await expect(page.locator(".room-card").first()).toBeVisible();

    // The enter button is a phx-click handled over the live socket, so wait until
    // the live socket is actually connected (a dead-render click is a no-op).
    await page.waitForFunction(
      () => Boolean((window as any).liveSocket && (window as any).liveSocket.isConnected()),
      undefined,
      { timeout: 15_000 },
    );
    await page.locator(".room-card__enter").first().click();

    await expect(page).toHaveURL(/\/game\/GAM[A-Za-z0-9]+/, { timeout: 15_000 });
    const boardRoot = page.locator("#board-root");
    await expect(boardRoot).toBeAttached();
    // The shell seals the React subtree (EdgeReact hook) and feeds it server props.
    // data-bundle is the edge pointer (Codemojex.Edge) and is empty in dev until the
    // board is deployed to static.codemoji.games — so assert the shell + the
    // server-supplied props, not the (deferred) edge bundle URL.
    await expect(boardRoot).toHaveAttribute("phx-hook", "EdgeReact");
    await expect(boardRoot).toHaveAttribute("data-component", "BoardScreen");
    await expect(boardRoot).toHaveAttribute("data-props", /"view"/);
    await shoot(page, testInfo, "04-board-shell");
  });

  // ── Story 5 ─ a Playwright plugin in action: axe accessibility on the lobby ──
  test("a11y — the authenticated lobby has no critical axe violations", async ({
    page,
    context,
    baseURL,
  }, testInfo) => {
    await context.addCookies([authCookie(baseURL!)]);
    await page.goto("/lobby");
    await expect(page.locator("h1.lobby__title")).toBeVisible();

    const results = await new AxeBuilder({ page }).analyze();
    await testInfo.attach("axe-lobby.json", {
      body: JSON.stringify(results.violations, null, 2),
      contentType: "application/json",
    });
    await shoot(page, testInfo, "05-lobby-a11y");

    const critical = results.violations.filter((v) => v.impact === "critical");
    expect(
      critical,
      `critical a11y violations: ${critical.map((v) => v.id).join(", ") || "none"}`,
    ).toEqual([]);
  });
});
