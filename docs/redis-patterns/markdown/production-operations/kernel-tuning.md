# Linux kernel tuning for Redis

> R8.01 · Production & Operations — module hub · route `/redis-patterns/production-operations/kernel-tuning`

Configure Linux kernel parameters to prevent latency spikes, persistence failures, and connection drops in
production Redis deployments — essential settings that override defaults hostile to in-memory databases.

Standard Linux kernel defaults are tuned for general workloads, not in-memory databases. A production Valkey
instance reaches consistent sub-millisecond latency only after a handful of host settings are changed away from
those defaults — and a second, application-level half lives in the server's own config file.

Grounding: the production case study in `docs/redis-patterns/content/production/kernel-tuning.md.txt` (the THP
amplification, the overcommit premise, the swappiness and TCP figures), the real
`infra/valkey/conf/valkey.conf` that backs EchoMQ's Valkey on Fly (the io-threads, lazyfree, AOF, noeviction,
and activedefrag posture, quoted verbatim), and the BCS manuscript B8.2 (`docs/echo/bcs/bcs.8.md` — the kernel
tuned away from its defaults, stated from the inside). The engine is Valkey 9; the host sysctls and the config
file are two halves of one posture.

## §1 · Transparent Huge Pages (THP)

THP is the most critical setting. When enabled, it causes severe latency spikes during persistence operations.

Valkey uses `fork()` to create a child process for an AOF rewrite (and, on engines that snapshot, for the RDB
save). Linux uses copy-on-write to share memory between parent and child. With THP enabled, the kernel hands
out 2 MB pages instead of 4 KB pages. When the parent modifies a single byte during the rewrite window, the
kernel must copy the entire 2 MB page — the source records this as a **500x amplification** of the copy.

The symptoms the source lists: latency spikes of 10–100x during a background save, memory usage doubling
temporarily during persistence, and client timeouts while the save runs.

THP is a **kernel** setting, not a server one. Turn it off at the host:

```
echo never > /sys/kernel/mm/transparent_hugepage/enabled
```

Make it permanent through systemd:

```
[Service]
ExecStartPre=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
```

The server logs a warning at startup if THP is enabled. The source's instruction is to never ignore it.

## §2 · Memory Overcommit

The `fork()` system call can fail if the kernel thinks there is insufficient memory.

When the server forks, the kernel may pessimistically assume the child needs as much memory as the parent. The
source's example: on a 32 GB instance with 30 GB used, the fork can fail even though copy-on-write means little
real memory is actually needed.

Overcommit is a **kernel** sysctl. Set it so the kernel always allows the allocation request, trusting that
copy-on-write keeps the real cost small:

```
sysctl vm.overcommit_memory=1
```

Persist it in `/etc/sysctl.conf`:

```
vm.overcommit_memory=1
```

## §3 · Swappiness

Data in swap is a catastrophic failure mode.

If any of the server's memory pages are swapped to disk, access times go from nanoseconds to milliseconds — the
source measures this as a **1,000,000x slowdown**. A single swapped page can cause client timeouts.

Swappiness is a **kernel** sysctl. The source sets it to 1 — not 0, because 0 can cause OOM kills; 1 makes
swapping extremely unlikely while still allowing the kernel to swap in a desperate situation:

```
sysctl vm.swappiness=1
```

## §4 · TCP Stack Tuning

Under high connection rates, default TCP settings cause connection failures.

The listen queue for incoming connections defaults to 128. During traffic spikes, new connections are dropped
before the server ever sees them. Two of these are **kernel** sysctls and one is a **server** setting, and they
interact: the effective backlog is `min(tcp-backlog, somaxconn)`. Raise both:

```
sysctl net.core.somaxconn=65536
sysctl net.ipv4.tcp_max_syn_backlog=65536
```

Set the server-side backlog in the config file:

```
tcp-backlog 65536
```

For long-lived connections through a load balancer, keepalives stop an idle connection from being terminated;
the source sets the server to send them every 300 seconds:

```
tcp-keepalive 300
```

## §5 · File Descriptor Limits

Each connection consumes a file descriptor.

The source raises the limit for the service account so a burst of clients is accepted rather than refused. In
the systemd service file:

```
[Service]
LimitNOFILE=65536
```

The server's `maxclients` is bounded by the available file descriptors minus roughly 32 reserved for internal
use.

## §6 · Memory Allocator

The engine uses jemalloc, which is well-suited to its allocation pattern. The source names two behaviours to
watch. After deleting a large amount of data, jemalloc retains memory to satisfy future allocations, so the
process RSS reflects peak usage rather than the current dataset size. And fragmentation shows up in
`mem_fragmentation_ratio` (read from `INFO MEMORY`):

- below 1.0 — the process is using swap (critical),
- 1.0–1.5 — normal,
- above 1.5 — significant fragmentation.

When fragmentation is high, active defragmentation relocates live objects so empty pages can be returned to the
OS. It is a **server** setting:

```
activedefrag yes
```

