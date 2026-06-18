defmodule Tinkoff.Public.Invest.Api.Contract.V1.StopOrderDirection do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.StopOrderDirection",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :STOP_ORDER_DIRECTION_UNSPECIFIED, 0
  field :STOP_ORDER_DIRECTION_BUY, 1
  field :STOP_ORDER_DIRECTION_SELL, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.StopOrderExpirationType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.StopOrderExpirationType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :STOP_ORDER_EXPIRATION_TYPE_UNSPECIFIED, 0
  field :STOP_ORDER_EXPIRATION_TYPE_GOOD_TILL_CANCEL, 1
  field :STOP_ORDER_EXPIRATION_TYPE_GOOD_TILL_DATE, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.StopOrderType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.StopOrderType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :STOP_ORDER_TYPE_UNSPECIFIED, 0
  field :STOP_ORDER_TYPE_TAKE_PROFIT, 1
  field :STOP_ORDER_TYPE_STOP_LOSS, 2
  field :STOP_ORDER_TYPE_STOP_LIMIT, 3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PostStopOrderRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PostStopOrderRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string, deprecated: true
  field :quantity, 2, type: :int64
  field :price, 3, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation

  field :stop_price, 4,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "stopPrice"

  field :direction, 5, type: Tinkoff.Public.Invest.Api.Contract.V1.StopOrderDirection, enum: true
  field :account_id, 6, type: :string, json_name: "accountId"

  field :expiration_type, 7,
    type: Tinkoff.Public.Invest.Api.Contract.V1.StopOrderExpirationType,
    json_name: "expirationType",
    enum: true

  field :stop_order_type, 8,
    type: Tinkoff.Public.Invest.Api.Contract.V1.StopOrderType,
    json_name: "stopOrderType",
    enum: true

  field :expire_date, 9, type: Google.Protobuf.Timestamp, json_name: "expireDate"
  field :instrument_id, 10, type: :string, json_name: "instrumentId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PostStopOrderResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PostStopOrderResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :stop_order_id, 1, type: :string, json_name: "stopOrderId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetStopOrdersRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetStopOrdersRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetStopOrdersResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetStopOrdersResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :stop_orders, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.StopOrder,
    json_name: "stopOrders"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.CancelStopOrderRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.CancelStopOrderRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
  field :stop_order_id, 2, type: :string, json_name: "stopOrderId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.CancelStopOrderResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.CancelStopOrderResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :time, 1, type: Google.Protobuf.Timestamp
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.StopOrder do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.StopOrder",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :stop_order_id, 1, type: :string, json_name: "stopOrderId"
  field :lots_requested, 2, type: :int64, json_name: "lotsRequested"
  field :figi, 3, type: :string
  field :direction, 4, type: Tinkoff.Public.Invest.Api.Contract.V1.StopOrderDirection, enum: true
  field :currency, 5, type: :string

  field :order_type, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.StopOrderType,
    json_name: "orderType",
    enum: true

  field :create_date, 7, type: Google.Protobuf.Timestamp, json_name: "createDate"
  field :activation_date_time, 8, type: Google.Protobuf.Timestamp, json_name: "activationDateTime"
  field :expiration_time, 9, type: Google.Protobuf.Timestamp, json_name: "expirationTime"
  field :price, 10, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue

  field :stop_price, 11,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "stopPrice"

  field :instrument_uid, 12, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.StopOrdersService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "tinkoff.public.invest.api.contract.v1.StopOrdersService",
    protoc_gen_elixir_version: "0.17.0"

  rpc :PostStopOrder,
      Tinkoff.Public.Invest.Api.Contract.V1.PostStopOrderRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.PostStopOrderResponse

  rpc :GetStopOrders,
      Tinkoff.Public.Invest.Api.Contract.V1.GetStopOrdersRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetStopOrdersResponse

  rpc :CancelStopOrder,
      Tinkoff.Public.Invest.Api.Contract.V1.CancelStopOrderRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.CancelStopOrderResponse
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.StopOrdersService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Tinkoff.Public.Invest.Api.Contract.V1.StopOrdersService.Service
end
