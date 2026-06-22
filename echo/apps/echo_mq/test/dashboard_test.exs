defmodule EchoMQ.DashboardTest do
  @moduledoc """
  The dashboard renderer, proven OFFLINE against fixture maps — the pure half
  (`render_depths/2`, `render_lanes/2`, `render_job/4`, `render_no_queues/1`,
  `frame/2`) needs no Valkey, so these tests have no `:valkey` tag. A single
  `:valkey`-tagged integration test exercises the live-fetch orchestration end
  to end (seed a job, discover it, render it) under `mix test --include valkey`.
  """
  use ExUnit.Case, async: true

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Dashboard, Jobs}

  setup_all do
    # only the :valkey-tagged live tests touch the snowflake/Valkey; starting
    # the snowflake here is harmless for the pure tests (it mints nothing).
    _ = EchoData.Snowflake.start(4)
    :ok
  end

  defp text(iodata), do: IO.iodata_to_binary(iodata)
  # the visible text with ANSI escapes stripped, for content assertions
  defp plain(iodata), do: text(iodata) |> String.replace(~r/\e\[[0-9;]*m/, "")

  describe "the pure renderer (offline, no Valkey)" do
    test "render_depths/2 lays the six state columns for each queue with the count" do
      fixture = [
        {"orders", {:ok, %{"pending" => 3, "active" => 1, "schedule" => 1, "dead" => 0, "completed" => 7, "failed" => 2}}},
        {"payments", {:ok, %{"pending" => 0, "active" => 0, "schedule" => 0, "dead" => 0, "completed" => 0, "failed" => 0}}}
      ]

      out = Dashboard.render_depths(fixture, "2026-06-22 00:00:00Z")
      plain = plain(out)

      # the header frame, the section, both queue names, and the column labels
      assert plain =~ "EchoMQ · queue depths"
      assert plain =~ "▌ DEPTHS"
      assert plain =~ "orders"
      assert plain =~ "payments"

      for st <- Dashboard.states(), do: assert(plain =~ st)

      # the orders row reports its counts (3 pending, 7 completed, 2 failed)
      [orders_line] = for l <- String.split(plain, "\n"), String.contains?(l, "orders"), do: l
      assert orders_line =~ "3"
      assert orders_line =~ "7"
      assert orders_line =~ "2"
    end

    test "render_depths/2 colors a non-zero state and dims a zero" do
      fixture = [{"q", {:ok, %{"pending" => 5, "active" => 0, "schedule" => 0, "dead" => 0, "completed" => 0, "failed" => 0}}}]
      out = text(Dashboard.render_depths(fixture, "t"))

      # pending non-zero uses the cyan ink \e[36m; a zero column carries the grey \e[90m
      assert out =~ "\e[36m5\e[0m"
      assert out =~ "\e[90m0\e[0m"
    end

    test "render_depths/2 surfaces a {:error, _} queue in red, never a fake zero" do
      fixture = [{"broken", {:error, :timeout}}]
      out = text(Dashboard.render_depths(fixture, "t"))

      assert out =~ "\e[31m"
      assert out =~ "read error"
      assert out =~ ":timeout"
      # it must NOT have invented a zero row of six columns
      refute plain(out) =~ "broken                     0"
    end

    test "render_no_queues/1 names the empty bus, does not fake an empty table" do
      out = plain(Dashboard.render_no_queues("t"))
      assert out =~ "no keyed queues found"
      assert out =~ "invisible to SCAN"
    end

    test "render_job/4 shows the id, the colored state atom, attempts and payload" do
      result = {:ok, %{state: :active, attempts: "2", payload: "process order #42"}}
      out = Dashboard.render_job("orders", "JOBabcDEF1234", result, "t")
      plain = plain(out)

      assert plain =~ "▌ JOB"
      assert plain =~ "JOBabcDEF1234"
      assert plain =~ "active"
      assert plain =~ "2"
      assert plain =~ "process order #42"
      # the state atom is colored (active → yellow \e[33m)
      assert text(out) =~ "\e[33mactive\e[0m"
    end

    test "render_job/4 colors the scheduled / awaiting_children / unknown atoms distinctly" do
      sched = text(Dashboard.render_job("q", "JOBx", {:ok, %{state: :scheduled, attempts: "0", payload: ""}}, "t"))
      await = text(Dashboard.render_job("q", "JOBx", {:ok, %{state: :awaiting_children, attempts: "0", payload: ""}}, "t"))
      unk = text(Dashboard.render_job("q", "JOBx", {:ok, %{state: :unknown, attempts: "0", payload: ""}}, "t"))

      assert sched =~ "\e[34mscheduled\e[0m"
      assert await =~ "\e[35mawaiting_children\e[0m"
      assert unk =~ "\e[90munknown\e[0m"
    end

    test "render_job/4 names the :absent and {:error,_} cases, never faking a row" do
      absent = plain(Dashboard.render_job("orders", "JOBmissing", :absent, "t"))
      assert absent =~ "not found in queue orders"
      assert absent =~ "JOBmissing"

      err = text(Dashboard.render_job("orders", "JOBx", {:error, :boom}, "t"))
      assert err =~ "\e[31m"
      assert err =~ "read error"
      assert err =~ ":boom"
    end

    test "render_job/4 names a malformed (non-branded) job id, never a stacktrace" do
      out = Dashboard.render_job("q", "not-a-branded-id", {:error, {:invalid_job_id, "not-a-branded-id"}}, "t")
      plain = plain(out)
      assert plain =~ "not a valid branded id"
      assert plain =~ "not-a-branded-id"
      assert text(out) =~ "\e[31m"
    end

    test "render_job/4 truncates a long payload with an ellipsis" do
      long = String.duplicate("z", 200)
      out = plain(Dashboard.render_job("q", "JOBx", {:ok, %{state: :pending, attempts: "0", payload: long}}, "t"))
      assert out =~ "…"
      refute out =~ String.duplicate("z", 200)
    end

    test "render_lanes/2 renders active groups with pending depth, and names a no-lane queue" do
      fixture = [
        {"orders", {:ok, %{"PRTaaa" => 3, "PRTbbb" => 0}}},
        {"payments", {:ok, %{}}},
        {"idle", :none}
      ]

      out = Dashboard.render_lanes(fixture, "t")
      plain = plain(out)

      assert plain =~ "▌ LANES"
      assert plain =~ "PRTaaa"
      assert plain =~ "3"
      # the payments queue has gactive but an empty depth map → named
      assert plain =~ "no active lanes"
      # the :none queue contributes no row at all (not even its name in a lane row)
      refute plain =~ "idle\n"
    end

    test "render_lanes/2 with only :none queues renders nothing (no empty section)" do
      assert Dashboard.render_lanes([{"a", :none}, {"b", :none}], "t") == []
    end

    test "frame/2 draws the boxed cyan header" do
      out = text(Dashboard.frame("title", "subtitle"))
      assert out =~ "\e[1;36m"
      assert out =~ "╔"
      assert out =~ "╗"
      assert out =~ "╚"
      assert out =~ "╝"
      assert plain(out) =~ "title"
      assert plain(out) =~ "subtitle"
    end

    test "states/0 is the closed six-state set in display order" do
      assert Dashboard.states() == ~w(pending active schedule dead completed failed)
    end
  end

  # -- the live-fetch orchestration (Valkey on 6390) ------------------------

  describe "the live path (integration)" do
    @describetag :valkey

    setup do
      {:ok, conn} = Connector.start_link(port: 6390)
      q = "emq.dashboard#{System.unique_integer([:positive])}"
      on_exit(fn -> purge(q) end)
      %{conn: conn, q: q}
    end

    test "fetch_depths/2 reports a seeded job as pending=1", %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "cargo")

      assert {:ok, counts} = Dashboard.fetch_depths(conn, q)
      assert counts["pending"] == 1
      assert counts["active"] == 0

      # and the rendered table contains the queue + a 1
      out = IO.iodata_to_binary(Dashboard.render_depths([{q, {:ok, counts}}], "t"))
      assert out =~ q
    end

    test "discover_queues/1 finds a seeded queue and excludes the {emq} fence", %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "cargo")

      assert {:ok, queues} = Dashboard.discover_queues(conn)
      assert q in queues
      refute "emq" in queues
    end

    test "fetch_job/3 reconciles the row with the membership atom for a seeded job", %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "process me")

      assert {:ok, info} = Dashboard.fetch_job(conn, q, id)
      assert info.state == :pending
      assert info.attempts == "0"
      assert info.payload == "process me"

      # claim it → the membership atom flips to :active, attempts → 1
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
      assert {:ok, claimed} = Dashboard.fetch_job(conn, q, id)
      assert claimed.state == :active
      assert claimed.attempts == "1"
    end

    test "fetch_job/3 answers :absent for an unknown id", %{conn: conn, q: q} do
      assert :absent = Dashboard.fetch_job(conn, q, BrandedId.generate!("JOB"))
    end

    test "fetch_job/3 names a malformed id rather than raising (the gated key builder)", %{conn: conn, q: q} do
      assert {:error, {:invalid_job_id, "garbage"}} = Dashboard.fetch_job(conn, q, "garbage")
    end

    test "fetch_lanes/2 answers :none when the queue has no active groups", %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "x")
      # a flat (non-grouped) job populates no gactive hash
      assert :none = Dashboard.fetch_lanes(conn, q)
    end
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end
end
