defmodule PortalWeb do
  @moduledoc """
  The entrypoint for the `:portal_web` Phoenix application (F6.1).

  Provides the `use PortalWeb, :controller`, `use PortalWeb, :html`,
  `use PortalWeb, :router`, `use PortalWeb, :live_view`, and
  `use PortalWeb, :verified_routes` macros that controllers, views, the router, the
  LiveView modules, and the endpoint share. The web layer reaches the domain only
  through the `Portal` facade (F6.1-INV1) — no macro here imports the engine, a repo,
  or any module below the boundary. The `:live_view` macro (F6.2) imports
  `Phoenix.LiveView` and the shared `html_helpers` (`~H`, `~p`) only.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: []

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      import Phoenix.Controller, only: [get_csrf_token: 0]

      unquote(html_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML
      alias Phoenix.LiveView.JS

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: PortalWeb.Endpoint,
        router: PortalWeb.Router,
        statics: PortalWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
