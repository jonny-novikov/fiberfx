defmodule EchoStore.TableTest do
  @moduledoc """
  The wire column of the Table row (echo2-migration.md §5). The table's
  init starts its own Connector (table.ex:207), so every test here needs
  the live wire — no pure Table test exists. Tables carry per-test names
  and table strings; the owner traps exits and follows the dying test
  process down, so teardown catches the already-dead exit.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoStore.{Coherence, Keyspace, Table}
  alias EchoData.BrandedId
  alias EchoMQ.Connector

  @conn_opts [port: 6390]

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    suffix = System.unique_integer([:positive])
    table = "emq0tbl#{suffix}"

    # the conn dies with the test process (the OTP parent-exit protocol),
    # so the purge rides its own disposable connection
    on_exit(fn -> purge("ecc:{" <> table <> "}:*") end)

    %{conn: conn, table: table, suffix: suffix}
  end

  defp purge(pattern) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", pattern])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  defp start_table(ctx, opts) do
    name = :"emq0_table_#{ctx.suffix}_#{System.unique_integer([:positive])}"

    defaults = [
      name: name,
      kind: "AST",
      loader: fn _id -> {:ok, "loaded"} end,
      connector: @conn_opts,
      table: ctx.table,
      ttl_ms: 60_000,
      sweep_ms: 30_000,
      jitter: 0.0
    ]

    {:ok, _pid} = Table.start_link(Keyword.merge(defaults, opts))

    on_exit(fn ->
      try do
        Table.stop(name)
      catch
        :exit, _ -> :ok
      end
    end)

    name
  end

  defp wait_until(pred, tries \\ 400) do
    cond do
      pred.() -> :ok
      tries == 0 -> flunk("condition never held")
      true ->
        Process.sleep(5)
        wait_until(pred, tries - 1)
    end
  end

  test "fetch/3 fills once, then hits, with the counters moving", ctx do
    name = start_table(ctx, [])
    id = BrandedId.generate!("AST")

    assert {:ok, "loaded", :fill} = Table.fetch(name, id)
    assert {:ok, "loaded", :hit} = Table.fetch(name, id)

    stats = Table.stats(name)
    assert stats.misses == 1
    assert stats.fills == 1
    assert stats.hits == 1
    assert stats.size == 1
  end

  test "fetch/3 serves a framed L2 row as :l2", ctx do
    name = start_table(ctx, [])
    id = BrandedId.generate!("AST")
    version = BrandedId.generate!("AST")

    {:ok, "OK"} =
      Connector.command(ctx.conn, ["SET", Keyspace.key(ctx.table, id), version <> "from-l2"])

    assert {:ok, "from-l2", :l2} = Table.fetch(name, id)
    assert Table.stats(name).l2_hits == 1
  end

  test "fetch/3 refuses a wrong-namespace id at the door", ctx do
    name = start_table(ctx, [])

    assert Table.fetch(name, BrandedId.generate!("USR")) == {:error, :kind}
    assert Table.fetch(name, "junk") == {:error, :kind}
  end

  test "put/3 mints a version of the table's kind; put/4 carries the writer's", ctx do
    name = start_table(ctx, [])
    id = BrandedId.generate!("AST")
    own_version = BrandedId.generate!("TXN")

    assert :ok = Table.put(name, id, "minted")
    assert {:ok, "minted", :hit} = Table.fetch(name, id)

    assert :ok = Table.put(name, id, "carried", own_version)
    {:ok, <<framed::binary-14, "carried">>} =
      Connector.command(ctx.conn, ["GET", Keyspace.key(ctx.table, id)])

    assert framed == own_version
  end

  test "apply_coherence/4 drops on newer and answers :stale on reapplication", ctx do
    name = start_table(ctx, [])
    id = BrandedId.generate!("AST")
    v1 = BrandedId.generate!("TXN")
    Process.sleep(2)
    v2 = BrandedId.generate!("TXN")

    :ok = Table.put(name, id, "row", v1)

    assert {:ok, :applied} = Table.apply_coherence(name, id, v2)
    assert {:ok, :stale} = Table.apply_coherence(name, id, v2)

    stats = Table.stats(name)
    assert stats.coh_applied == 1
    assert stats.coh_stale == 1
  end

  test "invalidate/3 drops the name from both layers", ctx do
    name = start_table(ctx, [])
    id = BrandedId.generate!("AST")

    :ok = Table.put(name, id, "doomed")
    assert {:ok, 1} = Connector.command(ctx.conn, ["EXISTS", Keyspace.key(ctx.table, id)])

    assert :ok = Table.invalidate(name, id)
    assert {:ok, 0} = Connector.command(ctx.conn, ["EXISTS", Keyspace.key(ctx.table, id)])
    assert Table.stats(name).size == 0
  end

  test "the sweeper reclaims expired rows on its tick", ctx do
    name = start_table(ctx, ttl_ms: 40, sweep_ms: 30)
    id = BrandedId.generate!("AST")

    :ok = Table.put(name, id, "ephemeral")
    assert Table.stats(name).size == 1

    wait_until(fn ->
      stats = Table.stats(name)
      stats.size == 0 and stats.swept >= 1
    end)
  end

  test "a full table degrades to pass-through, counted", ctx do
    name = start_table(ctx, max_size: 1)
    resident = BrandedId.generate!("AST")
    overflow = BrandedId.generate!("AST")

    :ok = Table.put(name, resident, "resident")

    assert {:ok, "loaded", :fill} = Table.fetch(name, overflow)

    stats = Table.stats(name)
    assert stats.full_skips >= 1
    assert stats.size == 1

    # the overflow row was served, not cached in L1 — the refetch reads L2
    assert {:ok, "loaded", :l2} = Table.fetch(name, overflow)
  end

  test "concurrent misses coalesce onto a single flight", ctx do
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    loader = fn _id ->
      Agent.update(calls, &(&1 + 1))
      Process.sleep(150)
      {:ok, "herd"}
    end

    name = start_table(ctx, loader: loader)
    id = BrandedId.generate!("AST")

    results =
      1..8
      |> Enum.map(fn _ -> Task.async(fn -> Table.fetch(name, id) end) end)
      |> Task.await_many(5_000)

    assert Enum.all?(results, &(&1 == {:ok, "herd", :fill}))
    assert Agent.get(calls, & &1) == 1
    assert Table.stats(name).coalesced == 7
  end

  test "coherence: :broadcast end-to-end — a second instance drops its row", ctx do
    name_a = start_table(ctx, coherence: :broadcast)
    name_b = start_table(ctx, coherence: :broadcast)

    id = BrandedId.generate!("AST")
    v1 = BrandedId.generate!("TXN")
    Process.sleep(2)
    v2 = BrandedId.generate!("TXN")

    :ok = Table.put(name_a, id, "row", v1)
    :ok = Table.put(name_b, id, "row", v1)
    assert {:ok, "row", :hit} = Table.fetch(name_b, id)

    {:ok, 2} = Coherence.broadcast(ctx.conn, ctx.table, id, v2)

    wait_until(fn -> Table.stats(name_b).coh_applied >= 1 end)
    wait_until(fn -> Table.stats(name_a).coh_applied >= 1 end)

    assert :ets.lookup(name_b, id) == []
  end

  test "coherence: :tracking — an external write evicts the L1 row (server-assisted)", ctx do
    name = start_table(ctx, coherence: :tracking)
    id = BrandedId.generate!("AST")
    far = System.monotonic_time(:millisecond) + 600_000

    # a row this cache holds (seeded directly, so no L2 write of ours can
    # self-invalidate it under BCAST)
    :ets.insert(name, {id, "row", far, BrandedId.generate!("TXN")})
    assert match?([{^id, "row", _, _}], :ets.lookup(name, id))

    # an external writer changes the tracked key on its own connection; the
    # server pushes the invalidation to the table's tracking lane
    {:ok, "OK"} =
      Connector.command(ctx.conn, [
        "SET",
        Keyspace.key(ctx.table, id),
        BrandedId.generate!("TXN") <> "row2"
      ])

    wait_until(fn -> :ets.lookup(name, id) == [] end)
    assert :ets.lookup(name, id) == []
  end

  test "coherence: :tracking — a flush push (nil keys) drops every row", ctx do
    name = start_table(ctx, coherence: :tracking)
    far = System.monotonic_time(:millisecond) + 600_000

    for _ <- 1..3,
        do: :ets.insert(name, {BrandedId.generate!("AST"), "v", far, BrandedId.generate!("TXN")})

    assert :ets.info(name, :size) == 3
    send(Process.whereis(name), {:emq_push, ["invalidate", nil]})

    wait_until(fn -> :ets.info(name, :size) == 0 end)
    assert :ets.info(name, :size) == 0
  end

  test "coherence: :tracking — a reconnect flushes L1 and tracking still evicts after", ctx do
    name = start_table(ctx, coherence: :tracking)
    far = System.monotonic_time(:millisecond) + 600_000

    :ets.insert(name, {BrandedId.generate!("AST"), "v", far, BrandedId.generate!("TXN")})
    assert :ets.info(name, :size) == 1

    # the reconnect signal flushes L1 (the gap may have dropped invalidations)
    send(Process.whereis(name), :retrack)
    wait_until(fn -> :ets.info(name, :size) == 0 end)
    assert :ets.info(name, :size) == 0

    # and tracking still evicts an external write afterward
    id = BrandedId.generate!("AST")
    :ets.insert(name, {id, "v2", far, BrandedId.generate!("TXN")})

    {:ok, "OK"} =
      Connector.command(ctx.conn, [
        "SET",
        Keyspace.key(ctx.table, id),
        BrandedId.generate!("TXN") <> "x"
      ])

    wait_until(fn -> :ets.lookup(name, id) == [] end)
    assert :ets.lookup(name, id) == []
  end

  test "stats/1 carries the counter names plus the live size", ctx do
    name = start_table(ctx, [])

    assert Map.keys(Table.stats(name)) |> Enum.sort() == [
             :coalesced,
             :coh_applied,
             :coh_stale,
             :fills,
             :full_skips,
             :hits,
             :l2_hits,
             :misses,
             :size,
             :sweeps,
             :swept
           ]
  end

  test "an undeclared cache answers :no_such_cache" do
    assert Table.fetch(:emq0_never_declared, "anything") == {:error, :no_such_cache}
  end
end
