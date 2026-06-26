// @codemoji/design — Figma-local bridge client.
//
// Talks straight to the figma-local bridge HTTP API (the same endpoint the
// figma-local MCP proxies, default the Windows Figma machine on the LAN).
// Image bytes flow bridge -> here -> disk, never through an agent's context —
// this is the Mac-side egress the toolkit prototypes (Fork 2 / B1).
//
// ACTION SURFACE — what the deployed plugin backs today (post-figl.2):
//   LIVE     get-current-page · get-selection · get-all-pages ·
//            find-nodes(query) · get-node-properties(nodeId?) · export-node(nodeId?,format)
//            (nodeId is OPTIONAL on get-node-properties / export-node; omit it
//            to fall back to the current page's single selected node.)
//            export-node now returns { nodeId, format, data: base64, w, h, byteLen }
//            (Fork 2 / B1 / ADR-1 — base64 wire, decoded Mac-side).
//   PROPOSED get-node-tree (JSON_REST_V1 + depth/fields/maxNodes projection) ·
//            resolve-variables (Variable.resolveForConsumer — plugin-only, figl.5) ·
//            get-component-instances (getMainComponentAsync + overrides dedup, S-2)
// The figl.1 cleanup dropped the DEAD row (get-batch-nodes / export-batch-nodes
// are gone; get-batch-nodes is re-implemented in figl.3, export-batch-nodes is
// superseded by file-based egress, ADR-1).

export const BRIDGE_URL = process.env.FIGMA_BRIDGE_URL || 'http://192.168.3.120:3001';

export const ACTION_SURFACE = {
  live: ['get-current-page', 'get-selection', 'get-all-pages', 'find-nodes', 'get-node-properties', 'export-node'],
  proposed: ['get-node-tree', 'resolve-variables', 'get-component-instances'],
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
export const exportNode = (nodeId, format = 'PNG') => request('export-node', { nodeId: normId(nodeId), format });
export const findNodes = (query) => request('find-nodes', { query });

/** "94-2974" -> "94:2974" (mirrors mcp.js normalizeNodeId). */
export function normId(id) {
  const t = (id || '').trim();
  return /^\d+-\d+$/.test(t) ? t.replace('-', ':') : t;
}
