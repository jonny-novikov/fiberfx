defmodule Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionAction do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.SubscriptionAction",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :SUBSCRIPTION_ACTION_UNSPECIFIED, 0
  field :SUBSCRIPTION_ACTION_SUBSCRIBE, 1
  field :SUBSCRIPTION_ACTION_UNSUBSCRIBE, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionInterval do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.SubscriptionInterval",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :SUBSCRIPTION_INTERVAL_UNSPECIFIED, 0
  field :SUBSCRIPTION_INTERVAL_ONE_MINUTE, 1
  field :SUBSCRIPTION_INTERVAL_FIVE_MINUTES, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionStatus do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.SubscriptionStatus",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :SUBSCRIPTION_STATUS_UNSPECIFIED, 0
  field :SUBSCRIPTION_STATUS_SUCCESS, 1
  field :SUBSCRIPTION_STATUS_INSTRUMENT_NOT_FOUND, 2
  field :SUBSCRIPTION_STATUS_SUBSCRIPTION_ACTION_IS_INVALID, 3
  field :SUBSCRIPTION_STATUS_DEPTH_IS_INVALID, 4
  field :SUBSCRIPTION_STATUS_INTERVAL_IS_INVALID, 5
  field :SUBSCRIPTION_STATUS_LIMIT_IS_EXCEEDED, 6
  field :SUBSCRIPTION_STATUS_INTERNAL_ERROR, 7
  field :SUBSCRIPTION_STATUS_TOO_MANY_REQUESTS, 8
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.TradeDirection do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.TradeDirection",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :TRADE_DIRECTION_UNSPECIFIED, 0
  field :TRADE_DIRECTION_BUY, 1
  field :TRADE_DIRECTION_SELL, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.CandleInterval do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.CandleInterval",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :CANDLE_INTERVAL_UNSPECIFIED, 0
  field :CANDLE_INTERVAL_1_MIN, 1
  field :CANDLE_INTERVAL_5_MIN, 2
  field :CANDLE_INTERVAL_15_MIN, 3
  field :CANDLE_INTERVAL_HOUR, 4
  field :CANDLE_INTERVAL_DAY, 5
  field :CANDLE_INTERVAL_2_MIN, 6
  field :CANDLE_INTERVAL_3_MIN, 7
  field :CANDLE_INTERVAL_10_MIN, 8
  field :CANDLE_INTERVAL_30_MIN, 9
  field :CANDLE_INTERVAL_2_HOUR, 10
  field :CANDLE_INTERVAL_4_HOUR, 11
  field :CANDLE_INTERVAL_WEEK, 12
  field :CANDLE_INTERVAL_MONTH, 13
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.MarketDataRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.MarketDataRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  oneof :payload, 0

  field :subscribe_candles_request, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeCandlesRequest,
    json_name: "subscribeCandlesRequest",
    oneof: 0

  field :subscribe_order_book_request, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeOrderBookRequest,
    json_name: "subscribeOrderBookRequest",
    oneof: 0

  field :subscribe_trades_request, 3,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeTradesRequest,
    json_name: "subscribeTradesRequest",
    oneof: 0

  field :subscribe_info_request, 4,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeInfoRequest,
    json_name: "subscribeInfoRequest",
    oneof: 0

  field :subscribe_last_price_request, 5,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeLastPriceRequest,
    json_name: "subscribeLastPriceRequest",
    oneof: 0

  field :get_my_subscriptions, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.GetMySubscriptions,
    json_name: "getMySubscriptions",
    oneof: 0
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.MarketDataServerSideStreamRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.MarketDataServerSideStreamRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :subscribe_candles_request, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeCandlesRequest,
    json_name: "subscribeCandlesRequest"

  field :subscribe_order_book_request, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeOrderBookRequest,
    json_name: "subscribeOrderBookRequest"

  field :subscribe_trades_request, 3,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeTradesRequest,
    json_name: "subscribeTradesRequest"

  field :subscribe_info_request, 4,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeInfoRequest,
    json_name: "subscribeInfoRequest"

  field :subscribe_last_price_request, 5,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeLastPriceRequest,
    json_name: "subscribeLastPriceRequest"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.MarketDataResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.MarketDataResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  oneof :payload, 0

  field :subscribe_candles_response, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeCandlesResponse,
    json_name: "subscribeCandlesResponse",
    oneof: 0

  field :subscribe_order_book_response, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeOrderBookResponse,
    json_name: "subscribeOrderBookResponse",
    oneof: 0

  field :subscribe_trades_response, 3,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeTradesResponse,
    json_name: "subscribeTradesResponse",
    oneof: 0

  field :subscribe_info_response, 4,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeInfoResponse,
    json_name: "subscribeInfoResponse",
    oneof: 0

  field :candle, 5, type: Tinkoff.Public.Invest.Api.Contract.V1.Candle, oneof: 0
  field :trade, 6, type: Tinkoff.Public.Invest.Api.Contract.V1.Trade, oneof: 0
  field :orderbook, 7, type: Tinkoff.Public.Invest.Api.Contract.V1.OrderBook, oneof: 0

  field :trading_status, 8,
    type: Tinkoff.Public.Invest.Api.Contract.V1.TradingStatus,
    json_name: "tradingStatus",
    oneof: 0

  field :ping, 9, type: Tinkoff.Public.Invest.Api.Contract.V1.Ping, oneof: 0

  field :subscribe_last_price_response, 10,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscribeLastPriceResponse,
    json_name: "subscribeLastPriceResponse",
    oneof: 0

  field :last_price, 11,
    type: Tinkoff.Public.Invest.Api.Contract.V1.LastPrice,
    json_name: "lastPrice",
    oneof: 0
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SubscribeCandlesRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.SubscribeCandlesRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :subscription_action, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionAction,
    json_name: "subscriptionAction",
    enum: true

  field :instruments, 2,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.CandleInstrument

  field :waiting_close, 3, type: :bool, json_name: "waitingClose"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.CandleInstrument do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.CandleInstrument",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string, deprecated: true
  field :interval, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionInterval, enum: true
  field :instrument_id, 3, type: :string, json_name: "instrumentId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SubscribeCandlesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.SubscribeCandlesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :tracking_id, 1, type: :string, json_name: "trackingId"

  field :candles_subscriptions, 2,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.CandleSubscription,
    json_name: "candlesSubscriptions"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.CandleSubscription do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.CandleSubscription",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :interval, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionInterval, enum: true

  field :subscription_status, 3,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionStatus,
    json_name: "subscriptionStatus",
    enum: true

  field :instrument_uid, 4, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SubscribeOrderBookRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.SubscribeOrderBookRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :subscription_action, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionAction,
    json_name: "subscriptionAction",
    enum: true

  field :instruments, 2,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.OrderBookInstrument
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OrderBookInstrument do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OrderBookInstrument",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string, deprecated: true
  field :depth, 2, type: :int32
  field :instrument_id, 3, type: :string, json_name: "instrumentId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SubscribeOrderBookResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.SubscribeOrderBookResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :tracking_id, 1, type: :string, json_name: "trackingId"

  field :order_book_subscriptions, 2,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.OrderBookSubscription,
    json_name: "orderBookSubscriptions"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OrderBookSubscription do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OrderBookSubscription",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :depth, 2, type: :int32

  field :subscription_status, 3,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionStatus,
    json_name: "subscriptionStatus",
    enum: true

  field :instrument_uid, 4, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SubscribeTradesRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.SubscribeTradesRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :subscription_action, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionAction,
    json_name: "subscriptionAction",
    enum: true

  field :instruments, 2,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.TradeInstrument
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.TradeInstrument do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.TradeInstrument",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string, deprecated: true
  field :instrument_id, 2, type: :string, json_name: "instrumentId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SubscribeTradesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.SubscribeTradesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :tracking_id, 1, type: :string, json_name: "trackingId"

  field :trade_subscriptions, 2,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.TradeSubscription,
    json_name: "tradeSubscriptions"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.TradeSubscription do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.TradeSubscription",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string

  field :subscription_status, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionStatus,
    json_name: "subscriptionStatus",
    enum: true

  field :instrument_uid, 3, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SubscribeInfoRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.SubscribeInfoRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :subscription_action, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionAction,
    json_name: "subscriptionAction",
    enum: true

  field :instruments, 2,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InfoInstrument
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.InfoInstrument do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.InfoInstrument",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string, deprecated: true
  field :instrument_id, 2, type: :string, json_name: "instrumentId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SubscribeInfoResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.SubscribeInfoResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :tracking_id, 1, type: :string, json_name: "trackingId"

  field :info_subscriptions, 2,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InfoSubscription,
    json_name: "infoSubscriptions"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.InfoSubscription do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.InfoSubscription",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string

  field :subscription_status, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionStatus,
    json_name: "subscriptionStatus",
    enum: true

  field :instrument_uid, 3, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SubscribeLastPriceRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.SubscribeLastPriceRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :subscription_action, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionAction,
    json_name: "subscriptionAction",
    enum: true

  field :instruments, 2,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.LastPriceInstrument
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.LastPriceInstrument do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.LastPriceInstrument",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string, deprecated: true
  field :instrument_id, 2, type: :string, json_name: "instrumentId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SubscribeLastPriceResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.SubscribeLastPriceResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :tracking_id, 1, type: :string, json_name: "trackingId"

  field :last_price_subscriptions, 2,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.LastPriceSubscription,
    json_name: "lastPriceSubscriptions"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.LastPriceSubscription do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.LastPriceSubscription",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string

  field :subscription_status, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionStatus,
    json_name: "subscriptionStatus",
    enum: true

  field :instrument_uid, 3, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Candle do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Candle",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :interval, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.SubscriptionInterval, enum: true
  field :open, 3, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :high, 4, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :low, 5, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :close, 6, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :volume, 7, type: :int64
  field :time, 8, type: Google.Protobuf.Timestamp
  field :last_trade_ts, 9, type: Google.Protobuf.Timestamp, json_name: "lastTradeTs"
  field :instrument_uid, 10, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OrderBook do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OrderBook",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :depth, 2, type: :int32
  field :is_consistent, 3, type: :bool, json_name: "isConsistent"
  field :bids, 4, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Order
  field :asks, 5, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Order
  field :time, 6, type: Google.Protobuf.Timestamp
  field :limit_up, 7, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation, json_name: "limitUp"

  field :limit_down, 8,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "limitDown"

  field :instrument_uid, 9, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Order do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Order",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :price, 1, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :quantity, 2, type: :int64
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Trade do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Trade",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :direction, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.TradeDirection, enum: true
  field :price, 3, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :quantity, 4, type: :int64
  field :time, 5, type: Google.Protobuf.Timestamp
  field :instrument_uid, 6, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.TradingStatus do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.TradingStatus",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string

  field :trading_status, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SecurityTradingStatus,
    json_name: "tradingStatus",
    enum: true

  field :time, 3, type: Google.Protobuf.Timestamp
  field :limit_order_available_flag, 4, type: :bool, json_name: "limitOrderAvailableFlag"
  field :market_order_available_flag, 5, type: :bool, json_name: "marketOrderAvailableFlag"
  field :instrument_uid, 6, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetCandlesRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetCandlesRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string, deprecated: true
  field :from, 2, type: Google.Protobuf.Timestamp
  field :to, 3, type: Google.Protobuf.Timestamp
  field :interval, 4, type: Tinkoff.Public.Invest.Api.Contract.V1.CandleInterval, enum: true
  field :instrument_id, 5, type: :string, json_name: "instrumentId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetCandlesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetCandlesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :candles, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.HistoricCandle
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.HistoricCandle do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.HistoricCandle",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :open, 1, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :high, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :low, 3, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :close, 4, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :volume, 5, type: :int64
  field :time, 6, type: Google.Protobuf.Timestamp
  field :is_complete, 7, type: :bool, json_name: "isComplete"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetLastPricesRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetLastPricesRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, repeated: true, type: :string, deprecated: true
  field :instrument_id, 2, repeated: true, type: :string, json_name: "instrumentId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetLastPricesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetLastPricesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :last_prices, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.LastPrice,
    json_name: "lastPrices"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.LastPrice do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.LastPrice",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :price, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :time, 3, type: Google.Protobuf.Timestamp
  field :instrument_uid, 11, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetOrderBookRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetOrderBookRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string, deprecated: true
  field :depth, 2, type: :int32
  field :instrument_id, 3, type: :string, json_name: "instrumentId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetOrderBookResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetOrderBookResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :depth, 2, type: :int32
  field :bids, 3, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Order
  field :asks, 4, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Order

  field :last_price, 5,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "lastPrice"

  field :close_price, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "closePrice"

  field :limit_up, 7, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation, json_name: "limitUp"

  field :limit_down, 8,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "limitDown"

  field :last_price_ts, 21, type: Google.Protobuf.Timestamp, json_name: "lastPriceTs"
  field :close_price_ts, 22, type: Google.Protobuf.Timestamp, json_name: "closePriceTs"
  field :orderbook_ts, 23, type: Google.Protobuf.Timestamp, json_name: "orderbookTs"
  field :instrument_uid, 9, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetTradingStatusRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetTradingStatusRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string, deprecated: true
  field :instrument_id, 2, type: :string, json_name: "instrumentId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetTradingStatusesRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetTradingStatusesRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instrument_id, 1, repeated: true, type: :string, json_name: "instrumentId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetTradingStatusesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetTradingStatusesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :trading_statuses, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.GetTradingStatusResponse,
    json_name: "tradingStatuses"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetTradingStatusResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetTradingStatusResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string

  field :trading_status, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SecurityTradingStatus,
    json_name: "tradingStatus",
    enum: true

  field :limit_order_available_flag, 3, type: :bool, json_name: "limitOrderAvailableFlag"
  field :market_order_available_flag, 4, type: :bool, json_name: "marketOrderAvailableFlag"
  field :api_trade_available_flag, 5, type: :bool, json_name: "apiTradeAvailableFlag"
  field :instrument_uid, 6, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetLastTradesRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetLastTradesRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string, deprecated: true
  field :from, 2, type: Google.Protobuf.Timestamp
  field :to, 3, type: Google.Protobuf.Timestamp
  field :instrument_id, 4, type: :string, json_name: "instrumentId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetLastTradesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetLastTradesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :trades, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Trade
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetMySubscriptions do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetMySubscriptions",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetClosePricesRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetClosePricesRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instruments, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentClosePriceRequest
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.InstrumentClosePriceRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.InstrumentClosePriceRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instrument_id, 1, type: :string, json_name: "instrumentId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetClosePricesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetClosePricesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :close_prices, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentClosePriceResponse,
    json_name: "closePrices"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.InstrumentClosePriceResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.InstrumentClosePriceResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :instrument_uid, 2, type: :string, json_name: "instrumentUid"
  field :price, 11, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :time, 21, type: Google.Protobuf.Timestamp
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.MarketDataService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "tinkoff.public.invest.api.contract.v1.MarketDataService",
    protoc_gen_elixir_version: "0.17.0"

  rpc :GetCandles,
      Tinkoff.Public.Invest.Api.Contract.V1.GetCandlesRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetCandlesResponse

  rpc :GetLastPrices,
      Tinkoff.Public.Invest.Api.Contract.V1.GetLastPricesRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetLastPricesResponse

  rpc :GetOrderBook,
      Tinkoff.Public.Invest.Api.Contract.V1.GetOrderBookRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetOrderBookResponse

  rpc :GetTradingStatus,
      Tinkoff.Public.Invest.Api.Contract.V1.GetTradingStatusRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetTradingStatusResponse

  rpc :GetTradingStatuses,
      Tinkoff.Public.Invest.Api.Contract.V1.GetTradingStatusesRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetTradingStatusesResponse

  rpc :GetLastTrades,
      Tinkoff.Public.Invest.Api.Contract.V1.GetLastTradesRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetLastTradesResponse

  rpc :GetClosePrices,
      Tinkoff.Public.Invest.Api.Contract.V1.GetClosePricesRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetClosePricesResponse
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.MarketDataService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Tinkoff.Public.Invest.Api.Contract.V1.MarketDataService.Service
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.MarketDataStreamService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "tinkoff.public.invest.api.contract.v1.MarketDataStreamService",
    protoc_gen_elixir_version: "0.17.0"

  rpc :MarketDataStream,
      stream(Tinkoff.Public.Invest.Api.Contract.V1.MarketDataRequest),
      stream(Tinkoff.Public.Invest.Api.Contract.V1.MarketDataResponse)

  rpc :MarketDataServerSideStream,
      Tinkoff.Public.Invest.Api.Contract.V1.MarketDataServerSideStreamRequest,
      stream(Tinkoff.Public.Invest.Api.Contract.V1.MarketDataResponse)
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.MarketDataStreamService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Tinkoff.Public.Invest.Api.Contract.V1.MarketDataStreamService.Service
end
