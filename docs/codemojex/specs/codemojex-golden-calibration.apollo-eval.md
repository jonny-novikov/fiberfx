# Codemojex · Golden Rooms Calibration — Apollo design-evaluation (the mandatory high-risk gate)

> **Design-phase evaluation.** No production code; no commit; the architects' design files are
> left untouched. This file is Apollo's verdict on the two designs (Venus-A engine-lens ∥ Venus-B
> design-canon-lens) per x-mode §12 (design-eval) + §11.2 (charter rigor). Every fact below was
> **independently re-verified against disk** — a second check is the whole point, so no citation is
> taken on the architects' or the Director's word.
>
> **Framing:** no gendered pronouns for agents; no perceptual or interior-state verbs; no
> first-person narration. This clause propagates into any brief derived from this evaluation.

---

## 0. Verdict

**BUILD-GRADE** — both designs are sound, grounded, INVENTED-free; the frame is correct and the
forks are real. The build rung is cleared to proceed **on the synthesis below**, carrying four
named residual gates (§3, §4). No design BLOCKS; the divergences resolve to a clean graft.

The recommended synthesis is **Venus-A as the base** (the engine/state-machine spine — the
`gathering` state, the snapshotted `start_threshold` prop, the catalogue depth) **with three Venus-B
grafts**: the distinct `cm:<game>:members` set (F-E), keeping `type:"golden"` for the blind mode
(F-A-rename), and the paid-room void+refund lead for F-D.

---

## 1. Independent re-verification of the pivotal facts (the second check)

| Fact | Probed on disk | Verdict |
|---|---|---|
| Golden chain builds the blind mode | `game.ex:208` → `rooms.ex:26,31` (`type: if(golden,"golden","classic")`) → `rooms.ex:75` `policies_for(type)` → `rooms.ex:127` `{feedback:"none",settlement:"sealed"}` | **CONFIRMED** end-to-end |
| I-9 `close_if_expired` unwired | `grep -rn close_if_expired lib/ test/` → ONLY its own def at `rooms.ex:298`; **zero callers**; no sweep/`send_after`/scheduler anywhere (GenServers = `rate_limiter`, `echo_bot`, `EchoStore.Directory` only) | **CONFIRMED — stronger:** no trigger exists to wire the never-fills close to |
| I-10 `ends_ms` blocks gathering | `migration:93` `null:false` **and** `game.ex:67` `validate_required([…,:ends_ms])` | **CONFIRMED both halves** → Venus-B "zero churn" is **FALSE** |
| `games_status` CHECK | `migration:110-113` lacks `gathering`, **has** `voided` | Venus-A needs a CHECK add; both F-D leans on `voided` (reachable) |
| `games_type` CHECK | `migration:108` `type IN ('classic','golden')` | the F-A-rename differentiator |
| SADD/SCARD/score path | `add_player rooms.ex:160` (called `:60,:116`); `total_players view.ex:117`; `Board.record game.ex:122`; perfect-600 `game.ex:144` | **CONFIRMED** — F-E insertion point real |
| all-pay before round | `charge_guess game.ex:33` inside `submit`, before `Lanes.enqueue game.ex:37`; `charge_guess` debits **keys|clips, never diamonds** (`wallet.ex:98-105`) | **CONFIRMED** — the never-fills hazard is real |
| canon = boost-on-classic | `README.md:119-126` (DISAMBIGUATION), `:126` "boost class on the classic base"; `03-rooms.md:11,91,118,150` | **CONFIRMED** — the canon is unambiguous; the code is the drift |

The convergence both designs rest on (F-A: a Golden Room is a boost class on `classic`; the code
builds the opposite) is **not an echo-chamber artifact** — it rests on the Operator's named source of
truth, read directly here, which says exactly what both designs claim.

---

## 2. The four divergence adjudications

### F-C — gathering shape · **adjudicate FOR Venus-A (a `:gathering` state)**

