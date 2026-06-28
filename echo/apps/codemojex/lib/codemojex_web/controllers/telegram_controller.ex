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
      _ = handle_update(conn.body_params)
      send_resp(conn, 200, "")
    else
      send_resp(conn, 401, "")
    end
  end

  # cm.7 — the Stars payment updates are handled SYNCHRONOUSLY here: Telegram requires a
  # pre_checkout answer within ~10s, and successful_payment must settle exactly-once on the
  # hot path. Every other update is bridged onto the bus as before (durable, replayable).
  defp handle_update(%{"pre_checkout_query" => q}) when is_map(q), do: handle_pre_checkout(q)

  defp handle_update(%{"message" => %{"successful_payment" => sp}}) when is_map(sp),
    do: handle_successful_payment(sp)

  defp handle_update(other), do: bridge(other)

  # The pre_checkout tamper guard (fail-closed, cm.7 §7 step 2). Answer ok: true only when
  # the order is still `created` and the presented amount equals the pinned price_minor; a
  # mismatch / a non-created / absent order -> ok: false (the charge is refused).
  defp handle_pre_checkout(%{"id" => qid, "invoice_payload" => order_id, "total_amount" => amount}) do
    ok = Codemojex.KeyShop.valid_pre_checkout?(order_id, amount)
    opts = if ok, do: [], else: [error_message: "This order is no longer valid."]
    _ = Codemojex.Telegram.answer_pre_checkout_query(qid, ok, opts)
    :ok
  end

  defp handle_pre_checkout(_), do: :ok

  # Telegram's successful_payment IS the order-coupled confirmation (cm-7 D-5). Settle
  # exactly-once via the OTX (rail, external_id) gate — a redelivered update no-ops (the
  # suppressed OTX insert mints nothing / books nothing). The full receipt is preserved in
  # raw_payload. external_id = the Telegram charge id; amount = the gross XTR credited.
  defp handle_successful_payment(
         %{
           "invoice_payload" => order_id,
           "telegram_payment_charge_id" => charge_id,
           "total_amount" => amount
         } = sp
       ) do
    _ =
      Codemojex.KeyShop.settle_payment(%{
        order_id: order_id,
        rail: "stars",
        external_id: charge_id,
        amount_minor: amount,
        payload: sp
      })

    :ok
  end

  defp handle_successful_payment(_), do: :ok

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
