# Visual tests — `@codemoji/design`

Screenshot Storybook stories and diff them against the **exported Figma master**, so
layout/alignment regressions (things a build + tsc can't catch) are caught against the
real render — and against the design source itself.

## Tools

| Tool | Does | Half of the loop |
|---|---|---|
| **`figma-export.mjs`** | export ONE Figma node → an image via the figma-local bridge (no API key) | capture the **exported Figma** |
| **`shoot.mjs`** | serve `storybook-static/` and screenshot a story element | capture the **live** render |
| **`compare.mjs`** | pixelmatch two PNGs → a highlighted diff **+ a side-by-side composite** | **compare** (pixels) |
| **`overlay.mjs`** | onion-skin + difference-blend two PNGs (resized to a common width) | **compare** (alignment) |
| **`structure-diff.mjs`** | match the manifest's figure bboxes to the live DOM boxes → per-element Δpos/Δsize | **compare** (structure) |
| **`drift.mjs`** | one command: figma-export → shoot → compare | the whole loop |

All pure Node + Playwright (Chromium) + pixelmatch/pngjs (devDependencies). The Figma
side talks straight to the bridge (`src/bridge.mjs`, default the Windows Figma machine
on the LAN) — the same egress `bin/codemoji-design extract` uses.

## Use

```sh
pnpm build-storybook                                  # produce storybook-static/ first

# the whole Figma-vs-live loop in one command (figma node id + story id [+ selector])
pnpm drift 709:38903 board-board-tabs--leaderboard-active '#storybook-root' /tmp/tabs
# → /tmp/tabs/{figma.png, live.png, diff.png, diff.sxs.png} — open the side-by-side

# …or the steps individually:
pnpm figma-export 709:38903 /tmp/figma-tabs.png       # the master's pixels
pnpm shoot board-board-tabs--leaderboard-active '#storybook-root' /tmp/live-tabs.png
pnpm compare /tmp/figma-tabs.png /tmp/live-tabs.png /tmp/diff.png

# CLIP_H caps the height for tall screens; selector "figure" = a drift view's live pane
CLIP_H=700 pnpm shoot screens-rooms-lobby--lobby figure /tmp/lobby-top.png
```

`compare.mjs` crops both images to their common top-left size (so a live shot and a
Figma export of different sizes still diff) and writes BOTH a highlighted `diff.png`
and a `diff.sxs.png` side-by-side. For a **Figma-vs-live** pair the side-by-side is the
artifact to read — a raw pixel-diff is noisy across font anti-aliasing — so `drift.mjs`
does not fail on compare's >2% exit. The % gate is meaningful for a **same-engine
baseline** (a live shot vs a stored live baseline), where >2% flags a real regression.

## Advanced drift comparison — `overlay.mjs` + `structure-diff.mjs`

`compare.mjs` is a heat-map: it tells you *how much* differs, not *where the layout
slipped*. These two go element-level.

```sh
# onion-skin + difference-blend (resizes both to a common width first)
pnpm overlay /tmp/figma-tabs.png /tmp/live-tabs.png /tmp/tabs
# → /tmp/tabs.overlay.png  (Figma + live@50% — a shift reads as a ghosted double edge)
#   /tmp/tabs.diff-blend.png  (|figma − live| — aligned goes black, anything moved GLOWS)

# element-level structural drift: manifest figure bboxes vs the live DOM boxes
pnpm structure-diff codemojies screens-game-free--board figure
# → console table of Δpos/Δsize per figure (largest drift first) + /tmp/cm-structure-<screen>.json
```

**`overlay.mjs`** `<figma.png> <live.png> [outPrefix]` — the single best *misalignment*
spotter. A live shot is deviceScaleFactor-2 at a 1000px viewport (a 375px card → a 750px
PNG) while a Figma 1× export is the node's CSS size, so both are resized to a **common
width** (the smaller of the two, downscaled — never upscaled) and cropped to their common
top-left height before compositing. It writes two artifacts: `<prefix>.overlay.png` (Figma
opaque, live at 50% alpha over white — aligned edges read as one edge, a shift as a ghosted
double edge, so you see the offset *and its direction*) and `<prefix>.diff-blend.png` (the
per-channel `|figma − live|` "Difference" blend — aligned pixels go black, anything that
moved or changed glows; it reads structure, not a heat-map of anti-aliasing). Resizing and
compositing run in a headless Playwright canvas (`drawImage` scaled + `toDataURL`) — **no
resampler dependency added** (pngjs has none, and `sharp` was deliberately not added to keep
`package.json` and the install surface untouched).

**`structure-diff.mjs`** `<screen> <storyId> [selector]` — catches what pixels can't: an
element in the *wrong place at the wrong size*. It reads `figma/<screen>/manifest.json` (the
extracted figure bboxes, in the screen frame's CSS space), pulls every live DOM bounding box
under `[selector]`, maps each into the Figma coordinate space (relative to the captured
frame's origin, then scaled by `figmaW / frameW`), greedily + exclusively matches figures ↔
live boxes by normalized bbox proximity, and prints **Δpos / Δsize per figure in Figma px**,
largest drift first, plus a JSON dump. Figures with no live box within `STRUCT_MATCH_MAX`
(default `1.0`, normalized; override via env) are logged **unmatched** rather than force-paired
— an off-canvas export artifact or a section the live build dropped/reflowed. `selector`
defaults to `figure` (the LIVE device pane of a drift-view story, same as `shoot.mjs`); pass a
tighter inner selector to shed the device-bezel offset, or `#storybook-root` for a bare
component story. It hits **only the manifest** — no bridge, no PNG, no screenshot.

### Which tool

| Question | Tool |
|---|---|
| How *much* differs? (a % gate, a same-engine regression baseline) | `compare.mjs` |
| Is it *shifted / mis-scaled*? (see the offset and its direction) | `overlay.mjs` |
| Is each *designed element* in the right place at the right size? (which one drifted, by how many px) | `structure-diff.mjs` |

Reach for `overlay` when a render "looks off" but you can't say why — the ghosted double
edge names the offset. Reach for `structure-diff` when you need to know *which* component
slipped and quantify it (it survives font/colour differences that swamp a pixel diff, and
names the figure). Use `compare` for a numeric gate against a stored same-engine baseline.

## Retina @2x reference exports

`figma-export.mjs` defaults to **@2x** (`scale: 2`) for fidelity — pass a trailing `1`
to force 1×. To regenerate a whole screen's reference PNGs at @2x, in place:

```sh
pnpm reexport-references codemojies     # re-export figma/codemojies/reference/*.png @2x
pnpm reexport-references codemojies 1    # revert to 1×
```

@2x renders through a Figma `SCALE` constraint in the plugin, so it only takes effect
**after the figma-local plugin is reloaded on the Windows Figma machine** — until then
the deployed plugin ignores the scale param and returns 1×, and every tool says so
(`[asked @2x, plugin returned @1x — reload the Figma plugin]`, or `reexport-references`'
"every file unchanged" warning). `extract` emits @2x references going forward and stamps
`manifest.renderScale: 2`.

## Transforming Figma data

The "transform Figma data → a comparable figure tree" half is already the repo's
`extract` command: `pnpm extract <nodeId>` walks the node via the bridge and writes
`figma/<screen>/` — `manifest.json` (a flattened figure list: id · name · type · x/y/w/h
· render name), per-figure PNG `reference/` renders, `structure/`, `spec.md`, `tokens.md`.
That manifest IS the transformed source: the bbox tree to diff a layout against, the
renders to feed `compare.mjs`. The board master `94:2974` is extracted at
`figma/codemojies/`.

### Researched alternatives (npm/GitHub, June 2026)

Surveyed before keeping the bridge-based `extract`; all need a `FIGMA_TOKEN` (REST API)
where the bridge needs none, so none was adopted — recorded for future REST work:

- **[didoo/figma-api](https://github.com/didoo/figma-api)** — typed REST client (Promises/ES6); `getImage` returns node→PNG/SVG URLs.
- **[mariohamann/figma-export-assets](https://github.com/mariohamann/figma-export-assets)** — batch asset export, any format, handles the REST batch limits.
- **[WeAreDevelopers-com/figma-exporter](https://github.com/WeAreDevelopers-com/figma-exporter)** — bulk image export from a file.

The figma-local bridge is preferred here precisely because it is **token-free** and is
the same path the MCP + the extraction toolkit already use.

## Why

The drift view shows the live build beside the Figma reference; these tools let the
build *itself* be screenshotted and diffed against the design source, instead of relying
on eyeballing in the Storybook UI. Shoot the region you changed, open the side-by-side.
