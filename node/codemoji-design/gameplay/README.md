# Codemoji — gameplay design canon (Figma `UI` page)

The screens on the **UI** page of `😾 CODEMOJI (25.06.2026)` are the player-facing design of [`codemojex`](../../../echo/apps/codemojex), the Mastermind-with-emoji Telegram Mini App that lives in the Echo umbrella. This folder names every screen on that page, maps each to a human-readable PNG in [`assets/`](assets/), and grounds its role in the codemojex vocabulary that the [engine design](../../../docs/codemojex/codemojex.design.md), the [roadmap](../../../docs/codemojex/codemojex.roadmap.md), and the [player rules](../../../echo/apps/codemojex/docs/codemojex.game_rules.md) already canonized.

It is the bridge a frontend implementor (or this package's `extract` toolkit) reaches for when they need to turn the Figma surface into a working Mini App. Every screen description is sourced to the design + rules — when this doc and those disagree, the design + rules win.

The screens are sorted by their role in the game loop, not by Figma-tree order:

| File | What it covers |
|---|---|
| [01-onboarding.md](01-onboarding.md) | `welcome screen` · `Main` · `Как играть?` — first touch, the wallet hub, and the in-app explainer of the linear-scoring engine |
| [02-board.md](02-board.md) | `CODEMOJIES` — the gameplay board (the 6-emoji guess composer); the canonical master + 6 design variants |
| [03-rooms.md](03-rooms.md) | `Rooms` · `Golden Room in progress` · `Golden Room finished` — the lobby + the boost-class room states |
| [04-sections.md](04-sections.md) | `Emoji section` · `Withdraw` · `Winner` · `Sharing` — embedded subsurfaces and end-of-game actions |
| [05-stories.md](05-stories.md) | `story RU v1..v6` (+ EN instances) — sharable cards for outbound growth |
| [06-meta.md](06-meta.md) | `Лидерборд v2?` · `ЭмодзиИстория` — leaderboard and per-player attempt history |

A machine-readable companion lives at [`manifest.json`](manifest.json) — the same screen-to-asset mapping, joinable by tooling.

## How a screen is documented

Every screen is one heading with a metadata table, a short role description grounded in the design + rules, and a reference to its rendered PNG:

```markdown
## Gameplay board (canonical)

| field | value |
|---|---|
| figma id | `94:2974` |
| figma label | `CODEMOJIES` |
| figma type | COMPONENT |
| figma page | UI |
| asset | [`assets/codemojies-board-canonical-94-2974.png`](assets/codemojies-board-canonical-94-2974.png) |
| role | gameplay board — composes + submits a 6-emoji guess (`GES`) |
| game state | `active` |
| mode | both (`classic` shows per-guess feedback; `golden` withholds until reveal) |
| entities | `GAM` · `PLR` · `GES` · `EMS` |
| events | `scored` (classic) · `state`/`timer` (golden in-flight) · `revealed` (golden settle) on `game:<id>` |

A 1–3 paragraph role description follows, citing the relevant design + rules sections.

![Gameplay board](assets/codemojies-board-canonical-94-2974.png)
```

## Codemojex vocabulary (load-bearing — use verbatim)

The descriptions below are repeated as needed in the category files; this is the index.

### Entities — the 14-character branded ids

`<3-char-uppercase-namespace><11-char-Base62>` over a `ts(41) | node(10) | seq(12)` snowflake (epoch `1704067200000`). The brand *is* the type; it is checked at every boundary and travels unchanged from Postgres to Valkey to the bus to the Phoenix channel. The seven the UI surface touches:

| brand | entity | lives in |
|---|---|---|
| `PLR` | player | Postgres `players`, Valkey lanes/board |
| `ROM` | room (template) | Postgres `rooms` |
| `GAM` | one play of a room | Postgres `games`, EchoStore `:cm_games` |
| `GES` | one guess | Postgres `guesses` |
| `EMS` | one emoji set (sprite + exposed codes) | Postgres `emoji_sets`, EchoStore `:cm_emojisets` |
| `TXN` | one wallet transaction | Postgres `transactions` |
| `NOT` | one outbound notification | Valkey `cm.notify` lane |

(`codemojex.design.md:60-72`)

### Modes — the policy split

| type | feedback | settlement | scoring | economy |
|---|---|---|---|---|
| `classic` | `score` — live per-guess 0–600 | `live` — close on a perfect crack (600) or the timer | linear distance | per-guess fee, winner-take-all pool |
| `golden` | `none` — no per-guess signal until reveal | `sealed` — one batch at close, pay the top `K` | linear distance | per-guess fee (all-pay), reduced set, top-K split |

Both modes share **one** linear scoring function. The difference is the feedback and the settlement, not the math. The brand `GAM` is one type; the mode is a policy column on the row. (`codemojex.design.md:17-22`)

### Game states — the CHECK-bounded ladder

`scheduled → open → active → revealing → settling → settled` — or `voided` for the abort path.

- **Classic** traverses `open → settled`. A perfect 600 inside the scoring authority closes it, or the timer does — whichever wins the one-shot `SET cm:<game>:closed NX` lock.
- **Golden** traverses `open → revealing → settling → settled`. Only the timer closes it (no per-guess signal, so no early close). The closer reveals the secret + nonce, scores every guess, ranks players, and pays the top `top_k` (default 5) from the boosted pool by `payout_split` (default `[40,25,15,12,8]`).
- `settled` is terminal; a classic room returns to its waiting state to form the next game.

(`codemojex.design.md:131-162`)

### Distance / scoring

For each position `i`, the per-position score is `100 - 20·d` where `d = |guess_position - secret_position|` (or `0` for a miss). Six positions sum to a max of 600.

| distance | points | meaning |
|---|---|---|
| `D0` | 100 | exact placement |
| `D1` | 80 | adjacent |
| `D2` | 60 | near |
| `D3` | 40 | near |
| `D4` | 20 | far |
| `D5` | 0 | wrong end |
| miss | 0 | not in code |

**The leaderboard ranks the raw best linear total** — there is no tier ladder and no first-mover bonus in the shipped engine. (`codemojex.design.md:84`) `game_rules.md`'s "30-tier system" is a forward-looking extension, not the current rank; do not show tier badges on a screen unless documenting that future.

### Currencies — three separate paths

| currency | role | acquisition | path |
|---|---|---|---|
| `keys` | pay for guesses in **paid** rooms | buy with Telegram Stars; convert from diamonds 10:1 | never crosses `clips` |
| `clips` | pay for guesses in **free** rooms | grants only (no purchase) | never crosses `keys`; no economic value; excluded from the available balance |
| `diamonds` | prize currency | won from games | convertible to keys at a fixed 10:1; not withdrawable today |

Every mutation is a Postgres transaction with `SELECT … FOR UPDATE` + a paired `TXN` row. (`01-currency-model.md` · `codemojex.design.md:88`)

### Channels + notifications — how a screen knows things change

- **Phoenix channel `game:<id>`** — a client joins per game; **classic** pushes `scored` per attempt (name + percentage + effective score, never the secret or the guess content); **golden** pushes `state`/`timer` only until close, then one fat `revealed` event carrying the secret, the final board, and the payouts. (`codemojex.design.md:180`)
- **Telegram notifications** — `round_result/3` · `prize_won/3` (classic) · `golden_win/4` (Golden Room) — text-only, enqueued as a `NOT` on the `cm.notify` lane, drained by `NotificationWorker` → `echo_bot` → Telegram. A player with no `players.tg_chat_id` is paid all the same; the diamonds are the record, the notice is the courtesy. (`notifications.md:33` · `notifications.md:63-66`)

### Telegram surface

Identity comes from verified Telegram `initData` (HMAC-SHA-256 over the bot token keyed by `WebAppData`); `players.tg_chat_id` is the push address. The UI is a Telegram Mini App over Phoenix. (`codemojex.design.md:182` · `notifications.md:64`)

### Golden Room vs. `golden` game type — DISAMBIGUATION

Two unrelated things in the canon use the word "golden":

- **Golden Room** (this folder's `Golden Room in progress` / `Golden Room finished` screens) — a *boost class* of an otherwise ordinary `classic`-type room: `golden: true` + `gold_multiplier: N` on `rooms` + `games`, snapshotted at start, paid at close as `effective_pool = pool * multiplier`, winner-take-all. Win notification: `golden_win/4`. (`golden-rooms.md`)
- **`golden` game type** — the blind/sealed mode (no per-guess feedback, commit-reveal: `commitment = SHA-256(secret ‖ nonce)`, `top_k` payout). Different mechanism; not what the Golden Room screens show.

The screens here document the **boost class** on the **classic base**.

## Asset filename convention

`<role>-<modifier?>-<figma-id-with-dash>.png` — kebab-case, semantic first, figma id as the unambiguous tail. The dashed form mirrors the `94-2974 ↔ 94:2974` normalization in [`../src/bridge.mjs:74-78`](../src/bridge.mjs). Example: `golden-room-in-progress-1089-19410.png`. The figma-id tail makes the manifest joinable on the live document without ambiguity if two screens share a role label.

## Regenerating the assets

From any host with the `figma-local` MCP wired (the Mac toolkit dials the same Windows bridge the rest of this package uses, default `FIGMA_BRIDGE_URL=http://192.168.3.120:3001`):

```text
# Per-screen PNG:
mcp__figma-local__export-node nodeId:"94:2974" format:"PNG"

# Batched (one call, many renders):
mcp__figma-local__export-batch-nodes nodeIds:["94:2974", "21:780", ...] format:"PNG"
```

Either returns base64-encoded PNG payloads; decode each to `gameplay/assets/<filename>` per [`manifest.json`](manifest.json). Image bytes stay out of an agent's context — bridge → tool → disk. The bridge accepts the same call regardless of plugin handshake state (`export-node` has been backed by the plugin since the first figl rung).

## Pointers

- Engine design (binding) — [`docs/codemojex/codemojex.design.md`](../../../docs/codemojex/codemojex.design.md)
- Roadmap (ship ladder) — [`docs/codemojex/codemojex.roadmap.md`](../../../docs/codemojex/codemojex.roadmap.md)
- Player rules — [`echo/apps/codemojex/docs/codemojex.game_rules.md`](../../../echo/apps/codemojex/docs/codemojex.game_rules.md)
- Golden Room mechanic — [`echo/apps/codemojex/docs/golden-rooms.md`](../../../echo/apps/codemojex/docs/golden-rooms.md)
- Currency model — [`echo/apps/codemojex/docs/01-currency-model.md`](../../../echo/apps/codemojex/docs/01-currency-model.md)
- Rooms + emoji-set rendering math — [`echo/apps/codemojex/docs/02-rooms-and-emoji-sets.md`](../../../echo/apps/codemojex/docs/02-rooms-and-emoji-sets.md)
- Notification path — [`echo/apps/codemojex/docs/notifications.md`](../../../echo/apps/codemojex/docs/notifications.md)
- Toolkit topology + bridge — [`README.md`](../README.md) + [`src/bridge.mjs`](../src/bridge.mjs)
- figma-local MCP design canon — [`docs/figma-local/`](../../../docs/figma-local/)
