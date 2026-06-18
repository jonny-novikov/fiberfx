defmodule EchoStore.Graft.Segment do
  @moduledoc """
  An immutable, deduplicated page range — the unit Graft ships to object storage.
  Modeled on Graft's push "build segment" step: collect every page referenced in an
  LSN range and **roll up** to the latest version of each page, so many local commits
  become one remote segment (graft.rs/docs/internals#push). Pages are grouped into
  frames (<= 64 pages) for compression and transfer.

  Hardening for EchoMQ 4+: the Streamer ships bytes, but the rollup/dedup that makes a
  remote commit cheap (and a checkpoint possible) was implicit. `build/3` makes it a
  first-class, testable value carrying a `SEG`-branded id (`EchoData.Graft.Id`).
  """
  alias EchoData.BrandedId

  @frame_pages 64

  @enforce_keys [:id, :volume_id, :lsn_lo, :lsn_hi]
  defstruct [:id, :volume_id, :lsn_lo, :lsn_hi, pages: %{}]

  @type page_no :: non_neg_integer()
  @type t :: %__MODULE__{
          id: BrandedId.t(),
          volume_id: BrandedId.t(),
          lsn_lo: non_neg_integer(),
          lsn_hi: non_neg_integer(),
          pages: %{optional(page_no()) => binary()}
        }

  @doc """
  Build a segment from a list of `{lsn, page_no, bytes}` touched in `[lsn_lo, lsn_hi]`.
  The list is folded newest-LSN-wins, so the result holds exactly one (latest) version
  of each page — the rollup. `seg_id` is a freshly minted `SEG` branded id.
  """
  @spec build(BrandedId.t(), BrandedId.t(), [{non_neg_integer(), page_no(), binary()}]) :: t()
  def build(seg_id, volume_id, touched) when is_list(touched) do
    {lo, hi, pages} =
      Enum.reduce(touched, {nil, 0, %{}}, fn {lsn, pno, bytes}, {lo, hi, acc} ->
        acc =
          case acc do
            %{^pno => {seen_lsn, _}} when seen_lsn >= lsn -> acc
            _ -> Map.put(acc, pno, {lsn, bytes})
          end

        {min(lo || lsn, lsn), max(hi, lsn), acc}
      end)

    %__MODULE__{
      id: seg_id,
      volume_id: volume_id,
      lsn_lo: lo || 0,
      lsn_hi: hi,
      pages: Map.new(pages, fn {pno, {_lsn, bytes}} -> {pno, bytes} end)
    }
  end

  @doc "Split the segment's pages into frames of at most #{@frame_pages} pages each."
  @spec frames(t()) :: [%{optional(page_no()) => binary()}]
  def frames(%__MODULE__{pages: pages}) do
    pages
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.chunk_every(@frame_pages)
    |> Enum.map(&Map.new/1)
  end

  @doc "Page count after rollup — the remote write size."
  @spec page_count(t()) :: non_neg_integer()
  def page_count(%__MODULE__{pages: pages}), do: map_size(pages)

  @doc """
  The object-storage key for this segment. Bytes travel off the write path
  (`EchoStore.Graft.Streamer` -> `Remote`), keyed by the `SEG` id, mirroring Graft's
  `/segments/{SegmentId}` layout.
  """
  @spec remote_key(t()) :: String.t()
  def remote_key(%__MODULE__{id: id}), do: "segments/" <> id
end
