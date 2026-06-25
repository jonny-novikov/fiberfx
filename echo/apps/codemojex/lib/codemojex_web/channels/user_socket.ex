defmodule CodemojexWeb.UserSocket do
  use Phoenix.Socket

  channel "game:*", CodemojexWeb.RoomChannel

  # cm.4: authenticate the socket by the SES connect-param. The SES is a body field
  # (`session`, or `token`), kept out of a query string so it does not land in proxy
  # logs. A bad / missing / revoked SES → :error (the connection is refused); only an
  # authenticated socket carries an assigned :player and a non-nil id/1.
  @impl true
  def connect(params, socket, _connect_info) do
    case Codemojex.Session.resolve(params["session"] || params["token"]) do
      {:ok, %{plr: plr}} -> {:ok, assign(socket, :player, plr)}
      {:error, _} -> :error
    end
  end

  @impl true
  def id(%{assigns: %{player: plr}}) when is_binary(plr), do: "player_socket:" <> plr
  def id(_socket), do: nil
end
