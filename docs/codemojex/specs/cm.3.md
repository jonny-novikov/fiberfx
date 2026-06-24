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
> **Builds on cm.1.** cm.1 is the founding core (the fresh schema **with the four blind columns present**,
> the three brand re-bases, classic live mode). cm.3 depends on cm.1 being shipped; it touches only the
> golden path.
>
> **`[RULE]`-pending: the open mechanics.** Five mechanics the canon leaves genuinely open are framed as
> Arms (design §10.2): the **commitment scheme** (V-10-Arm), the **top-K split curve** (V-11-Arm), the
> **reduced-set size + the anonymized-leaderboard treatment** (V-12-Arm), **scoring unification** (V-7),
> and the **state-machine shape + CHECK** (V-8). Each deliverable carries the **recommended Arm as its
> default** and is marked `[RULE]` so the Director's `AskUserQuestion` closes it before the build leg.
> These are open *mechanics* to rule, not invented surface — every one cites a canon line.
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
  `revealed_ms` is set. The `view.ex` privacy module branches on `feedback`/`revealed_ms`.
- **Commit-reveal** (design §3.8.3): at open compute + store `commitment = H(secret ‖ nonce)`, keep
  `secret`+`nonce` server-side sealed; at close set `revealed_ms` and expose `secret`/`nonce`/`commitment`
  so a player recomputes + verifies. The commitment **scheme** is the V-10-Arm ruling (default byte-pinned
  SHA-256).
- **Sealed top-K settlement** (design §3.8.2): at the timer close, inside the same `cm:{game}:closed`
  `SET NX` one-shot — reveal, rank by best linear `points`, pay the top `top_k` from
  `Economy.effective_pool/3` (boosted by `gold_multiplier`) as `TXN` deposits through the wallet, then
  `settled`. The **split curve** is the V-11-Arm ruling (default fixed `top_k`, graduated).
- **The `revealing`/`settling` states** (design §3.8.5): the golden path `open → revealing → settling →
  settled`; `voided` the abort. The state-machine **shape + CHECK** is V-8.
- **The reduced emoji set** (design §3.8.4): a golden room points at a smaller `EMS`. The **size** is the
  V-12-Arm ruling (default a 24-cell `EMS`); the mechanism is a smaller `EMS` row, **not** a per-game
  subset column.

**OUT (later rungs / flagged gaps — design §3.8.6):**
- **The `BNK` bank + the rake.** The top-K pays from the game's own `prize_pool` (as-built); no bank, no
  rake column. The bank lands with its system.
- **The anonymized leaderboard alias.** Needs `RMP` membership (absent). Until `RMP`, a golden leaderboard
  ranks by `PLR` like classic — and the reveal-gated privacy (no score until reveal) already secures the
  blind contest without the alias (V-12-Arm, sub-recommendation: defer).
- **The `SES` session / verified `initData`** + the **regulatory eligibility seam** (design §Arm V-9) —
  the gating is a join-time predicate + a launch-gate/legal decision, not a `games` column; a permissive
  default ships, the policy values are deferred.

---

## 3. Deliverables (each traced to a story §`cm.3.stories.md` and an invariant §5)

- **G1 — feedback `none` + the privacy withholding.** For `feedback="none"` before `revealed_ms`: the
  scoring worker stores `points` (charged, enqueued, persisted) but emits **no** `scored` PubSub push;
  `view.ex` `game_view/1` returns `status`+timer with **no** `totals.best`/`best_pct` score, `my_history/3`
  returns `emojis`+`at_ms` **without** `points`, and the leaderboard returns **no** score. After
  `revealed_ms`, the golden reads return the score like classic. A policy branch on `feedback`/
  `revealed_ms` inside `view.ex` — not a new view. (design §3.8.1, §5.1) → Story R-7.
- **G2 — commit-reveal.** At `start_game` for a golden game: draw `nonce`, compute `commitment =
  H(secret ‖ nonce)` `[RULE: V-10-Arm — the hash + encoding; default byte-pinned SHA-256 over a canonical
  UTF-8 encoding of the secret codes joined by a record separator, then ‖ nonce, lowercase hex]`, store
  all four blind columns (`commitment`, `nonce`, `top_k`), keep `secret`+`nonce` server-side. At the
  `revealing` transition: set `revealed_ms`, expose `secret`/`nonce`/`commitment`. The encoding is
  **byte-pinned + documented** so the client recomputes identically. (design §3.8.3) → Story R-7.
- **G3 — sealed top-K settlement.** At the timer close (golden never closes on a perfect crack — there is
  no per-guess signal): inside the `cm:{game}:closed` `SET NX` one-shot, reveal, rank players by best
  linear `points`, compute `Economy.effective_pool/3`, pay the **top `top_k`** `[RULE: V-11-Arm — the
  split curve; default a fixed top_k with a graduated decreasing share per rank]` as `TXN` deposits
  through `Codemojex.Wallet` (the Postgres-floor law: money moves only through the wallet in a
  transaction), record nothing to a rake (no `BNK`), move to `settled`. (design §3.8.2) → Story R-4.
- **G4 — the `revealing`/`settling` states.** The golden lifecycle `open → revealing → settling →
  settled`; `voided` the abort `[RULE: V-8 — bound status with a CHECK over the canon's 7 words, or leave
  it free text; and classic's terminal word (settled vs closed)]`. The `status` column already exists
  (cm.1); cm.3 writes the two new words at the transitions. (design §3.8.5) → Story R-4.
