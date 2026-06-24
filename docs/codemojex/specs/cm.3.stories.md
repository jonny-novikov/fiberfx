# cm.3 — Stories (acceptance, Given/When/Then)

> The Operator's acceptance face of `cm.3.md`. Each Deliverable (G1–G5) becomes a user story (Connextra
> form) with concrete Given/When/Then criteria; each names the invariant(s) it exercises; a Coverage line
> maps every Deliverable → its story. Derived from `cm.3.md` (the body authoritative — all mechanics RULED
> D-15/D-16) and the design doc §9 (the blind-mode stories R-4, R-7). When this disagrees with the body,
> the body wins.
>
> **Framing discipline:** no gendered pronouns for agents; no perceptual / interior-state verbs; no
> first-person narration. State surfaces as contracts.

---

## Story G-1 — a golden game gives no feedback until the sealed reveal (G1, V-7/V-13)

*As a blind-room player, a golden game shows state and the timer only until the sealed reveal at close, so
no per-guess signal leaks and the contest stays blind.*

- **Given** a golden game (`feedback="none"`, `settlement="sealed"`) with a `commitment` published at open
  and `secret`/`nonce` sealed server-side.
- **When** a player joins / refreshes / reads history on the **open** golden game, then submits a guess.
- **Then** the scoring worker **stores** `points` (charged, enqueued, persisted) but emits **no** `scored`
  PubSub push; `game_view/1` returns `status` + timer + the published `commitment` with **no**
  `totals.best`/`best_pct` score; `my_history/3` returns `emojis` + `at_ms` **without** `points`; the
  leaderboard returns **no** score; no query selects `secret`/`nonce`.
- **And** the score is computed by the **same** linear engine `Scoring.score/2` (V-7 — one linear function,
  both modes); only the emission is suppressed.
- **Invariants:** INV-9 (no score crosses the wire before `revealed_ms`; the privacy gate is
  `feedback`/`revealed_ms`); INV-3 (one linear engine, no second implementation).

---

## Story G-2 — the secret is provably fair (commit at open, reveal + verify at close) (G2, V-14)

*As a player in a golden game, I get a commitment at the start and can verify the secret was fixed, so the
outcome is provably fair.*

- **Given** a golden game at `start_game`: the `secret` is six distinct codes drawn from `cell_codes`, a
  `nonce` is drawn, and `commitment = SHA-256(secret ‖ nonce)` (lowercase hex, the byte-pinned encoding) is
  stored on the `GAM`.
- **When** the game runs to the `revealing` transition at the timer close.
- **Then** `revealed_ms` is set and `secret` / `nonce` / `commitment` are exposed; the recomputed
  `SHA-256(secret ‖ nonce)` (lowercase hex) **equals** the stored `commitment` byte-for-byte.
- **And** before reveal, no player-facing read selects `secret` or `nonce` (only the `commitment` hash is
  exposable at open).
- **Invariants:** INV-9 (the commitment **binds** the server — the revealed secret recomputes to it;
  `secret`+`nonce` sealed until reveal).

---

## Story G-3 — the sealed pass pays the top-K by the stored split, exactly once (G3, V-15)

*As the platform, a golden game pays its boosted pool to the top scorers at the sealed close by the room's
configured split, so a field of players is rewarded and a re-run pays identically.*

- **Given** a golden game with `top_k` (default `5`), `payout_split` (default `[40,25,15,12,8]`), a
  `prize_pool`, and `gold_multiplier`; players have submitted guesses scored to `points`.
- **When** the game closes on the timer (golden never closes on a perfect crack — there is no per-guess
  signal), inside the `cm:{game}:closed` `SET NX` one-shot.
- **Then** the pass reveals, ranks players by **best linear `points`** desc, computes
  `Economy.effective_pool/3` (the pool boosted by `gold_multiplier`), and pays rank `i` of the top-`top_k`
  its share `payout_split[i] / Σ payout_split` of the effective pool as a `TXN` deposit through
  `Codemojex.Wallet`; the game moves to `settled`.
