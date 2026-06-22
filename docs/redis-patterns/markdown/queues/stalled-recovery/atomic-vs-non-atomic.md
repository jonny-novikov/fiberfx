# Atomic vs non-atomic — one EVALSHA vs the round-trip loop

> Route: `/redis-patterns/queues/stalled-recovery/atomic-vs-non-atomic` · Dive R3.03.3 · Module R3.03 Stalled recovery.
> · Grounding: the atomic, recommended form is `moveStalledJobsToWait-8.lua`
> (`EchoMQ.Scripts.move_stalled_jobs_to_wait/4`) — one EVALSHA, the detect-and-move runs inside Redis's single thread.
> The cautionary contrast is the Go port `apps/echomq-go/pkg/echomq/stalled.go`, where
> `StalledChecker.checkStalledJobs` does the same work app-side in separate round trips (`LRANGE active` →
> `EXISTS lock` → `LREM`/`LPUSH`, with `atm` incremented client-side). All real.

The recovery sweep is two moves: detect — is this job stalled? — and recover — remove it from `active`, push it to
`wait`. How those two moves are joined determines whether the sweep is correct under concurrency. Joined as one indivisible
step, the sweep is exact. Joined as two separate round trips, a second sweep can slip between them and recover the same
job twice. This dive is that difference, run side by side.

## The detect-and-move as one step

The atomic form runs detect-and-move as a single Lua script. `moveStalledJobsToWait-8.lua` is invoked with one EVALSHA:
its body reads the in-flight list, tests each job's lock, and moves the stalled ones to `wait` — all inside Redis's
single command thread. No other command runs between the script's first line and its last. A second sweep that fires
during the script does not interleave with it; it waits its turn and then finds the work already done. Each stalled job
is reclaimed once per sweep, and the attempt count is incremented in the script, on the value the script itself read.

```lua
-- moveStalledJobsToWait-8.lua — atomic detect-and-move, one EVALSHA (real, Elixir)
-- KEYS: stalled(SET) wait(LIST) active(LIST) failed(ZSET) stalled-check meta paused marker
-- for each job in `active` whose lock has expired:
--   mark it on the first pass; on the next pass move it to `wait` (or `failed` past max attempts)
--   and increment attemptsMade — all in one indivisible step, nothing interleaves
```

The script is the lock. Because the read, the decision, and the writes are one step, there is no window between the check
and the move for a second sweep to act in.

## The two separate round trips

The non-atomic form is the Go port's `StalledChecker`, the cautionary contrast — the Go runtime's path, not EchoMQ's
recommended one. It does the same work app-side, in separate commands: `LRANGE active 0 -1` lists the in-flight jobs;
then for each job `EXISTS lock` is the stalled test (`isJobStalled`); then `recoverStalledJob` runs `HGETALL
job`, reads and increments the `atm` (attemptsMade) field in Go, runs `LREM active`, branches to `failed` past max
attempts, and runs `LPUSH wait` with a pipelined `HSET atm`. Each is a round trip, and the gaps between them are open.

```go
// stalled.go — the non-atomic Go path (the cautionary contrast, NOT "EchoMQ")
activeJobs, _ := redis.LRange(ctx, kb.Active(), 0, -1).Result()   // list in-flight jobs
for _, jobID := range activeJobs {
    if exists, _ := redis.Exists(ctx, kb.Lock(jobID)).Result(); exists == 0 {  // stalled?
        // ...a second checker can BOTH reach here for the same job — double-recovery window
        redis.LRem(ctx, kb.Active(), 1, jobID)   // separate round trip
        redis.LPush(ctx, kb.Wait(), jobID)       // separate round trip
        // atm (attemptsMade) read + incremented client-side, then HSet — a lost-update race
    }
}
```

Two gaps in this loop are the bugs the atomic script does not have.

**The double-recovery window.** Between `EXISTS lock` (the job is stalled) and `LREM`/`LPUSH` (reclaim it), a second
checker can run the same `EXISTS lock` for the same job, also see it stalled, and also run `LREM`/`LPUSH`. The job lands
in `wait` twice. One stalled job is redelivered to two workers — at-least-once becomes at-least-twice, by accident.

**The client-side attempt-count race.** The Go path reads `atm` with `HGETALL`, increments it in Go, and writes it back
with `HSET`. Two checkers that read the same `atm` before either writes both compute the same next value and both write
it — a lost update on the attempt counter, so a job that stalled twice records one attempt. The atomic Lua increments the
field in the script, on the value the script itself read, with nothing in between.

## The pattern, applied

EchoMQ uses the atomic form. `EchoMQ.Scripts.move_stalled_jobs_to_wait/4` wraps `moveStalledJobsToWait-8.lua`, an
eight-key script over `stalled`, `wait`, `active`, `failed`, `stalled-check`, `meta`, `paused`, and `marker`. One
EVALSHA reclaims each stalled job once per sweep and increments its attempt count in-script — both gaps closed by
construction. The Go port `apps/echomq-go/pkg/echomq/stalled.go` keeps the same job model but does the recovery in
separate round trips, and so carries both windows. It is shown here not as EchoMQ but as the contrast that makes the
atomic form's value concrete: the multi-round-trip loop is correct until two sweeps overlap, and a recovery sweep, by its
nature, runs concurrently.

The full script dispatch — the EVALSHA cache, the `stalled-check` throttle, and the pool-wide coordination that keeps two
sweeps from racing in the first place — is the dedicated EchoMQ course. This dive teaches why the move must be one step;
that course teaches the engine that runs it.

## References

### Sources
- [Redis — EVALSHA](https://redis.io/commands/evalsha/) — the cached-script call that runs the detect-and-move as one
  EVALSHA.
- [Redis — EVAL / scripting](https://redis.io/commands/eval/) — why a Lua script is one indivisible step, so no second
  sweep interleaves.
- [Redis — LREM](https://redis.io/commands/lrem/) — the in-flight removal both forms run; in the Go path a separate round
  trip.
- [Redis — LMOVE](https://redis.io/commands/lmove/) — the atomic move back to wait, the one-step alternative to the Go
  loop's separate `LREM`/`LPUSH`.
- [BullMQ — the queue protocol](https://bullmq.io/) — the stalled-check worker path both runtimes port.

### Related in this course
- [R3.03 · Stalled recovery](/redis-patterns/queues/stalled-recovery) — the module: the recovery sweep in full.
- [R3.03.1 · Lock-expiry detection](/redis-patterns/queues/stalled-recovery/lock-expiry-detection) — the lease the sweep
  tests.
- [R3.03.2 · Two-phase mark/recover](/redis-patterns/queues/stalled-recovery/two-phase-mark-recover) — the prior dive:
  mark once, recover on the next sweep.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the one-step atomic move this sweep needs.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the family in one place: the three guarantees.
- [E2 · The lifecycle, components & runtimes](/echomq/core) — the dedicated EchoMQ course: the worker fetch loop and the
  script dispatch.
