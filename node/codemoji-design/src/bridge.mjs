// @codemoji/design — Figma-local bridge client.
//
// Talks straight to the figma-local bridge HTTP API (the same endpoint the
// figma-local MCP proxies, default the Windows Figma machine on the LAN).
// Image bytes flow bridge -> here -> disk, never through an agent's context —
// this is the Mac-side egress the toolkit prototypes (Fork 2 / B1).
//
// ACTION SURFACE — the live Windows plugin backs only the LIVE set today.
// The DEAD + PROPOSED rows are the figma-local MCP improvement backlog this
// toolkit exists to motivate (see README.md and the manifest `gaps` list):
//   LIVE     get-current-page · get-selection · get-all-pages ·
//            find-nodes(query) · get-node-properties(nodeId) · export-node(nodeId,format)
//   DEAD     get-batch-nodes · export-batch-nodes
//            (registered in mcp.js, NO handler in figma-plugin/code.ts -> "Unknown action")
//   PROPOSED get-node-tree (JSON_REST_V1 + depth/fields/maxNodes projection) ·
//            export-to-file (figma.base64Encode + Mac write) ·
//            resolve-variables (Variable.resolveForConsumer — plugin-only) ·
//            get-component-instances (getMainComponentAsync + overrides dedup)

export const BRIDGE_URL = process.env.FIGMA_BRIDGE_URL || 'http://192.168.3.120:3001';

export const ACTION_SURFACE = {
  live: ['get-current-page', 'get-selection', 'get-all-pages', 'find-nodes', 'get-node-properties', 'export-node'],
  dead: ['get-batch-nodes', 'export-batch-nodes'],
  proposed: ['get-node-tree', 'export-to-file', 'resolve-variables', 'get-component-instances'],
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
