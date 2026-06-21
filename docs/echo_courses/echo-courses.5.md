---
title: "ec.5 — Design-system parity, assets & SEO"
id: echo-courses-5-assets-seo
rung: ec.5
size: M
risk: NORMAL
status: Draft
stands-on: "ec.4"
---

# ec.5 — Design-system parity, assets & SEO { id="echo-courses-5-assets-seo" }

> _Serve the jonnify design system and the interactive-element assets, and add per-page metadata, Open Graph, a sitemap, and robots — so the rendered site looks and indexes like the published one._

## Summary

Bring the jonnify design-system CSS/JS/fonts and each course's interactive assets under static serving, and add per-page `title`/`description`, Open Graph tags, `sitemap.xml`, and `robots.txt`. The rendered pages reach visual and SEO parity with the published site.

## Rationale

Routes without the design system are unstyled, and a migration that drops meta tags or the sitemap regresses how the site looks and how it is found. The published pages carry a specific look (the jonnify design system), interactive elements, and a descriptive index `meta-description`; parity means carrying all three across.

## 5W + H { id="ec5-5wh" }

| | |
|---|---|
| **Who** | Platform; reader- and crawler-facing. |
| **What** | Design-system + interactive assets under `/static`, per-page meta + Open Graph, `sitemap.xml`, `robots.txt`. |
| **When** | After ec.4; precedes ship. |
| **Where** | `web/static` (assets), the layout head (meta), handlers for sitemap/robots. |
| **Why** | Visual and SEO parity with the published site. |
| **How** | Vendor the design-system assets; add meta blocks driven by course data; generate the sitemap from the catalog. |

## Scope { id="ec5-scope" }

### In scope

- The jonnify design-system CSS/JS/fonts under `web/static`, linked by the ec.2 layout, so rendered pages match the published look.
- Each course's interactive-element assets served and wired so the interactions run.
- Per-page metadata: `title` and `description` (the index description is known from the published `meta-description`; detail pages use the course summary), plus Open Graph (`og:title`, `og:description`, `og:url`, `og:image`).
- `GET /sitemap.xml` listing `/courses` and every published course path; `GET /robots.txt`.
- A canonical link per page.

### Out of scope

- Deployment (ec.6); authoring new assets (existing assets are carried).

## Specification { id="ec5-spec" }

Design-system and interactive assets are placed under `web/static` and served by the ec.1 static handler; the layout links the stylesheet and any global scripts, and detail pages include their course's interactive assets. The layout head renders `title` and `meta description` from data — the index from the published catalog description, each detail page from its course summary — plus Open Graph tags and a canonical URL. A sitemap handler emits the catalog's URLs (`/courses` and each course `Path`); a robots handler emits a sane default. Asset paths are fingerprinted or cache-headed so a deploy invalidates correctly.

## Acceptance criteria { id="ec5-acceptance" }

1. **Given** the rendered index and a rendered detail page, **when** compared to the published pages, **then** the jonnify design system is applied and the layout matches (header, footer, card grid, filter).
2. **Given** a course page with interactive elements, **when** loaded, **then** its interactive assets load and the interactions run.
3. **Given** any page, **when** its head is inspected, **then** it has a correct `title`, a `meta description`, Open Graph tags, and a canonical link; the index description matches the published `meta-description`.
4. **Given** `GET /sitemap.xml`, **when** requested, **then** it lists `/courses` and all five published course paths.
5. **Given** `GET /robots.txt`, **when** requested, **then** it returns a valid robots file.
6. **Given** the rendered HTML, **when** validated, **then** it has no malformed-markup errors.

## Dependencies & risks { id="ec5-risks" }

- **Depends on:** ec.4.
- **Risk — asset provenance:** the design-system and interactive assets must come from the published site's source, not re-created, to guarantee visual parity (criteria 1/2).
- **Risk — cache invalidation:** fingerprint or version asset URLs so the ec.6 cutover doesn't serve stale styles.
