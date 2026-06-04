defmodule PortalWeb.RequireUserTest do
  @moduledoc """
  Unit test for the `PortalWeb.RequireUser` plug (F6.2-AS2, F6.2-D4, F6.2-INV3/INV6).

  Exercises `call/2` in isolation — the two arms (halt+redirect when no session user,
  assign+continue when present) and `init/1`'s compile-time pass-through. The ConnTest
  for the protected route (`learn_protected_test.exs`) complements this by proving the
  same boundary end-to-end through the pipeline.
  """
  use PortalWeb.ConnCase, async: false

  alias PortalWeb.RequireUser

  test "init/1 returns its options unchanged at compile time (F6.2-D4)" do
    assert RequireUser.init(:opts) == :opts
    assert RequireUser.init([]) == []
  end

  test "an absent session user halts with a redirect to the landing (F6.2-INV3)", %{conn: conn} do
    # In production INV5 guarantees `:browser` (fetch_session + fetch_live_flash) runs
    # before `:require_auth`, so the plug rightly assumes flash is present. This unit
    # test calls `call/2` in isolation, so it sets up the session + flash the pipeline
    # would have, then exercises the no-user arm directly.
    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> Phoenix.Controller.fetch_flash([])
      |> RequireUser.call(RequireUser.init([]))

    assert conn.halted == true
    assert redirected_to(conn) == ~p"/"
    assert Phoenix.Flash.get(conn.assigns.flash, :error)
    # The protected action is never reached, so no typed user assign is set (INV3).
    assert conn.assigns[:current_user_id] == nil
  end

  test "a present session user assigns :current_user_id and continues (F6.2-INV6)", %{conn: conn} do
    user_id = Portal.ID.new("USR")

    conn =
      conn
      |> Plug.Test.init_test_session(%{user_id: user_id})
      |> RequireUser.call(RequireUser.init([]))

    assert conn.halted == false
    assert conn.assigns.current_user_id == user_id
  end
end
