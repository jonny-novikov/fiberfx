defmodule Codemojex.Stories.EmojiCodesStoryTest do
  @moduledoc "GWT acceptance for the XXYY emoji-set addressing and the player-facing snapshot. Pure — runs anywhere."
  use Codemojex.Story, feature: "Emoji codes", async: true

  scenario "an XXYY code is column-then-row and round-trips" do
    given_ "the code \"0305\"" do
      code = "0305"
    end

    then_ "it addresses column 3, row 5, and code/2 is the inverse of xy/1" do
      assert EmojiSet.xy(code) == {3, 5}
      assert EmojiSet.code(3, 5) == code
    end
  end

  scenario "a code maps to the exact sprite-sheet offset the frontend renders" do
    given_ "a 6x6 set at the default 144px cell size" do
      set = EmojiSet.new("Dogs", 6, 6, sprite_url: "https://cdn.example/dogs.png")
    end

    then_ "code \"0305\" sits at (-432, -720) pixels" do
      assert EmojiSet.bg_position(set, "0305") == {-432, -720}
    end
  end

  scenario "the grid expands to every cell row-major when no subset is given" do
    given_ "a 6x6 set with no explicit codes" do
      set = EmojiSet.new("Dogs", 6, 6)
    end

    then_ "the keyboard has all 36 cells and each is a valid code" do
      assert length(set.codes) == 36
      assert EmojiSet.valid_code?(set, "0000")
      assert EmojiSet.valid_code?(set, "0505")
      refute EmojiSet.valid_code?(set, "9999")
    end
  end

  scenario "a well-formed secret is six distinct in-set codes" do
    given_ "a set and a drawn secret" do
      set = EmojiSet.new("Dogs", 6, 6)
      secret = EmojiSet.secret(set)
    end

    then_ "the drawn secret validates, but duplicates and out-of-set codes do not" do
      assert length(secret) == 6
      assert EmojiSet.valid_secret?(set, secret)
      refute EmojiSet.valid_secret?(set, ["0000", "0000", "0101", "0202", "0303", "0404"])
      refute EmojiSet.valid_secret?(set, ["9999", "0101", "0202", "0303", "0404", "0505"])
    end
  end

  scenario "the player-facing snapshot carries the keyboard but nothing the secret leaks from" do
    given_ "an emoji set" do
      set = EmojiSet.new("Dogs", 6, 6, sprite_url: "https://cdn.example/dogs.png")
    end

    when_ "the set is snapshotted for the client" do
      snap = EmojiSet.snapshot(set)
    end

    then_ "the snapshot is exactly the keyboard fields — no secret could be derived from it" do
      assert Map.keys(snap) |> Enum.sort() == ~w(cell_size codes cols count rows sprite_url)a
      assert snap.count == length(set.codes)
    end
  end
end
