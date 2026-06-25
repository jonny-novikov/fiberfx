defmodule Codemojex.InitData do
  @moduledoc """
  The pure Telegram WebApp `initData` verifier — the single trust point of the
  auth handshake (`POST /api/auth/:platform`).

  A function over a string and a token: no HTTP, no `Repo`, no session store. The
  same `verify/3` is provable offline with a test-signed fixture, so the HMAC
  path runs with no live Telegram. It is the auth floor's gate: a request reaches
  a player-acting action only after a `SES` minted from a verification this module
  accepted (cm.4.md §4).

  The algorithm is pinned against the live Telegram WebApp docs
  (https://core.telegram.org/bots/webapps), not memory:

    1. Parse the URL-encoded `initData` into `key => URL-decoded value`.
    2. Build the data-check-string from every field EXCEPT `hash` AND `signature`
       — the live docs exclude both; `signature` is the newer Ed25519 third-party
       field and a present `signature` left in the string corrupts the check —
       sorted by key, joined `key=value` with `\\n`.
    3. `secret_key = HMAC-SHA256(key: "WebAppData", msg: token)` — the WebApp
       derivation, which DIFFERS from the older Login-Widget `SHA256(token)`.
    4. `expected = hex(HMAC-SHA256(key: secret_key, msg: data_check_string))`,
       lower-case. Valid iff `:crypto.hash_equals(expected, hash)` — constant-time,
       never `==` (a non-constant-time compare is a timing oracle).
    5. Freshness: `auth_date` is Unix seconds; reject when
       `now - auth_date > max_age_seconds`. `opts[:now]` injects the clock so the
       fixture is deterministic; `:infinity` disables the window.
    6. Extract: decode `user` (JSON) to a map, lift `tg_user_id = user["id"]` (an
       integer).

  Fail-closed: a `nil` token (no bot token configured) returns `{:error, :no_token}`
  rather than authenticating.
  """

  @typedoc "The closed error set — every rejection reason `verify/3` can return."
  @type reason :: :missing | :malformed | :no_token | :bad_hash | :stale

  @default_max_age_seconds 86_400

  @doc """
  Verify a raw Telegram WebApp `initData` string against the bot `token`.

  Returns `{:ok, claims}` for a valid, fresh signature — `claims` carries
  `:tg_user_id` (an integer), the decoded `:user` map, the `:auth_date` (Unix
  seconds), and the `:raw` field map — else `{:error, reason}` in the closed set.

  Options:

    * `:max_age_seconds` — the freshness window in seconds (default `86_400`);
      `:infinity` disables it.
    * `:now` — the current time in Unix seconds (defaults to `System.system_time/1`);
      injected so a fixture is deterministic.
  """
  @spec verify(init_data :: binary() | nil, token :: binary() | nil, opts :: keyword()) ::
          {:ok,
           %{
             tg_user_id: integer(),
             user: map(),
             auth_date: integer(),
             raw: %{optional(binary()) => binary()}
           }}
          | {:error, reason()}
  def verify(init_data, token, opts \\ [])

  def verify(init_data, _token, _opts)
      when not is_binary(init_data) or init_data == "" do
    {:error, :missing}
  end

  def verify(_init_data, token, _opts) when not is_binary(token) do
    # Fail-closed: with no bot token configured the handshake rejects rather than
    # authenticating. A nil (or any non-binary) token is :no_token.
    {:error, :no_token}
  end

  def verify(init_data, token, opts) when is_binary(init_data) and is_binary(token) do
    raw = URI.decode_query(init_data)

    with {:ok, hash} <- fetch_hash(raw),
         :ok <- check_hash(raw, hash, token),
         {:ok, auth_date} <- fetch_auth_date(raw),
         :ok <- check_fresh(auth_date, opts),
         {:ok, user, tg_user_id} <- fetch_user(raw) do
      {:ok, %{tg_user_id: tg_user_id, user: user, auth_date: auth_date, raw: raw}}
    end
  end

  # -- steps -----------------------------------------------------------------

  defp fetch_hash(raw) do
    case Map.get(raw, "hash") do
      h when is_binary(h) and h != "" -> {:ok, h}
      _ -> {:error, :missing}
    end
  end

  # The data-check-string excludes BOTH "hash" and "signature" (pinned footgun),
  # sorts the remaining keys, joins `key=value` with newlines. The compare is
  # constant-time over the lower-case hex digest.
  defp check_hash(raw, hash, token) do
    data_check_string =
      raw
      |> Map.drop(["hash", "signature"])
      |> Enum.sort_by(fn {k, _v} -> k end)
      |> Enum.map_join("\n", fn {k, v} -> k <> "=" <> v end)

    secret_key = :crypto.mac(:hmac, :sha256, "WebAppData", token)

    expected =
      :crypto.mac(:hmac, :sha256, secret_key, data_check_string)
      |> Base.encode16(case: :lower)

    if :crypto.hash_equals(expected, hash), do: :ok, else: {:error, :bad_hash}
  end

  defp fetch_auth_date(raw) do
    with date when is_binary(date) <- Map.get(raw, "auth_date"),
         {seconds, ""} <- Integer.parse(date) do
      {:ok, seconds}
    else
      _ -> {:error, :malformed}
    end
  end

  # Freshness against the injected clock. `:infinity` disables the window.
  defp check_fresh(auth_date, opts) do
    case max_age(opts) do
      :infinity ->
        :ok

      max_age when is_integer(max_age) ->
        if now_seconds(opts) - auth_date > max_age, do: {:error, :stale}, else: :ok
    end
  end

  defp fetch_user(raw) do
    with user_json when is_binary(user_json) <- Map.get(raw, "user"),
         {:ok, %{} = user} <- Jason.decode(user_json),
         id when is_integer(id) <- Map.get(user, "id") do
      {:ok, user, id}
    else
      _ -> {:error, :malformed}
    end
  end

  # -- option helpers --------------------------------------------------------

  defp max_age(opts), do: Keyword.get(opts, :max_age_seconds, @default_max_age_seconds)

  defp now_seconds(opts), do: Keyword.get(opts, :now, System.system_time(:second))
end
