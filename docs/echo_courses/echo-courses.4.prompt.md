---
title: "ec.4 — the live site (ship prompt / x-mode runbook)"
id: echo-courses-4-prompt
rung: ec.4
mode: "Flat-L2, right-sized (Director + one mars); CONTINUES the in-flight ec-4 run"
risk: NORMAL+
vehicle: "generic x-mode (.claude/commands/x.md) — NOT /echo-mq-ship"
---

# ec.4 — ship prompt { id="echo-courses-4-prompt" }

## The rung in one paragraph

ec.4 makes the catalog a **live site**: `GET /courses` + `GET /` (D-2) → the index (hero, "5 deep dives", the track filter, 5 cards in `Course.Order`); the five detail routes on their published paths + `/courses/:slug` (render-identical, no redirect) → a course **landing** (D-3); a `?track=` server mirror; a 404 — all catalog-driven, styled by the ec.2 layout. Plus deploy-ready `Dockerfile` + `fly.toml`. **Verified via the local dev server (D-4), not Docker.**

## Authoritative sources

- **The build-grade spec:** `echo-courses.4.md` (the as-built seam §ec4-ground, the NO-INVENT API pins §ec4-api, ACs 1–9). Authoritative.
- **The run ledger:** `ec-4.progress.md` (T-1/T-2 derivation + reconcile; **D-1** facet_order, **D-2** GET /, **D-3** landing, **D-4** local-dev-server + deploy-ready; L-1 the escalation lesson).

## Settled (RULED — do not reopen)

- **D-1** facet-chip order = **PUBLISHED**, carried in the catalog via a `facet_order` field (elixir=1, agents=2, redis=3, echomq=4, bcs=5; the grid `Course.Order` stays 1..5). Add `FacetOrder int` to `catalog.Course` + `facet_order` to `courseMeta` + require it in `validate()`; `buildFacets` orders the non-All facets by `FacetOrder`; update `catalog_test.go` to expect `[All, Elixir, Agents, Redis, EchoMQ, BCS]`.
- **D-2** `GET /` → the SAME index handler as `GET /courses` (both first-class, no redirect).
- **D-3** detail page = a **landing** (`Course.Body`, the ec.3 intro); no deep-content migration; the ec.6 cutover must not shadow the deep routes.
- **D-4** verify via the **local dev server** (`make run` + the curl parity battery on localhost); **NO Docker testing**. The `Dockerfile` + `fly.toml` are deploy-ready artifacts (inspection-verified, adapted from the `go/` jonnify pattern); the Operator runs `fly deploy` manually.

## Build (Mars; inside `go/echo-courses` ONLY)

- **`internal/handler`** — an index handler (renders `Catalog.Courses` + `Facets` through the layout) + a detail handler (resolves a course via an explicit `path→course` map built from `Course.Path`; renders the landing). Wire into `newEcho` (thread the loaded `*catalog.Catalog` — `main.go:run` currently loads-and-DISCARDS it; that discard is the ec.4 seam). Register `GET /courses` + `GET /` + the five published paths + `/courses/:slug`; `?track=` (case-insensitive vs `Facet.Key`); 404 via `echo.NewHTTPError(http.StatusNotFound, …)`.
- **`internal/catalog`** — add `FacetOrder`/`facet_order` (D-1); update `buildFacets` + `catalog_test.go`; set `facet_order` in the five `content/<slug>.html`.
- **`web/templates/pages/index.html`** (hero + filter + card grid; the golden hero/section copy verbatim from `html/index.html`; the filter `<script>` verbatim, inline) + **`pages/course.html`** (the landing: layout + `Course.Body` + the eyebrow/title header).
- **`Dockerfile`** (multi-stage Go build; templates+content embedded, `COPY web/static`; the `replace => ../echo` needs `go/` as the build context or `go mod vendor`) + **`fly.toml`** (internal port, `/healthz` check, `SIGTERM`, `kill_timeout`). **Deploy-ready; do NOT Docker-test** (D-4).
- **NO-INVENT API pins** (verified in `go/echo`): `c.Param("slug")` (NOT `c.PathParam`); register `/courses/:slug` (the `:` token); `echo.NewHTTPError(code, msg)` (two args); `c.QueryParam("track")`; handlers `func(c *echo.Context) error`; `c.Render(200, "<page>.html", data)`.

## Gate (LOCAL DEV SERVER; `GOWORK=off`; from `go/echo-courses`)

- `make gate` (`go mod tidy` + `build` + `vet` + `test`; `gofmt` empty) — incl. the updated catalog facet_order test.
- **The local dev server + the URL-parity battery** (curl): `go build -o bin/server ./cmd/server; ADDR=:<port> ./bin/server`, then `/courses`, `/`, `/elixir`, `/redis-patterns`, `/echomq`, `/course/agile-agent-workflow`, `/bcs` each → 200 + the right course; `/courses/:slug` for each slug → the same render; `?track=Redis` → only the Redis course; an unknown slug → 404; `SIGTERM` → exit 0.
- A **link check** over the rendered index + detail pages (every internal link resolves, incl. the brand `href="/"`).
- `Dockerfile`/`fly.toml`: **inspection only** (valid; references the binary + `web/static` + `/healthz`). NO Docker build/run.

## Acceptance (echo-courses.4.md)

Criteria 1–7 (routes / parity / filter / 404 / links) verified via the **local dev server**; criterion 8 (the binary serves all paths — the local-dev-server equivalent of the container check); criterion 9 (`fly deploy`) = the Operator's manual completion (flyctl authed).

## Commit (LAW-4, scoped, Director-only)

`go/echo-courses` (the build) + `docs/echo_courses` (the ec.4 backward-reconcile + the `ec-4` ledger). `go/echo` is already tracked → no vendor commit. **Stage-6:** flip ec.4 status → Built; backward-reconcile `echo-courses.4.md` (an "As built" section; the local-dev-server/deploy posture); surface **ec.5**.
