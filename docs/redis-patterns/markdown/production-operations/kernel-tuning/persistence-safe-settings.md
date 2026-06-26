# Durable on a crash, never silently losing work

> R8.01.3 · Kernel tuning — dive 3 · route `/redis-patterns/production-operations/kernel-tuning/persistence-safe-settings`

A job store has two ways to lose work that a benchmark never shows: it crashes and discards the writes it
acknowledged, or it fills up and quietly evicts the keys it was holding. Both end the same way — a queue that
reported success and then dropped the work. The settings on this page close both gaps. They turn a store that fails
*quietly* into one that fails *loudly*: it bounds its crash loss to about a second, rejects new writes when it is
out of room instead of throwing old ones away, and refuses to acknowledge data it cannot promise to survive. The
same posture extends to the socket — a dropped connection is dropped work, so the listen queue and the
file-descriptor ceiling are raised to accept a burst rather than drop it.

This dive owns durability-without-losing-work and staying-connected. The fork's copy-on-write spike during an AOF
rewrite is dive 1 (THP and overcommit); the lazy-free thread and swap story is dive 2 (latency spikes). The gold
here is the persistence, memory, and network blocks of the real `infra/valkey/conf/valkey.conf` that fronts the
codemojex queue.

## §1 — The append-only log and the loss bound

The first question of durability is: after a crash, how much acknowledged work is gone. With an append-only log
turned on and an fsync cadence of once a second, the answer is bounded and small.

```
appendonly yes
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-use-rdb-preamble yes
save ""
```

`appendonly yes` makes the volume hold an append-only file: every write that changes the keyspace is appended to a
log on disk. `appendfsync everysec` flushes that log to the disk once a second on a background thread. The BCS
manuscript states the bound directly: *"With `appendonly` on and `appendfsync everysec`, the volume holds an
append-only log and the loss bound after a crash is roughly one second of writes, not a whole snapshot interval"*
(B8.2). A snapshot-only store loses everything written since the last snapshot — minutes of work; the append-only
log narrows that window to about one second.

