defmodule CodemojexWeb.KeyShopControllerTest do
  @moduledoc """
  The cm.7 KeyShop web surface: the create-order route (`POST /api/keys/buy`, now
  `{package_id, rail}` only — S6/A6) and the Stars invoice flow over the secret-gated
  `POST /api/telegram/webhook` — the `pre_checkout_query` tamper guard (S7/A7) and the
  `successful_payment` → `settle_payment/1` exactly-once settlement. Integration: needs the
  app, Postgres, and a Valkey on $VK_PORT (`mix test --include valkey`). The Telegram
  transport is injected (no network).
  """
  use ExUnit.Case, async: false
  @moduletag :valkey

  import Plug.Conn
  import Phoenix.ConnTest
  import Ecto.Query

  alias Codemojex.{Repo, AuthHelper}
  alias Codemojex.Schemas.{Order, RevenueLedger, OrderTransaction}

  @endpoint CodemojexWeb.Endpoint
  @secret "test-webhook-secret-cm7"
  @header "x-telegram-bot-api-secret-token"
  @rates %{"stars_usd" => 130, "ton" => 3_846_154, "usdt" => 10_000, "rub" => 90}

  setup do
    prior_ctl = Application.get_env(:codemojex, CodemojexWeb.TelegramController)
    Application.put_env(:codemojex, CodemojexWeb.TelegramController, secret: @secret)
    prior_rates = Application.get_env(:codemojex, :key_shop_rates)
    Application.put_env(:codemojex, :key_shop_rates, @rates)

    on_exit(fn ->
      restore(CodemojexWeb.TelegramController, prior_ctl)
      restore(:key_shop_rates, prior_rates)
    end)

    {:ok, conn: build_conn()}
  end

  defp restore(key, nil), do: Application.delete_env(:codemojex, key)
  defp restore(key, val), do: Application.put_env(:codemojex, key, val)

  defp authed(conn, plr), do: put_req_header(conn, "authorization", "Bearer " <> AuthHelper.put_session_for(plr))
  defp a_package, do: Enum.find(Codemojex.key_packages(), &(&1.keys == 100))

  describe "POST /api/keys/buy — the create-order route ({package_id, rail} only, S6/A6)" do
    test "creates an ORD and mints NO keys; the client never supplies the key count", %{conn: conn} do
      {:ok, plr} = Codemojex.create_player("Shopper", keys: 0)
      pkg = a_package()

      resp =
        conn
        |> authed(plr)
        |> post("/api/keys/buy", %{"package_id" => pkg.id, "rail" => "stars"})
        |> json_response(200)

      assert resp["order"]["rail"] == "stars"
      assert resp["order"]["keys"] == 100
      assert resp["order"]["price_minor"] == 1449
      assert resp["order"]["status"] == "created"
      # no keys minted on create — minting is reachable only from settle_payment/1
      assert Codemojex.balance(plr).keys == 0
    end

    test "a client-supplied key count without a package_id is REJECTED (no free-key path)", %{conn: conn} do
      {:ok, plr} = Codemojex.create_player("Cheater", keys: 0)

      conn
      |> authed(plr)
      |> post("/api/keys/buy", %{"keys" => 999, "ref" => "stars"})
      |> json_response(400)

      assert Codemojex.balance(plr).keys == 0
    end
  end

  describe "the Stars invoice flow over /api/telegram/webhook" do
    setup do
      # capture outbound Telegram calls (answerPreCheckoutQuery) without a network
      test_pid = self()
      prior = Application.get_env(:codemojex, Codemojex.Telegram)

      Application.put_env(:codemojex, Codemojex.Telegram,
        token: "test-bot-token:cm7",
        http_fun: fn url, payload ->
          send(test_pid, {:tg, url, Jason.decode!(payload)})
          {:ok, 200, Jason.encode!(%{"ok" => true, "result" => true})}
        end
      )

      on_exit(fn ->
        case prior do
          nil -> Application.delete_env(:codemojex, Codemojex.Telegram)
          _ -> Application.put_env(:codemojex, Codemojex.Telegram, prior)
        end
      end)

      :ok
    end

    test "pre_checkout with the pinned amount → ok: true; a tampered amount → ok: false (the tamper guard, S7)" do
      {:ok, plr} = Codemojex.create_player("PreCk", keys: 0)
      {:ok, order} = Codemojex.create_order(plr, a_package().id, "stars")

      post_webhook(%{
        "pre_checkout_query" => %{
          "id" => "q1",
          "invoice_payload" => order.id,
          "total_amount" => order.price_minor,
          "currency" => "XTR"
        }
      })

      assert_receive {:tg, url, body}
      assert url =~ "answerPreCheckoutQuery"
      assert body["ok"] == true

      post_webhook(%{
        "pre_checkout_query" => %{
          "id" => "q2",
          "invoice_payload" => order.id,
          "total_amount" => order.price_minor + 1,
          "currency" => "XTR"
        }
      })

      assert_receive {:tg, _url, body2}
      assert body2["ok"] == false
    end

    test "a successful_payment settles the order — keys minted, revenue booked, exactly once" do
      {:ok, plr} = Codemojex.create_player("Payer", keys: 0)
      {:ok, order} = Codemojex.create_order(plr, a_package().id, "stars")
      charge = "tg_charge_" <> order.id

      sp = %{
        "message" => %{
          "successful_payment" => %{
            "invoice_payload" => order.id,
            "telegram_payment_charge_id" => charge,
            "total_amount" => order.price_minor,
            "currency" => "XTR"
          }
        }
      }

      # deliver twice — the OTX (rail, external_id) gate makes the replay a no-op
      assert post_webhook(sp).status == 200
      assert post_webhook(sp).status == 200

      assert Codemojex.balance(plr).keys == 100
      assert Repo.get(Order, order.id).status == "paid"
      assert purchase_revenue_rows(order.id) == [order.price_minor]
      assert otx_count(order.id) == 1
    end
  end

  # --- helpers ---------------------------------------------------------------

  # A fresh conn per webhook POST (a sent conn does not carry arbitrary req headers across a
  # recycle); the webhook is stateless (secret-gated, no session).
  defp post_webhook(update) do
    build_conn()
    |> put_req_header("content-type", "application/json")
    |> put_req_header(@header, @secret)
    |> post("/api/telegram/webhook", Jason.encode!(update))
  end

  defp purchase_revenue_rows(order_id) do
    Repo.all(from r in RevenueLedger, where: r.ref == ^order_id and r.reason == "purchase", select: r.delta)
  end

  defp otx_count(order_id) do
    Repo.one(from o in OrderTransaction, where: o.order_id == ^order_id, select: count(o.id))
  end
end
