---
title: "ec.1 — Echo v5 server scaffold"
id: echo-courses-1-scaffold
rung: ec.1
size: S
risk: NORMAL
status: Built
stands-on: "Echo v5.2.0 (vendored at go/echo)"
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
| **Where** | The module `github.com/fiberfx/echo-courses` at `go/echo-courses/`, depending on the vendored Echo v5 (`replace … => ../echo`); `cmd/`, `internal/`, `web/`, `content/`. |
| **Why** | A known-good base with the right idioms before any feature lands. |
| **How** | `echo.New()`, handlers taking `*echo.Context`, `e.Static`, an `http.Server` shutdown on signal. |

## Scope { id="ec1-scope" }

### In scope

- `go.mod` for `github.com/fiberfx/echo-courses` requiring `github.com/labstack/echo/v5` with `replace … => ../echo` (the vendored v5.2.0 snapshot); built `GOWORK=off`.
- `cmd/server/main.go`: `echo.New()`, recover + request-logger middleware, `GET /healthz` → 200, static serving of `web/static`, graceful shutdown on `SIGINT`/`SIGTERM`.
- Project layout: `cmd/server`, `internal/handler`, `internal/catalog`, `web/templates`, `web/static`, `content/`.
- A `Makefile`/`justfile` target to run and to build.

### Out of scope

- The `Renderer` and templates (ec.2), the catalog (ec.3), routes/pages (ec.4), assets/SEO (ec.5), packaging (ec.6).

## Specification { id="ec1-spec" }

`main.go` constructs the Echo instance, registers `middleware.Recover()` and `middleware.RequestLogger()`, mounts `web/static` under `/static`, and adds `GET /healthz`. Shutdown follows Echo **v5**'s actual pattern: `signal.NotifyContext` derives a context cancelled on `SIGINT`/`SIGTERM`, and `echo.StartConfig{Address, GracefulTimeout}.Start(ctx, e)` serves until that context is cancelled, then runs the server's graceful drain within `GracefulTimeout` (v5 has **no** `e.Shutdown` method — `StartConfig` owns the shutdown). Configuration (bind address, default `:1323`) comes from the environment with sane defaults. Handlers use `func(c *echo.Context) error` per v5.

## Acceptance criteria { id="ec1-acceptance" }

1. **Given** a fresh checkout, **when** `go build ./...` runs, **then** it compiles against `github.com/labstack/echo/v5`.
2. **Given** the running server, **when** `GET /healthz` is called, **then** it returns 200.
3. **Given** a file in `web/static`, **when** requested under `/static/...`, **then** it is served with the correct content type.
4. **Given** a running server, **when** it receives `SIGTERM`, **then** it stops accepting new connections and drains in-flight requests before exiting (no abrupt connection reset).
5. **Given** the layout, **when** inspected, **then** `cmd/server`, `internal/handler`, `internal/catalog`, `web/templates`, `web/static`, and `content/` exist.

## Dependencies & risks { id="ec1-risks" }

- **Depends on:** the vendored Echo v5.2.0 (`go/echo`).
- **v4→v5 API (confirmed against the vendored source):** v5 makes `Context` a struct (`*echo.Context`) not an interface; graceful shutdown is `echo.StartConfig{…}.Start(ctx, e)` driven by context cancellation, **not** `e.Start` + `e.Shutdown`; the request logger is `middleware.RequestLogger()`; the `Renderer` interface is `Render(c *echo.Context, w io.Writer, name string, data any) error` (the `*Context` moved to the front vs v4 — carried into ec.2).

## As built { id="ec1-as-built" }

The scaffold lives at `go/echo-courses/` and is green against all five criteria.

- **Module + framework.** `github.com/fiberfx/echo-courses` requires `github.com/labstack/echo/v5` with `replace … => ../echo`; `go mod tidy` resolves one indirect dep (`golang.org/x/time`, echo's rate-limiter). Built and tested `GOWORK=off`.
- **Server.** `cmd/server/main.go`: `newEcho(staticDir)` wires `middleware.Recover()` + `middleware.RequestLogger()`, `GET /healthz` (`internal/handler.Health`), and `e.Static("/static", staticDir)`; `run(ctx, …)` serves via `echo.StartConfig{…}.Start`; `main` derives the context from `signal.NotifyContext`. `ADDR` (`:1323`) and `STATIC_DIR` (`web/static`) are env-configurable.
- **Layout.** `cmd/server`, `internal/handler`, `internal/catalog` (reserved for ec.3), `web/templates` (ec.2), `web/static` (with `version.txt`), `content/` (ec.3).
- **Tests + gate.** `go test ./...` is green: healthz 200, static-file serving, and a graceful-drain integration test (an in-flight request completes after `SIGTERM`). `make gate` runs tidy + build + vet + test + gofmt-clean; a running-binary smoke test confirmed `/healthz` 200, `/static/version.txt` 200, and a clean exit-0 on `SIGTERM`.
