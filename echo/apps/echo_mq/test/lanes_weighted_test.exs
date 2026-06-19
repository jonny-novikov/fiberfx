defmodule EchoMQ.LanesWeightedTest do
  @moduledoc """
  The wire column of the emq.4.4 weighted rotation (Fork B Arm 2, the additive
  weighted multi-pop): `weight/4` sets a per-lane fair-share weight on a
  branded-gated group, and `wclaim/3` serves a higher-weight lane proportionally
  more per turn -- never all of it, never past the lane's `glimit` concurrency
  ceiling, always leasing on the server clock. The capstone proof is the
  starvation drill: under sustained skew, EVERY lane drains. The equal
  round-robin `claim/3` is byte-frozen and coexists (an unweighted lane serves
  one head per turn, identical to `claim/3`). On per-test sub-queues with the
  baseline purge idiom. emq.4.4.
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
    q = "emq0.wlanes#{System.unique_integer([:positive])}"

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

  # Drive wclaim/3 over a window, returning a per-group tally of jobs served.
  defp drive(conn, q, turns) do
    Enum.reduce(1..turns, %{}, fn _, acc ->
      case Lanes.wclaim(conn, q, 60_000) do
        {:ok, served} ->
          Enum.reduce(served, acc, fn {_id, _p, _att, g}, a ->
            Map.update(a, g, 1, &(&1 + 1))
          end)

        :empty ->
          acc
      end
    end)
  end

  # Drive wclaim/3 over a bounded window, returning the SET of groups that were
  # served at least once within it (the interleaving witness).
  defp groups_served_within(conn, q, turns) do
    Enum.reduce(1..turns, MapSet.new(), fn _, seen ->
      case Lanes.wclaim(conn, q, 60_000) do
        {:ok, served} ->
          Enum.reduce(served, seen, fn {_id, _p, _att, g}, s -> MapSet.put(s, g) end)

        :empty ->
          seen
      end
    end)
  end

  test "weight/4 sets a lane weight on a branded group, readable back", %{conn: conn, q: q} do
    a = BrandedId.generate!("PRT")

    assert :ok = Lanes.weight(conn, q, a, 3)

    # the weight rides the gweight per-queue HASH (the glimit/gactive shape),
    # keyed by group -- no new key family
    assert {:ok, "3"} = Connector.command(conn, ["HGET", Keyspace.queue_key(q, "gweight"), a])
  end

  test "weight/4 raises on an ill-formed group before any wire", %{conn: conn, q: q} do
    assert_raise ArgumentError, fn -> Lanes.weight(conn, q, "not-a-branded-id", 2) end

    # nothing was written -- the gate is pre-wire
    assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.queue_key(q, "gweight")])
  end

  test "weight/4 refuses a weight below 1 (a parked lane is pause/3, not a weight)", %{
    conn: conn,
    q: q
  } do
    a = BrandedId.generate!("PRT")
    assert_raise FunctionClauseError, fn -> Lanes.weight(conn, q, a, 0) end
  end

  test "wclaim/3 serves two lanes weighted 3:1 approximately 3:1 over a window", %{
    conn: conn,
    q: q
  } do
    a = BrandedId.generate!("PRT")
    b = BrandedId.generate!("PRT")
    :ok = Lanes.weight(conn, q, a, 3)
    :ok = Lanes.weight(conn, q, b, 1)

    # flood both lanes far past the window
    for _ <- 1..60 do
      {:ok, :enqueued} = Lanes.enqueue(conn, q, a, BrandedId.generate!("JOB"), "wa")
      {:ok, :enqueued} = Lanes.enqueue(conn, q, b, BrandedId.generate!("JOB"), "wb")
    end

    counts = drive(conn, q, 40)
    served_a = Map.fetch!(counts, a)
    served_b = Map.fetch!(counts, b)

    # the lighter lane is served NON-ZERO (never shut out -- the starvation floor)
    assert served_b > 0
    # the heavier lane is served proportionally more, in the honest 3:1 band
    # ([2x, 4x] -- weighted schemes are exactly proportional only in the limit)
    assert served_a >= served_b * 2
    assert served_a <= served_b * 4
  end

  test "wclaim/3 leases every served job on the server clock", %{conn: conn, q: q} do
    a = BrandedId.generate!("PRT")
    :ok = Lanes.weight(conn, q, a, 3)
    for _ <- 1..3, do: {:ok, :enqueued} = Lanes.enqueue(conn, q, a, BrandedId.generate!("JOB"), "w")

    {:ok, before} = Connector.command(conn, ["TIME"])
    [secs, _] = before
    now_ms = String.to_integer(secs) * 1000

    assert {:ok, served} = Lanes.wclaim(conn, q, 60_000)
    assert length(served) == 3

    active = Keyspace.queue_key(q, "active")

    # each served id carries an active-set score = a TIME-derived deadline in the
    # future (now + 60_000), never a host timestamp. The RESP3 connector decodes
    # the ZSCORE as a native float.
    for {id, _p, _att, _g} <- served do
      assert {:ok, score} = Connector.command(conn, ["ZSCORE", active, id])
      deadline = trunc(score)
      assert deadline >= now_ms + 60_000
      assert deadline < now_ms + 120_000
    end
  end

  test "an unweighted lane serves one head per turn (defaults to weight 1, like claim/3)", %{
    conn: conn,
    q: q
  } do
    a = BrandedId.generate!("PRT")
    # no weight set -- the absent weight clamps to 1
    [j1, j2] = for _ <- 1..2, do: BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, a, j1, "u")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, a, j2, "u")

    assert {:ok, [{^j1, "u", 1, ^a}]} = Lanes.wclaim(conn, q, 60_000)
    assert {:ok, [{^j2, "u", 1, ^a}]} = Lanes.wclaim(conn, q, 60_000)
    assert :empty = Lanes.wclaim(conn, q, 60_000)
  end

  test "wclaim/3 never serves past a lane's glimit concurrency ceiling", %{conn: conn, q: q} do
    # the load-bearing concurrency invariant: a weight is a THROUGHPUT share, but
    # glimit is a CONCURRENCY ceiling -- a weight-K multi-pop must NEVER push
    # gactive past glimit. Lane weight 5, glimit 2: the first turn serves at most
    # 2 (the headroom), not 5.
    a = BrandedId.generate!("PRT")
    :ok = Lanes.weight(conn, q, a, 5)
    :ok = Lanes.limit(conn, q, a, 2)
    for _ <- 1..5, do: {:ok, :enqueued} = Lanes.enqueue(conn, q, a, BrandedId.generate!("JOB"), "c")

    assert {:ok, served} = Lanes.wclaim(conn, q, 60_000)
    # K is clamped to the headroom (2 - 0), not the weight (5)
    assert length(served) == 2
    # the lane is now at its ceiling -- de-ringed, the next turn serves nothing
    assert :empty = Lanes.wclaim(conn, q, 60_000)
    assert {:ok, "2"} = Connector.command(conn, ["HGET", Keyspace.queue_key(q, "gactive"), a])

    # completing the two in-flight jobs reopens the headroom; the lane returns
    [c1, c2] = Enum.map(served, fn {id, _p, att, _g} -> {id, att} end)
    :ok = Jobs.complete(conn, q, elem(c1, 0), elem(c1, 1))
    :ok = Jobs.complete(conn, q, elem(c2, 0), elem(c2, 1))
    # the lane is serviceable again (3 jobs still pending, headroom restored)
    assert {:ok, more} = Lanes.wclaim(conn, q, 60_000)
    assert length(more) == 2
  end

  test "the starvation drill: under skew, EVERY lane drains (the capstone guarantee)", %{
    conn: conn,
    q: q
  } do
    heavy = BrandedId.generate!("PRT")
    light1 = BrandedId.generate!("PRT")
    light2 = BrandedId.generate!("PRT")
    :ok = Lanes.weight(conn, q, heavy, 5)
    :ok = Lanes.weight(conn, q, light1, 1)
    :ok = Lanes.weight(conn, q, light2, 1)

    # the heavy lane is flooded DEEP (200 jobs at weight 5 = 40 turns to exhaust
    # alone); each light lane gets a small steady backlog
    for _ <- 1..200, do: {:ok, :enqueued} = Lanes.enqueue(conn, q, heavy, BrandedId.generate!("JOB"), "h")
    for _ <- 1..6, do: {:ok, :enqueued} = Lanes.enqueue(conn, q, light1, BrandedId.generate!("JOB"), "l1")
    for _ <- 1..6, do: {:ok, :enqueued} = Lanes.enqueue(conn, q, light2, BrandedId.generate!("JOB"), "l2")

    # the liveness floor: each light lane started with real backlog
    assert {:ok, 6} = Lanes.depth(conn, q, light1)
    assert {:ok, 6} = Lanes.depth(conn, q, light2)

    # THE LOAD-BEARING NO-OP-DEFEATER (interleaving within a bounded EARLY window):
    # with the heavy lane needing ~40 turns to exhaust at weight 5, a FIFO /
    # serve-heavy-to-exhaustion-first rotation serves ZERO from the light lanes in
    # the first handful of turns (a light lane is STUCK at its backlog). Fair
    # round-robin reaches BOTH light lanes within the first ring cycle. Assert
    # every light lane is served at least once inside a 9-turn window (3 ring
    # cycles) -- a no-fair-share rotation leaves them out, going RED here.
    early = groups_served_within(conn, q, 9)
    assert MapSet.member?(early, light1), "light1 starved in the early window: #{inspect(early)}"
    assert MapSet.member?(early, light2), "light2 starved in the early window: #{inspect(early)}"

    # the liveness assertion: drive to completion -- EVERY lane drains to zero,
    # the heavy lane included (served more, never to the exclusion of others)
    _ = drive(conn, q, 120)
    assert {:ok, 0} = Lanes.depth(conn, q, heavy)
    assert {:ok, 0} = Lanes.depth(conn, q, light1)
    assert {:ok, 0} = Lanes.depth(conn, q, light2)
  end

  test "a queue-wide pause stops the weighted claim too", %{conn: conn, q: q} do
    a = BrandedId.generate!("PRT")
    :ok = Lanes.weight(conn, q, a, 3)
    for _ <- 1..3, do: {:ok, :enqueued} = Lanes.enqueue(conn, q, a, BrandedId.generate!("JOB"), "w")

    assert :ok = EchoMQ.Admin.pause(conn, q)
    assert :empty = Lanes.wclaim(conn, q, 60_000)

    assert :ok = EchoMQ.Admin.resume(conn, q)
    assert {:ok, served} = Lanes.wclaim(conn, q, 60_000)
    assert length(served) == 3
  end
end
