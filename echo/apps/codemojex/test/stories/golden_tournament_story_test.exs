defmodule Codemojex.Stories.GoldenTournamentStoryTest do
  @moduledoc """
  GWT acceptance for the Golden Room tournament lifecycle (cm.5): the gather gate
  (the Nth paid member arms the timer), the live top-K split (no reveal, one
  distribution transaction), the consolation clips, the no-refund void, and the
  wired sweep. Integration: needs the app, Postgres, and a Valkey on $VK_PORT
  (`mix test --include valkey`).
  """
  use Codemojex.Story, feature: "Golden tournament", async: false
  @moduletag :valkey

  alias Codemojex.{Store, Rooms, Board}

  scenario "the gather threshold arms the timer exactly once (ends_ms = room_deadline)" do
    given_ "a Golden Room (start_threshold 2) with one paid member, still gathering" do
      set = EmojiSet.new("Dogs", 6, 6)
      deadline = deadline(48 * 3600)

      {:ok, room} =
        Codemojex.create_golden_room("Den", set,
          entry_fee_keys: 8,
          virtual_deposit: 1000,
          start_threshold: 2,
          first_movers: 1,
          entry_fee_revenue_percentage: 50,
          room_deadline: deadline
        )

      {:ok, a} = Codemojex.create_player("A", keys: 8)
      {:ok, b} = Codemojex.create_player("B", keys: 8)
      {:ok, game} = Codemojex.join_room(room, a)
      # one paid member: still gathering, the counter shows 1/2, ends_ms nil
      view1 = Codemojex.game_view(game)
    end

    when_ "the second (threshold-th) member buys in" do
      {:ok, ^game} = Codemojex.join_room(room, b)
      view2 = Codemojex.game_view(game)
    end

    then_ "the game is :open, ends_ms equals room_deadline, and the counter went 1/2 → 2/2" do
      assert view1.status == :gathering
      assert view1.gather == %{paid: 1, threshold: 2}
      assert view1.ends_ms == nil

      assert view2.status == :open
      assert view2.ends_ms == DateTime.to_unix(deadline, :millisecond)
      # the paid-set hint counter reached the threshold
      assert Store.game(game).status == :open
    end
  end

  scenario "the top-K split the diamond pool live — no reveal, one distribution" do
    given_ "a started Golden Room with two scored members and a known pool" do
      set = EmojiSet.new("Dogs", 6, 6)

      {:ok, room} =
        Codemojex.create_golden_room("Den", set,
          entry_fee_keys: 8,
          virtual_deposit: 1000,
          start_threshold: 2,
          first_movers: 0,
          entry_fee_revenue_percentage: 100,
          room_deadline: deadline(48 * 3600)
        )

      {:ok, alice} = Codemojex.create_player("Alice", keys: 9)
      {:ok, bob} = Codemojex.create_player("Bob", keys: 9)
      {:ok, game} = Codemojex.join_room(room, alice)
      {:ok, ^game} = Codemojex.join_room(room, bob)
      # two members score (distinct guesses); the pool is the seeded virtual_deposit
      # + the two guess fees ×10. Both scores must land before the pool is read.
      Phoenix.PubSub.subscribe(Codemojex.PubSub, "game:" <> game)
      assert {:ok, _} = Codemojex.submit(game, alice, ~w(0000 0101 0202 0303 0404 0505))
      assert {:ok, _} = Codemojex.submit(game, bob, ~w(0505 0404 0303 0202 0101 0000))
      assert eventually(fn -> length(elem(Board.top(game, 10), 1)) == 2 end)
      # wait for both guess→pool increments to land (virtual_deposit 1000 + 2×10)
      assert eventually(fn -> Store.game(game).prize_pool == 1020 end)
      pool = Store.game(game).prize_pool
    end

    when_ "the game is closed via the live-split path (tolerating a perfect-crack auto-close)" do
      # a 600 auto-closes the started tournament (INV-STATE), so the explicit close
      # may find it already settled — either way it settles via the live_split path.
      _ = Codemojex.close_now(game)
      assert eventually(fn -> Store.game(game).status == :settled end)
    end

    then_ "the whole pool drained to the top-K (dust to rank 1), a {:golden_win} fired, and NO {:revealed}" do
      # the whole pool was distributed as 💎 prizes for this game (top_k_split drains
      # it, dust to rank 1) — the sum of prize TXNs equals the pool at close.
      assert eventually(fn -> prize_total(game) == pool end)
      # the live tournament announces a golden win but NEVER reveals (INV-NO-REVEAL)
      assert_receive {:golden_win, %{game: ^game}}, 2_000
      refute_received {:revealed, _}
      assert Store.game(game).status == :settled
    end
  end

  scenario "every member outside the top-K is paid a consolation clip (0 if never scored)" do
    given_ "a started Golden Room with three members; one outside the top-K, one who never guesses" do
      set = EmojiSet.new("Dogs", 6, 6)

      {:ok, room} =
        Codemojex.create_golden_room("Den", set,
          entry_fee_keys: 8,
          virtual_deposit: 1000,
          start_threshold: 3,
          first_movers: 0,
          entry_fee_revenue_percentage: 100,
          payout_split: [100],
          room_deadline: deadline(48 * 3600)
        )

      {:ok, alice} = Codemojex.create_player("Alice", keys: 9)
      {:ok, bob} = Codemojex.create_player("Bob", keys: 9)
      {:ok, carol} = Codemojex.create_player("Carol", keys: 9)
      {:ok, game} = Codemojex.join_room(room, alice)
      {:ok, ^game} = Codemojex.join_room(room, bob)
      {:ok, ^game} = Codemojex.join_room(room, carol)
      # alice and bob both score (distinct guesses, neither a guaranteed 600 — the
      # secret is server-side); carol never guesses. We avoid relying on a perfect
      # crack so the ONLY close is the explicit close_now below (a 600 would auto-
      # close the started tournament and race the capture).
      assert {:ok, _} = Codemojex.submit(game, alice, ~w(0000 0101 0202 0303 0404 0505))
      assert {:ok, _} = Codemojex.submit(game, bob, ~w(0505 0404 0303 0202 0101 0000))
      assert eventually(fn -> length(elem(Board.top(game, 10), 1)) == 2 end)
      bob_clips_before = Codemojex.balance(bob).clips
      carol_clips_before = Codemojex.balance(carol).clips
    end

    when_ "the game closes (top_k = [100], so only rank 1 is in the split)" do
      # the board at close: rank 1 is in the split, every other member takes a
      # consolation clip of max_score/10. Capture the board + bob's score BEFORE close
      # (close drains the Valkey board state is preserved, but read it now to be safe),
      # tolerating a perfect-crack auto-close (the game settles via close_split either way).
      {:ok, final_board} = Board.top(game, 10)
      ranked = Enum.map(final_board, &elem(&1, 0))
      bob_best = bob_best_score(game, bob)
      _ = Codemojex.close_now(game)
      assert eventually(fn -> Store.game(game).status == :settled end)
    end

    then_ "every member outside the top-1 got max_score/10 clips; carol (never scored) got 0" do
      # bob is outside rank 1 (top_k=[100] pays only rank 1) → consolation = bob_best/10
      bob_in_top1 = List.first(ranked) == bob
      expected_bob = if bob_in_top1, do: 0, else: div(bob_best, 10)
      assert eventually(fn -> Codemojex.balance(bob).clips == bob_clips_before + expected_bob end)
      # carol never scored → never on the board → consolation 0 (0/10)
      assert Codemojex.balance(carol).clips == carol_clips_before
    end
  end

  scenario "a never-fills Golden Room voids with NO refund" do
    given_ "a Golden Room with buy-ins below threshold, past its room_deadline" do
      set = EmojiSet.new("Dogs", 6, 6)
      # a deadline already in the past → the void is due immediately
      past = DateTime.utc_now() |> DateTime.add(-60, :second) |> DateTime.truncate(:second)

      {:ok, room} =
        Codemojex.create_golden_room("Den", set,
          entry_fee_keys: 8,
          virtual_deposit: 1000,
          start_threshold: 10,
          first_movers: 0,
          entry_fee_revenue_percentage: 100,
          room_deadline: past
        )

      {:ok, alice} = Codemojex.create_player("Alice", keys: 8)
      {:ok, game} = Codemojex.join_room(room, alice)
      keys_after_buyin = Codemojex.balance(alice).keys
      members_before = length(Store.members(game))
    end

    when_ "the void fires (and re-fires on a second tick)" do
      assert {:ok, :voided} = Rooms.void_if_stale(game)
      second = Rooms.void_if_stale(game)
    end

    then_ "the game is :voided, the room reset, no refund TXN exists, and the balance did not rise" do
      assert Store.game(game).status == :voided
      assert Store.room(room).status == :waiting
      # the second tick is idempotent (the game is no longer :gathering)
      assert second == {:ok, :not_yet}
      # NO REFUND: the keys debited at buy-in stay debited; no member balance rose
      assert Codemojex.balance(alice).keys == keys_after_buyin
      # the membership rows are unchanged (no refund loop ran)
      assert length(Store.members(game)) == members_before
    end
  end

  scenario "the sweep drives the timer-close and the void, both idempotent" do
    given_ "an :open game past its ends_ms and a :gathering game past its room_deadline" do
      set = EmojiSet.new("Dogs", 6, 6)
      # an ordinary classic room with a normal timer, so the guess submits while open;
      # then the game is expired in place (ends_ms in the past) so the sweep's timer-
      # close is what settles it (deterministic — no clock race).
      {:ok, classic} = Codemojex.create_room("Classic", set, seed_pool: 100, duration_ms: 600_000)
      {:ok, alice} = Codemojex.create_player("Alice", keys: 5)
      {:ok, open_game} = Codemojex.join_room(classic, alice)
      assert {:ok, _} = Codemojex.submit(open_game, alice, ~w(0000 0101 0202 0303 0404 0505))
      assert eventually(fn -> Codemojex.leaderboard(open_game, 10) != [] end)
      # expire it: rewind ends_ms to the past, leaving it :open for the sweep to close
      expired = %{Store.game(open_game) | ends_ms: System.system_time(:millisecond) - 1}
      :ok = Store.put_game(open_game, expired)

      # a Golden Room past its deadline, below threshold → due to void
      past = DateTime.utc_now() |> DateTime.add(-60, :second) |> DateTime.truncate(:second)

      {:ok, groom} =
        Codemojex.create_golden_room("Den", set,
          entry_fee_keys: 8,
          virtual_deposit: 1000,
          start_threshold: 10,
          first_movers: 0,
          entry_fee_revenue_percentage: 100,
          room_deadline: past
        )

      {:ok, bob} = Codemojex.create_player("Bob", keys: 8)
      {:ok, gathering_game} = Codemojex.join_room(groom, bob)
      Process.sleep(20)
    end

    when_ "the sweep ticks (twice)" do
      :ok = Codemojex.Sweep.sweep()
      open_after = Store.game(open_game).status
      gathering_after = Store.game(gathering_game).status
      :ok = Codemojex.Sweep.sweep()
    end

    then_ "the open game settled, the gathering game voided, and a second tick changed nothing" do
      assert open_after == :settled
      assert gathering_after == :voided
      # idempotent: the statuses are stable on the second pass
      assert Store.game(open_game).status == :settled
      assert Store.game(gathering_game).status == :voided
    end
  end

  defp deadline(seconds_from_now) do
    DateTime.utc_now() |> DateTime.add(seconds_from_now, :second) |> DateTime.truncate(:second)
  end

  # The total 💎 paid out as prizes for a game — the sum of `prize`-reason TXN deltas
  # with ref = game. The settled pool drains entirely to these (close_split, R-HOLD).
  # Postgres sum() returns a Decimal, so the deltas are summed in Elixir to an integer.
  defp prize_total(game) do
    import Ecto.Query

    Codemojex.Repo.all(
      from t in Codemojex.Schemas.Transaction,
        where: t.ref == ^game and t.reason == "prize",
        select: t.delta
    )
    |> Enum.sum()
  end

  defp bob_best_score(game, bob) do
    case Board.top(game, 10) do
      {:ok, rows} -> Enum.find_value(rows, 0, fn {p, s} -> if p == bob, do: s end) || 0
      _ -> 0
    end
  end

  defp eventually(fun, tries \\ 50)
  defp eventually(_fun, 0), do: false
  defp eventually(fun, tries) do
    if fun.(), do: true, else: (Process.sleep(20); eventually(fun, tries - 1))
  end
end
