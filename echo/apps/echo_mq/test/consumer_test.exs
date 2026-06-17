defmodule EchoMQ.ConsumerTest do
  @moduledoc """
  The wire column of the Consumer row (echo2-migration.md §5), end to end:
  a handler's `:ok` completes the job; a raising handler converts to a
  typed retry and the loop survives to settle attempt two; `stop/2`
  drains and answers after the DOWN. The consumer drains the ring with
  rotating claims, so jobs ride `Lanes.enqueue/5`.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Consumer, Keyspace, Lanes}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq0.consumer#{System.unique_integer([:positive])}"

    # the conn dies with the test process (the OTP parent-exit protocol),
    # so the purge rides its own disposable connection
    on_exit(fn -> purge(q) end)

    %{conn: conn, q: q}
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  defp wait_until(pred, tries \\ 400) do
    cond do
      pred.() -> :ok
      tries == 0 -> flunk("condition never held")
      true ->
        Process.sleep(5)
        wait_until(pred, tries - 1)
    end
  end

  test "a handler answering :ok completes the job", %{conn: conn, q: q} do
    parent = self()
    group = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")

    {:ok, :enqueued} = Lanes.enqueue(conn, q, group, id, "cargo")

    handler = fn job ->
      send(parent, {:handled, job})
      :ok
    end

    {:ok, consumer} =
      Consumer.start_link(
        queue: q,
        handler: handler,
        connector: [port: 6390],
        beat_ms: 50,
        lease_ms: 5_000
      )

    assert_receive {:handled, %{id: ^id, payload: "cargo", attempts: 1, group: ^group}}, 3_000

    wait_until(fn ->
      {:ok, n} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)])
      n == 0
    end)

    assert :ok = Consumer.stop(consumer)
  end

  test "a raising handler converts to a typed retry and the loop survives", %{conn: conn, q: q} do
    parent = self()
    group = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")

    {:ok, :enqueued} = Lanes.enqueue(conn, q, group, id, "fragile")

    handler = fn job ->
      send(parent, {:attempt, job.attempts, self()})

      if job.attempts == 1 do
        raise "boom"
      else
        :ok
      end
    end

    {:ok, consumer} =
      Consumer.start_link(
        queue: q,
        handler: handler,
        connector: [port: 6390],
        beat_ms: 50,
        lease_ms: 5_000,
        retry_delay_ms: 10,
        max_attempts: 3
      )

    assert_receive {:attempt, 1, loop_pid}, 3_000
    assert_receive {:attempt, 2, ^loop_pid}, 3_000

    # the same loop process survived the raise and settled attempt two
    assert Process.alive?(consumer)

    wait_until(fn ->
      {:ok, n} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)])
      n == 0
    end)

    assert :ok = Consumer.stop(consumer)
  end

  test "stop/2 drains and answers after the loop is down", %{q: q} do
    {:ok, consumer} =
      Consumer.start_link(
        queue: q,
        handler: fn _ -> :ok end,
        connector: [port: 6390],
        beat_ms: 50
      )

    ref = Process.monitor(consumer)

    assert :ok = Consumer.stop(consumer)
    assert_receive {:DOWN, ^ref, :process, ^consumer, :normal}, 100
    refute Process.alive?(consumer)
  end
end
