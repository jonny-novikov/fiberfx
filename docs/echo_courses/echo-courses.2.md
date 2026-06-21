---
title: "ec.2 — Templating engine & base layout"
id: echo-courses-2-templating
rung: ec.2
size: M
risk: NORMAL
status: Built
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

`internal/render` parses **one `*template.Template` per page** at boot from an **embedded** tree (`web/embed.go`, `//go:embed templates`) — each set is `layout.html` + `partials/*.html` + that page — and implements the v5 `echo.Renderer` interface `Render(c *echo.Context, w io.Writer, name string, data any) error` by `ExecuteTemplate(w, "layout.html", data)`. It is a **custom** renderer; the bundled `echo.TemplateRenderer` was chosen against — its flat `ExecuteTemplate` cannot do the layout/block override. `main.go` assigns it to `e.Renderer`. The base layout (`layout.html`) carries the head + a `{{block "content" .}}` that each page overrides via `{{define "content"}}`; `partials/card.html` (`{{define "card"}}`) and `partials/filter.html` (`{{define "filter"}}`) are invoked by the pages. The layout's head, header, and footer are copied **verbatim** from the published `html/index.html` so the chrome matches (the design system is carried as **inline `<style>`** there — carried inline now, externalized to `web/static` at ec.5). A parse failure at boot returns a named error and aborts startup.

## Acceptance criteria { id="ec2-acceptance" }

1. **Given** the template tree, **when** the server boots, **then** all templates parse; a deliberately malformed template aborts startup with a named error rather than starting.
2. **Given** a placeholder page rendered through `c.Render`, **when** requested, **then** it returns 200 with the base layout's header and footer present in the output.
3. **Given** the rendered shell, **when** compared to the published page, **then** the header reads `jonnify · courses` and the footer reads `(с) jonnify`, and the design-system styles are present in the head (inline, verbatim from the published markup; externalized at ec.5).
4. **Given** the card partial with sample data, **when** rendered, **then** it produces a tag line, title, summary, and an "Open →" link.
5. **Given** the filter partial, **when** rendered, **then** it produces the facet controls (the labels are wired to data in ec.4).

## Dependencies & risks { id="ec2-risks" }

- **Depends on:** ec.1.
- **`Renderer` signature in v5 (confirmed against `go/echo/renderer.go`):** the interface is `Render(c *echo.Context, w io.Writer, name string, data any) error` — `c` is first and is a `*echo.Context` (v4 had it last and as an interface). The vendored `echo.TemplateRenderer` already implements this over an `html/template`-shaped `ExecuteTemplate`.
- **Design-system coupling (resolved):** the published shell carries the design system as **inline `<style>`** (not a linked file), so the rendered pages are fully styled now; ec.5 externalizes the CSS to `web/static`. (The earlier "stylesheet link" framing was inaccurate — corrected at build.)

## As built { id="ec2-as-built" }

Shipped to ec.2 acceptance (5/5); gate green + a running-binary smoke (`GET /` 200 with the chrome).

- **Embed + render.** `web/embed.go` (`//go:embed templates` → `web.FS`); `internal/render.New(fsys fs.FS) (*Renderer, error)` parses one set per `templates/pages/*.html` (fail-fast — a named `render: …` error); `Render` executes `"layout.html"`. `newEcho` is now `(*echo.Echo, error)` — a parse error aborts the boot before binding.
- **Templates.** `layout.html` (head + the two inline `<style>` blocks verbatim + the `.topbar` header + `{{block "content" .}}` + the `<footer>` + the reveal script), `partials/{card,filter}.html`, `pages/placeholder.html`; `GET /` renders the placeholder (ec.4 supersedes it with the catalog index).
- **Realization — `render.Card.Accent` is `template.CSS`, not `string`.** `html/template` sanitizes a plain-string `var(--token)` inside a custom property to `ZgotmplZ` (a silent accent-drop); `template.CSS` (trusted, in-repo) emits it verbatim. Verified: the rendered card carries `--accent:var(--gold-bright)`, no `ZgotmplZ`.
- **Verified.** Independent gate (`GOWORK=off` build/vet/test + gofmt) green; 12 tests incl. fail-fast (AC1), the chrome at the HTTP boundary (AC2/AC3), card (AC4), filter 6-facet (AC5); a mutation spot-check (corrupt template → fail; drop the filter → fail, reverted net-zero) confirmed the tests have teeth.
