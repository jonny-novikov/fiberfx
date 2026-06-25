defmodule CodemojexWeb.Auth do
  @moduledoc """
  The `:auth` plug — the read-side trust point (cm.4 §7b).

  Reads `Authorization: Bearer <SES>`, resolves the `SES` to a `PLR` through the
  shared session store (`Codemojex.Session.resolve/1`, which also slides the TTL),
  and assigns `conn.assigns.player` — the ONLY identity a player-acting action
  reads. A missing / malformed bearer, or an unknown / expired / revoked `SES`,
  halts the request with 401.

  There is NO dev/test bypass (F2, D-2): a leaked auth-skip minting access into the
  shared Valkey would fool every service, so the suite mints a real `SES` via a
  `test/support` helper rather than a trust flag. A revoked `SES` is `:unknown` on
  the next request because `:tracking` evicted it from L1 and the `DEL` cleared L2.
  """
  import Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with {:ok, ses} <- bearer(conn),
         {:ok, %{plr: plr}} <- Codemojex.Session.resolve(ses) do
      assign(conn, :player, plr)
    else
      _ -> unauthorized(conn)
    end
  end

  # -- helpers ---------------------------------------------------------------

  defp bearer(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> ses | _] when ses != "" -> {:ok, ses}
      _ -> {:error, :no_bearer}
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> Phoenix.Controller.json(%{error: :unauthenticated})
    |> halt()
  end
end
