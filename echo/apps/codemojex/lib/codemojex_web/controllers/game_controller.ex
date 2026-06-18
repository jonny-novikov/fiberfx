defmodule CodemojexWeb.GameController do
  @moduledoc """
  The Mini App's JSON endpoints. Every action calls the `Codemojex` facade and the
  privacy-preserving views — the secret and other players' guesses never cross
  this boundary. The player identity is read from the request for now; in
  production it comes from verified Telegram `initData` (a TODO).
  """
  use CodemojexWeb, :controller

  action_fallback CodemojexWeb.FallbackController

  def health(conn, _params), do: json(conn, %{status: "ok"})

  def create_player(conn, params) do
    opts = [
      keys: int(params["keys"], 0),
      clips: int(params["clips"], 0),
      diamonds: int(params["diamonds"], 0)
    ]

    with {:ok, uid} <- Codemojex.create_player(params["name"] || "player", opts) do
      json(conn, %{player: uid})
    end
  end

  def rooms(conn, _params), do: json(conn, %{rooms: Codemojex.lobby()})

  def join(conn, %{"id" => room} = params) do
    with player when is_binary(player) <- require_player(params),
         {:ok, round} <- Codemojex.join_room(room, player) do
      json(conn, %{round: round, view: Codemojex.round_view(round)})
    end
  end

  def round(conn, %{"id" => round}) do
    case Codemojex.round_view(round) do
      nil -> {:error, :no_round}
      view -> json(conn, %{view: view})
    end
  end

  def guess(conn, %{"id" => round} = params) do
    with player when is_binary(player) <- require_player(params),
         {:ok, _job} <- Codemojex.submit(round, player, params["emojis"]) do
      json(conn, %{status: "accepted", view: Codemojex.round_view(round)})
    end
  end

  def history(conn, %{"id" => round} = params) do
    with player when is_binary(player) <- require_player(params) do
      json(conn, %{history: Codemojex.my_history(round, player)})
    end
  end

  def leaderboard(conn, %{"id" => round}) do
    json(conn, %{leaderboard: rows(Codemojex.leaderboard(round, 20))})
  end

  def buy_keys(conn, params) do
    with player when is_binary(player) <- require_player(params),
         keys when is_integer(keys) <- int(params["keys"], {:error, :bad_amount}),
         {:ok, balance} <- Codemojex.purchase_keys(player, keys, params["ref"] || "stars") do
      json(conn, %{balance: balance})
    end
  end

  def convert(conn, params) do
    with player when is_binary(player) <- require_player(params),
         diamonds when is_integer(diamonds) <- int(params["diamonds"], {:error, :bad_amount}),
         {:ok, balance} <- Codemojex.convert_to_keys(player, diamonds) do
      json(conn, %{balance: balance})
    end
  end

  # --- helpers ---
  defp require_player(%{"player" => p}) when is_binary(p) and p != "", do: p
  defp require_player(_), do: {:error, :no_player}

  defp rows(pairs), do: Enum.map(pairs, fn {p, s} -> %{player: p, score: s} end)

  defp int(nil, default), do: default
  defp int(v, _default) when is_integer(v), do: v

  defp int(v, default) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      :error -> default
    end
  end
end
