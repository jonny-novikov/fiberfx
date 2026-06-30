import { test } from "node:test";
import assert from "node:assert/strict";
import { Value } from "@sinclair/typebox/value";
import {
  isBranded,
  namespaceOf,
  assertBranded,
  unsafeBrand,
  loadEnv,
  EnvError,
  BrandedIdSchema,
  ok,
  err,
} from "../src/index.js";

test("isBranded is a shape guard over namespace + base62", () => {
  assert.equal(isBranded("ROM0OOcCGXy0v3", "ROM"), true);
  assert.equal(isBranded("ROM0OOcCGXy0v3", "GAM"), false); // wrong namespace
  assert.equal(isBranded("rom0OOcCGXy0v3", "ROM"), false); // lowercase ns
  assert.equal(isBranded("ROM0OOcCGXy0v", "ROM"), false); // too short
  assert.equal(isBranded("ROM0OOcCGXy0v3x", "ROM"), false); // too long
  assert.equal(isBranded(42 as unknown, "ROM"), false); // non-string
});

test("namespaceOf reads a well-formed id's namespace", () => {
  assert.equal(namespaceOf("PLR0OOcCGXy0v5"), "PLR");
  assert.equal(namespaceOf("ZZZ0OOcCGXy0v5"), null); // unregistered ns
  assert.equal(namespaceOf("not-an-id"), null);
});

test("assertBranded returns the branded value or throws", () => {
  assert.equal(assertBranded("GAM0OOcCGXy0v7", "GAM"), "GAM0OOcCGXy0v7");
  assert.throws(() => assertBranded("GAM0OOcCGXy0v7", "ROM"), TypeError);
});

test("BrandedIdSchema validates the namespace pattern at runtime", () => {
  const gam = BrandedIdSchema("GAM");
  assert.equal(Value.Check(gam, "GAM0OOcCGXy0v7"), true);
  assert.equal(Value.Check(gam, "ROM0OOcCGXy0v3"), false); // wrong ns
  assert.equal(Value.Check(gam, "GAM-bad"), false); // malformed
});

test("loadEnv parses, strips inline comments, and fails on missing required", () => {
  const env = loadEnv(
    (r) => ({
      port: r.int("PORT", 3000),
      vk: r.int("VK"),
      host: r.str("HOST", "127.0.0.1"),
      mode: r.oneOf("MODE", ["dev", "prod"] as const, "dev"),
    }),
    { VK: "6390 # passwordless", MODE: "prod" },
  );
  assert.equal(env.port, 3000); // fallback used
  assert.equal(env.vk, 6390); // inline comment stripped
  assert.equal(env.host, "127.0.0.1");
  assert.equal(env.mode, "prod");
  assert.equal(Object.isFrozen(env), true);
  assert.throws(() => loadEnv((r) => ({ x: r.str("REQUIRED_MISSING") }), {}), EnvError);
});

test("result helpers round-trip", () => {
  assert.equal(ok(1).isOk(), true);
  assert.equal(err("e").isErr(), true);
  assert.equal(unsafeBrand("PLR0OOcCGXy0v5", "PLR"), "PLR0OOcCGXy0v5");
});
