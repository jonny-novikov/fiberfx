defmodule Codemojex.Repo.Migrations.CreateCodemojex do
  use Ecto.Migration

  def change do
    # Balances. Branded USR id is the key. The CHECK is the backstop the wallet
    # leans on: even if application logic ever slipped, the DB refuses a negative.
    create table(:players, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
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
      add :duration_ms, :bigint, null: false
      add :seed_pool, :bigint, null: false, default: 0
      add :guess_fee, :integer, null: false, default: 1
      add :free, :boolean, null: false, default: false
      add :clip_cost, :integer, null: false, default: 1
      add :status, :string, null: false, default: "waiting"
      add :round, :string
      timestamps(type: :utc_datetime_usec)
    end

    # The round carries the secret server-side; no player-facing query selects it.
    create table(:rounds, primary_key: false) do
      add :id, :string, primary_key: true
      add :room, :string
      add :emojiset, :string
      add :secret, {:array, :string}, null: false
      add :started_ms, :bigint, null: false
      add :ends_ms, :bigint, null: false
      add :prize_pool, :bigint, null: false, default: 0
      add :guess_fee, :integer, null: false, default: 1
      add :free, :boolean, null: false, default: false
      add :clip_cost, :integer, null: false, default: 1
      add :status, :string, null: false, default: "open"
      timestamps(type: :utc_datetime_usec)
    end

    create index(:rounds, [:room])

    create table(:guesses, primary_key: false) do
      add :id, :string, primary_key: true
      add :round, :string, null: false
      add :player, :string, null: false
      add :emojis, {:array, :string}, null: false
      add :points, :integer, null: false
      add :percentage, :integer
      add :tier, :integer
      add :at_ms, :bigint
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:guesses, [:round, :player])
  end
end
