defmodule Codemojex.Repo.Migrations.GoldenRoomsAndNotifications do
  use Ecto.Migration

  # Golden Rooms — a platform-boosted room class. `golden` flags the class and
  # `gold_multiplier` multiplies the diamond pool the winner takes (the platform
  # funds the boost). Both are snapshotted from the room onto the round at start,
  # so a change to the room never alters a round already in flight.
  #
  # `tg_chat_id` ties a player to their Telegram chat, so a game event (a prize, a
  # golden win) can be delivered through the notification system, which addresses
  # a chat. It is nullable: a player created without one simply receives no push.
  def change do
    alter table(:rooms) do
      add :golden, :boolean, null: false, default: false
      add :gold_multiplier, :integer, null: false, default: 1
    end

    alter table(:rounds) do
      add :golden, :boolean, null: false, default: false
      add :gold_multiplier, :integer, null: false, default: 1
    end

    alter table(:players) do
      add :tg_chat_id, :bigint
    end

    create index(:players, [:tg_chat_id])
  end
end
