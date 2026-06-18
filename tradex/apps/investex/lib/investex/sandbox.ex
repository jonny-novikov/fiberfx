defmodule Investex.Sandbox do
  @moduledoc """
  SandboxService — the minimal account-lifecycle bootstrap (rung TRD.9.1,
  `docs/exchange/trd.9.1.specs.md` §"SandboxService bootstrap — 3";
  sandbox.proto:20-26).

  A live test needs a sandbox account to test against; the Go SDK auto-opens one
  inside its constructor (client.go:90-111). This module maps the three lifecycle
  RPCs that obtain and dispose of a sandbox account — **open**, **get**, **close**
  — enough for the live round-trip (`open_account → get_accounts → close_account`)
  the rung's hard gate runs. The sandbox **order** methods (PostSandboxOrder etc.,
  sandbox.proto:29-41) wait for 9.3's order lifecycle, and the rest of
  SandboxService (sandbox.proto:44-59) waits for 9.4.

  Each function is **stateless given a client handle** (INV-5), returning
  `{:ok, %Proto.<Response>{}} | {:error, Investex.Error.t()}`. The arity follows
  the proto request shape: a no-field request → `/1`, an account-id-bearing
  request → `/2` (trd.9.1.specs.md §"the arity convention").
  """

  alias Investex.Caller
  alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto
  alias Tinkoff.Public.Invest.Api.Contract.V1.SandboxService.Stub

  @doc "OpenSandboxAccount — register a sandbox account; the response carries its account_id (sandbox.proto:20,63,68)."
  @spec open_account(Investex.Client.t()) ::
          {:ok, Proto.OpenSandboxAccountResponse.t()} | {:error, Investex.Error.t()}
  def open_account(client) do
    Caller.unary(client, &Stub.open_sandbox_account/3, %Proto.OpenSandboxAccountRequest{})
  end

  @doc "GetSandboxAccounts — the sandbox accounts; reuses GetAccountsResponse (sandbox.proto:23)."
  @spec get_accounts(Investex.Client.t()) ::
          {:ok, Proto.GetAccountsResponse.t()} | {:error, Investex.Error.t()}
  def get_accounts(client) do
    Caller.unary(client, &Stub.get_sandbox_accounts/3, %Proto.GetAccountsRequest{})
  end

  @doc "CloseSandboxAccount — close a sandbox account by id; empty response (sandbox.proto:26,73,78)."
  @spec close_account(Investex.Client.t(), String.t()) ::
          {:ok, Proto.CloseSandboxAccountResponse.t()} | {:error, Investex.Error.t()}
  def close_account(client, account_id) when is_binary(account_id) do
    Caller.unary(
      client,
      &Stub.close_sandbox_account/3,
      %Proto.CloseSandboxAccountRequest{account_id: account_id}
    )
  end
end
