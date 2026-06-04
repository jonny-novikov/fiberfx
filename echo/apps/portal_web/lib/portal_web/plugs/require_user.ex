defmodule PortalWeb.RequireUser do
  @moduledoc """
  A module plug that gates a protected scope on a session user (F6.2-D4, F6.2-D3).

  Implements the `Plug` behaviour: `init/1` returns its options once at compile time
  (F6.2-D4), and `call/2` parses the session EXACTLY ONCE (F6.2-INV6, parse-don't-
  validate). It reads `:user_id` from the session and either assigns a typed
  `:current_user_id` and continues, or halts with a redirect to the public landing
  and a flash. It has exactly TWO arms (F6.2-INV3); an unauthenticated request never
  reaches a protected action.

  It calls NO `Portal` facade function — a plug parses the session, not the domain —
  so it is trivially INV1-clean (it names no engine, repo, or `GenServer.call`). The
  `~p"/"` redirect target is the `PortalWeb.PageController.home` landing; F6.8 later
  swaps it for the real login path.

  The protected scope pipes `:browser` BEFORE `:require_auth` (F6.2-INV5), so the
  session is fetched before this plug reads it.
  """
  use PortalWeb, :verified_routes

  import Plug.Conn, only: [get_session: 2, assign: 3, halt: 1]
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_flash(:error, "Please sign in.")
        |> redirect(to: ~p"/")
        |> halt()

      user_id ->
        assign(conn, :current_user_id, user_id)
    end
  end
end
