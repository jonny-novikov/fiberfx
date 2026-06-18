defmodule Codemojex.Telegram do
  @moduledoc """
  A thin Telegram Bot API client for the Codemoji Mini App's send side.

  Dependency-light on purpose: it posts JSON with OTP's built-in `:httpc` (inets + ssl), so
  the bot needs no extra HTTP library. The HTTP call is injectable (`:http_fun` option / app
  env) so tests drive it without a network. The bot token comes from app env
  (`config :codemojex, Codemojex.Telegram, token: ...`); never hard-code it.

  Only the two calls the game uses are wrapped — `send_message/3` (round results, prize
  notices) and `answer_callback_query/3` (inline-keyboard taps). Both return
  `{:ok, result_map} | {:error, reason}`; the caller (the notification worker) decides whether
  a failure is retryable.
  """
  require Logger

  @api "https://api.telegram.org"

  @doc "Send a text message to a chat. `opts` may carry `:parse_mode`, `:reply_markup`, etc."
  @spec send_message(integer() | binary(), binary(), keyword()) :: {:ok, map()} | {:error, term()}
  def send_message(chat_id, text, opts \\ []) do
    body = Enum.into(opts, %{"chat_id" => chat_id, "text" => text})
    call("sendMessage", body)
  end

  @doc "Acknowledge a callback query (inline button tap) so Telegram stops the loading spinner."
  @spec answer_callback_query(binary(), binary() | nil, keyword()) :: {:ok, map()} | {:error, term()}
  def answer_callback_query(callback_query_id, text \\ nil, opts \\ []) do
    body =
      opts
      |> Enum.into(%{"callback_query_id" => callback_query_id})
      |> maybe_put("text", text)

    call("answerCallbackQuery", body)
  end

  # --- transport -------------------------------------------------------------

  defp call(method, body) do
    url = "#{@api}/bot#{token()}/#{method}"
    payload = Jason.encode!(body)

    case http_fun().(url, payload) do
      {:ok, 200, resp} -> decode_ok(resp)
      {:ok, status, resp} -> {:error, {:telegram_status, status, resp}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp decode_ok(resp) do
    case Jason.decode(resp) do
      {:ok, %{"ok" => true, "result" => result}} -> {:ok, result}
      {:ok, %{"ok" => false} = err} -> {:error, err}
      _ -> {:error, :bad_response}
    end
  end

  # Default transport: OTP :httpc. `inets` and `ssl` must be started (extra_applications).
  defp default_http(url, payload) do
    request = {String.to_charlist(url), [], ~c"application/json", payload}

    case :httpc.request(:post, request, [{:timeout, 10_000}], body_format: :binary) do
      {:ok, {{_http, status, _reason}, _headers, body}} -> {:ok, status, body}
      {:error, reason} -> {:error, reason}
    end
  end

  defp http_fun, do: cfg(:http_fun, &default_http/2)

  defp token do
    case cfg(:token, nil) do
      nil -> raise "Codemojex.Telegram: missing :token (config :codemojex, Codemojex.Telegram, token: ...)"
      t -> t
    end
  end

  defp cfg(key, default), do: Keyword.get(Application.get_env(:codemojex, __MODULE__, []), key, default)

  defp maybe_put(map, _k, nil), do: map
  defp maybe_put(map, k, v), do: Map.put(map, k, v)
end
