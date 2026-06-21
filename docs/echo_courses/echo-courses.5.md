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

> _On the already-live site, externalize the design-system CSS/JS/fonts to `web/static`, wire each course's interactive assets, and add per-page metadata, Open Graph, a sitemap, and robots — then redeploy, so the site indexes and caches like the published one while staying complete and live._

## Summary

The ec.4 site is live and styled (the layout's inline CSS). ec.5 moves the design system to `web/static` (fingerprinted/cache-headed), wires each course's interactive-element assets, and adds per-page `title`/`description`, Open Graph, `sitemap.xml`, and `robots.txt` — then redeploys. SEO and asset parity, with the site complete and live throughout.

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
| **How** | Lift the inline `<style>` to `web/static` (fingerprinted), link it from the layout; meta blocks driven by course data; the sitemap from the catalog; redeploy. |

## Scope { id="ec5-scope" }

### In scope

- Externalize the layout's inline design-system CSS (and any global JS/fonts) to `web/static`, fingerprinted/cache-headed, linked from the ec.2 layout — the rendered look is **byte-equivalent**, just cacheable.
- Each course's interactive-element assets served and wired so the interactions run.
- Per-page metadata: `title` + `description` (the index from the published `meta-description`; detail pages from the course summary), Open Graph (`og:title`/`description`/`url`/`image`), a canonical link per page.
- `GET /sitemap.xml` (the catalog's URLs: `/courses` + each course `Path`); `GET /robots.txt`.
- **Redeploy** the polished site to the Fly app; re-run the parity + a markup/no-broken-link check.

### Out of scope

- The production cutover of `jonnify.fly.dev` + rollback (ec.6).
- Re-hosting the deep course content (landings only).

## Specification { id="ec5-spec" }

The inline design-system CSS from ec.2's layout moves to a fingerprinted file under `web/static`, served by the ec.1 static handler and linked from the layout head — the rendered bytes match the published look, now cacheable. Detail pages include their course's interactive assets. The layout head renders `title` + `meta description` + Open Graph + a canonical from course data. A sitemap handler emits the catalog URLs; a robots handler emits a sane default. The image carries `web/static`; a redeploy ships it, and the parity battery + a markup/link check run against the deployed URL.

## Acceptance criteria { id="ec5-acceptance" }

1. **Given** the rendered index + a detail page, **when** compared to the published pages, **then** the design system is applied (now from `web/static`) and the layout matches (header, footer, card grid, filter) byte-equivalently.
2. **Given** a course page with interactive elements, **when** loaded, **then** its interactive assets load and the interactions run.
3. **Given** any page, **when** its head is inspected, **then** it has a correct `title`, `meta description`, Open Graph tags, and a canonical link; the index description matches the published `meta-description`.
4. **Given** `GET /sitemap.xml`, **then** it lists `/courses` + all five published course paths; **given** `GET /robots.txt`, **then** it returns a valid robots file.
5. **Given** the redeploy, **when** it completes, **then** the live Fly app serves the polished site and every published path still returns 200 (the site stayed complete + live).
6. **Given** the rendered HTML, **when** validated, **then** it has no malformed-markup errors.

## Dependencies & risks { id="ec5-risks" }

- **Depends on:** ec.4 (the live site).
- **Risk — asset provenance:** the externalized CSS must be byte-equivalent to the ec.2 inline styles (which are verbatim from the published markup) — confirm the look is unchanged.
- **Risk — cache invalidation:** fingerprint/version asset URLs so a redeploy doesn't serve stale styles.
