defmodule Codemojex.Repo.Migrations.GoldenRooms do
  use Ecto.Migration

  # cm.5 — the Golden Room tournament (the locked economy, cm-5 D-7). Additive onto
  # the two shipped migrations (both byte-frozen). The forks are resolved (D-7):
  # F-1 the pool is diamonds (convert at the increment side), F-2 a per-room
  # `room_deadline` :utc_datetime (the promotional-event end = the game-end),
  # F-3 `gold_multiplier` is dropped unconditionally.
  #
  # up/down are EXPLICIT (not change/0) because a CHECK constraint cannot be ALTERed
  # in place — it is dropped + recreated, and change/0 cannot infer the prior body.
  def up do
    # 1. :gathering — admit it to the games_status CHECK (no ALTER CONSTRAINT in PG;
    #    drop + recreate). 'voided' is already present (20260618000000:110-113).
    drop constraint(:games, :games_status)

    create constraint(:games, :games_status,
             check:
               "status IN ('gathering', 'scheduled', 'open', 'active', 'revealing', 'settling', 'settled', 'voided')"
           )

    # 2. ends_ms holds nil during gathering. Relax null:false (20260618000000:93);
    #    started_ms STAYS null:false (a gathering game is stamped at formation).
    alter table(:games) do
      modify :ends_ms, :bigint, null: true
    end

    # 3. The gather + economy levers, snapshotted room→game (rooms first, then games).
    alter table(:rooms) do
      add :start_threshold, :integer
      add :entry_fee_keys, :integer
      add :virtual_deposit, :bigint
      add :first_movers, :integer
      add :entry_fee_revenue_percentage, :integer
      # the promotional-event end = the game-end (D-7 / D-R4); :utc_datetime renders
      # natively for the bot-engagement nudges, ends_ms aligns to it at :gathering→:open
      add :room_deadline, :utc_datetime
    end

    alter table(:games) do
      add :start_threshold, :integer
      add :entry_fee_keys, :integer
      add :virtual_deposit, :bigint
      add :first_movers, :integer
      add :entry_fee_revenue_percentage, :integer
      add :room_deadline, :utc_datetime
    end

    # 4. The revenue-% domain guard (a money config → a DB backstop, the
    #    players_non_negative philosophy). Nullable-aware (nil = not a Golden config).
    create constraint(:rooms, :rooms_revenue_pct_range,
             check:
               "entry_fee_revenue_percentage IS NULL OR (entry_fee_revenue_percentage >= 0 AND entry_fee_revenue_percentage <= 100)"
           )

    create constraint(:games, :games_revenue_pct_range,
             check:
               "entry_fee_revenue_percentage IS NULL OR (entry_fee_revenue_percentage >= 0 AND entry_fee_revenue_percentage <= 100)"
           )

    # 5. gold_multiplier removed — UNCONDITIONAL DROP (D-7/D-16) on rooms + games.
    alter table(:rooms) do
      remove :gold_multiplier
    end

    alter table(:games) do
      remove :gold_multiplier
    end

    # 6. The buy-in exactly-once / double-charge guard (KEEP). The `where:` predicate
    #    is the SOLE source of truth for the Wallet.buy_in on_conflict conflict_target
    #    fragment — byte-matched. NO refund index (NO REFUND, D-7).
    create unique_index(:transactions, [:player, :ref],
             where: "reason = 'buy_in'",
             name: :transactions_buy_in_once_index
           )

    # 7. The close-time member-set read index (close_split's split + clip-grant loops).
    create index(:transactions, [:ref, :reason], name: :transactions_ref_reason_index)
  end

  def down do
    drop index(:transactions, [:ref, :reason], name: :transactions_ref_reason_index)
    drop index(:transactions, [:player, :ref], name: :transactions_buy_in_once_index)

    # gold_multiplier re-add (data-loss note: original 1-or-3 values not restored —
    # derivable golden? -> 3 : 1). The down is the dev-reset inverse, not a live rollback.
    alter table(:games) do
      add :gold_multiplier, :integer, null: false, default: 1
    end

    alter table(:rooms) do
      add :gold_multiplier, :integer, null: false, default: 1
    end

    drop constraint(:games, :games_revenue_pct_range)
    drop constraint(:rooms, :rooms_revenue_pct_range)

    alter table(:games) do
      remove :start_threshold
      remove :entry_fee_keys
      remove :virtual_deposit
      remove :first_movers
      remove :entry_fee_revenue_percentage
      remove :room_deadline
    end

    alter table(:rooms) do
      remove :start_threshold
      remove :entry_fee_keys
      remove :virtual_deposit
      remove :first_movers
      remove :entry_fee_revenue_percentage
      remove :room_deadline
    end

    # NOTE: re-asserting null:false on ends_ms FAILS over any nil-ends_ms gathering
    # row — the down is the dev-reset inverse, not a live rollback over data.
    alter table(:games) do
      modify :ends_ms, :bigint, null: false
    end

    drop constraint(:games, :games_status)

    create constraint(:games, :games_status,
             check:
               "status IN ('scheduled', 'open', 'active', 'revealing', 'settling', 'settled', 'voided')"
           )
  end
end
