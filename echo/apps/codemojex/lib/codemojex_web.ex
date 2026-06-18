defmodule CodemojexWeb do
  @moduledoc """
  The web surface for the Codemojex Mini App: a JSON API and a WebSocket channel.
  `use CodemojexWeb, :controller` / `:channel` / `:router` pull in the shared setup.
  """
  def router do
    quote do
      use Phoenix.Router, helpers: false
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:json], layouts: []
      import Plug.Conn
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
