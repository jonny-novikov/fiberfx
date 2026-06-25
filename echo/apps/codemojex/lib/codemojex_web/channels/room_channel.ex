defmodule CodemojexWeb.RoomChannel do
  @moduledoc """
  The live game. Joining `game:<id>` subscribes this channel to the matching
  PubSub topic; when the scoring worker finishes an attempt for a classic game it
  broadcasts `:scored` there, and the channel pushes it to the client — the
  leaderboard updates without any per-game process. A golden game carries state +
  timer only in-flight (no scores); at its sealed close one fat `revealed` event
  arrives with the secret, the board, and the top-K payouts. Joins return the game
  view (never the secret); a `refresh` re-reads the view and the leaderboard on
  demand.
  """
  use CodemojexWeb, :channel

  @impl true
  def join("game:" <> game, _params, socket) do
    {:ok, %{view: Codemojex.game_view(game)}, assign(socket, :game, game)}
  end

  @impl true
  def handle_info({:scored, payload}, socket) do
    push(socket, "scored", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:revealed, payload}, socket) do
    push(socket, "revealed", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:golden_win, payload}, socket) do
    push(socket, "golden_win", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_in("refresh", _params, socket) do
    game = socket.assigns.game

    reply = %{
      view: Codemojex.game_view(game),
      leaderboard: Enum.map(Codemojex.leaderboard(game, 20), fn {p, s} -> %{player: p, score: s} end)
    }

    {:reply, {:ok, reply}, socket}
  end
end
