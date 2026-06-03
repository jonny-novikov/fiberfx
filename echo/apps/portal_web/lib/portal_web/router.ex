defmodule PortalWeb.Router do
  @moduledoc """
  The router for the `:portal_web` app (F6.1-R3, F6.1-D3).

  Defines the `:browser` pipeline and one read route to the thin
  `PortalWeb.CourseController` over the `Portal` facade, plus a domain-free liveness
  route. The router is the endpoint's last plug (F6.1-INV3).
  """
  use PortalWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", PortalWeb do
    pipe_through :browser

    get "/courses/:user_id", CourseController, :index
  end

  # Liveness: returns 200 "ok" with no domain call (F6.1-R6, F6.1-D6). Outside the
  # :browser pipeline — the operator probe needs no session or CSRF token.
  get "/health", PortalWeb.CourseController, :health
end
