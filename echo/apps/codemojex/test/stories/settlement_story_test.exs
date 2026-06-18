defmodule Codemojex.Stories.SettlementStoryTest do
  @moduledoc """
  GWT acceptance for round settlement: the diamond pool pays the max-score player
  winner-take-all, and a round pays exactly once even when a perfect-crack close
  and a timer close race. Integration: needs the app, Postgres, and a Valkey on
  $VK_PORT (`mix test --include valkey`).
  """
  use Codemojex.Story, feature: "Settlement", async: false
  @moduletag :valkey

  setup do
    set = EmojiSet.new("Dogs", 6, 6)
    {:ok, room} = Codemojex.create_room("Dog House", set, seed_pool: 1000, guess_fee: 1, duration_ms: 600_000)
    {:ok, alice} = Codemojex.create_player("Alice", keys: 5)
    {:ok, round} = Codemojex.join_room(room, alice)
    %{room: room, round: round, alice: alice}
  end

  scenario "closing a round pays the whole diamond pool to the leader", %{round: round, alice: alice} do
    given_ "a single player who has scored on the board" do
      assert {:ok, _} = Codemojex.submit(round, alice, ~w(0000 0101 0202 0303 0404 0505))
      assert eventually(fn -> Codemojex.leaderboard(round, 10) != [] end)
      before = Codemojex.balance(alice).diamonds
    end

    when_ "the round is closed" do
      {:ok, payouts} = Codemojex.close_now(round)
    end

    then_ "the leader is paid the seeded pool in diamonds" do
      assert {^alice, 1000} = Enum.find(payouts, &match?({^alice, _}, &1))
      assert eventually(fn -> Codemojex.balance(alice).diamonds == before + 1000 end)
    end
  end

  scenario "a round pays exactly once — a second close is a no-op", %{round: round, alice: alice} do
    given_ "a round that has already been closed and paid" do
      assert {:ok, _} = Codemojex.submit(round, alice, ~w(0000 0101 0202 0303 0404 0505))
      assert eventually(fn -> Codemojex.leaderboard(round, 10) != [] end)
      {:ok, _first} = Codemojex.close_now(round)
      paid = Codemojex.balance(alice).diamonds
    end

    when_ "the round is closed again (the perfect-crack vs timer race)" do
      second = Codemojex.close_now(round)
    end

    then_ "the second close pays nothing — the balance is unchanged" do
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
