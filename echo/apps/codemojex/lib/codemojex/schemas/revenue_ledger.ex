defmodule Codemojex.Schemas.RevenueLedger do
  @moduledoc """
  An append-only platform-revenue row: one signed entry per platform movement (the
  seed debit, the per-buy-in revenue/recovery credits, the void reclaim). The
  balance is the sum of rows — never an in-place mutation. Holds ONLY platform
  movements (account-scoped), so the platform-revenue balance is a clean aggregate
  with no player rows to exclude (cm.6 D-1).

  The deliberate inverse of `Player`: the `delta` is signed with NO non-negative
  guard (the house legitimately swings negative on the `deposit_seed` debit), and
  there is NO exactly-once index (each house post is a distinct accrual — unlike the
  buy_in marker's (player, ref) uniqueness). The id's uniqueness is the `RVL` PK alone.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "revenue_ledger" do
    field :account, :string
    field :currency, :string
    field :delta, :integer
    field :reason, :string
    field :ref, :string
    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(row, attrs) do
    row
    |> cast(attrs, [:id, :account, :currency, :delta, :reason, :ref])
    |> validate_required([:id, :account, :currency, :delta, :reason])
  end
end
