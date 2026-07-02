---
name: codemojex-telegram-bot-and-grouped-enqueue
description: "codemojex Telegram bot wiring (webhook vs polling, @codemoji_bot) + the echo_mq grouped-enqueue contract a consumer MUST use (Lanes.enqueue branded-group + JOB id; plain Jobs.enqueue/schedule is NOT claimed by the grouped consumer) — the notification/command layer was broken against the live bus until fixed"
project: echo_mq
metadata: 
  node_type: memory
  type: project
  originSessionId: dfc9537d-f90d-4421-9f93-ca7810fa2c6b
---

Two linked facts surfaced wiring `echo_bot` inbound for codemojex (2026-06-26).

## The echo_mq grouped-enqueue contract (load-bearing; consumers drain ONLY this)

`EchoMQ.Consumer` claims via **`EchoMQ.Lanes.claim/3`** → the `@gclaim` script rotates a **ring of groups** (`emq:{q}:ring`) and pops `emq:{q}:g:<group>:pending`. It **never reads the global `emq:{q}:pending`**. So:

- **The only claimable enqueue is `Lanes.enqueue(conn, queue, GROUP, JOB_ID, payload)`** where `GROUP` is a **valid branded id** (`lane_key!` raises `"a lane is named by a valid branded id"` otherwise) and `JOB_ID` is **`JOB`-namespaced** (`EchoData.BrandedId.generate!("JOB")`). It RPUSHes the group onto the ring → claimable.
- **`EchoMQ.Jobs.enqueue` / `enqueue_in` / `enqueue_at`** write to the **global `pending`** / `schedule` set (and require a `JOB`-prefixed id — the Lua rejects non-`JOB`). `Jobs.promote` moves scheduled→global `pending`. **None of this is claimed by the grouped consumer** — it's a different (plain) claim model.
- The shipped, CORRECT pattern is `Codemojex.Game`: `job = generate!("JOB"); Lanes.enqueue(Bus.conn(), @queue, player_or_game_id, job, payload)` (group = a branded PLR/GAM). `scoring_story` proves it.

## codemojex notification/command layer was broken against the live bus (FIXED)

`Codemojex.EchoBot.bridge/1` and `Codemojex.Notifier.notify/3` keyed lanes by a **raw chat id** (`to_string(chat)`, not branded) and minted `CMD`/`NOT` ids → `Lanes.enqueue` **RAISED** on the first real update. Never caught because the `:valkey` tests covered scoring/settlement/economy/auth but **not** the notification/command bus path (inbound was never wired: `updater: :none`, no webhook route). **Fix (committed in-tree, uncommitted at write):** both now use `job_id = generate!("JOB")` as **both** the job id **and** the lane group (per-job lane → ring round-robin fairness; per-chat ordering NOT preserved, fine for independent bot commands/notifications). Full suite 86/0 after the fix.

- **STILL OPEN (pre-existing, flagged not fixed):** `Codemojex.NotificationWorker.requeue` (rate-limit defer / delivery retry) uses `Jobs.enqueue_in` (plain/scheduled → global pending) → NOT re-claimed by the grouped consumer. Only fires under per-chat bursts (≥2/s) or send retries. Needs a real grouped-delayed re-enqueue (or lease-expiry defer). DON'T naively swap to a JOB id + enqueue_in — that turns "eventually delivers via crash-retry" into "silently dropped."

## The bot wiring (cm.5)

- **@codemoji_bot** (id 8358401951). Token `CODEMOJI_BOT_TOKEN` (Fly secret, deployed) arms OUTBOUND (`Codemojex.Bot.token/0` reads `config :codemojex, Codemojex.Telegram, :token`).
- **INBOUND transport chosen in `config/runtime.exs` by `CODEMOJI_WEBHOOK_SECRET`:** SET → **webhook** mode (`CodemojexWeb.TelegramController` at `POST /api/telegram/webhook`, secret-token header constant-time checked, fail-closed; `echo_bot` updater stays `:none`, no poller → scales across machines). UNSET → **polling** fallback (`echo_bot` `updater: :polling`, `bot_config` = codemojex priv `bots/codemoji.yaml` → `Codemojex.Bot.Handler`; SINGLE machine only — a 2nd getUpdates poller gets Telegram 409).
- Bot definition `apps/codemojex/priv/bots/codemoji.yaml` (`name: codemoji_bot`, `token_env: CODEMOJI_BOT_TOKEN`, `handler: Codemojex.Bot.Handler`) ships via the Dockerfile `priv` copy.
- Register: `setWebhook(url: "https://codemoji.games/api/telegram/webhook", secret_token: <CODEMOJI_WEBHOOK_SECRET>)` — overwrites the stale `codemoji-game.fly.dev` webhook (one webhook per bot). Loop: webhook → `EchoBot.ingest/1`→`bridge` → bus lane `cm.bot.commands` → `CommandWorker` → reply via `Notifier` → `cm.notify` → `NotificationWorker` → `EchoBot.deliver` → Telegram.

Related: [[echomq-3-0-0-wire-cutover]] [[codemojex-program]] [[echo-mq-three-movements]]
