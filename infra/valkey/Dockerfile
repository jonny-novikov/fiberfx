# syntax=docker/dockerfile:1
# =============================================================================
# echo-valkey — the dedicated Valkey datastore for EchoMQ + EchoCache.
#
# One image, many environments. The per-environment TUNING lives in conf/*.conf
# (prod / staging / dev), copied into the image; an environment selects one with
# the VALKEY_CONFIG env var (see fly.toml / fly.staging.toml / fly.dev.toml).
# SECRETS and INVARIANTS — the password (VALKEY_PASSWORD secret), the bind, the
# port, and the data dir — are injected at boot and never written into a conf
# file, so the conf files are safe to commit. Sizing can also be overridden per
# environment without a rebuild via VALKEY_IO_THREADS / VALKEY_MAXMEMORY /
# VALKEY_EXTRA_FLAGS (later flags win over the conf).
#
# Pinned to valkey/valkey 9.1 (data dir /data; the official image ships
# protected-mode OFF, which is exactly why a password is required — see below).
# =============================================================================
ARG VALKEY_VERSION=9.1
FROM valkey/valkey:${VALKEY_VERSION}

# the per-environment configs (no secrets inside)
COPY conf/ /usr/local/etc/valkey/

# boot wrapper: best-effort kernel hints, then exec valkey-server with the chosen
# conf plus the injected secret/invariants. Inline (heredoc) to keep the app small.
COPY <<'BOOT' /usr/local/bin/echo-valkey-boot
#!/bin/sh
set -u

# --- kernel hints for an in-memory store (best-effort; never blocks boot) -----
# THP OFF: with 2 MB pages, one copy-on-write byte during an AOF-rewrite fork
# forces a whole-page copy and a latency spike.
echo never > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
echo never > /sys/kernel/mm/transparent_hugepage/defrag  2>/dev/null || true
sysctl -w vm.overcommit_memory=1        2>/dev/null || true   # so fork() does not fail under COW
sysctl -w vm.swappiness=1               2>/dev/null || true   # a swapped page trades ns for ms
sysctl -w net.core.somaxconn=65535      2>/dev/null || true   # accept connection bursts
sysctl -w net.ipv4.tcp_max_syn_backlog=65535 2>/dev/null || true
ulimit -n 65536 2>/dev/null || true                           # one fd per connection

# --- which environment's tuning to load (default: prod) -----------------------
CONF="${VALKEY_CONFIG:-/usr/local/etc/valkey/valkey.prod.conf}"

# --- the password is required, even on the private 6PN (defense in depth) ------
: "${VALKEY_PASSWORD:?set it first:  fly secrets set VALKEY_PASSWORD=... -a <app>}"

# Invariants + secret injected here (never in a conf file). Optional env knobs
# are appended AFTER the conf so they override it (valkey-server: last flag wins).
set -- "$CONF" --bind "0.0.0.0 ::" --port 6379 --requirepass "$VALKEY_PASSWORD" --dir /data
if [ -n "${VALKEY_IO_THREADS:-}" ]; then set -- "$@" --io-threads "$VALKEY_IO_THREADS"; fi
if [ -n "${VALKEY_MAXMEMORY:-}" ];  then set -- "$@" --maxmemory  "$VALKEY_MAXMEMORY";  fi
if [ -n "${VALKEY_EXTRA_FLAGS:-}" ]; then set -- "$@" $VALKEY_EXTRA_FLAGS; fi
exec valkey-server "$@"
BOOT
RUN chmod +x /usr/local/bin/echo-valkey-boot

EXPOSE 6379
ENTRYPOINT ["/usr/local/bin/echo-valkey-boot"]
