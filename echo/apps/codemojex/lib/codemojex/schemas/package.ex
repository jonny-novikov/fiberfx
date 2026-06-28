defmodule Codemojex.Schemas.Package do
  @moduledoc """
  A buyable key bundle — the KeyShop catalog (cm.7, PKG). The base price is whole
  Stars (the canonical face, economy.packages.md); the per-rail price is derived at
  order creation + pinned on the order, with an optional nullable per-rail
  minor-unit override. A versionable TEMPLATE — editing it changes future orders
  only (the order pins its own price), so this table carries updated_at while the
  ledger/receipt tables do not.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "packages" do
    field :keys, :integer
    field :stars_price, :integer
    field :discount_pct, :integer
    field :ton_price_minor, :integer     # the :bigint column (nanoTON), nullable override
    field :usdt_price_minor, :integer    # micro-USDT, nullable override
    field :rub_price_minor, :integer     # kopeck, nullable override
    field :enabled, :boolean, default: true
    field :sort, :integer, default: 0
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(pkg, attrs) do
    pkg
    |> cast(attrs, [:id, :keys, :stars_price, :discount_pct,
                    :ton_price_minor, :usdt_price_minor, :rub_price_minor, :enabled, :sort])
    |> validate_required([:id, :keys, :stars_price])
    |> validate_number(:keys, greater_than: 0)
    |> validate_number(:stars_price, greater_than: 0)
    |> check_constraint(:discount_pct, name: :packages_discount_pct_range)
  end
end
