defmodule Codemojex.RailsTest do
  @moduledoc """
  The frozen per-rail facts + the boot vector (cm.7, cm-7 D-6 F1/F5). Pure — no DB, no
  Valkey, runs in the default suite. The boot vector (self_check!/0) is the guard that a
  mis-scaling money constant fails fast, not at the first booked order.
  """
  use ExUnit.Case, async: true

  alias Codemojex.Rails

  test "the closed rail set is the four pay-in rails" do
    assert Rails.rails() == ~w(stars ton usdt rub)
  end

  test "each rail's native minor-unit factor + decimals are the frozen money facts" do
    assert Rails.factor("stars") == 1 and Rails.decimals("stars") == 0
    assert Rails.factor("ton") == 1_000_000_000 and Rails.decimals("ton") == 9
    assert Rails.factor("usdt") == 1_000_000 and Rails.decimals("usdt") == 6
    assert Rails.factor("rub") == 100 and Rails.decimals("rub") == 2
  end

  test "the minor-unit name is exposed per rail" do
    assert Rails.minor("ton") == :nano_ton
    assert Rails.minor("rub") == :kopeck
  end

  test "known?/1 admits only the four rails" do
    assert Rails.known?("ton")
    refute Rails.known?("btc")
    refute Rails.known?("")
  end

  test "self_check!/0 asserts factor == 10**decimals for every rail (the boot vector)" do
    assert Rails.self_check!() == :ok
  end

  test "an unknown rail raises rather than silently returning a wrong factor" do
    assert_raise ArgumentError, fn -> Rails.factor("btc") end
    assert_raise ArgumentError, fn -> Rails.decimals("btc") end
  end
end
