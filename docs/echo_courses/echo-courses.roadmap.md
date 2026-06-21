---
title: "echo-courses — Roadmap"
id: echo-courses-roadmap
status: Draft
owner: Fireheadz
source: "https://jonnify.fly.dev/courses (published HTML)"
target: "Echo v5.2.0 — vendored at go/echo, consumed via replace"
---

# echo-courses — rebuild the courses site on Echo { id="echo-courses-roadmap" }

> _Rebuild the published `jonnify.fly.dev/courses` site — the index, the five course pages, the track filter, and the jonnify design system — on a Go Echo v5 server with a templating engine, so pages are generated from a course catalog and content files rather than hand-authored HTML, with URL and visual parity so nothing already published breaks._

## 1. Vision

The courses site is published as static HTML: a `/courses` index listing five deep-dive courses, each on its own page, filtered by track, styled by the jonnify design system. Editing it means hand-editing HTML, and the five course URLs are inconsistent (`/elixir`, `/redis-patterns`, `/echomq`, `/course/agile-agent-workflow`, `/bcs`).

`echo-courses` moves that site onto an Echo v5 server driven by a templating engine. The index and cards render from a course catalog; each course page renders a base layout around per-course content; the design system and interactive elements are served as assets. The migration's first obligation is parity — every published URL keeps resolving, and the rendered pages match the published look — so the cutover is invisible to anyone with a bookmark or a link.

**Every rung from ec.4 ships a complete, live course site.** The ladder is sliced **vertically**, not by layer: rather than "routes, then design, then deploy" (a site that only works at the end), each rung deploys a complete, demoable course site and the next rung makes it richer. ec.1–ec.3 are the foundation (the scaffold · the renderer · the catalog — shipped); from ec.4 on, every rung is end-to-end and shippable, so value is in users' hands at every step and the production cutover (ec.6) is the last small flip rather than a big-bang launch.

## 2. The published site (ground truth) { id="ground-truth" }

Five courses, taught in English, filterable by track, on the jonnify design system. Header reads `jonnify · courses`; footer reads `(с) jonnify`; the index advertises "5 deep dives".

| # | Title | Track tags | Published path |
|---|-------|-----------|----------------|
| 1 | Functional Programming | Elixir · BEAM | `/elixir` |
| 2 | Redis Patterns Applied | Redis · EchoMQ | `/redis-patterns` |
| 3 | EchoMQ in Depth | EchoMQ · protocol | `/echomq` |
| 4 | Agile Agent Workflow | Claude Agents · Portal | `/course/agile-agent-workflow` |
| 5 | Branded Component System | Identity · five runtimes | `/bcs` |

Index filter facets: **All (5)**, **Elixir (1)**, **Agents (1)**, **Redis (1)**, **EchoMQ (1)**, **BCS (1)**.

## 3. Program 5W + H { id="program-5wh" }

| | |
|---|---|
| **Who** | Platform (Fireheadz); audience is course readers arriving at published URLs. |
| **What** | An Echo v5 server that renders the courses index and the five course pages from a catalog + content files through a templating engine, preserving the published URLs, look, and interactive elements. |
| **When** | Sequenced `ec.1` → `ec.6`; ec.1–ec.3 foundation (shipped), then **every rung from ec.4 ships a complete, live site** (vertical slices, deployed each rung); parity gates from `ec.4` onward. |
| **Where** | The Go module `github.com/fiberfx/echo-courses` at `go/echo-courses/`, served behind the vendored Echo v5 (`go/echo`); deployed on Fly, cutting over `jonnify.fly.dev`'s course routes. |
| **Why** | Turn hand-edited HTML into catalog-driven pages — one place to add a course, consistent layout, server-rendered — without breaking any published link or changing the look. |
| **How** | Echo's `Renderer` seam with a Go template engine; a base layout + partials extracted from the published HTML; a course catalog loaded from content files; routes that preserve the published paths. |

## 4. Architecture { id="architecture" }

```mermaid
flowchart TB
    Req["GET /courses, /elixir, /bcs, ..."] --> Echo["Echo v5 router"]
    Echo --> H["handlers (internal/handler)"]
    H --> Cat["course catalog (internal/catalog)"]
    Cat --> Content[("content/*.html + front-matter")]
    H --> R["echo.Renderer (html/template)"]
    R --> Layout["web/templates: layout + partials\n(header, footer, card, filter)"]
    Echo --> Static["web/static: design-system CSS/JS, fonts, interactive assets"]
    R --> HTML["rendered course pages"]
```

