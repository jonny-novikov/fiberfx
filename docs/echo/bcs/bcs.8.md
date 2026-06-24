# BCS · B8 — Production on Fly
<show-structure depth="2"/>

B8 takes Codemojex from a compiled umbrella to a running service, and shows the production shape from the inside. The chapter is served at `/bcs/fly`; its four dives at `/bcs/fly/the-release-and-the-image`, `/bcs/fly/valkey-on-a-fly-machine`, `/bcs/fly/echomq-setup-and-monitoring`, and `/bcs/fly/the-fly-config-and-the-local-stack`.

The build is a release: the Dockerfile compiles the `codemojex` app over `echo_mq`, `echo_data`, and `echo_wire`, makes the native branded-id codec, and packs `mix release codemojex` into a slim image — leaving `echo_store`, `echo_bot`, and `echo_graft` out, since the game does not depend on them. The queue's Valkey runs as its own Fly machine with an append-only log for a one-second loss bound and the kernel tuned away from its defaults. EchoMQ is wired into the supervision tree as a bus and a set of lane consumers, watched by queue depth and lease health. And the `fly.toml` ships it as machines under `codemoji-phoenix`, holding the endpoint on port 4000 so live sockets survive a deploy, with a docker compose that brings the same stack up locally.

Every artifact here is real and sits in the umbrella root: the multi-stage `Dockerfile`, the `fly.toml`, the `infra/inetrc` resolver, and the `docker-compose.yml`. No setting is named that those files do not carry.

## B8.1 · The release and the image

The image builds a release, not a running checkout. From the umbrella root the Dockerfile resolves the production dependencies, compiles the `codemojex` app over its in-umbrella deps, and assembles `mix release codemojex` — a self-contained tree of the BEAM, the compiled app, and its boot scripts. A second, slim runtime stage carries only that release, with no Elixir toolchain left behind, so the shipped image is small and holds nothing the running game does not use.

Before the release is cut, the native branded-id codec is built. `echo_data` carries a Rust core and a C shim that compile to shared objects in its `priv` directory; the release packs them, and the boot self-check confirms the native and pure-Elixir id paths agree. The codec is an optimization, not a requirement — the app falls back to pure Elixir if the shared object is absent — but building it in the image means production runs the accelerated path.

Only three of the umbrella's apps are built: `echo_mq`, `echo_data`, and `echo_wire`, the ones `codemojex` depends on. `echo_store` is left out on purpose, because the game does not depend on it and it carries a SQLite C-NIF the release would otherwise have to compile and ship for no use; `echo_bot` and `echo_graft` are out for the same reason, each its own concern behind its own boundary. The Dockerfile copies only the needed apps' manifests, so dependency resolution sees a minimal umbrella shape and the build stays lean.

## B8.2 · Valkey on a Fly machine

On Fly, the queue's Valkey runs as its own machine, separate from the web service. The image is a pinned `valkey/valkey`, started with `io-threads` sized to the machine's cores — one main thread executes commands, the rest feed it — a `maxmemory` budget, and a `noeviction` policy. Eviction is the wrong posture for a job store: a queue that silently drops keys is a queue that silently loses work, so memory pressure must surface as write errors and alerts. Apps reach it over the private network at `echo-valkey.internal`, behind a password even on the internal mesh, with auto-stop off so a machine is not reaped under a live queue.

Durability is the reason a queue chooses this engine. With `appendonly` on and `appendfsync everysec`, the volume holds an append-only log and the loss bound after a crash is roughly one second of writes, not a whole snapshot interval — and EchoMQ's checkpoints are designed against exactly that bound. The cost is that an AOF rewrite forks, and the copy-on-write spike during the fork must be budgeted: keep `maxmemory` well under the machine's RAM and schedule rewrites off-peak.