## On EchoMQ's valkey.conf

The host sysctls are only half the posture. The other half is the server's own config file — and EchoMQ's is
real, committed, and applied. The kernel knobs (THP, overcommit, swappiness, somaxconn) live in the host; the
application-level knobs live in `infra/valkey/conf/valkey.conf`. That file never carries a sysctl; it carries
the threads, lazy-free, persistence, eviction, and defrag posture that the sysctls leave room for.

The bridge:

- **The pattern** — change the host sysctls (THP off, overcommit on, swappiness low, somaxconn raised, file
  descriptors raised) so a fork stays cheap, a swapped page never appears, and a burst of clients is accepted;
  and set the in-memory database's own config away from defaults hostile to a job store.
- **Its EchoMQ application** — `infra/valkey/conf/valkey.conf` sets `io-threads 1` (one command thread on a
  shared-CPU machine; the second vCPU feeds fsync, fork copy-on-write, and jemalloc purge), the full
  `lazyfree-lazy-*` family (keep deletes off the command thread), `appendonly yes` with `appendfsync everysec`
  (a one-second loss bound), `maxmemory-policy noeviction` (a runaway keyspace rejects writes loudly rather than
  losing work), `activedefrag yes` (relocate live objects so empty pages purge), `propagation-error-behavior
  panic` (fail the write rather than acknowledge data that may not survive), and `tcp-backlog 511`.

The manuscript states the kernel half from the inside: an in-memory store needs the kernel tuned away from its
defaults — transparent huge pages off, overcommit set, swappiness low, and the connection backlog and
file-descriptor limits raised so a burst of clients is accepted rather than dropped (`docs/echo/bcs/bcs.8.md`,
B8.2).

### The production posture (frozen)

`infra/valkey/conf/valkey.conf` · the persistence + threads lines:

```
io-threads 1

appendonly yes
appendfsync everysec
auto-aof-rewrite-percentage 100
aof-use-rdb-preamble yes
save ""
dir /data

propagation-error-behavior panic

activedefrag yes
```

### Notes on Valkey

A background save forks a child and relies on copy-on-write; the fork copy-on-write spike during an AOF rewrite
is exactly what the kernel tuning is for, and is why the config keeps `maxmemory` well under the machine's RAM
— [valkey.io/topics/latency](https://valkey.io/topics/latency/).

With `appendonly` on and `appendfsync everysec`, the volume holds an append-only log and the loss bound after a
crash is roughly one second of writes, not a whole snapshot interval —
[valkey.io/topics/persistence](https://valkey.io/topics/persistence/).

## The three dives

Each dive takes one cluster of the source's settings, in the arc *the fork → the command thread → durability*:

- **R8.01.1 · The fork's two settings** (`/redis-patterns/production-operations/kernel-tuning/huge-pages-overcommit`)
  — THP off and overcommit on: the copy-on-write story behind the 500x amplification and the refused fork.
- **R8.01.2 · Keeping the single command thread fast**
  (`/redis-patterns/production-operations/kernel-tuning/latency-spikes`) — swappiness, the lazy frees, active
  defragmentation, and the observability that catches a spike before a client does.
- **R8.01.3 · Durable on a crash, never silently losing work**
  (`/redis-patterns/production-operations/kernel-tuning/persistence-safe-settings`) — AOF everysec, the
  `noeviction` posture, and the connection backlog that accepts a burst rather than dropping it.

Read them in order: the fork first, then the command thread, then durability.

## References

### Sources

- [Valkey — Diagnosing latency issues](https://valkey.io/topics/latency/) — the fork, fsync, and huge-page
  behaviour the kernel tuning is for.
- [Valkey — Persistence (the append-only file)](https://valkey.io/topics/persistence/) — the appendonly
  everysec posture and the roughly one-second loss bound after a crash.
- [Redis — Administration](https://redis.io/docs/management/admin/) — the host-level checklist the source
  follows: THP, overcommit, somaxconn, and file-descriptor limits.
- Kernel tuning case study (`kernel-tuning.md.txt`) — a Shopify RedisDays presentation, the Redis
  documentation, and production post-mortems from the Netflix, Uber, and AWS ElastiCache teams.

### Related in this course

- [R8.01.1 · The fork's two settings](/redis-patterns/production-operations/kernel-tuning/huge-pages-overcommit) — THP off and overcommit on.
- [R8.01.2 · Keeping the single command thread fast](/redis-patterns/production-operations/kernel-tuning/latency-spikes) — swap, lazy frees, defrag.
- [R8.01.3 · Durable on a crash](/redis-patterns/production-operations/kernel-tuning/persistence-safe-settings) — AOF, noeviction, backlog.
- [R8 · Production & Operations](/redis-patterns/production-operations) — the chapter.
- [/echomq](/echomq) — the EchoMQ protocol whose Valkey this config tunes.
- [/bcs/fly](/bcs/fly) — Codemojex on Fly, where this valkey.conf actually runs.
