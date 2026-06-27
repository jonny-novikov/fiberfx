import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import os from "node:os";
import path from "node:path";
import { mkdirSync, writeFileSync, readdirSync, statSync, unlinkSync } from "node:fs";

const BRIDGE_URL = process.env.FIGMA_BRIDGE_URL || 'http://localhost:3001';
const MAX_RETRIES = 3;
const INITIAL_RETRY_DELAY = 1000;

// Bounded render root (ADR-1). Override with FIGMA_MCP_RENDER_ROOT;
// otherwise renders land in a sub-dir of the OS temp dir. The directory is
// auto-created at startup; cleanup is explicit via the cleanup-renders tool.
const RENDER_ROOT = process.env.FIGMA_MCP_RENDER_ROOT || path.join(os.tmpdir(), 'figma-mcp-renders');
mkdirSync(RENDER_ROOT, { recursive: true });

// Plugin-backed tools (ADR-5). Compared against /health backedActions in
// check-bridge-status; a mismatch is WARN, never a hard fail.
const ADVERTISED_ACTIONS = [
  'get-current-page',
  'get-selection',
  'get-all-pages',
  'find-nodes',
  'get-node-properties',
  'export-node',
  'get-batch-nodes',
  'resolve-variables',
];

const server = new McpServer({
  name: "figma-local-mcp",
  version: "2.0.0",
});

