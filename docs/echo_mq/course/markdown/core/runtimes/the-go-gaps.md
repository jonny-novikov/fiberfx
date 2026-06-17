# E2.04.2 · The Go gaps

> Route: `/echomq/core/runtimes/the-go-gaps` · Movement I · The Core
> Hero back-link: `← redis-patterns R3` → `/redis-patterns/queues`.

The Go port (`apps/echomq-go`) speaks the same `emq:` wire as the Elixir reference — but it is partial, and the depth
course names the gaps rather than smoothing them. Two are real, one is a nuance often mistaken for a third, and the Go
port also carries one piece the Elixir runtime does not.

## Gap one — the non-atomic add path

On the Elixir reference, enqueuing a standard job runs **one** atomic Lua script — `addStandardJob-9.lua`, via
`Scripts.add_standard_job` (`scripts.ex` line ~435). The job hash is written and the id pushed onto the wait list in a
single round-trip that either fully happens or does not.

The Go port's add path runs **two separate commands**: `addJobToQueue` writes the hash with `HSet` (`queue_impl.go`
line ~105), and then `enqueueJob` pushes the id with a separate `LPush` (or `ZAdd` for delayed/priority,
`queue_impl.go` line ~137):

```go
// addJobToQueue — first command
return q.redisClient.HSet(ctx, key, fields).Err()
// enqueueJob — second, separate command
return q.redisClient.LPush(ctx, q.keyBuilder.Wait(), job.ID).Err()
```

Where the protocol expects one atomic script, the Go port issues two commands. A failure between them can leave a job
hash with no list entry. This is the **non-atomic critical path** — a real porting gap, reported, not glossed.

(The Go port's *fetch* path is atomic: the worker pickup runs the `moveToActive` Lua script — `worker_impl.go` line
~112 — so the gap is on the add side, not the pickup side.)

## Gap two (the nuance) — `attemptsMade` vs `atm`

A common worry is that the Go port writes the wrong field name. It does not. The Go port **writes and reads `atm`** on
the Redis hash, exactly as the wire requires:

```go
// queue_impl.go ~102 — write
"atm": job.AttemptsMade,
// script_runner.go ~160 — read
if attemptsMade, ok := data["atm"]; ok { fmt.Sscanf(attemptsMade, "%d", &job.AttemptsMade) }
```

Only the Go struct's external **JSON tag** is `attemptsMade` (`job.go` line 22):

```go
AttemptsMade int `json:"attemptsMade"`
```

That tag is an **L4 surface** — how a Go program serialises the struct to its own callers — not the wire. The Redis
field round-trips as `atm` in both directions, so a job written by Go and read by Elixir agrees on the field. This was
convergently verified twice: it is a serialisation tag, not a wire bug.

## What the Go port does carry — the cluster validator

The Go port carries a real Redis Cluster slot validator the Elixir runtime lacks. `pkg/echomq/cluster.go` implements
`GetClusterSlot` and `ValidateHashTags`, with `RedisClusterSlots = 16384`:

- `GetClusterSlot(key)` extracts the `{hashtag}` (the content between the first `{` and the next `}`), computes the
  CRC16 of that substring, and returns `crc % 16384`.
- `ValidateHashTags(keys)` confirms every key in a multi-key script hashes to the **same** slot — the precondition for
  running a multi-key Lua script on a Redis Cluster.

The rule is `slot = CRC16(hashtag) % 16384`; keys that share a hashtag share a slot. The slot checker below
demonstrates the rule over a fixed key list — same hashtag ⇒ same slot ⇒ a multi-key script is safe.

## Protocol → its Go runtime (the Movement-I bridge)

- **The protocol (immutable L1/L2):** the `emq:` keyspace and the field names — including `atm` on the hash — frozen
  and shared. A multi-key transition is one atomic script.
- **Its Go runtime (variable L3/L4):** a partial port — the add path runs two separate commands (the non-atomic gap),
  the `attemptsMade` JSON tag is an L4 serialisation choice over the `atm` field, and it adds a CRC16-based cluster slot
  validator the reference lacks.

**The take.** The Go port is honestly partial: a non-atomic add path is a real gap, the `attemptsMade`/`atm` mismatch
is an L4 tag and not a wire bug, and the cluster validator is a genuine Go-side addition. A depth course names all
three.

## The 2.0 fork — EchoMQ leaves the BullMQ wire

The gaps above are measured against the **v1 line (frozen at `1.3.0`)** — the BullMQ wire. emq.1 ships EchoMQ 2.0, and
the Go port must implement 2.0 to stay in the fleet: the v2 declared-keys script set, the `emq:{q}:…` keyspace, and the
transparent `{q}` hashtag. The Go port's gap list is its porting work-list for v2 — the non-atomic add path becomes a
v2 atomic script, and the cluster validator it already carries is exactly the placement check the v2 hashtag design
formalises. emq.1's fleet-interop probe tracks the port's v2 status honestly until it lands.

## References

### Sources

- BullMQ — *Documentation* (`https://docs.bullmq.io/`) — the atomic add and fetch scripts the Go port partially ports.
- Redis — *EVALSHA* (`https://redis.io/commands/evalsha/`) — the cached-script dispatch the atomic fetch path uses.
- Redis — *Documentation* (`https://redis.io/docs/`) — Redis Cluster, hash tags, and the CRC16 slot scheme the
  validator implements.

### Related in this course

- `/echomq/core/runtimes` — E2.04 · The three runtimes & interop (the module hub).
- `/echomq/core/runtimes/the-elixir-architecture` — the reference runtime the gaps are measured against.
- `/echomq/core/runtimes/cross-runtime-interop` — the `atm` field round-trip Elixir ⇄ Go in full.
- `/redis-patterns/queues` — redis-patterns R3 · Reliable queues (the atomic-transition pattern the gaps touch).
