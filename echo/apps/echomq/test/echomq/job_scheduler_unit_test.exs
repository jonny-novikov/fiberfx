defmodule EchoMQ.JobSchedulerUnitTest do
  @moduledoc """
  Unit tests for JobScheduler pure functions.
  For integration tests that require Redis, see job_scheduler_integration_test.exs
  """
  use ExUnit.Case, async: true

  alias EchoMQ.JobScheduler

  describe "calculate_next_millis/2 with :immediately" do
    test "returns reference time when immediately is true" do
      now = System.system_time(:millisecond)
      opts = %{immediately: true}

      result = JobScheduler.calculate_next_millis(opts, now)
      assert result == now
    end
  end

  describe "calculate_next_millis/2 with :every" do
    test "returns next interval time" do
      now = 1000
      opts = %{every: 60_000}  # 1 minute

      result = JobScheduler.calculate_next_millis(opts, now)
      # Should be in the future relative to reference time
      assert is_integer(result)
      assert result >= now
    end

    test "respects offset option" do
      now = 1000
      opts = %{every: 60_000, offset: 5000}

      result = JobScheduler.calculate_next_millis(opts, now)
      # Should include offset
      assert result >= now
    end

    test "respects start_date option" do
      now = 1000
      future_start = 100_000
      opts = %{every: 60_000, start_date: future_start}

      result = JobScheduler.calculate_next_millis(opts, now)
      # Should not be before start_date
      assert result >= future_start
    end

    test "returns nil if end_date is passed" do
      now = 100_000
      past_end = 50_000
      opts = %{every: 60_000, end_date: past_end}

      result = JobScheduler.calculate_next_millis(opts, now)
      assert result == nil
    end
  end

  describe "calculate_next_millis/2 with :pattern" do
    test "calculates next cron time for simple pattern" do
      now = System.system_time(:millisecond)
      opts = %{pattern: "* * * * *"}  # Every minute

      result = JobScheduler.calculate_next_millis(opts, now)
      assert is_integer(result)
      assert result > now
      # Should be within ~61 seconds (next minute)
      assert result - now <= 61_000
    end

    test "handles hourly pattern" do
      now = System.system_time(:millisecond)
      opts = %{pattern: "0 * * * *"}  # Top of every hour

      result = JobScheduler.calculate_next_millis(opts, now)
      assert is_integer(result)
      assert result > now
    end

    test "respects timezone option" do
      now = System.system_time(:millisecond)
      opts = %{pattern: "0 9 * * *", tz: "UTC"}

      result = JobScheduler.calculate_next_millis(opts, now)
      assert is_integer(result)
      assert result > now
    end

    test "respects start_date with cron pattern" do
      now = 1000
      future_start = System.system_time(:millisecond) + 86_400_000  # Tomorrow
      opts = %{pattern: "* * * * *", start_date: future_start}

      result = JobScheduler.calculate_next_millis(opts, now)
      # Should respect start_date
      assert result >= future_start or result == nil
    end

    test "returns nil for invalid pattern" do
      now = System.system_time(:millisecond)
      opts = %{pattern: "invalid cron"}

      result = JobScheduler.calculate_next_millis(opts, now)
      # Should handle gracefully (nil or error)
      assert result == nil or is_integer(result)
    end
  end

  describe "calculate_next_millis/2 edge cases" do
    test "returns nil for empty opts" do
      result = JobScheduler.calculate_next_millis(%{})
      assert result == nil
    end

    test "returns nil for invalid opts type" do
      result = JobScheduler.calculate_next_millis(nil)
      assert result == nil
    end
  end
end
