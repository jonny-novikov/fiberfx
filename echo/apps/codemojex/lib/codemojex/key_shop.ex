defmodule Codemojex.KeyShop do
  @moduledoc """
  The KeyShop (cm.7) — the multi-rail key-purchase surface.

  Two halves live here:

    * the **pure pricing** (`price_minor/3`, `net_revenue/3`, `usd_face_cents/2`) — the
      `economy.packages.md` model made code. No `Repo`, no clock, no HTTP: the same
      `(package, rail, rates)` always yields the same price (the `Economy` discipline).
      The base Stars ladder carries the discount ONCE (cm-7 D-6 F2); TON/USDT/RUB derive
      from the USD face via the pinned rate, or honor a per-rail override; all money is
      integer minor units, floored, never a float (cm-7 D-6 F5 / F-8).

    * the **order I/O** (`create_order/3`, `settle_payment/1`, `key_packages/0`, the
      reconciliation reads) — the impure half. `create_order/3` pins the price + the rate
      snapshot on the ORD at creation (cm-7 D-4); `settle_payment/1` is the atomic
      fulfilment: ONE `Repo.transaction` that inserts the OTX with Pattern A (gated on the
      `(rail, external_id)` partial unique index), and — only if that insert wrote — mints
      the keys (`Wallet.credit_purchase`, ref=ORD), books the gross to the SAME
      `revenue_ledger` (`Wallet.house_post`, `account="platform"`, `reason="purchase"`,
      cm-7 D-3), and flips the order to `paid`. A replayed payment suppresses the OTX
      insert and mutates nothing — exactly-once by construction (the cm.5 `insert_buy_in`
      pattern, applied to purchases).

  The rate map is `key_shop_rates` (config, runtime.exs at launch — cm-7 D-4). Each
  non-Stars rate is the rail's minor units per ONE USD cent (`ton`/`usdt`/`rub`); the
  base Stars->USD rate is `stars_usd` = hundredths-of-a-cent per Star
  ($0.013/Star, economy.packages.md).
  """
  import Ecto.Query
  alias Codemojex.Repo
  alias Codemojex.Schemas.{Package, Order, OrderTransaction}
  alias Codemojex.{Rails, Wallet}

  # The economy.packages.md baseline: $0.013/Star = 1.3 cents/Star, stored as
  # hundredths-of-a-cent so the USD face is integer-exact (99⭐ -> 129¢, 1449⭐ -> 1884¢).
  @default_stars_usd 130

  # The store fee a Stars sale loses by surface (economy.packages.md: ~32% mobile via
  # Apple/Google, ~3% desktop). A revenue-REPORTING figure (the net view), NOT a booked
  # deduction — the ledger books the gross (INV-GROSS-BOOKED). Frozen module data.
  @store_fee_pct %{mobile: 32, desktop: 3}

  # rail -> the package column carrying its optional pinned minor-unit override (cm-7 D-6 F2).
  @override_key %{"ton" => :ton_price_minor, "usdt" => :usdt_price_minor, "rub" => :rub_price_minor}

  # ---- the pure pricing (no Repo, no clock, no HTTP) -------------------------

  @doc """
  The rail price for a package, in that rail's minor unit (via `Codemojex.Rails`), from
  the base (Stars) ladder + a rate. Stars: the package's `stars_price` verbatim (the
  canonical face — no rate). TON/USDT/RUB: a per-rail override if the package pins one,
  else DERIVED from the USD face via the rate, scaled to the rail's minor unit. Returns
  `{:ok, pos_integer}` or `{:error, reason}` (an unknown rail, a missing price, a missing
  rate).
  """
  @spec price_minor(map(), binary(), map()) :: {:ok, pos_integer()} | {:error, term()}
  def price_minor(package, "stars", _rates) do
    case Map.get(package, :stars_price) do
      p when is_integer(p) and p > 0 -> {:ok, p}
      _ -> {:error, :no_price}
    end
  end

  def price_minor(package, rail, rates) when rail in ~w(ton usdt rub) do
    case override(package, rail) do
      p when is_integer(p) and p > 0 ->
        {:ok, p}

      _ ->
        with rate when is_integer(rate) and rate > 0 <- Map.get(rates, rail, :no_rate) do
          # minor = usd_face_cents × (rail minor units per USD cent), integer-exact, floored.
          {:ok, usd_face_cents(package, rates) * rate}
        else
          _ -> {:error, :no_rate}
        end
    end
  end

  def price_minor(_package, _rail, _rates), do: {:error, :bad_rail}

  @doc """
  Net developer revenue for a Stars sale, by surface (economy.packages.md — ~32% mobile /
  ~3% desktop fee). The store fee is a read-time reporting figure, not a booked deduction.
  Returns `%{usd_cents: integer}`.
  """
  @spec net_revenue(pos_integer(), :mobile | :desktop, map()) :: %{usd_cents: integer()}
  def net_revenue(stars, surface, rates) when surface in [:mobile, :desktop] do
    fee = Map.fetch!(@store_fee_pct, surface)
    %{usd_cents: div(face_cents(stars, rates) * (100 - fee), 100)}
  end

  @doc "A package's USD face in integer cents from its Stars price + the `stars_usd` rate."
  @spec usd_face_cents(map(), map()) :: integer()
  def usd_face_cents(package, rates), do: face_cents(Map.get(package, :stars_price), rates)

  # round-half-up: stars × (hundredths-of-a-cent/star) / 100, integer-exact.
  defp face_cents(stars, rates) when is_integer(stars) do
    div(stars * Map.get(rates, "stars_usd", @default_stars_usd) + 50, 100)
  end

  defp override(package, rail), do: Map.get(package, Map.fetch!(@override_key, rail))

  # ---- the catalog read -----------------------------------------------------

  @doc "The enabled packages, sorted (the shop face) — the public catalog read (cm-7 §5)."
  @spec key_packages() :: [%Package{}]
  def key_packages do
    Repo.all(from p in Package, where: p.enabled == true, order_by: [asc: p.sort, asc: p.id])
  end

  # ---- the order I/O --------------------------------------------------------

  @doc """
  Create a key-purchase order (cm-7 §6). Pins `keys` + the gross `price_minor` from the
  package via `price_minor/3` (Stars = the base; others rate-derived or override), and —
  for a non-Stars rail — the rate snapshot (`rate_minor`/`rate_pair`/`rate_source`/
  `rate_quoted_at`, cm-7 D-4), read ONCE from the `key_shop_rates` config. Inserts the
  ORD in `created`. NO keys are minted yet. Returns `{:ok, %Order{}}` or `{:error, reason}`.
  """
  @spec create_order(binary(), binary(), binary()) :: {:ok, %Order{}} | {:error, term()}
  def create_order(player, package_id, rail) do
    pkg = Repo.get(Package, package_id)

    cond do
      is_nil(pkg) -> {:error, :no_package}
      not pkg.enabled -> {:error, :package_disabled}
      not Rails.known?(rail) -> {:error, :bad_rail}
      true ->
        case price_minor(pkg, rail, rates()) do
          {:ok, price} -> insert_order(player, pkg, rail, price)
          {:error, _} = e -> e
        end
    end
  end

  defp insert_order(player, pkg, rail, price) do
    {rate_minor, rate_pair, rate_source, rate_quoted_at} = rate_snapshot(rail)

    %Order{}
    |> Order.changeset(%{
      id: EchoData.BrandedId.generate!("ORD"),
      player: player,
      package_id: pkg.id,
      rail: rail,
      keys: pkg.keys,
      currency: rail,
      price_minor: price,
      rate_minor: rate_minor,
      rate_pair: rate_pair,
      rate_source: rate_source,
      rate_quoted_at: rate_quoted_at,
      status: "created"
    })
    |> Repo.insert()
  end

  # The rate snapshot pinned on the order (cm-7 D-4). Stars needs no rate (the base price
  # IS Stars) -> all nil. A non-Stars rail pins the config rate value + its provenance, so
  # the booked order self-describes its rate's origin and is reproducible regardless of
  # later rate moves (the live rate is NEVER re-read for that order).
  defp rate_snapshot("stars"), do: {nil, nil, nil, nil}

  defp rate_snapshot(rail) do
    rate = Map.get(rates(), rail)
    quoted_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    {rate, "#{rail}_minor_per_usd_cent", "config", quoted_at}
  end

  @doc """
  Validate a `pre_checkout_query` against the order (cm-7 §7 step 2 — the tamper guard).
  True only when the order exists, is still `created`, and the presented amount equals the
  pinned `price_minor`. Fail-closed: any mismatch, or a non-`created`/absent order, is
  false.
  """
  @spec valid_pre_checkout?(binary(), integer()) :: boolean()
  def valid_pre_checkout?(order_id, amount_minor) do
    case Repo.get(Order, order_id) do
      %Order{status: "created", price_minor: ^amount_minor} -> true
      _ -> false
    end
  end

  @doc """
  The atomic purchase settlement (cm-7 §7 step 3). ONE `Repo.transaction` under a
  `FOR UPDATE` order lock: insert the OTX receipt with Pattern A (`on_conflict: :nothing`
  on the `(rail, external_id)` partial unique index, byte-matched to the migration); IF it
  wrote (the count-rose check, mirroring `insert_buy_in` wallet.ex:425-443) THEN mint the
  keys (`Wallet.credit_purchase`, ref=ORD) AND book the gross to `revenue_ledger`
  (`Wallet.house_post`, `account="platform"`, cm-7 D-3) AND flip the order to `paid`; ELSE
  (a replay — the OTX suppressed) mutate NOTHING. The mint + the booking are GATED on the
  OTX insert, so a doubly-delivered payment mints once, books once. The OTX
  `(rail, external_id)` partial unique index is the SOLE, race-safe exactly-once authority
  (cm-7 D-5) — NOT a `status == "paid"` read-then-act, which has a TOCTOU window the index
  closes and which would also mask the index from the A1 mutation guard.
  Returns `{:ok, :fulfilled}` | `{:ok, :already_fulfilled}` | `{:error, reason}`.
  """
  @spec settle_payment(map()) :: {:ok, :fulfilled | :already_fulfilled} | {:error, term()}
  def settle_payment(%{order_id: order_id, rail: rail, external_id: external_id, amount_minor: amount_minor} = params) do
    payload = Map.get(params, :payload)

    Repo.transaction(fn ->
      case lock_order(order_id) do
        nil ->
          Repo.rollback(:no_order)

        order ->
          case insert_otx(order_id, rail, external_id, amount_minor, payload) do
            :suppressed ->
              # the (rail, external_id) dedup fired — a replay, mint NOTHING / book NOTHING
              :already_fulfilled

            :wrote ->
              # 1. MINT the keys (a players credit — always non-negative, A-7) keyed on the ORD.
              {:ok, _} = Wallet.credit_purchase(order.player, order.keys, order_id)
              # 2. BOOK the gross to the SAME revenue_ledger (cm-7 D-1/D-3) — account="platform",
              #    currency=the rail, reason="purchase", ref=the order id. ZERO DDL on revenue_ledger.
              Wallet.house_post(Wallet.house_account(), order.currency, amount_minor, "purchase", order_id)
              # 3. FLIP the order to paid (the only money-column-adjacent UPDATE; the price/rate stay pinned).
              mark_paid!(order)
              :fulfilled
          end
      end
    end)
  end

  # ---- the reconciliation reads (cm-7 §7) -----------------------------------

  @doc "A player's purchase history — keyed by the orders_player_index."
  @spec orders_for(binary()) :: [%Order{}]
  def orders_for(player) do
    Repo.all(from o in Order, where: o.player == ^player, order_by: [desc: o.inserted_at])
  end

  @doc """
  An order's whole money story — the pinned order + its OTX receipts + the revenue row(s)
  it booked (`revenue_breakdown` by the ORD ref, since purchase rows carry `ref=<ORD id>`).
  """
  @spec order_reconciliation(binary()) :: map()
  def order_reconciliation(order_id) do
    %{
      order: Repo.get(Order, order_id),
      receipts: Repo.all(from t in OrderTransaction, where: t.order_id == ^order_id),
      revenue: Wallet.revenue_breakdown(order_id)
    }
  end

  # ---- internals ------------------------------------------------------------

  defp lock_order(id), do: Repo.one(from o in Order, where: o.id == ^id, lock: "FOR UPDATE")

  # Insert the OTX with Pattern A: on_conflict :nothing on the (rail, external_id) partial
  # unique index. The conflict_target fragment MUST match the migration `where:` predicate
  # byte-for-byte (the cm.5 insert_buy_in discipline). The truth is the LEDGER, not the
  # returned struct: on_conflict: :nothing returns a :loaded struct carrying the minted id
  # even when suppressed, so the caller passes the count BEFORE and we re-count after — the
  # count rose iff a row was actually written.
  defp insert_otx(order_id, rail, external_id, amount_minor, payload) do
    before = otx_count(rail, external_id)

    {:ok, _} =
      %OrderTransaction{}
      |> OrderTransaction.changeset(%{
        id: EchoData.BrandedId.generate!("OTX"),
        order_id: order_id,
        rail: rail,
        external_id: external_id,
        amount_minor: amount_minor,
        status: "confirmed",
        raw_payload: payload
      })
      |> Repo.insert(
        on_conflict: :nothing,
        conflict_target: {:unsafe_fragment, "(rail, external_id) WHERE external_id IS NOT NULL"}
      )

    if otx_count(rail, external_id) > before, do: :wrote, else: :suppressed
  end

  defp otx_count(rail, external_id) do
    Repo.one(
      from t in OrderTransaction,
        where: t.rail == ^rail and t.external_id == ^external_id,
        select: count(t.id)
    )
  end

  defp mark_paid!(order) do
    {:ok, _} = order |> Order.changeset(%{status: "paid"}) |> Repo.update()
  end

  defp rates, do: Application.get_env(:codemojex, :key_shop_rates, %{})
end
