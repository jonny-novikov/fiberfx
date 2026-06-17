defmodule Tinkoff.Public.Invest.Api.Contract.V1.OpenSandboxAccountRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OpenSandboxAccountRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.OpenSandboxAccountResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.OpenSandboxAccountResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.CloseSandboxAccountRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.CloseSandboxAccountRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.CloseSandboxAccountResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.CloseSandboxAccountResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SandboxPayInRequest do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.SandboxPayInRequest",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :account_id, 1, type: :string, json_name: "accountId"
  field :amount, 2, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SandboxPayInResponse do
  @moduledoc false

  use Protobuf,
    full_name: "tinkoff.public.invest.api.contract.v1.SandboxPayInResponse",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :balance, 1, type: Tinkoff.Public.Invest.Api.Contract.V1.MoneyValue
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SandboxService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "tinkoff.public.invest.api.contract.v1.SandboxService",
    protoc_gen_elixir_version: "0.17.0"

  rpc :OpenSandboxAccount,
      Tinkoff.Public.Invest.Api.Contract.V1.OpenSandboxAccountRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.OpenSandboxAccountResponse

  rpc :GetSandboxAccounts,
      Tinkoff.Public.Invest.Api.Contract.V1.GetAccountsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetAccountsResponse

  rpc :CloseSandboxAccount,
      Tinkoff.Public.Invest.Api.Contract.V1.CloseSandboxAccountRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.CloseSandboxAccountResponse

  rpc :PostSandboxOrder,
      Tinkoff.Public.Invest.Api.Contract.V1.PostOrderRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.PostOrderResponse

  rpc :ReplaceSandboxOrder,
      Tinkoff.Public.Invest.Api.Contract.V1.ReplaceOrderRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.PostOrderResponse

  rpc :GetSandboxOrders,
      Tinkoff.Public.Invest.Api.Contract.V1.GetOrdersRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetOrdersResponse

  rpc :CancelSandboxOrder,
      Tinkoff.Public.Invest.Api.Contract.V1.CancelOrderRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.CancelOrderResponse

  rpc :GetSandboxOrderState,
      Tinkoff.Public.Invest.Api.Contract.V1.GetOrderStateRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.OrderState

  rpc :GetSandboxPositions,
      Tinkoff.Public.Invest.Api.Contract.V1.PositionsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.PositionsResponse

  rpc :GetSandboxOperations,
      Tinkoff.Public.Invest.Api.Contract.V1.OperationsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.OperationsResponse

  rpc :GetSandboxOperationsByCursor,
      Tinkoff.Public.Invest.Api.Contract.V1.GetOperationsByCursorRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.GetOperationsByCursorResponse

  rpc :GetSandboxPortfolio,
      Tinkoff.Public.Invest.Api.Contract.V1.PortfolioRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.PortfolioResponse

  rpc :SandboxPayIn,
      Tinkoff.Public.Invest.Api.Contract.V1.SandboxPayInRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.SandboxPayInResponse

  rpc :GetSandboxWithdrawLimits,
      Tinkoff.Public.Invest.Api.Contract.V1.WithdrawLimitsRequest,
      Tinkoff.Public.Invest.Api.Contract.V1.WithdrawLimitsResponse
end

defmodule Tinkoff.Public.Invest.Api.Contract.V1.SandboxService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Tinkoff.Public.Invest.Api.Contract.V1.SandboxService.Service
end
