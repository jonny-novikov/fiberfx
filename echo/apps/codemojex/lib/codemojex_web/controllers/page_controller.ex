defmodule CodemojexWeb.PageController do
  @moduledoc """
  The web home `/` IS the Tier-1 welcome shell — served same-origin with the lobby so
  the Telegram handshake works. It loads Telegram's web-app SDK, forwards
  `Telegram.WebApp.initData` as the short-lived `tg_init` cookie that `MiniAppAuth`
  redeems at `/lobby`, and links into the lobby ("Играть").

  This is load-bearing for the auth flow: `/lobby` bounces an unauthenticated visitor
  to `/`, so `/` must be the page that can mint a session — not a dead end. The cookie
  is `path=/` on this origin (codemoji.games), so the welcome and `/lobby` MUST share
  an origin; a welcome served from another domain (e.g. static.codemoji.games) could
  not set a cookie `/lobby` can read. The shell's bytes (CSS, logo) load from
  static.codemoji.games; the source is `priv/static/welcome/index.html`.
  """
  use CodemojexWeb, :controller

  # Serve the welcome shell at `/` from its committed source, embedded at compile time.
  # @external_resource recompiles this module whenever the welcome HTML changes.
  @welcome_path Path.expand("../../../priv/static/welcome/index.html", __DIR__)
  @external_resource @welcome_path
  @welcome_html File.read!(@welcome_path)

  def home(conn, _params), do: html(conn, @welcome_html)
end
