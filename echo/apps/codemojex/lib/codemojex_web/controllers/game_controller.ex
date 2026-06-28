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

  # cm.7 — the KeyShop create-order route. The client supplies ONLY {package_id, rail};
  # the key count, the price, and the payment ref are server-derived and pinned on the ORD
  # (the double-mint hazard of params["keys"]/params["ref"] is closed — S6/A6). Minting
  # happens later, only via KeyShop.settle_payment/1 (the OTX-gated fulfilment). For the
  # Stars rail an XTR invoice link is returned when a bot token is configured.
  def buy_keys(conn, %{"package_id" => package_id, "rail" => rail}) do
    with {:ok, order} <- Codemojex.create_order(conn.assigns.player, package_id, rail) do
      json(conn, %{order: order_json(order), invoice: invoice_for(order)})
    end
  end

  def buy_keys(_conn, _params), do: {:error, :bad_request}

  def convert(conn, params) do
    with diamonds when is_integer(diamonds) <- int(params["diamonds"], {:error, :bad_amount}),
         {:ok, balance} <- Codemojex.convert_to_keys(conn.assigns.player, diamonds) do
      json(conn, %{balance: balance})
    end
  end

  # --- helpers ---
  defp rows(pairs), do: Enum.map(pairs, fn {p, s} -> %{player: p, score: s} end)

  # The order, projected to the client (no internal rate provenance leaks).
  defp order_json(o) do
    %{id: o.id, rail: o.rail, keys: o.keys, currency: o.currency, price_minor: o.price_minor, status: o.status}
  end

  # A Stars XTR invoice link when a bot token is configured (else nil — the order is still
  # created; the Mini App can re-request the link once a token is wired). Keyed by the ORD
  # id as the invoice payload, so pre_checkout / successful_payment resolve back to it.
  defp invoice_for(%{rail: "stars"} = order) do
    if telegram_token?() do
      case Codemojex.Telegram.create_invoice_link(%{
             "title" => "#{order.keys} keys",
             "description" => "Codemoji key bundle",
             "payload" => order.id,
             "prices" => [%{"label" => "#{order.keys} keys", "amount" => order.price_minor}]
           }) do
        {:ok, link} -> link
        _ -> nil
      end
    end
  end

  defp invoice_for(_order), do: nil

  defp telegram_token?,
    do: is_binary(Keyword.get(Application.get_env(:codemojex, Codemojex.Telegram, []), :token))

  defp int(nil, default), do: default
  defp int(v, _default) when is_integer(v), do: v

  defp int(v, default) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      :error -> default
    end
  end
end
