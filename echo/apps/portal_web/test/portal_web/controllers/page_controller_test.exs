defmodule PortalWeb.PageControllerTest do
  @moduledoc """
  ConnTest for the three published course-index routes (F6.2-US1, F6.2-D1, F6.2-D7;
  F6.5.5-D5/D8, F6.5.5-US0/US5; AAW-parity-D1/D3/D4).

  Proves the styled two-course index loads at `/`, the styled Elixir index at
  `/elixir`, and the styled agile-agent-workflow index at
  `/course/agile-agent-workflow`, all at `200` with no session. `/` is the redirect
  target `PortalWeb.RequireUser` sends an unauthenticated request to.
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

  test "GET /course/agile-agent-workflow renders the styled agile index at 200 with no session",
       %{conn: conn} do
    # ~p verifies the route exists at compile time (AAW-parity-R2); the request proves
    # it serves the styled local page (AAW-parity-D1).
    conn = get(conn, ~p"/course/agile-agent-workflow")

    assert conn.status == 200
    body = html_response(conn, 200)
    assert body =~ "<head"
    # Asset locality (AAW-parity-D3): the page pulls its CSS/JS from the Portal's own
    # priv/static, never the deep-link base.
    assert body =~ ~s(href="/assets/agile-index.css")
    assert body =~ ~s(src="/assets/agile-index.js")
    assert body =~ "The agile agent"
    # The bare index self-link stays relative; the sub-page deep links carry the
    # configurable base (AAW-parity-D4). The default base is jonnify.fly.dev.
    assert body =~ ~s(href="/course/agile-agent-workflow")
    assert body =~ ~s(href="#{PortalWeb.deep_link_base()}/course/agile-agent-workflow/why")
  end
end
