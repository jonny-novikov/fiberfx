// @codemoji/design — Figma-local bridge client.
//
// Talks straight to the figma-local bridge HTTP API (the same endpoint the
// figma-local MCP proxies, default the Windows Figma machine on the LAN).
// Image bytes flow bridge -> here -> disk, never through an agent's context —
// this is the Mac-side egress the toolkit prototypes (Fork 2 / B1).
//
// ACTION SURFACE — what the deployed plugin backs today (post-figl.5):
//   LIVE     get-current-page · get-selection · get-all-pages ·
//            find-nodes(query) ·
//            get-node-properties(nodeId?, depth?, maxNodes?) ·
//            export-node(nodeId?, format, scale=1) ·
//            get-batch-nodes(nodeIds[]) ·
//            resolve-variables(nodeId?)
//            - nodeId is OPTIONAL on get-node-properties / export-node / resolve-variables —
//              omit it to fall back to the current page's single selected node.
//            - export-node returns { nodeId, format, scale, data: base64, w, h, byteLen }
//              (Fork 2 / B1 / ADR-1 — base64 wire, decoded Mac-side). w/h are the
//              1× design dims; pass scale=2 for a Retina @2x raster (PNG/JPG only).
//            - serializeNodeDetailed carries cornerRadius (+ per-corner,
//              figma.mixed-guarded), auto-layout fields (only when layoutMode !== 'NONE'),
//              and absoluteBoundingBox (ADR-3).
//            - get-batch-nodes collapses N round-trips into 1; missing nodes
//              come back as per-id { id, error } entries, not a batch failure (ADR-3).
//            - get-node-properties(depth) collapses an N-call boundedWalk into one
//              recursive call over the SAME serializeNodeDetailed (ADR-2 / C2);
//              depth absent ≡ today's single-node shape EXACTLY, maxNodes caps
//              the walk (default 500) — when hit, root carries truncated:true.
//            - resolve-variables walks node-level boundVariables AND per-paint
//              bindings on fills/strokes/effects/layoutGrids, returns
//              {nodeId, bindings:[{field, variableId, name, value, resolvedType}|{...error}], count}
//              — the one capability the Mac client cannot supply
//              (valuesByMode "will not resolve any aliases", plugin-typings :11441;
//              only Variable.resolveForConsumer, :11432, walks the chain) (ADR-4).
//            - All node lookups are async (figma.getNodeByIdAsync) — defensive
//              against any future documentAccess:dynamic-page adoption (ADR-8).
//   PROPOSED get-node-tree (JSON_REST_V1 + fields projection, S-2 sibling) ·
//            get-component-instances (getMainComponentAsync + overrides dedup, S-2)

export const BRIDGE_URL = process.env.FIGMA_BRIDGE_URL || 'http://192.168.1.120:3001';

export const ACTION_SURFACE = {
  live: ['get-current-page', 'get-selection', 'get-all-pages', 'find-nodes', 'get-node-properties', 'export-node', 'get-batch-nodes', 'resolve-variables'],
  proposed: ['get-node-tree', 'get-component-instances'],
};

/** GET /health -> { status, connected, hasDocument } */
export async function health() {
  const r = await fetch(`${BRIDGE_URL}/health`);
  if (!r.ok) throw new Error(`bridge /health HTTP ${r.status}`);
  return r.json();
}

/** POST /request { action, params } -> result (throws on bridge/plugin error). */
export async function request(action, params = {}) {
  const r = await fetch(`${BRIDGE_URL}/request`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ action, params }),
  });
  let j;
  try { j = await r.json(); } catch { throw new Error(`bridge ${action}: non-JSON response (HTTP ${r.status})`); }
  if (!r.ok) throw new Error(j.error || `bridge ${action}: HTTP ${r.status}`);
  return j.result;
}

// Thin wrappers over the LIVE actions.
export const getSelection = () => request('get-selection');
export const getCurrentPage = () => request('get-current-page');
export const getNode = (nodeId) => request('get-node-properties', { nodeId: normId(nodeId) });
// scale=2 requests a Retina @2x raster (PNG/JPG only — SVG ignores it plugin-side).
// Defaults to 1 so existing callers are unchanged; the plugin must be reloaded for
// scale>1 to actually take effect (older deployed plugins ignore the param → 1×).
export const exportNode = (nodeId, format = 'PNG', scale = 1) => request('export-node', { nodeId: normId(nodeId), format, scale });
export const findNodes = (query) => request('find-nodes', { query });
export const resolveVariables = (nodeId) => request('resolve-variables', { nodeId: normId(nodeId) });

/** "94-2974" -> "94:2974" (mirrors mcp.js normalizeNodeId). */
export function normId(id) {
  const t = (id || '').trim();
  return /^\d+-\d+$/.test(t) ? t.replace('-', ':') : t;
}
