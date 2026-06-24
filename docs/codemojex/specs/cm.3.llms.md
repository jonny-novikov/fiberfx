# cm.3 — Build brief (the file Mars builds from)

> Mars builds the blind/sealed Golden flow **from this brief**; the Director and the Operator accept
> **against it**. Derived from `cm.3.md` (authoritative — all mechanics RULED, D-15/D-16) +
> `cm.3.stories.md` (acceptance). Every site cites a real module/line or the design doc; invent no symbol,
> route, field, or policy. **No `[RULE]`-pending fork remains** — every decision the build needs is fixed
> here. cm.3 builds on cm.1's shipped schema (the blind + `cell_codes` + `payout_split` columns + the
> `games_status` CHECK already present).
>
> **Framing discipline (propagate into any prose Mars writes):** no gendered pronouns for agents; no
> perceptual / interior-state verbs (sees / wants / notices); no first-person narration. State surfaces as
> contracts.

---

## 1. References — read these first (paths first)

- **The model design** `docs/codemojex/codemojex.game-model.design.md` — §3.8 (the blind mechanics, each
  grounded line-by-line in the canon), §3.5 (the `games` columns cm.1 landed), §5.1 (the blind keyspace),
  §6.3/§6.6/§6.8 (the lifecycle close branch + the privacy widening + the settle), §10.2 (the ruled Arms).
  **This is the primary reference.**
- **The spec body** `cm.3.md` (the deliverables G1–G5 + the invariants) and **the stories**
  `cm.3.stories.md` (the acceptance gates).
- **cm.1** (the shipped founding core) — the schema, the renamed `Codemojex.Schemas.Game`, the
  type/policy snapshot at `start_game`, the `games_status` CHECK. cm.3 builds **on top**; it touches only
  the golden path.
- **The real module surface:** `echo/apps/codemojex/lib/codemojex/` — `rooms.ex` (`start_game`/`close_game`,
  the `cm:{game}:closed` `SET NX` one-shot), `game.ex` (`Codemojex.ScoreWorker` / `Codemojex.Settle`),
  `view.ex` (the privacy module), `economy.ex` (`effective_pool/3`, `winner_take_all/2`, `proportional/2`),
  `emoji_set.ex` (`secret/1`, `codes`), `wallet.ex` (`deposit_prize`), `notifier.ex`; `test/stories/`.

---

## 2. Requirements (numbered; each traced to a story + an invariant)

- **R1 (G1 → G-1, INV-9/INV-3).** Suppress the per-guess emission for `feedback="none"`: in
  `Codemojex.ScoreWorker` branch on the game's `feedback` policy — store `points` as today but **do not**
  publish the `scored` PubSub push / `Events.publish "scored"`. Widen `view.ex`: for a golden game
  (`feedback="none"`) **before** `revealed_ms`, `game_view/1` returns `status`+timer + the `commitment`
  with **no** `totals.best`/`best_pct`, `my_history/3` returns `emojis`+`at_ms` **without** `points`, and
  the leaderboard returns no score; after `revealed_ms`, the golden reads return the score like classic. A
  policy branch on `feedback`/`revealed_ms` inside the existing privacy module — **not a new view**. The
  score is the **same** `Scoring.score/2` linear engine (V-7) — no second implementation.
- **R2 (G2 → G-2, INV-9).** At `start_game` for a golden game (cm.1 already snapshots type/policies +
  `cell_codes` + draws the secret from `cell_codes`): draw a `nonce`, compute **`commitment =
  SHA-256(secret ‖ nonce)`, lowercase hex** — a new **pure** helper over a canonical UTF-8 encoding of the
  six secret codes joined by a record separator, then `‖ nonce` (`:crypto.hash(:sha256, …)`, an OTP
  primitive, zero new dependency); store `commitment` + `nonce` on the `GAM`; keep `secret`+`nonce`
  server-side. **The byte layout is pinned + documented** in this brief (below) so a client recomputes it
  identically.
