const BRIDGE_URL = 'ws://localhost:3000';
let ws: WebSocket | null = null;

// Single source of truth for the capability handshake (ADR-5).
// Order matches the switch below; both must move together when an action is added.
const BACKED_ACTIONS = [
  'get-current-page',
  'get-selection',
  'get-all-pages',
  'find-nodes',
  'get-node-properties',
  'export-node',
  'get-batch-nodes',
  'resolve-variables',
  'export-figure',
] as const;

function connectToBridge() {
  figma.ui.postMessage({ type: 'connect', url: BRIDGE_URL });
}

figma.ui.onmessage = async (msg) => {
  if (msg.type === 'ws-connected') {
    console.log('Connected to bridge server');
    sendBackedActions();
    await sendDocumentUpdate();
  }

  if (msg.type === 'ws-request') {
    const { requestId, action, params } = msg.data;

    try {
      let result;

      switch (action) {
        case 'get-current-page':
          result = await getCurrentPage();
          break;
        case 'get-selection':
          result = await getSelection();
          break;
        case 'get-all-pages':
          result = await getAllPages();
          break;
        case 'find-nodes':
          result = await findNodes(params.query);
          break;
        case 'get-node-properties':
          result = await getNodeProperties(params.nodeId, params.depth, params.maxNodes);
          break;
        case 'export-node':
          // scale forwarded for Retina @2x (PNG/JPG only); defaults to 1× in exportNode.
          result = await exportNode(params.nodeId, params.format, params.scale);
          break;
        case 'get-batch-nodes':
          result = await getBatchNodes(params.nodeIds);
          break;
        case 'resolve-variables':
          result = await resolveVariables(params.nodeId);
          break;
        case 'export-figure':
          // figl.6 — the FigureBundle RAW gather (structure + tokens + per-asset
          // export). mcp.js does the pure-data projection + humanized disk egress.
          result = await exportFigure(params.nodeId, params.depth, params.scale, params.maxNodes);
          break;
        default:
          throw new Error(`Unknown action: ${action}`);
      }

      figma.ui.postMessage({
        type: 'ws-response',
        requestId,
        result
      });
    } catch (error) {
      figma.ui.postMessage({
        type: 'ws-response',
        requestId,
        error: error instanceof Error ? error.message : String(error)
      });
    }
  }
};

async function sendDocumentUpdate() {
  const data = {
    type: 'document-update',
    document: {
      name: figma.root.name,
      pages: figma.root.children.map(serializePage),
      selection: figma.currentPage.selection.map(node => ({
        id: node.id,
        name: node.name,
        type: node.type
      }))
    }
  };

  figma.ui.postMessage({ type: 'ws-send', data });
}

function sendBackedActions() {
  figma.ui.postMessage({
    type: 'ws-send',
    data: { type: 'backed-actions', actions: BACKED_ACTIONS },
  });
}

// Selection fallback (ADR-5): a tool called with no nodeId resolves to the
// current page's single selected node. Multi-selection is an explicit error —
// the caller must address one node at a time when they care which one.
function resolveNodeId(nodeId?: string): string {
  if (nodeId) return nodeId;
  const sel = figma.currentPage.selection;
  if (sel.length === 1) return sel[0].id;
  if (sel.length === 0) throw new Error('No nodeId given and the current page has no selection.');
  throw new Error(`No nodeId given and the current selection has ${sel.length} nodes (expected exactly 1).`);
}

function serializePage(page: PageNode) {
  return {
    id: page.id,
    name: page.name,
    type: page.type,
    children: page.children.map(child => ({
      id: child.id,
      name: child.name,
      type: child.type
    }))
  };
}

async function getCurrentPage() {
  return {
    id: figma.currentPage.id,
    name: figma.currentPage.name,
    type: figma.currentPage.type,
    children: figma.currentPage.children.map(node => serializeNode(node))
  };
}

async function getSelection() {
  return figma.currentPage.selection.map(node => serializeNode(node));
}

async function getAllPages() {
  return figma.root.children.map(serializePage);
}

