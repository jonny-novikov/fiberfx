defmodule EchoStore.Graft.Store do
  @moduledoc """
  The durable, per-Volume store, on CubDB's append-only immutable B-tree.

  Why CubDB: it is "an append-only, immutable B-tree … read operations are
  performed on zero cost immutable snapshots" with MVCC and ACID transactions
  (hexdocs `cubdb`). That is Graft's local model already — copy-on-write page
  versioning, immutable historical snapshots, ordered keys for range scans, and
  atomic commits — in pure Elixir, with no C and no NIF.

  Key space (Erlang term order gives the scan order):

    * `{:commit, lsn}`        => `%EchoData.Graft.Commit{}`        (the log)
    * `{:page, page_idx, lsn}` => page binary                      (versioned pages)
    * `:head`                 => the current head LSN
    * `:syncpoint`            => `%EchoData.Graft.SyncPoint{}`

  Resolving "the version of page P at or below LSN N" is one bounded reverse
  `select` over `{:page, P, 0}..{:page, P, N}` — the first row is the answer.
  """
  alias EchoData.Graft.{Commit, SyncPoint}

  @type db :: GenServer.server()

  @doc "Opens (or creates) a Volume's store. One CubDB process owns one data dir."
  @spec open(Path.t(), keyword()) :: {:ok, pid()} | {:error, term()}
  def open(dir, opts \\ []) do
    CubDB.start_link(
      Keyword.merge([data_dir: dir, auto_compact: true, auto_file_sync: true], opts)
    )
  end

  @doc "Highest committed LSN, or 0 for a fresh Volume."
  @spec head_lsn(db) :: non_neg_integer()
  def head_lsn(db), do: CubDB.get(db, :head, 0)

  @doc """
  Appends a commit: its pages and the commit row land in one CubDB transaction,
  so a crash never leaves a commit row without its pages.
  """
  @spec append(db, Commit.t(), %{non_neg_integer() => binary()}) :: :ok | {:error, term()}
  def append(db, %Commit{lsn: lsn} = commit, pages) when is_map(pages) do
    CubDB.transaction(db, fn tx ->
      tx =
        Enum.reduce(pages, tx, fn {idx, bin}, tx when is_binary(bin) ->
          CubDB.Tx.put(tx, {:page, idx, lsn}, bin)
        end)

      tx =
        tx
        |> CubDB.Tx.put({:commit, lsn}, commit)
        |> CubDB.Tx.put(:head, lsn)

      {:commit, tx, :ok}
    end)
  end

  @doc "The latest version of `page_idx` at or below `lsn`."
  @spec page_at(db, non_neg_integer(), non_neg_integer()) :: {:ok, binary()} | :absent
  def page_at(db, page_idx, lsn) do
    db
    |> CubDB.select(
      min_key: {:page, page_idx, 0},
      max_key: {:page, page_idx, lsn},
      reverse: true
    )
    |> Enum.take(1)
    |> case do
      [{_k, bin}] -> {:ok, bin}
      [] -> :absent
    end
  end

  @doc """
  Builds a Snapshot resolution index up to `lsn` by folding the commit log:
  later commits overwrite earlier page entries, leaving the latest writer per
  page. Reads are taken inside one CubDB snapshot, isolated from concurrent
  writes (MVCC), so the fold is consistent without locking.
  """
  @spec index_at(db, EchoData.BrandedId.t(), non_neg_integer()) :: EchoData.Graft.Snapshot.t()
  def index_at(db, volume_id, lsn) do
    # `select/2` is internally consistent: CubDB reads it inside one immutable
    # snapshot (MVCC), so the fold sees a single point-in-time view without locks.
    index =
      db
      |> CubDB.select(min_key: {:commit, 0}, max_key: {:commit, lsn})
      |> Enum.reduce(%{}, fn {{:commit, clsn}, %Commit{segment_id: seg, pages: pages}}, acc ->
        Enum.reduce(EchoData.Graft.PageSet.to_list(pages), acc, fn idx, acc ->
          Map.put(acc, idx, {clsn, seg})
        end)
      end)

    %EchoData.Graft.Snapshot{volume_id: volume_id, lsn: lsn, index: index}
  end

  @spec get_syncpoint(db) :: SyncPoint.t()
  def get_syncpoint(db), do: CubDB.get(db, :syncpoint, %SyncPoint{})

  @spec put_syncpoint(db, SyncPoint.t()) :: :ok
  def put_syncpoint(db, %SyncPoint{} = sp), do: CubDB.put(db, :syncpoint, sp)

  @doc "Streams commits in an inclusive LSN range, oldest first (the push planner)."
  @spec commits(db, non_neg_integer(), non_neg_integer()) :: Enumerable.t()
  def commits(db, from_lsn, to_lsn) do
    CubDB.select(db, min_key: {:commit, from_lsn}, max_key: {:commit, to_lsn})
  end
end
