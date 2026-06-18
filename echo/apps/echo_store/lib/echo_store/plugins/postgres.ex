defmodule EchoStore.Durability.Postgres do
  @moduledoc """
  A durability adapter that puts the outbox in PostgreSQL — a **bring-your-own plugin** a host
  provides in its own app, because it needs `ecto_sql` + `postgrex` and core ships dependency-free.
  Implements `EchoStore.Durability.Adapter`.

  It recovers Oban's strongest property — atomic enqueue — without paying Oban's price. The
  intent insert runs on the **host's own Ecto Repo**, so when called inside the host's
  `Repo.transaction/1` it commits atomically with the business row in the same Postgres
  transaction, while the bus, the dequeue, the retries, and the history all stay on Valkey. The
  database holds only the small `emq_intents` outbox and the `emq_applied` memory — one tiny
  insert per triggering write — so a single-instance Postgres becomes a low-rate, mostly-idle
  durability anchor rather than the queue's throughput ceiling and single point of failure.

  Newer-wins is the same rule as the SQLite journal, expressed in SQL as `substr(version, 4)` —
  the trailing 11-character branded-id payload. There is no owner process: Postgres provides the
  concurrency and the transactions, so `start_link/1` returns `:ignore` and the handle is a
  config struct built by `new/1`.

  ## Placement & setup

  Drop this module in the host app that already depends on `ecto_sql`/`postgrex` (e.g. the web
  app). Run `up/0` in an Ecto migration, then build a handle:

      pg = EchoStore.Durability.Postgres.new(repo: MyApp.Repo, group: group_id, table: "players")

  Compose the intent into the host's own transaction (the atomic outbox):

      MyApp.Repo.transaction(fn ->
        order = Repo.insert!(order_changeset)
        {:ok, _seq} = EchoStore.Durability.Postgres.record(pg, job_id, order.id, version)
      end)

  or use the all-in-one `intend_and_enqueue/4`.
  """
  @behaviour EchoStore.Durability.Adapter

  @enforce_keys [:repo, :group, :table, :queue]
  defstruct [:repo, :group, :table, :queue]

  alias EchoStore.{Coherence, Table}
  alias EchoData.BrandedId
  alias EchoMQ.Lanes

  @type t :: %__MODULE__{repo: module(), group: binary(), table: binary(), queue: binary()}

  @doc "Build a handle. `:repo` (an Ecto.Repo), `:group` (branded id), `:table` (cache table name)."
  @spec new(keyword()) :: t()
  def new(opts) do
    group = Keyword.fetch!(opts, :group)
    table = Keyword.fetch!(opts, :table)
    unless BrandedId.valid?(group), do: raise(ArgumentError, "group must be a branded id")

    %__MODULE__{
      repo: Keyword.fetch!(opts, :repo),
      group: group,
      table: table,
      queue: Coherence.queue(table)
    }
  end

  @doc "DDL for the host's migration: the outbox and the applied memory."
  @spec up() :: [String.t()]
  def up do
    [
      """
      CREATE TABLE IF NOT EXISTS emq_intents(
        seq BIGSERIAL PRIMARY KEY,
        job_id TEXT NOT NULL UNIQUE,
        name_id TEXT NOT NULL,
        version TEXT NOT NULL,
        enqueued BOOLEAN NOT NULL DEFAULT FALSE,
        recorded_at BIGINT NOT NULL
      )
      """,
      "CREATE INDEX IF NOT EXISTS emq_intents_name_idx ON emq_intents(name_id)",
      """
      CREATE TABLE IF NOT EXISTS emq_applied(
        name_id TEXT PRIMARY KEY,
        version TEXT NOT NULL,
        seq BIGINT NOT NULL DEFAULT 0
      )
      """
    ]
  end

  # -- Adapter callbacks -------------------------------------------------------

  @impl true
  def start_link(_opts), do: :ignore

  @impl true
  def record(%__MODULE__{} = pg, job_id, name_id, version) do
    now = System.os_time(:millisecond)

    %{rows: [[seq]]} =
      query!(
        pg,
        "INSERT INTO emq_intents(job_id, name_id, version, enqueued, recorded_at) " <>
          "VALUES($1,$2,$3,FALSE,$4) RETURNING seq",
        [job_id, name_id, version, now]
      )

    {:ok, seq}
  end

  @impl true
  def mark_enqueued(%__MODULE__{} = pg, job_id) do
    _ = query!(pg, "UPDATE emq_intents SET enqueued=TRUE WHERE job_id=$1", [job_id])
    :ok
  end

  @impl true
  def record_many(%__MODULE__{} = pg, triples) when is_list(triples) do
    repo = pg.repo

    repo.transaction(fn ->
      Enum.map(triples, fn {job_id, name_id, version} ->
        {:ok, seq} = record(pg, job_id, name_id, version)
        seq
      end)
    end)
    |> case do
      {:ok, seqs} -> {:ok, seqs}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def intend_and_enqueue(%__MODULE__{} = pg, conn, name_id, version) do
    job_id = BrandedId.generate!("JOB")
    repo = pg.repo

    # The intent commits in the same transaction as the enqueue decision. A crash before the
    # mark is covered by replay/2; a duplicate enqueue is absorbed by the bus and newer-wins.
    repo.transaction(fn ->
      {:ok, _seq} = record(pg, job_id, name_id, version)

      case Lanes.enqueue(conn, pg.queue, pg.group, job_id, Coherence.payload(name_id, version)) do
        {:ok, :enqueued} -> :ok = mark_enqueued(pg, job_id)
        {:ok, :duplicate} -> :ok
        other -> repo.rollback(other)
      end

      job_id
    end)
    |> case do
      {:ok, job_id} -> {:ok, job_id}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def last_applied(%__MODULE__{} = pg, name_id) do
    case query!(pg, "SELECT version FROM emq_applied WHERE name_id=$1", [name_id]) do
      %{rows: [[v]]} -> v
      %{rows: []} -> nil
    end
  end

  @impl true
  def apply_and_remember(%__MODULE__{} = pg, table, name_id, version) do
    case last_applied(pg, name_id) do
      remembered when is_binary(remembered) ->
        if Coherence.newer?(version, remembered),
          do: do_apply(pg, table, name_id, version),
          else: {:ok, :remembered_stale}

      nil ->
        do_apply(pg, table, name_id, version)
    end
  end

  @impl true
  def handler(%__MODULE__{} = pg, table) do
    fn %{payload: payload} ->
      {:ok, name_id, version} = Coherence.parse(payload)
      {:ok, _verdict} = apply_and_remember(pg, table, name_id, version)
      :ok
    end
  end

  @impl true
  def replay(%__MODULE__{} = pg, conn) do
    %{rows: rows} =
      query!(
        pg,
        "SELECT i.job_id, i.name_id, i.version FROM emq_intents i " <>
          "WHERE NOT EXISTS(SELECT 1 FROM emq_applied a " <>
          "WHERE a.name_id = i.name_id AND substr(a.version,4) >= substr(i.version,4)) " <>
          "ORDER BY i.seq",
        []
      )

    counts =
      Enum.reduce(rows, %{replayed: 0, deduplicated: 0}, fn [job_id, name_id, version], acc ->
        case Lanes.enqueue(conn, pg.queue, pg.group, job_id, Coherence.payload(name_id, version)) do
          {:ok, :enqueued} ->
            _ = query!(pg, "UPDATE emq_intents SET enqueued=TRUE WHERE job_id=$1", [job_id])
            %{acc | replayed: acc.replayed + 1}

          {:ok, :duplicate} ->
            %{acc | deduplicated: acc.deduplicated + 1}
        end
      end)

    {:ok, counts}
  end

  @impl true
  def compact(%__MODULE__{} = pg) do
    %{num_rows: n} =
      query!(
        pg,
        "DELETE FROM emq_intents i USING emq_applied a " <>
          "WHERE a.name_id = i.name_id AND substr(a.version,4) >= substr(i.version,4)",
        []
      )

    {:ok, n}
  end

  @impl true
  def stats(%__MODULE__{} = pg) do
    one = fn sql -> %{rows: [[n]]} = query!(pg, sql, []); n end

    %{
      intents: one.("SELECT count(*) FROM emq_intents"),
      pending_enqueue: one.("SELECT count(*) FROM emq_intents WHERE enqueued=FALSE"),
      remembered: one.("SELECT count(*) FROM emq_applied"),
      repo: pg.repo
    }
  end

  @impl true
  def stop(_pg), do: :ok

  # -- internals ---------------------------------------------------------------

  defp do_apply(pg, table, name_id, version) do
    {:ok, verdict} = Table.apply_coherence(table, name_id, version)

    _ =
      query!(
        pg,
        "INSERT INTO emq_applied(name_id, version, seq) VALUES($1,$2,0) " <>
          "ON CONFLICT(name_id) DO UPDATE SET version=EXCLUDED.version " <>
          "WHERE substr(EXCLUDED.version,4) > substr(emq_applied.version,4)",
        [name_id, version]
      )

    {:ok, verdict}
  end

  # Raw SQL on the host's repo — joins the caller's transaction when inside Repo.transaction/1.
  defp query!(%__MODULE__{repo: repo}, sql, params) do
    Ecto.Adapters.SQL.query!(repo, sql, params)
  end
end
