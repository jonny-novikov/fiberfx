defmodule CodemojexWeb.TelegramController do
  @moduledoc """
  The Telegram webhook ingress — the production inbound transport for @codemoji_bot.

  Telegram POSTs each update here; this is the alternative to `echo_bot`'s long-poll updater, and
  unlike polling it scales horizontally (Telegram fans out to one URL behind the load balancer, with
  no single-`getUpdates`-consumer constraint). The request is authenticated by Telegram's **secret
  token**: the value passed to `setWebhook(secret_token:)` is echoed on every call in the
  `X-Telegram-Bot-Api-Secret-Token` header, compared here in CONSTANT TIME to the configured secret.

  A valid update is handed to `Codemojex.EchoBot.ingest/1`, which normalizes it and bridges it onto
  the EchoMQ bus (drained by `Codemojex.CommandWorker`); the handler then returns 200 immediately, so
  Telegram does not retry while the command is processed off the hot path. An ingest error is logged,
  not surfaced — the update is acked (200) rather than risking a Telegram retry storm.

  **Fail-closed:** a missing/empty configured secret, a missing header, or a mismatch → 401, and
  ingest is never called. The route is therefore inert until webhook mode is configured — a
  `CODEMOJI_WEBHOOK_SECRET` set in prod wires the secret here (see `config/runtime.exs`).
  """
  use CodemojexWeb, :controller
  require Logger

  @secret_header "x-telegram-bot-api-secret-token"

  @doc "Webhook receiver: 200 on an authenticated update (bridged to the bus); 401 otherwise."
  def webhook(conn, _params) do
    if authorized?(conn) do
      _ = bridge(conn.body_params)
      send_resp(conn, 200, "")
    else
      send_resp(conn, 401, "")
    end
  end

  # Constant-time compare of the presented secret-token header against the configured secret.
  # Fail-closed: no configured secret, or no header present, is unauthorized.
  defp authorized?(conn) do
    with secret when is_binary(secret) and secret != "" <- configured_secret(),
         [presented | _] <- get_req_header(conn, @secret_header) do
      Plug.Crypto.secure_compare(secret, presented)
    else
      _ -> false
    end
  end

  # ingest/1 returns {:ok, job_id} | {:ok, :ignored} | {:error, term()}.
  defp bridge(params) when is_map(params) do
    case Codemojex.EchoBot.ingest(params) do
      {:ok, _} -> :ok
      {:error, reason} -> Logger.warning("telegram webhook: ingest failed (#{inspect(reason)})")
    end
  end

  defp bridge(_), do: :ok

  defp configured_secret, do: Keyword.get(Application.get_env(:codemojex, __MODULE__, []), :secret)
end
