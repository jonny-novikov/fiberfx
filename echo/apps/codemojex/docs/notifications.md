# Codemojex · Notifications

Codemojex's notification system carries every message between the game and a player's Telegram chat — a round result, a prize, a Golden Room win, a reply to a command. It is built on the EchoMQ bus and delivered through the `echo_bot` engine, so the umbrella speaks to Telegram through one owned, vendored client rather than a bespoke transport. This document describes the system end to end: the outbound path, the inbound path, how game events reach a player, and the configuration that turns it on. It is written against the source in `apps/codemojex`.

The shape to hold in mind: a notification is never sent inline on a request or a worker's hot path. It is enqueued as a branded job on a fair lane, drained by a rate-limited worker, and delivered through `echo_bot`. Every step is durable on the bus, so a notification is deferred or retried, never silently lost, and a burst from one chat cannot starve another.

## Why echo_bot

`echo_bot` is the umbrella's Telegram bot engine: a config-driven app that loads a bot from a YAML v1.0 definition, polls or receives updates, normalizes them to a platform-neutral shape, routes them to a handler, and sends replies through a vendored ex_gram client wrapped behind one module. Codemojex plugs into it on both sides. Outbound, the notification worker delivers through `EchoBot.Platform.Telegram.send_reply/3`. Inbound, `echo_bot`'s updater routes normalized updates to `Codemojex.Bot.Handler`, which bridges them onto the bus. The vendored client is named in exactly one place — `EchoBot.Platform.Telegram` — so the dependency on a copied library stays behind a wrap the rest of the game never touches.

`echo_bot` boots its own supervision tree as a dependency, independent of the rest of the umbrella. Its updater mode defaults to `:none`, so adding it changes nothing until it is configured: the engine comes up idle, and only the outbound send path is exercised until an updater is enabled.

## The outbound path

A notification travels four steps from the game to Telegram:

```
Codemojex.Notifier.notify(chat, text)
        │  mint a NOT id, enqueue on a fair lane keyed by chat
        ▼
EchoMQ lane  cm.notify   (one lane per chat)
        │  drained by an EchoMQ.Consumer
        ▼
Codemojex.NotificationWorker.handle/1
        │  rate-limit → deliver → classify (ack | defer | retry | drop)
        ▼
Codemojex.EchoBot.deliver/3 → Codemojex.Bot.deliver/2
        │
        ▼
EchoBot.Platform.Telegram.send_reply(token, chat, text)   (vendored ex_gram → Telegram)
```

**`Codemojex.Notifier`** is the enqueue side — what the game calls to send a message without touching Telegram or the rate limiter. It mints a `NOT` branded id (typed and time-ordered), encodes the chat, text, and attempt as JSON, and enqueues it on a lane keyed by the chat id. The call does one enqueue and no network work, so a caller is never blocked on delivery. Wording lives in one place: `round_result/3`, `prize_won/3`, and `golden_win/4` are thin wrappers that format the text.

**`Codemojex.NotificationWorker`** drains the `cm.notify` queue and applies three layers of control. Fairness is the per-chat lane, so one chat's burst cannot starve others. Rate is a token taken from `Codemojex.RateLimiter` (a token bucket, roughly global and per-chat); when a chat is over budget the worker does not block — it re-enqueues the same notification with `EchoMQ.Jobs.enqueue_in/5` after the bucket's reported wait and acks, so the notice stays durable on the bus, deferred rather than dropped. Delivery is the verdict the send returns: an ack releases the lease, a transient failure is retried with capped exponential backoff up to a bounded number of attempts, and a give-up is dropped with a log.

**`Codemojex.Bot`** is the send seam over `echo_bot`. It resolves the bot token, calls `send_reply`, and turns the result into the verdict the worker classifies — `:ok` for a delivered message, `{:retry, reason}` for any send error, and `{:drop, :no_token}` when no token is configured. Because the vendored client reports a send as success or an opaque error rather than an HTTP status, the classification is coarse: an error is treated as transient and retried, and the worker's attempt cap turns a truly permanent failure (a blocked bot) into a bounded handful of retries before it drops. The cap, not a status code, is the backstop.

One caveat is worth stating plainly: `send_reply` carries text only. Per-message options a richer client would forward — a parse mode, an inline keyboard — are not sent through this path. Notifications are plain text; a future need for rich replies would extend the wrap, not the call sites.

## The inbound path

An inbound update — a player typing `/start`, or any command — flows the mirror image:

```
echo_bot updater (polling or webhook)
        │  decode + normalize to EchoBot.Platform.Update
        ▼
Codemojex.Bot.Handler.handle/1
        │  bridge the normalized update onto the bus, reply :noreply
        ▼
Codemojex.EchoBot.bridge/1  →  EchoMQ lane  cm.bot.commands  (one lane per chat)
        │  drained by an EchoMQ.Consumer
        ▼
Codemojex.CommandWorker.handle/1  →  dispatch  →  Codemojex.Notifier (the reply)
```

