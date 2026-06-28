defmodule Codemojex.KeyShopTest do
  @moduledoc """
  The pure KeyShop pricing (cm.7 — S5/A5): priced per rail, the USD face, net revenue by
  surface, the per-rail override, and purity. No DB, no HTTP — runs in the default suite.
  The figures are grounded in economy.packages.md (the 100-key bundle = 1449⭐, $18.84 face,
  $12.81 mobile / $18.27 desktop net).
  """
  use ExUnit.Case, async: true

  alias Codemojex.KeyShop

  # the launch rates (the runtime.exs key_shop_rates defaults): stars_usd in
  # hundredths-of-a-cent per Star; each non-Stars rate in minor units per ONE USD cent.
  @rates %{"stars_usd" => 130, "ton" => 3_846_154, "usdt" => 10_000, "rub" => 90}

  # the 100-key bundle (economy.packages.md), as a plain map (price_minor is pure over a map).
  @pkg %{
    keys: 100,
    stars_price: 1449,
    discount_pct: 27,
    ton_price_minor: nil,
    usdt_price_minor: nil,
    rub_price_minor: nil
  }

  describe "usd_face_cents/2" do
    test "is the Stars price scaled by the stars_usd rate, integer-exact (economy.packages.md)" do
      assert KeyShop.usd_face_cents(@pkg, @rates) == 1884
      assert KeyShop.usd_face_cents(%{stars_price: 99}, @rates) == 129
      assert KeyShop.usd_face_cents(%{stars_price: 9999}, @rates) == 12_999
    end
  end

  describe "price_minor/3" do
    test "Stars returns the package stars_price VERBATIM (the canonical base face, no rate)" do
      assert KeyShop.price_minor(@pkg, "stars", @rates) == {:ok, 1449}
      # Stars needs no rate at all
      assert KeyShop.price_minor(@pkg, "stars", %{}) == {:ok, 1449}
    end

    test "TON is the USD-face-derived nanoTON via the pinned rate (native minor unit, F5)" do
      assert KeyShop.price_minor(@pkg, "ton", @rates) == {:ok, 1884 * 3_846_154}
    end

    test "USDT is micro-USDT and RUB is kopeck, each USD-face-derived" do
      assert KeyShop.price_minor(@pkg, "usdt", @rates) == {:ok, 1884 * 10_000}
      assert KeyShop.price_minor(@pkg, "rub", @rates) == {:ok, 1884 * 90}
    end

    test "a per-rail OVERRIDE on the package wins over the derived price (cm-7 D-6 F2)" do
      pinned = Map.put(@pkg, :ton_price_minor, 5_000_000_000)
      assert KeyShop.price_minor(pinned, "ton", @rates) == {:ok, 5_000_000_000}
    end

    test "a missing rate (no override) is a clean error, never a float or a crash" do
      assert KeyShop.price_minor(@pkg, "ton", %{}) == {:error, :no_rate}
    end

    test "an unknown rail is rejected" do
      assert KeyShop.price_minor(@pkg, "btc", @rates) == {:error, :bad_rail}
    end

    test "purity — the same (package, rail, rates) always yields the same price" do
      assert KeyShop.price_minor(@pkg, "ton", @rates) == KeyShop.price_minor(@pkg, "ton", @rates)
      assert KeyShop.price_minor(@pkg, "stars", @rates) == KeyShop.price_minor(@pkg, "stars", @rates)
    end
  end

  describe "net_revenue/3" do
    test "mobile nets ~68% and desktop ~97% of the USD face (economy.packages.md, exact for the 100-key bundle)" do
      # face $18.84; mobile (32% fee) -> $12.81; desktop (3% fee) -> $18.27.
      assert KeyShop.net_revenue(1449, :mobile, @rates) == %{usd_cents: 1281}
      assert KeyShop.net_revenue(1449, :desktop, @rates) == %{usd_cents: 1827}
    end

    test "the store fee is a reporting figure — mobile < desktop < the gross face" do
      face = KeyShop.usd_face_cents(@pkg, @rates)
      %{usd_cents: mobile} = KeyShop.net_revenue(1449, :mobile, @rates)
      %{usd_cents: desktop} = KeyShop.net_revenue(1449, :desktop, @rates)
      assert mobile < desktop and desktop < face
      # ~68% / ~97% within a cent of the percentage figure
      assert_in_delta mobile, div(face * 68, 100), 1
      assert_in_delta desktop, div(face * 97, 100), 1
    end
  end
end
