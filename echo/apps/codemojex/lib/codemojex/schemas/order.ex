defmodule Codemojex.Schemas.Order do
  @moduledoc """
  A key-purchase order (cm.7, ORD) — the rail-independent lifecycle (created -> paid
  -> failed/refunded) + the PINNED money (price_minor + the rate snapshot, frozen at
  creation). The order id is the ref on the keys-mint transactions row AND the
  revenue_ledger row (the per-order reconciliation key, replacing the weak 'stars'
  literal). The money columns are pinned at creation by discipline (never UPDATEd
  after paid), so a later package/rate edit never rewrites a booked order. The
  append-only receipts are OTX (order_transaction.ex).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @rails ~w(stars ton usdt rub)
  @statuses ~w(created paid failed refunded)

  schema "orders" do
    field :player, :string
    field :package_id, :string
    field :rail, :string
    field :keys, :integer
    field :currency, :string
    field :price_minor, :integer        # the :bigint column; gross rail amount in native minor units
    field :rate_minor, :integer         # the :bigint column; the pinned rate snapshot (nullable; Stars=nil)
    field :rate_pair, :string
    field :rate_source, :string
    field :rate_quoted_at, :utc_datetime_usec
    field :status, :string, default: "created"
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:id, :player, :package_id, :rail, :keys, :currency, :price_minor,
                    :rate_minor, :rate_pair, :rate_source, :rate_quoted_at, :status])
    |> validate_required([:id, :player, :rail, :keys, :currency, :price_minor])
    |> validate_inclusion(:rail, @rails)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:keys, greater_than: 0)
    |> validate_number(:price_minor, greater_than: 0)
    # the DB-error -> changeset-error bridge for the status/rail CHECKs (migration §3).
    |> check_constraint(:rail, name: :orders_rail_valid)
    |> check_constraint(:status, name: :orders_status_valid)
  end
end
