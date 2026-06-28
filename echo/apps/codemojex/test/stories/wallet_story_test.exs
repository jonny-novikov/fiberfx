defmodule Codemojex.Stories.WalletStoryTest do
  @moduledoc """
  GWT acceptance for the three-currency wallet: keys for paid rooms, clips for
  free rooms, diamonds as the prize currency, every move atomic and never below
  zero. Integration: needs the app, Postgres, and a Valkey on $VK_PORT
  (`mix test --include valkey`).
  """
  use Codemojex.Story, feature: "Wallet", async: false
  @moduletag :valkey

  setup do
    set = EmojiSet.new("Dogs", 6, 6)
    {:ok, paid} = Codemojex.create_room("Paid", set, guess_fee: 1, duration_ms: 600_000)
    {:ok, free} = Codemojex.create_room("Free", set, free: true, clip_cost: 1, duration_ms: 600_000)
    %{paid: paid, free: free}
  end

  scenario "a guess in a paid room is charged one key and leaves clips untouched", %{paid: paid} do
    given_ "a player with keys but no clips, in an opened paid game" do
      {:ok, p} = Codemojex.create_player("Pat", keys: 3)
      {:ok, game} = Codemojex.join_room(paid, p)
    end

    when_ "the player submits a guess" do
      assert {:ok, _} = Codemojex.submit(game, p, ~w(0000 0101 0202 0303 0404 0505))
    end

    then_ "one key is debited and clips stay at zero" do
      bal = Codemojex.balance(p)
      assert bal.keys == 2
      assert bal.clips == 0
    end
  end

  scenario "a guess in a free room spends a clip, never a key", %{free: free} do
    given_ "a player with clips, in an opened free game" do
      {:ok, p} = Codemojex.create_player("Free Fiona", keys: 0, clips: 3)
      {:ok, game} = Codemojex.join_room(free, p)
    end

    when_ "the player submits a guess" do
      assert {:ok, _} = Codemojex.submit(game, p, ~w(0000 0101 0202 0303 0404 0505))
    end

    then_ "a clip is debited and keys remain at zero" do
      bal = Codemojex.balance(p)
      assert bal.clips == 2
      assert bal.keys == 0
    end
  end

  scenario "a player with no keys cannot guess in a paid room, and the balance never goes negative", %{paid: paid} do
    given_ "a player with zero keys in an opened paid game" do
      {:ok, p} = Codemojex.create_player("Broke Bo", keys: 0)
      {:ok, game} = Codemojex.join_room(paid, p)
    end

    when_ "the player attempts a guess" do
      result = Codemojex.submit(game, p, ~w(0000 0101 0202 0303 0404 0505))
    end

    then_ "the guess is refused for insufficient funds and keys are still zero (never below)" do
      assert result == {:error, :insufficient}
      assert Codemojex.balance(p).keys == 0
    end
  end

  scenario "buying keys credits the balance" do
    given_ "a player" do
      {:ok, p} = Codemojex.create_player("Buyer Bea", keys: 0)
    end

    when_ "they buy 5 keys (paid externally via Stars)" do
      # cm.7 retired the Codemojex.purchase_keys facade (the double-mint client path, S6);
      # the wallet credit primitive still proves a keys purchase credits the balance.
      assert {:ok, _} = Codemojex.Wallet.purchase_keys(p, 5, "PMTstars000001")
    end

    then_ "the key balance reflects the purchase" do
      assert Codemojex.balance(p).keys == 5
    end
  end

  scenario "diamonds convert to keys at 10:1, and a non-multiple is refused" do
    given_ "a player holding 25 diamonds" do
      {:ok, p} = Codemojex.create_player("Rich Rae", diamonds: 25)
    end

    when_ "they convert 20 diamonds" do
      assert {:ok, _} = Codemojex.convert_to_keys(p, 20)
    end

    then_ "they receive 2 keys and keep the leftover 5 diamonds" do
      bal = Codemojex.balance(p)
      assert bal.keys == 2
      assert bal.diamonds == 5
    end

    but_ "converting a non-multiple of 10 is refused with the balance unchanged" do
      assert Codemojex.convert_to_keys(p, 3) == {:error, :bad_amount}
      assert Codemojex.balance(p).diamonds == 5
    end
  end
end
