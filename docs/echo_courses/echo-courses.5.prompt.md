---
title: "ec.5 — polish the live site (ship prompt / x-mode runbook)"
id: echo-courses-5-prompt
rung: ec.5
mode: "Flat-L2, right-sized (Director + ONE mars; NORMAL; no Apollo)"
risk: NORMAL
vehicle: "generic x-mode (.claude/commands/x.md) — NOT /echo-mq-ship"
---

# ec.5 — ship prompt { id="echo-courses-5-prompt" }

## The rung in one paragraph

ec.5 polishes the **already-live** echo-courses site (it stays complete + live throughout — a redeploy, never a first deploy). Three moves, all additive over the ec.4 site: (1) **externalize the design system** — lift the two inline `<style>` blocks from `layout.html` to one fingerprinted, immutable-cached `app.<hash8>.css`, embedded in the binary and served from a content-hash route (D-1), so the look caches like the published one while rendering **byte-equivalently**; (2) **externalize the two interactive scripts** — the index track-filter (`pages/index.html`) and the global reveal-on-scroll (`layout.html`) move to a fingerprinted `app.<hash8>.js`, `<script defer>` before `</body>` (detail pages are landings — ec.4 D-3 — so there are NO new widgets, only these two existing scripts); (3) **add the SEO surface** — per-page `title` + `description`, Open Graph (`og:title/type/url/description/site_name`), a `canonical` link, `twitter:card=summary` (D-2/D-3), plus `GET /sitemap.xml` (the catalog URLs) and `GET /robots.txt`. Then **redeploy**. **Verified via the local dev server (ec.4 D-4, standing), not Docker; `fly deploy` is the Operator's.**

## Authoritative sources

