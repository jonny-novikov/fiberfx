defmodule Codemojex.Schemas.Game do
  @moduledoc "A game: one play in a room. The secret (and, for a golden game, the nonce) is a server-side column and is never serialized to players. Field names match the plain maps the game logic speaks."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "games" do
    field :room, :string
    field :emojiset, :string
    # the engine discriminator + the four policies the type selects (snapshotted from the room at start)
    field :type, :string, default: "classic"
    field :feedback, :string, default: "score"
    field :scoring, :string, default: "linear"
    field :settlement, :string, default: "live"
    field :economy, :string, default: "winner_take_all"
    field :secret, {:array, :string}
    # the game's snapshotted keyboard (the full set, or a randomized N-cell subset for a reduced golden game); the secret draws from this
    field :cell_codes, {:array, :string}
    # the four blind-mode columns — NULL for classic, written for golden (commit-reveal)
    field :commitment, :string
    field :nonce, :string
    field :revealed_ms, :integer
    field :top_k, :integer, default: 5
    # the sealed-split weights, snapshotted from the room: rank i takes split[i]/Σsplit of the prize pool
    field :payout_split, {:array, :integer}, default: [40, 25, 15, 12, 8]
    field :started_ms, :integer
    field :ends_ms, :integer
    field :prize_pool, :integer, default: 0
    field :guess_fee, :integer, default: 1
    field :free, :boolean, default: false
    field :clip_cost, :integer, default: 1
    field :status, :string, default: "open"
    field :golden, :boolean, default: false
    field :gold_multiplier, :integer, default: 1
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, [
      :id,
      :room,
      :emojiset,
      :type,
      :feedback,
      :scoring,
      :settlement,
      :economy,
      :secret,
      :cell_codes,
      :commitment,
      :nonce,
      :revealed_ms,
      :top_k,
      :payout_split,
      :started_ms,
      :ends_ms,
      :prize_pool,
      :guess_fee,
      :free,
      :clip_cost,
      :status,
      :golden,
      :gold_multiplier
    ])
    |> validate_required([:id, :secret, :started_ms, :ends_ms])
  end
end
