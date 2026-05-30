import { test, expect } from "@playwright/test";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { allNodes, growth } from "../fixtures/mindmap";

/**
 * Guard against silent drift between the two copies of the dataset:
 *  - apps/e2e/fixtures/nodes.json — the declared single source of truth, and
 *  - the NODES / GROWTH literals inlined into map/index.html (the served 3D map
 *    page, which cannot fetch the JSON at runtime).
 *
 * The mindmap hook silently no-ops unknown ids, so a node present in nodes.json
 * but missing from the inlined copy would otherwise pass every other spec. This
 * test parses the literals straight out of map/index.html and deep-compares them.
 */

const MAP_HTML = fileURLToPath(
  new URL("../../../map/index.html", import.meta.url),
);

/** Extracts a `const <name> = [ ... ];` array literal and evaluates it. */
function extractArray(source: string, name: string): unknown[] {
  const marker = `const ${name} = [`;
  const start = source.indexOf(marker);
  if (start === -1) throw new Error(`could not find "${marker}" in map/index.html`);
  const open = source.indexOf("[", start);
  const end = source.indexOf("];", open);
  if (end === -1) throw new Error(`could not find end of ${name} literal`);
  const literal = source.slice(open, end + 1);
  // The literals are plain array-of-object-literals with no expressions; eval
  // them in an isolated function. Authored content only — no external input.
  return Function(`"use strict"; return (${literal});`)() as unknown[];
}

/** Canonical JSON with sorted keys so field order never matters. */
function canon(value: unknown): string {
  return JSON.stringify(value, (_k, v) => {
    if (v && typeof v === "object" && !Array.isArray(v)) {
      return Object.fromEntries(
        Object.keys(v as Record<string, unknown>)
          .sort()
          .map((k) => [k, (v as Record<string, unknown>)[k]]),
      );
    }
    return v;
  });
}

test.describe("dataset sync: map/index.html mirrors nodes.json", () => {
  const html = readFileSync(MAP_HTML, "utf8");

  test("inlined NODES equals the nodes.json fixture", () => {
    const inlined = extractArray(html, "NODES") as Array<{ id: string }>;
    expect(inlined.length).toBe(allNodes.length);

    const inlinedById = new Map(inlined.map((n) => [n.id, n]));
    const fixtureById = new Map(allNodes.map((n) => [n.id, n]));

    expect([...inlinedById.keys()].sort()).toEqual([...fixtureById.keys()].sort());

    for (const [id, node] of fixtureById) {
      expect(canon(inlinedById.get(id)), `node "${id}" must match`).toBe(
        canon(node),
      );
    }
  });

  test("inlined GROWTH equals the nodes.json fixture", () => {
    const inlined = extractArray(html, "GROWTH");
    expect(inlined.map(canon).sort()).toEqual(growth.map(canon).sort());
  });
});
