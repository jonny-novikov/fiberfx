# @echo/cluster

An efficient multicore runtime for echo HTTP surfaces. One node process — Bun or
Node — saturates one core. This package fans a server out across every core,
warms each worker before it takes traffic, and supervises the fleet: crash
respawn, graceful drain, and rolling generations with no capacity gap.

## The shape

Define a `Bundle` once and call `runCluster` in an entry module. The same module
is executed by the supervisor and by each worker; the runtime decides the role.

```ts
import { runCluster } from "@echo/cluster";

await runCluster(
  {
    // Get hot BEFORE serving: open pools, build the app, warm the hot path.
    async warmup(ctx) {
      const app = build();
      await app.ready();
      return app;
    },
    // Then bind the port with the warm state.
    async serve(app, ctx) {
      await app.listen({ host: "0.0.0.0", port: ctx.port });
      return { stop: () => app.close() }; // drains in-flight work
    },
  },
  { port: 3000 }, // workers default to the core count
);
```

The order is the contract: `warmup` resolves, then `serve` binds. A worker is in
the load-balancing rotation only after it has bound, so the kernel never routes a
request at a worker that is still warming.

## Backends

`backend` selects how workers are spawned and how they share the port.

- **`node`** — `node:cluster`. The primary owns the listening socket and
  distributes accepted connections; workers bind normally. Runs on Node and on
  Bun (Bun implements `node:cluster`). Use this for a Node-HTTP app such as
  Fastify or Express.
- **`bun`** — `Bun.spawn` with `SO_REUSEPORT`. Each worker binds the same port
  and the Linux kernel load-balances, with no primary proxy on the hot path. Bun
  runtime only; pairs with a native `Bun.serve` worker. See
  `examples/bun-native.ts`.
- **`auto`** (default) — `bun` under Bun, `node` otherwise.

`SO_REUSEPORT` is Linux only; macOS and Windows ignore it, so on those platforms
prefer the `node` backend for multi-process serving.

## Lifecycle

- **Readiness** — a worker reports ready over IPC once `serve` resolves. The
  supervisor counts it as available only then.
- **Respawn** — a worker that exits unexpectedly is respawned into the same
  logical slot with exponential backoff, capped at `maxRespawnDelayMs`.
- **Rolling reload** (`SIGHUP`) — a fresh generation is spawned and warmed to
  ready before the previous generation is drained, so capacity never dips. If the
  new generation does not warm within `warmupBudgetMs`, it is drained and the old
  one kept.
- **Shutdown** (`SIGTERM` / `SIGINT`) — every worker is asked to drain; any that
  overruns `drainTimeoutMs` is force-killed.

Because workers do not share memory, sessions, caches, and counters belong in an
external store (ValKey, Postgres) rather than process memory.

## Options

| Option              | Default | Meaning                                            |
| ------------------- | ------- | -------------------------------------------------- |
| `port`              | —       | The port every worker shares (required).           |
| `workers`           | cores   | Desired worker count.                              |
| `minWorkers`        | 1       | Lower clamp.                                       |
| `maxWorkers`        | 1024    | Upper clamp.                                       |
| `backend`           | `auto`  | `auto` \| `node` \| `bun`.                         |
| `warmupBudgetMs`    | 30000   | Time a new generation has to report ready.         |
| `drainTimeoutMs`    | 10000   | Time a draining worker has before a force kill.    |
| `respawnDelayMs`    | 250     | Initial crash-respawn backoff.                     |
| `maxRespawnDelayMs` | 5000    | Backoff ceiling.                                   |
| `onLog`             | JSON    | Structured log sink.                               |

## Scripts

```
pnpm build       # tsc -> dist
pnpm typecheck   # tsc --noEmit
pnpm test        # supervisor core over a fake transport
```
