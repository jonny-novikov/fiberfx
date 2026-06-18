defmodule EchoMQ.LanesReassignTest do
  @moduledoc """
  The fair-lanes control plane (emq.4.1-D2): `Lanes.reassign/4` moves a grouped
  pending member from its source lane to a destination lane in one atomic script.
  The source group is read from the row inside the script (arity 4, never
  passed); both lanes share the one `{q}` slot, so the move is atomic by
  construction and a cross-queue move is not expressible. The proof set: the move
  itself (the member leaves src, enters dst at score 0, the row group is
  rewritten); the ceiling accounting past the ZSET swap (a claim+complete of the
  moved member charges gactive[dst], not gactive[src] -- the byte-frozen @gclaim/
  @complete read the row's group); the ring re-shape (src dropped when emptied,
  dst returned only if serviceable); and the typed edges (not-found, not-pending/
  in-flight, same-group no-op, an ill-formed dst raises before the wire). On
  per-test sub-queues with the baseline purge idiom.
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
    q = "emq0.reassign#{System.unique_integer([:positive])}"

    on_exit(fn -> purge(q) end)

    %{conn: conn, q: q}
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  # ZSCORE answers a numeric score: a RESP3 double (the float 0.0) on a
  # protocol-3 connection, a bulk string ("0") on RESP2. Normalize to a float so
  # the assertion pins the score VALUE, not its wire representation (the
  # stalled_group conformance scenario sidesteps this by not pinning the form).
  defp lane_score(conn, q, group, id) do
    case Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "g:" <> group <> ":pending"), id]) do
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

  test "moves a pending member to the destination lane at score 0 and rewrites the row group",
       %{conn: conn, q: q} do
    src = BrandedId.generate!("PRT")
    dst = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, src, id, "move-me")

    assert {:ok, :reassigned} = Lanes.reassign(conn, q, id, dst)

    # left src, entered dst at score 0 (the mint-ordered place is kept)
    assert :absent = lane_score(conn, q, src, id)
    assert +0.0 = lane_score(conn, q, dst, id)
    # the load-bearing write: the row now records dst
    assert {:ok, ^dst} = row_group(conn, q, id)
  end

  test "the moved member is served in the destination lane's rotation with group = dst",
       %{conn: conn, q: q} do
    src = BrandedId.generate!("PRT")
    dst = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, src, id, "cargo")

    assert {:ok, :reassigned} = Lanes.reassign(conn, q, id, dst)
    assert {:ok, {^id, "cargo", 1, ^dst}} = Lanes.claim(conn, q, 60_000)
  end

  test "a claim+complete of the moved member charges the destination lane's ceiling, not the source's",
       %{conn: conn, q: q} do
    src = BrandedId.generate!("PRT")
    dst = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, src, id, "w")
    {:ok, :reassigned} = Lanes.reassign(conn, q, id, dst)

    {:ok, {^id, _, 1, ^dst}} = Lanes.claim(conn, q, 60_000)
    # in flight, the row's group drove the gactive increment to dst, never src
    assert {:ok, "1"} = gactive(conn, q, dst)
    assert {:ok, nil} = gactive(conn, q, src)

    :ok = Jobs.complete(conn, q, id, 1)
    # complete charges dst's counter back down (self-cleaning to absent)
    assert {:ok, nil} = gactive(conn, q, dst)
    assert {:ok, nil} = gactive(conn, q, src)
  end

  test "the source lane is dropped from the ring when the move empties it", %{conn: conn, q: q} do
    # src holds exactly one member; moving it leaves src empty, so src must be
    # dropped from the ring and only dst is served thereafter
    src = BrandedId.generate!("PRT")
    dst = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, src, id, "only")

    {:ok, :reassigned} = Lanes.reassign(conn, q, id, dst)

    # the ring holds dst alone (src was dropped when emptied)
    assert {:ok, [^dst]} = Connector.command(conn, ["LRANGE", Keyspace.queue_key(q, "ring"), "0", "-1"])
    assert {:ok, {^id, "only", 1, ^dst}} = Lanes.claim(conn, q, 60_000)
    assert :empty = Lanes.claim(conn, q, 60_000)
  end

  test "the source lane stays in the ring when the move leaves a sibling behind", %{conn: conn, q: q} do
    # src holds two members; moving one leaves src non-empty, so src stays
    # serviceable and the ring carries both lanes
    src = BrandedId.generate!("PRT")
    dst = BrandedId.generate!("PRT")
    stay = BrandedId.generate!("JOB")
    move = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, src, stay, "stay")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, src, move, "move")

    {:ok, :reassigned} = Lanes.reassign(conn, q, move, dst)

    # src still has its sibling; both lanes serviceable
    assert {:ok, 1} = Lanes.depth(conn, q, src)
    assert {:ok, 1} = Lanes.depth(conn, q, dst)
    {:ok, ring} = Connector.command(conn, ["LRANGE", Keyspace.queue_key(q, "ring"), "0", "-1"])
    assert Enum.sort(ring) == Enum.sort([src, dst])
  end

  test "a paused destination receives the member but is NOT forced back into the ring",
       %{conn: conn, q: q} do
    src = BrandedId.generate!("PRT")
    dst = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, src, id, "w")
    :ok = Lanes.pause(conn, q, dst)

    assert {:ok, :reassigned} = Lanes.reassign(conn, q, id, dst)

    # the member is parked in dst's lane, but dst is paused -> not on the ring
    assert +0.0 = lane_score(conn, q, dst, id)
    assert {:ok, nil} = Connector.command(conn, ["LPOS", Keyspace.queue_key(q, "ring"), dst])
    assert :empty = Lanes.claim(conn, q, 60_000)

    # resuming dst returns it to rotation and the member is served there
    :ok = Lanes.resume(conn, q, dst)
    assert {:ok, {^id, _, 1, ^dst}} = Lanes.claim(conn, q, 60_000)
  end

  test "a destination at its ceiling receives the member but is NOT forced back into the ring",
       %{conn: conn, q: q} do
    src = BrandedId.generate!("PRT")
    dst = BrandedId.generate!("PRT")
    # fill dst to a ceiling of 1 with an in-flight job, so dst is maxed
    :ok = Lanes.limit(conn, q, dst, 1)
    held = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, dst, held, "held")
    {:ok, {^held, _, 1, ^dst}} = Lanes.claim(conn, q, 60_000)

    moved = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, src, moved, "moved")
    assert {:ok, :reassigned} = Lanes.reassign(conn, q, moved, dst)

    # moved is parked in dst's lane, but dst is at its ceiling -> not re-ringed
    assert +0.0 = lane_score(conn, q, dst, moved)
    assert :empty = Lanes.claim(conn, q, 60_000)

    # completing the in-flight held job reopens dst; the moved member is served
    :ok = Jobs.complete(conn, q, held, 1)
    assert {:ok, {^moved, _, 1, ^dst}} = Lanes.claim(conn, q, 60_000)
  end

  test "a same-group destination is an idempotent no-op that changes nothing", %{conn: conn, q: q} do
    g = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, g, id, "w")

    assert {:ok, :noop} = Lanes.reassign(conn, q, id, g)
    # still pending in its lane at score 0, the row unchanged
    assert +0.0 = lane_score(conn, q, g, id)
    assert {:ok, ^g} = row_group(conn, q, id)
    assert {:ok, {^id, "w", 1, ^g}} = Lanes.claim(conn, q, 60_000)
  end

  test "a missing or non-grouped job answers not_found, changing nothing", %{conn: conn, q: q} do
    dst = BrandedId.generate!("PRT")

    # no such row
    missing = BrandedId.generate!("JOB")
    assert {:error, :not_found} = Lanes.reassign(conn, q, missing, dst)

    # a row with no group (enqueued flat, not grouped)
    flat = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, flat, "flat")
    assert {:error, :not_found} = Lanes.reassign(conn, q, flat, dst)
    # the flat job is untouched in pending, no dst lane was created
    assert {:ok, :pending} = EchoMQ.Metrics.get_job_state(conn, q, flat)
    assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.queue_key(q, "g:" <> dst <> ":pending")])
  end

  test "an in-flight (claimed) member answers not_pending and is not mis-moved", %{conn: conn, q: q} do
    src = BrandedId.generate!("PRT")
    dst = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, src, id, "w")
    # claim it -> the member leaves its lane for active; gactive[src] = 1
    {:ok, {^id, _, 1, ^src}} = Lanes.claim(conn, q, 60_000)

    assert {:error, :not_pending} = Lanes.reassign(conn, q, id, dst)

    # the row still records src (rewriting an in-flight job's group would corrupt
    # the OTHER gactive direction at complete) and no dst lane was created
    assert {:ok, ^src} = row_group(conn, q, id)
    assert :absent = lane_score(conn, q, dst, id)
    assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.queue_key(q, "g:" <> dst <> ":pending")])
    # the original claim still settles on its token
    assert :ok = Jobs.complete(conn, q, id, 1)
  end

  test "an ill-formed destination group raises before any wire", %{conn: conn, q: q} do
    src = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, src, id, "w")

    assert_raise ArgumentError, fn -> Lanes.reassign(conn, q, id, "not-a-branded-id") end
    # the source lane is untouched -- the raise happened host-side, no move
    assert +0.0 = lane_score(conn, q, src, id)
  end
end
