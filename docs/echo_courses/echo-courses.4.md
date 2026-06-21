---
title: "ec.4 — Routes & pages with URL parity"
id: echo-courses-4-routes
rung: ec.4
size: M
risk: NORMAL+
status: Draft
stands-on: "ec.3"
---

# ec.4 — Routes & pages with URL parity { id="echo-courses-4-routes" }

> _Render the `/courses` index and the five course detail pages from the catalog, on the exact published paths, with the track filter — so every existing link keeps working._

## Summary

The `/courses` index (hero, "5 deep dives", track filter, five cards) and the five detail pages, routed on their published paths (`/elixir`, `/redis-patterns`, `/echomq`, `/course/agile-agent-workflow`, `/bcs`) with `/courses/:slug` as the internal canonical. The filter narrows the grid by track.

## Rationale

This is the rung that makes the migration real and the one with the highest parity risk: the site is published, so the URLs are load-bearing. Rendering from the catalog gives the index and filter for free, but the routes must match the published paths exactly — an inconsistent set (`/elixir` but `/course/agile-agent-workflow`) that the catalog already carries — or bookmarks and inbound links break.

## 5W + H { id="ec4-5wh" }

| | |
|---|---|
| **Who** | Platform; reader-facing — this is what visitors hit. |
| **What** | Handlers for the index and the five detail pages, on the published paths, with the track filter. |
| **When** | After ec.3; gates ec.5/ec.6. |
| **Where** | `internal/handler` (index + detail), wired in `cmd/server`. |
| **Why** | Serve the catalog as pages without breaking a single published URL. |
| **How** | An index handler rendering the catalog through the layout; detail handlers resolving a slug from the catalog; routes registered on the published paths; the filter client-side, mirrored by a `?track=` server path. |

## Scope { id="ec4-scope" }

### In scope

- `GET /courses` → the index: hero ("In-depth courses."), the "5 deep dives" stat, the track filter, and a card per catalog course in published order.
- The five detail routes on their **published paths**, each rendering its course through the layout: `/elixir`, `/redis-patterns`, `/echomq`, `/course/agile-agent-workflow`, `/bcs`.
- `/courses/:slug` as the internal canonical resolving through the catalog; the published paths map to the same render.
- The track filter: client-side narrowing of the rendered grid, mirrored by `GET /courses?track=<facet>` returning the filtered set.
- A 404 for an unknown slug.

### Out of scope

- Design-system asset files, meta/Open Graph, sitemap (ec.5); deployment (ec.6).

## Specification { id="ec4-spec" }

The index handler passes the ordered catalog and the facet counts to the index template, which renders the hero, the filter (from the track index), and the card grid (from the card partial). Detail routes are registered for each published path and resolve their course from the catalog by slug, rendering the detail template (layout + course body). `/courses/:slug` resolves the same courses by slug and is treated as canonical; the published paths render identically (no redirect, to keep them first-class). The filter works client-side over the rendered cards and is mirrored server-side by `?track=` for no-JS and direct-link cases. An unknown slug returns 404 through Echo's error handler.

## Acceptance criteria { id="ec4-acceptance" }

1. **Given** `GET /courses`, **when** rendered, **then** it lists exactly the five published courses, in published order, each with its tag line, title, summary, and a working "Open →" link to its published path.
2. **Given** each published path (`/elixir`, `/redis-patterns`, `/echomq`, `/course/agile-agent-workflow`, `/bcs`), **when** requested, **then** it returns 200 and renders the matching course.
3. **Given** `/courses/:slug` for each of the five slugs, **when** requested, **then** it renders the same course as its published path.
4. **Given** the index, **when** the filter facets are rendered, **then** they read All 5 / Elixir 1 / Agents 1 / Redis 1 / EchoMQ 1 / BCS 1, and selecting a facet narrows the grid to that track.
5. **Given** `GET /courses?track=Redis`, **when** requested, **then** the returned set contains only the Redis-tracked course(s).
6. **Given** an unknown slug, **when** requested, **then** the server returns 404.
7. **Given** the rendered index and detail pages, **when** a link checker crawls them, **then** every internal link resolves.

## Dependencies & risks { id="ec4-risks" }

- **Depends on:** ec.3.
- **Risk — NORMAL+, URL parity:** the published paths are inconsistent and load-bearing; register them explicitly from the catalog's `Path`, and assert each in the parity battery (criterion 2).
- **Risk — filter parity:** the published filter is client-side; the `?track=` mirror must produce the same membership (criteria 4/5).
