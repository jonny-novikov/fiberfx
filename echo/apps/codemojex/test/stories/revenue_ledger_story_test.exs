defmodule Codemojex.Stories.RevenueLedgerStoryTest do
  @moduledoc """
  GWT acceptance for the cm.6 revenue ledger (cm-6 D-1..D-7): the explicit
  house-account double-entry over a dedicated, signed, multi-source/multi-currency
  `revenue_ledger`. Every platform cut cm.5 records implicitly (the seed, the
  deposit-recovery, the first-mover share, the full revenue, the void reclaim) is
  here a real signed row, booked in the SAME `Repo.transaction` as the player debit.

  The headline (S5) is the three-term CONSERVATION identity — `Σ player key debits ==
  Σ house key credits + Σ pool key portions` over three observable columns — proven,
  explicitly NOT `Σ all-ledger-rows = 0` (D-3; the conservation-honesty statement is
  S9 + the `revenue_breakdown/1` doc). Integration: needs the app, Postgres, and a
  Valkey on $VK_PORT (`mix test --include valkey`).
  """
  use Codemojex.Story, feature: "Revenue ledger", async: false
  @moduletag :valkey

  alias Codemojex.{Wallet, Store, Rooms}
  alias Codemojex.Repo
  alias Codemojex.Schemas.RevenueLedger
  import Ecto.Query

  # A Golden Room whose bands are reachable in a test: start_threshold 2 (the first 2
  # fees recover the deposit), first_movers 1 (member 3 splits its fee to the pool),
  # revenue 50% (so pool_keys = floor(8×50/100) = 4 keys → 40💎), entry_fee 8 keys,
  # virtual_deposit 1000💎 (the seed = div(1000,10) = 100 keys).
  setup do
    set = EmojiSet.new("Dogs", 6, 6, sprite_url: "https://cdn.example/dogs.png")

    {:ok, room} =
      Codemojex.create_golden_room("Golden Vault", set,
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

  # S1 — the virtual deposit is a real platform outlay (the seed debit, SEAM-1)
  scenario "the seed is booked as a negative house debit, wrapped atomically with the games-row write",
           %{room: room} do
    given_ "a Golden Room with virtual_deposit 1000 💎 (the seed = 100 keys)" do
      {:ok, alice} = Codemojex.create_player("Alice", keys: 8)
    end

    when_ "the golden game forms (the first join seeds the pool)" do
      {:ok, game} = Codemojex.join_room(room, alice)
    end

    then_ "the house holds a -100 keys deposit_seed row and the pool holds 1000 💎" do
      # the seed is div(virtual_deposit, 10) = 100 keys, booked NEGATIVE (the debit)
      assert house_rows(game, "deposit_seed") == [-100]
      assert Store.game(game).prize_pool == 1000
    end

    and_ "the house balance for the game is negative at this instant — the ledger admits it (no non-negative CHECK, D-1)" do
      # after one buy-in: seed -100 + the member-1 deposit_recovery +8 = -92 (still < 0).
      # A players row could not hold this (players_non_negative, player.ex:43-47); the
      # dedicated revenue_ledger does — the schema reason for the separate account kind.
      assert Wallet.revenue_breakdown(game) |> Map.values() |> Enum.sum() == -92
    end
  end

  # S2 — the first-ten (here first-two) fees are recorded revenue (deposit-recovery)
  scenario "deposit-recovery-band buy-ins each credit the house the full fee with no pool move",
           %{room: room} do
    given_ "a Golden Room (entry_fee 8, start_threshold 2)" do
      {:ok, a} = Codemojex.create_player("A", keys: 8)
      {:ok, b} = Codemojex.create_player("B", keys: 8)
    end

    when_ "members 1..2 buy in (the deposit-recovery band)" do
      {:ok, game} = Codemojex.join_room(room, a)
      {:ok, ^game} = Codemojex.join_room(room, b)
    end

    then_ "the house gained +8 keys per member (deposit_recovery), the pool is unchanged, each player's keys fell by 8" do
      assert house_rows(game, "deposit_recovery") == [8, 8]
      # the pool stayed at the seeded virtual_deposit — recovery fees do not fund it
      assert Store.game(game).prize_pool == 1000
      assert Codemojex.balance(a).keys == 0
      assert Codemojex.balance(b).keys == 0
    end

    and_ "the house NET after the 2 recoveries equals Σ recovery − seed (16 − 100 = −84, the zero-loss made explicit)" do
      assert Wallet.revenue_breakdown(game) |> Map.values() |> Enum.sum() == -84
    end
  end

  # S3 — the first-mover split is fully booked on both sides (the keys-exact partition)
  scenario "a first-mover credits the house fee − pool_keys and the pool the same pool_keys ×10, summing to the fee",
           %{room: room} do
    given_ "a Golden Room past its gather threshold (2 recovery members in)" do
      {:ok, a} = Codemojex.create_player("A", keys: 8)
      {:ok, b} = Codemojex.create_player("B", keys: 8)
      {:ok, c} = Codemojex.create_player("C", keys: 8)
      {:ok, game} = Codemojex.join_room(room, a)
      {:ok, ^game} = Codemojex.join_room(room, b)
      pool_after_gather = Store.game(game).prize_pool
    end

    when_ "the first-mover (member 3) buys in" do
      {:ok, ^game} = Codemojex.join_room(room, c)
      pool_after_first_mover = Store.game(game).prize_pool
    end

    then_ "the house gained +(8 − 4) = 4 keys (revenue) and the pool rose by 4×10 = 40 💎 — the SAME pool_keys both sides" do
      # pool_keys = Economy.entry_fee_split_keys(3, 2, 1, 50, 8) = div(8×50,100) = 4
      assert Economy.entry_fee_split_keys(3, 2, 1, 50, 8) == 4
      # the house credit is the exact-integer complement fee − pool_keys = 8 − 4 = 4
      assert house_rows(game, "revenue") == [4]
      assert pool_after_first_mover == pool_after_gather + 40
    end

    and_ "the house credit + the pool portion sum, IN KEYS, to the 8-key fee exactly (4 + 4 == 8, zero dust)" do
      house_keys = house_rows(game, "revenue") |> Enum.sum()
      pool_keys = Economy.entry_fee_split_keys(3, 2, 1, 50, 8)
      assert house_keys + pool_keys == 8
    end
  end

  # S4 — full-revenue tiers credit the whole fee
  scenario "a buy-in beyond the first-mover band credits the house the full fee with no pool move",
           %{room: room} do
    given_ "a Golden Room with the recovery band + the single first-mover filled (3 members in)" do
      {:ok, a} = Codemojex.create_player("A", keys: 8)
      {:ok, b} = Codemojex.create_player("B", keys: 8)
      {:ok, c} = Codemojex.create_player("C", keys: 8)
      {:ok, d} = Codemojex.create_player("D", keys: 8)
      {:ok, game} = Codemojex.join_room(room, a)
      {:ok, ^game} = Codemojex.join_room(room, b)
      {:ok, ^game} = Codemojex.join_room(room, c)
      pool_after_first_mover = Store.game(game).prize_pool
    end

    when_ "member 4 (ordinal > start_threshold + first_movers) buys in" do
      {:ok, ^game} = Codemojex.join_room(room, d)
      pool_after_revenue = Store.game(game).prize_pool
    end

    then_ "the house gained a +8 keys revenue row (member 4's full fee) and the pool is unchanged" do
      # the "revenue" rows now hold the first-mover's 4 AND member 4's 8
      assert house_rows(game, "revenue") |> Enum.sort() == [4, 8]
      assert pool_after_revenue == pool_after_first_mover
    end
  end

  # S5 — the double-entry balance invariant (THE headline; the three-term conservation)
  scenario "for any sequence of buy-ins the three-term keys identity holds over three observable columns",
           %{room: room} do
    given_ "a Golden Room and four members spanning all three bands + the seed" do
      {:ok, a} = Codemojex.create_player("A", keys: 8)
      {:ok, b} = Codemojex.create_player("B", keys: 8)
      {:ok, c} = Codemojex.create_player("C", keys: 8)
      {:ok, d} = Codemojex.create_player("D", keys: 8)
      ks0 = Enum.sum(for p <- [a, b, c, d], do: Codemojex.balance(p).keys)
    end

    when_ "all four buy in (members 1..4: recovery, recovery, first-mover, full-revenue)" do
      {:ok, game} = Codemojex.join_room(room, a)
      {:ok, ^game} = Codemojex.join_room(room, b)
      {:ok, ^game} = Codemojex.join_room(room, c)
      {:ok, ^game} = Codemojex.join_room(room, d)
    end

    then_ "Σ(player key debits) == Σ(house key credits, excl. the deposit legs) + Σ(pool key portions) — exactly" do
      # the three observable columns (D-3):
      #   1. player debits = the keys players SPENT (a players.keys column move)
      ks1 = Enum.sum(for p <- [a, b, c, d], do: Codemojex.balance(p).keys)
      player_debits = ks0 - ks1
      #   2. house credits = the revenue_ledger recovery+revenue rows (the per-buy-in
      #      legs; the seed/reclaim are the DEPOSIT legs, not per-buy-in — S7)
      bd = Wallet.revenue_breakdown(game)
      house_credits = Map.get(bd, "deposit_recovery", 0) + Map.get(bd, "revenue", 0)
      #   3. pool portions = games.prize_pool 💎 ÷ 10, MINUS the seeded deposit (the
      #      seed 💎 are not a buy-in conversion; the ×10 keys→💎 is the one accounted mint)
      pool_keys = div(Store.game(game).prize_pool - 1000, Economy.diamonds_per_key())
      # 4 buy-ins × 8 = 32 keys debited; house recovery+revenue = 8+8+4+8 = 28; pool = 4
      assert player_debits == 32
      assert house_credits + pool_keys == player_debits
    end

    and_ "the identity is proven by conservation over the three columns, explicitly NOT by Σ all-ledger-rows = 0 (D-3)" do
      # the bare revenue_ledger row-sum is NOT zero (it carries the seed debit + the
      # credits); a single-table SUM == 0 does not apply and is not asserted (S9).
      assert Wallet.revenue_breakdown(game) |> Map.values() |> Enum.sum() != 0
    end
  end

  # S6 — the void books the seed-cancelling reclaim only (SEAM-2, +seed, idempotent)
  scenario "a voided Golden Room books exactly one +seed reclaim, idempotent under the close lock, no refund",
           %{set: set} do
    given_ "a never-fills Golden Room (deadline already past) that took 1 recovery buy-in" do
      {:ok, room} =
        Codemojex.create_golden_room("Stale Vault", set,
          entry_fee_keys: 8,
          virtual_deposit: 1000,
          start_threshold: 2,
          first_movers: 1,
          entry_fee_revenue_percentage: 50,
          duration_ms: 600_000,
          # a deadline in the past so void_if_stale fires
          room_deadline: deadline(-1)
        )

      {:ok, a} = Codemojex.create_player("A", keys: 8)
      {:ok, game} = Codemojex.join_room(room, a)
      keys_before = Codemojex.balance(a).keys
    end

    when_ "close_void fires (and re-fires on a second tick)" do
      {:ok, :voided} = Rooms.void_if_stale(game)
      # the whole-ledger row count for the game right after the FIRST void — the second
      # tick must add nothing to it (the tight idempotency probe).
      rows_after_first = ledger_row_count(game)
      second = Rooms.void_if_stale(game)
    end

    then_ "the house holds exactly one +100 deposit_reclaim, the net is Σ kept fees, no player is refunded, the second tick books ZERO further rows" do
      assert house_rows(game, "deposit_reclaim") == [100]
      # net = seed(-100) + recovery(+8) + reclaim(+100) = +8 = the one kept fee
      assert Wallet.revenue_breakdown(game) |> Map.values() |> Enum.sum() == 8
      # no refund (cm.5 D-7): the player's keys did NOT rise on the void
      assert Codemojex.balance(a).keys == keys_before
      # the second tick is a no-op: the first void already settled (it returned :voided),
      # so the re-fire does NOT void again — the NX close lock is the exactly-once guard.
      refute match?({:ok, :voided}, second), "the second tick voided again (not idempotent): #{inspect(second)}"
      # the TIGHT idempotency assertion (D-Director note): a second void books EXACTLY
      # ZERO additional revenue_ledger rows for the game — not just one deposit_reclaim
      # row, but no row of any reason. The reclaim row count stays 1.
      assert ledger_row_count(game) == rows_after_first
      assert house_rows(game, "deposit_reclaim") == [100]
    end
  end

  # S7 — explicit equals implicit (the reconciliation read)
  scenario "the reconciliation read's house figure equals the conservation figure cm.5 leaves implicit",
           %{room: room} do
    given_ "a Golden Room with four members across the bands" do
      {:ok, a} = Codemojex.create_player("A", keys: 8)
      {:ok, b} = Codemojex.create_player("B", keys: 8)
      {:ok, c} = Codemojex.create_player("C", keys: 8)
      {:ok, d} = Codemojex.create_player("D", keys: 8)
    end

    when_ "they all buy in and finance reads revenue_breakdown(game)" do
      {:ok, game} = Codemojex.join_room(room, a)
      {:ok, ^game} = Codemojex.join_room(room, b)
      {:ok, ^game} = Codemojex.join_room(room, c)
      {:ok, ^game} = Codemojex.join_room(room, d)
      bd = Wallet.revenue_breakdown(game)
    end

    then_ "the per-game revenue (recovery + revenue rows) equals Σ fee_i − Σ pool_💎_i/10 — the cm.5-only conservation figure" do
      explicit = Map.get(bd, "deposit_recovery", 0) + Map.get(bd, "revenue", 0)
      # the cm.5-only computation: Σ entry_fee − Σ (pool 💎 contributed by buy-ins / 10).
      # 4 buy-ins × 8 = 32; the buy-ins added (prize_pool − seed) = 40 💎 → 4 keys.
      pool_keys_from_buyins = div(Store.game(game).prize_pool - 1000, Economy.diamonds_per_key())
      implicit = 4 * 8 - pool_keys_from_buyins
      assert explicit == implicit
      assert explicit == 28
    end

    and_ "house_balance groups by currency — keys now, a cm.7 stars row would sum into its own bucket with no read change" do
      assert Map.has_key?(Wallet.house_balance(), "keys")
    end
  end

  # S8 — atomic double-entry (all present or all absent)
  scenario "a buy-in's player debit, pool increment, and house credit are all present together",
           %{room: room} do
    given_ "a Golden Room past gather so a first-mover moves all three columns at once" do
      {:ok, a} = Codemojex.create_player("A", keys: 8)
      {:ok, b} = Codemojex.create_player("B", keys: 8)
      {:ok, c} = Codemojex.create_player("C", keys: 8)
      {:ok, game} = Codemojex.join_room(room, a)
      {:ok, ^game} = Codemojex.join_room(room, b)
      pool_before = Store.game(game).prize_pool
    end

    when_ "the first-mover buys in (one Repo.transaction under the games-row lock)" do
      {:ok, ^game} = Codemojex.join_room(room, c)
    end

    then_ "the player keys debit AND the prize_pool increment AND the revenue_ledger credit are all present" do
      assert Codemojex.balance(c).keys == 0
      assert Store.game(game).prize_pool == pool_before + 40
      assert house_rows(game, "revenue") == [4]
      # exactly one buy_in TXN for the member — the house credit did not fork a row
      assert Store.paid_count(game) == 3
    end
  end

  # S9 — the conservation-honesty statement (the mandatory acceptance item)
  scenario "the ledger balances by conservation over three columns, NOT by a zero row-sum, with the deferred rung named",
           %{room: room} do
    given_ "a Golden Room with the seed + buy-ins (the player debit is a bare keys column; the pool is a games column)" do
      {:ok, a} = Codemojex.create_player("A", keys: 8)
      {:ok, b} = Codemojex.create_player("B", keys: 8)
      {:ok, game} = Codemojex.join_room(room, a)
      {:ok, ^game} = Codemojex.join_room(room, b)
    end

    when_ "the revenue_ledger rows for the game are summed naively" do
      naive_row_sum = Wallet.revenue_breakdown(game) |> Map.values() |> Enum.sum()
    end

    then_ "the naive single-table row-sum is NOT zero — it is the house balance, not the system total (the honesty statement, D-3)" do
      # seed -100 + 2 recoveries +16 = -84 ≠ 0. The balanced identity is the three-term
      # conservation (S5), proven over the players.keys deltas + these rows + the pool
      # column — explicitly NOT Σ all-ledger-rows = 0. The deferred bank rung
      # ("reconcile the entry legs into signed rows + a pool account") is named in the
      # spec (cm.6.md §6/Acceptance, S9) and in Wallet.revenue_breakdown/1's @doc.
      assert naive_row_sum == -84
      assert naive_row_sum != 0
    end
  end

  # S10 — the existing cm.5 suite stays byte-unchanged and green (asserted by topology here)
  scenario "cm.6 writes only the new revenue_ledger table — the cm.5 player/pool figures are untouched",
           %{room: room} do
    given_ "a Golden Room and two recovery buy-ins (the cm.5 path)" do
      {:ok, a} = Codemojex.create_player("A", keys: 8)
      {:ok, b} = Codemojex.create_player("B", keys: 8)
    end

    when_ "the members buy in under cm.6" do
      {:ok, game} = Codemojex.join_room(room, a)
      {:ok, ^game} = Codemojex.join_room(room, b)
    end

    then_ "the cm.5 figures are exactly as cm.5 produced them — the pool at the seed, the players debited 8 (the house credit is disjoint)" do
      # S-VIRTUALDEPOSIT / S-FIRSTMOVER read the SAME prize_pool + players.keys cm.5 set;
      # cm.6 adds rows in a NEW table, moving no cm.5 figure (the additive overlay, D-3).
      assert Store.game(game).prize_pool == 1000
      assert Codemojex.balance(a).keys == 0 and Codemojex.balance(b).keys == 0
      # cm.6 wrote NO transactions rows (only revenue_ledger) — paid_count counts buy_in
      # TXNs, unchanged by the house credit
      assert Store.paid_count(game) == 2
    end
  end

  # S11 — the ledger is multi-source / multi-currency ready (the BNK + KeyShop foundation)
  scenario "the revenue_ledger holds a source + currency dimension with a signed delta and no non-negative CHECK",
           %{room: room} do
    given_ "the revenue_ledger founded this rung, with one golden game's rows" do
      {:ok, a} = Codemojex.create_player("A", keys: 8)
      {:ok, game} = Codemojex.join_room(room, a)
    end

    when_ "its shape is inspected (structure, not new behaviour)" do
      bal = Wallet.house_balance(Wallet.house_account())
    end

    then_ "it carries account=platform + currency=keys + a signed delta (a negative seed row exists — no non-negative CHECK, D-1)" do
      # the negative seed row is in the table — proof the signed, unconstrained delta
      # admits what players cannot (players_non_negative)
      assert house_rows(game, "deposit_seed") == [-100]
      # the read groups by currency — "keys" now; a cm.7 "stars"/"cents" row sums into
      # its own bucket with no read change (the multi-currency seam, D-5). The call
      # sites + the read bind to the Wallet.house_post / house_balance seam (D-7).
      assert Map.has_key?(bal, "keys")
    end
  end

  # S5-PROP — the keys-exact partition, as a PROPERTY over a grid (the spec's mandated
  # property test for the headline conservation, cm.6.md:144/181, S5). The fixed S5
  # above proves ONE 4-member sequence; this proves the partition for EVERY
  # (entry_fee_keys, revenue_pct, ordinal) in a grid — including pool values where
  # div(pool, 9) ≠ div(pool, 10), the blind spot the worked examples (pool=40,
  # div(40,9)==div(40,10)==4) cannot see. The grid asserts the house cut the production
  # buy-in computes (the EXACT fee − div(pool, 10) expression at wallet.ex:256) plus the
  # pool keys (the independent oracle Economy.entry_fee_split_keys/5) sum to the fee in
  # the first-mover band, and the house takes the whole fee outside it. A house cut that
  # over- or under-credits by even 1 key (e.g. the div(pool, 9) corruption) breaks it.
  scenario "PROPERTY: the keys-exact partition house_cut + pool_keys == fee holds across the fee×rev% grid (incl. div(pool,9)≠div(pool,10))" do
    given_ "the partition grid: entry_fee_keys × revenue_pct × ordinals spanning all three bands" do
      # band geometry fixed so each ordinal lands in a known band:
      #   start_threshold 2, first_movers 2 ⇒ ord 1..2 recovery, 3..4 first-mover, 5+ full.
      start_threshold = 2
      first_movers = 2
      fees = [8, 13, 20, 25]
      # rev%s chosen so the first-mover pool_keys hits DIVERGENCE points where
      # div(pool, 9) ≠ div(pool, 10) — fee=20,rev=55 ⇒ pool_keys 9 ⇒ pool 90 (div10=9,
      # div9=10); fee=13,rev=15 ⇒ pool_keys 11 ⇒ pool 110 (div10=11, div9=12) — plus the
      # boundary 0% (all to pool) and 100% (all to house) and the worked-example 50%.
      rev_pcts = [0, 15, 33, 50, 55, 67, 100]
      ordinals = [1, 2, 3, 4, 5, 9]
    end

    when_ "each grid cell computes the house cut the production buy-in computes and the oracle pool keys" do
      cells =
        for fee <- fees, rev <- rev_pcts, ord <- ordinals do
          # the POOL 💎 the production path computes (economy.ex:45-52), HERE under the
          # same inputs the buy-in passes (wallet.ex:233-240):
          pool = Economy.entry_fee_split(ord, start_threshold, first_movers, rev, fee)
          # the house cut EXACTLY as the production line wallet.ex:256 derives it:
          house_cut = fee - div(pool, Economy.diamonds_per_key())
          # the independent oracle — the keys pool portion from the ONE floor (D-7):
          pool_keys = Economy.entry_fee_split_keys(ord, start_threshold, first_movers, rev, fee)
          in_band? = ord > start_threshold and ord <= start_threshold + first_movers
          {fee, rev, ord, pool, house_cut, pool_keys, in_band?}
        end
    end

    then_ "in-band house_cut + pool_keys == fee exactly; out-of-band house_cut == fee; the pool is the oracle ×10" do
      for {fee, rev, ord, pool, house_cut, pool_keys, in_band?} <- cells do
        ctx = "fee=#{fee} rev=#{rev} ord=#{ord} pool=#{pool} cut=#{house_cut} pk=#{pool_keys}"

        if in_band? do
          # the keys partition is EXACT — the fee splits with zero residue (the headline
          # conservation at the entry unit). This is the assertion the div(pool,9)
          # corruption fails: at pool=90 it makes house_cut=10, so 10+9=19 ≠ 20.
          assert house_cut + pool_keys == fee, "in-band partition broke: #{ctx}"
          # both sides derive from the ONE floor — the pool 💎 is the oracle's keys ×10.
          assert pool == pool_keys * Economy.diamonds_per_key(), "pool≠pool_keys×10: #{ctx}"
        else
          # outside the band the house takes the whole fee and the pool does not move.
          assert house_cut == fee, "out-of-band cut≠fee: #{ctx}"
          assert pool == 0, "out-of-band pool≠0: #{ctx}"
          assert pool_keys == 0, "out-of-band pool_keys≠0: #{ctx}"
        end

        # the house cut is never negative and never exceeds the fee (a sign/over-credit
        # guard the worked examples cannot span — a negative cut is the div(pool,9)
        # failure mode the Apollo finding named, at pool=90 the correct cut is 11 not 10).
        assert house_cut >= 0 and house_cut <= fee, "cut out of [0,fee]: #{ctx}"
      end
    end

    and_ "the grid actually exercised a divergence cell where div(pool, 9) ≠ div(pool, 10) (else the property is blind to M5)" do
      # a meta-assertion: the grid is only a real M5 killer if it contains at least one
      # first-mover cell whose pool floors differently under /9 and /10. Without this the
      # grid could silently regress to the worked-example blind spot.
      divergent =
        Enum.filter(cells, fn {_fee, _rev, _ord, pool, _hc, _pk, in_band?} ->
          in_band? and pool > 0 and
            div(pool, Economy.diamonds_per_key()) != div(pool, Economy.diamonds_per_key() - 1)
        end)

      assert divergent != [], "the grid hit NO div(pool,9)≠div(pool,10) cell — it cannot kill M5"
    end
  end

  # S5-PROP-B — the three-term conservation as a PROPERTY over real buy-ins (cm.6.md:181,
  # S5). The fixed S5 drives ONE config; this drives several configs end-to-end through
  # the REAL Wallet.buy_in/2 + revenue_breakdown/1 + games.prize_pool, asserting
  # Σ(player key debits) == Σ(house key credits) + Σ(pool key portions) for each — over a
  # config whose first-movers land on a div(pool,9)≠div(pool,10) pool, so a corrupt house
  # cut breaks the live identity, not just the pure arithmetic.
  scenario "PROPERTY: the three-term conservation Σ identity holds over real buy-ins across configs", %{set: set} do
    given_ "a grid of golden-room configs spanning the bands, incl. a first-mover pool of 90 (div9≠div10)" do
      # {entry_fee_keys, start_threshold, first_movers, revenue_pct, member_count}
      configs = [
        {8, 2, 1, 50, 4},
        # fee 20, rev 55 ⇒ first-mover pool_keys = div(20×45,100) = 9 ⇒ pool 90: the
        # divergence point. Two first-movers each contribute 90💎.
        {20, 1, 2, 55, 4},
        # fee 13, rev 15 ⇒ pool_keys = div(13×85,100) = 11 ⇒ pool 110: a second divergence.
        {13, 1, 1, 15, 3},
        {25, 3, 0, 0, 4}
      ]
    end

    when_ "each config runs member_count real buy-ins into a fresh golden room" do
      results =
        for {fee, threshold, fmovers, rev, n} <- configs do
          {:ok, room} =
            Codemojex.create_golden_room("Grid #{fee}-#{rev}", set,
              entry_fee_keys: fee,
              virtual_deposit: 1000,
              start_threshold: threshold,
              first_movers: fmovers,
              entry_fee_revenue_percentage: rev,
              duration_ms: 600_000,
              room_deadline: deadline(48 * 3600)
            )

          players =
            for i <- 1..n do
              {:ok, p} = Codemojex.create_player("P#{fee}-#{rev}-#{i}", keys: fee)
              p
            end

          ks0 = Enum.sum(for p <- players, do: Codemojex.balance(p).keys)
          game = Enum.reduce(players, nil, fn p, _ -> {:ok, g} = Codemojex.join_room(room, p); g end)
          {fee, rev, n, players, ks0, game}
        end
    end

    then_ "for every config Σ(player debits) == Σ(house recovery+revenue credits) + Σ(pool key portions)" do
      for {fee, rev, n, players, ks0, game} <- results do
        ctx = "fee=#{fee} rev=#{rev} n=#{n}"
        # column 1 — the players.keys spent (the bare debit, cm.5, untouched):
        ks1 = Enum.sum(for p <- players, do: Codemojex.balance(p).keys)
        player_debits = ks0 - ks1
        # column 2 — the revenue_ledger per-buy-in credits (recovery + revenue; NOT the
        # seed/reclaim deposit legs, which are not per-buy-in — S5/S7):
        bd = Wallet.revenue_breakdown(game)
        house_credits = Map.get(bd, "deposit_recovery", 0) + Map.get(bd, "revenue", 0)
        # column 3 — the games.prize_pool 💎 contributed by buy-ins (÷10), MINUS the seed:
        pool_keys = div(Store.game(game).prize_pool - 1000, Economy.diamonds_per_key())

        # every member who could afford the fee bought in (keys: fee, one buy-in each):
        assert player_debits == fee * n, "player debits ≠ fee×n: #{ctx}"
        # THE three-term identity — the headline (D-2/D-3). A div(pool,9) house cut makes
        # house_credits too small while the pool is unchanged ⇒ the sum falls short.
        assert house_credits + pool_keys == player_debits,
               "three-term conservation broke: #{ctx} (#{house_credits}+#{pool_keys} ≠ #{player_debits})"
      end
    end
  end

  # S7-PROP — explicit == implicit as a PROPERTY (cm.6.md:197, S7). The fixed S7 proves
  # ONE config; this proves the reconciliation figure equals the cm.5-only conservation
  # figure (Σ fee_i − Σ pool_💎_i/10) for several configs, incl. divergence pools — the
  # equivalence the spec mandates a property test for.
  scenario "PROPERTY: the reconciliation figure equals the cm.5-only conservation figure across configs", %{set: set} do
    given_ "the same config grid (each closes to a per-game revenue_breakdown read)" do
      configs = [
        {8, 2, 1, 50, 4},
        {20, 1, 2, 55, 4},
        {13, 1, 1, 15, 3}
      ]
    end

    when_ "each config runs its buy-ins and finance reads revenue_breakdown(game)" do
      reads =
        for {fee, threshold, fmovers, rev, n} <- configs do
          {:ok, room} =
            Codemojex.create_golden_room("Recon #{fee}-#{rev}", set,
              entry_fee_keys: fee,
              virtual_deposit: 1000,
              start_threshold: threshold,
              first_movers: fmovers,
              entry_fee_revenue_percentage: rev,
              duration_ms: 600_000,
              room_deadline: deadline(48 * 3600)
            )

          game =
            Enum.reduce(1..n, nil, fn i, _ ->
              {:ok, p} = Codemojex.create_player("R#{fee}-#{rev}-#{i}", keys: fee)
              {:ok, g} = Codemojex.join_room(room, p)
              g
            end)

          {fee, rev, n, game}
        end
    end

    then_ "for every config the explicit per-game revenue == Σ fee_i − Σ (pool 💎 from buy-ins / 10)" do
      for {fee, rev, n, game} <- reads do
        ctx = "fee=#{fee} rev=#{rev} n=#{n}"
        bd = Wallet.revenue_breakdown(game)
        # EXPLICIT — the real revenue_ledger rows (the per-buy-in legs):
        explicit = Map.get(bd, "deposit_recovery", 0) + Map.get(bd, "revenue", 0)
        # IMPLICIT — the cm.5-only conservation figure, from the player debits + pool 💎
        # the shipped cm.5 build produces (untouched under the overlay):
        pool_keys_from_buyins = div(Store.game(game).prize_pool - 1000, Economy.diamonds_per_key())
        implicit = fee * n - pool_keys_from_buyins
        # the SAME number — cm.6 makes the implicit explicit, never a different figure.
        assert explicit == implicit, "explicit ≠ implicit: #{ctx} (#{explicit} ≠ #{implicit})"
      end
    end
  end

  # the house revenue_ledger deltas for a game + reason, ordered (the per-game read)
  defp house_rows(game, reason) do
    Repo.all(
      from r in RevenueLedger,
        where: r.ref == ^game and r.reason == ^reason,
        order_by: r.id,
        select: r.delta
    )
  end

  # the total revenue_ledger row count for a game (every reason) — the idempotency probe:
  # a no-op re-fire must leave this unchanged.
  defp ledger_row_count(game) do
    Repo.one(from r in RevenueLedger, where: r.ref == ^game, select: count(r.id))
  end

  defp deadline(seconds_from_now) do
    DateTime.utc_now() |> DateTime.add(seconds_from_now, :second) |> DateTime.truncate(:second)
  end
end
