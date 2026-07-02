# Codemojex course · C7 — The Live Surface on Phoenix

> **Route** `/codemojex/the-live-surface` · **stub shipped** — this manuscript is the chapter brief;
> the C7 authoring rung deepens both.
> **Sources** B7.6.1–.2 · **cm.4 folded in as dive 1** ([`../cm.4.md`](../cm.4.md)) · design
> §The web surface. (B7.6.3, production, is promoted to [`C8`](course.8.md).)

The surface is a thin Phoenix application, deliberately small: every call goes through the
`Codemojex` facade and the privacy-safe views, a guess returns accepted-and-on-its-way while the bus
carries the scoring, and there is no process per room — a large field of idle rooms costs nothing.
The chapter opens at the entry seam cm.4 closed: identity is verified, never trusted.

## C7.1 · The auth floor

Telegram `initData`, verified by the pure `Codemojex.InitData` HMAC-SHA-256 check (the bot token
keyed by the constant `WebAppData`); the handshake `POST /api/auth/:platform` — the sole `SES` mint —
resolves-or-creates the player by `tg_user_id`; the session lives in Valkey through a mutable
`EchoStore.Table` with `:tracking` coherence, so revocation is immediate; the `:auth` plug and the
socket read `conn.assigns.player`. The old unauthenticated mint (`POST /api/players`) is retired —
the free-money gap closed. Dive route: `/codemojex/the-live-surface/the-auth-floor` (planned).

## C7.2 · The JSON API

The lifecycle under `/api`: health, the auth handshake, the room lobby, joining a room, the game
view, submitting a guess, a player's own history, the leaderboard, and the key operations (buy and
convert) — each shaped by a privacy-safe view that never selects the secret and, for a golden game,
exposes the commitment but never its preimage. Dive route:
`/codemojex/the-live-surface/the-json-api` (planned).

## C7.3 · Channels and PubSub

A client joins `game:<id>`, which subscribes the channel to the matching PubSub topic. Classic: the
scoring worker's `scored` event pushes live and the board updates with no per-room process. Golden:
the channel carries state and timer only until the sealed reveal pushes one fat `revealed` event —
the secret, the final board, the payouts. Joins return the view, never the secret. Dive route:
`/codemojex/the-live-surface/channels-and-pubsub` (planned).

## Grounding

- `echo/apps/codemojex/lib/codemojex/init_data.ex` · `session.ex` ·
  `lib/codemojex_web/{auth.ex,mini_app_auth.ex,router.ex,channels/}` · `view.ex`.
- [`../cm.4.md`](../cm.4.md) (the auth floor) · [`codemojex.design.md`](../../codemojex.design.md)
  §The web surface / §Privacy and fairness · [`../../kb/auth-flow/`](../../kb/auth-flow/).
- [`stories/privacy.stories.md`](../../stories/privacy.stories.md).

## Doors

[/bcs](/bcs) — surfaces are peers joined by the thread · [`C6`](course.6.md) ← · → [`C8`](course.8.md).
