defmodule Tinkoff.Public.Invest.Api.Contract.V1.CouponType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.CouponType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :COUPON_TYPE_UNSPECIFIED, 0
  field :COUPON_TYPE_CONSTANT, 1
  field :COUPON_TYPE_FLOATING, 2
  field :COUPON_TYPE_DISCOUNT, 3
  field :COUPON_TYPE_MORTGAGE, 4
  field :COUPON_TYPE_FIX, 5
  field :COUPON_TYPE_VARIABLE, 6
  field :COUPON_TYPE_OTHER, 7
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OptionDirection do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.OptionDirection",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :OPTION_DIRECTION_UNSPECIFIED, 0
  field :OPTION_DIRECTION_PUT, 1
  field :OPTION_DIRECTION_CALL, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OptionPaymentType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.OptionPaymentType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :OPTION_PAYMENT_TYPE_UNSPECIFIED, 0
  field :OPTION_PAYMENT_TYPE_PREMIUM, 1
  field :OPTION_PAYMENT_TYPE_MARGINAL, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OptionStyle do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.OptionStyle",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :OPTION_STYLE_UNSPECIFIED, 0
  field :OPTION_STYLE_AMERICAN, 1
  field :OPTION_STYLE_EUROPEAN, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OptionSettlementType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.OptionSettlementType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :OPTION_EXECUTION_TYPE_UNSPECIFIED, 0
  field :OPTION_EXECUTION_TYPE_PHYSICAL_DELIVERY, 1
  field :OPTION_EXECUTION_TYPE_CASH_SETTLEMENT, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.InstrumentIdType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.InstrumentIdType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :INSTRUMENT_ID_UNSPECIFIED, 0
  field :INSTRUMENT_ID_TYPE_FIGI, 1
  field :INSTRUMENT_ID_TYPE_TICKER, 2
  field :INSTRUMENT_ID_TYPE_UID, 3
  field :INSTRUMENT_ID_TYPE_POSITION_UID, 4
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.InstrumentStatus do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.InstrumentStatus",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :INSTRUMENT_STATUS_UNSPECIFIED, 0
  field :INSTRUMENT_STATUS_BASE, 1
  field :INSTRUMENT_STATUS_ALL, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.ShareType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.ShareType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :SHARE_TYPE_UNSPECIFIED, 0
  field :SHARE_TYPE_COMMON, 1
  field :SHARE_TYPE_PREFERRED, 2
  field :SHARE_TYPE_ADR, 3
  field :SHARE_TYPE_GDR, 4
  field :SHARE_TYPE_MLP, 5
  field :SHARE_TYPE_NY_REG_SHRS, 6
  field :SHARE_TYPE_CLOSED_END_FUND, 7
  field :SHARE_TYPE_REIT, 8
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AssetType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.AssetType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :ASSET_TYPE_UNSPECIFIED, 0
  field :ASSET_TYPE_CURRENCY, 1
  field :ASSET_TYPE_COMMODITY, 2
  field :ASSET_TYPE_INDEX, 3
  field :ASSET_TYPE_SECURITY, 4
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.StructuredProductType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.StructuredProductType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :SP_TYPE_UNSPECIFIED, 0
  field :SP_TYPE_DELIVERABLE, 1
  field :SP_TYPE_NON_DELIVERABLE, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.EditFavoritesActionType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.EditFavoritesActionType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :EDIT_FAVORITES_ACTION_TYPE_UNSPECIFIED, 0
  field :EDIT_FAVORITES_ACTION_TYPE_ADD, 1
  field :EDIT_FAVORITES_ACTION_TYPE_DEL, 2
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.RealExchange do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.RealExchange",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :REAL_EXCHANGE_UNSPECIFIED, 0
  field :REAL_EXCHANGE_MOEX, 1
  field :REAL_EXCHANGE_RTS, 2
  field :REAL_EXCHANGE_OTC, 3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.RiskLevel do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.RiskLevel",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :RISK_LEVEL_UNSPECIFIED, 0
  field :RISK_LEVEL_LOW, 1
  field :RISK_LEVEL_MODERATE, 2
  field :RISK_LEVEL_HIGH, 3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.TradingSchedulesRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.TradingSchedulesRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :exchange, 1, type: :string
  field :from, 2, type: Google.Protobuf.Timestamp
  field :to, 3, type: Google.Protobuf.Timestamp
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.TradingSchedulesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.TradingSchedulesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :exchanges, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.TradingSchedule
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.TradingSchedule do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.TradingSchedule",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :exchange, 1, type: :string
  field :days, 2, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.TradingDay
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.TradingDay do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.TradingDay",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :date, 1, type: Google.Protobuf.Timestamp
  field :is_trading_day, 2, type: :bool, json_name: "isTradingDay"
  field :start_time, 3, type: Google.Protobuf.Timestamp, json_name: "startTime"
  field :end_time, 4, type: Google.Protobuf.Timestamp, json_name: "endTime"

  field :opening_auction_start_time, 7,
    type: Google.Protobuf.Timestamp,
    json_name: "openingAuctionStartTime"

  field :closing_auction_end_time, 8,
    type: Google.Protobuf.Timestamp,
    json_name: "closingAuctionEndTime"

  field :evening_opening_auction_start_time, 9,
    type: Google.Protobuf.Timestamp,
    json_name: "eveningOpeningAuctionStartTime"

  field :evening_start_time, 10, type: Google.Protobuf.Timestamp, json_name: "eveningStartTime"
  field :evening_end_time, 11, type: Google.Protobuf.Timestamp, json_name: "eveningEndTime"
  field :clearing_start_time, 12, type: Google.Protobuf.Timestamp, json_name: "clearingStartTime"
  field :clearing_end_time, 13, type: Google.Protobuf.Timestamp, json_name: "clearingEndTime"

  field :premarket_start_time, 14,
    type: Google.Protobuf.Timestamp,
    json_name: "premarketStartTime"

  field :premarket_end_time, 15, type: Google.Protobuf.Timestamp, json_name: "premarketEndTime"

  field :closing_auction_start_time, 16,
    type: Google.Protobuf.Timestamp,
    json_name: "closingAuctionStartTime"

  field :opening_auction_end_time, 17,
    type: Google.Protobuf.Timestamp,
    json_name: "openingAuctionEndTime"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.InstrumentRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.InstrumentRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :id_type, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentIdType,
    json_name: "idType",
    enum: true

  field :class_code, 2, type: :string, json_name: "classCode"
  field :id, 3, type: :string
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.InstrumentsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.InstrumentsRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instrument_status, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentStatus,
    json_name: "instrumentStatus",
    enum: true
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.FilterOptionsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.FilterOptionsRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :basic_asset_uid, 1, type: :string, json_name: "basicAssetUid"
  field :basic_asset_position_uid, 2, type: :string, json_name: "basicAssetPositionUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.BondResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.BondResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instrument, 1, type: Tinkoff.Public.Invest.Api.Contract.V1.Bond
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.BondsResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.BondsResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instruments, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Bond
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetBondCouponsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetBondCouponsRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :from, 2, type: Google.Protobuf.Timestamp
  field :to, 3, type: Google.Protobuf.Timestamp
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetBondCouponsResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetBondCouponsResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :events, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Coupon
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Coupon do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Coupon",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :coupon_date, 2, type: Google.Protobuf.Timestamp, json_name: "couponDate"
  field :coupon_number, 3, type: :int64, json_name: "couponNumber"
  field :fix_date, 4, type: Google.Protobuf.Timestamp, json_name: "fixDate"

  field :pay_one_bond, 5,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "payOneBond"

  field :coupon_type, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.CouponType,
    json_name: "couponType",
    enum: true

  field :coupon_start_date, 7, type: Google.Protobuf.Timestamp, json_name: "couponStartDate"
  field :coupon_end_date, 8, type: Google.Protobuf.Timestamp, json_name: "couponEndDate"
  field :coupon_period, 9, type: :int32, json_name: "couponPeriod"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.CurrencyResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.CurrencyResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instrument, 1, type: Tinkoff.Public.Invest.Api.Contract.V1.Currency
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.CurrenciesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.CurrenciesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instruments, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Currency
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.EtfResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.EtfResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instrument, 1, type: Tinkoff.Public.Invest.Api.Contract.V1.Etf
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.EtfsResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.EtfsResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instruments, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Etf
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.FutureResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.FutureResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instrument, 1, type: Tinkoff.Public.Invest.Api.Contract.V1.Future
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.FuturesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.FuturesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instruments, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Future
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OptionResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OptionResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instrument, 1, type: Tinkoff.Public.Invest.Api.Contract.V1.Option
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OptionsResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OptionsResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instruments, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Option
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Option do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Option",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :uid, 1, type: :string
  field :position_uid, 2, type: :string, json_name: "positionUid"
  field :ticker, 3, type: :string
  field :class_code, 4, type: :string, json_name: "classCode"
  field :basic_asset_position_uid, 5, type: :string, json_name: "basicAssetPositionUid"

  field :trading_status, 21,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SecurityTradingStatus,
    json_name: "tradingStatus",
    enum: true

  field :real_exchange, 31,
    type: Tinkoff.Public.Invest.Api.Contract.V1.RealExchange,
    json_name: "realExchange",
    enum: true

  field :direction, 41, type: Tinkoff.Public.Invest.Api.Contract.V1.OptionDirection, enum: true

  field :payment_type, 42,
    type: Tinkoff.Public.Invest.Api.Contract.V1.OptionPaymentType,
    json_name: "paymentType",
    enum: true

  field :style, 43, type: Tinkoff.Public.Invest.Api.Contract.V1.OptionStyle, enum: true

  field :settlement_type, 44,
    type: Tinkoff.Public.Invest.Api.Contract.V1.OptionSettlementType,
    json_name: "settlementType",
    enum: true

  field :name, 101, type: :string
  field :currency, 111, type: :string
  field :settlement_currency, 112, type: :string, json_name: "settlementCurrency"
  field :asset_type, 131, type: :string, json_name: "assetType"
  field :basic_asset, 132, type: :string, json_name: "basicAsset"
  field :exchange, 141, type: :string
  field :country_of_risk, 151, type: :string, json_name: "countryOfRisk"
  field :country_of_risk_name, 152, type: :string, json_name: "countryOfRiskName"
  field :sector, 161, type: :string
  field :lot, 201, type: :int32

  field :basic_asset_size, 211,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "basicAssetSize"

  field :klong, 221, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :kshort, 222, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :dlong, 223, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :dshort, 224, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation

  field :dlong_min, 225,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dlongMin"

  field :dshort_min, 226,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dshortMin"

  field :min_price_increment, 231,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "minPriceIncrement"

  field :strike_price, 241,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "strikePrice"

  field :expiration_date, 301, type: Google.Protobuf.Timestamp, json_name: "expirationDate"
  field :first_trade_date, 311, type: Google.Protobuf.Timestamp, json_name: "firstTradeDate"
  field :last_trade_date, 312, type: Google.Protobuf.Timestamp, json_name: "lastTradeDate"

  field :first_1min_candle_date, 321,
    type: Google.Protobuf.Timestamp,
    json_name: "first1minCandleDate"

  field :first_1day_candle_date, 322,
    type: Google.Protobuf.Timestamp,
    json_name: "first1dayCandleDate"

  field :short_enabled_flag, 401, type: :bool, json_name: "shortEnabledFlag"
  field :for_iis_flag, 402, type: :bool, json_name: "forIisFlag"
  field :otc_flag, 403, type: :bool, json_name: "otcFlag"
  field :buy_available_flag, 404, type: :bool, json_name: "buyAvailableFlag"
  field :sell_available_flag, 405, type: :bool, json_name: "sellAvailableFlag"
  field :for_qual_investor_flag, 406, type: :bool, json_name: "forQualInvestorFlag"
  field :weekend_flag, 407, type: :bool, json_name: "weekendFlag"
  field :blocked_tca_flag, 408, type: :bool, json_name: "blockedTcaFlag"
  field :api_trade_available_flag, 409, type: :bool, json_name: "apiTradeAvailableFlag"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.ShareResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.ShareResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instrument, 1, type: Tinkoff.Public.Invest.Api.Contract.V1.Share
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SharesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.SharesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instruments, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Share
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Bond do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Bond",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :ticker, 2, type: :string
  field :class_code, 3, type: :string, json_name: "classCode"
  field :isin, 4, type: :string
  field :lot, 5, type: :int32
  field :currency, 6, type: :string
  field :klong, 7, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :kshort, 8, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :dlong, 9, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :dshort, 10, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation

  field :dlong_min, 11,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dlongMin"

  field :dshort_min, 12,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dshortMin"

  field :short_enabled_flag, 13, type: :bool, json_name: "shortEnabledFlag"
  field :name, 15, type: :string
  field :exchange, 16, type: :string
  field :coupon_quantity_per_year, 17, type: :int32, json_name: "couponQuantityPerYear"
  field :maturity_date, 18, type: Google.Protobuf.Timestamp, json_name: "maturityDate"
  field :nominal, 19, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue

  field :initial_nominal, 20,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "initialNominal"

  field :state_reg_date, 21, type: Google.Protobuf.Timestamp, json_name: "stateRegDate"
  field :placement_date, 22, type: Google.Protobuf.Timestamp, json_name: "placementDate"

  field :placement_price, 23,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "placementPrice"

  field :aci_value, 24,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "aciValue"

  field :country_of_risk, 25, type: :string, json_name: "countryOfRisk"
  field :country_of_risk_name, 26, type: :string, json_name: "countryOfRiskName"
  field :sector, 27, type: :string
  field :issue_kind, 28, type: :string, json_name: "issueKind"
  field :issue_size, 29, type: :int64, json_name: "issueSize"
  field :issue_size_plan, 30, type: :int64, json_name: "issueSizePlan"

  field :trading_status, 31,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SecurityTradingStatus,
    json_name: "tradingStatus",
    enum: true

  field :otc_flag, 32, type: :bool, json_name: "otcFlag"
  field :buy_available_flag, 33, type: :bool, json_name: "buyAvailableFlag"
  field :sell_available_flag, 34, type: :bool, json_name: "sellAvailableFlag"
  field :floating_coupon_flag, 35, type: :bool, json_name: "floatingCouponFlag"
  field :perpetual_flag, 36, type: :bool, json_name: "perpetualFlag"
  field :amortization_flag, 37, type: :bool, json_name: "amortizationFlag"

  field :min_price_increment, 38,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "minPriceIncrement"

  field :api_trade_available_flag, 39, type: :bool, json_name: "apiTradeAvailableFlag"
  field :uid, 40, type: :string

  field :real_exchange, 41,
    type: Tinkoff.Public.Invest.Api.Contract.V1.RealExchange,
    json_name: "realExchange",
    enum: true

  field :position_uid, 42, type: :string, json_name: "positionUid"
  field :for_iis_flag, 51, type: :bool, json_name: "forIisFlag"
  field :for_qual_investor_flag, 52, type: :bool, json_name: "forQualInvestorFlag"
  field :weekend_flag, 53, type: :bool, json_name: "weekendFlag"
  field :blocked_tca_flag, 54, type: :bool, json_name: "blockedTcaFlag"
  field :subordinated_flag, 55, type: :bool, json_name: "subordinatedFlag"
  field :liquidity_flag, 56, type: :bool, json_name: "liquidityFlag"

  field :first_1min_candle_date, 61,
    type: Google.Protobuf.Timestamp,
    json_name: "first1minCandleDate"

  field :first_1day_candle_date, 62,
    type: Google.Protobuf.Timestamp,
    json_name: "first1dayCandleDate"

  field :risk_level, 63,
    type: Tinkoff.Public.Invest.Api.Contract.V1.RiskLevel,
    json_name: "riskLevel",
    enum: true
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Currency do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Currency",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :ticker, 2, type: :string
  field :class_code, 3, type: :string, json_name: "classCode"
  field :isin, 4, type: :string
  field :lot, 5, type: :int32
  field :currency, 6, type: :string
  field :klong, 7, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :kshort, 8, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :dlong, 9, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :dshort, 10, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation

  field :dlong_min, 11,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dlongMin"

  field :dshort_min, 12,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dshortMin"

  field :short_enabled_flag, 13, type: :bool, json_name: "shortEnabledFlag"
  field :name, 15, type: :string
  field :exchange, 16, type: :string
  field :nominal, 17, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue
  field :country_of_risk, 18, type: :string, json_name: "countryOfRisk"
  field :country_of_risk_name, 19, type: :string, json_name: "countryOfRiskName"

  field :trading_status, 20,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SecurityTradingStatus,
    json_name: "tradingStatus",
    enum: true

  field :otc_flag, 21, type: :bool, json_name: "otcFlag"
  field :buy_available_flag, 22, type: :bool, json_name: "buyAvailableFlag"
  field :sell_available_flag, 23, type: :bool, json_name: "sellAvailableFlag"
  field :iso_currency_name, 24, type: :string, json_name: "isoCurrencyName"

  field :min_price_increment, 25,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "minPriceIncrement"

  field :api_trade_available_flag, 26, type: :bool, json_name: "apiTradeAvailableFlag"
  field :uid, 27, type: :string

  field :real_exchange, 28,
    type: Tinkoff.Public.Invest.Api.Contract.V1.RealExchange,
    json_name: "realExchange",
    enum: true

  field :position_uid, 29, type: :string, json_name: "positionUid"
  field :for_iis_flag, 41, type: :bool, json_name: "forIisFlag"
  field :for_qual_investor_flag, 52, type: :bool, json_name: "forQualInvestorFlag"
  field :weekend_flag, 53, type: :bool, json_name: "weekendFlag"
  field :blocked_tca_flag, 54, type: :bool, json_name: "blockedTcaFlag"

  field :first_1min_candle_date, 56,
    type: Google.Protobuf.Timestamp,
    json_name: "first1minCandleDate"

  field :first_1day_candle_date, 57,
    type: Google.Protobuf.Timestamp,
    json_name: "first1dayCandleDate"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Etf do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Etf",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :ticker, 2, type: :string
  field :class_code, 3, type: :string, json_name: "classCode"
  field :isin, 4, type: :string
  field :lot, 5, type: :int32
  field :currency, 6, type: :string
  field :klong, 7, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :kshort, 8, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :dlong, 9, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :dshort, 10, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation

  field :dlong_min, 11,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dlongMin"

  field :dshort_min, 12,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dshortMin"

  field :short_enabled_flag, 13, type: :bool, json_name: "shortEnabledFlag"
  field :name, 15, type: :string
  field :exchange, 16, type: :string

  field :fixed_commission, 17,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "fixedCommission"

  field :focus_type, 18, type: :string, json_name: "focusType"
  field :released_date, 19, type: Google.Protobuf.Timestamp, json_name: "releasedDate"

  field :num_shares, 20,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "numShares"

  field :country_of_risk, 21, type: :string, json_name: "countryOfRisk"
  field :country_of_risk_name, 22, type: :string, json_name: "countryOfRiskName"
  field :sector, 23, type: :string
  field :rebalancing_freq, 24, type: :string, json_name: "rebalancingFreq"

  field :trading_status, 25,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SecurityTradingStatus,
    json_name: "tradingStatus",
    enum: true

  field :otc_flag, 26, type: :bool, json_name: "otcFlag"
  field :buy_available_flag, 27, type: :bool, json_name: "buyAvailableFlag"
  field :sell_available_flag, 28, type: :bool, json_name: "sellAvailableFlag"

  field :min_price_increment, 29,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "minPriceIncrement"

  field :api_trade_available_flag, 30, type: :bool, json_name: "apiTradeAvailableFlag"
  field :uid, 31, type: :string

  field :real_exchange, 32,
    type: Tinkoff.Public.Invest.Api.Contract.V1.RealExchange,
    json_name: "realExchange",
    enum: true

  field :position_uid, 33, type: :string, json_name: "positionUid"
  field :for_iis_flag, 41, type: :bool, json_name: "forIisFlag"
  field :for_qual_investor_flag, 42, type: :bool, json_name: "forQualInvestorFlag"
  field :weekend_flag, 43, type: :bool, json_name: "weekendFlag"
  field :blocked_tca_flag, 44, type: :bool, json_name: "blockedTcaFlag"
  field :liquidity_flag, 45, type: :bool, json_name: "liquidityFlag"

  field :first_1min_candle_date, 56,
    type: Google.Protobuf.Timestamp,
    json_name: "first1minCandleDate"

  field :first_1day_candle_date, 57,
    type: Google.Protobuf.Timestamp,
    json_name: "first1dayCandleDate"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Future do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Future",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :ticker, 2, type: :string
  field :class_code, 3, type: :string, json_name: "classCode"
  field :lot, 4, type: :int32
  field :currency, 5, type: :string
  field :klong, 6, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :kshort, 7, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :dlong, 8, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :dshort, 9, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation

  field :dlong_min, 10,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dlongMin"

  field :dshort_min, 11,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dshortMin"

  field :short_enabled_flag, 12, type: :bool, json_name: "shortEnabledFlag"
  field :name, 13, type: :string
  field :exchange, 14, type: :string
  field :first_trade_date, 15, type: Google.Protobuf.Timestamp, json_name: "firstTradeDate"
  field :last_trade_date, 16, type: Google.Protobuf.Timestamp, json_name: "lastTradeDate"
  field :futures_type, 17, type: :string, json_name: "futuresType"
  field :asset_type, 18, type: :string, json_name: "assetType"
  field :basic_asset, 19, type: :string, json_name: "basicAsset"

  field :basic_asset_size, 20,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "basicAssetSize"

  field :country_of_risk, 21, type: :string, json_name: "countryOfRisk"
  field :country_of_risk_name, 22, type: :string, json_name: "countryOfRiskName"
  field :sector, 23, type: :string
  field :expiration_date, 24, type: Google.Protobuf.Timestamp, json_name: "expirationDate"

  field :trading_status, 25,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SecurityTradingStatus,
    json_name: "tradingStatus",
    enum: true

  field :otc_flag, 26, type: :bool, json_name: "otcFlag"
  field :buy_available_flag, 27, type: :bool, json_name: "buyAvailableFlag"
  field :sell_available_flag, 28, type: :bool, json_name: "sellAvailableFlag"

  field :min_price_increment, 29,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "minPriceIncrement"

  field :api_trade_available_flag, 30, type: :bool, json_name: "apiTradeAvailableFlag"
  field :uid, 31, type: :string

  field :real_exchange, 32,
    type: Tinkoff.Public.Invest.Api.Contract.V1.RealExchange,
    json_name: "realExchange",
    enum: true

  field :position_uid, 33, type: :string, json_name: "positionUid"
  field :basic_asset_position_uid, 34, type: :string, json_name: "basicAssetPositionUid"
  field :for_iis_flag, 41, type: :bool, json_name: "forIisFlag"
  field :for_qual_investor_flag, 42, type: :bool, json_name: "forQualInvestorFlag"
  field :weekend_flag, 43, type: :bool, json_name: "weekendFlag"
  field :blocked_tca_flag, 44, type: :bool, json_name: "blockedTcaFlag"

  field :first_1min_candle_date, 56,
    type: Google.Protobuf.Timestamp,
    json_name: "first1minCandleDate"

  field :first_1day_candle_date, 57,
    type: Google.Protobuf.Timestamp,
    json_name: "first1dayCandleDate"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Share do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Share",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :ticker, 2, type: :string
  field :class_code, 3, type: :string, json_name: "classCode"
  field :isin, 4, type: :string
  field :lot, 5, type: :int32
  field :currency, 6, type: :string
  field :klong, 7, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :kshort, 8, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :dlong, 9, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :dshort, 10, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation

  field :dlong_min, 11,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dlongMin"

  field :dshort_min, 12,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dshortMin"

  field :short_enabled_flag, 13, type: :bool, json_name: "shortEnabledFlag"
  field :name, 15, type: :string
  field :exchange, 16, type: :string
  field :ipo_date, 17, type: Google.Protobuf.Timestamp, json_name: "ipoDate"
  field :issue_size, 18, type: :int64, json_name: "issueSize"
  field :country_of_risk, 19, type: :string, json_name: "countryOfRisk"
  field :country_of_risk_name, 20, type: :string, json_name: "countryOfRiskName"
  field :sector, 21, type: :string
  field :issue_size_plan, 22, type: :int64, json_name: "issueSizePlan"
  field :nominal, 23, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue

  field :trading_status, 25,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SecurityTradingStatus,
    json_name: "tradingStatus",
    enum: true

  field :otc_flag, 26, type: :bool, json_name: "otcFlag"
  field :buy_available_flag, 27, type: :bool, json_name: "buyAvailableFlag"
  field :sell_available_flag, 28, type: :bool, json_name: "sellAvailableFlag"
  field :div_yield_flag, 29, type: :bool, json_name: "divYieldFlag"

  field :share_type, 30,
    type: Tinkoff.Public.Invest.Api.Contract.V1.ShareType,
    json_name: "shareType",
    enum: true

  field :min_price_increment, 31,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "minPriceIncrement"

  field :api_trade_available_flag, 32, type: :bool, json_name: "apiTradeAvailableFlag"
  field :uid, 33, type: :string

  field :real_exchange, 34,
    type: Tinkoff.Public.Invest.Api.Contract.V1.RealExchange,
    json_name: "realExchange",
    enum: true

  field :position_uid, 35, type: :string, json_name: "positionUid"
  field :for_iis_flag, 46, type: :bool, json_name: "forIisFlag"
  field :for_qual_investor_flag, 47, type: :bool, json_name: "forQualInvestorFlag"
  field :weekend_flag, 48, type: :bool, json_name: "weekendFlag"
  field :blocked_tca_flag, 49, type: :bool, json_name: "blockedTcaFlag"
  field :liquidity_flag, 50, type: :bool, json_name: "liquidityFlag"

  field :first_1min_candle_date, 56,
    type: Google.Protobuf.Timestamp,
    json_name: "first1minCandleDate"

  field :first_1day_candle_date, 57,
    type: Google.Protobuf.Timestamp,
    json_name: "first1dayCandleDate"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetAccruedInterestsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetAccruedInterestsRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :from, 2, type: Google.Protobuf.Timestamp
  field :to, 3, type: Google.Protobuf.Timestamp
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetAccruedInterestsResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetAccruedInterestsResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :accrued_interests, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.AccruedInterest,
    json_name: "accruedInterests"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AccruedInterest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AccruedInterest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :date, 1, type: Google.Protobuf.Timestamp
  field :value, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation

  field :value_percent, 3,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "valuePercent"

  field :nominal, 4, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetFuturesMarginRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetFuturesMarginRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetFuturesMarginResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetFuturesMarginResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :initial_margin_on_buy, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "initialMarginOnBuy"

  field :initial_margin_on_sell, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "initialMarginOnSell"

  field :min_price_increment, 3,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "minPriceIncrement"

  field :min_price_increment_amount, 4,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "minPriceIncrementAmount"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.InstrumentResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.InstrumentResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instrument, 1, type: Tinkoff.Public.Invest.Api.Contract.V1.Instrument
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Instrument do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Instrument",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :ticker, 2, type: :string
  field :class_code, 3, type: :string, json_name: "classCode"
  field :isin, 4, type: :string
  field :lot, 5, type: :int32
  field :currency, 6, type: :string
  field :klong, 7, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :kshort, 8, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :dlong, 9, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :dshort, 10, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation

  field :dlong_min, 11,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dlongMin"

  field :dshort_min, 12,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dshortMin"

  field :short_enabled_flag, 13, type: :bool, json_name: "shortEnabledFlag"
  field :name, 14, type: :string
  field :exchange, 15, type: :string
  field :country_of_risk, 16, type: :string, json_name: "countryOfRisk"
  field :country_of_risk_name, 17, type: :string, json_name: "countryOfRiskName"
  field :instrument_type, 18, type: :string, json_name: "instrumentType"

  field :trading_status, 19,
    type: Tinkoff.Public.Invest.Api.Contract.V1.SecurityTradingStatus,
    json_name: "tradingStatus",
    enum: true

  field :otc_flag, 20, type: :bool, json_name: "otcFlag"
  field :buy_available_flag, 21, type: :bool, json_name: "buyAvailableFlag"
  field :sell_available_flag, 22, type: :bool, json_name: "sellAvailableFlag"

  field :min_price_increment, 23,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "minPriceIncrement"

  field :api_trade_available_flag, 24, type: :bool, json_name: "apiTradeAvailableFlag"
  field :uid, 25, type: :string

  field :real_exchange, 26,
    type: Tinkoff.Public.Invest.Api.Contract.V1.RealExchange,
    json_name: "realExchange",
    enum: true

  field :position_uid, 27, type: :string, json_name: "positionUid"
  field :for_iis_flag, 36, type: :bool, json_name: "forIisFlag"
  field :for_qual_investor_flag, 37, type: :bool, json_name: "forQualInvestorFlag"
  field :weekend_flag, 38, type: :bool, json_name: "weekendFlag"
  field :blocked_tca_flag, 39, type: :bool, json_name: "blockedTcaFlag"

  field :instrument_kind, 40,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentType,
    json_name: "instrumentKind",
    enum: true

  field :first_1min_candle_date, 56,
    type: Google.Protobuf.Timestamp,
    json_name: "first1minCandleDate"

  field :first_1day_candle_date, 57,
    type: Google.Protobuf.Timestamp,
    json_name: "first1dayCandleDate"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetDividendsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetDividendsRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :from, 2, type: Google.Protobuf.Timestamp
  field :to, 3, type: Google.Protobuf.Timestamp
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetDividendsResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetDividendsResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :dividends, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Dividend
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Dividend do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Dividend",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :dividend_net, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "dividendNet"

  field :payment_date, 2, type: Google.Protobuf.Timestamp, json_name: "paymentDate"
  field :declared_date, 3, type: Google.Protobuf.Timestamp, json_name: "declaredDate"
  field :last_buy_date, 4, type: Google.Protobuf.Timestamp, json_name: "lastBuyDate"
  field :dividend_type, 5, type: :string, json_name: "dividendType"
  field :record_date, 6, type: Google.Protobuf.Timestamp, json_name: "recordDate"
  field :regularity, 7, type: :string

  field :close_price, 8,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "closePrice"

  field :yield_value, 9,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "yieldValue"

  field :created_at, 10, type: Google.Protobuf.Timestamp, json_name: "createdAt"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AssetRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AssetRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :id, 1, type: :string
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AssetResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AssetResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :asset, 1, type: Tinkoff.Public.Invest.Api.Contract.V1.AssetFull
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AssetsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AssetsRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instrument_type, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentType,
    json_name: "instrumentType",
    enum: true
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AssetsResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AssetsResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :assets, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Asset
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AssetFull do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AssetFull",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  oneof :ext, 0

  field :uid, 1, type: :string
  field :type, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.AssetType, enum: true
  field :name, 3, type: :string
  field :name_brief, 4, type: :string, json_name: "nameBrief"
  field :description, 5, type: :string
  field :deleted_at, 6, type: Google.Protobuf.Timestamp, json_name: "deletedAt"
  field :required_tests, 7, repeated: true, type: :string, json_name: "requiredTests"
  field :currency, 8, type: Tinkoff.Public.Invest.Api.Contract.V1.AssetCurrency, oneof: 0
  field :security, 9, type: Tinkoff.Public.Invest.Api.Contract.V1.AssetSecurity, oneof: 0
  field :gos_reg_code, 10, type: :string, json_name: "gosRegCode"
  field :cfi, 11, type: :string
  field :code_nsd, 12, type: :string, json_name: "codeNsd"
  field :status, 13, type: :string
  field :brand, 14, type: Tinkoff.Public.Invest.Api.Contract.V1.Brand
  field :updated_at, 15, type: Google.Protobuf.Timestamp, json_name: "updatedAt"
  field :br_code, 16, type: :string, json_name: "brCode"
  field :br_code_name, 17, type: :string, json_name: "brCodeName"

  field :instruments, 18,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.AssetInstrument
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Asset do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Asset",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :uid, 1, type: :string
  field :type, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.AssetType, enum: true
  field :name, 3, type: :string

  field :instruments, 4,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.AssetInstrument
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AssetCurrency do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AssetCurrency",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :base_currency, 1, type: :string, json_name: "baseCurrency"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AssetSecurity do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AssetSecurity",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  oneof :ext, 0

  field :isin, 1, type: :string
  field :type, 2, type: :string

  field :instrument_kind, 10,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentType,
    json_name: "instrumentKind",
    enum: true

  field :share, 3, type: Tinkoff.Public.Invest.Api.Contract.V1.AssetShare, oneof: 0
  field :bond, 4, type: Tinkoff.Public.Invest.Api.Contract.V1.AssetBond, oneof: 0
  field :sp, 5, type: Tinkoff.Public.Invest.Api.Contract.V1.AssetStructuredProduct, oneof: 0
  field :etf, 6, type: Tinkoff.Public.Invest.Api.Contract.V1.AssetEtf, oneof: 0

  field :clearing_certificate, 7,
    type: Tinkoff.Public.Invest.Api.Contract.V1.AssetClearingCertificate,
    json_name: "clearingCertificate",
    oneof: 0
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AssetShare do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AssetShare",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :type, 1, type: Tinkoff.Public.Invest.Api.Contract.V1.ShareType, enum: true

  field :issue_size, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "issueSize"

  field :nominal, 3, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :nominal_currency, 4, type: :string, json_name: "nominalCurrency"
  field :primary_index, 5, type: :string, json_name: "primaryIndex"

  field :dividend_rate, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "dividendRate"

  field :preferred_share_type, 7, type: :string, json_name: "preferredShareType"
  field :ipo_date, 8, type: Google.Protobuf.Timestamp, json_name: "ipoDate"
  field :registry_date, 9, type: Google.Protobuf.Timestamp, json_name: "registryDate"
  field :div_yield_flag, 10, type: :bool, json_name: "divYieldFlag"
  field :issue_kind, 11, type: :string, json_name: "issueKind"
  field :placement_date, 12, type: Google.Protobuf.Timestamp, json_name: "placementDate"
  field :repres_isin, 13, type: :string, json_name: "represIsin"

  field :issue_size_plan, 14,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "issueSizePlan"

  field :total_float, 15,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "totalFloat"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AssetBond do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AssetBond",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :current_nominal, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "currentNominal"

  field :borrow_name, 2, type: :string, json_name: "borrowName"

  field :issue_size, 3,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "issueSize"

  field :nominal, 4, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :nominal_currency, 5, type: :string, json_name: "nominalCurrency"
  field :issue_kind, 6, type: :string, json_name: "issueKind"
  field :interest_kind, 7, type: :string, json_name: "interestKind"
  field :coupon_quantity_per_year, 8, type: :int32, json_name: "couponQuantityPerYear"
  field :indexed_nominal_flag, 9, type: :bool, json_name: "indexedNominalFlag"
  field :subordinated_flag, 10, type: :bool, json_name: "subordinatedFlag"
  field :collateral_flag, 11, type: :bool, json_name: "collateralFlag"
  field :tax_free_flag, 12, type: :bool, json_name: "taxFreeFlag"
  field :amortization_flag, 13, type: :bool, json_name: "amortizationFlag"
  field :floating_coupon_flag, 14, type: :bool, json_name: "floatingCouponFlag"
  field :perpetual_flag, 15, type: :bool, json_name: "perpetualFlag"
  field :maturity_date, 16, type: Google.Protobuf.Timestamp, json_name: "maturityDate"
  field :return_condition, 17, type: :string, json_name: "returnCondition"
  field :state_reg_date, 18, type: Google.Protobuf.Timestamp, json_name: "stateRegDate"
  field :placement_date, 19, type: Google.Protobuf.Timestamp, json_name: "placementDate"

  field :placement_price, 20,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "placementPrice"

  field :issue_size_plan, 21,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "issueSizePlan"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AssetStructuredProduct do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AssetStructuredProduct",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :borrow_name, 1, type: :string, json_name: "borrowName"
  field :nominal, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :nominal_currency, 3, type: :string, json_name: "nominalCurrency"
  field :type, 4, type: Tinkoff.Public.Invest.Api.Contract.V1.StructuredProductType, enum: true
  field :logic_portfolio, 5, type: :string, json_name: "logicPortfolio"

  field :asset_type, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.AssetType,
    json_name: "assetType",
    enum: true

  field :basic_asset, 7, type: :string, json_name: "basicAsset"

  field :safety_barrier, 8,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "safetyBarrier"

  field :maturity_date, 9, type: Google.Protobuf.Timestamp, json_name: "maturityDate"

  field :issue_size_plan, 10,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "issueSizePlan"

  field :issue_size, 11,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "issueSize"

  field :placement_date, 12, type: Google.Protobuf.Timestamp, json_name: "placementDate"
  field :issue_kind, 13, type: :string, json_name: "issueKind"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AssetEtf do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AssetEtf",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :total_expense, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "totalExpense"

  field :hurdle_rate, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "hurdleRate"

  field :performance_fee, 3,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "performanceFee"

  field :fixed_commission, 4,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "fixedCommission"

  field :payment_type, 5, type: :string, json_name: "paymentType"
  field :watermark_flag, 6, type: :bool, json_name: "watermarkFlag"

  field :buy_premium, 7,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "buyPremium"

  field :sell_discount, 8,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "sellDiscount"

  field :rebalancing_flag, 9, type: :bool, json_name: "rebalancingFlag"
  field :rebalancing_freq, 10, type: :string, json_name: "rebalancingFreq"
  field :management_type, 11, type: :string, json_name: "managementType"
  field :primary_index, 12, type: :string, json_name: "primaryIndex"
  field :focus_type, 13, type: :string, json_name: "focusType"
  field :leveraged_flag, 14, type: :bool, json_name: "leveragedFlag"

  field :num_share, 15,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "numShare"

  field :ucits_flag, 16, type: :bool, json_name: "ucitsFlag"
  field :released_date, 17, type: Google.Protobuf.Timestamp, json_name: "releasedDate"
  field :description, 18, type: :string
  field :primary_index_description, 19, type: :string, json_name: "primaryIndexDescription"
  field :primary_index_company, 20, type: :string, json_name: "primaryIndexCompany"

  field :index_recovery_period, 21,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "indexRecoveryPeriod"

  field :inav_code, 22, type: :string, json_name: "inavCode"
  field :div_yield_flag, 23, type: :bool, json_name: "divYieldFlag"

  field :expense_commission, 24,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "expenseCommission"

  field :primary_index_tracking_error, 25,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "primaryIndexTrackingError"

  field :rebalancing_plan, 26, type: :string, json_name: "rebalancingPlan"
  field :tax_rate, 27, type: :string, json_name: "taxRate"

  field :rebalancing_dates, 28,
    repeated: true,
    type: Google.Protobuf.Timestamp,
    json_name: "rebalancingDates"

  field :issue_kind, 29, type: :string, json_name: "issueKind"
  field :nominal, 30, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :nominal_currency, 31, type: :string, json_name: "nominalCurrency"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AssetClearingCertificate do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AssetClearingCertificate",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :nominal, 1, type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation
  field :nominal_currency, 2, type: :string, json_name: "nominalCurrency"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Brand do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Brand",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :uid, 1, type: :string
  field :name, 2, type: :string
  field :description, 3, type: :string
  field :info, 4, type: :string
  field :company, 5, type: :string
  field :sector, 6, type: :string
  field :country_of_risk, 7, type: :string, json_name: "countryOfRisk"
  field :country_of_risk_name, 8, type: :string, json_name: "countryOfRiskName"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AssetInstrument do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.AssetInstrument",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :uid, 1, type: :string
  field :figi, 2, type: :string
  field :instrument_type, 3, type: :string, json_name: "instrumentType"
  field :ticker, 4, type: :string
  field :class_code, 5, type: :string, json_name: "classCode"
  field :links, 6, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentLink

  field :instrument_kind, 10,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentType,
    json_name: "instrumentKind",
    enum: true

  field :position_uid, 11, type: :string, json_name: "positionUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.InstrumentLink do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.InstrumentLink",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :type, 1, type: :string
  field :instrument_uid, 2, type: :string, json_name: "instrumentUid"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetFavoritesRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetFavoritesRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetFavoritesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetFavoritesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :favorite_instruments, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.FavoriteInstrument,
    json_name: "favoriteInstruments"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.FavoriteInstrument do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.FavoriteInstrument",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
  field :ticker, 2, type: :string
  field :class_code, 3, type: :string, json_name: "classCode"
  field :isin, 4, type: :string
  field :instrument_type, 11, type: :string, json_name: "instrumentType"
  field :otc_flag, 16, type: :bool, json_name: "otcFlag"
  field :api_trade_available_flag, 17, type: :bool, json_name: "apiTradeAvailableFlag"

  field :instrument_kind, 18,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentType,
    json_name: "instrumentKind",
    enum: true
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.EditFavoritesRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.EditFavoritesRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instruments, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.EditFavoritesRequestInstrument

  field :action_type, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.EditFavoritesActionType,
    json_name: "actionType",
    enum: true
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.EditFavoritesRequestInstrument do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.EditFavoritesRequestInstrument",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :figi, 1, type: :string
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.EditFavoritesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.EditFavoritesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :favorite_instruments, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.FavoriteInstrument,
    json_name: "favoriteInstruments"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetCountriesRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetCountriesRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetCountriesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetCountriesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :countries, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.CountryResponse
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.CountryResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.CountryResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :alfa_two, 1, type: :string, json_name: "alfaTwo"
  field :alfa_three, 2, type: :string, json_name: "alfaThree"
  field :name, 3, type: :string
  field :name_brief, 4, type: :string, json_name: "nameBrief"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.FindInstrumentRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.FindInstrumentRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :query, 1, type: :string

  field :instrument_kind, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentType,
    json_name: "instrumentKind",
    enum: true

  field :api_trade_available_flag, 3, type: :bool, json_name: "apiTradeAvailableFlag"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.FindInstrumentResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.FindInstrumentResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :instruments, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentShort
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.InstrumentShort do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.InstrumentShort",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :isin, 1, type: :string
  field :figi, 2, type: :string
  field :ticker, 3, type: :string
  field :class_code, 4, type: :string, json_name: "classCode"
  field :instrument_type, 5, type: :string, json_name: "instrumentType"
  field :name, 6, type: :string
  field :uid, 7, type: :string
  field :position_uid, 8, type: :string, json_name: "positionUid"

  field :instrument_kind, 10,
    type: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentType,
    json_name: "instrumentKind",
    enum: true

  field :api_trade_available_flag, 11, type: :bool, json_name: "apiTradeAvailableFlag"
  field :for_iis_flag, 12, type: :bool, json_name: "forIisFlag"

  field :first_1min_candle_date, 26,
    type: Google.Protobuf.Timestamp,
    json_name: "first1minCandleDate"

  field :first_1day_candle_date, 27,
    type: Google.Protobuf.Timestamp,
    json_name: "first1dayCandleDate"

  field :for_qual_investor_flag, 28, type: :bool, json_name: "forQualInvestorFlag"
  field :weekend_flag, 29, type: :bool, json_name: "weekendFlag"
  field :blocked_tca_flag, 30, type: :bool, json_name: "blockedTcaFlag"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetBrandsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetBrandsRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetBrandRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetBrandRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :id, 1, type: :string
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetBrandsResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetBrandsResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :brands, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Brand
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.InstrumentsService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "tinkoff.public.invest.api.contract.v1.InstrumentsService",
    protoc_gen_elixir_version: "0.17.0"

  rpc :TradingSchedules,
      Tinkoff.Public.Invest.Api.Contract.V1.TradingSchedulesRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.TradingSchedulesResponse

  rpc :BondBy,
      Tinkoff.Public.Invest.Api.Contract.V1.InstrumentRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.BondResponse

  rpc :Bonds,
      Tinkoff.Public.Invest.Api.Contract.V1.InstrumentsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.BondsResponse

  rpc :GetBondCoupons,
      Tinkoff.Public.Invest.Api.Contract.V1.GetBondCouponsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetBondCouponsResponse

  rpc :CurrencyBy,
      Tinkoff.Public.Invest.Api.Contract.V1.InstrumentRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.CurrencyResponse

  rpc :Currencies,
      Tinkoff.Public.Invest.Api.Contract.V1.InstrumentsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.CurrenciesResponse

  rpc :EtfBy,
      Tinkoff.Public.Invest.Api.Contract.V1.InstrumentRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.EtfResponse

  rpc :Etfs,
      Tinkoff.Public.Invest.Api.Contract.V1.InstrumentsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.EtfsResponse

  rpc :FutureBy,
      Tinkoff.Public.Invest.Api.Contract.V1.InstrumentRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.FutureResponse

  rpc :Futures,
      Tinkoff.Public.Invest.Api.Contract.V1.InstrumentsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.FuturesResponse

  rpc :OptionBy,
      Tinkoff.Public.Invest.Api.Contract.V1.InstrumentRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.OptionResponse

  rpc :Options,
      Tinkoff.Public.Invest.Api.Contract.V1.InstrumentsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.OptionsResponse

  rpc :OptionsBy,
      Tinkoff.Public.Invest.Api.Contract.V1.FilterOptionsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.OptionsResponse

  rpc :ShareBy,
      Tinkoff.Public.Invest.Api.Contract.V1.InstrumentRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.ShareResponse

  rpc :Shares,
      Tinkoff.Public.Invest.Api.Contract.V1.InstrumentsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.SharesResponse

  rpc :GetAccruedInterests,
      Tinkoff.Public.Invest.Api.Contract.V1.GetAccruedInterestsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetAccruedInterestsResponse

  rpc :GetFuturesMargin,
      Tinkoff.Public.Invest.Api.Contract.V1.GetFuturesMarginRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetFuturesMarginResponse

  rpc :GetInstrumentBy,
      Tinkoff.Public.Invest.Api.Contract.V1.InstrumentRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.InstrumentResponse

  rpc :GetDividends,
      Tinkoff.Public.Invest.Api.Contract.V1.GetDividendsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetDividendsResponse

  rpc :GetAssetBy,
      Tinkoff.Public.Invest.Api.Contract.V1.AssetRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.AssetResponse

  rpc :GetAssets,
      Tinkoff.Public.Invest.Api.Contract.V1.AssetsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.AssetsResponse

  rpc :GetFavorites,
      Tinkoff.Public.Invest.Api.Contract.V1.GetFavoritesRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetFavoritesResponse

  rpc :EditFavorites,
      Tinkoff.Public.Invest.Api.Contract.V1.EditFavoritesRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.EditFavoritesResponse

  rpc :GetCountries,
      Tinkoff.Public.Invest.Api.Contract.V1.GetCountriesRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetCountriesResponse

  rpc :FindInstrument,
      Tinkoff.Public.Invest.Api.Contract.V1.FindInstrumentRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.FindInstrumentResponse

  rpc :GetBrands,
      Tinkoff.Public.Invest.Api.Contract.V1.GetBrandsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetBrandsResponse

  rpc :GetBrandBy,
      Tinkoff.Public.Invest.Api.Contract.V1.GetBrandRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.Brand
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.InstrumentsService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Tinkoff.Public.Invest.Api.Contract.V1.InstrumentsService.Service
end
