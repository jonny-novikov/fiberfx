defmodule EchoMQ.StreamTest do
  @moduledoc """
  The writer law's `:valkey` proof (emq3.2, S1 the writer part 2): the
  `EchoMQ.Stream` writer round-trips over a live RESP3 connection on 6390 --
  N≥2 EVT records append in mint order and read back in that order (the
  order-theorem proof surface, INV1); a wrong-kind / malformed record id RAISES
  before any wire with NO key written (the host-side kind door, INV2); and a
  contrived out-of-order append surfaces `{:error, :nonmonotonic}` (the `id≤top`
  rejection, never swallowed -- INV3).

  `:valkey`-tagged (a live connection on 6390). The writer MINTS branded record
  ids in the append path, so the determinism posture is the ≥100 loop (the
  same-ms mint hazard), run from the gate ladder. The per-queue purge rides its
  OWN disposable connection (the stream key emq:{q}:stream:<name> shares the {q}
  hashtag, so KEYS emq:{q}:* sweeps it) -- the stream_verbs_test idiom.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.{BrandedId, Snowflake}
  alias EchoMQ.{Connector, Stream}
  alias EchoMQ.Stream.Id

  setup_all do
    :ok = Snowflake.start(8)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    queue = "emq32.st#{System.unique_integer([:positive])}"

    on_exit(fn ->
      stop_conn(conn)
      purge(queue)
    end)

    %{conn: conn, queue: queue}
  end

  defp stop_conn(conn) do
    try do
      GenServer.stop(conn)
    catch
      :exit, _ -> :ok
    end
  end

  defp purge(queue) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> queue <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    stop_conn(conn)
  end

  describe "AS-3/AS-4 -- append + the order-theorem read-back (the proof surface)" do
    test "N EVT records append, return the branded receipt, and read back in MINT order", ctx do
      %{conn: conn, queue: queue} = ctx
      n = 5

      # append N records; each returns its branded receipt (the mint order is
      # the append order over the shared monotone cell).
      receipts =
        for i <- 1..n do
          assert {:ok, branded} = Stream.append(conn, queue, "s", [{"seq", "v#{i}"}])
          assert BrandedId.namespace(branded) == "EVT"
          branded
        end

      # the read-back returns {branded, fields_map} IN MINT ORDER -- assert the
      # order equals the receipts' order AND equals the id-SORT order (positive,
      # N>=2, against the appended data -- not a vacuous XRANGE).
      assert {:ok, read} = Stream.read(conn, queue, "s")
      read_brandeds = for {b, _f} <- read, do: b

      assert read_brandeds == receipts, "read-back order != mint order"
      assert read_brandeds == Enum.sort(receipts), "read-back order != id-sort order (the order theorem)"

      # the payloads round-trip in order (v1..vN), and the branded id is the
      # stored "id" field recovered (the claims-only contract).
      read_vals = for {_b, f} <- read, do: Map.fetch!(f, "seq")
      assert read_vals == for(i <- 1..n, do: "v#{i}")
    end

    test "the explicit XADD id on the wire is the A1 image of the branded receipt", ctx do
      %{conn: conn, queue: queue} = ctx
      assert {:ok, branded} = Stream.append(conn, queue, "a1", [{"k", "v"}])
      {:ok, expected_xadd} = Id.xadd_id(branded)

      # XRANGE raw: the entry id is the A1 xadd id; the "id" field is the branded
      # receipt -- the writer stored both as the law requires.
      key = Stream.stream_key(queue, "a1")
      assert {:ok, [[^expected_xadd, ["id", ^branded, "k", "v"]]]} =
               Connector.command(conn, ["XRANGE", key, "-", "+"])
    end

    test "append_batch lands N records in one pipeline, receipts in append/mint order", ctx do
      %{conn: conn, queue: queue} = ctx
      n = 4
      records = for i <- 1..n, do: [{"seq", "b#{i}"}]

      assert {:ok, receipts} = Stream.append_batch(conn, queue, "batch", records)
      assert length(receipts) == n
      assert Enum.all?(receipts, &(BrandedId.namespace(&1) == "EVT"))

      assert {:ok, read} = Stream.read(conn, queue, "batch")
      read_brandeds = for {b, _f} <- read, do: b
      assert read_brandeds == receipts
      assert read_brandeds == Enum.sort(receipts)
    end

    test "read COUNT bounds the read-back (a thin XRANGE COUNT wrapper)", ctx do
      %{conn: conn, queue: queue} = ctx
      for i <- 1..3, do: {:ok, _} = Stream.append(conn, queue, "c", [{"n", "#{i}"}])

      assert {:ok, [{_b, %{"n" => "1"}}]} = Stream.read(conn, queue, "c", "-", "+", 1)
    end
  end

  describe "EMQ3.2-INV2 -- the kind door RAISES before any wire (NO key written)" do
    test "a wrong-namespace record id raises, with the stream key ABSENT", ctx do
      %{conn: conn, queue: queue} = ctx
      ord_id = BrandedId.encode!("ORD", Snowflake.next())
      key = Stream.stream_key(queue, "kd")

      assert_raise ArgumentError, ~r/one brand per stream|EVT/, fn ->
        Stream.append_id(conn, queue, "kd", ord_id, [{"f", "v"}])
      end

      # the raise occurred BEFORE any XADD -- the stream key does not exist.
      assert {:ok, 0} = Connector.command(conn, ["EXISTS", key])
    end

    test "a malformed record id raises, with the stream key ABSENT", ctx do
      %{conn: conn, queue: queue} = ctx
      key = Stream.stream_key(queue, "mal")

      assert_raise ArgumentError, ~r/valid branded id/, fn ->
        Stream.append_id(conn, queue, "mal", "not-branded", [{"f", "v"}])
      end

      assert {:ok, 0} = Connector.command(conn, ["EXISTS", key])
    end
  end

  describe "EMQ3.2-INV3 -- the :nonmonotonic liveness (id<=top surfaced, never swallowed)" do
    test "a contrived out-of-order append answers {:error, :nonmonotonic}", ctx do
      %{conn: conn, queue: queue} = ctx

      # mint two EVT ids in mint order (older first), then append them OUT of
      # order: the newer lands, then the OLDER is appended -- its A1 xadd id is
      # below the stream top, so Valkey rejects it. This is the multi-writer
      # interleave (the body §1.3); single-writer never produces it naturally.
      older = BrandedId.encode!("EVT", Snowflake.next())
      newer = BrandedId.encode!("EVT", Snowflake.next())
      assert Id.xadd_id(older) < Id.xadd_id(newer)

      assert {:ok, ^newer} = Stream.append_id(conn, queue, "nm", newer, [{"f", "v"}])
      # the older id is now <= the stream top -> the rejection is SURFACED,
      # never swallowed, never retried with `*`.
      assert {:error, :nonmonotonic} = Stream.append_id(conn, queue, "nm", older, [{"f", "v"}])

      # the stream still holds exactly the one (newer) record -- the rejected
      # append wrote nothing.
      key = Stream.stream_key(queue, "nm")
      assert {:ok, 1} = Connector.command(conn, ["XLEN", key])
    end

    test "a NON-monotonic error (WRONGTYPE) passes through verbatim, NOT mapped to :nonmonotonic", ctx do
      %{conn: conn, queue: queue} = ctx
      # a key holding a non-stream type -> XADD answers WRONGTYPE; the writer must
      # pass it through verbatim (only the id<=top ERR maps to :nonmonotonic).
      key = Stream.stream_key(queue, "wt")
      {:ok, _} = Connector.command(conn, ["SET", key, "x"])
      evt = BrandedId.encode!("EVT", Snowflake.next())

      assert {:error, {:error_reply, "WRONGTYPE" <> _}} =
               Stream.append_id(conn, queue, "wt", evt, [{"f", "v"}])
    end
  end

  # ==========================================================================
  # emq3.6 TIME-TRAVEL -- a mint-time window read == the id-filtered truth
  # ==========================================================================

  # Append one EVT record at a CONTROLLED, KNOWN mint instant `dt`: the branded
  # id's snowflake IS min_for(dt) (seq 0 at that ms), so its mint instant is
  # exactly `dt` -- the deterministic mint the time-travel assertions stand on
  # (no next_branded live-clock hazard; the window straddle is exact by
  # construction, so a multi-seed sweep suffices -- not the ≥100 loop). The
  # conformance stream_retention_append_at precedent.
  defp append_at(conn, queue, name, %DateTime{} = dt) do
    branded = BrandedId.encode!("EVT", Snowflake.min_for(dt))
    {:ok, ^branded} = Stream.append_id(conn, queue, name, branded, [{"at", DateTime.to_iso8601(dt)}])
    branded
  end

  # The mint instant of a branded EVT id (its snowflake -> DateTime) -- the
  # id-filter the window read is asserted EQUAL to (INV-TT).
  defp instant(branded) do
    {:ok, "EVT", snow} = BrandedId.parse(branded)
    Snowflake.to_datetime(snow)
  end

  defp ids(entries), do: for({b, _f} <- entries, do: b)

  describe "emq3.6 INV-TT -- read_window/5 == the id-filtered full read (the straddle)" do
    test "a STRADDLING window returns EXACTLY the in-window entries in mint order, excluding below/above",
         ctx do
      %{conn: conn, queue: queue} = ctx
      t0 = ~U[2025-05-01 09:00:00.000Z]
      t1 = ~U[2025-05-01 09:00:00.300Z]

      below = for d <- 3..1//-1, do: append_at(conn, queue, "tt", DateTime.add(t0, -d, :millisecond))
      inside = for ms <- [0, 100, 300], do: append_at(conn, queue, "tt", DateTime.add(t0, ms, :millisecond))
      above = for d <- 1..3, do: append_at(conn, queue, "tt", DateTime.add(t1, d, :millisecond))

      {:ok, full} = Stream.read(conn, queue, "tt")
      full_ids = ids(full)

      # the id-filtered truth: the full read filtered by each id's mint instant.
      filtered =
        for b <- full_ids,
            DateTime.compare(instant(b), t0) != :lt and DateTime.compare(instant(b), t1) != :gt,
            do: b

      {:ok, win} = Stream.read_window(conn, queue, "tt", t0, t1)
      win_ids = ids(win)

      # INV-TT: the window read EQUALS the id-filter, in mint order, == the inside set.
      assert win_ids == filtered
      assert win_ids == inside

      # the no-vacuous-pass proof: the window ACTUALLY EXCLUDES the below and above.
      assert Enum.all?(below, fn b -> b not in win_ids end)
      assert Enum.all?(above, fn b -> b not in win_ids end)
      # and it is a STRICT subset of the full read (the bounds filtered something).
      assert length(win_ids) < length(full_ids)
    end

    test "a window containing ALL records degenerates to the full read; a window containing NONE is empty",
         ctx do
      %{conn: conn, queue: queue} = ctx
      base = ~U[2025-05-02 12:00:00.000Z]
      recs = for ms <- [0, 10, 20, 30], do: append_at(conn, queue, "ttall", DateTime.add(base, ms, :millisecond))

      # ALL: a wide window covering every record == the full read.
      {:ok, all} = Stream.read_window(conn, queue, "ttall", DateTime.add(base, -1000, :millisecond), DateTime.add(base, 1000, :millisecond))
      assert ids(all) == recs

      # NONE: a window entirely BELOW the data is empty (the edge case, not the proof).
      {:ok, none} = Stream.read_window(conn, queue, "ttall", DateTime.add(base, -1000, :millisecond), DateTime.add(base, -500, :millisecond))
      assert none == []
    end

    test "read_window respects a COUNT cap", ctx do
      %{conn: conn, queue: queue} = ctx
      base = ~U[2025-05-03 08:00:00.000Z]
      recs = for ms <- [0, 5, 10, 15, 20], do: append_at(conn, queue, "ttc", DateTime.add(base, ms, :millisecond))

      {:ok, capped} = Stream.read_window(conn, queue, "ttc", base, DateTime.add(base, 100, :millisecond), 2)
      # COUNT caps to the 2 OLDEST in mint order (XRANGE COUNT semantics).
      assert ids(capped) == Enum.take(recs, 2)
    end
  end

  describe "emq3.6 INV-BOUND -- the exact-ms edges, never a raw min_for integer to the wire" do
    test "the lower floor (t0 IN, t0-1ms OUT) and the inclusive upper (t1 IN, t1+1ms OUT)", ctx do
      %{conn: conn, queue: queue} = ctx
      t0 = ~U[2025-06-10 06:30:00.000Z]
      t1 = ~U[2025-06-10 06:30:00.250Z]

      lo_out = append_at(conn, queue, "tte", DateTime.add(t0, -1, :millisecond))
      lo_in = append_at(conn, queue, "tte", t0)
      hi_in = append_at(conn, queue, "tte", t1)
      hi_out = append_at(conn, queue, "tte", DateTime.add(t1, 1, :millisecond))

      {:ok, win} = Stream.read_window(conn, queue, "tte", t0, t1)
      win_ids = ids(win)

      # the half-open lower floor (minid_floor): t0 IN, t0-1ms OUT.
      assert lo_in in win_ids
      assert lo_out not in win_ids
      # the INCLUSIVE upper (maxid_ceil): t1 IN, t1+1ms OUT.
      assert hi_in in win_ids
      assert hi_out not in win_ids
      # the window is exactly the two in-edge records.
      assert win_ids == [lo_in, hi_in]
    end

    test "maxid_ceil is the inverse of minid_floor: floor is <ms>-0, ceil is <ms>-0x3FFFFF, neither a raw integer" do
      dt = ~U[2025-06-11 00:00:00.123Z]
      ms = Snowflake.unix_ms(Snowflake.min_for(dt))

      assert Stream.minid_floor(dt) == "#{ms}-0"
      assert Stream.maxid_ceil(dt) == "#{ms}-#{0x3FFFFF}"
      # the F-1-class discipline: the bound is "ms-seq", NEVER the snowflake integer.
      refute Stream.minid_floor(dt) == Integer.to_string(Snowflake.min_for(dt))
      refute Stream.maxid_ceil(dt) == Integer.to_string(Snowflake.min_for(dt))
    end

    test "read_since/4 reads the open [t0, inf): at-or-after t0 in mint order, excluding below-t0", ctx do
      %{conn: conn, queue: queue} = ctx
      t0 = ~U[2025-07-01 00:00:00.100Z]

      below = for d <- 2..1//-1, do: append_at(conn, queue, "tts", DateTime.add(t0, -d, :millisecond))
      at_or_after = for ms <- [0, 50, 200], do: append_at(conn, queue, "tts", DateTime.add(t0, ms, :millisecond))

      {:ok, since} = Stream.read_since(conn, queue, "tts", t0)
      since_ids = ids(since)

      assert since_ids == at_or_after
      assert Enum.all?(below, fn b -> b not in since_ids end)
    end
  end

  describe "emq3.6 the time-travel read guards (policy before the wire)" do
    test "read_window RAISES ArgumentError on an inverted window (t1 < t0) before any wire", ctx do
      %{conn: conn, queue: queue} = ctx
      t0 = ~U[2025-08-01 00:00:00.000Z]
      t1 = ~U[2025-07-01 00:00:00.000Z]

      assert_raise ArgumentError, fn ->
        Stream.read_window(conn, queue, "ttbad", t0, t1)
      end
    end

    test "an equal-instant window [t,t] is VALID (not inverted) and reads the records at that ms", ctx do
      %{conn: conn, queue: queue} = ctx
      t = ~U[2025-08-02 00:00:00.000Z]
      rec = append_at(conn, queue, "tteq", t)

      {:ok, win} = Stream.read_window(conn, queue, "tteq", t, t)
      assert ids(win) == [rec]
    end
  end
end
