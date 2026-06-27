defmodule CodemojexWeb.MiniAppAuth do
  @moduledoc """
  The browser-pipeline trust point for the LiveView surface (the JSON API keeps
  its own `Bearer <SES>` `CodemojexWeb.Auth`). It is the same handshake as
  `AuthController.handshake/2` — verify Telegram `initData`, resolve the `PLR`,
  mint a `SES` — but it lands the `SES` in the Plug session so `LiveView.mount/3`
  reads it from `session["ses"]` (the live socket inherits the signed session).

  Order of trust:
    1. a `SES` already in the session that still resolves → reuse it (no re-mint);
    2. else the short-lived `tg_init` cookie the static welcome forwarded → run the
       handshake, store the `SES`;
    3. else leave the session empty — `mount/3` redirects to the welcome, which is
       where `initData` is obtained.

  This stays the single-writer model: like the controller handshake, the mint here
  is the only `SES` writer on the browser path.
  """
  import Plug.Conn

  @behaviour Plug
  @max_age_seconds 86_400

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case resolve_existing(conn) do
      {:ok, plr} -> assign(conn, :player, plr)
      :none -> handshake_from_cookie(conn)
    end
  end

  defp resolve_existing(conn) do
    case get_session(conn, "ses") do
      ses when is_binary(ses) ->
        case Codemojex.Session.resolve(ses) do
          {:ok, %{plr: plr}} -> {:ok, plr}
          _ -> :none
        end

      _ ->
        :none
    end
  end

  defp handshake_from_cookie(conn) do
    conn = fetch_cookies(conn)

    with init_data when is_binary(init_data) <- decode_cookie(conn.cookies["tg_init"]),
         {:ok, %{tg_user_id: uid} = claims} <-
           Codemojex.InitData.verify(init_data, Codemojex.Bot.token(), max_age_seconds: @max_age_seconds),
         {:ok, plr} <- Codemojex.resolve_player_by_tg(uid, name: display_name(claims)),
         {:ok, ses} <- Codemojex.Session.mint(plr, "telegram", %{"tg_user_id" => uid}) do
      conn
      |> put_session("ses", ses)
      |> delete_resp_cookie("tg_init")
      |> assign(:player, plr)
    else
      _ -> assign(conn, :player, nil)
    end
  end

  defp decode_cookie(nil), do: nil
  defp decode_cookie(v) when is_binary(v), do: URI.decode(v)

  defp display_name(%{user: %{"first_name" => name}}) when is_binary(name) and name != "", do: name
  defp display_name(_claims), do: "player"
end
