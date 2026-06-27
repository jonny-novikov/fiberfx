// figl.6 — Mac-side regression test for the FigureBundle projection (figure.js).
// The plugin can't run on the Mac, so this proves every pure transform that
// shapes the bundle: RGBA→hex, fills→background, auto-layout→flex, drop-shadow,
// token references, humanized asset naming, the ADR-1 by-reference egress, the
// svg:'inline' escape hatch, and slug collisions. Run: `node figure.test.mjs`.

import assert from "node:assert/strict";
import { slugify, shortId, rgbaToHex, figmaVarToToken, projectFigureNode, buildFigureBundle } from "./figure.js";

let passed = 0;
const check = (name, fn) => { fn(); passed++; console.log(`  ok  ${name}`); };

// --- unit: the leaf helpers ---
check("slugify humanizes + collapses", () => {
  assert.equal(slugify("CoinIcon"), "coinicon");
  assert.equal(slugify("Game Board"), "game-board");
  assert.equal(slugify("  weird__Name!! "), "weird-name");
  assert.equal(slugify(""), "node");
});
check("shortId from node id", () => assert.equal(shortId("94:2990"), "94-2990"));
check("rgbaToHex 0..1 floats → #1a1a2e", () => {
  assert.equal(rgbaToHex({ r: 26 / 255, g: 26 / 255, b: 46 / 255 }), "#1a1a2e");
  assert.equal(rgbaToHex({ r: 1, g: 1, b: 1 }, 0.5), "#ffffff80"); // alpha → #rrggbbaa
});
check("figmaVarToToken kebabs the path", () => {
  assert.equal(figmaVarToToken("color/card"), "--color-card");
  assert.equal(figmaVarToToken("text/muted"), "--text-muted");
});

// --- a representative RAW bundle (what the plugin returns) ---
const rawBundle = () => ({
  root: {
    id: "94:2974", name: "StatusBar", type: "FRAME",
    x: 0, y: 0, width: 374, height: 32,
    layoutMode: "HORIZONTAL", itemSpacing: 8,
    paddingTop: 0, paddingRight: 16, paddingBottom: 0, paddingLeft: 16,
    cornerRadius: 16, opacity: 0.9,
    fills: [{ type: "SOLID", color: { r: 26 / 255, g: 26 / 255, b: 46 / 255 } }],
    effects: [{ type: "DROP_SHADOW", visible: true, radius: 12, offset: { x: 0, y: 4 }, color: { r: 0, g: 0, b: 0, a: 0.2 } }],
    tokens: [{ field: "fills[0].color", name: "color/card", value: {}, resolvedType: "COLOR" }],
    children: [
      { id: "94:2980", name: "Balance", type: "TEXT", characters: "1,240", fontSize: 10,
        fontName: { family: "Inter", style: "Semi Bold" },
        fills: [{ type: "SOLID", color: { r: 154 / 255, g: 160 / 255, b: 181 / 255 } }],
        tokens: [{ field: "fills[0].color", name: "text/muted", value: {}, resolvedType: "COLOR" }] },
      // a pure-vector subtree → one .svg asset, no children in the bundle
      { id: "94:2990", name: "CoinIcon", type: "GROUP", assetRef: "94:2990",
        fills: [], tokens: [] },
      // an image leaf → a .png asset
      { id: "94:2991", name: "Avatar", type: "RECTANGLE", assetRef: "94:2991",
        fills: [{ type: "IMAGE", scaleMode: "FILL" }], tokens: [] },
      // a second vector named "Icon" — collision with... (added below)
    ],
    nodeCount: 5,
  },
  assets: [
    { node: "94:2990", name: "CoinIcon", type: "svg", data: "<svg viewBox=\"0 0 24 24\"><path d=\"M1 1\"/></svg>", w: 24, h: 24, byteLen: 48 },
    { node: "94:2991", name: "Avatar", type: "png", data: "QUJDRA==", scale: 2, w: 48, h: 48, byteLen: 4 },
  ],
});

