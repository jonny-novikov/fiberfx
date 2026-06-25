defmodule CodemojexWeb.AuthController do
  @moduledoc """
  The auth handshake — `POST /api/auth/:platform` — the SOLE `SES` mint (cm.4 §6).

  It is the "issue here, verify everywhere else" point and the single writer the
  read-only-edge model depends on: it verifies Telegram WebApp `initData` (the
  pure `Codemojex.InitData`), resolves the verified Telegram user to a `PLR`
  (`Codemojex.resolve_player_by_tg/2`, resolve-or-create), and mints a
  `SES`-branded session in Valkey, returning the `SES` as the bearer.

  The route is open (it issues the bearer — there is no `SES` to present yet); the
  trust is in the `initData` signature, not a session. Any verification, resolve,
  or mint failure renders a deterministic 401 — never a 500 — so a forged, stale,
  or unconfigured-token request is refused at the door.
  """
  use CodemojexWeb, :controller

  # The freshness window for a handshake's initData (seconds). Operator-tunable; a
  # generous default — the WebApp issues initData once at open and it is presented
  # promptly, so a day's window tolerates clock skew without admitting replay.
  @max_age_seconds 86_400

  @doc """
  Exchange a signed `initData` for a `SES` + the resolved `PLR`.

  `:platform` selects the adapter ("telegram" today). The `initData` is read from
  the `initData` body param, or the `x-telegram-init-data` header as a fallback.
  """
  def handshake(conn, %{"platform" => platform} = params) do
    init_data = params["initData"] || get_init_data_header(conn)

    with {:ok, %{tg_user_id: uid} = claims} <-
           Codemojex.InitData.verify(init_data, Codemojex.Bot.token(), max_age_seconds: @max_age_seconds),
         {:ok, plr} <- Codemojex.resolve_player_by_tg(uid, name: display_name(claims)),
         {:ok, ses} <- Codemojex.Session.mint(plr, platform, %{"tg_user_id" => uid}) do
      json(conn, %{session: ses, player: plr})
    else
      # A verify / resolve / mint failure is unauthenticated, not a server error.
      # Render 401 here (the FallbackController's default for an unknown reason is
      # 400, which would mis-signal a verify failure).
      {:error, _reason} -> unauthorized(conn)
      _ -> unauthorized(conn)
    end
  end

  def handshake(conn, _params), do: unauthorized(conn)

  # -- helpers ---------------------------------------------------------------

  defp unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: :unauthenticated})
  end

  defp get_init_data_header(conn) do
    case get_req_header(conn, "x-telegram-init-data") do
      [value | _] -> value
      [] -> nil
    end
  end

  defp display_name(%{user: %{"first_name" => name}}) when is_binary(name) and name != "", do: name
  defp display_name(_claims), do: "player"
end
