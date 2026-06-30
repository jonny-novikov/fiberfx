defmodule CodemojexWeb.Router do
  use CodemojexWeb, :router

  # --- JSON API (unchanged from the original surface) ---
  pipeline :api do
    plug :accepts, ["json"]
  end

  # cm.4: the read-side trust point for the JSON API. Bearer <SES> -> conn.assigns.player.
  pipeline :auth do
    plug CodemojexWeb.Auth
  end

  # --- the LiveView surface (added) ---
  # The browser pipeline carries the signed session the live socket inherits, and
  # MiniAppAuth lands the SES there (the same handshake the JSON API does over a
  # bearer). put_root_layout wires the LiveView client; the React island is loaded
  # lazily by LiveReact, not here.
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CodemojexWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug CodemojexWeb.MiniAppAuth
  end

  # The welcome (HTML, not the JSON API), served by PageController at /; its assets
  # (welcome/, logo) are served same-origin by Plug.Static (static_paths).
  scope "/", CodemojexWeb do
    get "/", PageController, :home
  end

  # Arm B: the React game island bytes, pulled from the edge by Codemojex.GameBundle and
  # served same-origin from memory. A public scope — a JS module needs no session/auth and
  # should be cacheable; the content-hashed filename is immutable. A distinct prefix so it
  # collides with neither /game (LiveView) nor /assets (Plug.Static).
  scope "/", CodemojexWeb do
    get "/game-bundle/:file", GameBundleController, :show
  end

  # Tier 2/3: the lobby and the game, both LiveViews. join_room returns a GAM, so
  # the game LiveView is keyed by the game id.
  scope "/", CodemojexWeb do
    pipe_through :browser

    live_session :app, session: %{} do
      live "/lobby", LobbyLive, :index
      live "/game/:gam", GameLive, :show
    end
  end

  # Open JSON routes — trust no caller-supplied identity.
  scope "/api", CodemojexWeb do
    pipe_through :api

    get "/health", GameController, :health
    post "/auth/:platform", AuthController, :handshake
    post "/telegram/webhook", TelegramController, :webhook
    get "/rooms", GameController, :rooms
    get "/games/:id", GameController, :game
    get "/games/:id/leaderboard", GameController, :leaderboard
  end

  # Player-acting JSON routes — gated by the :auth plug.
  scope "/api", CodemojexWeb do
    pipe_through [:api, :auth]

    post "/rooms/:id/join", GameController, :join
    post "/games/:id/guess", GameController, :guess
    get "/games/:id/history", GameController, :history
    post "/keys/buy", GameController, :buy_keys
    post "/keys/convert", GameController, :convert
  end
end
