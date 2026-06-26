# R8.06 · Operating EchoMQ

> Module hub · `/redis-patterns/production-operations/operating-echomq`
> The bridge to the dedicated EchoMQ course — a production operator's view of running the bus.

Operating the bus in production is three operator moves on top of the application code: **colocate** the
keys so a multi-key script stays legal at cluster scale, **observe** the bus so throughput, latency, and
failures are visible, and **scale the fleet** so more workers can drain the same queues. Each move lands
on a real surface, and each is a preview of the dedicated EchoMQ course — this module operates the bus
without re-teaching the protocol depth that course owns.

The three surfaces, each at a different layer:

- the keyspace's colocation rule — `EchoMQ.Keyspace.slot/1`, which computes a key's Valkey cluster slot
  client-side from the `{q}` hashtag, so every key of one queue lands on one of 16384 slots and a
  multi-key Lua `EVAL` stays `CROSSSLOT`-safe in cluster mode;
- the bus's observability surface — `EchoMQ.Meter`, a `:telemetry` tree rooted `[:emq, …]` that costs
  nothing when `:telemetry` is absent and that a Prometheus or OpenTelemetry exporter attaches to;
- the identity's conformance property — the 14-character branded id is *conformant*: one canon across
  Elixir, Node, Go, PostgreSQL, and WASM, which is what makes a polyglot worker fleet over one wire
  possible.

This is the operations layer, and it is honest about what ships today: the bus is Elixir, and the
polyglot fleet is the conformance target the wire and the id contract make reachable. Read this for the
operator's view; door into the EchoMQ course for the protocol itself.

## The bridge

| Operating the bus in production — colocate, observe, scale the fleet | Its EchoMQ application |
|---|---|
| Colocate the keys, observe the throughput, scale the worker fleet | `EchoMQ.Keyspace.slot/1` (the `{q}` hashtag → one of 16384 cluster slots) · `EchoMQ.Meter` (`[:emq, …]` telemetry → Prometheus / OpenTelemetry) · the branded-id conformance (one id canon → a polyglot fleet over one wire) |

The take: a job system in production is the application plus three operator moves. Colocation keeps the
multi-key scripts legal at scale, the telemetry tree makes the bus observable through standard exporters,
and the conformant id is the shared contract that lets a fleet of workers — in any of five runtimes —
drain the same queues over the same wire.

## Colocate — the cluster slot

The first operator move is placement. In Valkey Cluster the keyspace is split across 16384 hash slots, and
a single command — including a Lua `EVAL` — may only touch keys in one slot, or the server answers
`CROSSSLOT`. EchoMQ makes that constraint disappear by construction: every key of a queue is born braced —
`emq:{q}:pending`, `emq:{q}:active`, `emq:{q}:job:<JOB>` — and the slot is computed from the substring
inside the first `{…}`, the hashtag. `EchoMQ.Keyspace.slot/1` is `rem(crc16(hashtag(key), 0), 16384)`:
CRC16-XMODEM over the hashtag, modulo 16384, the cluster specification's own algorithm computed
client-side so the connector can route without a server round trip. Because every key of one queue shares
the `{q}` brace, all of them hash to one slot — so a multi-key script over a queue is always `CROSSSLOT`-safe.

The known vector the source pins: `slot("123456789") == 12739`. Deploy on a Valkey Cluster and colocation
is automatic — the hashtag *is* the shard key.

Dive 1, `cluster-colocation`, takes `slot/1` and `hashtag/1` apart and shows why the braced keyspace is
what keeps a queue's Lua legal at cluster scale.

## Observe — the telemetry tree

The second operator move is observability. `EchoMQ.Meter` is the bus's `:telemetry` surface:
`attach`/`attach_many`/`emit`/`span`, every event rooted `[:emq | suffix]`, and every emission guarded so
it costs nothing when `:telemetry` is not loaded. The lifecycle event tree is fixed:
`[:emq, :job, :add|:start|:complete|:fail|:retry]`, `[:emq, :worker, :start|:stop]`, and
`[:emq, :rate_limit, :hit]` — plus the connector's own `[:emq, :connector, …]`, one tree. `span/3` wraps a
call in start/stop/exception events, the standard OpenTelemetry span shape. Attach a Prometheus exporter
or an OpenTelemetry bridge to the `[:emq, …]` tree and throughput, latency, and failure are metered the
standard Elixir way — no bus-specific agent. For a quick read at the terminal, `EchoMQ.Dashboard` is a
cat-able ANSI operator view, read-only over the `EchoMQ.Metrics` pure-read plane.

