# echo-valkey — the Valkey node

The **Valkey 9.1** node for the BCS stack: a private, single-machine cache + bus,
reached over the 6PN at `echo-valkey.internal:6390`. This file covers the node's
specifics; the generic create → disk → secrets → deploy → verify lifecycle (and the
private-by-design rules) lives in [`../README.md`](../README.md).

## Image and password

- **Official `valkey/valkey:9.1` image** (`Dockerfile`, `ARG VALKEY_VERSION=9.1`) —
  **not** a from-source build. It already ships the bundled jemalloc (which
  `activedefrag` requires), carries the current security patches, and its entrypoint
  chowns the mounted volume and drops from root to the `valkey` user. The tuned
  `conf/valkey.conf` is layered on; `CMD` runs `valkey-server /usr/local/etc/valkey/valkey.conf`.
  (A from-source build is kept in `docs/echo-valkey.Dockerfile` for the benchmark
  bench — it is not the deploy image.)
- **The password rides `VALKEY_EXTRA_FLAGS`, not `VALKEY_PASSWORD`.** The entrypoint
  appends those flags after the config file and a CLI flag overrides the file, so
  `requirepass` takes effect with the secret never present in any image layer:

  ```bash
  fly secrets set -a echo-valkey \
    VALKEY_EXTRA_FLAGS="--requirepass $(openssl rand -hex 32)"
  ```

  The consuming app authenticates with that same password in its connection config.

## Conf choices — `conf/valkey.conf` (shared-cpu-2x / 1 GB)

- **`maxmemory 512mb` + `noeviction`** — half the box, leaving the rest for the
  AOF-rewrite fork's copy-on-write, jemalloc fragmentation, and the OS. Eviction off
  means hitting the cap refuses writes (a loud error to alert on) rather than dropping
  a leaderboard entry or a queued job. Live state sits far below this — mostly a ceiling.
- **`io-threads 1`** — the deliberate non-default. Extra I/O threads only help
  network-bound loads; this is command-bound, so the second vCPU is left for background work.
- **`appendonly yes` / `appendfsync everysec` / `save ""`** — AOF is the ~1s loss
  bound; disabling RDB save points leaves a *single* fork source (the AOF rewrite)
  competing for the second vCPU and the volume, not two.
- **`lazyfree-* yes` + `activedefrag yes`** — the background work the second core
  absorbs: big-key frees off the main thread, and incremental defrag to claw back
  fragmentation over a long uptime (needs the bundled jemalloc the image provides).
- **`maxmemory-clients 64mb` + pub/sub buffer limits** — on a 1 GB box a stuck RESP3
  tracking subscriber or slow consumer can't balloon memory; the runaway client is dropped first.

The conf binds the wildcard on **port 6390** and writes its AOF to **`/data`** (the
mounted `valkey_data` volume). No TLS — the 6PN is the trust boundary.

## Deploy (prod)

Private by construction — no public IP (see [`../README.md`](../README.md)). In short:

```bash
fly apps create echo-valkey
fly volumes create valkey_data --size 3 --region fra -a echo-valkey
fly secrets set -a echo-valkey VALKEY_EXTRA_FLAGS="--requirepass $(openssl rand -hex 32)"
fly deploy -a echo-valkey            # the Operator runs the deploy
```

## Staging / dev variants (`docs/`)

Alternate environment configs, deployed with `-c`:

- `docs/echo-valkey.fly.staging.toml` — `echo-valkey-staging`, performance-2x / 2 GB, sized for < 5000 simultaneous players.
- `docs/echo-valkey.fly.dev.toml` — `echo-valkey-dev`, shared-1x / 512 MB, scale-to-zero, **ephemeral** (no volume; restart = empty store, which is the point in dev).
- `docs/echo-valkey.Dockerfile` — the from-source build (bench only).

> ⚠️ **These two tomls predate the official-image prod cutover and carry their own
> drift** — they expose a **public `[[services]]` on port 6379** (prod is private on
> 6390), set `VALKEY_CONFIG` (which the current `Dockerfile` doesn't read — it hardcodes
> the conf path and copies only `conf/valkey.conf`), and use a `VALKEY_PASSWORD` secret
> (prod uses `VALKEY_EXTRA_FLAGS`). Reconcile them to the prod mechanism before using
> them — as written they are not wired to the as-built image.

## Observability

Grafana: alert on `used_memory` approaching 512 MB, and on CPU throttle/steal for the
machine — the two signals that you've outgrown either the cap or the shared CPU.
