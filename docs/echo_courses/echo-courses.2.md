---
title: "ec.2 — Templating engine & base layout"
id: echo-courses-2-templating
rung: ec.2
size: M
risk: NORMAL
status: Draft
stands-on: "ec.1"
---

# ec.2 — Templating engine & base layout { id="echo-courses-2-templating" }

> _Register Echo's `Renderer` with a Go template engine and extract the published site's shell — head, header, footer, and the reusable card and filter partials — into a base layout._

## Summary

Wire `html/template` behind Echo's `Renderer`, then lift the published HTML's shared structure into a base layout plus partials (header, footer, course card, track filter). Templates parse at boot and fail fast.

## Rationale

The published pages share one shell — the same head, the `jonnify · courses` header, the `(с) jonnify` footer, the design-system stylesheet — and repeat one card shape across the grid. Capturing that shell once as a layout, and the card and filter as partials, is what turns five hand-authored pages into a catalog-driven render. Echo plugs in any Go template engine through its `Renderer`; `html/template` is the standard-library, Renderer-native fit.

## 5W + H { id="ec2-5wh" }

| | |
|---|---|
| **Who** | Platform; the output is the page shell every course renders into. |
| **What** | An `echo.Renderer` over `html/template`, a base layout, and partials for header, footer, course card, and track filter. |
| **When** | After ec.1; precedes the catalog and routes. |
| **Where** | `web/templates` (layout + partials), `internal/render` (the Renderer). |
| **Why** | One shell, defined once, rendered for every page — and parsed at boot so a template error never reaches a reader. |
| **How** | Parse the template tree at startup; implement the v5 `Renderer` — `Render(c *echo.Context, w io.Writer, name string, data any) error` — or use the bundled `echo.TemplateRenderer`; set `e.Renderer`. |

## Scope { id="ec2-scope" }

### In scope

- An `echo.Renderer` implementation over `html/template`, parsing `web/templates/**` once at startup (fail fast on a parse error).
- A base layout carrying the head (design-system stylesheet link), the `jonnify · courses` header, and the `(с) jonnify` footer, extracted from the published HTML.
- Partials: course **card** (tag line, title, summary, "Open →" link) and the **track filter** control.
- A render path proven by one placeholder page.

### Out of scope

- Real course data (ec.3); the index and detail routes (ec.4); design-system asset files and SEO (ec.5).

## Specification { id="ec2-spec" }

`internal/render` parses the template tree at boot into a `*template.Template` and implements the v5 `echo.Renderer` interface — `Render(c *echo.Context, w io.Writer, name string, data any) error` — by executing the named template (or wraps `html/template` in the bundled `echo.TemplateRenderer`); `main.go` assigns it to `e.Renderer`. The base layout (`layout.html`) defines blocks for title, head-extras, and body; partials (`partials/card.html`, `partials/filter.html`) are defined templates the page templates invoke. The layout's header and footer are copied verbatim from the published markup so the chrome matches. A parse failure at startup aborts the boot with a clear error.

## Acceptance criteria { id="ec2-acceptance" }

1. **Given** the template tree, **when** the server boots, **then** all templates parse; a deliberately malformed template aborts startup with a named error rather than starting.
2. **Given** a placeholder page rendered through `c.Render`, **when** requested, **then** it returns 200 with the base layout's header and footer present in the output.
3. **Given** the rendered shell, **when** compared to the published page, **then** the header reads `jonnify · courses` and the footer reads `(с) jonnify`, and the design-system stylesheet is linked in the head.
4. **Given** the card partial with sample data, **when** rendered, **then** it produces a tag line, title, summary, and an "Open →" link.
5. **Given** the filter partial, **when** rendered, **then** it produces the facet controls (the labels are wired to data in ec.4).

## Dependencies & risks { id="ec2-risks" }

- **Depends on:** ec.1.
- **`Renderer` signature in v5 (confirmed against `go/echo/renderer.go`):** the interface is `Render(c *echo.Context, w io.Writer, name string, data any) error` — `c` is first and is a `*echo.Context` (v4 had it last and as an interface). The vendored `echo.TemplateRenderer` already implements this over an `html/template`-shaped `ExecuteTemplate`.
- **Risk — design-system coupling:** the layout links the stylesheet but the asset files arrive in ec.5; until then, style may be unstyled locally — acceptable for this rung.
