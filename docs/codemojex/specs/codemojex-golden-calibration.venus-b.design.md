# Codemojex · Golden Rooms calibration — Venus-B design (the design-canon / player-surface lens)

> **Design-phase deliverable.** No production code; spec + a complete inconsistency analysis.
> Authored independently of Venus-A from the same brief (the dual-architect contract). The lens is
> the player surface down: what the player SEES, what the designers INTENDED by "Golden Room", and
> the complete design-canon ↔ engine-spec ↔ as-built drift catalogue read from the surface.
>
> Sources of truth, in precedence order for this calibration: (1) the design canon
> `node/codemoji-design/gameplay/` + `node/codemoji-design/screens/game/` (the Operator's named
> source); (2) the engine canon `docs/codemojex/codemojex.design.md` + `codemojex.roadmap.md`; (3)
> the app docs `echo/apps/codemojex/docs/*.md`; (4) the as-built `echo/apps/codemojex/lib/codemojex/*.ex`.
> Every claim is grounded in a real `file:line` or design §. Forward-tense for any unshipped surface.
>
> **Framing:** no gendered pronouns for agents; no perceptual or interior-state verbs; no
> first-person narration. This clause propagates into any brief derived from this design.

---

## 0. The locked constraints (Operator — NON-NEGOTIABLE; designed around, not relitigated)

1. **The Golden Room timer starts when 10 players are "in a game"** — a participation-gated start,
   replacing the current "first player joins → timer starts."
2. **"In a game" / room membership = a `PLR` who has made ≥1 guess** in that concrete `GAM`
   (participation, not mere join).
3. **The same `N/10` counter surfaces on the Gameplay screen** (the `CODEMOJIES` board).
4. **The specs are reconciled to the canonical design** at `node/codemoji-design/gameplay/` — a
   complete inconsistency catalogue, not only the start mechanic.

---

## 1. Headline finding (the design-intent verdict)

**"Golden Room" is the BOOST CLASS on a `classic` base; the as-built code builds the OPPOSITE under
that name, and the design canon already disambiguated the collision the code fell into.**

The design canon is internally consistent across **four** files that a Golden Room is a *boost
class* (the `golden: true` + `gold_multiplier` props) riding a **`classic`-typed** game with **live
`scored` feedback** and **winner-take-all** settlement:

- `node/codemoji-design/gameplay/README.md:119-126` — an explicit **DISAMBIGUATION** section:
  *"Golden Room … a boost class of an otherwise ordinary `classic`-type room … `golden` game type …
  the blind/sealed mode … Different mechanism; not what the Golden Room screens show."*
