defmodule CodemojexWeb.Router do
  use CodemojexWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  # cm.4: the read-side trust point. Resolves a Bearer <SES> to conn.assigns.player
  # or halts 401. The player-acting routes pipe through it; the handshake does not
  # (it issues the bearer).
  pipeline :auth do
    plug CodemojexWeb.Auth
  end

  # The web home page — the Codemoji logo on a neutral-grey field (HTML, not the JSON API).
  scope "/", CodemojexWeb do
    get "/", PageController, :home
  end

  # Open routes — trust no caller-supplied identity. The handshake is open because
  # it ISSUES the bearer (it verifies initData, not a SES).
  scope "/api", CodemojexWeb do
    pipe_through :api

    get "/health", GameController, :health

    # cm.4: the SOLE SES mint. Verifies Telegram initData → resolves the PLR → mints
    # the SES. POST /api/players is RETIRED (G3) — minting a player now requires a
    # verified handshake.
    post "/auth/:platform", AuthController, :handshake

    # cm.5: the inbound Telegram webhook (the production inbound transport). Open route —
    # authenticated by Telegram's secret-token HEADER in the controller, not a player SES.
    # Inert until CODEMOJI_WEBHOOK_SECRET is set (the controller fails closed). Telegram
    # registers it via setWebhook(url: ".../api/telegram/webhook", secret_token: <secret>).
    post "/telegram/webhook", TelegramController, :webhook

    get "/rooms", GameController, :rooms
    get "/games/:id", GameController, :game
    get "/games/:id/leaderboard", GameController, :leaderboard
  end

  # Player-acting routes — gated by the :auth plug, which assigns conn.assigns.player.
  scope "/api", CodemojexWeb do
    pipe_through [:api, :auth]

    post "/rooms/:id/join", GameController, :join
    post "/games/:id/guess", GameController, :guess
    get "/games/:id/history", GameController, :history
    post "/keys/buy", GameController, :buy_keys
    post "/keys/convert", GameController, :convert
  end
end
