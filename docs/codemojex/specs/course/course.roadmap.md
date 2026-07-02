# Codemojex — the course · Roadmap + grounding contract

The plan for the standalone `/codemojex` course and the contract every page is authored under. The
course teaches the **shipped** engine (`cm.1`–`cm.7`) as-built; the one forward surface it carries is
the `cm.8+` ladder (cash-out, the rake, `RMP` membership), stated forward-tense wherever named. The
map is [`course.toc.md`](course.toc.md); the dashboard is [`course.progress.md`](course.progress.md).

## The ladder (C0–C8)

| # | Chapter | Slug | Sources reconciled | Grounding (code · canon · stories) |
|---|---------|------|--------------------|------------------------------------|
| C0 | Overview | `overview` | roadmap + design intro §§ | `game.ex` (the `Codemojex` facade) · design §The engine / §The game in one paragraph / §The architecture at a glance · `rooms-and-games.stories.md` |
| C1 | The Game as Branded Systems | `branded-systems` | B7.1 · cm.1 | `wire.ex` · the 11 `schemas/*.ex` · `tables.ex` · `view.ex` · design §Identity · `privacy.stories.md` |
| C2 | Rooms, Modes, and the Secret | `rooms-and-modes` | B7.2 · cm.1 + cm.3 | `rooms.ex` · `emoji_set.ex` · `schemas/{room,emoji_set,game}.ex` · design §The engine / §The data model · `emoji-codes` + `golden-blind` + `rooms-and-games` stories |
| C3 | Guesses on Fair Lanes | `guesses-on-fair-lanes` | B7.3 · cm.1 | `game.ex` (`Codemojex.Guesses`) · `locks.ex` · `rate_limiter.ex` · design §Messaging / §Core flows · `scoring.stories.md` (the submit path) |
| C4 | Scoring and Settlement | `scoring-and-settlement` | B7.4 **linear-only** · cm.3 + cm.5 | `scoring.ex` · `economy.ex` (`top_k_split`) · `game.ex` (ScoreWorker + Settle) · `board.ex` · `sweep.ex` · `scoring` + `settlement` + `golden-blind` + `golden-tournament` stories |
| C5 | The Economy and the Bank | `the-economy` | B7.5 · cm.1 + cm.5 | `wallet.ex` · `economy.ex` · `ledger.ex` · `schemas/{player,transaction}.ex` · [`../economy/economy.md`](../economy/economy.md) §8 · `wallet` + `economy` + `golden-economy` + `golden-tournament` stories |
| C6 | The Revenue Ledger and the KeyShop | `commerce` | **extension** — cm.6 + cm.7 shipped; cm.8 forward | `key_shop.ex` · `rails.ex` · `schemas/{package,order,order_transaction,webhook,revenue_ledger}.ex` · `wallet.ex` (`house_post`/`house_balance`) · [`../cm.6.md`](../cm.6.md) + [`../cm.7.md`](../cm.7.md) · `revenue-ledger` + `keyshop` stories · [`../../kb/revenue-model/`](../../kb/revenue-model/) |
| C7 | The Live Surface on Phoenix | `the-live-surface` | B7.6.1–.2 · **cm.4 folded in as dive 1** | `init_data.ex` · `session.ex` · `codemojex_web/{auth.ex,mini_app_auth.ex,router.ex,channels/}` · [`../cm.4.md`](../cm.4.md) · design §The web surface · `privacy.stories.md` · [`../../kb/auth-flow/`](../../kb/auth-flow/) |
| C8 | Production Deployment | `production` | **extension** — B7.6.3 promoted + design §Fault tolerance / §Production deployment / §The pragmatic Valkey node / §Configuration | `application.ex` (the supervision tree) · design §§ above |

The **Golden Room tournament (cm.5)** is deliberately not a chapter — modes are policy, so it threads
the arc: C2 (the `golden` marker vs the blind `golden` type), C4 (`close_split`, the third settlement),
C5 (`Wallet.buy_in`, the buy-in-funded pool, the consolation clips).

## The B7 → C reconcile map (the deltas, recorded honestly)

| Delta | What changed | Where |
|---|---|---|
| Tiers → linear | B7.4 ("Scoring, **Tiers**, and Settlement", "the thirty tiers") described the removed bonus-tier mechanic; the engine scores linearly, `100 − 20·d` out of 600, no tiers, no bonus. The course is written linear-only end to end. | C4; the roadmap's tier `[RECONCILE]` is closed |
| Auth folded in | cm.4 (verified `initData` → the `SES` session) shipped after the arc was written; it is the surface's entry seam, so it opens the live-surface chapter. | C7.1 |
| Commerce added | cm.6 (the `RVL` revenue ledger) and cm.7 (the KeyShop) shipped after the arc; neither had a module. They are the new C6. | C6 (extension) |
| Production promoted | B7.6.3 ("Production on Fly") grew into its own chapter over design §Fault tolerance + §Production deployment + §The pragmatic Valkey node. | C8 (extension) |
| Golden Room shipped | The arc predates cm.5; the design's forward-tense Golden Room is reconciled to as-built and threads C2/C4/C5. | canon reconcile (this rung) |
| Forward-tense law | cm.8 cash-out (C6.3), the rake (inside C5.3), `RMP`/the anonymized leaderboard — named forward-tense only. | C5, C6 |

## The grounding contract

- **No invention.** Every module, function, table, key, id shape, and figure on a page traces to
  `echo/apps/codemojex` on disk, the binding design, a settled spec triad under
  [`specs/`](../), or the generated stories. Where the canon names a thing, the page uses its
  exact name.
- **Stories are the acceptance catalog.** The twelve `mix codemojex.stories` features
  ([`stories/`](../../stories/)) are the behavioral ground truth a chapter cites — never a
  hand-written transcript.
- **Forward-tense law.** Anything not shipped (cm.8+) is marked forward wherever named; a page never
  lets a forward claim read as shipped surface.
- **The identity contract.** 14-character branded ids (3-char namespace + 11 Base62 over the
  `ts(41)|node(10)|seq(12)` snowflake, epoch `1704067200000`) — the stamp on every page is a real
  `CMX` mint and the decoder is the standard footer IIFE.

## The HTML ladder

| Rung | Deliverable | State |
|---|---|---|
| **scaffold (this rung)** | the landing `/codemojex` built A+ + nine gated real-shell chapter stubs (identity + thesis + dive gists) + the `/bcs/codemojex` door section | ships with this canon |
| chapter rungs (next) | one authoring rung per chapter: the stub deepens into the full chapter page from its `course.N.md` brief | planned |
| dive rungs | the 27 dive pages, three per chapter, after their chapter lands | planned |

## The gate ladder (every page, every rung)

1. The ten jonnify-cms gates at `STATUS: PASS`, run with the cross-course mounts:
   `go/jonnify-cms/bin/cms check --require-refs --routes-from /codemojex=html/codemojex
   --routes-from /bcs=html/bcs --routes-from /echomq=html/echomq
   --routes-from /redis-patterns=html/redis-patterns --routes-from /mesh=html/mesh
   --routes-from /echo-persistence=html/echo-persistence <pages>`.
2. The identity greps, each empty: font leaks (`cormorant|manrope|pt serif|jetbrains|fonts.googleapis`),
   external assets (`<link |<script src|fetch(`), the basis tokens (`--b-`) — the `--c-*` calibration
   must be total.
3. The stamp check: every page carries its own unique 14-char `CMX…` id and the standard decoder.
4. A serve sweep over `go/echo-static` (`:1330`) — every route 200.
