import type { Page, TestInfo } from "@playwright/test";

/**
 * Save a full-page screenshot to ./screenshots AND attach it to the HTML report,
 * so each story's visual state is visible in `playwright show-report` (not only on
 * the filesystem). Returns the file path.
 */
export async function shoot(
  page: Page,
  testInfo: TestInfo,
  name: string,
): Promise<string> {
  const path = `screenshots/${name}.png`;
  await page.screenshot({ path, fullPage: true });
  await testInfo.attach(name, { path, contentType: "image/png" });
  return path;
}
