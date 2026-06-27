// figl.6 / ADR-9, ADR-10 — pure transforms for the FigureBundle.
//
// The Figma plugin (`figma-plugin/code.ts` → `exportFigure`) can't run on the
// Mac and can't touch the filesystem, so it returns a RAW bundle: the structural
// tree (serializeNodeDetailed nodes) + a per-node `tokens` array (resolved
// variable bindings) + an `assets[]` array carrying raw payloads (svg strings /
// base64 rasters). Everything in THIS file is pure data-shaping with no figma
// and no I/O, so it is unit-testable on the Mac (see `figure.test.mjs`). The
// only side effect — writing the humanized asset files — is described as a
// `writes[]` plan here and performed by `mcp.js`.

import path from "node:path";

// fs-/url-safe, human-readable slug. "CoinIcon" -> "coinicon"; "Game Board" ->
// "game-board". Never empty (falls back to "node").
export function slugify(s) {
  return String(s == null ? "" : s)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "") || "node";
}

// A stable disambiguator from a node id: "94:2990" -> "94-2990".
export function shortId(nodeId) {
  return String(nodeId == null ? "" : nodeId).replace(/[^A-Za-z0-9]+/g, "-");
}

// Figma colors are 0..1 floats; emit #rrggbb (or #rrggbbaa when alpha < 1).
// `opacity` (the Paint's own opacity) overrides the color's alpha when present.
export function rgbaToHex(color, opacity) {
  if (!color) return undefined;
  const to255 = (x) => Math.max(0, Math.min(255, Math.round((x == null ? 0 : x) * 255)));
  const hx = (v) => v.toString(16).padStart(2, "0");
  const a = opacity != null ? opacity : color.a != null ? color.a : 1;
  const base = `#${hx(to255(color.r))}${hx(to255(color.g))}${hx(to255(color.b))}`;
  return a < 1 ? `${base}${hx(to255(a))}` : base;
}

