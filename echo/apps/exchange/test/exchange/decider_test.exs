defmodule Exchange.DeciderTest do
  @moduledoc """
  Acceptance suite for the pure matching rule (rung TRD.2.1,
  `docs/exchange/trd.2.1.specs.md`, step two): G1 (a crossing pair fills at the
  maker's price, branded FIL id, the limit remainder rests), G2 (price-time
  priority over `decide`), G5 (no float in any event or folded book), G6
  (same-account orders do not self-fill; the aggressor is rejected `:self_trade`,
  the book unchanged), AS-7 (every `:fill` carries a `FIL`-namespace `valid?`
  14-byte id + integer money), and AS-2 (the source of `decider.ex`, comments
  stripped, holds none of the forbidden-effect set).

  `Exchange.Decider` is pure modulo the FIL mint (INV-3); the only runtime
  prerequisite is `EchoData.Snowflake.start/1`, booted once below so the `ORD`
  ids minted in `setup`/helpers and the `FIL` ids minted inside `decide` byte-sort
  in mint order (INV-5). Properties never assert id-equality across two `decide`
  calls (D-5).
  """
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Exchange.{OrderBook, Decider}
  alias EchoData.{Snowflake, BrandedId}

  setup_all do
    :ok = Snowflake.start(8)
    :ok
  end

  # Mint an ORD id the way the Gateway does (the time component of price-time
  # priority). Minted in call order, so successive ids byte-sort ascending.
  defp ord, do: Snowflake.next_branded("ORD")

  # A {:place, …} command with the TRD.1.1 fields; the id is freshly minted unless
  # one is passed (a test that needs to name the taker id keeps it).
  defp place(overrides) do
    base = %{
      id: ord(),
      instrument: "BBG004730N88",
      account: "acct-A",
      direction: :buy,
      type: :limit,
      quantity: 10,
      price: {100, 0}
    }

    {:place, Map.merge(base, overrides)}
  end

  # Fold a fresh resting maker onto a book (a :rested event the way decide emits
  # one), minting its ORD id so arrival order == mint order. Returns {book, id}.
  defp rest_maker(book, side, price, quantity, account) do
    id = ord()

    book =
      Decider.evolve(book, {
        :rested,
        %{
          order: id,
          account: account,
          instrument: "BBG004730N88",
          side: side,
          price: price,
          quantity: quantity
        }
      })

    {book, id}
  end

  # The whole-book fold of decide's emitted events (INV-4).
  defp fold(events, book), do: Enum.reduce(events, book, fn e, b -> Decider.evolve(b, e) end)

  # Structural float-scan over any event/book term (INV-6 / G5).
  defp no_float?(f) when is_float(f), do: false

  defp no_float?(%OrderBook{buy: buy, sell: sell}) do
    no_float?(:gb_trees.to_list(buy)) and no_float?(:gb_trees.to_list(sell))
  end

  defp no_float?(%{} = m), do: Enum.all?(m, fn {k, v} -> no_float?(k) and no_float?(v) end)
  defp no_float?({a, b}), do: no_float?(a) and no_float?(b)
  defp no_float?(t) when is_tuple(t), do: t |> Tuple.to_list() |> no_float?()
  defp no_float?(list) when is_list(list), do: Enum.all?(list, &no_float?/1)
  defp no_float?(_), do: true

  # ── G1 — a crossing pair fills at the maker's price ──────────────────────────

  describe "G1 — two crossing orders fill at the maker's price (INV-4, INV-5, INV-6)" do
    test "a crossing buy fills the resting sell at the maker's price; the limit remainder rests" do
      # A resting sell of 10 @ {100, 0}; a crossing buy of 15 @ {101, 0}.
      {book, sell_id} = rest_maker(OrderBook.new(), :sell, {100, 0}, 10, "acct-S")
      {:place, buy} = place(%{account: "acct-B", direction: :buy, quantity: 15, price: {101, 0}})

      assert [{:fill, f}, {:rested, r}] = Decider.decide({:place, buy}, book)

      # The fill is at the MAKER's price, the matched quantity, both order ids.
      assert f.price == {100, 0}
      assert f.quantity == 10
      assert f.taker == buy.id
      assert f.maker == sell_id
      assert f.instrument == "BBG004730N88"

      # AS-7: a branded FIL id, 14 bytes, valid?, namespace "FIL".
      assert byte_size(f.id) == 14
      assert BrandedId.valid?(f.id)
      assert BrandedId.namespace(f.id) == "FIL"

      # The limit remainder (5) rests on the buy side at the limit price.
      assert r.order == buy.id
      assert r.side == :buy
      assert r.price == {101, 0}
      assert r.quantity == 5

      # After the fold: the sell is consumed; the buy remainder rests.
      next = fold([{:fill, f}, {:rested, r}], book)
      assert OrderBook.best(next, :sell) == :empty
      assert {{101, 0}, [{_, "acct-B", :buy, {101, 0}, 5}]} = OrderBook.best(next, :buy)
    end

    test "an exact-quantity cross fills fully with no remainder" do
      {book, _sell_id} = rest_maker(OrderBook.new(), :sell, {100, 0}, 10, "acct-S")
      {:place, buy} = place(%{account: "acct-B", direction: :buy, quantity: 10, price: {100, 0}})

      assert [{:fill, f}] = Decider.decide({:place, buy}, book)
      assert f.quantity == 10
      # No :rested — fully filled.
      assert fold([{:fill, f}], book) |> OrderBook.best(:sell) == :empty
    end

    test "a non-crossing limit order rests, never rejects (D-3)" do
      # A buy below the resting ask does not cross — it rests.
      {book, _sell_id} = rest_maker(OrderBook.new(), :sell, {105, 0}, 10, "acct-S")
      {:place, buy} = place(%{account: "acct-B", direction: :buy, quantity: 4, price: {100, 0}})

      assert [{:rested, r}] = Decider.decide({:place, buy}, book)
      assert r.quantity == 4
      assert r.price == {100, 0}
    end

    test "an aggressor crossing two makers emits one :fill per maker, each at its price" do
      # Two sells: 4 @ {100,0} (earlier) then 6 @ {101,0}; a buy of 8 @ {101,0}
      # crosses both — fills 4 @ {100,0} then 4 @ {101,0}.
      {b1, m1} = rest_maker(OrderBook.new(), :sell, {100, 0}, 4, "acct-S")
      {b2, m2} = rest_maker(b1, :sell, {101, 0}, 6, "acct-S")
      {:place, buy} = place(%{account: "acct-B", direction: :buy, quantity: 8, price: {101, 0}})

      assert [{:fill, f1}, {:fill, f2}] = Decider.decide({:place, buy}, b2)
      assert {f1.maker, f1.price, f1.quantity} == {m1, {100, 0}, 4}
      assert {f2.maker, f2.price, f2.quantity} == {m2, {101, 0}, 4}
      # Two fills, two distinct FIL ids (mint order — never asserted equal).
      assert f1.id != f2.id
    end
  end

  # ── G2 — price-time priority over decide ─────────────────────────────────────

  describe "G2 — price-time priority holds (INV-5)" do
    test "among makers at one price, the earlier mint fills first" do
      # Two sells at the SAME price; the earlier-minted maker fills first.
      {b1, m1} = rest_maker(OrderBook.new(), :sell, {100, 0}, 5, "acct-S1")
      {b2, _m2} = rest_maker(b1, :sell, {100, 0}, 5, "acct-S2")
      {:place, buy} = place(%{account: "acct-B", direction: :buy, quantity: 5, price: {100, 0}})

      assert [{:fill, f}] = Decider.decide({:place, buy}, b2)
      assert f.maker == m1
    end

    test "among prices, the best fills first (a buy lifts the lowest ask)" do
      # Sells at {101,0} (minted first) and {100,0} (minted second). A buy crosses
      # both but the BEST price (lowest ask {100,0}) fills first despite later mint.
      {b1, _m_high} = rest_maker(OrderBook.new(), :sell, {101, 0}, 5, "acct-S1")
      {b2, m_low} = rest_maker(b1, :sell, {100, 0}, 5, "acct-S2")
      {:place, buy} = place(%{account: "acct-B", direction: :buy, quantity: 3, price: {101, 0}})

      assert [{:fill, f}] = Decider.decide({:place, buy}, b2)
      assert f.maker == m_low
      assert f.price == {100, 0}
    end

    property "the first fill is always at the best opposite price, earliest mint" do
      check all(
              prices <-
                StreamData.list_of(StreamData.integer(95..104), min_length: 1, max_length: 8),
              take <- StreamData.integer(1..3)
            ) do
        # Rest one sell of `take` lots at each generated price (in list order ==
        # mint order), then a large crossing buy at {200, 0}.
        {book, makers} =
          Enum.reduce(prices, {OrderBook.new(), []}, fn p, {b, acc} ->
            {b2, id} = rest_maker(b, :sell, {p, 0}, take, "acct-S")
            {b2, [{p, id} | acc]}
          end)

        makers = Enum.reverse(makers)

        {:place, buy} =
          place(%{account: "acct-B", direction: :buy, quantity: take, price: {200, 0}})

        case Decider.decide({:place, buy}, book) do
          [{:fill, f} | _] ->
            best_price = prices |> Enum.min()
            assert f.price == {best_price, 0}
            # The maker filled is the EARLIEST-minted order at the best price.
            earliest_at_best =
              makers |> Enum.filter(fn {p, _} -> p == best_price end) |> List.first() |> elem(1)

            assert f.maker == earliest_at_best

          other ->
            flunk("a crossing buy produced no fill: #{inspect(other)}")
        end
      end
    end
  end

  # ── G5 — no float ────────────────────────────────────────────────────────────

  describe "G5 — no float in any event or folded book (INV-6)" do
    test "no float in a matched run's events or its folded book" do
      {book, _sid} = rest_maker(OrderBook.new(), :sell, {100, 250_000_000}, 10, "acct-S")

      {:place, buy} =
        place(%{account: "acct-B", direction: :buy, quantity: 15, price: {101, 750_000_000}})

      events = Decider.decide({:place, buy}, book)
      assert no_float?(events)
      assert no_float?(fold(events, book))
    end

    property "no float survives any generated crossing run (structural)" do
      check all(
              maker_price <- StreamData.integer(90..100),
              maker_qty <- StreamData.integer(1..50),
              taker_qty <- StreamData.integer(1..50),
              taker_price <- StreamData.integer(95..110)
            ) do
        {book, _sid} = rest_maker(OrderBook.new(), :sell, {maker_price, 0}, maker_qty, "acct-S")

        {:place, buy} =
          place(%{
            account: "acct-B",
            direction: :buy,
            quantity: taker_qty,
            price: {taker_price, 0}
          })

        events = Decider.decide({:place, buy}, book)
        assert no_float?(events)
        assert no_float?(fold(events, book))
      end
    end
  end

  # ── G6 — self-trade prevented ────────────────────────────────────────────────

  describe "G6 — self-trade prevented (INV-6, D-2)" do
    test "two same-account crossing orders do not self-fill; the aggressor is rejected, book unchanged" do
      # A resting sell from acct Z; a crossing buy from acct Z.
      {book, _sell_id} = rest_maker(OrderBook.new(), :sell, {100, 0}, 10, "acct-Z")
      {:place, buy} = place(%{account: "acct-Z", direction: :buy, quantity: 10, price: {101, 0}})

      events = Decider.decide({:place, buy}, book)

      # Exactly one :rejected :self_trade naming the taker; NO :fill, NO :rested.
      assert events == [{:rejected, %{order: buy.id, reason: :self_trade}}]

      # The book is unchanged (the fold of the emitted events leaves the input).
      assert fold(events, book) == book
    end

    test "a self-cross is all-or-nothing even with another maker ahead of it" do
      # A sell from acct-OTHER ahead (better price), then a sell from acct-Z. A buy
      # from acct-Z that crosses BOTH must reject in full — no partial fill against
      # acct-OTHER ahead of the self-cross (D-2 all-or-nothing).
      {b1, _other} = rest_maker(OrderBook.new(), :sell, {100, 0}, 5, "acct-OTHER")
      {b2, _zid} = rest_maker(b1, :sell, {101, 0}, 5, "acct-Z")
      {:place, buy} = place(%{account: "acct-Z", direction: :buy, quantity: 10, price: {101, 0}})

      events = Decider.decide({:place, buy}, b2)
      assert events == [{:rejected, %{order: buy.id, reason: :self_trade}}]
      assert fold(events, b2) == b2
    end

    property "a same-account aggressor never produces a :fill (book unchanged)" do
      check all(
              maker_price <- StreamData.integer(90..100),
              maker_qty <- StreamData.integer(1..30),
              taker_qty <- StreamData.integer(1..30)
            ) do
        {book, _sid} = rest_maker(OrderBook.new(), :sell, {maker_price, 0}, maker_qty, "acct-Z")
        # The crossing buy shares the maker's account.
        {:place, buy} =
          place(%{account: "acct-Z", direction: :buy, quantity: taker_qty, price: {105, 0}})

        events = Decider.decide({:place, buy}, book)
        refute Enum.any?(events, &match?({:fill, _}, &1))
        assert events == [{:rejected, %{order: buy.id, reason: :self_trade}}]
        assert fold(events, book) == book
      end
    end
  end

  # ── AS-7 — fill-key freeze ───────────────────────────────────────────────────

  describe "AS-7 — every :fill carries a branded FIL id + integer money" do
    property "every :fill from any crossing run has a valid 14-byte FIL id and integer {units, nano}" do
      check all(
              maker_price <- StreamData.integer(90..100),
              maker_qty <- StreamData.integer(1..50),
              taker_qty <- StreamData.integer(1..50)
            ) do
        {book, _sid} = rest_maker(OrderBook.new(), :sell, {maker_price, 0}, maker_qty, "acct-S")

        {:place, buy} =
          place(%{account: "acct-B", direction: :buy, quantity: taker_qty, price: {105, 0}})

        for {:fill, f} <- Decider.decide({:place, buy}, book) do
          assert byte_size(f.id) == 14
          assert BrandedId.valid?(f.id)
          assert BrandedId.namespace(f.id) == "FIL"
          assert {u, n} = f.price
          assert is_integer(u) and is_integer(n)
          assert is_integer(f.quantity) and f.quantity > 0
        end
      end
    end

    test "no :fill is emitted without an id" do
      {book, _sid} = rest_maker(OrderBook.new(), :sell, {100, 0}, 10, "acct-S")
      {:place, buy} = place(%{account: "acct-B", direction: :buy, quantity: 10, price: {100, 0}})

      for {:fill, f} <- Decider.decide({:place, buy}, book) do
        assert Map.has_key?(f, :id)
        assert is_binary(f.id)
      end
    end
  end

  # ── decide is total over :place ──────────────────────────────────────────────

  describe "decide/2 is total over :place (non-empty, tagged events)" do
    property "every place yields a non-empty list of tagged events, never a crash" do
      book_with_makers =
        Enum.reduce(
          [{:sell, {100, 0}, 10}, {:sell, {101, 0}, 5}, {:buy, {98, 0}, 7}],
          OrderBook.new(),
          fn
            {side, price, qty}, b -> elem(rest_maker(b, side, price, qty, "acct-MKT"), 0)
          end
        )

      check all(
              direction <- StreamData.member_of([:buy, :sell]),
              type <- StreamData.member_of([:limit, :market]),
              quantity <- StreamData.integer(1..40),
              units <- StreamData.integer(90..110),
              account <- StreamData.member_of(["acct-B", "acct-MKT"])
            ) do
        price = if type == :market, do: :market, else: {units, 0}

        cmd =
          place(%{
            direction: direction,
            type: type,
            quantity: quantity,
            price: price,
            account: account
          })

        events = Decider.decide(cmd, book_with_makers)
        assert is_list(events) and events != []

        assert Enum.all?(events, fn
                 {:fill, m} when is_map(m) -> true
                 {:rested, m} when is_map(m) -> true
                 {:rejected, %{reason: reason}} -> reason in [:self_trade, :no_liquidity]
                 _ -> false
               end)

        assert no_float?(events)
        assert no_float?(fold(events, book_with_makers))
      end
    end
  end

  # ── AS-2 — the forbidden-effect set is empty in decider.ex (source grep) ─────

  describe "AS-2 — decider.ex holds no forbidden effect (pure-grep, INV-3, D-5)" do
    test "the source, comments stripped, contains none of the forbidden set" do
      # The grep is over CODE, not prose: strip line comments first so the
      # moduledoc's own listing of what it forbids cannot trip a substring match
      # (the trd_1_1_check.exs:250 strip_comments idiom). The FIL mint
      # (next_branded) is the sole sanctioned effect.
      path = Path.expand("../../lib/exchange/decider.ex", __DIR__)
      assert File.exists?(path)

      code =
        path
        |> File.read!()
        |> String.split("\n")
        |> Enum.map_join("\n", &Regex.replace(~r/#.*/, &1, ""))

      forbidden = ["GenServer", ":ets", "System.monotonic_time", "System.os_time", "Process."]

      for token <- forbidden do
        refute String.contains?(code, token),
               "decider.ex (comments stripped) must not contain #{inspect(token)} (AS-2)"
      end

      # The sole sanctioned effect IS present.
      assert String.contains?(code, "next_branded")
    end
  end
end
