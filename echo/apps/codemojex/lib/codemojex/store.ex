defmodule Codemojex.Store do
  @moduledoc """
  The component reads and writes, on Postgres. Branded ids stay the keys — BCS
  gives identity, the relational store gives durability and query. Plain maps
  cross the boundary so the rest of the game (which speaks maps) is unchanged;
  status atoms map to text columns and back. The money tables (players,
  transactions) are written only through `Codemojex.Wallet`, inside DB transactions
  — `player/1` here is a read for convenience.
  """
  import Ecto.Query
  alias Codemojex.Repo
  alias Codemojex.Schemas.{Player, Round, Guess, Room, EmojiSet}

  # rounds ----------------------------------------------------------------
  def put_round(id, m), do: upsert(Round, id, m)
  def round(id), do: to_map(Repo.get(Round, id))

  # rooms -----------------------------------------------------------------
  def put_room(id, m), do: upsert(Room, id, m)
  def room(id), do: to_map(Repo.get(Room, id))
  def rooms, do: Room |> Repo.all() |> Enum.map(&to_map/1)

  # guesses ---------------------------------------------------------------
  def put_guess(id, m), do: upsert(Guess, id, m)
  def guess(id), do: to_map(Repo.get(Guess, id))

  def guesses_for(round, player, n) do
    Repo.all(
      from g in Guess,
        where: g.round == ^round and g.player == ^player,
        order_by: [desc: g.at_ms],
        limit: ^n
    )
    |> Enum.map(&to_map/1)
  end

  # players (read only here; writes go through Codemojex.Wallet) -----------
  def player(id), do: to_map(Repo.get(Player, id))

  # emoji sets (returns the EmojiSet struct callers pattern-match on) ------
  def put_set(%Codemojex.EmojiSet{} = set) do
    attrs = Map.take(set, [:id, :name, :cols, :rows, :cell_size, :sprite_url, :codes])

    %EmojiSet{}
    |> EmojiSet.changeset(attrs)
    |> Repo.insert(on_conflict: {:replace_all_except, [:id, :inserted_at]}, conflict_target: :id)

    :ok
  end

  def set(id) do
    case Repo.get(EmojiSet, id) do
      nil ->
        nil

      r ->
        %Codemojex.EmojiSet{
          id: r.id,
          name: r.name,
          cols: r.cols,
          rows: r.rows,
          cell_size: r.cell_size,
          sprite_url: r.sprite_url,
          codes: r.codes
        }
    end
  end

  # --- helpers -----------------------------------------------------------
  defp upsert(schema, id, m) do
    attrs = m |> Map.put(:id, id) |> stringify_status()

    case schema |> struct(%{}) |> schema.changeset(attrs) |> Repo.insert(
           on_conflict: {:replace_all_except, [:id, :inserted_at]},
           conflict_target: :id
         ) do
      {:ok, _} -> :ok
      {:error, _} = e -> e
    end
  end

  defp stringify_status(%{status: s} = m) when is_atom(s) and not is_nil(s),
    do: %{m | status: Atom.to_string(s)}

  defp stringify_status(m), do: m

  defp to_map(nil), do: nil

  defp to_map(struct) do
    struct
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> atomize_status()
  end

  defp atomize_status(%{status: s} = m) when is_binary(s), do: %{m | status: String.to_atom(s)}
  defp atomize_status(m), do: m
end

defmodule Codemojex.Bus do
  @moduledoc "The shared RESP3 connector to Valkey (the EchoMQ bus + the real-time competitive state). Supervised; the connector pid is the child."
  @key {__MODULE__, :conn}

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end

  def start_link(opts \\ []) do
    {:ok, conn} = EchoMQ.Connector.start_link(port: Keyword.get(opts, :port, 6390), protocol: 3)
    :persistent_term.put(@key, conn)
    {:ok, conn}
  end

  def conn, do: :persistent_term.get(@key)
end

defmodule Codemojex.Cache do
  @moduledoc """
  The read-hot seam — now over Postgres. A round (with its secret) and an emoji
  set are read on the scoring path; in production those reads go through
  `EchoStore.Table.fetch/2` (an L1 ETS cache), falling back to the relational
  system of record on a miss. Where EchoStore is not loaded the seam degrades to
  reading Postgres directly — a permanent miss, the correct lower bound. The
  cached value's version is the entity's own branded id: a round's secret and an
  emoji set are immutable for the round's life, so the cache never goes stale.
  """
  @cache :cm_rounds
  @sets :cm_emojisets

  def fetch_round(round_id) do
    if Code.ensure_loaded?(EchoStore.Table) do
      case apply(EchoStore.Table, :fetch, [@cache, round_id]) do
        {:ok, bin} when is_binary(bin) -> :erlang.binary_to_term(bin)
        _ -> Codemojex.Store.round(round_id)
      end
    else
      Codemojex.Store.round(round_id)
    end
  end

  def put_round(round_id, round_map) do
    if Code.ensure_loaded?(EchoStore.Table) do
      apply(EchoStore.Table, :put, [@cache, round_id, :erlang.term_to_binary(round_map), round_id])
    end

    :ok
  end

  def fetch_set(set_id) do
    if Code.ensure_loaded?(EchoStore.Table) do
      case apply(EchoStore.Table, :fetch, [@sets, set_id]) do
        {:ok, bin} when is_binary(bin) -> :erlang.binary_to_term(bin)
        _ -> Codemojex.Store.set(set_id)
      end
    else
      Codemojex.Store.set(set_id)
    end
  end

  def put_set(%Codemojex.EmojiSet{id: id} = set) do
    if Code.ensure_loaded?(EchoStore.Table) do
      apply(EchoStore.Table, :put, [@sets, id, :erlang.term_to_binary(set), id])
    end

    :ok
  end
end
