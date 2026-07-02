# Codemojex course · C4 — Scoring and Settlement

> **Route** `/codemojex/scoring-and-settlement` · **stub shipped** — this manuscript is the chapter
> brief; the C4 authoring rung deepens both.
> **Sources** B7.4 **reconciled linear-only** (the tier `[RECONCILE]` is closed) · cm.1 + cm.3
> (sealed top-K) + cm.5 (`close_split`/`close_void`, the sweep) · design §The data model /
> §Core flows (settlement, exactly once).

The score is linear and only linear: distance is the absolute gap between a guessed position and the
secret's, each position earns `100 − 20·d` (an emoji not in the code earns zero), and the six
positions sum to a total out of 600. There are no tiers and no bonus — the leaderboard ranks the raw
best total, so the score a player sees is the score they earned. Settlement is a strategy the game
selects, and every strategy closes exactly once behind the same one-shot lock.

## C4.1 · Distance and points

The per-position law: `100, 80, 60, 40, 20, 0` by distance, zero for an absent emoji. Scoring is
pure — a re-scored guess is identical — which is what makes at-least-once delivery harmless. Dive
route: `/codemojex/scoring-and-settlement/distance-and-points` (planned).

## C4.2 · The total out of 600

The six position points sum to the guess's total; a player's best total feeds the `cm:<game>:base`
hash and the board ZSET. A perfect 600 closes a classic game there and then. No `tier`, no
`percentage` column — the linear `points` is the sole stored score. Dive route:
`/codemojex/scoring-and-settlement/the-total-out-of-600` (planned).

## C4.3 · Settlement strategies

A game closes on a perfect crack (classic only) or the timer, and the two can race: the close path
takes `SET cm:<game>:closed NX`, and only the winner of the SET settles. Three strategies: `live`
pays the diamond pool winner-take-all to the top scorer; `sealed` reveals the secret and nonce,
scores every guess against the revealed secret, and pays the top K by the snapshotted `payout_split`
(default `[40,25,15,12,8]`, integer-division dust to rank 1); the Golden Room's `live_split`
(cm.5) reuses the same top-K split math over a buy-in-funded pool, pays live, and grants consolation
clips (`max_score/10`) — with `close_void` refunding buy-ins exactly once if the gather never fills,
and the periodic sweep (`Codemojex.Sweep`) driving both timer-close and void. Dive route:
`/codemojex/scoring-and-settlement/settlement-strategies` (planned).

## Grounding

- `echo/apps/codemojex/lib/codemojex/scoring.ex` · `economy.ex` (`top_k_split`) · `game.ex`
  (ScoreWorker + Settle) · `board.ex` (the ZSET board) · `sweep.ex` · `rooms.ex` (`close_split` /
  `close_void`).
- [`codemojex.design.md`](../../codemojex.design.md) §The data model (games, guesses, the keyspace) /
  §Core flows (settlement, exactly once).
- [`stories/scoring.stories.md`](../../stories/scoring.stories.md) ·
  [`stories/settlement.stories.md`](../../stories/settlement.stories.md) ·
  [`stories/golden-blind.stories.md`](../../stories/golden-blind.stories.md) ·
  [`stories/golden-tournament.stories.md`](../../stories/golden-tournament.stories.md).

## Reconcile notes

B7.4 was titled "Scoring, **Tiers**, and Settlement" and described thirty tiers over twenty-point
gaps — the first-mover bonus-tier mechanic the engine **removed** (Operator-ruled: linear score
only). This chapter and its dives are written linear-only end to end; the roadmap's tier
`[RECONCILE]` closed with this canon.

## Doors

[/redis-patterns](/redis-patterns) — `SET NX` locks and ZSET boards applied · [`C3`](course.3.md) ← ·
→ [`C5`](course.5.md).
