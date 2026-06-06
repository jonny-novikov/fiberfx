defmodule Portal.Accounts do
  @moduledoc """
  The Accounts bounded context — users and sessions (F6.4).

  Owns and is the only module that builds or persists its entities; references other
  contexts only by branded id (never by struct). Internals are private: this context
  names `Portal.Store` privately and never another context's schema or `Repo`
  (F6.4-INV3).

  Users stay Store-backed this rung — F6.4 scope is the Course schema + event-sourced
  enrollment; Accounts persistence is out of scope (no schema, no `Repo`). The surface
  here is the minimum the web and the `enroll_and_welcome/2` orchestration need, plus —
  since F6.8.1 (Option A, RATIFIED) — the credential/session-mint internals the new
  `Portal.Auth` facade calls: `resolve_credential/2` (resolve a user by identifier and
  verify the password against a private `bcrypt`-hashed credential), `email_known?/1`
  (the reset resolve-or-not), and `mint_session/1` (a `%Session{}` minted with a branded
  `SES` id). These are PRIVATE to the context — `Portal.Auth` is the only caller; the web
  never names them (F6.8.1-INV1).

  The credential is a thin slice (F6.8.1-D5): NO new schema, NO migration. The seeded
  demonstration accounts live in a private credential table keyed by identifier
  (username or email); each row carries a fixed-id `%User{}` and a `bcrypt` password
  hash. The hash is held HERE, never on the `%User{}` struct — so `%User{}`'s public
  `@derive {Jason.Encoder, only: …}` set cannot serialize it to the web (F6.8.1-INV7).
  """
  alias Portal.Accounts.{Session, User}

  # The seeded demonstration accounts (Option A — Store-backed, no schema). Each entry
  # maps a lower-cased identifier (username AND email both resolve the same user) to its
  # `%User{}` and its bcrypt password hash. Fixed ids keep a seeded user stable across a
  # `Portal.Store.reset/0` (the per-test isolation hook), so the honest-door tests are
  # deterministic. The hash never leaves this module on a `%User{}`. The hashes below are
  # bcrypt of "correct-horse" (the demonstration password the course copy uses).
  @ada %User{id: "USRada00000000", email: "ada@portal.dev", name: "Ada"}
  @ada_hash "$2b$12$7nfeWOR9A5D5YAla1OMAGOf7p9549a4pZeKaxpuumzFZUP9nl0YDC"

  # Identifier → {user, password_hash}. Both the username and the email key the same
  # record (the page lets a learner sign in with either, login.html:439).
  @credentials %{
    "ada" => {@ada, @ada_hash},
    "ada@portal.dev" => {@ada, @ada_hash}
  }

  @doc "Fetch a user by branded id."
  @spec user(String.t()) :: {:ok, User.t()} | :error
  def user(user_id) do
    case Portal.Store.get("USR", user_id) do
      {:ok, %User{} = user} -> {:ok, user}
      :error -> seeded_user(user_id)
    end
  end

  @doc """
  Resolve a user by identifier (username or email) and verify the password against the
  stored `bcrypt` hash (F6.8.1-D5). Returns `{:ok, %User{}}` only when the identifier
  resolves AND the password verifies; returns `:error` for a missing user OR a wrong
  password — the SAME `:error` either way, so the caller (`Portal.Auth.sign_in/2`)
  cannot branch on which half failed (the honest door, F6.8.1-INV3). Runs a constant
  `bcrypt` cost on a missing user too (`no_user_verify/0`), so timing does not leak
  user existence. PRIVATE to the context (`Portal.Auth` is the only caller).
  """
  @spec resolve_credential(String.t(), String.t()) :: {:ok, User.t()} | :error
  def resolve_credential(identifier, password)
      when is_binary(identifier) and is_binary(password) do
    case Map.get(@credentials, normalize(identifier)) do
      {%User{} = user, hash} ->
        if Bcrypt.verify_pass(password, hash), do: {:ok, user}, else: :error

      nil ->
        # No such identifier — spend the same hashing time, return the same :error.
        Bcrypt.no_user_verify()
        :error
    end
  end

  @doc """
  Resolve-or-not an email for a reset request (F6.8.1-D5). Returns a boolean for the
  context's own use; the FACADE (`Portal.Auth.request_reset/1`) discards it and always
  answers `:ok`, so the result never crosses the boundary (no account enumeration,
  F6.8.1-INV3). PRIVATE to the context.
  """
  @spec email_known?(String.t()) :: boolean()
  def email_known?(email) when is_binary(email) do
    Map.has_key?(@credentials, normalize(email))
  end

  @doc """
  Mint an authenticated `%Session{}` for a resolved user (F6.8.1-D5, INV4). The id is a
  branded `SES` id from the canonical `Portal.ID.new/1`; the token is an opaque
  random secret. PRIVATE to the context (`Portal.Auth.sign_in/2` calls it on a verified
  credential). No `Repo`, no schema — the thin Option-A slice.
  """
  @spec mint_session(User.t()) :: Session.t()
  def mint_session(%User{id: user_id}) do
    session = %Session{
      id: Portal.ID.new("SES"),
      user_id: user_id,
      token: Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)
    }

    :ok = Portal.Store.put(session)
    session
  end

  # A seeded account is resolvable by its fixed branded id too (so `UserAuth`'s
  # `current_user` load via `Portal.Auth.user/1` finds the signed-in seeded user after a
  # `Portal.Store.reset/0`). The Store remains the primary lookup; this is the fallback.
  @spec seeded_user(String.t()) :: {:ok, User.t()} | :error
  defp seeded_user(user_id) do
    @credentials
    |> Map.values()
    |> Enum.find_value(:error, fn
      {%User{id: ^user_id} = user, _hash} -> {:ok, user}
      _ -> false
    end)
  end

  defp normalize(identifier), do: identifier |> String.trim() |> String.downcase()

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