Both claimed Venus-B advantages collapse under the disk check. "Zero migration churn" is **false** —
both approaches need the `ends_ms` `null:false` drop + the `validate_required` relaxation; the only
delta is Venus-A's +1 `games_status` CHECK value (cheap). "Expiry already no-ops on a nil `ends_ms`"
is **half-true**: `expired?/2` (`game.ex:48`) is robust by an **explicit** `is_integer` guard, but
`close_if_expired` (`rooms.ex:302`) is immune to a `nil` `ends_ms` **only** by the silent Erlang
`number < atom` total-ordering (`now >= nil` ⇒ false, never raises) — fragile under any future guard
refactor or a stray `nil` reaching the client `SessionTimer`. For a money state machine with a
to-be-wired sweep, the explicit, greppable state word is the safer encoding of the
must-not-fire-pre-threshold invariant. Net cost of A = one CHECK value; net benefit = legibility +
robustness. **Weak-lean A** (a genuine design call) — and the disk facts strengthen the Director's
lean.

### F-E — the count key · **adjudicate FOR Venus-B (a NEW `cm:<game>:members` set)**

Venus-A reuses `cm:<game>:players` and silently **flips its meaning** join→participant; Venus-B adds
a distinct `cm:<game>:members` and keeps `players` as the join set. The BCS law the entire stack is
built on — *one name, one meaning; no overload* — makes the silent semantic flip the riskier move: a
reader of `cm:<game>:players` / `total_players` (`view.ex:117`) assuming "joiners" breaks invisibly.
Venus-B's separate set is the BCS-honest encoding. The cost (re-point `total_players` to
`members_count`) is owed under **both** designs — A merely hides it behind the same name. **Strong-lean
B.** (This is the one place Apollo diverges from Venus-A's own recommendation; the Director left F-E
open for this adjudication.)

### F-A-rename — the blind type's name · **adjudicate FOR Venus-B (keep `type:"golden"`)**

