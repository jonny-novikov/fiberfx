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
    field :gold_multiplier, :integer, default: 1
    # the sealed-split policy snapshotted to a game at start (rank weights summing to the share base)
    field :payout_split, {:array, :integer}, default: [40, 25, 15, 12, 8]
    # the reduced-set size N; null = the full emoji-set keyboard (classic)
    field :cell_count, :integer
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
      :gold_multiplier,
      :payout_split,
      :cell_count
    ])
    |> validate_required([:id, :name, :emojiset, :duration_ms])
  end
end
