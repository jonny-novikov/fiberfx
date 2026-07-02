# Codemojex · Golden Rooms Calibration — Venus-A design (engine / state-machine / keyspace lens)

> **Status:** DESIGN-PHASE deliverable, dual-architect (Venus-A). No production code is written here; this is
> a spec + a complete inconsistency catalogue + the ADR set, for the Director to ratify and the Operator to
> rule. Every claim is grounded in a real `file:line` or design §; any forward-tense surface is marked.
> **Boundary:** this file only. Deltas it proposes land in `docs/codemojex/**` (engine specs) and
> `node/codemoji-design/**` (design canon) — stated per row in §D.
>
> **Lens.** Venus-A leads from the as-built Elixir engine: the `GAM` state machine, the `ends_ms` lifecycle,
> the `cm:<game>:players` participant substrate (`SCARD` as the threshold gate), the close-sweep guard, the
> score path as the membership-signal site, and the `SET NX` exactly-once + privacy invariants.

---

## 0. The calibration in one paragraph

The Operator named the gameplay design canon (`node/codemoji-design/gameplay/`) as the source of truth and
locked four constraints: (1) a Golden Room's timer starts when **10 players are in a game**; (2) "in a game"
= a `PLR` who has made **≥1 guess** in that concrete `GAM`; (3) the same **N/10** counter surfaces on the
gameplay board (`CODEMOJIES`); (4) the engine specs are **reconciled** to the canon — a complete drift
catalogue, not just the start mechanic. The headline finding is that **"golden" is overloaded onto two
opposite mechanisms** and the as-built `create_golden_room/3` builds the wrong one. Resolving that, then
adding a participation-gated start, reshapes the `GAM` state machine (a new `gathering` phase), moves the
membership signal from the join path to the score path, and adds a `start_threshold` room prop — all on the
existing Valkey `cm:<game>:players` set with one schema relaxation (`ends_ms` nullable) and two additive CHECK
values.

---

## A. The complete inconsistency catalogue

Severity key: **S1** breaks a locked constraint or builds the opposite of the canon · **S2** a substantive
drift the calibration must resolve · **S3** a stale line / naming hazard to fix in passing · **S4** cosmetic
or already-tracked.

Source columns: **CANON** = `node/codemoji-design/**` · **SPEC** = `docs/codemojex/**` +
`echo/apps/codemojex/docs/**` · **CODE** = `echo/apps/codemojex/lib/**` (+ migration/tests).

