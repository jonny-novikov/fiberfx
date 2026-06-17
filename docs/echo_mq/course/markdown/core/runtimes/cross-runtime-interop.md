# E2.04.3 · Cross-runtime interop

> Route: `/echomq/core/runtimes/cross-runtime-interop` · Movement I · The Core
> Hero back-link: `← redis-patterns R3` → `/redis-patterns/queues`.

Interop is what "one wire, three runtimes" buys: a job written by one runtime can be picked up and finished by another,
because both write the same keys and run the same scripts. This dive shows v1 interop as it works today, then the
fleet's v2 trajectory — the fork that makes interop the EchoMQ fleet's own.

## v1 interop today — one job hash, shared scripts

A standard job lives in one Redis hash at `emq:{queue}:{jobId}` with the same compressed field names in every
runtime — including `atm` (attempts made). The Go port and the Elixir reference write and read that field identically:

- Go writes `"atm": job.AttemptsMade` on the hash (`queue_impl.go` ~102) and reads `data["atm"]` back
  (`script_runner.go` ~160).
- Elixir's `EchoMQ.Job.from_redis/4` reads the same compressed fields (`atm`/`ats`/`stc`/`deid`/`defa`/`nrjid`).

So a job enqueued by Go and fetched by an Elixir worker — or the reverse — agrees on every field, because the field
names are L1 and the transition scripts are L2. The round-trip stepper below walks an `atm` field across runtimes: Go
writes it, Elixir reads it, processing increments it, the value is consistent throughout.

The honest seam: Node.js is the BullMQ reference implementation, and EchoMQ has **no first-party Node runtime today**.
v1 interop in practice is Elixir ⇄ Go ⇄ upstream-BullMQ-Node, all on the shared `emq:` wire.

## The v2 trajectory — the fork

The shared wire above is the **v1 line (frozen at `1.3.0`)**. emq.1 ships EchoMQ 2.0, which leaves the BullMQ wire
deliberately, once, and versioned:

- the `emq:` prefix replaces `emq:` — `emq:{q}:wait`, `emq:{q}:active`, `emq:{q}:{jobId}`, … ;
- the per-queue `{q}` hashtag is applied **transparently by the core** (a caller writes `Queue("orders")`, the core
  places `emq:{orders}:*`);
- the braced base prefix `{emq}:` is reserved for the core's own cross-queue keys, and `emq` is rejected as a queue
  name;
- every Lua key is declared in `KEYS[]`;
- `meta.version` becomes `echomq:2.0.0`, with a two-way boot fence that refuses cross-version contact.

The keyspace comparator below puts the two side by side over a fixed key list — `emq:orders:wait` (v1) against
`emq:{orders}:wait` (v2, the `{orders}` hashtag placed by the core). The v2 side is always what **emq.1 ships**, not
shipped code.

## The fleet — interop becomes EchoMQ's own

Once the wire is EchoMQ's own, interop is the fleet's own too:

- **Stock BullMQ clients cannot speak v2** — by design. That is the honest fleet seam; a v2 deployment never reads or
  writes `emq:*`.
- emq.1 ships a **fleet-interop probe**: a job enqueued by one first-party runtime is fetched and completed by another,
  both directions, with the harness runtime-pluggable. Honest status until then: Elixir is the only v2 speaker; the Go
  port must implement 2.0 to join.
- A first-party **echomq-node** is proposed — a Node.js runtime with the Dragonfly target and the same transparent
  `{key}` convention. It is proposed; it does not exist.

## Dragonfly — the v2 first-class substrate

The payoff of every key declared and every queue hashtagged is **DragonflyDB-native multithreading**. Dragonfly is
thread-per-shard: a key's `{hashtag}` decides its owning thread. With v2, `--lock_on_hashtags` locks precisely — one
queue per thread, distinct queues across cores — and the deployment never needs
`--default_lua_flags=allow-undeclared-keys`, the whole-store escape hatch that v1's undeclared keys would otherwise
force. The two flags are the v2 substrate's posture: require `--lock_on_hashtags`, never set the allow-undeclared-keys
flag.

## Pattern → implementation? No — protocol → its runtimes (the Movement-I bridge)

- **The protocol (immutable L1/L2):** one job hash, the same field names (`atm` …), the same transition scripts —
  shared, so a job round-trips between any two runtimes on the same wire.
- **Its three runtimes (variable L3/L4):** Elixir reads and writes the fields with OTP processes, the Go port with
  goroutines, and (in v2) the proposed echomq-node with its event loop — each a different executor over the same
  declared keys.

**The take.** v1 interop works today because the field names and scripts are shared. The v2 fork makes interop the
EchoMQ fleet's own — stock BullMQ clients out by design, the Go port to be ported, echomq-node proposed — with
Dragonfly the first-class multithreaded substrate the break unlocks.

## References

### Sources

- BullMQ — *Documentation* (`https://docs.bullmq.io/`) — the shared `emq:` wire and the job hash field set both
  runtimes use.
- Redis — *EVALSHA* (`https://redis.io/commands/evalsha/`) — the cached-script dispatch the shared scripts run through.
- DragonflyDB — *Running BullMQ on Dragonfly* (`https://www.dragonflydb.io/docs/integrations/bullmq`) — the
  thread-per-shard substrate the v2 fork targets first-class.
- DragonflyDB — *Server flags* (`https://www.dragonflydb.io/docs/managing-dragonfly/flags`) — `--lock_on_hashtags` and
  the `--default_lua_flags=allow-undeclared-keys` escape hatch the break avoids.
- Redis — *Documentation* (`https://redis.io/docs/`) — Redis Cluster and hash tags underneath both keyspaces.

### Related in this course

- `/echomq/core/runtimes` — E2.04 · The three runtimes & interop (the module hub).
- `/echomq/core/runtimes/the-elixir-architecture` — the reference runtime that speaks v2 first.
- `/echomq/core/runtimes/the-go-gaps` — the Go port's v2 porting work-list.
- `/echomq/protocol/job-hash/the-field-name-bug` — the `attemptsMade`/`atm` field round-trip in depth.
- `/redis-patterns/queues` — redis-patterns R3 · Reliable queues (the pattern the shared wire applies).
