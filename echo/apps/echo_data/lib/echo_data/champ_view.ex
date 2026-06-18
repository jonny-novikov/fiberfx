defmodule EchoData.ChampView do
  @moduledoc """
  CHAMP feature: rebuild an in-heap `BrandedChamp` view from the durable Graft commit log.

  `BrandedChamp` and `EchoData.ChampServer` already give a complete persistent map and a
  GenServer around it. What was missing is the *derivation* — the rule from the layered-store
  design that CHAMP is an L0 memory tier whose contents are **rebuildable from L2 (Graft)**,
  never a separate source of truth. This module is that rule as code:

    * `rebuild_view/2` folds a stream of decoded component entries into a fresh `BrandedChamp`.
    * `from_volume/3` reads a Graft Volume's pages at a snapshot, decodes each into a
      `{branded_id, value}`, and builds the view — the "fold the commit stream into a view"
      step the article (`rebuild_view/2`) describes.
    * `rebuild_server/3` swaps a `ChampServer`'s whole map atomically via its existing
      `replace/2`, so a decider/trading view can be re-derived after a crash with no bespoke
      recovery path.

  The decoder is injected, because how a page's bytes become a `{branded_id, term}` is the
  caller's component contract (Codemoji stores `:erlang.term_to_binary/1` values keyed by a
  `PLR`/`SEC`/`GSS` id; another domain may differ). Decoding to `:skip` drops a page that is
  not a component (tombstones, intent edges).
  """

  alias EchoData.BrandedChamp

  @type entry :: {EchoData.BrandedId.t(), term()}
  @type decoder :: (page_idx :: non_neg_integer(), bytes :: binary() -> {:ok, entry()} | :skip)

  @doc """
  Fold an enumerable of `{:ok, {id, value}} | :skip` results into a `BrandedChamp`.
  Pure: no process, no IO — the same input always yields the same view.
  """
  @spec rebuild_view(Enumerable.t()) :: BrandedChamp.t()
  def rebuild_view(decoded) do
    Enum.reduce(decoded, BrandedChamp.new(), fn
      {:ok, {id, value}}, champ -> BrandedChamp.put(champ, id, value)
      :skip, champ -> champ
    end)
  end

  @doc """
  Build a `BrandedChamp` view of a Graft Volume at the given snapshot (defaults to head),
  decoding each live page with `decoder`. Reads are lock-free via `EchoStore.Graft` — the
  view is a consistent point-in-time projection of the durable log.
  """
  @spec from_volume(EchoData.BrandedId.t(), decoder(), keyword()) :: BrandedChamp.t()
  def from_volume(volume_id, decoder, opts \\ []) when is_function(decoder, 2) do
    snap = Keyword.get_lazy(opts, :snapshot, fn -> EchoStore.Graft.VolumeServer.snapshot(volume_id) end)
    page_indices = snapshot_pages(snap)

    page_indices
    |> Stream.map(fn idx ->
      case read_page(volume_id, snap, idx) do
        {:ok, bytes} -> decoder.(idx, bytes)
        :absent -> :skip
      end
    end)
    |> rebuild_view()
  end

  @doc """
  Re-derive a `ChampServer`'s entire map from a Graft Volume and install it atomically.
  Returns `{:ok, size}`. This is recovery for the L0 tier: replay the durable log into a
  fresh view and swap it in, rather than mutating in place.
  """
  @spec rebuild_server(GenServer.server(), EchoData.BrandedId.t(), decoder()) ::
          {:ok, non_neg_integer()}
  def rebuild_server(server, volume_id, decoder) when is_function(decoder, 2) do
    champ = from_volume(volume_id, decoder)
    :ok = EchoData.ChampServer.replace(server, champ)
    {:ok, BrandedChamp.size(champ)}
  end

  # --- helpers ---------------------------------------------------------------

  # A snapshot's `index` maps page_idx => {lsn, segment_id}; its keys are the live pages.
  defp snapshot_pages(%{index: index}) when is_map(index), do: Map.keys(index)
  defp snapshot_pages(_), do: []

  defp read_page(volume_id, snap, idx) do
    # `read_at/3` resolves CubDB at the snapshot's LSN, faulting from the remote on a miss.
    EchoStore.Graft.read_at(volume_id, snap, idx)
  end
end
