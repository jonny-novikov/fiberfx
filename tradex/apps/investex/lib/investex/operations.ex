defmodule Investex.Operations do
  @moduledoc """
  OperationsService — the 7 unary operations/portfolio read RPCs (rung TRD.9.2,
  `docs/exchange/trd.9.2.specs.md` §"The 41-function surface";
  operations.pb.ex:1040-1074). The 2 `OperationsStreamService` RPCs
  (operations.pb.ex:1082) are streams — deferred to 9.5.

  Each function is a **1:1 pass-through** mirroring `Investex.Users` (RQ-1/D-1):
  it takes a pre-built typed `%Proto.<Request>{}` and forwards it to
  `Investex.Caller.unary(client, &OperationsService.Stub.<fun>/3, request)`,
  returning `{:ok, %Proto.<Response>{}} | {:error, Investex.Error.t()}`.
  Stateless given a client handle (INV-5); no exception escapes.

  `get_portfolio` is **money-dense** — `PortfolioResponse` carries the money
  shapes the `Investex.Money` codec decodes (INV-3, exercised this rung):
  `total_amount_*` are `MoneyValue` (decode via `Investex.Money.from_money_value/1`),
  while `expected_yield` and each `PortfolioPosition.quantity` are `Quotation`
  (decode via `Investex.Money.from_quotation/1`). The caller decodes the fields it
  needs; this layer returns the raw `%Proto.<Response>{}` (the established 9.1
  contract).

  These are the **non-sandbox** operations reads; the `Sandbox.*` mirrors of the
  portfolio/positions/operations reads are 9.4.
  """

  alias Investex.Caller
  alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto
  alias Tinkoff.Public.Invest.Api.Contract.V1.OperationsService.Stub

  @doc "GetOperations — the account's operations over a range (operations.pb.ex:1047)."
  @spec get_operations(Investex.Client.t(), Proto.OperationsRequest.t()) ::
          {:ok, Proto.OperationsResponse.t()} | {:error, Investex.Error.t()}
  def get_operations(client, %Proto.OperationsRequest{} = request) do
    Caller.unary(client, &Stub.get_operations/3, request)
  end

  @doc """
  GetPortfolio — the account's current portfolio (operations.pb.ex:1051).

  Money-dense: `PortfolioResponse.total_amount_*` are `MoneyValue` (decode via
  `Investex.Money.from_money_value/1`); `expected_yield` and each
  `PortfolioPosition.quantity` are `Quotation` (decode via
  `Investex.Money.from_quotation/1`).
  """
  @spec get_portfolio(Investex.Client.t(), Proto.PortfolioRequest.t()) ::
          {:ok, Proto.PortfolioResponse.t()} | {:error, Investex.Error.t()}
  def get_portfolio(client, %Proto.PortfolioRequest{} = request) do
    Caller.unary(client, &Stub.get_portfolio/3, request)
  end

  @doc "GetPositions — the account's open positions (operations.pb.ex:1055)."
  @spec get_positions(Investex.Client.t(), Proto.PositionsRequest.t()) ::
          {:ok, Proto.PositionsResponse.t()} | {:error, Investex.Error.t()}
  def get_positions(client, %Proto.PositionsRequest{} = request) do
    Caller.unary(client, &Stub.get_positions/3, request)
  end

  @doc "GetWithdrawLimits — the account's withdraw limits (operations.pb.ex:1059)."
  @spec get_withdraw_limits(Investex.Client.t(), Proto.WithdrawLimitsRequest.t()) ::
          {:ok, Proto.WithdrawLimitsResponse.t()} | {:error, Investex.Error.t()}
  def get_withdraw_limits(client, %Proto.WithdrawLimitsRequest{} = request) do
    Caller.unary(client, &Stub.get_withdraw_limits/3, request)
  end

  @doc "GetBrokerReport — the broker report for an account over a range (operations.pb.ex:1063)."
  @spec get_broker_report(Investex.Client.t(), Proto.BrokerReportRequest.t()) ::
          {:ok, Proto.BrokerReportResponse.t()} | {:error, Investex.Error.t()}
  def get_broker_report(client, %Proto.BrokerReportRequest{} = request) do
    Caller.unary(client, &Stub.get_broker_report/3, request)
  end

  @doc "GetDividendsForeignIssuer — the foreign-issuer dividends report (operations.pb.ex:1067)."
  @spec get_dividends_foreign_issuer(
          Investex.Client.t(),
          Proto.GetDividendsForeignIssuerRequest.t()
        ) ::
          {:ok, Proto.GetDividendsForeignIssuerResponse.t()} | {:error, Investex.Error.t()}
  def get_dividends_foreign_issuer(
        client,
        %Proto.GetDividendsForeignIssuerRequest{} = request
      ) do
    Caller.unary(client, &Stub.get_dividends_foreign_issuer/3, request)
  end

  @doc "GetOperationsByCursor — the account's operations paged by cursor (operations.pb.ex:1071)."
  @spec get_operations_by_cursor(
          Investex.Client.t(),
          Proto.GetOperationsByCursorRequest.t()
        ) ::
          {:ok, Proto.GetOperationsByCursorResponse.t()} | {:error, Investex.Error.t()}
  def get_operations_by_cursor(client, %Proto.GetOperationsByCursorRequest{} = request) do
    Caller.unary(client, &Stub.get_operations_by_cursor/3, request)
  end
end
