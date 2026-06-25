# bitmapist-server on a minimal Fly machine: Doist's roaring-bitmap store
# (github.com/Doist/bitmapist-server), built from source and run private on the
# 6PN network so the dashboard and markers reach it at <app>.internal:6400.
FROM golang:1.23-bookworm AS build
RUN CGO_ENABLED=0 go install github.com/Doist/bitmapist-server@latest

FROM debian:bookworm-slim
RUN useradd -r -u 10001 bitmapist && mkdir -p /data && chown bitmapist /data
COPY --from=build /go/bin/bitmapist-server /usr/local/bin/bitmapist-server
USER bitmapist
VOLUME ["/data"]
# Bind the 6PN interface (IPv6). The db file is memory-mapped on the volume;
# -bak names a separate file for a consistent snapshot on SIGUSR1.
CMD ["bitmapist-server", "-addr", "[::]:6400", "-db", "/data/bitmapist.db", "-bak", "/data/bitmapist.bak"]
