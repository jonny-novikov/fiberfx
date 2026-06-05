defmodule PortalWeb.PageController do
  @moduledoc """
  The thin public landing controller (F6.2-R1, F6.2-D1; F6.5.5-D2/D6).

  Renders the two published course indexes as static, full-document pages from no
  assigns — neither action calls a `Portal` facade function nor names anything below
  the boundary (F6.2-INV1, F6.5.5-INV1). `home/2` renders the two-course index at `/`
  (`page_html/home.html.heex`, reproducing `html/courses.html`); `elixir/2` renders
  the Elixir course index at `/elixir` (`page_html/elixir.html.heex`, reproducing
  `elixir/index.html`). The `/` landing is also the redirect target
  `PortalWeb.RequireUser` sends an unauthenticated request to (F6.2-D4); F6.8 later
  swaps that target for the real login path.
  """
  use PortalWeb, :controller

  @doc """
  Render the static two-course index at `/` — always a `200`, no domain call.
  """
  def home(conn, _params) do
    render(conn, :home)
  end

  @doc """
  Render the static Elixir course index at `/elixir` — always a `200`, no domain call.
  """
  def elixir(conn, _params) do
    render(conn, :elixir)
  end
end