async function callBridge(endpoint, options = {}, retries = MAX_RETRIES) {
  let lastError;

  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const response = await fetch(`${BRIDGE_URL}${endpoint}`, options);
      const data = await response.json();

      if (!response.ok) {
        const errorMsg = data.error || 'Bridge request failed';

        if (response.status === 503) {
          throw new Error(`Bridge Error: ${errorMsg}. Make sure the Figma plugin is connected and the bridge server is running (pnpm bridge).`);
        } else if (response.status === 404) {
          throw new Error(`Bridge Error: ${errorMsg}. The requested endpoint was not found.`);
        } else {
          throw new Error(`Bridge Error: ${errorMsg}`);
        }
      }

      return data;
    } catch (error) {
      lastError = error;

      if (error.message.includes('404') || error.message.includes('plugin is connected')) {
        throw error;
      }

      if (attempt < retries) {
        const delay = INITIAL_RETRY_DELAY * Math.pow(2, attempt);
        console.error(`Attempt ${attempt + 1} failed. Retrying in ${delay}ms...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }

  throw new Error(`Failed after ${retries + 1} attempts. Last error: ${lastError.message}`);
}

function normalizeNodeId(input) {
  if (!input) return input;
  const trimmed = input.trim();

  if (/^\d+-\d+$/.test(trimmed)) {
    return trimmed.replace('-', ':');
  }

  return trimmed;
}

// "1h" / "30m" / "24h" / "7d" / "60s" / "500ms" or a bare integer (ms).
function parseDurationMs(input) {
  if (typeof input === 'number') return input;
  if (typeof input !== 'string') throw new Error(`keepSince must be a string like "1h" or a number of ms`);
  const m = input.trim().match(/^(\d+(?:\.\d+)?)\s*(ms|s|m|h|d)?$/i);
  if (!m) throw new Error(`keepSince: unrecognized duration "${input}" (expected "1h", "30m", "24h", "7d", "60s", "500ms")`);
  const n = parseFloat(m[1]);
  const unit = (m[2] || 'ms').toLowerCase();
  const mult = { ms: 1, s: 1000, m: 60_000, h: 3_600_000, d: 86_400_000 }[unit];
  return n * mult;
}

// fs-safe filename: nodeId ":" -> "_"; ISO timestamp; lowercase ext.
function renderFilename(nodeId, format) {
  const safe = String(nodeId || 'node').replace(/[^A-Za-z0-9_-]+/g, '_');
  const ts = new Date().toISOString().replace(/[:.]/g, '-');
  return `${safe}_${ts}.${String(format || 'png').toLowerCase()}`;
}

async function requestFigma(action, params) {
  const data = await callBridge('/request', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ action, params })
  });
  return data.result;
}

server.registerTool(
  "get-figma-document",
  {
    title: "Get Figma Document",
    description: "Gets the current Figma document structure including all pages and top-level frames. Works entirely locally through the Figma plugin - no API key required.",
  },
  async () => {
    const doc = await callBridge('/document');
    return { content: [{ type: "text", text: JSON.stringify(doc, null, 2) }] };
  }
);

server.registerTool(
  "get-current-page",
  {
    title: "Get Current Page",
    description: "Gets detailed information about the currently active page in Figma. Works entirely locally - no API key required.",
  },
  async () => {
    const result = await requestFigma('get-current-page');
    return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
  }
);

server.registerTool(
  "get-selection",
  {
    title: "Get Selected Nodes",
    description: "Gets the currently selected nodes in Figma with their properties. Works entirely locally - no API key required.",
  },
  async () => {
    const result = await requestFigma('get-selection');
    return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
  }
);

server.registerTool(
  "get-all-pages",
  {
    title: "Get All Pages",
    description: "Gets a list of all pages in the current Figma document. Works entirely locally - no API key required.",
  },
  async () => {
    const result = await requestFigma('get-all-pages');
    return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
  }
);

server.registerTool(
  "find-nodes",
  {
    title: "Find Nodes",
    description: "Searches for nodes by name in the current page. Works entirely locally - no API key required.",
    inputSchema: {
      query: z.string()
    },
  },
  async ({ query }) => {
    const result = await requestFigma('find-nodes', { query });
    return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
  }
);

server.registerTool(
  "get-node-properties",
  {
    title: "Get Node Properties",
    description: "Gets detailed properties of a node by its ID. Omit nodeId to fall back to the current page's single selected node (multi-selection is an error). Pass depth>=0 to expand children recursively in one call (depth=0 = just this node + lite child stubs, depth=1 = one level deep with detailed children, etc.). maxNodes caps the total detailed serializations (default 500) — when the cap is hit, the response carries truncated:true and nodeCount. Omit depth to get the byte-identical single-node shape (no truncated/nodeCount fields).",
    inputSchema: {
      nodeId: z.string().optional(),
      depth: z.number().int().nonnegative().optional(),
      maxNodes: z.number().int().positive().optional(),
    },
  },
  async ({ nodeId, depth, maxNodes }) => {
    const normalizedNodeId = nodeId ? normalizeNodeId(nodeId) : undefined;
    const result = await requestFigma('get-node-properties', { nodeId: normalizedNodeId, depth, maxNodes });
    return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
  }
);

server.registerTool(
  "export-node",
  {
    title: "Export Node as Image",
    description: "Exports a node as an image in PNG, SVG, or JPG format. Writes the bytes to a bounded Mac temp path and returns {path, scale, w, h, byteLen} — the bytes never enter the tool result. Pass scale=2 for a Retina @2x raster (PNG/JPG only; SVG is vector and ignores it); defaults to 1×. Omit nodeId to fall back to the current page's single selected node.",
    inputSchema: {
      nodeId: z.string().optional(),
      format: z.enum(['PNG', 'SVG', 'JPG']).optional(),
      scale: z.number().positive().optional() // 2 = Retina @2x (PNG/JPG); default 1×
    },
  },
  async ({ nodeId, format, scale }) => {
    const resolvedFormat = (format || 'PNG').toUpperCase();
    const resolvedScale = scale ?? 1;
    const normalizedNodeId = nodeId ? normalizeNodeId(nodeId) : undefined;
    const result = await requestFigma('export-node', { nodeId: normalizedNodeId, format: resolvedFormat, scale: resolvedScale });
    const buf = Buffer.from(result.data, 'base64');
    const file = renderFilename(result.nodeId || normalizedNodeId, resolvedFormat);
    const fullPath = path.join(RENDER_ROOT, file);
    writeFileSync(fullPath, buf);
    const out = {
      path: fullPath,
      nodeId: result.nodeId,
      format: resolvedFormat,
      scale: result.scale ?? resolvedScale, // what the plugin honored (1 if it's an un-reloaded plugin)
      w: result.w, // 1× design dims; the raster on disk is scale× larger
      h: result.h,
      byteLen: result.byteLen ?? buf.length,
    };
    return { content: [{ type: "text", text: JSON.stringify(out, null, 2) }] };
  }
);

server.registerTool(
  "get-batch-nodes",
  {
    title: "Get Batch Node Properties",
    description: "Gets detailed properties for multiple nodes in one bridge round-trip — much faster than calling get-node-properties N times. Missing-node failures are recorded per-id (the batch does not fail on the first miss). Each entry uses the same shape as get-node-properties.",
    inputSchema: {
      nodeIds: z.array(z.string())
    },
  },
  async ({ nodeIds }) => {
    const normalizedNodeIds = nodeIds.map(normalizeNodeId);
    const result = await requestFigma('get-batch-nodes', { nodeIds: normalizedNodeIds });
    return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
  }
);

server.registerTool(
  "resolve-variables",
  {
    title: "Resolve Bound Variables",
    description: "Walks a node's variable bindings (node-level boundVariables AND per-paint bindings on fills/strokes/effects/layoutGrids) and resolves each VARIABLE_ALIAS via Variable.resolveForConsumer (the one capability the Mac client physically cannot supply — valuesByMode does not follow aliases). Returns {nodeId, bindings:[{field, variableId, name, value, resolvedType}|{...error}], count}. Per-binding errors do not fail the whole call. Omit nodeId to fall back to the current page's single selected node.",
    inputSchema: {
      nodeId: z.string().optional(),
    },
  },
  async ({ nodeId }) => {
    const normalizedNodeId = nodeId ? normalizeNodeId(nodeId) : undefined;
    const result = await requestFigma('resolve-variables', { nodeId: normalizedNodeId });
    return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
  }
);

server.registerTool(
  "check-bridge-status",
  {
    title: "Check Bridge Status",
    description: "Checks if the Figma bridge server is running, if a Figma plugin is connected, and whether every advertised plugin-backed tool is actually backed by the deployed plugin (advertised ⊆ backed). A mismatch is reported as a warning, never an error.",
  },
  async () => {
    const health = await callBridge('/health');
    const backed = Array.isArray(health.backedActions) ? health.backedActions : null;
    const missing = backed ? ADVERTISED_ACTIONS.filter(a => !backed.includes(a)) : [];
    const extra = backed ? backed.filter(a => !ADVERTISED_ACTIONS.includes(a)) : [];
    const handshake = backed === null
      ? { status: 'unknown', note: 'plugin has not reported a backed-actions list (older plugin? disconnected?)' }
      : missing.length === 0
        ? { status: 'ok', note: 'advertised ⊆ backed' }
        : { status: 'warn', note: `${missing.length} advertised tool(s) NOT backed by the deployed plugin: ${missing.join(', ')}` };
    const out = {
      ...health,
      advertised: ADVERTISED_ACTIONS,
      handshake,
      extra, // actions the plugin backs but mcp.js does not yet advertise (forward-compat)
      renderRoot: RENDER_ROOT,
    };
    return { content: [{ type: "text", text: JSON.stringify(out, null, 2) }] };
  }
);

server.registerTool(
  "cleanup-renders",
  {
    title: "Cleanup Render Files",
    description: "Deletes files in the bounded render root. Provide keepLast (keep the N most recent) and/or keepSince (keep files newer than this duration — e.g. '1h', '30m', '24h', '7d', or a bare number of ms). A file is kept if it satisfies EITHER rule; everything else is deleted. dryRun=true lists what would be deleted without acting. At least one of keepLast / keepSince is required.",
    inputSchema: {
      keepLast: z.number().int().nonnegative().optional(),
      keepSince: z.union([z.string(), z.number()]).optional(),
      dryRun: z.boolean().optional(),
    },
  },
  async ({ keepLast, keepSince, dryRun }) => {
    if (keepLast === undefined && keepSince === undefined) {
      throw new Error("cleanup-renders: must provide keepLast or keepSince (or both).");
    }
    const sinceMs = keepSince === undefined ? null : parseDurationMs(keepSince);
    const cutoff = sinceMs === null ? null : Date.now() - sinceMs;

    const entries = readdirSync(RENDER_ROOT, { withFileTypes: true })
      .filter(d => d.isFile())
      .map(d => {
        const full = path.join(RENDER_ROOT, d.name);
        const st = statSync(full);
        return { name: d.name, path: full, mtimeMs: st.mtimeMs, size: st.size };
      })
      .sort((a, b) => b.mtimeMs - a.mtimeMs); // newest first

    const keptIdx = new Set();
    if (keepLast !== undefined) {
      for (let i = 0; i < Math.min(keepLast, entries.length); i++) keptIdx.add(i);
    }
    if (cutoff !== null) {
      for (let i = 0; i < entries.length; i++) if (entries[i].mtimeMs >= cutoff) keptIdx.add(i);
    }

    const kept = [];
    const deleted = [];
    for (let i = 0; i < entries.length; i++) {
      const e = entries[i];
      if (keptIdx.has(i)) {
        kept.push({ path: e.path, mtimeMs: e.mtimeMs, size: e.size });
      } else {
        if (!dryRun) unlinkSync(e.path);
        deleted.push({ path: e.path, mtimeMs: e.mtimeMs, size: e.size });
      }
    }

    const out = {
      root: RENDER_ROOT,
      dryRun: dryRun === true,
      rules: { keepLast: keepLast ?? null, keepSince: keepSince ?? null },
      totalKept: kept.length,
      totalDeleted: deleted.length,
      kept,
      deleted,
    };
    return { content: [{ type: "text", text: JSON.stringify(out, null, 2) }] };
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
