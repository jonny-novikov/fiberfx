defmodule EchoMQ.StreamRetentionTest do
  @moduledoc """
  The retention law's `:valkey` proof (emq3.4, S2 the readers part 2): the
  `EchoMQ.Stream.trim/4` verb + the named/opt-in `EchoMQ.StreamRetention` driver
  round-trip over a live RESP3 connection on 6390 -- the DESTRUCTIVE at-rest op
  proven POSITIVELY (a real deletion AND a real survival in the same check, the
  blast radius bounded by the declared window, INV4).

  Four proof clusters, all POSITIVE (a no-op that deletes nothing is a LOUD
  failure -- the TRD.9.1 false-green class this rung guards against):

    1. the window honored + the blast radius bounded over BOTH forms (MAXLEN and
       MINID) -- append entries inside AND below a window, trim, assert
       below-window GONE + in-window SURVIVE + the removed-count correct
       (INV1/INV2/INV4);
    2. the `MINID`-floor exactness (INV6) -- the floor `"<ms>-0"` derived from
       `Snowflake.min_for/1`, a `dt - 1ms` entry trimmed while a `dt` entry
       survives (the exact half-open `[dt, ∞)` edge), the floor-ms unit check;
    3. the truthful-read-after-trim (INV3) -- a read of an emptied below-floor
       range answers an honest `[]`, a read spanning the floor returns exactly
       the survivors;
    4. the driver's PURE decision core (the `Pump.Core` precedent -- exhaustive +
       disjoint over the policy forms, `:noop` when nothing is declared) + a trim
       applied on a sweep with NO `StreamConsumer` present (retention decoupled
       from consumer liveness, D-2).

  ## The determinism posture (the load-bearing difference from emq3.3)

  emq3.4 mints NO branded ids in the trim path (the floor derives from a caller
  `DateTime`; the floor-edge entries are minted at CHOSEN milliseconds via
  `Snowflake.min_for/1`, NOT the live clock, so the edge is seed-independent --
  no `Process.sleep` race) and opens NO lease. The same-ms mint hazard that
  mandated emq3.3's >=100 loop is ABSENT -- the posture is a multi-seed sweep +
  an honest statement (the gate ladder), and the driver's tick decision is a
  PURE function of the injected clock, tested directly here. `:valkey`-tagged.
  The per-queue purge rides its OWN disposable connection (the stream key
  emq:{q}:stream:<name> shares the {q} hashtag) -- the stream_test idiom.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.{BrandedId, Snowflake}
  alias EchoMQ.{Connector, Stream}
  alias EchoMQ.StreamRetention.Core

  doctest EchoMQ.StreamRetention.Core

  setup_all do
    :ok = Snowflake.start(8)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    queue = "emq34.rt#{System.unique_integer([:positive])}"

    on_exit(fn ->
      stop_conn(conn)
      purge(queue)
    end)

    %{conn: conn, queue: queue}
  end

  # ---- (1) the window honored + the blast radius bounded over BOTH forms -----

  describe "AS1/AS4 -- MAXLEN window honored, the blast radius bounded (POSITIVE)" do
    test "MAXLEN = N keeps the N newest, removes the older, returns the exact removed-count", ctx do
      %{conn: conn, queue: queue} = ctx
      k = 6
      keep = 2

      # append K records in mint order; capture the receipts (mint order == the
      # sort order, so the last `keep` are the in-window survivors).
      receipts = for i <- 1..k, do: ok!(Stream.append(conn, queue, "ml", [{"seq", "v#{i}"}]))
      {below, in_window} = Enum.split(receipts, k - keep)

      # EXACT trim (`=`): the removed-count is exactly K - keep, and the read-back
      # is exactly the in-window survivors -- a real DELETION and a real SURVIVAL.
      assert {:ok, removed} = Stream.trim(conn, queue, "ml", {:maxlen, keep, false})
      assert removed == k - keep, "removed-count must be exact under ="

      assert {:ok, read} = Stream.read(conn, queue, "ml")
      survivors = for {b, _f} <- read, do: b
      assert survivors == in_window, "the in-window entries must SURVIVE in mint order"
      assert Enum.all?(below, fn b -> b not in survivors end), "every below-window entry must be GONE"
      # over-deletion is a LOUD failure: NO in-window receipt may be missing.
      assert Enum.all?(in_window, fn b -> b in survivors end), "an in-window entry was over-deleted"
    end

    test "MAXLEN ~ (approx, the safe default) keeps AT LEAST the window -- never over-trims", ctx do
      %{conn: conn, queue: queue} = ctx
      k = 8
      keep = 3
      receipts = for i <- 1..k, do: ok!(Stream.append(conn, queue, "mla", [{"seq", "v#{i}"}]))
      in_window = Enum.take(receipts, -keep)

      # approximate trim: it may UNDER-trim (keep extra) but can NEVER OVER-trim.
      assert {:ok, removed} = Stream.trim(conn, queue, "mla", {:maxlen, keep, true})
      assert removed >= 0

      assert {:ok, read} = Stream.read(conn, queue, "mla")
      survivors = for {b, _f} <- read, do: b
      # the safe-direction proof: every in-window entry SURVIVES (approx never
      # removes inside the window), even though approx may keep more than `keep`.
      assert Enum.all?(in_window, fn b -> b in survivors end),
             "approx MAXLEN over-trimmed inside the window (impossible under ~)"
      assert length(survivors) >= keep
    end
  end

  describe "AS1/AS4 -- MINID window honored, the blast radius bounded (POSITIVE)" do
    test "MINID <floor> removes entries below the instant, keeps entries at/above it", ctx do
      %{conn: conn, queue: queue} = ctx
      # a fixed horizon; entries minted 3ms below and 3ms at/above it (CHOSEN
      # milliseconds via min_for/1, appended in ASCENDING mint order -- the only
      # order a single-writer stream can hold: dt-3, dt-2, dt-1, dt, dt+1, dt+2).
      dt = ~U[2025-03-01 12:00:00.500Z]
      below = for d <- 3..1//-1, do: append_at(conn, queue, "mi", shift(dt, -d), 0)
      at_or_above = for d <- 0..2, do: append_at(conn, queue, "mi", shift(dt, d), 0)

      assert {:ok, removed} = Stream.trim(conn, queue, "mi", {:minid, dt, false})
      assert removed == length(below), "MINID = must remove exactly the below-floor entries"

      assert {:ok, read} = Stream.read(conn, queue, "mi")
      survivors = for {b, _f} <- read, do: b
      assert Enum.all?(below, fn b -> b not in survivors end), "a below-floor entry was NOT trimmed"
      assert Enum.all?(at_or_above, fn b -> b in survivors end),
             "an at/above-floor entry was over-deleted (impossible -- the floor is the window edge)"
    end
  end

  # ---- (2) the MINID-floor exactness (INV6) ---------------------------------

  describe "AS2 -- the MINID floor is derived from Snowflake.min_for/1 (the half-open edge)" do
    test "the floor id is \"<ms>-0\" with ms == unix_ms(min_for(dt)) == DateTime.to_unix(dt, :ms)", _ctx do
      dt = ~U[2025-06-15 09:30:00.123Z]
      ms = Snowflake.unix_ms(Snowflake.min_for(dt))

      assert ms == DateTime.to_unix(dt, :millisecond)
      assert Stream.minid_floor(dt) == "#{ms}-0"
      # NEVER the raw snowflake integer to the wire (the wire wants ms-seq).
      refute Stream.minid_floor(dt) == Integer.to_string(Snowflake.min_for(dt))
    end

    test "a dt - 1ms entry is trimmed by MINID(dt) while a dt entry SURVIVES (exact edge)", ctx do
      %{conn: conn, queue: queue} = ctx
      dt = ~U[2025-03-01 12:00:00.000Z]

      # the edge entries: one minted at dt - 1ms (must trim), one at dt (must
      # survive, its ms == the floor ms, tail >= 0 >= the floor's -0).
      _just_below = append_at(conn, queue, "edge", shift(dt, -1), 0)
      at_floor = append_at(conn, queue, "edge", dt, 0)

      assert {:ok, 1} = Stream.trim(conn, queue, "edge", {:minid, dt, false})

      assert {:ok, read} = Stream.read(conn, queue, "edge")
      survivors = for {b, _f} <- read, do: b
      assert survivors == [at_floor], "the half-open [dt, ∞) edge: dt-1ms gone, dt survives"
    end
  end

  # ---- (3) the truthful-read-after-trim (INV3) ------------------------------

  describe "AS-truth -- a read after a trim answers truthfully (never a phantom, never a lie)" do
    test "a read of a fully-trimmed below-floor range returns an honest [] (not an error)", ctx do
      %{conn: conn, queue: queue} = ctx
      dt = ~U[2025-04-01 00:00:00.000Z]
      # entries ONLY below the floor (ascending: dt-3, dt-2, dt-1), then a MINID
      # trim empties them all.
      for d <- 3..1//-1, do: append_at(conn, queue, "tr", shift(dt, -d), 0)
      assert {:ok, 3} = Stream.trim(conn, queue, "tr", {:minid, dt, false})

      # a read of the emptied below-floor range is an honest [] -- never an error,
      # never stale phantom entries.
      below_floor_id = Stream.minid_floor(shift(dt, -1))
      assert {:ok, []} = Stream.read(conn, queue, "tr", "-", below_floor_id)
      # the whole stream is now empty too (everything was below the floor).
      assert {:ok, []} = Stream.read(conn, queue, "tr")
    end

    test "a read spanning the floor returns exactly the surviving at/above-floor entries", ctx do
      %{conn: conn, queue: queue} = ctx
      dt = ~U[2025-04-02 00:00:00.000Z]
      # ascending: dt-2, dt-1 (below) then dt, dt+1, dt+2 (the survivors).
      for d <- 2..1//-1, do: append_at(conn, queue, "sp", shift(dt, -d), 0)
      survivors = for d <- 0..2, do: append_at(conn, queue, "sp", shift(dt, d), 0)
      assert {:ok, 2} = Stream.trim(conn, queue, "sp", {:minid, dt, false})

      # a read over the FULL range now returns only the survivors, in mint order.
      assert {:ok, read} = Stream.read(conn, queue, "sp")
      assert (for {b, _f} <- read, do: b) == survivors
    end
  end

  # ---- the error surfaces (the closed set -- WRONGTYPE surfaced, name raises) -

  describe "the closed error set -- faults surfaced, malformed name raises before any wire" do
    test "a WRONGTYPE against a non-stream key is SURFACED verbatim, not swallowed", ctx do
      %{conn: conn, queue: queue} = ctx
      key = Stream.stream_key(queue, "wt")
      {:ok, _} = Connector.command(conn, ["SET", key, "x"])

      assert {:error, {:error_reply, "WRONGTYPE" <> _}} =
               Stream.trim(conn, queue, "wt", {:maxlen, 1, true})
    end

    test "a malformed (non-binary) stream name raises before any wire (policy before existence)", ctx do
      %{conn: conn, queue: queue} = ctx
      # a non-binary name fails the guard clause -- a raise BEFORE any wire (no
      # XTRIM issued); the stream key for a sibling well-formed name stays absent.
      assert_raise FunctionClauseError, fn ->
        Stream.trim(conn, queue, :not_a_binary, {:maxlen, 1, true})
      end

      key = Stream.stream_key(queue, "never")
      assert {:ok, 0} = Connector.command(conn, ["EXISTS", key])
    end
  end

  # ---- (4) the driver: the pure core + a sweep with NO consumer present ------

  describe "AS3 -- the pure decision core (exhaustive + disjoint, :noop when nothing is due)" do
    test "an empty policy decides :noop; a populated policy maps each to a trim call", _ctx do
      now = ~U[2025-01-01 00:00:00.000Z]
      assert Core.decide([], now) == :noop

      policy = [
        {"q1", "s1", {:maxlen, 100, true}},
        {"q2", "s2", {:minid, ~U[2024-12-31 00:00:00Z], false}}
      ]

      assert Core.decide(policy, now) == [
               {"q1", "s1", {:maxlen, 100, true}},
               {"q2", "s2", {:minid, ~U[2024-12-31 00:00:00Z], false}}
             ]
    end

    test "a RELATIVE {:ago, ms} :minid horizon resolves against the INJECTED clock (pure)", _ctx do
      now = ~U[2025-05-01 12:00:00.000Z]
      # keep the last 60_000ms -> the floor is now - 60s, a pure fn of the clock.
      assert [{"q", "s", {:minid, floor_dt, true}}] =
               Core.decide([{"q", "s", {:minid, {:ago, 60_000}, true}}], now)

      assert floor_dt == DateTime.add(now, -60_000, :millisecond)
    end

    test "a malformed window RAISES at decision time (never a silent skip)", _ctx do
      now = ~U[2025-01-01 00:00:00.000Z]

      assert_raise ArgumentError, ~r/malformed retention window/, fn ->
        Core.decide([{"q", "s", {:bogus, 1}}], now)
      end

      # a negative MAXLEN count is also malformed (guards exhausted -> raise).
      assert_raise ArgumentError, ~r/malformed retention window/, fn ->
        Core.resolve({:maxlen, -1, true}, now)
      end
    end
  end

  describe "AS3 -- the driver sweep applies the declared policy with NO consumer present (D-2)" do
    test "a sweep trims a flooded stream to its declared window, no StreamConsumer running", ctx do
      %{conn: conn, queue: queue} = ctx
      k = 7
      keep = 2
      receipts = for i <- 1..k, do: ok!(Stream.append(conn, queue, "drv", [{"seq", "v#{i}"}]))
      in_window = Enum.take(receipts, -keep)

      # the driver's pure-core+router sweep, driven directly (no cadence, no
      # consumer) -- retention is a property of the STREAM, not of a consumer.
      state = %{
        conn: conn,
        policy: [{queue, "drv", {:maxlen, keep, false}}],
        clock: fn -> DateTime.utc_now() end
      }

      assert {:ok, %{trimmed: trimmed, calls: 1}} = EchoMQ.StreamRetention.sweep(state)
      assert trimmed == k - keep

      assert {:ok, read} = Stream.read(conn, queue, "drv")
      assert (for {b, _f} <- read, do: b) == in_window, "the declared window was applied by the sweep"
    end

    test "an empty-policy sweep is a no-op (no trim, nothing removed)", ctx do
      %{conn: conn, queue: queue} = ctx
      for i <- 1..3, do: ok!(Stream.append(conn, queue, "np", [{"n", "#{i}"}]))

      state = %{conn: conn, policy: [], clock: fn -> DateTime.utc_now() end}
      assert {:ok, %{trimmed: 0, calls: 0}} = EchoMQ.StreamRetention.sweep(state)

      assert {:ok, read} = Stream.read(conn, queue, "np")
      assert length(read) == 3, "an empty policy must trim nothing"
    end
  end

  describe "AS3 -- the named/opt-in driver runs as a transient child and trims on its tick" do
    test "an owner-started driver trims the declared stream on a beat, then stops cleanly", ctx do
      %{conn: conn, queue: queue} = ctx
      k = 5
      keep = 1
      receipts = for i <- 1..k, do: ok!(Stream.append(conn, queue, "tick", [{"seq", "v#{i}"}]))
      newest = List.last(receipts)

      # opt-in, owner-started, decoupled from any consumer: a tight tick so the
      # trim lands inside the test; a SEPARATE conn (the driver owns its own).
      {:ok, driver} =
        EchoMQ.StreamRetention.start_link(
          connector: [port: 6390],
          policy: [{queue, "tick", {:maxlen, keep, false}}],
          tick_ms: 20
        )

      # wait for at least one beat to land the trim (poll the read-back, bounded).
      assert eventually(fn ->
               case Stream.read(conn, queue, "tick") do
                 {:ok, [{^newest, _f}]} -> true
                 _ -> false
               end
             end)

      assert :ok = EchoMQ.StreamRetention.stop(driver)
    end
  end

  # ---- helpers --------------------------------------------------------------

  # Append a record minted at a CHOSEN millisecond instant `dt` (tail `tail`),
  # via the writer's caller-supplied-id path -- so the floor edge is exact and
  # seed-independent (no live-clock race). Returns the branded receipt.
  defp append_at(conn, queue, name, %DateTime{} = dt, tail) when is_integer(tail) and tail >= 0 do
    snow = Snowflake.min_for(dt) + tail
    branded = BrandedId.encode!("EVT", snow)
    ok!(Stream.append_id(conn, queue, name, branded, [{"at", DateTime.to_iso8601(dt)}]))
  end

  defp shift(%DateTime{} = dt, ms), do: DateTime.add(dt, ms, :millisecond)

  defp ok!({:ok, v}), do: v

  # Poll `fun` until it returns true or a bounded number of attempts elapses
  # (a tick-driven assertion, no fixed sleep flake).
  defp eventually(fun, attempts \\ 100) do
    Enum.reduce_while(1..attempts, false, fn _, _ ->
      if fun.() do
        {:halt, true}
      else
        Process.sleep(10)
        {:cont, false}
      end
    end)
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
end
