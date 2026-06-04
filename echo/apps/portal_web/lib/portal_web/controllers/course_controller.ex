defmodule PortalWeb.CourseController do
  @moduledoc """
  The thin read controller for a user's courses (F6.1-R4, F6.1-D4).

  `index/2` calls ONLY the `Portal` facade (`Portal.courses_of/1`) — it names no
  module below the boundary, no persistence layer, and issues no direct process call
  (F6.1-INV1) — and hands the closed outcome to `render_outcome/2`, which holds the
  two railway arms: data renders `:index`, and a `%Portal.Error{}` renders `:error`
  at status `422` (F6.1-INV4). `health/2` is the domain-free liveness action
  (F6.1-R6).

  ## Two routes, one action (F6.2)

  `index/2` backs BOTH the public `get "/courses/:user_id"` and the protected
  `get "/learn"`. The public route supplies `user_id` as a route param; the protected
  `/learn` route has no path param and instead carries the authenticated learner's id
  in the `:current_user_id` assign that `PortalWeb.RequireUser` set (F6.2-INV6).
  `index/2` reads `params["user_id"]` first, falling back to
  `conn.assigns.current_user_id`, then calls the same facade read. The fallback adds
  no domain logic and touches only assigns/params, so the action stays facade-only
  (F6.2-INV1) and carries no cross-cutting code (F6.2-INV2).
  """
  use PortalWeb, :controller

  @doc """
  Render a user's enrolled courses.

  `Portal.courses_of/1` is TOTAL at F6.1 (`portal.ex` lines 81-82,
  `@spec {:ok, [%Enrollment{}]}`): an unknown or malformed `user_id` yields
  `{:ok, []}`, so the empty list renders the empty state (a clean `200`), never a
  `422`. The `{:error, %Portal.Error{}}` arm is defensive (railway-oriented,
  F6.1-INV5): it satisfies the error-render contract structurally and becomes
  request-reachable when the facade gains id-validation (a later F6 rung); at F6.1 it
  is exercised by a controller/view unit test injecting a `%Portal.Error{}`.

  The public `get "/courses/:user_id"` supplies `user_id` as a route param; the
  protected `get "/learn"` (F6.2) has no path param and instead carries the
  authenticated learner's id in the `:current_user_id` assign `PortalWeb.RequireUser`
  set, so the param is read first with the assign as the fallback (F6.2-INV6).
  """
  def index(conn, params) do
    user_id = params["user_id"] || conn.assigns.current_user_id
    render_outcome(conn, Portal.courses_of(user_id))
  end

  # Split into a separate function so each outcome arm is its own clause. With a single
  # inline `case`, the 1.18 type checker would prune the defensive `{:error, ...}` branch
  # as unreachable (`Portal.courses_of/1` is success-only today); distinct heads keep the
  # error path live for the injected-error unit test and the later id-validation rung.
  @spec render_outcome(Plug.Conn.t(), {:ok, [Portal.Learning.Enrollment.t()]}) :: Plug.Conn.t()
  @spec render_outcome(Plug.Conn.t(), {:error, Portal.Error.t()}) :: Plug.Conn.t()
  def render_outcome(conn, {:ok, courses}) do
    render(conn, :index, courses: courses)
  end

  def render_outcome(conn, {:error, %Portal.Error{} = error}) do
    conn
    |> put_status(422)
    |> render(:error, error: error)
  end

  @doc """
  Liveness probe — `200 "ok"`, no domain call (F6.1-R6). The only route that does not
  reach the facade.
  """
  def health(conn, _params) do
    send_resp(conn, 200, "ok")
  end
end
