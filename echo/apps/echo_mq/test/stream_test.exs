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
end
