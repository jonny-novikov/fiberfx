defmodule ExGram.Client do
  @moduledoc """
  The low-level Telegram Bot API client — the minimal vendored subset.

  Vendored from ex_gram (github.com/rockneurotiko/ex_gram) as owned source; see
  `vendor/ex_gram/README.md` for provenance and `vendor/ex_gram/CLAUDE.md` for the
  ownership directive. Only the two calls F10.1 needs are carried: `get_updates/2`
  (the long-poll) and `send_message/4` (the reply). Transport is OTP's built-in
  `:httpc`/`:ssl` (no Finch/Tesla/hackney), so the footprint stays minimal.

  This module is reached ONLY through `EchoBot.Platform.Telegram`; no engine-core
  module names it (F10.1-INV4).
  """

  @api_base "https://api.telegram.org/bot"
  @default_timeout 30

  @doc """
  Long-poll `getUpdates`. `offset` acknowledges every update strictly below it, so a
  consumed update is never re-delivered; `timeout` is the long-poll hold in seconds.
  Returns `{:ok, [raw_update_map]}` or `{:error, reason}`.
  """
  @spec get_updates(String.t(), keyword()) :: {:ok, [map()]} | {:error, term()}
  def get_updates(token, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    body =
      %{"timeout" => timeout}
      |> maybe_put("offset", Keyword.get(opts, :offset))
      |> maybe_put("allowed_updates", Keyword.get(opts, :allowed_updates))

    case request(token, "getUpdates", body, timeout + 5) do
      {:ok, result} when is_list(result) -> {:ok, result}
      {:ok, _other} -> {:error, :unexpected_result}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  `sendMessage` — post `text` to `chat_id`. Returns `{:ok, raw_message_map}` or
  `{:error, reason}`.
  """
  @spec send_message(String.t(), integer() | String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def send_message(token, chat_id, text, opts \\ []) do
    body =
      %{"chat_id" => chat_id, "text" => text}
      |> maybe_put("parse_mode", Keyword.get(opts, :parse_mode))

    request(token, "sendMessage", body, @default_timeout)
  end

  # POST a JSON body to a Bot API method and unwrap Telegram's `{ok, result}` envelope.
  defp request(token, method, body, timeout_s) do
    url = ~c"#{@api_base}#{token}/#{method}"
    payload = Jason.encode!(body)

    http_opts = [timeout: timeout_s * 1000, connect_timeout: 10_000]
    opts = [body_format: :binary]

    request_tuple = {url, [], ~c"application/json", payload}

    case :httpc.request(:post, request_tuple, http_opts, opts) do
      {:ok, {{_v, status, _r}, _headers, response_body}} ->
        decode_envelope(status, response_body)

      {:error, reason} ->
        {:error, {:http, reason}}
    end
  end

  # Telegram wraps every reply in `{"ok": bool, "result"|"description": ...}`.
  defp decode_envelope(status, response_body) do
    case Jason.decode(response_body) do
      {:ok, %{"ok" => true, "result" => result}} ->
        {:ok, result}

      {:ok, %{"ok" => false, "description" => description}} ->
        {:error, {:telegram, status, description}}

      {:ok, other} ->
        {:error, {:telegram, status, other}}

      {:error, _} ->
        {:error, {:decode, status}}
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
