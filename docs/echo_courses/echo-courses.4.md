---
title: "ec.4 — The live site (routes, URL parity, first deploy)"
id: echo-courses-4-routes
rung: ec.4
size: L
risk: NORMAL+
status: Reconciled — build-grade (routes); deploy-forward layered (ec.4 ships live)
stands-on: "ec.3"
---

# ec.4 — The live site { id="echo-courses-4-routes" }

> _Render the `/courses` index and the five course detail pages from the catalog, on the exact published paths, with the track filter, and deploy it to Fly — so every existing link keeps working and the first complete course site is live._

## Summary

The `/courses` index (hero, "5 deep dives", track filter, five cards) and the five detail pages, routed on their published paths (`/elixir`, `/redis-patterns`, `/echomq`, `/course/agile-agent-workflow`, `/bcs`) with `/courses/:slug` as the internal canonical. The filter narrows the grid by track. Packaged in a multi-stage image and **deployed to a Fly app** — the first complete, demoable live site (the production cutover of `jonnify.fly.dev` is ec.6).

## Rationale

This is the rung that makes the migration real and the one with the highest parity risk: the site is published, so the URLs are load-bearing. Rendering from the catalog gives the index and filter for free, but the routes must match the published paths exactly — an inconsistent set (`/elixir` but `/course/agile-agent-workflow`) that the catalog already carries — or bookmarks and inbound links break. Under the deploy-forward ladder this rung also **ships**: the layout already styles the pages (ec.2's inline design system), so deploying the routed catalog now yields a complete, live, parity-correct site and de-risks ec.6 to a routing flip.

## 5W + H { id="ec4-5wh" }

| | |
|---|---|
| **Who** | Platform; reader-facing — this is what visitors hit. |
| **What** | Handlers for the index and the five detail pages, on the published paths, with the track filter. |
| **When** | After ec.3; gates ec.5/ec.6. |
| **Where** | `internal/handler` (index + detail handlers) + new `web/templates/pages/index.html` and `web/templates/pages/course.html`, wired into `newEcho` in `cmd/server/main.go` (threading the loaded `*catalog.Catalog`). |
| **Why** | Serve the catalog as pages without breaking a single published URL. |
| **How** | An index handler rendering the catalog through the layout; detail handlers resolving a slug from the catalog; routes registered on the published paths; the filter client-side, mirrored by a `?track=` server path. |

## Scope { id="ec4-scope" }

### In scope

- `GET /courses` → the index: hero ("In-depth courses."), the "5 deep dives" stat, the track filter, and a card per catalog course in published order.
- The five detail routes on their **published paths**, each rendering its course through the layout: `/elixir`, `/redis-patterns`, `/echomq`, `/course/agile-agent-workflow`, `/bcs`.
- `/courses/:slug` as the internal canonical resolving through the catalog; the published paths map to the same render.
- The track filter: client-side narrowing of the rendered grid, mirrored by `GET /courses?track=<facet>` returning the filtered set.
- A 404 for an unknown slug.
- A multi-stage `Dockerfile` + `fly.toml` (internal port, `/healthz` check, `SIGTERM`, `kill_timeout` > the ec.1 graceful window); **deploy to a Fly app** (a new/staging app, NOT yet `jonnify.fly.dev`); verify every published path + `/healthz` on the deployed machine.

### Out of scope

- Design-system asset-file externalization, meta/Open Graph, sitemap (ec.5); the **production cutover** of `jonnify.fly.dev` + rollback (ec.6). (Deploy to a Fly app IS in scope — the live site.)
- Re-hosting the deep multi-page course content (the detail pages are landings — §7 decision 4).

## Specification { id="ec4-spec" }

The index handler passes the ordered catalog and the facet counts to the index template, which renders the hero, the filter (from the track index), and the card grid (from the card partial). Detail routes are registered for each published path and resolve their course from the catalog by slug, rendering the detail template (layout + course body). `/courses/:slug` resolves the same courses by slug and is treated as canonical; the published paths render identically (no redirect, to keep them first-class). The filter works client-side over the rendered cards and is mirrored server-side by `?track=` for no-JS and direct-link cases. An unknown slug returns 404 through Echo's error handler.

### Ground truth — the as-built seam (verified against the code) { id="ec4-ground" }

The catalog already carries everything the index and the routes need; ec.4 wires it. `internal/catalog.Course{Slug,Order,Title,Tracks,Facet,Summary,Path,Accent,Icon,Body}` and `Catalog{Courses []Course (ordered by Order), Facets []Facet{Label,Key,Count}}` are loaded fail-fast at boot (`internal/catalog/catalog.go`; `cmd/server/main.go:run` calls `catalog.Load(content.FS)` and **discards** the result — that discard is the ec.4 thread-in point). The renderer (`internal/render`) executes `layout.html` for the named page set and exposes `render.Card{Accent,Tags,Href,Icon,Eyebrow,Title,Summary}`. The layout's brand is `<a href="/">` and the route-tag reads `/courses`; the title is a `{{block "title" .}}` the detail page overrides.

Pinned from the golden master `html/index.html` (the parity ground truth — every figure quoted, never invented):

- **Card grid order == `Course.Order`.** The golden grid is elixir → redis-patterns → echomq → agile-agent-workflow → bcs, which is exactly `Order` 1…5. Criterion 1's "published order" is `Course.Order`.
- **Eyebrow == `strings.Join(Course.Tracks, " · ") + " · English"`.** The golden card eyebrow is `Elixir · BEAM · English`; the catalog carries `Tracks: [Elixir, BEAM]`. The trailing ` · English` is appended by the index handler (it is not a track).
- **Card `data-tags` == `strings.ToLower(Course.Facet)`.** The golden cards carry `data-tags="elixir"` / `"redis"` / `"echomq"` / `"agents"` / `"bcs"` — the single facet key, lower-cased — **not** the multi-track list. This is the pin that makes a chip (`data-tag="redis"`) filter its card; `card.Tags` is the facet key, equal to the matching `Facet.Key`.
- **The filter is a client-side `<script>`**, quoted verbatim from the golden master (it splits `data-tags` on a space and toggles the `.filter-hidden` class). ec.5 owns asset files, so for ec.4 this script rides **inline** in the index page template (the golden master itself inlines it). The verbatim source:

  ```js
  // Tag filtering for the course grid
  const fbar=document.querySelector('.filter-bar');
  if(fbar){
    const cards=[...document.querySelectorAll('.series-card')];
    fbar.addEventListener('click',e=>{
      const btn=e.target.closest('.filter-btn');if(!btn)return;
      fbar.querySelectorAll('.filter-btn').forEach(b=>{const on=b===btn;b.classList.toggle('active',on);b.setAttribute('aria-pressed',on)});
      const tag=btn.dataset.tag;
      cards.forEach(c=>{const show=tag==='all'||(c.dataset.tags||'').split(' ').includes(tag);c.classList.toggle('filter-hidden',!show)});
    });
  }
  ```

- **The index hero + section copy is the golden master's, not the ec.2 placeholder's.** Hero sub: _"Five English-language courses built on the jonnify design system: …"_; section mark `<span class="num">courses</span><span class="lbl">5 deep dives</span>`; `<h2>Choose a course</h2>`; `<p>All five are taught in English and open in any order. Filter by track below.</p>`. Quote these verbatim from `html/index.html` (the placeholder text — "The render path is live…" — is dropped).

### NO-INVENT API pins (verified in `go/echo` source) { id="ec4-api" }

- Path parameter accessor is **`c.Param("slug")`** (`go/echo/context.go:283`). There is **no `c.PathParam`** method — do not call it.
- Route parameters use the **`:`** token: register `/courses/:slug` (`go/echo/router.go:138`, `paramLabel = ':'`). Not `{slug}`.
- A 404 is **`echo.NewHTTPError(http.StatusNotFound, "…")`** — the constructor takes **two** args `(code int, message string)` (`go/echo/httperror.go:99`). Returning it routes through `DefaultHTTPErrorHandler`, which emits a JSON body with status 404 (`go/echo/echo.go:431`). Criterion 6 needs the **status**; a styled 404 page is ec.5, out of scope here.
- Query parameter is **`c.QueryParam("track")`** (`go/echo/context.go:337`).
- Handlers are `func(c *echo.Context) error`; render via `c.Render(http.StatusOK, "<page>.html", data)` (the registered `render.Renderer`, `internal/render/render.go:87`).

## Acceptance criteria { id="ec4-acceptance" }

1. **Given** `GET /courses`, **when** rendered, **then** it lists exactly the five published courses, in `Course.Order` (published) order, each with its eyebrow (`tracks · English`), title, summary, and a working "Open →" link to its `Course.Path`.
2. **Given** each published path (`/elixir`, `/redis-patterns`, `/echomq`, `/course/agile-agent-workflow`, `/bcs`), **when** requested, **then** it returns 200 and renders the matching course (resolved from the catalog by `Path`).
3. **Given** `/courses/:slug` for each of the five slugs, **when** requested, **then** it renders the same course as its published path (no redirect — both are first-class).
4. **Given** the index, **when** the filter facets are rendered, **then** they read All 5 / Elixir 1 / Agents 1 / Redis 1 / EchoMQ 1 / BCS 1 (the chip-order question is **F-A**, below), and clicking a facet narrows the grid to the cards whose `data-tags` (the facet key) match.
5. **Given** `GET /courses?track=Redis`, **when** requested, **then** the rendered grid contains only the course(s) whose facet matches `track`, **case-insensitively** against `Facet.Key` (so `?track=Redis`, `?track=redis`, and `?track=REDIS` are equivalent), and the matching chip renders active; `?track=all` or an absent/unknown `track` renders all five.
6. **Given** an unknown slug (`/courses/nope` or an unregistered single-segment path), **when** requested, **then** the server returns status **404** (via `echo.NewHTTPError(http.StatusNotFound, …)`).
7. **Given** the rendered index and detail pages, **when** a link checker crawls them, **then** every internal link resolves — including the topbar brand `href="/"` (so `/` MUST resolve; see **F-B** if the golden master is read as ambiguous) and every card `href` to its published path.
8. **Given** the multi-stage `Dockerfile`, **when** built and run locally, **then** the container serves `/courses` + all five published paths + `/healthz` 200.
9. **Given** `fly deploy`, **when** it runs, **then** it succeeds, the Fly health check passes, and every published path returns 200 on the deployed app (the parity battery against the deployed URL).

## Forks { id="ec4-forks" }

> Surfaced, not decided. The Director rules each with the Operator (`AskUserQuestion`) **before** the build; flipping the recommendation is a one-line change to the brief.

### F-A — facet-chip order { id="ec4-fa" }

The golden master's filter renders the chips as **All · Elixir · Agents · Redis · EchoMQ · BCS** (criterion 4 quotes this order). The ec.3 `Catalog.Facets` is built in **first-seen `Course.Order`** order — **All · Elixir · Redis · EchoMQ · Agents · BCS** (`buildFacets` walks the order-sorted courses). The card grid and the chip row are sorted by **different** keys in the golden master: the cards by `Order` (Agents 4th), the chips with Agents 2nd. No single `Course.Order` yields both. The tension is gate-4 (the catalog is the single source — chips should derive from `Catalog.Facets`) against gate-2 + criterion-4 (visual parity on the quoted chip order). The Director's ruling is carried as the brief's facet-order rule; the four candidate arms are laid out in the build brief (`echo-courses.4.prompt.md`, §F-A).

### F-B — `GET /` behaviour { id="ec4-fb" }

The golden master's topbar brand is `<a href="/">`, so `/` must resolve for gate-5 (no broken links). The published path table lists `/courses` as the index, not `/`. The golden master does not itself settle whether `/` is the index or a redirect to `/courses`. Recommendation: **register `GET /` to the same index handler as `GET /courses`** (both first-class, no redirect — mirroring the published-path/`:slug` treatment), so the brand link resolves and the index is reachable at both. The Director confirms.

### F-C — detail-page scope { id="ec4-fc" }

Each detail page renders the catalog body. The published deep courses (`html/elixir/**` etc.) are large multi-page sites; the recommendation (roadmap §7 decision 4) is a **landing** — the course intro, with the deep content staying served at its existing routes — not a re-host. This defines what a "complete course" detail page is and what the ec.6 cutover replaces. The Director rules it before the build.

## Dependencies & risks { id="ec4-risks" }

- **Depends on:** ec.3 (the catalog + content seed, built).
- **Risk — NORMAL+, URL parity:** the published paths are inconsistent and load-bearing; register them explicitly from each `Course.Path` (not a `/:slug` catch-all — `/course/agile-agent-workflow` is multi-segment and would collide), and assert each in the parity battery (criterion 2).
- **Risk — filter parity:** the published filter is client-side; the `?track=` mirror must produce the same membership (criteria 4/5). Port the filter `<script>` verbatim (do not re-author it).
- **Risk — chip-order vs catalog (F-A):** the published chip order differs from `Catalog.Facets`; resolve via the Director's F-A ruling before the build, and assert the chosen order in the parity battery.
- **Risk — the vendored-replace Docker build:** the `replace => ../echo` means the build context needs `../echo` (build from `go/` and `COPY echo/ echo-courses/`, or `go mod vendor`); build `GOWORK=off`.
- **Scope note — L-sized rung:** ec.4 now carries routes + parity **and** the first Fly deploy (deploy-forward). If that is too large for one rung, the deploy can split into a thin ec.4-deploy follow-on without changing the routes contract above.
