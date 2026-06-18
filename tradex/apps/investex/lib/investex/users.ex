defmodule Investex.Users do
  @moduledoc """
  UsersService — the 4 account/user RPCs (rung TRD.9.1,
  `docs/exchange/trd.9.1.specs.md` §"UsersService — 4"; users.proto:19-28).

  Each function is **stateless given a client handle** (INV-5): it reads the
  channel and the per-RPC metadata from the supervised `Investex.Client`, calls
  the generated `UsersService.Stub`, and returns `{:ok, %Proto.<Response>{}} |
  {:error, Investex.Error.t()}`. No exception escapes; the channel-level and
  gRPC-status failures fold into the typed `Investex.Error`.

  `get_accounts/1` is the canonical sandbox smoke — a no-argument read returning
  the caller's accounts, the lightest real call the client makes (the same one
  the Go SDK uses to confirm a client is alive, client.go:90-111).

  The arity follows the proto request shape (trd.9.1.specs.md §"the arity
  convention"): a no-field request → `/1`, an account-id-bearing request → `/2`.
  """

  alias Investex.Caller
  alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto
  alias Tinkoff.Public.Invest.Api.Contract.V1.UsersService.Stub

  @doc "GetAccounts — the caller's accounts (users.proto:19; empty request)."
  @spec get_accounts(Investex.Client.t()) ::
          {:ok, Proto.GetAccountsResponse.t()} | {:error, Investex.Error.t()}
  def get_accounts(client) do
    Caller.unary(client, &Stub.get_accounts/3, %Proto.GetAccountsRequest{})
  end

  @doc "GetMarginAttributes — margin metrics for an account (users.proto:22; account_id request)."
  @spec get_margin_attributes(Investex.Client.t(), String.t()) ::
          {:ok, Proto.GetMarginAttributesResponse.t()} | {:error, Investex.Error.t()}
  def get_margin_attributes(client, account_id) when is_binary(account_id) do
    Caller.unary(
      client,
      &Stub.get_margin_attributes/3,
      %Proto.GetMarginAttributesRequest{account_id: account_id}
    )
  end

  @doc "GetUserTariff — the user's request limits (users.proto:25; empty request)."
  @spec get_user_tariff(Investex.Client.t()) ::
          {:ok, Proto.GetUserTariffResponse.t()} | {:error, Investex.Error.t()}
  def get_user_tariff(client) do
    Caller.unary(client, &Stub.get_user_tariff/3, %Proto.GetUserTariffRequest{})
  end

  @doc "GetInfo — premium/qualified status + tariff (users.proto:28; empty request)."
  @spec get_info(Investex.Client.t()) ::
          {:ok, Proto.GetInfoResponse.t()} | {:error, Investex.Error.t()}
  def get_info(client) do
    Caller.unary(client, &Stub.get_info/3, %Proto.GetInfoRequest{})
  end
end
