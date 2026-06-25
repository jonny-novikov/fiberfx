import { test, expect } from '@playwright/test';

/**
 * Visual regression tests for RoomsPage (React)
 * Screenshots serve as reference for Svelte mini-app comparison
 */
test.describe('RoomsPage Visual Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/rooms');
    await page.waitForLoadState('networkidle');
    // Wait for content to render
    await page.waitForSelector('[data-testid="status-bar"]', { timeout: 10000 });
  });

  test('full rooms page should capture reference', async ({ page }) => {
    // Wait for rooms to load
    await page.waitForSelector('[data-testid^="room-item-"]', { timeout: 10000 });

    await expect(page).toHaveScreenshot('rooms-page-full.png', {
      maxDiffPixels: 100,
      fullPage: true,
    });
  });

  test('status bar component reference', async ({ page }) => {
    const statusBar = page.locator('[data-testid="status-bar"]');
    await expect(statusBar).toBeVisible();

    await expect(statusBar).toHaveScreenshot('status-bar.png', {
      maxDiffPixels: 50,
    });
  });

  test('promo banner component reference', async ({ page }) => {
    const promoBanner = page.locator('[data-testid="promo-banner"]');
    await expect(promoBanner).toBeVisible();

    await expect(promoBanner).toHaveScreenshot('promo-banner.png', {
      maxDiffPixels: 50,
    });
  });

  test('room item component reference', async ({ page }) => {
    const roomItem = page.locator('[data-testid^="room-item-"]').first();
    await expect(roomItem).toBeVisible();

    await expect(roomItem).toHaveScreenshot('room-item.png', {
      maxDiffPixels: 50,
    });
  });

  test('verify status bar gradient styling', async ({ page }) => {
    const statusBar = page.locator('[data-testid="status-bar"]').first();
    await expect(statusBar).toBeVisible();

    // Verify rounded pill shape
    await expect(statusBar).toHaveCSS('border-radius', '9999px');
  });

  test('verify room card shadow', async ({ page }) => {
    const roomCard = page.locator('[data-testid^="room-item-"]').first();
    await expect(roomCard).toBeVisible();

    const boxShadow = await roomCard.evaluate(el =>
      window.getComputedStyle(el).boxShadow
    );
    expect(boxShadow).toContain('rgba');
  });
});

test.describe('GamePage Visual Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to a game room
    await page.goto('/game/test-room');
    await page.waitForLoadState('networkidle');
  });

  test('game page full reference', async ({ page }) => {
    await page.waitForSelector('.lobby-grid, [class*="grid"]', { timeout: 10000 });

    await expect(page).toHaveScreenshot('game-page-full.png', {
      maxDiffPixels: 100,
      fullPage: true,
    });
  });

  test('lobby info grid reference', async ({ page }) => {
    const lobbyInfo = page.locator('.px-2.grid').first();

    if (await lobbyInfo.isVisible()) {
      await expect(lobbyInfo).toHaveScreenshot('lobby-info.png', {
        maxDiffPixels: 50,
      });
    }
  });

  test('emotion picker reference', async ({ page }) => {
    const emotionPicker = page.locator('[data-testid="emotion-picker"], .emotion-picker').first();

    if (await emotionPicker.isVisible()) {
      await expect(emotionPicker).toHaveScreenshot('emotion-picker.png', {
        maxDiffPixels: 50,
      });
    }
  });
});
