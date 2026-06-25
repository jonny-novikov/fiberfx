defmodule CodemojexWeb.GameController do
  @moduledoc """
  The Mini App's JSON endpoints. Every action calls the `Codemojex` facade and the
  privacy-preserving views — the secret and other players' guesses never cross
  this boundary. The player identity of a player-acting endpoint is
  `conn.assigns.player`, assigned by the `:auth` plug after it resolves a verified
  `SES` (cm.4) — never a caller-supplied id.
  """
  use CodemojexWeb, :controller

  action_fallback CodemojexWeb.FallbackController

  def health(conn, _params), do: json(conn, %{status: "ok"})

  def rooms(conn, _params), do: json(conn, %{rooms: Codemojex.lobby()})

  def join(conn, %{"id" => room}) do
    with {:ok, game} <- Codemojex.join_room(room, conn.assigns.player) do
      json(conn, %{game: game, view: Codemojex.game_view(game)})
    end
  end

  def game(conn, %{"id" => game}) do
    case Codemojex.game_view(game) do
      nil -> {:error, :no_game}
      view -> json(conn, %{view: view})
    end
  end

  def guess(conn, %{"id" => game} = params) do
    with {:ok, _job} <- Codemojex.submit(game, conn.assigns.player, params["emojis"]) do
      json(conn, %{status: "accepted", view: Codemojex.game_view(game)})
    end
  end

  def history(conn, %{"id" => game}) do
    json(conn, %{history: Codemojex.my_history(game, conn.assigns.player)})
  end

  def leaderboard(conn, %{"id" => game}) do
    json(conn, %{leaderboard: rows(Codemojex.leaderboard(game, 20))})
  end

  def buy_keys(conn, params) do
    with keys when is_integer(keys) <- int(params["keys"], {:error, :bad_amount}),
         {:ok, balance} <- Codemojex.purchase_keys(conn.assigns.player, keys, params["ref"] || "stars") do
      json(conn, %{balance: balance})
    end
  end

  def convert(conn, params) do
    with diamonds when is_integer(diamonds) <- int(params["diamonds"], {:error, :bad_amount}),
         {:ok, balance} <- Codemojex.convert_to_keys(conn.assigns.player, diamonds) do
      json(conn, %{balance: balance})
    end
  end

  # --- helpers ---
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
