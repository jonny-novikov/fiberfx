# Codemojex · Telegram Bot Inbound — Webhook vs Polling

How **@codemoji_bot** receives updates from Telegram, the two transports it can use, and the exact
steps to set up (or switch) each. The *outbound* side (the game sending messages) is covered in
[`apps/codemojex/docs/notifications.md`](../../apps/codemojex/docs/notifications.md); this document is
about the *inbound* edge — a player typing `/start`, tapping a button, etc.

> **TL;DR.** One environment variable decides everything: **`CODEMOJI_WEBHOOK_SECRET`**.
> Set it → **webhook** mode (production, scales across machines). Leave it unset → **polling**
> fallback (simplest, but exactly one machine). Either way the bot also needs **`CODEMOJI_BOT_TOKEN`**
> to send replies.

---

## 1. The two transports at a glance

Telegram offers two ways for a bot to receive updates, and they are **mutually exclusive** — the API
refuses `getUpdates` (polling) while a webhook URL is registered, and stops delivering to a webhook
once you call `getUpdates`. Codemojex supports both behind one config switch.

| | **Webhook** (push) | **Polling** (pull) |
|---|---|---|
| How | Telegram `POST`s each update to a public HTTPS URL | The app long-polls `getUpdates` in a loop |
| Who runs the loop | nobody — it's an HTTP route (`CodemojexWeb.TelegramController`) | the `echo_bot` engine's updater process |
| Machines | **any number** — Telegram hits the load balancer, Fly fans out | **exactly one** — a 2nd poller gets Telegram **409 Conflict** |
| Public URL | required (the apex `https://codemoji.games`) | not required |
| Auth | a shared **secret token** in a request header | the bot token only (no inbound surface) |
| Best for | **production** | local/dev, a quick demo, a single-machine deploy |

**Recommendation: webhook for production.** Codemojex keeps a websocket (`/socket`) for live games and
will scale past one machine; polling's single-consumer rule (one `getUpdates` per bot token) caps it at
one machine and makes a routine `fly scale count 2` silently break inbound. Webhook has neither limit.

---

## 2. How an inbound update flows

Both transports converge on the **same bus pipeline** — the only difference is the first hop.

```
                        ┌─ WEBHOOK:  Telegram ──POST /api/telegram/webhook──► CodemojexWeb.TelegramController
 a player types /start ─┤                         (secret-token header checked, constant-time, fail-closed)
                        └─ POLLING:  echo_bot updater ──getUpdates──► Codemojex.Bot.Handler
                                                                              │
                                          both call Codemojex.EchoBot.ingest/1 / bridge/1
                                                                              │  normalize + enqueue
                                                                              ▼
                                   EchoMQ bus lane   cm.bot.commands   (a JOB on its own fair lane)
                                                                              │  drained by an EchoMQ.Consumer
                                                                              ▼
                                                   Codemojex.CommandWorker.handle/1
                                                                              │  /start, /help → reply text
                                                                              ▼
                                   Codemojex.Notifier ─► cm.notify ─► Codemojex.NotificationWorker
                                                                              │  rate-limit → deliver
                                                                              ▼
                                   Codemojex.Bot.deliver/2 ─► echo_bot (vendored ex_gram) ─► Telegram
```

The inbound update is **never processed inline**. It is bridged onto the bus as a durable job and
drained by a consumer, so the HTTP/poll path stays fast and a command survives a crash. The reply
goes back out through the ordinary notification path, so it inherits the same rate limiting and
retries as every other message. The loop closes on itself: *Telegram in → the bus → Telegram out.*

---

## 3. Configuration

Two environment variables, read at boot in [`config/runtime.exs`](../../config/runtime.exs) (prod only):

| Variable | Purpose | Effect |
|---|---|---|
| `CODEMOJI_BOT_TOKEN` | the bot's API token (from @BotFather) | **outbound** — `Codemojex.Bot` resolves it to send. Unset → every send drops `:no_token` (the app still boots). |
| `CODEMOJI_WEBHOOK_SECRET` | the inbound transport switch + webhook auth | **set** → webhook mode; **unset** → polling mode. |

Both are **Fly secrets** (encrypted, never in `fly.toml` or the repo), set via `fly secrets set …` or
`fly secrets import < .env.production`. The precedence in `runtime.exs` is:

```elixir
if bot_token = System.get_env("CODEMOJI_BOT_TOKEN") do
  config :codemojex, Codemojex.Telegram, token: bot_token          # outbound, both modes

  case System.get_env("CODEMOJI_WEBHOOK_SECRET") do
    secret when is_binary(secret) and secret != "" ->
      config :codemojex, CodemojexWeb.TelegramController, secret: secret   # WEBHOOK: arm the route
                                                                           # (echo_bot updater stays :none — no poller)
    _ ->
      config :echo_bot,                                             # POLLING fallback
        updater: :polling,
        bot_config: Path.join(:code.priv_dir(:codemojex), "bots/codemoji.yaml")
  end
end
```

