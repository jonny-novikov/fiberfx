defmodule EchoCache.Graft do
  @moduledoc """
  Native-BEAM Graft: lazy, partial, page-based, strongly consistent replication,
  wired onto the Echo umbrella with no foreign engine.

    * **Engine** — `EchoCache.Graft.VolumeServer`, one single-writer process per
      Volume; its mailbox is Graft's global write lock.
    * **Store** — `EchoCache.Graft.Store` on CubDB's append-only immutable B-tree
      (zero-cost MVCC snapshots = Graft snapshots; pure Elixir, no C).
    * **L1** — `EchoCache.Table`, the existing `read_concurrency` ETS cache, used
      as the write-through head-page cache.
    * **Bus** — `EchoMQ.Connector` (RESP3 over Valkey) for push / pull / lazy
      fetch, via `EchoCache.Graft.Sync`.
    * **IDs** — BCS branded GIDs (`VOL` / `SEG` / `CMT`) from `EchoData.Graft.Id`.

  A typical write/read:

      {:ok, _pid} = EchoCache.Graft.open_volume(vol, data_dir: "priv/graft/\#{vol}", conn: conn)
      {:ok, base} = EchoCache.Graft.begin(vol)
      {:ok, lsn}  = EchoCache.Graft.commit(vol, base, %{0 => page0, 1 => page1})
      {:ok, bin}  = EchoCache.Graft.read(vol, 0)
  """
  alias EchoCache.Graft.{VolumeServer, Reader}

  @doc "Starts (under the dynamic supervisor) a Volume's writer + store."
  @spec open_volume(EchoData.BrandedId.t(), keyword()) :: DynamicSupervisor.on_start_child()
  def open_volume(volume_id, opts) do
    spec = {VolumeServer, Keyword.put(opts, :volume_id, volume_id)}
    DynamicSupervisor.start_child(EchoCache.Graft.VolumeSup, spec)
  end

  @doc "Mints a fresh `VOL` GID for a new Volume."
  @spec new_volume_id() :: EchoData.BrandedId.t()
  def new_volume_id, do: EchoData.Graft.Id.volume()

  defdelegate begin(volume_id), to: VolumeServer
  defdelegate commit(volume_id, base_lsn, staged), to: VolumeServer
  defdelegate snapshot(volume_id), to: VolumeServer
  defdelegate head_lsn(volume_id), to: VolumeServer
  defdelegate push(volume_id), to: VolumeServer

  @doc "Lock-free read of a page at the Volume's head."
  @spec read(EchoData.BrandedId.t(), non_neg_integer()) :: {:ok, binary()} | :absent
  def read(volume_id, page_idx) do
    ctx = ctx(volume_id)
    Reader.get(ctx, page_idx)
  end

  @doc "Lock-free read of a page at a historical Snapshot."
  @spec read_at(EchoData.BrandedId.t(), EchoData.Graft.Snapshot.t(), non_neg_integer()) ::
          {:ok, binary()} | :absent
  def read_at(volume_id, snap, page_idx), do: Reader.get_at(ctx(volume_id), snap, page_idx)

  # A read context resolves the L1 table name and CubDB handle from the Registry
  # (an ETS-backed lookup), never through the writer process — reads stay
  # lock-free. The VolumeServer publishes this context under `{:ctx, volume_id}`
  # at init.
  defp ctx(volume_id) do
    case Registry.lookup(EchoCache.Graft.Registry, {:ctx, volume_id}) do
      [{_pid, ctx}] -> ctx
      [] -> raise ArgumentError, "no open Volume #{inspect(volume_id)}"
    end
  end
end
