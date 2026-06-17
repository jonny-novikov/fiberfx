defmodule EchoMQ.ResubscribeTest do
  @moduledoc """
  Connector auto-resubscribe (EMQ.1-D6): the connector records its
  subscription set and re-issues each SUBSCRIBE in the `:reconnect` success
  arm, so a dropped socket does not silently end a feed. `unsubscribe/2` is
  the companion that keeps the set truthful.

  PLACEMENT: lives in `apps/echo_mq/test/` (not the wire app's own tree)
  because the connector's fence reads `EchoMQ.Keyspace.version_key/0` at
  runtime and keyspace.ex lives in echo_mq -- a per-app echo_wire run loads
  only the dependency-free wire app, so no echo_wire-local test can connect.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoMQ.Connector

  defp client_id(conn) do
    {:ok, id} = Connector.command(conn, ["CLIENT", "ID"])
    Integer.to_string(id)
  end

  defp wait_reconnected(_conn, 0), do: false

  defp wait_reconnected(conn, n) do
    Process.sleep(20)

    case Connector.stats(conn).status do
      :connected -> true
      _ -> wait_reconnected(conn, n - 1)
    end
  end

  test "a subscribed connector answers the channel again after its socket is killed", _ctx do
    chan = "emq1.resub#{System.unique_integer([:positive])}"
    {:ok, pub} = Connector.start_link(port: 6390)

    {:ok, sub} =
      Connector.start_link(port: 6390, protocol: 3, push_to: self(), backoff_initial: 20, backoff_max: 50)

    on_exit(fn ->
      for c <- [pub, sub], do: (try do: GenServer.stop(c), catch: (:exit, _ -> :ok))
    end)

    :ok = Connector.subscribe(sub, chan)
    sub_id = client_id(sub)

    {:ok, 1} = Connector.command(pub, ["PUBLISH", chan, "before"])
    assert_receive {:emq_push, ["message", ^chan, "before"]}, 1_000

    # kill the subscriber's socket from the publisher connection
    {:ok, _} = Connector.command(pub, ["CLIENT", "KILL", "ID", sub_id])
    assert wait_reconnected(sub, 50), "subscriber did not reconnect"

    # the prior subscription answers again with NO caller restart
    {:ok, 1} = Connector.command(pub, ["PUBLISH", chan, "after"])
    assert_receive {:emq_push, ["message", ^chan, "after"]}, 2_000

    # the reconnect was counted
    assert Connector.stats(sub).reconnects >= 1
  end

  test "unsubscribe drops the channel so a reconnect does not re-issue it", _ctx do
    chan = "emq1.resub#{System.unique_integer([:positive])}"
    {:ok, pub} = Connector.start_link(port: 6390)

    {:ok, sub} =
      Connector.start_link(port: 6390, protocol: 3, push_to: self(), backoff_initial: 20, backoff_max: 50)

    on_exit(fn ->
      for c <- [pub, sub], do: (try do: GenServer.stop(c), catch: (:exit, _ -> :ok))
    end)

    :ok = Connector.subscribe(sub, chan)
    assert :ok = Connector.unsubscribe(sub, chan)
    sub_id = client_id(sub)

    # confirm the unsubscribe landed: a publish does not reach push_to
    {:ok, _} = Connector.command(pub, ["PUBLISH", chan, "gone"])
    refute_receive {:emq_push, ["message", ^chan, "gone"]}, 300

    # after a reconnect the dropped channel is NOT re-issued
    {:ok, _} = Connector.command(pub, ["CLIENT", "KILL", "ID", sub_id])
    assert wait_reconnected(sub, 50)

    {:ok, _} = Connector.command(pub, ["PUBLISH", chan, "still-gone"])
    refute_receive {:emq_push, ["message", ^chan, "still-gone"]}, 300
  end

  test "subscribe on a RESP2 connection is refused and records nothing", _ctx do
    {:ok, sub} = Connector.start_link(port: 6390, protocol: 2)
    on_exit(fn -> try do: GenServer.stop(sub), catch: (:exit, _ -> :ok) end)

    assert {:error, :requires_resp3} = Connector.subscribe(sub, "emq1.r2chan")
    assert {:error, :requires_resp3} = Connector.unsubscribe(sub, "emq1.r2chan")
  end

  test "unsubscribe on an unknown channel is harmless", _ctx do
    {:ok, sub} = Connector.start_link(port: 6390, protocol: 3, push_to: self())
    on_exit(fn -> try do: GenServer.stop(sub), catch: (:exit, _ -> :ok) end)

    assert :ok = Connector.unsubscribe(sub, "emq1.never-subscribed")
  end
end
