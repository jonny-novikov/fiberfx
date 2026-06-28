defmodule Codemojex.Stories.KeyShopStoryTest do
  @moduledoc """
  GWT acceptance for the cm.7 KeyShop (cm-7 D-1..D-6): the multi-rail key-purchase flow —
  a `PKG` catalog, an `ORD`/`OTX` order model with the `(rail, external_id)` partial-unique
  exactly-once gate, the pinned price + rate, and gross revenue booked into the SAME
  `revenue_ledger` cm.6 founded (`account="platform"`, `reason="purchase"`, `currency=`the
  rail). Stars is settled end to end; TON is exercised as a shaped rail (the same
  `settle_payment/1`, no order/ledger reshape).

  The headline (S-EXACTLY-ONCE) is the double-mint fix: a replayed payment mints keys once
  and books revenue once, gated on the OTX insert. Integration: needs the app, Postgres,
  and a Valkey on $VK_PORT (`mix test --include valkey`).
  """
  use Codemojex.Story, feature: "KeyShop", async: false
  @moduletag :valkey

  alias Codemojex.{Wallet, Repo}
  alias Codemojex.Schemas.{Transaction, RevenueLedger, OrderTransaction, Order, Package}
  import Ecto.Query

  # the launch rates (the runtime.exs key_shop_rates defaults) — set here so TON prices
  # derive; restored per test so no concurrent/later test reads a mutated global.
  @rates %{"stars_usd" => 130, "ton" => 3_846_154, "usdt" => 10_000, "rub" => 90}

  setup do
    prior = Application.get_env(:codemojex, :key_shop_rates)
    Application.put_env(:codemojex, :key_shop_rates, @rates)

    on_exit(fn ->
      case prior do
        nil -> Application.delete_env(:codemojex, :key_shop_rates)
        _ -> Application.put_env(:codemojex, :key_shop_rates, prior)
      end
    end)

    :ok
  end

  # S-EXACTLY-ONCE — THE headline (A1, INV-EXACTLY-ONCE-PER-RAIL): the double-mint fix.
  scenario "S-EXACTLY-ONCE — a replayed Stars payment mints keys once and books revenue once" do
    given_ "a Stars order for the 100-key bundle (created, unpaid)" do
      {:ok, plr} = Codemojex.create_player("Buyer", keys: 0)
      pkg = pkg_with(100)
      {:ok, order} = Codemojex.create_order(plr, pkg.id, "stars")
      charge = "tg_charge_" <> order.id
    end

    when_ "the SAME successful_payment is delivered twice (same rail + external_id)" do
      settle = fn ->
        Codemojex.settle_payment(%{
          order_id: order.id,
          rail: "stars",
          external_id: charge,
          amount_minor: order.price_minor,
          payload: %{"telegram_payment_charge_id" => charge}
        })
      end

      r1 = settle.()
      r2 = settle.()
    end

    then_ "keys rose ONCE; exactly one OTX, one TXN purchase credit, one RVL purchase row" do
      assert r1 == {:ok, :fulfilled}
      assert r2 == {:ok, :already_fulfilled}
      assert Codemojex.balance(plr).keys == 100
      assert otx_count(order.id) == 1
      assert purchase_credits(order.id) == [100]
      assert purchase_revenue_rows(order.id) == [order.price_minor]
    end

    and_ "the second settle is a no-op — the (rail, external_id) partial-unique index is the authority (the A1 mutation guard target)" do
      # removing the unique index (or the on_conflict guard) would let r2 mint a SECOND
      # time — the Director's net-zero spot-check proves the gate proves the gate.
      assert r2 == {:ok, :already_fulfilled}
    end
  end

  # S-THREE-ROWS — atomic recognition (A2, INV-ATOMIC-PURCHASE).
  scenario "S-THREE-ROWS — the receipt, the key credit, and the revenue booking are all-or-nothing" do
    given_ "a Stars order for the 50-key bundle" do
      {:ok, plr} = Codemojex.create_player("Atomic", keys: 0)
      pkg = pkg_with(50)
      {:ok, order} = Codemojex.create_order(plr, pkg.id, "stars")
    end

    when_ "fulfilment commits" do
      result =
        Codemojex.settle_payment(%{
          order_id: order.id,
          rail: "stars",
          external_id: "ch_" <> order.id,
          amount_minor: order.price_minor,
          payload: nil
        })
    end

    then_ "the OTX receipt AND the TXN key credit AND the RVL gross booking are all present" do
      assert result == {:ok, :fulfilled}
      assert otx_count(order.id) == 1
      assert purchase_credits(order.id) == [50]
      assert purchase_revenue_rows(order.id) == [order.price_minor]
      assert Codemojex.balance(plr).keys == 50
      assert Repo.get(Order, order.id).status == "paid"
    end

    and_ "a settle for a nonexistent order rolls back — NONE of the three rows is written, no key minted" do
      bogus = EchoData.BrandedId.generate!("ORD")

      assert {:error, :no_order} =
               Codemojex.settle_payment(%{
                 order_id: bogus,
                 rail: "stars",
                 external_id: "ch_bogus",
                 amount_minor: 1,
                 payload: nil
               })

      assert otx_count(bogus) == 0
      assert purchase_revenue_rows(bogus) == []
    end
  end

  # S-GROSS-REVENUE — same ledger, native unit, multi-currency (A3, INV-GROSS-BOOKED).
  scenario "S-GROSS-REVENUE — revenue is booked gross in the rail's native unit into the same ledger" do
    given_ "a Stars purchase of the 100-key bundle (gross 1449 ⭐)" do
      {:ok, plr} = Codemojex.create_player("Gross", keys: 0)
      pkg = pkg_with(100)
      {:ok, order} = Codemojex.create_order(plr, pkg.id, "stars")

      {:ok, :fulfilled} =
        Codemojex.settle_payment(%{
          order_id: order.id,
          rail: "stars",
          external_id: "ch_" <> order.id,
          amount_minor: order.price_minor,
          payload: nil
        })
    end

    then_ "revenue_ledger holds one +1449 stars row (the gross, currency=stars) and house_balance returns the stars bucket (the cm.6 read, no change)" do
      assert order.price_minor == 1449
      # per-ORD (the test DB has no per-test rollback, so every assertion is keyed on the
      # unique ORD ref — never a global house_balance sum, which accumulates across tests).
      assert purchase_revenue_rows(order.id) == [1449]
      assert purchase_revenue_currencies(order.id) == ["stars"]
      assert Map.has_key?(Wallet.house_balance(), "stars")
    end

    and_ "a TON purchase books into its own nanoTON bucket — each rail stored in its native minor unit (a shaped-rail unit)" do
      {:ok, plr2} = Codemojex.create_player("Whale", keys: 0)
      pkg = pkg_with(100)
      {:ok, ton_order} = Codemojex.create_order(plr2, pkg.id, "ton")

      {:ok, :fulfilled} =
        Codemojex.settle_payment(%{
          order_id: ton_order.id,
          rail: "ton",
          external_id: "ton_tx_" <> ton_order.id,
          amount_minor: ton_order.price_minor,
          payload: nil
        })

      # 1884¢ face × 3_846_154 nanoTON/cent — the native nanoTON gross, never normalized at write.
      assert ton_order.price_minor == 1884 * 3_846_154
      assert purchase_revenue_rows(ton_order.id) == [ton_order.price_minor]
      assert purchase_revenue_currencies(ton_order.id) == ["ton"]
      assert Map.has_key?(Wallet.house_balance(), "ton")
    end
  end

  # S-VISIBLE-REVENUE — the D-3 correctness fix (A8b, INV-VISIBLE-REVENUE).
  scenario "S-VISIBLE-REVENUE — purchase revenue is SEEN by the house_balance reconciliation read (D-3)" do
    given_ "a fulfilled Stars purchase" do
      {:ok, plr} = Codemojex.create_player("Visible", keys: 0)
      pkg = pkg_with(15)
      {:ok, order} = Codemojex.create_order(plr, pkg.id, "stars")

      {:ok, :fulfilled} =
        Codemojex.settle_payment(%{
          order_id: order.id,
          rail: "stars",
          external_id: "ch_" <> order.id,
          amount_minor: order.price_minor,
          payload: nil
        })
    end

    then_ "the purchase row is booked to account=platform — so the default house_balance (WHERE account=platform) SEES it" do
      # keyed on the ORD ref (no global rollback) — the row's account IS the visibility:
      # the default house_balance reads WHERE account="platform", so this row is included.
      assert purchase_revenue_accounts(order.id) == ["platform"]
      assert Map.has_key?(Wallet.house_balance(), "stars")
    end

    and_ "it is NOT booked to account=purchase (which would hide it from the one reconciliation read — the A8b mutation guard target)" do
      # the Director's net-zero spot-check flips the booking to account="purchase"; this
      # assertion then fails (the row would be invisible to house_balance's WHERE filter).
      refute "purchase" in purchase_revenue_accounts(order.id)
    end
  end

  # S-PINNED-RATE — reproducible, self-describing booking (A4, INV-PRICE-PINNED; D-4).
  scenario "S-PINNED-RATE — the price + rate (with provenance) are pinned at creation; the live rate is never re-read" do
    given_ "a TON order created at config rate R" do
      {:ok, plr} = Codemojex.create_player("Pinned", keys: 0)
      pkg = pkg_with(100)
      {:ok, order} = Codemojex.create_order(plr, pkg.id, "ton")
      pinned_price = order.price_minor
      pinned_rate = order.rate_minor
    end

    when_ "the config rate later changes to R'" do
      Application.put_env(:codemojex, :key_shop_rates, Map.put(@rates, "ton", 9_999_999))
    end

    then_ "the order's pinned price + rate are unchanged (R-derived), with the rate provenance recorded" do
      reloaded = Repo.get(Order, order.id)
      assert reloaded.price_minor == pinned_price
      assert reloaded.rate_minor == pinned_rate
      assert reloaded.rate_source == "config"
      assert reloaded.rate_pair == "ton_minor_per_usd_cent"
      refute is_nil(reloaded.rate_quoted_at)
    end

    and_ "the booked revenue equals the pinned price, independent of the current rate" do
      {:ok, :fulfilled} =
        Codemojex.settle_payment(%{
          order_id: order.id,
          rail: "ton",
          external_id: "ton_tx_" <> order.id,
          amount_minor: pinned_price,
          payload: nil
        })

      assert purchase_revenue_rows(order.id) == [pinned_price]
    end
  end

  # S-PRICED — create_order pins the catalog price for the chosen rail (A5 surface).
  scenario "S-PRICED — create_order pins the catalog price per rail (Stars verbatim, TON rate-derived)" do
    given_ "the 100-key bundle (1449 ⭐)" do
      {:ok, plr} = Codemojex.create_player("Priced", keys: 0)
      pkg = pkg_with(100)
    end

    when_ "an order is created for Stars and for TON" do
      {:ok, stars_order} = Codemojex.create_order(plr, pkg.id, "stars")
      {:ok, ton_order} = Codemojex.create_order(plr, pkg.id, "ton")
    end

    then_ "Stars pins the base stars_price verbatim, TON the USD-face-derived nanoTON; keys/currency/status are pinned" do
      assert stars_order.price_minor == 1449
      assert stars_order.keys == 100 and stars_order.currency == "stars" and stars_order.status == "created"
      assert is_nil(stars_order.rate_minor)
      assert ton_order.price_minor == 1884 * 3_846_154
      assert ton_order.currency == "ton" and ton_order.keys == 100
    end
  end

  # S-NO-CLIENT-MINT — the gap closed (A6).
  scenario "S-NO-CLIENT-MINT — create_order mints no keys; the purchase_keys facade is retired" do
    given_ "a player with zero keys" do
      {:ok, plr} = Codemojex.create_player("NoMint", keys: 0)
      pkg = pkg_with(100)
    end

    when_ "an order is created (the price/keys are server-derived from {package_id, rail})" do
      {:ok, order} = Codemojex.create_order(plr, pkg.id, "stars")
    end

    then_ "no keys were minted by create_order — the order is merely created, unpaid" do
      assert Codemojex.balance(plr).keys == 0
      assert order.status == "created"
    end

    and_ "Codemojex.purchase_keys/3 is no longer a public facade function (the client mint path is gone)" do
      refute function_exported?(Codemojex, :purchase_keys, 3)
    end
  end

  # S-CATALOG — editable shop (A8).
  scenario "S-CATALOG — the catalog is DB-stored, sorted, and editable without a deploy" do
    given_ "the seeded launch ladder" do
      pkgs = Codemojex.key_packages()
    end

    then_ "key_packages returns the seven seeded launch bundles, enabled and sorted" do
      assert Enum.map(pkgs, & &1.keys) == [5, 15, 50, 100, 200, 500, 1000]
      assert Enum.all?(pkgs, & &1.enabled)
      sorts = Enum.map(pkgs, & &1.sort)
      assert sorts == Enum.sort(sorts)
    end

    and_ "a package appears when enabled and disappears when disabled — editable without a deploy" do
      # toggle a DEDICATED throwaway (the test DB has no rollback — mutating a seeded row
      # would persist and corrupt the launch ladder for later tests); left disabled, so the
      # enabled read stays the seeded seven.
      pkg_id = EchoData.BrandedId.generate!("PKG")

      {:ok, _} =
        %Package{}
        |> Package.changeset(%{id: pkg_id, keys: 7, stars_price: 149, enabled: true, sort: 99})
        |> Repo.insert()

      assert Enum.any?(Codemojex.key_packages(), &(&1.id == pkg_id))

      {:ok, _} = Repo.get(Package, pkg_id) |> Ecto.Changeset.change(enabled: false) |> Repo.update()
      refute Enum.any?(Codemojex.key_packages(), &(&1.id == pkg_id))
    end
  end

  # S-CM6-FROZEN — additive only; cm.7 produces into the cm.6 ledger via the cm.6 reads (A9 topology).
  scenario "S-CM6-FROZEN — cm.7 books into the SAME revenue_ledger, read by the cm.6 reads unchanged" do
    given_ "a fulfilled Stars purchase" do
      {:ok, plr} = Codemojex.create_player("Frozen", keys: 0)
      pkg = pkg_with(100)
      {:ok, order} = Codemojex.create_order(plr, pkg.id, "stars")

      {:ok, :fulfilled} =
        Codemojex.settle_payment(%{
          order_id: order.id,
          rail: "stars",
          external_id: "ch_" <> order.id,
          amount_minor: order.price_minor,
          payload: nil
        })
    end

    then_ "the cm.6 revenue_breakdown(ref) reads the purchase row, and house_balance returns the new bucket — NO read change" do
      # the cm.6 reads are reused verbatim: revenue_breakdown by the ORD ref (per-ref, exact)
      # and house_balance grouped by currency (the new "stars" bucket present, the seam).
      assert Wallet.revenue_breakdown(order.id) == %{"purchase" => 1449}
      assert Map.has_key?(Wallet.house_balance(), "stars")
    end
  end

  # --- helpers ---------------------------------------------------------------

  defp pkg_with(keys), do: Enum.find(Codemojex.key_packages(), &(&1.keys == keys))

  defp purchase_credits(order_id) do
    Repo.all(
      from t in Transaction,
        where: t.ref == ^order_id and t.reason == "purchase",
        select: t.delta
    )
  end

  defp purchase_revenue_rows(order_id) do
    Repo.all(
      from r in RevenueLedger,
        where: r.ref == ^order_id and r.reason == "purchase",
        select: r.delta
    )
  end

  defp purchase_revenue_currencies(order_id) do
    Repo.all(
      from r in RevenueLedger,
        where: r.ref == ^order_id and r.reason == "purchase",
        select: r.currency
    )
  end

  defp purchase_revenue_accounts(order_id) do
    Repo.all(
      from r in RevenueLedger,
        where: r.ref == ^order_id and r.reason == "purchase",
        select: r.account
    )
  end

  defp otx_count(order_id) do
    Repo.one(from o in OrderTransaction, where: o.order_id == ^order_id, select: count(o.id))
  end
end
