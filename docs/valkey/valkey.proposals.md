# Porting valkey-go: What to Build, in What Order

The module catalogue (`valkey.go.md`) ends on a narrow frontier: the hard core is owned, the construction
ergonomics are built (`ewr.*` Movement I), and most satellites have a richer BCS-native peer already. This
chapter is the build order for what remains — a forward-looking plan, in the series convention, with each
proposal grounded in a real roadmap home and never asserted as shipped.

The proposals sort into five tiers by verdict. Two are the point of the next movement; two are clean additions
with no current peer; the rest is recorded so a later rung does not rediscover a closed question.

## Tier 1 — the flagship: EchoMQ 2.0 with Streaming

valkey-go lists Streams among its core capabilities beside Pub/Sub and Sharded Pub/Sub [1]: `XADD`, the
`XREADGROUP` consumer-group read, `XACK`, `XAUTOCLAIM`. The Echo peer is **not** a port of the Go surface — it
is the stream tier the EchoMQ roadmap already lays out (`emq.roadmap.md`, §EchoMQ 3.x), and valkey-go is the
proof that the verb set and the consumer-group model are the right primitives to build on.

The EchoMQ stream tier is the natural carrier of the *retained, replayable event log* the BCS whole-picture
names (the availability-first surface beside the consistency-first ledger). The roadmap's rung ladder is the
plan of record:

- **The writer law** — `XADD` through the certified connector, hash-tagged per stream key, **branded record
  ids**, append is mint order so *stream order == id sort, every time* (`EchoMQ.Stream`; `emq.N.1`–`emq.N.2`).
  This is where the wire-core port pays off: the stream verbs land on the *extracted* wire, constructed through
  `EchoWire.Pipe` rather than hand-written `[[binary]]` literals.
- **The reader + groups** — `XREADGROUP`/`XACK`/`XAUTOCLAIM` as the at-least-once consumer surface, the
  branded `JOB`/record id the claim check a worker redeems.
- **Retention as declared policy** — `MAXLEN` (approx) and mint-time `MINID` windows per stream; trim honors
  the window, inside-window reads never miss, outside answers truthfully (`emq.N.4`).
- **The archive + time-travel** — segments folded into the `EchoStore.Graft` engine (local CubDB → Tigris),
  mint-instant → `XRANGE` bounds, Table hydration from a tail (`emq.N.5`–`emq.N.6`).

**The dependency, recorded.** The stream tier **hard-gates on the extracted wire** (`emq.0`) — its verbs land on
the connector and its construction rides `EchoWire.Pipe`. Nothing here reverses the standing decisions: the
braced `emq:{q}:` keyspace, every Lua key declared, the server clock on any lease, the `echomq:X.Y.Z` fence
climbing in lockstep. Streaming is the capability that takes EchoMQ from a queue/bus to a *log*, and it is the
single largest thing the valkey-go feature list says the Echo stack should still build.

## Tier 2 — server-assisted client-side caching (the Movement II seam)

This is the other half of what makes valkey-go distinctive [2], and it is already named as a seam on the wire
program: rueidis's `DoCache`/`Cacheable`, the `CLIENT TRACKING ON [OPTIN|BCAST]` handshake, and the
`invalidate` push → local eviction coherence (`ewr.roadmap.md`, Movement II). It is the **"message about a
name"** the BCS law names literally, and the natural fit for the `echo_store` L1 in front of Valkey — exactly
where `valkeyaside` lives in the Go tree.

The proposal is to build it where its consumer is real: when `echo_store`'s L1 consumes server-assisted
invalidation, the tracking connection becomes a **third lane** beside command and blocking lanes (engine ch. 2),
its pushes accelerating the convergence Snowflake-versioned newer-wins already guarantees. The cost is recorded
honestly: the **send side is additive**, but making tracking survive reconnect needs a boot-step in the frozen
connector (`boot_rest/4`, the fence sequence) — a wire **MAJOR**, held behind the seam until a consumer makes
the trade real, never folded into an additive rung. This is the one place the port may cut into the frozen wire,
and it earns its own surfaced fork when it does.

## Tier 3 — the clean additions (no current peer)

