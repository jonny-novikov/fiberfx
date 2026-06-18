defmodule EchoStore.ComponentStore do
  @moduledoc """
  CubDB feature for BCS: a component-addressable local durable store keyed by a
  branded id, the concrete form of the B4 "local store" tier for *components* (as opposed to
  `EchoStore.Graft.Store`, which keys CubDB by Graft *page* index).

  Keys are `{ns, snowflake}` tuples — the branded id, split so a namespace is a contiguous
  CubDB range. That makes three things cheap and lock-free, reusing CubDB's MVCC:

    * `get/2` / `put/3` — point reads and writes by branded id.
    * `namespace/2` — every component in a namespace, oldest-first, by a single range select
      between `{ns, 0}` and `{ns, @max_snow}` (mint order == byte order, so the range is the
      whole namespace in time order).
    * `window/4` — a time/branded-id window inside a namespace, addressed purely by snowflake
      arithmetic, for paging a leaderboard or a round's guesses without scanning the table.

  Writes go through `transaction/2` so a multi-component change (a guess that debits a wallet
  and appends to a round) is atomic. Snapshots (`snapshot/1` + `get_at/3`) give a reader a
  consistent point-in-time view while writers proceed — the MVCC of B4.
  """

  alias EchoData.BrandedId

  @max_snow Bitwise.bsl(1, 64) - 1

  @doc "Open (or create) a component store at `dir`. One CubDB process owns one directory."
  @spec open(Path.t(), keyword()) :: {:ok, pid()} | {:error, term()}
  def open(dir, opts \\ []) do
    CubDB.start_link(Keyword.merge([data_dir: dir, auto_compact: true], opts))
  end

  @doc "Insert or update the component at a branded id. Raises on an invalid id."
  @spec put(GenServer.server(), BrandedId.t(), term()) :: :ok
  def put(db, id, value) do
    {ns, snow} = split!(id)
    CubDB.put(db, {ns, snow}, value)
  end

  @doc "Atomically write many `{branded_id, value}` components."
  @spec put_many(GenServer.server(), [{BrandedId.t(), term()}]) :: :ok
  def put_many(db, entries) when is_list(entries) do
    CubDB.transaction(db, fn tx ->
      tx =
        Enum.reduce(entries, tx, fn {id, value}, tx ->
          {ns, snow} = split!(id)
          CubDB.Tx.put(tx, {ns, snow}, value)
        end)

      {:commit, tx, :ok}
    end)
  end

  @doc "Point read by branded id."
  @spec get(GenServer.server(), BrandedId.t(), term()) :: term()
  def get(db, id, default \\ nil) do
    {ns, snow} = split!(id)
    CubDB.get(db, {ns, snow}, default)
  end

  @doc "Delete a component by branded id (absent key is a no-op)."
  @spec delete(GenServer.server(), BrandedId.t()) :: :ok
  def delete(db, id) do
    {ns, snow} = split!(id)
    CubDB.delete(db, {ns, snow})
  end

  @doc """
  Every `{branded_id, value}` in a namespace, oldest-first (mint order). Streamed lazily by
  CubDB inside one immutable snapshot, so it is consistent without locking writers.
  """
  @spec namespace(GenServer.server(), binary()) :: [{BrandedId.t(), term()}]
  def namespace(db, ns) when byte_size(ns) == 3 do
    db
    |> CubDB.select(min_key: {ns, 0}, max_key: {ns, @max_snow})
    |> Enum.map(fn {{^ns, snow}, value} -> {BrandedId.encode!(ns, snow), value} end)
  end

  @doc """
  A bounded window inside a namespace: components whose snowflake lies in `[from_snow, to_snow]`,
  optionally reversed and limited — paging by branded-id arithmetic, no table scan.
  """
  @spec window(GenServer.server(), binary(), {non_neg_integer(), non_neg_integer()}, keyword()) ::
          [{BrandedId.t(), term()}]
  def window(db, ns, {from_snow, to_snow}, opts \\ []) when byte_size(ns) == 3 do
    limit = Keyword.get(opts, :limit, :infinity)
    reverse = Keyword.get(opts, :reverse, false)

    stream =
      CubDB.select(db, min_key: {ns, from_snow}, max_key: {ns, to_snow}, reverse: reverse)

    stream = if limit == :infinity, do: stream, else: Stream.take(stream, limit)

    Enum.map(stream, fn {{^ns, snow}, value} -> {BrandedId.encode!(ns, snow), value} end)
  end

  @doc "An immutable snapshot for consistent point-in-time reads while writers proceed."
  @spec snapshot(GenServer.server()) :: CubDB.Snapshot.t()
  def snapshot(db), do: CubDB.snapshot(db)

  @doc "Read by branded id at a snapshot."
  @spec get_at(CubDB.Snapshot.t(), BrandedId.t(), term()) :: term()
  def get_at(snap, id, default \\ nil) do
    {ns, snow} = split!(id)
    CubDB.Snapshot.get(snap, {ns, snow}, default)
  end

  @doc "Run `fun` inside a CubDB transaction; `fun` returns `{:commit, tx, result} | {:cancel, result}`."
  @spec transaction(GenServer.server(), (CubDB.Tx.t() -> {:commit, CubDB.Tx.t(), term()} | {:cancel, term()})) ::
          term()
  def transaction(db, fun) when is_function(fun, 1), do: CubDB.transaction(db, fun)

  # --- helpers ---------------------------------------------------------------

  defp split!(id) do
    case BrandedId.parse(id) do
      {:ok, ns, snow} -> {ns, snow}
      :error -> raise ArgumentError, "not a branded id: #{inspect(id)}"
    end
  end
end
