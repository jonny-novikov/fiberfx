defmodule Codemojex.Stories.PrivacyStoryTest do
  @moduledoc """
  GWT acceptance for the privacy invariant: a player never sees the secret or
  another player's guesses — only their own history, the max-score leaderboard,
  and the keyboard. Integration: needs the app, Postgres, and a Valkey on
  $VK_PORT (`mix test --include valkey`).
  """
  use Codemojex.Story, feature: "Privacy", async: false
  @moduletag :valkey

  setup do
    set = EmojiSet.new("Dogs", 6, 6, sprite_url: "https://cdn.example/dogs.png")
    {:ok, room} = Codemojex.create_room("Dog House", set, guess_fee: 1, duration_ms: 600_000)
    {:ok, alice} = Codemojex.create_player("Alice", keys: 5)
    {:ok, bob} = Codemojex.create_player("Bob", keys: 5)
    {:ok, round} = Codemojex.join_room(room, alice)
    {:ok, ^round} = Codemojex.join_room(room, bob)
    %{round: round, alice: alice, bob: bob}
  end

  scenario "the round view never carries the secret", %{round: round} do
    given_ "an open round whose secret was minted server-side" do
      :ok
    end

    when_ "the client fetches the round view" do
      view = Codemojex.round_view(round)
    end

    then_ "there is no :secret key anywhere in the view — only the keyboard snapshot" do
      refute Map.has_key?(view, :secret)
      assert is_list(view.emojiset.codes)
      refute Map.has_key?(view.emojiset, :secret)
    end
  end

  scenario "a player's history shows only their own attempts", %{round: round, alice: alice, bob: bob} do
    given_ "both players have submitted a guess" do
      assert {:ok, _} = Codemojex.submit(round, alice, ~w(0000 0101 0202 0303 0404 0505))
      assert {:ok, _} = Codemojex.submit(round, bob, ~w(0505 0404 0303 0202 0101 0000))
      assert eventually(fn -> length(Codemojex.my_history(round, alice)) >= 1 and length(Codemojex.my_history(round, bob)) >= 1 end)
    end

    when_ "Alice reads her history" do
      mine = Codemojex.my_history(round, alice)
    end

    then_ "she sees her own guess and nothing of Bob's" do
      assert Enum.any?(mine, fn g -> g.emojis == ~w(0000 0101 0202 0303 0404 0505) end)
      refute Enum.any?(mine, fn g -> g.emojis == ~w(0505 0404 0303 0202 0101 0000) end)
    end
  end

  scenario "the leaderboard exposes scores, never guess content", %{round: round, alice: alice} do
    given_ "a scored attempt on the board" do
      assert {:ok, _} = Codemojex.submit(round, alice, ~w(0000 0101 0202 0303 0404 0505))
      assert eventually(fn -> Codemojex.leaderboard(round, 10) != [] end)
    end

    when_ "the leaderboard is read" do
      board = Codemojex.leaderboard(round, 10)
    end

    then_ "every row is a {player, score} pair with no emojis attached" do
      assert Enum.all?(board, fn row -> match?({p, s} when is_binary(p) and is_integer(s), row) end)
    end
  end

  defp eventually(fun, tries \\ 50)
  defp eventually(_fun, 0), do: false
  defp eventually(fun, tries) do
    if fun.(), do: true, else: (Process.sleep(20); eventually(fun, tries - 1))
  end
end
