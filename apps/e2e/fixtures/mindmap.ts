import { type Page, type Locator, expect } from "@playwright/test";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
// Load the dataset via fs rather than a JSON import: Node's ESM loader requires
// an import attribute (`with { type: "json" }`) that the Playwright transpiler
// does not reliably emit, so a direct read keeps this portable across versions.
const data = JSON.parse(
  readFileSync(fileURLToPath(new URL("./nodes.json", import.meta.url)), "utf8"),
);

/**
 * Page-object and dataset loaders for the v2 landing page.
 *
 * The v2 page presents a four-card .modgrid at the ROOT view; activating a card
 * dives into a three.js WebGL SCENE for that series, where each topic is a 3D
 * node with an HTML CSS2D label. The dataset in nodes.json is the single source
 * of truth for node ids, urls, types, parent relationships, and the planned
 * flag. The shared v2 contract defines the DOM ids (#root-view, #scene-view,
 * #gl, #btn-back), the per-label [data-id] hooks, and the window.__mindmap test
 * hook that this module relies on.
 */

/* ------------------------------------------------------------------ *
 * Dataset types and loaders
 * ------------------------------------------------------------------ */

export interface MindmapNode {
  id: string;
  label: string;
  series: string;
  type: string;
  parent: string | null;
  url?: string;
  roman?: string;
  planned?: boolean;
}

export interface GrowthEdge {
  from: string;
  to: string;
}

interface NodesFile {
  nodes: MindmapNode[];
  growth: GrowthEdge[];
}

const dataset = data as unknown as NodesFile;

/** Every node entry from the dataset, in file order. */
export const allNodes: MindmapNode[] = dataset.nodes;

/** Growth edges that describe cross-series connections in the dataset. */
export const growth: GrowthEdge[] = dataset.growth;

/** A node counts as planned when it carries the explicit planned flag. */
function isPlanned(node: MindmapNode): boolean {
  return node.planned === true || node.type === "planned";
}

/** Nodes that map to a real page (carry a url and are not planned). */
export const realNodes: MindmapNode[] = allNodes.filter(
  (node) => !isPlanned(node) && typeof node.url === "string",
);

/** Nodes that are placeholders for unwritten pages. */
export const plannedNodes: MindmapNode[] = allNodes.filter(isPlanned);

/** The four top-level hub nodes (parent === null), in dataset order. */
export const hubs: MindmapNode[] = allNodes.filter((node) => node.parent === null);

/** The four hub ids in their canonical dataset order [school,future,edu,ege]. */
export const hubIds: string[] = hubs.map((node) => node.id);

/** The four series ids, identical to the hub ids in dataset order. */
export const seriesIds: string[] = hubIds;

/** Per-series accent color, mirroring the page's SERIES_COLOR tokens. */
export const seriesColor: Record<string, string> = {
  school: "#d4a85a",
  geometria: "#9d7cc9",
  future: "#5a87c4",
  edu: "#7ba387",
  ege: "#c4504c",
};

/** Set of ids that act as a parent for at least one other node. */
const parentIds = new Set<string>(
  allNodes.map((node) => node.parent).filter((parent): parent is string => parent !== null),
);

/** Nodes that have at least one child (hubs and sub-hubs). */
export const expandableNodes: MindmapNode[] = allNodes.filter((node) =>
  parentIds.has(node.id),
);

/** Real nodes that have no children (true leaves that navigate). */
export const leaves: MindmapNode[] = realNodes.filter((node) => !parentIds.has(node.id));

/** Returns the direct children of a node id, in dataset order. */
export function childrenOf(id: string): MindmapNode[] {
  return allNodes.filter((node) => node.parent === id);
}

/** Returns the child ids of a node id, in dataset order. */
export function childIdsOf(id: string): string[] {
  return childrenOf(id).map((node) => node.id);
}

/** Looks up a single node by id, or undefined when absent. */
export function nodeById(id: string): MindmapNode | undefined {
  return allNodes.find((node) => node.id === id);
}

/**
 * Every real url, computed the same way the page's allRealUrls() hook does:
 * node.url for each real node (the edu hub yields "/edu"; the geometria hub
 * yields "/school/geometria" since its files live under school/). The planned
 * node is excluded. Used to cross-check the live hook output.
 */
export const realUrls: string[] = realNodes.map((node) => node.url ?? "/" + node.id);

/* ------------------------------------------------------------------ *
 * Window hook typing (v2 contract)
 * ------------------------------------------------------------------ */

export type MindmapView = "root" | "scene";

