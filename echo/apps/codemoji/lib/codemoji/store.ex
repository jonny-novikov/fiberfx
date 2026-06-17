defmodule Codemoji.Store do
  @moduledoc """
  The systems of record, as Branded Component System property stores
  (`EchoData.Bcs.PropertyStore`). Each store is namespaced and keyed only by a
  branded id; the store refuses an id of the wrong namespace at the boundary.
  Three components: rounds (`RND`), players (`USR`), guesses (`GES`).
  """
  alias EchoData.Bcs.{PropertyStore, Supervisor}

  @rounds :cm_rounds
  @players :cm_players
  @guesses :cm_guesses

  def start_link do
    Supervisor.start_link([{@rounds, "RND"}, {@players, "USR"}, {@guesses, "GES"}])
  end

  def put_round(id, m), do: PropertyStore.put(@rounds, id, m)
  def round(id), do: unwrap(PropertyStore.get(@rounds, id))

  def put_player(id, m), do: PropertyStore.put(@players, id, m)
  def player(id), do: unwrap(PropertyStore.get(@players, id))

  def put_guess(id, m) do
    PropertyStore.record_entity(@guesses, id)
    PropertyStore.put(@guesses, id, m)
  end

  def guess(id), do: unwrap(PropertyStore.get(@guesses, id))
  def recent_guesses(n) do
    case PropertyStore.page_desc(@guesses, n) do
      {:ok, ids} -> ids
      _ -> []
    end
  end

  defp unwrap({:ok, v}), do: v
  defp unwrap(_), do: nil
end

defmodule Codemoji.Bus do
  @moduledoc "The shared RESP3 connector to Valkey (the bus + the leaderboard L2)."
  @key {__MODULE__, :conn}

  def start(opts \\ []) do
    {:ok, conn} = EchoMQ.Connector.start_link(port: Keyword.get(opts, :port, 6390), protocol: 3)
    :persistent_term.put(@key, conn)
    {:ok, conn}
  end

  def conn, do: :persistent_term.get(@key)
end

defmodule Codemoji.Cache do
  @moduledoc """
  The read-hot seam. A round (with its secret) is read on every guess; in
  production that read goes through `EchoCache.Table.fetch/3` — an L1 ETS cache
  over the Valkey L2, with `EchoCache.Coherence.newer?/2` deciding staleness by
  the version's mint order. Where the cache app is not loaded (no SQLite shadow
  dependency available), the seam degrades to reading the system of record it
  fronts — a permanent miss, which is the correct lower bound, not a substitute.
  The version is the round's own branded id: a round's secret is immutable for the
  round's life, so the cached value never goes stale under it.
  """
  @cache :cm_rounds

  def fetch_round(round_id) do
    if Code.ensure_loaded?(EchoCache.Table) do
      case apply(EchoCache.Table, :fetch, [@cache, round_id]) do
        {:ok, bin} when is_binary(bin) -> :erlang.binary_to_term(bin)
        _ -> Codemoji.Store.round(round_id)
      end
    else
      Codemoji.Store.round(round_id)
    end
  end

  def put_round(round_id, round_map) do
    if Code.ensure_loaded?(EchoCache.Table) do
      apply(EchoCache.Table, :put, [@cache, round_id, :erlang.term_to_binary(round_map), round_id])
    end

    :ok
  end
end
