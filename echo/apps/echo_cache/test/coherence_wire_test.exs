defmodule EchoCache.CoherenceWireTest do
  @moduledoc """
  The wire column of the Coherence row (echo2-migration.md §5):
  `drop_l2/4` newer-deletes / stale-keeps / short-frame-deletes,
  `broadcast/4` answering the receiver count, and `enqueue/5` riding
  EchoMQ's fair lanes — per-test tables and sub-queues, purged after.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoCache.{Coherence, Keyspace}
  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Lanes}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    table = "emq0coh#{System.unique_integer([:positive])}"

    # the conn dies with the test process (the OTP parent-exit protocol),
    # so the purge rides its own disposable connection
    on_exit(fn ->
      purge(["ecc:{" <> table <> "}:*", "emq:{" <> Coherence.queue(table) <> "}:*"])
    end)

    %{conn: conn, table: table}
  end

  defp purge(patterns) do
    {:ok, conn} = Connector.start_link(port: 6390)

    for pattern <- patterns do
      {:ok, keys} = Connector.command(conn, ["KEYS", pattern])
      if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    end

    GenServer.stop(conn)
  end

  defp mint_pair do
    older = BrandedId.generate!("TXN")
    Process.sleep(2)
    newer = BrandedId.generate!("TXN")
    {older, newer}
  end

  test "drop_l2/4 deletes only when the version is newer than the framed one", %{
    conn: conn,
    table: table
  } do
    id = BrandedId.generate!("AST")
    {older, newer} = mint_pair()
    key = Keyspace.key(table, id)

    # newer wins: the stored frame carries the older version
    {:ok, "OK"} = Connector.command(conn, ["SET", key, older <> "value"])
    assert {:ok, 1} = Coherence.drop_l2(conn, table, id, newer)
    assert {:ok, 0} = Connector.command(conn, ["EXISTS", key])

    # stale keeps: the stored frame carries the newer version
    {:ok, "OK"} = Connector.command(conn, ["SET", key, newer <> "value"])
    assert {:ok, 0} = Coherence.drop_l2(conn, table, id, older)
    assert {:ok, 1} = Connector.command(conn, ["EXISTS", key])
  end

  test "drop_l2/4 deletes a short frame and ignores a missing row", %{conn: conn, table: table} do
    id = BrandedId.generate!("AST")
    version = BrandedId.generate!("TXN")
    key = Keyspace.key(table, id)

    {:ok, "OK"} = Connector.command(conn, ["SET", key, "tiny"])
    assert {:ok, 1} = Coherence.drop_l2(conn, table, id, version)
    assert {:ok, 0} = Connector.command(conn, ["EXISTS", key])

    assert {:ok, 0} = Coherence.drop_l2(conn, table, id, version)
  end

  test "broadcast/4 answers the receiver count", %{conn: conn, table: table} do
    id = BrandedId.generate!("AST")
    version = BrandedId.generate!("TXN")

    assert {:ok, 0} = Coherence.broadcast(conn, table, id, version)

    {:ok, sub} = Connector.start_link(port: 6390, protocol: 3, push_to: self())
    on_exit(fn ->
      try do
        GenServer.stop(sub)
      catch
        :exit, _ -> :ok
      end
    end)

    :ok = Connector.subscribe(sub, Coherence.channel(table))

    assert {:ok, 1} = Coherence.broadcast(conn, table, id, version)

    expected_channel = Coherence.channel(table)
    expected_payload = Coherence.payload(id, version)
    assert_receive {:emq_push, ["message", ^expected_channel, ^expected_payload]}, 1_000
  end

  test "enqueue/5 rides the fair lanes with the payload framed", %{conn: conn, table: table} do
    group = BrandedId.generate!("PRT")
    id = BrandedId.generate!("AST")
    version = BrandedId.generate!("TXN")
    queue = Coherence.queue(table)

    assert {:ok, :enqueued} = Coherence.enqueue(conn, table, group, id, version)

    expected_payload = Coherence.payload(id, version)
    assert {:ok, {job_id, ^expected_payload, 1, ^group}} = Lanes.claim(conn, queue, 60_000)
    assert binary_part(job_id, 0, 3) == "JOB"
  end
end
