# cm.5 — The Golden Room Tournament Engine (the build brief)

> **Status — the BUILD brief Mars builds from, REVISED to the Operator-locked economy (`D-7`).** The design is
> settled (the calibration scope `codemojex-golden-calibration`, ledger `D-18`; the binding target
> [`echo/apps/codemojex/docs/golden-rooms.md`](../../../echo/apps/codemojex/docs/golden-rooms.md); the
> consolidated launch model [`economy/economy.md`](economy/economy.md) §8) and then **refined into its final
> launch shape by the Operator** (the cm-5 ledger `D-7`: the virtual-deposit / first-mover / guess→pool /
> no-refund model, and the three forks RESOLVED). This is **not a re-design** — it is the agent contract for the
> unbuilt tournament engine, grounded NO-INVENT in `echo/apps/codemojex` at a real `file:line` or marked
> *(new)* / *(forward)*. Authored by **Venus** (the code/wire/economy lens); the relational redesign — every
> column type/null/default/CHECK/index, the migration shape, and the exact DB target — is **VenusPG's** parallel
> deliverable ([`progress/cm-5.postgres.design.md`] equivalent), cited here by **constraint** ("the relational
> redesign (VenusPG)"), never by reading. This is a **DATA-MODEL · money-critical · HIGH-risk** rung (`D-1`):
> Apollo is mandatory.
>
> **The three earlier forks are RESOLVED by `D-7`** (recorded as decisions in §3, no longer arms): **F-1** →
> the pool is **diamonds**, converted at buy-in; **F-2** → a per-room **`room_deadline`** (DATETIME) that
> drives bot-engagement notifications and the void; **F-3** → **drop** `gold_multiplier` (unconditional). A
> single residual is coordinated with VenusPG: the physical type of `room_deadline` and whether it **is** the
> game-end (`ends_ms` aligns to it — the Director's lean, a fixed promotional-event end) or a separate gather
> window.

## 0. The rung in one paragraph

A **Golden Room** is the launch tournament: a `type:"classic"` game marked `golden:true` that forms in a new
**`:gathering`** state (`started_ms` set to the creation time, `ends_ms` nil, no timer) with its **diamond
prize pool seeded by a configurable `virtual_deposit` (~$10)**. Entry costs a configurable **`entry_fee_keys`
(8 keys = 80💎)**, charged at join; paying makes the player a **member** and runs a **fee waterfall**: the
**first `start_threshold` (10) fees go to the platform** (recovering the virtual deposit — zero/near-zero
loss), the next **`first_movers` (N) members split their fee** (`entry_fee_revenue_percentage`% to the
platform, the rest to the pool), and every member beyond that pays **100% platform revenue**. When the tenth
paid member joins, the live timer arms (`:gathering → :open`) under an exactly-once `SET cm:<game>:started NX`
guard, with **`ends_ms` aligned to `room_deadline`** (the fixed event end). **Every guess additionally funds
the pool** (its full fee ×10 → diamonds). On close the pool — held as **one running diamonds record,
transferred to no one until finish** — is distributed in **one atomic ledger transaction**: the **top-K split
it proportionally** (`close_split`, reusing `Economy.top_k_split/3`, **mirroring `close_live` not
`close_sealed`**), and **every other member receives consolation clips** (`max_score / 10`). Entries are
**non-refundable**: a field that never gathers by `room_deadline` is simply **voided** (`close_void` — the
platform keeps the fees, reclaims the unpaid deposit; **no refund**), fired by a newly **wired periodic sweep**
that also drives the timer-close and the bot-engagement nudges. The buy-in's **double-charge** exactly-once is
enforced by a **Postgres partial unique index** on `transactions(player, ref) WHERE reason='buy_in'` inside the
**same** `Repo.transaction` as the debit and the atomic pool `+` (the Valkey `cm:<game>:paid` key is a
fast-path **hint, never the source of truth** — the L-10 gate). The legacy **`gold_multiplier` is dropped**
(`D-16`). The launch ships a free warm-up room **"Бокс для разминки"** and one Golden Room.

## 1. References (read first, in order)

1. The cm-5 ledger [`progress/cm-5.progress.md`](progress/cm-5.progress.md) **`D-7`** — the Operator-locked
   economy (the binding model this brief encodes) — and VenusPG's coordination decisions **`D-2`** (the
   gathering relaxation: +1 CHECK value, `ends_ms` nullable, `started_ms` stays NOT NULL), **`D-3`** (the
   exactly-once index design — now **one** `buy_in` partial unique index + a read index, the `buy_in_refund`
   index **removed**), **`D-4`** (`Wallet.buy_in` + `close_void` = **ONE `Repo.transaction` each, NO
   `Ecto.Multi`**), **`D-5`** (one additive migration; both shipped migrations byte-frozen; explicit up/down).
2. [`echo/apps/codemojex/docs/golden-rooms.md`](../../../echo/apps/codemojex/docs/golden-rooms.md) +
   [`economy/economy.md`](economy/economy.md) §8 — the design target (the model; `D-7` supersedes where the
   pool funding / refund differ).
3. The calibration ledger [`progress/codemojex-golden-calibration.progress.md`](progress/codemojex-golden-calibration.progress.md):
   **L-7** (the `started NX` start-race), **L-8** (buy-in writes Postgres-only, `reason` is free-text →
   no enum migration), **L-9** (`close_split` mirrors `close_live`), **L-10** (the cross-store money-leak →
   the index-is-authority), and the **Y-10** TODO digest.
4. The as-built code: `lib/codemojex/{rooms.ex, game.ex, economy.ex, wallet.ex, view.ex, board.ex, notifier.ex,
   application.ex, store.ex}`, `lib/codemojex/schemas/{room.ex, game.ex, transaction.ex}`,
   `priv/repo/migrations/{20260618000000_create_codemojex.exs, 20260625145121_add_player_tg_user_id.exs}`,
   `test/stories/{settlement, golden_blind, rooms_and_games, privacy}_story_test.exs`,
   `test/support/codemojex/story.ex`.
5. **The relational redesign (VenusPG)** — owns every schema/migration/index/type detail. This brief states the
   *code constraint*; VenusPG states the *DDL*. Coordinate by constraint, not by reading.

## 2. Requirements (each traced: → `D-7` clause · → story §5.x · → invariant §9)

### The economy (the `D-7` core)

- **R-FEE — the entry fee.** Entry costs **`entry_fee_keys` keys** (default **8** = 80💎), a configurable
  per-room column snapshotted to the game (a marketing lever). Charged in **keys** at join (the Stars→keys
  rail, wallet.ex:108; Stars are pay-in only — no Stars-invoice). (`D-7` · S-BUYIN · INV-FEE)
- **R-SEED — the virtual deposit.** The diamond pool is **seeded with `virtual_deposit`** (diamonds, ~$10 ≈
  833💎; a configurable per-room column snapshotted to the game). A golden game initializes
  `prize_pool = virtual_deposit` at creation (a non-golden game keeps `seed_pool`). (`D-7` · S-VIRTUALDEPOSIT ·
  INV-VIRTUAL-DEPOSIT)
- **R-WATERFALL — the fee waterfall (the pool credit per buy-in).** For the joining member's 1-based paid
  **ordinal** `o` (the count of `buy_in` TXNs for the game, including this one):
  - `o ∈ [1, start_threshold]` → pool credit **0** (the fee → platform, recovering `virtual_deposit`);
  - `o ∈ [start_threshold+1, start_threshold+first_movers]` → pool credit
    `entry_fee_keys × (100 − entry_fee_revenue_percentage)/100 × 10` diamonds (the platform keeps
    `entry_fee_revenue_percentage`%); — the **first-movers** band;
  - `o > start_threshold + first_movers` → pool credit **0** (100% platform revenue).

  `first_movers` (N, e.g. 2) and `entry_fee_revenue_percentage` (0-100, the **platform's** share; 100 → nothing
  to pool, 0 → all to pool) are configurable per-room columns snapshotted to the game. (`D-7` · S-FIRSTMOVER ·
  INV-FIRSTMOVER)
- **R-GUESSPOOL — every guess funds the pool.** For a golden (paid) game, each guess adds its **full fee
  ×10 → diamonds** to `prize_pool`, atomically with the keys charge. **This SUPERSEDES** the earlier
  "per-guess fees are platform revenue" — strike that framing from the economy/privacy/fairness prose. (A
  non-golden game's guess charge is unchanged.) (`D-7` · S-GUESSPOOL · INV-GUESS-POOL)
- **R-HOLD — the holding record + the one-transaction distribution.** `prize_pool` is **one running diamonds
  record, transferred to no player until finish**. At finish the pool is distributed as **one best-practice
  `Repo.transaction`** (the top-K diamond credits + the consolation clip grants + the settled-state write,
  recording room/game/prize_pool/splits). Revenue realizes at game **start**; the pool pays out only at
  **finish**. (`D-7` · S-SPLIT/S-CONSOLATION · INV-ONE-DISTRIBUTION)

### The engine (the state machine, settlement, lifecycle)

- **R1 — the `:gathering` state.** A golden game forms in `:gathering` with `started_ms` = the creation time,
  `ends_ms = nil`, no countdown; it accepts buy-ins and guesses. `'gathering'` is added to the `games_status`
  CHECK; `ends_ms`'s `null:false` is relaxed to nullable (**`started_ms` stays NOT NULL**, VenusPG `D-2`);
  `validate_required([:ends_ms])` (game.ex:67) is relaxed. (Y-10 #1 · S-GATHER · INV-STATE)
- **R2 — `start_threshold`.** A nullable per-room prop (nil = legacy first-join; `create_golden_room` defaults
  **10**), **snapshotted** onto the game. (Y-10 #2 · S-GATHER · INV-SNAPSHOT)
- **R3 — membership = the buy-in.** A member = a PLR with a `buy_in` TXN for the game; the gather counts **paid
  members**. SUPERSEDES member-by-guess (`D-9`). (Y-10 #3 · S-GATHER · INV-MEMBER)
- **R4 — `Wallet.buy_in` (the two-sided op, money-critical).** **ONE `Repo.transaction`** (the
  `convert_to_keys` idiom, wallet.ex:118; **NO `Ecto.Multi`**, VenusPG `D-4`): `lock(player)` FOR UPDATE → the
  non-negative CHECK → debit `entry_fee_keys` → an **atomic SQL `+`** on `games.prize_pool` by the
  waterfall's `pool_diamonds` (`update_all(inc: …)`, never an app read-modify-write; skipped when 0) → a
  paired `buy_in` TXN. **Exactly-once (double-charge) is the Postgres partial unique index** on
  `transactions(player, ref) WHERE reason='buy_in'` (a conflict ⇒ the whole transaction rolls back ⇒
  `:already_member`); the `SET cm:<game>:paid` Valkey key is a fast-path **hint only**. Charged **once at
  join**; writes **Postgres only** — no `Cache.put_game` (L-8). (Y-10 #4 · S-BUYIN · **INV-EXACTLY-ONCE-BUYIN**,
  the L-10 gate)
- **R5 — the gather gate (`:gathering → :open`).** When the paid-member count reaches `start_threshold`, arm
  the timer under a single `SET cm:<game>:started NX`: the winner sets `status = :open` and **`ends_ms =
  room_deadline`** (the fixed event end, the Director's lean — coordinate with VenusPG); every concurrent loser
  is a no-op. The count is **ledger-authoritative** (the `buy_in` TXN count). (Y-10 #9 · S-GATHER ·
  **INV-START-ONCE**, the L-7 gate)
- **R6 — `close_split` (the live top-K split).** A new `settlement:"live_split"` / `economy:"proportional"`
  policy dispatched in `do_close`. **It MIRRORS `close_live`'s shape** — a `Store.put_game`-only settle + the
  `announce_golden`/`{:golden_win}` fan-out — **NOT `close_sealed`** (no `Cache.put_game`, no `:revealing`, no
  `broadcast_revealed`/`{:revealed}`). The payer is `Economy.top_k_split/3` over `prize_pool` (the running
  record); the distribution is the one transaction (R-HOLD). (Y-10 #6 · S-SPLIT · **INV-NO-REVEAL**, the L-9
  gate)
- **R7 — consolation clips.** Inside the same distribution, **every member not in the top-K** receives
  `clips = max_score / 10` via `Wallet.grant(player, :clips, clips, "consolation")` (wallet.ex:114); a member
  who paid but never guessed scores 0 → 0 clips. (Y-10 #7 · S-CONSOLATION · INV-EVERY-MEMBER-PAID)
- **R8 — `close_void` (the never-fills close — NO REFUND).** On `room_deadline` a still-gathering game
  transitions `:gathering → :voided` under the `SET cm:<game>:closed NX` close lock and resets the room. **No
  refund, no player money moves** — entries are non-refundable (`D-7`); the platform keeps the collected fees
  and reclaims the (unpaid) virtual deposit. **REMOVED vs the prior draft:** the refund loop, `refund_buy_in`,
  the `buy_in_refund` index, the per-`(player,ref)` refund idempotency, INV-EXACTLY-ONCE-REFUND. (The forward
  `buy_in` double-charge index STAYS.) (`D-7` · S-VOID · INV-NO-REFUND)
- **R9 — wire the sweep + bot engagement.** A new supervised periodic process drives, idempotently under the NX
  locks: (a) the **timer-close** for `:open` games past `ends_ms` (`close_if_expired/1`, rooms.ex:298 — today
  zero callers); (b) the **never-fills void** for `:gathering` games past `room_deadline`; (c) **bot-engagement
  notifications** for `:gathering` golden games approaching `room_deadline` (nudges to members' chats via the
  notifier). (Y-10 #10 · S-SWEEP · INV-SWEEP-IDEMPOTENT)
- **R10 — `gold_multiplier` drop (`D-16`, unconditional, `D-7` F-3).** Remove every `mult` reader (the 12-site
  surface in §6), `Economy.effective_pool/3`, and **DROP the column** from `rooms` + `games` (the destructive
  migration; the Operator deploys the prod migration). `Notifier.golden_win/4 → /3`; `announce_golden/3 → /2`;
  `notify_winner/5 → /4`. The pool is paid as `prize_pool`, unboosted. (Y-10 #11 · S-RECONCILE · INV-NO-MULT)
- **R11 — `buy_in ⇒ not free`.** A changeset rule on the room: a `golden:true` room cannot be `free`. (Y-10 #12
  · S-NOTFREE · INV-NOTFREE)
- **R12 — `create_golden_room` + the U-1 fixture audit.** `create_golden_room/3` produces a **classic**-typed,
  `golden:true` tournament (defaults `start_threshold` 10 + the `D-7` economy columns): rooms.ex:31 stops
  defaulting `golden → type:"golden"` (blind is reached **only** by explicit `type:"golden"`). **Fixture
  audit:** `golden_blind_story_test.exs:21/:24` (repair to an explicit `type:"golden"` blind room, drop
  `gold_multiplier:`); run the full suite to catch any other (see §5 note on `settlement_story`). (Y-10 #13 ·
  S-CREATE/S-FIXTURE · INV-FIXTURE)
- **R13 — the launch config.** A seed/installer producing the two launch rooms: the free warm-up **"Бокс для
  разминки"** (`type:"classic"`, free, 1 clip/guess, no buy-in) and one **Golden Room** (`type:"classic"`,
  `golden:true`, `entry_fee_keys` 8, `virtual_deposit` ~833💎, `start_threshold` 10, `first_movers` + a
  `entry_fee_revenue_percentage`, a `room_deadline`, the live top-K + consolation). (Y-10 #15 · S-LAUNCH ·
  INV-LAUNCH)
- **R14 — the live counter + lobby.** `View.game_view/1` surfaces a gather counter (`paid/threshold`) for a
  `:gathering` game (cheap `SCARD cm:<game>:paid`); the lobby already shows the live pool + fee (view.ex:19-46,
  Postgres-read — unchanged). (Y-10 #3 · S-GATHER · INV-PRIVACY)

## 3. Fork resolutions (recorded as decisions — `D-7`; NOT arms)

- **F-1 (RESOLVED) — the pool is DIAMONDS, converted at buy-in.** The entry fee is keys (`entry_fee_keys`);
  `prize_pool` stays diamond-denominated; each pool credit converts keys→diamonds (`×10`, economy.ex:10) at
  buy-in. `top_k_split`, `deposit_prize`, and the `to_usd` display rails are unchanged. (The prior Arm B —
  a key-denominated pool — is rejected.)
- **F-2 (RESOLVED) — a per-room `room_deadline` (DATETIME).** Replaces `gather_deadline_ms`. Drives the void
  (unfilled-by-deadline → `:voided`, no refund) **and** bot-engagement notifications. **Residual coordinated
  with VenusPG:** the physical type (a `_ms` bigint idiom vs a real `:utc_datetime`) and whether `room_deadline`
  **is** the game-end — `ends_ms` aligns to it (the Director's lean, a fixed promotional-event end; §6/R5
  encode this lean) — or a separate gather window. VenusPG pins both.
- **F-3 (RESOLVED) — DROP `gold_multiplier`.** The migration drops the column from `rooms` + `games`
  (destructive; the Operator deploys the prod migration); the down re-adds with `default: 1`. R10 is
  unconditional.

## 4. Execution topology — the runtime shape

```
join_room(room, player)                  the entry fee is charged here (golden), exactly-once (double-charge)
  ├─ room :waiting   → start_game → golden: :gathering, prize_pool=virtual_deposit, ends_ms=nil
  │                                  non-golden: :open, prize_pool=seed_pool (legacy)
  ├─ room :active    → add_player to the live/gathering game
  └─ (golden)        → Wallet.buy_in(player, game)   [AS-BUILT — RULING 1 / D-12]
                       (the ordinal + the waterfall tier compute INSIDE the txn under the
                        games-row FOR UPDATE lock; join_room computes NO pool figure)
                       arm? (count ≥ threshold ⇒ SET …:started NX ⇒ :open, ends_ms=room_deadline)

submit(game,player)   charge_guess: golden ⇒ debit keys + atomic-+ prize_pool (guess_fee×10💎); else debit only
ScoreWorker.handle    a 600-crack closes only an :open game (guard the :gathering case)
Codemojex.Sweep       (NEW supervised child)  every tick:
  ├─ :open  past ends_ms          → close_if_expired/1   (rooms.ex:298, now wired)
  ├─ :gathering past room_deadline → close_void           (set :voided, NO refund)
  └─ :gathering approaching deadline → bot-engagement nudges (Notifier)
close_game → do_close → dispatch on :settlement
  ├─ "sealed"      → close_sealed   (blind, type:"golden" — mult-stripped, otherwise byte-unchanged)
  ├─ "live_split"  → close_split    (NEW — mirrors close_live; top_k_split + consolation; ONE distribution txn)
  └─ _             → close_live     (classic winner-take-all — mult-stripped)
```

**Build-order task DAG (smallest-change, BDD red → green → blue):**

1. **Schema + migration** (with VenusPG): the one additive migration — `'gathering'` CHECK · `ends_ms`
   nullable (`started_ms` NOT NULL) · the new columns (`start_threshold`, `entry_fee_keys`, `virtual_deposit`,
   `first_movers`, `entry_fee_revenue_percentage`, `room_deadline`) on rooms+games · the `buy_in` partial
   unique index + a read index · **DROP** `gold_multiplier` · (no `buy_in_refund` index) + the schema field
   edits. **Prove up/down first.**
2. **The reconcile-out** (R10): strip `gold_multiplier`/`effective_pool`/the mult args+text — keeps the suite
   compiling. (`close_live`/`close_sealed` compute `pool = prize_pool` directly.)
3. **Policies + dispatch** (R6 scaffold): `policies_for(type, golden)` adds `live_split`/`proportional`;
   `do_close` adds `"live_split" → close_split`.
4. **`Economy`** (the waterfall): `entry_fee_split/5` *(new, pure)* → the pool-credit diamonds for an ordinal;
   remove `effective_pool/3`.
5. **`Wallet.buy_in`** (R4) + **the guess→pool** in `charge_guess` (R-GUESSPOOL) — the money headline.
6. **`:gathering` + the gather gate** (R1/R2/R3/R5): `start_game` golden branch (seed `virtual_deposit`) +
   `join_room` buy-in wiring (the ordinal + the waterfall) + the `started NX` arm (`ends_ms = room_deadline`).
7. **`close_split` + consolation + the one distribution transaction** (R6/R7/R-HOLD); **`close_void`**
   (R8 — status-only, no refund).
8. **The sweep + engagement** (R9) in `application.ex`; **`create_golden_room` fix + fixtures** (R12);
   **`buy_in ⇒ not free`** (R11); **the view counter** (R14); **the launch config** (R13).
9. **New story tests** (§5) + the U-1 fixture repair; the gate ladder (§8).

**Boundary:** every touched file is under `echo/apps/codemojex/**` (+ this `docs/codemojex/specs/cm.5.*`). **No
sibling umbrella app**; `mix.lock` excluded.

## 5. Agent stories (Given/When/Then — the acceptance face; each a real `Codemojex.Story` scenario)

Model every scenario on the shipped harness (`use Codemojex.Story, …`; `@moduletag :valkey`; `setup`;
`scenario … do given_/when_/then_ … end`; `eventually/1`), as in `settlement_story_test.exs`. **A gate must
exercise its own outcome** — a positive proof, never a silent skip-or-pass.

- **S-VIRTUALDEPOSIT — the pool seeds and the first fees recover it.** *As the platform, I want a guaranteed
  prize without standing loss.* **Given** a Golden Room (`virtual_deposit` V, `start_threshold` 10), **When**
  the game forms and the first nine members buy in, **Then** `prize_pool == V` throughout (the first fees are
  platform revenue, not pool) and each member's keys were debited `entry_fee_keys`. (INV-VIRTUAL-DEPOSIT)
- **S-FIRSTMOVER — the first-movers split into the pool; the rest are revenue.** **Given** a started Golden
  Room (`first_movers` N, `entry_fee_revenue_percentage` p), **When** members 11..10+N then 10+N+1 buy in,
  **Then** the pool rose by `entry_fee_keys×(100−p)/100×10` per first-mover and **0** for member 10+N+1.
  (INV-FIRSTMOVER)
- **S-GUESSPOOL — a guess funds the pool.** **Given** a golden game with pool P, **When** a member submits a
  charged guess (fee `f` keys), **Then** `prize_pool == P + f×10` and the member's keys fell by `f`.
  (INV-GUESS-POOL)
- **S-GATHER — the tenth paid member arms the timer.** **Given** a Golden Room (`start_threshold` 10) and nine
  paid members (`:gathering`, `ends_ms` nil), **When** the tenth buys in, **Then** the game is `:open`,
  `ends_ms == room_deadline`, set once, and `game_view` showed `9/10` then `10/10`. (INV-START-ONCE, INV-MEMBER)
- **S-BUYIN — the buy-in is exactly-once (double-charge) and two-sided.** **Given** a member with sufficient
  keys, **When** they buy in twice (a re-join), **Then** keys are debited once, the pool moved by exactly one
  waterfall credit, exactly one `buy_in` TXN exists, and the second call returns `:already_member`. **And** a
  crash between the Valkey hint and the DB commit leaves no free play and no double-charge. (INV-EXACTLY-ONCE-BUYIN)
- **S-SPLIT — the top-K split the diamond pool, live, no reveal, one transaction.** **Given** a closed Golden
  Room with a ranked board, **When** `close_split` runs, **Then** the top-K are paid `top_k_split` shares (the
  whole pool drains, dust to rank 1) in one `Repo.transaction`, a `{:golden_win}` broadcast fired, and **no**
  `{:revealed}` event and **no** `Cache.put_game` occurred. (INV-NO-REVEAL — the L-9 gate; assert the event
  channel + cache, not just amounts. INV-ONE-DISTRIBUTION)
- **S-CONSOLATION — every other member is paid clips.** **Given** a closed Golden Room with members outside the
  top-K (one never guessed), **When** settlement runs, **Then** each non-top-K member received `max_score/10`
  clips and the never-guessed member received 0. (INV-EVERY-MEMBER-PAID)
- **S-VOID — a never-fills field voids with NO refund.** *As the platform, I keep non-refundable entries.*
  **Given** a Golden Room with buy-ins below threshold past `room_deadline`, **When** the void fires (and
  re-fires on a second tick), **Then** the game is `:voided`, the room reset, and **no** refund TXN exists and
  **no** member's balance rose. (INV-NO-REFUND)
- **S-SWEEP — the sweep drives the closes + engagement.** **Given** an `:open` game past `ends_ms` and a
  `:gathering` game past `room_deadline`, **When** the sweep ticks, **Then** the first settles via
  `close_if_expired/1`, the second voids, both idempotent on a second tick; **and** a gathering game before
  `room_deadline` emits an engagement notification. (INV-SWEEP-IDEMPOTENT)
- **S-CREATE / S-FIXTURE — `golden:true` is a classic tournament; the blind mode needs explicit `type`.**
  **Then** `create_golden_room/3` yields `type:"classic"`, `golden:true`, `start_threshold` 10; a blind game is
  produced **only** by `create_room(type:"golden")`. **And** `golden_blind_story_test` drives an explicit
  `type:"golden"` room and stays green. (INV-FIXTURE)
- **S-NOTFREE — a buy-in room cannot be free.** **Given** `golden:true` + `free:true`, **Then** the changeset
  is invalid. (INV-NOTFREE)
- **S-RECONCILE — no boost survives.** **Then** `grep gold_multiplier`/`effective_pool` over `lib/` is empty;
  the classic winner-take-all path pays `prize_pool` unchanged. (INV-NO-MULT)
- **S-PRIVACY — the privacy line holds.** A Golden Room is classic-typed → it fans out **live**; **Then** the
  shipped `privacy_story_test` stays green (no secret, no others' guesses). (INV-PRIVACY)
- **S-LAUNCH — the two launch rooms exist.** **Then** the launch config produces "Бокс для разминки" and one
  Golden Room with the `D-7` terms. (INV-LAUNCH)

> **Fixture-audit note (settlement_story):** `settlement_story_test.exs` exercises a **non-golden** classic
> room (`create_room`, `seed_pool` 1000, winner-take-all) — the guess→pool (R-GUESSPOOL) and the waterfall are
> **golden-only**, so its `{^alice, 1000}` assertion stays green untouched. If the Operator later extends
> guess→pool to **all** paid rooms, this fixture's expected payout becomes `seed + Σ(guess_fee×10)` — **flagged
> for the Director, not silently changed.**

**Coverage:** R-FEE→S-BUYIN · R-SEED→S-VIRTUALDEPOSIT · R-WATERFALL→S-FIRSTMOVER · R-GUESSPOOL→S-GUESSPOOL ·
R-HOLD→S-SPLIT/S-CONSOLATION · R1/R2/R3/R5→S-GATHER · R4→S-BUYIN · R6→S-SPLIT · R7→S-CONSOLATION · R8→S-VOID ·
R9→S-SWEEP · R10→S-RECONCILE · R11→S-NOTFREE · R12→S-CREATE/S-FIXTURE · R13→S-LAUNCH · R14→S-GATHER/S-PRIVACY.

## 6. The module / function MAP (every change at `file:line`; NO invented signature)

> Schema/migration/index **shapes are the relational redesign (VenusPG)**. Signatures marked *(new)* are this
> brief's contract.

**`lib/codemojex/economy.ex`**
- `:34-36` **remove** `effective_pool/3`.
- `entry_fee_split/5` *(new, pure)* — `entry_fee_split(ordinal, start_threshold, first_movers,
  revenue_pct, entry_fee_keys)` → the **pool-credit diamonds** for that ordinal (0 | the first-mover band
  share | 0), reusing `@diamonds_per_key` (`:10`). The platform portion is implicit (the player always pays
  `entry_fee_keys`). (R-WATERFALL)

**`lib/codemojex/wallet.ex`**
- **AS-BUILT `buy_in/2`** `buy_in(player, game)` (wallet.ex:203 — **RULING 1 / D-12 supersedes this brief's
  original `buy_in/4` literal**: the ordinal + the waterfall tier MUST compute inside the txn under the
  games-row lock; a pre-computed `pool_diamonds` in `join_room` would reopen the band-edge race the lock
  closes). **ONE `Repo.transaction`** (the `convert_to_keys` idiom; **NO `Ecto.Multi`**, VenusPG `D-4`):
  `lock_game(game)` **FOR UPDATE** (the per-game ordinal/gather/start serializer) → `lock(player)` →
  `ordinal = buy_in_count(game) + 1` (exact under the lock) → insert the `buy_in` TXN with **Pattern A**
  (`on_conflict: :nothing`, `conflict_target` byte-matched to the partial index `where:`); a SUPPRESSED insert
  (detected by the ledger count-delta, not the returned struct) ⇒ `:already_member`, mutating nothing; else
  `debit entry_fee_keys` → `pool = Economy.entry_fee_split(ordinal, …)` → `if pool > 0: inc_pool!(game, pool)`
  (the atomic `+`). Returns `{:ok, :member} | {:ok, :already_member} | {:error, reason}`. The `SET cm:<game>:paid`
  hint is set *outside* the transaction (fast-path only). (R4, **INV-EXACTLY-ONCE-BUYIN**)
- `charge_guess/3` (`:98`) — *(extend)* for a **golden** (non-free) game, make it two-sided in one transaction:
  debit `guess_fee` keys **and** `update_all(games, inc: [prize_pool: guess_fee × 10])`. A non-golden game is
  unchanged. (R-GUESSPOOL)
- `distribute_pool/3` *(new)* `distribute_pool(game, top_k_payouts, consolation_grants)` — **ONE
  `Repo.transaction`** crediting each top-K player's diamonds (`credit/5` discipline, wallet.ex:178) + granting
  each consolation player's clips + leaving the settled write to the caller; records each as a TXN `ref=game`.
  Replaces the per-winner `deposit_prize` loop for the golden split. (R-HOLD)
- **REMOVE** any `refund_buy_in` — there is no refund (R8).
- `grant/4` (`:114`) — **reused** for consolation clips.

**`lib/codemojex/rooms.ex`**
- `:31 create_room` — `type:` default stops forcing `"golden"` → `Keyword.get(opts, :type, "classic")`; add
  `start_threshold`, `entry_fee_keys`, `virtual_deposit`, `first_movers`, `entry_fee_revenue_percentage`,
  `room_deadline` to the room map; **remove** `gold_multiplier` (`:37-40`); enforce `buy_in ⇒ not free` (R11).
- `:68 start_game` — snapshot the `D-7` columns onto the game; `policy = policies_for(type, Map.get(room,
  :golden, false))`; a `golden:true` game forms `status: :gathering, started_ms: now, ends_ms: nil,
  prize_pool: virtual_deposit` (a non-golden game keeps `:open` + `seed_pool`); remove `gold_multiplier`
  (`:108`).
- `:54 join_room` — *(new behaviour, golden)* compute the ordinal `o` (ledger-authoritative paid-member count
  + 1) and `pool_diamonds = Economy.entry_fee_split(o, …snapshotted cfg…)`; call `Wallet.buy_in(player, game,
  entry_fee_keys, pool_diamonds)`; on `{:ok, _}` add the member + `arm_if_gathered/2` *(new defp)* (count ≥
  `start_threshold` and still `:gathering` ⇒ `SET cm:<game>:started NX` ⇒ `ends_ms = room_deadline`, `:open`);
  on `{:error, reason}` return it. (R3/R4/R5)
- `:127 policies_for` — *(new clause)* `policies_for(_classic, true) → %{feedback:"score", scoring:"linear",
  settlement:"live_split", economy:"proportional"}`; `("golden", _)` unchanged (sealed); `(_classic, false)` =
  today's live/winner_take_all.
- `:188 do_close` — add `"live_split" → close_split(game, r)`.
- `:196 close_live` — strip `golden`/`mult`/`effective_pool`: `pool = Map.get(r, :prize_pool, 0)`.
- `close_split/2` — *(new)* **clone `close_live`'s structure** (Store-only, the `announce_golden` fan-out —
  **no** `Cache.put_game`, **no** `:revealing`, **no** `broadcast_revealed`); read the board once
  (`Board.top(game, n ≥ members)`); `payouts = Economy.top_k_split(pool, board, payout_split)`; compute
  consolation (each member ∉ payouts → `max_score/10` clips); call `Wallet.distribute_pool/3` (the **one**
  transaction); then `Store.put_game(:settled)`, the `{:golden_win}` fan-out, `reset_room`. (R6/R7/R-HOLD)
- `:223 close_sealed` — strip `mult`/`effective_pool` only (`pool = prize_pool`); otherwise **byte-unchanged**.
- `close_void/2` — *(new, simple)* under `SET cm:<game>:closed NX`: set `:voided`, `reset_room`. **No refund,
  no money moves.** (R8)
- `void_if_stale/1` *(new)* — guards `:gathering` + `room_deadline` elapsed → `close_void` (the sweep calls
  it).
- `:258 notify_winner/5 → /4` (drop `mult`); `:267 announce_golden/3 → /2` (drop `mult` + the broadcast
  `multiplier:` key); `:298 close_if_expired/1` — unchanged, now **called by the sweep**.

**`lib/codemojex/game.ex`** (the facade + workers)
- `:208 create_golden_room/3` — yields `type:"classic"`, `golden:true` (via the rooms.ex:31 fix), default
  `start_threshold` 10 + the `D-7` columns.
- `:103 ScoreWorker.handle` — **guard the perfect-crack close** (`:144`): close **only** an `:open` game (a
  600 during `:gathering` builds standing, does not settle). (INV-STATE)
- `:33 Guesses.submit` — the keys charge now also funds the pool via the extended `charge_guess` (R-GUESSPOOL);
  no call-site change beyond passing the game map (already does).

**`lib/codemojex/view.ex`**
- `:49 game_view/1` — add `gather: %{paid: SCARD cm:<game>:paid, threshold: r.start_threshold}` when
  `status == :gathering` (R14). The lobby (`:19`) is unchanged.

**`lib/codemojex/notifier.ex`**
- `:50-55 golden_win/4 → /3` — drop the `multiplier` arg + the "Nx boost" text (R10); update rooms.ex:261.
- an **engagement** helper *(new/forward)* over `notify/3` (`:24`) — the gather nudge text (e.g. spots left /
  time to `room_deadline`); the sweep calls it per member chat (`Store.chat_of`). (R9)

**`lib/codemojex/application.ex`**
- `:23 children` — add a supervised `Codemojex.Sweep` child *(new module)* (a periodic `GenServer` /
  `:timer` loop) before the endpoint (R9); it enumerates due games via `Store.due_games/1`.

**`lib/codemojex/store.ex`**
- `due_games/1` *(new)* — `:open` games past `ends_ms`, and `:gathering` games (for the void + the engagement
  nudges) relative to `room_deadline` (the query shape + index = VenusPG). A ledger paid-member **count** read
  for the gather gate + the ordinal (count `buy_in` TXNs by game) — VenusPG owns the index.

**`lib/codemojex/schemas/{room.ex,game.ex,transaction.ex}`** *(field set + changeset only; DDL = VenusPG)*
- `room.ex` / `game.ex` — `+start_threshold, +entry_fee_keys, +virtual_deposit, +first_movers,
  +entry_fee_revenue_percentage, +room_deadline`; **−`gold_multiplier`** (room.ex:21/:44, game.ex:35/:65);
  relax `validate_required` to drop `:ends_ms` (game.ex:67); the `buy_in ⇒ not free` validation on `room.ex`
  (R11). `transaction.ex` — add the `unique_constraint([:player, :ref], name: <buy_in>)` hook (`:17`) — **only
  the `buy_in` index** (no `buy_in_refund`).

**`priv/repo/migrations/` (VenusPG owns the DDL; the code constraints — one additive migration, VenusPG `D-5`):**
`'gathering'` in the `games_status` CHECK · `ends_ms` `null:false → nullable` (`started_ms` stays NOT NULL) ·
the six new columns (rooms+games) · the `transactions(player,ref) WHERE reason='buy_in'` partial unique index +
a read index (template: the `tg_user_id` index, 20260625145121) · **DROP `gold_multiplier`** (rooms+games) · **no
`buy_in_refund` index**. `reason` is free-text (transaction.ex:20) — **no enum migration** for
`buy_in`/`consolation`.

## 7. The declared Valkey keys (additive to the braced `cm:<game>:…` family)

| Key | Shape | Role | Authority |
|---|---|---|---|
| `cm:<game>:started` | `SET … NX` | arms `:gathering → :open` exactly once (R5) | the lock IS the truth |
| `cm:<game>:paid` | `SADD`/`SCARD` | the buy-in fast-path **hint** + the view counter (R14) | **HINT ONLY** — the `buy_in` TXN ledger is the source of truth (L-10) |
| `cm:<game>:closed` | `SET … NX` | the existing close lock — **reused** by `close_split` + `close_void` (rooms.ex:181) | the lock IS the truth |

Existing, unchanged: `cm:<game>:players`, `cm:<game>:base`, `cm:<game>:board`, `cm:<game>:attempts`,
`cm:total_won`. The `cm:<game>:paid` realization (per-player `SET NX` vs a `SADD` set) is a mechanism within the
locked key name + NX semantics; `SADD`/`SCARD` is recommended (serves the dedup hint **and** the counter) —
confirm at build, not an Operator fork. **No `buy_in_refund` key** (no refund).

## 8. The gate ladder + acceptance (from `echo/apps/codemojex`, `TMPDIR=/tmp`)

1. **Re-probe** `asdf current` / `.tool-versions` from the app dir (do **not** hardcode the toolchain).
2. `valkey-cli -p 6390 ping` → `PONG`; Postgres accepting (the codemojex test DB).
3. `TMPDIR=/tmp mix compile --warnings-as-errors`.
4. **Migration proof (the destructive gate — the `gold_multiplier` DROP):** **surface the exact DB target
   first**, then `ecto.drop → ecto.create → ecto.migrate` (fresh-reinit) **and** `ecto.rollback →
   ecto.migrate` (down/up) on the **test** DB — both clean (the `down` re-adds `gold_multiplier`).
5. `TMPDIR=/tmp mix test --include valkey` — green, including the new economy + tournament stories
   (S-VIRTUALDEPOSIT/S-FIRSTMOVER/S-GUESSPOOL/S-VOID-no-refund) + the repaired U-1 fixture + the unchanged
   `settlement`/`privacy`/`rooms_and_games` stories.
6. **The ≥100 determinism loop** (the same-ms branded-id mint + the concurrent buy-in/Nth-member race;
   the first-mover band-edge ordinal is a loop target):
   `for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break; done`.
7. `TMPDIR=/tmp mix codemojex.stories` — regenerate the generated stories.
8. **Acceptance closure:** the migration up/down (#4) · the ≥100 loop (#6) · the privacy line (S-PRIVACY) ·
   the **U-1 fixture audit** (every golden test repaired; full suite green) · the **boundary grep empty**
   (`git diff --name-only ⊆ {echo/apps/codemojex/**, docs/codemojex/**}`) · the
   **`gold_multiplier`/`effective_pool` grep over `lib/` empty** · the money invariants exercised with positive
   proof. **Apollo MANDATORY** (money-critical) — the §11.2 charter: a prompted-checks table at `file:line`,
   ≥1 un-prompted finding, ≥1 attack-that-held, a mutation kill-rate.

## 9. Invariants (the named gates §5 exercises)

- **INV-EXACTLY-ONCE-BUYIN** (L-10, headline) — the buy-in is exactly-once **in Postgres** (the partial unique
  index), atomic with the debit + the pool `+`; the Valkey hint can crash either way without a double-charge.
- **INV-VIRTUAL-DEPOSIT** — the pool seeds with `virtual_deposit`; the first `start_threshold` fees are
  platform revenue (pool credit 0), recovering it (zero/near-zero loss).
- **INV-FIRSTMOVER** — members `start_threshold+1 .. +first_movers` credit the pool
  `entry_fee_keys×(100−revenue%)/100×10`; all others credit 0.
- **INV-GUESS-POOL** — a golden guess adds its full fee ×10 → diamonds to the pool, atomically with the charge.
- **INV-ONE-DISTRIBUTION** — at finish the pool pays the top-K + consolation in **one** `Repo.transaction`;
  nothing is transferred before finish.
- **INV-NO-REFUND** — entries are non-refundable; a never-fills game voids `:voided` with no money moving (the
  platform keeps the fees, reclaims the deposit).
- **INV-START-ONCE** (L-7) — exactly one buy-in arms the timer (`SET …:started NX`); `ends_ms = room_deadline`;
  the count is ledger-authoritative.
- **INV-NO-REVEAL** (L-9) — `close_split` mirrors `close_live`: no `Cache.put_game`, no `:revealing`, no
  `{:revealed}`; the `{:golden_win}` fan-out fires.
- **INV-STATE** — settlement fires only on a started (`:open`) game; a `:gathering` game transitions only to
  `:open` (gather) or `:voided` (deadline); a 600-crack during `:gathering` builds standing, does not settle.
- **INV-SNAPSHOT** — the `D-7` columns (`start_threshold`, `entry_fee_keys`, `virtual_deposit`, `first_movers`,
  `entry_fee_revenue_percentage`, `room_deadline`) are snapshotted at start; editing the room never changes a
  game in flight.
- **INV-MEMBER** — a member = a `buy_in` TXN (supersedes member-by-guess). **INV-EVERY-MEMBER-PAID** — top-K
  split diamonds; every other member gets `max_score/10` clips (0 if never guessed). **INV-NO-MULT** — no
  `gold_multiplier`/`effective_pool` survives; the column is dropped. **INV-FEE** — entry costs
  `entry_fee_keys` keys at join. **INV-NOTFREE** — `golden:true ⇒ not free`. **INV-PRIVACY** — the
  classic-typed Golden Room fans out live; the privacy stories stay green. **INV-SWEEP-IDEMPOTENT** — the
  sweep's closes are idempotent; gathering games get engagement nudges. **INV-FIXTURE** — every golden fixture
  is repaired. **INV-LAUNCH** — the two launch rooms exist.

## 10. Framing / propagation clause (binds this brief and every prompt derived from it)

Third person; no gendered pronouns for agents; no perceptual or interior-state verbs ("sees"/"wants"/"feels");
no first-person-agent narration ("we"/"I think"). Ground every named surface at a real `file:line` or mark it
*(new)* / *(forward)*. Surface forks; never decide them. Edit only within the `echo/apps/codemojex` boundary
(+ this spec); no sibling umbrella app; `mix.lock` excluded; agents run no git (the Director commits by
pathspec). Coordinate the schema by **constraint** with the relational redesign (VenusPG), never by reading.
