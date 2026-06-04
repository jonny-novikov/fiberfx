defmodule PortalWeb.PageControllerTest do
  @moduledoc """
  ConnTest for the public landing route (F6.2-US1, F6.2-D1, F6.2-D7).

  Proves the public landing loads at `200` with no session — the redirect target
  `PortalWeb.RequireUser` sends an unauthenticated request to.
  """
  use PortalWeb.ConnCase, async: false

  test "GET / renders the landing at 200 with no session", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert conn.status == 200
    assert html_response(conn, 200) =~ "Portal"
  end
end