- **R3 (G3 → G-3, INV-5/INV-11).** Add a new **pure** `economy.ex` `top_k_split/2` over the ranked best
  `points` + the stored `games.payout_split` array: pay rank `i` of the top-`top_k` its share
  `payout_split[i] / Σ payout_split` of `Economy.effective_pool/3` (the pool boosted by `gold_multiplier`).
  In `Codemojex.Settle` the golden branch (`settlement="sealed"`) runs the sealed pass **inside the same**
  `cm:{game}:closed` `SET NX` one-shot: reveal (set `revealed_ms`, expose secret+nonce), rank by best
  linear `points`, call `top_k_split/2`, deposit each prize as a `TXN` through `Codemojex.Wallet` (money
  moves only through the wallet in a transaction), move to `settled`. When fewer than `top_k` players
  guessed, the share normalizes over the present ranks; no rake (no `BNK` — pay from `prize_pool`).
- **R4 (G1 → G-1, INV-9/V-13).** Emit **one fat `revealed` event** at the close (the `revealing`
  transition) carrying `secret`+`nonce`+`commitment`+the final board+the top-K payouts+the terminal
  `status` — the single broadcast (not a stream of per-guess pushes). The `game_view` carries the
  `commitment` from open so the player records it for verification.
- **R5 (G4 → G-4, INV-10).** Write the two new state words at the golden transitions in `rooms.ex`/
  `Codemojex.Settle`: `open → revealing → settling → settled`; `voided` the abort. The `status` column +
  the `games_status` CHECK already ship in cm.1 — cm.3 writes within the bound, **no** new table, **no**
  migration.
- **R6 (G5 → G-5, INV-10).** The golden room's `cell_count` + the per-game `games.cell_codes` snapshot +
  the secret-from-`cell_codes` draw already land in cm.1's `start_game` (the schema + the snapshot are
  cm.1's). cm.3 **relies on** them for the golden flow (the keyboard the blind client taps = `cell_codes`);
  no new wiring beyond confirming the golden room sets `cell_count` and the snapshot is the reduced
  keyboard. **No new column.**

> **The commitment byte layout (R2 — pinned).** `commitment = lowercase_hex(SHA-256(payload))` where
> `payload = utf8(join(secret, SEP)) <> SEP <> utf8(nonce)`, `SEP` a single record-separator byte
> (`<<0x1e>>`), `secret` the six codes in their stored order, `nonce` a server-drawn random string. A
> client reproduces the commitment from the revealed `secret` + `nonce` with the same encoding. (The exact
> `SEP` byte + the nonce length are Mars's to fix in the helper + document in code; this brief pins the
> SHA-256 / lowercase-hex / `secret ‖ nonce` shape, V-14.)

---

## 3. Execution topology (the build-order DAG + the exact files)

> Build order is chosen so the pure helpers (the commitment, the split) land first, the lifecycle wires
> them, and the privacy/suppression branch lands before the wire emission. Each step's files are design
> §6.3/§6.6/§6.8.

1. **The pure helpers** — the commitment helper (R2, a new pure fn; `:crypto.hash(:sha256, …)`) +
   `economy.ex` `top_k_split/2` (R3, beside `winner_take_all/2` + `proportional/2`).