So the three states are: **no token** → bot fully idle (boots clean); **token only** → polling;
**token + webhook secret** → webhook.

The polling bot definition is [`apps/codemojex/priv/bots/codemoji.yaml`](../../apps/codemojex/priv/bots/codemoji.yaml)
(`name: codemoji_bot`, `token_env: CODEMOJI_BOT_TOKEN`, `handler: Codemojex.Bot.Handler`); it ships in
the release via the Dockerfile's `priv` copy and is only consulted in polling mode.

---

## 4. Setup — Webhook (production)

**Prerequisites:** the apex `codemoji.games` resolves to the app with a valid TLS cert
(`fly certs show codemoji.games -a codemojex` → *Ready*), and `CODEMOJI_BOT_TOKEN` is already a Fly secret.

1. **Generate a strong secret** (1–256 chars, `A–Z a–z 0–9 _ -`):
   ```bash
   openssl rand -hex 32
   ```
2. **Set it as a Fly secret** (and record it in the gitignored `echo/.env.production` so the two stay in sync):
   ```bash
   fly secrets set CODEMOJI_WEBHOOK_SECRET='<that value>' -a codemojex
   ```
3. **Deploy this codebase** (the webhook route is compile-time — it must be in the image, not just the secret):
   ```bash
   fly deploy -a codemojex
   ```
   Sanity-check the route is live and **fails closed** before registering it — a no-secret POST must be
   `401` (live + guarded), *not* `404` (route not deployed):
   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" -X POST https://codemoji.games/api/telegram/webhook \
     -H 'content-type: application/json' -d '{"update_id":1}'      # expect 401
   ```
4. **Register the webhook with Telegram** (reads the token + secret from `.env.production`, prints neither;
   `setWebhook` *overwrites* any previous webhook, so no `deleteWebhook` first):
   ```bash
   cd echo
   TOKEN=$(grep -hE '^CODEMOJI_BOT_TOKEN='      .env.production | head -1 | sed -E 's/^[^=]+=//; s/^["'"'"']//; s/["'"'"']$//')
   SECRET=$(grep -hE '^CODEMOJI_WEBHOOK_SECRET=' .env.production | head -1 | sed -E 's/^[^=]+=//; s/^["'"'"']//; s/["'"'"']$//')
   curl -s -X POST "https://api.telegram.org/bot${TOKEN}/setWebhook" \
     --data-urlencode "url=https://codemoji.games/api/telegram/webhook" \
     --data-urlencode "secret_token=${SECRET}" \
     -d "drop_pending_updates=true"
   ```
5. **Verify:**
   ```bash
   curl -s "https://api.telegram.org/bot${TOKEN}/getWebhookInfo"     # url = the apex, pending=0, no last_error_message
   ```
   Then send `/start` to **@codemoji_bot** → expect *"Welcome to Codemoji. Tap the button to play."*
   That single round-trip exercises the entire loop (webhook → bus → CommandWorker → reply → Telegram).

---

## 5. Setup — Polling (single machine)

Use this for local/dev or a deliberately single-machine deploy.

1. **Ensure no webhook secret** is set (its presence forces webhook mode):
   ```bash
   fly secrets unset CODEMOJI_WEBHOOK_SECRET -a codemojex      # if it was ever set
   ```
2. **Pin to one machine** — polling allows exactly one `getUpdates` consumer per bot token:
   ```bash
   fly scale count 1 -a codemojex
   ```
3. **Clear any registered webhook** (Telegram won't poll while a webhook is set):
   ```bash
   curl -s "https://api.telegram.org/bot${TOKEN}/deleteWebhook"
   ```
4. **Deploy.** With `CODEMOJI_BOT_TOKEN` set and no webhook secret, `runtime.exs` boots the `echo_bot`
   engine in `updater: :polling` against `codemoji.yaml`. Send `/start` to verify.

> **In dev** (`mix`), polling is the default (`config/dev.exs` sets `updater: :polling`). With the
> token env var unset, `echo_bot` logs a warning and starts no bot — the app still boots.

---

## 6. Switching transports

| From → To | Steps |
|---|---|
| **Polling → Webhook** | `fly secrets set CODEMOJI_WEBHOOK_SECRET=… ` → `fly deploy` → `setWebhook(url, secret_token)`. (setWebhook stops polling automatically.) |
| **Webhook → Polling** | `fly secrets unset CODEMOJI_WEBHOOK_SECRET` → `fly scale count 1` → `fly deploy` → `deleteWebhook`. |

Always change the **Fly secret** and the **Telegram registration** together — a half-switch (e.g. a
webhook still registered while the app polls) yields a 409 and a silent inbound stall.

---

## 7. Operations & troubleshooting

- **`getWebhookInfo`** is the source of truth for the inbound state:
  ```bash
  curl -s "https://api.telegram.org/bot${TOKEN}/getWebhookInfo"
  ```
  - `url` empty → polling (or unset); `url` = the apex → webhook.
  - `pending_update_count` climbing → updates aren't being accepted (the endpoint is erroring or down).
  - `last_error_message` / `last_error_date` → Telegram's last failed delivery (e.g. a TLS or 5xx error).
- **404 on the webhook route** → the **code isn't deployed** (a Fly *secret* restart reuses the old image;
  the route is compile-time). Run `fly deploy`. Confirm with the no-secret `curl` → `401`.
- **401 with the right secret** → the Fly secret and the value you're sending differ. Reconcile
  `CODEMOJI_WEBHOOK_SECRET` (Fly) with `.env.production`, redeploy.
- **409 Conflict** in logs (polling) → a second poller is running. With webhook, this means a webhook is
  still registered — `deleteWebhook`. With polling, scale to one machine.
- **`/start` reaches the bus but no reply** → the outbound token. `Codemojex.Bot.token/0` must resolve
  `CODEMOJI_BOT_TOKEN`; an unset token drops sends with `:no_token`.
- **Liveness ≠ inbound.** `/api/health` is DB/bus-less and stays `200` even if inbound is broken —
  verify with `getWebhookInfo` and a real `/start`, never the health check.

---

## 8. Under the hood (the bus contract)

The bridge enqueues each inbound command as a branded **`JOB`** that is **its own lane group**:

```elixir
job_id = EchoData.BrandedId.generate!("JOB")
EchoMQ.Lanes.enqueue(Bus.conn(), "cm.bot.commands", job_id, job_id, payload)
```

This is deliberate, and it mirrors the shipped scoring path. An `EchoMQ.Consumer` claims via
`EchoMQ.Lanes.claim/3`, which rotates a **ring of branded groups** and pops `g:<group>:pending` — it
is the *only* enqueue shape a consumer drains. A lane group **must be a valid branded id**
(`EchoMQ.Lanes.lane_key!` raises otherwise), so a raw Telegram chat id cannot be a lane key; giving
each job its own `JOB`-id lane yields round-robin fairness across commands (no chat can starve another).
Per-chat *ordering* is not preserved, which is fine — the bot's commands are independent. The same
shape backs the outbound notifications (`Codemojex.Notifier`).

> **Known limitation.** `Codemojex.NotificationWorker`'s rate-limit **defer** and delivery **retry**
> re-enqueue via the *scheduled/plain* half of EchoMQ (`Jobs.enqueue_in`), which the grouped consumer
> does not claim. This only fires under per-chat bursts (≥2 messages/sec to one chat) or transient send
> failures — not the normal `/start` path — so the bot works. A proper fix is a **grouped delayed
> re-enqueue** (or a lease-expiry-based defer); it should land before the bot sees sustained load.

---

## 9. Reference

**Code**
- `config/runtime.exs` — the env switch + precedence.
- `apps/codemojex/lib/codemojex_web/controllers/telegram_controller.ex` — the webhook receiver (secret gate).
- `apps/codemojex/lib/codemojex_web/router.ex` — `POST /api/telegram/webhook`.
- `apps/codemojex/lib/codemojex/echo_bot.ex` — `ingest/1` (webhook entry) + `bridge/1` (normalize → bus).
- `apps/codemojex/lib/codemojex/bot.ex` — `Codemojex.Bot.deliver/2` (outbound) + `Codemojex.Bot.Handler` (polling entry).
- `apps/codemojex/lib/codemojex/command_worker.ex` — drains `cm.bot.commands`, dispatches `/start` `/help`.
- `apps/codemojex/priv/bots/codemoji.yaml` — the polling bot definition.
- `apps/echo_bot/` — the YAML-driven engine (polling updater, vendored ex_gram client).

**Telegram API**
- [setWebhook](https://core.telegram.org/bots/api#setwebhook) · [getWebhookInfo](https://core.telegram.org/bots/api#getwebhookinfo) · [deleteWebhook](https://core.telegram.org/bots/api#deletewebhook)
- [Marking updates as received / webhook vs getUpdates](https://core.telegram.org/bots/api#getting-updates)
- [A guide to webhooks](https://core.telegram.org/bots/webhooks)