- **G5 — the reduced emoji set.** A golden room points at a smaller `EMS` `[RULE: V-12-Arm — the size;
  default a 24-cell EMS row]`. The mechanism is an `EMS` row with a smaller `codes` array (the as-built
  `EmojiSet` supports it), **not** a per-game `games.symbols` column. (design §3.8.4) → Story R-4.

> **Scoring unification (V-7) underpins G1/G3.** Blind settlement scores every guess with the **same
> linear distance** engine `Scoring.score/2` and ranks by best total — `[RULE: V-7 — linear (the
> Operator's HARD constraint + roadmap B7.4.1) vs architecture.md:59's "exact-match"; default linear]`.
> The default is the only reading consistent with the linear-score constraint; surfaced because
> `architecture.md` genuinely says "exact-match".

---

## 4. Grounding (NO-INVENT — every claim cites a real artifact)

- **Feedback none + privacy:** `architecture.md` "Data flow — a Golden Room" (*"the channel carries the
  timer and state only, with no results"*); `roadmap.md` B7.1.3 (*"not even a score leaks until reveal"*);
  the as-built `view.ex` privacy module (the branch point).
- **Commit-reveal:** `architecture.md` "Provably-fair secret" (hash commitment over secret+nonce →
  hiding + binding); `specs.md:53–56` (publish the commitment at open, sealed server-side, reveal +
  verify at close). The hash is the canon's "lean instantiation" (the scheme is V-10-Arm).
- **Sealed top-K:** `architecture.md` "Data flow — a Golden Room" (*"one settlement pass scores every GES
  against the revealed secret, ranks, pays the top K … the game moves to settled"*); `specs.md:47` (close
  on timer, one pass, pay top K); the as-built `rooms.ex` `close_round`/`do_close` (the `SET NX` one-shot)
  + `economy.ex` `effective_pool/3` + `Codemojex.Wallet.deposit_prize`.
- **The state machine:** `specs.md:36` (`scheduled→open→active→revealing→settling→settled→voided`); the
  as-built `open|closed` is the degenerate cm.1 ships.
- **The reduced set:** `specs.md:46` ("18 or 24 cells"); `architecture.md:14` ("a reduced symbol set");
  the as-built `EmojiSet` (arbitrary `codes`).
- **The scoring engine:** the as-built `scoring.ex` `Scoring.score/2` (`points(d)=100-20*d` summed to
  600); `roadmap.md` B7.4.1 (blind scores on the same linear scale).
- **The four blind columns:** cm.1 (the schema lands them present; design §3.5).

**The master grounding:** every mechanic cites design §3.8 → the canon line; the three flagged gaps
(`BNK`/`RMP`/`SES`, design §3.8.6) are designed-around, never invented; the five open mechanics are Arms
to rule (each cites the canon line that leaves it open), never guessed surface.

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
- **INV-10 — no new table, no migration.** cm.3 writes the four blind columns cm.1 landed; it adds **no**
  Postgres table and **no** migration (the schema already carries the columns + the `status` word).
- **INV-11 — the wallet floor.** Every top-K prize is a `TXN` through `Codemojex.Wallet` in a transaction
  (the non-negative CHECK + the append-only ledger); the pool is the game's own `prize_pool` (no `BNK`).
- **INV-3 (inherited) — linear purity.** `Scoring.score/2` stays the sole linear engine for both modes
  (the V-7 default); blind adds **no** second scoring implementation.

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
   asserts the revealed `H(secret ‖ nonce)` **equals** the stored `commitment` (byte-for-byte, the pinned
   encoding) — the provably-fair contract.
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
- No second scoring implementation (INV-3 — the linear engine is the sole scorer; V-7 default).
- No change to classic's live flow (cm.1) — cm.3 branches the golden path only.
- No `git`; the Director commits by pathspec. Per-app testing only (the codemojex app dir).
  `TMPDIR=/tmp` for all `mix`.

---

## 8. The Arm rulings this rung waits on (the Director's `AskUserQuestion`, design §10.2)

The body's `[RULE]` markers correspond to these forks; the stories + brief re-derive once they are ruled:

| Arm | Deliverable | Default (RECOMMEND) |
|---|---|---|
| **V-7** scoring unification | G1/G3 (the rank key) | linear distance for both modes (the Operator's HARD constraint + roadmap B7.4.1) |
| **V-8** state-machine shape | G4 | the full canon set as text words; sub-rulings: CHECK-bound? classic terminal word? |
| **V-10-Arm** commitment scheme | G2 | byte-pinned SHA-256 over a canonical encoding of `secret ‖ nonce`, lowercase hex |
| **V-11-Arm** top-K split curve | G3 | a fixed `top_k` with a graduated decreasing share per rank |
| **V-12-Arm** reduced-set size + alias | G5 | a 24-cell `EMS` row; defer the anonymized alias to the `RMP` rung |

Each is an open *mechanic* the canon leaves to rule (cited in §4), not invented surface. cm.3 builds once
they are ruled and the stories + brief re-derive to the rulings.

---

*Authored by Venus-PG (architect), Stage-2. The blind flow is grounded entirely on disk — every mechanic
cites design §3.8 → a canon line; the three flagged gaps (`BNK`/`RMP`/`SES`) are designed-around, never
invented; the five open mechanics are Arms to rule, each `[RULE]`-marked with its cited-canon default. No
production code was edited. cm.3 builds on cm.1's shipped schema once the §8 Arms are ruled. The Director
ratifies; the Operator accepts.*
