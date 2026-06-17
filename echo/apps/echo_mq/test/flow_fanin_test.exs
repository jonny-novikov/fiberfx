defmodule EchoMQ.FlowFaninTest do
  @moduledoc """
  EMQ.3.1-D3 -- the fan-in hook folded into `EchoMQ.Jobs.@complete`: a flow
  child's completion decrements the parent's `:dependencies` count, records the
  child in the parent's `:processed` subkey, and -- at zero -- releases the
  parent to `pending` (`state = pending`, claimable). The parent is held
  (`:empty` to a claim) until the LAST child completes (INV4).

  The decrement is idempotent (INV5): it sits inside the `was_active == 1`
  branch the shipped `@complete` already computes, so it fires exactly once per
  the child's own active->done transition -- a double-complete of an
  already-completed child is refused `:gone` (its row was retired, so
  `@complete` returns before the fan-in branch) and decrements nothing. The
  emq.3.1 HONEST BOUND (a dead child did NOT decrement -- the parent hung
  `awaiting_children`) was the gap emq.3.4 CLOSED: with the failure policy
  (emq.3.4-INV5), a dead child now FAILS the parent by default (parent ->
  `dead`, the child in :failed) or, with `ignore_dependency_on_failure`,
  satisfies-and-records so the parent proceeds -- asserted here in its updated
  form, the hang no longer a reachable behavior.

  This is the mint/process-touching flow suite -- it mints N+1 ids per flow and
  fans in across completions -- so it runs under the >=100-iteration
  determinism loop owning the machine (one green run is NOT proof). Per-test
  sub-queues; Valkey 6390 the truth row. EMQ.3.1-US3 / EMQ.3.1-AS2.
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
    q = "emq31.ffan#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  describe "the fan-in release -- the parent runs exactly once all children complete" do
    test "the parent is held until the last child, then claimable", %{conn: conn, q: q} do
      {parent, _children} = add_flow(conn, q, 2)

      # before any child completes: parent held, count 2
      assert {:ok, "2"} == deps(conn, q, parent)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, q, parent)

      # complete the first child -> count 1, parent still held
      complete_one(conn, q)
      assert {:ok, "1"} == deps(conn, q, parent)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, q, parent)

      assert {:ok, nil} ==
               Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "pending"), parent])

      # complete the second (last) child -> count 0, parent released to pending
      complete_one(conn, q)
      assert {:ok, "0"} == deps(conn, q, parent)
      assert {:ok, :pending} == Metrics.get_job_state(conn, q, parent)

      # the parent now claims (token 1) -- it became an ordinary claimable job
      assert {:ok, {^parent, "P", 1}} = Jobs.claim(conn, q, 60_000)
    end

    test "the :processed subkey records each completed child", %{conn: conn, q: q} do
      {parent, [_c1, _c2]} = add_flow(conn, q, 2)

      first = complete_one(conn, q)
      second = complete_one(conn, q)

      assert {:ok, processed} = Connector.command(conn, ["HKEYS", processed_key(q, parent)])
      assert Enum.sort(processed) == Enum.sort([first, second])
    end

    test "a three-child flow releases the parent only at the third completion", %{
      conn: conn,
      q: q
    } do
      {parent, _children} = add_flow(conn, q, 3)

      complete_one(conn, q)
      assert {:ok, "2"} == deps(conn, q, parent)
      complete_one(conn, q)
      assert {:ok, "1"} == deps(conn, q, parent)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, q, parent)
      complete_one(conn, q)
      assert {:ok, "0"} == deps(conn, q, parent)
      assert {:ok, :pending} == Metrics.get_job_state(conn, q, parent)
    end
  end

  describe "the idempotent decrement (INV5) -- exactly-once fan-in per child" do
    test "a double-complete of a child decrements the parent's count by exactly 1", %{
      conn: conn,
      q: q
    } do
      {parent, _children} = add_flow(conn, q, 2)

      # claim + complete the first child -> the row is retired (DEL), count 1
      {:ok, {first, _, tok}} = Jobs.claim(conn, q, 60_000)
      assert :ok == Jobs.complete(conn, q, first, tok)
      assert {:ok, "1"} == deps(conn, q, parent)

      # a second completion of the SAME child is refused -- the row is gone, so
      # @complete returns BEFORE the fan-in branch and decrements nothing,
      # whether the token is stale or the original (the row no longer exists).
      assert {:error, :gone} == Jobs.complete(conn, q, first, tok + 999)
      assert {:ok, "1"} == deps(conn, q, parent)
      assert {:error, :gone} == Jobs.complete(conn, q, first, tok)
      assert {:ok, "1"} == deps(conn, q, parent)
    end

    test "the was_active==1 gate skips the decrement when the active entry is gone", %{
      conn: conn,
      q: q
    } do
      # The SECOND idempotency layer (the row-gone path above is the first): a
      # completion whose token still matches the row but whose active entry was
      # already removed (a reaped/redelivered lease) finds was_active == 0, so
      # the fan-in DECR is gated OUT -- the child has not transitioned
      # active->done through THIS completion, and the parent must NOT decrement.
      # Constructed the unknown_state way: claim (active holds it), then ZREM
      # active WITHOUT a transition, leaving the row + the live token intact.
      {parent, _children} = add_flow(conn, q, 2)
      {:ok, {first, _, tok}} = Jobs.claim(conn, q, 60_000)
      {:ok, 1} = Connector.command(conn, ["ZREM", Keyspace.queue_key(q, "active"), first])

      # the row + token still match (so it is NOT a :gone/:stale refusal); the
      # completion returns :ok, retires the row -- but the parent count holds at
      # 2 (the DECR was gated on was_active == 1, which is now 0).
      assert :ok == Jobs.complete(conn, q, first, tok)
      assert {:ok, "2"} == deps(conn, q, parent)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, q, parent)
    end
  end

  describe "the failure half (emq.3.4-INV5) -- a dead child fails the parent by default" do
    test "a child that exhausts retries to dead FAILS the parent (the default fail_parent policy)", %{
      conn: conn,
      q: q
    } do
      # emq.3.1's honest bound was that a dead child did NOT decrement and the
      # parent HUNG (awaiting_children) -- the gap emq.3.4 closes. With the
      # default fail_parent_on_failure policy (add_flow passes no flag), a child
      # dead-lettering now FAILS the parent: the parent moves to `dead` with the
      # child recorded in :failed (atomic, same-queue -- emq.3.4-INV5). The hang
      # is no longer a reachable behavior (a child is fail-parent OR ignore-dep).
      {parent, _children} = add_flow(conn, q, 2)

      # take one child to dead by exhausting its retries (max_attempts 1 dead-letters)
      {:ok, {dead, _, tok}} = Jobs.claim(conn, q, 60_000)
      assert {:ok, :dead} == Jobs.retry(conn, q, dead, tok, 0, 1, "boom")

      assert {:ok, "dead"} ==
               Connector.command(conn, ["HGET", Keyspace.job_key(q, dead), "state"])

      # the parent is now DEAD (failed by the dead child, the default policy),
      # with the dead child recorded in the parent's :failed subkey -> its error
      assert {:ok, :dead} == Metrics.get_job_state(conn, q, parent)

      assert {:ok, "boom"} ==
               Connector.command(conn, ["HGET", Keyspace.job_key(q, parent) <> ":failed", dead])
    end
  end

  # -- helpers --------------------------------------------------------------

  # Add a flow of a parent + n same-queue children; return {parent_id, child_ids}.
  defp add_flow(conn, q, n) do
    parent = BrandedId.generate!("JOB")
    children = for i <- 1..n, do: %{id: BrandedId.generate!("JOB"), payload: "c#{i}"}
    child_ids = Enum.map(children, & &1.id)

    {:ok, {^parent, ^child_ids}} =
      Flows.add(conn, q, %{parent: %{id: parent, payload: "P"}, children: children})

    {parent, child_ids}
  end

  # Claim the next pending child and complete it; return the completed id. The
  # parent is never claimed here (it is withheld until fan-in releases it).
  defp complete_one(conn, q) do
    {:ok, {id, _, tok}} = Jobs.claim(conn, q, 60_000)
    :ok = Jobs.complete(conn, q, id, tok)
    id
  end

  defp deps(conn, q, parent),
    do: Connector.command(conn, ["GET", Keyspace.job_key(q, parent) <> ":dependencies"])

  defp processed_key(q, parent), do: Keyspace.job_key(q, parent) <> ":processed"

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end
end
