defmodule CodemojexWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :codemojex

  # The signed session the LiveView socket inherits. The JSON API does not use it
  # (it authenticates per request with a Bearer SES); the browser/LiveView path
  # does — MiniAppAuth writes the SES here, mount reads it.
  @session_options [
    store: :cookie,
    key: "_codemojex_key",
    signing_salt: "cmjxLiveV",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Real-time: the room channel rides this socket (the JSON/Mini App client).
  socket "/socket", CodemojexWeb.UserSocket,
    websocket: true,
    longpoll: false

  # Phoenix-served static files (the LiveView client runtime + the lobby CSS + the
  # welcome shell). The React BOARD bundle is NOT here — it is fetched from
  # edge.codemoji.games at runtime (see Codemojex.Edge). `welcome` is added so the
  # static shell can also be served from this machine in dev.
  plug Plug.Static,
    at: "/",
    from: :codemojex,
    gzip: false,
    only: CodemojexWeb.static_paths()

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug CodemojexWeb.Router
end
