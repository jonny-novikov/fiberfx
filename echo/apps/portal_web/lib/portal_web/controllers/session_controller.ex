defmodule PortalWeb.SessionController do
  @moduledoc """
  The `/auth/*` controller (F6.8.1-D6/D7), the HTTP face of the honest door.

  `create/2` (`POST /auth/session`) reads `identifier` + `password`, calls
  `Portal.Auth.sign_in/2`, and on `{:ok, session}` writes the learner's id into the
  signed session cookie F6.1 configured (`put_session(conn, :user_id, …)`) before
  answering the form's `data-redirect`. On `{:error, :invalid_credentials}` it answers
  a `401` — the SAME failure for a wrong name and a wrong password, so the boundary
  leaks nothing about which half was wrong (F6.8.1-INV3); the page reads
  `r.status === 401 || r.status === 403` (`login.html:677`).

  `request_reset/2` (`POST /auth/reset`) reads `email`, calls
  `Portal.Auth.request_reset/1`, and answers a `200` regardless of whether the email
  matches an account (no enumeration, F6.8.1-INV3).

  It names ONLY `Portal.Auth` — never `Portal.Accounts`, `Portal.Engine`, a `Repo`, or
  `GenServer.call` (F6.8.1-INV1, the master invariant).
  """
  use PortalWeb, :controller

  # The default redirect target on a successful sign-in when the request carries no
  # `data-redirect` (the rendered form always sends `/elixir`, login.html:436).
  @default_redirect "/elixir"

  @doc """
  Sign in over the facade — write the signed session and redirect, or fail the same
  way for both halves (F6.8.1-D6, INV3/INV4).
  """
  def create(conn, params) do
    identifier = Map.get(params, "identifier", "")
    password = Map.get(params, "password", "")

    case Portal.Auth.sign_in(identifier, password) do
      {:ok, session} ->
        conn
        |> put_session(:user_id, session.user_id)
        |> redirect(to: safe_redirect(params))

      {:error, :invalid_credentials} ->
        conn
        |> put_status(401)
        |> text("Invalid credentials")
    end
  end

  @doc """
  Request a reset over the facade — always a `200`, never an existence oracle
  (F6.8.1-D7, INV3).
  """
  def request_reset(conn, params) do
    _ = Portal.Auth.request_reset(Map.get(params, "email", ""))

    conn
    |> put_status(200)
    |> text("If an account matches, a reset link is on its way.")
  end

  # The redirect target the sign-in form names (`data-redirect`). The JS posts only the
  # credential fields, so this is normally absent and the constant default is used; a
  # `data-redirect` form field is honored ONLY when it is a local single-leading-slash
  # path (never `//host` or a scheme-relative URL), so the endpoint cannot be turned
  # into an open redirect.
  defp safe_redirect(params) do
    case Map.get(params, "data-redirect") do
      "//" <> _ -> @default_redirect
      "/" <> _ = path -> path
      _ -> @default_redirect
    end
  end
end
