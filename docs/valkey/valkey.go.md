# valkey-go: The Library, the Module Map, and the Port Posture

The four engine chapters (`valkey.evolution.md` → `valkey.core.md`) answer one question: *what Valkey the
server is, and how EchoMQ Core should connect to it.* This chapter opens a second, orthogonal axis under the same
roof: *what the valkey-go **client library** offers, module by module, and which of those modules the Echo
ecosystem should port, already owns, or should deliberately skip.* The engine axis is about the thing on
`:6379`; the library axis is about the shape of the client that talks to it — and that shape is the structural
reference for what `echo_wire` is becoming.

This is a survey with verdicts, in the series convention: surfaces the roadmap will build are written as plans,
never as references to code that exists. The companion chapter `valkey.proposals.md` turns the verdicts into a
build order.

## Why valkey-go is the reference, not the dependency

valkey-go is the official Valkey Go client, derived from rueidis: a fast client that auto-pipelines
non-blocking commands and supports server-assisted client-side caching [1][2]. The Echo stack will never depend
on it — it is Go, and `echo_wire` is BEAM-native and dep-free by covenant. valkey-go matters for its **shape**,
which is exactly the shape `echo_wire`'s roadmap reaches for:

- **A small core with no dependencies.** One `package valkey` (`go.mod` requires only a test matcher and
  `golang.org/x/sys`), flat role-named files: `pipe.go`, `pool.go`, `mux.go`, `resp.go`, `lua.go`, `retry.go`,
  `cluster.go`, `sentinel.go`, `standalone.go`. This is `echo_wire`'s `lib/echo_mq/{connector,resp,script}.ex`
  with the names changed.
- **Satellites that import the core down-only.** Eleven `package valkey<thing>` sibling directories —
  `valkeyaside`, `valkeylock`, `valkeylimiter`, `valkeyotel`, `valkeyhook`, `valkeycompat`, `valkeyprob`,
  `valkeyrdma`, `om`, `mock`, `valkeycompatmock` — each depending on the core and never the reverse. Ten carry
  their **own `go.mod`** (a hard module boundary a stranger imports in isolation); the lone exception,
  `valkeylock`, is package-separated but shares the core module. The pattern-as-library: a lock, a limiter, a
  cache-aside helper, an object mapper — each a thin layer over the core, shipped as its own importable unit.

The covenant-relevant fact (chapter 4): an OSS release of EchoMQ Core needs precisely this layering — a
dep-free core a stranger can vendor, with the patterns offered as opt-in satellites rather than baked into the
wire.

## The Echo peer surface, as it stands

`echo_wire` already owns the **hard** half of the core — the half rueidis is famous for:

- **Connection-level auto-pipelining.** `EchoMQ.Connector` pipelines concurrent callers through an in-flight
  FIFO (the rueidis `pipe.go` mux), so the throughput property valkey-go advertises is already shipped, not
  pending.
- **A full RESP3 decoder.** `EchoMQ.RESP` covers the 13 RESP3 terms including push frames — the substrate both
  client tracking and pub/sub ride.
- **EVALSHA-first scripting.** `EchoMQ.Script` precomputes SHA1 and runs EVALSHA-first, behind the
  `echomq:2.4.2` fence (the protocol version, climbing in lockstep with the library to `3.0.0` at emq.8).

What `echo_wire` did **not** own — the *construction* half, the fluent builder rueidis is also known for — is
the live port: the **`ewr.*` client-core program** (`docs/echo_mq/wire/`). Its **Movement I is BUILT**:
`EchoWire.Pipe` (the threaded `|>` pipeline, `ewr.1.1`), the immutable command value (`ewr.1.2`), the two-tier
error split (`ewr.1.3`), and the adoption of all three into `echo_mq`'s own `enqueue_many/3` (`ewr.1.4`). The
satellites map onto the BCS stack apps above the wire. The catalogue below records, for every valkey-go module,
where its Echo peer lives and how far along it is.

## The module catalogue

Read the verdict column as the load-bearing one. `OWNED` — Echo already has a richer or equivalent peer; do not
re-port. `BUILT` — ported and shipped on the `ewr.*` ladder. `PROPOSE` — worth building; a plan, with a home on
a roadmap. `ADAPT` — the capability belongs in Echo but via a BEAM-native mechanism, not a port. `SKIP` — the
module solves a Go-specific or niche problem Echo does not have.