export interface MindmapHook {
  /** True while the continuous render/animation loop is active. */
  motionRunning: boolean;
  /** Current view. */
  view(): MindmapView;
  /** Switch ROOT -> SCENE for a hub id; lazy-loads three.js. */
  enterSeries(seriesId: string): void;
  /** Return SCENE -> ROOT. */
  back(): void;
  /** Alias for back() plus a reset of scene state. */
  collapseAll(): void;
  /** data-ids currently present in the 3D scene (empty at ROOT). */
  sceneNodeIds(): string[];
  /** Programmatic node activation: expandable drills, leaf navigates, planned no-ops. */
  activate(id: string): void;
  /** Every real node url ("/"+id, edu hub = "/edu"); excludes the planned node. */
  allRealUrls(): string[];
}

declare global {
  interface Window {
    __mindmap: MindmapHook;
  }
}

/* ------------------------------------------------------------------ *
 * Page-object helpers
 * ------------------------------------------------------------------ */

/**
 * Navigates to the 3D map page (/map) and waits until the v2 test hook is
 * installed. The hook is defined synchronously at module start (before three.js
 * loads), so resolving it confirms JS has booted and the modgrid root is live —
 * it does not wait for any WebGL scene, which only mounts on the first
 * enterSeries(). Note: "/" is now the lightweight landing hub with no __mindmap
 * hook; the orbital map (and the whole v2 contract) lives at /map.
 */
export async function gotoMap(page: Page): Promise<void> {
  // Wait for DOM ready, not the full "load" event: the synchronous __mindmap
  // hook is what matters, and "load" would also block on the ~1.3MB three.js
  // modulepreload (only needed once a series is entered), which is slow under load.
  await page.goto("/map", { waitUntil: "domcontentloaded" });
  await page.waitForFunction(() => {
    const hook = (window as unknown as { __mindmap?: MindmapHook }).__mindmap;
    return Boolean(hook) && typeof hook.view === "function";
  });
}

/** Locator for the label/node element carrying the given data-id. */
export function nodeLocator(page: Page, id: string): Locator {
  return page.locator(`[data-id="${cssEscape(id)}"]`);
}

/** Locator for the modcard anchor of a series (school/future/edu/ege). */
export function modcard(page: Page, series: string): Locator {
  return page.locator(`.modcard[data-series="${cssEscape(series)}"]`);
}

/** Reports the current view ('root' | 'scene') via the test hook. */
export async function view(page: Page): Promise<MindmapView> {
  return page.evaluate(() => window.__mindmap.view());
}

/** Switches ROOT -> SCENE for a series id through the test hook. */
export async function enterSeries(page: Page, seriesId: string): Promise<void> {
  await page.evaluate((id) => window.__mindmap.enterSeries(id), seriesId);
}

/** Returns SCENE -> ROOT through the test hook. */
export async function back(page: Page): Promise<void> {
  await page.evaluate(() => window.__mindmap.back());
}

/** Resets scene state and returns to ROOT through the test hook. */
export async function collapseAll(page: Page): Promise<void> {
  await page.evaluate(() => window.__mindmap.collapseAll());
}

/** Returns the data-ids of nodes currently mounted in the 3D scene. */
export async function sceneNodeIds(page: Page): Promise<string[]> {
  return page.evaluate(() => window.__mindmap.sceneNodeIds());
}

/** Activates a node by id through the programmatic test hook. */
export async function activate(page: Page, id: string): Promise<void> {
  await page.evaluate((nodeId) => window.__mindmap.activate(nodeId), id);
}

/** Returns every real node url as reported by the page's hook. */
export async function allRealUrls(page: Page): Promise<string[]> {
  return page.evaluate(() => window.__mindmap.allRealUrls());
}

/** Reports whether the render/animation loop is currently active. */
export async function motionRunning(page: Page): Promise<boolean> {
  return page.evaluate(() => window.__mindmap.motionRunning);
}

/**
 * Enters a series and waits until the scene reports its nodes are mounted, so a
 * subsequent activate()/label assertion runs against a built scene rather than
 * one still resolving the lazy three.js import. Polls the hook rather than
 * sleeping. Resolves once view() === 'scene' and at least one scene node exists.
 */
export async function enterSeriesAndSettle(page: Page, seriesId: string): Promise<void> {
  await enterSeries(page, seriesId);
  await expect
    .poll(async () =>
      page.evaluate(
        () =>
          window.__mindmap.view() === "scene" &&
          window.__mindmap.sceneNodeIds().length > 0,
      ),
    )
    .toBe(true);
}

/**
 * Minimal CSS attribute-value escaper for data-id and data-series values. The
 * dataset ids use letters, digits, hyphens, and slashes; only the quote and
 * backslash need escaping inside a quoted attribute selector.
 */
function cssEscape(value: string): string {
  return value.replace(/["\\]/g, "\\$&");
}