`Codemojex.Bot.Handler` is the `EchoBot.Handler` named in the bot's YAML. Rather than answer in the updater, it bridges the normalized update onto the bus and returns `:noreply`, so a command is handled durably and per-chat ordered by `Codemojex.CommandWorker`, with the slow parts (a database read, a reply) off the updater's path. A webhook deployment can reach the same bus through `Codemojex.EchoBot.ingest/1`, which decodes a raw Telegram map, normalizes it through the same `echo_bot` step, and bridges it — so both entry points produce one normalized job shape on the lane.

`Codemojex.CommandWorker` is a deliberately small dispatcher over that shape: `/start` and `/help` reply with static text, and anything else is logged and ignored. The reply goes back out through `Codemojex.Notifier`, so an inbound command's answer inherits the same fair lane, rate limit, retries, and `echo_bot` delivery as every other outbound message. The loop closes on itself: `echo_bot` in, the bus, `echo_bot` out.

## Game events reach a player

A round result and a prize are game events, raised deep in the scoring and settlement systems, not at a request edge. To deliver one, the system needs the player's Telegram chat — and a player is a branded `USR`, not a chat. The link is `players.tg_chat_id`, a nullable column set when a player is created (from the verified launch data in production); `Codemojex.Store.chat_of/1` resolves a player to their chat, or `nil` if they registered without one, in which case they receive no push.

Settlement uses this directly. When a round closes and the winner-take-all payout is deposited, the closer looks up the winner's chat and, if present, sends a prize notification — a `golden_win` for a Golden Room, a `prize_won` otherwise — through the ordinary notifier path. A player with no chat on file is paid all the same; the diamonds are the system of record, the notification is the courtesy. This is the one place the notification system and the money system meet, and they meet only through the chat lookup and the notifier — settlement never calls Telegram.

## Configuration

The system has two configuration surfaces, and the outbound path needs only the first.

The token for the outbound send is read at send time from application config:

```elixir
config :codemojex, Codemojex.Telegram, token: System.get_env("CODEMOJI_BOT_TOKEN")
```

With no token, a send returns `{:drop, :no_token}` and is logged — the app boots and runs without it, which is the dev default.

The inbound engine is opt-in. To run it, point `echo_bot` at the Codemoji bot definition and choose an updater:

```elixir
config :echo_bot,
  updater: :polling,
  bot_config: Path.join(:code.priv_dir(:codemojex), "bots/codemoji.yaml")
```

The bot definition (`apps/codemojex/priv/bots/codemoji.yaml`) is a YAML v1.0 file naming the platform, the handler, and the environment variable the token lives in — never the token itself:

```yaml
version: "1.0"
name: codemoji
platform: telegram
token_env: CODEMOJI_BOT_TOKEN
handler: Codemojex.Bot.Handler
```

`echo_bot` resolves `token_env` to the live value at boot, selects the Telegram adapter, and resolves the handler to `Codemojex.Bot.Handler` — loaded in the release because both apps ship in the same umbrella. With `updater: :none` (the base default) the engine boots idle and only the outbound path runs.

## Fault tolerance

The notification system inherits EchoMQ's discipline. Delivery is at-least-once, and a `NOT` id makes a duplicate rare and harmless — the same notice is at worst delivered twice, never lost. A consumer leases each job, so a crash makes the in-flight notification visible again rather than dropping it. Rate-limit deferrals and delivery retries are both re-enqueues on the bus, durable across a restart. The worker never blocks the consumer: over budget it defers, on a transient error it backs off, and on a permanent failure it drops after a bounded number of attempts. A failure to reach Telegram degrades a single notification, never the game.

## References

- [Telegram Bot API — sendMessage](https://core.telegram.org/bots/api) — the send the vendored client wraps.
- [Telegram — Mini Apps (validating WebApp data)](https://core.telegram.org/bots/webapps) — the verified launch data a player's chat is bound from.
- [Kreps — The Log (LinkedIn Engineering)](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying-abstraction) — the bus the notification is durable on.
- [Phoenix — Channels](https://hexdocs.pm/phoenix/channels.html) — the live round topic a golden win is also broadcast on.
- [Valkey — Persistence (RDB and the append-only file)](https://valkey.io/topics/persistence/) — the durable substrate beneath the queues.
- [Erlang/OTP — the gen_server behaviour](https://www.erlang.org/doc/apps/stdlib/gen_server.html) — the consumers, the rate limiter, and the bot gateway.
- [Erlang/OTP — the supervisor behaviour](https://www.erlang.org/doc/apps/stdlib/supervisor.html) — the trees that restart a crashed worker in isolation.
