defmodule Portal.Accounts do
  @moduledoc """
  The Accounts bounded context — users and sessions (F6.4).

  Owns and is the only module that builds or persists its entities; references other
  contexts only by branded id (never by struct). Internals are private: this context
  names `Portal.Store` privately and never another context's schema or `Repo`
  (F6.4-INV3).

  Users stay Store-backed this rung — F6.4 scope is the Course schema + event-sourced
  enrollment; Accounts persistence is out of scope (no schema, no `Repo`, no
  registration/auth internals). The surface here is the minimum the web and the
  `enroll_and_welcome/2` orchestration need.
  """
  alias Portal.Accounts.User

  @doc "Fetch a user by branded id."
  @spec user(String.t()) :: {:ok, User.t()} | :error
  def user(user_id), do: Portal.Store.get("USR", user_id)

  @doc """
  Welcome a learner (F6.4-D3) — the surface the `enroll_and_welcome/2` orchestration
  calls. Resolves the learner and returns a closed outcome: `{:ok, %User{}}` if the
  user exists, `{:error, :not_found}` otherwise (the caller folds the bare reason into
  the closed `%Portal.Error{}` set at the seam — F6.4-INV5). No side effect is recorded
  this rung (Accounts persistence is out of scope); the welcome is the learner lookup
  the with-chain depends on.
  """
  @spec welcome(String.t()) :: {:ok, User.t()} | {:error, :not_found}
  def welcome(user_id) do
    case user(user_id) do
      {:ok, %User{} = user} -> {:ok, user}
      :error -> {:error, :not_found}
    end
  end
end
