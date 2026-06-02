defmodule Portal.Accounts.Session do
  @moduledoc "An authenticated session for a user (namespace SES)."
  @derive {Jason.Encoder, only: [:id, :user_id, :token]}
  @enforce_keys [:id, :user_id, :token]
  defstruct [:id, :user_id, :token]

  @type t :: %__MODULE__{id: String.t(), user_id: String.t(), token: String.t()}
end
