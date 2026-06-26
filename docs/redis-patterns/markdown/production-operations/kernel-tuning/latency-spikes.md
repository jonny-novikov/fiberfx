# R8.01.2 · Keeping the single command thread fast

> Route: `/redis-patterns/production-operations/kernel-tuning/latency-spikes` · dive 2 of the
> `kernel-tuning` module. Source spine: `docs/redis-patterns/content/production/kernel-tuning.md.txt`
> (§ Swappiness, § Memory Allocator). Real application: `infra/valkey/conf/valkey.conf`. Manuscript:
> `docs/echo/bcs/bcs.8.md` (B8.2).

Every command runs on one thread. So anything that stalls that thread — a page that has to come
back from swap, a large synchronous free, a heap so fragmented the allocator works to place a
value — is a latency spike that every waiting client feels. The fix is the same shape each time:
move the slow work **off** the command thread and onto the spare capacity beside it.

The companion dive [Huge pages & overcommit](/redis-patterns/production-operations/kernel-tuning/huge-pages-overcommit)
owns the fork-during-persistence spike (transparent huge pages, copy-on-write, overcommit); this
dive owns the steady-state thread: swap, work-off-the-thread, fragmentation, and observing latency.

---

## §1 · The single command thread

A Valkey server executes commands on **one** thread. That is the design, not a limit to fix: a
single thread means a command runs to completion with no lock and no other command interleaved,
which is what makes a single `SET` or a Lua script atomic. The cost of the design is that the one
thread is a shared resource — whatever it spends a millisecond on is a millisecond no command runs.

The committed tuning surface states the premise plainly. The box is a Fly `shared-cpu-2x`: command
execution takes the first vCPU, and the second is reserved for the background helpers — AOF fsync,
fork copy-on-write, jemalloc purge, lazy frees, active defrag — so none of that work lands on the
command thread.

> **Source — `infra/valkey/conf/valkey.conf`, the sizing premise**
>
> ```
> # Sizing premise: command execution is single-threaded, so the second shared
> # vCPU is reserved for background work (AOF fsync, fork copy-on-write, jemalloc
> # purge, lazy frees, active defrag) — not for busy-waiting I/O threads, which
> # would burn the shared-CPU budget.
> ```

The rest of this dive is the catalogue of what can stall the command thread and the one setting
that moves each off it.

## §2 · Swap is the worst spike

Memory access is measured in nanoseconds; a disk read is measured in milliseconds. When the kernel
swaps a page of the dataset out to disk, the next read of that page pays the disk cost — the source
puts the slowdown at roughly **1,000,000×**. A single swapped page can be enough to time a client
out, and the server has no way to see it coming.

The fix is a kernel setting, not a server setting — `vm.swappiness` lives in the Linux VM, set with
`sysctl`:

```
sysctl vm.swappiness=1
```

The source is specific about the value: **1, not 0**. Zero forbids swap entirely, which can turn
memory pressure into an OOM kill; one makes swapping extremely unlikely while still letting the
kernel swap in a genuine emergency rather than killing the process. The manuscript states the same
trade in one line: swappiness is set to its lowest practical value, *because a swapped page trades
nanoseconds for milliseconds*.

## §3 · Keep work off the thread

Three settings move steady-state work off the command thread and onto the second vCPU.

**`io-threads 1`** on a shared-CPU box. Extra I/O threads busy-wait — they spin rather than sleep,
which pins the CPU near 100% and drains a shared machine's burst balance even while idle. The
background helper threads (fsync, jemalloc background purge) sleep between cycles, so they are the
right tenants for the second vCPU; the I/O threads are not.

**Lazy frees** (`lazyfree-lazy-*`). Freeing a large value is itself work, and done inline it runs on
the command thread. The lazy-free settings hand that work to a background thread instead: an
eviction, an expiry, a server-side delete, a user `DEL`, and a `FLUSH` each return immediately and
reclaim the memory off-thread, so a single big delete does not stall the commands behind it.

**`jemalloc-bg-thread yes`**. jemalloc's background purge thread sleeps between cycles and returns
unused pages to the OS off the main thread, so reclaiming memory never costs a command.

> **Source — `infra/valkey/conf/valkey.conf`, threads + lazy freeing (verbatim)**
>
> ```
> # ---- Lazy freeing: keep deletes off the command thread -----------------------
> lazyfree-lazy-eviction yes
> lazyfree-lazy-expire yes
> lazyfree-lazy-server-del yes
> lazyfree-lazy-user-del yes
> lazyfree-lazy-user-flush yes
>
> # ---- Threads -----------------------------------------------------------------
> # One I/O thread on a shared-CPU machine. Extra I/O threads busy-wait, which
> # pins CPU near 100% and drains the shared burst balance even while idle. The
> # background helper threads (fsync, jemalloc bg purge) sleep, so they are the
> # right tenants for the second vCPU.
> io-threads 1
>
> # jemalloc's background purge thread sleeps between cycles; let it return pages
> # to the OS off the main thread.
> jemalloc-bg-thread yes
> ```

## §4 · Fragmentation and defrag

Valkey uses jemalloc, well-suited to its allocation patterns, with one behaviour to watch. After a
large amount of data is deleted, jemalloc retains the freed memory to satisfy future allocations
rather than returning it all to the OS — so process RSS reflects peak usage, not the current
dataset size. Over time the live objects can scatter across sparse runs, and the allocator works
harder to place each new value: fragmentation.

