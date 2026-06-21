---
title: "ec.1 — Echo v5 server scaffold"
id: echo-courses-1-scaffold
rung: ec.1
size: S
risk: NORMAL
status: Draft
stands-on: "Echo v5"
---

# ec.1 — Echo v5 server scaffold { id="echo-courses-1-scaffold" }

> _Stand up a minimal Echo v5 server with static serving, a health check, graceful shutdown, and the project layout the later rungs fill in._

## Summary

A booting Echo v5 application: module, router, `/healthz`, static file serving, graceful shutdown on `SIGTERM`, and the directory layout for handlers, templates, static assets, and content. No course logic yet.

## Rationale

Every later rung needs a place to live and a server to attach to. Getting the scaffold right first — Echo v5 idioms (`*echo.Context`), a clean layout, graceful shutdown for a no-drop Fly deploy — means rungs `ec.2`–`ec.6` add features to a known-good base rather than reshaping the skeleton mid-flight.

## 5W + H { id="ec1-5wh" }

| | |
|---|---|
| **Who** | Platform; no reader-facing output yet. |
| **What** | An Echo v5 server with `/healthz`, static serving, graceful shutdown, and the project layout. |
| **When** | First; blocks everything. |
| **Where** | A Go module (`github.com/labstack/echo/v5`); `cmd/`, `internal/`, `web/`, `content/`. |
| **Why** | A known-good base with the right idioms before any feature lands. |
| **How** | `echo.New()`, handlers taking `*echo.Context`, `e.Static`, an `http.Server` shutdown on signal. |

## Scope { id="ec1-scope" }

### In scope

- `go.mod` on `github.com/labstack/echo/v5`.
- `cmd/server/main.go`: `echo.New()`, recover + request-logger middleware, `GET /healthz` → 200, static serving of `web/static`, graceful shutdown on `SIGINT`/`SIGTERM`.
- Project layout: `cmd/server`, `internal/handler`, `internal/catalog`, `web/templates`, `web/static`, `content/`.
- A `Makefile`/`justfile` target to run and to build.

### Out of scope

- The `Renderer` and templates (ec.2), the catalog (ec.3), routes/pages (ec.4), assets/SEO (ec.5), packaging (ec.6).

## Specification { id="ec1-spec" }

`main.go` constructs the Echo instance, registers `middleware.Recover()` and a request logger, mounts `web/static` under `/static`, and adds `GET /healthz`. Shutdown follows Echo v5's pattern: start in a goroutine, block on a signal channel, then call `e.Shutdown(ctx)` with a bounded timeout so in-flight requests drain. Configuration (bind address, default `:1323`) comes from the environment with sane defaults. Handlers use `func(c *echo.Context) error` per v5.

## Acceptance criteria { id="ec1-acceptance" }

1. **Given** a fresh checkout, **when** `go build ./...` runs, **then** it compiles against `github.com/labstack/echo/v5`.
2. **Given** the running server, **when** `GET /healthz` is called, **then** it returns 200.
3. **Given** a file in `web/static`, **when** requested under `/static/...`, **then** it is served with the correct content type.
4. **Given** a running server, **when** it receives `SIGTERM`, **then** it stops accepting new connections and drains in-flight requests before exiting (no abrupt connection reset).
5. **Given** the layout, **when** inspected, **then** `cmd/server`, `internal/handler`, `internal/catalog`, `web/templates`, `web/static`, and `content/` exist.

## Dependencies & risks { id="ec1-risks" }

- **Depends on:** Echo v5.
- **Risk — v4→v5 API drift:** v5 uses `*echo.Context` and the `echo/v5` import path; confirm the `Renderer` and middleware signatures against the v5 docs before ec.2.
