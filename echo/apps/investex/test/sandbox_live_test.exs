defmodule Investex.SandboxLiveTest do
  @moduledoc """
  Tier 2 (the live sandbox suite) — the Operator's HARD ship gate (G6; 9.1 scope
  for the open/close smoke, **9.2 scope for the read representative subset**;
  trd.9.1.specs.md + trd.9.2.specs.md INV-8). The `@moduletag :sandbox` + the
  default `exclude: [:sandbox]` (test_helper.exs) mean this module runs ONLY when
  the caller opts in with `mix test --include sandbox`. INV-8's keyless-CI case is
  preserved: a default `mix test` never reaches here.

  Once `--include sandbox` is given, the caller HAS opted into the live gate, so
  this is a TRUE hard gate (L-9 / FIX-2): a **missing token FAILS loudly** (you
  asked for the live tier but supplied no token), never a silent no-op-PASS; and
  each test asserts it ACTUALLY DIALED (a positive `dialed?` proof + real
  responses), so a self-skip can never satisfy the gate's letter while defeating
  its intent. The earlier keyless `:ok` early-return is exactly what let the L-9
  env-clobber hide as green.

  The 9.1 smoke is the venue-client proof: `open_account → get_accounts →
  close_account` (client.go:90-111; sandbox.proto:20-26). The **9.2 read
  representative subset** (RQ-3/D-3, D-10) extends it through the read services:
  `open → Instruments.shares (returns data) → MarketData.get_last_prices +
  Money.from_quotation(LastPrice.price) → Operations.get_portfolio +
  Money.from_money_value(a total_amount_* MoneyValue) → close`. Play-money sandbox
  only; no order is placed (that is 9.3's G6 lifecycle).

  The hard floor (INV-8): the subset MUST prove (a) ≥1 Instruments read dialed and
  returned data AND (b) ≥1 Money decode from a real money-dense response (the
  last-prices Quotation OR the portfolio MoneyValue — whichever the sandbox
  serves). A money-dense read the sandbox does not serve is a **named, loud SKIP**
  (never a silent pass); if **neither** money-dense read is served (Money never
  exercised live), the test FAILS LOUD with a BLOCK message (the Director/Apollo
  escalate via AskUserQuestion) — never a hollow green.

  Secret hygiene (INV-9, hard): the token is read from the env only, never
  asserted-on, printed, or written. The account id / instrument uid obtained are
  asserted to be non-empty binaries — their VALUES are not logged.
  """
  use ExUnit.Case, async: false

  alias Investex.{Client, Instruments, MarketData, Money, Operations, Sandbox}
  alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto

  @moduletag :sandbox

  # The token must be present once `--include sandbox` is given (the caller opted
  # in). A missing token FAILS the setup loudly — the live gate did NOT run is
  # surfaced as a failure, not hidden as green (L-9 / FIX-2). The token VALUE is
  # NOT placed in the context. A real, dialing client is provided to each test;
  # it is stopped on exit.
  setup do
    token = System.get_env("INVEST_TOKEN")

    unless is_binary(token) and token != "" do
      flunk(
        "INVEST_TOKEN is not set, but the live sandbox tier was requested " <>
          "(--include sandbox). The Operator hard gate (G6) cannot run without a " <>
          "token. Source it into the env (never into a file) and re-run."
      )
    end

    {:ok, client} = Client.start_link([])
    on_exit(fn -> if Process.alive?(client), do: Client.stop(client) end)
    {:ok, client: client}
  end

  test "the sandbox vertical: open → get_accounts → close against the real endpoint (G6)", ctx do
    # open: a fresh sandbox account; the response carries its account_id. A real
    # non-empty id proves the dial happened (a no-op could not produce one).
    assert {:ok, %Proto.OpenSandboxAccountResponse{account_id: account_id}} =
             Sandbox.open_account(ctx.client)

    assert is_binary(account_id) and byte_size(account_id) > 0,
           "dialed?=false — open_account returned no account id; the live gate did not actually run"

    # get_accounts: the opened account is among the sandbox accounts.
    assert {:ok, %Proto.GetAccountsResponse{accounts: accounts}} =
             Sandbox.get_accounts(ctx.client)

    assert Enum.any?(accounts, fn %Proto.Account{id: id} -> id == account_id end)

    # close: dispose of the account; an empty response on success.
    assert {:ok, %Proto.CloseSandboxAccountResponse{}} =
             Sandbox.close_account(ctx.client, account_id)
  end

  test "get_accounts is the canonical liveness smoke (a no-arg read over the live channel)",
       ctx do
    # A real GetAccountsResponse over the live channel — the lightest dial proof.
    assert {:ok, %Proto.GetAccountsResponse{accounts: accounts}} =
             Sandbox.get_accounts(ctx.client)

    # The accounts field is a list (possibly empty) — the response was decoded
    # from the wire, proving the round-trip dialed (dialed?=true).
    assert is_list(accounts),
           "dialed?=false — get_accounts returned no decoded response; the live gate did not run"
  end

  test "the read representative subset: open → Instruments → Money(last-prices) → Money(portfolio) → close (G6, 9.2)",
       ctx do
    client = ctx.client

    # --- open: a fresh sandbox account (the 9.1 bootstrap, reused) -------------
    assert {:ok, %Proto.OpenSandboxAccountResponse{account_id: account_id}} =
             Sandbox.open_account(client)

    assert is_binary(account_id) and byte_size(account_id) > 0,
           "dialed?=false — open_account returned no account id; the live gate did not run"

    # The account is closed even if a read assertion below fails (no orphaned
    # play-money account; the close is itself a fourth dialed read).
    on_exit(fn ->
      if Process.alive?(client), do: Sandbox.close_account(client, account_id)
    end)

    # --- Instruments: a read that returns data (the floor's read half) --------
    # shares/2 with the base instrument list — a populated InstrumentsService read
    # proves an InstrumentsService dial returned data (instruments.pb.ex:1933).
    assert {:ok, %Proto.SharesResponse{instruments: shares}} =
             Instruments.shares(client, %Proto.InstrumentsRequest{
               instrument_status: :INSTRUMENT_STATUS_BASE
             })

    assert is_list(shares) and shares != [],
           "dialed?=false — Instruments.shares returned no instruments; the InstrumentsService read did not dial"

    instruments_dialed? = true

    # An instrument id to price (uid preferred, figi fallback — both on Share).
    %Proto.Share{uid: uid, figi: figi} = hd(shares)
    instrument_id = if is_binary(uid) and uid != "", do: uid, else: figi

    assert is_binary(instrument_id) and instrument_id != "",
           "the first Share carries neither a uid nor a figi — cannot price an instrument"

    # --- MarketData money leg: decode a REAL LastPrice.price Quotation --------
    # get_last_prices/2 for that instrument; LastPrice.price is a Quotation
    # (marketdata.pb.ex). Decode it through Money.from_quotation/1. If the sandbox
    # serves no last price, this leg is a NAMED LOUD SKIP (the portfolio leg can
    # still satisfy the money floor); never a silent pass.
    money_from_last_price? =
      case MarketData.get_last_prices(client, %Proto.GetLastPricesRequest{
             instrument_id: [instrument_id]
           }) do
        {:ok, %Proto.GetLastPricesResponse{last_prices: [%Proto.LastPrice{price: price} | _]}}
        when not is_nil(price) ->
          {units, nano} = Money.from_quotation(price)

          assert is_integer(units) and is_integer(nano),
                 "Money.from_quotation did not yield an integer pair from a real LastPrice.price"

          refute is_float(units) or is_float(nano)
          true

        {:ok, %Proto.GetLastPricesResponse{}} ->
          IO.puts(
            "[live SKIP] get_last_prices: the sandbox served no last price for the instrument " <>
              "(no money decode from this leg); the portfolio leg must satisfy the money floor."
          )

          false
      end

    # --- Operations money leg: decode a REAL total_amount_* MoneyValue --------
    # get_portfolio/2 for the account; total_amount_* are MoneyValue
    # (operations.pb.ex). Decode the first populated one through
    # Money.from_money_value/1. If the sandbox serves no MoneyValue total, a NAMED
    # LOUD SKIP; never a silent pass.
    money_from_portfolio? =
      case Operations.get_portfolio(client, %Proto.PortfolioRequest{account_id: account_id}) do
        {:ok, %Proto.PortfolioResponse{} = portfolio} ->
          totals =
            [
              portfolio.total_amount_shares,
              portfolio.total_amount_bonds,
              portfolio.total_amount_etf,
              portfolio.total_amount_currencies,
              portfolio.total_amount_futures,
              portfolio.total_amount_portfolio
            ]
            |> Enum.filter(&match?(%Proto.MoneyValue{}, &1))

          case totals do
            [%Proto.MoneyValue{} = mv | _] ->
              {{units, nano}, currency} = Money.from_money_value(mv)

              assert is_integer(units) and is_integer(nano),
                     "Money.from_money_value did not yield an integer pair from a real total_amount_*"

              refute is_float(units) or is_float(nano)
              assert is_binary(currency)
              true

            [] ->
              IO.puts(
                "[live SKIP] get_portfolio: the sandbox served no populated total_amount_* MoneyValue " <>
                  "(no money decode from this leg)."
              )

              false
          end
      end

    # --- close: dispose of the account (a fourth dialed read) -----------------
    assert {:ok, %Proto.CloseSandboxAccountResponse{}} = Sandbox.close_account(client, account_id)

    # --- THE HARD FLOOR (INV-8): the gate's teeth -----------------------------
    # (a) ≥1 Instruments read dialed and returned data, AND (b) ≥1 Money decode
    # from a real money-dense response. The money half is the OR of the two legs:
    # a single served money-dense read satisfies it; an unserved one was a loud
    # SKIP above. If NEITHER money leg was served, Money was never exercised live
    # → BLOCK (fail loud; escalate via AskUserQuestion), never a hollow green.
    assert instruments_dialed?,
           "hard floor unmet: no Instruments read dialed and returned data"

    money_decoded? = money_from_last_price? or money_from_portfolio?

    assert money_decoded?,
           "BLOCK — the live representative subset dialed, but NEITHER money-dense read " <>
             "(get_last_prices Quotation nor get_portfolio MoneyValue) was served by the " <>
             "sandbox, so Investex.Money was never exercised against real venue data. The " <>
             "hard floor (≥1 live Money decode) is unmet — 9.2 BLOCKS. Escalate to the " <>
             "Operator (AskUserQuestion): re-run when the sandbox serves a money-dense read, " <>
             "or rule on shipping without a live Money exercise."
  end
end
