---
title: "ec.5 — Polish: SEO, asset externalization, interactive parity"
id: echo-courses-5-polish
rung: ec.5
size: M
risk: NORMAL
status: Draft
stands-on: "ec.4"
---

# ec.5 — Polish the live site { id="echo-courses-5-polish" }

> _On the already-live site, externalize the design-system CSS and the two interactive scripts to `web/static` (embedded + content-hash-served), add per-page metadata, Open Graph, a sitemap, and robots — then redeploy, so the site indexes and caches like the published one while staying complete and live._
>
> _[RECONCILE — "fonts" dropped from the externalization: the as-built layout loads fonts from the Google Fonts CDN (`layout.html:9–11`), not from `web/static`; ec.5 externalizes the CSS + the two scripts only, and leaves the font links as published. The mechanism is D-1 (embed + content-hash route), not a generic "fingerprinted file".]_

## Summary

The ec.4 site is live and styled (the layout's inline CSS). ec.5 moves the design system to `web/static` (embedded, content-hash-served per D-1), externalizes the two interactive scripts the site already has, and adds per-page `title`/`description`, Open Graph, `sitemap.xml`, and `robots.txt` — then redeploys. SEO and asset parity, with the site complete and live throughout.

## Rationale

A live site that inlines its CSS on every page and lacks meta/sitemap works but doesn't cache or index like the published one. Externalizing the assets (so a deploy invalidates correctly) and adding the SEO surface brings the live site to full parity — without ever taking it down (a redeploy, not a first deploy, since ec.4 shipped it live).

## 5W + H { id="ec5-5wh" }

| | |
|---|---|
| **Who** | Platform; reader- and crawler-facing. |
| **What** | Design-system + interactive assets under `/static`, per-page meta + Open Graph, `sitemap.xml`, `robots.txt`; a redeploy. |
| **When** | After ec.4 (live); precedes the production cutover. |
| **Where** | `web/static` (assets), the layout head (meta), handlers for sitemap/robots. |
| **Why** | SEO + caching parity on the live site, without downtime. |
| **How** | Lift the two inline `<style>` blocks + the two inline scripts to `web/static`, embed them, serve from a content-hash route (D-1), link from the layout; meta blocks driven by course data + `CANONICAL_BASE` (D-2/D-3); the sitemap from the catalog; redeploy. |

## Scope { id="ec5-scope" }

### In scope

- Externalize the layout's two inline `<style>` blocks to `web/static/app.css`, **embedded** in the binary and served from a **content-hash route** (`/static/app.<hash8>.css`, immutable `Cache-Control`) per **D-1**, linked from the ec.2 layout head — the rendered look is **byte-equivalent**, just cacheable.
- Externalize the **two existing inline scripts** (the index track-filter + the global reveal-on-scroll) to `web/static/app.js`, served the same content-hash way, `<script defer>` before `</body>` — the interactions run from the external file. _[RECONCILE — no new widgets; detail pages are landings, ec.4 D-3.]_
- Per-page metadata: `title` + `description` (the index `description` **byte-identical** to the published `meta-description`; detail pages from `Course.Summary`), Open Graph (`og:title`/`og:type`/`og:url`/`og:description`/`og:site_name` — **`og:image` omitted, D-3**), `twitter:card=summary`, and a `canonical` link per page (canonical/`og:url` = env `CANONICAL_BASE` + path, **D-2**).
- `GET /sitemap.xml` (the catalog's URLs: `/courses` + each course `Path`); `GET /robots.txt`.
- **Redeploy** the polished site to the Fly app; re-run the parity + a markup/no-broken-link check.

### Out of scope

- The production cutover of `jonnify.fly.dev` + rollback (ec.6).
- Re-hosting the deep course content (landings only).

## Specification { id="ec5-spec" }

The two inline `<style>` blocks from ec.2's layout move to `web/static/app.css` (byte-for-byte, sans wrappers); the two inline scripts move to `web/static/app.js`. Both are **embedded** in the binary (`//go:embed templates static`, **D-1**) and served from boot-computed **content-hash routes** (`/static/app.<hash8>.css`/`.js`, immutable `Cache-Control`) — the rendered bytes match the published look, now cacheable, and a byte change yields a new hash → a new URL (correct invalidation by construction). The layout head renders `title` + `meta description` + Open Graph + `twitter:card` + a `canonical` (from `Course.Summary`/`Title`/`Path` + env `CANONICAL_BASE`, **D-2/D-3**). A sitemap handler emits the catalog URLs; a robots handler emits a sane default. The single binary self-contains the assets; a redeploy ships it, and the parity battery + a markup/link check run via the **local dev server** (ec.4 D-4; `fly deploy` is the Operator's). _[RECONCILE — the assets are embedded + content-hash-served (D-1), NOT disk-served by the ec.1 static handler; that handler serves `web/static` from disk, which D-1 supersedes for the design-system assets.]_

The per-page-meta + asset-URL **injection mechanism** (the Go shape) is the implementor's call: either a shared `Head` struct embedded in each view-model, or a template `FuncMap` the render set closes the boot hashes + `CANONICAL_BASE` over. The spec fixes the head's *contract*, not the form; both pass the same gates.

## Acceptance criteria { id="ec5-acceptance" }

1. **Given** the rendered index + a detail page, **when** compared to the published pages, **then** the design system is applied (now from `web/static`, served from a content-hash route) and the layout matches (header, footer, card grid, filter) byte-equivalently. _[RECONCILE — this is the rung's **signature invariant**: the externalized `app.css` bytes equal the former two inline `<style>` block bodies (sans wrappers), proven by extracting them from `git show HEAD:web/templates/layout.html`, concatenating, and diffing → empty. The externalization changes only the head/asset wiring; no other rendered byte moves.]_
2. **Given** the rendered site, **when** loaded, **then** the externalized interactive assets load and the interactions run. _[RECONCILE — the "interactive assets" are the **two existing inline scripts** externalized to `web/static/app.js`: the index track-filter (`pages/index.html`) and the global reveal-on-scroll (`layout.html`). Detail pages are landings (ec.4 D-3) with no per-course widgets, so ec.5 externalizes those two — it does NOT author new widgets (§9 non-goal: no client-side framework rewrites).]_
3. **Given** any page, **when** its head is inspected, **then** it has a correct `title`, `meta description`, Open Graph tags (`og:title`/`og:type`/`og:url`/`og:description`/`og:site_name`), a `canonical` link, and `twitter:card=summary`; the index `meta description` is **byte-identical** to the published `meta-description`, and detail-page descriptions are the course `Summary`. _[RECONCILE — OG + canonical are ADDITIVE polish: the published master `html/index.html` carries ONLY `<title>` + one `<meta description>` (zero OG, zero `rel=canonical`, zero favicon, zero JSON-LD), so the only strict-parity duty is the index description (already verbatim at `layout.html:8`). Per **D-3**, `og:image` is OMITTED (no cover asset; SVG OG poorly supported). Per **D-2**, `canonical`/`og:url` derive from env `CANONICAL_BASE` (default `https://jonnify.fly.dev`) + the page path.]_
4. **Given** `GET /sitemap.xml`, **then** it lists `/courses` + all five published course paths; **given** `GET /robots.txt`, **then** it returns a valid robots file.
5. **Given** the redeploy, **when** it completes, **then** the live Fly app serves the polished site and every published path still returns 200 (the site stayed complete + live).
6. **Given** the rendered HTML, **when** validated, **then** it has no malformed-markup errors.

## Dependencies & risks { id="ec5-risks" }

- **Depends on:** ec.4 (the live site).
- **Risk — asset provenance (the SIGNATURE invariant):** the externalized `app.css`/`app.js` must be **byte-equivalent** to the ec.4-HEAD inline `<style>`/`<script>` bodies (themselves verbatim from the published markup). Proof: extract the pre-edit blocks from `git show HEAD:web/templates/layout.html` + `…/pages/index.html`, concatenate, `diff` against the new files → empty. A non-empty diff (a reflow, a minify, a stray byte) BLOCKS — it would silently change the look. This is the rung's signature test.
- **Risk — cache invalidation:** the **content-hash route** (D-1: `/static/app.<sha256-8>.css`, `Cache-Control: …immutable`) ties the URL to the bytes, so a redeploy with changed bytes serves a new URL — no stale-style window. (Not a `?v=` query string, which some CDNs ignore.)
- **Risk — a dead deploy-config key:** `CANONICAL_BASE` (D-2) must be CONSUMED (`os.Getenv`/`envOr` → the rendered canonical/`og:url`), not merely declared — verify by flipping it for one local run and confirming the head reflects it (the runtime-config-consumed reconcile class).
