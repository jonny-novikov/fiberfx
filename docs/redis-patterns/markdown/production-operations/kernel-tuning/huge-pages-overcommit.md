# The fork's two settings: huge pages & overcommit

> R8.01.1 · Kernel tuning — dive 1 · route `/redis-patterns/production-operations/kernel-tuning/huge-pages-overcommit`

Valkey forks a child process for an AOF rewrite and relies on copy-on-write to keep that fork cheap. Two
kernel settings — transparent huge pages and memory overcommit — determine whether the fork stays cheap and
whether the kernel allows it at all. Get them wrong and a background rewrite turns into a latency spike or a
fork that the kernel refuses outright.

Grounding: the production case study in `kernel-tuning.md.txt` (the THP amplification and the overcommit
premise), the real `infra/valkey/conf/valkey.conf` (the fork budget the file leaves), and the BCS manuscript
B8.2 (`docs/echo/bcs/bcs.8.md` — the two settings, stated from the inside).

This dive owns the **fork / copy-on-write** story only. Swappiness, threads, and defrag are the next dive
(latency spikes); the AOF cadence, the `noeviction` posture, and connection limits are the third
(persistence-safe settings). This page references them, it does not repeat them.

## §1 · The fork and copy-on-write

Valkey is single-threaded for command execution, so it cannot pause the world to write a snapshot. Instead it
forks a child process and lets the child do the slow work — for an append-only-file rewrite, the child reads a
consistent point-in-time view of the keyspace and writes the compacted log while the parent keeps serving
commands.

The fork would be ruinous if it copied the whole heap. It does not. Linux gives parent and child the **same**
physical pages and marks them read-only; the pages are shared until one side writes. That is copy-on-write
(COW): a page is duplicated only at the moment a write touches it, and only that one page. A child that reads
without writing — the rewrite child — copies almost nothing. The parent copies a page only when a live command
modifies it during the rewrite window.

So the cost of a fork is not the size of the dataset; it is the rate of writes during the rewrite times the
size of the unit the kernel copies per write. That unit is what the first setting controls.

## §2 · Transparent huge pages, off

A normal memory page is 4 KB. Transparent huge pages (THP) is a kernel feature that hands out 2 MB pages
instead, to cut page-table pressure on large-heap workloads. For an in-memory store under copy-on-write it is
the wrong trade.

The source states the mechanism plainly: with THP enabled the kernel uses 2 MB pages instead of 4 KB, so
when the parent modifies a single byte during a rewrite the kernel must copy the entire 2 MB page — a **500×
amplification** of the work a 4 KB copy would have done. The visible symptoms in the source are latency
spikes of **10–100× during BGSAVE or BGREWRITEAOF**, memory usage doubling temporarily during persistence,
and client timeouts during background saves.

The fix is to disable it. The source's required form:

```sh
echo never > /sys/kernel/mm/transparent_hugepage/enabled
```

Make it permanent under systemd so it survives a reboot, as a pre-start step on the service:

```ini
[Service]
ExecStartPre=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
```

Valkey logs a warning at startup if THP is still enabled. That warning is not noise — it is the engine telling
you a single-byte write during a fork will cost a 2 MB page copy. Address it, never ignore it.

THP is a **kernel** setting, written under `/sys`. It is not a `valkey.conf` directive; the config file tunes
the server, the kernel knob tunes the host the server forks on.

## §3 · Memory overcommit, on

The second setting is about whether the fork is **allowed**, not how cheap it is. The `fork()` call can fail
when the kernel sizes the child as if it needs as much memory as the parent.

The source describes the trap: when Valkey forks, the kernel pessimistically reserves enough memory for the
child to hold a full copy of the parent. On a box with most of its RAM already used, the fork can fail even
though copy-on-write means almost no real memory is needed — the child shares the parent's pages, it does not
duplicate them. A pessimistic reservation refuses a fork that would have been free.

The fix tells the kernel to trust copy-on-write:

```sh
sysctl vm.overcommit_memory=1
```

Persist it in `/etc/sysctl.conf`:

```ini
vm.overcommit_memory=1
```

