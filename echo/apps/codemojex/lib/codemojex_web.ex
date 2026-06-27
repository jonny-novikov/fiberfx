defmodule CodemojexWeb do
  @moduledoc """
  The web surface for the Codemojex Mini App. The original surface is a JSON API
  and a WebSocket channel; this revision adds the three-tier render path — a
  LiveView lobby (HEEx + streams + PubSub) and a LiveReact board island — so
  `:live_view`, `:html`, and `:verified_routes` join `:controller`/`:channel`.
  """
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt welcome)

  def router do
    quote do
      use Phoenix.Router, helpers: false
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel, do: quote(do: use(Phoenix.Channel))

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json], layouts: [html: CodemojexWeb.Layouts]
      import Plug.Conn
      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView, layout: {CodemojexWeb.Layouts, :app}
      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # `use Phoenix.HTML` was removed in phoenix_html 4.0 (it raises): the HEEx here
      # needs only component/JS helpers, which arrive via `use Phoenix.Component` /
      # `use Phoenix.LiveView`. JS is aliased for the flash group's `JS.hide/1`.
      import LiveReact
      import Phoenix.LiveView.Helpers
      alias Phoenix.LiveView.JS
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: CodemojexWeb.Endpoint,
        router: CodemojexWeb.Router,
        statics: CodemojexWeb.static_paths()
    end
  end

  defmacro __using__(which) when is_atom(which), do: apply(__MODULE__, which, [])
end