- `node/codemoji-design/gameplay/03-rooms.md:11` (disambiguation reminder), `:91` (game state
  `open`, mode `classic`), `:118` (*"the game is `classic`-typed … per-guess `scored` events …
  still fan out and the leaderboard updates live"*).
- `node/codemoji-design/gameplay/02-board.md:27,29` — the board, mode `classic`, `scored` events.
- `node/codemoji-design/gameplay/04-sections.md:107-110` — *"Two distinct close paths to keep
  straight"*: a Golden Room (boost class on `classic`) **fires the Winner card**; a `golden` *type*
  game (blind/sealed) does **not** — *"Build that surface separately if/when the design lands."*

The engine's **own** doc agrees with the canon: `echo/apps/codemojex/docs/golden-rooms.md:4` —
*"It plays exactly like an ordinary Codemoji game … but the diamond prize the winner takes is
multiplied"* — and its wired close path is `close_live` (winner-take-all), not the sealed one
(`golden-rooms.md:39-48`).

The Figma master `1089:19410` ("Golden Room in progress") agrees: game state `open`, mode
`classic`, events `scored` (`03-rooms.md:83-93`).

**But the as-built code builds the blind/sealed mode under the boost name.** The defaulting chain:

| step | location | effect |
|---|---|---|
| `create_golden_room/3` = `create_room(name, set, Keyword.put(opts, :golden, true))` | `lib/codemojex/game.ex:208` | sets `golden: true` |
| `golden = opts[:golden]`; `type: if(golden, "golden", "classic")` | `lib/codemojex/rooms.ex:26,31` | **the BOOST flag forces the blind MODE** |
| `policies_for("golden")` = `feedback: "none", settlement: "sealed", economy: "winner_take_all"` | `lib/codemojex/rooms.ex:127` | blind, top-K via `close_sealed` (`rooms.ex:223`) |

So `Codemojex.create_golden_room("Friday Gold", set, seed_pool: 500)` produces a **blind sealed
top-K** game — no per-guess feedback (`game.ex:126` suppresses `scored`), settled by `close_sealed`
(`rooms.ex:236` `top_k_split`) — which is the canon's `golden` **type**, the *other* thing, the one
the canon says is "not what the Golden Room screens show."

**The root cause is a namespace collision baked into a defaulting chain.** The word "golden"
overloads two orthogonal axes:

- the **boost** axis — `golden: bool` + `gold_multiplier` (the platform-funded multiplier);
- the **mode** axis — `type: "classic" | "golden"` (live-scored vs blind-sealed).

`create_room` (`rooms.ex:31`) conflates them by *defaulting `type` from the `golden` boolean*. The
calibration decouples the two axes: a boost flag must not pick a mode.

**Is "Golden Room" one thing or two?** The design intends **two distinct surfaces under one word, and
names them apart**: (a) the **Golden Room** — boost class on `classic`, live, the
`gameplay/03-rooms.md` screens (`Golden Room in progress` / `finished`); and (b) the **golden (blind)
variant** — the sealed commit-reveal mode, which the canon places in a **sibling, separately-named
surface** `node/codemoji-design/screens/game-golden/` (`screens/game/README.md:12`: *"The sibling
`screens/game-golden/` covers the golden (blind) variant"*). The collision is that the *code* maps
both onto the single word "golden" via the convenience API; the *design* keeps them apart. The
calibration makes the engine match the design: **"Golden Room" → boost class; "golden type" → the
blind variant, reached only by an explicit `type:`.**

---

## A. The complete inconsistency catalogue

Severity key: **S1** breaks the player-facing contract (the surface shows the wrong game) · **S2**
a doc ↔ doc / doc ↔ code contract drift that misleads a builder · **S3** a default/mock/cosmetic
drift, note-only.

Position legend: **Canon** = `node/codemoji-design/**` · **Spec** = `docs/codemojex/**` +
`echo/apps/codemojex/docs/**` · **Code** = `echo/apps/codemojex/lib/codemojex/**`.

### A-1 — "Golden Room" builds the blind mode instead of the boost class · **S1**

| source | position |
|---|---|
| Canon | Golden Room = boost class on `classic`, **live** `scored`, winner-take-all (`gameplay/README.md:119-126`; `03-rooms.md:11,91,118`; `02-board.md:27`; `04-sections.md:109`) |
| Spec | `golden-rooms.md:4` agrees (boost on classic, `close_live`); `codemojex.design.md:123` (the *boost* row of the disambiguation) |
| Code | `create_golden_room/3` → `golden:true` → `rooms.ex:31` `type:"golden"` → `policies_for("golden")` `rooms.ex:127` = **blind/sealed** (the opposite) |

**Resolution:** decouple the boost axis from the mode axis (ADR **F-A**). A Golden Room is
`type:"classic"` + `golden:true` + `gold_multiplier`. The blind/sealed mode is reached only via an
explicit `type:"golden"` opt. **`create_golden_room/3` must NOT set `type:"golden"`.**

### A-2 — Start trigger: first-join vs participation-gated (the locked mechanic) · **S1**

| source | position |
|---|---|
| Canon | the screens show a gathering/in-progress player count (`147` mock, center-top, `03-rooms.md:101`); the Operator's locked rule: **the timer starts at 10 distinct guessers** |
| Spec | *"the first player to join … starts the game"* (`codemojex.design.md:143`; `golden-rooms.md:35`; `03-rooms.md:3`) — first-join start, **no gathering phase** |
| Code | `join_room` `rooms.ex:54` → `start_game` `rooms.ex:68` → `ends_ms` `rooms.ex:95`, `status::open` `rooms.ex:109` — **first join starts the timer** |

**Resolution:** participation-gated start (ADR **F-B**, **F-C**, **F-E**). See §B.

### A-3 — Membership = joiner vs ≥1-guesser (the locked definition) · **S1**

| source | position |
|---|---|
| Canon | "in a game" is the participating field the screens rank; the Operator's locked rule: **member = a `PLR` who has made ≥1 guess in the `GAM`** |
| Spec | `cm:<game>:players` is "a set" of joiners (`codemojex.design.md:139`); `total_players` is its `SCARD` |
| Code | `add_player` `rooms.ex:160` `SADD cm:<game>:players`, called on **join** (`rooms.ex:60,116`) — "players" = **joiners**, not guessers; `total_players` `view.ex:117` reads it |

**Resolution:** introduce a **members-by-guess** set, distinct from the join set (ADR **F-E**). See §B.

### A-4 — `N/10` counter not surfaced on the board · **S1** (new requirement)

| source | position |
|---|---|
| Canon | the board (`94:2974`) + the Golden Room (`1089:19410`) render a **player count in a fixed center-top stat slot** (`147` mock; the three-stat row timer · count · pool — verified in the rendered PNGs); the Operator's locked rule: **the same `N/10` counter surfaces on the Gameplay screen** |
| Spec | `game_view` returns `totals.players` = the joiner count (`view.ex:71-83`); no threshold, no gathering flag |
| Code | `game_view` exposes neither `threshold` nor `members_count` nor a `gathering` phase flag (`view.ex:49-87`) |

**Resolution:** `game_view` exposes `gathering` (bool), `members_count`, and `threshold`; the
center-top stat reads `N/10` while gathering, the live participant count after (ADR **F-F**). See §B.

### A-5 — The "30-Tier System" presented as current, against a no-tier canon · **S2**

| source | position |
|---|---|
| Canon | **no tier ladder, no first-mover bonus in the shipped engine** — emphatic and triple-sourced: `gameplay/README.md:98`; `gameplay/01-onboarding.md:74` (*"the explainer must NOT show a tier ladder"*) |
| Spec (engine) | `codemojex.design.md:84,137,139,172` — *"no `tier`/`percentage` column … no tier race, no bonus … the score a player sees is the score they earned"* |
| Spec (rules) | `game_rules.md:185-239` ships a full **"30-Tier System"** table; `:46-47` first-mover bonuses ("submit early to claim first-mover bonuses"); `:250` summary row lists "Tier" as a current concept. `:230` *does* head a "Future Game Extension: Tiers" section — but the body at `:185` + the summary present tiers as shipped, so the doc reads as half-current |
| Spec (engine doc) | **`golden-rooms.md:4` itself says "the same first-mover tiers"** — the engine's own Golden doc contradicts the engine design |

**Resolution:** demote `game_rules.md`'s tier system unambiguously to a **forward-looking
extension** (a clear "NOT in the shipped engine" banner on the §30-Tier and §Future sections), and
**strike "the same first-mover tiers" from `golden-rooms.md:4`** (it must read "the same linear
scoring"). No code change — the engine is already tier-free (`design.md:139`).

### A-6 — Fee → pool accrual: claimed in rules, absent in code · **S2** (FORK)

| source | position |
|---|---|
| Canon | the pool is a **seeded** winner-take-all pool (`gameplay/README.md:70`); the canon never asserts the fee accrues to the pool; the in-app rules string DOES (`screens/game/README.md:177`: *"Every attempt adds crystals to the growing prize pool"*) — and `screens/game/README.md:112-116` **FLAGS** the divergence |
| Spec | `game_rules.md:41-52` — *"Entry fees (30% platform fee)"*, *"Players contribute to the prize pool through entry fees … remaining 70% is distributed"* (fee→pool, with a platform cut) |
| Code | `prize_pool` is **platform-seeded** (`rooms.ex:33,97` `seed_pool`) + golden-boosted at close (`economy.ex` `effective_pool`); **no code adds the guess fee to the pool** — `Wallet.charge_guess` debits keys/clips only (`game.ex:33`) |

**Resolution:** a **FORK for the Operator** (ADR **F-G**). The design-canon reading favours the
**platform-seeded** pool (strike the fee→pool copy). If the Operator wants fee-funded pools, that is
new economy to build (not part of this calibration). Either way the three docs must be reconciled to
one story.

### A-7 — Default duration vs the screens' shown durations · **S3** (note-only)

| source | position |
|---|---|
| Canon | Golden Room screen shows `48:00:00` (`03-rooms.md:101`, "a 2-day window suggesting Golden Rooms run as multi-day promotional events"); the board shows `34:55:38` (the PNG) |
| Code | `duration_ms` defaults to **35h** (`rooms.ex:32`) |

**Resolution:** none required — a default vs a mock, not a contract. Note: if Golden Rooms are
intended as ~48h promotional events, `create_golden_room/3` may default `duration_ms` higher, but
that is a promotional/economic decision (charter: `golden-rooms.md:56`), not a calibration defect.

### A-8 — `147` player count is a Figma mock · **S3** (note-only)

The `147` (and `2352`/`52352` pools) on the screens are Figma mock values (`03-rooms.md:101`). They
do not constrain the engine. The center-top stat slot they occupy IS the surface the `N/10` counter
binds to (see A-4 / §B).

### A-9 — Disambiguation-doc fan-out: where the boost-class story already lives (correct) vs where the code drifted · **S2** (consistency map, not a new defect)

The boost-class definition is correctly stated in: `gameplay/README.md:119-126`,
`gameplay/03-rooms.md`, `gameplay/04-sections.md:107-110`, `golden-rooms.md` (body), and the *boost*
row of `codemojex.design.md:123`. The **only** place the boost-class story is contradicted is the
**code** (A-1) and the **two doc lines** A-5 flags (`golden-rooms.md:4` "first-mover tiers";
`game_rules.md` tier framing). The catalogue's center of gravity is the code, not the canon — the
canon is the fixed point the engine conforms to.

---

## B. The calibrated Golden Rooms mechanics spec (the deltas)

This section states the concrete spec delta for the three locked behaviours. It is written
forward-tense; the actual code lands via Mars under the Director, not here.

### B-1 — Decouple the boost axis from the mode axis (resolves A-1)

- **`create_golden_room/3`** sets `golden: true` (and any `gold_multiplier`/`guess_fee`/`seed_pool`)
  but **does NOT set `type`**, so the room is `type: "classic"` (the `create_room` default at
  `rooms.ex:31` once the `if(golden, "golden", …)` coupling is removed). The blind/sealed mode stays
  reachable by an explicit `create_room(name, set, type: "golden", …)`.
- **Effect:** a Golden Room is `type:"classic"` + `golden:true` → `policies_for("classic")` →
  `feedback:"score"` (live) + `settlement:"live"` → `close_live` (winner-take-all over the boosted
  `effective_pool`). This is exactly what `golden-rooms.md:4` and the screens describe.
- **Lands in:** `docs/codemojex/codemojex.design.md` (the disambiguation note must state the axes are
  independent — a Golden Room is `classic` + a boost, NOT `type:"golden"`); the spec triad's body;
  the code delta is Mars's (`rooms.ex:31` decoupling + `game.ex:208` not forcing the type).

### B-2 — Participation-gated start: member-by-guess + the threshold (resolves A-2, A-3)

- **A new "members" set, distinct from the join set.** Today `cm:<game>:players` is the join set
  (`rooms.ex:160`). The calibration adds a **members-by-guess** set — proposed key
  `cm:<game>:members` — to which a `PLR` is added on **its first scored guess in this `GAM`**. The
  natural insertion point is the score path: after `Board.record` (`game.ex:122`), `SADD
  cm:<game>:members <player>` (idempotent — a set; the second-and-later guesses no-op the add). The
  **member count** is `SCARD cm:<game>:members`.
- **The threshold.** The participation gate is `members_count >= threshold`, default `threshold = 10`
  (the locked constant). Whether the threshold is a hardcoded `10`, a room/game prop, and whether it
  is golden-only or all-rooms is ADR **F-B**.
- **The timer starts on the threshold-crossing guess.** While `members_count < threshold` the game's
  `ends_ms` stays **`nil`** (the timer is not running). On the guess that brings `members_count` to
  `threshold`, the score path sets `ends_ms = now + duration_ms` (the timer "starts"). The
  gathering-phase shape (reuse `open` + `ends_ms:nil` vs a new `gathering` state) is ADR **F-C**;
  the recommendation is `open` + `ends_ms:nil`.
- **Why `ends_ms:nil` is already safe.** Every expiry path already guards on an *integer* `ends_ms`:
  `Guesses.submit` `expired?` returns `false` when `ends_ms` is non-integer (`game.ex:48-53`);
  `close_if_expired` matches only `%{status: :open, ends_ms: e} when now >= e` (`rooms.ex:302`), so a
  `nil` `ends_ms` never sweeps-closed. A gathering game is therefore naturally un-closeable and
  accepts guesses — exactly the gathering behaviour, with no new guard.
- **`start_game` change.** `start_game` (`rooms.ex:68`) sets `ends_ms: nil` at open instead of `now +
  duration_ms` (`rooms.ex:95`), and stamps a `gather_window`/`gather_by_ms` if ADR **F-D** chooses a
  gather deadline. Everything else (the keyboard snapshot, the secret, the commitment) is unchanged.
- **Lands in:** `codemojex.design.md` §"The game as a state machine" (the `open`/`ends_ms:nil`
  gathering phase, the threshold, the member-by-guess set) + the `cm:<game>:` keyspace family
  (`design.md:139` adds `members`); the spec triad body; `golden-rooms.md` (the start rule changes
  from "first player to join starts the round" `:35` to "the round's timer starts when N players
  have each made a guess"); `node/codemoji-design/gameplay/03-rooms.md` (the in-progress screen
  description gains the gathering phase). The code delta is Mars's.

### B-3 — The `N/10` counter on the board + the gathering surface (resolves A-4)

- **The surface, three phases:**
  - **gathering** (`members_count < threshold`, `ends_ms == nil`): the center-top stat reads the
    counter `N/10` with "waiting for players" copy; **no countdown** (there is no `ends_ms` to count
    to). The leaderboard/board still renders (guesses are accepted and scored live in a Golden Room).
  - **in-progress** (`members_count >= threshold`, `ends_ms` set, `status:open`): the center-top
    stat reads the **live participant count** (`members_count`), the countdown runs to `ends_ms`. This
    is the Figma `Golden Room in progress` / board state (the `147`/timer/pool row).
  - **finished** (`status:settled`): the Figma `Golden Room finished` screen — the reveal/winner
    surface, unchanged by this calibration.
- **The counter copy + placement.** The counter occupies the **existing center-top stat slot** the
  screens already render (timer · **count** · pool — verified in `94:2974` and `1089:19410`): it is a
  *value-source* change, not a new element. Gathering: `N/10` + a "waiting for players" label.
  In-progress: the participant count, as today's `147` mock slot. (Exact RU/EN copy is a design-copy
  decision for the Figma surface, not the engine.)
- **The engine delta that powers the surface.** `game_view` (`view.ex:49-87`) gains, alongside
  `totals`: `gathering` (bool = `members_count < threshold`), `members_count` (`SCARD
  cm:<game>:members`), and `threshold`. The frontend chooses gathering-vs-countdown from `gathering`
  + `ends_ms` (which is `nil` while gathering). Whether the counter is golden-only or shown for all
  rooms on the board is part of ADR **F-B** / **F-F**.
- **Lands in:** `node/codemoji-design/gameplay/02-board.md` + `03-rooms.md` (the board + Golden Room
  screen descriptions gain the gathering phase + the `N/10` counter in the center-top stat slot);
  `codemojex.design.md` §"The web surface" (the `game_view` shape gains `gathering`/`members_count`/
  `threshold`); the spec triad body. The code delta (the `game_view` fields) is Mars's.

### B-4 — The doc reconciliation (resolves A-5, and the A-6 doc side)

- **`game_rules.md`** — the §"The 30-Tier System" (`:185-227`) and §"Future Game Extension: Tiers"
  (`:230-240`) get an explicit **"NOT in the shipped engine — a forward-looking extension"** banner;
  the §"Key Concepts Summary" "Tier" row (`:250`) is marked future; the "first-mover bonuses" copy
  (`:46-47`) is struck or future-flagged. The shipped rule (linear best total, no tier, no
  first-mover bonus — `design.md:139`) is stated as current.
- **`golden-rooms.md:4`** — *"the same first-mover tiers"* → *"the same linear scoring"* (strike the
  contradiction; the engine has no tiers).
- **`game_rules.md:41-52` + the in-app rules string** — reconciled to the chosen A-6 outcome (default:
  platform-seeded pool; strike "Every attempt adds crystals to the growing prize pool" / "Entry fees
  … prize pool"). If the Operator chooses fee-funded (F-G), instead state that economy precisely.
- **Lands in:** `echo/apps/codemojex/docs/codemojex.game_rules.md` + `golden-rooms.md`. No engine
  code change for A-5 (the engine is already tier-free).

### B-5 — The new state-machine shape (the picture)

Under the recommended ADRs (F-C Opt A: `open` + `ends_ms:nil`; F-E: member-by-guess set):

```
        join a waiting room
                │
                ▼
        ┌──────────────────────┐   guess → score (the cm lane)
        │  open, ends_ms = nil  │◀──────────────────────────┐
        │  (GATHERING)          │   each scored guess:       │
        │  members < threshold  │   SADD cm:<game>:members   │
        └──────────┬───────────┘   (board + scored events,   │
                   │                  Golden Room is classic) │
   the guess that  │                                          │
   makes members   ▼                                          │
   == threshold:   set ends_ms = now + duration_ms ───────────┘
                   │  (the timer STARTS)
                   ▼
        ┌──────────────────────┐
        │  open, ends_ms set    │   (the existing open behaviour:
        │  (IN PROGRESS)        │    600 crack or timer → SET NX close)
        └──────────┬───────────┘
                   ▼
        classic ─▶ settled   (winner-take-all over the boosted effective_pool)

   [F-D abort path] gather_by_ms passes with members < threshold
                   └─▶ voided  (refund the charged fees — see ADR F-D)
```

The seven canon states (`design.md:136`) are unchanged in count; `open` now spans both gathering and
in-progress, distinguished by `ends_ms == nil` vs set. `voided` (already canon) is the F-D abort path.

---

## C. The ADRs (one per fork)

Each ADR: context · ≥2 steelmanned options (incl. a baseline) · the decision/recommendation · the
consequences. The **bolded RECOMMENDATION is a recommendation, not a ruling** — the forks are the
Operator's to decide (Discipline: surface forks, never decide them). The Director carries them.

### ADR F-A — Which "Golden"? (the boost class vs the blind mode)

- **Context.** `create_golden_room/3` builds the blind/sealed mode (A-1) because `golden:true`
  defaults `type:"golden"` (`rooms.ex:31`). The canon names a Golden Room as the boost class on a
  `classic` base and names the blind mode a *separate* surface (`screens/game-golden/`).
- **Options.**
  - **A1 — boost class on classic (conform to the canon).** Decouple the axes; a Golden Room is
    `type:"classic"` + `golden:true`. The blind mode is `type:"golden"`, explicit. *Steelman:* the
    canon is consistent across four files + the engine's own `golden-rooms.md` + the Figma screens;
    the Winner card and `scored` events all assume `classic`; the disambiguation was written
    *pre-emptively* to prevent exactly this collision.
  - **A2 — Golden Room IS the blind mode (conform the canon to the code).** Keep the code; rewrite
    the canon so "Golden Room" means blind/sealed. *Steelman:* zero code change; the commit-reveal
    machinery is built and tested. *Against:* contradicts the Operator's own design canon (the named
    source of truth), the Figma screens (which show live `scored`/leaderboard), `golden-rooms.md`,
    and the `04-sections.md:107-110` two-paths enumeration; the Winner card + live leaderboard on the
    in-progress screen would all be wrong. Rewriting the canon to match a defaulting accident inverts
    the precedence the Operator set.
  - **A3 — both, explicitly (a Golden Room MAY be blind via a flag).** Keep the boost class as
    `classic` by default, but allow `create_golden_room(..., type: "golden")` for a blind golden
    promotion. *Steelman:* maximal flexibility. *Against:* re-introduces the collision under a
    pass-through; the canon treats them as two named surfaces, not one parametric one — better kept
    apart until the `screens/game-golden/` design lands.
- **RECOMMENDATION: A1.** The canon is the fixed point; the code is the drift. Decouple the boost
  axis from the mode axis: `golden:true` rides `type:"classic"`. The blind mode remains, reached only
  by an explicit `type:"golden"`, and is the `screens/game-golden/` surface to be built separately
  (`04-sections.md:110`).
- **Consequences.** `create_golden_room/3` no longer forces `type` (`game.ex:208`); `create_room`'s
  `type` default decouples from `golden` (`rooms.ex:31`). Golden Rooms now fire `close_live`
  (winner-take-all over `effective_pool`) + live `scored` + the Winner card. The blind commit-reveal
  path (`close_sealed`, `seal_commitment`) is untouched and still exercised by an explicit
  `type:"golden"` game — no test deletion, no dead code. The disambiguation note in `design.md` must
  state the axes are independent.

### ADR F-B — Threshold scope: hardcoded vs a prop; golden-only vs all rooms

- **Context.** The locked constant is `10`. Open: is `10` hardcoded, a room/game prop, and does the
  participation gate apply only to Golden Rooms or to all rooms?
- **Options.**
  - **B1 — a `threshold` prop on room+game, default 10, applied to ALL rooms.** Mirror the `golden` /
    `payout_split` pattern (a defaulted column snapshotted onto the game, `design.md:130-135`).
    *Steelman:* uniform model; tunable per promotion; snapshot-at-start keeps an in-flight game's
    terms fixed (the room's standing rule, `golden-rooms.md:6`); a default of 10 means existing
    behaviour for any room is "gather 10 then start." *Against:* changes the start semantics for
    *every* room, not just Golden — a bigger behavioural change than the constraint strictly names.
  - **B2 — a `threshold` prop, default 10, applied ONLY when `golden:true` (else first-join, as
    today).** *Steelman:* the locked constraints name the **Golden Room** specifically; this scopes
    the change to exactly what was asked and leaves ordinary rooms' first-join start intact.
    *Against:* two start regimes coexist (a branch on `golden`); the `N/10` counter is golden-only on
    the board.
  - **B3 — hardcoded `10`, golden-only, no prop.** *Steelman:* simplest. *Against:* a magic number;
    no per-promotion tuning; a later "make it 5" is a code change, not a config.
- **RECOMMENDATION: B2 with the threshold as a defaulted prop (10), gated on `golden:true`.** It
  matches the locked scope (the *Golden Room* timer), follows the established defaulted-prop +
  snapshot pattern, and keeps the threshold tunable per promotion. The participation gate is
  `golden and members_count < threshold`; an ordinary room keeps first-join start (`ends_ms` set at
  `start_game`). If the Operator wants the gate everywhere, B1 is the clean generalization (same
  mechanism, drop the `golden` guard).
- **Consequences.** A `threshold` column on `rooms` + `games` (defaulted 10, CHECK > 0), snapshotted
  at start. The start path branches on `golden`. The `N/10` counter surfaces on Golden Rooms; on the
  board it shows for a golden game and the live participant count otherwise.

### ADR F-C — Gathering-phase shape: a new state vs `open` + `ends_ms:nil`

- **Context.** While `members_count < threshold` the game accepts guesses (members are *defined* by
  guessing) but the timer is not running. How is that phase represented?
- **Options.**
  - **C1 — reuse `open` with `ends_ms = nil` (the recommendation).** The game is `open` from first
    join, accepts guesses, `ends_ms` stays `nil` until the threshold-crossing guess sets it.
    *Steelman:* zero CHECK/migration churn; `submit` already admits on `:open` (`game.ex:27`); every
    expiry path already no-ops on a non-integer `ends_ms` (`game.ex:48-53`, `rooms.ex:302`); the
    gathering vs in-progress distinction is a derived view flag (`ends_ms == nil`), not a new column.
  - **C2 — a new `gathering` state before `open`.** Add `gathering` to the seven-state CHECK ladder
    (`design.md:136`); `start_game` enters `gathering`; the threshold-crossing guess transitions
    `gathering → open` and sets `ends_ms`. *Steelman:* the state word *names* the phase; cleaner
    introspection. *Against:* touches the CHECK-bounded ladder (a migration + a `games_type`/status
    CHECK edit, the very surface `design.md:136` pins); and `submit` admits only on `:open`
    (`game.ex:27`), so `gathering` would *also* have to admit guesses — at which point `open` no
    longer means "accepting guesses," so the new state buys naming, not behaviour. More surface for
    the same outcome.
  - **C3 — keep the room (not the game) in `waiting` until the gate, mint the `GAM` at the threshold.**
    *Steelman:* no in-flight gathering game. *Against:* violates the locked definition — members are
    `PLR`s who have *guessed in the `GAM`*, so the `GAM` must exist (with a snapshotted keyboard +
    secret) to accept those guesses *during* gathering. A guess needs a game id (`game.ex:104`). This
    reading is impossible under constraint #2.
- **RECOMMENDATION: C1 (`open` + `ends_ms:nil`).** The locked constraint forces the game to accept
  guesses while gathering, so `open` must stay the guess-accepting state regardless; a separate
  `gathering` state duplicates that meaning. `ends_ms:nil` is already the engine's "timer not
  running" sentinel.
- **Consequences.** `start_game` sets `ends_ms: nil` (`rooms.ex:95`); the score path sets `ends_ms`
  on the threshold-crossing guess. `game_view` derives `gathering = ends_ms == nil` (equivalently
  `members_count < threshold`). The seven-state ladder is unchanged — no migration to the CHECK. The
  `design.md` state-machine §gains the gathering description but not a new state word.

### ADR F-D — The never-fills case: void / refund / wait

- **Context.** A Golden Room is all-pay (every guess debits keys/clips at `charge_guess`,
  `game.ex:33`) and its pool is platform-seeded. If gathering never reaches the threshold, the timer
  never starts — yet players have *paid* for guesses. This is a player-fairness + economic-exposure
  question (the kind `design.md:188` + `golden-rooms.md:56` say belongs with the chief architect +
  legal).
- **Options.**
  - **D1 — void-and-refund on a gather deadline (the recommendation).** Stamp `gather_by_ms = now +
    gather_window` at start; a sweep that finds `members_count < threshold` past `gather_by_ms`
    transitions the `GAM` to `voided` (the canon abort state, `design.md:136`) and refunds every
    charged guess fee via a new `Wallet.refund_guess` (mirroring `deposit_prize`, a paired `TXN`).
    *Steelman:* fairest to the player — an all-pay room that cannot settle returns the all-pay fees;
    uses the existing `voided` state; bounded platform exposure (refund only what was charged).
    *Against:* a refund path + a gather-window sweep + a void settlement variant to build.
  - **D2 — wait forever (no gather deadline).** The game sits in `open` + `ends_ms:nil` until the
    10th guesser. *Steelman:* simplest; matches today's first-join rooms, which also have no
    abandonment timer; matches "the room recycles only after a game settles." *Against:*
    non-refundable fees on a never-settling paid room; the seed pool is locked in a game that can
    never recycle — poor fairness for an all-pay room.
  - **D3 — start on timeout with `< threshold` (degrade the threshold).** If `gather_by_ms` passes
    with `members_count >= 1` but `< threshold`, start the timer with whoever has guessed. *Steelman:*
    keeps the game + the seed pool live; no refund path. *Against:* silently weakens the locked "10
    players" contract — a soft threshold the Operator must explicitly own.
- **RECOMMENDATION: surface as a FORK; lead D1 (void-and-refund) on player-fairness grounds.** An
  all-pay room that cannot settle MUST return the all-pay fees, and `voided` already exists for it.
  D3 is the viable "keep it live" alternative *if* the Operator accepts a soft threshold. D2 is only
  acceptable for **free** (clips) rooms, where the fee carries no economic value (`01-currency-model.md`
  — clips are excluded from the available balance).
- **Consequences (D1).** A `gather_by_ms` column + a gather-window default; a sweep extension
  (`close_if_expired`'s sibling for the gather deadline); `Wallet.refund_guess` + a void-refund path
  reading the `guesses` charged in the GAM; `voided` becomes a reachable terminal state. The refund
  policy (full fee? minus a processing cut?) is itself an economic call nested under this fork.

### ADR F-E — Member-by-guess: the SADD move + the `total_players` semantic flip

- **Context.** Today `cm:<game>:players` is the join set (`rooms.ex:160`), read as `total_players`
  (`view.ex:117`). The locked definition makes membership ≥1-guess.
- **Options.**
  - **E1 — a NEW `cm:<game>:members` set; keep `players` as the join set (the recommendation).**
    `SADD cm:<game>:members <player>` on the player's first scored guess (after `Board.record`,
    `game.ex:122`); `members_count = SCARD cm:<game>:members` drives the threshold + the counter.
    `cm:<game>:players` stays the join set for any join-count need. *Steelman:* the two notions are
    genuinely distinct (joiners vs participants); keeping both is honest and avoids overloading one
    key with two meanings; the SADD is idempotent (a set), so repeated guesses no-op; one new key in
    the `cm:<game>:` family (`design.md:139`). *Against:* `total_players` (`view.ex:117`) must be
    re-pointed — does the board's "players" stat mean joiners or participants? Under the locked
    constraint #3 (the `N/10` counter is the participant count), the board stat should read
    **members**, so `game_view.totals.players` re-points to `members_count` (or a new
    `members`/`participants` field is added and the surface reads it).
  - **E2 — REPURPOSE `cm:<game>:players` to mean guessers (move the SADD from join to first-guess).**
    Drop the join-time SADD (`rooms.ex:60,116`); SADD on first guess instead. *Steelman:* one key, no
    new key; `total_players` already reads it and now means participants with no view change.
    *Against:* loses the join-count entirely (no record of who entered but never guessed); a silent
    semantic flip of an existing key is a drift hazard (the same overload class the BCS law warns
    against — one name, two meanings); any reader assuming "players == joiners" breaks.
  - **E3 — derive membership from the `guesses` table (no Valkey set).** `members_count = SELECT
    COUNT(DISTINCT player) FROM guesses WHERE game = ?`. *Steelman:* no new key; Postgres is the
    record. *Against:* a per-guess COUNT(DISTINCT) on the hot path (the threshold is checked on every
    guess until it crosses) is more expensive than a `SCARD`; the score path is the Valkey-fast lane
    (`game.ex:120-122` already writes `attempts` + the board to Valkey), so a Valkey set is the
    consistent substrate.
- **RECOMMENDATION: E1 (a new `cm:<game>:members` set), and re-point the board's participant stat to
  `members_count`.** It keeps the two notions distinct, follows the `cm:<game>:` Valkey-family
  pattern, and the SADD-on-first-guess is a one-line idempotent add at the existing score-path Valkey
  block (`game.ex:120-122`). The join set survives for any join-count need.
- **Consequences.** `cm:<game>:members` added to the keyspace family (`design.md:139`); the score
  path gains a `SADD` + the threshold check (and, on crossing, the `ends_ms` write — B-2); `game_view`
  exposes `members_count` and re-points (or adds) the participant stat; `total_players` semantics are
  documented (joiners vs participants) so no reader is surprised.

### ADR F-F — The counter surface (where the `N/10` lives + what it reads)

- **Context.** Constraint #3: the same `N/10` counter surfaces on the Gameplay screen. The screens
  already render a player count in a fixed center-top stat slot (timer · count · pool, verified in
  `94:2974` + `1089:19410`).
- **Options.**
  - **F1 — re-purpose the existing center-top stat slot (the recommendation).** The counter is a
    *value-source* change on the slot the screens already have: gathering → `N/10` + "waiting for
    players"; in-progress → the live participant count (`members_count`). *Steelman:* no new UI
    element; the placement constraint #3 is satisfied by the existing slot; the engine change is the
    `game_view` fields (B-3). *Against:* the slot's meaning shifts between phases (a count-to-threshold
    vs a live count) — the copy must make the phase legible.
  - **F2 — a dedicated gathering banner above the board, separate from the in-progress stat.**
    *Steelman:* unambiguous gathering affordance. *Against:* a new surface element; constraint #3
    says "the same counter," which reads as the existing stat, not a new banner.
- **RECOMMENDATION: F1.** Bind the counter to the existing center-top stat slot; `game_view` exposes
  `gathering`, `members_count`, `threshold`, and the frontend renders `N/threshold` while
  `gathering`, the live count after. The countdown is hidden while `ends_ms == nil`.
- **Consequences.** `game_view` (`view.ex:49-87`) gains `gathering`/`members_count`/`threshold`; the
  Figma surface docs (`02-board.md`, `03-rooms.md`) describe the gathering phase + the counter in the
  center-top slot. Exact RU/EN copy is a design-copy decision (the engine ships the numbers + the
  `gathering` flag).

---

## D. Where each delta lands (engine specs vs design canon)

| delta | engine specs `docs/codemojex/**` + `echo/apps/codemojex/docs/**` | design canon `node/codemoji-design/**` |
|---|---|---|
| **B-1** decouple boost/mode (F-A) | `codemojex.design.md` disambiguation note (axes independent; Golden Room = `classic` + boost); the spec triad body | `gameplay/README.md:119-126` + `03-rooms.md:11` already correct — **no change** (the canon is the fixed point) |
| **B-2** participation-gated start + member-by-guess (F-B/C/E) | `codemojex.design.md` §state-machine (the `open`+`ends_ms:nil` gathering phase, the `threshold`, the `cm:<game>:members` set at `:139`); `golden-rooms.md` (start rule: "first to join" → "timer starts at N guessers"); the spec triad body | `gameplay/03-rooms.md` (the in-progress screen description gains the gathering phase); `gameplay/README.md` game-states note (`open` spans gather/in-progress) |
| **B-3** `N/10` counter + gathering surface (F-F) | `codemojex.design.md` §"The web surface" (`game_view` gains `gathering`/`members_count`/`threshold`); the spec triad body | `gameplay/02-board.md` + `03-rooms.md` (the board + Golden Room screens gain the gathering phase + the counter in the center-top stat slot) |
| **B-4 / A-5** tier-system demotion + strike "first-mover tiers" | `game_rules.md` (banner the §30-Tier + §Future as NOT shipped; future-flag the summary "Tier" + "first-mover bonuses"); `golden-rooms.md:4` ("first-mover tiers" → "linear scoring") | `gameplay/01-onboarding.md:74` already correct — **no change** |
| **A-6** fee→pool (F-G fork) | `game_rules.md:41-52` + the in-app rules string reconciled to the chosen outcome (default: platform-seeded; strike the fee→pool copy) | `screens/game/README.md:112-116` already flags it — **no change** (the flag stays as the record of the resolution) |
| **A-7 / A-8** duration + `147` mock | note-only; optional `create_golden_room/3` duration default is a promotional call | **no change** (a mock, not a contract) |

**Summary of the landing rule:** the **design canon is the fixed point** — almost every delta lands
in the **engine specs + the engine code** (via Mars), bringing the engine *to* the canon. The only
design-canon edits are *descriptive additions* on `02-board.md` / `03-rooms.md` to document the new
gathering phase + the `N/10` counter (the screens themselves already render the stat slot); the
canon's Golden-Room *definition* needs no correction because it was already right.

---

## E. The forks the Director must carry to the Operator (summary)

| fork | the question | Venus-B recommendation |
|---|---|---|
| **F-A** | Which "Golden"? boost class on `classic`, or the blind mode? | **Boost class on `classic`** (conform the engine to the canon; the blind mode is the separate `screens/game-golden/` surface, reached by explicit `type:"golden"`) |
| **F-B** | Threshold: hardcoded 10 vs a prop; golden-only vs all rooms? | **A defaulted `threshold` prop (10), gated on `golden:true`** (B1 generalizes to all rooms if wanted) |
| **F-C** | Gathering phase: a new state vs `open` + `ends_ms:nil`? | **`open` + `ends_ms:nil`** (zero CHECK/migration churn; the engine already no-ops expiry on a nil `ends_ms`) |
| **F-D** | The never-fills case: void / refund / wait? | **FORK (economic/legal): lead void-and-refund** on a gather deadline (`voided` already exists); D3 soft-threshold is the "keep it live" alternative; D2 wait-forever only for free rooms |
| **F-E** | Member-by-guess: SADD move + `total_players` flip? | **A new `cm:<game>:members` set** (keep the join set); re-point the board's participant stat to `members_count` |
| **F-F** | The counter surface? | **Re-purpose the existing center-top stat slot**; `game_view` exposes `gathering`/`members_count`/`threshold` |
| **F-G** | Fee → pool accrual (A-6): intended economy, or platform-seeded canonical? | **FORK (economic): lead platform-seeded** (strike the fee→pool copy); fee-funded is new economy to build |

---

## F. Reconcile delta table (claims probed against disk)

| claim | source | disk | verdict |
|---|---|---|---|
| `create_golden_room/3` sets `golden:true` over `create_room/3` | `golden-rooms.md:20` | `game.ex:208` `Keyword.put(opts, :golden, true)` | **MATCH** |
| `golden:true` defaults `type:"golden"` | (collision) | `rooms.ex:31` `if(golden, "golden", "classic")` | **MATCH** (this is the defect A-1) |
| `policies_for("golden")` = blind/sealed | — | `rooms.ex:127-128` `feedback:"none", settlement:"sealed"` | **MATCH** |
| first-join starts the timer (`ends_ms`) | `design.md:143` | `rooms.ex:68→95` `ends_ms = now + duration_ms`, `:109` `status::open` | **MATCH** |
| `cm:<game>:players` SADD on join | `design.md:139` | `rooms.ex:160` `SADD`, called `:60,:116` | **MATCH** |
| `total_players = SCARD cm:<game>:players` | — | `view.ex:117` | **MATCH** |
| score path → `Board.record` (member-SADD insertion point) | `design.md:166` | `game.ex:103→122` | **MATCH** |
| expiry no-ops on non-integer `ends_ms` | — | `game.ex:48-53` (`expired?`), `rooms.ex:302` (`close_if_expired`) | **MATCH** (powers F-C Opt A) |
| seven canon states, `open→settled` (classic) | `design.md:136,162` | `rooms.ex` traversal; `design.md:141-162` figure | **MATCH** |
| pool is platform-seeded, no fee→pool code | `screens/game/README.md:112-116` | `rooms.ex:33,97` `seed_pool`; `charge_guess` debits keys/clips only (`game.ex:33`) | **MATCH** (A-6 defect confirmed) |
| Golden Room canon = boost class on classic, live | `gameplay/README.md:119-126`; `04-sections.md:107-110` | the four canon files | **MATCH** (the canon is consistent) |
| `golden-rooms.md:4` "same first-mover tiers" vs no-tier engine | `design.md:139` | `golden-rooms.md:4` literally says "tiers" | **STALE** (A-5 doc defect) |
| `game_rules.md` 30-tier presented as current | `design.md:84` | `game_rules.md:185-227,250` | **STALE** (A-5 doc defect) |
| sibling blind surface `screens/game-golden/` | `screens/game/README.md:12` | the README references it | **MATCH** (design intends two surfaces) |

**Verdict: BUILD-GRADE as a design spec.** No INVENTED claims; every fork has ≥2 steelmanned
options + a recommendation; the four locked constraints are designed around, not relitigated. The
defects are real drift (A-1 code-vs-canon, A-2/A-3 locked-mechanic gaps, A-5 doc-vs-canon) with
concrete resolutions; A-6 and F-D are surfaced as Operator forks (economic/legal).

---

## G. Notes for the Director / cross-review

- **The Golden collision is low-ambiguity from the design-intent angle.** The canon disambiguated it
  pre-emptively across four files; the code is the drift, not the canon. If Venus-A reaches the same
  A1 resolution, that convergence is confidence. A divergence (e.g. Venus-A favouring "Golden Room IS
  blind") would be the fork worth surfacing — but the precedence the Operator set (the design canon
  is the named source) points hard at the boost-class reading.
- **The two genuine economic/legal forks are F-D (never-fills refund) and F-G (fee→pool).** Both are
  the kind `design.md:188` + `golden-rooms.md:56` explicitly reserve for the chief architect + legal;
  the engine deltas are mechanical once the policy is ruled.
- **The cheapest behavioural landing is F-C Opt A + F-E E1:** `open` + `ends_ms:nil` + a new
  `cm:<game>:members` set + a `game_view` flag — no CHECK/migration churn, no new state word, the
  expiry paths already safe on a nil `ends_ms`. If the Operator wants the gate everywhere (B1), the
  mechanism generalizes by dropping the `golden` guard.
