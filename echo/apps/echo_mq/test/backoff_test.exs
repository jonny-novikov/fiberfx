defmodule EchoMQ.BackoffTest do
  @moduledoc """
  The pure backoff vocabulary (EMQ.1-D4): policy + attempts -> delay_ms, no
  process, no clock. The wire-feeding drill (dead at the cap) is the
  `:backoff` conformance scenario; this pins the curve.
  """
  use ExUnit.Case, async: true

  alias EchoMQ.Backoff

  doctest EchoMQ.Backoff

  test "fixed is the same delay on every attempt" do
    for att <- 1..10, do: assert(Backoff.delay_ms({:fixed, 500}, att) == 500)
  end

  test "exponential climbs base * 2^(attempts-1) then clamps at cap" do
    assert Backoff.delay_ms({:exponential, 100, 10_000}, 1) == 100
    assert Backoff.delay_ms({:exponential, 100, 10_000}, 2) == 200
    assert Backoff.delay_ms({:exponential, 100, 10_000}, 3) == 400
    assert Backoff.delay_ms({:exponential, 100, 10_000}, 4) == 800
    # climbs past the cap input but holds at the ceiling
    assert Backoff.delay_ms({:exponential, 100, 1_000}, 5) == 1_000
    assert Backoff.delay_ms({:exponential, 100, 1_000}, 50) == 1_000
  end

  test "jitter wraps an inner policy in 0..inner_delay inclusive" do
    inner = {:fixed, 1_000}

    samples = for _ <- 1..2_000, do: Backoff.delay_ms({:jitter, inner}, 1)

    assert Enum.all?(samples, fn d -> d >= 0 and d <= 1_000 end)
    # the spread is real: not every sample is the same value
    assert length(Enum.uniq(samples)) > 1
    # both ends are reachable across enough draws
    assert Enum.min(samples) < 100
    assert Enum.max(samples) > 900
  end

  test "jitter over a zero inner delay is zero" do
    assert Backoff.delay_ms({:jitter, {:fixed, 0}}, 1) == 0
  end

  test "jitter composes over exponential" do
    samples = for _ <- 1..1_000, do: Backoff.delay_ms({:jitter, {:exponential, 100, 10_000}}, 3)
    # attempt 3 bound is 400
    assert Enum.all?(samples, fn d -> d >= 0 and d <= 400 end)
  end
end
