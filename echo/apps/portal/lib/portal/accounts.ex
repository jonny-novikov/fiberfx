defmodule Portal.Accounts do
  @moduledoc """
  The Accounts bounded context — users and sessions.

  Owns and is the only module that builds or persists its entities; references
  other contexts only by branded id (never by struct).
  """
  alias Portal.Accounts.User

  @doc "Fetch a user by branded id."
  @spec user(String.t()) :: {:ok, User.t()} | :error
  def user(user_id), do: Portal.Store.get("USR", user_id)
end
