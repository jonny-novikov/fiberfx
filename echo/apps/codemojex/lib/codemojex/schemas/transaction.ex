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
    # cm.5: the DB-error → changeset-error bridge for the buy-in double-charge guard.
    # Names the SAME partial index as the migration. Defense-in-depth — the buy-in
    # INSERT uses Pattern A (on_conflict: :nothing) directly, so a violation should
    # not surface here, but this keeps a stray buy_in conflict a changeset error, not
    # a raised ConstraintError. Mirrors player.ex:33.
    |> unique_constraint(:ref, name: :transactions_buy_in_once_index)
  end
end