| # | Claim under test | CANON | SPEC | CODE | Sev | Recommended resolution |
|---|---|---|---|---|---|---|
| **I-1** | **What is a "Golden Room"?** | a **boost class on a `classic` base** — `golden:true` + `gold_multiplier`, live `scored` feedback, winner-take-all (`README.md:119-126`, `03-rooms.md:11,91,118`) | **SPLIT:** `golden-rooms.md:3-4,39-46` = boost-on-classic (agrees with canon); `codemojex.design.md:20-22` + `roadmap.md:7,75-81` = the **blind/sealed** mode | **blind/sealed:** `create_golden_room` (`game.ex:208`) sets `golden:true` → `rooms.ex:31` defaults `type:"golden"` → `policies_for("golden")` (`rooms.ex:127`) = `feedback none / settlement sealed` | **S1** | **F-A / D-1.** `create_golden_room/3` must yield a **`classic`-typed** game with `golden:true`+`gold_multiplier` (NOT `type:"golden"`). The blind mode survives as an explicit type, renamed off "golden" to end the overload. |
| **I-2** | **When does the timer start?** | (today, canon-described) first join starts; **(Operator-locked) starts at 10 participants** | first join → `start_game` snapshots + sets `ends_ms` (`design.md:143`, `roadmap` implied) | `rooms.ex:54`→`:64`→`start_game` `:95` `ends_ms = now+duration_ms`, `:109` `status:open` — first join starts | **S1** | **F-B/F-C/D-2,D-3.** A `gathering` state with `ends_ms:nil`; start fires when `SCARD players` hits `start_threshold` (a snapshotted room prop, default 10 for golden, nil = legacy first-join). |
| **I-3** | **What is "in a game" / room membership?** | a `PLR` who has **made ≥1 guess** in the `GAM` (Operator-locked participation) | the canon's "players" count is described as joiners (`02-board.md`, `screens/game/README.md:206`) | `add_player` SADDs `cm:<game>:players` on **JOIN** (`rooms.ex:160`, called `:60`+`:116`); `total_players` = `SCARD` (`view.ex:117`) | **S1** | **F-E/D-4.** Move the SADD from the join path to the **score path** (`game.ex` `ScoreWorker.handle`, after `Board.record` `:122`); `SCARD` now counts **participants**; the join path stops SADDing. |
| **I-4** | **The N/10 counter on the gameplay board** | a player count shown on the board + the Golden-Room screens (`02-board.md`, `03-rooms.md:101`, `screens/game/README.md:206`) | `view.totals.players` is in the game view (`design.md` reads) | `game_view` emits `totals.players` (`view.ex:72,81`) = `total_players` SCARD | **S2** | **F-F/D-6.** Surface the existing `SCARD` verbatim with the snapshotted `start_threshold` as denominator → "N/10"; one read, two screens. No new key. |
| **I-5** | **Golden Room default duration** | **48h** (`03-rooms.md:101` "48:00:00 ... multi-day promotional events") | `golden-rooms.md` silent on duration | `rooms.ex:32` default `duration_ms = 35h`; `create_golden_room` does NOT override it | **S2** | `create_golden_room/3` should default `duration_ms` to **48h** (`48*3_600*1000`) to match the canon screen; still overridable. Engine delta + a design note that 48h is the golden default. |
| **I-6** | **fee → prize pool accrual** | rules card: "**Every attempt adds crystals to the growing prize pool**" (`screens/game/README.md:112-116,177`); the pool "accrues over its life" (`design.md:26`, `roadmap.md:75`) | `design.md:26` "the room accrues a pool over its life"; pool is **platform-seeded** (`design.md` storage) | **NO code adds the fee into `prize_pool`** — `prize_pool = seed_pool` snapshot (`rooms.ex:97`), never incremented; the canon doc itself flags this (`screens/game/README.md:112-116`) | **S2** | Reconcile the **language**: either drop "every attempt adds to the pool" (the as-built truth: platform-seeded + golden-boosted) OR schedule fee-accrual as a forward `cm.5+` (the `BNK` bank, `roadmap.md:248`). RECOMMEND: reconcile to as-built now, leave accrual to `BNK`. Not in this rung's scope; cataloged. |
| **I-7** | **the tier system / "first-mover tiers"** | "**no tier ladder and no first-mover bonus**" (`README.md:98`, `01-onboarding.md:74`) | `roadmap.md:113-114` B7.4.2 "thirty tiers"; `golden-rooms.md:4` "the same first-mover tiers" | code is **linear-only** (`scoring.ex`, `board.ex:5-7` "no tier ladder"); migration has no `tier` column (`migration:115`) | **S3** | Already tracked for `roadmap.md` B7.4.2/B7.3 (`roadmap.md:171-175`). **ADD** `golden-rooms.md:4` to the same tier-reconcile set — it is the one un-tracked stale tier line. Doc-only. |
| **I-8** | **`golden` as a TYPE value vs a boolean** | canon uses **"golden"** only for the boost class (a boolean flag) (`README.md:123`) | `design.md:131` `type IN (classic\|golden)`; `roadmap.md` "golden (blind)" | the word "golden" is BOTH a `type` value (`"golden"`, `migration:108`) AND a boolean column (`golden`, `migration:99`); `create_golden_room` conflates them (`rooms.ex:31`) | **S1** | **F-A/D-1.** Decouple: `golden` (bool) = the boost; the blind feedback/settlement = a **type** renamed off "golden" (e.g. `"blind"` or `"sealed"`). The `games_type` CHECK changes accordingly (a schema fork — surface to Operator). |
| **I-9** | **the close-sweep is not wired** | the canon assumes a timer close (`03-rooms.md`, `design.md:162`) | `design.md:162` "or on the timer under a sweep" | `close_if_expired/1` exists (`rooms.ex:298`) but has **ZERO callers** in `lib/`; live closes = perfect-600 (`game.ex:144`) + explicit `Settle.close`/`close_now` | **S2** | Pre-existing gap (not introduced by this calibration). For the gathering design, the guard `status==:open` (`rooms.ex:302`) already makes a `gathering` game sweep-immune. The never-fills auto-close (F-D) needs a real sweep OR stays manual; cataloged + folded into D-2/D-5. |
| **I-10** | **`ends_ms` nullability** | n/a (canon is UI) | the state ladder sets `ends_ms` at open (`design.md:143`) | `ends_ms` is `null:false` (`migration:93`) AND `validate_required` (`game.ex:67`) | **S2** | **F-C/D-2.** A gathering game has no timer → `ends_ms` must be nullable. **Drop NOT NULL + drop from `validate_required`** (one migration + one changeset edit). Required under any gathering shape. |
| **I-11** | **anonymized leaderboard (golden)** | the Golden Room screens show **named** live ranking (`03-rooms.md:103` "Игроки / Лидерборд" with player rows) | `roadmap.md:79,235` "an anonymized leaderboard: generated neutral names" (forward, with `RMP`) | live board is by `PLR` name (`game.ex:131` `Store.player(player).name`) | **S3** | Consistent: the canon boost-class Golden Room is **classic-typed → named live board**; the "anonymized leaderboard" belongs to the **blind** mode + `RMP` (`roadmap.md:253`), not the Golden Room. Confirms F-A: the anonymized-board language attaches to the blind type, not "Golden Room". Doc clarification. |
| **I-12** | **state-machine entry word** | n/a | `design.md:136` ladder = `scheduled·open·active·revealing·settling·settled·voided`; `start_game` enters `open` | `start_game` sets `status:open` (`rooms.ex:109`); `scheduled`/`active` are in the CHECK but **unused** by the live flow | **S4** | The calibration adds `gathering` (D-2). Note that `active` is already an unused CHECK word — the ladder's prose (`design.md:141-162`) should be reconciled to what the flow actually traverses while adding `gathering`. Doc. |

