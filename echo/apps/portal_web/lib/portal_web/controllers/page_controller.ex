defmodule PortalWeb.PageController do
  @moduledoc """
  The thin public landing controller (F6.2-R1, F6.2-D1; F6.5.5-D2/D6).

  Renders the two published course indexes as static, full-document pages from no
  assigns — neither action calls a `Portal` facade function nor names anything below
  the boundary (F6.2-INV1, F6.5.5-INV1). `home/2` renders the two-course index at `/`
  (`page_html/home.html.heex`, reproducing `html/courses.html`); `elixir/2` renders
  the Elixir course index at `/elixir` (`page_html/elixir.html.heex`, reproducing
  `elixir/index.html`). `login/2` renders the static sign-in page at `/login`
  (`page_html/login.html.heex`, reproducing the current `elixir/login.html` the F6.5.5
  way — extracted `login.css`/`login.js`, no layout, no CoreComponents; F6.8.1-D1).
  `PortalWeb.UserAuth` now redirects an unauthenticated protected request to that
  `/login` path (F6.8.1-D9), discharging the redirect-target change F6.2 deferred.
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

  @doc """
  Render the static agile-agent-workflow course index at `/course/agile-agent-workflow` —
  always a `200`, no domain call (AAW-parity-R1).
  """
  def agile(conn, _params) do
    render(conn, :agile)
  end

  @doc """
  Render the static sign-in page at `/login` — always a `200`, no domain call
  (F6.8.1-D1, INV2). The page is parity-faithful to `elixir/login.html`; its forms
  post to `Portal.Auth`-backed `/auth/*` endpoints, but the page itself names no
  facade function (it is judged at envelope + clamp-spacing + token-fidelity parity).
  """
  def login(conn, _params) do
    render(conn, :login)
  end
end