The catalog is the single source for the index; the renderer wraps per-course content in the shared layout; the design system and interactive elements ride as static assets. Echo v5 handlers take `*echo.Context` and call `c.Render(...)`.

**The framework is vendored.** Echo v5 has no published release, so the framework is carried in-repo at `go/echo` (the **v5.2.0** snapshot) and consumed by `echo-courses` through a `replace github.com/labstack/echo/v5 => ../echo` directive in `go.mod`. Because the dependency is a local path and the workspace `go/go.work` spans only the agent-OS modules, `echo-courses` builds hermetically with `GOWORK=off` and is **not** a `go.work` member (the `go/CLAUDE.md` standalone-tool convention). `go/echo` is treated as a read-only vendored snapshot — vendored from, never edited.

## 5. Rungs { id="rungs" }

| Rung | Ships | Stands on | Size | Risk | Build topology |
|---|---|---|---|---|---|
| **ec.1** | Echo v5 server scaffold — module, `echo.New`, `/healthz`, static serving, graceful shutdown, project layout | Echo v5.2.0 (vendored) | **S** | **NORMAL** | Flat-L2 |
| **ec.2** | templating engine + base layout — register the `Renderer`; extract layout + partials (header/footer/card/filter) from the published HTML | ec.1 | **M** | **NORMAL** | Flat-L2 |
| **ec.3** | course catalog + content model — `Course` model, `content/*` with front-matter, a loader seeded with the five courses | ec.2 | **M** | **NORMAL** | Flat-L2 |
| **ec.4** | **the live site** — `/courses` index + the five detail routes on their published paths + the track filter, styled by the layout's design system, **deployed to Fly** (multi-stage Dockerfile + `fly.toml`); the first complete, demoable course site | ec.3 | **L** | **NORMAL+** (parity + first deploy) | Flat-L2 + parity battery |
| **ec.5** | **polish the live site** — externalize the design-system CSS/JS/fonts to `web/static` + per-course interactive assets; per-page meta, Open Graph, `sitemap.xml`, `robots.txt`; redeploy (still complete + live) | ec.4 | **M** | **NORMAL** | Flat-L2 |
| **ec.6** | **the production cutover** — point `jonnify.fly.dev`'s course routes at the deployed Echo app, verify every published path, one-step rollback; production smoke | ec.1–ec.5 | **S** | **HIGH** (live-domain cutover; Apollo) | Flat-L2 + Apollo |

**Status.** `ec.1`–`ec.3` are **built** at `go/echo-courses/` — ec.1 the scaffold, ec.2 the templating engine + base layout (the embedded `html/template` `Renderer`, the verbatim chrome, the card/filter partials), and ec.3 the course catalog + content model (the file-backed loader over `content/<slug>.html`, the five courses seeded in published order, fail-fast; all acceptance criteria green). `ec.4`–`ec.6` are specced as **deploy-forward vertical slices** — each ships a complete, live site (ec.4 the first live deploy of the index + five course pages, ec.5 polish + redeploy, ec.6 the production cutover of `jonnify.fly.dev`).

## 6. Sequencing { id="sequencing" }

```mermaid
flowchart LR
    ec1["ec.1 scaffold"] --> ec2["ec.2 templating"]
    ec2 --> ec3["ec.3 catalog"]
    ec3 --> ec4["ec.4 live site (deploy)"]
    ec4 --> ec5["ec.5 polish + redeploy"]
    ec5 --> ec6["ec.6 production cutover"]
```

## 7. Decisions to lock { id="decisions" }

Each is the recommended path; flipping any is a one-line change to the relevant rung.

