defmodule EchoMQ.MeterTest do
  @moduledoc """
  The v1 `EchoMQ.Telemetry` test corpus ADOPTED for the v2 `EchoMQ.Meter`
  (emq.2.3-D3, the Operator's "tests v1 adopted and verified"). Re-derived
  against the v2 surface: the module is `EchoMQ.Meter`; the event tree is
  re-rooted `[:emq, …]` (the v1 `[:echomq, …]`); every emit guards
  `:telemetry` being present (the `Connector.emit/3` zero-cost precedent).

  The TWO-MODE contract (L-2): `:telemetry` is an OPTIONAL dependency the bus
  does not declare, so under the per-app `mix test` it may be ABSENT. The suite
  therefore asserts the REAL verdict of the surface in EITHER mode --
  PRESENT: the v1-derived assertions, the `[:emq, …]` event fires; ABSENT: the
  surface is callable and a safe no-op (attach/emit answer `:ok`, nothing
  fires). The telemetry CONTRACT (the payload-shape matrix) is emq.8 (INV6) --
  not asserted here; this proves the surface, in whatever mode the env provides.

  All `:telemetry.*` interaction routes through `apply/3` so the suite compiles
  with `:telemetry` off the path (the bus declares no `:telemetry` dep).
  """
  use ExUnit.Case, async: true

  alias EchoMQ.Meter

  @telemetry_loaded :erlang.function_exported(:telemetry, :execute, 3)

  defp t_attach(id, event, fun) do
    if @telemetry_loaded, do: apply(:telemetry, :attach, [id, event, fun, nil])
  end

  defp t_attach_many(id, events, fun) do
    if @telemetry_loaded, do: apply(:telemetry, :attach_many, [id, events, fun, nil])
  end

  defp t_execute(event, meas, meta) do
    if @telemetry_loaded, do: apply(:telemetry, :execute, [event, meas, meta])
  end

  defp t_detach(id) do
    if @telemetry_loaded, do: apply(:telemetry, :detach, [id])
  end

  describe "emit/3" do
    test "emits a telemetry event with an atom name (re-rooted [:emq, …])" do
      ref = make_ref()
      test_pid = self()
      id = "test-handler-#{inspect(ref)}"

      t_attach(id, [:emq, :test_event], fn event, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, event, measurements, metadata})
      end)

      assert :ok = Meter.emit(:test_event, %{value: 42}, %{queue: "test"})

      if @telemetry_loaded do
        assert_receive {:telemetry_event, [:emq, :test_event], %{value: 42}, %{queue: "test"}}
      else
        refute_receive {:telemetry_event, _, _, _}, 50
      end

      t_detach(id)
    end

    test "emits a telemetry event with a list name (re-rooted [:emq, …])" do
      ref = make_ref()
      test_pid = self()
      id = "test-handler-#{inspect(ref)}"

      t_attach(id, [:emq, :job, :complete], fn event, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, event, measurements, metadata})
      end)

      assert :ok = Meter.emit([:job, :complete], %{duration: 100}, %{job_id: "123"})

      if @telemetry_loaded do
        assert_receive {:telemetry_event, [:emq, :job, :complete], %{duration: 100},
                        %{job_id: "123"}}
      else
        refute_receive {:telemetry_event, _, _, _}, 50
      end

      t_detach(id)
    end
  end

  describe "attach/4" do
    test "attaches a handler to an [:emq, …]-prefixed event" do
      ref = make_ref()
      test_pid = self()
      id = "test-attach-#{inspect(ref)}"

      # Meter.attach is the unit under test; it prepends [:emq] and delegates.
      assert :ok = Meter.attach(id, [:custom, :event], fn event, m, md, _ ->
        send(test_pid, {:handler_called, event, m, md})
      end)

      t_execute([:emq, :custom, :event], %{data: 1}, %{})

      if @telemetry_loaded do
        assert_receive {:handler_called, [:emq, :custom, :event], %{data: 1}, %{}}
      else
        refute_receive {:handler_called, _, _, _}, 50
      end

      t_detach(id)
    end
  end

  describe "attach_many/4" do
    test "attaches a handler to multiple events" do
      ref = make_ref()
      test_pid = self()
      id = "test-attach-many-#{inspect(ref)}"

      assert :ok = Meter.attach_many(id, [[:event, :one], [:event, :two]], fn event, _m, _md, _ ->
        send(test_pid, {:event_received, event})
      end)

      t_execute([:emq, :event, :one], %{}, %{})
      t_execute([:emq, :event, :two], %{}, %{})

      if @telemetry_loaded do
        assert_receive {:event_received, [:emq, :event, :one]}
        assert_receive {:event_received, [:emq, :event, :two]}
      else
        refute_receive {:event_received, _}, 50
      end

      t_detach(id)
    end
  end

  describe "span/3" do
    test "always runs the function and (when telemetry is present) emits start + stop" do
      ref = make_ref()
      test_pid = self()
      id = "test-span-#{inspect(ref)}"

      t_attach_many(id, [[:emq, :operation, :start], [:emq, :operation, :stop]], fn event, m, md, _ ->
        send(test_pid, {:span_event, event, m, md})
      end)

      # the wrapped function ALWAYS runs and returns its value (the zero-cost
      # contract: span is callable with or without telemetry)
      assert :ok ==
               Meter.span([:operation], %{id: "op-1"}, fn ->
                 Process.sleep(10)
                 :ok
               end)

      if @telemetry_loaded do
        assert_receive {:span_event, [:emq, :operation, :start], %{system_time: _}, %{id: "op-1"}}

        assert_receive {:span_event, [:emq, :operation, :stop], %{duration: duration},
                        %{id: "op-1"}}

        assert duration > 0
      else
        refute_receive {:span_event, _, _, _}, 50
      end

      t_detach(id)
    end

    test "re-raises on error and (when telemetry is present) emits an exception event" do
      ref = make_ref()
      test_pid = self()
      id = "test-span-error-#{inspect(ref)}"

      t_attach_many(id, [[:emq, :operation, :start], [:emq, :operation, :exception]], fn event, m, md, _ ->
        send(test_pid, {:span_event, event, m, md})
      end)

      # the exception always propagates (the work's failure is not swallowed)
      assert_raise RuntimeError, fn ->
        Meter.span([:operation], %{id: "op-2"}, fn -> raise "test error" end)
      end

      if @telemetry_loaded do
        assert_receive {:span_event, [:emq, :operation, :start], _, _}
        assert_receive {:span_event, [:emq, :operation, :exception], %{duration: _}, metadata}
        assert metadata.kind == :error
        assert %RuntimeError{} = metadata.reason
      else
        refute_receive {:span_event, _, _, _}, 50
      end

      t_detach(id)
    end
  end

  describe "convenience emitters (the v1 lifecycle helpers, re-rooted)" do
    test "job_added/4 emits [:emq, :job, :add]" do
      ref = make_ref()
      test_pid = self()
      id = "test-job-added-#{inspect(ref)}"

      t_attach(id, [:emq, :job, :add], fn event, m, md, _ ->
        send(test_pid, {:event, event, m, md})
      end)

      assert :ok = Meter.job_added("test-queue", "job-123", "process", 50)

      if @telemetry_loaded do
        assert_receive {:event, [:emq, :job, :add], %{queue_time: 50}, metadata}
        assert metadata.queue == "test-queue"
        assert metadata.job_id == "job-123"
        assert metadata.job_name == "process"
      else
        refute_receive {:event, _, _, _}, 50
      end

      t_detach(id)
    end

    test "job_completed/5 emits [:emq, :job, :complete]" do
      ref = make_ref()
      test_pid = self()
      id = "test-job-completed-#{inspect(ref)}"

      t_attach(id, [:emq, :job, :complete], fn event, m, md, _ ->
        send(test_pid, {:event, event, m, md})
      end)

      assert :ok = Meter.job_completed("emails", "job-456", "send", self(), 1000)

      if @telemetry_loaded do
        assert_receive {:event, [:emq, :job, :complete], %{duration: 1000}, metadata}
        assert metadata.queue == "emails"
        assert metadata.job_id == "job-456"
        assert metadata.job_name == "send"
        assert metadata.worker == self()
      else
        refute_receive {:event, _, _, _}, 50
      end

      t_detach(id)
    end

    test "job_failed/6 emits [:emq, :job, :fail] with the error" do
      ref = make_ref()
      test_pid = self()
      id = "test-job-failed-#{inspect(ref)}"

      t_attach(id, [:emq, :job, :fail], fn event, m, md, _ ->
        send(test_pid, {:event, event, m, md})
      end)

      error = %RuntimeError{message: "test error"}
      assert :ok = Meter.job_failed("emails", "job-789", "send", self(), 500, error)

      if @telemetry_loaded do
        assert_receive {:event, [:emq, :job, :fail], %{duration: 500}, metadata}
        assert metadata.queue == "emails"
        assert metadata.error == error
      else
        refute_receive {:event, _, _, _}, 50
      end

      t_detach(id)
    end

    test "rate_limit_hit/2 emits [:emq, :rate_limit, :hit]" do
      ref = make_ref()
      test_pid = self()
      id = "test-rate-limit-#{inspect(ref)}"

      t_attach(id, [:emq, :rate_limit, :hit], fn event, m, md, _ ->
        send(test_pid, {:event, event, m, md})
      end)

      assert :ok = Meter.rate_limit_hit("api-calls", 5000)

      if @telemetry_loaded do
        assert_receive {:event, [:emq, :rate_limit, :hit], %{delay: 5000}, %{queue: "api-calls"}}
      else
        refute_receive {:event, _, _, _}, 50
      end

      t_detach(id)
    end
  end

  describe "the zero-cost guard (the v2 surface contract)" do
    test "attach + emit are callable and answer :ok regardless of :telemetry presence" do
      # This is the new-surface contract the v1 corpus did not test (v1 had a
      # hard :telemetry dep): the bus carries no dep, so the surface must be a
      # safe no-op when :telemetry is absent (INV6, the Connector.emit/3
      # precedent). Both modes answer :ok.
      assert :ok = Meter.attach("zc-#{inspect(make_ref())}", [:zc, :evt], fn _, _, _, _ -> :ok end)
      assert :ok = Meter.attach_many("zcm-#{inspect(make_ref())}", [[:a], [:b]], fn _, _, _, _ -> :ok end)
      assert :ok = Meter.emit(:anything, %{}, %{})
      assert :ok = Meter.emit([:a, :b], %{}, %{})
      assert :ok = Meter.worker_started("q", self(), 4)
      assert :ok = Meter.worker_stopped("q", self(), 1000)
      assert 99 == Meter.span([:x], %{}, fn -> 99 end)
    end
  end
end
