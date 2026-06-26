defmodule CodemojexWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :codemojex

  # Real-time: the room channel rides this socket.
  socket "/socket", CodemojexWeb.UserSocket,
    websocket: true,
    longpoll: false

  # Serve the home-page assets (the cm-logo) as Phoenix static files from priv/static/assets.
  plug Plug.Static,
    at: "/",
    from: :codemojex,
    gzip: false,
    only: ["assets"]

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug CodemojexWeb.Router
end
