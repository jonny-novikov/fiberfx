# R8.02 · Persistence, pooling & failover

> Module hub · `/redis-patterns/production-operations/persistence-pooling-failover`
> Applies R7.01 `redis-as-primary-database` — operating the bus as a record of truth in production.

Operating the job store as a record of truth in production means three guarantees, not one. It must
**survive a restart** (the data outlives the process), **serve under load** (one server, many callers,
no head-of-line stall), and **ride a failover** (the wire drops, the client comes back). R7.01 made the
case that the bus *is* the record of truth — the `JOB` HASH carries `state` / `attempts` / `payload`,
and Postgres holds only what must be transactional. This module takes that record into production and
asks the operational question R7.01 left open: how does it stay one.

The answer is three real surfaces, each at a different layer:

- the engine's persistence policy — `infra/valkey/conf/valkey.conf`, where `appendonly yes` +
  `appendfsync everysec` + `save ""` make the append-only log the single source of durability;
- the client-side pool — `EchoMQ.Pool`, N pipelined connectors round-robined lock-free, sized for
  pipeline depth rather than cores;
- the connection's failover discipline — `EchoMQ.Connector`, supervised reconnect with capped jittered
  backoff that fails in-flight callers rather than replay them.

This is the operations layer, not the pattern. Read R7.01 for *why* the bus is the record of truth; read
this for *how it stays one* across a restart, a load spike, and a failover.

## The bridge

| The pattern — `redis-as-primary-database` in production | Its EchoMQ application |
|---|---|
| Survive restart, serve under load, ride a failover | `valkey.conf` (`appendonly yes` + `appendfsync everysec` + `save ""`, the durability dial) · `EchoMQ.Pool` (N pipelined connectors hiding RTT over a single-threaded server) · `EchoMQ.Connector` (capped-jittered-backoff reconnect, in-flight fail-not-replay) |

The take: a record of truth is not a data model — it is a data model plus the three operational
guarantees that keep it whole. The persistence policy keeps the record across a restart, the pool keeps
it served under load, and the reconnect discipline keeps it reachable across a failover.

## Survive a restart — the persistence policy

The first guarantee is durability: the data outlives the process. `valkey.conf` makes the append-only
log the single source of durability — `appendonly yes` records every keyspace-changing write to a log
on disk; `appendfsync everysec` flushes that log on a background thread once a second, bounding crash
loss to about one second of writes; `save ""` turns RDB snapshotting off so it never competes for a
second fork; `aof-use-rdb-preamble yes` gives the rewrite a compact preamble so it stays fast.
`propagation-error-behavior panic` fails a write rather than acknowledge data that may not survive, and
`maxmemory-policy noeviction` rejects writes loudly under memory pressure instead of dropping a job
(the R7.01 tie). One fork source, one durability mechanism, no false acknowledgements.

Dive 1, `rdb-and-aof`, takes this block apart line by line. It is distinct from R8.01's
`persistence-safe-settings`, which is the *kernel* layer (the `vm.overcommit_memory` sysctl for the save
fork); here it is the *Valkey persistence policy* itself.

## Serve under load — the pool

The second guarantee is throughput under concurrency. `EchoMQ.Pool` is a fixed pool of pipelined
connectors with lock-free round-robin dispatch: `next/1` advances an `:atomics` counter and a caller
hits the next member; the default `size: 4`. The sharp production insight is the one most pool sizing
gets wrong. Valkey runs commands **single-threaded** — `valkey.conf` sets `io-threads 1` and its own
comment reads *"command execution is single-threaded."* So a pool does **not** buy N× server
parallelism — it hides round-trip latency by keeping the one command thread fed via pipelining. Size for
pipeline depth and RTT-hiding, not for cores; over-sizing only adds sockets the single thread serializes
anyway.

Dive 2, `pool-sizing`, derives that insight. It is the same `EchoMQ.Pool` R6.05 teaches as the
concurrency primitive — here it is *sized* for production rather than introduced.

## Ride a failover — the reconnect discipline

The third guarantee is reachability across a disruption. When a primary fails over to a replica, a
client that keeps writing to the old node gets a Valkey `-READONLY` reply — the signal that a failover
happened. A resilient client must reconnect to the new primary. `EchoMQ.Connector` grounds the reconnect
discipline directly: supervised reconnect with capped jittered backoff, re-fencing on every reconnect;
in-flight callers failed with `:disconnected` on socket loss — never replayed, because the connector
cannot know what is idempotent; and an idle heartbeat that PINGs a quiet wire so dead peers are noticed
before the next caller pays for the discovery. The shipped deploy is a standalone Fly node, so a failover
here is a socket drop and a reconnect to the same restarted server; the discipline is the same one a
Sentinel- or Cluster-aware client uses to re-resolve a new primary.

Dive 3, `readonly-reconnect-failover`, separates the `-READONLY` signal (the pattern) from the
connector's reconnect discipline (the real grounding), and is honest that the connector handles failover
by socket-drop-and-reconnect, not by parsing `-READONLY`.

## Putting it together

The three surfaces are one posture seen from three layers. A restart hits the persistence policy: the
append-only log replays and the record is whole. A load spike hits the pool: the four pipelined
connectors keep the single command thread fed without one slow caller stalling the rest. A failover hits
the connector: the socket drops, in-flight callers get a clean `:disconnected`, and the supervised
reconnect re-fences and resumes. For codemojex, this is exactly the protection in-flight game and `JOB`
state needs — that state lives in Valkey (the bus + store) while money lives in Postgres, so the AOF
durability is what carries it across a restart, and the `EchoMQ.Pool` fronts the bot workers' notify
queue.

## The three dives

1. **`rdb-and-aof`** — the real `valkey.conf` persistence block, verbatim: AOF as the single source of
   durability, `appendfsync everysec`'s one-second loss bound, `save ""` retiring RDB, the panic posture.
2. **`pool-sizing`** — `EchoMQ.Pool` and the single-threaded-server insight: size for pipeline depth and
   RTT-hiding, not for cores.
3. **`readonly-reconnect-failover`** — the `-READONLY` signal and the connector's reconnect discipline:
   capped jittered backoff, re-fence, in-flight fail-not-replay.

## References

### Sources

- [Valkey — *Persistence*](https://valkey.io/topics/persistence/) — the append-only file, the
  `everysec` fsync policy, and the roughly one-second loss bound after a crash.
- [Valkey — *Replication*](https://valkey.io/topics/replication/) — primary/replica roles and the
  `-READONLY` reply returned to a client that writes to a replica after a failover.
- [Valkey — *CLIENT*](https://valkey.io/commands/client-no-evict/) — the client-side controls a pooled
  connector negotiates at boot.
- [Redis — *Pipelining*](https://redis.io/docs/latest/develop/use/pipelining/) — why a pipeline hides
  round-trip latency on a single command thread, the premise behind pool sizing.

### Related in this course

- [R7.01 · Redis as a primary database](/redis-patterns/data-modeling/primary-database) — the pattern
  this module operates in production.
- [R8.01 · Kernel tuning](/redis-patterns/production-operations/kernel-tuning) — the host layer beneath
  this server-level posture.
- [R6.05 · Worker concurrency](/redis-patterns/flow-control/worker-concurrency) — the same `EchoMQ.Pool`,
  taught as the concurrency primitive.
- [/echomq · the Proof pillar](/echomq/proof) — conformance, telemetry, and the production evidence the bus carries.
- [/bcs · Production on Fly](/bcs/fly) — the Fly machine where this exact `valkey.conf` runs.
- [/echo-persistence](/echo-persistence) — the durability floor: the dial beyond AOF.
