defmodule EchoCache.Journal do
  @moduledoc """
  The lane that remembers: a per-group SQLite journal standing beside the
  bus, never inside it. The bus stays volatile by decision D-2; durability
  for the job lane's obligations lives here, at the two edges where it is
  cheap and true — the writer's intent before the enqueue, and the
  applier's memory after the apply.

  One journal file per group, one owner process per journal — the single
  writer of Chapter 4.3 as a storage discipline. The `intents` table is a
  transactional outbox: record the intent, enqueue on the bus, mark it
  enqueued; every crash window between those steps is covered by replay
  plus machinery that already exists — the bus deduplicates a re-enqueued
  job id, and newer-wins makes a re-applied version harmless. The
  `applied` table is the lane's memory of the last version applied per
  name: it survives the node, the cache, and the bus, so a replayed old
  intent answers stale from the journal even when L1 has forgotten the
  row. Compaction retires every intent whose name has an applied version
  at least as new — coverage, not acknowledgment, so the hot path pays no
  per-intent completion write.

  Recovery is replay: `replay/2` re-enqueues every intent not yet covered
  by the applied memory, reusing the recorded job ids so the bus's own
  admission dedup absorbs the ones it still holds. Streaming the journal
  file off the box is a separate process by design — Litestream-shaped,
  referenced in the chapter, deliberately not implemented here.
  """

  use GenServer

  alias EchoCache.Coherence
  alias EchoData.BrandedId
  alias EchoMQ.Lanes
  alias Exqlite.Sqlite3

  # -- surface ---------------------------------------------------------------

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "The writer's first edge: record the intent before the bus hears it."
  def record(j, job_id, name_id, version) do
    GenServer.call(j, {:record, job_id, name_id, version})
  end

  @doc "The writer's second edge: the bus accepted this intent."
  def mark_enqueued(j, job_id), do: GenServer.call(j, {:mark_enqueued, job_id})

  @doc """
  Group commit at the writer's edge: record a batch of intents inside one
  transaction — one WAL append amortized across the batch. Marks remain
  individual and post-enqueue; the outbox seam this batches is admission,
  never acknowledgment.
  """
  def record_many(j, triples) when is_list(triples) do
    GenServer.call(j, {:record_many, triples}, 30_000)
  end

  @doc """
  The outbox in one verb: mint a job id, record the intent, enqueue on the
  bus, mark it enqueued. The two crash windows between the steps are the
  rung's drill, covered by replay plus dedup plus newer-wins.
  """
  def intend_and_enqueue(j, conn, name_id, version) do
    job_id = BrandedId.generate!("JOB")
    {:ok, _seq} = record(j, job_id, name_id, version)

    case GenServer.call(j, :route) do
      {queue, group} ->
        {:ok, :enqueued} = Lanes.enqueue(conn, queue, group, job_id, Coherence.payload(name_id, version))
        :ok = mark_enqueued(j, job_id)
        {:ok, job_id}
    end
  end

  @doc "The memory: the newest version this lane has applied for a name."
  def last_applied(j, name_id), do: GenServer.call(j, {:last_applied, name_id})

  @doc """
  Apply with memory: stale against the journal answers without touching
  the cache at all; otherwise the table applies and the journal remembers.
  """
  def apply_and_remember(j, table, name_id, version) do
    GenServer.call(j, {:apply_and_remember, table, name_id, version})
  end

  @doc "A consumer handler wiring the job lane through the journal's memory."
  def handler(j, table) do
    fn %{payload: payload} ->
      {:ok, name_id, version} = Coherence.parse(payload)
      {:ok, _verdict} = apply_and_remember(j, table, name_id, version)
      :ok
    end
  end

  @doc """
  Recovery beside the bus: re-enqueue every intent not covered by the
  applied memory, in seq order, reusing recorded job ids so the bus's
  admission dedup absorbs whatever it still holds. Returns the counts.
  """
  def replay(j, conn), do: GenServer.call(j, {:replay, conn}, 30_000)

  @doc "Retire every intent whose name carries an applied version at least as new."
  def compact(j), do: GenServer.call(j, :compact)

  def stats(j), do: GenServer.call(j, :stats)
  def stop(j), do: GenServer.stop(j)

  # -- owner -------------------------------------------------------------------

  @impl true
  def init(opts) do
    group = Keyword.fetch!(opts, :group)
    table_str = Keyword.fetch!(opts, :table)
    dir = Keyword.fetch!(opts, :dir)

    unless BrandedId.valid?(group), do: raise(ArgumentError, "group must be a branded id")

    File.mkdir_p!(dir)
    path = Path.join(dir, "journal-" <> group <> ".db")
    {:ok, db} = Sqlite3.open(path)

    :ok = Sqlite3.execute(db, "PRAGMA journal_mode=WAL")
    :ok = Sqlite3.execute(db, "PRAGMA synchronous=NORMAL")
    # the shadow takes brief write locks at checkpoint; wait, never error
    :ok = Sqlite3.execute(db, "PRAGMA busy_timeout=5000")

    :ok =
      Sqlite3.execute(db, """
      CREATE TABLE IF NOT EXISTS intents(
        seq INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id TEXT NOT NULL UNIQUE,
        name_id TEXT NOT NULL,
        version TEXT NOT NULL,
        enqueued INTEGER NOT NULL DEFAULT 0,
        recorded_at INTEGER NOT NULL
      )
      """)

    :ok =
      Sqlite3.execute(db, """
      CREATE TABLE IF NOT EXISTS applied(
        name_id TEXT PRIMARY KEY,
        version TEXT NOT NULL,
        seq INTEGER NOT NULL
      )
      """)

    upsert_sql =
      "INSERT INTO applied(name_id, version, seq) VALUES(?,?,0) " <>
        "ON CONFLICT(name_id) DO UPDATE SET version=excluded.version " <>
        "WHERE substr(excluded.version,4) > substr(version,4)"

    prep = fn sql ->
      {:ok, st} = Sqlite3.prepare(db, sql)
      st
    end

    stmts = %{
      insert:
        prep.(
          "INSERT INTO intents(job_id, name_id, version, enqueued, recorded_at) " <>
            "VALUES(?,?,?,0,?) RETURNING seq"
        ),
      mark: prep.("UPDATE intents SET enqueued=1 WHERE job_id=?"),
      get_applied: prep.("SELECT version FROM applied WHERE name_id=?"),
      upsert: prep.(upsert_sql)
    }

    {:ok,
     %{
       db: db,
       path: path,
       group: group,
       table: table_str,
       queue: Coherence.queue(table_str),
       stmts: stmts
     }}
  end

  @impl true
  def handle_call({:record, job_id, name_id, version}, _from, s) do
    now = System.os_time(:millisecond)
    [seq] = hot_one(s.db, s.stmts.insert, [job_id, name_id, version, now])
    {:reply, {:ok, seq}, s}
  end

  def handle_call({:record_many, triples}, _from, s) do
    :ok = Sqlite3.execute(s.db, "BEGIN")
    now = System.os_time(:millisecond)

    seqs =
      Enum.map(triples, fn {job_id, name_id, version} ->
        [seq] = hot_one(s.db, s.stmts.insert, [job_id, name_id, version, now])
        seq
      end)

    :ok = Sqlite3.execute(s.db, "COMMIT")
    {:reply, {:ok, seqs}, s}
  end

  def handle_call({:mark_enqueued, job_id}, _from, s) do
    :ok = hot_write(s.db, s.stmts.mark, [job_id])
    {:reply, :ok, s}
  end

  def handle_call(:route, _from, s), do: {:reply, {s.queue, s.group}, s}

  def handle_call({:last_applied, name_id}, _from, s) do
    {:reply, fetch_applied(s, name_id), s}
  end

  def handle_call({:apply_and_remember, table, name_id, version}, _from, s) do
    reply =
      case fetch_applied(s, name_id) do
        remembered when is_binary(remembered) ->
          if Coherence.newer?(version, remembered) do
            apply_and_record(s, table, name_id, version)
          else
            {:ok, :remembered_stale}
          end

        nil ->
          apply_and_record(s, table, name_id, version)
      end

    {:reply, reply, s}
  end

  def handle_call({:replay, conn}, _from, s) do
    {:ok, st} =
      Sqlite3.prepare(s.db, """
      SELECT i.job_id, i.name_id, i.version FROM intents i
      WHERE NOT EXISTS(
        SELECT 1 FROM applied a
        WHERE a.name_id = i.name_id AND substr(a.version,4) >= substr(i.version,4)
      )
      ORDER BY i.seq
      """)

    rows = collect(s.db, st, [])
    :ok = Sqlite3.release(s.db, st)

    counts =
      Enum.reduce(rows, %{replayed: 0, deduplicated: 0}, fn [job_id, name_id, version], acc ->
        case Lanes.enqueue(conn, s.queue, s.group, job_id, Coherence.payload(name_id, version)) do
          {:ok, :enqueued} ->
            :ok = run(s.db, "UPDATE intents SET enqueued=1 WHERE job_id=?", [job_id])
            %{acc | replayed: acc.replayed + 1}

          {:ok, :duplicate} ->
            %{acc | deduplicated: acc.deduplicated + 1}
        end
      end)

    {:reply, {:ok, counts}, s}
  end

  def handle_call(:compact, _from, s) do
    :ok =
      run(
        s.db,
        """
        DELETE FROM intents
        WHERE EXISTS(
          SELECT 1 FROM applied a
          WHERE a.name_id = intents.name_id AND substr(a.version,4) >= substr(intents.version,4)
        )
        """,
        []
      )

    {:ok, st} = Sqlite3.prepare(s.db, "SELECT changes()")
    {:row, [n]} = Sqlite3.step(s.db, st)
    :ok = Sqlite3.release(s.db, st)
    {:reply, {:ok, n}, s}
  end

  def handle_call(:stats, _from, s) do
    one = fn sql ->
      {:ok, st} = Sqlite3.prepare(s.db, sql)
      {:row, [n]} = Sqlite3.step(s.db, st)
      :ok = Sqlite3.release(s.db, st)
      n
    end

    {:reply,
     %{
       intents: one.("SELECT count(*) FROM intents"),
       pending_enqueue: one.("SELECT count(*) FROM intents WHERE enqueued=0"),
       remembered: one.("SELECT count(*) FROM applied"),
       path: s.path
     }, s}
  end

  @impl true
  def terminate(_reason, s) do
    Sqlite3.close(s.db)
    :ok
  end

  # -- internals ---------------------------------------------------------------

  defp apply_and_record(s, table, name_id, version) do
    {:ok, verdict} = EchoCache.Table.apply_coherence(table, name_id, version)
    :ok = hot_write(s.db, s.stmts.upsert, [name_id, version])
    {:ok, verdict}
  end

  defp fetch_applied(s, name_id) do
    case hot_one(s.db, s.stmts.get_applied, [name_id]) do
      [v] -> v
      nil -> nil
    end
  end

  defp hot_write(db, st, args) do
    :ok = Sqlite3.bind(db, st, args)
    :done = Sqlite3.step(db, st)
    :ok
  end

  defp hot_one(db, st, args) do
    :ok = Sqlite3.bind(db, st, args)

    case Sqlite3.step(db, st) do
      {:row, row} ->
        # drain to :done so a RETURNING write is fully applied before reply
        :done = Sqlite3.step(db, st)
        row

      :done ->
        nil
    end
  end

  defp run(db, sql, args) do
    {:ok, st} = Sqlite3.prepare(db, sql)
    :ok = if args == [], do: :ok, else: Sqlite3.bind(db, st, args)
    :done = Sqlite3.step(db, st)
    :ok = Sqlite3.release(db, st)
    :ok
  end

  defp collect(db, st, acc) do
    case Sqlite3.step(db, st) do
      {:row, row} -> collect(db, st, [row | acc])
      :done -> Enum.reverse(acc)
    end
  end
end