`aof-use-rdb-preamble yes` lets the periodic rewrite start from a compact binary preamble rather than replaying
every command, so the rewrite is fast and the file stays small. `save ""` turns snapshotting off on purpose: with
the append-only file as the single source of durability, there is no reason to keep a second snapshot fork
competing for the machine. One fork source, one durability mechanism. (The copy-on-write spike of that one rewrite
fork is dive 1's subject, not repeated here.)

## §2 — Reject, do not evict

The second way a job store loses work is memory pressure. When a store fills up it must choose: throw old keys
away to make room, or refuse the new write. For a cache the first is fine — an evicted key is only a future miss.
For a queue it is a silent data-loss bug.

```
maxmemory 512mb
maxmemory-policy noeviction
maxmemory-clients 64mb
```

`maxmemory 512mb` is a loud guardrail, not a working ceiling — the live dataset is single-digit megabytes, so 512
sits far above it and leaves the rest of the box for fork copy-on-write and client buffers. `maxmemory-policy
noeviction` is the load-bearing line. The config's own comment names the trade: *"`noeviction` means a runaway
keyspace REJECTS writes loudly instead of being OOM-killed silently."* The manuscript states the principle: *"a
queue that silently drops keys is a queue that silently loses work, so memory pressure must surface as write errors
and alerts"* (B8.2). Under `noeviction`, a write that would exceed `maxmemory` returns an error to the caller — a
signal to alert on — rather than discarding a job that something already enqueued.

`maxmemory-clients 64mb` caps the memory a single client's buffers may hold, so one slow or stuck consumer cannot
drive the whole instance into that pressure on its own.

## §3 — Fail loudly

Rejecting writes under memory pressure is one half of failing loudly. The other half is refusing to acknowledge
data the store cannot promise to keep, and giving the log a chance to flush on the way down.

```
propagation-error-behavior panic
shutdown-timeout 10
```

`propagation-error-behavior panic` is the strictest possible posture, and the config states why in one line: *"Fail
the write rather than acknowledge data that may not survive."* If a write cannot be propagated where it must go,
the server fails the write rather than returning a success the data does not back. A false acknowledgement is worse
than a visible error — the caller that hears "OK" stops worrying about the job; an error makes it retry.

`shutdown-timeout 10` covers the orderly exit. On a `SIGTERM` — the signal a deploy or a platform sends to stop the
process — the server is given ten seconds to flush the append-only file before the platform forces it down. The
config's comment: *"Give the AOF a chance to flush on SIGTERM."* Without that window, a rolling deploy could discard
the last unflushed second on every restart.

## §4 — Staying connected

A dropped connection is dropped work, so the network settings take the same posture as the persistence ones: accept
the burst rather than drop it. These are the connection-survival half of the source's kernel-tuning guide.

```
tcp-backlog 511
tcp-keepalive 300
client-output-buffer-limit pubsub 32mb 8mb 60
```

`tcp-backlog` sets the listen queue for incoming connections. The source's kernel-tuning guide warns that the Linux
default is **128**, so during a traffic spike new connections are dropped before the server ever sees them. The
effective backlog is `min(tcp-backlog, somaxconn)` — both the application's `tcp-backlog` and the kernel's
`net.core.somaxconn` must be raised, or whichever is smaller caps the queue. `somaxconn` and the other kernel knobs
are set on the host, not in this file:

```sh
# /etc/sysctl.conf — the kernel half of the connection-survival pair
net.core.somaxconn=65536
net.ipv4.tcp_max_syn_backlog=65536

# the file-descriptor ceiling (systemd unit) — each connection costs one fd
LimitNOFILE=65536
```

The source sets `somaxconn` to **65536** so the kernel's queue is never the limit, and raises the
file-descriptor ceiling to **65536** because each connection consumes one file descriptor and a server's
`maxclients` is bounded by the descriptors available to it. `tcp-keepalive 300` sends a keepalive every 300 seconds
so a load balancer or firewall does not silently reap a long-lived idle connection. `client-output-buffer-limit
pubsub 32mb 8mb 60` bounds a subscriber's output buffer, so a slow subscriber is dropped rather than allowed to
grow the server's memory without limit.

## §5 — Beneath the volatile tier

The settings above bound the queue's crash loss to about one second. That is the right floor for a volatile
work tier, but it is not the whole durability story. Deep history and off-box durability live one tier down, on the
persistence floor: when the bus trims a stream, `EchoStore.StreamArchive` folds the trimmed segments into
`EchoStore.Graft`'s append-only CubDB at a reserved high page range, and a streamer ships those pages on to Tigris
object storage — deep history without resident memory (B5). The volatile tier keeps the last second; the durable
floor keeps everything, addressable beside the live tail. That floor is its own course — the `/echo-persistence`
door carries it; this page stays on the `valkey.conf` that fronts the queue.

## §6 — Recap

A durable job store is one that fails loudly. The append-only log with `appendfsync everysec` bounds crash loss to
about a second; `noeviction` makes memory pressure a rejected write and an alert instead of a silently dropped key;
`propagation-error-behavior panic` refuses to acknowledge data that may not survive; `shutdown-timeout 10` flushes
the log on the way down; and a raised `tcp-backlog`/`somaxconn` pair and file-descriptor ceiling accept a
connection burst rather than drop it. Every one of these settings is in the real `valkey.conf` (or the host sysctls
beside it) that fronts the codemojex queue.

## References

### Sources

- [Valkey — Persistence (RDB and the append-only file)](https://valkey.io/topics/persistence/) — the
  `appendonly` everysec posture and the roughly one-second loss bound after a crash.
- [Valkey — SHUTDOWN](https://valkey.io/commands/shutdown/) — the orderly stop that `shutdown-timeout` bounds, giving
  the append-only file a chance to flush on `SIGTERM`.
- [Redis — Persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/) — RDB and AOF,
  the fsync policies, and the durability trade the append-only file makes.
- [Redis — Documentation](https://redis.io/docs/) — the production guidance: overcommit, the listen backlog,
  file-descriptor limits, and the startup warnings.
- [Shopify, Netflix, Uber, AWS — production Redis kernel tuning](https://redis.io/docs/) — the source case study
  behind the connection-survival figures: the 128 listen-queue default, `somaxconn` at 65536, and `LimitNOFILE` at
  65536.

### Related in this course

- `/redis-patterns/production-operations/kernel-tuning` — R8.01 · Kernel tuning (the module hub).
- `/redis-patterns/production-operations/kernel-tuning/latency-spikes` — R8.01.2 · Latency spikes (swap, threads,
  defrag — the previous dive).
- `/redis-patterns/production-operations` — R8 · Production & Operations (the chapter).
- `/echo-persistence` — the persistence floor: the durable tier beneath the volatile queue.
- `/bcs/fly` — BCS · Production on Fly: Valkey on a Fly machine, the append-only log, and the kernel tuned away from
  its defaults.
