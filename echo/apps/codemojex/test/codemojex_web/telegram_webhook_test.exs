defmodule CodemojexWeb.TelegramWebhookTest do
  @moduledoc """
  The cm.5 inbound webhook transport — `POST /api/telegram/webhook`.

  The SECURITY gate (Telegram's secret-token header, constant-time compared, fail-closed) needs no
  bus and runs in the default suite. The end-to-end proof that an authenticated update bridges onto
  the EchoMQ bus carries `@tag :valkey` (it mints a CMD job), opt-in via `mix test --include valkey`.
  """
  use ExUnit.Case, async: false

  import Plug.Conn
  import Phoenix.ConnTest

  @endpoint CodemojexWeb.Endpoint
  @secret "test-webhook-secret-cm5"
  @header "x-telegram-bot-api-secret-token"

  setup do
    prior = Application.get_env(:codemojex, CodemojexWeb.TelegramController)
    Application.put_env(:codemojex, CodemojexWeb.TelegramController, secret: @secret)

    on_exit(fn ->
      case prior do
        nil -> Application.delete_env(:codemojex, CodemojexWeb.TelegramController)
        _ -> Application.put_env(:codemojex, CodemojexWeb.TelegramController, prior)
      end
    end)

    {:ok, conn: build_conn()}
  end

  # POST a JSON Telegram update, optionally carrying the secret-token header.
  defp post_update(conn, secret_token, update) do
    conn
    |> put_req_header("content-type", "application/json")
    |> maybe_secret(secret_token)
    |> post("/api/telegram/webhook", Jason.encode!(update))
  end

  defp maybe_secret(conn, nil), do: conn
  defp maybe_secret(conn, token), do: put_req_header(conn, @header, token)

  describe "the secret-token gate (fail-closed)" do
    test "the correct secret → 200 (a chat-less update is accepted and ignored, no bus)", %{conn: conn} do
      conn = post_update(conn, @secret, %{"update_id" => 1})
      assert conn.status == 200
    end

    test "a wrong secret → 401 (ingest never runs)", %{conn: conn} do
      conn = post_update(conn, "not-the-secret", %{"update_id" => 1})
      assert conn.status == 401
    end

    test "no secret-token header → 401", %{conn: conn} do
      conn = post_update(conn, nil, %{"update_id" => 1})
      assert conn.status == 401
    end

    test "with NO secret configured the route fails closed → 401 even with a header", %{conn: conn} do
      Application.delete_env(:codemojex, CodemojexWeb.TelegramController)
      conn = post_update(conn, @secret, %{"update_id" => 1})
      assert conn.status == 401
    end
  end

  describe "the end-to-end bridge (needs the bus)" do
    @tag :valkey
    test "a /start update with the correct secret → 200 and a CMD job on the commands lane", %{conn: conn} do
      update = %{
        "update_id" => 2,
        "message" => %{
          "message_id" => 10,
          "date" => 0,
          "text" => "/start",
          "chat" => %{"id" => 555, "type" => "private"},
          "from" => %{"id" => 555, "is_bot" => false, "first_name" => "T"}
        }
      }

      # A real /start (with a chat) exercises the full bridge → Lanes.enqueue. The OLD code raised
      # here (chat id as a non-branded lane group → 500); the fixed grouped JOB enqueue returns 200.
      conn = post_update(conn, @secret, update)
      assert conn.status == 200

      # And the bridge mints a JOB on the bus (the only shape Lanes.claim can drain).
      assert {:ok, <<"JOB", _::binary>>} = Codemojex.EchoBot.ingest(update)
    end
  end
end
