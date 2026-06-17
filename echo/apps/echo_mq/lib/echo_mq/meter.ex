defmodule EchoMQ.Meter do
  @moduledoc """
  The `:telemetry` surface over the job lifecycle: `attach`/`attach_many`/
  `emit`/`span` and the lifecycle convenience emitters, re-rooted under
  `[:emq, …]` (the v1 `EchoMQ.Telemetry` capability re-derived). So throughput,
  latency, and failure counts are metered the standard Elixir way -- AT ZERO
  COST when `:telemetry` is not loaded. emq.2.3-D3.

  (The module is `EchoMQ.Meter`, not `EchoMQ.Telemetry`: the frozen v1
  reference `apps/echomq` already defines `EchoMQ.Telemetry`, and both apps
  load on one code path -- a same-named module would shadow the new bus
  non-deterministically. The capability is the v1 telemetry surface's; the name
  is collision-free. emq.2.3 realization-over-literal, ledger L-1.)

  Re-rooted `[:emq | suffix]` (the v1 `[:echomq | suffix]` re-rooted to the bus
  namespace -- the connector already fires `[:emq, :connector, …]`, one tree).
  Every emission guards `:erlang.function_exported(:telemetry, :execute, 3)`
  (the `EchoMQ.Connector.emit/3` precedent): with no `:telemetry` dependency
  loaded, an emit is a no-op and an `attach` answers `:ok` with no effect, so
  the bus carries NO `:telemetry` dependency edge (a host opts in by adding
  `:telemetry` itself). `span/3` always RUNS the wrapped function -- only the
  start/stop/exception events are guarded.

  This ships the telemetry **surface** (the events fire). The telemetry
  **contract** -- the payload-shape assertions, the engine matrix -- is
  **emq.8** (ADR-2's two-layer split). emq.2.3 registers a telemetry
  conformance scenario (an attached `[:emq, …]` handler receives a lifecycle
  event); it does not assert emq.8's contract.
  """

  @type suffix :: [atom()]
  @type measurements :: map()
  @type metadata :: map()

  @root :emq

  defp loaded?, do: :erlang.function_exported(:telemetry, :execute, 3)

  @doc """
  Attach a handler to an EchoMQ event (the `[:emq | suffix]` event tree). A
  convenience over `:telemetry.attach/4`. With no `:telemetry` loaded, answers
  `:ok` as a no-op (the event never fires, so the handler is harmless).
  """
  @spec attach(binary(), suffix(), function(), term()) :: :ok | {:error, term()}
  def attach(handler_id, event_suffix, handler_fn, config \\ nil) do
    if loaded?() do
      apply(:telemetry, :attach, [handler_id, [@root | event_suffix], handler_fn, config])
    else
      :ok
    end
  end

  @doc """
  Attach a handler to several EchoMQ events at once (each `[:emq | suffix]`). A
  convenience over `:telemetry.attach_many/4`. With no `:telemetry` loaded,
  answers `:ok` as a no-op.
  """
  @spec attach_many(binary(), [suffix()], function(), term()) :: :ok | {:error, term()}
  def attach_many(handler_id, event_suffixes, handler_fn, config \\ nil) do
    if loaded?() do
      events = Enum.map(event_suffixes, fn suffix -> [@root | suffix] end)
      apply(:telemetry, :attach_many, [handler_id, events, handler_fn, config])
    else
      :ok
    end
  end

  @doc """
  Emit an EchoMQ telemetry event. Either an atom name (wrapped to a single-
  element suffix) or a suffix list; both are rooted `[:emq | …]`. Guarded
  zero-cost when `:telemetry` is absent (the `Connector.emit/3` precedent).
  Answers `:ok`.
  """
  @spec emit(atom() | suffix(), measurements(), metadata()) :: :ok
  def emit(event_name, measurements, metadata) when is_atom(event_name) do
    emit([event_name], measurements, metadata)
  end

  def emit(event_suffix, measurements, metadata) when is_list(event_suffix) do
    if loaded?() do
      apply(:telemetry, :execute, [[@root | event_suffix], measurements, metadata])
    end

    :ok
  end

  @doc """
  Span a function call with start/stop/exception telemetry events around it
  (the standard `:telemetry.span` shape, re-rooted `[:emq | suffix]`). The
  wrapped function ALWAYS runs; only the events are guarded zero-cost when
  `:telemetry` is absent. Answers the function's result; re-raises on an
  exception after emitting the exception event.
  """
  @spec span(suffix(), metadata(), (-> result)) :: result when result: term()
  def span(event_suffix, metadata, fun) do
    if loaded?() do
      span_metered([@root | event_suffix], metadata, fun)
    else
      fun.()
    end
  end

  defp span_metered(event_prefix, metadata, fun) do
    start_time = System.monotonic_time()

    apply(:telemetry, :execute, [
      event_prefix ++ [:start],
      %{system_time: System.system_time()},
      metadata
    ])

    try do
      result = fun.()
      duration = System.monotonic_time() - start_time
      apply(:telemetry, :execute, [event_prefix ++ [:stop], %{duration: duration}, metadata])
      result
    rescue
      exception ->
        duration = System.monotonic_time() - start_time

        apply(:telemetry, :execute, [
          event_prefix ++ [:exception],
          %{duration: duration},
          Map.merge(metadata, %{kind: :error, reason: exception, stacktrace: __STACKTRACE__})
        ])

        reraise exception, __STACKTRACE__
    end
  end

  # -- lifecycle convenience emitters (the v1 six + worker_stopped/rate_limit_hit)

  @doc "Emit `[:emq, :job, :add]`: a job was admitted (the v1 `job_added`)."
  def job_added(queue, job_id, job_name, duration) do
    emit([:job, :add], %{queue_time: duration}, %{queue: queue, job_id: job_id, job_name: job_name})
  end

  @doc "Emit `[:emq, :job, :start]`: a job began (the v1 `job_started`)."
  def job_started(queue, job_id, job_name, worker_pid) do
    emit([:job, :start], %{system_time: System.system_time()}, %{
      queue: queue,
      job_id: job_id,
      job_name: job_name,
      worker: worker_pid
    })
  end

  @doc "Emit `[:emq, :job, :complete]`: a job completed (the v1 `job_completed`)."
  def job_completed(queue, job_id, job_name, worker_pid, duration) do
    emit([:job, :complete], %{duration: duration}, %{
      queue: queue,
      job_id: job_id,
      job_name: job_name,
      worker: worker_pid
    })
  end

  @doc "Emit `[:emq, :job, :fail]`: a job failed (the v1 `job_failed`)."
  def job_failed(queue, job_id, job_name, worker_pid, duration, error) do
    emit([:job, :fail], %{duration: duration}, %{
      queue: queue,
      job_id: job_id,
      job_name: job_name,
      worker: worker_pid,
      error: error
    })
  end

  @doc "Emit `[:emq, :job, :retry]`: a job was retried (the v1 `job_retried`)."
  def job_retried(queue, job_id, job_name, attempt, delay) do
    emit([:job, :retry], %{attempt: attempt, delay: delay}, %{
      queue: queue,
      job_id: job_id,
      job_name: job_name
    })
  end

  @doc "Emit `[:emq, :worker, :start]`: a worker started (the v1 `worker_started`)."
  def worker_started(queue, worker_pid, concurrency) do
    emit([:worker, :start], %{concurrency: concurrency}, %{queue: queue, worker: worker_pid})
  end

  @doc "Emit `[:emq, :worker, :stop]`: a worker stopped (the v1 `worker_stopped`)."
  def worker_stopped(queue, worker_pid, uptime) do
    emit([:worker, :stop], %{uptime: uptime}, %{queue: queue, worker: worker_pid})
  end

  @doc "Emit `[:emq, :rate_limit, :hit]`: a rate limit was hit (the v1 `rate_limit_hit`)."
  def rate_limit_hit(queue, delay) do
    emit([:rate_limit, :hit], %{delay: delay}, %{queue: queue})
  end
end
