defmodule Codemojex.Schemas.Guess do
  @moduledoc "One scored attempt. The player's own history reads these back; the leaderboard derives from their points. Linear-only — the points total is the sole stored score."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "guesses" do
    field :game, :string
    field :player, :string
    field :emojis, {:array, :string}
    field :points, :integer
    field :at_ms, :integer
    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(g, attrs) do
    g
    |> cast(attrs, [:id, :game, :player, :emojis, :points, :at_ms])
    |> validate_required([:id, :game, :player, :emojis, :points])
  end
end