// --- projection: layout / style / text / tokens ---
check("auto-layout → flexbox", () => {
  const fn = projectFigureNode(rawBundle().root);
  assert.deepEqual(fn.layout, { x: 0, y: 0, w: 374, h: 32, display: "flex", flexDirection: "row", gap: 8, padding: [0, 16, 0, 16] });
});
check("SOLID fill + bound variable → style.background {token,value}", () => {
  const fn = projectFigureNode(rawBundle().root);
  assert.deepEqual(fn.style.background, { token: "--color-card", var: "color/card", value: "#1a1a2e" });
  assert.equal(fn.style.borderRadius, 16);
  assert.equal(fn.style.opacity, 0.9);
  assert.equal(fn.style.boxShadow, "0px 4px 12px #00000033");
});
check("TEXT → text {characters,fontSize,fontStyle,color}", () => {
  const fn = projectFigureNode(rawBundle().root);
  const t = fn.children[0];
  assert.equal(t.type, "TEXT");
  assert.deepEqual(t.text, { characters: "1,240", fontSize: 10, fontStyle: "Semi Bold", color: { token: "--text-muted", var: "text/muted", value: "#9aa0b5" } });
  assert.equal(t.style, undefined); // TEXT fill is the color, not a background
});

// --- bundle: humanized egress, by-reference, write plan ---
check("assets humanized + by-reference; bundle carries NO bytes", () => {
  const { bundle, writes } = buildFigureBundle(rawBundle(), { assetRoot: "/tmp/assets" });
  assert.equal(bundle.assetRoot, "/tmp/assets/statusbar");
  assert.equal(bundle.assets.length, 2);
  const svg = bundle.assets.find((a) => a.type === "svg");
  assert.deepEqual(svg, { id: "statusbar/coinicon", node: "94:2990", name: "CoinIcon", type: "svg", path: "/tmp/assets/statusbar/coinicon.svg", scale: 1, w: 24, h: 24, byteLen: 48 });
  const png = bundle.assets.find((a) => a.type === "png");
  assert.equal(png.path, "/tmp/assets/statusbar/avatar.png");
  assert.equal(png.scale, 2);
  // the leaves reference assets; they carry no inline data
  assert.equal(bundle.root.children[1].assetRef, "94:2990");
  assert.equal(bundle.root.children[1].svg, undefined);
  // ADR-1: not one byte of asset payload leaked into the returned bundle
  const json = JSON.stringify(bundle);
  assert.ok(!json.includes("<svg"), "svg markup must NOT be in the bundle (file mode)");
  assert.ok(!json.includes("QUJDRA"), "base64 raster must NOT be in the bundle");
  // the write plan carries the bytes instead
  assert.equal(writes.length, 2);
  assert.deepEqual(writes.find((w) => w.path.endsWith(".svg")), { path: "/tmp/assets/statusbar/coinicon.svg", data: "<svg viewBox=\"0 0 24 24\"><path d=\"M1 1\"/></svg>", encoding: "utf8" });
  assert.equal(writes.find((w) => w.path.endsWith(".png")).encoding, "base64");
});
check("svg:'inline' keeps markup on the node, drops the file + asset", () => {
  const { bundle, writes } = buildFigureBundle(rawBundle(), { assetRoot: "/tmp/assets", svg: "inline" });
  assert.equal(bundle.assets.length, 1); // only the png remains an asset
  assert.equal(writes.length, 1); // only the png is written
  assert.equal(bundle.root.children[1].svg, "<svg viewBox=\"0 0 24 24\"><path d=\"M1 1\"/></svg>");
  assert.equal(bundle.root.children[1].assetRef, undefined);
});
check("slug collision disambiguates with the node id", () => {
  const raw = rawBundle();
  raw.assets = [
    { node: "94:1", name: "Icon", type: "svg", data: "<svg/>", w: 1, h: 1, byteLen: 6 },
    { node: "94:2", name: "Icon", type: "svg", data: "<svg/>", w: 1, h: 1, byteLen: 6 },
  ];
  const { bundle } = buildFigureBundle(raw, { assetRoot: "/tmp/assets" });
  assert.equal(bundle.assets[0].id, "statusbar/icon");
  assert.equal(bundle.assets[1].id, "statusbar/icon-94-2");
});
check("truncated/nodeCount lift to the bundle", () => {
  const raw = rawBundle();
  raw.root.truncated = true;
  const { bundle } = buildFigureBundle(raw, { assetRoot: "/tmp/assets" });
  assert.equal(bundle.truncated, true);
  assert.equal(bundle.nodeCount, 5);
});

console.log(`\nFIGURE PROJECTION: ${passed} checks passed.`);
