defmodule Exchange.OrderBookTest do
  @moduledoc """
  Acceptance suite for the pure price-time ladder (rung TRD.2.1,
  `docs/exchange/trd.2.1.specs.md`, step one): `new/0` + `best/2` behavior, the
  price-time ordering property (best price first; within a price, earliest mint
  order first), and a no-float structural scan over a ladder built from generated
  resting orders. `Exchange.OrderBook` is pure and starts nothing; the only
  runtime prerequisite is the branded-id minter (`Exchange.Id.Snowflake.start/1`),
  booted once below so generated `ORD` ids byte-sort in mint order.
  """
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Exchange.OrderBook

  # The minting prerequisite. start/1 is idempotent (:persistent_term-guarded,
  # lib/exchange/id/snowflake.ex), so a fixed node id is safe
  # on every suite run.
  setup_all do
    :ok = Exchange.Id.Snowflake.start(8)
    :ok
  end

  # Build a book directly from a list of {side, price, quantity} by minting an ORD
  # id per order in arrival order (so list order == mint order) and folding each as
  # a :rested event through the Decider's evolve. The OrderBook itself exposes only
  # new/0 + best/2 (the matching/insert is the Decider's, §170-173); this helper
  # threads a resting maker onto the ladder the way the fold does.
  defp rest(book, side, price, quantity, account \\ "acct") do
    order = Exchange.Id.Snowflake.next_branded("ORD")

    Exchange.Decider.evolve(book, {
      :rested,
      %{
        order: order,
        account: account,
        instrument: "X",
        side: side,
        price: price,
        quantity: quantity
      }
    })
  end

  # No number anywhere in a ladder read (the price pair, the resting tuples) may be
  # a float (INV-6). Walks tuples, lists, the :empty atom.
  defp no_float?(f) when is_float(f), do: false
  defp no_float?({a, b}), do: no_float?(a) and no_float?(b)
  defp no_float?(t) when is_tuple(t), do: t |> Tuple.to_list() |> no_float?()
  defp no_float?(list) when is_list(list), do: Enum.all?(list, &no_float?/1)
  defp no_float?(_), do: true

  describe "new/0 — the empty book" do
    test "best/2 reads :empty on both sides" do
      book = OrderBook.new()
      assert OrderBook.best(book, :buy) == :empty
      assert OrderBook.best(book, :sell) == :empty
    end
  end

  describe "best/2 — reads the top of a side" do
    test "the buy side's best is the HIGHEST price" do
      book =
        OrderBook.new()
        |> rest(:buy, {100, 0}, 5)
        |> rest(:buy, {102, 0}, 7)
        |> rest(:buy, {101, 0}, 3)

      assert {{102, 0}, [{_id, _acct, :buy, {102, 0}, 7}]} = OrderBook.best(book, :buy)
    end

    test "the sell side's best is the LOWEST price" do
      book =
        OrderBook.new()
        |> rest(:sell, {100, 0}, 5)
        |> rest(:sell, {98, 0}, 7)
        |> rest(:sell, {99, 0}, 3)

      assert {{98, 0}, [{_id, _acct, :sell, {98, 0}, 7}]} = OrderBook.best(book, :sell)
    end

    test "a nano tiebreak orders below a whole unit" do
      # {100, 500_000_000} is 100.5 — between {100, 0} and {101, 0}.
      book =
        OrderBook.new()
        |> rest(:buy, {100, 0}, 1)
        |> rest(:buy, {100, 500_000_000}, 1)

      assert {{100, 500_000_000}, _} = OrderBook.best(book, :buy)
    end

    test "within one price level the FIFO is earliest mint order first" do
      # Three sells at the same price, minted in this order: the FIFO head is the
      # earliest mint (INV-5 — the ORD id byte order is time priority).
      book =
        OrderBook.new()
        |> rest(:sell, {100, 0}, 1)
        |> rest(:sell, {100, 0}, 2)
        |> rest(:sell, {100, 0}, 3)

      assert {{100, 0}, [first, second, third]} = OrderBook.best(book, :sell)
      {id1, _, _, _, q1} = first
      {id2, _, _, _, q2} = second
      {id3, _, _, _, q3} = third

      # The arrival order (== mint order) is preserved as the FIFO, and the ids
      # byte-sort ascending in that order.
      assert [q1, q2, q3] == [1, 2, 3]
      assert id1 < id2 and id2 < id3
    end

    test "the two sides are independent" do
      book =
        OrderBook.new()
        |> rest(:buy, {99, 0}, 1)
        |> rest(:sell, {101, 0}, 1)

      assert {{99, 0}, _} = OrderBook.best(book, :buy)
      assert {{101, 0}, _} = OrderBook.best(book, :sell)
    end
  end

  describe "no float (INV-6, structural)" do
    test "no float appears in a ladder read" do
      book =
        OrderBook.new()
        |> rest(:buy, {100, 250_000_000}, 5)
        |> rest(:sell, {101, 750_000_000}, 7)

      assert no_float?(OrderBook.best(book, :buy))
      assert no_float?(OrderBook.best(book, :sell))
      assert no_float?(OrderBook.best(OrderBook.new(), :buy))
    end
  end

  # ── The price-time ordering property (StreamData) — INV-5, INV-6 ─────────────

  # A generated price as a {units, nano} integer pair (non-negative — the ladder
  # orders by Erlang term order, which is the venue's price order for non-negative
  # money). nano stays in 0..10^9-1.
  defp price_gen do
    StreamData.tuple({
      StreamData.integer(0..200),
      StreamData.integer(0..999_999_999)
    })
  end

  defp resting_gen(side) do
    StreamData.tuple({StreamData.constant(side), price_gen(), StreamData.integer(1..100)})
  end

  property "best/2 reads price-time order: best price first, earliest mint within a price (INV-5)" do
    check all(orders <- StreamData.list_of(resting_gen(:sell), min_length: 1, max_length: 30)) do
      # Fold the generated sells onto a fresh book IN LIST ORDER, minting an ORD id
      # per order so list order == mint order.
      book =
        Enum.reduce(orders, OrderBook.new(), fn {side, price, qty}, b ->
          rest(b, side, price, qty)
        end)

      case OrderBook.best(book, :sell) do
        :empty ->
          # Only when no order generated — but min_length: 1 forbids it.
          flunk("a non-empty input produced an empty side")

        {best_price, level} ->
          # Price priority: the sell side's best is the minimum generated price.
          min_price = orders |> Enum.map(fn {_s, p, _q} -> p end) |> Enum.min()
          assert best_price == min_price

          # Time priority: within the best level, the FIFO is in ascending id order
          # (== mint order == arrival order), and no float appears.
          ids = Enum.map(level, fn {id, _a, _s, _p, _q} -> id end)
          assert ids == Enum.sort(ids)
          assert Enum.all?(level, fn {_id, _a, _s, p, _q} -> p == best_price end)
          assert no_float?({best_price, level})
      end
    end
  end

  property "the buy side's best is the maximum generated price (INV-5)" do
    check all(orders <- StreamData.list_of(resting_gen(:buy), min_length: 1, max_length: 30)) do
      book =
        Enum.reduce(orders, OrderBook.new(), fn {side, price, qty}, b ->
          rest(b, side, price, qty)
        end)

      {best_price, _level} = OrderBook.best(book, :buy)
      max_price = orders |> Enum.map(fn {_s, p, _q} -> p end) |> Enum.max()
      assert best_price == max_price
    end
  end
end
