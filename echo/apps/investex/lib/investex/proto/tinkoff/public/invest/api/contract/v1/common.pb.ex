defmodule Tinkoff.Public.Invest.Api.Contract.V1.InstrumentType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.InstrumentType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :INSTRUMENT_TYPE_UNSPECIFIED, 0
  field :INSTRUMENT_TYPE_BOND, 1
  field :INSTRUMENT_TYPE_SHARE, 2
  field :INSTRUMENT_TYPE_CURRENCY, 3
  field :INSTRUMENT_TYPE_ETF, 4
  field :INSTRUMENT_TYPE_FUTURES, 5
  field :INSTRUMENT_TYPE_SP, 6
  field :INSTRUMENT_TYPE_OPTION, 7
  field :INSTRUMENT_TYPE_CLEARING_CERTIFICATE, 8
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SecurityTradingStatus do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.SecurityTradingStatus",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :SECURITY_TRADING_STATUS_UNSPECIFIED, 0
  field :SECURITY_TRADING_STATUS_NOT_AVAILABLE_FOR_TRADING, 1
  field :SECURITY_TRADING_STATUS_OPENING_PERIOD, 2
  field :SECURITY_TRADING_STATUS_CLOSING_PERIOD, 3
  field :SECURITY_TRADING_STATUS_BREAK_IN_TRADING, 4
  field :SECURITY_TRADING_STATUS_NORMAL_TRADING, 5
  field :SECURITY_TRADING_STATUS_CLOSING_AUCTION, 6
  field :SECURITY_TRADING_STATUS_DARK_POOL_AUCTION, 7
  field :SECURITY_TRADING_STATUS_DISCRETE_AUCTION, 8
  field :SECURITY_TRADING_STATUS_OPENING_AUCTION_PERIOD, 9
  field :SECURITY_TRADING_STATUS_TRADING_AT_CLOSING_AUCTION_PRICE, 10
  field :SECURITY_TRADING_STATUS_SESSION_ASSIGNED, 11
  field :SECURITY_TRADING_STATUS_SESSION_CLOSE, 12
  field :SECURITY_TRADING_STATUS_SESSION_OPEN, 13
  field :SECURITY_TRADING_STATUS_DEALER_NORMAL_TRADING, 14
  field :SECURITY_TRADING_STATUS_DEALER_BREAK_IN_TRADING, 15
  field :SECURITY_TRADING_STATUS_DEALER_NOT_AVAILABLE_FOR_TRADING, 16
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.MoneyValue",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :currency, 1, type: :string
  field :units, 2, type: :int64
  field :nano, 3, type: :int32
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Quotation do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Quotation",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :units, 1, type: :int64
  field :nano, 2, type: :int32
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Ping do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Ping",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :time, 1, type: Google.Protobuf.Timestamp
end
