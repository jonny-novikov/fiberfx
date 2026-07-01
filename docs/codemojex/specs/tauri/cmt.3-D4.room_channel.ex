defmodule CodemojexWeb.RoomChannel do
  @moduledoc """
  The live game over a Phoenix channel — the channel-transport twin of
  `CodemojexWeb.GameLive`. Joining `game:<id>` subscribes this channel to the
  matching PubSub topic and returns the full game props (view, leaderboard,
  history, me); the secret is never sent. Guesses, locks, and unlocks come in
  over the channel and route through the same `Codemojex` calls the LiveView
  uses. When the scoring worker finishes an attempt for a classic game it
  broadcasts `:scored` on the topic and the channel pushes fresh props as
  `game:update`, so the leaderboard updates without any per-game process. A
  golden game carries state + timer only in-flight (no scores); at its sealed
  close one `revealed` event arrives with the secret, the board, and the top-K
  payouts. A `refresh` re-reads the props on demand.
  """
  use CodemojexWeb, :channel

  alias Codemojex.Store

  @impl true
  def join("game:" <> game, _params, socket) do
    socket = assign(socket, :game, game)
    {:ok, props(socket), socket}
  end

  # --- inbound: mirror GameLive.handle_event/3 (same Codemojex calls) ---

  @impl true
  def handle_in("submit_guess", %{"emojis" => emojis}, socket) when is_list(emojis) do
    case Codemojex.submit(socket.assigns.game, socket.assigns.player, emojis) do
      {:ok, _job} ->
        {:noreply, socket}

      {:error, reason} ->
        push(socket, "guess_rejected", %{reason: to_string(reason)})
        {:noreply, socket}
    end
  end

  def handle_in("lock", %{"pos" => pos, "code" => code}, socket) do
    Codemojex.lock(socket.assigns.game, socket.assigns.player, pos, code)
    {:noreply, socket}
  end

  def handle_in("unlock", %{"pos" => pos}, socket) do
    Codemojex.unlock(socket.assigns.game, socket.assigns.player, pos)
    {:noreply, socket}
  end

  def handle_in("refresh", _params, socket) do
    {:reply, {:ok, props(socket)}, socket}
  end

  # --- outbound: topic broadcasts pushed to the client (mirror GameLive) ---

  @impl true
  def handle_info({:scored, _payload}, socket), do: {:noreply, push_props(socket)}

  def handle_info({:golden_win, payload}, socket) do
    push(socket, "golden_win", payload)
    {:noreply, socket}
  end

  def handle_info({:revealed, payload}, socket) do
    push(socket, "revealed", payload)
    {:noreply, push_props(socket)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  # --- props (mirror GameLive.game_props/3, named/2, player_name/1) ---

  defp props(socket) do
    %{game: gam, player: plr} = socket.assigns
    game_props(gam, plr, Codemojex.game_view(gam))
  end

  defp push_props(socket) do
    %{game: gam, player: plr} = socket.assigns

    case Codemojex.game_view(gam) do
      view when is_map(view) ->
        push(socket, "game:update", game_props(gam, plr, view))
        socket

      _ ->
        socket
    end
  end

  defp game_props(gam, plr, view) do
    %{
      view: view,
      leaderboard: named(Codemojex.leaderboard(gam, 20), plr),
      history: Codemojex.my_history(gam, plr, 50),
      me: plr
    }
  end

  defp named(rows, me) do
    Enum.map(rows, fn {p, s} -> %{player: p, name: player_name(p), score: s, is_me: p == me} end)
  end

  defp player_name(plr) do
    case Store.player(plr) do
      %{name: name} -> name
      _ -> "?"
    end
  end
end
