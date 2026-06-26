defmodule Codemojex.Schemas.Room do
  @moduledoc "A room template and its at-most-one active game. Field names match the game's maps."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "rooms" do
    field :name, :string
    field :emojiset, :string
    # the room's default game type (classic | golden)
    field :type, :string, default: "classic"
    field :duration_ms, :integer
    field :seed_pool, :integer, default: 0
    field :guess_fee, :integer, default: 1
    field :free, :boolean, default: false
    field :clip_cost, :integer, default: 1
    field :status, :string, default: "waiting"
    field :game, :string
    field :golden, :boolean, default: false
    # the sealed-split policy snapshotted to a game at start (rank weights summing to the share base)
    field :payout_split, {:array, :integer}, default: [40, 25, 15, 12, 8]
    # the reduced-set size N; null = the full emoji-set keyboard (classic)
    field :cell_count, :integer
    # the Golden Room tournament levers (cm.5), snapshotted to a game at start.
    # All nullable: nil = an ordinary room. See Codemojex.Schemas.Game for the roles.
    field :start_threshold, :integer
    field :entry_fee_keys, :integer
    field :virtual_deposit, :integer
    field :first_movers, :integer
    field :entry_fee_revenue_percentage, :integer
    field :room_deadline, :utc_datetime
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(room, attrs) do
    room
    |> cast(attrs, [
      :id,
      :name,
      :emojiset,
      :type,
      :duration_ms,
      :seed_pool,
      :guess_fee,
      :free,
      :clip_cost,
      :status,
      :game,
      :golden,
      :payout_split,
      :cell_count,
      :start_threshold,
      :entry_fee_keys,
      :virtual_deposit,
      :first_movers,
      :entry_fee_revenue_percentage,
      :room_deadline
    ])
    |> validate_required([:id, :name, :emojiset, :duration_ms])
    # the dual guard mirroring the DB CHECK: the platform's revenue share is 0..100
    |> validate_number(:entry_fee_revenue_percentage,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    )
    # R11 (INV-NOTFREE): a real-money buy-in room cannot carry free:true.
    |> validate_buy_in_not_free()
  end

  # A golden:true room (a real-money buy-in) cannot also be free:true — the two
  # currency rails never cross (a buy-in spends keys; a free room only clips).
  defp validate_buy_in_not_free(cs) do
    if get_field(cs, :golden) and get_field(cs, :free) do
      add_error(cs, :free, "a golden (buy-in) room cannot be free")
    else
      cs
    end
  end
end
