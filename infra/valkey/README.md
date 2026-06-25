# ValKey Fly.io deployment

## STAGING — echo-valkey-staging. Deploy with:  fly deploy -c fly.staging.toml

Sized for < 5000 simultaneous players; same durable posture as prod, smaller machine.

```bash
fly apps create echo-valkey-staging
fly volumes create valkey_staging_data --region fra --size 10 -a echo-valkey-staging
fly secrets set VALKEY_PASSWORD="$(openssl rand -base64 32)" -a echo-valkey-staging
fly deploy -c fly.staging.toml
```

Building from source (so you control the Valkey version and get the bundled jemalloc 5.3.0 your bench targets), tuned exactly for the constraints we discussed: single-threaded command loop, second vCPU reserved for background work, memory capped well under 1 GB, eviction off.Quick syntax check on the entrypoint, then presenting: Four files, a self-contained deploy folder (`Dockerfile` expects `conf/valkey.conf` and `docker-entrypoint.sh` beside it).

The choices that come straight from the `shared-cpu-2x` / 1 GB sizing:

- **`maxmemory 512mb` + `noeviction`** — half the box, leaving the rest for the AOF-rewrite fork's copy-on-write, jemalloc fragmentation, and the OS. With eviction off, hitting the cap refuses writes (a loud error to alert on) instead of dropping a leaderboard entry or a queued job. Your live state sits far below this, so it's mostly a safety ceiling.
- **`io-threads 1`** — the deliberate non-default. Extra I/O threads only help network-bound loads; yours is command-bound, so the second vCPU is left for background work instead.
- **`appendonly yes` / `appendfsync everysec` / `save ""`** — AOF is the ~1s loss bound, and disabling RDB save points means a *single* fork source (the AOF rewrite, with an RDB-preamble base) competing for that second vCPU and the volume, not two.
- **`lazyfree-* yes` + `activedefrag yes`** — the background work the second core absorbs: big-key frees off the main thread, and incremental defrag (gentle `cycle-max 25`) to claw back fragmentation over a long uptime.
- **`maxmemory-clients 64mb` + pub/sub buffer limits** — on a 1 GB box, a stuck RESP3 tracking subscriber or slow consumer can't balloon memory; the runaway client is dropped first.
- **Secret injection** — `requirepass` (and any `VALKEY_MAXMEMORY`/`VALKEY_PORT` override) come from env via the entrypoint, so nothing sensitive is in the image. CLI args override the conf.

The Dockerfile builds Valkey from source with `MALLOC=jemalloc` (the bundled 5.3.0 your bench targets), no TLS since the 6PN network is the trust boundary. `active-defrag` requires that jemalloc build, which this produces.

Deploy:

```bash
fly apps create echo-valkey
fly volumes create valkey_data --region fra --size 3 -a echo-valkey
fly secrets set VALKEY_PASSWORD="$(openssl rand -hex 32)" -a echo-valkey
fly deploy -a echo-valkey --build-arg VALKEY_VERSION=8.1.1
```

```bash
fly secrets set VALKEY_PASSWORD="<same value>" -a codemoji-phoenix
```

Pin `VALKEY_VERSION` to one of the tag on the [releases page](https://github.com/valkey-io/valkey/releases)

Grafana alert on `used_memory` approaching 512 MB and on CPU throttle/steal for the machine — the two signals that outgrown either the cap or the shared CPU.