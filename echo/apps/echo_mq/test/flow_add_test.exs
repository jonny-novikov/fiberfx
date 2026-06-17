defmodule EchoMQ.FlowAddTest do
  @moduledoc """
  EMQ.3.1-D2 -- the single-queue flow ADD: `EchoMQ.Flows.add/3` + the inline
  `@enqueue_flow`. A parent + a flat list of same-queue children lands in one
  atomic transition on one slot: every node minted a distinct branded JOB id
  and gated at `Keyspace.job_key/2`, the children claimable immediately (in
  `pending`), the parent held out of `pending` with its outstanding-child count
  in `:dependencies` and its row `state = awaiting_children`.

  The kind law (`EMQKIND`) is the script's first act over the parent and every
  child; a child spec naming a different queue is rejected host-side
  (`{:error, :cross_queue}` -- the cross-queue flow is emq.3.3, INV8); an
  ill-formed id raises at the gate before any wire (INV6). Per-test sub-queues;
  Valkey 6390 the truth row. EMQ.3.1-US2 / EMQ.3.1-AS1.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Flows, Jobs, Keyspace, Metrics}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq31.fadd#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  describe "Flows.add/3 -- the atomic single-queue add" do
    test "mints N+1 distinct branded JOB ids, lands them on one slot", %{conn: conn, q: q} do
      parent = BrandedId.generate!("JOB")
      c1 = BrandedId.generate!("JOB")
      c2 = BrandedId.generate!("JOB")

      assert 3 == length(Enum.uniq([parent, c1, c2]))

      assert {:ok, {^parent, [^c1, ^c2]}} =
               Flows.add(conn, q, %{
                 parent: %{id: parent, payload: "P"},
                 children: [%{id: c1, payload: "c1"}, %{id: c2, payload: "c2"}]
               })

      # every flow key shares the one {q} slot (single-queue -> atomic)
      slot = Keyspace.slot(Keyspace.job_key(q, parent))
      assert slot == Keyspace.slot(Keyspace.job_key(q, c1))
      assert slot == Keyspace.slot(Keyspace.queue_key(q, "pending"))
    end

    test "the children are claimable; the parent is withheld from pending", %{conn: conn, q: q} do
      parent = BrandedId.generate!("JOB")
      c1 = BrandedId.generate!("JOB")
      c2 = BrandedId.generate!("JOB")

      {:ok, {^parent, [^c1, ^c2]}} =
        Flows.add(conn, q, %{
          parent: %{id: parent, payload: "P"},
          children: [%{id: c1, payload: "c1"}, %{id: c2, payload: "c2"}]
        })

      # the two children claim (token 1 each); a third claim is empty (the
      # parent is NOT a pending member)
      assert {:ok, {first, _, 1}} = Jobs.claim(conn, q, 60_000)
      assert first in [c1, c2]
      assert {:ok, {second, _, 1}} = Jobs.claim(conn, q, 60_000)
      assert second in [c1, c2] and second != first
      assert :empty == Jobs.claim(conn, q, 60_000)

      assert {:ok, nil} ==
               Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "pending"), parent])
    end

    test "the parent row is awaiting_children with :dependencies = N", %{conn: conn, q: q} do
      parent = BrandedId.generate!("JOB")
      c1 = BrandedId.generate!("JOB")
      c2 = BrandedId.generate!("JOB")

      {:ok, _} =
        Flows.add(conn, q, %{
          parent: %{id: parent, payload: "P"},
          children: [%{id: c1, payload: "c1"}, %{id: c2, payload: "c2"}]
        })

      assert {:ok, %{"state" => "awaiting_children", "payload" => "P"}} =
               Metrics.get_job(conn, q, parent)

      assert {:ok, "2"} ==
               Connector.command(conn, ["GET", Keyspace.job_key(q, parent) <> ":dependencies"])

      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, q, parent)
    end

    test "each child row carries its parent field (the host-side fan-in seam)", %{
      conn: conn,
      q: q
    } do
      parent = BrandedId.generate!("JOB")
      c1 = BrandedId.generate!("JOB")

      {:ok, _} =
        Flows.add(conn, q, %{
          parent: %{id: parent, payload: "P"},
          children: [%{id: c1, payload: "c1"}]
        })

      assert {:ok, ^parent} =
               Connector.command(conn, ["HGET", Keyspace.job_key(q, c1), "parent"])
    end

    test "a single-child flow lands (the degenerate one-level case)", %{conn: conn, q: q} do
      parent = BrandedId.generate!("JOB")
      c1 = BrandedId.generate!("JOB")

      assert {:ok, {^parent, [^c1]}} =
               Flows.add(conn, q, %{
                 parent: %{id: parent, payload: "P"},
                 children: [%{id: c1, payload: "c1"}]
               })

      assert {:ok, "1"} ==
               Connector.command(conn, ["GET", Keyspace.job_key(q, parent) <> ":dependencies"])
    end
  end

  describe "Flows.add/3 -- the cross-queue admit (emq.3.3 replaced the emq.3.1 refusal)" do
    test "a cross-queue child is now ADMITTED on its own slot (the refusal is gone)", %{
      conn: conn,
      q: q
    } do
      # emq.3.1 REJECTED a cross-queue child {:error, :cross_queue}; emq.3.3
      # replaced reject_cross_queue/2 with the admit path. The parent lands
      # held on q; the cross-queue child lands claimable on its OWN queue. The
      # full cross-queue mechanism is exercised in flow_cross_queue_test.exs.
      parent = BrandedId.generate!("JOB")
      c1 = BrandedId.generate!("JOB")
      cq = q <> ".other"

      assert {:ok, {^parent, [^c1]}} =
               Flows.add(conn, q, %{
                 parent: %{id: parent, payload: "P"},
                 children: [%{id: c1, payload: "c1", queue: cq}]
               })

      # the parent is held on q; the child is claimable on its own queue cq,
      # NOT on q (the cross-queue add lands the child cross-slot)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, q, parent)
      assert :empty == Jobs.claim(conn, q, 60_000)
      assert {:ok, {^c1, "c1", 1}} = Jobs.claim(conn, cq, 60_000)

      # tidy the cross-queue child slot (a different hashtag than q)
      {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> cq <> "}:*"])
      if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    end

    test "a non-JOB parent id refuses EMQKIND before any write", %{conn: conn, q: q} do
      # an ORD id is a valid branded id (passes the gate) but the wrong kind
      parent = BrandedId.generate!("ORD")
      c1 = BrandedId.generate!("JOB")

      assert {:error, :kind} =
               Flows.add(conn, q, %{
                 parent: %{id: parent, payload: "P"},
                 children: [%{id: c1, payload: "c1"}]
               })

      assert {:ok, 0} == Connector.command(conn, ["EXISTS", Keyspace.job_key(q, parent)])
      assert {:ok, 0} == Connector.command(conn, ["EXISTS", Keyspace.job_key(q, c1)])
    end

    test "a non-JOB child id refuses EMQKIND, the parent unwritten too (atomic)", %{
      conn: conn,
      q: q
    } do
      parent = BrandedId.generate!("JOB")
      bad_child = BrandedId.generate!("ORD")

      assert {:error, :kind} =
               Flows.add(conn, q, %{
                 parent: %{id: parent, payload: "P"},
                 children: [%{id: bad_child, payload: "c"}]
               })

      # the kind law runs before any HSET -> the parent never landed (atomic refusal)
      assert {:ok, 0} == Connector.command(conn, ["EXISTS", Keyspace.job_key(q, parent)])
    end

    test "an ill-formed id raises at the gate (Keyspace.job_key/2), before any wire", %{
      conn: conn,
      q: q
    } do
      parent = BrandedId.generate!("JOB")

      assert_raise ArgumentError, fn ->
        Flows.add(conn, q, %{
          parent: %{id: parent, payload: "P"},
          children: [%{id: "not-a-branded-id", payload: "c"}]
        })
      end

      assert {:ok, 0} == Connector.command(conn, ["EXISTS", Keyspace.job_key(q, parent)])
    end
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end
end
