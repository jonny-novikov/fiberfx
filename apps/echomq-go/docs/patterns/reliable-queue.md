# Reliable Queue

At-least-once delivery by atomically transferring a message from the main queue to a per-worker processing list, keeping the message in Redis until a successful handler explicitly removes it. A reaper process periodically scans processing lists for stalled owners and returns their messages to the main queue. Streams-era successor (`XREADGROUP` + `XAUTOCLAIM`) offers equivalent guarantees with richer semantics — this pattern documents both and marks the Streams variant as preferred when consumer groups, replay, or multi-consumer fanout are required.

**Primary use-case axis:** A — supervisor/worker messaging (at-least-once delivery with crash recovery).
**Secondary axes:** B (human-addressed work items such as draft-approval backlogs).

## Primitive

Two variants: the List-based legacy pattern and the Streams-based successor.

**List-based (legacy):**

- `LMOVE <src> <dst> LEFT RIGHT` (or `RIGHT LEFT`) — atomically transfer one message from one list to another in a single command. Per [`mercury reliable-queue.md §How It Works`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/reliable-queue.md.txt).
- `BLMOVE <src> <dst> LEFT RIGHT <timeout>` — blocking variant; waits up to `<timeout>` seconds for a message to arrive. Per [`mercury reliable-queue.md §Blocking Variant`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/reliable-queue.md.txt).
- `LREM <processing-list> 1 <message>` — acknowledgement after successful handler. Removes exactly one occurrence from the left.
- Reaper cron: periodically scans each processing list; if a message has been pending longer than a stall threshold, `LMOVE` it back into the main queue.

Semantics: at-least-once. Messages remain in Redis in some list (main queue or one processing list) at all times, so crashes between dequeue and ACK do not lose data. Duplicate processing is possible if a worker crashes after handling but before `LREM`; handlers must be idempotent.

**Streams-based (successor; preferred for multi-consumer / replay / consumer-group semantics):**