Decisive un-prompted canon fact: **the design canon itself uses `golden` as the type value** for the
blind mode (`README.md:67-72` Modes table — `type | golden | none | sealed`; `:124` "the `golden`
game type — the blind/sealed mode"). The canon distinguishes the two by **Golden *Room* (boost) vs
`golden` *type* (blind)** — it does **not** rename the type. Venus-A's rename to `"blind"`/`"sealed"`
would make the engine's type-vocabulary **diverge from the canon's own** — the opposite of the
calibration's goal (conform the engine *to* the canon). Keeping `type:"golden"` keeps the `games_type`
CHECK + the type words aligned with the canon and needs **no** CHECK migration; the name-overload is
resolved at the API (`create_golden_room` stops *selecting* the blind type), not by renaming a
canon-blessed value. **Strong-lean B.** Still surfaced to the Operator as the F-A sub-fork — but
Apollo's recommendation is B on the canon-vocabulary evidence.

### F-D — never-fills default · **SURFACE to the Operator (money/legal), SHARPENED**

Apollo does not decide the money/legal default. But the fork sharpens: `charge_guess` debits
**keys (paid) or clips (free), never the diamond pool** (`wallet.ex:98-105`), and the canon states
clips have *"no economic value; excluded from the available balance"* (`README.md:105`). So:

- the fork is really **"PAID golden rooms: void+refund-keys on a gather deadline (Venus-B) vs
  wait-forever (Venus-A)"**;
- **FREE golden rooms are a settled sub-case** — wait-forever, because the clip charge is valueless.

Apollo's lead recommendation to the Operator: **Venus-B's void+refund for PAID rooms** on
player-fairness + regulatory-exposure grounds (`design.md:250`), with wait-forever the explicit
free-room sub-case — a synthesis of both designs' instincts. **If void+refund is chosen, it carries
the two mandatory build gates in §3.**

---

## 3. The never-fills integrity verdict (the high-risk money dimension, probed adversarially)

**SOUND-IF** the build rung carries two gates the design must NAME (only Venus-A §E partially named
the first):

1. **Two distinct `SET NX` guards, not one.** The `gathering → open` start transition needs its own
   `SET cm:<game>:started NX` (the SADD + the SCARD + the `ends_ms` write are **three non-atomic
   ops** — two concurrent guesses can both observe `SCARD == threshold` and both attempt to start the
   timer). The void transition reuses `SET cm:<game>:closed NX`. Venus-A gestures at the started-lock
   as "consider"; it is **required**, not optional. Venus-B does not mention it — a gap.
2. **Per-guess refund idempotency BELOW the close lock.** The `SET cm:<game>:closed NX` makes the
   *state transition* exactly-once, but the refund is a loop of N `credit()` calls, each its own DB
   txn. A crash mid-loop leaves the lock held (`voided`) with only some players refunded and **no
   retry path** (the NX lock now blocks re-entry). The refund must be idempotent at the per-guess TXN
   level (a refund TXN keyed by the guess/game, so a re-run skips already-refunded guesses) — not only
   at the close-lock level. Neither design specified this.

With both gates, the never-fills + the start transition are exactly-once and crash-safe. The ≥100
determinism loop is correctly mandated (the Nth-participant race is a real same-millisecond +
concurrent-SADD hazard).

---

## 4. Constraint fidelity + un-prompted findings

**Constraint fidelity — both designs honor the 3 locked Operator mechanics EXACTLY** (participation
start at the 10th; member = ≥1 guess in the `GAM`; the same N/10 counter on the gameplay board), and
the 4th (reconcile to canon — a complete catalogue, not just the start mechanic) is met by both
catalogues (Venus-A I-1..I-12; Venus-B A-1..A-9). No design re-litigates a locked fork. The classic
first-join contract (`rooms_and_games_story_test.exs:30`) is preserved under both F-B resolutions
(the `start_threshold=nil`/`golden`-gated default). **No constraint drift.**

**Un-prompted findings (charter requires ≥1; three are recorded):**

- **U-1 — the F-B golden-default-of-10 collides with every existing golden test's small-N setup.**
  `golden_blind_story_test.exs:20-31` joins only 2 players; with `start_threshold` defaulting to 10
  on `create_golden_room`, that game sits in `gathering`/`ends_ms:nil` permanently. `close_now` still
  works (it dispatches on settlement, not the timer), so the sealed scenarios survive — but any
  re-pinned scenario asserting the game has *started* hangs. The build rung owes a fixture audit of
  every `create_golden_room` call site and an explicit `start_threshold` in the golden tests (default
  10 in production). **Neither design flagged this fixture interaction.**
- **U-2 — the refund currency is keys|clips, not the diamond pool; the free-room refund is void.**
  Sharpens F-D (see §2, §3) — the refund path is load-bearing only for PAID rooms.
- **U-3 — the gathering→open transition has no exactly-once guard in either design.** The required
  `SET cm:<game>:started NX` (see §3, gate 1).

---

## 5. Residual risks the build rung must carry

1. **Wire a real sweep** (I-9): the never-fills auto-close and the timer-expiry close both depend on a
   periodic caller of `close_if_expired` that **does not exist today** — a hard build-rung dependency
   both designs underweight.
2. The **two `SET NX` guards** + **per-guess refund idempotency** (§3).
3. The **`create_golden_room` threshold-default fixture audit** (U-1).
4. The **golden-test re-pin** (`golden_blind_story_test.exs` inverts to a classic-boost test; a NEW
   explicit-`type:"golden"` blind test is owed; `settlement_story_test.exs` golden dispatch flips
   live).

These are gates, not blockers — the design is BUILD-GRADE; the build rung executes them under the
≥100 determinism loop on Valkey 6390 with `TMPDIR=/tmp`.

---

# PART II — The tournament-economy extension (money-critical, second evaluation)

> Evaluates `codemojex-golden-calibration.economy.design.md` (Venus-A) — the buy-in tournament built
> ON TOP of the ratified start-mechanic design (which stands). MONEY-CRITICAL: real player buy-ins
> fund the pool. Same discipline — every claim re-verified against disk; no citation taken on the
> design's word.

## II.0 Verdict

**BUILD-GRADE** — the economic model is sound, grounded, and composes cleanly with the ratified
start-mechanic design. Every money-critical claim holds on disk. The build rung carries **one headline
residual risk** (the cross-store buy-in entry-guard, §II.2) and the named gates. No BLOCK.

## II.1 Independent re-verification of the money-critical surfaces

| Surface | Probed on disk | Verdict |
|---|---|---|
| `do_close` dispatch shape | `rooms.ex:188-193` — 2-way (`"sealed"`→`close_sealed`; `_`→`close_live`); reached only AFTER the `SET NX` lock (`close_game rooms.ex:181-184`) | **CONFIRMED** — the 3rd `"live_split"`→`close_split` branch composes with the close lock |
| `Economy.top_k_split` reuse | `economy.ex:62` `div(pool*w,sum)` + dust-to-rank-1, deterministic; suite-proven | **CONFIRMED** — reused verbatim; `economy:"proportional"` is descriptive-not-dispatch (`do_close` keys on `settlement`) |
| schema additivity | `settlement`/`economy` (`migration:83-84`) have **no CHECK** (only `players_non_negative`/`games_type`/`games_status`); `transaction.ex:9` `reason` free-text | **CONFIRMED** — `live_split`/`proportional`/`buy_in`/`buy_in_refund` all additive, no CHECK-widen |
| `Ecto.Multi` precedent | **none** in the tree — every wallet op is a single-table `Repo.transaction`+`lock`+`update!`+`txn!` | `buy_in/3` is genuinely the **first cross-entity op**; the atomic SQL `+` has no precedent to copy — the highest-risk novelty |
| idempotency-index precedent | no `transactions(player,ref)` index today; but the 2nd migration (`…_add_player_tg_user_id`) shipped a **partial unique index** consumed by `resolve_by_tg` (`wallet.ex:52-87`) | the refund's idempotency mechanism **mirrors an already-shipped pattern** — strong |
| cache coherence (§3.3) | hot path `game.ex:106-107` matches `%{secret: secret}` only (never `prize_pool`); view `view.ex:50,61` + settlement `rooms.ex:171,199` read `Store.game` (Postgres) | **CONFIRMED** — `buy_in` writing Postgres-only does not break `:cm_games` |

Every money-critical claim is grounded, not invented.

## II.2 The headline residual risk — the cross-store buy-in entry-guard is NOT exactly-once

The design guards the buy-in with `SET cm:<game>:paid:<player> NX` checked **before** `buy_in/3`
(§3.2). But the NX-check (Valkey) and the `buy_in` `Ecto.Multi` (Postgres) are **two ops in two
stores, not atomic** — and the failure is asymmetric and worse than a same-store race:

- **NX-then-Multi, Multi crashes:** the player is marked paid in Valkey but never debited and the pool
  never credited; on retry the NX returns 0 → the player plays **free** and the pool is **short**. A
  money **leak**.
- **Multi-then-NX, NX-mark crashes:** the player is debited + pooled, then on retry the NX succeeds
  again → **double buy-in**. A player **overcharge**.

Neither ordering is exactly-once across the store boundary. **The fix the brief must mandate:** make
the buy-in idempotent **in Postgres** (the same store as the debit + pool) via a **partial unique
index on `transactions(player, ref) WHERE reason = 'buy_in'`** — mirroring the `buy_in_refund` index
and the shipped `tg_user_id` pattern — so the `buy_in` Multi is exactly-once by construction, and the
Valkey paid-set degrades to a cheap fast-path **hint**, not the source of truth. This is the one
money-integrity gap a build would ship **as-specified** (the design's §10 names the Multi atomicity +
the paid-NX but does not see the NX-across-stores is itself non-atomic with the Multi). It would pass a
happy-path payout test; only a cross-store crash test surfaces it.

## II.3 The other un-prompted finding — `close_split` must mirror `close_live`, not `close_sealed`

`close_split` pays top-K via `top_k_split` — **identical math to `close_sealed`** — so a builder is
tempted to mirror it on `close_sealed`. But `close_sealed` calls `Cache.put_game` twice (`rooms.ex:232`
the revealing blob, `:250` the settled blob) and emits a `{:revealed}` event; `close_live` calls
`Cache.put_game` **zero** times (Store-only settle at `:214`). The Golden Room is classic/live (no
reveal phase), so **`close_split` must mirror `close_live`'s shape** (the `announce_golden`/
`{:golden_win}` fan-out + a Store-only settle), swapping `top_k_split` for `winner_take_all` as the
**only** payer change. A `close_sealed`-mirrored `close_split` would stray a cache write and possibly
emit a nonsense `{:revealed}` for a live room — **gate-invisible** (it still pays correctly), surfacing
only under a cache-coherence or event-assertion probe. The design says "mirrors `close_live`" (§2.2)
but does not warn against the tempting wrong mirror.

