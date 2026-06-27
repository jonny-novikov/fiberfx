# Atomic vs non-atomic — one EVALSHA vs the round-trip loop

> **Route:** `/redis-patterns/queues/stalled-recovery/atomic-vs-non-atomic` · **Dive:** R3.03.3
> **Grounding:** `echo/apps/echo_mq/lib/echo_mq/stalled.ex` — `@sweep_stalled`, one `EVALSHA` detect-and-move over `active`/`pending`/`dead`, the in-script `HINCRBY 'attempts'`/`'stalled'`. The non-atomic contrast is a **generic** app-side loop, not any shipped surface.

This is the dive the module is built around. Stalled recovery has to detect a stalled job and move it, and there are two ways to do that: as one indivisible step inside the server, or as a sequence of round trips from the application. They look equivalent on a quiet queue. Under two overlapping sweeps they are not — and the difference is whether a job is redelivered once or twice.

## The atomic form — one EVALSHA

`EchoMQ.Stalled` runs the whole recovery as one cached Lua script, dispatched `EVALSHA`-first. Read, decide, and write happen on the server's single thread, so nothing interleaves between them:

    local exp = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', now, 'LIMIT', 0, lim)  -- detect
    for _, id in ipairs(exp) do
      redis.call('ZREM', KEYS[1], id)                       -- claim it out of active
      local jk = p .. 'job:' .. id
      local st = redis.call('HINCRBY', jk, 'stalled', 1)    -- count in-script
      if st >= maxst then
        redis.call('HSET', jk, 'state', 'dead')
        redis.call('ZADD', KEYS[3], 0, id)                  -- dead
      else
        redis.call('ZADD', KEYS[2], 0, id)                  -- pending
        redis.call('HSET', jk, 'state', 'pending')
      end
    end

The `ZREM` that removes a job from `active` and the `ZADD` that puts it in `pending` are in the same script. A job is never in both sets and never in neither — between the two writes no other command runs. A second sweep that starts while this one is mid-loop does not begin until this `EVALSHA` returns, because the server runs one script at a time. Each expired lease is reclaimed exactly once per sweep, and the `stalled` and `attempts` counters are incremented by the script, never read-modify-written by a client.

## The non-atomic form — the round-trip loop

The same recovery, written app-side, is a sequence of separate round trips: list the in-flight set, probe each member's liveness, then move the stalled ones. In pseudocode:

    in_flight = ZRANGEBYSCORE active -inf now      -- round trip 1: detect
    for id in in_flight:
      if probe_says_stalled(id):                   -- round trip 2: re-check
        ZREM active id                             -- round trip 3: remove
        ZADD pending 0 id                          -- round trip 4: re-queue
        n = HGET job:id stalled; HSET job:id stalled (n+1)  -- read, increment, write

Every line is a separate command, and the application's state lives between them. That gap is where correctness leaks. This is the cautionary contrast — not a strawman, the genuinely common shape of an app-side recovery, and exactly what the atomic Lua exists to avoid.

## The double-recovery window

Two sweeps run on a cadence; on a busy queue they overlap. In the non-atomic loop, sweep A reads the in-flight set and finds job `J` stalled. Before A reaches its `ZREM`, sweep B also reads the set and also finds `J` stalled. Now both move it: A removes it from `active` and pushes it to `pending`; B removes it again (a no-op) and pushes it again. `J` is now in `pending` twice — claimed twice, run twice. The same gap corrupts the count: A reads `stalled = 2`, B reads `stalled = 2`, both write `3`, and one increment is lost — a job that has stalled four times records two.

The atomic form has no window. A single sweep's detect-and-move is one script; a concurrent sweep cannot start mid-loop. Even two sweeps fired at once serialize on the server, so `J` is reclaimed once and its count is exact. The lesson is the reliable-queue family's core: a recovery that detects and moves in separate steps is correct only until two recoveries overlap, and recoveries always eventually overlap.

## The bridge

- **The pattern:** the detect-and-move must be one indivisible step, or two overlapping sweeps redeliver the same job and lose an increment on the attempt counter.
- **Its EchoMQ application:** `@sweep_stalled` is that one step — `ZRANGEBYSCORE` + `ZREM` + `ZADD` + `HINCRBY` inside a single `EVALSHA`, on the server's single thread; the count is bumped in-script, never read-modify-written by a client.

The take: atomic recovery is not a performance choice; it is the only form that survives two sweeps running at once.

## When a recovery gives up

The atomic sweep that recovers a job is the same one that dead-letters it: at `max_stalled` the job lands in `emq:{q}:dead` in the same script that detected it. From there its history is durable. When the bus trims the stream, `EchoStore.StreamArchive` folds the trimmed segments into the Graft floor and on to Tigris — so a job that exhausted its recoveries is kept, not lost. The durability dial is the subject of `/echo-persistence`.

## References

### Sources

- [Redis — *EVALSHA*](https://redis.io/commands/evalsha/) — the cached script run as one indivisible step; the dispatch the connector uses first.
- [Redis — *EVAL / scripting*](https://redis.io/commands/eval/) — the server runs one script at a time, so two sweeps serialize.
- [Valkey — *ZRANGEBYSCORE*](https://valkey.io/commands/zrangebyscore/) — the detect read at the top of both forms; only the atomic form fences the move that follows it.
- [Valkey — *HINCRBY*](https://valkey.io/commands/hincrby/) — the in-script increment that avoids the lost-update race a client-side read-modify-write opens.

### Related in this course

- [R3.03 · Stalled recovery](/redis-patterns/queues/stalled-recovery) — the module hub.
- [R3.03.1 · Lock-expiry detection](/redis-patterns/queues/stalled-recovery/lock-expiry-detection) — the lease the sweep reads.
- [R3.03.2 · Two-phase mark/recover](/redis-patterns/queues/stalled-recovery/two-phase-mark-recover) — the stall count this script increments.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the one-step atomic move, in full.
- [/echomq/queue](/echomq/queue) — the EchoMQ Queue pillar: the state machine and the inline Lua in depth.
- [/echo-persistence](/echo-persistence) — the durability floor a dead-lettered job's history reaches.
