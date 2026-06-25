defmodule Codemojex.AuthHelper do
  @moduledoc """
  Test-only auth conveniences (cm.4 §8, F2). Lives in `test/support` — NEVER a
  `lib/` bypass: a leaked auth-skip minting access into the shared Valkey would
  fool every service, so the suite mints a REAL `SES` via `Codemojex.Session.mint/3`
  and exercises the real verify path with a fixture-signed `initData`.

  `put_session_for/2` mints a real session row in the test Valkey and returns the
  `SES` to present as a bearer. `sign_init_data/2` builds a valid Telegram WebApp
  `initData` string for the WebApp HMAC scheme (excluding `hash` and `signature`
  from the data-check-string, signing with `HMAC-SHA256("WebAppData", token)`), so
  a ConnTest can drive `POST /api/auth/:platform` through the real verifier.
  `with_token/2` sets a known bot token for the duration of a function and restores
  it, so the otherwise-nil test token is deterministic.
  """

  @doc """
  Mint a real `SES` for `plr` (default platform `"telegram"`) and return the id.
  Writes an actual row in the test Valkey via the single-writer surface.
  """
  def put_session_for(plr, platform \\ "telegram") do
    {:ok, ses} = Codemojex.Session.mint(plr, platform, %{})
    ses
  end

  @doc """
  Build a valid Telegram WebApp `initData` string signed with `token`.

  `fields` is a map of `key => value` (string values), e.g.
  `%{"user" => Jason.encode!(%{"id" => 42, "first_name" => "Ada"}), "auth_date" => "1700000000"}`.
  The returned string carries the computed `hash` so `Codemojex.InitData.verify/3`
  accepts it. Tamper one field after signing to drive a reject test.
  """
  def sign_init_data(fields, token) when is_map(fields) and is_binary(token) do
    data_check_string =
      fields
      |> Map.drop(["hash", "signature"])
      |> Enum.sort_by(fn {k, _v} -> k end)
      |> Enum.map_join("\n", fn {k, v} -> k <> "=" <> v end)

    secret_key = :crypto.mac(:hmac, :sha256, "WebAppData", token)

    hash =
      :crypto.mac(:hmac, :sha256, secret_key, data_check_string)
      |> Base.encode16(case: :lower)

    fields
    |> Map.put("hash", hash)
    |> URI.encode_query()
  end

  @doc """
  Run `fun` with a known bot token configured (so the otherwise-nil test token is
  deterministic), restoring the prior value afterward. The token namespace is the
  config key `Codemojex.Telegram` (NOT a module).
  """
  def with_token(token, fun) when is_binary(token) and is_function(fun, 0) do
    prior = Application.get_env(:codemojex, Codemojex.Telegram)
    Application.put_env(:codemojex, Codemojex.Telegram, token: token)

    try do
      fun.()
    after
      case prior do
        nil -> Application.delete_env(:codemojex, Codemojex.Telegram)
        _ -> Application.put_env(:codemojex, Codemojex.Telegram, prior)
      end
    end
  end
end
