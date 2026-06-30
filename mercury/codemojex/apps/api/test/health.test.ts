import { test, expect } from "vitest";
import { buildApp } from "../src/app.js";

// Fastify's canonical in-process test idiom: build the app and `inject()` a
// request — no port bound, the full plugin/route stack exercised. A dummy
// DATABASE_URL is enough because the pg pool connects lazily (plugins/db.ts)
// and the health route never queries it (it returns process.uptime()).
test("GET /api/health -> 200 ok", async () => {
  const app = await buildApp({
    DATABASE_URL: "postgres://postgres:postgres@localhost:5432/codemojex",
    PORT: 0,
    HOST: "127.0.0.1",
    LOG_LEVEL: "silent",
  });

  try {
    const res = await app.inject({ method: "GET", url: "/api/health" });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toMatchObject({ status: "ok" });
    expect(typeof res.json().uptime).toBe("number");
  } finally {
    await app.close();
  }
});
