defmodule Exchange.GatewayTest do
  @moduledoc """
  Acceptance suite for rung TRD.1.1 (`docs/exchange/trd.1.1.specs.md`):
  G1–G5 + cancel + the StreamData totality property. The Gateway is pure and
  touches no Valkey; the only runtime prerequisite is the branded-id minter
  (`Exchange.Id.Snowflake.start/1`, INV-3), booted once below.
  """
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Exchange.Gateway

  # INV-3 minting prerequisite. start/1 is idempotent (:persistent_term-guarded,
  # lib/exchange/id/snowflake.ex), so a fixed node id is
  # safe to call on every suite run.
  setup_all do
    :ok = Exchange.Id.Snowflake.start(7)
    :ok
  end

  # A canonical well-formed limit buy. Helpers below derive the malformed cases
  # from it by overwriting one field, so each error is reachable in isolation.
  defp limit_buy(overrides \\ %{}) do
    Map.merge(
      %{
        instrument: "BBG004730N88",
        account: "acct-2000",
        direction: :buy,
        type: :limit,
        quantity: 10,
        price: {145, 250_000_000}
      },
      overrides
    )
  end

  defp cancel_order(overrides \\ %{}) do
    Map.merge(
      %{instrument: "BBG004730N88", order_ref: "venue-ref-991"},
      overrides
    )
  end

  # Structural float-scan over a parsed command term: no number anywhere in the
  # output may be a float (INV-2 / G3). Walks the tagged tuple, the map, and the
  # money pair.
  defp no_float?(term)
  defp no_float?(f) when is_float(f), do: false
  defp no_float?({a, b}), do: no_float?(a) and no_float?(b)
  defp no_float?(%{} = m), do: Enum.all?(m, fn {k, v} -> no_float?(k) and no_float?(v) end)
  defp no_float?(list) when is_list(list), do: Enum.all?(list, &no_float?/1)
  defp no_float?(_), do: true

  describe "G1 — valid place parses and mints (INV-1, INV-2, INV-3)" do
    test "a well-formed limit buy yields a branded id and a {units, nano} price" do
      assert {:ok, {:place, m}} = Gateway.parse_place(limit_buy())

      # Branded id: ORD namespace, 14 bytes, valid? true.
      assert byte_size(m.id) == 14
      assert Exchange.Id.BrandedId.valid?(m.id)
      assert Exchange.Id.BrandedId.namespace(m.id) == "ORD"

      # Price is a {units, nano} integer pair — never a float.
      assert {units, nano} = m.price
      assert is_integer(units) and is_integer(nano)
      assert {units, nano} == {145, 250_000_000}

      assert m.direction == :buy
      assert m.type == :limit
      assert m.quantity == 10
    end

    test "the same input twice yields two distinct ids (mint order)" do
      assert {:ok, {:place, a}} = Gateway.parse_place(limit_buy())
      assert {:ok, {:place, b}} = Gateway.parse_place(limit_buy())
      assert a.id != b.id
    end

    test "a units-only decimal string parses to {units, 0}" do
      assert {:ok, {:place, m}} = Gateway.parse_place(limit_buy(%{price: "145"}))
      assert m.price == {145, 0}
    end

    test "a \"units.nano\" string parses to the integer pair" do
      assert {:ok, {:place, m}} = Gateway.parse_place(limit_buy(%{price: "145.25"}))
      assert m.price == {145, 250_000_000}
    end
  end

  describe "G2 — each error is reachable and exact (INV-1)" do
    test "the six malformed inputs yield the six error atoms, one each" do
      assert Gateway.parse_place(limit_buy(%{instrument: ""})) == {:error, :unknown_instrument}
      assert Gateway.parse_place(limit_buy(%{direction: :hodl})) == {:error, :bad_direction}
      assert Gateway.parse_place(limit_buy(%{type: :bestprice})) == {:error, :bad_order_type}
      assert Gateway.parse_place(limit_buy(%{quantity: 0})) == {:error, :nonpositive_quantity}
      assert Gateway.parse_place(limit_buy(%{price: 1.45})) == {:error, :bad_price}
      assert Gateway.parse_place("not a map") == {:error, :malformed}
    end

    test "a non-map input never crashes — it is :malformed" do
      for bad <- [nil, 42, :atom, "str", [1, 2], {:place, %{}}] do
        assert Gateway.parse_place(bad) == {:error, :malformed}
        assert Gateway.parse_cancel(bad) == {:error, :malformed}
      end
    end

    test "a missing account folds into :malformed (no dedicated atom, INV-4)" do
      assert Gateway.parse_place(Map.delete(limit_buy(), :account)) == {:error, :malformed}
    end
  end

  describe "G3 — no float survives (INV-2)" do
    test "a float-bearing price is :bad_price" do
      assert Gateway.parse_place(limit_buy(%{price: 1.45})) == {:error, :bad_price}
      assert Gateway.parse_place(limit_buy(%{price: {145, 2.5}})) == {:error, :bad_price}
      assert Gateway.parse_place(limit_buy(%{price: {1.45, 0}})) == {:error, :bad_price}
    end

    test "a float-shaped string with an extra dot is :bad_price" do
      assert Gateway.parse_money("1.4.5") == {:error, :bad_price}
      assert Gateway.parse_money("1.5e3") == {:error, :bad_price}
    end

    test "no float appears anywhere in an accepted command term" do
      assert {:ok, command} = Gateway.parse_place(limit_buy())
      assert no_float?(command)

      assert {:ok, mkt} = Gateway.parse_place(limit_buy(%{type: :market}))
      assert no_float?(mkt)
    end
  end

  describe "G4 — market order ignores price (INV-1)" do
    test "a market order parses with price: :market regardless of any price field" do
      # A price field present and parseable — still ignored.
      assert {:ok, {:place, m}} = Gateway.parse_place(limit_buy(%{type: :market}))
      assert m.price == :market

      # A price field that would be :bad_price for a limit — still ignored.
      assert {:ok, {:place, m2}} =
               Gateway.parse_place(limit_buy(%{type: :market, price: 1.45}))

      assert m2.price == :market

      # No price field at all.
      assert {:ok, {:place, m3}} =
               Gateway.parse_place(Map.delete(limit_buy(%{type: :market}), :price))

      assert m3.price == :market
    end
  end

  describe "G5 — opaque ids carried verbatim (INV-4)" do
    test "instrument and account appear in the command unchanged and unbranded" do
      raw = limit_buy(%{instrument: "BBG-WEIRD-123", account: "acct-XYZ"})
      assert {:ok, {:place, m}} = Gateway.parse_place(raw)
      assert m.instrument == "BBG-WEIRD-123"
      assert m.account == "acct-XYZ"

      # They are opaque strings, not branded ids — parse/1 rejects them.
      assert Exchange.Id.BrandedId.parse(m.instrument) == :error
      assert Exchange.Id.BrandedId.parse(m.account) == :error
    end
  end

  describe "cancel — parse_cancel/1 parses (INV-1, INV-3, INV-4)" do
    test "a well-formed cancel yields a branded id and verbatim order_ref + instrument" do
      assert {:ok, {:cancel, m}} = Gateway.parse_cancel(cancel_order())
      assert byte_size(m.id) == 14
      assert Exchange.Id.BrandedId.valid?(m.id)
      assert Exchange.Id.BrandedId.namespace(m.id) == "CMD"
      assert m.instrument == "BBG004730N88"
      assert m.order_ref == "venue-ref-991"
    end

    test "a cancel missing its order_ref is :malformed; missing instrument is :unknown_instrument" do
      assert Gateway.parse_cancel(Map.delete(cancel_order(), :order_ref)) == {:error, :malformed}

      assert Gateway.parse_cancel(cancel_order(%{instrument: ""})) ==
               {:error, :unknown_instrument}
    end

    test "two cancels of the same input yield two distinct ids" do
      assert {:ok, {:cancel, a}} = Gateway.parse_cancel(cancel_order())
      assert {:ok, {:cancel, b}} = Gateway.parse_cancel(cancel_order())
      assert a.id != b.id
    end
  end

  describe "AS-3 — a rejection mints nothing" do
    test "a rejected place returns a bare error, no command, no id" do
      # An error result is a 2-tuple {:error, atom} — it carries no map and thus
      # no minted id. (The mint call lives strictly inside the {:ok, …} branch.)
      assert {:error, atom} = Gateway.parse_place(limit_buy(%{direction: :hodl}))
      assert is_atom(atom)
    end
  end

  # ── The totality property (StreamData) — INV-1, INV-2, INV-5 ────────────────

  @error_set [
    :unknown_instrument,
    :bad_direction,
    :bad_order_type,
    :nonpositive_quantity,
    :bad_price,
    :malformed
  ]

  # A generator that mixes well-formed and malformed field values, wrong types,
  # and missing keys — so the property exercises both the {:ok, …} and every
  # {:error, …} path, and crash-shaped inputs (floats, atoms, lists where a
  # string is expected).
  defp field_value(well_formed, junk) do
    StreamData.one_of([
      StreamData.member_of(well_formed),
      StreamData.member_of(junk),
      StreamData.integer(),
      StreamData.float(),
      StreamData.binary(),
      StreamData.boolean(),
      StreamData.constant(nil)
    ])
  end

  defp place_input do
    StreamData.fixed_map(%{
      instrument: field_value(["BBG004730N88", "BBG000B9XRY4"], ["", nil]),
      account: field_value(["acct-1", "acct-2"], ["", nil]),
      direction: field_value([:buy, :sell, "buy", "ORDER_DIRECTION_SELL"], [:hodl, "BUY"]),
      type: field_value([:limit, :market, "limit", "ORDER_TYPE_MARKET"], [:bestprice, "x"]),
      quantity: field_value([1, 10, 999], [0, -5]),
      price:
        field_value(
          [{145, 0}, {145, 250_000_000}, "10", "10.5", {-2, 0}],
          [1.45, "1.4.5", "abc", "1.5e3"]
        )
    })
    # Drop a random subset of keys so missing-key inputs are exercised too.
    |> StreamData.bind(fn map ->
      StreamData.bind(
        StreamData.list_of(StreamData.member_of(Map.keys(map)), max_length: 3),
        fn drop -> StreamData.constant(Map.drop(map, drop)) end
      )
    end)
  end

  defp cancel_input do
    StreamData.fixed_map(%{
      instrument: field_value(["BBG004730N88"], ["", nil]),
      order_ref: field_value(["venue-ref-1", "venue-ref-2"], ["", nil])
    })
    |> StreamData.bind(fn map ->
      StreamData.bind(
        StreamData.list_of(StreamData.member_of(Map.keys(map)), max_length: 2),
        fn drop -> StreamData.constant(Map.drop(map, drop)) end
      )
    end)
  end

  # Asserts a single Gateway result is total: {:ok, command} (no float, the
  # expected tag) or {:error, atom-in-the-closed-set}. Never a crash, never a
  # partial command.
  defp assert_total(result, expected_tag) do
    case result do
      {:ok, {^expected_tag, m}} ->
        assert is_map(m)
        assert is_binary(m.id) and byte_size(m.id) == 14
        assert no_float?({expected_tag, m})

      {:error, atom} ->
        assert atom in @error_set

      other ->
        flunk("non-total Gateway output: #{inspect(other)}")
    end
  end

  property "parse_place/1 is total over generated input (INV-1, INV-2, INV-5)" do
    check all(raw <- place_input()) do
      assert_total(Gateway.parse_place(raw), :place)
    end
  end

  property "parse_cancel/1 is total over generated input (INV-1, INV-2, INV-5)" do
    check all(raw <- cancel_input()) do
      assert_total(Gateway.parse_cancel(raw), :cancel)
    end
  end

  property "any non-map input is :malformed, never a crash (INV-1)" do
    check all(
            not_a_map <-
              StreamData.one_of([
                StreamData.integer(),
                StreamData.binary(),
                StreamData.boolean(),
                StreamData.list_of(StreamData.integer()),
                StreamData.constant(nil)
              ])
          ) do
      assert Gateway.parse_place(not_a_map) == {:error, :malformed}
      assert Gateway.parse_cancel(not_a_map) == {:error, :malformed}
    end
  end
end
