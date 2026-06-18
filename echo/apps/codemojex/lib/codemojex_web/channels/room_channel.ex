defmodule CodemojexWeb.RoomChannel do
  @moduledoc """
  The live round. Joining `round:<id>` subscribes this channel to the matching
  PubSub topic; when the scoring worker finishes an attempt it broadcasts `:scored`
  there, and the channel pushes it to the client — the leaderboard updates without
  any per-room process. Joins return the round view (never the secret); a `refresh`
  re-reads the view and the leaderboard on demand.
  """
  use CodemojexWeb, :channel

  @impl true
  def join("round:" <> round, _params, socket) do
    {:ok, %{view: Codemojex.round_view(round)}, assign(socket, :round, round)}
  end

  @impl true
  def handle_info({:scored, payload}, socket) do
    push(socket, "scored", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_in("refresh", _params, socket) do
    round = socket.assigns.round

    reply = %{
      view: Codemojex.round_view(round),
      leaderboard: Enum.map(Codemojex.leaderboard(round, 20), fn {p, s} -> %{player: p, score: s} end)
    }

    {:reply, {:ok, reply}, socket}
  end
end