The number to watch is `mem_fragmentation_ratio` in `INFO MEMORY`. The source gives three bands:

- **below 1.0** — the process is using swap; critical (this is the §2 spike, seen from the allocator's side).
- **1.0–1.5** — normal.
- **above 1.5** — significant fragmentation.

`MEMORY PURGE` forces jemalloc to return memory to the OS on demand. Better, the server can keep the
ratio near 1 continuously: `activedefrag yes` relocates live objects out of sparse runs so empty
pages are purged. The committed config pairs it with gentle cycle bounds — `active-defrag-cycle-min 1`
and `active-defrag-cycle-max 25` — so defrag never takes more than a small slice of any cycle and
the main thread is never starved.

> **Source — `infra/valkey/conf/valkey.conf`, active defragmentation (verbatim)**
>
> ```
> # ---- Active defragmentation (jemalloc only) ----------------------------------
> # Relocates live objects out of sparse jemalloc runs so empty pages are purged,
> # keeping mem_fragmentation_ratio near 1. Gentle cycle bounds so the main thread
> # is never starved.
> activedefrag yes
> active-defrag-ignore-bytes 100mb
> active-defrag-threshold-lower 10
> active-defrag-threshold-upper 100
> active-defrag-cycle-min 1
> active-defrag-cycle-max 25
> active-defrag-max-scan-fields 1000
> ```

## §5 · Observing it

A spike you cannot see is a spike you cannot fix. The committed config turns on three observation
surfaces:

- `slowlog-log-slower-than 10000` — record any command that runs longer than 10,000 microseconds
  (10 ms) in the slow log.
- `latency-monitor-threshold 100` — arm the latency monitor at 100 ms so the server tracks the
  events that crossed it.
- `latency-tracking yes` — keep per-command latency percentiles.

One caveat the config calls out: on Valkey 9.1, watch `used_active_time_main_thread` (via `INFO`)
for true headroom — with I/O threads the raw CPU figure busy-waits near 100% and hides spare
capacity, so the main-thread time is the honest number.

**Notes on Valkey.** Diagnosing latency is a topic in its own right — fork pauses, fsync, huge
pages, and slow commands each leave a different signature, and the latency monitor names which one
fired. See [valkey.io/topics/latency](https://valkey.io/topics/latency/).

---

## The applied close

| The pattern | Its application in `valkey.conf` |
| --- | --- |
| Keep the single command thread fast: a swapped page, a synchronous free, and a fragmented heap are each a latency spike, so move that work off the thread and watch the thread's own time. | `io-threads 1`, `lazyfree-lazy-*`, `jemalloc-bg-thread yes`, and `activedefrag` move the work to the second vCPU; `slowlog` / `latency-monitor-threshold` / `latency-tracking` watch it; on 9.1 `used_active_time_main_thread` reads the honest headroom. |

**Take.** The command thread is the one resource every client shares. Each tuning move here is the
same idea applied to a different stall — get the slow work off the thread, and measure the thread,
not the busy-waiting CPU.

---

## Recap → next dive

A latency spike on a single-threaded store is almost always work that landed on the command thread.
Swap is the worst case and the cheapest fix (`vm.swappiness=1`). Lazy frees, one I/O thread, and the
jemalloc background thread keep steady-state work off the thread; active defrag keeps the heap from
forcing the allocator to work; and the slow log plus the latency monitor make a spike visible. The
next dive, [Persistence-safe settings](/redis-patterns/production-operations/kernel-tuning/persistence-safe-settings),
turns to durability — AOF, `noeviction`, and the connection settings that keep a burst of clients
from being dropped.

## References

### Sources

- [Valkey — Diagnosing latency issues](https://valkey.io/topics/latency/) — the fork, fsync,
  swap, and slow-command signatures the latency monitor distinguishes.
- [Valkey — Memory optimization](https://valkey.io/topics/memory-optimization/) — jemalloc's
  high-water mark, fragmentation, `MEMORY PURGE`, and active defragmentation.
- [Redis — Documentation](https://redis.io/docs/) — the memory and latency operations the source's
  framing draws on: `mem_fragmentation_ratio`, the slow log, and the latency monitor.
- Shopify RedisDays presentation, Redis documentation, and production post-mortems (Netflix, Uber,
  AWS ElastiCache) — the source named in `kernel-tuning.md.txt`, origin of the 1,000,000× swap
  figure and the `mem_fragmentation_ratio` bands.

### Related in this course

- [R8.01 · Kernel tuning](/redis-patterns/production-operations/kernel-tuning) — the module hub.
- [R8.01.1 · Huge pages & overcommit](/redis-patterns/production-operations/kernel-tuning/huge-pages-overcommit) —
  the fork-during-persistence spike (THP, copy-on-write, overcommit).
- [R8.01.3 · Persistence-safe settings](/redis-patterns/production-operations/kernel-tuning/persistence-safe-settings) —
  the next dive: AOF, `noeviction`, connections.
- [R8 · Production & Operations](/redis-patterns/production-operations) — the chapter.
- [/bcs/fly](/bcs/fly) — Codemojex on Fly: the same Valkey machine, the production shape from the inside.
