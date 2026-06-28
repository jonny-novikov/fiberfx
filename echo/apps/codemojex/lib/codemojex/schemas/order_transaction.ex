defmodule Codemojex.Schemas.OrderTransaction do
  @moduledoc """
  An external rail payment receipt for an order (cm.7, OTX). The
  (rail, external_id) partial unique index is the per-rail exactly-once authority —
  the fix for the 'stars'-literal double-mint (the buy_in exactly-once pattern,
  golden_rooms.exs:73-76, applied to purchases). The key-mint + the revenue booking
  fire only if THIS row's insert actually wrote. external_id is nullable (it does
  not exist until the provider confirms); the FULL provider receipt is preserved in
  raw_payload. Append-only — a refund is a new row.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "order_transactions" do
    field :order_id, :string
    field :rail, :string
    field :external_id, :string
    field :amount_minor, :integer       # the :bigint column; the gross rail amount in native minor units
    field :status, :string, default: "confirmed"
    field :raw_payload, :map            # the :jsonb column — the verbatim provider receipt
    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(otx, attrs) do
    otx
    |> cast(attrs, [:id, :order_id, :rail, :external_id, :amount_minor, :status, :raw_payload])
    |> validate_required([:id, :order_id, :rail, :amount_minor])
    # The DB-error -> changeset-error bridge: a 23505 on the partial unique index
    # surfaces as a changeset error, not a raised ConstraintError. Names the SAME index
    # as the migration byte-for-byte. Mirrors transaction.ex:26.
    |> unique_constraint([:rail, :external_id], name: :order_transactions_rail_external_once_index)
  end
end
