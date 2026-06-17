defmodule EchoMQ.RateConsultTest do
  @moduledoc """
  EMQ.2.4-D2 -- the rate-gate residue, the RULED Arm 2 (Operator, 2026-06-14,
  ledger D-3): the over-ceiling-claim behavior is the **consult-before-claim**
  contract, not a transition edit. `EchoMQ.Metrics.is_maxed/2` is the pure-read
  a claimer consults BEFORE `EchoMQ.Jobs.claim/3` (or `EchoMQ.Lanes.claim/3`);
  at or above the `meta.concurrency` ceiling it returns `{:error, :rate}` and
  the claimer SKIPS the claim, so the active set stays at the ceiling; below it
  returns `:ok` and the claim proceeds. This matches the v1 parity (v1
  `isMaxed-2` is a PRE-claim read the worker calls, NOT a step inside
  `moveToActive-11`), and keeps the shipped `@claim`/`@gclaim` scripts BYTE-
  UNCHANGED (the named HIGH-RISK edit foreclosed -- INV3).

  `is_maxed/2`'s as-built return shape is `:ok | {:error, :rate}` (NOT a
  boolean) -- the `EMQRATE` wire refusal mapped (metrics.ex). This suite drives
  the consult-then-skip discipline end to end; the pure-read primitive is
  unchanged (proven byte-equal by `git diff`, asserted behaviorally here).

  Read-only over the rate gate plus the standard claim transition; per-test
  sub-queues with the baseline purge idiom; Valkey on 6390 the truth row.
  EMQ.2.4-AS2 / EMQ.2.4-US2.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Jobs, Keyspace, Lanes, Metrics}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq24.rconsult#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  describe "the consult-before-claim contract (Arm 2)" do
    test "below the ceiling, is_maxed/2 answers :ok and the claim proceeds", %{conn: conn, q: q} do
      {:ok, _} = Connector.command(conn, ["HSET", Keyspace.queue_key(q, "meta"), "concurrency", "2"])
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")

      # one active job, ceiling 2 -> below the ceiling -> consult answers :ok
      assert :ok = Metrics.is_maxed(conn, q)
      # the claimer proceeds: it is allowed to claim
      assert {:ok, {^id, "w", 1}} = Jobs.claim(conn, q, 60_000)
      assert {:ok, %{"active" => 1}} = Metrics.get_counts(conn, q, ["active"])
    end

    test "at the ceiling, the consult refuses {:error, :rate} and a skipping claimer leaves active at the ceiling",
         %{conn: conn, q: q} do
      {:ok, _} = Connector.command(conn, ["HSET", Keyspace.queue_key(q, "meta"), "concurrency", "1"])

      # drive one job to active -> the gate is now at the ceiling
      held = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, held, "held")
      {:ok, {^held, _, 1}} = Jobs.claim(conn, q, 60_000)

      # a second job waits in pending
      waiting = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, waiting, "wait")

      # the claimer consults FIRST: at the ceiling it must skip the claim
      claimed =
        case Metrics.is_maxed(conn, q) do
          {:error, :rate} -> :skipped
          :ok -> Jobs.claim(conn, q, 60_000)
        end

      assert claimed == :skipped
      # the active set stayed at the ceiling; the waiting job is untouched in pending
      assert {:ok, %{"active" => 1, "pending" => 1}} =
               Metrics.get_counts(conn, q, ["active", "pending"])
      assert {:ok, :pending} = Metrics.get_job_state(conn, q, waiting)
    end

    test "the gate reopens on complete: after the held job retires, the consult answers :ok again",
         %{conn: conn, q: q} do
      {:ok, _} = Connector.command(conn, ["HSET", Keyspace.queue_key(q, "meta"), "concurrency", "1"])

      held = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, held, "held")
      {:ok, {^held, _, 1}} = Jobs.claim(conn, q, 60_000)

      waiting = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, waiting, "wait")

      assert {:error, :rate} = Metrics.is_maxed(conn, q)
      :ok = Jobs.complete(conn, q, held, 1)

      # the ceiling reopened -> the consult answers :ok -> the waiting job claims
      assert :ok = Metrics.is_maxed(conn, q)
      assert {:ok, {^waiting, "wait", 1}} = Jobs.claim(conn, q, 60_000)
    end

    test "the contract also gates a grouped claim: a skipping claimer leaves the lane backlog intact",
         %{conn: conn, q: q} do
      {:ok, _} = Connector.command(conn, ["HSET", Keyspace.queue_key(q, "meta"), "concurrency", "1"])

      g = BrandedId.generate!("PRT")
      j1 = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Lanes.enqueue(conn, q, g, j1, "g")
      # claim one into active via the grouped path -> the gate is at the ceiling
      {:ok, {^j1, _, 1, ^g}} = Lanes.claim(conn, q, 60_000)

      j2 = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Lanes.enqueue(conn, q, g, j2, "g")

      # the consult is queue-wide (the active set is shared); at the ceiling the
      # grouped claimer skips, so the lane keeps its backlog
      claimed =
        case Metrics.is_maxed(conn, q) do
          {:error, :rate} -> :skipped
          :ok -> Lanes.claim(conn, q, 60_000)
        end

      assert claimed == :skipped
      assert {:ok, 1} = Lanes.depth(conn, q, g)
      assert {:ok, %{"active" => 1}} = Metrics.get_counts(conn, q, ["active"])
    end

    test "an unconfigured concurrency never refuses (no ceiling)", %{conn: conn, q: q} do
      # no meta.concurrency -> is_maxed answers :ok even with an active job
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
      assert :ok = Metrics.is_maxed(conn, q)
    end
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end
end
