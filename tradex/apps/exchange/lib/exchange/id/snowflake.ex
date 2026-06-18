defmodule Exchange.Id.Snowflake do
  @moduledoc """
  Lock-free snowflake generator. Layout: `ts(41) <<< 22 ||| node(10) <<< 12 ||| seq(12)`,
  epoch 2024-01-01T00:00:00Z, values in `[0, 2^63)`.

  Inlined into `exchange` (pure Elixir) from `EchoData.Snowflake` when the trading
  apps were extracted to their own umbrella. Only the lock-free core the Gateway
  and Decider mint through is kept — `start/1`, `next/0`, and `next_branded/1`; the
  echo-stack back-compat helpers (`generate/1`, `timestamp/1`, `worker_id/1`,
  `extract/1`, the per-call-node `next/1`) and the optional NIF were dropped. The
  bit layout and epoch are unchanged, so ids byte-sort in mint order exactly as
  `echo_data`'s do (the Appendix-F order theorem the OrderBook relies on, INV-5).

  State is one `:atomics` cell holding `ts <<< 12 ||| seq` (53 bits). Each mint
  performs a compare-exchange of `max(now_part, last + 1)`:

    * normal flow — the clock advanced, `now_part` wins, sequence restarts;
    * burst — same millisecond, `last + 1` increments the sequence;
    * sequence exhausted (4096/ms) — the carry borrows into the timestamp,
      preserving strict monotonicity;
    * clock regression — `now_part < last`, so `last + 1` keeps minting from the
      logical clock; no duplicates, no blocking.

  Call `start/1` once before any mint — typically in the host's `Application.start/2`
  or a test `setup_all`. It is idempotent (`:persistent_term`-guarded).
  """

  import Bitwise

  @epoch_ms 1_704_067_200_000
  @seq_bits 12
  @node_bits 10
  @key {__MODULE__, :state}

  @doc "Initializes the generator. `node_id` in 0..1023; defaults to `phash2(node())`. Idempotent."
  def start(node_id \\ nil) do
    node_id =
      node_id || Application.get_env(:exchange, :node_id) ||
        :erlang.phash2(node(), 1 <<< @node_bits)

    unless node_id in 0..((1 <<< @node_bits) - 1) do
      raise ArgumentError, "node_id must be in 0..1023, got: #{inspect(node_id)}"
    end

    case :persistent_term.get(@key, nil) do
      nil ->
        ref = :atomics.new(1, signed: true)
        :atomics.put(ref, 1, now_part())
        :persistent_term.put(@key, {ref, node_id})
        :ok

      {_ref, _node} ->
        :ok
    end
  end

  @doc "Mints the next snowflake using the node fixed at `start/1`. Safe to call concurrently."
  @spec next() :: non_neg_integer()
  def next do
    {ref, node_id} = state()
    pack(advance(ref, now_part()), node_id)
  end

  @doc "Mints and brands in one call (requires `start/1`)."
  @spec next_branded(binary()) :: Exchange.Id.BrandedId.t()
  def next_branded(ns), do: Exchange.Id.BrandedId.encode!(ns, next())

  # Packs a monotonic `ts <<< 12 ||| seq` value and a node id into the wire layout.
  defp pack(v, node_id) do
    ts = v >>> @seq_bits
    seq = v &&& 0xFFF
    ts <<< 22 ||| node_id <<< @seq_bits ||| seq
  end

  defp state do
    :persistent_term.get(@key, nil) ||
      raise("Exchange.Id.Snowflake.start/1 has not been called")
  end

  defp advance(ref, cand) do
    last = :atomics.get(ref, 1)
    next = max(cand, last + 1)

    case :atomics.compare_exchange(ref, 1, last, next) do
      :ok -> next
      _actual -> advance(ref, cand)
    end
  end

  defp now_part, do: (System.system_time(:millisecond) - @epoch_ms) <<< @seq_bits
end
