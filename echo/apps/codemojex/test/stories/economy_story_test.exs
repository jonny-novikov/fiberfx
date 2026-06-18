defmodule Codemojex.Stories.EconomyStoryTest do
  @moduledoc "GWT acceptance for the pure three-currency money math. No balances, no DB — runs anywhere."
  use Codemojex.Story, feature: "Economy", async: true

  scenario "diamonds convert to keys at a fixed 10:1, floored" do
    given_ "the fixed conversion rate of 10 diamonds per key" do
      assert Economy.diamonds_per_key() == 10
    end

    then_ "283 diamonds yield 28 keys (the remainder does not round up)" do
      assert Economy.keys_from_diamonds(283) == 28
      assert Economy.diamonds_for_keys(3) == 30
    end
  end

  scenario "a diamond amount renders as USD at 1.2 cents each" do
    given_ "the price of a diamond is 1.2 US cents" do
      :ok
    end

    then_ "283 diamonds is $3.40 and 100 diamonds is $1.20" do
      assert Economy.to_cents(283) == 340
      assert Economy.to_usd(283) == "$3.40"
      assert Economy.to_usd(100) == "$1.20"
    end
  end

  scenario "the whole pool goes to the single highest score" do
    given_ "a finished board with one clear leader" do
      board = [{"PLRalice00000", 600}, {"PLRbob0000000", 400}]
    end

    when_ "the pool settles winner-take-all" do
      payouts = Economy.winner_take_all(1000, board)
    end

    then_ "the leader takes the entire diamond pool" do
      assert payouts == [{"PLRalice00000", 1000}]
    end
  end

  scenario "a tie for first splits the pool evenly" do
    given_ "two players tied at the top score" do
      board = [{"PLRa000000000", 600}, {"PLRb000000000", 600}, {"PLRc000000000", 400}]
    end

    when_ "the pool settles winner-take-all" do
      payouts = Economy.winner_take_all(1000, board)
    end

    then_ "the two leaders split the pool and the rest get nothing" do
      assert payouts == [{"PLRa000000000", 500}, {"PLRb000000000", 500}]
    end
  end

  scenario "settlement is pure: re-running pays identically" do
    given_ "a board and a pool" do
      board = [{"PLRa000000000", 520}, {"PLRb000000000", 520}]
    end

    then_ "two settlements of the same inputs are equal" do
      assert Economy.winner_take_all(900, board) == Economy.winner_take_all(900, board)
    end
  end

  scenario "the lobby progress bar is the best score as a percent of 600" do
    then_ "600 is 100%, 180 is 30%, 80 is 13.33%" do
      assert Economy.progress_pct(600) == 100.0
      assert Economy.progress_pct(180) == 30.0
      assert Economy.progress_pct(80) == 13.33
    end
  end
end
