# The telemetry surface

> Route: `/echomq/proof/telemetry-and-the-read-plane/the-telemetry-surface` · Module 02 · dive 01.
> Grounds in `EchoMQ.Meter` — `attach/4`, `attach_many/4`, `emit/3`, `span/3`, and the lifecycle emitters
> `job_added/4` / `job_started/4` / `job_completed/5` / `job_failed/6` (`echo/apps/echo_mq`).
> No Lua — the events fire host-side through `:telemetry`.

A running bus reports on itself by **emitting events** as work happens. The surface is the standard Elixir
`:telemetry` surface — `attach`, `emit`, `span` — re-rooted under one namespace, `[:emq, …]`, so every event
the bus fires lives on **one tree**. A host that wants to meter throughput, latency, and failure rates
attaches a handler to a `[:emq, …]` event; the bus fires the event; the numbers flow to the handler. Nothing
in the work path changes.

## Re-rooted under `[:emq, …]` — one tree

Telemetry events are lists of atoms. `EchoMQ.Meter` takes a **suffix** — `[:job, :start]`, `[:job, :complete]`
— and roots it under the bus namespace, so the host sees `[:emq, :job, :start]`. The connector already fires
`[:emq, :connector, …]`, so the meter's events and the connector's events are the **same tree**: one attach
prefix (`[:emq, …]`) reaches the whole bus. That is the point of the re-root — the host subscribes to one
namespace and gets every signal the system emits.

`attach/4` is a convenience over `:telemetry.attach/4`: it prepends `:emq` to the suffix and hands off.
`attach_many/4` does the same for a list of suffixes in one call — the usual way to meter a whole lifecycle.

```elixir
# echo_mq — EchoMQ.Meter
# @root is :emq — every event the bus fires is rooted [:emq | suffix], so the
# connector's [:emq, :connector, …] and the lifecycle's [:emq, :job, …] are ONE
# tree. attach/4 is a convenience over :telemetry.attach/4: prepend the root,
# hand off. (With no :telemetry loaded this answers :ok as a no-op — the next
# dive.)
@root :emq

def attach(handler_id, event_suffix, handler_fn, config \\ nil) do
  if loaded?() do
    apply(:telemetry, :attach, [handler_id, [@root | event_suffix], handler_fn, config])
  else
    :ok
  end
end

# attach to several events at once — the usual way to meter a whole lifecycle.
def attach_many(handler_id, event_suffixes, handler_fn, config \\ nil) do
  if loaded?() do
    events = Enum.map(event_suffixes, fn suffix -> [@root | suffix] end)
    apply(:telemetry, :attach_many, [handler_id, events, handler_fn, config])
  else
    :ok
  end
end
```

## The lifecycle emitters — the named beats of a job

`emit/3` fires one event; `span/3` wraps a function call in start/stop/exception events around it. On top of
those, `EchoMQ.Meter` exposes **named lifecycle emitters** so a job's beats are fired by name with the right
measurements and metadata already shaped:

- **`job_added/4`** → `[:emq, :job, :add]` with a `queue_time` measurement — a job was admitted.
- **`job_started/4`** → `[:emq, :job, :start]` with `system_time` and the worker pid — a job began.
- **`job_completed/5`** → `[:emq, :job, :complete]` with `duration` — a job finished.
- **`job_failed/6`** → `[:emq, :job, :fail]` with `duration` and the `error` — a job failed.

Each is a thin call into `emit/3`: the measurements are the numbers a handler aggregates (a histogram of
`duration`, a counter of `:fail`), and the metadata is the context (`queue`, `job_id`, `job_name`, `worker`).
Because they all route through `emit/3`, they all inherit the **zero-cost guard** the next dive is about — a
host that has not opted into `:telemetry` pays nothing for these calls sitting in the lifecycle.

```elixir
# echo_mq — EchoMQ.Meter
# The named lifecycle beats. Each is a thin emit/3 with the measurements a handler
# aggregates (duration, queue_time) and the metadata that contexts them (queue,
# job_id, job_name, worker). All rooted [:emq, :job, …] — one tree with the
# connector's events.
def job_started(queue, job_id, job_name, worker_pid) do
  emit([:job, :start], %{system_time: System.system_time()}, %{
    queue: queue,
    job_id: job_id,
    job_name: job_name,
    worker: worker_pid
  })
end

def job_completed(queue, job_id, job_name, worker_pid, duration) do
  emit([:job, :complete], %{duration: duration}, %{
    queue: queue,
    job_id: job_id,
    job_name: job_name,
    worker: worker_pid
  })
end

def job_failed(queue, job_id, job_name, worker_pid, duration, error) do
  emit([:job, :fail], %{duration: duration}, %{
    queue: queue,
    job_id: job_id,
    job_name: job_name,
    worker: worker_pid,
    error: error
  })
end
```

## `span/3` — measure a block, surface a raise

`span/3` is the standard `:telemetry.span` shape, re-rooted: it fires `[:emq | suffix, :start]` before the
function, `[:emq | suffix, :stop]` with a measured `duration` after it succeeds, and
`[:emq | suffix, :exception]` (with the kind, reason, and stacktrace) if it raises — then **re-raises**, so
the span never swallows the error. The one rule that makes `span/3` safe to wrap anything: the **wrapped
function always runs**; only the *events* are guarded zero-cost. With `:telemetry` absent the span reduces to
`fun.()` — the work is never skipped because nobody is metering.

## Pattern & implementation

- **The pattern (Redis Patterns Applied):** instrument the running system so an operator can see throughput,
  latency, and failures — without changing the work. `/redis-patterns/production-operations` teaches running
  the tier.
- **The implementation (echo_mq):** `EchoMQ.Meter` re-roots the standard `:telemetry` surface under
  `[:emq, …]`, names the lifecycle beats (`job_added` / `job_started` / `job_completed` / `job_failed`), and
  `span/3` measures a block while re-raising any error — one tree the host attaches once to meter the whole
  bus.

## References

### Sources
- [Elixir — the `:telemetry` library](https://hexdocs.pm/telemetry/readme.html) — the metering surface the Meter re-roots under `[:emq, …]`.
- [Erlang/OTP — `:telemetry.execute/3`](https://hexdocs.pm/telemetry/telemetry.html) — the execute the lifecycle emitters call.
- [Erlang/OTP — `:telemetry.span/3`](https://hexdocs.pm/telemetry/telemetry.html#span/3) — the start/stop/exception shape `span/3` re-roots.

### Related in this course
- `/echomq/proof/telemetry-and-the-read-plane` — the module this dive belongs to.
- `/echomq/proof/telemetry-and-the-read-plane/zero-cost-when-absent` — why these emitters cost nothing unless a host opts in.
- `/echomq/proof/telemetry-and-the-read-plane/the-read-plane` — the pull side that answers state by reading.
- `/echomq/queue` — the job lifecycle these events are the beats of.
- `/redis-patterns/production-operations` — the production-operations pattern that doors here.
- `/bcs/together` — the manuscript chapter (B6) where the four libraries are one umbrella.
