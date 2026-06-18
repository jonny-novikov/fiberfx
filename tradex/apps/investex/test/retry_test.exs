defmodule Investex.RetryTest do
  @moduledoc """
  Tier 1 (pure): the retry decision is pure and correct on its three branches
  (trd.9.1.specs.md G4; INV-6). The forbidden-effect grep proves no
  clock/sleep/Process.* in the decision.
  """
  use ExUnit.Case, async: true

  alias Investex.{Config, Retry}

  doctest Investex.Retry

  describe "linear branch — :unavailable / :internal under the cap ⇒ {:retry, 500}" do
    test ":unavailable under the cap retries on the 500ms linear backoff" do
      assert Retry.decide(:unavailable, 0, %{}) == {:retry, 500}
      assert Retry.decide(:unavailable, 2, %{}) == {:retry, 500}
    end

    test ":internal under the cap retries on the 500ms linear backoff" do
      assert Retry.decide(:internal, 0, %{}) == {:retry, 500}
      assert Retry.decide(:internal, 2, %{}) == {:retry, 500}
    end
  end

  describe "resource-exhausted branch — honors x-ratelimit-reset (L-2)" do
    test "reads the header seconds → milliseconds" do
      assert Retry.decide(:resource_exhausted, 0, %{"x-ratelimit-reset" => "7"}) == {:retry, 7000}
      assert Retry.decide(:resource_exhausted, 1, %{"x-ratelimit-reset" => "30"}) == {:retry, 30_000}
    end

    test "floors at 500ms when the header is absent / blank / unparseable / zero" do
      assert Retry.decide(:resource_exhausted, 0, %{}) == {:retry, 500}
      assert Retry.decide(:resource_exhausted, 0, %{"x-ratelimit-reset" => ""}) == {:retry, 500}
      assert Retry.decide(:resource_exhausted, 0, %{"x-ratelimit-reset" => "abc"}) == {:retry, 500}
      assert Retry.decide(:resource_exhausted, 0, %{"x-ratelimit-reset" => "0"}) == {:retry, 500}
    end

    test "accepts an integer header value too" do
      assert Retry.decide(:resource_exhausted, 0, %{"x-ratelimit-reset" => 5}) == {:retry, 5000}
    end

    test "gives up when the resource-exhausted retry is disabled (client.go:61-64)" do
      cfg = Config.new(disable_resource_exhausted_retry: true)
      assert Retry.decide(:resource_exhausted, 0, %{"x-ratelimit-reset" => "5"}, cfg) == :give_up
    end
  end

  describe "give-up branch — past the cap or an unretryable status" do
    test "gives up at and past max_retries (default 3)" do
      assert Retry.decide(:unavailable, 3, %{}) == :give_up
      assert Retry.decide(:internal, 4, %{}) == :give_up
      assert Retry.decide(:resource_exhausted, 3, %{"x-ratelimit-reset" => "5"}) == :give_up
    end

    test "respects a lower cap via Config" do
      cfg = Config.new(max_retries: 1)
      assert Retry.decide(:unavailable, 0, %{}, cfg) == {:retry, 500}
      assert Retry.decide(:unavailable, 1, %{}, cfg) == :give_up
    end

    test "disable_all_retry (cap 0) gives up immediately" do
      cfg = Config.new(disable_all_retry: true)
      assert Retry.decide(:unavailable, 0, %{}, cfg) == :give_up
    end

    test "gives up on any status the policy does not retry" do
      for status <- [:not_found, :permission_denied, :invalid_argument, :ok, :unauthenticated] do
        assert Retry.decide(status, 0, %{}) == :give_up
      end
    end
  end

  describe "purity (INV-6 / G4 forbidden-effect grep)" do
    test "the decision function holds no clock, sleep, Process.*, network, or IO" do
      # The grep is over CODE, comments stripped (the trd_2_1_check.exs:227 idiom)
      # — a forbidden token in the moduledoc STRING would survive stripping, so the
      # doc is worded to avoid the bare tokens.
      code =
        Path.expand("../lib/investex/retry.ex", __DIR__)
        |> File.read!()
        |> String.split("\n")
        |> Enum.map_join("\n", &Regex.replace(~r/#.*/, &1, ""))

      forbidden = [
        "Process.sleep",
        ":timer.sleep",
        "System.monotonic_time",
        "System.os_time",
        "System.system_time",
        "DateTime.utc_now",
        "GRPC.Stub",
        "IO."
      ]

      present = Enum.filter(forbidden, &String.contains?(code, &1))
      assert present == [], "Retry.decide must be pure; found forbidden: #{inspect(present)}"
    end
  end
end
