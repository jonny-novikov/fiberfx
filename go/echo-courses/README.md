# echo-courses

An [Echo v5](https://echo.labstack.com/) server that rebuilds the published
`jonnify.fly.dev/courses` site from a course catalog and content files, with URL
and visual parity so nothing already published breaks.

The spec program lives at [`docs/echo_courses/`](../../docs/echo_courses/)
(roadmap + rungs `ec.1`–`ec.6`). This module is the implementation.

## Status

- **ec.1 — Echo v5 server scaffold: built.** Boot, `GET /healthz`, static
  serving under `/static`, graceful shutdown, and the project layout.
- ec.2–ec.6 (templating, catalog, routes + URL parity, design/SEO, ship on Fly)
  are pending; they build on `cmd/server/main.go`'s `newEcho` without reshaping
  it.

## The vendored framework

Echo **v5** has no published release, so the framework is vendored in-repo at
[`../echo`](../echo) (the **v5.2.0** snapshot) and consumed via a `replace`
directive in `go.mod`:

```
require github.com/labstack/echo/v5 v5.2.0
replace github.com/labstack/echo/v5 => ../echo
```

Because the dependency is a local path and the parent `go/go.work` spans only the
agent-OS modules, **always build with `GOWORK=off`** (the `Makefile` sets it).
Treat `../echo` as a read-only vendored snapshot — vendor from it, do not edit it.

## Run

```bash
make run                  # serves on :1323 by default
curl -s localhost:1323/healthz            # -> ok
curl -s localhost:1323/static/version.txt # -> the scaffold marker
```

Configuration (with defaults): `ADDR` (`:1323`), `STATIC_DIR` (`web/static`).

## Layout

```
cmd/server/        the main: newEcho (wiring) + run (serve + graceful drain)
internal/handler/  HTTP handlers (ec.1: Health)
internal/catalog/  the Course model + loader (ec.3)
web/templates/     base layout + partials (ec.2)
web/static/        design-system + interactive assets (ec.5)
content/           per-course content files (ec.3)
```

## Gate

```bash
make gate            # GOWORK=off: tidy + build + vet + test + gofmt-clean
```
