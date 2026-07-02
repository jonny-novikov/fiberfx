# mx.9.6 — build context (llms)

**One line.** Bring `apps/showcase` chrome to *visual* parity with `static/showcase.html` (the deferred mx.9.5
acceptance), and add a Playwright visual-regression harness so the pixel pass is mechanical, not a manual residual.

**Reference.** `mercury/static/showcase.html` (+ its `support.js`/`tokens.css`/`mercury.css` runtime, all under
`mercury/static/`). Renders headlessly when the dir is served. Its `<style>` block (lines 19–77) is the exact
target for the sidebar/topbar/page/stage/hero/gcards values.

**Parity is STYLE, not content.** The app is a derived showcase (registry → live `.stories.tsx` stage → `.prompt.md`
docs); the sidebar grouping stays derived (Operator carve-out). Match the skin: sidebar item style + brand, inset
topbar, eyebrow/title/lede headers, near-solid stage, Home overview, sans display titles, spacing/color.

**Two diagnosed root causes (don't re-investigate).**
- Mono titles: `packages/mercury-ui/src/styles/tokens.css:373-390` sets bare `h1/h2/h3 → var(--font-secondary=DM
  Mono)`. Override app-side with `var(--font-primary)` on the chrome heading classes. **Never edit the DS tokens.**
- Strong hatch: mx.9.5 painted hatch-first. The reference paints the opaque base FIRST (hatch occluded). Reorder.

**Boundary/gate.** Edit only `apps/showcase/src/**` + `apps/showcase/visual/**` + `package.json`. Tokens-only, no
raw hex; barrel/packages frozen; `pnpm-lock.yaml` for the Operator. Gate: `pnpm --filter @mercury/showcase
typecheck && … build`, then the harness (`node visual/shoot.mjs`) — Read the app shots next to the ref shots.

**Harness usage.**
`SHOTS_DIR=<dir> REF_URL=http://localhost:8799/showcase.html node mercury/apps/showcase/visual/shoot.mjs`
(serve the reference first: `python3 -m http.server 8799 --directory mercury/static`).

**Waves.** W1 = layout grid + sidebar brand/dots + inset topbar + heading-font (A) + stage (D). W2 = ComponentPage
header (B) + Home overview (C, metrics derived from `REGISTRY`/`TOTAL`). Self-iterate each wave against the harness.
