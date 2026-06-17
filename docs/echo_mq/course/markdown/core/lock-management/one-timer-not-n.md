# E2.03.1 · One timer, not N

> Route: `/echomq/core/lock-management/one-timer-not-n` · Movement I · The Core · `← redis-patterns R3`

## The fact

`EchoMQ.LockManager` keeps every held lock fresh with **one timer per worker, not one timer per
job**. A naive design would arm a `Process.send_after` for each active job and renew that job's lock
when its timer fires — N jobs, N timers, N Redis round-trips per renewal window. The LockManager
arms a single recurring timer for the whole worker, and when it fires it batch-renews every job that
is due in **one** Redis call.

## The worked example — on the real `EchoMQ.LockManager`

The lock manager is a `GenServer`. At `init` it reads `lock_duration` (default `30_000` ms — the
lock TTL) and `lock_renew_time` (default `div(lock_duration, 2)` = `15_000` ms), then arms the timer:

```elixir
defp schedule_renewal(lock_renew_time) do
  interval = div(lock_renew_time, 2)            # 7_500 ms by default
  Process.send_after(self(), :extend_locks, interval)
end
```

So with the defaults a lock lives **30_000 ms**, the renew window is **15_000 ms**, and the single
timer ticks every **7_500 ms** — comfortably ahead of the TTL. Each worker has exactly one of these
timers regardless of how many jobs it holds.

When the worker picks a job up it calls `track_job(manager, job_id, token)` (arity 3), storing the
job's token and a millisecond timestamp. On complete or fail it calls `untrack_job(manager, job_id)`
(arity 2). The full public surface is `start_link/1`, `track_job/3`, `untrack_job/2`,
`get_active_job_count/1`, `get_tracked_job_ids/1`, `is_tracked?/2`, and `stop/1`.

When the timer fires, `handle_info(:extend_locks, state)` runs. It scans **all** `tracked_jobs`,
selects those whose `info.ts + threshold < now` — where `threshold = div(lock_renew_time, 2)` — and
collects their ids and tokens:

```elixir
def handle_info(:extend_locks, state) do
  now = System.system_time(:millisecond)
  threshold = div(state.lock_renew_time, 2)

  {jobs_to_extend, updated_tracked} =
    Enum.reduce(state.tracked_jobs, {[], %{}}, fn {job_id, info}, {to_extend, tracked} ->
      if info.ts + threshold < now do
        {[{job_id, info.token} | to_extend], Map.put(tracked, job_id, %{info | ts: now})}
      else
        {to_extend, Map.put(tracked, job_id, info)}
      end
    end)

  # one Redis call renews every due job
  ...
end
```

The due jobs are renewed together via `EchoMQ.Scripts.extend_locks(connection, keys, job_ids,
tokens, lock_duration)` — **arity 5** (this is `EchoMQ.LockManager.extend_locks/5` reaching
`EchoMQ.Scripts.extend_locks/5`). The script side packs all of it into one call:

```elixir
def extend_locks(conn, ctx, job_ids, tokens, duration) do
  keys = [Keys.stalled(ctx)]               # exactly ONE key
  args = [
    Keys.key(ctx),                         # the baseKey
    Msgpax.pack!(tokens, iodata: false),   # all tokens in one ARGV
    Msgpax.pack!(job_ids, iodata: false),  # all ids in one ARGV
    duration
  ]
  execute(conn, :extend_locks, keys, args)
end
```

One key means the script is **`extendLocks-1.lua`** — the `-1` suffix is the `numkeys`, and the
key is the stalled set. The script walks the packed ids and tokens, and for each job:

```lua
-- extendLocks-1.lua · KEYS[1] stalled · ARGV baseKey, tokens, jobIds, lockDuration
local currentToken = rcall("GET", baseKey .. jobIds[i] .. ':lock')
if currentToken == token then
  rcall("SET", lockKey, token, "PX", lockDuration)   -- re-set the TTL
  rcall("SREM", stalledKey, jobId)                   -- clear from stalled set
else
  table.insert(failedJobs, jobId)                    -- record a lost lock
end
return failedJobs   -- the list of FAILED ids; empty means all renewed
```

The script **returns the list of failed job ids** (an empty list means every lock was renewed). The
LockManager untracks any job whose lock was lost and fires its `on_lock_renewal_failed` callback —
that job has stalled, and the stalled checker will recover it.

## Why one timer beats N

With a timer per job, N concurrent jobs cost **N `Process.send_after` timers** and **N Redis
round-trips** per renewal window — O(N) on both. With one timer and one batched `extendLocks-1.lua`
call, the same N jobs cost **one timer** and **one Redis round-trip**. Under heavy concurrency that
is the difference between N renew calls and 1.

## The protocol and its three runtimes

The lock key `emq:{queue}:{jobId}:lock` (a UUID token under a `PX` TTL, **L1**) and the renew
script `extendLocks-1.lua` (**L2**) are frozen and shared. The single-timer batch design — a
threshold scan in `handle_info`, one batched `extend_locks/5` call — is the Elixir runtime's own
OTP `GenServer` choice (**L3/L4**). Go and Node.js renew the same locks with the same extend script
on their own schedule. The renew protocol does not move; the batching strategy above it does.

## Recap

- One `Process.send_after` timer per worker, fired every `div(lock_renew_time, 2)` = ~7_500 ms.
- The timer selects every tracked job past `info.ts + threshold` and renews them in one
  `extend_locks/5` call.
- `extend_locks/5` runs `extendLocks-1.lua` (one stalled key), which re-sets the TTL on jobs whose
  token still matches and returns the ids of any whose lock was lost.
- Defaults: `lock_duration` 30_000 ms, `lock_renew_time` 15_000 ms, timer interval 7_500 ms.
- O(1) timers and one Redis round-trip, not O(N).

## References

### Sources

- BullMQ — Documentation — the lock-renewal protocol and the batched lock-extension call EchoMQ
  implements. https://docs.bullmq.io/
- Redis — SET — the `SET key token PX ms` that re-sets each lock's TTL inside `extendLocks-1.lua`.
  https://redis.io/commands/set/
- Redis — SREM — the remove-from-stalled-set step a successful renewal performs.
  https://redis.io/commands/srem/

### Related in this course

- `/echomq/core/lock-management` — E2.03 · the module hub.
- `/echomq/core/lock-management/stalled-recovery` — E2.03.2 · what happens to a job whose lock the
  renewal could not keep.
- `/echomq/core/lifecycle/the-lock-protocol` — E2.01.3 · the single-lock acquire, heartbeat, and
  token check this dive scales up.
- `/redis-patterns/queues` — redis-patterns R3 · the reliable-queue pattern this lock renewal upholds.