- `XREADGROUP GROUP <g> <consumer> BLOCK <ms> COUNT <n> STREAMS <stream> >` — dequeue (delivery without removal; entry moves to the consumer's Pending Entries List).
- `XACK <stream> <g> <entry-id>` — acknowledgement; removes the entry from the PEL. Equivalent of `LREM` in the List pattern.
- `XAUTOCLAIM <stream> <g> <consumer> <min-idle-ms> 0-0 COUNT <n>` — reaper equivalent; atomically scans the PEL for entries whose owner has been idle longer than `<min-idle-ms>` and transfers ownership.
- `XPENDING <stream> <g> - + <count> <consumer>` — introspect delivery counts; entries with `times-delivered > MAX_RETRIES` route to a deadletter stream per [`mercury streams-consumer-patterns.md §Poison Pill Handling`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-consumer-patterns.md.txt).

Semantics: at-least-once with better ergonomics. Streams support consumer groups (multi-worker load balancing with per-entry ownership tracking), replay (re-read from any id), and durable retention bounded by `MAXLEN ~ N`.

## Rose Tree + FTR-009 Application

FTR-009 adopts the Streams-based successor as its canonical reliable-queue shape:

- **Reader loop** — `XREADGROUP BLOCK 5000 COUNT 32` followed by handler execution and `XACK` on success. On handler error, entry stays in the PEL for `XAUTOCLAIM` recovery after 5 minutes of idleness. See [FTR-009 `reader-loop.md` §2-§4](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md).
- **Crash recovery** — consumer name bound to `<pid>-<boot_ns>` per [FTR-009 `mailbox-keyspace.md` §1 I-kspc-C](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) means a restarted process creates a fresh consumer; the prior consumer's PEL entries become `XAUTOCLAIM` candidates after 5 minutes.
- **Deadletter escalation** — entries with `times-delivered > 10` route to a `<stream>:deadletter` stream. See [FTR-009 `reader-loop.md` §4](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md).
- **Retention** — `MAXLEN ~ 1024` per mailbox stream bounds memory; out-of-band `XTRIM` not needed at steady state. See [FTR-009 `mailbox-keyspace.md` §1 I-kspc-A](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md).

FTR-009 does NOT use the List-based variant — `XAUTOCLAIM` subsumes `LMOVE` reaper cron, and consumer groups give multi-reader coordination that List semantics cannot provide natively.

**When the List-based variant would be the right choice (out of scope for FTR-009):**

- Small-scale FIFO work queues where a single worker is enough and `XREADGROUP` machinery is overkill.
- Simple ops tools where operational simplicity beats Streams' feature set.
- Environments with Redis < 5.0 (no Streams support).

## echomq-go code anchor

EchoMQ implements a hybrid: List-based wait/active queues + lock-based ownership tracking + stalled-job recovery via a cron. The mapping to this pattern:

- Wait list (FIFO input): [`../../pkg/echomq/keys.go:42-47`](../../pkg/echomq/keys.go) returns `bull:<queue>:wait` (or `bull:{<queue>}:wait` in cluster mode).
- Active list (processing queue): [`../../pkg/echomq/keys.go:65-71`](../../pkg/echomq/keys.go) returns `bull:<queue>:active`.
- Atomic dequeue + lock acquisition via Lua script: [`../../pkg/echomq/scripts/scripts.go:10-246`](../../pkg/echomq/scripts/scripts.go) — the `MoveToActive` script is BullMQ's reliable-dequeue equivalent. It atomically pops from `wait` (or `prioritized`), pushes to `active`, sets a lock key with TTL, and emits an `XADD event active jobId <id> prev waiting` event. The combination of atomic pop + lock-set replaces `LMOVE` and layers ownership tracking on top.
- Lock key TTL as ownership proof: [`../../pkg/echomq/scripts/scripts.go:136-139`](../../pkg/echomq/scripts/scripts.go) — `SET <lockKey> <token> PX <lockDuration>`. Worker heartbeat extends it; expiry means the worker died.
- Reaper cron (stalled-job detection): [`../../pkg/echomq/stalled.go`](../../pkg/echomq/stalled.go) — `checkStalledJobs` scans the active list, checks each job's lock-key existence, and on missing lock (expired TTL) increments attempts, LRem from active, and LPush back to wait. This is the `LMOVE`-reaper equivalent adapted to BullMQ's lock-based ownership model.
- Worker pickup entry point: [`../../pkg/echomq/worker_impl.go:76-128`](../../pkg/echomq/worker_impl.go) — `pickupJob` runs the `MoveToActive` Lua script and launches a handler goroutine.
- Lock heartbeat to extend TTL during processing: [`../../pkg/echomq/heartbeat.go:60-105`](../../pkg/echomq/heartbeat.go) — the `heartbeatLoop` runs the `ExtendLock` Lua script every `HeartbeatInterval` (default 15s, half of the 30s lock TTL).

BullMQ's hybrid ships most of the Streams-successor's guarantees (ownership tracking, crash recovery, retry escalation, deadletter via `failed` ZSET) on a List substrate because BullMQ predates the XAUTOCLAIM surface.

## Antipatterns avoided

**1. Naive RPOP-then-process.** A consumer that does `RPOP <queue>` and then processes the returned message loses the message forever if it crashes before handling completes. Per [`mercury reliable-queue.md §The Problem with Simple Queues`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/reliable-queue.md.txt), the fix is `LMOVE <queue> <processing-list>` so the message is never absent from Redis.

**2. Processing list without a reaper.** `LMOVE` into a processing list protects against consumer crash, but without a reaper the message stays in the processing list forever after the crash. The reaper cron scans and returns stalled messages. EchoMQ's `stalled.go` is the reference implementation for the lock-based ownership variant.

**3. Non-idempotent handlers.** At-least-once delivery means handlers may run twice for the same message (worker crash after handling but before ACK → reaper returns it). Per [echomq-go `CLAUDE.md §Idempotency`](../../CLAUDE.md), the library guarantees at-least-once, not exactly-once — handlers MUST be idempotent via idempotency keys, database unique constraints, or external idempotency tokens.

**4. Mixing consumer-group ACK with manual XDEL.** Streams-based variant uses `XACK` to clear the PEL and `MAXLEN ~` for memory. A consumer that `XACK`s and then `XDEL`s the entry creates Swiss-cheese fragmentation — per [`mercury streams-consumer-patterns.md §Memory Management`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-consumer-patterns.md.txt), `XDEL` cannot reclaim memory until the whole macro-node is empty.

## Cross-references

FTR consumers:

- [FTR-009 `reader-loop.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md) — XAUTOCLAIM-based reaper pattern
- [FTR-009 `mailbox-keyspace.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) — mailbox stream + consumer group as reliable-queue substrate
- [FTR-009 `teammate-lifecycle.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md) — state gating on shutdown
- FTR-010 (future) — draft-approval queue may use this pattern
- FTR-007 `dev/mcp/features/FTR-007-mcp-shim/` — MCP shim consumes queued work via reliable-queue substrate

Sibling patterns:

- [`streams-consumer-groups.md`](streams-consumer-groups.md) — the primary Streams-based variant (preferred when consumer-groups semantics are needed)
- [`streams-event-sourcing.md`](streams-event-sourcing.md) — event-sourcing projection surface on the same substrate
- [`atomic-updates.md`](atomic-updates.md) — Lua-script atomicity for the BullMQ `MoveToActive` pickup
- [`delayed-queue.md`](delayed-queue.md) — ZSET-based scheduled-task variant; complements the at-least-once shape with time-based triggers
- [`hash-tag-colocation.md`](hash-tag-colocation.md) — required for cluster-mode multi-key Lua scripts over wait/active/events keys

Mercury-design source:

- [`fundamental/reliable-queue.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/reliable-queue.md.txt) — List-based primitive reference
- [`fundamental/streams-consumer-patterns.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-consumer-patterns.md.txt) — Streams successor + XAUTOCLAIM + deadletter

## Worked example

List-based variant (the legacy pattern mercury-design describes):

```bash
# Producer — push message to work queue
LPUSH work_queue "msg:job-123"

# Consumer — atomic dequeue into per-worker processing list
LMOVE work_queue processing:worker1 RIGHT LEFT
# Returns: "msg:job-123"

# Consumer processes the message (application logic)
# ...

# Consumer — acknowledge by removing from processing list
LREM processing:worker1 1 "msg:job-123"

# Blocking variant — wait up to 30s for a message
BLMOVE work_queue processing:worker1 RIGHT LEFT 30

# Reaper cron — scan processing lists for stalled messages
# (pseudocode — implemented as a separate monitor process)
for worker in 1..N:
    LRANGE processing:worker<N> 0 -1   # inspect
    # for each message present longer than timeout:
    LMOVE processing:worker<N> work_queue RIGHT RIGHT  # return for redelivery
```

Streams-based successor (the FTR-009 canonical shape):

```bash
# Producer — append to the mailbox stream
XADD cclin:mbox:flyer-a1:mars-3:stream MAXLEN \~ 1024 * \
     from director to mars-3 body '{"job":"scan"}' kind direct

# Consumer — dequeue with BLOCK + COUNT
XREADGROUP GROUP cclin:mbox:flyer-a1:mars-3:stream:grp 12345-boot_ns_0001 \
           BLOCK 5000 COUNT 32 \
           STREAMS cclin:mbox:flyer-a1:mars-3:stream >

# Consumer acknowledges on handler success
XACK cclin:mbox:flyer-a1:mars-3:stream \
     cclin:mbox:flyer-a1:mars-3:stream:grp 1714000000000-0

# Reaper equivalent — XAUTOCLAIM runs in a janitor goroutine every 2 minutes
XAUTOCLAIM cclin:mbox:flyer-a1:mars-3:stream \
           cclin:mbox:flyer-a1:mars-3:stream:grp \
           12345-boot_ns_0001 300000 0-0 COUNT 32

# Poison-pill escalation — entries delivered > 10 times reroute
XPENDING cclin:mbox:flyer-a1:mars-3:stream \
         cclin:mbox:flyer-a1:mars-3:stream:grp - + 100 12345-boot_ns_0001
# For each entry with times-delivered > 10:
XADD <stream>:deadletter * original_id <id> reason "max-delivery-exceeded" ...
XACK <stream> <group> <id>
```

BullMQ hybrid (as implemented in echomq-go; mirrors [`stalled.go`](../../pkg/echomq/stalled.go)):

```go
// Dequeue + lock acquisition via MoveToActive Lua script
cmd := moveToActiveScript.Run(ctx, w.redisClient, keys, args...)
result, _ := parseMoveToActiveResult(cmd, ...)
job := result.Job

// Handler runs with heartbeat extending the lock every 15s
// (see heartbeat.go:60-105 for ExtendLock Lua script usage)

// Reaper (stalled.go) — scan active list, check each lock, recover expired
activeJobs, _ := redis.LRange(ctx, kb.Active(), 0, -1).Result()
for _, jobID := range activeJobs {
    if redis.Exists(ctx, kb.Lock(jobID)).Val() == 0 {
        // Lock expired → job stalled
        redis.LRem(ctx, kb.Active(), 1, jobID)
        redis.LPush(ctx, kb.Wait(), jobID)  // return for retry
    }
}
```