Setting `vm.overcommit_memory=1` makes the kernel always grant the allocation, trusting that COW means the
child's nominal claim is never realized. Like THP, this is a **kernel** setting applied with `sysctl`, not a
line in `valkey.conf`.

## §4 · On EchoMQ's valkey.conf

The course's worked engine is the Valkey that backs EchoMQ — the owned bus over the braced `emq:{q}:` keyspace,
the store the codemojex game's queue runs on. Its real config sits at `infra/valkey/conf/valkey.conf`, and two
of its lines exist to keep the fork cheap and rare.

`maxmemory 512mb` is a loud guardrail, not a working ceiling: the live dataset is single-digit megabytes
(round leaderboards, presence, in-flight stream entries), so 512 MB sits far above it, leaving — in the file's
own words — **~half the box for fork copy-on-write during an AOF rewrite**. The headroom THP and overcommit
make usable is the headroom this line budgets.

`save ""` disables RDB snapshotting, which leaves the AOF rewrite as the **one** fork source. The file's
comment is explicit: *one fork source*, so RDB does not compete for a second fork. With `appendonly yes` and a
single fork source, the copy-on-write spike is paid once per rewrite, not split across two competing children.

The valkey.conf file carries **no** THP or overcommit line — and it must not. THP and overcommit are host
kernel settings (`/sys` and `sysctl`); the config file tunes the server process. The two layers cooperate: the
kernel makes the fork cheap and allowed; the config budgets the headroom and keeps a single fork source.

```text
# infra/valkey/conf/valkey.conf · the fork budget (verbatim)
maxmemory 512mb               # ~half the box left for fork copy-on-write during an AOF rewrite
maxmemory-policy noeviction

appendonly yes                # One fork source.
save ""                       # RDB off — no second fork to compete
```

**Bridge — the pattern → its EchoMQ application.** The pattern: a forking in-memory store needs THP off so a
single-byte write costs a 4 KB copy not a 2 MB one, and overcommit on so copy-on-write is allowed to forgo
memory it never uses. Its application: `infra/valkey/conf/valkey.conf` budgets ~half the box for COW with
`maxmemory 512mb` and keeps **one** fork source with `save ""`, so the spike the kernel made cheap is also paid
just once.

**Take.** Two kernel settings, one config posture. THP off makes a copy-on-write page small; overcommit on
makes the fork legal; and EchoMQ's valkey.conf leaves the room for it and limits it to a single AOF rewrite.

## §Recap

A fork is cheap because of copy-on-write, and copy-on-write is cheap because the copied unit is small and the
fork is allowed. THP off keeps the unit at 4 KB; `vm.overcommit_memory=1` keeps the fork from being refused;
EchoMQ's `maxmemory 512mb` + `save ""` reserve the headroom and hold to one fork source. The next dive keeps
the **other** thread fast — the single command thread that the fork must never stall: swappiness, defrag, and
the I/O-thread budget that protect tail latency between rewrites.

## References

### Sources

- [Valkey — Diagnosing latency issues](https://valkey.io/topics/latency/) — the fork, fsync, and huge-page behaviour the kernel tuning is for.
- [Redis — Persistence (RDB and AOF)](https://redis.io/docs/management/persistence/) — why a rewrite forks a child and relies on copy-on-write.
- [Redis — Administration](https://redis.io/docs/management/admin/) — the documented THP and overcommit guidance the source applies, plus the startup warning.
- [Redis — Documentation](https://redis.io/docs/) — strings, persistence, and the kernel-tuning context the case study draws on. The source is a Shopify RedisDays presentation, the Redis docs, and production post-mortems.

### Related in this course

- [R8.01 · Kernel tuning](/redis-patterns/production-operations/kernel-tuning) — the module hub.
- [R8.01.2 · Latency spikes](/redis-patterns/production-operations/kernel-tuning/latency-spikes) — the next dive: swappiness, defrag, the command thread.
- [R8 · Production & Operations](/redis-patterns/production-operations) — the chapter.
- [/bcs/fly](/bcs/fly) — the same Valkey machine, set up from inside the BCS stack.