Dive 2, `prometheus-and-opentelemetry`, attaches an exporter to the event tree and reads the `span/3`
shape as an OpenTelemetry span.

## Scale the fleet — the conformant id

The third operator move is scale. A 14-character branded id has four properties — *typed*, *ordered*,
*placed*, and *conformant* — and the fourth is what scales a fleet. Conformant means one source of truth
and one vector file make encode and decode identical across five runtimes — Elixir, Node, Go, PostgreSQL,
and WASM — so which language runs a worker is a deployment detail. The runtime proves it at boot:
`self_check!` mints, encodes, decodes, and hashes a known id down both the native and pure paths and
asserts the committed vectors. A node that cannot reproduce them never reaches its first message.

The honest frame: the shipped bus is Elixir (`echo/apps/echo_mq`), and a Go or Node worker fleet does not
ship today. The polyglot fleet is the conformance *target* — the wire protocol and the id contract are
exactly what make it reachable. So this dive is the door to the dedicated EchoMQ course, where the
polyglot protocol and the full Lua inventory live.

Dive 3, `the-polyglot-fleet`, reads the boot-asserted id vectors and the conformance property that a
shared bus depends on.

## Putting it together

The three moves are one operator posture. Colocation keeps the multi-key scripts legal as the cluster
grows: the `{q}` hashtag pins a queue to one slot, so its `EVAL` never spans two. Observability makes the
bus legible: the `[:emq, …]` telemetry tree feeds a standard exporter, no special tooling. Conformance
makes the fleet portable: one id canon, proven at boot, lets workers in five runtimes share the wire. For
codemojex, the `cm` queue's keys share the `{cm}` brace — the same colocation — and the bot workers are a
fleet draining `cm`; codemojex mints `PLR`, `ROM`, `GAM`, `GES`, and `JOB` — the conformant ids that fleet
would share.

## The three dives

1. **`cluster-colocation`** — `EchoMQ.Keyspace.slot/1` and `hashtag/1`: CRC16-XMODEM over the `{q}`
   hashtag modulo 16384, the vector `slot("123456789") == 12739`, and why the braced keyspace keeps a
   queue's multi-key Lua `CROSSSLOT`-safe.
2. **`prometheus-and-opentelemetry`** — `EchoMQ.Meter`'s `[:emq, …]` event tree and `span/3` shape:
   attaching a Prometheus exporter or an OpenTelemetry bridge to a zero-cost telemetry surface.
3. **`the-polyglot-fleet`** — the branded id's *conformant* property and the boot-asserted vectors: one id
   canon across five runtimes, the door to the dedicated EchoMQ course.

## References

### Sources

- [Valkey — *Cluster specification*](https://valkey.io/topics/cluster-spec/) — the 16384 hash slots and
  how a `{hashtag}` forces a key family onto one slot, the basis for `slot/1`.
- [Valkey — *CLUSTER KEYSLOT*](https://valkey.io/commands/cluster-keyslot/) — the command that returns a
  key's slot, the server-side counterpart to the client-side CRC16 computation.
- [OpenTelemetry — *Traces*](https://opentelemetry.io/docs/concepts/signals/traces/) — the span model
  `EchoMQ.Meter.span/3` follows with its start/stop/exception events.
- [Prometheus — *Documentation*](https://prometheus.io/docs/) — the metrics model an exporter maps the
  `[:emq, …]` telemetry tree onto.

### Related in this course

- [R8.02 · Persistence, pooling & failover](/redis-patterns/production-operations/persistence-pooling-failover) — the same pool and connector, taken into production.
- [R7.04 · Bitmap patterns](/redis-patterns/data-modeling/bitmap-patterns) — where the same `hash32` placement is read as a bit offset.
- [/echomq · the Proof pillar](/echomq/proof) — conformance, telemetry, and the production evidence the bus carries.
- [/echomq · the Queue pillar](/echomq/queue) — the scaling layer: lanes, leases, and the worker fleet in depth.
- [/bcs · The bus](/bcs/bus) — EchoMQ as the architecture: the braced keyspace and the BCS law on the wire.
- [/bcs · Production on Fly](/bcs/fly) — where the bus runs in production.
