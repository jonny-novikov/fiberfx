defmodule Tinkoff.Public.Invest.Api.Contract.V1.OrderDirection do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.OrderDirection",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :ORDER_DIRECTION_UNSPECIFIED, 0
  field :ORDER_DIRECTION_BUY, 1
  field :ORDER_DIRECTION_SELL, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OrderType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.OrderType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :ORDER_TYPE_UNSPECIFIED, 0
  field :ORDER_TYPE_LIMIT, 1
  field :ORDER_TYPE_MARKET, 2
  field :ORDER_TYPE_BESTPRICE, 3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OrderExecutionReportStatus do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.OrderExecutionReportStatus",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :EXECUTION_REPORT_STATUS_UNSPECIFIED, 0
  field :EXECUTION_REPORT_STATUS_FILL, 1
  field :EXECUTION_REPORT_STATUS_REJECTED, 2
  field :EXECUTION_REPORT_STATUS_CANCELLED, 3
  field :EXECUTION_REPORT_STATUS_NEW, 4
  field :EXECUTION_REPORT_STATUS_PARTIALLYFILL, 5
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PriceType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.PriceType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :PRICE_TYPE_UNSPECIFIED, 0
  field :PRICE_TYPE_POINT, 1
  field :PRICE_TYPE_CURRENCY, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.TradesStreamRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.TradesStreamRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :accounts, 1, repeated: true, type: :string
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.TradesStreamResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.TradesStreamResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  oneof :payload, 0

  field :order_trades, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.OrderTrades,
    json_name: "orderTrades",
    oneof: 0

  field :ping, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.Ping, oneof: 0
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OrderTrades do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OrderTrades",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :order_id, 1, type: :string, json_name: "orderId"
  field :created_at, 2, type: Google.Protobuf.Timestamp, json_name: "createdAt"
  field :direction, 3, type: Tinkoff.Public.Invest.Api.Contract.V1.OrderDirection, enum: true
  field :figi, 4, type: :string
  field :trades, 5, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.OrderTrade
  field :account_id, 6, type: :string, json_name: "accountId"
  field :instrument_uid, 7, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OrderTrade do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OrderTrade",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :date_time, 1, type: Google.Protobuf.Timestamp, json_name: "dateTime"
  field :price, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :quantity, 3, type: :int64
  field :trade_id, 4, type: :string, json_name: "tradeId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PostOrderRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PostOrderRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string, deprecated: true
  field :quantity, 2, type: :int64
  field :price, 3, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :direction, 4, type: Tinkoff.Public.Invest.Api.Contract.V1.OrderDirection, enum: true
  field :account_id, 5, type: :string, json_name: "accountId"

  field :order_type, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.OrderType,
    json_name: "orderType",
    enum: true

  field :order_id, 7, type: :string, json_name: "orderId"
  field :instrument_id, 8, type: :string, json_name: "instrumentId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PostOrderResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PostOrderResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :order_id, 1, type: :string, json_name: "orderId"

  field :execution_report_status, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.OrderExecutionReportStatus,
    json_name: "executionReportStatus",
    enum: true

  field :lots_requested, 3, type: :int64, json_name: "lotsRequested"
  field :lots_executed, 4, type: :int64, json_name: "lotsExecuted"

  field :initial_order_price, 5,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "initialOrderPrice"

  field :executed_order_price, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "executedOrderPrice"

  field :total_order_amount, 7,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "totalOrderAmount"

  field :initial_commission, 8,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "initialCommission"

  field :executed_commission, 9,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "executedCommission"

  field :aci_value, 10,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "aciValue"

  field :figi, 11, type: :string
  field :direction, 12, type: Tinkoff.Public.Invest.Api.Contract.V1.OrderDirection, enum: true

  field :initial_security_price, 13,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "initialSecurityPrice"

  field :order_type, 14,
    type: Tinkoff.Public.Invest.Api.Contract.V1.OrderType,
    json_name: "orderType",
    enum: true

  field :message, 15, type: :string

  field :initial_order_price_pt, 16,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "initialOrderPricePt"

  field :instrument_uid, 17, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.CancelOrderRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.CancelOrderRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
  field :order_id, 2, type: :string, json_name: "orderId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.CancelOrderResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.CancelOrderResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :time, 1, type: Google.Protobuf.Timestamp
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetOrderStateRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetOrderStateRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
  field :order_id, 2, type: :string, json_name: "orderId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetOrdersRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetOrdersRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetOrdersResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetOrdersResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :orders, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.OrderState
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OrderState do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OrderState",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :order_id, 1, type: :string, json_name: "orderId"

  field :execution_report_status, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.OrderExecutionReportStatus,
    json_name: "executionReportStatus",
    enum: true

  field :lots_requested, 3, type: :int64, json_name: "lotsRequested"
  field :lots_executed, 4, type: :int64, json_name: "lotsExecuted"

  field :initial_order_price, 5,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "initialOrderPrice"

  field :executed_order_price, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "executedOrderPrice"

  field :total_order_amount, 7,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "totalOrderAmount"

  field :average_position_price, 8,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "averagePositionPrice"

  field :initial_commission, 9,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "initialCommission"

  field :executed_commission, 10,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "executedCommission"

  field :figi, 11, type: :string
  field :direction, 12, type: Tinkoff.Public.Invest.Api.Contract.V1.OrderDirection, enum: true

  field :initial_security_price, 13,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "initialSecurityPrice"

  field :stages, 14, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.OrderStage

  field :service_commission, 15,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "serviceCommission"

  field :currency, 16, type: :string

  field :order_type, 17,
    type: Tinkoff.Public.Invest.Api.Contract.V1.OrderType,
    json_name: "orderType",
    enum: true

  field :order_date, 18, type: Google.Protobuf.Timestamp, json_name: "orderDate"
  field :instrument_uid, 19, type: :string, json_name: "instrumentUid"
  field :order_request_id, 20, type: :string, json_name: "orderRequestId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OrderStage do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OrderStage",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :price, 1, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue
  field :quantity, 2, type: :int64
  field :trade_id, 3, type: :string, json_name: "tradeId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.ReplaceOrderRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.ReplaceOrderRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
  field :order_id, 6, type: :string, json_name: "orderId"
  field :idempotency_key, 7, type: :string, json_name: "idempotencyKey"
  field :quantity, 11, type: :int64
  field :price, 12, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation

  field :price_type, 13,
    type: Tinkoff.Public.Invest.Api.Contract.V1.PriceType,
    json_name: "priceType",
    enum: true
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OrdersStreamService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "tinkoff.public.invest.api.contract.v1.OrdersStreamService",
    protoc_gen_elixir_version: "0.17.0"

  rpc :TradesStream,
      Tinkoff.Public.Invest.Api.Contract.V1.TradesStreamRequest,
      stream(Tinkoff.Public.Invest.Api.Contract.V1.TradesStreamResponse)
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OrdersStreamService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Tinkoff.Public.Invest.Api.Contract.V1.OrdersStreamService.Service
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OrdersService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "tinkoff.public.invest.api.contract.v1.OrdersService",
    protoc_gen_elixir_version: "0.17.0"

  rpc :PostOrder,
      Tinkoff.Public.Invest.Api.Contract.V1.PostOrderRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.PostOrderResponse

  rpc :CancelOrder,
      Tinkoff.Public.Invest.Api.Contract.V1.CancelOrderRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.CancelOrderResponse

  rpc :GetOrderState,
      Tinkoff.Public.Invest.Api.Contract.V1.GetOrderStateRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.OrderState

  rpc :GetOrders,
      Tinkoff.Public.Invest.Api.Contract.V1.GetOrdersRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetOrdersResponse

  rpc :ReplaceOrder,
      Tinkoff.Public.Invest.Api.Contract.V1.ReplaceOrderRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.PostOrderResponse
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OrdersService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Tinkoff.Public.Invest.Api.Contract.V1.OrdersService.Service
end
