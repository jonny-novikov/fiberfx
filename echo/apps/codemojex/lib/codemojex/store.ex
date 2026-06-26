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
  alias Codemojex.Schemas.{Player, Game, Guess, Room, EmojiSet}

  # games -----------------------------------------------------------------
  def put_game(id, m), do: upsert(Game, id, m)
  def game(id), do: to_map(Repo.get(Game, id))

  # rooms -----------------------------------------------------------------
  def put_room(id, m), do: upsert(Room, id, m)
  def room(id), do: to_map(Repo.get(Room, id))
  def rooms, do: Room |> Repo.all() |> Enum.map(&to_map/1)

  # guesses ---------------------------------------------------------------
  def put_guess(id, m), do: upsert(Guess, id, m)
  def guess(id), do: to_map(Repo.get(Guess, id))

  def guesses_for(game, player, n) do
    Repo.all(
      from g in Guess,
        where: g.game == ^game and g.player == ^player,
        order_by: [desc: g.at_ms],
        limit: ^n
    )
    |> Enum.map(&to_map/1)
  end

  # players (read only here; writes go through Codemojex.Wallet) -----------
  def player(id), do: to_map(Repo.get(Player, id))

  @doc "The player's Telegram chat id for notifications, or nil if they have none."
  def chat_of(id) do
    case Repo.get(Player, id) do
      %Player{tg_chat_id: chat} -> chat
      _ -> nil
    end
  end

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
    # opts is the shared connector option list (protocol/port/host/password); merge defaults so a
    # bare start still gets a RESP3 lane on 127.0.0.1:6390.
    {:ok, conn} = EchoWire.start_link(Keyword.merge([port: 6390, protocol: 3], opts))
    :persistent_term.put(@key, conn)
    {:ok, conn}
  end

  def conn, do: :persistent_term.get(@key)
end

defmodule Codemojex.Cache do
  @moduledoc """
  The read-hot seam, over the EchoStore near-cache declared in `Codemojex.Tables`.
  A game (with its secret) and an emoji set are read on the scoring path through
  `EchoStore.Table.fetch/3` — an L1 `:ets` hit in the caller's process, otherwise
  a single-flight fill that checks the shared Valkey (L2) and falls through to the
  loader (the relational system of record). The cached value's version is the
  entity's own 14-byte branded id: a game's secret and an emoji set are immutable
  for the game's life, so the cache never goes stale and coherence is `:none`.

  The reads keep a direct fallback to Postgres for the window before the tables
  have started (boot) or if a table is briefly unavailable; the writes are best-
  effort (`safe_put/4`), so a Valkey blip or a table restart never fails the
  writer that is recording a game or a set.
  """
  @cache :cm_games
  @sets :cm_emojisets

  @doc "Read a game through the L1/L2 cache, falling back to the system of record."
  def fetch_game(game_id) do
    case EchoStore.Table.fetch(@cache, game_id) do
      {:ok, bin, _source} when is_binary(bin) -> :erlang.binary_to_term(bin)
      _ -> Codemojex.Store.game(game_id)
    end
  end

  @doc "Write a game into both cache layers, framed with its own id as the version."
  def put_game(game_id, game_map) do
    _ = safe_put(@cache, game_id, :erlang.term_to_binary(game_map), game_id)
    :ok
  end

  @doc "Read an emoji set through the L1/L2 cache, falling back to the system of record."
  def fetch_set(set_id) do
    case EchoStore.Table.fetch(@sets, set_id) do
      {:ok, bin, _source} when is_binary(bin) -> :erlang.binary_to_term(bin)
      _ -> Codemojex.Store.set(set_id)
    end
  end

  @doc "Write an emoji set into both cache layers, framed with its own id as the version."
  def put_set(%Codemojex.EmojiSet{id: id} = set) do
    _ = safe_put(@sets, id, :erlang.term_to_binary(set), id)
    :ok
  end

  # A cache write is an optimization, never a correctness dependency: a failure
  # to reach Valkey, or a table mid-restart, must not fail the writer.
  defp safe_put(table, id, bin, <<_::binary-14>> = version) do
    EchoStore.Table.put(table, id, bin, version)
  rescue
    _ -> :error
  catch
    :exit, _ -> :error
  end
end
