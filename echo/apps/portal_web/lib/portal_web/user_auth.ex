defmodule PortalWeb.UserAuth do
  @moduledoc """
  The session-backed auth gate (F6.8.1-D9), evolving the F6.2 `PortalWeb.RequireUser`
  plug into the named `UserAuth` surface F6.9's `live_session` forward-ref expects.

  Three surfaces, all reading the `:user_id` the signed session cookie carries
  (`SessionController.create/2` wrote it on sign-in):

    * `fetch_current_user/2` — a plug that reads `:user_id` and assigns a loaded
      `current_user` (a `%User{}`, via `Portal.Auth`) or `nil`. It also keeps the
      `:current_user_id` assign the F6.5 `EnrollmentController.index/2` reads, so that
      working controller needs no edit (the id is now sourced from the loaded user).
    * `require_authenticated_user/2` — a plug that admits a request carrying a
      `current_user` and redirects an anonymous one to `~p"/login"` (the target moved
      from `~p"/"`, discharging the `RequireUser` moduledoc's owed change, F6.8.1-INV5).
    * `on_mount/4` (`:ensure_authenticated`) — the LiveView hook F6.9's `live_session`
      names as `{PortalWeb.UserAuth, :ensure_authenticated}` (`f6.9.stories.md:84`):
      it assigns `current_user` on a connected mount and halts/redirects an anonymous
      mount to `~p"/login"`.

  It calls ONLY `Portal.Auth` for the user load (a plug that loads a domain entity
  through the facade) — it names no `Portal.Engine`, `Repo`, or `GenServer.call`
  (F6.8.1-INV1, the master invariant).
  """
  use PortalWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  alias Portal.Accounts.User

  @doc """
  A plug that loads the session `current_user` (F6.8.1-D9).

  Reads `:user_id` from the session and assigns `current_user` — a `%User{}` loaded via
  `Portal.Auth.user/1` — plus the `:current_user_id` the F6.5 enrollment read expects.
  Assigns `nil`/leaves the id unset for an anonymous or unresolvable session; it never
  halts (gating is `require_authenticated_user/2`'s job).
  """
  @spec fetch_current_user(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def fetch_current_user(conn, _opts) do
    with user_id when is_binary(user_id) <- get_session(conn, :user_id),
         {:ok, %User{} = user} <- Portal.Auth.user(user_id) do
      conn
      |> assign(:current_user, user)
      |> assign(:current_user_id, user.id)
    else
      _ ->
        conn
        |> assign(:current_user, nil)
        |> assign(:current_user_id, nil)
    end
  end

  @doc """
  A plug that gates a protected scope on a loaded `current_user` (F6.8.1-D9, INV5).

  Admits a request whose `:current_user` assign is a `%User{}` (set by
  `fetch_current_user/2` earlier in the pipeline); redirects an anonymous request to
  `~p"/login"` and halts (the protected action is never reached). Two arms, no third.
  """
  @spec require_authenticated_user(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def require_authenticated_user(conn, _opts) do
    case conn.assigns[:current_user] do
      %User{} ->
        conn

      _ ->
        conn
        |> put_flash(:error, "Please sign in.")
        |> redirect(to: ~p"/login")
        |> halt()
    end
  end

  @doc """
  The LiveView `on_mount` hook F6.9's `live_session` rides (F6.8.1-D9, INV5).

  `:ensure_authenticated` loads `current_user` from the session into the socket and
  `:cont`s when a `%User{}` resolves; otherwise it `:halt`s the mount with a redirect to
  `~p"/login"`. The named surface F6.9 references as `{PortalWeb.UserAuth,
  :ensure_authenticated}` (`f6.9.stories.md:84`). The user load goes through
  `Portal.Auth` only (F6.8.1-INV1).
  """
  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = Phoenix.Component.assign_new(socket, :current_user, fn -> load_user(session) end)

    case socket.assigns.current_user do
      %User{} -> {:cont, socket}
      _ -> {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/login")}
    end
  end

  defp load_user(session) do
    with user_id when is_binary(user_id) <- Map.get(session, "user_id"),
         {:ok, %User{} = user} <- Portal.Auth.user(user_id) do
      user
    else
      _ -> nil
    end
  end
end
