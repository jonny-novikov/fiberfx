import { test, expect } from "@playwright/test";
import {
  gotoMap,
  enterSeriesAndSettle,
  motionRunning,
  view,
} from "../fixtures/mindmap";

/**
 * E5 — Performance and runtime health: no console errors or page errors across
 * entering a scene, interacting, and a settle window; an acceptable rAF frame
 * cadence while the render loop runs; the loop pausing on tab hide and resuming
 * on restore; and no WebGL context loss or GL error surfaced to the console.
 */

/** Patterns that signal a GPU/WebGL failure surfaced to the console. */
const GL_FAILURE = /webgl context lost|context lost|gl error|webglrenderer/i;

test.describe("E5 perf: console health, cadence, visibility, WebGL", () => {
  test("no console errors, page errors, or WebGL failures across enter + interact", async ({
    page,
  }) => {
    const consoleErrors: string[] = [];
    const pageErrors: string[] = [];
    const glFailures: string[] = [];

    page.on("console", (message) => {
      const text = message.text();
      if (message.type() === "error") consoleErrors.push(text);
      if (GL_FAILURE.test(text)) glFailures.push(text);
    });
    page.on("pageerror", (error) => {
      pageErrors.push(error.message);
      if (GL_FAILURE.test(error.message)) glFailures.push(error.message);
    });

    await gotoMap(page);
    await enterSeriesAndSettle(page, "school");

    // Drag the canvas to drive a render, then return to root and re-enter.
    const box = await page.locator("#gl").boundingBox();
    if (box) {
      const cx = box.x + box.width / 2;
      const cy = box.y + box.height / 2;
      await page.mouse.move(cx, cy);
      await page.mouse.down();
      await page.mouse.move(cx + 120, cy + 60, { steps: 8 });
      await page.mouse.up();
      await page.mouse.wheel(0, -240);
    }
    await page.evaluate(() => window.__mindmap.back());
    await enterSeriesAndSettle(page, "future");

    // Observe a fixed two-second window so asynchronous work (the render loop,
    // the lazy three.js import, deferred handlers) has time to surface errors.
    await page.evaluate(
      () => new Promise<void>((resolve) => setTimeout(resolve, 2000)),
    );

    expect(consoleErrors, consoleErrors.join("\n")).toEqual([]);
    expect(pageErrors, pageErrors.join("\n")).toEqual([]);
    expect(glFailures, glFailures.join("\n")).toEqual([]);
  });

  test("median rAF frame delta stays under 22ms while the render loop runs", async ({
    page,
  }) => {
    await gotoMap(page);
    await enterSeriesAndSettle(page, "school");

    const running = await motionRunning(page);
    test.skip(!running, "render loop is not running in this environment");

    const median = await page.evaluate(async () => {
      const deltas: number[] = [];
      await new Promise<void>((resolve) => {
        let last = performance.now();
        const stopAt = last + 1500;
        function tick(now: number) {
          deltas.push(now - last);
          last = now;
          if (now < stopAt) {
            requestAnimationFrame(tick);
          } else {
            resolve();
          }
        }
        requestAnimationFrame(tick);
      });
      const sorted = deltas.slice(1).sort((a, b) => a - b);
      return sorted.length ? sorted[Math.floor(sorted.length / 2)] : Infinity;
    });

    expect(median).toBeLessThan(22);
  });

  test("render loop pauses when the tab hides and resumes when restored", async ({
    page,
  }) => {
    await gotoMap(page);
    await enterSeriesAndSettle(page, "school");

    const initiallyRunning = await motionRunning(page);
    test.skip(!initiallyRunning, "render loop is not running in this environment");

    await page.evaluate(() => {
      Object.defineProperty(document, "visibilityState", {
        configurable: true,
        get: () => "hidden",
      });
      document.dispatchEvent(new Event("visibilitychange"));
    });
    await expect.poll(() => motionRunning(page)).toBe(false);

    await page.evaluate(() => {
      Object.defineProperty(document, "visibilityState", {
        configurable: true,
        get: () => "visible",
      });
      document.dispatchEvent(new Event("visibilitychange"));
    });
    await expect.poll(() => motionRunning(page)).toBe(true);
    expect(await view(page)).toBe("scene");
  });
});
