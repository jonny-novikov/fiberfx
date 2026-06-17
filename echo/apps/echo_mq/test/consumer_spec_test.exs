defmodule EchoMQ.ConsumerSpecTest do
  @moduledoc """
  The pure column of the Consumer row (echo2-migration.md §5): the
  `child_spec/1` map fields — a permanent child whose start is the loop's
  own `start_link/1` (the consumer is a spawn_link loop, not a GenServer).
  """
  use ExUnit.Case, async: true

  alias EchoMQ.Consumer

  test "child_spec/1 is a permanent child carrying the loop's start" do
    handler = fn _job -> :ok end
    opts = [queue: "q", handler: handler]

    spec = Consumer.child_spec(opts)

    assert spec.id == EchoMQ.Consumer
    assert spec.start == {EchoMQ.Consumer, :start_link, [opts]}
    assert spec.restart == :permanent
    assert spec.shutdown == 5_000
  end

  test "child_spec/1 honors a caller-supplied :id" do
    spec = Consumer.child_spec(id: :consumer_a, queue: "q", handler: fn _ -> :ok end)
    assert spec.id == :consumer_a
  end
end
