defmodule Investex.MarketData do
  @moduledoc """
  MarketDataService — the 7 unary market-data read RPCs (rung TRD.9.2,
  `docs/exchange/trd.9.2.specs.md` §"The 41-function surface";
  marketdata.pb.ex:901-935). The 2 `MarketDataStreamService` RPCs
  (marketdata.pb.ex:943) are streams — deferred to 9.5.

  Each function is a **1:1 pass-through** mirroring `Investex.Users` (RQ-1/D-1):
  it takes a pre-built typed `%Proto.<Request>{}` and forwards it to
  `Investex.Caller.unary(client, &MarketDataService.Stub.<fun>/3, request)`,
  returning `{:ok, %Proto.<Response>{}} | {:error, Investex.Error.t()}`.
  Stateless given a client handle (INV-5); no exception escapes.

  Two responses are **money-dense** — they carry the `Quotation` shapes the
  `Investex.Money` codec decodes (INV-3, exercised this rung): `get_last_prices`
  returns `GetLastPricesResponse.last_prices` (repeated `LastPrice`, each with a
  `price` `Quotation`, marketdata.pb.ex), and `get_order_book` returns
  `GetOrderBookResponse` whose `Order.price` is a `Quotation`. The caller decodes
  those fields via `Investex.Money.from_quotation/1`; this layer returns the raw
  `%Proto.<Response>{}` (the established 9.1 contract — investex forwards, the
  consumer decodes).
  """

  alias Investex.Caller
  alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto
  alias Tinkoff.Public.Invest.Api.Contract.V1.MarketDataService.Stub

  @doc "GetCandles — historical candles for an instrument over a range (marketdata.pb.ex:908)."
  @spec get_candles(Investex.Client.t(), Proto.GetCandlesRequest.t()) ::
          {:ok, Proto.GetCandlesResponse.t()} | {:error, Investex.Error.t()}
  def get_candles(client, %Proto.GetCandlesRequest{} = request) do
    Caller.unary(client, &Stub.get_candles/3, request)
  end

  @doc """
  GetLastPrices — the latest prices for instruments (marketdata.pb.ex:912).

  Money-dense: `GetLastPricesResponse.last_prices` is a repeated `LastPrice`,
  each carrying a `price` `Quotation` — decode via `Investex.Money.from_quotation/1`.
  """
  @spec get_last_prices(Investex.Client.t(), Proto.GetLastPricesRequest.t()) ::
          {:ok, Proto.GetLastPricesResponse.t()} | {:error, Investex.Error.t()}
  def get_last_prices(client, %Proto.GetLastPricesRequest{} = request) do
    Caller.unary(client, &Stub.get_last_prices/3, request)
  end

  @doc """
  GetOrderBook — the order book for an instrument (marketdata.pb.ex:916).

  Money-dense: each `Order.price` in the response is a `Quotation` — decode via
  `Investex.Money.from_quotation/1`.
  """
  @spec get_order_book(Investex.Client.t(), Proto.GetOrderBookRequest.t()) ::
          {:ok, Proto.GetOrderBookResponse.t()} | {:error, Investex.Error.t()}
  def get_order_book(client, %Proto.GetOrderBookRequest{} = request) do
    Caller.unary(client, &Stub.get_order_book/3, request)
  end

  @doc "GetTradingStatus — the trading status for one instrument (marketdata.pb.ex:920)."
  @spec get_trading_status(Investex.Client.t(), Proto.GetTradingStatusRequest.t()) ::
          {:ok, Proto.GetTradingStatusResponse.t()} | {:error, Investex.Error.t()}
  def get_trading_status(client, %Proto.GetTradingStatusRequest{} = request) do
    Caller.unary(client, &Stub.get_trading_status/3, request)
  end

  @doc "GetTradingStatuses — the trading statuses for many instruments (marketdata.pb.ex:924)."
  @spec get_trading_statuses(Investex.Client.t(), Proto.GetTradingStatusesRequest.t()) ::
          {:ok, Proto.GetTradingStatusesResponse.t()} | {:error, Investex.Error.t()}
  def get_trading_statuses(client, %Proto.GetTradingStatusesRequest{} = request) do
    Caller.unary(client, &Stub.get_trading_statuses/3, request)
  end

  @doc "GetLastTrades — the latest trades for an instrument over a range (marketdata.pb.ex:928)."
  @spec get_last_trades(Investex.Client.t(), Proto.GetLastTradesRequest.t()) ::
          {:ok, Proto.GetLastTradesResponse.t()} | {:error, Investex.Error.t()}
  def get_last_trades(client, %Proto.GetLastTradesRequest{} = request) do
    Caller.unary(client, &Stub.get_last_trades/3, request)
  end

  @doc "GetClosePrices — the close prices for instruments (marketdata.pb.ex:932)."
  @spec get_close_prices(Investex.Client.t(), Proto.GetClosePricesRequest.t()) ::
          {:ok, Proto.GetClosePricesResponse.t()} | {:error, Investex.Error.t()}
  def get_close_prices(client, %Proto.GetClosePricesRequest{} = request) do
    Caller.unary(client, &Stub.get_close_prices/3, request)
  end
end