**Headline (S1) drifts:** I-1, I-2, I-3, I-8 — the Golden collision and the three locked-constraint gaps.

---

## B. The calibrated Golden Rooms mechanics spec (the delta)

This is the concrete spec delta. Each sub-section states the new shape, the exact doc/§ it lands in, and the
engine surface it implies (forward-tense — Mars builds it; Venus does not).

### B.1 The state machine — a new `gathering` phase

The 7-word ladder gains an 8th word, `gathering`, **before** `open`:

```
   join a gathering-capable room (start_threshold set)
                │
                ▼
        ┌───────────────┐   guess → score (the cm lane)
        │   gathering   │◀──────────────────┐  ends_ms = nil (no timer)
        └───────┬───────┘                   │  SADD cm:<game>:players (score path)
   SCARD players │ reaches start_threshold   │  board + (live) scored events
   on the Nth    │  (the start trigger)      │
   participant   ▼                           │
            ┌──────────┐  guess → score      │
            │   open   │◀────────────────────┘  ends_ms = now + duration_ms  (set HERE)
            └────┬─────┘
   600 crack /   │  or timer ends_ms
   sweep         ▼
        SET cm:<game>:closed NX ── classic ▶ settled   (Golden Room = boost class: live, winner-take-all)
                                   blind  ▶ revealing ▶ settling ▶ settled
   gather_deadline (optional) ───▶ voided  (refund the all-pay gathering fees)
```

