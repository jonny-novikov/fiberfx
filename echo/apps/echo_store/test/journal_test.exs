defmodule EchoStore.JournalTest do
  @moduledoc """
  The pure column of the Journal row (echo2-migration.md §5) — the exqlite
  side, no wire: the branded-group refusal at start, the intents outbox
  (`record/4` seq, `record_many/2` one-call seq list, `mark_enqueued/2`),
  `stats/1`, `last_applied/2`, persistence across reopen of the same
  dir/group, and `compact/1` retiring nothing over an empty applied table.
  Every test gets a fresh `System.tmp_dir!()` subdir, removed in `on_exit`,
  and a unique journal name (the Journal discipline).
  """
  use ExUnit.Case, async: true

  alias EchoStore.Journal

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  defp fresh_dir do
    dir = Path.join(System.tmp_dir!(), "emq0_journal_#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    dir
  end

  defp open_journal(dir, group) do
    name = :"journal_#{System.unique_integer([:positive])}"
    {:ok, j} = Journal.start_link(name: name, group: group, table: "users", dir: dir)
    j
  end

  defp triple do
    {EchoData.BrandedId.generate!("JOB"), EchoData.BrandedId.generate!("AST"),
     EchoData.BrandedId.generate!("TXN")}
  end

  test "start refuses a non-branded group" do
    Process.flag(:trap_exit, true)
    dir = fresh_dir()

    assert {:error, {%ArgumentError{message: "group must be a branded id"}, _stack}} =
             Journal.start_link(name: :journal_refused, group: "team-a", table: "t", dir: dir)
  end

  test "record/4 returns ascending seqs and stats/1 carries the key set" do
    dir = fresh_dir()
    group = EchoData.BrandedId.generate!("PRT")
    j = open_journal(dir, group)

    {j1, n1, v1} = triple()
    {j2, n2, v2} = triple()

    assert {:ok, 1} = Journal.record(j, j1, n1, v1)
    assert {:ok, 2} = Journal.record(j, j2, n2, v2)

    stats = Journal.stats(j)
    assert stats.intents == 2
    assert stats.pending_enqueue == 2
    assert stats.remembered == 0
    assert stats.path == Path.join(dir, "journal-" <> group <> ".db")
    assert Map.keys(stats) |> Enum.sort() == [:intents, :path, :pending_enqueue, :remembered]

    Journal.stop(j)
  end

  test "record_many/2 answers the seq list from one call" do
    dir = fresh_dir()
    j = open_journal(dir, EchoData.BrandedId.generate!("PRT"))

    triples = for _ <- 1..3, do: triple()
    assert {:ok, [1, 2, 3]} = Journal.record_many(j, triples)
    assert Journal.stats(j).intents == 3

    Journal.stop(j)
  end

  test "mark_enqueued/2 retires the intent from the pending count" do
    dir = fresh_dir()
    j = open_journal(dir, EchoData.BrandedId.generate!("PRT"))

    {job_id, name_id, version} = triple()
    {:ok, _} = Journal.record(j, job_id, name_id, version)
    {:ok, _} = Journal.record(j, elem(triple(), 0), name_id, version)

    assert Journal.stats(j).pending_enqueue == 2
    assert :ok = Journal.mark_enqueued(j, job_id)
    assert Journal.stats(j).pending_enqueue == 1

    Journal.stop(j)
  end

  test "last_applied/2 is nil when the name is unknown" do
    dir = fresh_dir()
    j = open_journal(dir, EchoData.BrandedId.generate!("PRT"))

    assert Journal.last_applied(j, EchoData.BrandedId.generate!("AST")) == nil

    Journal.stop(j)
  end

  test "intents persist across stop and reopen of the same dir and group" do
    dir = fresh_dir()
    group = EchoData.BrandedId.generate!("PRT")

    j = open_journal(dir, group)
    {:ok, _} = Journal.record_many(j, for(_ <- 1..2, do: triple()))
    :ok = Journal.stop(j)

    j2 = open_journal(dir, group)
    assert Journal.stats(j2).intents == 2

    Journal.stop(j2)
  end

  test "compact/1 retires nothing over an empty applied table" do
    dir = fresh_dir()
    j = open_journal(dir, EchoData.BrandedId.generate!("PRT"))

    {:ok, _} = Journal.record_many(j, for(_ <- 1..2, do: triple()))
    assert {:ok, 0} = Journal.compact(j)
    assert Journal.stats(j).intents == 2

    Journal.stop(j)
  end
end
