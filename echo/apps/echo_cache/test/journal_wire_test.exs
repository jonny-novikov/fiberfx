defmodule EchoCache.JournalWireTest do
  @moduledoc """
  The wire column of the Journal row (echo2-migration.md §5): the outbox
  verb `intend_and_enqueue/4`, `replay/2`'s counts riding the bus's
  admission dedup, `apply_and_remember/4`'s memory beside a live Table,
  and `handler/2` over a Consumer — the full lane.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoCache.{Coherence, Journal, Table}
  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Consumer, Lanes}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    suffix = System.unique_integer([:positive])
    table = "emq0jrn#{suffix}"
    dir = Path.join(System.tmp_dir!(), "emq0_jwire_#{suffix}")
    group = BrandedId.generate!("PRT")

    {:ok, j} =
      Journal.start_link(
        name: :"journal_wire_#{suffix}",
        group: group,
        table: table,
        dir: dir
      )

    on_exit(fn -> File.rm_rf!(dir) end)

    # the conn dies with the test process (the OTP parent-exit protocol),
    # so the purge rides its own disposable connection
    on_exit(fn ->
      purge(["emq:{" <> Coherence.queue(table) <> "}:*", "ecc:{" <> table <> "}:*"])
    end)

    on_exit(fn ->
      try do
        Journal.stop(j)
      catch
        :exit, _ -> :ok
      end
    end)

    %{conn: conn, j: j, table: table, group: group, suffix: suffix, queue: Coherence.queue(table)}
  end

  defp purge(patterns) do
    {:ok, conn} = Connector.start_link(port: 6390)

    for pattern <- patterns do
      {:ok, keys} = Connector.command(conn, ["KEYS", pattern])
      if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    end

    GenServer.stop(conn)
  end

  defp start_table(ctx) do
    name = :"emq0_jrn_table_#{ctx.suffix}"

    {:ok, _pid} =
      Table.start_link(
        name: name,
        kind: "AST",
        loader: fn _id -> {:ok, "loaded"} end,
        connector: [port: 6390],
        table: ctx.table,
        ttl_ms: 60_000,
        sweep_ms: 30_000,
        jitter: 0.0
      )

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

  test "intend_and_enqueue/4 records, enqueues on the lane, and marks", ctx do
    name_id = BrandedId.generate!("AST")
    version = BrandedId.generate!("TXN")

    assert {:ok, job_id} = Journal.intend_and_enqueue(ctx.j, ctx.conn, name_id, version)
    assert binary_part(job_id, 0, 3) == "JOB"

    stats = Journal.stats(ctx.j)
    assert stats.intents == 1
    assert stats.pending_enqueue == 0

    expected_payload = Coherence.payload(name_id, version)
    group = ctx.group
    assert {:ok, {^job_id, ^expected_payload, 1, ^group}} = Lanes.claim(ctx.conn, ctx.queue, 60_000)
  end

  test "replay/2 re-enqueues uncovered intents and the bus dedups the second pass", ctx do
    triples =
      for _ <- 1..3 do
        {BrandedId.generate!("JOB"), BrandedId.generate!("AST"), BrandedId.generate!("TXN")}
      end

    {:ok, _seqs} = Journal.record_many(ctx.j, triples)
    assert Journal.stats(ctx.j).pending_enqueue == 3

    assert {:ok, %{replayed: 3, deduplicated: 0}} = Journal.replay(ctx.j, ctx.conn)
    assert Journal.stats(ctx.j).pending_enqueue == 0

    # the jobs still sit on the bus: the second pass is absorbed by admission dedup
    assert {:ok, %{replayed: 0, deduplicated: 3}} = Journal.replay(ctx.j, ctx.conn)
  end

  test "apply_and_remember/4 remembers, refuses stale without touching the table, passes newer through",
       ctx do
    tname = start_table(ctx)
    name_id = BrandedId.generate!("AST")

    [v1, v2, v3] =
      for _ <- 1..3 do
        Process.sleep(2)
        BrandedId.generate!("TXN")
      end

    # first application: nothing remembered — the table answers (row absent -> :stale)
    assert {:ok, :stale} = Journal.apply_and_remember(ctx.j, tname, name_id, v2)
    assert Journal.last_applied(ctx.j, name_id) == v2

    # stale against the memory: answered from the journal, the table untouched
    before_stats = Table.stats(tname)
    assert {:ok, :remembered_stale} = Journal.apply_and_remember(ctx.j, tname, name_id, v1)
    assert Table.stats(tname) == before_stats
    assert Journal.last_applied(ctx.j, name_id) == v2

    # newer passes through: the table drops its row and the memory advances
    :ok = Table.put(tname, name_id, "row", v2)
    assert {:ok, :applied} = Journal.apply_and_remember(ctx.j, tname, name_id, v3)
    assert Journal.last_applied(ctx.j, name_id) == v3
  end

  test "handler/2 over a Consumer rides the job lane into the memory", ctx do
    tname = start_table(ctx)
    name_id = BrandedId.generate!("AST")
    version = BrandedId.generate!("TXN")

    {:ok, consumer} =
      Consumer.start_link(
        queue: ctx.queue,
        handler: Journal.handler(ctx.j, tname),
        connector: [port: 6390],
        beat_ms: 50,
        lease_ms: 5_000
      )

    assert {:ok, _job_id} = Journal.intend_and_enqueue(ctx.j, ctx.conn, name_id, version)

    wait_until(fn -> Journal.last_applied(ctx.j, name_id) == version end)

    assert :ok = Consumer.stop(consumer)
  end
end