## II.4 Constraint fidelity + the buildable-now fork recommendations

**Constraint fidelity — PASS, all 6 locked mechanics (§0) honored exactly:** live-proportional (WTA
retained for ordinary paid classic; blind keeps sealed); buy-in + per-guess (buy-in at join,
`charge_guess` unchanged); buy-ins fund the pool / per-guess platform revenue (atomic-`+` + the struck
copy); hard-10 + never-fills refund (reuses the ratified gate + `close_void`); launch config; keep
`type:"golden"` (no `games_type` change). No re-litigation.

**Fork recommendations (Apollo's engineering input; the Operator rules the cost — surfaced via the
Director):**

- **Pool composition (§4):** (c) `(seed+Σbuy_ins)×mult` is **lowest-code** (it is exactly the current
  `effective_pool`); (b) `Σbuy_ins` only is lowest-cost; (a) `seed×mult + Σbuy_ins` is most
  promotional. **Caveat for the Operator: (c) is lowest-code but NOT lowest-cost** — boosting the
  buy-in-funded pot means the platform matches the field N:1.
- **USD rail (§5):** **strong-lean (a) keys-priced-in-USD** for launch — reuses the Stars→keys rail
  (`wallet.ex:108`), needs only a pure `keys_for_usd/1`, no new payment webhook/ledger; (b)
  direct-Stars-at-join is the forward `ORD`/`OTX`/`WHK` commerce build (a separate rung).
