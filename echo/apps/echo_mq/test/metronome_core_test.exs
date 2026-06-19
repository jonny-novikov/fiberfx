defmodule EchoMQ.Metronome.CoreTest do
  @moduledoc """
  The metronome's pure decision core (emq.4.3): the beat interval and the
  dispatch decision as plain functions of the start options + the registry,
  no process, no clock, no Valkey. The metronome-as-system behavior (the
  single block, the fan-out, the lost-wakeup + fairness proofs) is the
  `metronome_test.exs` `:valkey` + process suite; this pins the arithmetic
  and the dispatch contract. `async: true` is sound -- the core touches no
  process-global state.
  """
  use ExUnit.Case, async: true

  alias EchoMQ.Metronome.Core

  doctest EchoMQ.Metronome.Core

  test "beat_ms defaults to the one-second beat and honors the option" do
    assert Core.beat_ms([]) == 1_000
    assert Core.beat_ms(beat_ms: 250) == 250
  end

  test "beat_ms refuses a non-positive beat" do
    assert_raise ArgumentError, fn -> Core.beat_ms(beat_ms: 0) end
    assert_raise ArgumentError, fn -> Core.beat_ms(beat_ms: -5) end
  end

  test "dispatch authorizes exactly one claim per registered-idle consumer (the D-2 contract)" do
    # the order is preserved (head = idle longest, the fair tie-break) and the
    # set is exact -- one :claim_once per idle consumer per wake, no more, no
    # fewer (a poke-one-to-exhaustive-drain would return fewer than the set).
    assert Core.dispatch([]) == []
    assert Core.dispatch([:a]) == [:a]
    assert Core.dispatch([:a, :b, :c]) == [:a, :b, :c]
  end

  test "repoke? is true only when work was poked AND consumers re-registered" do
    # re-poke promptly when there may be more work AND someone is idle to take
    # it; otherwise re-block (the beat is the fallback).
    assert Core.repoke?(poked: 2, idle: 2) == true
    assert Core.repoke?(poked: 1, idle: 3) == true
    refute Core.repoke?(poked: 0, idle: 3)
    refute Core.repoke?(poked: 2, idle: 0)
    refute Core.repoke?(poked: 0, idle: 0)
  end
end