Two satellites solve problems Echo does not yet have a peer for. Both are small, additive, and land as
patterns over the owned wire — the `valkey<thing>` satellite shape, in Elixir.

- **A rate limiter (`valkeylimiter`).** A fixed-window limiter, sharded and replicated, of the kind GitHub
  documented for its API [3]. EchoMQ has admission and fair-lanes (the group control plane, `emq.4.x`) but no
  *rate* primitive — actions-per-window per identity. The branded id is the natural key; the window counter is
  a small inline Lua over a hash-tagged key, declared-keys clean. **Propose** as an `echo_mq` pattern (or a
  pattern-as-module if the OSS posture wants it satellite-shaped).
- **Probabilistic admission (`valkeyprob`).** Bloom filters and friends without Redis Stack [4] — a
  membership test the admission feature (dedup, "seen before") can lean on without a module dependency, in the
  spirit of valkeyprob implementing the structure over plain commands. **Propose** as a forward edge for
  EchoMQ admission; lower priority than the two flagships.

## Tier 4 — already owned (do not re-port)

The catalogue's `OWNED` rows, restated as a warning: porting these would clone a thinner version of a peer the
BCS stack already has.

- **Object mapping (`om`)** → `EchoData.Bcs.PropertyStore` + archetypes. The BCS identity contract (the 14-byte
  branded snowflake, the gate, the property store) is a *richer* object surface than a Hash/JSON repository, and
  it is the law of the stack, not a satellite.
- **Cache-aside (`valkeyaside`)** → `EchoStore` L1-over-L2. Already the structural design; Tier 2 *deepens* it
  with server-assisted invalidation rather than re-porting it.
- **Distributed lock (`valkeylock`)** → the `@distributed-lock` wire-pipe pattern over `echo_mq`. Shipped as a
  story; server-clock leases are already the discipline.
- **Auto-pipelining + the command builder** → `EchoMQ.Connector` + `EchoWire.Pipe`. The hard core is owned and
  the ergonomic core is built (`ewr.*` Movement I).

## Tier 5 — adapt or skip

- **Telemetry (`valkeyotel`)** → **ADAPT.** The capability belongs in Echo, but via BEAM-native `:telemetry`
  events the existing tooling already consumes, not an OpenTelemetry port. Emit the spans/metrics on the Elixir
  side; do not import the Go integration shape.
- **AZ-affinity routing** → **ADAPT.** Real, but it is a deployment posture (the Fly 6PN two-pool topology,
  engine ch. 3), not a client module to port.
- **`valkeyhook`** → **SKIP.** The `EchoWire` facade is already the interception seam; a hook layer would
  duplicate it.
- **`valkeycompat` / `valkeycompatmock`** → **SKIP.** A go-redis API adapter answers a Go migration problem the
  BEAM does not have.
- **`valkeyrdma`** → **SKIP.** Experimental, payload-limited, niche.
- **`mock`** → **SKIP.** Echo's conformance suite runs against a live Valkey on `:6390`; the test posture is
  real-engine, not a builder mock.

## The build order, recorded

The frontier is narrow and the sequencing is clear. The wire-core construction surface is **done** (`ewr.*`
Movement I, built), so both flagships can build on it. **First**, the stream tier — the largest capability gap
and the carrier of the retained log — gated on the extracted wire it already has. **Second**, server-assisted
caching — gated on a real `echo_store` L1 consumer, surfaced as a wire MAJOR when it lands. **Then**, the two
clean satellites (rate limiter, probabilistic admission) as additive patterns when a consumer asks. Everything
else is owned, adapted at the deployment edge, or deliberately skipped. The port is mostly finished; what is
left is the part that turns the bus into a log and the cache into a coherent one.

## References

1. https://github.com/valkey-io/valkey-go
2. https://redis.io/docs/latest/develop/reference/client-side-caching/
3. https://github.blog/engineering/infrastructure/how-we-scaled-github-api-sharded-replicated-rate-limiter-redis/
4. https://github.com/valkey-io/valkey-go/tree/main/valkeyprob
5. https://redis.io/docs/latest/develop/data-types/streams/
