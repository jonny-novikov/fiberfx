defmodule Codemojex.Stories.ScoringStoryTest do
  @moduledoc "GWT acceptance for the pure Linear scoring engine. No bus, no DB — runs anywhere."
  use Codemojex.Story, feature: "Scoring", async: true

  @secret ~w(0000 0101 0202 0303 0404 0505)

  scenario "an exact six-emoji crack scores the maximum" do
    given_ "a secret of six distinct emoji codes" do
      secret = @secret
    end

    when_ "the player guesses the secret exactly" do
      result = Scoring.score(secret, secret)
    end

    then_ "every position is EXACT and the total is 600 at 100%, tier 30" do
      assert result.total == 600
      assert result.percentage == 100
      assert result.tier == 30
      assert Enum.all?(result.breakdown, fn {_pos, _e, d, _pts, status} -> d == 0 and status == "EXACT" end)
    end
  end

  scenario "points fall off linearly with distance, and a miss scores zero" do
    given_ "the distance-to-points rule points = 100 - 20*d" do
      :ok
    end

    then_ "0..5 yield 100,80,60,40,20,0 and a miss yields 0" do
      assert Enum.map(0..5, &Scoring.points/1) == [100, 80, 60, 40, 20, 0]
      assert Scoring.points(:miss) == 0
    end

    and_ "the status words match the rules table" do
      assert Enum.map([:miss, 0, 1, 2, 3, 4, 5], &Scoring.status/1) ==
               ~w(MISS EXACT ADJACENT NEAR NEAR FAR MAX)
    end
  end

  scenario "two emojis in the wrong-but-adjacent positions still score most of their value" do
    given_ "a guess with positions 0 and 1 swapped, the rest exact" do
      guess = ~w(0101 0000 0202 0303 0404 0505)
    end

    when_ "the guess is scored against the secret" do
      result = Scoring.score(@secret, guess)
    end

    then_ "each swapped emoji is ADJACENT (distance 1, 80 points) and the total is 560 at 93%, tier 28" do
      assert result.total == 560
      assert result.percentage == 93
      assert result.tier == 28
    end
  end

  scenario "the two ends swapped score zero on those positions" do
    given_ "a guess with positions 0 and 5 swapped, the rest exact" do
      guess = ~w(0505 0101 0202 0303 0404 0000)
    end

    when_ "the guess is scored" do
      result = Scoring.score(@secret, guess)
    end

    then_ "the swapped ends are MAX distance (0 points) and the total is 400 at 67%, tier 20" do
      assert result.total == 400
      assert result.percentage == 67
      assert result.tier == 20
    end
  end

  scenario "an emoji not in the secret is a clean miss" do
    given_ "a guess whose first emoji is absent from the secret" do
      guess = ~w(9999 0101 0202 0303 0404 0505)
    end

    when_ "the guess is scored" do
      result = Scoring.score(@secret, guess)
    end

    then_ "that position is a MISS worth 0 and the total is 500 at 83%, tier 25" do
      assert {0, "9999", :miss, 0, "MISS"} = hd(result.breakdown)
      assert result.total == 500
      assert result.percentage == 83
      assert result.tier == 25
    end
  end

  scenario "the same secret and guess always score identically (a re-delivered guess is safe)" do
    given_ "any guess" do
      guess = ~w(0101 0000 9999 0303 0404 0505)
    end

    when_ "it is scored twice" do
      a = Scoring.score(@secret, guess)
      b = Scoring.score(@secret, guess)
    end

    then_ "the two results are identical — scoring is pure" do
      assert a == b
    end
  end
end
