# E2.04 · The three runtimes & interop

> Route: `/echomq/core/runtimes` · Movement I · The Core · chapter E2 `core`
> Hero back-link: `← redis-patterns R3` → `/redis-patterns/queues` (the E2 chapter-grounding marker).

One wire, three runtimes. EchoMQ's v1 line speaks the BullMQ wire — the `emq:` keyspace, `meta.version` =
`bullmq:5.65.1`, the same 50 Lua scripts — and three runtimes share it: the **Elixir reference** (`echo/apps/echomq`,
v`1.3.0`), the **Go port** (`apps/echomq-go`), and **Node.js**, which is the BullMQ reference implementation itself.
The Golden Rule holds across all three: L1 (the keyspace and field names) and L2 (the Lua scripts) are byte-identical;
only L3 (the executor) and L4 (the client API) differ per runtime.

## The Golden Rule, restated for runtimes

A runtime is free to drive the protocol however its host language drives best — OTP processes in Elixir, goroutines in
Go, an event loop in Node — but every runtime writes the same keys and runs the same scripts. That is why a job
enqueued by one runtime can be processed by another: the wire underneath does not move.

## The three runtimes, by status

| Runtime | Source | Status (the v1 line) |
|---|---|---|
| Elixir (the reference) | `echo/apps/echomq` v`1.3.0` | The reference runtime. Library-only — no own supervision tree; the host supervises it. Drives the wire with OTP processes (one BEAM process per job via `Task.async`; one `LockManager` timer per worker). |
| Go (the port) | `apps/echomq-go` | A partial port with two named, honest gaps: a **non-atomic add path** (the enqueue runs two separate commands where the reference runs one atomic Lua script), and the `attemptsMade`-vs-`atm` field-name nuance (a Go-side L4 tag, not a wire bug). It does carry a real cluster validator (`GetClusterSlot` + `ValidateHashTags`). |
| Node.js (the origin) | BullMQ upstream | The protocol's origin — the reference implementation EchoMQ rides. **EchoMQ has no first-party Node runtime today.** |

## The dives

1. **The Elixir architecture** — the reference runtime's L3/L4: library-only and host-supervised, one BEAM process per
   job (`Task.async`), the one-timer `LockManager`, the NimblePool connection, EVALSHA dispatch.
2. **The Go gaps** — the honest port status: the non-atomic add path, the `attemptsMade`/`atm` tag nuance
   (wire-correct, L4-different), and the cluster validator the Go port does carry.
3. **Cross-runtime interop** — v1 interop today (one job hash, shared scripts, the `atm` round-trip Elixir ⇄ Go) and
   the fleet's v2 trajectory: the fork, the proposed echomq-node, and Dragonfly as the v2 first-class substrate.

## Protocol → its runtimes (the Movement-I bridge)

- **The protocol (immutable L1/L2):** the `emq:` keyspace, the field names, and the 50 Lua scripts every transition
  runs — frozen, shared, the same in every runtime.
- **Its three runtimes (variable L3/L4):** Elixir drives the wire with supervised OTP processes; the Go port drives the
  same scripts with goroutines (with the named gaps); Node is the upstream reference. The wire does not move; the
  executor above it does.

**The take.** Three runtimes, one wire. The reference is Elixir, the port is Go (honestly partial), and the origin is
Node — and a job round-trips between any two that speak the same wire.

## The 2.0 fork — EchoMQ leaves the BullMQ wire

The shared wire above is the **v1 line (frozen at `1.3.0`)** — the BullMQ wire. emq.1 ships EchoMQ 2.0, which leaves it:
the `emq:` keyspace replaces `emq:`, every Lua key is declared in `KEYS[]`, the per-queue `{q}` hashtag is applied
transparently by the core, and `meta.version` becomes `echomq:2.0.0`. Interop then becomes the EchoMQ fleet's own:
stock BullMQ clients cannot speak v2 by design, the Go port must implement 2.0 to stay in the fleet, and a first-party
**echomq-node** is proposed (it does not exist). The payoff is Dragonfly-native multithreading.

## References

### Sources

- BullMQ — *Documentation* (`https://docs.bullmq.io/`) — the wire protocol, the lifecycle, and the Lua scripts the
  three runtimes share.
- Redis — *EVALSHA* (`https://redis.io/commands/evalsha/`) — the cached-script dispatch the Elixir reference uses.
- DragonflyDB — *Running BullMQ on Dragonfly* (`https://www.dragonflydb.io/docs/integrations/bullmq`) — the
  thread-per-shard substrate the v2 fork targets.
- DragonflyDB — *Server flags* (`https://www.dragonflydb.io/docs/managing-dragonfly/flags`) — `--lock_on_hashtags` and
  the `--default_lua_flags=allow-undeclared-keys` escape hatch.
- Redis — *Documentation* (`https://redis.io/docs/`) — the command and cluster reference underneath both runtimes.

### Related in this course

- `/echomq/core` — E2 · The core (the chapter landing).
- `/echomq/core/runtimes/the-elixir-architecture` — the Elixir reference runtime in depth.
- `/echomq/core/runtimes/the-go-gaps` — the honest Go port status.
- `/echomq/core/runtimes/cross-runtime-interop` — v1 interop and the v2 trajectory.
- `/redis-patterns/queues` — redis-patterns R3 · Reliable queues (the pattern these runtimes apply).
