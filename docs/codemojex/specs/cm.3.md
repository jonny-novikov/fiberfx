# cm.3 — Blind Golden: feedback-none · commit-reveal · sealed top-K settlement

> **The blind-Golden rung of the Codemojex game-engine build.** The `golden` game **type** becomes the
> canon's blind/sealed mode on the cm.1 schema: **feedback `none`** (no score leaks until reveal), a
> **commit-reveal** provably-fair secret (`commitment` at open, `secret`+`nonce` sealed server-side,
> revealed + verifiable at close), and a **sealed top-K settlement** (one pass at the timer close, rank by
> best linear `points`, pay the top `top_k` from the game's boosted `prize_pool`). It writes the four
> blind columns cm.1 landed inert (`commitment`/`nonce`/`revealed_ms`/`top_k`) and adds the
> `revealing`/`settling` states. **No new table, no migration** — cm.1's schema already carries the
> columns; cm.3 is the *flow*.
>
> **Source of truth:** this body is authoritative; `cm.3.stories.md` (acceptance) and `cm.3.llms.md` (the
> build brief) derive from it. When a derived file disagrees, this body wins. The stories + brief are
> authored once the §"Open mechanics" Arms are ruled, so their contracts are fixed, not guessed.
>
> **Design canon:** `docs/codemojex/codemojex.game-model.design.md` §3.8 (the blind mechanics, each
> grounded line-by-line in `architecture.md` / `specs.md` / `roadmap.md`) + §5.1 (the keyspace) + §10.2
> (the open Arms). The product canon is `codemojex.architecture.md` ("Provably-fair secret", "Data flow —
> a Golden Room", "Anonymization") / `codemojex.specs.md:36,46–56` / `codemojex.roadmap.md` B7.1.3/B7.4.1.
>
> **Builds on cm.1.** cm.1 is the founding core (the fresh schema **with the four blind columns +
> `cell_codes` + `payout_split` present**, the three brand re-bases, classic live mode). cm.3 depends on
> cm.1 being shipped; it touches only the golden path. The schema columns this rung writes
> (`commitment`/`nonce`/`revealed_ms`/`top_k`/`cell_codes`/`payout_split`) are all landed by cm.1 — cm.3
> adds **no** table and **no** migration (INV-10).
>
> **All mechanics are RULED (D-15/D-16, 2026-06-25).** The mechanics the canon left open are settled by the
> Operator (design §10.2): the **commitment scheme** = SHA-256(secret ‖ nonce) lowercase hex (V-14); the
> **top-K payout** = `top_k` DEFAULT 5 + a stored `payout_split` weight array (V-15); the **reduced set** =
> room `cell_count` + a per-game randomized `games.cell_codes` snapshot (V-16a); the **anonymized alias** =
> deferred to `RMP` (V-16b); **scoring unification** = one linear function (V-7); the **state machine** =
> the CHECK-bounded 7 words, classic terminal `settled` (V-8); the **reveal event** = one fat `revealed`
> (V-13). Each deliverable below states the ruled mechanic as a contract — **no `[RULE]`-pending fork
> remains**; the stories + brief derive directly.
>
> **Framing discipline (propagate):** no gendered pronouns for agents; no perceptual or interior-state
> verbs (sees / wants / notices); no first-person narration. State surfaces as contracts.

---

## 1. The goal (one paragraph)

A Golden game runs **blind**: a player guesses with **no per-guess feedback**, the server holds the
secret under a published **commitment** so the outcome is provably fair, and at the timer close a single
**sealed pass** scores every guess on the same linear scale, ranks players, and pays the **top K** from
the boosted pool. The contest's secrecy is the privacy gate (no score crosses the wire until reveal); the
fairness is the commitment (the revealed secret must recompute to it). This rung wires the four blind
columns cm.1 landed inert and the two new states, **on the same schema, the same `cm:{game}:` keyspace,
and the same linear scoring engine** — the difference from classic is **feedback + settlement**, not the
data model or the scoring math.

---

## 2. Scope — IN and OUT

**IN (this rung):**
- **Feedback `none` + the privacy withholding** (design §3.8.1, §5.1): a golden game stores `points`
  server-side but emits **no** `scored` push and returns **no** score from any player-facing read until
  `revealed_ms` is set. The `view.ex` privacy module branches on `feedback`/`revealed_ms`. The
  `game_view` carries the `commitment` from open. At close, **one fat `revealed` event** (V-13) — not a
  stream of per-guess pushes.
- **Commit-reveal** (design §3.8.3): at open compute + store **`commitment = SHA-256(secret ‖ nonce)`,
  lowercase hex** (V-14), keep `secret`+`nonce` server-side sealed; at close set `revealed_ms` and expose
  `secret`/`nonce`/`commitment` so a player recomputes + verifies. The byte-pinned encoding is documented
  (G2).
- **Sealed top-K settlement** (design §3.8.2): at the timer close, inside the same `cm:{game}:closed`
  `SET NX` one-shot — reveal, rank by best linear `points`, pay the top `top_k` (DEFAULT 5) from
  `Economy.effective_pool/3` (boosted by `gold_multiplier`), **rank `i` taking its weight share
  `payout_split[i] / Σ payout_split`** (the stored `games.payout_split` array, V-15) as `TXN` deposits
  through the wallet, then `settled`.
- **The `revealing`/`settling` states** (design §3.8.5): the golden path `open → revealing → settling →
  settled`; `voided` the abort. The state column is **CHECK-bounded** over the seven canon words (V-8),
  shipped by cm.1; classic terminal is `settled`.
- **The reduced emoji set** (design §3.8.4): a golden room sets **`rooms.cell_count`** (`N`); at start the
  game snapshots **`games.cell_codes = Enum.take_random(room_codes, N)`** and the secret draws from that
  (V-16a). The narrowing is a per-game randomized snapshot, **not** a smaller `EMS` row (the EMS stays the
  full keyboard).

**OUT (later rungs / flagged gaps — design §3.8.6):**
- **The `BNK` bank + the rake.** The top-K pays from the game's own `prize_pool` (as-built); no bank, no
  rake column. The bank lands with its system.
- **The anonymized leaderboard alias.** Needs `RMP` membership (absent) — RULED **deferred to `RMP`**
  (V-16b). Until `RMP`, a golden leaderboard ranks by `PLR` like classic; the board push carries
  `{player_id, score}` and the wire shape is authored to accept `{alias, score}` later (no wire break when
  `RMP` lands). The reveal-gated privacy (no score until reveal) already secures the blind contest.
- **The `SES` session / verified `initData`** + the **regulatory eligibility seam** (design §Arm V-9) —
  the gating is a join-time predicate + a launch-gate/legal decision, not a `games` column; a permissive
  default ships, the policy values are deferred.

---

## 3. Deliverables (each traced to a story §`cm.3.stories.md` and an invariant §5)

- **G1 — feedback `none` + the privacy withholding + the one fat reveal.** For `feedback="none"` before
  `revealed_ms`: the scoring worker stores `points` (charged, enqueued, persisted) but emits **no**
  `scored` PubSub push; `view.ex` `game_view/1` returns `status`+timer + the published `commitment` with
  **no** `totals.best`/`best_pct` score, `my_history/3` returns `emojis`+`at_ms` **without** `points`, and
  the leaderboard returns **no** score. At close the golden path emits **one fat `revealed` event** (V-13)
  carrying `secret`+`nonce`+`commitment`+board+top-K payouts+terminal `status` — the first and only results
  the blind client receives. After `revealed_ms`, the golden reads return the score like classic. A policy
  branch on `feedback`/`revealed_ms` inside `view.ex` — not a new view. (design §3.8.1, §5.1, §6.6) →
  Story R-7.
- **G2 — commit-reveal (SHA-256, V-14).** At `start_game` for a golden game: draw `nonce`, compute
  **`commitment = SHA-256(secret ‖ nonce)`, lowercase hex** — over a canonical UTF-8 encoding of the six
  secret codes joined by a record separator, then `‖ nonce` (`:crypto.hash(:sha256, …)`, zero new
  dependency); store `commitment`+`nonce`, keep `secret`+`nonce` server-side. At the `revealing`
  transition: set `revealed_ms`, expose `secret`/`nonce`/`commitment`. **The byte layout is pinned +
  documented** (the encoding is the deliverable) so a client in any language recomputes it identically.
  (design §3.8.3) → Story R-7.
- **G3 — sealed top-K settlement (stored `payout_split`, V-15).** At the timer close (golden never closes
  on a perfect crack — there is no per-guess signal): inside the `cm:{game}:closed` `SET NX` one-shot,
  reveal, rank players by best linear `points`, compute `Economy.effective_pool/3`, pay the **top `top_k`**
  (DEFAULT 5) — **rank `i` taking its share `payout_split[i] / Σ payout_split`** of the effective pool (the
  stored `games.payout_split` weight array, a new pure `economy.ex` `top_k_split/2`) — as `TXN` deposits
  through `Codemojex.Wallet` (the Postgres-floor law: money moves only through the wallet in a
  transaction), record nothing to a rake (no `BNK`), move to `settled`. When fewer than `top_k` players
  guessed, the share normalizes over the present ranks. (design §3.8.2) → Story R-4.
- **G4 — the `revealing`/`settling` states (CHECK-bounded, V-8).** The golden lifecycle `open → revealing
  → settling → settled`; `voided` the abort. The `status` column + its `games_status` CHECK (the seven
  canon words; classic terminal `settled`) already ship in cm.1; cm.3 writes the two new words
  (`revealing`, `settling`) at the transitions. (design §3.8.5) → Story R-4.
- **G5 — the reduced emoji set (room `cell_count` + per-game snapshot, V-16a).** A golden room sets
  **`rooms.cell_count`** (`N`, e.g. `24`); at `start_game` the game snapshots **`games.cell_codes =
  Enum.take_random(EMS.codes, N)`** (or the full set when `cell_count` is null), and the secret draws its
  six from `cell_codes` (`EmojiSet.secret`). The narrowing is a per-game randomized snapshot, **not** a
  smaller `EMS` row and **not** a per-game `games.symbols` column. Both columns ship in cm.1. (design
  §3.8.4) → Story R-4.

> **Scoring unification (V-7, RULED) underpins G1/G3.** Blind settlement scores every guess with the
> **same linear distance** engine `Scoring.score/2` and ranks by best total — **one linear function for
> both modes** (the Operator's HARD constraint + `roadmap.md` B7.4.1); `architecture.md:59`'s "exact-match"
> is the rejected arm. Blind adds **no** second scoring implementation.

---

## 4. Grounding (NO-INVENT — every claim cites a real artifact)

- **Feedback none + privacy:** `architecture.md` "Data flow — a Golden Room" (*"the channel carries the
  timer and state only, with no results"*); `roadmap.md` B7.1.3 (*"not even a score leaks until reveal"*);
  the as-built `view.ex` privacy module (the branch point).
- **Commit-reveal:** `architecture.md` "Provably-fair secret" (hash commitment over secret+nonce →
  hiding + binding); `specs.md:53–56` (publish the commitment at open, sealed server-side, reveal +
  verify at close). The hash is the canon's "lean instantiation", ruled **SHA-256(secret ‖ nonce)
  lowercase hex** (V-14) — `:crypto.hash(:sha256, …)`, an OTP primitive, zero new dependency.
- **Sealed top-K:** `architecture.md` "Data flow — a Golden Room" (*"one settlement pass scores every GES
  against the revealed secret, ranks, pays the top K … the game moves to settled"*); `specs.md:47` (close
  on timer, one pass, pay top K); the as-built `rooms.ex` `close_round`/`do_close` (the `SET NX` one-shot)
  + `economy.ex` `effective_pool/3` + `Codemojex.Wallet.deposit_prize`. The split is the stored
  `games.payout_split` weight array, `top_k` default 5 (V-15).
- **The state machine:** `specs.md:36` (`scheduled→open→active→revealing→settling→settled→voided`); the
  as-built `open|closed` is the degenerate cm.1 ships; the seven words are CHECK-bounded, classic terminal
  `settled` (V-8).
- **The reduced set:** `specs.md:46` ("18 or 24 cells"); `architecture.md:14` ("a reduced symbol set");
  the as-built `EmojiSet` (arbitrary `codes`) + `EmojiSet.secret` (`Enum.take_random(codes, 6)`,
  `emoji_set.ex:64`). The mechanism is `rooms.cell_count` + the per-game `games.cell_codes` snapshot
  (V-16a); the EMS seed is the two real sprite sheets (design §3.3.1).
- **The scoring engine:** the as-built `scoring.ex` `Scoring.score/2` (`points(d)=100-20*d` summed to
  600); `roadmap.md` B7.4.1 (blind scores on the same linear scale). One linear function, both modes (V-7).
- **The blind/reduced/split columns:** cm.1 (the schema lands `commitment`/`nonce`/`revealed_ms`/`top_k` +
  `cell_codes` + `payout_split` present; design §3.5).

**The master grounding:** every mechanic cites design §3.8 → the canon line; the three flagged gaps
(`BNK`/`RMP`/`SES`, design §3.8.6) are designed-around, never invented; every mechanic the canon left open
is now RULED (D-15/D-16, design §10.2), each citing the canon line it grounds in — no guessed surface.

---

## 5. Invariants (the code-asserting contract Apollo + the Director verify)

- **INV-5 — sealed exactly-once + idempotent.** The sealed pass runs once (the `cm:{game}:closed`
  `SET NX` one-shot guards it); the payout is a **pure function** of the ranked best `points` — a re-run
  pays identically (purity, the BCS idempotency story extended to the top-K split).
- **INV-9 — the privacy + binding contract.** `secret` + `nonce` are selected by **no** player-facing
  query until `revealed_ms` is set (the same server-side discipline as `secret` in classic, widened to
  `nonce`); **no score** (`points`, `best`, leaderboard) crosses the wire for a golden game before
  `revealed_ms`; the revealed secret **recomputes** to the stored `commitment` (the server is bound to the
  secret it fixed at open). The privacy gate is `feedback`/`revealed_ms`, not a per-call opt-in.
- **INV-10 — no new table, no migration.** cm.3 writes the blind + `cell_codes` + `payout_split` columns
  cm.1 landed; it adds **no** Postgres table and **no** migration (the schema already carries the columns
  + the CHECK-bounded `status` word).
- **INV-11 — the wallet floor.** Every top-K prize is a `TXN` through `Codemojex.Wallet` in a transaction
  (the non-negative CHECK + the append-only ledger); the pool is the game's own `prize_pool` (no `BNK`).
- **INV-3 (inherited) — linear purity.** `Scoring.score/2` stays the sole linear engine for both modes
  (V-7, one linear function); blind adds **no** second scoring implementation.

---

## 6. The gate (what closes this rung)

1. `cd echo/apps/codemojex && TMPDIR=/tmp mix compile --warnings-as-errors` → clean.
2. `valkey-cli -p 6390 ping` → `PONG`; Postgres up; `TMPDIR=/tmp mix test --include valkey` → green — the
   golden/blind stories exercise the full blind flow end-to-end (open → guess-with-no-feedback → timer
   close → reveal → sealed top-K pay) on the cm.1 schema.
3. **The privacy probe (INV-9 liveness).** A test asserts that for a golden game **before reveal**: no
   `scored` event is published, `my_history` returns no `points`, the leaderboard returns no score, and no
   query selects `secret`/`nonce`. A present golden game that leaks any score before `revealed_ms` is a
   **LOUD failure**, never a silent pass.
4. **The fairness probe (INV-9 binding).** A test computes the commitment at open, runs to reveal, and
   asserts the revealed `SHA-256(secret ‖ nonce)` (lowercase hex, the pinned encoding) **equals** the
   stored `commitment` byte-for-byte — the provably-fair contract.
5. **The idempotency probe (INV-5).** The sealed settlement pass is run twice (or the close raced); the
   payouts are **identical** and the wallet ledger shows each prize **once** (the `SET NX` one-shot + the
   pure split).
6. **The ≥100 determinism loop** on the mint/process/settlement suite (the same-ms branded-id mint hazard
   + the settlement ordering) — `for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break;
   done`.

> A gate specifies its own liveness: the privacy probe MUST run with a **present** golden game and assert
> no leak (an absent game is not a pass); the fairness probe MUST recompute + compare the commitment (not
> assert `true`); the idempotency probe MUST run the pass twice and compare. Each is a positive proof, not
> a skip.

---

## 7. Out-of-scope guardrails (do not touch)

- No `BNK` bank / rake (the top-K pays from `prize_pool`); no `RMP` membership / anonymized alias (rank by
  `PLR`); no `SES` session / verified `initData`; no regulatory column (the V-9 seam is a join-time
  predicate + a launch-gate decision, permissive default).
- No new Postgres table, no migration (INV-10 — cm.1's schema already carries the columns).
- No second scoring implementation (INV-3 — the linear engine is the sole scorer; V-7, one linear function).
- No change to classic's live flow (cm.1) — cm.3 branches the golden path only.
- No `git`; the Director commits by pathspec. Per-app testing only (the codemojex app dir).
  `TMPDIR=/tmp` for all `mix`.

---

## 8. The Arm rulings (RULED — D-15/D-16, 2026-06-25; design §10.2)

Every mechanic the canon left open is now ruled. The body states each as a contract (above); the stories +
brief derive directly. The table records the ruling + the ledger V-number (the authority):

| Arm | Deliverable | RULED |
|---|---|---|
| **V-7** scoring unification | G1/G3 (the rank key) | ONE linear distance function, both modes (the Operator's HARD constraint + roadmap B7.4.1); `architecture.md:59`'s exact-match rejected |
| **V-8** state-machine shape | G4 | the full canon set, CHECK-bounded (`games_status`); classic terminal `settled`; golden `open→revealing→settling→settled` |
| **V-13** reveal event | G1 | ONE fat `revealed` event at close (secret+nonce+commitment+board+top-K+state); commitment on `game_view` from open; golden per-guess pushes suppressed |
| **V-14** commitment scheme | G2 | SHA-256(secret ‖ nonce), lowercase hex, byte-pinned encoding; HMAC + per-cell rejected |
| **V-15** top-K payout | G3 | `top_k` DEFAULT 5 + a stored `payout_split` weight array (default `[40,25,15,12,8]`); rank `i` takes `split[i]/Σsplit` of `effective_pool` |
| **V-16a** reduced set | G5 | room `cell_count` (N, nullable) + a per-game randomized `games.cell_codes` snapshot; the secret draws from the snapshot; the EMS stays the full keyboard |
| **V-16b** anonymized alias | §2 OUT | DEFER to the `RMP` rung; the board push carries `{player_id, score}`, the wire accepts `{alias, score}` later |

Each ruling grounds in the canon line cited in §4 — no invented surface, no open fork. The cm.3 stories +
brief derive from this body.

---

*Authored by Venus-PG (architect), Stage-2 + Stage-2 convergence (2026-06-25). The blind flow is grounded
entirely on disk — every mechanic cites design §3.8 → a canon line; the EMS seed is measured (design
§3.3.1); the three flagged gaps (`BNK`/`RMP`/`SES`) are designed-around, never invented; **every mechanic
is RULED (D-15/D-16) — no `[RULE]`-pending fork remains**. No production code was edited. cm.3 builds on
cm.1's shipped schema. The Director ratifies; the Operator accepts.*