async function findNodes(query: string) {
  const results: SceneNode[] = [];

  function search(node: BaseNode) {
    if ('name' in node && node.name.toLowerCase().includes(query.toLowerCase())) {
      results.push(node as SceneNode);
    }
    if ('children' in node) {
      for (const child of node.children) {
        search(child);
      }
    }
  }

  search(figma.currentPage);
  return results.map(node => serializeNode(node));
}

// Default maxNodes when depth is given without an explicit cap. Sized to fit a
// CODEMOJIES-scale screen (77 nodes) several times over while keeping the walk
// well under the ~30s bridge timeout (`bridge-server.js:148`).
const DEFAULT_MAX_NODES = 500;

async function getNodeProperties(nodeId?: string, depth?: number, maxNodes?: number) {
  const id = resolveNodeId(nodeId);
  // ADR-8: async swap. Sync getNodeById works under legacy mode but throws
  // under documentAccess:dynamic-page (typings :423); the async form is
  // behavior-preserving today and defensive against future adoption.
  const node = await figma.getNodeByIdAsync(id);
  if (!node) {
    throw new Error(`Node not found: ${id}`);
  }
  // ADR-2: depth absent ≡ today's single-node shape, EXACTLY. The recursive
  // path is opt-in; the default response is byte-identical to pre-figl.4.
  if (depth === undefined) {
    return serializeNodeDetailed(node);
  }
  return serializeSubtree(node, depth, maxNodes ?? DEFAULT_MAX_NODES);
}

// Bounded recursive walk over the SAME serializeNodeDetailed (ADR-2 / C2 — one
// node shape, deeper). depth=0 is "just this node, no children expanded";
// depth=N expands N levels. maxNodes caps the total detailed serializations so
// a deep tree truncates rather than blowing the 30s bridge timeout — when the
// cap is hit, the walk stops and the root carries truncated:true + nodeCount.
function serializeSubtree(root: BaseNode, depth: number, maxNodes: number) {
  let count = 0;
  let truncated = false;

  function walk(node: BaseNode, d: number): any {
    count++;
    const data = serializeNodeDetailed(node);
    if (d <= 0) return data;
    if (!('children' in node) || !Array.isArray((node as any).children)) return data;
    const kids = (node as any).children as BaseNode[];
    const richKids: any[] = [];
    for (const c of kids) {
      if (count >= maxNodes) { truncated = true; break; }
      richKids.push(walk(c, d - 1));
    }
    data.children = richKids; // replaces the lite {id,name,type} stub from serializeNode
    return data;
  }

  const result = walk(root, depth);
  result.nodeCount = count;
  if (truncated) result.truncated = true;
  return result;
}

async function exportNode(nodeId?: string, format: 'PNG' | 'SVG' | 'JPG' = 'PNG', scale: number = 1) {
  const id = resolveNodeId(nodeId);
  // ADR-8: async swap (see getNodeProperties comment).
  const node = (await figma.getNodeByIdAsync(id)) as SceneNode;
  if (!node) {
    throw new Error(`Node not found: ${id}`);
  }

  // Retina @2x: a SCALE constraint multiplies the raster output (e.g. scale:2
  // doubles each dimension). PNG/JPG only — SVG is vector, so scale is a no-op
  // there and Figma rejects the constraint on SVG. scale defaults to 1, so every
  // existing 1× caller is byte-for-byte unchanged. Two calls (not one settings
  // object) so control-flow narrows `format` to 'PNG'|'JPG' for the typed
  // ExportSettingsImage overload that carries `constraint`.
  const s = Number(scale) || 1;
  const bytes = (format === 'SVG' || s === 1)
    ? await node.exportAsync({ format })
    : await node.exportAsync({ format, constraint: { type: 'SCALE', value: s } });
  // node.width/height are the 1× design dimensions; the actual raster is scale×
  // larger. Report both so callers can name files / verify @2x.
  const w = 'width' in node ? node.width : undefined;
  const h = 'height' in node ? node.height : undefined;
  return {
    nodeId: id,
    format,
    scale: s,
    data: figma.base64Encode(bytes),
    w,
    h,
    byteLen: bytes.length,
  };
}

