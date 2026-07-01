/**
 * admin.1 — the gated read foundation, proven by app.inject over buildServer.
 *
 * The auth core (401 without a token, 401 on a wrong token, health open) and the
 * structural secret-strip run in ANY environment: the gate returns 401 before any
 * handler, /health catches a Postgres miss, and the strip is a serializer-shape
 * assertion over GameSummary. The live 200 path needs Postgres on :5432; those
 * tests skip-with-reason when it is unreachable — a check counts only if it runs,
 * so a deferral is named rather than hidden behind a false green.
 *
 * One shared server, built once and closed once. The @codemojex/db `sql` is a
 * MODULE SINGLETON (packages/db/src/client.ts:17) and buildServer's onClose ends
 * it (server.ts:75), so a fresh-per-test close would poison the pool for later
 * tests. Every test here is a read-only GET, so the shared instance keeps the
 * isolation the brief asked for. process.env is never mutated — the env is a
 * literal handed straight to buildServer, so no async test races another.
 */
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { connect } from "node:net";
import type { FastifyInstance } from "fastify";
import { buildServer } from "../src/server";
import type { Env } from "../src/env";
import { GameSummary } from "../src/schemas";

const testEnv: Env = {
  port: 0,
  host: "127.0.0.1",
  logLevel: "fatal",
  databaseUrl: "postgres://localhost:5432/codemojex_dev",
  valkeyHost: "localhost",
  valkeyPort: 6390,
  adminToken: "test-admin-token",
};

const bearer = { authorization: `Bearer ${testEnv.adminToken}` };

/** Is a TCP port accepting connections? Gates the live-Postgres tests. */
function tcpReachable(host: string, port: number, timeoutMs = 600): Promise<boolean> {
  return new Promise((resolve) => {
    const socket = connect({ host, port });
    const done = (ok: boolean): void => {
      socket.destroy();
      resolve(ok);
    };
    socket.setTimeout(timeoutMs);
    socket.once("connect", () => done(true));
    socket.once("timeout", () => done(false));
    socket.once("error", () => done(false));
  });
}

let app: FastifyInstance;
let pgUp = false;

before(async () => {
  pgUp = await tcpReachable(testEnv.host, 5432);
  app = buildServer(testEnv);
  await app.ready();
});

after(async () => {
  await app.close();
});

// ---- auth core (environment-independent) ----

test("admin.1-INV3 · GET /health is open and tokenless (200 + substrate keys)", async () => {
  const res = await app.inject({ method: "GET", url: "/health" });
  assert.equal(res.statusCode, 200);
  const body = res.json() as Record<string, unknown>;
  assert.ok("postgres" in body, "health body carries postgres");
  assert.ok("valkey" in body, "health body carries valkey");
  assert.ok("worker" in body, "health body carries worker");
});

test("admin.1-INV1 · GET /rooms without a token → 401 { error: unauthorized }", async () => {
  const res = await app.inject({ method: "GET", url: "/rooms" });
  assert.equal(res.statusCode, 401);
  assert.deepEqual(res.json(), { error: "unauthorized" });
});

test("admin.1-INV1 · GET /rooms with a wrong bearer → 401", async () => {
  const res = await app.inject({
    method: "GET",
    url: "/rooms",
    headers: { authorization: "Bearer wrong" },
  });
  assert.equal(res.statusCode, 401);
});

test("admin.1-INV1 · GET /games (list) without a token → 401 (the gate covers games)", async () => {
  // The LIST route carries no params, so the preHandler gate runs before any
  // validation could 400 a bad :id — this proves the gate, not param-checking.
  const res = await app.inject({ method: "GET", url: "/games" });
  assert.equal(res.statusCode, 401);
});

test("admin.1-INV2 · GameSummary lists neither secret nor cellCodes (serializer strip)", () => {
  const keys = Object.keys(GameSummary.properties);
  assert.ok(!keys.includes("secret"), "no secret column on the public game shape");
  assert.ok(!keys.includes("cellCodes"), "no cellCodes column on the public game shape");
  assert.ok(!keys.includes("cell_codes"), "no cell_codes column on the public game shape");
});

// ---- the live 200 path (Postgres-gated; skip-with-reason when :5432 is down) ----

test("admin.1-INV1 · GET /rooms with the bearer → 200 (live Postgres)", async (t) => {
  if (!pgUp) {
    t.skip("Postgres :5432 unreachable — live 200-path deferred to a PG-up run");
    return;
  }
  const res = await app.inject({ method: "GET", url: "/rooms", headers: bearer });
  assert.equal(res.statusCode, 200);
});

test("admin.1-INV2 · GET /games/:id (live) → 200, body free of secret + cellCodes", async (t) => {
  if (!pgUp) {
    t.skip("Postgres :5432 unreachable — live secret-strip deferred to a PG-up run");
    return;
  }
  // Wave 2 wired the reads to the real schema — /games MUST read now; a 500 is a regression.
  const list = await app.inject({ method: "GET", url: "/games", headers: bearer });
  assert.equal(list.statusCode, 200);
  const rows = list.json() as Array<{ id: string }>;
  if (rows.length === 0) {
    t.skip("no games in the live DB — live detail secret-strip deferred (no invented data)");
    return;
  }
  // Discover a real game id from the live list rather than inventing a row.
  const res = await app.inject({ method: "GET", url: `/games/${rows[0].id}`, headers: bearer });
  assert.equal(res.statusCode, 200);
  const body = res.json() as { game: Record<string, unknown> };
  assert.ok(!("secret" in body.game), "no secret on the wire");
  assert.ok(!("cellCodes" in body.game), "no cellCodes on the wire");
  assert.ok(!("cell_codes" in body.game), "no cell_codes on the wire");
});