- A room with `start_threshold = nil` (the default for `create_room/3`) **skips `gathering` entirely** — it
  opens on first join exactly as today (preserves `rooms_and_games_story_test.exs:30`).
- A room with `start_threshold` set (the default 10 for `create_golden_room/3`) opens in **`gathering`**:
  guesses are admitted (a guess is the membership signal), the timer is not running.
- The transition `gathering → open` is performed by the **score worker** at the moment a *new* participant's
  SADD makes `SCARD` reach the threshold; that transition sets `ends_ms = now + duration_ms`.
- `gathering → voided` is the optional never-fills abort (B.4).

**Lands in:** `codemojex.design.md` §"The game as a state machine" (`:141-162`) — add `gathering`, redraw the
diagram, state the entry rule; `codemojex.roadmap.md` §"Games and guesses" state list (`:222`); the
`games_status` CHECK (migration) gains `'gathering'`. **Engine:** `rooms.ex` `start_game` chooses the entry
state by `start_threshold`; `ScoreWorker.handle` (`game.ex`) performs the gated transition.

### B.2 The `ends_ms` lifecycle

| Phase | `ends_ms` | Set by | Read by |
|---|---|---|---|
| `gathering` | **`nil`** | — (not started) | view returns `nil` → the surface shows "gathering N/10", no countdown |
| `open` (gated start) | `now + duration_ms` | the score worker, at the threshold-reaching guess | `expired?` (`game.ex:48`), the close sweep (`rooms.ex:302`), the surface timer |
| `open` (legacy, `start_threshold=nil`) | `now + duration_ms` at `start_game` | `start_game` (`rooms.ex:95`) — unchanged | as today |

The schema change (I-10): `ends_ms` becomes nullable (drop `null:false` in the migration; drop `:ends_ms`
from `validate_required` in `schemas/game.ex:67`). `started_ms` stays required (set at creation in both
paths). **Lands in:** the migration + `schemas/game.ex`; noted in `codemojex.design.md` §data-model `games`.

### B.3 The `cm:<game>:players` substrate change (member-by-guess)

- **Today:** `add_player/2` (`rooms.ex:160-161`) `SADD cm:<game>:players` on **join** — called from
  `join_room`'s active-game branch (`:60`) and `start_game` (`:116`).
- **Calibrated:** the SADD moves to the **score authority** — inside `ScoreWorker.handle`
  (`game.ex:103-152`), after the guess is durably scored (after `Board.record`, `game.ex:122`). The set is
  idempotent, so a player's 2nd..Nth guess is a no-op; `SCARD` = the count of **distinct participants**.
- The join path **stops** SADDing (a join no longer makes you a member).
- `total_players/1` (`view.ex:117`) and the view `totals.players` (`view.ex:72,81`) keep their **name**; their
  **meaning** flips from "joiners" to "participants" — this is the N/10 numerator.
- **The start trigger co-locates with the membership signal:** when the SADD returns 1 (a new member) and
  that makes `SCARD == start_threshold`, the same `handle` invocation runs the `gathering → open` transition.
  One place, one idempotent set — a re-delivered guess neither double-counts nor double-starts.

**Lands in:** `codemojex.design.md` §"The systems" (Play / scoring authority — note the score path now SADDs
membership) + §data-model Valkey keyspace (`players` = participants). **Engine:** `game.ex` (the SADD + the
gated transition), `rooms.ex` (remove the join-path SADD).

### B.4 The all-pay never-fills guard (the gathering abort) — **escalate to Operator**

