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

  scenario "the sealed top-K split pays each rank its configured weight share" do
    given_ "a full board and the default [40,25,15,12,8] split over a 1000 pool" do
      board = [
        {"PLR1000000000", 600},
        {"PLR2000000000", 500},
        {"PLR3000000000", 400},
        {"PLR4000000000", 300},
        {"PLR5000000000", 200},
        {"PLR6000000000", 100}
      ]
    end

    when_ "the pool settles top-K (K = 5)" do
      payouts = Economy.top_k_split(1000, Enum.take(board, 5), [40, 25, 15, 12, 8])
    end

    then_ "only the top 5 are paid, each its weight share of the pool" do
      assert payouts == [
               {"PLR1000000000", 400},
               {"PLR2000000000", 250},
               {"PLR3000000000", 150},
               {"PLR4000000000", 120},
               {"PLR5000000000", 80}
             ]
    end
  end

  scenario "a configured split can differ from the default" do
    given_ "a two-rank room split [70,30] over a 1000 pool" do
      board = [{"PLRa000000000", 600}, {"PLRb000000000", 400}]
    end

    when_ "the pool settles by the room's own split" do
      payouts = Economy.top_k_split(1000, board, [70, 30])
    end

    then_ "the two leaders take 70% and 30%" do
      assert payouts == [{"PLRa000000000", 700}, {"PLRb000000000", 300}]
    end
  end

  scenario "the split normalizes when fewer players than weights are present" do
    given_ "only two players but a five-weight split" do
      board = [{"PLRa000000000", 600}, {"PLRb000000000", 400}]
    end

    when_ "the pool settles top-K with the default [40,25,15,12,8]" do
      payouts = Economy.top_k_split(1000, board, [40, 25, 15, 12, 8])
    end

    then_ "only the assigned ranks are paid, the share normalizes over 40+25, and the whole pool drains" do
      # 40/65 and 25/65 of 1000 floor to 615 + 384 = 999; the 1-diamond dust goes to rank 1.
      assert payouts == [{"PLRa000000000", 616}, {"PLRb000000000", 384}]
      assert Enum.map(payouts, &elem(&1, 1)) |> Enum.sum() == 1000
    end
  end

  scenario "the sealed split drains the whole pool — no diamond is stranded" do
    given_ "a five-rank board over an awkward pool that does not divide evenly" do
      board = for n <- 1..5, do: {"PLR#{n}00000000", 600 - n * 50}
      split = [40, 25, 15, 12, 8]
    end

    when_ "the pool settles top-K over a pool of 999" do
      payouts = Economy.top_k_split(999, board, split)
    end

    then_ "the sum of the payouts equals the whole pool (the rounding dust is paid to rank 1)" do
      assert Enum.map(payouts, &elem(&1, 1)) |> Enum.sum() == 999
    end
  end

  scenario "the sealed split is pure: re-running pays identically" do
    given_ "a board, a pool, and a split" do
      board = [{"PLRa000000000", 520}, {"PLRb000000000", 480}, {"PLRc000000000", 300}]
    end

    then_ "two settlements of the same inputs are equal" do
      split = [40, 25, 15, 12, 8]
      assert Economy.top_k_split(900, board, split) == Economy.top_k_split(900, board, split)
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
