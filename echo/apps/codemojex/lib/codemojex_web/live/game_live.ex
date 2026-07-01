defmodule CodemojexWeb.GameLive do
  @moduledoc """
  Tier 3 — the game. The LiveView is the shell: it resolves the player and the
  `GAM`, reads the privacy-preserving `Codemojex.game_view/1` + leaderboard once on
  the server, and hands them to the React `GameEdge` as props. React mounts
  populated — no client fetch, no spinner.

  The component CODE is not baked into this release: `Codemojex.Edge.game_url/0`
  resolves the current bundle on edge.codemoji.games, `Codemojex.GameBundle` pulls
  those bytes once and serves them **same-origin** from memory, and the `GameIsland`
  hook dynamic-imports `GameBundle.src/0` — so a game change is an edge deploy, not a
  `fly deploy`. The LiveReact bridge pattern (props in, `pushEvent` out over the live
  socket) is preserved; only the bundle's serve layer moves on-machine.

  The game never scores. A submitted guess is `Codemojex.submit/3`, which enqueues
  a `JOB` on the player's lane (the engine is async); the score lands later as a
  `{:scored, …}` broadcast on `"game:"<>game` — the same topic `RoomChannel` uses —
  and this LiveView pushes a prop diff. The secret and other players' guesses never
  cross this boundary (the view withholds them).
  """
  use CodemojexWeb, :live_view

  alias Codemojex.{GameBundle, Session, Store}

  @impl true
  def mount(%{"gam" => gam}, session, socket) do
    with {:ok, %{plr: plr}} <- Session.resolve(session["ses"]),
         {:ok, "GAM", _snow} <- EchoData.BrandedId.parse(gam),
         view when is_map(view) <- Codemojex.game_view(gam) do
      if connected?(socket), do: Phoenix.PubSub.subscribe(Codemojex.PubSub, "game:" <> gam)

      {:ok,
       socket
       |> assign(player: plr, game: gam, page_title: "Codemoji", game_bundle: dev_bundle_url())
       |> assign(game_props: game_props(gam, plr, view))}
    else
      _ -> {:ok, socket |> put_flash(:error, "Room not found") |> push_navigate(to: ~p"/lobby")}
    end
  end

  # Dev-only local-serve override. When GAME_DEV_URL is set (the game's Vite dev
  # server — e.g. http://127.0.0.1:5173/src/index.tsx — or a locally-built bundle),
  # the game module loads from there instead of the same-origin GameBundle serve, so
  # a local edit shows in the running app with no edge deploy. Unset in prod (and in
  # config/runtime.exs), so GameBundle.src/0 stands — this branch is inert there.
  defp dev_bundle_url, do: System.get_env("GAME_DEV_URL") || GameBundle.src()

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- warm the same-origin game bytes while LiveView boots; strictly additive --%>
    <link :if={@game_bundle} rel="modulepreload" href={@game_bundle} />
    <div
      id="game-root"
      class="game-root"
      phx-hook="GameIsland"
      phx-update="ignore"
      data-bundle={@game_bundle}
      data-component="GameEdge"
      data-props={Jason.encode!(@game_props)}
    >
    </div>
    """
  end

  # --- play: enqueue only; the score returns over PubSub ---
  @impl true
  def handle_event("submit_guess", %{"emojis" => emojis}, socket) when is_list(emojis) do
    case Codemojex.submit(socket.assigns.game, socket.assigns.player, emojis) do
      {:ok, _job} -> {:noreply, socket}
      {:error, reason} -> {:noreply, push_event(socket, "guess_rejected", %{reason: to_string(reason)})}
    end
  end

  def handle_event("lock", %{"pos" => pos, "code" => code}, socket) do
    Codemojex.lock(socket.assigns.game, socket.assigns.player, pos, code)
    {:noreply, socket}
  end

  def handle_event("unlock", %{"pos" => pos}, socket) do
    Codemojex.unlock(socket.assigns.game, socket.assigns.player, pos)
    {:noreply, socket}
  end

  # --- live engine events: push fresh props (the mount point is phx-update=ignore,
  # so updates ride push_event, not a re-render of data-props) ---
  @impl true
  def handle_info({:scored, _payload}, socket), do: {:noreply, push_props(socket)}
  def handle_info({:golden_win, payload}, socket), do: {:noreply, push_event(socket, "golden_win", payload)}

  def handle_info({:revealed, payload}, socket) do
    {:noreply, socket |> push_event("revealed", payload) |> push_props()}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp push_props(socket) do
    %{game: gam, player: plr} = socket.assigns

    case Codemojex.game_view(gam) do
      view when is_map(view) -> push_event(socket, "game:update", game_props(gam, plr, view))
      _ -> socket
    end
  end

  # The game's whole initial state, server-resolved. Mirrors what RoomChannel.join
  # returns, widened with the player's own history and the named leaderboard.
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
