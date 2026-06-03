# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Scope of this file

This repo is a Go workspace (`go.work`) holding several unrelated modules. **This file documents only the `jonnify` web server** — the interactive educational website served at `/edu`, `/school`, `/ege`, `/future` — and how it is deployed to Fly.io via `fly.toml`. Other modules (`flyer`, `apps/gateway`, `apps/s3xplorer`, `datadog`, `hugot-memory`) are out of scope here.

The `jonnify` server is the **root module**: `main.go` + `go.mod` (`github.com/jonny-novikov/jonnify`, Go 1.25) + `Dockerfile` + `fly.toml`. It is a single-file Fiber v2 (`github.com/gofiber/fiber/v2`) app with no test suite and no other *server* packages. (The one extra package, `cmd/sitemap`, is a build-time generator — see "SEO" below — **not** compiled into the server binary; the `Dockerfile` builds only the root package.)

## Architecture: it's a static file server, not a renderer

The entire server is `main.go`. There is **no templating, no rendering, no data layer, no database, no `embed.FS`, no `app.Static` mount**. Each page is a complete, pre-authored `.html` file on disk; the server maps a clean URL to a file and streams it with `c.SendFile(...)`.

Request flow for `/edu`, `/school`, `/ege`, `/future` (the four are implemented identically via per-section closures `serveEdu`/`serveSchool`/`serveEge`/`serveFuture`):

1. Fiber matches the bare route (`GET /edu`) or the named route (`GET /edu/:name`).
2. The handler reads `c.Params("name")`; the bare route passes `""`.
3. Empty name → a **per-section default** (see table — note `/edu` is special).
4. Target path = `filepath.Join(<sectionDir>, name+".html")`.
5. **Path-traversal guard** (`resolveUnder`): the cleaned path must equal `<sectionDir>` or sit under it with a separator boundary — so `..` escapes *and* sibling-prefix paths like `/app/html/egevil` are rejected — else a `403`. Works with relative **and** absolute dirs (it cleans the dir too, so `./html/ege` is fine).
6. `os.Stat` existence check → a `404` if missing.
7. Sets `Cache-Control: public, max-age=300, must-revalidate`, then `c.SendFile` (which handles `Last-Modified`/`If-Modified-Since` → 304 automatically).

Steps 5–6 return their errors via `fiber.NewError`, which the **central `ErrorHandler`** renders (see "Error pages" below): a styled `error/<status>.html` for browsers, `{"error": "..."}` JSON for API clients.

### Route table