- **And** when fewer than `top_k` players guessed, the share normalizes over the present ranks; no rake is
  recorded (no `BNK` — the pool is the game's own `prize_pool`).
- **And** the pass run **twice** (or the close raced) pays **identically** and the wallet ledger shows each
  prize **once**.
- **Invariants:** INV-5 (exactly-once via the `SET NX` lock + a pure ranked split — idempotent); INV-11
  (every prize a `TXN` through the wallet in a transaction; the pool is `prize_pool`, no `BNK`).

---

## Story G-4 — the golden lifecycle traverses revealing → settling → settled (G4, V-8)

*As the engine, a golden game moves through the reveal and settle states so the sealed pass is observable
and the state machine is bounded.*

- **Given** a golden game `open` and the `games_status` CHECK (the seven canon words) shipped by cm.1.
- **When** the timer expires.
- **Then** the game transitions `open → revealing` (reveal secret+nonce, set `revealed_ms`, score the
  sealed batch) `→ settling` (pay the top-K) `→ settled` (exposed for verification); `voided` is the abort
  path.
- **And** a write of a `status` outside the seven canon words is **rejected** by the `games_status` CHECK.
- **Invariants:** INV-10 (cm.3 writes the two new words `revealing`/`settling` — no new table, no
  migration; the column + CHECK already ship in cm.1).

---

## Story G-5 — the reduced keyboard is a per-game randomized snapshot (G5, V-16a)

*As a blind-room player, the keyboard is a smaller randomized subset so the six-of-N space is tractable
without hints, and it varies game to game.*

- **Given** a golden room with `cell_count = N` (e.g. `24`) pointing at a full `EMS` (the keyboard).
- **When** a golden game starts.
- **Then** the game snapshots `games.cell_codes = Enum.take_random(EMS.codes, N)` (a randomized `N`-cell
  subset), the secret is six distinct codes drawn from `cell_codes`, and the player's keyboard is exactly
  `cell_codes`.
- **And** the `EMS` row is **unchanged** (the full keyboard) — the narrowing is the per-game snapshot, not
  a smaller `EMS.codes`; a classic room (`cell_count` null) snapshots the full set.
- **Invariants:** INV-10 (the `cell_codes` column already ships in cm.1; cm.3 writes the reduced subset for
  golden, no migration).

---

## Coverage

| Deliverable | Story | Invariants |
|---|---|---|
| G1 feedback none + privacy + one fat reveal | G-1 | INV-9, INV-3 |
| G2 commit-reveal (SHA-256) | G-2 | INV-9 |
| G3 sealed top-K by stored split | G-3 | INV-5, INV-11 |
| G4 revealing/settling states | G-4 | INV-10 |
| G5 reduced keyboard snapshot | G-5 | INV-10 |

> **The rung split:** cm.1 lands the schema (the blind + `cell_codes` + `payout_split` columns present, the
> `games_status` CHECK) + classic live mode; cm.3 (these stories) writes the golden flow on that schema.
> Every deliverable maps to a story; completion is provable from the text.

**Liveness:** G-1 requires a **present** golden game to be guessed and asserts no `scored` push / no
`points` in history / no leaderboard score / no `secret`/`nonce` selected — a leak before `revealed_ms` is a
**LOUD failure**, never a silent pass; G-2 requires the commitment to be **recomputed** at reveal and
compared byte-for-byte (not `assert true`); G-3 requires the sealed pass to **run twice** and the payouts +
ledger compared (idempotency proven, not assumed); G-4 requires the `games_status` CHECK to be **exercised**
by a rejected write; G-5 requires a present golden game with `cell_count = N` to snapshot exactly `N` codes
and the secret to be drawn from them. No gate is satisfied by a no-op.

---

*Derived from `cm.3.md` (all mechanics RULED, D-15/D-16). The body is authoritative; feedback edits the
body and the stories re-derive.*
