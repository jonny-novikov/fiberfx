defmodule CodemojexWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :codemojex

  # Real-time: the room channel rides this socket.
  socket "/socket", CodemojexWeb.UserSocket,
    websocket: true,
    longpoll: false

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
