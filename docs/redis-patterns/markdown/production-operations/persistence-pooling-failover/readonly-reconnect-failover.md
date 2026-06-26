# R8.02.3 · READONLY, reconnect & failover

> Dive · `/redis-patterns/production-operations/persistence-pooling-failover/readonly-reconnect-failover`

A record of truth has to stay reachable across a disruption. When the node a client is writing to fails
over — a primary steps down, a replica is promoted — the client's old connection is suddenly pointing at
the wrong server. This dive separates two things that production discussions often blur: the Valkey
*signal* that a failover happened (the pattern), and the client *discipline* that recovers from it (the
real grounding in `EchoMQ.Connector`). The honest seam between them is the point of the dive.

## The `-READONLY` signal — the pattern

In a replicated Valkey deployment, writes go to the primary; replicas serve reads and refuse writes. If a
client keeps issuing writes to a node that has become a replica — which is exactly what happens for a
moment after a failover, before the client has detected the change — the server answers with a `-READONLY` error:
*"You can't write against a read only replica."*

That reply is a **signal**: the topology changed under the client. A resilient client treats it as the
cue to stop writing to this node and reconnect to the new primary. How it finds the new primary depends
on the deployment — a Sentinel client asks the sentinels, a Cluster client re-resolves the slot's owner.
The signal is the pattern; the rediscovery mechanism is deployment-specific.

## What the connector actually does — the honest retarget

`EchoMQ.Connector` (`echo/apps/echo_wire/lib/echo_mq/connector.ex`) does **not** parse `-READONLY`, and
it does not do Sentinel discovery. Being honest about that is the whole point of this dive: the TOC name
"READONLY-reconnect" overstates what is in the code. The connector handles failover the way a
single-owner socket client should — by **socket-drop and supervised reconnect**. When the wire to the old
node drops (a failover tears the connection down, or the node restarts), the connector notices, fails its
in-flight callers, and reconnects on a backoff. The shipped deploy is a standalone Fly node, so a failover
here is a restart and the reconnect goes back to the same server — but the discipline is exactly the one a
Sentinel- or Cluster-aware client layers its rediscovery on top of.

So the grounding here is not a `-READONLY` handler. It is the **reconnect discipline** the connector ships
— three real properties that make reconnection safe.

## The three production properties

The connector's moduledoc names them. The reconnect itself:

> supervised reconnect with capped jittered backoff, re-fencing on every reconnect.

The capped jittered backoff is real in `schedule/1`: each attempt waits the current backoff plus a random
jitter, and the backoff doubles up to a ceiling —
`Process.send_after(self(), :reconnect, s.backoff + jitter)` with `min(s.backoff * 2, s.backoff_max)`.
The jitter keeps a fleet of reconnecting clients from synchronizing into a thundering herd; the cap keeps
the wait bounded. "Re-fencing on every reconnect" means the wire-version fence (`@wire_version`) is
re-checked before the first command on the new connection, so a reconnect can never resume against a
server speaking a different protocol.

The in-flight policy:

> in-flight callers failed with `:disconnected` on socket loss -- never replayed, because the connector
> cannot know what is idempotent.

This is the load-bearing safety property. When the socket drops, every caller waiting on a reply gets a
clean `{:error, :disconnected}` — and the command is **not** re-sent on the new connection. The connector
refuses to replay because it cannot know whether the command was idempotent: a write that already landed
before the drop would be applied twice if replayed. So the wire is at-most-once, and idempotency is
pushed up to the caller, which is the only place with the information a safe retry needs. A `complete` that
already ran must not run again; the retry decision belongs to the caller.

The early-warning property:

> an idle heartbeat that PINGs a quiet wire so dead peers are noticed before the next caller pays for the
> discovery.

A connection that has been idle might already be dead — the peer gone, the path broken — and nobody knows
until the next caller tries to use it and waits for a timeout. The connector arms an idle heartbeat that
PINGs a quiet wire, so a dead peer surfaces as a failed PING and triggers the reconnect *before* a real
caller is made to pay the discovery cost.

The connector also exposes the failover state to observers: a `reconnects` counter (slot 4 of its
counters) increments on each successful reconnect, and `stats/1` reports `status: :reconnecting` while
the socket is down and `:connected` once it is back.

## The bridge

| The pattern — reconnect-to-the-new-primary on the failover signal | Its EchoMQ application |
|---|---|
| Treat `-READONLY` (or a dropped socket) as the cue that the topology changed; reconnect with backoff; never replay an in-flight write whose idempotency is unknown | `EchoMQ.Connector` ships capped jittered backoff with re-fence on reconnect, fails in-flight callers `:disconnected` (at-most-once on the wire), and PINGs an idle wire so dead peers surface early; the standalone Fly deploy reconnects to the restarted node |

The take: failover recovery is a discipline, not a single error code. The connector does not parse
`-READONLY` — it drops, fails in-flight callers loudly, re-fences, and reconnects on a jittered backoff,
and it pushes idempotency to the caller because that is the only place with the information a safe retry needs.

## Where this completes the posture

This is the third guarantee of operating the bus as a record of truth. The persistence policy (dive 1)
keeps the data across a restart; the pool (dive 2) serves it under load; this reconnect discipline keeps
each connection reachable across a failover. Because a pool member *is* an `EchoMQ.Connector`, the pool
inherits this discipline for free: one member's socket dropping fails only that member's in-flight callers
and reconnects on its own, while the rest of the pool keeps serving.

## References

### Sources

- [Valkey — *Replication*](https://valkey.io/topics/replication/) — primary/replica roles and the
  `-READONLY` reply a client gets writing to a replica after a failover.
- [Valkey — *Sentinel*](https://valkey.io/topics/sentinel/) — automatic failover and how a
  Sentinel-aware client re-resolves the new primary the reconnect targets.
- [Redis — *Documentation*](https://redis.io/docs/) — the high-availability and client-reconnection
  topics this discipline draws on.
- [antirez — *Redis Sentinel design*](https://antirez.com/news/79) — the Redis creator's notes on
  failover signalling and client rediscovery.

### Related in this course

- [R8.02 · Persistence, pooling & failover](/redis-patterns/production-operations/persistence-pooling-failover) — the module hub.
- [R8.02.2 · Pool sizing](/redis-patterns/production-operations/persistence-pooling-failover/pool-sizing) — the pool whose members inherit this discipline.
- [R7.01 · Redis as a primary database](/redis-patterns/data-modeling/primary-database) — the record of truth this keeps reachable.
- [/echomq · the Proof pillar](/echomq/proof) — conformance and telemetry, including the `reconnects` counter.
- [/bcs · Production on Fly](/bcs/fly) — the standalone Fly node this reconnects to.
- [/echo-persistence](/echo-persistence) — the durability floor beneath the volatile tier.
