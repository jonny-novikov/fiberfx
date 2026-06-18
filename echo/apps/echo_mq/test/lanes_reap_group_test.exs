defmodule EchoMQ.LanesReapGroupTest do
  @moduledoc """
  Group-aware recovery (emq.4.2-D2): `Lanes.reap_group/3` recovers ONE named
  group's expired-lease members on demand, returning each to its OWN lane
  (`g:<g>:pending`, score 0), NOT the flat pending -- the group-scoped entry the
  queue-wide `Jobs.reap/2` / `Stalled.check/3` lack. A NEW inline `@greap_group`
  byte-models `@reap`'s group branch (`jobs.ex`) with a `g == ARGV[1]` filter, so
  `@reap` and `@sweep_stalled` stay byte-frozen (INV1).

  The proof set: the TWO-group scoping (the load-bearing delta -- two groups both
  lapse, recover ONE, only its members land on its lane, the sibling's are LEFT in
  `active` for the queue-wide reaper -- the headline; a one-group probe would pass
  even with the filter absent); THE REORDER (a non-matching expired id is SKIPPED,
  never `ZREM`'d -- it survives in `active`); the `gactive` coherence past the
  lane-return (the sweep `HINCRBY gactive g -1`, so a re-claim+complete charges an
  honest `gactive[g]`); `group` a pure read (the recovered member reads back group
  = `g` unchanged); the live-lease exclusion (a non-expired lease is not swept);
  the ring respect (a paused / at-ceiling lane receives the member but is NOT
  re-rung -- the `@reap` guard); and the edges (an ill-formed group raises before
  the wire, a well-formed group with no expiry answers `{:ok, 0}`). On per-test
  sub-queues with the baseline purge idiom.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Jobs, Keyspace, Lanes}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq0.reapgroup#{System.unique_integer([:positive])}"

    on_exit(fn -> purge(q) end)

    %{conn: conn, q: q}
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  # ZSCORE answers a numeric score: a RESP3 double on a protocol-3 connection, a
  # bulk string on RESP2. Normalize a present score to a float (the value, not the
  # wire form); absence is a clean :absent either way (the lanes_reassign_test
  # idiom).
  defp lane_score(conn, q, group, id) do
    case Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "g:" <> group <> ":pending"), id]) do
      {:ok, nil} -> :absent
      {:ok, s} when is_number(s) -> s / 1.0
      {:ok, s} when is_binary(s) -> elem(Float.parse(s), 0)
      other -> other
    end
  end

  defp active_score(conn, q, id) do
    case Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "active"), id]) do
      {:ok, nil} -> :absent
      {:ok, s} when is_number(s) -> s / 1.0
      {:ok, s} when is_binary(s) -> elem(Float.parse(s), 0)
      other -> other
    end
  end

  defp gactive(conn, q, group),
    do: Connector.command(conn, ["HGET", Keyspace.queue_key(q, "gactive"), group])

  defp row_group(conn, q, id),
    do: Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "group"])

  # Enqueue one grouped job, claim it on a short lease, and let the lease lapse --
  # the member is now an expired-lease member of `active`. Returns the claimed id
  # (asserting it is the one enqueued under `group`).
  defp lapse(conn, q, group, payload, lease_ms) do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, group, id, payload)
    {:ok, {^id, ^payload, 1, ^group}} = Lanes.claim(conn, q, lease_ms)
    id
  end

  test "recovers ONLY the named group's expired members, leaving a sibling group in active",
       %{conn: conn, q: q} do
    g = BrandedId.generate!("PRT")
    h = BrandedId.generate!("PRT")
    # one group at a time so each claim serves the intended lane (no ring race)
    id_g = lapse(conn, q, g, "g", 30)
    id_h = lapse(conn, q, h, "h", 30)
    Process.sleep(80)

    assert {:ok, 1} = Lanes.reap_group(conn, q, g)

    # g's member is back in its OWN lane at score 0, gone from active + flat pending
    assert +0.0 = lane_score(conn, q, g, id_g)
    assert :absent = active_score(conn, q, id_g)
    assert {:ok, nil} = Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "pending"), id_g])

    # THE SCOPING: h's expired member is STILL in active (not recovered, not touched)
    assert is_float(active_score(conn, q, id_h))
    assert :absent = lane_score(conn, q, h, id_h)
    assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.queue_key(q, "g:" <> h <> ":pending")])
  end

  test "the reorder: a non-matching expired id is SKIPPED, never ZREM'd from active",
       %{conn: conn, q: q} do
    # the load-bearing correctness point -- @reap ZREMs every expired id it scans;
    # @greap_group must leave a non-matching expired id in active for the
    # queue-wide reaper. Two siblings lapse; reap_group(g) must not evict h.
    g = BrandedId.generate!("PRT")
    h = BrandedId.generate!("PRT")
    _id_g = lapse(conn, q, g, "g", 30)
    id_h = lapse(conn, q, h, "h", 30)
    Process.sleep(80)

    {:ok, 1} = Lanes.reap_group(conn, q, g)

    # h's id survives in active unchanged -> the queue-wide reaper recovers it next
    assert is_float(active_score(conn, q, id_h))
    # the queue-wide reaper then returns h's member to ITS lane (g:<h>:pending)
    {:ok, _} = Jobs.reap(conn, q)
    assert +0.0 = lane_score(conn, q, h, id_h)
    assert :absent = active_score(conn, q, id_h)
  end

  test "gactive is decremented on recovery and stays honest through a re-claim+complete",
       %{conn: conn, q: q} do
    g = BrandedId.generate!("PRT")
    id = lapse(conn, q, g, "w", 30)
    # in flight: the claim charged gactive[g] = 1
    assert {:ok, "1"} = gactive(conn, q, g)
    Process.sleep(80)

    {:ok, 1} = Lanes.reap_group(conn, q, g)
    # recovery decremented gactive[g] to absent (HDEL at zero) -- the @reap accounting
    assert {:ok, nil} = gactive(conn, q, g)

    # the recovered member is served in g's lane, group = g unchanged (pure read),
    # attempts incremented to 2; the re-claim charges gactive[g] back to 1
    assert {:ok, {^id, "w", 2, ^g}} = Lanes.claim(conn, q, 60_000)
    assert {:ok, "1"} = gactive(conn, q, g)
    assert {:ok, ^g} = row_group(conn, q, id)

    # a completion charges gactive[g] back down to absent -- honest at every step
    :ok = Jobs.complete(conn, q, id, 2)
    assert {:ok, nil} = gactive(conn, q, g)
  end

  test "a live (non-expired) lease is NOT swept -- only lapsed leases recover",
       %{conn: conn, q: q} do
    g = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, g, id, "live")
    # claim on a long lease and do NOT wait -> the lease is live, outside the
    # ZRANGEBYSCORE -inf..now window
    {:ok, {^id, "live", 1, ^g}} = Lanes.claim(conn, q, 60_000)

    assert {:ok, 0} = Lanes.reap_group(conn, q, g)
    # the live token is untouched: still active, gactive[g] still 1
    assert is_float(active_score(conn, q, id))
    assert {:ok, "1"} = gactive(conn, q, g)
    assert :absent = lane_score(conn, q, g, id)
    # the original token still settles
    assert :ok = Jobs.complete(conn, q, id, 1)
  end

  test "a recovered member into a PAUSED lane enters the lane but is NOT re-rung",
       %{conn: conn, q: q} do
    g = BrandedId.generate!("PRT")
    id = lapse(conn, q, g, "w", 30)
    :ok = Lanes.pause(conn, q, g)
    Process.sleep(80)

    assert {:ok, 1} = Lanes.reap_group(conn, q, g)
    # the member is parked in g's lane, but g is paused -> not on the ring
    assert +0.0 = lane_score(conn, q, g, id)
    assert {:ok, nil} = Connector.command(conn, ["LPOS", Keyspace.queue_key(q, "ring"), g])
    assert :empty = Lanes.claim(conn, q, 60_000)

    # resuming g returns it to rotation and the recovered member is served there
    :ok = Lanes.resume(conn, q, g)
    assert {:ok, {^id, _, 2, ^g}} = Lanes.claim(conn, q, 60_000)
  end

  test "a recovered member into a serviceable lane IS re-rung and wakes a parked consumer",
       %{conn: conn, q: q} do
    # the complement of the paused case: when the lane is serviceable after the
    # decrement (unpaused, below its ceiling, not already on the ring), recovery
    # re-rings g and pushes a wake -- the @reap guard's true branch. A single
    # member lapses, so after its claim leaves the lane empty the lane drops off
    # the ring; recovery must put it back.
    g = BrandedId.generate!("PRT")
    id = lapse(conn, q, g, "w", 30)
    # the lane emptied on claim -> g is no longer on the ring, the wake log is drained
    assert {:ok, nil} = Connector.command(conn, ["LPOS", Keyspace.queue_key(q, "ring"), g])
    {:ok, _} = Connector.command(conn, ["DEL", Keyspace.queue_key(q, "wake")])
    Process.sleep(80)

    assert {:ok, 1} = Lanes.reap_group(conn, q, g)
    # the member is back in its lane, g is re-rung, and a wake was pushed
    assert +0.0 = lane_score(conn, q, g, id)
    assert {:ok, pos} = Connector.command(conn, ["LPOS", Keyspace.queue_key(q, "ring"), g])
    assert is_integer(pos)
    assert {:ok, wake} = Connector.command(conn, ["LLEN", Keyspace.queue_key(q, "wake")])
    assert wake > 0
    # and the lane is immediately serviceable -- the recovered member is claimed
    assert {:ok, {^id, "w", 2, ^g}} = Lanes.claim(conn, q, 60_000)
  end

  test "a well-formed group with no expired members answers {:ok, 0}, changing nothing",
       %{conn: conn, q: q} do
    g = BrandedId.generate!("PRT")
    # a pending (never-claimed) member is not in active, so nothing to recover
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, g, id, "pending")

    assert {:ok, 0} = Lanes.reap_group(conn, q, g)
    # the pending member is untouched in its lane; a never-touched group is also 0
    assert +0.0 = lane_score(conn, q, g, id)
    assert {:ok, 0} = Lanes.reap_group(conn, q, BrandedId.generate!("PRT"))
  end

  test "an ill-formed group raises before any wire", %{conn: conn, q: q} do
    g = BrandedId.generate!("PRT")
    id = lapse(conn, q, g, "w", 30)
    Process.sleep(80)

    assert_raise ArgumentError, fn -> Lanes.reap_group(conn, q, "not-a-branded-id") end
    # the raise happened host-side: no recovery ran, the member is still in active
    assert is_float(active_score(conn, q, id))
    assert :absent = lane_score(conn, q, g, id)
  end
end
