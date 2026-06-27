# Visual tests — `@codemoji/design`

Screenshot Storybook stories and diff them against the **exported Figma master**, so
layout/alignment regressions (things a build + tsc can't catch) are caught against the
real render — and against the design source itself.

## Tools

| Tool | Does | Half of the loop |
|---|---|---|
| **`figma-export.mjs`** | export ONE Figma node → an image via the figma-local bridge (no API key) | capture the **exported Figma** |
| **`shoot.mjs`** | serve `storybook-static/` and screenshot a story element | capture the **live** render |
| **`compare.mjs`** | pixelmatch two PNGs → a highlighted diff **+ a side-by-side composite** | **compare** figures |
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
