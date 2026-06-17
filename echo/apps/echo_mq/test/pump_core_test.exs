defmodule EchoMQ.Pump.CoreTest do
  @moduledoc """
  The pump's pure decision core (EMQ.1-D5): the tick interval and the
  per-tick batch as plain functions of the start options, no process, no
  clock. The cadence-and-sweep behavior is the `pump_test.exs` `:valkey`
  suite; this pins the arithmetic.
  """
  use ExUnit.Case, async: true

  alias EchoMQ.Pump.Core

  doctest EchoMQ.Pump.Core

  test "tick_ms defaults to the one-second beat and honors the option" do
    assert Core.tick_ms([]) == 1_000
    assert Core.tick_ms(tick_ms: 250) == 250
  end

  test "tick_ms refuses a non-positive beat" do
    assert_raise ArgumentError, fn -> Core.tick_ms(tick_ms: 0) end
    assert_raise ArgumentError, fn -> Core.tick_ms(tick_ms: -5) end
  end

  test "batch defaults to 100 and honors the option" do
    assert Core.batch([]) == 100
    assert Core.batch(batch: 10) == 10
  end

  test "batch refuses a non-positive size" do
    assert_raise ArgumentError, fn -> Core.batch(batch: 0) end
    assert_raise ArgumentError, fn -> Core.batch(batch: -1) end
  end
end
