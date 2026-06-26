defmodule Codemojex.Stories.GoldenBlindStoryTest do
  @moduledoc """
  GWT acceptance for the blind/sealed Golden flow (cm.3, built LIVE this scope):
  feedback `none` (no score leaks until reveal), commit-reveal (the commitment is
  published at open, the secret+nonce sealed until close), and the one fat
  `revealed` event at the sealed close. The privacy line is EXERCISED with a
  present golden game — the suppression and the reveal both run, with a positive
  proof. Integration: needs the app, Postgres, and a Valkey on $VK_PORT
  (`mix test --include valkey`).
  """
  use Codemojex.Story, feature: "Golden blind", async: false
  @moduletag :valkey

  setup do
    set = EmojiSet.new("Dogs", 6, 6, sprite_url: "https://cdn.example/dogs.png")
    # a long timer so the game stays open through every in-flight submit — the
    # sealed close is triggered EXPLICITLY via `close_now/1` (it dispatches on
    # `settlement == "sealed"` regardless of the timer), so the flow is
    # deterministic, not clock-dependent (no `:expired` race).
    # The BLIND/sealed mode is reached by an explicit type:"golden" (cm.5 R12 —
    # `golden:true` is now the live-tournament marker, a SEPARATE thing). This test
    # exercises the blind commit-reveal flow, so it creates a type:"golden" room.
    {:ok, room} =
      Codemojex.create_room("Golden Den", set,
        type: "golden",
        seed_pool: 1000,
        guess_fee: 1,
        duration_ms: 600_000
      )

    {:ok, alice} = Codemojex.create_player("Alice", keys: 9)
    {:ok, bob} = Codemojex.create_player("Bob", keys: 9)
    {:ok, game} = Codemojex.join_room(room, alice)
    {:ok, ^game} = Codemojex.join_room(room, bob)
    %{room: room, game: game, alice: alice, bob: bob}
  end

  scenario "a golden game publishes the commitment but never the secret or nonce in-flight", %{game: game} do
    given_ "an open golden game whose secret + nonce were minted server-side" do
      :ok
    end

    when_ "the client fetches the game view" do
      view = Codemojex.game_view(game)
    end

    then_ "the commitment is present but the secret and nonce are not, and no score is shown" do
      assert is_binary(view.commitment)
      refute Map.has_key?(view, :secret)
      refute Map.has_key?(view, :nonce)
      # before reveal, the totals carry no score (no :best / :best_pct)
      refute Map.has_key?(view.totals, :best)
      refute Map.has_key?(view.totals, :best_pct)
    end
  end

  scenario "a per-guess scored push does not fire for a golden game", %{game: game, alice: alice} do
    given_ "a client subscribed to the golden game's topic" do
      Phoenix.PubSub.subscribe(Codemojex.PubSub, "game:" <> game)
    end

    when_ "the player submits a guess into the blind game" do
      assert {:ok, _} = Codemojex.submit(game, alice, ~w(0000 0101 0202 0303 0404 0505))
      # give the score worker time to process (it would push if it were classic)
      Process.sleep(300)
    end

    then_ "no :scored message is broadcast in-flight, and the player's history withholds points" do
      refute_received {:scored, _payload}
      # the guess is stored (persisted) but its points are withheld before reveal
      hist = Codemojex.my_history(game, alice)
      assert eventually(fn -> Codemojex.my_history(game, alice) != [] end)
      assert Enum.all?(hist, fn g -> not Map.has_key?(g, :points) end)
      # the leaderboard returns nothing before reveal
      assert Codemojex.leaderboard(game, 10) == []
    end
  end

  scenario "the sealed close reveals the secret and the commitment verifies", %{game: game, alice: alice} do
    given_ "a golden game with a scored guess, subscribed for the reveal" do
      Phoenix.PubSub.subscribe(Codemojex.PubSub, "game:" <> game)
      assert {:ok, _} = Codemojex.submit(game, alice, ~w(0000 0101 0202 0303 0404 0505))
      assert eventually(fn -> Codemojex.my_history(game, alice) != [] end)
    end

    when_ "the game is closed (the sealed pass runs)" do
      {:ok, _payouts} = Codemojex.close_now(game)
    end

    then_ "one revealed event arrives whose secret+nonce recompute to the published commitment" do
      assert_receive {:revealed, payload}, 2_000
      assert is_list(payload.secret)
      assert is_binary(payload.nonce)
      assert payload.state == :settled
      # the binding holds: SHA-256(secret ‖ nonce) == the commitment fixed at open
      assert Codemojex.Rooms.commit(payload.secret, payload.nonce) == payload.commitment
      # after reveal the score is exposed like classic
      assert eventually(fn -> Codemojex.leaderboard(game, 10) != [] end)
    end
  end

  scenario "the sealed settlement is exactly-once — a second close pays nothing", %{game: game, alice: alice} do
    given_ "a golden game closed once (sealed top-K paid)" do
      assert {:ok, _} = Codemojex.submit(game, alice, ~w(0000 0101 0202 0303 0404 0505))
      assert eventually(fn -> Codemojex.my_history(game, alice) != [] end)
      {:ok, _first} = Codemojex.close_now(game)
      paid = Codemojex.balance(alice).diamonds
    end

    when_ "the game is closed again (the sealed pass must not re-pay)" do
      second = Codemojex.close_now(game)
    end

    then_ "the second close is a no-op and the balance is unchanged" do
      assert second == {:ok, :already_closed}
      assert Codemojex.balance(alice).diamonds == paid
    end
  end

  defp eventually(fun, tries \\ 50)
  defp eventually(_fun, 0), do: false
  defp eventually(fun, tries) do
    if fun.(), do: true, else: (Process.sleep(20); eventually(fun, tries - 1))
  end
end
