defmodule PortalWeb.LearnProtectedTest do
  @moduledoc """
  ConnTest for the protected `/learn` route (F6.2-AS2, F6.2-D3, F6.2-INV5).

  Exercises the access boundary END-TO-END through the real router pipeline, the
  complement to the in-isolation `require_user_test.exs` unit test. A `call/2` unit
  test cannot observe a misconfigured scope — a missing or mis-ordered `:require_auth`
  in `scope "/learn"` would leave the plug correct yet the route unprotected. This
  test drives the request through endpoint → router → pipeline → controller, so the
  scope wiring itself is under test.

  `async: false` plus the `Portal.Store`/stream/engine reset in `PortalWeb.ConnCase`
  give per-test fold isolation against the branded-id collision hazard
  (echo/CLAUDE.md §4).
  """
  use PortalWeb.ConnCase, async: false

  describe "GET /learn (the protected scope)" do
    test "an unauthenticated request redirects to the landing and renders no protected body (F6.2-INV3)",
         %{conn: conn} do
      # No session is set, so `:require_auth` (PortalWeb.RequireUser) halts before the
      # CourseController.index action runs.
      conn = get(conn, ~p"/learn")

      assert redirected_to(conn) == ~p"/"
      assert conn.halted == true
      # The protected action never rendered, so its body header is absent.
      refute conn.resp_body && conn.resp_body =~ "Courses"
    end

    test "an authenticated request renders the protected courses page at 200 (F6.2-INV6)",
         %{conn: conn} do
      # A `:user_id` in the session passes `:require_auth`; RequireUser assigns
      # `:current_user_id` and CourseController.index reads the learner's own courses.
      # The branded id is the shape the other controller tests mint (USR-namespaced).
      user_id = Portal.ID.new("USR")

      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user_id})
        |> get(~p"/learn")

      body = html_response(conn, 200)
      # The protected action rendered the courses page. With no enrollment the empty
      # state shows; the stable `<h1>Courses</h1>` header marks the protected render
      # without over-asserting domain data.
      assert body =~ "Courses"
      assert body =~ "No courses yet."
    end
  end
end
