defmodule Codemojex.Schemas.EmojiSet do
  @moduledoc "An emoji set: a sprite grid plus the XXYY code subset a room exposes."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "emoji_sets" do
    field :name, :string
    field :cols, :integer
    field :rows, :integer
    field :cell_size, :integer
    field :sprite_url, :string
    field :codes, {:array, :string}
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(set, attrs) do
    set
    |> cast(attrs, [:id, :name, :cols, :rows, :cell_size, :sprite_url, :codes])
    |> validate_required([:id, :name, :cols, :rows, :cell_size, :codes])
  end
end
