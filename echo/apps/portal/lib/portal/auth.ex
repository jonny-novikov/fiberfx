defmodule Portal.Auth do
  @moduledoc """
  The authentication facade (F6.8.1-D3/D4, the NET-NEW auth seam).

  The single auth-facing surface the web names — `PortalWeb.SessionController` and
  `PortalWeb.UserAuth` call ONLY `Portal.Auth`, never `Portal.Accounts` internals,
  `Portal.Engine`, a `Repo`, or `GenServer.call` (F6.8.1-INV1, the master invariant).
  Like `Portal` itself, this module owns no credential logic: the credential lookup,
  the `bcrypt` verify, and the `%Session{}` mint live PRIVATE under `Portal.Accounts`
  (the F6.8.1 Option-A thin slice); `Portal.Auth` is the thin boundary that names them.

  ## The honest door (F6.8.1-INV3)

  `sign_in/2` returns the IDENTICAL `{:error, :invalid_credentials}` for a non-existent
  identifier AND for an existing identifier with a wrong password — one error for both
  halves, no branch, message, status, or timing that distinguishes them (the underlying
  `Portal.Accounts.resolve_credential/2` runs a constant `bcrypt` cost on a missing user
  too). A caller learns ONE bit on success (`{:ok, %Session{}}`) and ZERO on failure.

  `request_reset/1` ALWAYS returns `:ok`, whether or not the email matches an account —
  the reset endpoint cannot be used as an account-existence oracle (the difference, if
  any, plays out in an inbox, which is out of scope this rung).
  """
  alias Portal.Accounts
  alias Portal.Accounts.{Session, User}

  @doc """
  Sign a learner in by identifier (username or email) and password (F6.8.1-D3, INV3/INV4).

  Resolves the user and verifies the password against the stored `bcrypt` hash. On a
  verified credential it mints `%Portal.Accounts.Session{id: Portal.ID.new("SES"),
  user_id: user.id, token: …}` and returns `{:ok, session}`; on a missing user OR a
  wrong password it returns the SAME `{:error, :invalid_credentials}` (the honest door —
  no oracle).
  """
  @spec sign_in(String.t(), String.t()) :: {:ok, Session.t()} | {:error, :invalid_credentials}
  def sign_in(identifier, password) when is_binary(identifier) and is_binary(password) do
    case Accounts.resolve_credential(identifier, password) do
      {:ok, %User{} = user} -> {:ok, Accounts.mint_session(user)}
      :error -> {:error, :invalid_credentials}
    end
  end

  @doc """
  Request a password reset for an email (F6.8.1-D4, INV3).

  Resolves-or-not by email and ALWAYS returns `:ok` — the same answer whether the email
  matches an account or not, so the endpoint reveals nothing about which addresses have
  accounts (no enumeration). Sending the actual reset mail is out of scope this rung.
  """
  @spec request_reset(String.t()) :: :ok
  def request_reset(email) when is_binary(email) do
    _ = Accounts.email_known?(email)
    :ok
  end

  @doc """
  Load the `%User{}` behind a session id (F6.8.1-D9). The user-load seam
  `PortalWeb.UserAuth.fetch_current_user/2` calls to turn a session `:user_id` into a
  `current_user` — `{:ok, %User{}}` if the id resolves, `:error` otherwise.
  """
  @spec user(String.t()) :: {:ok, User.t()} | :error
  def user(user_id) when is_binary(user_id), do: Accounts.user(user_id)
end