1. **Templating engine — `html/template` (recommended) vs `templ`.** Echo plugs in any Go template engine. `html/template` is the standard-library, Renderer-native path and the lightest match for layout + partials + injected content. `templ` (a-h/templ) is the type-safe, compiled alternative if components and compile-time checks are wanted; it writes to the response writer rather than through the `Renderer`. Recommendation: `html/template` for the spine. **(RULED: `html/template`, embedded via `//go:embed` behind a custom `internal/render.Renderer` — ec.2.)**
2. **URLs — preserve published paths (recommended) vs normalize to `/courses/:slug`.** The site is published; links exist. Preserve `/elixir`, `/redis-patterns`, `/echomq`, `/course/agile-agent-workflow`, `/bcs` exactly, and add `/courses/:slug` as an internal canonical that the published paths map to. Normalizing instead would require 301s from every old path. **(RULED: preserve the published paths — ec.4.)**
3. **Content storage — Markdown + front-matter vs HTML partials vs structured Go.** Per-course `content/<slug>.html` with a YAML front-matter block (order, title, tracks, facet, summary, path, accent, icon) + an HTML body keeps the catalog declarative and matches the real (HTML) course bodies. **(RULED: HTML body + front-matter; `content/<slug>.html`; `yaml.v3`; no Markdown engine — ec.3.)**
4. **Detail-page scope — a course landing (recommended) vs the full course.** Each `/elixir`-style detail page renders the catalog body. The published deep courses (e.g. `html/elixir/**`) are large multi-page sites; the echo-courses detail page is a **landing** — the course intro, with the deep content staying served at its existing routes — not a re-host of the whole course (the "don't migrate deep content" non-goal). This defines what "complete course" means on a detail page and what the ec.6 cutover replaces. **To be ruled at ec.4's Stage-0.**

## 8. Cross-cutting acceptance gates { id="gates" }

Every rung is done only when, in addition to its own criteria:

1. **URL parity** — every published path (`/courses`, `/elixir`, `/redis-patterns`, `/echomq`, `/course/agile-agent-workflow`, `/bcs`) resolves with a 200 and renders the right course (enforced from `ec.4`).
2. **Visual parity** — rendered pages apply the jonnify design system and match the published header (`jonnify · courses`), footer (`(с) jonnify`), and layout.
3. **Fail-fast** — templates and content files parse at boot; a malformed template or missing course fails startup, never renders a half-page.
4. **Catalog is the single source** — the index, the filter counts, and the routes derive from the catalog; no course is listed in two places.
5. **No broken links** — internal links between the index and course pages resolve; a link checker over the rendered site is clean.
6. **Echo v5 idioms** — handlers take `*echo.Context`; rendering goes through the registered `Renderer`.
7. **Shippable each rung (from ec.4)** — the rung ends with the site **deployed to Fly and serving a complete course experience** (the index + all five course pages, styled, parity-correct), and a smoke test against the deployed URL passes. ec.1–ec.3 (foundation) are exempt; from ec.4 every rung is live + complete + demoable.

## 9. Non-goals { id="non-goals" }

- A CMS or admin UI (content is files in the repo).
- Authoring new course content (this migrates existing content).
- Re-hosting each course's deep multi-page content — the detail pages are **landings** into it; the deep content stays served at its existing routes (§7 decision 4).
- A database (the catalog is file-backed).
- Rewriting the design system (it is carried as assets).
- Client-side framework rewrites of the interactive elements (they are preserved as assets).

## 10. Glossary { id="glossary" }

- **Renderer** — Echo's `Renderer` interface; `c.Render(status, name, data)` writes a named template.
- **Layout / partial** — the shared page shell and the reusable fragments (card, filter, header, footer).
- **Catalog** — the in-memory list of `Course` records loaded from `content/`.
- **Slug** — a course's stable key (e.g. `elixir`, `bcs`); maps to its published path.
- **Track** — a course's tag facet (Elixir, Agents, Redis, EchoMQ, BCS) used by the filter.
- **Parity** — the migrated site resolves the same URLs and matches the published look.

## 11. References { id="references" }

- Published source — https://jonnify.fly.dev/courses
- Echo v5 — https://echo.labstack.com/ · quickstart https://echo.labstack.com/guide/quickstart/ · routing https://echo.labstack.com/guide/routing/
- Echo API (v5, upstream) — https://pkg.go.dev/github.com/labstack/echo/v5
- Vendored framework — `go/echo` (the Echo **v5.2.0** snapshot; consumed via `replace github.com/labstack/echo/v5 => ../echo`). The implementation module is `go/echo-courses`.
