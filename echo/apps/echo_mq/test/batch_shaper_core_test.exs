defmodule EchoMQ.BatchShaper.CoreTest do
  @moduledoc """
  The batch shaper's pure decision core (emq.5.2, INV-PureCore): the
  `min_size`/`timeout` flush decision as a plain function of the observed
  depth, the injected elapsed, and the two knobs -- no process, no clock, no
  I/O. The cadence behavior (the live watch-flush-settle) is the
  `batch_consumer_test.exs` `:valkey` suite; this pins the decision and the
  knob validation. The `EchoMQ.Pump.Core` doctest precedent.
  """
  use ExUnit.Case, async: true

  alias EchoMQ.BatchShaper.Core

  doctest EchoMQ.BatchShaper.Core

  describe "validate!/2" do
    test "returns the positive knobs unchanged" do
      assert Core.validate!(10, 200) == {10, 200}
      assert Core.validate!(1, 1) == {1, 1}
    end

    test "raises on a non-positive min_size" do
      assert_raise ArgumentError, ~r/min_size/, fn -> Core.validate!(0, 200) end
      assert_raise ArgumentError, ~r/min_size/, fn -> Core.validate!(-5, 200) end
    end

    test "raises on a non-positive timeout" do
      assert_raise ArgumentError, ~r/timeout/, fn -> Core.validate!(10, 0) end
      assert_raise ArgumentError, ~r/timeout/, fn -> Core.validate!(10, -1) end
    end

    test "raises on a non-integer knob" do
      assert_raise ArgumentError, fn -> Core.validate!(10.0, 200) end
      assert_raise ArgumentError, fn -> Core.validate!(10, :nope) end
    end
  end

  describe "decide/4 -- D1 the size floor (watch-depth)" do
    test "flushes the full observed depth at the floor" do
      # depth == min_size: flush exactly min_size
      assert Core.decide(10, 0, 10, 200) == {:flush, 10}
    end

    test "flushes the full observed depth above the floor (drain all-ready)" do
      # depth > min_size: request the full depth, not just min_size
      assert Core.decide(25, 0, 10, 200) == {:flush, 25}
    end

    test "waits below the floor with time remaining" do
      assert Core.decide(9, 0, 10, 200) == :wait
      assert Core.decide(1, 199, 10, 200) == :wait
    end

    test "the floor wins even at the ceiling (a full batch is still a flush)" do
      # at the ceiling AND at/over the floor -> {:flush, depth} (the floor leg
      # subsumes; the request is the full depth, >= min_size)
      assert Core.decide(12, 200, 10, 200) == {:flush, 12}
    end
  end

  describe "decide/4 -- D2 the latency ceiling (ceiling-wins / soft floor / empty)" do
    test "flushes the partial when the ceiling fires below the floor" do
      # elapsed >= timeout, depth < min_size -> flush the partial (< min_size)
      assert Core.decide(3, 200, 10, 200) == {:flush, 3}
      assert Core.decide(1, 500, 10, 200) == {:flush, 1}
    end

    test "an empty window at the ceiling flushes nothing (re-open)" do
      # depth == 0 at the ceiling -> :wait (no batch -- a zero-member batch
      # carries no work, D2 empty case)
      assert Core.decide(0, 200, 10, 200) == :wait
      assert Core.decide(0, 10_000, 10, 200) == :wait
    end

    test "the boundary: elapsed exactly == timeout fires the ceiling" do
      assert Core.decide(2, 200, 10, 200) == {:flush, 2}
      assert Core.decide(2, 199, 10, 200) == :wait
    end
  end

  describe "decide/4 -- determinism + guards" do
    test "the same arguments always yield the same decision" do
      args = {7, 120, 10, 200}
      {d, e, m, t} = args
      first = Core.decide(d, e, m, t)
      assert Enum.all?(1..50, fn _ -> Core.decide(d, e, m, t) == first end)
    end

    test "re-validates the knobs (a non-positive knob raises at decide too)" do
      assert_raise ArgumentError, fn -> Core.decide(5, 10, 0, 200) end
      assert_raise ArgumentError, fn -> Core.decide(5, 10, 10, 0) end
    end
  end
end