// Figma variable name "color/card" -> the CSS custom-property "--color-card".
// The consumer's @theme map is keyed by the same names (codemoji-design tokens),
// so this kebab derivation is a DEFAULT the consumer can override — never a guess
// at a utility class (that is why Bundle beat Codegen; see export.design.md).
export function figmaVarToToken(name) {
  return "--" + slugify(String(name == null ? "" : name).replace(/\//g, "-"));
}

// One raw plugin node -> one FigureNode (layout + style + text + token refs).
// Recurses children. Heavy asset bytes are NOT here — a leaf carries `assetRef`
// (-> bundle.assets[].id by node) or, when svg:'inline', an inline `svg` string
// attached by buildFigureBundle.
export function projectFigureNode(raw) {
  if (!raw || typeof raw !== "object") return raw;
  const fn = { id: raw.id, name: raw.name, type: raw.type };

  // --- layout (geometry + auto-layout -> flexbox) ---
  const layout = {};
  if (raw.x != null) layout.x = raw.x;
  if (raw.y != null) layout.y = raw.y;
  if (raw.width != null) layout.w = raw.width;
  if (raw.height != null) layout.h = raw.height;
  if (raw.layoutMode && raw.layoutMode !== "NONE") {
    layout.display = "flex";
    layout.flexDirection = raw.layoutMode === "HORIZONTAL" ? "row" : "column";
    if (raw.itemSpacing != null) layout.gap = raw.itemSpacing;
    // CSS order: [top, right, bottom, left].
    layout.padding = [
      raw.paddingTop || 0,
      raw.paddingRight || 0,
      raw.paddingBottom || 0,
      raw.paddingLeft || 0,
    ];
  }
  if (Object.keys(layout).length) fn.layout = layout;

  // --- tokens: index resolved bindings by their source field ---
  const tok = {};
  for (const b of raw.tokens || []) if (b && !b.error && b.field) tok[b.field] = b;
  // {token, value} when a variable is bound to this field, else {value}.
  const colorRef = (field, value) => {
    const b = tok[field];
    return b ? { token: figmaVarToToken(b.name), var: b.name, value } : { value };
  };

  const fills = Array.isArray(raw.fills) ? raw.fills.filter((f) => f && f.visible !== false) : [];
  const fill0 = fills[0];

  // --- style ---
  const style = {};
  if (fill0 && fill0.type === "SOLID" && raw.type !== "TEXT") {
    style.background = colorRef("fills[0].color", rgbaToHex(fill0.color, fill0.opacity));
  }
  if (raw.cornerRadius != null) {
    style.borderRadius = raw.cornerRadius;
  } else if (raw.topLeftRadius != null) {
    // [tl, tr, br, bl] — CSS border-radius corner order.
    style.borderRadius = [raw.topLeftRadius, raw.topRightRadius, raw.bottomRightRadius, raw.bottomLeftRadius];
  }
  if (raw.opacity != null && raw.opacity < 1) style.opacity = raw.opacity;
  const shadows = (Array.isArray(raw.effects) ? raw.effects : [])
    .filter((e) => e && e.type === "DROP_SHADOW" && e.visible !== false && e.offset)
    .map((e) => `${e.offset.x}px ${e.offset.y}px ${e.radius || 0}px ${rgbaToHex(e.color, e.color && e.color.a)}`);
  if (shadows.length) style.boxShadow = shadows.join(", ");
  if (Object.keys(style).length) fn.style = style;

  // --- text ---
  if (raw.type === "TEXT" && raw.characters != null) {
    const text = { characters: raw.characters };
    if (raw.fontSize != null) text.fontSize = raw.fontSize;
    if (raw.fontName && raw.fontName.style) text.fontStyle = raw.fontName.style;
    if (fill0 && fill0.type === "SOLID") {
      text.color = colorRef("fills[0].color", rgbaToHex(fill0.color, fill0.opacity));
    }
    fn.text = text;
  }

  // --- asset / children ---
  if (raw.assetRef) fn.assetRef = raw.assetRef;
  if (Array.isArray(raw.children)) fn.children = raw.children.map(projectFigureNode);
  return fn;
}

// Turn a RAW plugin bundle into { bundle: FigureBundle, writes: [{path,data,encoding}] }.
// PURE — performs no I/O. mcp.js iterates `writes` to land the humanized assets,
// then returns `bundle`. `svg:'inline'` keeps a vector's markup inline on the node
// (no file, no asset entry) instead of writing it.
export function buildFigureBundle(raw, opts = {}) {
  const svgMode = opts.svg;
  const assetRoot = opts.assetRoot || "";
  const root = raw && raw.root ? raw.root : {};
  const screenSlug = slugify(root.name);
  const dir = path.join(assetRoot, screenSlug);

  const used = new Set();
  const assets = [];
  const writes = [];
  const inline = {}; // node id -> svg string (svg:'inline' only)

  for (const a of (raw && raw.assets) || []) {
    let base = slugify(a.name);
    if (used.has(base)) base = `${base}-${shortId(a.node)}`;
    used.add(base);

    if (a.type === "svg" && svgMode === "inline") {
      inline[a.node] = a.data; // ADR-10 escape hatch: inline replaces the file
      continue;
    }
    const ext = a.type === "svg" ? "svg" : a.type === "jpg" ? "jpg" : "png";
    const full = path.join(dir, `${base}.${ext}`);
    writes.push({ path: full, data: a.data, encoding: a.type === "svg" ? "utf8" : "base64" });
    assets.push({
      id: `${screenSlug}/${base}`,
      node: a.node,
      name: a.name,
      type: a.type,
      path: full,
      scale: a.scale == null ? 1 : a.scale,
      w: a.w,
      h: a.h,
      byteLen: a.byteLen,
    });
  }

  const projectedRoot = projectFigureNode(root);
  if (svgMode === "inline") {
    const attach = (n) => {
      if (n && n.assetRef && inline[n.assetRef] != null) {
        n.svg = inline[n.assetRef];
        delete n.assetRef;
      }
      if (n && Array.isArray(n.children)) n.children.forEach(attach);
    };
    attach(projectedRoot);
  }

  const bundle = {
    root: projectedRoot,
    assets,
    assetRoot: dir,
    truncated: !!root.truncated,
    nodeCount: root.nodeCount,
  };
  return { bundle, writes };
}
