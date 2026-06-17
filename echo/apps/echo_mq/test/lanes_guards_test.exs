defmodule EchoMQ.LanesGuardsTest do
  @moduledoc """
  The pure column of the Lanes row (echo2-migration.md §5): `lane_key!/2`
  refuses a non-branded group through every public verb, before any wire
  work — the conn argument is a plain atom on purpose.
  """
  use ExUnit.Case, async: true

  alias EchoMQ.Lanes

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  test "enqueue/5 refuses a non-branded group with the lane-name law" do
    job = EchoData.BrandedId.generate!("JOB")

    assert_raise ArgumentError, "a lane is named by a valid branded id", fn ->
      Lanes.enqueue(:no_conn, "q", "team-a", job, "payload")
    end
  end

  test "pause/3 refuses a non-branded group" do
    assert_raise ArgumentError, fn -> Lanes.pause(:no_conn, "q", "team-a") end
  end

  test "resume/3 refuses a non-branded group" do
    assert_raise ArgumentError, fn -> Lanes.resume(:no_conn, "q", "team-a") end
  end

  test "limit/4 refuses a non-branded group" do
    assert_raise ArgumentError, fn -> Lanes.limit(:no_conn, "q", "team-a", 2) end
  end

  test "limit/4 refuses a non-positive ceiling (n > 0)" do
    group = EchoData.BrandedId.generate!("PRT")
    assert_raise FunctionClauseError, fn -> Lanes.limit(:no_conn, "q", group, 0) end
  end

  test "depth/3 refuses a non-branded group" do
    assert_raise ArgumentError, fn -> Lanes.depth(:no_conn, "q", "team-a") end
  end

  test "claim/3 refuses a non-positive lease (lease_ms > 0)" do
    assert_raise FunctionClauseError, fn -> Lanes.claim(:no_conn, "q", 0) end
  end
end
