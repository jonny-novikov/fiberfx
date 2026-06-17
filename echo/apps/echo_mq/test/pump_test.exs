defmodule EchoMQ.PumpTest do
  @moduledoc """
  The promote pump (EMQ.1-D5): a supervised, opt-in cadence process that
  promotes due schedule entries through `Jobs.promote/3` and fires due
  repeatables, minting a fresh branded JOB id per occurrence. A worker
  without the pump is unchanged; a crash restarts the cadence whole. Per-test
  sub-queues.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Jobs, Keyspace, Pump, Repeat}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq1.pump#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  test "one sweep promotes a due scheduled job and fires a due repeatable", %{conn: conn, q: q} do
    sched_id = BrandedId.generate!("JOB")
    {:ok, :scheduled} = Jobs.enqueue_in(conn, q, sched_id, "due", 0)
    {:ok, :registered} = Repeat.register(conn, q, "tick", 10_000, "occ", 0)

    # drive one sweep directly (no cadence)
    assert {:ok, %{promoted: 1, fired: 1}} =
             Pump.sweep(%{conn: conn, queue: q, batch: 100})

    # the scheduled job is now claimable
    assert {:ok, {^sched_id, "due", 1}} = Jobs.claim(conn, q, 60_000)
    # the repeatable produced one fresh occurrence (a different id)
    assert {:ok, {occ_id, "occ", 1}} = Jobs.claim(conn, q, 60_000)
    assert occ_id != sched_id
  end

  test "a sweep over a mixed batch fires the live registration and sweeps a dangling one", %{conn: conn, q: q} do
    # one live registration, one whose record was deleted out of band (its
    # registry member dangles). The soft-matched sweep fires the live one,
    # sweeps the dangling member, and survives -- no crash, the cadence holds.
    {:ok, :registered} = Repeat.register(conn, q, "live", 10_000, "occ", 0)
    {:ok, :registered} = Repeat.register(conn, q, "dangling", 10_000, "x", 0)
    {:ok, _} = Connector.command(conn, ["DEL", Keyspace.queue_key(q, "repeat:") <> "dangling"])

    # the dangling member is still scored due until the sweep removes it
    assert {:ok, %{fired: 1}} = Pump.sweep(%{conn: conn, queue: q, batch: 100})

    # exactly the live occurrence was enqueued
    assert {:ok, {_id, "occ", 1}} = Jobs.claim(conn, q, 60_000)
    assert :empty = Jobs.claim(conn, q, 60_000)
    # the dangling registration was swept from the registry
    assert {:ok, 1} = Repeat.count(conn, q)
  end

  test "the pump cadence promotes due work within a tick", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :scheduled} = Jobs.enqueue_in(conn, q, id, "soon", 20)

    {:ok, pump} = Pump.start_link(conn: conn, queue: q, tick_ms: 20, batch: 100)

    # within a few ticks the due entry is promoted and claimable
    assert wait_claimable(q, id, 50)

    Pump.stop(pump)
  end

  test "a worker without the pump leaves the schedule untouched (opt-in)", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :scheduled} = Jobs.enqueue_in(conn, q, id, "parked", 0)

    # no pump started: the due entry stays parked, never auto-promoted
    Process.sleep(60)
    assert {:ok, 1} = Connector.command(conn, ["ZCARD", Keyspace.queue_key(q, "schedule")])
    assert :empty = Jobs.claim(conn, q, 60_000)
  end

  test "the pump is a transient child with stated restart semantics", %{conn: conn, q: q} do
    spec = Pump.child_spec(conn: conn, queue: q, tick_ms: 1_000)
    assert spec.restart == :transient
    assert spec.shutdown == 5_000
    assert spec.id == EchoMQ.Pump
  end

  test "a crashed pump under supervision restarts and resumes the cadence", %{q: q} do
    # the pump owns its own connector lane here so a restart re-establishes it
    child = {Pump, [queue: q, tick_ms: 20, batch: 100, connector: [port: 6390], id: :pump_under_sup]}
    {:ok, sup} = Supervisor.start_link([child], strategy: :one_for_one)

    [{_, pid1, _, _}] = Supervisor.which_children(sup)
    assert is_pid(pid1)

    # crash it; transient => the supervisor restarts it
    Process.exit(pid1, :kill)
    assert wait_restarted(sup, pid1, 50)

    # the restarted pump still promotes due work
    {:ok, conn} = Connector.start_link(port: 6390)
    id = BrandedId.generate!("JOB")
    {:ok, :scheduled} = Jobs.enqueue_in(conn, q, id, "after-restart", 20)
    assert wait_claimable(q, id, 50)

    Supervisor.stop(sup)
  end

  defp wait_claimable(_q, _id, 0), do: false

  defp wait_claimable(q, id, n) do
    {:ok, conn} = Connector.start_link(port: 6390)

    res =
      case Jobs.claim(conn, q, 60_000) do
        {:ok, {^id, _, _}} -> true
        _ -> false
      end

    GenServer.stop(conn)
    if res, do: true, else: (Process.sleep(20); wait_claimable(q, id, n - 1))
  end

  defp wait_restarted(_sup, _old, 0), do: false

  defp wait_restarted(sup, old, n) do
    Process.sleep(20)

    case Supervisor.which_children(sup) do
      [{_, pid, _, _}] when is_pid(pid) and pid != old -> true
      _ -> wait_restarted(sup, old, n - 1)
    end
  end
end
