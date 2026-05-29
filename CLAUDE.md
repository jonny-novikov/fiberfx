# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Scope of this file

This repo is a Go workspace (`go.work`) holding several unrelated modules. **This file documents only the `jonnify` web server** — the interactive educational website served at `/edu`, `/school`, `/ege` — and how it is deployed to Fly.io via `fly.toml`. Other modules (`flyer`, `apps/gateway`, `apps/s3xplorer`, `datadog`, `hugot-memory`) are out of scope here.

The `jonnify` server is the **root module**: `main.go` + `go.mod` (`github.com/jonny-novikov/jonnify`, Go 1.25) + `Dockerfile` + `fly.toml`. It is a single-file Fiber v2 (`github.com/gofiber/fiber/v2`) app with no test suite and no other server packages.

## Architecture: it's a static file server, not a renderer

The entire server is `main.go`. There is **no templating, no rendering, no data layer, no database, no `embed.FS`, no `app.Static` mount**. Each page is a complete, pre-authored `.html` file on disk; the server maps a clean URL to a file and streams it with `c.SendFile(...)`.

Request flow for `/edu`, `/school`, `/ege` (the three are implemented identically via per-section closures `serveEdu`/`serveSchool`/`serveEge`):

1. Fiber matches the bare route (`GET /edu`) or the named route (`GET /edu/:name`).
2. The handler reads `c.Params("name")`; the bare route passes `""`.
3. Empty name → a **per-section default** (see table — note `/edu` is special).
4. Target path = `filepath.Join(<sectionDir>, name+".html")`.
5. **Path-traversal guard**: after `filepath.Clean`, the cleaned path must still be prefixed by `<sectionDir>`, else `403 {"error":"access denied"}`.
6. `os.Stat` existence check → `404 {"error":"<section> page not found: <name>"}` if missing.
7. Sets `Cache-Control: public, max-age=300, must-revalidate`, then `c.SendFile` (which handles `Last-Modified`/`If-Modified-Since` → 304 automatically).

### Route table

| URL | Serves | Default page (bare URL) |
|---|---|---|
| `/ege`, `/ege/:name` | `ege/<name>.html` | `ege/index.html` |
| `/edu`, `/edu/:name` | `edu/<name>.html` | **`edu/finances.html`** (default name is `finances`, NOT `index`) |
| `/school`, `/school/:name` | `school/<name>.html` | `school/index.html` |
| `/`, `/files`, `/health`, `/distr/*` | root landing, JSON distr listing, health JSON, tarball downloads | — |

Section directories are env-overridable (`EGE_DIR`, `EDU_DIR`, `SCHOOL_DIR`, also `INDEX_HTML`, `DISTR_DIR`); they default to the container paths `/app/ege`, `/app/edu`, `/app/school`. `PORT` defaults to `8080`. The server ends in `log.Fatal(app.Listen(...))` — there is no in-code graceful shutdown; Fly sends `SIGTERM` (the binary is PID 1).

**To add a new page:** drop `school/foo.html` (etc.) into the section dir. The `:name` route already serves any `<name>.html` — no `main.go` change is needed. On deploy it ships automatically because the `Dockerfile` copies whole section dirs (see below).

**To add a new top-level section** (e.g. `/future`): you must do BOTH (a) add a `serveX` closure + two `app.Get` registrations in `main.go`, and (b) add a `COPY future/ /app/future/` line to the `Dockerfile`. See the `future/` caveat.

## Content authoring model (what makes the site "interactive")

The content is ~58 hand-authored, dependency-light HTML pages. There is **no build step, no bundler, no npm, no CSS framework/preprocessor** — pages are served byte-for-byte. Treat each `.html` file as a self-contained unit.

Shared conventions across all pages:
- **Design system via CSS custom properties.** Every page opens its inline `<style>` with the same `:root` token palette (dark navy `--ink`, cream text, gold/blue/burgundy/sage accents, serif/sans/mono font stacks, radius/shadow tokens). Match these tokens when editing or adding pages.
- **Math** is rendered client-side by **KaTeX 0.16.9 loaded from jsDelivr CDN** with `auto-render` and `$...$` / `$$...$$` delimiters. Google Fonts are also CDN-loaded. No vendored assets.
- **JS is 100% vanilla**, inline at the bottom of each file. No React/Vue/htmx/Alpine; no Chart.js/D3/three.js.

