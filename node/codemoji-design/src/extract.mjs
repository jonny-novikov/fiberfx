// @codemoji/design — extraction core.
//
// A Mac-side prototype of the PROPOSED figma-local MCP tools, built on the
// LIVE primitives only. Where the current plugin falls short, the code marks
// the GAP and names the fork that fixes it — those marks roll up into the
// manifest `gaps` list (the MCP improvement backlog).

import { mkdirSync, writeFileSync } from 'fs';
import { join } from 'path';
import * as bridge from './bridge.mjs';

/** Figma 0..1 RGBA -> #rrggbb(aa). */
export function hex(c) {
  if (!c) return null;
  const f = (x) => Math.round(x * 255).toString(16).padStart(2, '0');
  return '#' + f(c.r) + f(c.g) + f(c.b) + (c.a != null && c.a < 1 ? f(c.a) : '');
}

/** filesystem-safe short label. */
export const slug = (s) =>
  (s || '').replace(/[^a-zA-Z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 40) || 'node';

function fillsOf(n) {
  if (!Array.isArray(n.fills)) return undefined;
  return n.fills
    .filter((f) => f && f.visible !== false)
    .map((f) => {
      if (f.type === 'SOLID') return { t: 'SOLID', hex: hex(f.color), op: f.opacity, var: f.boundVariables?.color?.id };
      if (typeof f.type === 'string' && f.type.startsWith('GRADIENT'))
        return { t: f.type, stops: (f.gradientStops || []).map((s) => hex(s.color)) };
      if (f.type === 'IMAGE') return { t: 'IMAGE', hash: f.imageHash, scale: f.scaleMode };
      return { t: f.type };
    });
}

/** Compact, agent-readable summary of one detailed node payload. */
export function summarize(n, depth) {
  const e = { id: n.id, name: n.name, type: n.type, depth, x: n.x, y: n.y, w: n.width, h: n.height, visible: n.visible };
  const fills = fillsOf(n);
  if (fills && fills.length) e.fills = fills;
  if (Array.isArray(n.strokes) && n.strokes.length)
    e.strokes = n.strokes.filter((s) => s.visible !== false).map((s) => ({ t: s.type, hex: s.type === 'SOLID' ? hex(s.color) : undefined, op: s.opacity }));
  if (Array.isArray(n.effects) && n.effects.length)
    e.effects = n.effects.map((x) => ({ t: x.type, radius: x.radius, offset: x.offset, color: hex(x.color) }));
  if (n.type === 'TEXT') e.text = { chars: n.characters, fontSize: n.fontSize, font: n.fontName };
  e.childCount = Array.isArray(n.children) ? n.children.length : 0;
  // GAP (current serializeNodeDetailed omits these): cornerRadius, auto-layout
  // (layoutMode/padding/itemSpacing), absoluteBoundingBox, full TEXT typography
  // (lineHeight/letterSpacing/textAlign/fontWeight). -> Fork 1 / A1 enrichment.
  // GAP: e.fills[].var is a raw VariableID alias, unresolved. -> Fork 4 / D1.
  return e;
}

/**
 * Bounded recursive walk via per-node get-node-properties.
 * This is the Fork 3 / C1 shape done client-side: depth + childCap guard the
 * blast radius. It costs ~1 bridge call per visited node — the inefficiency a
 * native get-node-tree (on exportAsync JSON_REST_V1) would collapse to one call.
 */
export async function boundedWalk(rootId, { depth = 3, childCap = 20, sample = 2 } = {}) {
  const nodes = [];
  const imageAssets = [];
  let calls = 0;
  async function walk(id, d) {
    let n;
    try { n = await bridge.getNode(id); calls++; }
    catch (e) { nodes.push({ id, depth: d, error: String(e.message || e) }); return; }
    const e = summarize(n, d);
    nodes.push(e);
    if (e.fills) for (const f of e.fills) if (f.t === 'IMAGE') imageAssets.push({ id: n.id, name: n.name, hash: f.hash });
    const kids = Array.isArray(n.children) ? n.children : [];
    if (d >= depth) return;
    if (kids.length > childCap) {
      e.note = `capped: ${kids.length} children, sampled ${sample} (repeated set — Fork 4 / D1 dedup)`;
      for (const c of kids.slice(0, sample)) await walk(c.id, d + 1);
    } else {
      for (const c of kids) await walk(c.id, d + 1);
    }
  }
  await walk(bridge.normId(rootId), 0);
  return { nodes, imageAssets, calls };
}

/**
 * Render nodes to PNG, decoding the CURRENT int-array egress Mac-side.
 * The plugin returns { data:[int,...] } (Array.from(bytes)) — ~6-10x the byte
 * size on the wire. We decode here (the Fork 2 / B1 "Mac writes the file" half);
 * the plugin SHOULD send figma.base64Encode(bytes) to cut the wire ~6x. Bytes
 * never enter an agent context — only the file path + size do.
 */
export async function renderNodes(targets, refDir) {
  mkdirSync(refDir, { recursive: true });
  const renders = [];
  for (const t of targets) {
    try {
      const res = await bridge.exportNode(t.id, 'PNG');
      const buf = Buffer.from(res.data); // GAP: int-array egress -> Fork 2 / B1 (base64)
      const file = `${t.id.replace(':', '-')}_${slug(t.name)}.png`;
      writeFileSync(join(refDir, file), buf);
      renders.push({ id: t.id, name: t.name, file, kb: Math.round(buf.length / 1024) });
    } catch (e) {
      renders.push({ id: t.id, name: t.name, error: String(e.message || e) });
    }
  }
  return renders;
}

/** Nodes worth a reference render: visible, not tiny (skips spacers/rails). */
export const renderTargets = (nodes, { maxDepth = 2, minW = 40, minH = 24 } = {}) =>
  nodes.filter((n) => !n.error && n.depth <= maxDepth && n.visible !== false && (n.w || 0) >= minW && (n.h || 0) >= minH)
       .map((n) => ({ id: n.id, name: n.name }));
