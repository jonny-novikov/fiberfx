defmodule EchoMQ.KeyspaceTest do
  use ExUnit.Case, async: true
  alias EchoMQ.Keyspace

  test "queue keys share one hash tag per queue" do
    pending = Keyspace.queue_key("q1", "pending")
    active = Keyspace.queue_key("q1", "active")
    [tag] = Regex.run(~r/\{[^}]+\}/, pending) |> Enum.take(1)
    assert String.contains?(active, tag)
  end
end