| URL | Serves | Default page (bare URL) |
|---|---|---|
| `/ege`, `/ege/:name` | `ege/<name>.html` | `ege/index.html` |
| `/edu`, `/edu/:name` | `edu/<name>.html` | **`edu/finances.html`** (default name is `finances`, NOT `index`) |
| `/school`, `/school/:name` | `school/<name>.html` | `school/index.html` |
| `/future`, `/future/:name` | `future/<name>.html` | `future/index.html` |
| `/elixir`, `/elixir/*` | `elixir/<path…>` — the **Elixir course**, a **folder-routed section** (the URL tree mirrors the filesystem; `/health` works identically): a wildcard route + `try_files`-style cascade (the shared `serveDirTree`) resolves a clean URL to `elixir/<path>/index.html` for **directories** (`/elixir`, `/elixir/algebra`), to `elixir/<path>.html` for **clean leaf URLs** (`/elixir/algebra/f1-01-functions`), or to an **exact co-located file** (e.g. an `.svg`, or a per-chapter **`llms.txt`** agent map — see the `/llms.txt` row). `ELIXIR_DIR` env-overridable, default `/app/elixir`. Path-traversal-guarded by the shared `resolveUnder` (a raw `..` segment in any path component → 403). | `elixir/index.html` |
| `/health`, `/health/*` | `health/<path…>` — the **Health course** («Здоровье как прикладная математика»), folder-routed like `/elixir` via `serveDirTree`: **chapters are directories** (`/health/son` → `health/son/index.html`) and **modules are files inside them** (`/health/son/pamyat` → `health/son/pamyat.html`), so the URL tree mirrors the on-disk tree. `HEALTH_DIR` env-overridable, default `/app/html/health`. **Note:** the machine liveness probe is the separate **`/healthz`** route (below), NOT this. | `health/index.html` |
| `/logic`, `/law`, `/physics`, `/ai-rabota` (+ each `/<section>/*`) | four more **folder-routed courses**, identical mechanics to `/elixir` & `/health` via the shared `serveDirTree` (**chapters are directories**, **modules are files inside them**, so the URL tree mirrors the on-disk tree): **Logic** («Логика и принятие решений», `LOGIC_DIR`, default `/app/html/logic`); **Law** («Право повседневной жизни», `LAW_DIR`, default `/app/html/law`); **Physics** («Электричество и устройства: школьная физика дома», `PHYSICS_DIR`, default `/app/html/physics`); **AI-at-work** («ИИ на работе: считать, проверять, автоматизировать», `AI_RABOTA_DIR`, default `/app/html/ai-rabota`). Path-traversal-guarded by the shared `resolveUnder`. | each section's `index.html` |
| `/` | `index.html` — lightweight, mobile-friendly landing **hub**: hero + a grid of **11 series cards** (school, school/geometria, future, edu/finances, ege, health, elixir, logic, law, physics, ai-rabota) plus a topic filter-bar, each card linking into its series. Pure HTML/CSS, **no WebGL**; links to `/map`. | — |
| `/map`, `/map/:name` | `map/<name>.html` — the **three.js WebGL orbital 3D node-graph** of all **five** series — school, наглядная геометрия (`/school/geometria`), future, edu, ege — and their topics (the heavy interactive map, moved here from `/`); loads vendored three.js from `/vendor/three/`. `MAP_DIR` env-overridable, default `/app/html/map`. The node dataset is inlined in `map/index.html` and mirrored by `apps/e2e/fixtures/nodes.json` (guarded by the `dataset-sync` e2e test). | `map/index.html` |
| `/game` | `game.html` — standalone emoji memory game (`GAME_HTML` env-overridable); not linked from the landing | — |
| `/sitemap.xml`, `/robots.txt` | SEO files **pre-generated** by `cmd/sitemap` (`make sitemap`) and baked into the image; served verbatim with explicit `Content-Type` (`application/xml` / `text/plain`). `SITEMAP_XML`/`ROBOTS_TXT` env-overridable, default `/app/html/sitemap.xml`, `/app/html/robots.txt`. The generator reproduces the clean-URL scheme (default page → bare `/<section>`, so e.g. `/edu/finances` is omitted in favour of `/edu`; elixir folder-routed). Re-run `make sitemap` after adding pages. | — |
| `/llms.txt` | **Hand-authored** markdown site map for LLMs/agents ([llmstxt.org](https://llmstxt.org) convention): H1 → blockquote summary → per-series `##` link-lists with **root-relative** URLs to every course hub + chapter. Served verbatim as `text/plain; charset=utf-8` (renders inline; agents read it raw). `LLMS_TXT` env-overridable, default `/app/html/llms.txt`. **NOT** produced by `cmd/sitemap` — edit `llms.txt` by hand when course/chapter structure changes. The **Elixir course additionally carries per-chapter maps**: `/elixir/llms.txt` (course index) and `/elixir/<chapter>/llms.txt` for each of the 7 chapter dirs (each chapter's full lesson tree, derived from page `<title>`+`<meta description>`). These are plain files committed under `elixir/`, served `text/plain` by **`serveDirTree`'s co-located-file branch** (not this route), and shipped by the whole-dir `COPY elixir/`. They are generated from page metadata by **`cmd/elixir-llms`** (run **`make elixir-llms`**) — re-run it after adding/renaming elixir lessons so the maps stay accurate (the `cmd/sitemap` pattern, but for the per-chapter llms.txt). | — |
| `/vendor/*` | self-hosted front-end modules (three.js) from the `html/assets/` dir (`VENDOR_DIR` env-overridable, default `/app/html/assets`); path-traversal-guarded; `.js` served as `text/javascript` | — |
| `/files`, `/healthz`, `/distr/*` | JSON distr listing; **`/healthz`** = machine liveness JSON `{"status":"ok",…}` (Fly's `[[http_service.checks]]` polls this — keep it 200 JSON; `/health` is a content section, above, not the probe); tarball downloads | — |
| _(any error)_ | central Fiber `ErrorHandler` renders `error/<status>.html` (`ERROR_DIR`, default `/app/html/error`) for browsers, JSON for API clients; covers unmatched-route 404s, handler 403/404s, and panics (500) | — |

Section directories are env-overridable (`EGE_DIR`, `EDU_DIR`, `SCHOOL_DIR`, `FUTURE_DIR`, `ELIXIR_DIR`, `HEALTH_DIR`, `LOGIC_DIR`, `LAW_DIR`, `PHYSICS_DIR`, `AI_RABOTA_DIR`, also `INDEX_HTML`, `DISTR_DIR`, `GAME_HTML`, `VENDOR_DIR`, `MAP_DIR`, `ERROR_DIR`, `SITEMAP_XML`, `ROBOTS_TXT`, `LLMS_TXT`); they default to the container paths `/app/html/ege`, `/app/html/edu`, `/app/html/school`, `/app/html/future` (plus `/app/html/health`, `/app/html/logic`, `/app/html/law`, `/app/html/physics` and `/app/html/ai-rabota` for the folder-routed Health, Logic, Law, Physics and AI-at-work courses, `/app/html/map` for the 3D map, `/app/html/error` for the error pages, and `/app/html/sitemap.xml` + `/app/html/robots.txt` for SEO, plus `/app/html/llms.txt` for the hand-authored llms.txt map). **The whole served site lives under `/app/html/` — mirroring the repo's `html/` dir — with exactly two exceptions kept at the container root: the Elixir course at `/app/elixir` (`ELIXIR_DIR`, repo `elixir/`) and the distr tarballs at `/app/distr` (`DISTR_DIR`, repo `data/`).** `PORT` defaults to `8080`. The server ends in `log.Fatal(app.Listen(...))` — there is no in-code graceful shutdown; Fly sends `SIGTERM` (the binary is PID 1).

### Error pages (`error/<status>.html`)

`fiber.New` is configured with a central **`ErrorHandler`**, and every failure funnels through it: unmatched routes (Fiber's auto-404), panics caught by the `recover` middleware (500), and the `fiber.NewError(code, msg)` values returned by the section / `/vendor` / `/distr` handlers (403/404). It **content-negotiates** via `c.Accepts`: browsers (`Accept: text/html`) get the styled `error/<status>.html`; `curl`, API clients, and the `/healthz` probe get `{"error": "..."}` JSON. Pages are read into memory once at startup (keyed by the status code parsed from the filename, restricted to `400`–`599`), then written with `c.Status(code).Send(...)` — deliberately **not** `c.SendFile`, which resets the status to `200`. To add a page, just drop `error/NNN.html` in (e.g. `429.html`) — no `main.go` change, same as adding a content page. Shipped today: `403`, `404`, `500`, `502`, `503`. **Caveat:** `502`/`503` are produced by Fly's *edge proxy* when the machine is down/unreachable — a running app cannot serve its own "I'm down" page, and `fly.toml` exposes no setting to override Fly's proxy error pages; those two ship for completeness/parity only.

**To add a new page:** drop `html/school/foo.html` (etc.) into the section dir. The `:name` route already serves any `<name>.html` — no `main.go` change is needed. On deploy it ships automatically because the `Dockerfile` copies whole section dirs (see below).

**To add a new top-level section** (e.g. a hypothetical `/blog`): you must do BOTH (a) add a `serveX` closure + two `app.Get` registrations in `main.go` (copy any existing `serve*` block — they are identical except for the dir var and the default-name special case), and (b) add a `COPY html/blog/ /app/html/blog/` line to the `Dockerfile` (the served site lives under `html/`, so the new section dir goes in `html/blog/`). For local dev also thread a `BLOG_DIR` var into the `Makefile`'s `start`/`run` recipes (pointed at `$(REPO_DIR)/html/blog`). The four flat sections (`/ege`, `/edu`, `/school`, `/future`) were all added this way. **`/elixir`, `/health`, `/logic`, `/law`, `/physics` and `/ai-rabota` are folder-routed instead:** rather than a flat `serve*` block + `:name` route, each registers a bare + `/<section>/*` wildcard route that delegates to the shared `serveDirTree(c, dir, sub, label)` helper (the `try_files`-style cascade: directory → `index.html`, else `<path>.html`, else exact file). To add another folder-routed section, just add two `app.Get` lines calling `serveDirTree` with its dir — no new closure needed.

## Content authoring model (what makes the site "interactive")

The content is ~58 hand-authored, dependency-light HTML pages. There is **no build step, no bundler, no npm, no CSS framework/preprocessor** — pages are served byte-for-byte. Treat each `.html` file as a self-contained unit.

The "no libraries / 100% vanilla" rule below applies to the ~58 content pages **and to the lightweight root `index.html`** (the `/` landing hub is pure HTML/CSS — no libraries). **It is partially superseded for `map/index.html` (served at `/map`) only:** that page uses **three.js 0.169.0** (`three.module.js` + the `examples/jsm` addons `OrbitControls` and `CSS2DRenderer`) to render the WebGL orbital 3D node-graph, wired via an **import map**. three.js is **vendored and self-hosted** under `assets/three/` and served same-origin at `/vendor/three/*` (lazy-imported on the first series dive). It is NOT loaded from a CDN — self-hosting removes the runtime third-party single-point-of-failure (a CDN outage cannot break the 3D map). The dir is named `assets/`, NOT `vendor/`, because a `vendor/` directory at the Go module root is reserved by the toolchain. The three.js exception is scoped to `map/index.html`; every other page (including the root landing) remains 100% vanilla with no libraries.

Shared conventions across all pages:
- **Design system via CSS custom properties.** Every page opens its inline `<style>` with the same `:root` token palette (dark navy `--ink`, cream text, gold/blue/burgundy/sage accents, serif/sans/mono font stacks, radius/shadow tokens). Match these tokens when editing or adding pages.
- **Math** is rendered client-side by **KaTeX 0.16.9 loaded from jsDelivr CDN** with `auto-render` and `$...$` / `$$...$$` delimiters. Google Fonts are also CDN-loaded. No vendored assets.
- **JS is 100% vanilla**, inline at the bottom of each file. No React/Vue/htmx/Alpine; no Chart.js/D3. The sole library exception is three.js, used only by `map/index.html` (the `/map` orbital map; see the note above); the root landing and the content pages use no libraries.

Interactivity patterns, with the canonical file to copy from:
- **Basic/Advanced level toggle + scroll-reveal** (most common; school/future essays): buttons set `document.body.dataset.level`; CSS shows/hides by level; an `IntersectionObserver` reveals sections. Pattern lives in e.g. `school/*.html`.
- **Canvas 3D geometry viewer** (EGE stereometry, the richest interactivity): a hand-rolled `Scene3D` class (vector math, perspective projection, drag-to-rotate, `requestAnimationFrame`) in `ege/stereometria.html`; "atlas" pages add step-through solution controls (`bindStepControls`, `data-canvas`/`data-step`) — see `ege/zadanie-13-atlas.html`.
- **Slider-driven financial calculators + bespoke SVG charts** (EDU finances): `<input type=number>` paired with `<input type=range>` kept in sync, recomputing real formulas (compound interest, annuity, Rule-of-72) with `Intl.NumberFormat('ru-RU')`. Charts are generated as SVG strings, not a library. See `edu/finances-m2.html`, `edu/finances-m3.html`.
- **Self-grading quiz** with `localStorage` persistence: a `questions` array of inline JS objects drives render/grade/restart. Only example: `edu/finances-test.html`.

Content map: `edu/` = «Финансовая математика» (6-module finance course, `finances-m1..m6` + sub-sections + test); `ege/` = ЕГЭ profile-math prep (stereometry tasks 13–14, financial task 16); `school/` = «Сто лет школьной математики» (essay series on Russian math education) **plus the «Курс наглядной геометрии» course** (`geometria` hub + ~10 M-numbered chapters + profession deep-dives, all served at `school/<slug>`), which the `/map` graph surfaces as its own 5th series; `future/` = the actively-developed AI-education series (LLMs, transformers, formal logic, functional programming — all recent commits are `future: ...`). Its pages internally link to `/future/<name>` clean routes.

## Build / run locally

**`GOWORK=off` is mandatory** for any `go` command on this server. The workspace `go.work` references uninitialized submodules (`atlas`, `pgroll`, `tbls`, `imgkit`), so a plain `go build` inside the workspace fails. The `Makefile` exports `GOWORK=off` for you.

```bash
make build      # GOWORK=off go build -o bin/jonnify .
make run        # build + run in FOREGROUND on port 8765
make start      # build + run in BACKGROUND (PID -> bin/jonnify.pid, logs -> bin/jonnify.log)
make stop       # stop background process via PID file
make restart    # stop + rebuild + start (fresh binary)
make status     # show running / not running
```

The `Makefile`'s `start`/`run` recipes export all four section dirs (`EGE_DIR`, `EDU_DIR`, `SCHOOL_DIR`, `FUTURE_DIR`) plus `INDEX_HTML`/`DISTR_DIR`, all pointed at the in-repo dirs — so every route works locally with no extra setup. One gotcha: the Makefile default port is **8765**, not 8080.

Run directly (foreground, no Makefile), exercising all four sections:

```bash
GOWORK=off PORT=8765 INDEX_HTML=./html/index.html \
  EGE_DIR=./html/ege EDU_DIR=./html/edu SCHOOL_DIR=./html/school FUTURE_DIR=./html/future DISTR_DIR=./data MAP_DIR=./html/map ERROR_DIR=./html/error \
  go run .
# then: curl localhost:8765/healthz ; open /health /edu /school /ege /ege/stereometria /future
```

There are **no tests, lint config, or format hooks** for this module. Manual: `gofmt -w main.go`, `go vet .`.

## Deploy via fly.toml

Deployment is **manual only**: from the repo root (where `fly.toml` + `Dockerfile` live):

```bash
fly deploy
```

There is no CI/CD (no `.github/workflows`). The `README.md` claims auto-deploy on push to `deploy/v8` — that is **stale/false**; trust `fly.toml`, which states deploy is manual.

`fly.toml` essentials (app `jonnify`, region `fra`):
- `[build] dockerfile = "Dockerfile"` (Docker build, not buildpacks).
- `[http_service]` `internal_port = 8080` (matches `PORT` env + `EXPOSE 8080`), `force_https = true`, `auto_stop_machines`/`auto_start_machines` with `min_machines_running = 1` (one warm machine, never fully cold), request concurrency soft/hard 200/250.
- `[[http_service.checks]]` `GET /healthz` every 30s — **the `/healthz` route must keep returning 200 JSON or deploys/machines are marked unhealthy.** (The `/health` path is the folder-routed Health course, not the probe.)
- `kill_signal = "SIGTERM"`, `kill_timeout = 10`; VM `shared` CPU, 256 MB. No volumes/mounts — the app is stateless, all content baked into the image.

The `Dockerfile` is multi-stage (`golang:1.25-alpine` builder → `alpine:3.19` runtime) and bakes the served content into the image at the paths `main.go` defaults to:
- builds the static binary: `CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o jonnify .` (copies only `main.go` + `go.mod`/`go.sum`, so it's independent of the workspace);
- `COPY html/index.html /app/html/index.html`, `COPY html/game.html /app/html/game.html`, `COPY html/sitemap.xml`/`robots.txt` (SEO, pre-generated), `COPY html/llms.txt /app/html/llms.txt` (the hand-authored llmstxt.org site map), `COPY html/ege/ /app/html/ege/`, `COPY html/edu/ /app/html/edu/`, `COPY html/school/ /app/html/school/`, `COPY html/future/ /app/html/future/`, `COPY html/map/ /app/html/map/` (the 3D orbital map), `COPY elixir/ /app/elixir/` (the one section kept OUTSIDE `html/`), `COPY html/health/ /app/html/health/`, `COPY html/logic/ /app/html/logic/`, `COPY html/law/ /app/html/law/`, `COPY html/physics/ /app/html/physics/`, `COPY html/ai-rabota/ /app/html/ai-rabota/` (folder-routed Elixir, Health, Logic, Law, Physics and AI-at-work courses), `COPY html/error/ /app/html/error/` (styled HTML error pages), `COPY html/assets/ /app/html/assets/` (vendored three.js) — **whole-directory copies** for the section dirs, so any new `.html` in them ships on the next deploy with no Dockerfile edit (but **re-run `make sitemap`** so new pages enter `sitemap.xml`, which is a single generated file, not a dir);
- also cross-compiles the unrelated `flyer` CLI into download tarballs under `/app/distr/` (served via `/distr/*`); not relevant to the website but explains the second build stage.

Because the runtime image is what serves the site, **content changes are only live after `fly deploy`** (or a local run pointed at the repo dirs) — there is no hot reload.

## Key files

- `main.go` — the whole server (routing, the four flat `serve*` closures + the shared `serveDirTree` helper for the folder-routed `/elixir`, `/health`, `/logic`, `/law`, `/physics` and `/ai-rabota` sections, the `resolveUnder` traversal guard, the central `ErrorHandler` + `renderError`/`loadErrorPages`, `/healthz` (JSON probe), `/sitemap.xml` + `/robots.txt` + `/llms.txt`).
- `cmd/sitemap/main.go` — **build-time** sitemap.xml + robots.txt generator (run via `make sitemap`); walks the content dirs and reproduces the clean-URL scheme. NOT part of the server binary. `sitemap.xml` / `robots.txt` — its generated output, committed under `html/` and `COPY`'d into the image.
- `cmd/elixir-llms/main.go` — **build-time** generator (run via `make elixir-llms`) for the per-chapter `elixir/<chapter>/llms.txt` agent maps (+ course-root `elixir/llms.txt`); derives each chapter's lesson tree from page `<title>`/`<meta description>` in hub-link (pedagogical) order. NOT part of the server binary; its output is committed under `elixir/` and served as `text/plain` by `serveDirTree`. Re-run after adding/renaming elixir lessons.
- `html/llms.txt` — **hand-authored** ([llmstxt.org](https://llmstxt.org)) markdown map of the whole site for LLMs/agents: the eleven course series + their chapters as **root-relative** links, each with a one-line "what it's about". Committed under `html/`, `COPY`'d into the image, served at `/llms.txt` (`text/plain; charset=utf-8`). Unlike `sitemap.xml` it is **not generated** — update it by hand when adding or renaming courses/chapters.
- `fly.toml`, `Dockerfile` — deployment + what ships into the image.
- `Makefile` — local dev driver (note the `GOWORK=off` and port 8765 quirks above); its `start`/`run` recipes export every section dir (the four flat sections plus the folder-routed Elixir/Health/Logic/Law/Physics/AI-at-work).
- `html/edu/`, `html/ege/`, `html/school/`, `html/future/` — the served content (the whole site lives under `html/`, except the `elixir/` course). `html/index.html` — the lightweight, mobile-friendly landing **hub** (root `/`): hero + series-card grid, pure HTML/CSS, links to `/map`. `html/map/index.html` — the heavy **three.js WebGL orbital 3D node-graph** served at `/map` (three.js 0.169.0 vendored under `html/assets/three/`, served same-origin at `/vendor/*`; carries the `window.__mindmap` test hook). `html/game.html` — standalone emoji game served at `/game`. `html/error/` — styled HTML error pages (`403/404/500/502/503.html`) rendered by the central `ErrorHandler`. `apps/e2e/` — Playwright+TS end-to-end suite that tests the `/map` 3D scene (modcard root + WebGL nodes); headless Chromium provides WebGL 2.0. Out of scope of the no-build static server; run via `npm test`.
- Pattern anchors: `html/ege/stereometria.html` (canvas 3D), `html/ege/zadanie-13-atlas.html` (step controls), `html/edu/finances-m2.html` (calculators/SVG charts), `html/edu/finances-test.html` (quiz), any `html/school/*.html` (level toggle + scroll-reveal).
