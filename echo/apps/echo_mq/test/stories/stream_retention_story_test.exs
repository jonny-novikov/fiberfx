defmodule EchoMQ.Stories.StreamRetentionStoryTest do
  @moduledoc """
  Acceptance criteria for **Stream retention** (emq3.4, S2 the readers part 2) —
  retention as policy over a per-key event stream: `EchoMQ.Stream.trim/4` bounds
  a stream to a DECLARED window over `XTRIM` issued direct, and the named,
  opt-in `EchoMQ.StreamRetention` driver re-applies that window on its own beat.

  The rung's whole point is that retention is a DESTRUCTIVE op whose blast
  radius is bounded by the declared window: a trim removes ONLY entries OUTSIDE
  the window (older than the newest-N, or minted before a mint-instant floor) and
  can NEVER delete an entry inside it. So every scenario below proves a real
  DELETION (below-window entries gone) AND a real SURVIVAL (in-window receipts
  still read back) in the same verdict — a trim that deletes nothing proves
  nothing about retention, and a trim that deletes everything proves nothing
  about the bound. Retention is a property of the STREAM, not of a consumer: a
  stream nobody drains still trims (the driver is decoupled from consumer
  liveness, D-2), and a manual `trim/4` call is the equally-supported cadence.

  Written in the `EchoMQ.Story` BDD DSL: every scenario below is a real ExUnit
  test driving `EchoMQ.Stream` / `EchoMQ.StreamRetention` against Valkey on 6390,
  AND the source of `docs/echo_mq/stories/stream-retention.stories.md` (generated
  by `mix echo_mq.stories`). The exhaustive `:valkey` coverage (both window forms,
  the half-open MINID edge, the truthful-read-after-trim, the pure decision core)
  lives in `test/stream_retention_test.exs`; the conformance proof is the
  `stream_retention` scenario (`EchoMQ.Conformance`). The MINID-floor entries are
  minted at CHOSEN milliseconds via `EchoData.Snowflake.min_for/1` (NOT the live
  clock), so the half-open `[dt, ∞)` edge is exact and seed-independent — no
  real-time sleep gates a verdict.
  """
  use EchoMQ.Story, feature: "Stream retention", async: false

  @moduletag :valkey

  alias EchoData.{BrandedId, Snowflake}
  alias EchoMQ.{Connector, Stream, StreamRetention}

  setup_all do
    :ok = Snowflake.start(8)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq.story.retention#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  scenario "a MAXLEN trim keeps the newest entries and removes the older, never deleting inside the window",
           %{conn: conn, q: q} do
    given_ "a stream flooded with six EVT records appended in mint order" do
      receipts = for i <- 1..6, do: ok!(Stream.append(conn, q, "ml", [{"seq", "v#{i}"}]))
      {below, in_window} = Enum.split(receipts, 4)
    end

    when_ "trim/4 keeps the two newest with an EXACT MAXLEN window" do
      {:ok, removed} = Stream.trim(conn, q, "ml", {:maxlen, 2, false})
    end

    then_ "exactly the four oldest are removed and the two newest SURVIVE a read-back (the bound held)" do
      assert removed == 4
      {:ok, read} = Stream.read(conn, q, "ml")
      survivors = for {b, _f} <- read, do: b
      assert survivors == in_window, "the in-window entries must survive in mint order"
      assert Enum.all?(below, fn b -> b not in survivors end), "every below-window entry must be gone"
    end
  end

  scenario "a MINID trim removes entries minted before a mint instant and keeps those at or after it",
           %{conn: conn, q: q} do
    given_ "a stream with three records minted below a horizon and three at or above it (ascending)" do
      dt = ~U[2025-03-01 12:00:00.500Z]
      below = for d <- 3..1//-1, do: append_at(conn, q, "mi", DateTime.add(dt, -d, :millisecond))
      at_or_above = for d <- 0..2, do: append_at(conn, q, "mi", DateTime.add(dt, d, :millisecond))
    end

    when_ "trim/4 trims by MINID(horizon), the floor derived from Snowflake.min_for/1" do
      {:ok, removed} = Stream.trim(conn, q, "mi", {:minid, dt, false})
    end

    then_ "the below-instant records are GONE and the at/above-instant records SURVIVE (the half-open [dt, ∞) edge)" do
      assert removed == length(below)
      {:ok, read} = Stream.read(conn, q, "mi")
      survivors = for {b, _f} <- read, do: b
      assert Enum.all?(below, fn b -> b not in survivors end), "a below-floor entry was not trimmed"
      assert Enum.all?(at_or_above, fn b -> b in survivors end), "an at/above-floor entry was over-deleted"
    end
  end

  scenario "the blast radius is bounded by the declared window — an in-window entry survives a trim",
           %{conn: conn, q: q} do
    given_ "a stream flooded with eight records and one in-window entry tracked by its receipt" do
      receipts = for i <- 1..8, do: ok!(Stream.append(conn, q, "br", [{"seq", "v#{i}"}]))
      tracked = List.last(receipts)
    end

    when_ "trim/4 keeps the newest three (the tracked newest is inside the window)" do
      {:ok, _removed} = Stream.trim(conn, q, "br", {:maxlen, 3, false})
    end

    then_ "the tracked in-window entry still reads back — over-deletion would be a LOUD failure" do
      {:ok, read} = Stream.read(conn, q, "br")
      survivors = for {b, _f} <- read, do: b
      assert tracked in survivors, "the in-window entry was over-deleted (impossible under a correct trim)"
    end
  end

  scenario "retention is a property of the stream — the opt-in driver trims with no consumer present",
           %{conn: conn, q: q} do
    given_ "a flooded stream and a declared per-stream policy held BEAM-side (no keyspace subkey)" do
      receipts = for i <- 1..7, do: ok!(Stream.append(conn, q, "drv", [{"seq", "v#{i}"}]))
      newest = List.last(receipts)
      policy = [{q, "drv", {:maxlen, 1, false}}]
    end

    when_ "a named, owner-started trim driver sweeps the declared policy (NO StreamConsumer running)" do
      {:ok, %{trimmed: trimmed, calls: 1}} =
        StreamRetention.sweep(%{conn: conn, policy: policy, clock: fn -> DateTime.utc_now() end})
    end

    then_ "the stream is trimmed to its window even though nothing drains it (retention decoupled from liveness)" do
      assert trimmed == 6
      {:ok, read} = Stream.read(conn, q, "drv")
      assert (for {b, _f} <- read, do: b) == [newest], "the declared window was applied with no consumer"
    end
  end

  # ---- helpers --------------------------------------------------------------

  # append an EVT record minted at a CHOSEN millisecond instant `dt` via the
  # writer's caller-supplied-id path (Snowflake.min_for/1 -> the snowflake at
  # dt's ms, tail 0) -- so the floor edge is exact and seed-independent.
  defp append_at(conn, q, name, %DateTime{} = dt) do
    branded = BrandedId.encode!("EVT", Snowflake.min_for(dt))
    ok!(Stream.append_id(conn, q, name, branded, [{"at", DateTime.to_iso8601(dt)}]))
  end

  defp ok!({:ok, v}), do: v

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])

    try do
      GenServer.stop(conn)
    catch
      :exit, _ -> :ok
    end
  end
end
