defmodule Codemojex.Schemas.Round do
  @moduledoc "A round: a game in a room. The secret is a server-side column and is never serialized to players. Field names match the plain maps the game logic speaks."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "rounds" do
    field :room, :string
    field :emojiset, :string
    field :secret, {:array, :string}
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

  def changeset(round, attrs) do
    round
    |> cast(attrs, [:id, :room, :emojiset, :secret, :started_ms, :ends_ms, :prize_pool, :guess_fee, :free, :clip_cost, :status, :golden, :gold_multiplier])
    |> validate_required([:id, :secret, :started_ms, :ends_ms])
  end
end
