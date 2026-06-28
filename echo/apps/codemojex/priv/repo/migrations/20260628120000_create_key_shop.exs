defmodule Codemojex.Repo.Migrations.CreateKeyShop do
  use Ecto.Migration

  # cm.7 — the KeyShop (multi-rail pay-in: Stars + TON/USDT/RUB -> keys). THREE NEW
  # tables (cm-7 D-5): packages (the catalog template), orders (ORD — the lifecycle +
  # the PINNED money), order_transactions (OTX — the external rail receipt + the
  # per-rail exactly-once key). The webhooks (WHK) table is NOT created here — it folds
  # into the OTX (rail, external_id) index for the Stars launch (successful_payment is
  # order-coupled, deduped by OTX directly) and lands with the first push-webhook rail
  # (on-chain TON). Additive onto the FOUR shipped migrations (all byte-frozen, incl.
  # cm.6 revenue_ledger) — cm.7 creates, never edits, and books into revenue_ledger
  # with ZERO DDL (via Wallet.house_post).
  #
  # up is NON-DESTRUCTIVE (pure create + a one-time catalog seed — the destructive gate
  # is a no-op on it); down is the dev-reset inverse (drops the three new tables in
  # FK-dependency order), never a live rollback over orders.
  def up do
    # --- packages: the catalog TEMPLATE (editable; carries updated_at) ---
    create table(:packages, primary_key: false) do
      add :id, :string, primary_key: true
      add :keys, :integer, null: false
      add :stars_price, :integer, null: false          # the base price (whole Stars)
      add :discount_pct, :integer                        # presentational; nullable
      add :ton_price_minor, :bigint                      # nanoTON override; nullable
      add :usdt_price_minor, :bigint                     # micro-USDT override; nullable
      add :rub_price_minor, :bigint                      # kopeck override; nullable
      add :enabled, :boolean, null: false, default: true
      add :sort, :integer, null: false, default: 0
      timestamps(type: :utc_datetime_usec)               # EDITABLE template -> updated_at
    end

    create constraint(:packages, :packages_discount_pct_range,
             check: "discount_pct IS NULL OR (discount_pct >= 0 AND discount_pct <= 100)")

    # --- orders: ORD — the lifecycle + the PINNED money ---
    create table(:orders, primary_key: false) do
      add :id, :string, primary_key: true
      add :player, references(:players, type: :string, column: :id, on_delete: :restrict), null: false
      add :package_id, references(:packages, type: :string, column: :id, on_delete: :nilify_all)
      add :rail, :string, null: false
      add :keys, :integer, null: false                   # pinned from the package at creation
      add :currency, :string, null: false
      add :price_minor, :bigint, null: false             # gross rail amount, native minor units, PINNED
      add :rate_minor, :bigint                            # the rate snapshot; nullable (Stars)
      add :rate_pair, :string
      add :rate_source, :string                           # "config" | <provider> — the provenance (D-4)
      add :rate_quoted_at, :utc_datetime_usec
      add :status, :string, null: false, default: "created"
      timestamps(type: :utc_datetime_usec)                # status mutates -> updated_at
    end

    create constraint(:orders, :orders_rail_valid,
             check: "rail IN ('stars','ton','usdt','rub')")
    create constraint(:orders, :orders_status_valid,
             check: "status IN ('created','paid','failed','refunded')")
    create constraint(:orders, :orders_price_positive, check: "price_minor > 0")
    create index(:orders, [:player])
    create index(:orders, [:status])

    # --- order_transactions: OTX — the external receipt + the per-rail exactly-once key ---
    create table(:order_transactions, primary_key: false) do
      add :id, :string, primary_key: true
      add :order_id, references(:orders, type: :string, column: :id, on_delete: :restrict), null: false
      add :rail, :string, null: false
      add :external_id, :string                           # Stars charge id / TON tx hash / fiat ref; nullable until confirmed
      add :amount_minor, :bigint, null: false             # gross rail amount, native minor units
      add :status, :string, null: false, default: "confirmed"
      add :raw_payload, :map                              # :jsonb — the verbatim provider receipt
      timestamps(type: :utc_datetime_usec, updated_at: false)  # APPEND-ONLY receipt
    end

    create constraint(:order_transactions, :order_transactions_rail_valid,
             check: "rail IN ('stars','ton','usdt','rub')")
    create constraint(:order_transactions, :order_transactions_status_valid,
             check: "status IN ('confirmed','failed','refunded')")
    create constraint(:order_transactions, :order_transactions_amount_positive,
             check: "amount_minor > 0")
    create index(:order_transactions, [:order_id])
    # THE per-rail exactly-once authority (the 'stars'-literal double-mint fix) — PARTIAL
    # UNIQUE, byte-matched by the OrderTransaction changeset + the KeyShop conflict_target.
    create unique_index(:order_transactions, [:rail, :external_id],
             where: "external_id IS NOT NULL",
             name: :order_transactions_rail_external_once_index)

    # Flush the deferred DDL above so the `packages` table EXISTS before the seed insert
    # (the Runner batches create/index ops; a direct repo() write runs immediately).
    flush()

    # The seven launch bundles (economy.packages.md). Seeded once here so the catalog is
    # operational from the first migrate (the order pins its own price, so a later edit
    # changes future orders only). PKG ids are branded snowflakes; a migrate run does not
    # boot the app, so start the (idempotent, persistent_term-backed) snowflake generator
    # before minting.
    EchoData.Snowflake.start()
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    packages =
      for {keys, stars, discount, sort} <- [
            {5, 99, 0, 1},
            {15, 249, 16, 2},
            {50, 799, 20, 3},
            {100, 1449, 27, 4},
            {200, 2599, 35, 5},
            {500, 5499, 45, 6},
            {1000, 9999, 50, 7}
          ] do
        %{
          id: EchoData.BrandedId.generate!("PKG"),
          keys: keys,
          stars_price: stars,
          discount_pct: discount,
          enabled: true,
          sort: sort,
          inserted_at: now,
          updated_at: now
        }
      end

    repo().insert_all("packages", packages)
  end

  def down do
    # drop the THREE new tables in FK-dependency order (children before parents).
    drop table(:order_transactions)
    drop table(:orders)
    drop table(:packages)
  end
end
