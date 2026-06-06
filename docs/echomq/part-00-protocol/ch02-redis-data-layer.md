# Chapter 02. Redis Data Layer

## 2.1. Data Structure Taxonomy

The EchoMQ protocol uses 8 Redis data types across ~25 key patterns. All keys follow the format `bull:{queueName}:{suffix}` with hash tags ensuring Redis Cluster slot co-location.

### Queue-Level Structures

| Structure | Redis Type | Key Pattern | Purpose |
|-----------|-----------|-------------|---------|
| **Wait Queue** | LIST | `bull:{queue}:wait` | FIFO queue for standard jobs |
| **Paused Queue** | LIST | `bull:{queue}:paused` | Holds jobs when queue is paused |
| **Active Queue** | LIST | `bull:{queue}:active` | Jobs currently being processed |
| **Prioritized Queue** | ZSET | `bull:{queue}:prioritized` | Priority-ordered jobs (score = priority) |
| **Delayed Queue** | ZSET | `bull:{queue}:delayed` | Time-scheduled jobs (score = timestamp ms) |
| **Completed Set** | ZSET | `bull:{queue}:completed` | Terminal state — success (score = timestamp) |
| **Failed Set** | ZSET | `bull:{queue}:failed` | Terminal state — failure (score = timestamp) |
| **Waiting-Children** | ZSET | `bull:{queue}:waiting-children` | Parent jobs awaiting child completion |
| **Stalled Set** | SET | `bull:{queue}:stalled` | Stalled job markers for detection |
| **Stalled Check** | STRING | `bull:{queue}:stalled-check` | Timestamp of last stalled check |
| **Queue ID Counter** | STRING | `bull:{queue}:id` | Auto-increment counter for job IDs |
| **Queue Metadata** | HASH | `bull:{queue}:meta` | Queue config (paused, concurrency, version, rate limit) |
| **Events Stream** | STREAM | `bull:{queue}:events` | Real-time event log (~10,000 entries) |
| **Rate Limiter** | STRING | `bull:{queue}:limiter` | Rate limit counter with TTL |
| **Priority Counter** | STRING | `bull:{queue}:pc` | Priority counter for ordering within priority levels |
| **Marker** | ZSET | `bull:{queue}:marker` | Notification marker for blocking workers |
| **Repeat/Scheduler** | ZSET | `bull:{queue}:repeat` | Job scheduler metadata |
| **Deduplication** | STRING | `bull:{queue}:de:{id}` | Deduplication keys with TTL |
| **Metrics** | STRING/LIST | `bull:{queue}:metrics:*` | Completed/failed metrics |

### Job-Level Structures

| Structure | Redis Type | Key Pattern | Purpose |
|-----------|-----------|-------------|---------|
| **Job Hash** | HASH | `bull:{queue}:{jobId}` | All job data and metadata |
| **Job Lock** | STRING | `bull:{queue}:{jobId}:lock` | Distributed lock (value = UUID token, TTL-based) |
| **Job Logs** | LIST | `bull:{queue}:{jobId}:logs` | Per-job log entries |
| **Job Dependencies** | SET | `bull:{queue}:{jobId}:dependencies` | Unprocessed child job keys |
| **Job Processed** | HASH | `bull:{queue}:{jobId}:processed` | Completed child results |
| **Job Failed Children** | HASH | `bull:{queue}:{jobId}:failed` | Ignored child failures |
| **Job Unsuccessful** | ZSET | `bull:{queue}:{jobId}:unsuccessful` | Failed child job keys |

## 2.2. Job Hash Schema

The job hash (`bull:{queue}:{jobId}`) stores all job data and metadata as HASH fields:

### Required Fields (Set on Creation)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Job name/type identifier |
| `data` | JSON string | Job payload (application data) |
| `opts` | JSON string | Job options (stored as JSON, transmitted as msgpack) |
| `timestamp` | string (ms) | Creation timestamp in milliseconds |
| `delay` | string (ms) | Delay value in milliseconds (0 for immediate) |
| `priority` | string | Priority value (0 = highest, 2^21 = lowest) |

### Fields Set by Lua Scripts During Processing

| Field | Type | Description |
|-------|------|-------------|
| `ats` | string | Attempts started (HINCRBY in `prepareJobForProcessing`) |
| `atm` | string | Attempts made (HINCRBY in `moveToFinished`) |
| `stc` | string | Stalled counter (incremented on stall detection) |
| `pb` | string | Processed by (worker name identifier) |
| `processedOn` | string (ms) | Processing start timestamp |
| `finishedOn` | string (ms) | Completion timestamp |
| `returnvalue` | JSON string | Success result (**LOWERCASE** — critical for interop) |
| `failedReason` | string | Error message on failure |
| `stacktrace` | JSON array string | Error stacktraces (serialized JSON array) |

### Optional Fields (Set on Creation)

