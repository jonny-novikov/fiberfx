# Visual tests — `@codemoji/design`

Screenshot Storybook stories and pixel-diff them, so layout/alignment regressions
(things a build + tsc can't catch) are caught against the real render.

## Tools

- **`shoot.mjs`** — serve `storybook-static/` and screenshot a story element.
- **`compare.mjs`** — pixelmatch two PNGs → a highlighted diff + mismatch %.

Both are pure Node + Playwright (Chromium) + pixelmatch/pngjs (devDependencies).

## Use

```sh
pnpm build-storybook                                  # produce storybook-static/

# screenshot a story (default selector "figure" = the first device frame = the
# LIVE pane of a drift view). CLIP_H caps the height for tall screens.
pnpm shoot screens-rooms-lobby--lobby figure /tmp/lobby-live.png
CLIP_H=700 pnpm shoot screens-rooms-lobby--lobby figure /tmp/lobby-top.png
pnpm shoot lobby-nav-phone-panel--default '#storybook-root' /tmp/nav.png

# compare a live shot against a baseline / the Figma reference export
pnpm compare /tmp/lobby-top.png gameplay/assets/rooms-lobby-121-2056.png /tmp/diff.png
```

`compare.mjs` crops both images to their common top-left size, so a live shot and a
Figma export of different sizes still diff. Exit code is non-zero when mismatch > 2%
(a gate for a baseline regression — not for intentional drift like role colors).

## Why

The drift view shows the live build beside the Figma reference; these tools let the
build *itself* be screenshotted and diffed, instead of relying on eyeballing in the
Storybook UI. Shoot the region you changed, open the PNG, compare to Figma.
