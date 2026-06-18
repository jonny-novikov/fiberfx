defmodule Codemojex.Schemas.Transaction do
  @moduledoc "An append-only ledger row: one per balance mutation, written in the same DB transaction as the balance change."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "transactions" do
    field :player, :string
    field :currency, :string
    field :delta, :integer
    field :reason, :string
    field :ref, :string
    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(txn, attrs) do
    txn
    |> cast(attrs, [:id, :player, :currency, :delta, :reason, :ref])
    |> validate_required([:id, :player, :currency, :delta, :reason])
  end
end
