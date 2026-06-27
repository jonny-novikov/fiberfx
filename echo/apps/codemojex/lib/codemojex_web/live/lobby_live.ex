defmodule CodemojexWeb.LobbyLive do
  @moduledoc """
  Tier 2 — the lobby. Pure LiveView: the room cards from `Codemojex.lobby/0` are
  server-rendered HEEx and patched in place; no React reaches this page. A live
  prize pool rides PubSub (`"lobby"`) plus a low-frequency re-read; selecting a
  room is `Codemojex.join_room/2`, which starts or enters the game and returns the
  `GAM` we navigate to. The card fields are exactly the view's: USD prize, emoji
  count, cells, and the leader's progress.
  """
  use CodemojexWeb, :live_view

  alias Codemojex.Session

  @tick_ms 3_000

  @impl true
  def mount(_params, session, socket) do
    case Session.resolve(session["ses"]) do
      {:ok, %{plr: plr}} ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(Codemojex.PubSub, "lobby")
          Process.send_after(self(), :tick, @tick_ms)
        end

        {:ok,
         socket
         |> assign(player: plr, page_title: "Codemoji")
         |> stream(:rooms, cards())}

      _ ->
        {:ok, redirect(socket, to: ~p"/")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="lobby">
      <h1 class="lobby__title">Выбери сейф, чтобы начать</h1>
      <p class="lobby__hint">Получай ключи, чтобы подобрать эмодзи код</p>

      <ul id="rooms" phx-update="stream" class="lobby__rooms">
        <li :for={{dom_id, room} <- @streams.rooms} id={dom_id} class="room-card">
          <div class="room-card__head">
            <span class="room-card__name">{room.name}</span>
            <span class="room-card__prize">${room.prize_usd}</span>
          </div>
          <div class="room-card__meta">
            {room.emoji_count} эмодзи / {room.cells} ячеек
          </div>
          <div class="room-card__bar"><span style={"width:#{room.progress_pct}%"}></span></div>
          <button phx-click="enter_room" phx-value-id={room.room} class="room-card__enter">
            <%= if room.free do %>Бесплатно<% else %>Открыть сейф · {room.guess_fee}<% end %>
          </button>
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def handle_event("enter_room", %{"id" => room}, socket) do
    case Codemojex.join_room(room, socket.assigns.player) do
      {:ok, gam} -> {:noreply, push_navigate(socket, to: ~p"/game/#{gam}")}
      {:error, reason} -> {:noreply, put_flash(socket, :error, reason_text(reason))}
    end
  end

  @impl true
  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, @tick_ms)
    {:noreply, upsert(socket)}
  end

  def handle_info({:lobby_changed}, socket), do: {:noreply, upsert(socket)}
  def handle_info(_msg, socket), do: {:noreply, socket}

  # Re-read the (small) room list and upsert each card; the stream patches only
  # what changed. Streams are kept so this scales if the room count grows.
  defp upsert(socket) do
    Enum.reduce(cards(), socket, fn card, acc -> stream_insert(acc, :rooms, card) end)
  end

  # `Codemojex.lobby/0` cards keyed by their ROM id for the stream dom id.
  defp cards do
    Enum.map(Codemojex.lobby(), fn card -> Map.put(card, :id, card.room) end)
  end

  defp reason_text(:insufficient_keys), do: "Недостаточно ключей"
  defp reason_text(:no_room), do: "Комната недоступна"
  defp reason_text(other), do: to_string(other)
end