The all-pay economy (`design.md:188`) charges every guess a fee in `submit` *before* enqueue (`game.ex:33`).
In `gathering`, players are charged but no prize round has started. Default: **wait indefinitely**
(no `ends_ms` → the sweep cannot fire). Optional room prop `gather_deadline_ms` (nullable, snapshotted): if
set and reached while still `gathering`, the game transitions `gathering → voided` and **every gathering-phase
guess fee is reversed** (a paired `TXN` credit), guarded by the same `SET NX` exactly-once so a double-void
does not double-refund. This is the **first destructive-at-rest money op** the calibration adds →
**HIGH-RISK, Apollo-mandatory**. The default + refund policy is an **economic/regulatory ruling** (the
paid-entry classification, `design.md:250`) — surfaced to the Operator, not decided here (ADR F-D).

### B.5 The N/10 counter surface

`game_view` (`view.ex:49-87`) gains `start_threshold` in/alongside `totals`, so the surface renders
`players / start_threshold` (e.g. `7/10`) on the gameplay board and the Golden-Room screen wherever the count
shows; once `open`, the threshold is met (the surface may drop or check-mark the "/10"). No new read path, no
new Valkey key. **Lands in:** `node/codemoji-design/gameplay/02-board.md` (the board count gains a
denominator) + `03-rooms.md` (the Golden-Room screen's count is N/threshold during gathering);
`codemojex.design.md` §web-surface (the view exposes the threshold). **Engine:** `view.ex` (additive field).

### B.6 The Golden-Room policy shape (F-A resolution, the decoupling)

The boost and the feedback/settlement type **decouple**:

| Concern | Column | Golden Room (calibrated) | Blind mode (renamed off "golden") |
|---|---|---|---|
| boost flag | `golden` (bool) | **`true`** | `false` (or `true` if a blind room is also boosted — orthogonal) |
| boost factor | `gold_multiplier` | `3` (default) | `1` |
| `type` | discriminator | **`"classic"`** | `"blind"` *(was `"golden"`)* |
| `feedback` | policy | `"score"` (live) | `"none"` |
| `settlement` | policy | `"live"` (winner-take-all) | `"sealed"` (top-K) |
| start | `start_threshold` | `10` (default) | `nil` or set, independently |

`create_golden_room/3` (`game.ex:208`) becomes: `create_room(name, set, opts |> put(:golden, true) |>
default(:gold_multiplier, 3) |> default(:duration_ms, 48h) |> default(:start_threshold, 10))` — and crucially
**does NOT set `type:"golden"`**; `rooms.ex:31` stops defaulting the type from the `golden` flag.

**Lands in:** `codemojex.design.md` §modes table (`:17-22`) + §"The systems" Rooms; the `games_type` /
`rooms` CHECK if the blind type is renamed (a schema fork — F-A's sub-decision, Operator-surfaced);
`golden-rooms.md` (already boost-class — only the tier line I-7 needs fixing); the `golden_blind` test re-pin.

---

## C. ADRs — one per fork

Each ADR: context → ≥2 steelmanned options → recommendation + rationale. The full derivation is in the
`codemojex-golden-calibration.progress.md` ledger (D-1…D-6, V-1…V-2, L-1…L-4, T-1…T-3).

### ADR F-A — Which "Golden"?

**Context.** "golden" names two opposite mechanisms (I-1, I-8). The canon (Operator's named truth) says
Golden Room = a `classic` boost class (live); `design.md` + the code build the blind/sealed type.

- **Option A — resolve to the canon (boost class on classic).** `create_golden_room` → a `classic`-typed
  game with `golden:true`; the blind mode keeps the policy but loses the name "Golden Room" (renamed type).
- **Option B — keep `create_golden_room` building the blind type;** treat the gameplay canon as superseded.
- **Option C — split the API:** `create_golden_room` (boost-on-classic) + a new `create_blind_room` (the
  blind type), both first-class, ending the name-overload at the API.

**RECOMMENDATION: A (with C's API hygiene folded in).** The Operator named the canon as truth and locked
three constraints (participation start, member-by-guess, **live** N/10 counter) that are *incoherent on a
blind room* — a blind room shows no per-guess feedback and no live count, so the constraints are themselves
evidence for the boost-class reading. The engine's own `golden-rooms.md` (cited *by* the canon) already
describes the boost class. Option B is rejected (V-1): the weight of "shipped work" is on the blind side, but
the weight of "the Operator's named truth + the locked constraints + the engine's own mechanic doc" is
decisively boost-class. The blind mode is **not deleted** — it survives as an explicit type (rename it off
"golden", e.g. `"blind"`, to end the overload — this is C's contribution and a **schema fork to surface to the
Operator**: renaming a `type` value touches the `games_type` CHECK). **Consequence:** the `golden_blind`
test inverts (it re-pins as a classic-boost test + a new blind-type test, L-3).

### ADR F-B — Threshold scope + value (hardcoded 10 vs a room prop; golden-only vs all rooms)

**Context.** Constraint #1 says "10 players." Where does 10 live, and does gating apply to all rooms?

- **Option A — hardcode 10, gate all rooms.** Simplest; one constant.
- **Option B — a per-room `start_threshold` prop (nullable; nil = legacy first-join), generic mechanism,
  `create_golden_room` defaults it to 10.** Same snapshot pattern as `duration`/`gold_multiplier`.
- **Option C — a prop, but golden-only** (only `golden:true` rooms can gather).

**RECOMMENDATION: B.** Hardcoding 10 (A) bakes one promo's parameter into the engine and forces **all** rooms
through gating, breaking the classic first-join contract (`rooms_and_games_story_test.exs:30`). A nullable
snapshotted prop keeps the round self-describing and lets a future classic promo opt in; making the mechanism
generic but **defaulting** the value on `create_golden_room` lands the Operator's "10" exactly where it
belongs (the Golden Room) without coupling the engine to "golden ⇒ gather" (C is needlessly narrow — gating is
a clean generic capability). **Consequence:** `rooms` + `games` gain `start_threshold` (nullable int,
snapshotted); `create_golden_room` default 10.

### ADR F-C — Gathering-phase shape (a new state vs `open` + `ends_ms:nil`)

**Context.** A phase must accept guesses (membership) while the timer is not running (I-2, I-10).

- **Option A — a new first-class state `gathering` (`ends_ms:nil`).** Admit guesses in `gathering`; transition
  to `open` + set `ends_ms` at the threshold.
- **Option B — overload `open` with an `ends_ms:nil` sentinel.** No new state word.

**RECOMMENDATION: A.** (V-2.) The state word is the honest description — the canon defines `open` as
"timer running, accepting guesses" and sets `ends_ms` *as* it enters `open` (`design.md:143`), so "open with
nil `ends_ms`" makes the spec self-contradictory and lets a `nil` leak into the surface countdown
(`SessionTimer` → crash). A `gathering` game is *observably different* (no countdown) and the surface
(`03-rooms.md:101`) renders it differently, so the distinction belongs in the state, not a nil-check scattered
across `view`/`submit`/`sweep`. Crucially, the close-sweep guard already matches `status==:open`
(`rooms.ex:302`), so a `gathering` game is **sweep-immune for free** — exactly the "must not fire
pre-threshold" invariant — whereas the overload would require adding a nil-guard to the sweep. **Cost:**
`'gathering'` joins the `games_status` CHECK; the `ends_ms` NOT-NULL relaxation (I-10) is needed under either
option, so it's not a differentiator.

### ADR F-D — The never-fills case (what happens to all-pay fees if 10 never participate)

**Context.** Gathering players are charged per guess (all-pay, `game.ex:33`) before any round starts.

- **Option A — wait indefinitely (default).** No `ends_ms` → no auto-close; the guesses already bought
  leaderboard standing for when the round starts.
- **Option B — an optional `gather_deadline_ms`; on expiry, `gathering → voided` + refund every gathering-phase
  fee** (paired `TXN`, exactly-once under `SET NX`).
- **Option C — `gather_deadline` → start anyway with fewer than the threshold.**

**RECOMMENDATION: A as the default, B available as a room prop — and ESCALATE to the Operator.** Default-wait
is the lowest-surprise reading of "the timer starts when 10 are in" (until then nothing runs, nobody is owed),
but the all-pay fee for a round that never starts is an **economic + regulatory exposure** (`design.md:250`,
paid-entry classification), so a deadline+refund path must *exist*. Void (not settle) because there is no pool
and no winner — the round never legally began. Reject C: it silently breaks the "10 players" contract and pays
a boosted pool to a thin field, worsening house exposure. **This is the calibration's one HIGH-RISK money op**
(fees reversed) → Apollo-mandatory; the close path `close_void` is new and distinct from
`close_live`/`close_sealed`, and the refund must be exactly-once. **The default + refund policy is an
Operator ruling, not an engine call.**

### ADR F-E — Member-by-guess (the SADD move + the `total_players` semantic flip)

**Context.** Constraint #2: membership = ≥1 guess in the `GAM` (I-3).

- **Option A — move the SADD from the join path to the score path; `SCARD` counts participants.**
- **Option B — keep the join SADD; add a *second* "participants" set populated by the score path; `SCARD`
  the new set for the threshold; keep the old set for "joiners".**

**RECOMMENDATION: A.** The Operator's definition is exactly "participant," and there is no surviving
requirement for a "joiners" count (the lobby reads room status, not a per-game joiner set). One set, moved to
the score authority (after `Board.record`, `game.ex:122`), is the minimal change and co-locates the membership
signal with the start trigger (F-C/B.3) under one idempotent SADD. B keeps a now-meaningless second set and
two write sites. **Consequence:** `total_players` (`view.ex:117`) keeps its name, flips to participants; the
join path (`rooms.ex:60,116`) stops SADDing; a joiner who never guesses is (correctly) invisible to the count.

### ADR F-F — The counter surface

**Context.** Constraint #3: the same N/10 counter on the gameplay board (I-4).

- **Option A — reuse `view.totals.players` (the participant `SCARD`) + expose `start_threshold` as the
  denominator;** the surface renders N/threshold. One read, two screens.
- **Option B — a dedicated counter endpoint / Valkey key for "N of threshold".**

**RECOMMENDATION: A.** Reusing `total_players` keeps **one** source of truth for the count (the canon's "one
name asked at different depths," `design.md:113`); the only new datum is the threshold, already snapshotted on
the game, so the surface joins them. B adds a redundant read path for a number the view already carries.
**Consequence:** `game_view` gains `start_threshold` alongside `totals`; the design canon records the
denominator on `02-board.md` + `03-rooms.md`.

---

## D. Where each delta lands — engine specs vs design canon

| Delta | `docs/codemojex/**` (engine specs) | `node/codemoji-design/**` (design canon) | Engine code (forward — Mars) |
|---|---|---|---|
| F-A Golden = boost-on-classic | `codemojex.design.md` §modes (`:17-22`), §systems Rooms; `golden-rooms.md` (only tier line I-7); `roadmap.md` §Golden Rooms (`:73-81`) — reconcile "blind" framing to "the **blind type**, separate from the Golden Room" | `README.md:119-126` + `03-rooms.md:11` already correct — **confirm**, no change beyond cross-link | `rooms.ex:31` (stop type-defaulting from `golden`); `game.ex:208` (`create_golden_room` shape); `games_type` CHECK if blind type renamed |
| F-B `start_threshold` prop | `codemojex.design.md` §data-model (`rooms`/`games` gain `start_threshold`) | — | `schemas/room.ex`, `schemas/game.ex`, migration; `rooms.ex` `create_room`/`start_game` |
| F-C `gathering` state | `codemojex.design.md` §state-machine (`:141-162`); `roadmap.md:222` | `03-rooms.md` (the in-progress screen has a gathering variant) | `games_status` CHECK; `rooms.ex` entry state; `game.ex` admit + transition |
| F-C `ends_ms` nullable | `codemojex.design.md` §data-model `games` (note `ends_ms` nullable in gathering) | — | migration (`:93` drop `null:false`); `schemas/game.ex:67` (drop from `validate_required`) |
| F-D never-fills (void+refund) | `codemojex.design.md` §core-flows (a `close_void` path) + §open-questions (the all-pay-gathering ruling) | — | `rooms.ex` `close_void`; `schemas/*` `gather_deadline_ms`; the sweep |
| F-E member-by-guess | `codemojex.design.md` §systems (score path SADDs) + §data-model Valkey (`players` = participants) | `02-board.md` / `03-rooms.md` (the count = participants) | `game.ex` (SADD + transition); `rooms.ex` (remove join SADD) |
| F-F N/10 counter | `codemojex.design.md` §web-surface (view exposes `start_threshold`) | `02-board.md` + `03-rooms.md` (N/threshold denominator) | `view.ex` (additive `start_threshold` in totals) |
| I-5 48h golden default | `codemojex.design.md` / `golden-rooms.md` (48h golden default) | `03-rooms.md:101` already 48h — **confirm** | `game.ex:208` default `duration_ms` |
| I-6 fee→pool language | `codemojex.design.md:26` + `roadmap.md:248` (`BNK` forward) — reconcile to as-built (platform-seeded) | `screens/game/README.md:112-116,177` already flags it — align rules copy | (none now; `BNK` is `cm.5+`) |
| I-7 tier line | `roadmap.md:171-175` (add `golden-rooms.md:4` to the tracked tier-reconcile) | — | (none — linear-only already) |

---

## E. Risk posture + handoff notes for Mars / Apollo

- **HIGH-RISK rung.** Two triggers fire: a **new state surface** (`gathering` + the gated transition in the
  score worker = a new process/lease-adjacent path) and a **destructive at-rest money op** (F-D
  void+refund reverses charged fees). **Apollo is mandatory.** The `≥100` determinism loop applies — the
  threshold-reaching transition is a same-millisecond branded-id + concurrent-SADD hazard (two participants'
  guesses racing to be "the Nth").
- **Exactly-once is load-bearing in two new places:** (1) the `gathering → open` transition must fire **once**
  even if the threshold-reaching guess is re-delivered — gate it on the SADD-returns-1 + `SCARD==threshold`
  check being inside the worker's idempotent body, and consider a `SET NX`-style guard on the transition
  itself (`cm:<game>:started`) mirroring the close lock; (2) the void+refund must not double-refund (reuse the
  `SET cm:<game>:closed NX` discipline).
- **The blind-type rename (F-A) is a schema fork** (`games_type` CHECK). If the Operator prefers to keep the
  `type` value `"golden"` for the blind mode (no rename), F-A still holds — `create_golden_room` just stops
  *selecting* it — but the name-overload persists in the schema. Surface both to the Operator.
- **Test blast radius (L-3):** `golden_blind_story_test.exs` inverts (classic-boost + a new blind test);
  `rooms_and_games_story_test.exs:30` is preserved by the `start_threshold=nil` default; a NEW gathering
  story is owed (gather → threshold → start → close).
- **No third app.** Every delta is inside `echo/apps/codemojex` (lib + schemas + migration + tests) and the
  two doc trees. No `echo_mq`/`echo_store`/`echo_data` edit.

---

## F. Open items surfaced to the Operator (not decided here)

1. **F-A sub-fork:** rename the blind `type` off `"golden"` (schema CHECK change) vs keep `"golden"` and only
   re-point `create_golden_room`. (Recommendation: rename, to end the overload.)
2. **F-D policy:** the never-fills default (wait-forever vs a `gather_deadline` that voids+refunds) and the
   refund mechanics — an **economic/regulatory** ruling.
3. **I-6 scope:** reconcile fee→pool language to as-built now (recommended) vs schedule fee-accrual into the
   forward `BNK` bank (`cm.5+`).
