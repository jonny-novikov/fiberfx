defmodule Codemojex.Schemas.Guess do
  @moduledoc "One scored attempt. The player's own history reads these back; the leaderboard derives from their points."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "guesses" do
    field :round, :string
    field :player, :string
    field :emojis, {:array, :string}
    field :points, :integer
    field :percentage, :integer
    field :tier, :integer
    field :at_ms, :integer
    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(g, attrs) do
    g
    |> cast(attrs, [:id, :round, :player, :emojis, :points, :percentage, :tier, :at_ms])
    |> validate_required([:id, :round, :player, :emojis, :points])
  end
end
