defmodule PortalWeb.PageControllerTest do
  @moduledoc """
  ConnTest for the two published course-index routes (F6.2-US1, F6.2-D1, F6.2-D7;
  F6.5.5-D5/D8, F6.5.5-US0/US5).

  Proves the styled two-course index loads at `/` and the styled Elixir index at
  `/elixir`, both at `200` with no session. `/` is the redirect target
  `PortalWeb.RequireUser` sends an unauthenticated request to.
  """
  use PortalWeb.ConnCase, async: false

  test "GET / renders the styled two-course index at 200 with no session", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert conn.status == 200
    body = html_response(conn, 200)
    assert body =~ "<head"
    assert body =~ "/assets/courses.css"
    assert body =~ "Choose a course"
  end

  test "GET /elixir renders the styled Elixir course index at 200 with no session", %{conn: conn} do
    conn = get(conn, ~p"/elixir")

    assert conn.status == 200
    body = html_response(conn, 200)
    assert body =~ "<head"
    assert body =~ "/assets/elixir-index.css"
    assert body =~ "Functional Programming"
  end
end