- **Refund scope (§6.3):** **confirm buy-ins-only** — a scored guess bought a delivered service; only
  the buy-in (entry to a tournament that never began) is owed.
- **Buy-in-room-never-free (§9.4):** **confirm the rule** — a free room takes clips (valueless), so a
  clips-funded pool is worthless. The build must **enforce** `buy_in set ⇒ free=false` as a changeset
  validation, not merely document it.

## II.5 Residual risks the build rung must carry (economy)

1. **The cross-store buy-in entry-guard** (§II.2) — the headline: make `buy_in` Postgres-idempotent via
   the `transactions(player,ref) WHERE reason='buy_in'` partial index; the Valkey paid-set is a hint.
2. **The atomic SQL `+` for the pool** — `UPDATE games SET prize_pool = prize_pool + amount` via
   `update_all`/fragment, **never** an app-side read-modify-write (N concurrent buy-ins lose updates).
   No precedent in the tree to copy.
3. **`buy_in/3` is one `Ecto.Multi`** — the player debit and the pool credit commit together or not at
   all (a partial commit is a money bug). The non-negative CHECK (`migration:23`) is the short-buy-in
   backstop.
4. **`close_void` refund** — ledger-authoritative (read `buy_in` TXN rows for `ref=game`, not the
   volatile paid-set), per-`(player,ref)` partial-index idempotency so a mid-loop crash is resumable.
5. **`close_split` mirrors `close_live`, not `close_sealed`** (§II.3).
6. **Enforce `buy_in ⇒ not free`** as a changeset validation (§II.4).

Items 2–4 are named in the design's §10; items 1, 5, 6 are Apollo's additions. All are gates, not
blockers — the model is BUILD-GRADE; the build executes them under the determinism loop with the
money-path crash tests (cross-store buy-in, mid-loop refund) as the new adversarial coverage.
