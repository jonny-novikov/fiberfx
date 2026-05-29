# @jonnify/e2e

Playwright + TypeScript end-to-end suite for the jonnify landing page.

The suite drives the local jonnify static server and verifies the v2 landing
page (`/`): its four-card modgrid root, its three.js WebGL scene, its links, its
accessibility, and its runtime performance.

## Prerequisites

- Node.js 18 or newer.
- The Chromium browser is already cached at
  `~/Library/Caches/ms-playwright`. The suite does not download browsers.
- The jonnify Go server builds locally via the repo `Makefile`
  (`make -C ../.. start`), which Playwright invokes automatically when no
  server is listening on port 8765.

## How to run

```bash
cd apps/e2e
npm i
npm test
```

The `webServer` block in `playwright.config.ts` starts the server with
`make -C ../.. start` and waits for `http://localhost:8765/health`. When a
server is already running on that port, the suite reuses it
(`reuseExistingServer: true`).

Additional scripts:

| Script | Purpose |
| --- | --- |
| `npm test` | Run the suite headless. |
| `npm run test:headed` | Run with a visible browser. |
| `npm run test:ui` | Open the Playwright UI runner. |
| `npm run report` | Open the last HTML report. |

The base URL is overridable with `E2E_BASE_URL`.

## Layout

```
apps/e2e/
  package.json
  playwright.config.ts
  tsconfig.json
  fixtures/
    nodes.json     # dataset: source of truth (do not modify)
    mindmap.ts     # page-object + dataset loaders
  tests/
    smoke.spec.ts        # E1 endpoint status checks
    links.spec.ts        # E1 allRealUrls + planned-node link checks
    dataset-sync.spec.ts # inlined NODES/GROWTH equal nodes.json
    root-cards.spec.ts   # E2 modgrid root cards + chrome + screenshots
    scene.spec.ts        # E3 enter scene / drill / navigate / back / orbit
    a11y.spec.ts         # E4 keyboard / axe / reduced-motion / no-JS
    perf.spec.ts         # E5 console health / frame cadence / visibility / WebGL
```

The dataset `fixtures/nodes.json` is the source of truth for node ids, urls,
types, parent relationships, and the planned flag. `fixtures/mindmap.ts`
exposes typed loaders (`realNodes`, `plannedNodes`, `hubs`, `hubIds`, `leaves`,
`growth`, `childrenOf`, `realUrls`, `seriesColor`) and page-object helpers
(`gotoMap`, `nodeLocator`, `modcard`, `view`, `enterSeries`,
`enterSeriesAndSettle`, `back`, `collapseAll`, `sceneNodeIds`, `activate`,
`allRealUrls`, `motionRunning`).

## CONTRACT (v2)

The page (`index.html`) and these specs MUST agree on the following. Keep both
sides in sync when either changes. The v2 page has two views: a four-card
modgrid ROOT, and a three.js WebGL SCENE per series.

### Views and containers

- Root container `#root-view` holds `.modgrid`. Scene container `#scene-view`
  holds the `<canvas id="gl">` and `<button id="btn-back">`. Both ids exist in
  the DOM at all times; exactly one view is active and the inactive one carries
  the `hidden` attribute (or a class that sets `display:none`).
- `.modgrid` has exactly four `.modcard` elements, one per series in dataset hub
  order `['school','future','edu','ege']`. Each modcard is a real anchor
  `<a class="modcard" data-series="<series>" href="/<series>">` carrying a
  per-series top-border accent color and containing a `.mnum`, an `<h4>`, a
  `<p>`, and a `.go` label. Activating a card transitions ROOT -> SCENE; the
  href keeps the JS-off path a plain navigation to the hub.

### Scene nodes and labels

- Each 3D node has an HTML CSS2D label carrying `data-id="<clean-path>"` and the
  node text. An expandable node's label carries `role="button"`, `tabindex="0"`,
  and `aria-expanded`. A leaf label is an `<a href="/<clean-path>">`. A planned
  node label is a non-anchor with `aria-disabled="true"` and
  `data-planned="true"`, and never navigates.
- Under automation (`navigator.webdriver === true`) the scene applies zero
  auto-motion so projected label positions are stable across frames; a pointer
  drag on `#gl` still reorients the camera, which moves those positions.

### Window hook

- The page exposes a read-only test hook on `window`, defined synchronously at
  module start (before three.js loads):

  ```js
  window.__mindmap = {
    motionRunning: boolean,        // true while the render/animation loop runs
    view(),                        // 'root' | 'scene'
    enterSeries(seriesId),         // ROOT -> SCENE for a hub id (lazy-loads three)
    back(),                        // SCENE -> ROOT
    collapseAll(),                 // back() + reset
    sceneNodeIds(),                // data-ids in the 3D scene (empty at ROOT)
    activate(id),                  // expandable drills, leaf navigates, planned no-ops
    allRealUrls()                  // every real url ("/"+id, edu hub = "/edu")
  }
  ```

- Initial state is the ROOT view: `view() === 'root'` and `sceneNodeIds()` is
  empty. `allRealUrls()` excludes the planned node.

### Additional selectors the specs depend on

- `#topbar`, `#footer`, and `#legend` exist and are visible chrome regions.
- The `body` computed `background-image` is not `none`.
- The no-JS / fallback sitemap is `<nav id="sitemap-fallback">` containing
  `<a href>` links to every real node; visible by default, hidden (via the
  `hidden` attribute or a class) once JS boots (`body.js-ready`).
- The render loop reads `document.visibilityState` and `visibilitychange`,
  setting `__mindmap.motionRunning` to `false` while hidden and back to `true`
  on restore.
- Under `prefers-reduced-motion: reduce`, the loop does not auto-rotate/bob and
  `motionRunning === false`, while `enterSeries` still works.
