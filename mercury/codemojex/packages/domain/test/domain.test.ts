import { test } from "node:test";
import assert from "node:assert/strict";
import { CM } from "../src/index.js";

test("registers the codemojex namespaces, and USR is not one of them", () => {
  assert.deepEqual(
    [...CM.names].sort(),
    ["EMS", "GAM", "GES", "JOB", "PLR", "ROM", "SES", "TXN"],
  );
  assert.equal(CM.has("GAM"), true);
  assert.equal(CM.has("USR"), false); // USR is the codec example, not a codemojex namespace
});

test("the gate admits the right namespace and refuses others (error-as-value)", () => {
  const goodGam = "GAM0OOcCGXy0v7";

  const okR = CM.gate("GAM", goodGam);
  assert.equal(okR.isOk(), true);

  const wrongNs = CM.gate("ROM", goodGam);
  assert.equal(wrongNs.isErr(), true);
  if (wrongNs.isErr()) assert.equal(wrongNs.error, "namespace");

  const malformed = CM.gate("GAM", "GAM-not-valid-id");
  assert.equal(malformed.isErr(), true);
  if (malformed.isErr()) assert.equal(malformed.error, "invalid");
});

test("idSchema carries the namespace pattern and length bounds", () => {
  const s = CM.idSchema("PLR") as { pattern: string; minLength: number; maxLength: number };
  assert.equal(s.pattern, "^PLR[0-9A-Za-z]{11}$");
  assert.equal(s.minLength, 14);
  assert.equal(s.maxLength, 14);
});

test("brand and shape guard agree on a well-formed id", () => {
  const id = CM.brand("ROM", "ROM0OOcCGXy0v3");
  assert.equal(CM.is("ROM", id), true);
  assert.equal(CM.is("GAM", id), false);
});
