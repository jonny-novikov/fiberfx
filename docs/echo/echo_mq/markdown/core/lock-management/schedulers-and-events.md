# E2.03.3 · Schedulers & events

> Route: `/echomq/core/lock-management/schedulers-and-events` · Movement I · The Core · `← redis-patterns R3`

## The fact

Two supporting processes read and write the shared protocol around the lifecycle.
`EchoMQ.JobScheduler` emits recurring jobs on a schedule — a cron pattern or a fixed interval — and
`EchoMQ.QueueEvents` consumes the queue's lifecycle events in real time from a Redis Stream. Both
are library processes the host application supervises.

## The worked example — on the real `EchoMQ.JobScheduler`

A scheduler repeats either by **cron pattern** or by a fixed **`:every`** interval. A `repeat_opts`
is `%{every: ms}` or `%{pattern: "…cron…"}` (plus an optional `:immediately`). The public surface:

- `upsert(conn, queue_name, scheduler_id, repeat_opts, job_name, job_data \\ %{}, opts \\ [])` —
  create or update a scheduler.
- `get/4`, `list/3`, `count/3`, `remove/4`, `remove_by_key/4`.
- `calculate_next_millis(repeat_opts, reference_time \\ now)` — the next-run computation.

`calculate_next_millis` has one clause per shape:

```elixir
def calculate_next_millis(%{immediately: true}, reference_time), do: reference_time

def calculate_next_millis(%{every: every}, reference_time) when is_integer(every) do
  # default: the next run is reference_time + every
  reference_time + every
end

def calculate_next_millis(%{pattern: pattern}, reference_time) do
  # parse the cron expression and ask for the next run date after reference_time
  ...
end
```

So `%{every: 60_000}` schedules the next run 60_000 ms after the reference time, while
`%{pattern: "0 9 * * *"}` resolves to 9 AM on the next day the cron allows. The scheduler persists
its schedulers in Redis and emits the next delayed job each time it fires. The scheduler script
family lives in `priv/scripts`: `addJobScheduler-11`, `updateJobScheduler-12`, `getJobScheduler-1`,
and `removeJobScheduler-3` (the number on each is its `numkeys`).

## The worked example — on the real `EchoMQ.QueueEvents`

`EchoMQ.QueueEvents` subscribes to job lifecycle events over **Redis Streams**. It consumes by
blocking on the events stream in a `Task.async` and looping:

```elixir
Redix.command(blocking_conn, ["XREAD", "BLOCK", 5000, "STREAMS", events_key, last_event_id])
```

`events_key` is `emq:{queue}:events`; the read blocks for 5 s, then loops. The public surface is
`start_link/1`, `subscribe(server, pid \\ self())`, `unsubscribe(server, pid \\ self())`, and
`close(server)`. Each event reaches every subscriber as a message:

```elixir
{:echomq_event, event_type, event_data}
```

The event types, from `parse_event_type`, are `:added`, `:waiting`, `:active`, `:progress`,
`:completed`, `:failed`, `:delayed`, `:stalled`, `:removed`, `:drained`, `:paused`, `:resumed`,
`:duplicated`, `:deduplicated`, `:retries_exhausted`, `:waiting_children`, and `:cleaned`.

`last_event_id` defaults to `"$"` — only new events from the moment of subscription. Passing `"0"`
instead would replay the stream from its start. An optional `EchoMQ.QueueEvents.Handler` behaviour
(`handle_event/3`) gives structured, in-process handling alongside the subscriber messages.

## The key point — the stream is part of the protocol

The `emq:{queue}:events` Redis Stream is **L1/L2**. Every transition Lua script `XADD`s its event
onto that stream, so the stream is written **identically by all three runtimes**. `QueueEvents` is
only the Elixir consumer; Go and Node.js read the same stream their own way. Likewise the scheduler
keys persist in Redis under the protocol's key taxonomy, and the scheduler script family is shared.
These supporting processes read and write the shared protocol; the host supervises them, since
EchoMQ-Elixir ships no supervision tree of its own.

## The protocol and its three runtimes

The `emq:{queue}:events` stream and the `XADD` each transition script performs, plus the scheduler
keys in Redis (**L1/L2**), are frozen — written by the same Lua across runtimes. `JobScheduler` and
`QueueEvents` (Elixir `GenServer`s, the latter `XREAD`-consuming) are **L3/L4**. Go and Node.js have
their own scheduler and consumer; the same stream and scheduler keys sit underneath.

## Recap

- `JobScheduler` repeats by `%{every: ms}` or `%{pattern: cron}`; `calculate_next_millis` resolves
  the next run, and the scheduler emits a delayed job each time it fires.
- The scheduler script family is `addJobScheduler-11`, `updateJobScheduler-12`, `getJobScheduler-1`,
  `removeJobScheduler-3`.
- `QueueEvents` blocks on `XREAD … STREAMS emq:{queue}:events <last_event_id>` and delivers
  `{:echomq_event, type, data}` to each subscriber.
- `last_event_id` defaults to `"$"` (new events only); `"0"` replays from the stream start.
- The events stream is L1/L2 — every transition script `XADD`s onto it, so all three runtimes write
  it identically.

## References

### Sources

- BullMQ — Documentation — the job scheduler (cron/every), the events stream, and the lifecycle
  event vocabulary EchoMQ implements. https://docs.bullmq.io/
- Redis — XADD — the append each transition script makes onto the queue's events stream.
  https://redis.io/commands/xadd/
- Redis — XREAD — the blocking read `QueueEvents` loops to consume new events.
  https://redis.io/commands/xread/

### Related in this course

- `/echomq/core/lock-management` — E2.03 · the module hub.
- `/echomq/core/lock-management/stalled-recovery` — E2.03.2 · the checker that emits the `:stalled`
  event this consumer can observe.
- `/echomq/protocol` — E1 · the protocol whose key taxonomy and event stream these processes read
  and write.
- `/redis-patterns/queues` — redis-patterns R3 · the queue patterns the scheduler and event stream
  build on.
