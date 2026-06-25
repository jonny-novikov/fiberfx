defmodule Codemojex.Stories.RoomsAndGamesStoryTest do
  @moduledoc """
  GWT acceptance for the room/game lifecycle. Integration: needs the app up
  (Repo + PubSub + EchoMQ bus + consumers) against Postgres and a Valkey on
  $VK_PORT. Run with `mix test --include valkey` (and a created/migrated DB).
  """
  use Codemojex.Story, feature: "Rooms and games", async: false
  @moduletag :valkey

  setup do
    set = EmojiSet.new("Dogs", 6, 6, sprite_url: "https://cdn.example/dogs.png")
    {:ok, room} = Codemojex.create_room("Dog House", set, seed_pool: 200, guess_fee: 1, duration_ms: 600_000)
    {:ok, alice} = Codemojex.create_player("Alice", keys: 5)
    {:ok, bob} = Codemojex.create_player("Bob", keys: 5)
    %{set: set, room: room, alice: alice, bob: bob}
  end

  scenario "the first player to join a waiting room opens its game", %{room: room, alice: alice} do
    given_ "a freshly created room in the waiting state" do
      :ok
    end

    when_ "the first player joins" do
      {:ok, game} = Codemojex.join_room(room, alice)
    end

    then_ "a game is opened with the room's keyboard and a running timer" do
      view = Codemojex.game_view(game)
      assert view.status == :open
      assert view.ends_ms > System.system_time(:millisecond)
      assert view.emojiset.count == 36
    end
  end

  scenario "a later joiner lands in the same active game", %{room: room, alice: alice, bob: bob} do
    given_ "a game already opened by the first joiner" do
      {:ok, game} = Codemojex.join_room(room, alice)
    end

    when_ "a second player joins the same room" do
      {:ok, second} = Codemojex.join_room(room, bob)
    end

    then_ "both joins resolve to one and the same game id" do
      assert second == game
    end
  end

  scenario "the prize pool is seeded in diamonds and shown to the lobby in USD", %{room: room, alice: alice} do
    given_ "a room seeded with 200 diamonds" do
      {:ok, game} = Codemojex.join_room(room, alice)
    end

    then_ "the game view reports the pool and its USD value" do
      view = Codemojex.game_view(game)
      assert view.prize_pool == 200
      assert view.prize_usd == Codemojex.Economy.to_usd(200)
    end
  end

  scenario "a guess submitted on the lane is scored and reaches the leaderboard", %{room: room, alice: alice} do
    given_ "an open game" do
      {:ok, game} = Codemojex.join_room(room, alice)
    end

    when_ "the player submits a valid six-emoji guess" do
      assert {:ok, _} = Codemojex.submit(game, alice, ~w(0000 0101 0202 0303 0404 0505))
    end

    then_ "the score worker records it and the player appears on the leaderboard" do
      assert eventually(fn -> Enum.any?(Codemojex.leaderboard(game, 10), &match?({^alice, _}, &1)) end)
    end
  end

  # Retry a Valkey/async assertion until it holds (the score worker is async).
  defp eventually(fun, tries \\ 50)
  defp eventually(_fun, 0), do: false
  defp eventually(fun, tries) do
    if fun.() do
      true
    else
      Process.sleep(20)
      eventually(fun, tries - 1)
    end
  end
end
