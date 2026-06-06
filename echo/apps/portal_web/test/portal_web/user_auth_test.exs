defmodule PortalWeb.UserAuthTest do
  @moduledoc """
  Unit test for the `PortalWeb.UserAuth` gate (F6.8.1-AS6, D9, INV5/INV1).

  Exercises the three surfaces in isolation: `fetch_current_user/2` (assign a loaded
  `current_user` or `nil`), `require_authenticated_user/2` (admit a loaded user / redirect
  an anonymous request to `~p"/login"`), and `on_mount(:ensure_authenticated, …)` (the
  F6.9 `live_session` hook). The end-to-end protected-route wiring is proved by
  `learn_protected_test.exs`.

  `async: false` + the `Portal.Store` reset in `PortalWeb.ConnCase` give per-test
  isolation against the branded-id collision hazard (echo/CLAUDE.md §4).
  """
  use PortalWeb.ConnCase, async: false

  alias Portal.Accounts.User
  alias PortalWeb.UserAuth

  # The seeded demonstration account (Portal.Accounts @credentials). Its fixed id is
  # resolvable by `Portal.Auth.user/1` even after a Store reset.
  @seeded_id "USRada00000000"

  describe "fetch_current_user/2" do
    test "an absent session assigns current_user: nil", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> UserAuth.fetch_current_user([])

      assert conn.assigns.current_user == nil
      assert conn.assigns.current_user_id == nil
      refute conn.halted
    end

    test "a session with a resolvable user assigns a loaded %User{}", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: @seeded_id})
        |> UserAuth.fetch_current_user([])

      assert %User{id: @seeded_id} = conn.assigns.current_user
      assert conn.assigns.current_user_id == @seeded_id
      refute conn.halted
    end
  end

  describe "require_authenticated_user/2" do
    test "an anonymous request redirects to /login and halts", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Phoenix.Controller.fetch_flash([])
        |> UserAuth.fetch_current_user([])
        |> UserAuth.require_authenticated_user([])

      assert conn.halted == true
      assert redirected_to(conn) == ~p"/login"
    end

    test "a loaded current_user is admitted (not halted)", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: @seeded_id})
        |> UserAuth.fetch_current_user([])
        |> UserAuth.require_authenticated_user([])

      assert conn.halted == false
      assert %User{id: @seeded_id} = conn.assigns.current_user
    end
  end

  describe "on_mount(:ensure_authenticated, …) — the F6.9 hook" do
    test "a resolvable session continues the mount with current_user" do
      socket = %Phoenix.LiveView.Socket{}

      assert {:cont, socket} =
               UserAuth.on_mount(:ensure_authenticated, %{}, %{"user_id" => @seeded_id}, socket)

      assert %User{id: @seeded_id} = socket.assigns.current_user
    end

    test "an anonymous session halts the mount with a redirect to /login" do
      socket = %Phoenix.LiveView.Socket{}

      assert {:halt, _socket} =
               UserAuth.on_mount(:ensure_authenticated, %{}, %{}, socket)
    end
  end
end
