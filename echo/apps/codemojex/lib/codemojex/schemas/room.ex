defmodule Codemojex.Schemas.Room do
  @moduledoc "A room template and its at-most-one active round. Field names match the game's maps."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "rooms" do
    field :name, :string
    field :emojiset, :string
    field :duration_ms, :integer
    field :seed_pool, :integer, default: 0
    field :guess_fee, :integer, default: 1
    field :free, :boolean, default: false
    field :clip_cost, :integer, default: 1
    field :status, :string, default: "waiting"
    field :round, :string
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(room, attrs) do
    room
    |> cast(attrs, [:id, :name, :emojiset, :duration_ms, :seed_pool, :guess_fee, :free, :clip_cost, :status, :round])
    |> validate_required([:id, :name, :emojiset, :duration_ms])
  end
end