// Collapses N round-trips through the bridge into one (ADR-3). Loops the async
// node lookup (ADR-8 — async is harmless under legacy mode and forward-safe
// against any later dynamic-page adoption); missing-node failures are recorded
// per-id rather than failing the whole batch.
async function getBatchNodes(nodeIds: string[]) {
  if (!Array.isArray(nodeIds)) throw new Error('get-batch-nodes: nodeIds must be an array');
  const out: any[] = [];
  for (const id of nodeIds) {
    try {
      const node = await figma.getNodeByIdAsync(id);
      if (!node) {
        out.push({ id, error: `Node not found: ${id}` });
      } else {
        out.push(serializeNodeDetailed(node));
      }
    } catch (e) {
      out.push({ id, error: e instanceof Error ? e.message : String(e) });
    }
  }
  return out;
}

// ADR-4 core, factored out (figl.6) so export-figure can resolve the bound
// variables of EVERY node in a subtree without re-implementing the walk. The
// binding list — its order, fields, and per-binding shape — is byte-identical
// to the figl.5 resolve-variables contract; the public action below is now a
// thin wrapper. `valuesByMode` "will not resolve any aliases" (typings :11441);
// only `Variable.resolveForConsumer(consumer)` (:11432) walks the chain to a
// concrete value, and it needs the consuming SceneNode (which lives only here).
async function collectBoundVariables(node: BaseNode): Promise<any[]> {
  const sceneNode = node as SceneNode;
  const bindings: any[] = [];

  async function pushAlias(field: string, alias: any) {
    if (!alias || alias.type !== 'VARIABLE_ALIAS' || typeof alias.id !== 'string') return;
    const variable = await figma.variables.getVariableByIdAsync(alias.id);
    if (!variable) {
      bindings.push({ field, variableId: alias.id, error: 'Variable not found' });
      return;
    }
    try {
      const resolved = variable.resolveForConsumer(sceneNode);
      bindings.push({
        field,
        variableId: alias.id,
        name: variable.name,
        resolvedType: resolved.resolvedType,
        value: resolved.value,
      });
    } catch (e) {
      bindings.push({
        field,
        variableId: alias.id,
        name: variable.name,
        error: e instanceof Error ? e.message : String(e),
      });
    }
  }

  // 1. Node-level boundVariables (scalar + multi-value + componentProperties).
  const nbv = (node as any).boundVariables;
  if (nbv && typeof nbv === 'object') {
    for (const key of Object.keys(nbv)) {
      const val = nbv[key];
      if (Array.isArray(val)) {
        for (let i = 0; i < val.length; i++) await pushAlias(`${key}[${i}]`, val[i]);
      } else if (val && typeof val === 'object' && (val as any).type === 'VARIABLE_ALIAS') {
        await pushAlias(key, val);
      } else if (val && typeof val === 'object') {
        // componentProperties: { [propertyName]: VariableAlias }
        for (const propName of Object.keys(val)) {
          await pushAlias(`${key}.${propName}`, (val as any)[propName]);
        }
      }
    }
  }

  // 2. Per-paint boundVariables on fills / strokes / effects / layoutGrids
  //    (e.g. SOLID.boundVariables.color — where the CODEMOJIES aliases live).
  for (const arrayKey of ['fills', 'strokes', 'effects', 'layoutGrids']) {
    const arr = (node as any)[arrayKey];
    if (!Array.isArray(arr)) continue;
    for (let i = 0; i < arr.length; i++) {
      const entry = arr[i];
      if (!entry || !entry.boundVariables) continue;
      for (const subKey of Object.keys(entry.boundVariables)) {
        const subVal = entry.boundVariables[subKey];
        if (Array.isArray(subVal)) {
          for (let j = 0; j < subVal.length; j++) {
            await pushAlias(`${arrayKey}[${i}].${subKey}[${j}]`, subVal[j]);
          }
        } else {
          await pushAlias(`${arrayKey}[${i}].${subKey}`, subVal);
        }
      }
    }
  }

  return bindings;
}

// ADR-4: the one capability the Mac client physically cannot supply. Thin
// wrapper over collectBoundVariables — the figl.5 {nodeId, bindings, count}
// contract is unchanged (the binding walk now lives in the helper above).
async function resolveVariables(nodeId?: string) {
  const id = resolveNodeId(nodeId);
  const node = await figma.getNodeByIdAsync(id);
  if (!node) {
    throw new Error(`Node not found: ${id}`);
  }
  const bindings = await collectBoundVariables(node);
  return { nodeId: id, bindings, count: bindings.length };
}

