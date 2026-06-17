defmodule Investex.ConfigTest do
  @moduledoc """
  Tier 1 (pure, network-free): `Investex.Config` defaults, the env-only token
  read (INV-9), and the env-resolved endpoint + precedence (INV-10)
  (trd.9.1.1.specs.md §Surface). No token VALUE appears in this file.

  `async: false` is MANDATORY (L-9): the `resolve/1` tests mutate the GLOBAL OS
  environment (`INVEST_TOKEN`, and now `INVEST_API_URL` / `INVEST_API_PORT`),
  which is process-wide, NOT per-test. Under `async: true` this raced
  `SandboxLiveTest`'s `System.get_env("INVEST_TOKEN")` and clobbered a real token
  mid-suite, silently no-op'ing the G6 live hard gate to false-green. Run
  serially, and every test that touches a variable SAVES the prior value and
  RESTORES it in `on_exit` — so a real token AND a real `INVEST_API_URL` present
  for the live tier SURVIVE this file untouched (INV-10's resolution reads them).
  """
  use ExUnit.Case, async: false

  alias Investex.Config

  doctest Investex.Config

  describe "new/1 defaults (client.go:116-128)" do
    test "applies the Go-SDK defaults; token is nil (never a default, INV-9)" do
      c = Config.new([])
      assert c.endpoint == "sandbox-invest-public-api.tbank.ru:443"
      assert c.app_name == "jonnify.investex"
      assert c.max_retries == 3
      assert c.disable_resource_exhausted_retry == false
      assert c.disable_all_retry == false
      assert c.account_id == nil
      assert c.token == nil
    end

    test "overrides apply over the defaults" do
      c = Config.new(endpoint: "host:443", app_name: "x.y", account_id: "acc-1", max_retries: 5)
      assert c.endpoint == "host:443"
      assert c.app_name == "x.y"
      assert c.account_id == "acc-1"
      assert c.max_retries == 5
    end

    test "disable_all_retry forces max_retries to 0 (client.go:123-124), overriding an explicit cap" do
      assert Config.new(disable_all_retry: true).max_retries == 0
      assert Config.new(disable_all_retry: true, max_retries: 9).max_retries == 0
    end

    test "accepts a map as well as a keyword" do
      assert Config.new(%{max_retries: 2}).max_retries == 2
    end
  end

  describe "resolve/1 (INV-9 — token from the env only)" do
    # SAVE/RESTORE the prior INVEST_TOKEN around every env-mutating test (L-9):
    # a real token present for the live tier MUST survive this file. on_exit
    # restores the captured prior value (or deletes if there was none) — never an
    # unconditional delete that would clobber a real token for the rest of the
    # suite. With `async: false` (above) these run serially, so no concurrent
    # test reads the env mid-mutation.
    setup do
      prior = System.get_env("INVEST_TOKEN")

      on_exit(fn ->
        case prior do
          nil -> System.delete_env("INVEST_TOKEN")
          value -> System.put_env("INVEST_TOKEN", value)
        end
      end)

      :ok
    end

    test "lifts INVEST_TOKEN from the env into :token" do
      # A NON-secret marker value, asserting the env→:token wiring without any
      # real token. The setup above restores the prior value on exit.
      System.put_env("INVEST_TOKEN", "marker-not-a-real-token")

      c = Config.new([]) |> Config.resolve()
      assert c.token == "marker-not-a-real-token"
    end

    test "raises a variable-naming (not value-bearing) error when INVEST_TOKEN is unset" do
      # Temporarily clear it (the setup restores the prior value on exit), so the
      # unset path is exercised without permanently wiping a real token.
      System.delete_env("INVEST_TOKEN")

      err = assert_raise System.EnvError, fn -> Config.resolve(Config.new([])) end
      # The raise names the variable, never a value (INV-9).
      assert Exception.message(err) =~ "INVEST_TOKEN"
    end
  end

  describe "resolve/1 — the endpoint is env-resolved, precedence explicit > env > default (INV-10)" do
    # SAVE/RESTORE all three env vars resolve/1 now reads (L-9): a real token AND
    # a real INVEST_API_URL/PORT present for the live tier MUST survive this file.
    # on_exit restores each captured prior value (or deletes if there was none) —
    # never an unconditional delete. async: false (above) keeps these serial.
    setup do
      vars = ~w(INVEST_TOKEN INVEST_API_URL INVEST_API_PORT)
      prior = Map.new(vars, fn k -> {k, System.get_env(k)} end)

      on_exit(fn ->
        Enum.each(prior, fn
          {k, nil} -> System.delete_env(k)
          {k, v} -> System.put_env(k, v)
        end)
      end)

      # A non-secret marker token so resolve/1 clears the INVEST_TOKEN precondition
      # and reaches endpoint resolution. The setup restores the prior value on exit.
      System.put_env("INVEST_TOKEN", "marker-not-a-real-token")
      :ok
    end

    test "with no env URL set, the endpoint is the tbank.ru default" do
      System.delete_env("INVEST_API_URL")
      System.delete_env("INVEST_API_PORT")

      c = Config.new([]) |> Config.resolve()
      assert c.endpoint == "sandbox-invest-public-api.tbank.ru:443"
    end

    test "INVEST_API_URL + INVEST_API_PORT compose host:port (env > default)" do
      System.put_env("INVEST_API_URL", "sandbox-invest-public-api.tbank.ru")
      System.put_env("INVEST_API_PORT", "443")

      c = Config.new([]) |> Config.resolve()
      assert c.endpoint == "sandbox-invest-public-api.tbank.ru:443"
    end

    test "INVEST_API_URL alone defaults the port to 443" do
      System.put_env("INVEST_API_URL", "custom-host.example")
      System.delete_env("INVEST_API_PORT")

      c = Config.new([]) |> Config.resolve()
      assert c.endpoint == "custom-host.example:443"
    end

    test "an explicit :endpoint opt overrides the env (explicit > env)" do
      System.put_env("INVEST_API_URL", "env-host.example")
      System.put_env("INVEST_API_PORT", "9000")

      c = Config.new(endpoint: "explicit-host:443") |> Config.resolve()
      assert c.endpoint == "explicit-host:443"
    end

    test "an empty INVEST_API_URL falls back to the default (not a bare ':443')" do
      System.put_env("INVEST_API_URL", "")
      System.delete_env("INVEST_API_PORT")

      c = Config.new([]) |> Config.resolve()
      assert c.endpoint == "sandbox-invest-public-api.tbank.ru:443"
    end
  end
end