An in-memory store needs the kernel tuned away from its defaults. Transparent huge pages are turned off, because the larger pages turn a single-byte write during a fork's copy-on-write into a large page copy and a latency spike. Memory overcommit is set so a fork does not fail when copy-on-write means little real memory is needed; swappiness is set to its lowest practical value, because a swapped page trades nanoseconds for milliseconds; and the connection backlog and file-descriptor limits are raised so a burst of clients is accepted rather than dropped.

## B8.3 · EchoMQ setup and monitoring

EchoMQ is wired into the supervision tree, not bolted on. The application starts a shared bus and its connector against Valkey on the configured port, and each connector negotiates the RESP3 protocol with `HELLO 3` and pipelines its commands rather than waiting on each round trip. The bus is the one place that holds the Valkey connection; everything that touches the queue goes through it, so there is a single, supervised path to the store.

Above the bus sit the consumers, each a supervised child draining one lane: the scoring authority, the settlement worker, the notification worker, and the inbound-command worker. Each runs on a heartbeat and takes a lease on the job it is working, so a crashed consumer's in-flight job becomes visible again rather than lost, and the supervisor restarts the consumer in place. The lanes keep a hot player from starving the rest, the same fair rotation the play path relies on.

What you watch in production is the depth of the lanes and the health of the consumers. Queue length is a direct read, the bundled dashboard task connects to the same Valkey and prints the queues and their backlog, and the lease and heartbeat timings tell you whether a consumer is keeping up. Because the store is set to refuse rather than evict, a backlog that grows without draining surfaces as pressure to alert on — a signal that a consumer is stuck or the work is outrunning it — rather than as work quietly disappearing.

## B8.4 · The fly.toml and the local stack

The `fly.toml` describes how the release becomes machines. It names the `codemoji-phoenix` app and a primary region, builds from the Dockerfile, and deploys with a rolling strategy so a release replaces machines one at a time. Fly's internal network is IPv6, so the config points Erlang's resolver at an `inetrc` file, makes the database driver use IPv6 sockets, and runs distribution over inet6 — harmless on one machine, ready if the app ever clusters.

Two settings keep the live surface live. A health check polls `/health` so a machine that stops answering is taken out of rotation, and auto-stop is turned off with at least one machine always running, so a node is not reaped mid-session and a player's open `/socket` connection is not dropped under them. Connection limits are set per machine, so a machine sheds load by refusing new connections rather than collapsing.

The same image runs locally under docker compose, which brings up the whole stack: Postgres reachable on port 6432, Valkey on 6390 — the connector's port — and the endpoint on 4000. Because the connector dials its Valkey on localhost, the web container shares the Valkey container's network namespace, so the app finds the store on its own loopback with no change to the code. It is the production shape in miniature: the release, a database, and a queue, wired the way Fly wires them.

## References

- [Fly.io — Fly Machines](https://fly.io/docs/machines/) — the Machines the codemojex release deploys to under the codemoji-phoenix app.
- [Valkey — Persistence (RDB and the append-only file)](https://valkey.io/topics/persistence/) — the appendonly everysec posture, a roughly one-second loss bound after a crash.
- [Valkey — Diagnosing latency issues](https://valkey.io/topics/latency/) — the fork, fsync, and huge-page behavior the kernel tuning is for.
- [Phoenix — Channels](https://hexdocs.pm/phoenix/channels.html) — the JSON and `/socket` surface the endpoint holds open on port 4000.
- [Erlang/OTP — the gen_server behaviour](https://www.erlang.org/doc/apps/stdlib/gen_server.html) — the supervised processes the release boots as one application.
- [Kreps — The Log (LinkedIn Engineering)](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying-abstraction) — the lanes a single consumer drains, watched by their depth.
- [Helland — Life Beyond Distributed Transactions (CIDR 2007)](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf) — each umbrella app as its own bounded concern, built only when depended on.
- [The Go Blog — Share Memory By Communicating](https://go.dev/doc/codewalk/sharemem/) — the consumers draining work by message, and the deps an app keeps to itself.
