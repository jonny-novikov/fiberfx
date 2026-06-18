defmodule CodemojexWeb.Router do
  use CodemojexWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CodemojexWeb do
    pipe_through :api

    get "/health", GameController, :health
    post "/players", GameController, :create_player

    get "/rooms", GameController, :rooms
    post "/rooms/:id/join", GameController, :join

    get "/rounds/:id", GameController, :round
    post "/rounds/:id/guess", GameController, :guess
    get "/rounds/:id/history", GameController, :history
    get "/rounds/:id/leaderboard", GameController, :leaderboard

    post "/keys/buy", GameController, :buy_keys
    post "/keys/convert", GameController, :convert
  end
end
