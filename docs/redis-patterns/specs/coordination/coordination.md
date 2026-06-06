# R2 · Coordination & Consistency — atomicity first

> The atomicity foundation every later chapter builds on: a reliable queue is made of atomic moves and a lock lease,
> so coordination is taught before the queue. Five patterns — atomic updates, locking, Redlock (as a contrast),
> cross-shard consistency, and hash-tag colocation — grounded in EchoMQ's Lua transactions and cluster key layout.

## Where this chapter starts and ends

- **Start** — R1's read-path caching; the reader knows Redis commands but not how to make a multi-key change race-
  free, or why a single-node "distributed lock" silently breaks.
- **End** — the reader can make a multi-key update atomic with a Lua script, take a fenced lock with a renewable
  lease, explain when Redlock's majority guarantee is and is not needed, and lay out keys so a cluster keeps
  multi-key operations on one slot. The workshop makes Portal enrollment atomic across runtimes.

## The grounding (Redis Pattern Applied)

Grounded in **EchoMQ's coordination layer**: every state transition is a single Lua script — `moveToActive-11`,
`moveToFinished-14` (`apps/echomq-go/pkg/echomq/scripts/scripts.go`) — so the multi-key change cannot interleave;
the job lock is `bull:{queue}:{id}:lock` (UUID value, `PX` TTL) renewed by `ExtendLock` (GET-token-then-SET-PX); and
all of a queue's keys share the `{queue}` hash tag so `cluster.go`'s `CalculateCRC16` / `GetClusterSlot` (% 16384)
land them on one slot. Redlock is the **contrast** — EchoMQ's lease is a single-Redis lock, not a multi-master one.

## The module ladder

| Module | Pattern | What it adds | Grounding | Dives |
| --- | --- | --- | --- | --- |
| R2.01 atomic-updates | `atomic-updates` | read-modify-write without a race | every EchoMQ Lua move; `MULTI/EXEC` | WATCH/MULTI/EXEC · Lua for complex logic · shadow-key bulk |
| R2.02 distributed-locking | `distributed-locking` | mutual exclusion with `SET NX PX` + a fencing token | `:{id}:lock` + `ExtendLock` lease | SET NX PX · fencing tokens · lease renewal (one timer per worker) |
| R2.03 redlock | `redlock` | a majority-of-N multi-master lock | **contrast** with EchoMQ's single-Redis lease | N/2+1 majority · clock assumptions · when single-instance is enough |
| R2.04 cross-shard-consistency | `cross-shard-consistency` | detect torn writes across instances | EchoMQ's single-slot requirement for multi-key Lua | torn writes · version tokens · commit markers |
| R2.05 hash-tag-colocation | `hash-tag-colocation` | force related keys to one cluster slot | `bull:{queue}:*`; `cluster.go` CRC16 % 16384 | the `{tag}` mechanic · CROSSSLOT prevention · cluster auto-detect |
| R2.06 Workshop | — | make Portal enrollment atomic across runtimes | the Lua transaction over the enrollment keys | — |

## The door to the EchoMQ course

→ EchoMQ. The deeper implementation — the full include-graph of `moveToActive`/`moveToFinished`, the EVALSHA +
NOSCRIPT dispatch, and the polyglot lock-renewal strategies (the Elixir LockManager's one-timer-for-N-jobs vs the Go
per-job heartbeat) — belongs to the dedicated EchoMQ course. This chapter teaches the patterns; that course teaches
the transaction model.

## Conventions

Pages follow the two mandatory layout rules (segmented route-tag; canonical 3-column footer + `TSK…` stamp), pass
the ten gates including `refs`, and honour voice and no-invent: cite the real EchoMQ key, command, or Lua script
named in the grounding map, never an invented one. `redlock` is taught as a contrast, not as something EchoMQ
implements. See [`../redis-patterns.md`](../redis-patterns.md).

Index: [`../redis-patterns.md`](../redis-patterns.md) · TOC: [`../../redis-patterns.toc.md`](../../redis-patterns.toc.md) · Roadmap: [`../../redis-patterns.roadmap.md`](../../redis-patterns.roadmap.md)
