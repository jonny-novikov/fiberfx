defmodule EchoCache.ShadowCopyTest do
  @moduledoc """
  The EchoCache.Shadow.Copy extension row (the agent brief, Stage-1c):
  SQLite-bound, wire-free. Determinism is driven through the forced
  `sync/1` only — `every_ms` is set far beyond the test's life so the
  periodic `:tick` never fires (the hazards bank). Each test gets fresh
  `System.tmp_dir!()` subdirs, removed in `on_exit`.
  """
  use ExUnit.Case, async: true

  alias EchoCache.Shadow.Copy
  alias Exqlite.Sqlite3

  @quiet_ms 600_000

  defp fresh_dirs do
    base = Path.join(System.tmp_dir!(), "emq0_copy_#{System.unique_integer([:positive])}")
    live_dir = Path.join(base, "live")
    rep_dir = Path.join(base, "replica")
    File.mkdir_p!(live_dir)
    File.mkdir_p!(rep_dir)
    on_exit(fn -> File.rm_rf!(base) end)
    {Path.join(live_dir, "journal-test.db"), rep_dir}
  end

  defp seed_rows(path, range) do
    {:ok, c} = Sqlite3.open(path)
    :ok = Sqlite3.execute(c, "CREATE TABLE IF NOT EXISTS rows(id INTEGER PRIMARY KEY, v TEXT)")

    for i <- range do
      :ok = Sqlite3.execute(c, "INSERT INTO rows(id, v) VALUES(#{i}, 'row-#{i}')")
    end

    :ok = Sqlite3.close(c)
  end

  defp count_rows(path) do
    {:ok, c} = Sqlite3.open(path)
    {:ok, st} = Sqlite3.prepare(c, "SELECT count(*) FROM rows")
    {:row, [n]} = Sqlite3.step(c, st)
    :ok = Sqlite3.release(c, st)
    :ok = Sqlite3.close(c)
    n
  end

  defp drop_live(db) do
    File.rm!(db)
    File.rm(db <> "-wal")
    File.rm(db <> "-shm")
  end

  test "init raises KeyError on a missing :db or :dir" do
    Process.flag(:trap_exit, true)
    {db, dir} = fresh_dirs()

    assert {:error, {%KeyError{key: :dir}, _stack}} = Copy.start_link(db: db)
    assert {:error, {%KeyError{key: :db}, _stack}} = Copy.start_link(dir: dir)
  end

  test "replica_path/2 joins the directory with the database's basename" do
    assert Copy.replica_path("/data/journals/journal-PRT123.db", "/backups") ==
             "/backups/journal-PRT123.db"
  end

  test "restore/1 over a live file answers :no_replica and leaves it byte-identical (SH3)" do
    {db, dir} = fresh_dirs()
    seed_rows(db, 1..3)
    before_bytes = File.read!(db)

    assert Copy.restore(db: db, dir: dir) == {:ok, :no_replica}
    assert File.read!(db) == before_bytes
  end

  test "restore/1 with nothing behind answers :no_replica and writes nothing (SH3)" do
    {db, dir} = fresh_dirs()

    assert Copy.restore(db: db, dir: dir) == {:ok, :no_replica}
    refute File.exists?(db)
  end

  test "restore/1 copies the snapshot back when the live file is missing" do
    {db, dir} = fresh_dirs()
    seed_rows(Path.join(dir, Path.basename(db)), 1..2)

    assert Copy.restore(db: db, dir: dir) == {:ok, :restored}
    assert File.exists?(db)
    assert count_rows(db) == 2
  end

  test "forced sync/1 snapshots, counts, and status/1 carries the key set" do
    {db, dir} = fresh_dirs()
    seed_rows(db, 1..3)

    {:ok, sh} = Copy.start_link(db: db, dir: dir, every_ms: @quiet_ms)

    assert Copy.status(sh) == %{db: db, dir: dir, every_ms: @quiet_ms, syncs: 0, last_error: nil}

    assert :ok = Copy.sync(sh)

    status = Copy.status(sh)
    assert status.syncs == 1
    assert status.last_error == nil
    assert File.exists?(Copy.replica_path(db, dir))

    assert :ok = Copy.stop(sh)
  end

  test "the SH2 cycle: rows written, one sync, the live file lost, restore brings the count back exactly" do
    {db, dir} = fresh_dirs()
    seed_rows(db, 1..3)

    {:ok, sh} = Copy.start_link(db: db, dir: dir, every_ms: @quiet_ms)
    assert :ok = Copy.sync(sh)
    assert :ok = Copy.stop(sh)

    drop_live(db)
    refute File.exists?(db)

    assert Copy.restore(db: db, dir: dir) == {:ok, :restored}
    assert count_rows(db) == 3
  end

  test "the SH4 follow: a second sync after more rows carries them" do
    {db, dir} = fresh_dirs()
    seed_rows(db, 1..3)

    {:ok, sh} = Copy.start_link(db: db, dir: dir, every_ms: @quiet_ms)
    assert :ok = Copy.sync(sh)

    seed_rows(db, 4..5)
    assert :ok = Copy.sync(sh)
    assert Copy.status(sh).syncs == 2
    assert :ok = Copy.stop(sh)

    drop_live(db)
    assert Copy.restore(db: db, dir: dir) == {:ok, :restored}
    assert count_rows(db) == 5
  end

  test "a snapshot is a no-op when the live file is absent" do
    {db, dir} = fresh_dirs()

    {:ok, sh} = Copy.start_link(db: db, dir: dir, every_ms: @quiet_ms)

    assert :ok = Copy.sync(sh)
    assert Copy.status(sh).syncs == 0
    refute File.exists?(Copy.replica_path(db, dir))

    assert :ok = Copy.stop(sh)
  end
end
