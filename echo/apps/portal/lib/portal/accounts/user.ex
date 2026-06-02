defmodule Portal.Accounts.User do
  @moduledoc "A learner account (namespace USR)."
  @derive {Jason.Encoder, only: [:id, :email, :name]}
  @enforce_keys [:id, :email, :name]
  defstruct [:id, :email, :name]

  @type t :: %__MODULE__{id: String.t(), email: String.t(), name: String.t()}
end