// figl.6 / ADR-9, ADR-10 — vector asset boundaries. An icon is usually a GROUP
// of paths; we want it as ONE reusable .svg, not N path fragments. So a node is
// an asset boundary when its WHOLE subtree is vector shapes (or it is a single
// vector leaf). A layout frame mixing a vector with text is NOT a boundary — it
// stays structural and we recurse into it. Types per the typings: VECTOR :10529,
// LINE :10446, ELLIPSE :10462, POLYGON :10482, STAR :10502, BOOLEAN_OPERATION :10884.
const VECTOR_TYPES = ['VECTOR', 'STAR', 'LINE', 'ELLIPSE', 'POLYGON', 'BOOLEAN_OPERATION'];

function isVectorSubtree(node: BaseNode): boolean {
  if (VECTOR_TYPES.indexOf(node.type) !== -1) return true;
  if ('children' in node) {
    const kids = (node as any).children as BaseNode[];
    return kids.length > 0 && kids.every(isVectorSubtree);
  }
  return false;
}

// A leaf that paints a raster (an IMAGE fill) → export it as a PNG at `scale`.
function hasImageFill(node: BaseNode): boolean {
  const fills = (node as any).fills;
  return Array.isArray(fills) && fills.some((f: any) => f && f.type === 'IMAGE' && f.visible !== false);
}

// figl.6 — the FigureBundle RAW gather. The plugin does ONLY what needs the
// figma.* API: the structural read (serializeNodeDetailed), token resolution
// (collectBoundVariables → resolveForConsumer), and per-asset export — the
// SVG_STRING overload returns a string (typings :8675); the image overload
// returns a Uint8Array (:8673) base64-encoded with figma.base64Encode (:1886).
// It returns RAW payloads (svg strings, base64 rasters, raw bindings); every
// pure-data transform (RGBA→hex, fills→background, auto-layout→flex, box-shadow,
// humanized naming, disk egress) lives in mcp.js / figure.js, unit-tested on the
// Mac with no Figma. Bounded by maxNodes exactly like serializeSubtree (ADR-2):
// depth omitted = the full subtree (capped); depth=N expands N levels.
async function exportFigure(nodeId?: string, depth?: number, scale: number = 1, maxNodes: number = DEFAULT_MAX_NODES) {
  const id = resolveNodeId(nodeId);
  const root = await figma.getNodeByIdAsync(id);
  if (!root) {
    throw new Error(`Node not found: ${id}`);
  }

  const s = Number(scale) || 1;
  const assets: any[] = [];
  let count = 0;
  let truncated = false;
  const maxDepth = depth === undefined ? Infinity : depth;

  async function walk(node: BaseNode, d: number): Promise<any> {
    count++;
    const data: any = serializeNodeDetailed(node);
    if ('opacity' in node) data.opacity = (node as any).opacity; // BlendMixin :4331
    const tokens = await collectBoundVariables(node);
    if (tokens.length) data.tokens = tokens;

    // Asset boundary: a pure-vector subtree → one SVG; an image leaf → one PNG.
    // The node becomes a leaf asset — we do NOT recurse into it.
    if (isVectorSubtree(node) && 'exportAsync' in node) {
      const svgString = await (node as SceneNode).exportAsync({ format: 'SVG_STRING' });
      assets.push({
        node: node.id,
        name: node.name,
        type: 'svg',
        data: svgString,
        w: 'width' in node ? (node as any).width : undefined,
        h: 'height' in node ? (node as any).height : undefined,
        byteLen: svgString.length,
      });
      data.assetRef = node.id;
      delete data.children;
      return data;
    }
    if (!('children' in node) && hasImageFill(node) && 'exportAsync' in node) {
      const bytes = s === 1
        ? await (node as SceneNode).exportAsync({ format: 'PNG' })
        : await (node as SceneNode).exportAsync({ format: 'PNG', constraint: { type: 'SCALE', value: s } });
      assets.push({
        node: node.id,
        name: node.name,
        type: 'png',
        data: figma.base64Encode(bytes),
        scale: s,
        w: 'width' in node ? (node as any).width : undefined,
        h: 'height' in node ? (node as any).height : undefined,
        byteLen: bytes.length,
      });
      data.assetRef = node.id;
      return data;
    }

    // Structural: recurse (bounded), replacing the lite {id,name,type} stubs.
    if (d > 0 && 'children' in node) {
      const kids = (node as any).children as BaseNode[];
      const rich: any[] = [];
      for (const c of kids) {
        if (count >= maxNodes) { truncated = true; break; }
        rich.push(await walk(c, d - 1));
      }
      data.children = rich;
    }
    return data;
  }

  const rootData = await walk(root, maxDepth);
  rootData.nodeCount = count;
  if (truncated) rootData.truncated = true;
  return { root: rootData, assets };
}

