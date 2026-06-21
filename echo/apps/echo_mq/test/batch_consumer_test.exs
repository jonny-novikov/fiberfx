defmodule EchoMQ.BatchConsumerTest do
  @moduledoc """
  The wire column of the BatchConsumer row (emq.5.2), end to end against
  Valkey on 6390: the self-pacing batch cadence over the byte-frozen
  `claim_batch/4` (`@bclaim`). The size-floor flush drains a batch of
  >= min_size; the latency-ceiling flush (against an INJECTED clock -- no
  real-time flake) drains the partial; partial-failure isolation through the
  cadence retries one poison member (and a fail-safe-retries an absent one)
  while the rest complete, each member emitting its own lifecycle event; and
  `stop/2` drains and answers after the DOWN. The batch drains the FLAT
  `emq:{q}:pending` set, so jobs ride `Jobs.enqueue/4` (NOT `Lanes.enqueue/5`,
  the grouped ring -- the grouped batch is emq.5.3).
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{BatchConsumer, Connector, Events, Jobs, Keyspace}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq0.batchcons#{System.unique_integer([:positive])}"

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

  defp enqueue_flat(conn, q, n, payload) do
    for _ <- 1..n do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, payload)
      id
    end
  end

  defp hget(conn, q, id, field) do
    Connector.command(conn, ["HGET", Keyspace.job_key(q, id), field])
  end

  describe "the size-floor flush (INV-Floor+Ceiling the floor / INV-ClaimPath)" do
    test "a flood >= min_size drains ONE batch of >= min_size, settled per-member", %{conn: conn, q: q} do
      parent = self()
      min_size = 3
      ids = enqueue_flat(conn, q, 5, "floor")

      handler = fn members ->
        send(parent, {:batch, members})
        # all-good per-member verdict map
        Map.new(members, fn %{id: id} -> {id, :ok} end)
      end

      {:ok, consumer} =
        BatchConsumer.start_link(
          queue: q,
          batch_handler: handler,
          connector: [port: 6390],
          min_size: min_size,
          timeout: 5_000,
          poll_ms: 20,
          lease_ms: 5_000
        )

      # the batch carried >= min_size members, in mint order
      assert_receive {:batch, members}, 3_000
      assert length(members) >= min_size
      claimed = Enum.map(members, & &1.id)
      assert claimed == Enum.take(ids, length(members))
      assert Enum.all?(members, &(&1.attempts == 1))

      # every served member completed -- its row retired
      wait_until(fn ->
        Enum.all?(claimed, fn id ->
          Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)]) == {:ok, 0}
        end)
      end)

      assert :ok = BatchConsumer.stop(consumer)
    end
  end

  describe "the latency-ceiling flush (INV-Floor+Ceiling the ceiling / INV-PureCore the injected clock)" do
    test "a trickle M < min_size flushes the partial at the ceiling, against an injected clock", %{conn: conn, q: q} do
      parent = self()
      min_size = 10
      timeout = 200
      m = 2
      ids = enqueue_flat(conn, q, m, "ceil")

      # INJECTED clock: the first read (window t0) is 0, every later read jumps
      # past the timeout -- so the first poll sees elapsed >= timeout and the
      # ceiling fires deterministically (no real-time sleep, no flake).
      ctr = :counters.new(1, [:atomics])

      now_fn = fn ->
        n = :counters.get(ctr, 1)
        :counters.add(ctr, 1, 1)
        if n == 0, do: 0, else: timeout * 100
      end

      handler = fn members ->
        send(parent, {:batch, members})
        Map.new(members, fn %{id: id} -> {id, :ok} end)
      end

      {:ok, consumer} =
        BatchConsumer.start_link(
          queue: q,
          batch_handler: handler,
          connector: [port: 6390],
          min_size: min_size,
          timeout: timeout,
          poll_ms: 20,
          lease_ms: 5_000,
          now_fn: now_fn
        )

      # the partial flush carried EXACTLY M members (< min_size) -- the soft floor
      assert_receive {:batch, members}, 3_000
      assert length(members) == m
      assert m < min_size
      claimed = Enum.map(members, & &1.id)
      assert claimed == ids

      wait_until(fn ->
        Enum.all?(claimed, fn id ->
          Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)]) == {:ok, 0}
        end)
      end)

      assert :ok = BatchConsumer.stop(consumer)
    end

    test "an empty window flushes nothing -- no batch handler invocation", %{q: q} do
      parent = self()

      handler = fn members ->
        send(parent, {:batch, members})
        Map.new(members, fn %{id: id} -> {id, :ok} end)
      end

      # min_size 5, but nothing enqueued -- the window watches an empty pending
      # set; even past the ceiling, depth 0 flushes nothing (D2 empty case).
      {:ok, consumer} =
        BatchConsumer.start_link(
          queue: q,
          batch_handler: handler,
          connector: [port: 6390],
          min_size: 5,
          timeout: 50,
          poll_ms: 10,
          lease_ms: 5_000
        )

      # no batch is ever handled on an empty queue
      refute_receive {:batch, _}, 300

      assert :ok = BatchConsumer.stop(consumer)
    end
  end

  describe "partial-failure isolation through the cadence (INV-PartialFailure / INV-Events)" do
    test "one poison retries, an absent member fail-safe-retries, the rest complete -- per-member events", %{conn: conn, q: q} do
      parent = self()
      ids = enqueue_flat(conn, q, 3, "spf")
      [oldest | _] = ids

      # a per-member verdict map: fail the OLDEST (poison), complete the
      # SECOND, and OMIT the THIRD entirely (the fail-safe proof -- an absent
      # member must retry "missing verdict", never silently complete).
      handler = fn members ->
        send(parent, {:batch, Enum.map(members, & &1.id)})
        by_age = Enum.sort_by(members, & &1.id)
        [poison, good, _omitted] = by_age
        %{poison.id => {:error, "poison"}, good.id => :ok}
      end

      # subscribe to the per-member lifecycle events (D3)
      {:ok, events} =
        Events.start_link(queue: q, connector: [port: 6390])

      :ok = Events.subscribe(events, self())

      {:ok, consumer} =
        BatchConsumer.start_link(
          queue: q,
          batch_handler: handler,
          connector: [port: 6390],
          min_size: 3,
          timeout: 5_000,
          poll_ms: 20,
          lease_ms: 5_000,
          retry_delay_ms: 10,
          max_attempts: 5
        )

      assert_receive {:batch, claimed}, 3_000
      assert Enum.sort(claimed) == Enum.sort(ids)

      [poison_id, good_id, miss_id] = Enum.sort(ids)

      # the poison retried with its own reason kept
      wait_until(fn -> hget(conn, q, poison_id, "state") == {:ok, "scheduled"} end)
      assert hget(conn, q, poison_id, "last_error") == {:ok, "poison"}

      # the good member completed -- its row retired
      wait_until(fn ->
        Connector.command(conn, ["EXISTS", Keyspace.job_key(q, good_id)]) == {:ok, 0}
      end)

      # the OMITTED member fail-safe-retried (NOT silently completed)
      wait_until(fn -> hget(conn, q, miss_id, "state") == {:ok, "scheduled"} end)
      assert hget(conn, q, miss_id, "last_error") == {:ok, "missing verdict"}

      # the events plane saw per-member transitions: a completed and at least
      # one failed (D3 -- per-member, not a batch-level event)
      assert_receive {:emq_event, :completed, _payload}, 2_000
      assert_receive {:emq_event, :failed, _payload}, 2_000

      assert :ok = BatchConsumer.stop(consumer)
      :ok = Events.close(events)
    end
  end

  describe "lifecycle" do
    test "stop/2 drains and answers after the loop is down", %{q: q} do
      {:ok, consumer} =
        BatchConsumer.start_link(
          queue: q,
          batch_handler: fn members -> Map.new(members, fn %{id: id} -> {id, :ok} end) end,
          connector: [port: 6390],
          min_size: 1,
          timeout: 1_000,
          poll_ms: 20
        )

      ref = Process.monitor(consumer)

      assert :ok = BatchConsumer.stop(consumer)
      assert_receive {:DOWN, ^ref, :process, ^consumer, :normal}, 500
      refute Process.alive?(consumer)
    end

    test "a non-positive knob raises at start", %{q: q} do
      assert_raise ArgumentError, fn ->
        BatchConsumer.start_link(
          queue: q,
          batch_handler: fn _ -> %{} end,
          connector: [port: 6390],
          min_size: 0,
          timeout: 1_000
        )
      end

      assert_raise ArgumentError, fn ->
        BatchConsumer.start_link(
          queue: q,
          batch_handler: fn _ -> %{} end,
          connector: [port: 6390],
          min_size: 1,
          timeout: -5
        )
      end
    end
  end
end
