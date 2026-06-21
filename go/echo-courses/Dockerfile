# Dockerfile — echo-courses (the Echo v5 courses server, docs/echo_courses ec.4).
#
# BUILD CONTEXT IS go/  (the PARENT of this dir), not echo-courses/. The module
# consumes the vendored Echo via `replace github.com/labstack/echo/v5 => ../echo`,
# so the build needs BOTH ./echo and ./echo-courses inside the context. fly.toml
# sets the Dockerfile + context accordingly; the operator deploys manually from
# go/:
#
#   cd go && fly deploy -c echo-courses/fly.toml
#
# (D-4: deploy-ready, inspection-verified — NOT Docker-built in this rung.)

# ---- build stage ----
FROM golang:1.25-alpine AS builder

WORKDIR /src

# The vendored Echo (../echo per the replace) and the module itself. Copying the
# replace target first lets `go mod download` resolve it from the local path.
COPY echo/ ./echo/
COPY echo-courses/ ./echo-courses/

WORKDIR /src/echo-courses

# Hermetic build: echo-courses is NOT a go.work member (go/CLAUDE.md), so force
# GOWORK=off; CGO is off for a static binary on the slim runtime. Templates and
# course content are go:embed'd into the binary (web/embed.go, content/embed.go).
ENV GOWORK=off CGO_ENABLED=0 GOOS=linux
RUN go build -ldflags="-s -w" -o /out/server ./cmd/server

# ---- runtime stage ----
FROM alpine:3.19

RUN apk --no-cache add ca-certificates

WORKDIR /app

# The server binary (templates + content are embedded; only the filesystem-served
# static dir is copied — web/static is NOT embedded yet, ec.5 owns asset files).
COPY --from=builder /out/server /app/server
COPY echo-courses/web/static /app/web/static

# The server reads ADDR (the bind address) and STATIC_DIR from the environment;
# fly.toml sets ADDR=:8080 and STATIC_DIR defaults to web/static (relative to the
# /app workdir). EXPOSE documents the internal port the health check hits.
EXPOSE 8080

CMD ["/app/server"]