function serializeNode(node: BaseNode) {
  const base: any = {
    id: node.id,
    name: node.name,
    type: node.type
  };

  if ('children' in node) {
    base.children = node.children.map(child => ({
      id: child.id,
      name: child.name,
      type: child.type
    }));
  }

  return base;
}

function serializeNodeDetailed(node: BaseNode) {
  const data: any = serializeNode(node);
  const n = node as any;

  if ('visible' in node) data.visible = node.visible;
  if ('locked' in node) data.locked = node.locked;

  if ('x' in node) data.x = n.x;
  if ('y' in node) data.y = n.y;
  if ('width' in node) data.width = n.width;
  if ('height' in node) data.height = n.height;

  if ('fills' in node) {
    data.fills = JSON.parse(JSON.stringify(n.fills));
  }
  if ('strokes' in node) {
    data.strokes = JSON.parse(JSON.stringify(n.strokes));
  }
  if ('effects' in node) {
    data.effects = JSON.parse(JSON.stringify(n.effects));
  }

  // figl.3 / ADR-3 — cornerRadius behind a figma.mixed guard. The unified value
  // is only meaningful when every corner agrees; the per-corner numbers are
  // always concrete and always safe to emit.
  if ('cornerRadius' in node) {
    if (n.cornerRadius !== figma.mixed) {
      data.cornerRadius = n.cornerRadius;
    }
    if ('topLeftRadius' in node) data.topLeftRadius = n.topLeftRadius;
    if ('topRightRadius' in node) data.topRightRadius = n.topRightRadius;
    if ('bottomLeftRadius' in node) data.bottomLeftRadius = n.bottomLeftRadius;
    if ('bottomRightRadius' in node) data.bottomRightRadius = n.bottomRightRadius;
  }

  // figl.3 / ADR-3 — auto-layout fields, emitted ONLY when the node actually
  // participates in auto-layout. Bare frames stay slim so get-selection is not bloated.
  if ('layoutMode' in node && n.layoutMode !== 'NONE') {
    data.layoutMode = n.layoutMode;
    if ('paddingTop' in node) data.paddingTop = n.paddingTop;
    if ('paddingRight' in node) data.paddingRight = n.paddingRight;
    if ('paddingBottom' in node) data.paddingBottom = n.paddingBottom;
    if ('paddingLeft' in node) data.paddingLeft = n.paddingLeft;
    if ('itemSpacing' in node) data.itemSpacing = n.itemSpacing;
    if ('layoutSizingHorizontal' in node) data.layoutSizingHorizontal = n.layoutSizingHorizontal;
    if ('layoutSizingVertical' in node) data.layoutSizingVertical = n.layoutSizingVertical;
  }

  if ('absoluteBoundingBox' in node && n.absoluteBoundingBox) {
    const abb = n.absoluteBoundingBox;
    data.absoluteBoundingBox = { x: abb.x, y: abb.y, width: abb.width, height: abb.height };
  }

  if (node.type === 'TEXT') {
    const textNode = node as TextNode;
    data.characters = textNode.characters;
    data.fontSize = textNode.fontSize;
    data.fontName = textNode.fontName;
  }

  return data;
}

figma.on('selectionchange', () => {
  sendDocumentUpdate();
});

figma.showUI(__html__, { width: 300, height: 200, themeColors: true });
connectToBridge();