| Field | Type | Description |
|-------|------|-------------|
| `parentKey` | string | Parent job's full Redis key |
| `parent` | JSON string | Parent metadata `{id, queueKey}` |
| `rjk` | string | Repeat job key |
| `deid` | string | Deduplication ID |
| `defa` | string | Deferred failure message |
| `nrjid` | string | Next repeatable job ID |

### Progress Field

| Field | Type | Description |
|-------|------|-------------|
| `progress` | string or JSON | Job progress — can be a number (0-100) or a JSON object |

## 2.3. Redis Cluster Support

### Hash Tag Strategy

All keys for a queue are co-located in the same Redis Cluster slot by embedding the queue name in hash tags. The key format `bull:{queueName}:suffix` naturally provides this because Redis Cluster hashes only the content within `{...}`.

This is essential because Lua scripts access multiple keys atomically — CROSSSLOT errors will occur if keys map to different nodes.

### Slot Calculation

Redis Cluster uses CRC16-CCITT to map keys to 16,384 slots:

```
slot = CRC16(hash_tag) % 16384
```

For key `bull:{myqueue}:wait`, the hash tag is `myqueue`, so:
```
slot = CRC16("myqueue") % 16384
```

All keys with the same queue name map to the same slot, enabling Lua script execution.

### Implementation Requirements

| Requirement | Details |
|-------------|---------|
| Auto-detection | Detect `*redis.ClusterClient` vs `*redis.Client` at runtime |
| Hash tag validation | Verify all keys in a Lua KEYS array share the same hash tag |
| CROSSSLOT prevention | Reject operations that would span multiple slots |

## 2.4. Queue Metadata Hash

The `bull:{queue}:meta` hash stores queue-level configuration:

| Field | Type | Description |
|-------|------|-------------|
| `paused` | `"0"` / `"1"` | Whether the queue is paused |
| `concurrency` | string (int) | Global concurrency limit |
| `version` | string | Implementation version identifier |
| `max` | string (int) | Rate limit max operations |
| `duration` | string (ms) | Rate limit window duration |
| `maxLenEvents` | string (int) | Event stream MAXLEN (default ~10,000) |

## 2.5. Event Stream Format

Events are emitted to `bull:{queue}:events` Redis STREAM via XADD with approximate MAXLEN trimming (~10,000 entries).

### Event Types

| Event | Fields | Trigger |
|-------|--------|---------|
| `added` | jobId, name | Job stored in hash |
| `waiting` | jobId | Job added to wait list |
| `active` | jobId, prev=waiting | Job moved to active |
| `progress` | jobId, progress | Progress updated |
| `completed` | jobId, returnvalue, prev=active | Job completed successfully |
| `failed` | jobId, failedReason, prev=active | Job processing failed |
| `retries-exhausted` | jobId, attemptsMade | Max retries reached |
| `stalled` | jobId | Stalled job detected |
| `delayed` | jobId | Job moved to delayed |
| `paused` | — | Queue paused |
| `resumed` | — | Queue resumed |
| `drained` | — | All jobs processed |
| `cleaned` | count | Old jobs cleaned |
| `removed` | jobId | Job removed |

### Stream Retention

Default: `MAXLEN ~ 10000` (approximate trimming for performance).

Configurable via `meta.opts.maxLenEvents`. The `~` prefix uses approximate trimming, which is more efficient than exact trimming at the cost of keeping slightly more entries.

### Consuming Events

Events are consumed via Redis XREAD (blocking or polling). Each implementation provides its own event consumer:

| Implementation | Pattern |
|---------------|---------|
| **Node.js** | `QueueEvents` class with EventEmitter |
| **Elixir** | `QueueEvents` GenServer with process mailbox subscription |
| **Go** | Not yet implemented (planned: goroutine-based XREAD loop) |

## 2.6. Rate Limiting

### Per-Worker Rate Limiting

The `moveToActive` Lua script enforces rate limiting via the `bull:{queue}:limiter` key:

1. Check if limiter counter exceeds `max` within `duration` window
2. If exceeded, move job to wait list instead of active
3. The limiter key has TTL equal to `duration`

### Global Rate Limiting

The `meta` hash stores global rate limit config (`max` and `duration` fields). The Lua scripts check these values before activating jobs.

## 2.7. Priority System

### Priority Counter (`pc` Key)

The `bull:{queue}:pc` key is a STRING counter that provides fine-grained ordering within the same priority level. Each job at a given priority gets a unique counter value, ensuring FIFO ordering among same-priority jobs.

The ZSET score for prioritized jobs combines the priority value with the counter:

```
score = priority * priority_counter_scale + counter
```

This ensures:
- Lower priority value = higher priority (0 is highest)
- Within same priority level, jobs are FIFO ordered by counter

### Marker ZSET

The `bull:{queue}:marker` ZSET is used for efficient worker notification. When a new job is added, a marker entry is written. Workers use `BZPOPMIN` on this ZSET for blocking wait, avoiding polling overhead.

---

*Previous: [Unified Protocol](ch01-unified-protocol.md) | Next: [Job Lifecycle](ch03-job-lifecycle.md)*
