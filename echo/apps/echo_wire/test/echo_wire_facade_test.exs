defmodule EchoWireFacadeTest do
  @moduledoc """
  The EchoWire extension row (the agent brief, Stage-1c; extended Chapter
  3.7): the facade is a pure delegation module — the ten connector verbs are
  exported at their delegated arities (the Chapter 3.7 addition is
  `unsubscribe/2`, the companion to `subscribe/2`), and `script/2` returns
  the same `%EchoMQ.Script{}` as `EchoMQ.Script.new/2`. The wire-bound proof
  (one command and one pipeline through the facade) lives in the
  `:valkey`-tagged live suite.
  """
  use ExUnit.Case, async: true

  test "the delegated connector surface is exported" do
    assert {:module, EchoWire} = Code.ensure_loaded(EchoWire)

    for {fun, arity} <- [
          command: 3,
          pipeline: 3,
          noreply_pipeline: 3,
          transaction_pipeline: 3,
          eval: 5,
          push_command: 3,
          subscribe: 2,
          unsubscribe: 2,
          stats: 1,
          start_link: 1
        ] do
      assert function_exported?(EchoWire, fun, arity),
             "expected EchoWire.#{fun}/#{arity} to be exported"
    end
  end

  test "script/2 returns the same struct as EchoMQ.Script.new/2" do
    source = "return redis.call('EXISTS', KEYS[1])"

    assert EchoWire.script(:fence_probe, source) == EchoMQ.Script.new(:fence_probe, source)
    assert %EchoMQ.Script{} = EchoWire.script(:fence_probe, source)
  end
end
