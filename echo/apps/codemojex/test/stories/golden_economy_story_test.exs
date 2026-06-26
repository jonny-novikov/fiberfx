defmodule Codemojex.Stories.GoldenEconomyStoryTest do
  @moduledoc """
  GWT acceptance for the Golden Room economy (cm.5 D-7): the virtual-deposit revenue
  model, the entry-fee waterfall, the two-sided guess→pool, the exactly-once buy-in,
  and the structural invariants (a buy-in room is not free; no boost survives; a
  golden tournament is classic-typed). Integration: needs the app, Postgres, and a
  Valkey on $VK_PORT (`mix test --include valkey`).
  """
  use Codemojex.Story, feature: "Golden economy", async: false
  @moduletag :valkey

  alias Codemojex.{Wallet, Store}

  # A Golden Room with a small gather threshold so the bands are reachable in a test:
  # start_threshold 2 (the first 2 fees recover the deposit), first_movers 1 (the 3rd
  # member splits its fee to the pool), revenue 50% (so the pool gets 4 keys' worth).
  setup do
    set = EmojiSet.new("Dogs", 6, 6, sprite_url: "https://cdn.example/dogs.png")

    {:ok, room} =
      Codemojex.create_golden_room("Golden Den", set,
        entry_fee_keys: 8,
        virtual_deposit: 1000,
        start_threshold: 2,
        first_movers: 1,
        entry_fee_revenue_percentage: 50,
        duration_ms: 600_000,
        room_deadline: deadline(48 * 3600)
      )

    %{room: room, set: set}
  end

  scenario "the pool seeds with the virtual deposit and the deposit-recovery fees do not fund it",
           %{room: room} do
    given_ "a Golden Room (virtual_deposit 1000, start_threshold 2)" do
      {:ok, alice} = Codemojex.create_player("Alice", keys: 8)
      {:ok, bob} = Codemojex.create_player("Bob", keys: 8)
    end

    when_ "the game forms and the first two members buy in (the deposit-recovery band)" do
      {:ok, game} = Codemojex.join_room(room, alice)
      {:ok, ^game} = Codemojex.join_room(room, bob)
    end

    then_ "the pool stayed at the virtual deposit (the fees were platform revenue) and each member's keys fell by 8" do
      # the pool is the seeded virtual_deposit — the first start_threshold fees recover
      # it (pool credit 0), they did NOT add to it (INV-VIRTUAL-DEPOSIT)
      assert Store.game(game).prize_pool == 1000
      assert Codemojex.balance(alice).keys == 0
      assert Codemojex.balance(bob).keys == 0
    end
  end

  scenario "a first-mover splits its entry fee into the pool; the next member is pure revenue",
           %{room: room} do
    given_ "a Golden Room past its gather threshold (2 members in, deposit recovered)" do
      {:ok, a} = Codemojex.create_player("A", keys: 8)
      {:ok, b} = Codemojex.create_player("B", keys: 8)
      {:ok, c} = Codemojex.create_player("C", keys: 8)
      {:ok, d} = Codemojex.create_player("D", keys: 8)
      {:ok, game} = Codemojex.join_room(room, a)
      {:ok, ^game} = Codemojex.join_room(room, b)
      pool_after_gather = Store.game(game).prize_pool
    end

    when_ "the first-mover (member 3) then member 4 buy in" do
      {:ok, ^game} = Codemojex.join_room(room, c)
      pool_after_first_mover = Store.game(game).prize_pool
      {:ok, ^game} = Codemojex.join_room(room, d)
      pool_after_revenue = Store.game(game).prize_pool
    end

    then_ "the pool rose by floor(8×(100-50)/100)×10 = 40 for the first-mover and by 0 for member 4" do
      # first_movers band: floor(entry_fee_keys × (100−revenue%)/100) × 10 = floor(4)×10 = 40 💎
      assert pool_after_first_mover == pool_after_gather + 40
      # member 4 is beyond start_threshold + first_movers → 100% platform revenue, pool += 0
      assert pool_after_revenue == pool_after_first_mover
    end
  end

  scenario "a guess funds the pool by its full fee ×10 (golden two-sided charge)", %{room: room} do
    given_ "a golden game with a member who has spare keys to guess" do
      {:ok, a} = Codemojex.create_player("A", keys: 8)
      {:ok, b} = Codemojex.create_player("B", keys: 9)
      {:ok, game} = Codemojex.join_room(room, a)
      # the second buy-in arms the timer (start_threshold 2) → :open, so guesses flow
      {:ok, ^game} = Codemojex.join_room(room, b)
      pool_before = Store.game(game).prize_pool
      keys_before = Codemojex.balance(b).keys
    end

    when_ "the member submits a charged guess (guess_fee 1 key)" do
      assert {:ok, _} = Codemojex.submit(game, b, ~w(0000 0101 0202 0303 0404 0505))
      assert eventually(fn -> Store.game(game).prize_pool > pool_before end)
    end

    then_ "the pool rose by fee×10 = 10 💎 and the member's keys fell by the fee" do
      assert Store.game(game).prize_pool == pool_before + 10
      assert Codemojex.balance(b).keys == keys_before - 1
    end
  end

  scenario "the buy-in is exactly-once and two-sided — a re-join does not double-charge",
           %{room: room} do
    given_ "a member who has bought in once (a first-mover, so the pool moved)" do
      {:ok, a} = Codemojex.create_player("A", keys: 8)
      {:ok, b} = Codemojex.create_player("B", keys: 8)
      {:ok, c} = Codemojex.create_player("C", keys: 16)
      {:ok, game} = Codemojex.join_room(room, a)
      {:ok, ^game} = Codemojex.join_room(room, b)
      {:ok, ^game} = Codemojex.join_room(room, c)
      keys_after_first = Codemojex.balance(c).keys
      pool_after_first = Store.game(game).prize_pool
      members_after_first = length(Store.members(game))
    end

    when_ "the same member buys in again (a re-join)" do
      second = Wallet.buy_in(c, game)
    end

    then_ "keys are debited once, the pool moved once, exactly one buy_in TXN exists, and the second call says :already_member" do
      assert second == {:ok, :already_member}
      assert Codemojex.balance(c).keys == keys_after_first
      assert Store.game(game).prize_pool == pool_after_first
      assert length(Store.members(game)) == members_after_first
      assert Store.paid_count(game) == 3
    end
  end

  scenario "a buy-in room cannot be free", %{set: set} do
    given_ "a request for a golden room that is also free" do
      :ok
    end

    when_ "the room is created free + golden" do
      result = Codemojex.create_golden_room("Bad Room", set, free: true, entry_fee_keys: 8)
    end

    then_ "the changeset is invalid (INV-NOTFREE)" do
      assert {:error, %Ecto.Changeset{} = cs} = result
      assert Keyword.has_key?(cs.errors, :free)
    end
  end

  scenario "a golden:true room is a classic tournament, not the blind mode", %{room: room} do
    given_ "a Golden Room created via create_golden_room" do
      :ok
    end

    when_ "the room is read back" do
      r = Store.room(room)
    end

    then_ "it is type:classic, golden:true, start_threshold 2 — the blind type:golden is a separate thing" do
      assert r.type == "classic"
      assert r.golden == true
      assert r.start_threshold == 2
    end
  end

  defp deadline(seconds_from_now) do
    DateTime.utc_now() |> DateTime.add(seconds_from_now, :second) |> DateTime.truncate(:second)
  end

  defp eventually(fun, tries \\ 50)
  defp eventually(_fun, 0), do: false
  defp eventually(fun, tries) do
    if fun.(), do: true, else: (Process.sleep(20); eventually(fun, tries - 1))
  end
end