- **The build-grade spec:** `echo-courses.5.md` (the reconciled scope §ec5-scope, the §ec5-spec mechanism, ACs 1–6 + the §ec5-risks signature byte-equivalence invariant). Authoritative.
- **The roadmap:** `echo-courses.roadmap.md` (§5 the ec.5 row, §7 the ruled decisions, **§8 the cross-cutting gates** — esp. gate 1 URL parity, gate 2 visual parity, gate 5 no-broken-links, gate 7 shippable-each-rung).
- **The run ledger:** `ec-5.progress.md` (T-2 the as-built reconcile; **D-1/D-2/D-3** the Operator-/Director-ruled forks; **D-4** the runbook bakes them as settled; **D-5** the per-page-meta mechanism = Mars's call, two options; V-1 the asset-serving arms; L-1 the AC2-is-the-two-scripts trap).
- **The as-built code (read first, all under `go/echo-courses`):** `web/templates/layout.html` (the two `<style>` blocks lines 13–135 + the reveal-on-scroll `<script>` 146–149 + the verbatim `<meta description>` line 8), `web/templates/pages/index.html` (the filter `<script>` 22–34), `web/templates/pages/course.html` (the landing — `{{.Title}}`/`{{.Body}}`), `web/embed.go` (embeds ONLY `templates` today), `cmd/server/main.go` (`e.Static("/static", staticDir)` from disk, `newEcho`), `internal/render/render.go` (the `Renderer`, `New(fsys)`, the per-page set), `internal/handler/courses.go` (`indexData`/`detailData`, `Index`/`Detail`), `internal/catalog/catalog.go` (`Course` — `.Summary`/`.Path`/`.Title`/`.Slug`).
- **The published master (parity ground truth, repo-root):** `html/index.html` — `<head>` = `<title>` + ONE `<meta description>` + font preconnects/stylesheet; **zero og:, zero `rel=canonical`, zero favicon, zero JSON-LD** (the lone `canonical` grep hit is body text at line 192). So OG + canonical are ADDITIVE; the only strict parity duty is the index `<meta description>` byte-identical to published (already verbatim at `layout.html:8`).

## Settled (RULED — do not reopen; D-1/D-2/D-3 are CONTRACTS Mars builds TO)

- **D-1 — asset-serving = Arm A1 embed + content-hash route (Operator-ruled via AskUserQuestion).** Add `static` to the embed (`//go:embed templates static`). At boot, sha256 the externalized CSS and JS bytes → serve them at `/static/app.<hash8>.css` and `/static/app.<hash8>.js` **from the embedded bytes** (not from disk), each with `Cache-Control: public, max-age=31536000, immutable` (and the right `Content-Type`). Inject the hashed URLs into the layout: the CSS as a `<link rel="stylesheet">` in `<head>`, the JS as `<script defer src=…>` immediately before `</body>`. (Rationale, recorded V-1: single-binary symmetry with the already-embedded templates + correct cache invalidation by construction — a byte change yields a new hash → a new URL. NOT `?v=` query-busting; NOT a minify/esbuild pipeline — minifying would BREAK byte-equivalence.)
- **D-2 — canonical/OG base = env `CANONICAL_BASE`, default `https://jonnify.fly.dev`.** Read once at boot (the `envOr` pattern already in `main.go`); the canonical + `og:url` for a page = `CANONICAL_BASE` + the page's path.
- **D-3 — `og:image` OMITTED.** The published master has zero OG; there is no cover asset; SVG OG is poorly supported. Ship `og:title` / `og:type` / `og:url` / `og:description` / `og:site_name` + `canonical` + `twitter:card=summary` — and no more. The index `<meta description>` stays **BYTE-IDENTICAL** to the published master (it already is, `layout.html:8`); detail-page descriptions = `Course.Summary`.

> The per-page-meta + asset-URL **injection mechanism** (Go shape) is **Mars's call** (D-5) — Option A a shared `Head` struct embedded in every view-model, or Option B a template `FuncMap` the render set closes the boot-hashes + `CANONICAL_BASE` over. The spec fixes the *contract* (what each head renders), not the form; both pass the same shape-agnostic gates. Mars picks one and states it.

## Build (Mars; inside `go/echo-courses` ONLY — no second module)

The exact files touched (the topology):

1. **`web/static/app.css`** (NEW) — the externalized design system: the **concatenation of the two `<style>` block bodies** in `layout.html` (the design-system root + the courses-page chrome), **byte-for-byte, sans the `<style>`/`</style>` wrappers**. This file's bytes are the signature invariant (see the gate).
2. **`web/static/app.js`** (NEW) — the externalized interactivity: the **two existing inline scripts** concatenated — the reveal-on-scroll (`layout.html:146–149`) + the track-filter (`pages/index.html:22–34`), **byte-for-byte sans the `<script>` wrappers**. Author NO new widget (NO-INVENT; §9 non-goal).
3. **`web/embed.go`** — extend the directive to `//go:embed templates static` (so the binary carries the assets; this is what makes D-1's embedded-bytes serving possible).
4. **`cmd/server/main.go` / a new `internal/handler` (or `internal/asset`) seam** — at boot: read the embedded `static/app.css` + `static/app.js`, sha256 each → an 8-char hex hash, register `GET /static/app.<hash>.css` + `…<hash>.js` serving the embedded bytes with the immutable `Cache-Control` + correct `Content-Type`. **Remove the now-stale assets from the old disk `e.Static` path as appropriate** (keep `/static` working for anything still disk-served, e.g. fonts if any land there; today only `version.txt` lives there). Register `GET /sitemap.xml` (an XML body: `<urlset>` over `CANONICAL_BASE` + `/courses` + each `Course.Path`) and `GET /robots.txt` (a sane default — allow all + a `Sitemap:` line pointing at `CANONICAL_BASE/sitemap.xml`). Read `CANONICAL_BASE` (D-2) via `envOr`.
5. **`web/templates/layout.html`** — DELETE the two inline `<style>` blocks and the inline reveal-on-scroll `<script>`; in their place inject (per D-5's chosen mechanism) the `<link rel="stylesheet" href="/static/app.<hash>.css">` in `<head>` and `<script defer src="/static/app.<hash>.js">` before `</body>`. Add the per-page OG/canonical/twitter meta to `<head>` (a `{{block "head"}}`-style seam or the Head struct / funcs). Keep the existing `{{block "title"}}` and the verbatim `<meta description>` for the index (byte-identical to published).
6. **`web/templates/pages/index.html`** — DELETE the inline filter `<script>` (now in `app.js`); supply the index's per-page meta if Option A (Head struct) is chosen.
7. **`web/templates/pages/course.html`** — supply each detail page's per-page meta: `title` = `{{.Title}} · jonnify` (already), `description` = `Course.Summary`, `og:*` + canonical from `CANONICAL_BASE` + the course path.
8. **`internal/handler/courses.go`** — if Option A: extend `indexData`/`detailData` with the `Head` payload (asset hashes + per-page meta) the handlers populate; if Option B: no handler change (the funcs read boot state).

- **NO-INVENT API pins** (Echo v5, verified in `go/echo` / already used in the tree): handlers `func(c *echo.Context) error`; `c.Render(200, "<page>.html", data)`; `echo.NewHTTPError(code, msg)`; raw bytes via `c.Blob(status, contentType, b)` or `c.String(status, s)` for sitemap/robots; the embedded FS pattern is `web.FS` (already an `embed.FS`). Use `crypto/sha256` + `encoding/hex` for the hash; `fs.ReadFile(web.FS, "static/app.css")` for the bytes. Do **not** invent an Echo asset-pipeline helper — serve the bytes directly.

## Gate (LOCAL DEV SERVER; `GOWORK=off`; from `go/echo-courses`)

- `make gate` (`go mod tidy` + `build` + `vet` + `test`; `gofmt -l .` prints nothing). Add Go tests for: the sitemap body (lists `/courses` + all five `Course.Path`), the robots body (valid, has the `Sitemap:` line), and the hash-route registration.
- **THE SIGNATURE TEST — byte-equivalence (AC1 / §ec5-risks).** A test (or a scripted check the runbook records) proving the **served CSS bytes equal the former inline `<style>` bytes**. Concretely: the bytes of `web/static/app.css` MUST equal the concatenation of the two `layout.html` `<style>` block bodies as they stood at ec.4 HEAD (sans wrappers). Prove it explicitly — e.g. extract the two pre-edit `<style>` bodies from `git show HEAD:web/templates/layout.html`, concatenate, and `diff` against `web/static/app.css` → empty. The rendered page must therefore present the identical CSS, now from a cacheable URL. Do the same for `app.js` vs the two former inline scripts.
- **The local dev server + the URL-parity battery** (curl; ec.4 D-4): `go build -o bin/server ./cmd/server; ADDR=:<port> ./bin/server`, then —
  - `/courses`, `/`, `/elixir`, `/redis-patterns`, `/echomq`, `/course/agile-agent-workflow`, `/bcs` each → **200** + the right course (URL parity, §8 gate 1 — unchanged from ec.4, must still hold).
  - `/courses/:slug` for each slug → the same render (D-3 render-identical).
  - `/static/app.<hash>.css` + `/static/app.<hash>.js` → **200**, correct `Content-Type`, `Cache-Control: public, max-age=31536000, immutable`; a WRONG hash → 404 (the route is the exact hashed path).
  - `/sitemap.xml` → **200**, `Content-Type` xml, body lists `/courses` + all five published paths (absolute under `CANONICAL_BASE`).
  - `/robots.txt` → **200**, valid, the `Sitemap:` line present.
  - **Head inspection** (AC3): `curl /` → the head carries the byte-identical published `<meta description>` + `og:title/type/url/description/site_name` + `<link rel="canonical">` + `twitter:card=summary`; `curl /elixir` → `description` = that course's `Summary`, og/canonical resolved from `CANONICAL_BASE` + the path. Set `CANONICAL_BASE=https://example.test` for one run and confirm the canonical/og:url reflect it (D-2 actually consumed, not a dead env key — the runtime.exs-class check from the reconcile discipline).
  - The hashed `<link>`/`<script>` in the rendered HTML point at the live hash routes (no inline `<style>`/`<script>` remain — grep the rendered `/` for `<style` and the reveal/filter source → absent).
  - `SIGTERM` → exit 0 (graceful shutdown unchanged).
- **A link check** over the rendered index + detail pages (every internal link resolves, incl. the brand `href="/"` and the hashed asset hrefs) — §8 gate 5.
- **Markup validity** (AC6): the rendered HTML has no malformed-markup errors (a tidy/validator pass over `/` + one detail page).
- `Dockerfile`/`fly.toml`: **inspection only** — confirm they still reference the binary + `/healthz`; with `static` now embedded, the `COPY web/static` step is no longer load-bearing for serving (the binary self-contains assets) — note it, do not Docker-build.

## Acceptance (echo-courses.5.md — ACs 1–6)

- **AC1** (design system applied from `web/static`, byte-equivalent layout) — the signature byte-equivalence test + the rendered-page parity (header `jonnify · courses`, footer `(с) jonnify`, card grid, filter present).
- **AC2** (interactive assets load + run) — `app.js` served + linked; the filter + reveal scripts run from the external file (the two existing scripts, not new widgets — L-1).
- **AC3** (head: title, description, OG, canonical; index description = published) — the head-inspection battery; index `<meta description>` byte-identical to `html/index.html:7`.
- **AC4** (`/sitemap.xml` lists `/courses` + five paths; `/robots.txt` valid) — the sitemap/robots curl + tests.
- **AC5** (redeploy → live app serves the polished site; every published path still 200) — verified via the **local dev server** as the standing equivalent (the binary serves all paths, complete + live); `fly deploy` = the Operator's manual completion (ec.4 D-4 standing).
- **AC6** (no malformed-markup errors) — the markup-validity pass.
- **Cross-cutting (roadmap §8):** gates 1 (URL parity), 2 (visual parity), 5 (no broken links), 6 (Echo v5 idioms — `*echo.Context`, `c.Render`), 7 (shippable: the binary serves the complete styled site).

## Stage prompts

### Stage-2 — Mars-1 (build to the brief)
> As Mars on team `ec-5`, build ec.5 to `echo-courses.5.prompt.md` (this file) + `echo-courses.5.md`, inside `go/echo-courses` ONLY. Build the three moves in topology order: (1) externalize `app.css` (byte-for-byte the two `layout.html` `<style>` bodies, sans wrappers) + `app.js` (byte-for-byte the reveal + filter scripts); (2) embed `static`, serve content-hash routes (D-1) with the immutable `Cache-Control`, read `CANONICAL_BASE` (D-2); (3) inject the hashed asset URLs + per-page OG/canonical/twitter meta into the layout (D-3) — pick D-5 Option A (Head struct) **or** B (FuncMap) and STATE which; add `/sitemap.xml` + `/robots.txt`. D-1/D-2/D-3 are SETTLED — build to them, do not reopen. NO new interactive widget (L-1: detail pages are landings). Run the FULL gate before reporting: `make gate`, the byte-equivalence proof (the `git show HEAD:…layout.html` extract-concat-diff → empty), the local-dev-server URL-parity + asset-route + sitemap/robots + head-inspection battery (including one `CANONICAL_BASE=https://example.test` run proving the env is consumed), the link check, the markup pass. Cite the spec line for every public surface; invent no API. Frame all prose third-person, no gendered pronouns, no perceptual/interior verbs, no first-person narration. Report to the Director: what you built per file, the D-5 option chosen, the byte-equivalence diff result, the full gate transcript, and any STALE/blocker.

### Stage-3 — Director (solo review + findings)
> Independent verify on the local dev server. Re-run the gate from a clean `go/echo-courses`. Re-prove byte-equivalence BY HAND: `git show HEAD:web/templates/layout.html`, extract the two `<style>` bodies, concatenate, `diff` against `web/static/app.css` → must be empty; same for the two scripts vs `app.js`. Adversarial probes: (a) a WRONG asset hash → 404 (the route is exact); (b) `CANONICAL_BASE` flip actually changes the canonical/og:url (the dead-env-key class — D-2 consumed, not just declared); (c) grep the rendered `/` for residual inline `<style`/reveal/filter source → absent (the externalization is complete, not duplicated); (d) the index `<meta description>` byte-identical to `html/index.html:7`; (e) URL parity for all five published paths STILL 200 (ec.4 not regressed). A net-zero spot check: the externalization must not change any RENDERED byte except the head/asset wiring (the design-system look is unchanged). File findings as `tool_x_*`; render the verdict.

### Stage-4 — Mars-2 (remediate + harden)
> Address every Director finding. Harden: ensure the asset `Content-Type`s are exact, the sitemap is well-formed XML, robots is valid, and the byte-equivalence holds after any edit (re-run the diff). If the Director found zero findings, this stage collapses (state so). Re-run the full gate; report the delta.

### Stage-5 — Director (ship + Stage-6 fold)
> Final gate green on the local dev server. Commit by pathspec (LAW-4, scoped, Director-only — re-verify `git diff --cached --name-only` is purely ec.5 before committing). Stage-6: flip `echo-courses.5.md` status → Built; backward-reconcile it (an "As built" section: the D-5 option shipped, the content-hash route, the byte-equivalence proof, the local-dev-server/`fly deploy` posture); surface **ec.6** (the production cutover — HIGH, Apollo-mandatory).

## Commit (LAW-4, scoped, Director-only)

`go/echo-courses` (the build: `web/static/app.css` + `app.js`, `web/embed.go`, `cmd/server/main.go`, the asset/sitemap/robots handler, the three templates, `internal/handler/courses.go` if Option A, the new Go tests) **+** `docs/echo_courses` (the ec.5 backward-reconcile + the `ec-5` ledger). `go/echo` is already tracked → no vendor commit. Pathspec only, never `git add -A`; split if the tree is entangled. Do not push unless asked. `fly deploy` is the Operator's (ec.4 D-4 standing).