| valkey-go module | What it is | Echo peer (app) | Status | Verdict |
|---|---|---|---|---|
| core — auto-pipelining | connection-level pipelining of concurrent non-blocking commands | `EchoMQ.Connector` (`echo_wire`) | shipped (the in-flight FIFO) | **OWNED** |
| core — command builder | fluent `client.B()…Build()` immutable command construction | `EchoWire.Pipe` + the command value (`echo_wire`) | `ewr.1.1`/`ewr.1.2` | **BUILT** |
| core — error model | `NonValkeyError()` (transport) vs `Error()` (server, in-band) | `EchoWire` two-tier result split (`echo_wire`) | `ewr.1.3` | **BUILT** |
| core — RESP3 + push | the wire codec incl. out-of-band push frames | `EchoMQ.RESP` (`echo_wire`) | shipped (13 terms) | **OWNED** |
| core — server-assisted client-side caching (`DoCache`) | `CLIENT TRACKING` + invalidation-push → local eviction | the `ewr` Movement II seam → `echo_store` L1 | PROPOSED (possible wire MAJOR) | **PROPOSE** ★ |
| core — Streams (`XADD`/`XREADGROUP`/…) | the stream verbs + consumer groups | EchoMQ stream tier (`echo_mq`) | PROPOSED (emq.N.1–N.6) | **PROPOSE** ★ |
| core — Pub/Sub + Sharded Pub/Sub | the broadcast lanes | `Connector` PUB/SUB + the push lane (`echo_wire`) | shipped (frozen) / deepening | **OWNED** |
| core — `DoStream` | stream a large reply to an `io.Writer` | — | — | **SKIP** (niche; BEAM streams differently) |
| core — Cluster / Sentinel | topology-aware routing + failover client | the vkc rungs under emq.7 (`echo_wire`) | PROPOSED (engine ch. 4) | **PROPOSE** |
| core — AZ-affinity routing | zone-aware replica routing | the Fly 6PN topology (engine ch. 3) | deployment posture | **ADAPT** |
| `om` | generic object mapping — Hash/JSON repositories + caching | `EchoData.Bcs.PropertyStore` + archetypes (`echo_data`) | shipped (the richer peer) | **OWNED** |
| `valkeyaside` | cache-aside enhanced by client-side caching | `EchoStore` L1-over-L2 (`echo_store`) + the cache-aside story | shipped; deepened by Movement II | **OWNED** |
| `valkeylock` | distributed lock enhanced by client-side caching | `@distributed-lock` (the wire-pipe story → `echo_mq`) | shipped (story) | **OWNED** |
| `valkeylimiter` | fixed-window rate limiter (sharded/replicated) | — | — | **PROPOSE** |
| `valkeyprob` | probabilistic structures (Bloom, …) without Redis Stack | — | — | **PROPOSE** |
| `valkeyotel` | OpenTelemetry tracing + connection metrics | `:telemetry` events (BEAM-native) | adapt, don't port | **ADAPT** |
| `valkeyhook` | intercept the client via a `Hook` handler | the `EchoWire` facade is already the seam | — | **SKIP** |
| `valkeycompat` | go-redis-like `Cmdable` API adapter | — (no go-redis idiom to ape in Elixir) | — | **SKIP** |
| `valkeyrdma` | experimental RDMA connection type | — | — | **SKIP** (experimental, niche) |
| `mock` / `valkeycompatmock` | gomock test doubles for the builder | the conformance suite against real Valkey `:6390` | — | **SKIP** (Echo tests against a live engine) |

★ marks the two frontier features — server-assisted caching and streaming — that `valkey.proposals.md` argues
are the whole point of the next movement.

## What the catalogue tells us

Three readings distill. First, the **hard core is already owned**: the auto-pipelining and RESP3 decoding that
make valkey-go fast are `echo_wire`'s shipped floor, and the construction ergonomics on top are `ewr.*` Movement
I, **already built**. Second, **most satellites are already patterns Echo owns** — the lock, the cache-aside, the
object mapper each have a richer BCS-native peer; re-porting them would be cloning a thinner version of what the
stack already has. Third, the **real frontier is narrow and high-value**: server-assisted client-side caching
and the stream tier, plus two clean satellites with no current peer (a rate limiter, probabilistic admission).
That narrowness is the good news — the port is mostly done; what remains is the part worth doing well.

## References

1. https://github.com/valkey-io/valkey-go
2. https://redis.io/docs/latest/develop/reference/client-side-caching/
3. https://github.com/redis/rueidis
4. https://github.com/valkey-io/valkey-go/tree/main/om
5. https://github.com/valkey-io/valkey-go/tree/main/valkeyaside
