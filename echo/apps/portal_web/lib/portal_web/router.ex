defmodule PortalWeb.Router do
  @moduledoc """
  The router for the `:portal_web` app (F6.1 + F6.2).

  Declares three pipelines (`:browser`, `:api`, `:require_auth`), a public scope, a
  protected scope, an `:api` scope, the retained domain-free liveness route, and a
  private function plug. Every route maps to a handler that calls only the `Portal`
  facade (F6.2-INV1) — the router itself names only controllers, plugs, and the
  LiveView, never a module below the boundary. Every internal URL is a verified `~p`
  path (F6.2-INV4). The router is the endpoint's last plug (F6.1-INV3).
  """
  use PortalWeb, :router

  # Cross-cutting work for HTML browser requests, declared once (F6.2-INV2). The
  # function plug `stamp_request_marker` runs last (F6.2-D5) so both public and
  # protected browser routes pass through it.
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :stamp_request_marker
  end

  # JSON requests carry nothing browser-specific — no session, CSRF, or secure
  # headers (F6.2-D2). Only `accepts ["json"]`.
  pipeline :api do
    plug :accepts, ["json"]
  end

  # The auth gate, declared once (F6.2-D3). `PortalWeb.RequireUser` loads the session
  # user or halts with a redirect; the protected scope stacks it AFTER `:browser`
  # (F6.2-INV5) so the session is fetched before this plug reads it.
  pipeline :require_auth do
    plug PortalWeb.RequireUser
  end

  # Public surface (F6.2-D1): the four route kinds (`get`, `post`, `resources`,
  # `live`) plus the static landing. Routes are pinned in this order for determinism;
  # there is no overlap among them, so order is not load-bearing for matching.
  scope "/", PortalWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/courses/:user_id", CourseController, :index
    resources "/lessons", LessonController, only: [:show]
    post "/enroll", EnrollmentController, :create
    live "/enroll/:id", EnrollmentLive
  end

  # Protected surface (F6.2-D3, F6.2-INV5): pipe order is LOAD-BEARING — `:browser`
  # fetches the session before `:require_auth` reads it. `get "/learn"` reuses
  # `CourseController.index/2` (facade-only over `Portal.courses_of/1`), reading the
  # learner's own enrollments from the `:current_user_id` assign `RequireUser` set.
  scope "/learn", PortalWeb do
    pipe_through [:browser, :require_auth]

    get "/", CourseController, :index
  end

  # JSON surface (F6.2-D2/D7): `/api/lessons/:id` negotiates JSON via `accepts
  # ["json"]` and `LessonController.show_json/2` returns `json(conn, _)`.
  scope "/api", PortalWeb do
    pipe_through :api

    get "/lessons/:id", LessonController, :show_json
  end

  # Liveness: returns 200 "ok" with no domain call (F6.1-R6, F6.1-D6). Outside the
  # :browser pipeline — the operator probe needs no session or CSRF token.
  get "/health", PortalWeb.CourseController, :health

  # A function plug (F6.2-D5): a one-line `(conn, _opts) -> conn` step that stamps a
  # request attribute and returns the conn, demonstrating the plug contract without a
  # module. Non-halting — it cannot perturb any existing route.
  defp stamp_request_marker(conn, _opts) do
    assign(conn, :request_marker, true)
  end
end
