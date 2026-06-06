defmodule PortalWeb.SessionControllerTest do
  @moduledoc """
  ConnTest for the `/auth/*` endpoints (F6.8.1-AS5, D6/D7, INV1/INV3).

  Drives `POST /auth/session` and `POST /auth/reset` through the real router pipeline.
  Proves the honest door at the HTTP boundary: valid credentials write the signed
  session and redirect; a wrong name and a wrong password both answer the SAME status;
  a reset request always answers `200`. CSRF is resolution (a) — the page renders a
  token and `login.js` sends it; these tests bypass `protect_from_forgery` with
  `Plug.Test`'s `init_test_session`-backed conn (the controller test conn is not
  CSRF-protected), so the focus stays the controller behavior.

  `async: false` + the `Portal.Store`/stream/engine reset in `PortalWeb.ConnCase` give
  per-test isolation against the branded-id collision hazard (echo/CLAUDE.md §4) — a
  successful sign-in mints a `SES` id.
  """
  use PortalWeb.ConnCase, async: false

  @good_ident "ada"
  @good_pass "correct-horse"

  describe "POST /auth/session" do
    test "valid credentials write the signed session and redirect to /elixir", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> post(~p"/auth/session", %{"identifier" => @good_ident, "password" => @good_pass})

      assert redirected_to(conn) == "/elixir"
      # The learner's id was written into the session (the cookie F6.1 configured).
      assert is_binary(get_session(conn, :user_id))
    end

    test "a WRONG password answers 401 and writes no session", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> post(~p"/auth/session", %{"identifier" => @good_ident, "password" => "nope"})

      assert conn.status == 401
      assert get_session(conn, :user_id) == nil
    end

    test "a WRONG name answers the SAME 401 (the honest door, INV3)", %{conn: conn} do
      wrong_name =
        conn
        |> Plug.Test.init_test_session(%{})
        |> post(~p"/auth/session", %{"identifier" => "nobody", "password" => "nope"})

      wrong_pass =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> post(~p"/auth/session", %{"identifier" => @good_ident, "password" => "nope"})

      # Same status for both failure halves — the boundary does not branch on which.
      assert wrong_name.status == 401
      assert wrong_pass.status == 401
      assert wrong_name.status == wrong_pass.status
    end
  end

  describe "POST /auth/reset" do
    test "a matching email answers 200", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> post(~p"/auth/reset", %{"email" => "ada@portal.dev"})

      assert conn.status == 200
    end

    test "a non-matching email answers the SAME 200 (no enumeration, INV3)", %{conn: conn} do
      matching =
        conn
        |> Plug.Test.init_test_session(%{})
        |> post(~p"/auth/reset", %{"email" => "ada@portal.dev"})

      missing =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> post(~p"/auth/reset", %{"email" => "nobody@nowhere.test"})

      assert matching.status == 200
      assert missing.status == 200
      assert matching.status == missing.status
    end
  end
end
