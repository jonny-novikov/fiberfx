defmodule EchoMQ.LanesBatchTest do
  @moduledoc """
  The wire column of the emq.5.3 grouped (affinity-respecting) batch claim
  (FORK 5.3-A Arm 1 -- the additive `@gbclaim`): `bclaim/3` rotates the ring one
  step and serves the rotated lane a HOMOGENEOUS batch in one atomic turn --
  every member of the batch from the ONE group the rotation landed on, leased on
  the server clock, counted against that group's `gactive` ceiling and never
  past its `glimit`. Ring-rotated, not caller-named (the `wclaim/3` shape, no
  caller group): the served count is the lane's full `glimit` HEADROOM, the
  direct `wclaim/3` isomorph with the lane's depth in place of its weight. The
  grouped counterpart of the flat `EchoMQ.Jobs.claim_batch/4` (which serves a
  cross-group batch over the flat `pending` set, bypassing the ring's per-group
  accounting). Every shipped `@g*`/`@bclaim` is byte-frozen -- this is a parallel
  path. On per-test sub-queues with the baseline purge idiom. emq.5.3.
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
    q = "emq0.blanes#{System.unique_integer([:positive])}"

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

  defp flood(conn, q, group, n, payload) do
    for _ <- 1..n do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Lanes.enqueue(conn, q, group, id, payload)
      id
    end
  end

  test "bclaim/3 serves a HOMOGENEOUS batch -- every member from one landed lane", %{
    conn: conn,
    q: q
  } do
    a = BrandedId.generate!("PRT")
    b = BrandedId.generate!("PRT")
    a_ids = flood(conn, q, a, 5, "ba")
    b_ids = flood(conn, q, b, 5, "bb")

    assert {:ok, served} = Lanes.bclaim(conn, q, 60_000)
    assert served != []

    groups = served |> Enum.map(fn {_id, _p, _att, g} -> g end) |> Enum.uniq()
    # the tuple group is homogeneous -- one group across the whole batch
    assert length(groups) == 1
    g = hd(groups)

    served_ids = Enum.map(served, fn {id, _p, _att, _g} -> id end)
    own_ids = if g == a, do: a_ids, else: b_ids
    sibling_ids = if g == a, do: b_ids, else: a_ids

    # every member came from the served lane's flood, none from the sibling
    assert Enum.all?(served_ids, &(&1 in own_ids))
    refute Enum.any?(served_ids, &(&1 in sibling_ids))

    # the ROW group field agrees, homogeneous, equal to the served group
    row_groups =
      served_ids
      |> Enum.map(fn id ->
        {:ok, rg} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "group"])
        rg
      end)
      |> Enum.uniq()

    assert row_groups == [g]
  end

  test "bclaim/3 with no glimit serves the landed lane's whole depth (headroom-bounded)",
       %{conn: conn, q: q} do
    a = BrandedId.generate!("PRT")
    ids = flood(conn, q, a, 4, "d")

    # no glimit set -> K is bounded by the lane depth alone (the @gwclaim no-limit
    # case): the whole backlog is served in one batch
    assert {:ok, served} = Lanes.bclaim(conn, q, 60_000)
    assert length(served) == 4
    claimed = Enum.map(served, fn {id, _p, _att, _g} -> id end)
    # the four oldest-mint ids, in mint order (the order theorem)
    assert claimed == ids
    # each at its first-claim token, homogeneous in the lane
    assert Enum.all?(served, fn {_id, _p, att, g} -> att == 1 and g == a end)
  end

  test "bclaim/3 clamps to the glimit headroom and never serves past the ceiling", %{
    conn: conn,
    q: q
  } do
    # the load-bearing concurrency invariant: a grouped batch must NEVER push
    # gactive past glimit. Lane glimit 3, flooded 8: the batch serves at most 3.
    a = BrandedId.generate!("PRT")
    :ok = Lanes.limit(conn, q, a, 3)
    ids = flood(conn, q, a, 8, "c")

    assert {:ok, served} = Lanes.bclaim(conn, q, 60_000)
    # K clamped to the headroom (3 - 0), not the depth (8)
    assert length(served) == 3
    assert {:ok, "3"} = Connector.command(conn, ["HGET", Keyspace.queue_key(q, "gactive"), a])

    # the lane is at its ceiling -- de-ringed, the next batch serves nothing
    assert :empty = Lanes.bclaim(conn, q, 60_000)

    # completing one in-flight job reopens one slot; the freed headroom serves the
    # NEXT oldest-mint member (not a re-serve)
    {id0, _p, att0, ^a} = hd(served)
    :ok = Jobs.complete(conn, q, id0, att0)
    assert {:ok, [{next_id, _np, 1, ^a}]} = Lanes.bclaim(conn, q, 60_000)
    assert next_id == Enum.at(ids, 3)
  end

  test "bclaim/3 increments gactive by the ACTUAL count served", %{conn: conn, q: q} do
    a = BrandedId.generate!("PRT")
    :ok = Lanes.limit(conn, q, a, 10)
    _ = flood(conn, q, a, 3, "n")

    assert {:ok, served} = Lanes.bclaim(conn, q, 60_000)
    assert length(served) == 3
    # gactive == the actual count served (3), well under the ceiling (10)
    assert {:ok, "3"} = Connector.command(conn, ["HGET", Keyspace.queue_key(q, "gactive"), a])
  end

  test "bclaim/3 leases every served member on the server clock (one shared deadline)", %{
    conn: conn,
    q: q
  } do
    a = BrandedId.generate!("PRT")
    _ = flood(conn, q, a, 3, "w")

    {:ok, before} = Connector.command(conn, ["TIME"])
    [secs, _] = before
    now_ms = String.to_integer(secs) * 1000

    assert {:ok, served} = Lanes.bclaim(conn, q, 60_000)
    assert length(served) == 3

    active = Keyspace.queue_key(q, "active")

    deadlines =
      for {id, _p, _att, _g} <- served do
        assert {:ok, score} = Connector.command(conn, ["ZSCORE", active, id])
        deadline = trunc(score)
        # a TIME-derived deadline in the future (now + 60_000), never a host clock
        assert deadline >= now_ms + 60_000
        assert deadline < now_ms + 120_000
        score
      end

    # ONE shared lease deadline for the whole batch (a single in-script TIME read)
    assert length(Enum.uniq(deadlines)) == 1
  end

  test "bclaim/3 answers :empty on an empty ring", %{conn: conn, q: q} do
    assert :empty = Lanes.bclaim(conn, q, 60_000)
  end

  test "bclaim/3 answers :empty once the only lane is drained", %{conn: conn, q: q} do
    a = BrandedId.generate!("PRT")
    _ = flood(conn, q, a, 2, "x")

    assert {:ok, served} = Lanes.bclaim(conn, q, 60_000)
    assert length(served) == 2
    # the lane is empty now -> the next claim finds nothing
    assert :empty = Lanes.bclaim(conn, q, 60_000)
  end

  test "a queue-wide pause stops the grouped batch too (pending untouched)", %{conn: conn, q: q} do
    a = BrandedId.generate!("PRT")
    _ = flood(conn, q, a, 3, "p")

    assert :ok = EchoMQ.Admin.pause(conn, q)
    assert :empty = Lanes.bclaim(conn, q, 60_000)
    # the lane backlog is intact behind the queue-wide pause
    assert {:ok, 3} = Lanes.depth(conn, q, a)

    assert :ok = EchoMQ.Admin.resume(conn, q)
    assert {:ok, served} = Lanes.bclaim(conn, q, 60_000)
    assert length(served) == 3
  end

  test "bclaim/3 rotates the ring across lanes when each lane is capped", %{conn: conn, q: q} do
    # with a per-lane ceiling, each lane yields its headroom then de-rings until a
    # complete frees it -- so successive batches (with completion) round-robin the
    # lanes, the fairness-by-construction of the rotating ring carried to the batch.
    a = BrandedId.generate!("PRT")
    b = BrandedId.generate!("PRT")
    :ok = Lanes.limit(conn, q, a, 2)
    :ok = Lanes.limit(conn, q, b, 2)
    _ = flood(conn, q, a, 4, "ra")
    _ = flood(conn, q, b, 4, "rb")

    # drive a bounded window, settling each batch so the lane reopens; record the
    # set of groups served -- both lanes must appear (the ring rotated)
    seen =
      Enum.reduce(1..6, MapSet.new(), fn _, acc ->
        case Lanes.bclaim(conn, q, 60_000) do
          {:ok, served} ->
            Enum.each(served, fn {id, _p, att, _g} -> Jobs.complete(conn, q, id, att) end)
            Enum.reduce(served, acc, fn {_id, _p, _att, g}, s -> MapSet.put(s, g) end)

          :empty ->
            acc
        end
      end)

    assert MapSet.member?(seen, a)
    assert MapSet.member?(seen, b)
  end

  test "bclaim/3 refuses a non-positive lease (the wclaim/3 guard)", %{conn: conn, q: q} do
    assert_raise FunctionClauseError, fn -> Lanes.bclaim(conn, q, 0) end
    assert_raise FunctionClauseError, fn -> Lanes.bclaim(conn, q, -1) end
  end
end
