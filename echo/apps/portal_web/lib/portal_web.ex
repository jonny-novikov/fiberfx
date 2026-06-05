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

  @doc """
  The production base URL prepended to navigation deep-links the Portal does not
  itself serve (F6.5.5-D9 / INV9). A plain function — NOT a macro — read at render
  time by the parity templates and injected ONCE (`window.__deepLinkBase`) for the
  static `elixir-index.js` arc link-builder, so the host crosses the server/static
  boundary exactly once and no `jonnify.fly.dev` literal survives outside config
  (`config :portal_web, :deep_link_base_url`, default below; a deploy overrides it
  in `config/runtime.exs`). Applies to CATEGORY-4 nav links only — never to the
  `~p"/assets/…"` static routes (INV9(b)) nor the `/`,`/elixir` self-routes.
  """
  def deep_link_base,
    do: Application.get_env(:portal_web, :deep_link_base_url, "https://jonnify.fly.dev")

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
      # The controller builds `@form = to_form(changeset)` for the view to render
      # (F6.5-D4/D9). Only the form-builder is imported — the rendering DSL stays in
      # the `:html` macro.
      import Phoenix.Component, only: [to_form: 1]

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
      # The app's function components (the slot a generated app's CoreComponents import
      # fills) — `<.course_card>`/`<.panel>`/`<.input>` resolve in every :html and
      # :live_view module (F6.5-D2/D3/R9). `<.form>`/`<.link>` come from Phoenix.Component.
      import PortalWeb.CatalogComponents
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
