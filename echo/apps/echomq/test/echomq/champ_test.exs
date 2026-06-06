defmodule EchoMQ.ChampTest do
  use ExUnit.Case, async: true

  alias EchoMQ.Champ

  describe "generate_id/1" do
    test "generates job ID with correct prefix" do
      id = Champ.generate_id(:job)
      assert String.starts_with?(id, "JOB")
      assert byte_size(id) == 14
    end

    test "generates event ID with correct prefix" do
      id = Champ.generate_id(:event)
      assert String.starts_with?(id, "EVT")
      assert byte_size(id) == 14
    end

    test "generates flow ID with correct prefix" do
      id = Champ.generate_id(:flow)
      assert String.starts_with?(id, "FLW")
      assert byte_size(id) == 14
    end

    test "generates queue ID with correct prefix" do
      id = Champ.generate_id(:queue)
      assert String.starts_with?(id, "QUE")
      assert byte_size(id) == 14
    end

    test "generates worker ID with correct prefix" do
      id = Champ.generate_id(:worker)
      assert String.starts_with?(id, "WRK")
      assert byte_size(id) == 14
    end

    test "generates trace ID with correct prefix" do
      id = Champ.generate_id(:trace)
      assert String.starts_with?(id, "TRC")
      assert byte_size(id) == 14
    end

    test "generates unique IDs" do
      ids = for _ <- 1..100, do: Champ.generate_id(:job)
      assert length(Enum.uniq(ids)) == 100
    end
  end

  describe "parse/1" do
    test "parses valid job ID" do
      id = Champ.generate_id(:job)
      assert {:ok, :job, snowflake} = Champ.parse(id)
      assert is_integer(snowflake)
    end

    test "parses valid event ID" do
      id = Champ.generate_id(:event)
      assert {:ok, :event, _snowflake} = Champ.parse(id)
    end

    test "returns error for invalid length" do
      assert :error = Champ.parse("JOB123")
      assert :error = Champ.parse("JOB0123456789ABC")
    end

    test "returns error for unknown namespace" do
      assert :error = Champ.parse("XXX0123456789A")
    end

    test "returns error for non-string" do
      assert :error = Champ.parse(123)
      assert :error = Champ.parse(nil)
    end
  end

  describe "namespace/1" do
    test "extracts namespace from valid ID" do
      job_id = Champ.generate_id(:job)
      assert {:ok, :job} = Champ.namespace(job_id)

      event_id = Champ.generate_id(:event)
      assert {:ok, :event} = Champ.namespace(event_id)
    end

    test "returns error for invalid ID" do
      assert :error = Champ.namespace("invalid")
      assert :error = Champ.namespace(nil)
    end
  end

  describe "timestamp/1" do
    test "extracts timestamp from ID" do
      id = Champ.generate_id(:job)
      ts = Champ.timestamp(id)
      assert %DateTime{} = ts
      # Should be recent (within last minute)
      assert DateTime.diff(DateTime.utc_now(), ts, :second) < 60
    end

    test "returns nil for invalid ID" do
      assert nil == Champ.timestamp("invalid")
      assert nil == Champ.timestamp(nil)
    end
  end

  describe "extract/1" do
    test "extracts all components from ID" do
      id = Champ.generate_id(:flow)
      assert {:ok, components} = Champ.extract(id)
      # Extract returns snowflake components (timestamp_ms, worker_id, sequence)
      assert is_integer(components.timestamp_ms)
      assert is_integer(components.worker_id)
      assert is_integer(components.sequence)
      assert %DateTime{} = components.timestamp
    end

    test "returns error for invalid ID" do
      assert :error = Champ.extract("short")
    end
  end

  describe "envelope/4" do
    test "creates message envelope with required fields" do
      msg = Champ.envelope(:job_completed, %{result: "ok"})

      assert is_binary(msg.id)
      assert String.starts_with?(msg.id, "EVT")
      assert msg.type == :job_completed
      assert msg.payload == %{result: "ok"}
      assert is_map(msg.trace_context)
      # timestamp is epoch ms integer
      assert is_integer(msg.timestamp)
    end

    test "includes reference ID when provided" do
      ref_id = Champ.generate_id(:job)
      msg = Champ.envelope(:job_failed, %{error: "timeout"}, ref_id)

      assert msg.ref_id == ref_id
    end

    test "accepts trace context in opts" do
      trace_ctx = %{
        trace_id: "abc123def456abc123def456abc12345",
        span_id: "1234567890123456",
        trace_flags: 1
      }
      msg = Champ.envelope(:job_started, %{}, nil, trace_context: trace_ctx)

      # Trace ID is preserved
      assert msg.trace_context.trace_id == trace_ctx.trace_id
    end
  end

  describe "namespace_prefix/1" do
    test "returns prefix for valid namespace" do
      assert "JOB" = Champ.namespace_prefix(:job)
      assert "EVT" = Champ.namespace_prefix(:event)
      assert "FLW" = Champ.namespace_prefix(:flow)
      assert "QUE" = Champ.namespace_prefix(:queue)
      assert "WRK" = Champ.namespace_prefix(:worker)
      assert "TRC" = Champ.namespace_prefix(:trace)
    end
  end

  describe "format_traceparent/1" do
    test "formats W3C traceparent header" do
      ctx = %{
        trace_id: "abc123def456abc123def456abc12345",
        span_id: "1234567890123456",
        trace_flags: 1
      }

      header = Champ.format_traceparent(ctx)
      assert header =~ ~r/^00-[a-f0-9]{32}-[a-f0-9]{16}-0[0-9]$/
    end
  end

  describe "parse_traceparent/1" do
    test "parses valid traceparent header" do
      header = "00-abc123def456abc123def456abc12345-1234567890123456-01"

      assert {:ok, ctx} = Champ.parse_traceparent(header)
      assert ctx.trace_id == "abc123def456abc123def456abc12345"
      assert ctx.span_id == "1234567890123456"
      assert ctx.trace_flags == 1
    end

    test "returns error for invalid format" do
      assert :error = Champ.parse_traceparent("invalid")
      assert :error = Champ.parse_traceparent(nil)
    end
  end

  describe "to_json/1 and from_json/1" do
    test "roundtrips message envelope" do
      original = Champ.envelope(:job_completed, %{result: 42})

      json = Champ.to_json(original)
      assert is_binary(json)

      {:ok, parsed} = Champ.from_json(json)
      assert parsed.id == original.id
      assert parsed.type == original.type
      # JSON keys become strings
      assert parsed.payload == %{"result" => 42}
    end
  end

  describe "child_trace_context/1" do
    test "creates child context with same trace_id" do
      parent = %{
        trace_id: "parent_trace_id_32chars_0000000",
        span_id: "parent_span_1234",
        trace_flags: 1
      }

      child = Champ.child_trace_context(parent)

      assert child.trace_id == parent.trace_id
      assert child.span_id != parent.span_id  # New span
      assert child.trace_flags == parent.trace_flags
    end
  end
end
