defmodule Tinkoff.Public.Invest.Api.Contract.V1.OperationState do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.OperationState",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :OPERATION_STATE_UNSPECIFIED, 0
  field :OPERATION_STATE_EXECUTED, 1
  field :OPERATION_STATE_CANCELED, 2
  field :OPERATION_STATE_PROGRESS, 3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OperationType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.OperationType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :OPERATION_TYPE_UNSPECIFIED, 0
  field :OPERATION_TYPE_INPUT, 1
  field :OPERATION_TYPE_BOND_TAX, 2
  field :OPERATION_TYPE_OUTPUT_SECURITIES, 3
  field :OPERATION_TYPE_OVERNIGHT, 4
  field :OPERATION_TYPE_TAX, 5
  field :OPERATION_TYPE_BOND_REPAYMENT_FULL, 6
  field :OPERATION_TYPE_SELL_CARD, 7
  field :OPERATION_TYPE_DIVIDEND_TAX, 8
  field :OPERATION_TYPE_OUTPUT, 9
  field :OPERATION_TYPE_BOND_REPAYMENT, 10
  field :OPERATION_TYPE_TAX_CORRECTION, 11
  field :OPERATION_TYPE_SERVICE_FEE, 12
  field :OPERATION_TYPE_BENEFIT_TAX, 13
  field :OPERATION_TYPE_MARGIN_FEE, 14
  field :OPERATION_TYPE_BUY, 15
  field :OPERATION_TYPE_BUY_CARD, 16
  field :OPERATION_TYPE_INPUT_SECURITIES, 17
  field :OPERATION_TYPE_SELL_MARGIN, 18
  field :OPERATION_TYPE_BROKER_FEE, 19
  field :OPERATION_TYPE_BUY_MARGIN, 20
  field :OPERATION_TYPE_DIVIDEND, 21
  field :OPERATION_TYPE_SELL, 22
  field :OPERATION_TYPE_COUPON, 23
  field :OPERATION_TYPE_SUCCESS_FEE, 24
  field :OPERATION_TYPE_DIVIDEND_TRANSFER, 25
  field :OPERATION_TYPE_ACCRUING_VARMARGIN, 26
  field :OPERATION_TYPE_WRITING_OFF_VARMARGIN, 27
  field :OPERATION_TYPE_DELIVERY_BUY, 28
  field :OPERATION_TYPE_DELIVERY_SELL, 29
  field :OPERATION_TYPE_TRACK_MFEE, 30
  field :OPERATION_TYPE_TRACK_PFEE, 31
  field :OPERATION_TYPE_TAX_PROGRESSIVE, 32
  field :OPERATION_TYPE_BOND_TAX_PROGRESSIVE, 33
  field :OPERATION_TYPE_DIVIDEND_TAX_PROGRESSIVE, 34
  field :OPERATION_TYPE_BENEFIT_TAX_PROGRESSIVE, 35
  field :OPERATION_TYPE_TAX_CORRECTION_PROGRESSIVE, 36
  field :OPERATION_TYPE_TAX_REPO_PROGRESSIVE, 37
  field :OPERATION_TYPE_TAX_REPO, 38
  field :OPERATION_TYPE_TAX_REPO_HOLD, 39
  field :OPERATION_TYPE_TAX_REPO_REFUND, 40
  field :OPERATION_TYPE_TAX_REPO_HOLD_PROGRESSIVE, 41
  field :OPERATION_TYPE_TAX_REPO_REFUND_PROGRESSIVE, 42
  field :OPERATION_TYPE_DIV_EXT, 43
  field :OPERATION_TYPE_TAX_CORRECTION_COUPON, 44
  field :OPERATION_TYPE_CASH_FEE, 45
  field :OPERATION_TYPE_OUT_FEE, 46
  field :OPERATION_TYPE_OUT_STAMP_DUTY, 47
  field :OPERATION_TYPE_OUTPUT_SWIFT, 50
  field :OPERATION_TYPE_INPUT_SWIFT, 51
  field :OPERATION_TYPE_OUTPUT_ACQUIRING, 53
  field :OPERATION_TYPE_INPUT_ACQUIRING, 54
  field :OPERATION_TYPE_OUTPUT_PENALTY, 55
  field :OPERATION_TYPE_ADVICE_FEE, 56
  field :OPERATION_TYPE_TRANS_IIS_BS, 57
  field :OPERATION_TYPE_TRANS_BS_BS, 58
  field :OPERATION_TYPE_OUT_MULTI, 59
  field :OPERATION_TYPE_INP_MULTI, 60
  field :OPERATION_TYPE_OVER_PLACEMENT, 61
  field :OPERATION_TYPE_OVER_COM, 62
  field :OPERATION_TYPE_OVER_INCOME, 63
  field :OPERATION_TYPE_OPTION_EXPIRATION, 64
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PortfolioSubscriptionStatus do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.PortfolioSubscriptionStatus",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :PORTFOLIO_SUBSCRIPTION_STATUS_UNSPECIFIED, 0
  field :PORTFOLIO_SUBSCRIPTION_STATUS_SUCCESS, 1
  field :PORTFOLIO_SUBSCRIPTION_STATUS_ACCOUNT_NOT_FOUND, 2
  field :PORTFOLIO_SUBSCRIPTION_STATUS_INTERNAL_ERROR, 3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PositionsAccountSubscriptionStatus do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.PositionsAccountSubscriptionStatus",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :POSITIONS_SUBSCRIPTION_STATUS_UNSPECIFIED, 0
  field :POSITIONS_SUBSCRIPTION_STATUS_SUCCESS, 1
  field :POSITIONS_SUBSCRIPTION_STATUS_ACCOUNT_NOT_FOUND, 2
  field :POSITIONS_SUBSCRIPTION_STATUS_INTERNAL_ERROR, 3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PortfolioRequest.CurrencyRequest do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.PortfolioRequest.CurrencyRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :RUB, 0
  field :USD, 1
  field :EUR, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OperationsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OperationsRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
  field :from, 2, type: Google.Protobuf.Timestamp
  field :to, 3, type: Google.Protobuf.Timestamp
  field :state, 4, type: Tinkoff.Public.Invest.Api.Contract.V1.OperationState, enum: true
  field :figi, 5, type: :string
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OperationsResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OperationsResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :operations, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Operation
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Operation do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Operation",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :id, 1, type: :string
  field :parent_operation_id, 2, type: :string, json_name: "parentOperationId"
  field :currency, 3, type: :string
  field :payment, 4, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue
  field :price, 5, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue
  field :state, 6, type: Tinkoff.Public.Invest.Api.Contract.V1.OperationState, enum: true
  field :quantity, 7, type: :int64
  field :quantity_rest, 8, type: :int64, json_name: "quantityRest"
  field :figi, 9, type: :string
  field :instrument_type, 10, type: :string, json_name: "instrumentType"
  field :date, 11, type: Google.Protobuf.Timestamp
  field :type, 12, type: :string

  field :operation_type, 13,
    type: Tinkoff.Public.Invest.Api.Contract.V1.OperationType,
    json_name: "operationType",
    enum: true

  field :trades, 14, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.OperationTrade
  field :asset_uid, 16, type: :string, json_name: "assetUid"
  field :position_uid, 17, type: :string, json_name: "positionUid"
  field :instrument_uid, 18, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OperationTrade do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OperationTrade",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :trade_id, 1, type: :string, json_name: "tradeId"
  field :date_time, 2, type: Google.Protobuf.Timestamp, json_name: "dateTime"
  field :quantity, 3, type: :int64
  field :price, 4, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PortfolioRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PortfolioRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"

  field :currency, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.PortfolioRequest.CurrencyRequest,
    enum: true
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PortfolioResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PortfolioResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :total_amount_shares, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "totalAmountShares"

  field :total_amount_bonds, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "totalAmountBonds"

  field :total_amount_etf, 3,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "totalAmountEtf"

  field :total_amount_currencies, 4,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "totalAmountCurrencies"

  field :total_amount_futures, 5,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "totalAmountFutures"

  field :expected_yield, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "expectedYield"

  field :positions, 7,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.PortfolioPosition

  field :account_id, 8, type: :string, json_name: "accountId"

  field :total_amount_options, 9,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "totalAmountOptions"

  field :total_amount_sp, 10,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "totalAmountSp"

  field :total_amount_portfolio, 11,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "totalAmountPortfolio"

  field :virtual_positions, 12,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.VirtualPortfolioPosition,
    json_name: "virtualPositions"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PositionsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PositionsRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PositionsResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PositionsResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :money, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue
  field :blocked, 2, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue

  field :securities, 3,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.PositionsSecurities

  field :limits_loading_in_progress, 4, type: :bool, json_name: "limitsLoadingInProgress"
  field :futures, 5, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.PositionsFutures
  field :options, 6, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.PositionsOptions
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.WithdrawLimitsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.WithdrawLimitsRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.WithdrawLimitsResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.WithdrawLimitsResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :money, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue
  field :blocked, 2, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue

  field :blocked_guarantee, 3,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "blockedGuarantee"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PortfolioPosition do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PortfolioPosition",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :instrument_type, 2, type: :string, json_name: "instrumentType"
  field :quantity, 3, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation

  field :average_position_price, 4,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "averagePositionPrice"

  field :expected_yield, 5,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "expectedYield"

  field :current_nkd, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "currentNkd"

  field :average_position_price_pt, 7,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "averagePositionPricePt",
    deprecated: true

  field :current_price, 8,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "currentPrice"

  field :average_position_price_fifo, 9,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "averagePositionPriceFifo"

  field :quantity_lots, 10,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "quantityLots",
    deprecated: true

  field :blocked, 21, type: :bool

  field :blocked_lots, 22,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "blockedLots"

  field :position_uid, 24, type: :string, json_name: "positionUid"
  field :instrument_uid, 25, type: :string, json_name: "instrumentUid"

  field :var_margin, 26,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "varMargin"

  field :expected_yield_fifo, 27,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "expectedYieldFifo"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.VirtualPortfolioPosition do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.VirtualPortfolioPosition",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :position_uid, 1, type: :string, json_name: "positionUid"
  field :instrument_uid, 2, type: :string, json_name: "instrumentUid"
  field :figi, 3, type: :string
  field :instrument_type, 4, type: :string, json_name: "instrumentType"
  field :quantity, 5, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation

  field :average_position_price, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "averagePositionPrice"

  field :expected_yield, 7,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "expectedYield"

  field :expected_yield_fifo, 8,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "expectedYieldFifo"

  field :expire_date, 9, type: Google.Protobuf.Timestamp, json_name: "expireDate"

  field :current_price, 10,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "currentPrice"

  field :average_position_price_fifo, 11,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "averagePositionPriceFifo"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PositionsSecurities do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PositionsSecurities",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :blocked, 2, type: :int64
  field :balance, 3, type: :int64
  field :position_uid, 4, type: :string, json_name: "positionUid"
  field :instrument_uid, 5, type: :string, json_name: "instrumentUid"
  field :exchange_blocked, 11, type: :bool, json_name: "exchangeBlocked"
  field :instrument_type, 16, type: :string, json_name: "instrumentType"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PositionsFutures do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PositionsFutures",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :blocked, 2, type: :int64
  field :balance, 3, type: :int64
  field :position_uid, 4, type: :string, json_name: "positionUid"
  field :instrument_uid, 5, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PositionsOptions do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PositionsOptions",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :position_uid, 1, type: :string, json_name: "positionUid"
  field :instrument_uid, 2, type: :string, json_name: "instrumentUid"
  field :blocked, 11, type: :int64
  field :balance, 21, type: :int64
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.BrokerReportRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.BrokerReportRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  oneof :payload, 0

  field :generate_broker_report_request, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.GenerateBrokerReportRequest,
    json_name: "generateBrokerReportRequest",
    oneof: 0

  field :get_broker_report_request, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.GetBrokerReportRequest,
    json_name: "getBrokerReportRequest",
    oneof: 0
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.BrokerReportResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.BrokerReportResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  oneof :payload, 0

  field :generate_broker_report_response, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.GenerateBrokerReportResponse,
    json_name: "generateBrokerReportResponse",
    oneof: 0

  field :get_broker_report_response, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.GetBrokerReportResponse,
    json_name: "getBrokerReportResponse",
    oneof: 0
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GenerateBrokerReportRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GenerateBrokerReportRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
  field :from, 2, type: Google.Protobuf.Timestamp
  field :to, 3, type: Google.Protobuf.Timestamp
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GenerateBrokerReportResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GenerateBrokerReportResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :task_id, 1, type: :string, json_name: "taskId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetBrokerReportRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetBrokerReportRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :task_id, 1, type: :string, json_name: "taskId"
  field :page, 2, type: :int32
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetBrokerReportResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetBrokerReportResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :broker_report, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.BrokerReport,
    json_name: "brokerReport"

  field :itemsCount, 2, type: :int32
  field :pagesCount, 3, type: :int32
  field :page, 4, type: :int32
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.BrokerReport do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.BrokerReport",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :trade_id, 1, type: :string, json_name: "tradeId"
  field :order_id, 2, type: :string, json_name: "orderId"
  field :figi, 3, type: :string
  field :execute_sign, 4, type: :string, json_name: "executeSign"
  field :trade_datetime, 5, type: Google.Protobuf.Timestamp, json_name: "tradeDatetime"
  field :exchange, 6, type: :string
  field :class_code, 7, type: :string, json_name: "classCode"
  field :direction, 8, type: :string
  field :name, 9, type: :string
  field :ticker, 10, type: :string
  field :price, 11, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue
  field :quantity, 12, type: :int64

  field :order_amount, 13,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "orderAmount"

  field :aci_value, 14,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "aciValue"

  field :total_order_amount, 15,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "totalOrderAmount"

  field :broker_commission, 16,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "brokerCommission"

  field :exchange_commission, 17,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "exchangeCommission"

  field :exchange_clearing_commission, 18,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "exchangeClearingCommission"

  field :repo_rate, 19,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "repoRate"

  field :party, 20, type: :string
  field :clear_value_date, 21, type: Google.Protobuf.Timestamp, json_name: "clearValueDate"
  field :sec_value_date, 22, type: Google.Protobuf.Timestamp, json_name: "secValueDate"
  field :broker_status, 23, type: :string, json_name: "brokerStatus"
  field :separate_agreement_type, 24, type: :string, json_name: "separateAgreementType"
  field :separate_agreement_number, 25, type: :string, json_name: "separateAgreementNumber"
  field :separate_agreement_date, 26, type: :string, json_name: "separateAgreementDate"
  field :delivery_type, 27, type: :string, json_name: "deliveryType"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetDividendsForeignIssuerRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetDividendsForeignIssuerRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  oneof :payload, 0

  field :generate_div_foreign_issuer_report, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.GenerateDividendsForeignIssuerReportRequest,
    json_name: "generateDivForeignIssuerReport",
    oneof: 0

  field :get_div_foreign_issuer_report, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.GetDividendsForeignIssuerReportRequest,
    json_name: "getDivForeignIssuerReport",
    oneof: 0
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetDividendsForeignIssuerResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetDividendsForeignIssuerResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  oneof :payload, 0

  field :generate_div_foreign_issuer_report_response, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.GenerateDividendsForeignIssuerReportResponse,
    json_name: "generateDivForeignIssuerReportResponse",
    oneof: 0

  field :div_foreign_issuer_report, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.GetDividendsForeignIssuerReportResponse,
    json_name: "divForeignIssuerReport",
    oneof: 0
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GenerateDividendsForeignIssuerReportRequest do
  @moduledoc false

  use Protobuf,
    full_name:
      "tinkoff.public.invest.api.contract.v1.GenerateDividendsForeignIssuerReportRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
  field :from, 2, type: Google.Protobuf.Timestamp
  field :to, 3, type: Google.Protobuf.Timestamp
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetDividendsForeignIssuerReportRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetDividendsForeignIssuerReportRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :task_id, 1, type: :string, json_name: "taskId"
  field :page, 2, type: :int32
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GenerateDividendsForeignIssuerReportResponse do
  @moduledoc false

  use Protobuf,
    full_name:
      "tinkoff.public.invest.api.contract.v1.GenerateDividendsForeignIssuerReportResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :task_id, 1, type: :string, json_name: "taskId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetDividendsForeignIssuerReportResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetDividendsForeignIssuerReportResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :dividends_foreign_issuer_report, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.DividendsForeignIssuerReport,
    json_name: "dividendsForeignIssuerReport"

  field :itemsCount, 2, type: :int32
  field :pagesCount, 3, type: :int32
  field :page, 4, type: :int32
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.DividendsForeignIssuerReport do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.DividendsForeignIssuerReport",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :record_date, 1, type: Google.Protobuf.Timestamp, json_name: "recordDate"
  field :payment_date, 2, type: Google.Protobuf.Timestamp, json_name: "paymentDate"
  field :security_name, 3, type: :string, json_name: "securityName"
  field :isin, 4, type: :string
  field :issuer_country, 5, type: :string, json_name: "issuerCountry"
  field :quantity, 6, type: :int64
  field :dividend, 7, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation

  field :external_commission, 8,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "externalCommission"

  field :dividend_gross, 9,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dividendGross"

  field :tax, 10, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation

  field :dividend_amount, 11,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dividendAmount"

  field :currency, 12, type: :string
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PortfolioStreamRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PortfolioStreamRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :accounts, 1, repeated: true, type: :string
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PortfolioStreamResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PortfolioStreamResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  oneof :payload, 0

  field :subscriptions, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.PortfolioSubscriptionResult,
    oneof: 0

  field :portfolio, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.PortfolioResponse, oneof: 0
  field :ping, 3, type: Tinkoff.Public.Invest.Api.Contract.V1.Ping, oneof: 0
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PortfolioSubscriptionResult do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PortfolioSubscriptionResult",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :accounts, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.AccountSubscriptionStatus
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AccountSubscriptionStatus do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AccountSubscriptionStatus",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"

  field :subscription_status, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.PortfolioSubscriptionStatus,
    json_name: "subscriptionStatus",
    enum: true
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetOperationsByCursorRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetOperationsByCursorRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
  field :instrument_id, 2, type: :string, json_name: "instrumentId"
  field :from, 6, type: Google.Protobuf.Timestamp
  field :to, 7, type: Google.Protobuf.Timestamp
  field :cursor, 11, type: :string
  field :limit, 12, type: :int32

  field :operation_types, 13,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.OperationType,
    json_name: "operationTypes",
    enum: true

  field :state, 14, type: Tinkoff.Public.Invest.Api.Contract.V1.OperationState, enum: true
  field :without_commissions, 15, type: :bool, json_name: "withoutCommissions"
  field :without_trades, 16, type: :bool, json_name: "withoutTrades"
  field :without_overnights, 17, type: :bool, json_name: "withoutOvernights"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetOperationsByCursorResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetOperationsByCursorResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :has_next, 1, type: :bool, json_name: "hasNext"
  field :next_cursor, 2, type: :string, json_name: "nextCursor"
  field :items, 6, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.OperationItem
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OperationItem do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OperationItem",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :cursor, 1, type: :string
  field :broker_account_id, 6, type: :string, json_name: "brokerAccountId"
  field :id, 16, type: :string
  field :parent_operation_id, 17, type: :string, json_name: "parentOperationId"
  field :name, 18, type: :string
  field :date, 21, type: Google.Protobuf.Timestamp
  field :type, 22, type: Tinkoff.Public.Invest.Api.Contract.V1.OperationType, enum: true
  field :description, 23, type: :string
  field :state, 24, type: Tinkoff.Public.Invest.Api.Contract.V1.OperationState, enum: true
  field :instrument_uid, 31, type: :string, json_name: "instrumentUid"
  field :figi, 32, type: :string
  field :instrument_type, 33, type: :string, json_name: "instrumentType"

  field :instrument_kind, 34,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentType,
    json_name: "instrumentKind",
    enum: true

  field :position_uid, 35, type: :string, json_name: "positionUid"
  field :payment, 41, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue
  field :price, 42, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue
  field :commission, 43, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue
  field :yield, 44, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue

  field :yield_relative, 45,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "yieldRelative"

  field :accrued_int, 46,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "accruedInt"

  field :quantity, 51, type: :int64
  field :quantity_rest, 52, type: :int64, json_name: "quantityRest"
  field :quantity_done, 53, type: :int64, json_name: "quantityDone"
  field :cancel_date_time, 56, type: Google.Protobuf.Timestamp, json_name: "cancelDateTime"
  field :cancel_reason, 57, type: :string, json_name: "cancelReason"

  field :trades_info, 61,
    type: Tinkoff.Public.Invest.Api.Contract.V1.OperationItemTrades,
    json_name: "tradesInfo"

  field :asset_uid, 64, type: :string, json_name: "assetUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OperationItemTrades do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OperationItemTrades",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :trades, 6, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.OperationItemTrade
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OperationItemTrade do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OperationItemTrade",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :num, 1, type: :string
  field :date, 6, type: Google.Protobuf.Timestamp
  field :quantity, 11, type: :int64
  field :price, 16, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue
  field :yield, 21, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue

  field :yield_relative, 22,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "yieldRelative"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PositionsStreamRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PositionsStreamRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :accounts, 1, repeated: true, type: :string
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PositionsStreamResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PositionsStreamResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  oneof :payload, 0

  field :subscriptions, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.PositionsSubscriptionResult,
    oneof: 0

  field :position, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.PositionData, oneof: 0
  field :ping, 3, type: Tinkoff.Public.Invest.Api.Contract.V1.Ping, oneof: 0
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PositionsSubscriptionResult do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PositionsSubscriptionResult",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :accounts, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.PositionsSubscriptionStatus
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PositionsSubscriptionStatus do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PositionsSubscriptionStatus",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"

  field :subscription_status, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.PositionsAccountSubscriptionStatus,
    json_name: "subscriptionStatus",
    enum: true
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PositionData do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PositionData",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
  field :money, 2, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.PositionsMoney

  field :securities, 3,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.PositionsSecurities

  field :futures, 4, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.PositionsFutures
  field :options, 5, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.PositionsOptions
  field :date, 6, type: Google.Protobuf.Timestamp
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.PositionsMoney do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.PositionsMoney",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :available_value, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "availableValue"

  field :blocked_value, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "blockedValue"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OperationsService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "tinkoff.public.invest.api.contract.v1.OperationsService",
    protoc_gen_elixir_version: "0.17.0"

  rpc :GetOperations,
      Tinkoff.Public.Invest.Api.Contract.V1.OperationsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.OperationsResponse

  rpc :GetPortfolio,
      Tinkoff.Public.Invest.Api.Contract.V1.PortfolioRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.PortfolioResponse

  rpc :GetPositions,
      Tinkoff.Public.Invest.Api.Contract.V1.PositionsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.PositionsResponse

  rpc :GetWithdrawLimits,
      Tinkoff.Public.Invest.Api.Contract.V1.WithdrawLimitsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.WithdrawLimitsResponse

  rpc :GetBrokerReport,
      Tinkoff.Public.Invest.Api.Contract.V1.BrokerReportRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.BrokerReportResponse

  rpc :GetDividendsForeignIssuer,
      Tinkoff.Public.Invest.Api.Contract.V1.GetDividendsForeignIssuerRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetDividendsForeignIssuerResponse

  rpc :GetOperationsByCursor,
      Tinkoff.Public.Invest.Api.Contract.V1.GetOperationsByCursorRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetOperationsByCursorResponse
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OperationsService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Tinkoff.Public.Invest.Api.Contract.V1.OperationsService.Service
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OperationsStreamService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "tinkoff.public.invest.api.contract.v1.OperationsStreamService",
    protoc_gen_elixir_version: "0.17.0"

  rpc :PortfolioStream,
      Tinkoff.Public.Invest.Api.Contract.V1.PortfolioStreamRequest,
      stream(Tinkoff.Public.Invest.Api.Contract.V1.PortfolioStreamResponse)

  rpc :PositionsStream,
      Tinkoff.Public.Invest.Api.Contract.V1.PositionsStreamRequest,
      stream(Tinkoff.Public.Invest.Api.Contract.V1.PositionsStreamResponse)
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OperationsStreamService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Tinkoff.Public.Invest.Api.Contract.V1.OperationsStreamService.Service
end
