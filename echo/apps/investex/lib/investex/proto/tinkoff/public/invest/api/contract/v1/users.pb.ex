defmodule Tinkoff.Public.Invest.Api.Contract.V1.AccountType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.AccountType",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :ACCOUNT_TYPE_UNSPECIFIED, 0
  field :ACCOUNT_TYPE_TINKOFF, 1
  field :ACCOUNT_TYPE_TINKOFF_IIS, 2
  field :ACCOUNT_TYPE_INVEST_BOX, 3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AccountStatus do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.AccountStatus",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :ACCOUNT_STATUS_UNSPECIFIED, 0
  field :ACCOUNT_STATUS_NEW, 1
  field :ACCOUNT_STATUS_OPEN, 2
  field :ACCOUNT_STATUS_CLOSED, 3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.AccessLevel do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "tinkoff.public.invest.api.contract.v1.AccessLevel",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :ACCOUNT_ACCESS_LEVEL_UNSPECIFIED, 0
  field :ACCOUNT_ACCESS_LEVEL_FULL_ACCESS, 1
  field :ACCOUNT_ACCESS_LEVEL_READ_ONLY, 2
  field :ACCOUNT_ACCESS_LEVEL_NO_ACCESS, 3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetAccountsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetAccountsRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetAccountsResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetAccountsResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :accounts, 1, repeated: true, type: Tinkoff.Public.Invest.Api.Contract.V1.Account
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.Account do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.Account",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :id, 1, type: :string
  field :type, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.AccountType, enum: true
  field :name, 3, type: :string
  field :status, 4, type: Tinkoff.Public.Invest.Api.Contract.V1.AccountStatus, enum: true
  field :opened_date, 5, type: Google.Protobuf.Timestamp, json_name: "openedDate"
  field :closed_date, 6, type: Google.Protobuf.Timestamp, json_name: "closedDate"

  field :access_level, 7,
    type: Tinkoff.Public.Invest.Api.Contract.V1.AccessLevel,
    json_name: "accessLevel",
    enum: true
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetMarginAttributesRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetMarginAttributesRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetMarginAttributesResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetMarginAttributesResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :liquid_portfolio, 1,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "liquidPortfolio"

  field :starting_margin, 2,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "startingMargin"

  field :minimal_margin, 3,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "minimalMargin"

  field :funds_sufficiency_level, 4,
    type: Tinkoff.Public.Invest.Api.Contract.V1.Quotation,
    json_name: "fundsSufficiencyLevel"

  field :amount_of_missing_funds, 5,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "amountOfMissingFunds"

  field :corrected_margin, 6,
    type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue,
    json_name: "correctedMargin"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetUserTariffRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetUserTariffRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetUserTariffResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetUserTariffResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :unary_limits, 1,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.UnaryLimit,
    json_name: "unaryLimits"

  field :stream_limits, 2,
    repeated: true,
    type: Tinkoff.Public.Invest.Api.Contract.V1.StreamLimit,
    json_name: "streamLimits"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.UnaryLimit do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.UnaryLimit",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :limit_per_minute, 1, type: :int32, json_name: "limitPerMinute"
  field :methods, 2, repeated: true, type: :string
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.StreamLimit do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.StreamLimit",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :limit, 1, type: :int32
  field :streams, 2, repeated: true, type: :string
  field :open, 3, type: :int32
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetInfoRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetInfoRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.GetInfoResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.GetInfoResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :prem_status, 1, type: :bool, json_name: "premStatus"
  field :qual_status, 2, type: :bool, json_name: "qualStatus"

  field :qualified_for_work_with, 3,
    repeated: true,
    type: :string,
    json_name: "qualifiedForWorkWith"

  field :tariff, 4, type: :string
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.UsersService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "tinkoff.public.invest.api.contract.v1.UsersService",
    protoc_gen_elixir_version: "0.17.0"

  rpc :GetAccounts,
      Tinkoff.Public.Invest.Api.Contract.V1.GetAccountsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetAccountsResponse

  rpc :GetMarginAttributes,
      Tinkoff.Public.Invest.Api.Contract.V1.GetMarginAttributesRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetMarginAttributesResponse

  rpc :GetUserTariff,
      Tinkoff.Public.Invest.Api.Contract.V1.GetUserTariffRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetUserTariffResponse

  rpc :GetInfo,
      Tinkoff.Public.Invest.Api.Contract.V1.GetInfoRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetInfoResponse
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.UsersService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Tinkoff.Public.Invest.Api.Contract.V1.UsersService.Service
end