2. **The lifecycle open branch** (`rooms.ex` `start_game`, golden): draw `nonce`, compute + store
   `commitment` (R2). (The secret + `cell_codes` snapshot are cm.1's.)
3. **The privacy widening + suppression** (`game.ex` `ScoreWorker`, `view.ex`): suppress the `scored` push
   for `feedback="none"`; withhold the score from player-facing reads before `revealed_ms`; carry the
   `commitment` on `game_view` (R1).
4. **Compile-gate** (`TMPDIR=/tmp mix compile --warnings-as-errors`).
5. **The sealed close** (`rooms.ex` `close_game` / `Codemojex.Settle`, golden branch): the sealed pass
   inside the `cm:{game}:closed` `SET NX` one-shot — reveal, rank, `top_k_split/2`, wallet deposits,
   `settled`; write `revealing`/`settling` (R3, R5); emit the one fat `revealed` event (R4).
6. **Tests** (`test/stories/`): the golden/blind stories — the privacy probe, the fairness probe, the
   idempotency probe (cm.3.md §6); `mix codemojex.stories` regenerates.

**Exact files touched:** `rooms.ex` (the golden open + close branches), `game.ex` (`ScoreWorker`
suppression + `Settle` sealed pass), `view.ex` (the privacy widening), `economy.ex` (`top_k_split/2`), a
new commitment helper (a pure module fn), `notifier.ex` (the golden reveal/result, if it carries the
event), the blind/golden test stories. **No schema, no migration** (cm.1 landed the columns + the CHECK —
INV-10). **No** change to classic's live flow.

---

## 4. Agent stories (Directive + Acceptance gate, contract form)

- **B-1 — the commitment + the split helpers.** *Directive:* R2 (the pinned SHA-256 commitment helper) +
  R3's `top_k_split/2`. *Acceptance:* the commitment helper recomputes from `secret`+`nonce` deterministically
  (lowercase hex); `top_k_split/2` pays rank `i` its `payout_split[i]/Σ` share and is pure (a re-run is
  identical). *Invariant:* INV-5 (pure split), INV-9 (the commitment binds).
- **B-2 — the privacy widening + the suppression.** *Directive:* R1 + R4 (the `game_view` commitment + the
  one fat reveal). *Acceptance:* the privacy story is green and **exercises** the in-flight checks (no
  `scored` push, no `points` in history, no leaderboard score, no `secret`/`nonce` selected) + the at-reveal
  commitment recompute. *Invariant:* INV-9, INV-3.
- **B-3 — the sealed close.** *Directive:* R3 + R5 (the sealed pass inside the one-shot, the state words,
  the `revealed` event). *Acceptance:* the golden flow runs open → guess-no-feedback → timer close → reveal
  → sealed top-K pay end-to-end; the pass run twice pays identically (the ledger shows each prize once).
  *Invariant:* INV-5, INV-10, INV-11.

---

## 5. The acceptance gate (close the rung — `cm.3.md` §6)

1. `cd echo/apps/codemojex && TMPDIR=/tmp mix compile --warnings-as-errors` → clean.
2. `valkey-cli -p 6390 ping` → `PONG`; Postgres up; `TMPDIR=/tmp mix test --include valkey` → green — the
   golden/blind stories exercise the full blind flow end-to-end on the cm.1 schema.
3. **The privacy probe (INV-9 liveness):** a present golden game **before reveal** leaks no `scored` event,
   no `points` in history, no leaderboard score, and no query selects `secret`/`nonce` — a leak is a LOUD
   failure.
4. **The fairness probe (INV-9 binding):** the revealed `SHA-256(secret ‖ nonce)` (lowercase hex, the
   pinned encoding) equals the stored `commitment` byte-for-byte.
5. **The idempotency probe (INV-5):** the sealed pass run twice (or the close raced) pays identically and
   the wallet ledger shows each prize once.
6. **The ≥100 determinism loop** on the mint/process/settlement suite (the same-ms branded-id mint hazard +
   the settlement ordering): `for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break; done`.
7. **Run no `git`** — the Director commits by pathspec. `TMPDIR=/tmp` for all `mix`. Per-app only.

---

*Authored by Venus-PG (architect), Stage-2 convergence (2026-06-25) — derived from `cm.3.md` once every
§10.2 Arm was RULED (D-15/D-16), so the scoring/scheme/split/reduced-set/state contracts are fixed, not
guessed. cm.3 builds on cm.1's shipped schema; no schema or migration (INV-10). Mars builds; the Director
ratifies; the Operator accepts. No production code edited in authoring this brief.*
