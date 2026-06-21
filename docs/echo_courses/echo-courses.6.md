---
title: "ec.6 — Ship on Fly"
id: echo-courses-6-ship
rung: ec.6
size: S
risk: NORMAL
status: Draft
stands-on: "ec.1–ec.5"
---

# ec.6 — Ship on Fly { id="echo-courses-6-ship" }

> _Package the Echo server in a small image, deploy it on Fly, and cut the published course routes over to it with a health check and a rollback path._

## Summary

A multi-stage Dockerfile and a `fly.toml` that deploy the Echo v5 server on Fly, then a cutover of `jonnify.fly.dev`'s course routes to the new app, gated by a health check and reversible by rollback.

## Rationale

The site is already live on Fly, so shipping means a controlled cutover, not a fresh launch: the new app must serve every published path before traffic moves, the health check must reflect readiness, and there must be a one-step way back. A small static-Go image keeps the deploy fast and the surface minimal.

## 5W + H { id="ec6-5wh" }

| | |
|---|---|
| **Who** | Platform/operator. |
| **What** | A Dockerfile, a `fly.toml`, a deploy, and a cutover of the course routes with health check + rollback. |
| **When** | Last; stands on ec.1–ec.5. |
| **Where** | Fly app serving `jonnify.fly.dev` course routes. |
| **Why** | Replace the published static site with the Echo app, invisibly to visitors. |
| **How** | Multi-stage build → small runtime image; `fly.toml` with the internal port, `/healthz` check, and `SIGTERM`; deploy, verify, then move traffic; keep the prior release for rollback. |

## Scope { id="ec6-scope" }

### In scope

- A multi-stage `Dockerfile`: build the Go binary, copy it plus `web/` and `content/` into a small runtime image (distroless or alpine). Because Echo v5 is vendored via a local `replace … => ../echo`, the build stage must see `../echo` (build from the `go/` parent context, or pre-`go mod vendor`) and run `GOWORK=off`.
- A `fly.toml`: app name, `internal_port` matching the server bind, an HTTP health check on `/healthz`, `kill_signal = "SIGTERM"`, a `kill_timeout` covering graceful shutdown.
- Deploy; verify every published path on the deployed app before cutover.
- Cutover of `jonnify.fly.dev`'s course routes to the Echo app; a documented rollback (redeploy the prior release / revert the route).
- A smoke test run against the deployed URL.

### Out of scope

- Further performance work; CDN/edge config beyond Fly defaults.

## Specification { id="ec6-spec" }

The Dockerfile builds the binary in a Go stage and copies it with `web/static`, `web/templates`, and `content/` into a minimal runtime image (templates and content are embedded or copied; if embedded via `embed.FS`, only the binary ships). `fly.toml` sets the internal port to the server's bind address, an HTTP check on `/healthz`, and `SIGTERM` with a `kill_timeout` longer than the graceful-shutdown window from ec.1. Deploy creates/updates the app; a verification step requests every published path and `/healthz` against the deployed machine before any traffic move. Cutover points `jonnify.fly.dev`'s course routes at the Echo app; the prior release is retained so a rollback is a single redeploy.

## Acceptance criteria { id="ec6-acceptance" }

1. **Given** the Dockerfile, **when** built and run locally, **then** the container serves `/courses` and all five published paths and answers `/healthz` with 200.
2. **Given** `fly deploy`, **when** it runs, **then** it succeeds and the Fly health check on `/healthz` passes.
3. **Given** the deployed app, **when** every published path is requested, **then** each returns 200 and renders the right course (the parity battery, against the deployed URL).
4. **Given** a deploy under load, **when** the machine receives `SIGTERM`, **then** in-flight requests drain within `kill_timeout` (no dropped connections).
5. **Given** a failed or regressed release, **when** rollback is invoked, **then** the prior release is restored by a single documented step.
6. **Given** the cutover, **when** complete, **then** `jonnify.fly.dev/courses` and the five course paths are served by the Echo app.

## Dependencies & risks { id="ec6-risks" }

- **Depends on:** ec.1–ec.5.
- **Risk — cutover on a live domain:** verify all published paths on the deployed app before moving traffic (criterion 3), and keep the prior release for rollback (criterion 5).
- **Risk — embedded vs copied assets:** if using `embed.FS`, confirm templates and content are embedded; if copying, confirm the image includes `web/` and `content/`.
- **Risk — the vendored-replace build context:** the local `replace => ../echo` means a Docker build whose context is only `go/echo-courses/` cannot resolve Echo v5. Set the build context to `go/` (and `COPY echo/ echo-courses/`), or run `go mod vendor` so the image build is self-contained; build `GOWORK=off`.
