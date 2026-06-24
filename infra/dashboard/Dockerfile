# syntax=docker/dockerfile:1

# 1) Build the Svelte UI -> web/dist
FROM node:22-slim AS ui
WORKDIR /ui
COPY web/package.json web/package-lock.json* ./
RUN npm install
COPY web/ ./
RUN npm run build

# 2) Build the Go server, and build pgweb from source (pinned) as a dependency
FROM golang:1.23-bookworm AS build
WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
COPY --from=ui /ui/dist ./web/dist
RUN CGO_ENABLED=0 go build -trimpath -o /out/dashboard .
RUN CGO_ENABLED=0 GOBIN=/out go install github.com/sosedoff/pgweb@v0.16.2

# 3) Runtime: the dashboard binary supervises the pgweb binary
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build /out/dashboard /usr/local/bin/dashboard
COPY --from=build /out/pgweb     /usr/local/bin/pgweb
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/dashboard"]
