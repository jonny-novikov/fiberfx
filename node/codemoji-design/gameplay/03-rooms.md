# 03 — Rooms (lobby + Golden Room states)

A **room** (`ROM`) is a template: it holds the props a `GAM` inherits at start — emoji set (`EMS`), duration, seeded prize pool, guess fee, free-or-paid, the game `type` (`classic` | `golden`), the sealed `payout_split`, the reduced-set `cell_count`, and the boost props (`golden` bool + `gold_multiplier`). At any moment a room either has **no** active game (waiting for the first player to join) or **exactly one** game in flight; the first player to join a waiting room starts the game, the room snapshots its props onto the `GAM`, and from that moment the round's terms are fixed (`02-rooms-and-emoji-sets.md` + `codemojex.design.md:130`).

The screens in this folder cover three room surfaces:

- the **rooms lobby** — a list of rooms by their props (3 variants)
- a **Golden Room in progress** — the boost class while a `classic` game is running
- a **Golden Room finished** — the boost class post-settlement

**Disambiguation reminder** ([README.md](README.md#golden-room-vs-golden-game-type--disambiguation)): a *Golden Room* is a boost class on a `classic`-type game (`golden: true` + `gold_multiplier: N` on `rooms` + `games`, applied at settlement as `effective_pool = pool * multiplier`, winner-take-all). A `golden` *type* game is the blind/sealed commit-reveal mode — different mechanism, no per-guess feedback, top-K payout. The screens here document the boost class on the classic base.

---

## Rooms lobby — canonical

| field | value |
|---|---|
| figma id | `121:2056` |
| figma label | `Rooms` |
| figma type | COMPONENT |
| figma page | UI |
| asset | [`assets/rooms-lobby-121-2056.png`](assets/rooms-lobby-121-2056.png) |
| role | rooms lobby — the room list (canonical master component) |
| game state | n/a (lobby is rooms-level, not game-level) |
| mode | n/a |
| entities | `ROM` |
| events | none — the lobby is an HTTP read against `rooms` (no per-room process exists, so a large idle field costs nothing) |

The lobby is the room-picker: a list rendered from the `rooms` table with the props a player needs to choose — emoji set, duration, seed prize pool, guess fee, paid/free, and (where set) the Golden Room boost. There is **no** per-room server process (`codemojex.design.md:178`); the lobby is a JSON read and joining a room is what mints a `GAM`. A player choosing a `paid` room commits `keys`; choosing a `free` room commits `clips` — the two paths never cross (`01-currency-model.md`).

The canonical component is `121:2056`; design variants `561:12013` and `846:15620` below explore the same surface.

![Rooms lobby — canonical](assets/rooms-lobby-121-2056.png)

---

## Rooms lobby — variant `561:12013`

| field | value |
|---|---|
| figma id | `561:12013` |
| figma label | `Rooms` |
| figma type | COMPONENT |
| figma page | UI |
| asset | [`assets/rooms-lobby-variant-561-12013.png`](assets/rooms-lobby-variant-561-12013.png) |
| role | rooms-lobby design variant (second master component) |
| game state | n/a |
| mode | n/a |
| entities | `ROM` |
| events | none |

A second master component for the lobby — same surface contract as `121:2056`, different treatment.

![Rooms lobby — variant 561:12013](assets/rooms-lobby-variant-561-12013.png)

---

## Rooms lobby — variant `846:15620`

| field | value |
|---|---|
| figma id | `846:15620` |
| figma label | `Rooms` |
| figma type | FRAME |
| figma page | UI |
| asset | [`assets/rooms-lobby-variant-846-15620.png`](assets/rooms-lobby-variant-846-15620.png) |
| role | rooms-lobby design exploration |
| game state | n/a |
| mode | n/a |
| entities | `ROM` |
| events | none |

A frame-level iteration of the lobby surface.

![Rooms lobby — variant 846:15620](assets/rooms-lobby-variant-846-15620.png)

---

## Golden Room — in progress

| field | value |
|---|---|
| figma id | `1089:19410` |
| figma label | `Golden Room in progress` |
| figma type | COMPONENT |
| figma page | UI |
| asset | [`assets/golden-room-in-progress-1089-19410.png`](assets/golden-room-in-progress-1089-19410.png) |
| role | Golden Room with an active boosted game — shows `gold_multiplier` + effective pool |
| game state | `open` |
| mode | `classic` (the boost class rides on the classic base) |
| entities | `ROM` · `GAM` · `PLR` |
| events | `scored` events from `game:<id>` (classic mode — live per-guess) |

A Golden Room is one where the platform is funding a multiplied diamond payout: the boost is `gold_multiplier` (default `3×` unless a multiplier is given), captured onto the round at start so editing the room — or ending the gold promotion — never changes the terms of a round already in flight (`golden-rooms.md:6` + `golden-rooms.md:9-16`).

### What the screen depicts

The screen is a single full-page composition the player scrolls through end-to-end:

- **Top scoreboard** — a `48:00:00` countdown timer (a 2-day window suggesting Golden Rooms run as multi-day promotional events, not the minutes-long pace of an ordinary round), a player count (`147` in the mock), and the diamond pool (`2352`). The pool here is the **effective** pool — `pool * gold_multiplier` — not the raw seed.
- **Board strip** — `Отгадай код из 6 эмодзи` (guess the 6-emoji code) with the keyboard slot; this composes the [Emoji section](04-sections.md#emoji-section--canonical) inline rather than as a separate route.
- **Two-column live ranking** — `Игроки` / `Лидерборд` with ranked rows showing each player's most-recent guess as the six emoji cells; this is the same `cm:<game>:board` ZSET the standalone [Leaderboard](06-meta.md#leaderboard) renders, just embedded.
- **Правила игры** — the rules panel inlined.
- **Referral footer** — `Поделиться в стори` / `Пригласить друга` (share to story / invite a friend), which is the entry to the [Sharing surface](04-sections.md#sharing).

### How the boost is wired (code paths)

- **Two columns carry the mechanic** on both the room template and the round it snapshots: `golden` (boolean — `true` flags the class) and `gold_multiplier` (the factor; default `3×`, or whatever is passed at creation). Both are defaulted, so existing rooms are unaffected by the presence of the columns (`golden-rooms.md:10-16`).
- **The convenience API** is `Codemojex.create_golden_room/3` over `create_room/3` (`golden-rooms.md:20-33`). Two shapes:
  ```elixir
  {:ok, room} = Codemojex.create_golden_room("Friday Gold", emoji_set, seed_pool: 500)
  {:ok, room} = Codemojex.create_golden_room("Mega Gold", emoji_set,
                  seed_pool: 1_000, gold_multiplier: 5, guess_fee: 3)
  ```
  The room is created in the waiting state like any other; the first player to join starts the round, and the round snapshots `golden` + `gold_multiplier` from the room. **From that moment the round's terms are fixed** — editing the room (or ending the promotion) cannot reshape an in-flight round.
- **The pool rule** is the pure function `Codemojex.Economy.effective_pool/3` (`golden-rooms.md:39-44`): `effective_pool(pool, true, mult) → pool * mult` (else `pool`). The surface shows this product; the platform funds the difference between the seeded pool and the boosted payout.
- Because the game is `classic`-typed (the boost class rides on the classic base), per-guess `scored` events from `game:<id>` still fan out and the leaderboard updates live.

![Golden Room — in progress](assets/golden-room-in-progress-1089-19410.png)

### Instance placements

The Figma file holds three INSTANCES of this master at `1105:20625`, `1117:28575`, and `1105:22103` (all named `Golden Room in progress`). They are placements of `1089:19410` on flow/mockup canvases without observable text or property overrides — they render identically to the master at the moment of capture. Kept here as a Figma cross-reference only; not rendered to `assets/` (an identical second copy would add no documentation value).

---

## Golden Room — finished

| field | value |
|---|---|
| figma id | `1108:27589` |
| figma label | `Golden Room finished` |
| figma type | COMPONENT |
| figma page | UI |
| asset | [`assets/golden-room-finished-1108-27589.png`](assets/golden-room-finished-1108-27589.png) |
| role | Golden Room post-settlement — winner-take-all of the boosted pool, golden_win moment |
| game state | `settled` |
| mode | `classic` |
| entities | `ROM` · `GAM` · `PLR` · `TXN` · `NOT` |
| events | PubSub `{:golden_win, …}` broadcast on the game's topic + `golden_win/4` Telegram notification |

The post-settlement Golden Room screen is the louder moment a Golden Room has been designed for. It is the same full-page composition as the in-progress screen — board strip + two-column leaderboard + rules + referral footer — with two state changes: a settled-state header replaces the active-game CTA, and a **`Правильный ответ`** (correct answer) reveal panel is added so the secret 6-emoji code is visible alongside each player's final guess in the leaderboard rows.

### Settlement (the close path)

Settlement runs inside the one-shot **`SET cm:<game>:closed NX`** lock, so a perfect-crack close and a timer close never both pay (`golden-rooms.md:46-48`). The closer:

1. Computes the **effective pool** via `Codemojex.Economy.effective_pool/3` (pure: `pool * mult` when `golden: true`).
2. Applies the ordinary **winner-take-all** split over the boosted pool — the whole pool to the top scorer, divided evenly on a tie. There is no separate Golden split policy; the boost is purely the multiplier on the same winner-take-all rule every classic room follows.
3. Deposits each prize through the wallet path as a `TXN`, bumps `cm:total_won`, and marks the game `settled`.

Because `effective_pool/3` is a pure function and the close runs inside the `SET … NX` lock, a re-run settlement pays identically — a Golden Room never double-pays its boost (`golden-rooms.md:48`).

### The win is a moment (two channels)

The win is announced on **two channels** the surface needs to handle:

- **`{:golden_win, …}` on the round's Phoenix PubSub topic** — so anyone watching the room sees the moment fan out, the same way a `scored` event does. This drives the live transition from in-progress to finished for every connected viewer (`golden-rooms.md:50-52`).
- **`Codemojex.Notifier.golden_win/4`** — a text notification carrying the boosted diamonds + the multiplier, addressed via `Codemojex.Store.chat_of/1` to the winner's `tg_chat_id` and delivered by `echo_bot` through the `cm.notify` lane (see [notifications.md](../../../echo/apps/codemojex/docs/notifications.md)). A player with no chat on file is paid all the same — the diamonds are the record, the notice is the flourish (`golden-rooms.md:50-52`).

After this screen the room transitions back to waiting (the `classic` traversal `open → settled`, then the room is reusable for the next game).

### Relationship to the basic Winner card

The [Winner card](04-sections.md#winner) (`771:15371`) is the per-player flourish that fires on the winning player's surface at any classic-type close (a Golden Room is `classic`-typed, so it fires here too). The Golden Room **finished** screen above is the **full-page room view** that everyone watching the room sees — it is the Golden boost-class equivalent of the classic settled view, not a replacement for the Winner card. The Winner card is the personal moment; the Golden Room finished page is the public one.

![Golden Room — finished](assets/golden-room-finished-1108-27589.png)
