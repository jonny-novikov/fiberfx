# E2 · The lifecycle, components & runtimes — the as-built library

> Route: `/echomq/core` · Chapter landing · Movement I (present tense) · ← redis-patterns R3

The route-mirror source-of-record for the E2 chapter landing. E2 is Movement I — the as-built core, taught in the
present tense; there is no `emq.N` rung here (the core is shipped). The chapter deepens redis-patterns R3 (reliable
queues) and stands on E1 (the immutable wire).

## The arc

overview → why & when → what (the four module cards) → how it works → the workshop → an "Up next" grid of E3–E8.

## Why & when

A reader who walked the `→ EchoMQ` door from the reliable-queue pattern (R3) has met states-as-locations and the
atomic-move thesis. A reader who finished E1 holds the immutable wire — the keys and the scripts. This chapter teaches
the library in motion: which eight states a job occupies, which script performs each transition, and how the lock keeps
a job owned while a worker runs it. The **Golden Rule** holds throughout: the state's keys (L1) and the transition's Lua
script (L2) are immutable and shared across runtimes; the executor (L3) and the API (L4) vary.

## The eight states (the framing interactive's dataset — verified against `EchoMQ.Keys` + corpus ch03 §3.1)

| State | Redis location | Entered by | Key fn |
|---|---|---|---|
| wait | LIST `emq:{q}:wait` | `addStandardJob-9` (add) · `moveStalledJobsToWait-8` (recover) | `Keys.wait/1` |
| paused | LIST `emq:{q}:paused` | `pause-7` (queue paused) | `Keys.paused/1` |
| delayed | ZSET `emq:{q}:delayed` (score = run-at ms) | `addDelayedJob-6` (add) · `moveToDelayed-8` (retry backoff) | `Keys.delayed/1` |
| prioritized | ZSET `emq:{q}:prioritized` (score = priority) | `addPrioritizedJob-9` (add) | `Keys.prioritized/1` |
| active | LIST `emq:{q}:active` | `moveToActive-11` (pickup — acquires the lock) | `Keys.active/1` |
| completed | ZSET `emq:{q}:completed` (score = finished-at ms) | `moveToFinished-14` (success) | `Keys.completed/1` |
| failed | ZSET `emq:{q}:failed` | `moveToFinished-14` (failure, attempts exhausted) | `Keys.failed/1` |
| waiting-children | ZSET `emq:{q}:waiting-children` | `addParentJob-6` (flow parent) | `Keys.waiting_children/1` |

## The modules

- **E2.01 · The lifecycle & state machine** *(built)* — the eight states, the script behind each transition, the lock
  protocol, the closed `-1`…`-11` codes. Dives: the eight states · every transition & its script · the lock protocol.
- **E2.02 · Jobs, queues & workers** *(soon)* — the job model and options, the stateless queue, the worker fetch loop.
- **E2.03 · Lock management & the supporting processes** *(soon)* — one timer per worker, stalled recovery, schedulers
  and events.
- **E2.04 · The three runtimes & interop** *(soon)* — the Elixir library-only architecture, the honest Go gaps,
  cross-runtime interop.
- **E2.05 · Workshop** *(soon)* — run a job through every state, observed across two runtimes.

## How it works (the protocol ↔ runtime bridge)

One transition makes the layering concrete. A worker picks up the next job: at **L4** a runtime API; at **L3** the
executor dispatches by SHA (`EchoMQ.Scripts.move_to_active/4`); at **L2** `moveToActive-11` runs atomically; at **L1** it
moves a job id from `emq:{queue}:wait` to `emq:{queue}:active` and sets `emq:{queue}:{jobId}:lock` with a UUID token
and a `PX` TTL. `moveToFinished-14` verifies that token first; a missing or mismatched lock returns `-2` or `-6` from the
closed set. L1 and L2 are byte-identical across runtimes; only L3 and L4 differ.

- **The protocol (immutable L1/L2):** the state keys (`Keys.wait/1`, `active/1`, …) and the transition scripts
  (`moveToActive-11`, `moveToFinished-14`), with the same closed `-1`…`-11` codes everywhere.
- **Its three runtimes (variable L3/L4):** Elixir dispatches with `EchoMQ.Scripts` over a Redix pool and renews locks
  with one `EchoMQ.LockManager` timer per worker; Go and Node.js drive the same scripts their own way.

## Up next

Movement II (E3–E8) tracks the EMQ extension ladder — E3 substrate (⇄ emq.1), E4 groups (⇄ emq.2), E5 batches
(⇄ emq.3), E6 lifecycle controls (⇄ emq.4), E7 EchoCache (⇄ emq.5), E8 production (⇄ emq.6) — each teaching the
redis-patterns pattern, the rung's spec, and the as-built code together.

## References

### Sources

- BullMQ — *Documentation* (https://docs.bullmq.io/) — the wire protocol EchoMQ implements: the states, the transition scripts, the lock.
- Redis — *RPOPLPUSH* (https://redis.io/commands/rpoplpush/) — the reliable wait→active move at the heart of `moveToActive`.
- Redis — *EVALSHA* (https://redis.io/commands/evalsha/) — the run-by-SHA dispatch every transition script runs under.
- Redis — *Sorted sets* (https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the ZSET scoring behind delayed, prioritized, and the terminal sets.

### Related in this course

- `/echomq/core/lifecycle` — E2.01 · The lifecycle & state machine (start here).
- `/echomq/protocol` — E1 · The protocol & the data layer (the immutable wire this chapter sets in motion).
- `/redis-patterns/queues` — redis-patterns R3 · Reliable queues (the pattern this chapter deepens).
