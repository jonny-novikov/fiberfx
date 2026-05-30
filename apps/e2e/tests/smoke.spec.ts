import { test, expect } from "@playwright/test";
import { leaves, nodeById } from "../fixtures/mindmap";

/**
 * E1 — Smoke: every served entry point responds with the expected status and
 * content type. The leaf sample is drawn from the dataset so it stays in sync.
 */

test.describe("E1 smoke: server endpoints respond", () => {
  test("GET / returns 200 text/html", async ({ request }) => {
    const response = await request.get("/");
    expect(response.status()).toBe(200);
    expect(response.headers()["content-type"] ?? "").toContain("text/html");
  });

  test("GET /map returns 200 text/html", async ({ request }) => {
    const response = await request.get("/map");
    expect(response.status()).toBe(200);
    expect(response.headers()["content-type"] ?? "").toContain("text/html");
  });

  test("GET /game returns 200", async ({ request }) => {
    const response = await request.get("/game");
    expect(response.status()).toBe(200);
  });

  test("GET /health returns {status:'ok'}", async ({ request }) => {
    const response = await request.get("/health");
    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body.status).toBe("ok");
  });

  test("GET /edu returns 200", async ({ request }) => {
    const response = await request.get("/edu");
    expect(response.status()).toBe(200);
  });

  test("sampled leaf URLs from the dataset return 200", async ({ request }) => {
    const sampleIds = [
      "school/kiselev",
      "future/claude-code",
      "edu/finances-m1",
      "ege/stereometria",
    ];
    for (const id of sampleIds) {
      const node = nodeById(id);
      expect(node, `dataset must contain ${id}`).toBeDefined();
      const url = node!.url as string;
      const response = await request.get(url);
      expect(response.status(), `${url} should respond 200`).toBe(200);
    }
  });

  test("a representative leaf from the loader resolves", async ({ request }) => {
    expect(leaves.length).toBeGreaterThan(0);
    const first = leaves[0];
    const response = await request.get(first.url as string);
    expect(response.status()).toBe(200);
  });
});
