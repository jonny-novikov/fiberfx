defmodule EchoStore.Durability.Graft do
  @moduledoc """
  A durability adapter whose outbox **is** the Graft commit log — the EchoMQ 4+
  commit-log-as-outbox, a **bring-your-own plugin** a host provides in its own app because it
  needs the Graft tier (`EchoStore.Graft.*` + `cubdb`). Implements `EchoStore.Durability.Adapter`.

  There is no separate `intents` table. An intent is a Graft commit: `record/4` commits a single
  page carrying `{job_id, name, version}` to the volume, and the commit's LSN is the intent's
  seq. Because the volume's pages roll up into segments shipped to object storage
  (`EchoStore.Graft.Streamer`), the outbox is durable *and replicated* for free — an intent
  survives the node and reaches a replica without a second store. Two small cursors live in the
  volume's CubDB: the **enqueue watermark** (the highest LSN already put on the bus) and the
  **applied memory** (`{:obx_applied, name} => version`), the newest version applied per name.
  Newer-wins is the shared rule (`EchoStore.Coherence.newer?/2`).

  Each intent takes a unique page index in a reserved high range (`@obx_base + seq`), so an
  intent page is never overwritten — which makes recovery a single head-snapshot scan: `replay/2`
  reads every reserved-range page whose commit LSN is above the enqueue watermark, re-enqueues it
  (reusing the recorded job id; the bus's dedup absorbs any it still holds), and advances the
  watermark. Compaction is not a per-intent delete here — the log is append-only — but the
  Streamer's rollup plus CubDB's auto-compaction, so `compact/1` advances a compacted-watermark
  and returns the number of intents now covered.

  ## Placement & setup

  Drop this module in the host app that owns the Graft volume. Build a handle with the volume id
  and its CubDB store (defaults to the registered store for the volume):

      g = EchoStore.Durability.Graft.new(volume_id: vol, table: "players", group: group_id)

  The host should also run `EchoStore.Graft.Committer` for the steady-state drain; this adapter
  is the journal-contract face of the same log (recovery, memory, stats).
  """
  @behaviour EchoStore.Durability.Adapter

  @enforce_keys [:volume_id, :db, :group, :table, :queue]
  defstruct [:volume_id, :db, :group, :table, :queue]

  alias EchoStore.{Coherence, Table}
  alias EchoStore.Graft.{VolumeServer, Store}
  alias EchoData.BrandedId
  alias EchoMQ.Lanes

  # Reserved page range for outbox intents — far above any realistic business page count,
  # so an intent page is unique and never overwritten by a data page.
  @obx_base :erlang.bsl(1, 48)

  @type t :: %__MODULE__{
          volume_id: BrandedId.t(),
          db: GenServer.server(),
          group: binary(),
          table: binary(),
          queue: binary()
        }

  @doc """
  Build a handle. `:volume_id` (a `VOL` branded id), `:table` (cache table name),
  `:group` (branded id). `:db` defaults to the volume's registered CubDB store.
  """
  @spec new(keyword()) :: t()
  def new(opts) do
    vol = Keyword.fetch!(opts, :volume_id)
    group = Keyword.fetch!(opts, :group)
    table = Keyword.fetch!(opts, :table)
    unless BrandedId.valid?(group), do: raise(ArgumentError, "group must be a branded id")

    %__MODULE__{
      volume_id: vol,
      db: Keyword.get_lazy(opts, :db, fn -> store_for(vol) end),
      group: group,
      table: table,
      queue: Coherence.queue(table)
    }
  end

  # -- Adapter callbacks -------------------------------------------------------

  @impl true
  def start_link(_opts), do: :ignore

  @impl true
  # Commit the intent as a page; the LSN is the seq. A conflicting base retries upstream.
  def record(%__MODULE__{} = g, job_id, name_id, version) do
    page_idx = @obx_base + next_seq(g.db)
    bytes = :erlang.term_to_binary({job_id, name_id, version})
    {:ok, base} = VolumeServer.begin(g.volume_id)

    case VolumeServer.commit(g.volume_id, base, %{page_idx => bytes}) do
      {:ok, lsn} -> {:ok, lsn}
      {:error, {:conflict, _head}} = c -> c
    end
  end

  @impl true
  # The commit log records the intent; enqueue progress is an LSN watermark, not a per-job flag.
  def mark_enqueued(%__MODULE__{}, _job_id), do: :ok

  @impl true
  def record_many(%__MODULE__{} = g, triples) when is_list(triples) do
    seqs =
      Enum.map(triples, fn {job_id, name_id, version} ->
        {:ok, lsn} = record(g, job_id, name_id, version)
        lsn
      end)

    {:ok, seqs}
  end

  @impl true
  def intend_and_enqueue(%__MODULE__{} = g, conn, name_id, version) do
    job_id = BrandedId.generate!("JOB")

    case record(g, job_id, name_id, version) do
      {:ok, lsn} ->
        case Lanes.enqueue(conn, g.queue, g.group, job_id, Coherence.payload(name_id, version)) do
          {:ok, _} -> advance_enqueued(g.db, lsn)
          _ -> :ok
        end

        {:ok, job_id}

      {:error, _} = err ->
        err
    end
  end

  @impl true
  def last_applied(%__MODULE__{} = g, name_id), do: CubDB.get(g.db, {:obx_applied, name_id}, nil)

  @impl true
  def apply_and_remember(%__MODULE__{} = g, table, name_id, version) do
    case last_applied(g, name_id) do
      remembered when is_binary(remembered) ->
        if Coherence.newer?(version, remembered),
          do: do_apply(g, table, name_id, version),
          else: {:ok, :remembered_stale}

      nil ->
        do_apply(g, table, name_id, version)
    end
  end

  @impl true
  def handler(%__MODULE__{} = g, table) do
    fn %{payload: payload} ->
      {:ok, name_id, version} = Coherence.parse(payload)
      {:ok, _verdict} = apply_and_remember(g, table, name_id, version)
      :ok
    end
  end

  @impl true
  # Recovery as a head-snapshot scan: every reserved-range page above the enqueue watermark,
  # not yet covered by the applied memory, gets re-enqueued reusing its recorded job id.
  def replay(%__MODULE__{} = g, conn) do
    snap = VolumeServer.snapshot(g.volume_id)
    wm = enqueued_watermark(g.db)

    counts =
      snap.index
      |> Enum.filter(fn {idx, {lsn, _seg}} -> idx >= @obx_base and lsn > wm end)
      |> Enum.sort_by(fn {_idx, {lsn, _seg}} -> lsn end)
      |> Enum.reduce(%{replayed: 0, deduplicated: 0}, fn {idx, _}, acc ->
        with {:ok, bytes} <- EchoStore.Graft.read_at(g.volume_id, snap, idx),
             {job_id, name_id, version} <- :erlang.binary_to_term(bytes),
             false <- covered?(g, name_id, version) do
          case Lanes.enqueue(conn, g.queue, g.group, job_id, Coherence.payload(name_id, version)) do
            {:ok, :enqueued} -> %{acc | replayed: acc.replayed + 1}
            {:ok, :duplicate} -> %{acc | deduplicated: acc.deduplicated + 1}
            _ -> acc
          end
        else
          _ -> acc
        end
      end)

    advance_enqueued(g.db, Store.head_lsn(g.db))
    {:ok, counts}
  end

  @impl true
  # Append-only log: compaction is the Streamer's rollup + CubDB auto-compact, not a per-intent
  # delete. Record the covered frontier and report how many intents it now covers.
  def compact(%__MODULE__{} = g) do
    snap = VolumeServer.snapshot(g.volume_id)

    covered =
      snap.index
      |> Enum.filter(fn {idx, _} -> idx >= @obx_base end)
      |> Enum.count(fn {idx, _} ->
        case EchoStore.Graft.read_at(g.volume_id, snap, idx) do
          {:ok, bytes} ->
            {_job, name_id, version} = :erlang.binary_to_term(bytes)
            covered?(g, name_id, version)

          _ ->
            false
        end
      end)

    CubDB.put(g.db, :obx_compacted_wm, Store.head_lsn(g.db))
    {:ok, covered}
  end

  @impl true
  def stats(%__MODULE__{} = g) do
    applied =
      g.db
      |> CubDB.select(min_key: {:obx_applied, ""}, max_key: {:obx_applied, <<0xFF>>})
      |> Enum.count()

    %{
      head_lsn: Store.head_lsn(g.db),
      enqueued_watermark: enqueued_watermark(g.db),
      remembered: applied,
      volume_id: g.volume_id
    }
  end

  @impl true
  def stop(_g), do: :ok

  # -- internals ---------------------------------------------------------------

  defp do_apply(g, table, name_id, version) do
    {:ok, verdict} = Table.apply_coherence(table, name_id, version)
    CubDB.put(g.db, {:obx_applied, name_id}, version)
    {:ok, verdict}
  end

  defp covered?(g, name_id, version) do
    case last_applied(g, name_id) do
      remembered when is_binary(remembered) -> not Coherence.newer?(version, remembered)
      nil -> false
    end
  end

  # Atomic page-index allocator for intents.
  defp next_seq(db) do
    CubDB.transaction(db, fn tx ->
      cur = CubDB.Tx.get(tx, :obx_seq, 0)
      {:commit, CubDB.Tx.put(tx, :obx_seq, cur + 1), cur + 1}
    end)
  end

  defp enqueued_watermark(db), do: CubDB.get(db, :obx_enqueued_wm, 0)

  defp advance_enqueued(db, lsn) do
    cur = enqueued_watermark(db)
    if lsn > cur, do: CubDB.put(db, :obx_enqueued_wm, lsn), else: :ok
  end

  defp store_for(vol), do: {:via, Registry, {EchoStore.Graft.Registry, {:store, vol}}}
end
