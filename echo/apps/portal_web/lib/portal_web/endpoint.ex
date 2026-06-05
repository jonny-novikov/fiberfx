defmodule PortalWeb.Endpoint do
  @moduledoc """
  The front door for the `:portal_web` app (F6.1-R1, F6.1-D1).

  The outermost plug: a request enters here, traverses the plug stack in declared
  order, and `plug PortalWeb.Router` runs last (F6.1-INV3). `socket "/live"` is
  declared for the LiveView modules a later rung adds; the session plug runs before
  any controller reads the session (F6.1-INV3).
  """
  use Phoenix.Endpoint, otp_app: :portal_web

  # The session is signed (cookie store); the salts/secret resolve from config. The
  # session must be configured before the socket and the parsers reference it.
  @session_options [
    store: :cookie,
    key: "_portal_web_key",
    signing_salt: "8mWqK0Zt",
    same_site: "Lax"
  ]

  # The LiveView socket, declared for the modules a later rung mounts (F6.1-D1). No
  # LiveView is routed at F6.1; the declaration keeps the endpoint ready.
  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve static assets from the app's own priv/static at the root (F6.1-R1; mount
  # corrected F6.5.5). `static_paths/0` (`~w(assets fonts images …)`) is the phx.new
  # default written for `at: "/"`: the URL `/assets/courses.css` keeps its first path
  # segment `assets`, which the `only:` filter admits, and the file resolves at
  # `priv/static/assets/courses.css`. The prior `at: "/assets"` stripped the prefix,
  # leaving the inner first segment `courses.css` (not in `only`) → 404; F6.5.5 is the
  # mount's first consumer, so that latent surfaced here and is corrected to one line.
  plug Plug.Static,
    at: "/",
    from: :portal_web,
    gzip: false,
    only: PortalWeb.static_paths()

  # A correlation id per request, set before telemetry so logs and metrics share it.
  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  # Decode urlencoded/multipart/json bodies (JSON via Jason) before the router.
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  # The router runs last (F6.1-INV3): every prior plug has shaped the conn before a
  # route matches.
  plug PortalWeb.Router
end