Interactivity patterns, with the canonical file to copy from:
- **Basic/Advanced level toggle + scroll-reveal** (most common; school/future essays): buttons set `document.body.dataset.level`; CSS shows/hides by level; an `IntersectionObserver` reveals sections. Pattern lives in e.g. `school/*.html`.
- **Canvas 3D geometry viewer** (EGE stereometry, the richest interactivity): a hand-rolled `Scene3D` class (vector math, perspective projection, drag-to-rotate, `requestAnimationFrame`) in `ege/stereometria.html`; "atlas" pages add step-through solution controls (`bindStepControls`, `data-canvas`/`data-step`) — see `ege/zadanie-13-atlas.html`.
- **Slider-driven financial calculators + bespoke SVG charts** (EDU finances): `<input type=number>` paired with `<input type=range>` kept in sync, recomputing real formulas (compound interest, annuity, Rule-of-72) with `Intl.NumberFormat('ru-RU')`. Charts are generated as SVG strings, not a library. See `edu/finances-m2.html`, `edu/finances-m3.html`.
- **Self-grading quiz** with `localStorage` persistence: a `questions` array of inline JS objects drives render/grade/restart. Only example: `edu/finances-test.html`.

Content map: `edu/` = «Финансовая математика» (6-module finance course, `finances-m1..m6` + sub-sections + test); `ege/` = ЕГЭ profile-math prep (stereometry tasks 13–14, financial task 16); `school/` = «Сто лет школьной математики» (12-chapter essay series on Russian math education).

### Caveat: `future/` exists but is NOT served

The `future/` directory (the actively-developed AI-education series — all recent commits are `future: ...`) is **not routed in `main.go` and not copied by the `Dockerfile`**. Its pages internally link to `/future/...`, so those URLs currently 404 in production. Wiring it up requires both a route block in `main.go` and a `COPY future/ /app/future/` in the `Dockerfile` (see "add a new top-level section" above).

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

Two `Makefile` gotchas to be aware of:
- **`make run`/`make start` do NOT export `SCHOOL_DIR`**, so `/school/*` falls back to the `/app/school` default and 404s locally. To test `/school`, run directly with `SCHOOL_DIR` set.
- The Makefile default port is **8765**, not 8080.

Run directly (foreground, no Makefile), exercising all three sections:

```bash
GOWORK=off PORT=8765 INDEX_HTML=./index.html \
  EGE_DIR=./ege EDU_DIR=./edu SCHOOL_DIR=./school DISTR_DIR=./data \
  go run .
# then: curl localhost:8765/health ; open /edu /school /ege /ege/stereometria
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
- `[[http_service.checks]]` `GET /health` every 30s — **the `/health` route must keep returning 200 JSON or deploys/machines are marked unhealthy.**
- `kill_signal = "SIGTERM"`, `kill_timeout = 10`; VM `shared` CPU, 256 MB. No volumes/mounts — the app is stateless, all content baked into the image.

The `Dockerfile` is multi-stage (`golang:1.25-alpine` builder → `alpine:3.19` runtime) and bakes the served content into the image at the paths `main.go` defaults to:
- builds the static binary: `CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o jonnify .` (copies only `main.go` + `go.mod`/`go.sum`, so it's independent of the workspace);
- `COPY index.html /app/index.html`, `COPY ege/ /app/ege/`, `COPY edu/ /app/edu/`, `COPY school/ /app/school/` — **whole-directory copies**, so any new `.html` in these dirs ships on the next deploy with no Dockerfile edit;
- also cross-compiles the unrelated `flyer` CLI into download tarballs under `/app/distr/` (served via `/distr/*`); not relevant to the website but explains the second build stage.

Because the runtime image is what serves the site, **content changes are only live after `fly deploy`** (or a local run pointed at the repo dirs) — there is no hot reload.

## Key files

- `main.go` — the whole server (routing, the three `serve*` closures, guards, `/health`).
- `fly.toml`, `Dockerfile` — deployment + what ships into the image.
- `Makefile` — local dev driver (note the `GOWORK=off`, port 8765, and missing `SCHOOL_DIR` quirks above).
- `edu/`, `ege/`, `school/` — the served content. `future/` — authored but not yet served.
- Pattern anchors: `ege/stereometria.html` (canvas 3D), `ege/zadanie-13-atlas.html` (step controls), `edu/finances-m2.html` (calculators/SVG charts), `edu/finances-test.html` (quiz), any `school/*.html` (level toggle + scroll-reveal).
