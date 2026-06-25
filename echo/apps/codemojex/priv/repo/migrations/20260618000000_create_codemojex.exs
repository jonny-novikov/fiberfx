defmodule Codemojex.Repo.Migrations.CreateCodemojex do
  use Ecto.Migration

  # The one clean initial schema for the game-engine model (D-3: a fresh machine,
  # no data migration — the two prior create/alter migrations are collapsed here).
  # Six tables: players, transactions, emoji_sets, rooms, games, guesses. `NOT`
  # (notification) is a Valkey bus lane, not a Postgres table.
  def change do
    # Balances. The branded PLR id is the key. The CHECK is the backstop the wallet
    # leans on: even if application logic ever slipped, the DB refuses a negative.
    create table(:players, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :tg_chat_id, :bigint
      add :keys, :bigint, null: false, default: 0
      add :clips, :bigint, null: false, default: 0
      add :diamonds, :bigint, null: false, default: 0
      add :bonus_diamonds, :bigint, null: false, default: 0
      add :locked_diamonds, :bigint, null: false, default: 0
      timestamps(type: :utc_datetime_usec)
    end

    create constraint(:players, :players_non_negative,
             check:
               "keys >= 0 AND clips >= 0 AND diamonds >= 0 AND bonus_diamonds >= 0 AND locked_diamonds >= 0"
           )

    create index(:players, [:tg_chat_id])

    # The ledger: append-only, queried per player for a statement.
    create table(:transactions, primary_key: false) do
      add :id, :string, primary_key: true
      add :player, :string, null: false
      add :currency, :string, null: false
      add :delta, :bigint, null: false
      add :reason, :string, null: false
      add :ref, :string
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:transactions, [:player, :inserted_at])

    create table(:emoji_sets, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :cols, :integer, null: false
      add :rows, :integer, null: false
      add :cell_size, :integer, null: false
      add :sprite_url, :string
      add :codes, {:array, :string}, null: false, default: []
      timestamps(type: :utc_datetime_usec)
    end

    create table(:rooms, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :emojiset, :string, null: false
      add :type, :string, null: false, default: "classic"
      add :duration_ms, :bigint, null: false
      add :seed_pool, :bigint, null: false, default: 0
      add :guess_fee, :integer, null: false, default: 1
      add :free, :boolean, null: false, default: false
      add :clip_cost, :integer, null: false, default: 1
      add :status, :string, null: false, default: "waiting"
      add :game, :string
      add :golden, :boolean, null: false, default: false
      add :gold_multiplier, :integer, null: false, default: 1
      add :payout_split, {:array, :integer}, null: false, default: [40, 25, 15, 12, 8]
      add :cell_count, :integer
      timestamps(type: :utc_datetime_usec)
    end

    # The game carries the secret (and, for golden, the nonce) server-side; no
    # player-facing query selects them. The four blind columns ship LIVE but inert
    # for a classic game (NULL); a golden game writes them via the commit-reveal flow.
    create table(:games, primary_key: false) do
      add :id, :string, primary_key: true
      add :room, :string
      add :emojiset, :string
      add :type, :string, null: false, default: "classic"
      add :feedback, :string, null: false, default: "score"
      add :scoring, :string, null: false, default: "linear"
      add :settlement, :string, null: false, default: "live"
      add :economy, :string, null: false, default: "winner_take_all"
      add :secret, {:array, :string}, null: false
      add :cell_codes, {:array, :string}, null: false, default: []
      add :commitment, :string
      add :nonce, :string
      add :revealed_ms, :bigint
      add :top_k, :integer, null: false, default: 5
      add :payout_split, {:array, :integer}, null: false, default: [40, 25, 15, 12, 8]
      add :started_ms, :bigint, null: false
      add :ends_ms, :bigint, null: false
      add :prize_pool, :bigint, null: false, default: 0
      add :guess_fee, :integer, null: false, default: 1
      add :free, :boolean, null: false, default: false
      add :clip_cost, :integer, null: false, default: 1
      add :status, :string, null: false, default: "open"
      add :golden, :boolean, null: false, default: false
      add :gold_multiplier, :integer, null: false, default: 1
      timestamps(type: :utc_datetime_usec)
    end

    create index(:games, [:room])

    # The type discriminator is bounded to the launch set, and the status to the
    # seven canon state words — an unknown value cannot be written.
    create constraint(:games, :games_type, check: "type IN ('classic', 'golden')")

    create constraint(:games, :games_status,
             check:
               "status IN ('scheduled', 'open', 'active', 'revealing', 'settling', 'settled', 'voided')"
           )

    # Linear-only: no tier, no percentage column. The points total is the sole score.
    create table(:guesses, primary_key: false) do
      add :id, :string, primary_key: true
      add :game, :string, null: false
      add :player, :string, null: false
      add :emojis, {:array, :string}, null: false
      add :points, :integer, null: false
      add :at_ms, :bigint
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:guesses, [:game, :player])
  end
end
