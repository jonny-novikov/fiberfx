# cm.6.design.a — The Revenue Ledger · Minimal-Ledger Steward lens

> One of two independent architect designs (the dual-architect debate). Forward-tense, NO-INVENT. Surfaces forks; the Operator rules.

## §0 — Locked constraints (the as-built money surface this designs around)

The Steward designs the *lightest* change that achieves balanced double-entry on the revenue
side **without manufacturing schema the BNK bank will re-shape**. Every constraint below is an
as-built fact (Director-verified at the cited `file:line` this session) — the design bends to
them, it does not re-derive them.

**L-1 · The ledger is append-only, free-text, schema-stable.**
`Codemojex.Schemas.Transaction` (`lib/codemojex/schemas/transaction.ex`) is a row
`{id (TXN brand), player, currency (string), delta (signed int), reason (free-text), ref
(free-text, nullable)}` with `inserted_at` only — no `updated_at`, no `CHECK` on `reason`/`ref`.
**Consequence (the Steward's central lever):** a *new reason string* (`"deposit_seed"`,
`"deposit_recovery"`, `"revenue"`, `"deposit_reclaim"`) needs **no migration** — it is data, not
schema. The partial unique index `(player, ref) WHERE reason='buy_in'` is the **exactly-once
authority** for membership; it does not constrain a credit row.

**L-2 · Every player balance is non-negative by DB CHECK — the collision the Steward owns.**
`Codemojex.Schemas.Player` (`player.ex`) carries `[:keys, :clips, :diamonds, :bonus_diamonds,
:locked_diamonds]` (int, default 0); `guard/1` (`player.ex:43-47`) applies
`validate_number(>= 0)` to **all five** and adds `check_constraint :players_non_negative`. A
sentinel house `PLR` accumulating *credits* stays non-negative — but the **seed debit** of
`virtual_deposit/10` keys (cm.6.md Scope §2) drives a fresh house row **negative on its first
write**, colliding with the CHECK. This is F1-Arm1's load-bearing liability; §1 prices it and §4
resolves it.

**L-3 · The buy-in path does NOT ledger its debit; the guess path DOES.**
`Wallet.buy_in/2` (`wallet.ex:203-242`) locks the `games` row `FOR UPDATE` (the per-game ordinal
serializer, cm.5 RULING 1) **then** the player; `ordinal = count + 1`; `insert_buy_in`
(`wallet.ex:347-366`) writes the `buy_in` `TXN` with **`delta: 0`** — a *membership / exactly-once
MARKER*, not a debit. The actual fee leaves the player as a **bare balance update**
(`update!(keys -= fee)`, `wallet.ex:226`) with **no signed row**, then `Economy.entry_fee_split(…)`
+ `inc_pool!`. Contrast `charge_guess_golden` (`wallet.ex:122-139`): `update!(keys -= fee)` **+
`txn!(-fee, "guess", ref)`** (a *real* signed row) + `inc_pool!(fee×10)`. **So the asymmetry cm.6
closes is internal to the codebase, not just finance-facing:** guess debits are already ledgered;
buy-in debits are not.

**L-4 · The pool is a games COLUMN incremented by atomic SQL `+`, not a ledger account.**
`inc_pool!` (`wallet.ex:371`) is `update_all(inc: [prize_pool: 💎])` on the `games.prize_pool`
column. The pool is **not** a `transactions` balance — so "the pool side" of any double-entry the
Steward writes is a *conversion/minting entry at the column boundary*, never a row that sums into
`Σ transactions`. This is why the balance invariant (§6) is stated **at the keys unit with the
×10 keys→💎 as the one accounted minting step**, not as `Σ all TXN deltas == 0` across mixed
currencies.

**L-5 · `txn!` already exists and is the credit primitive.**
`txn!` (`wallet.ex:380`) writes a **real signed-delta `TXN`** and is used by guess/convert/credit/
debit. The Steward's house credits are **`txn!` calls with a house player + a new reason** — *zero
new write primitive*. This is the reuse the lens is built on.

**L-6 · Distribution is already double-entry; revenue is the only gap.**
`distribute_pool/3` (`wallet.ex:252-268`) credits the finish (`deposit_prize` 💎 `"prize"` + grant
clips `"consolation"`) in nested `txn!`s that **join the parent transaction** → atomic. The
*payout* is balanced; the *revenue* is implicit. cm.6 closes exactly one half — it adds **no new
fee and changes no cm.5 amount** (cm.6.md Scope Out).

**L-7 · The split already computes the pool portion; the house cut is its complement.**
`Economy` (`economy.ex`): `@diamonds_per_key 10` (`:13`), `@cents_per_diamond 1.2` (`:11`);
`entry_fee_split/5` (`:45-52`) = pool 💎 `floor(entry_fee_keys × (100 − revenue%)/100) × 10` for the
first-mover band, else 0 — the **platform portion is the implicit complement**
`entry_fee_keys − floor(entry_fee_keys × (100 − revenue%)/100)`. `diamonds_for_keys` = `k × 10`
(`:19`). The canonical conversion is fixed: **1 key = 10 💎 = 12¢.**

**L-8 · Seed / void are settled, no-refund.**
Golden `start_game` seeds `prize_pool = virtual_deposit` 💎; `close_void` → status `:voided` +
reclaim the unpaid deposit, **no player refund** (cm.5 D-7). (cm.5.postgres.design.md §2 / §7.)

**L-9 · The freeze + boundary.**
The two shipped migrations **and** the cm.5 `golden_rooms` migration are **byte-frozen**; cm.6's
house representation is a **new additive migration** (§8). The boundary is
`echo/apps/codemojex/**` + the rung docs; `mix.lock` untouched; no sibling umbrella app.

**The Steward's reading of these nine:** L-1 + L-5 + L-6 say the credit machinery already exists
and a new reason is free — the *only* genuinely new surface cm.6 forces is **a representation for
the house that can hold balance (incl. a transient negative seed) and can later carry an account
lifecycle for the BNK rake/withdrawal.** That single forced surface is F1, and L-2 is the reason
the lightest F1 arm is not free. Everything else (the unit, the entry side) is a reuse-vs-purity
trade, not a forced build.

## §1 — F1 The house representation

**The forced surface.** cm.6 needs a thing the house's revenue accrues to. Arm 1 reuses the
`players` + `transactions` substrate (a sentinel system `PLR`); Arm 2 builds a dedicated
`revenue_ledger`/accounts table. The Steward ranks reuse first **and pays the honest cost** of the
two liabilities it carries (the `players_non_negative` collision · actor-conflation).

### Arm 1 — a reserved SYSTEM `PLR` (sentinel house player; reuse `transactions` + `players`)

**Rationale.** L-1 + L-5 + L-6 mean the entire credit path already exists: a house credit is one
`txn!(house_id, "keys", +cut, reason, ref=game)` joining the buy-in's existing
`Repo.transaction`. The house *balance* is then the same `SUM(delta) … GROUP BY currency` query
that reads any player. No new table, no new write primitive, no new read primitive — the lightest
change that makes Σ balance. The seed (cm.6.md §2) is a single house *debit* row; recovery credits
cancel it (the zero-loss becomes explicit) exactly as the spec's S-DEPOSIT-RECOVERY net states.

**5W.**
- **Why** — the Steward thesis: do not manufacture schema the bank will re-shape; reuse the proven,
  append-only ledger and pay only for what reuse genuinely breaks.
- **What** — one reserved branded `PLR` (a sentinel, minted once at migration or seeded as data),
  treated as the credit counterparty; revenue `TXN`s addressed to it; balance read by `SUM(delta)`.
- **Who** — the house `PLR` is the single counterparty for `deposit_seed` (debit), `deposit_recovery`
  / `revenue` / `deposit_reclaim` (credits). The BNK rake/withdrawal later debit/credit the **same
  id** — but see the Steward cost.
- **When** — the sentinel exists from cm.6's migration forward; forward-only (cm.6.md Scope Out:
  no backfill); it inherits the games-row lock on the buy-in path (no new race).
- **Where** — `Wallet` (the credit call sites, §5), `transaction.ex` (unchanged — L-1), `player.ex`
  (the **CHECK is the problem**, §4), and a new `house_balance/0..1` read in `Wallet`/`Store`.

**Steelman.** This is what a seasoned BEAM/Postgres engineer reaches for first, and rightly: the
ledger is already the source of truth, already append-only, already atomic via parent-join (L-6).
Adding a table to hold a *running sum the ledger can already compute* is duplicated state — two
places revenue lives, which can disagree. Reuse keeps **one** source of truth. The sentinel pattern
is industry-standard (a "system account" / "house book") and the `(player, ref)` exactly-once index
extends naturally to credit idempotency if the bank ever needs it. cm.5's *own distribution* proves
the pattern: `deposit_prize` already credits a player-shaped counterparty via `txn!` — the house is
symmetric to that.

**Steward.** Reuse is the lens, but reuse here is **not free** — two honest costs, both priced, not
waved:
- **(C-1) The `players_non_negative` collision (L-2).** A sentinel `PLR` is a `players` row, so the
  DB CHECK forbids it going negative. The seed debit (`deposit_seed`, `−virtual_deposit/10` keys)
  drives it negative on write → the insert *raises*. This is real and load-bearing; §4 resolves it
  three ways (record the seed as a debit `TXN` **without** mutating a balance column — the house
  balance is `SUM(delta)`, never a column · OR exempt the sentinel id from the CHECK · OR carry the
  house outside `players` entirely, which is Arm 2). The Steward's resolution is the first: **the
  house never has a balance *column*; its balance is the ledger sum** — so the CHECK never applies to
  it because no house row exists in `players` at all (the sentinel is an *id*, the balance is the
  `TXN` sum). This is lighter than it sounds (§4) but it is the cost.
- **(C-2) Actor-conflation.** A house `PLR` shares the namespace and balance-read code path with real
  players; a careless `Players.all` / leaderboard / total-supply query can sweep the house in. The
  brand-namespace is the same (`PLR`), so *the type system does not distinguish house from player* —
  the very BCS discipline (the brand IS the type) is slightly bent. Mitigation: a reserved,
  well-known house id + a documented exclusion predicate; but it is a permanent footgun the bank
  inherits.

### Arm 2 — a dedicated `revenue_ledger` / accounts table

**Rationale.** Give platform revenue its own home: a `revenue_ledger` table (or a small `accounts`
table the house is one row of) with its own signed-entry rows, free of the `players` CHECK and
cleanly separable from player balances. The seed debit is then *expected* (a revenue account is
allowed to be negative mid-game); the actor is unambiguous; the BNK rake/withdrawal get a real
account lifecycle (an account type, a withdrawable-balance concept) to hang on.

**5W.**
- **Why** — separation of concerns: platform money is not a player; modelling it as one borrows a
  schema (the CHECK, the player columns) that fights revenue's actual shape.
- **What** — a new additive table (`revenue_ledger {id, account, currency, delta, reason, ref,
  inserted_at}` mirroring `transactions`, *or* a thin `accounts` table + house rows in
  `transactions`). The house balance is `SUM(delta)` over **that** table.
- **Who** — an explicit house/platform account row; later the BNK rake/withdrawal are first-class
  operations on it.
- **When** — the table ships in cm.6's additive migration; forward-only.
- **Where** — a new schema module + migration; `Wallet` writes house entries to it inside the same
  `Repo.transaction`.

**Steelman (the bank-architect's strongest case — pre-empted here, per the lens brief).** A reused
**player** ledger **conflates actors and cannot carry the account lifecycle** the rake/withdrawal
need: a withdrawal must debit a *withdrawable platform balance* with its own rules (settlement
state, possibly multi-currency netting, a "real-money cash-out" lifecycle, cm.6.md Scope Out → BNK);
a player row models none of that and the `players_non_negative` CHECK actively obstructs it. cm.6.md
itself frames the BNK as building **on** this house account — so the house representation is *not*
cm.6's to dispose of lightly; it is the bank's foundation, and founding it on a sentinel player is a
foundation the bank must immediately rebuild. Separation now is cheaper than a migration later under
live money. **This is the objection the Steward must answer, and does, in the recommendation.**

**Steward.** Honest, but **heavier than cm.6 needs and speculative about the bank's shape.** It adds
a table, a schema module, a second `SUM(delta)` read path, and a parallel set of stories — for a
*running sum the ledger already computes* (the Arm-1 Steelman's duplicated-state point applies in
reverse: a dedicated table is the second source of truth). The account-lifecycle the Steelman cites
is **explicitly cm.6 Scope Out** (rake, withdrawal → later BNK slices); designing the table's
lifecycle *now*, before the bank's requirements exist, is **building surface the bank will re-shape
anyway** — the exact anti-pattern the lens names. The Steward's counter is not "the conflation
isn't real" — it is "**the seam, not the table, is what the bank needs from cm.6**."

### Ranked recommendation (ADVICE — the Operator rules)

**Rank: Arm 1 (sentinel `PLR`) recommended for cm.6 — but `house_id` behind a single
`Wallet.house_account/0` seam so the bank can swap the representation without touching the call
sites.** The one reason: **cm.6's job is to make revenue a balanced, queryable `SUM(delta)` — which
the existing ledger already does — and every gram of new schema is surface the unspecified bank will
re-shape.** The lightest arm that makes Σ balance is the sentinel, *provided its two costs are paid*:
C-1 is resolved by **never giving the house a balance column** (its balance is the ledger sum; the
CHECK never applies — §4), and C-2 is resolved by **a reserved id behind one accessor**, which also
neutralises the Steelman.

**Rebuttal to the bank-architect's objection (the conflation/lifecycle case).** The objection is
correct that a *player row* cannot carry a withdrawal lifecycle — but the Steward does not propose a
player *row*; it proposes a reserved *id* whose balance is a ledger sum, reached **only** through
`Wallet.house_account/0`. When the bank arrives, "promote the house to a real `accounts` table" is a
*data move behind one function* (re-point `house_account/0`, migrate the house's `TXN`s — all
`ref`-keyed and replayable, L-1), not a rewrite of cm.6's five credit sites. **The seam buys the
bank's optionality at near-zero cm.6 cost; the table spends cm.6's budget on a lifecycle whose
requirements do not yet exist.** If the Operator already has a firm withdrawal/settlement spec in
hand, that calculus flips and Arm 2 is right — so the decisive question for the Operator is: *is the
BNK account lifecycle specified enough to design its table now?* If no → Arm 1 + seam. If yes →
Arm 2. The Steward, lacking that spec, ranks Arm 1.

## §2 — F2 The ledger unit

**The question.** At what unit does the balance invariant hold? Arm 1 keeps **keys** (the entry
unit, with the pool's ×10 keys→💎 as an explicit conversion entry). Arm 2 normalizes every entry to
**one canonical unit** (💎 or cents) so a single `SUM(delta) == 0` proves balance.

### Arm 1 — keys-unit (`entry_fee_keys = house_credit_keys + pool_portion_keys`; the ×10 is a named conversion entry)

**Rationale.** The entry fee is denominated in **keys** (`entry_fee_keys`, L-3/L-7); the player debit
is in keys; the house credit is therefore most naturally in keys. The pool, however, lives in 💎
(L-4, `prize_pool` column) at the fixed `×10` (L-7). So the invariant is stated **at the keys unit**:
`entry_fee_keys = house_credit_keys + pool_portion_keys`, and the pool's keys→💎 ×10 is the **one
accounted minting/conversion boundary** — exactly cm.6.md Scope §4 and S-DOUBLE-ENTRY-BALANCE. The
`transactions.currency` column is already a free string (L-1), so keys rows and any 💎 rows coexist
without schema change.

**5W.**
- **Why** — the fee, the player debit, and the house cut are all naturally keys; pricing them in keys
  keeps the player-debit ↔ house-credit pairing in **one unit** with no conversion at the pairing.
- **What** — house credits are `"keys"`-currency `TXN`s; the pool portion is converted **once**, at
  the pool boundary, and that conversion is the named exception in the invariant.
- **Who** — `entry_fee_split` already computes the pool 💎 (L-7); the house keys credit is its keys
  **complement** `entry_fee_keys − floor(entry_fee_keys×(100−rev%)/100)` — no new arithmetic, the
  same numbers cm.5 already produces.
- **When** — every buy-in; the conversion is per-entry at the first-mover band, zero elsewhere.
- **Where** — `Economy.entry_fee_split` (the complement is read here, §5); `Wallet` (the keys credit).

**Steelman.** This is the **exact unit cm.6.md writes the invariant in** (Scope §4, Acceptance,
S-DOUBLE-ENTRY-BALANCE all say "at the entry unit / keys"), so Arm 1 ships the spec verbatim with no
re-derivation. It keeps the dominant pairing (player debit ↔ house credit) in a *single* unit, so the
common case has **no conversion at all** — only the first-mover band touches the ×10, and there it is
*already* computed by `entry_fee_split`. The conversion is **localized to one named boundary**, which
is exactly how you want a minting step: auditable, singular, labelled. Integer keys also sidestep any
rounding question on the dominant path.

**Steward.** The honest cost: the ledger now holds **mixed currencies** (keys for the entry pairing,
💎 for the pool/distribution side, L-6), so `Σ all TXN deltas` is **not** a single zero — you must
prove balance *at the keys unit with the conversion named*, not by one blind `SUM`. That is a
slightly more nuanced proof (§6) and a slightly more careful reconciliation read (must group by
currency and apply the ×10 at the pool boundary). But this mixed-currency reality **already exists in
cm.5** (guess credits the pool in 💎, distribution pays 💎, fees move in keys) — Arm 1 does not
introduce it; it *names* it. The Steward judges naming an existing reality cheaper than re-denominating
the whole ledger.

### Arm 2 — a normalized-currency ledger (one canonical unit — 💎 or cents)

**Rationale.** Convert **every** entry to one unit (the natural candidate is 💎, since the pool and
distribution already live there; cents is the true-money unit, L-7 `@cents_per_diamond 1.2`). Then the
double-entry invariant is the textbook one: **`SUM(delta) == 0`** over the whole ledger, no
per-currency grouping, no named conversion exception.

**5W.**
- **Why** — one unit ⇒ one blind-`SUM` proof of balance; the cleanest possible invariant.
- **What** — the player debit, the house credit, and the pool portion are all 💎 (or all cents);
  keys are converted at the boundary into the canonical unit before they hit the ledger.
- **Who** — every money site converts to the canonical unit; `entry_fee_split` already emits 💎 for
  the pool, so the pool side is native; the player/house sides convert keys→💎 (×10).
- **When** — at every entry, on every side.
- **Where** — every `Wallet` money site; the conversion moves from "one named boundary" to "every
  row."

**Steelman.** A single canonical unit gives the **strongest, simplest invariant** — `SUM(delta) == 0`
is unarguable and trivially testable; no reviewer has to reason about a conversion exception. If cm.6
were greenfield, this is the disciplined choice, and cents (the real-money unit) would even let
finance read the ledger in dollars directly.

**Steward.** **Heavier and it fights the as-built grain.** (a) It **re-denominates the player debit**
— but cm.5 debits the player in *keys* via a bare `keys -= fee` update (L-3), and cm.6.md Acceptance
demands "the cm.5 suite stays green **untouched**, the player/pool figures **unchanged**." Normalizing
the player side to 💎 either changes how cm.5 records the debit (a cm.5 edit — forbidden) or creates a
keys-debit / 💎-credit pair that *itself* needs a conversion entry — reintroducing the very exception
Arm 2 claimed to remove, now on the dominant path. (b) Choosing 💎 makes the *keys* fee the thing that
gets converted on every entry (more rounding surface); choosing cents converts *both* keys and 💎
everywhere. (c) It is **more migration/rewrite than cm.6 needs** for a proof nicety. The Steward reads
cm.6.md's repeated "at the entry unit / keys" as the spec *already choosing* this fork — Arm 2 would be
overriding the brief.

### Ranked recommendation (ADVICE — the Operator rules)

**Rank: Arm 1 (keys-unit) recommended.** The one reason: **cm.6.md states the invariant in keys with
the ×10 as the single named conversion (Scope §4, S-DOUBLE-ENTRY-BALANCE), and Arm 1 ships that
verbatim while keeping the player-debit ↔ house-credit pairing in one unit and reusing the exact
numbers `entry_fee_split` already computes — Arm 2 would re-denominate the cm.5 player debit, which
Acceptance forbids touching.** The mixed-currency proof is a real but small cost, paid in §6 by stating
balance *at keys with the conversion named*, not as a blind `SUM`.

**Rebuttal to the normalization case.** Arm 2's "one blind `SUM == 0`" is genuinely cleaner **in the
abstract**, but it is clean *because* it pushes the keys→canonical conversion onto **every** row,
including the player debit cm.5 already shipped in keys — so the simplicity is bought with either a
cm.5 edit (forbidden) or a per-entry conversion pair (the exception returns, multiplied). Arm 1
concentrates the **one** unavoidable conversion (keys→💎 at the pool) into the **one** named boundary
the spec already designates. The conversion does not disappear under Arm 2 — it *spreads*. Concentrated
and named beats spread and implicit. (If finance hard-requires a single dollar-denominated `SUM` for
external reporting, that is a *reporting view* — a read that converts at query time, §7 — not a reason
to re-denominate the write path.)

## §3 — F3 The entry-side representation

**The question.** cm.5 records the buy-in oddly from a ledger-purist view (L-3): a `delta:0` marker
`TXN` + a **bare** `keys -= fee` balance update (no signed row) + an atomic pool *column* increment
(L-4). Arm 1 leaves all of that **exactly as-is** and *adds* house-credit rows in the same
`Repo.transaction` (cm.5 suite untouched). Arm 2 **reconciles** the buy-in path: the player debit
becomes a real signed `TXN`, the pool becomes a ledger account.

### Arm 1 — ADDITIVE OVERLAY (leave cm.5's buy-in shape verbatim; ADD house credits in the same transaction)

**Rationale.** cm.6.md's Acceptance and S-EXISTING-GREEN are explicit: "**the cm.5 suite stays green
untouched**," "the pool/player figures **unchanged**," "the house credit **makes the implicit
explicit; it does not move money differently**." The overlay honors that to the byte: the `delta:0`
buy-in marker, the bare `keys -= fee` update, and the `inc_pool!` column write **stay exactly as cm.5
shipped them**; cm.6 only **adds** `txn!(house_id, +cut, reason, ref=game)` (L-5) inside the *same*
`Repo.transaction` so the credit is atomic with the debit it pairs to. No cm.5 line moves; no cm.5
test changes; the revenue side becomes explicit purely additively.

**5W.**
- **Why** — the lightest change that satisfies cm.6.md Acceptance *as written*; "stays green
  untouched" is read as a first-class constraint, not a courtesy.
- **What** — house credit rows added; the cm.5 player-debit representation (`delta:0` marker + bare
  balance update) and the pool column (L-4) left verbatim.
- **Who** — Mars adds five `txn!` credit sites (§5) inside existing transactions; touches no cm.5
  debit/pool code.
- **When** — the credit joins the buy-in's existing games-row-locked `Repo.transaction` (cm.5 RULING
  1) → inherits the ordinal serialization, no new lock, no new race (cm.6.md Scope §6).
- **Where** — purely the credit insertion points (§5); the cm.5 sites are read-only references.

**Steelman.** This is the **only** arm that satisfies cm.6.md Acceptance *literally* — "the cm.5
suite stays green untouched" is unachievable if you rewrite the debit into a signed row (that *is*
touching cm.5's recorded shape; its tests assert the current shape). It is the smallest possible diff
(five additive `txn!` calls + a read + a representation), the lowest regression risk on **live
withdrawable money** (L-8), and it keeps cm.6 *purely additive on the revenue side* exactly as
cm.6.md Scope Out demands ("any cm.5-resolved surface … untouched"). The balance invariant (§6) is
fully provable over the overlay: the player debit is observable as the bare `keys` delta, the house
credit as the `TXN`, the pool as the column delta — the three reconcile at the keys unit without
*re-representing* any of them.

**Steward.** The honest cost: **the ledger remains internally asymmetric.** After the overlay, the
*guess* debit is a signed `TXN` (L-3) but the *buy-in* debit is still a bare balance update with a
`delta:0` marker — so "read every debit from `transactions`" is **still false** for buy-ins; the
player-debit half of the buy-in double-entry lives in the `keys` column, not the ledger. The house
*credit* is balanced and queryable, but its *counter-entry* (the player debit) is not co-located in
the same table. The Steward accepts this: cm.6.md's invariant is stated **at the keys unit across the
three observable deltas** (debit-column, credit-TXN, pool-column), not as "every leg is a
`transactions` row" — so the overlay *satisfies the spec's invariant* even though it does not achieve
full ledger purity. Purity is Arm 2's prize, and the spec did not ask for it.

### Arm 2 — RECONCILE the buy-in path (the debit becomes a real signed row; the pool becomes a ledger account)

**Rationale.** Make the buy-in symmetric to the guess: replace the `delta:0` marker + bare
`keys -= fee` with a real `txn!(player, -fee, "buy_in", ref)` signed row, and promote the pool from a
games column (L-4) to a ledger account, so **every leg of every entry is a `transactions` row** and
balance is `SUM(delta) == 0` over a single table. The cleanest possible ledger.

**5W.**
- **Why** — full double-entry purity: one table, every leg a row, the textbook invariant.
- **What** — the buy-in debit becomes signed; the pool becomes an account (a pool counterparty id or
  a pool ledger), so the pool increment is a `TXN` not a column `+`.
- **Who** — Mars rewrites `insert_buy_in` (the `delta:0` → signed), the bare `keys -= fee` site, and
  `inc_pool!` (column → ledger); the membership/exactly-once marker must be preserved *separately*
  (the `delta:0` row is **also** the `(player, ref) WHERE reason='buy_in'` exactly-once authority, L-1
  — collapsing it into a debit must not lose that index's guarantee).
- **When** — a buy-in-path rewrite, not an overlay.
- **Where** — `wallet.ex:347-366` (`insert_buy_in`), `:226` (the bare debit), `:371` (`inc_pool!`),
  plus every cm.5 read of `prize_pool` that now must sum a ledger instead of reading a column.

**Steelman.** A reconciled ledger is **objectively the better long-term artifact**: one source of
truth, every leg a row, `SUM == 0` provable blind, no "which debits are ledgered and which aren't"
asymmetry, and the BNK bank inherits a *uniform* ledger rather than a column-plus-rows hybrid. The
guess path already does this (L-3) — Arm 2 makes the buy-in *consistent* with the guess, removing a
genuine wart. If the Operator's true intent under "best-practices ledger" is **a pure ledger**, this
is the faithful reading.

**Steward.** **This arm cannot be reconciled with cm.6.md Acceptance, and it is high-risk on live
money.** (a) It **directly violates** "the cm.5 suite stays green untouched" / "pool figures
unchanged" — promoting the pool to a ledger changes how *every cm.5 read* of `prize_pool` works
(`distribute_pool`, the void reclaim, the seed, the inc), so cm.5 tests asserting column reads break
*by construction*. (b) It is **explicitly Scope Out**: "any cm.5-resolved surface (… the pool
denomination, the distribution double-entry) — untouched; cm.6 is purely additive on the revenue
side." Promoting the pool is *not additive* and *not revenue-side*. (c) Collapsing the `delta:0`
marker into a debit risks the **exactly-once membership index** (L-1) — a subtle, money-critical
regression (double-membership) on the hottest path. (d) It is the **larger diff on withdrawable money**
(L-8) for **zero new revenue-side capability** — the house credit is equally explicit and queryable
under the overlay. The Steward's verdict: Arm 2 is the right *eventual* refactor, but it is **a
separate, non-cm.6 rung** ("unify the buy-in debit into the ledger / promote the pool"), correctly
*deferred*, not smuggled into a revenue rung whose Acceptance forbids it.

### Ranked recommendation (ADVICE — the Operator rules)

**Rank: Arm 1 (additive overlay) recommended — decisively.** The one reason: **cm.6.md Acceptance and
S-EXISTING-GREEN make "the cm.5 suite stays green untouched / pool figures unchanged / does not move
money differently" a hard constraint, and only the overlay satisfies it — Arm 2 breaks cm.5 reads by
construction and is explicitly Scope Out (the pool denomination + distribution are cm.5-resolved).**
The overlay makes the **revenue side** explicit and balanced (cm.6's actual job) while leaving the
cm.5 *entry/pool* representation exactly as shipped.

**Rebuttal to the purity case.** Arm 2's purity is real and desirable — but it is **purity of the cm.5
entry path, which cm.6.md placed Out of scope and protected with a green-suite Acceptance.** The
correct response to a worthy refactor that the current rung forbids is to **name it as a follow-on
rung**, not to expand cm.6's blast radius onto live money mid-flight. Note the asymmetry the overlay
*does* leave (buy-in debit unledgered while guess debit is ledgered, §3 Steward) and **flag it
forward** (§10) as the seam for that future "ledger-unification" rung — the Steward records the debt
honestly rather than paying it with the wrong budget.

## §4 — The house-account schema/representation shape (under the recommended arms)

Recommended arms: **F1-Arm1 (sentinel `PLR` behind `Wallet.house_account/0`) · F2-Arm1 (keys-unit) ·
F3-Arm1 (additive overlay).** Under those, the house's representation is **deliberately almost
nothing** — and resolving the `players_non_negative` collision (L-2 / C-1) is the one piece of real
design here.

**The shape: the house is an ID, not a row.** The house has **no `players` row** and therefore **no
balance column**. It is a single reserved branded `PLR` id (a well-known constant), and its balance is
**defined as `SUM(delta) … WHERE player = <house_id> GROUP BY currency`** over `transactions`. Three
consequences:

1. **C-1 dissolves rather than being patched.** The `players_non_negative` CHECK (L-2) constrains
   `players` *columns*; the house has none, so the **seed debit** (`deposit_seed`,
   `−virtual_deposit/10` keys) is just a negative `TXN` row — and `transactions.delta` is a plain
   signed int with **no CHECK** (L-1). A house balance that is transiently negative mid-game is simply
   a `SUM(delta)` that is currently negative — entirely legal. *No CHECK is touched, no exemption is
   added, the sentinel never appears in `players`.* This is the Steward's lightest resolution: the
   collision was an artifact of assuming the house needs a balance *column*; it does not.
2. **The reserved id.** A single constant `PLR` — minted once and pinned as an application constant
   (a module attribute `@house_id` on `Wallet`, asserted at boot the way the branded-id boot vectors
   are asserted elsewhere), **not** a `players` row to be inserted. NO-INVENT flag for Mars: the exact
   id-minting/derivation mechanism (a fixed literal `PLR…` vs a `BrandedId.derive` from a seed) is a
   build detail to confirm against `EchoData.BrandedId` — the *shape* (one reserved constant id) is
   what this design fixes.
3. **The single seam (the F1 rebuttal made concrete).** Every house reference goes through
   **`Wallet.house_account/0`** (returns the id) and **`Wallet.house_balance/0..1`** (returns the
   `SUM(delta)` by currency, optionally per-game by `ref`). The five credit sites (§5) and the
   reconciliation read (§7) call **only** these — so when the BNK bank promotes the house to a real
   `accounts`/`revenue_ledger` table, it re-points two functions and migrates the house's `ref`-keyed
   `TXN`s; the call sites do not move.

**Why not a balance column even for convenience.** A column would (a) re-introduce C-1 (the CHECK),
(b) create the duplicated-state problem (the column and `SUM(delta)` can disagree — the Arm-1 Steelman
against Arm 2 applies to the house's *own* representation), and (c) require an `UPDATE` path the
append-only ledger otherwise avoids (L-1). The `SUM(delta)`-only house is *both* lighter *and* purer
than a column-backed house. (Read-perf: if the house balance is ever hot, a materialized view or a
periodic snapshot is a later optimization — but it is a *cache* of the `SUM`, never the source.)

**C-2 (actor-conflation) mitigation, recorded.** Because the house id shares the `PLR` namespace, any
query that enumerates players (a leaderboard, a total-keys-in-circulation audit) can sweep it in. The
mitigation is **a documented exclusion predicate** (`player != Wallet.house_account()`) applied at those
read sites, plus the well-known-constant id so the exclusion is greppable. This is a permanent footgun
the design *names* rather than removes — and it is the strongest input to the Operator's F1 ruling: if
the conflation risk is judged unacceptable on withdrawable money, F1-Arm2 (a separate table) is the
answer, at the schema cost §1 priced.

**Net new surface under the recommendation:** **zero new tables, zero new columns, zero migration**
for the house *balance* (the seed/recovery/revenue/reclaim are all `TXN` rows via the existing `txn!`).
The only thing §8 leaves to decide is whether a *trivial* additive migration is wanted at all — see §8
(the Steward's answer: likely **none**, which is itself a finding).

## §5 — The paired-credit insertion points (deposit_seed · deposit-recovery · first-mover · full-revenue · void-reclaim) keyed to wallet.ex sites

The five revenue movements, each as a `txn!` against `Wallet.house_account()` (§4), keyed `ref=game`.
**Critical NO-INVENT distinction (verified this session):** the house credit must use the private
**`txn!`** (`wallet.ex:380` — inserts a signed `TXN` *only*, no balance column, no `lock`), **never
`credit`** (`wallet.ex:305-318` — which `lock`s a `players` row and `update!`s a column, so it would
*require* a house `players` row and re-introduce C-1). The house has no row; `txn!` is its exact
primitive. Mars makes `txn!` (or a thin `house_txn!` wrapper) reachable from the credit sites.

| Movement | cm.5 site (verified) | The paired house `TXN` (keys, via `txn!`) | Same `Repo.transaction`? |
|---|---|---|---|
| **deposit_seed** | `rooms.ex:173-178` `formation/3` seeds `prize_pool = virtual_deposit` 💎 — a **`Store.put_game` (Valkey) write**, *not* a Postgres `games` row, *not* inside `Wallet.buy_in` | `txn!(house, "keys", −div(virtual_deposit, 10), "deposit_seed", game)` | **NO — separate path (see SEAM-1)** |
| **deposit_recovery** (ordinal 1..`start_threshold`) | `buy_in/2` `wallet.ex:226` bare `keys -= fee`; `entry_fee_split` returns **0** here (`economy.ex:51-52`) so no pool credit | `txn!(house, "keys", +fee, "deposit_recovery", game)` | **YES** — inside `buy_in`'s `Repo.transaction`, on the `:wrote` branch, after the debit |
| **first-mover revenue** (band) | `buy_in/2` `wallet.ex:228-237`; `pool = entry_fee_split(...)` = `div(fee×(100−rev%),100)×10` 💎; `inc_pool!` adds it | `txn!(house, "keys", +(fee − div(fee×(100−rev%),100)), "revenue", game)` — the **keys complement** of the pool's keys portion (the exact integer `pool_keys` `economy.ex:47`) | **YES** — same `Repo.transaction`, paired with the existing `inc_pool!` |
| **full revenue** (ordinal > band) | `buy_in/2` `wallet.ex:226`; `entry_fee_split` returns **0** (`economy.ex:51`) | `txn!(house, "keys", +fee, "revenue", game)` | **YES** — same `Repo.transaction` |
| **void deposit_reclaim** | `rooms.ex:462` `close_void` — under a **Valkey `SET cm:<game>:closed NX`** lock, "**No money moves … no per-player loop**"; touches **no Postgres** today | `txn!(house, "keys", +(Σ kept fees + unpaid seed), "deposit_reclaim", game)` — the explicit booking of the kept-fees-plus-reclaimed-deposit | **NO — separate path (see SEAM-2)** |

**The three buy-in movements are clean overlays.** deposit_recovery / first-mover / full-revenue all
live **inside `Wallet.buy_in/2`'s existing `Repo.transaction`** on the `:wrote` branch
(`wallet.ex:224-238`). Mars adds **one** `txn!(house, …)` call there, computing the keys cut from the
*same* `ordinal` / `entry_fee_split` inputs already in scope — so the credit is **atomic with the
player debit and the pool increment** (S-ATOMIC-DOUBLE-ENTRY), inherits the **games-row `FOR UPDATE`
lock** (cm.5 RULING 1 → no new race, cm.6.md Scope §6), and reuses cm.5's exact numbers (no new
arithmetic; the house keys cut is `fee − pool_keys`, exact integer subtraction — see §6). **A single
branch addition covers all three** (the reason + the keys amount switch on which `entry_fee_split`
band the ordinal is in).

**SEAM-1 (deposit_seed) — the architectural finding the Steward surfaces.** The seed is **not** a
Postgres write and **not** inside any `Repo.transaction` — `formation/3` seeds the pool in **Valkey**
(`Store.put_game`, `rooms.ex:173-178`). So "paired and atomic with the pool credit" (cm.6.md S-SEED)
**cannot be a single `Repo.transaction`** the way the buy-in credits can — the pool side is a Valkey
field, the house debit is a Postgres row. Two honest options for the Operator/Mars:
- **(1a)** Record the `deposit_seed` house debit at golden formation as a standalone `txn!` adjacent to
  the `Store.put_game` seed — accepting that the seed's two legs (Valkey pool field · Postgres house
  `TXN`) are **not** in one ACID transaction (they are coupled by the same `formation` code path and
  the `ref=game` key, the way cm.5 already couples Valkey game-state and Postgres ledger across the
  whole app). The balance invariant (§6) still holds *at settlement* because the seed debit cancels the
  recovery credits (S-DEPOSIT-RECOVERY net) regardless of the exact instant each leg is written.
- **(1b)** Defer the seed *debit* recording to first buy-in or to close (book it lazily), so it lands
  inside a `Repo.transaction`. Heavier; changes when the seed is observable.
- The Steward leans **1a** (honest about the cross-store coupling cm.5 already lives with; the invariant
  is a *settlement* property, not a per-instant one) and flags it as the one place "atomic double-entry"
  is looser than the buy-in credits — Mars/Apollo must state the determinism posture for it.

**SEAM-2 (void deposit_reclaim).** `close_void` currently moves **no money** and runs under a Valkey
NX close lock with **no Postgres transaction** (`rooms.ex:462-472`). Booking the `deposit_reclaim`
credit means **adding a Postgres `txn!`** to a path that today is Valkey-only. The reclaim amount is
`Σ kept fees + unpaid seed` — but note the kept fees were *already* booked as `deposit_recovery` /
`revenue` credits at each buy-in (the rows above), so **double-counting is the hazard**: the reclaim
must book **only the un-booked remainder** (principally the *unpaid seed* the void reclaims — the seed
debit is cancelled by the reclaim, mirroring how recoveries cancel it on the happy path), **not** re-credit
the fees already in the ledger. The Steward's precise reading: at void, the house already holds
`+Σ recovery/revenue` (from buy-ins) and `−seed` (from SEAM-1); the void's economic event is "the seed
is never paid out, so the platform reclaims it" → the booking is a `+seed` `deposit_reclaim` credit
that **cancels the seed debit**, leaving the house net = `Σ kept fees` (the platform's actual void
take). Mars must compute the reclaim as the *seed-cancelling* amount, NOT `Σfees + seed` literally
(which would double-book the fees). **This is a money-critical NO-INVENT flag (§10).**

**The `txn!` plumbing.** `txn!` is private (`wallet.ex:380`); the buy-in credits call it from *within*
`Wallet` (already in scope). SEAM-1/SEAM-2 fire from `Rooms` — so either (a) expose a public
`Wallet.book_house(reason, amount_keys, game)` thin wrapper over `txn!`, or (b) move the seed/reclaim
booking into `Wallet` functions `Rooms` calls. Either keeps the house-credit primitive single and
behind the `Wallet` boundary (§4's seam). NO-INVENT: confirm `EchoData.BrandedId.generate!("TXN")`
(`wallet.ex:381`) is the id mint for the new rows — it is the one `txn!` already uses.

## §6 — The balance-invariant proof sketch (at the recommended unit)

**The invariant (cm.6.md S-DOUBLE-ENTRY-BALANCE, at the keys unit):**

> `Σ(player key debits) == Σ(house key credits) + Σ(pool key-equivalent portions)`

— no key minted or lost; the ×10 keys→💎 at the pool is the **one** accounted minting boundary.

**Per-entry algebra (the load-bearing step).** For any buy-in at `ordinal`, the player is debited
`fee` keys (`wallet.ex:226`). Define `pool_keys = div(fee × (100 − rev%), 100)` — the **exact integer**
`economy.ex:47` computes (floored in *keys*, the cm.5 rounding pin). The split's three bands:

| Band | `entry_fee_split` (💎) | `pool_keys` | house keys credit (§5) | player debit |
|---|---|---|---|---|
| ordinal ≤ `start_threshold` | 0 | 0 | `fee` (`deposit_recovery`) | `fee` |
| first-mover band | `pool_keys × 10` | `div(fee×(100−rev%),100)` | `fee − pool_keys` (`revenue`) | `fee` |
| ordinal > band | 0 | 0 | `fee` (`revenue`) | `fee` |

In **every** band, `house_keys + pool_keys == fee` **exactly**, because `house_keys` is *defined* as
`fee − pool_keys` (integer subtraction, no rounding — the floor already happened inside `pool_keys`).
So per entry: `player_debit(fee) == house_credit(fee − pool_keys) + pool_portion_keys(pool_keys)`. ∎
**The keys partition exactly, with zero dust**, precisely because the only rounding (the floor in
`pool_keys`) is shared by both sides of the subtraction — this is why the keys unit (F2-Arm1) makes the
proof trivial where a re-denominated ledger (F2-Arm2) would reintroduce a per-entry rounding term.

**The ×10 conversion is conservative and singular.** The pool receives `pool_keys × 10` 💎
(`economy.ex:48`). At the keys unit this is `pool_keys` keys-equivalent (`@diamonds_per_key = 10`,
`economy.ex:10`), so it enters the invariant as `pool_keys` and balances. The conversion conserves to
whole diamonds **by construction** (floor-before-×10), so no 💎 is minted or lost at the boundary
either. This is the *one* minting step the invariant accounts for; everything else is keys-conserving.

**Summing over a game (incl. the seed).** Let the game take members `1..N`. Then:
- `Σ player debits = Σ_{i=1..N} fee_i` (each buy-in's keys debit).
- `Σ house credits (buy-in) = Σ_{i=1..N} (fee_i − pool_keys_i)`.
- `Σ pool portions = Σ_{i=1..N} pool_keys_i`.
- Their identity `Σ debits = Σ house + Σ pool` holds term-by-term (the per-entry algebra). ∎

**The seed (the zero-loss made explicit).** The house *also* holds the `deposit_seed` debit `−V/10`
keys (V = `virtual_deposit` 💎; §5 SEAM-1). On the happy path, the first `start_threshold` members each
credit the house `+fee` (`deposit_recovery`), so the house **net** after recoveries is
`Σ recovery − V/10`. cm.6.md S-DEPOSIT-RECOVERY states this nets to ≈ 0 (the zero-loss): the seed is
*calibrated* so the deposit-recovery band recovers it (`start_threshold × fee ≈ V/10` by the operator's
configuration — NO-INVENT: this is a *configuration* relationship, the design does not assert exact
equality, only that the seed debit and the recovery credits are the **same accounted keys**, so they
cancel to whatever residual the configuration leaves — and that residual is now a *visible house
balance* rather than an implicit conservation gap).

**The void (S-VOID-RECLAIM).** If the game voids before filling, the house holds `−V/10` (seed) +
`Σ recovery/revenue` (from however many bought in) and then books `+V/10` (`deposit_reclaim`, the
seed-cancelling credit, §5 SEAM-2 — *not* `Σfees + V/10`, which would double-book). Net house =
`Σ kept fees` (the platform's void take); no player refunded (cm.5 D-7); the books balance — every key
the players spent is either a house credit or a pool portion, and the seed debit is cancelled by its
reclaim. ∎

**What "balances to zero" means here (the honest framing the overlay forces, F3 Steward).** Because
the player debit is a **bare `keys` column delta** (not a `TXN`, L-3/F3-Arm1) and the pool is a
**`games` column** (L-4), the invariant is **NOT** `SELECT SUM(delta) FROM transactions == 0`. It is
the three-term keys identity above, proven over **three observable quantities**: the players' `keys`
deltas, the house's `TXN` credits, and the `games.prize_pool` 💎 deltas (÷10 → keys). The proof is a
**property test** (Acceptance "proven by a property test against a cm.5-only computation"): generate
arbitrary `{fee, start_threshold, first_movers, rev%, N}`, run the buy-in sequence, assert
`Σ player_key_debits == house_key_balance + (Σ pool_💎 / 10)` at the keys unit. Under F2-Arm2 this
*would* collapse to a single `SUM==0`, but at the cost F2/F3 Stewards priced (re-denominating the cm.5
debit). The Steward's invariant is provably correct and matches the spec's stated unit — it is simply
proven over three columns rather than one, which is the truthful shape of the as-built money surface.

## §7 — The reconciliation read + the explicit==implicit equivalence (cm.6.md S-RECONCILE)

**The read.** A `Wallet.house_balance/0..1` (the §4 seam) over `transactions`:
- `house_balance()` → `SUM(delta) … WHERE player = house_account() GROUP BY currency` (the total
  platform balance per currency).
- `house_balance(game)` → the same, `AND ref = game` (the per-game figure), plus a **breakdown by
  reason** (`GROUP BY reason`): `deposit_seed` / `deposit_recovery` / `revenue` / `deposit_reclaim` —
  exactly the five-way split cm.6.md Scope §5 / S-RECONCILE asks for, so revenue is **queried**, not
  re-derived. This is a pure read (no new write, no schema); it reuses the same `from t in Transaction`
  shape `buy_in_count` already uses (`wallet.ex:330-334`).

**The equivalence (S-RECONCILE — the headline acceptance).** cm.6 must make the *same* number cm.5
leaves implicit, never a different one. The implicit (conservation) figure cm.5 leaves is, per game:

> `implicit_platform_keys = Σ (player keys debited) − Σ (pool keys-equivalent) = Σ fee_i − (Σ pool_💎_i / 10)`

The explicit figure cm.6 books is `house_balance(game)` in keys (the sum of the §5 credits + the seed
debit + any reclaim). **Claim:** `house_balance(game) == implicit_platform_keys` (modulo the seed/seed-
cancel pair, which nets to the same residual on the happy path and to `Σ kept fees` on void — §6).

**Proof of equivalence.** From §6's per-entry algebra, `house_key_credit_i = fee_i − pool_keys_i` for
every buy-in (across all three bands, since `pool_keys_i = 0` outside the first-mover band). Summing:
`Σ house_credits = Σ fee_i − Σ pool_keys_i = Σ fee_i − (Σ pool_💎_i / 10) = implicit_platform_keys`. ∎
The seed debit and its happy-path recoveries (or void reclaim) net out as §6 shows, so the *book*
matches the *conservation* number term-for-term. The Acceptance test is exactly this: a property test
computing `implicit_platform_keys` from a **cm.5-only computation** (the player debits and pool 💎 the
cm.5 build already produces, untouched under the overlay) and asserting it equals `house_balance(game)`
— "the same number, now a row" (S-RECONCILE). Because the overlay changes **no cm.5 figure** (F3-Arm1),
the cm.5-only computation is *literally the shipped cm.5 behavior*, so the equivalence is a check that
cm.6's *additions* sum to the gap cm.5 left — the cleanest possible form of the acceptance.

**Why the reconciliation read is robust under the recommended arms.** It is a single-table `SUM` over
an append-only ledger (L-1) keyed by a well-known house id (§4) and `ref=game` — no join to the pool
column, no cross-store read. The pool 💎 it compares against is read once from `games.prize_pool`
(L-4) for the implicit-figure side of the *test*, but the *production* reconciliation read needs only
the house's own `TXN`s (the platform balance is self-contained in the ledger). The forward-only
discontinuity (cm.6.md Scope Out: no backfill) is surfaced to finance as "the house balance begins at
cm.6" — pre-cm.6 revenue stays implicit-only and is *not* in this read; the read is honest about its
epoch.

## §8 — The migration up/down shape (additive; shipped migrations byte-frozen)

**The Steward's headline finding: under the recommended arms, cm.6 needs NO migration.** The three
shipped migrations (`20260618000000_create_codemojex.exs`, `20260625145121_add_player_tg_user_id.exs`,
`20260626120000_golden_rooms.exs` — verified on disk) stay **byte-frozen** (L-9, cm.6.md Acceptance).
Because the house is an **id, not a row**, and its balance is `SUM(transactions.delta)` (§4):
- **No new table** — house credits are `transactions` rows; `transactions` already exists with the
  exact shape needed (`{id, player, currency, delta (plain signed int, no CHECK), reason (free-text),
  ref (free-text, nullable), inserted_at}` — verified `transaction.ex:6-13`).
- **No new column** — the four new reasons (`deposit_seed` / `deposit_recovery` / `revenue` /
  `deposit_reclaim`) are **data**, not schema (L-1); `reason` has no CHECK to extend.
- **No CHECK change** — `players_non_negative` is never touched because the house has no `players` row
  (C-1 dissolved, §4); `transactions` has no CHECK (`transaction.ex` — only a `unique_constraint` on
  the buy-in partial index, untouched).

So the migration up/down is **empty**, which is the strongest possible reading of "additive; shipped
migrations byte-frozen": the lightest change adds **zero** at-rest schema surface. cm.6.md Acceptance's
"migration up/down clean (+ the destructive gate if a column/table is dropped)" is satisfied
*vacuously* — nothing is added, nothing is dropped, so there is no destructive op to gate.

**The one thing that might want a migration (and the Steward's recommendation against it).** If the
Operator/Venus-Postgres wants the reserved house id to **exist as a referenceable anchor** (e.g. a FK
target, or a `players` row for admin-UI visibility), that would be a one-row additive insert — but the
Steward argues **against** it: a house `players` row *re-introduces C-1* (the seed debit would violate
`players_non_negative` if any code path syncs a balance column), and the house's balance is
authoritative as the ledger sum regardless. The reserved id is best a **boot-asserted application
constant** (`@house_id` on `Wallet`, validated against `EchoData.BrandedId` at boot, mirroring the
branded-id boot vectors used elsewhere in the stack) — *not* a migrated row. If admin visibility is
needed, a **read view** (a query that surfaces the house balance) serves it without a row.

**If F1-Arm2 is chosen instead (the contrast).** Then §8 is non-empty: a new additive migration
creating `revenue_ledger` (or `accounts` + house rows), with a clean `down` dropping it — and *that*
`down` **is** a destructive op (a table drop) requiring cm.6.md's destructive gate + a fresh reinit on
`codemojex_test` (surface the DB target first, cm.6.md Acceptance). This is the migration cost the F1
ruling buys: **Arm1 = no migration; Arm2 = one additive table + a gated destructive `down`.** The
Steward records this as a concrete decision input for the Operator: the table is not free even at the
migration layer.

**Test-DB note (carries regardless of arm).** cm.6.md Acceptance requires a fresh reinit on
`codemojex_test` and "surface the DB target first." Under Arm1 the reinit is a no-op for schema (no DDL
changed) but the **reserved house id** must be present/asserted in the test setup so the house credits
have a valid counterparty id — Mars seeds/asserts `@house_id` in the test harness (a data fixture, not
a migration).

## §9 — cm.5-stays-green strategy + the ≥100-determinism + boundary posture

**cm.5-stays-green (the strategy the overlay makes nearly free).** cm.6.md Acceptance: "the cm.5 suite
stays green untouched … the pool/player figures unchanged." Under F3-Arm1 (additive overlay):
- **No cm.5 line moves.** The `delta:0` buy-in marker (`insert_buy_in`, `wallet.ex:347-366`), the bare
  `keys -= fee` debit (`wallet.ex:226`), `inc_pool!` (`wallet.ex:371`), `entry_fee_split`
  (`economy.ex:45-52`), and `distribute_pool` (`wallet.ex:252-268`) are **read-only references** for
  cm.6. The only edit inside `buy_in/2` is **adding** one `txn!(house, …)` on the `:wrote` branch
  (§5) — it writes a *new* row to a *different* player (the house), touching no existing balance or
  pool figure.
- **The cm.5 player/pool assertions hold by construction.** A cm.5 test asserting `player.keys` fell
  by `fee` or `prize_pool` rose by `pool_💎` sees the **identical** values — the house credit is a
  disjoint write. So the cm.5 suite is green *because no cm.5 observable changed*, not because the
  tests were updated.
- **The residual risk** is purely transactional: the added `txn!` must not abort the buy-in's
  `Repo.transaction` (e.g. a bad house id → an insert error → rollback of the whole buy-in). Mitigation:
  the house id is a boot-asserted constant (§8), and `txn!` is the *same* primitive the guess path
  uses successfully — so the credit insert is as reliable as the shipped guess credit. Apollo's mutation
  spot-check should kill a mutant that drops the house credit (proving it is actually written) **and** a
  mutant that lets a house-credit failure silently swallow (proving it is in the atomic envelope).

**The ≥100-determinism loop (required — money + a hot serialized path).** cm.6.md Risk: HIGH → the
≥100 determinism loop (reinit-per-iter). The hazard the loop targets is the **same-millisecond branded-
id mint** under contention (echo CLAUDE.md §3): cm.6 mints a **new `TXN` id per house credit**
(`EchoData.BrandedId.generate!("TXN")`, `wallet.ex:381`) **in addition to** the buy-in marker id — so a
busy game now mints *two* `TXN` ids inside one `buy_in/2` call, doubling the same-ms mint pressure on
the hottest path. The loop (`for i in $(seq 1 150); do TMPDIR=/tmp mix test || break; done`, reinit per
iter) is the right ratify for this; a multi-seed sweep would **not** reproduce the within-run same-ms
contention. The determinism posture statement must explicitly note the **two-mint-per-buy-in** change
as the new contention surface. (The buy-in's games-row `FOR UPDATE` lock serializes *ordinal*
assignment, but id minting is not serialized by that lock — the ids are minted before/around the DB
write — so the same-ms hazard is real and the loop, not the lock, is its guard.)

**SEAM-1/SEAM-2 determinism posture (the honest caveat).** The seed debit (SEAM-1, Valkey-formation
path) and the void reclaim (SEAM-2, Valkey-NX-close path) are **not** inside the games-row-locked buy-in
transaction — they fire from `Rooms` under Valkey locks. Their determinism rests on cm.5's existing
guards: SEAM-1 on the single `formation` code path (the game forms once), SEAM-2 on the `cm:<game>:closed
NX` close lock (the exactly-once void guard, `rooms.ex:463`). The Steward flags that these two `TXN`s
must be **idempotent under their respective Valkey locks** — a `deposit_seed` must book once per game
formation, a `deposit_reclaim` once per void — and Mars/Apollo must prove the close-lock prevents a
double-reclaim (the NX lock already does for the void transition; the new `txn!` must ride *inside* that
guard, not before it). This is the one place the determinism story is *not* the buy-in lock and must be
argued separately.

**Boundary posture.** The boundary is **`echo/apps/codemojex/**` + the rung docs**, exactly cm.6.md
Acceptance. The edits are confined to: `lib/codemojex/wallet.ex` (the house credit + `house_balance`
read + the `txn!` exposure), `lib/codemojex/rooms.ex` (SEAM-1 seed booking + SEAM-2 reclaim booking via
the `Wallet` seam), the test tree (the new revenue-ledger stories + the property tests of §6/§7 + the
house-id fixture), and `docs/codemojex/specs/` (this design + the triad). **No sibling umbrella app**
(no `echo_mq`/`echo_store`/`echo_data`/`echo_wire` edit — the house credit is pure Postgres via the
existing `Repo`); **`mix.lock` untouched** (no dep moved); the three migrations **byte-frozen**. The
gate ladder is the codemojex ladder (`TMPDIR=/tmp mix test --include valkey` from the app dir, Valkey
6390 up, warnings-as-errors, the ≥100 loop) — Postgres-floor for the ledger reads, Valkey for the
SEAM-1/SEAM-2 paths. **No conformance count / no Lua / no wire invariant** applies — cm.6 is a
codemojex-app money rung, not an echo_mq wire rung (the v2 master invariant is out of scope here).

## §10 — Build-precision flags + coordination note (the contracts Mars wires both sides of)

**Build-precision flags (NO-INVENT — Mars confirms each against the as-built before wiring):**

- **PF-1 · Use `txn!`, never `credit`, for the house.** The house credit is `txn!(house_id, "keys",
  +amount, reason, ref)` (`wallet.ex:380` — signed `TXN` row only). `credit` (`wallet.ex:305-318`)
  `lock`s + `update!`s a `players` row → would require a house row + re-break C-1. **This is the single
  most important wiring fact.**
- **PF-2 · The house id is a reserved constant, boot-asserted, NOT a `players` row.** Confirm the exact
  mint/derivation against `EchoData.BrandedId` (a fixed `PLR…` literal vs `BrandedId.derive`); the
  *shape* (one reserved id behind `Wallet.house_account/0`) is fixed by this design.
- **PF-3 · The first-mover house cut is `fee − pool_keys`, where `pool_keys = div(fee×(100−rev%),100)`**
  (`economy.ex:47`) — exact integer subtraction, NOT a re-floor and NOT recomputed from 💎 (recomputing
  `entry_fee_split/10` risks a ÷ rounding mismatch; subtract the keys directly). Expose `pool_keys`
  from `Economy` (a tiny pure function `entry_fee_split_keys/5` returning the keys portion) so both the
  pool 💎 (`×10`) and the house keys cut derive from the **one** floored value — do not duplicate the
  floor.
- **PF-4 · SEAM-2 reclaim books the SEED-CANCELLING amount, not `Σfees + seed`.** The kept fees are
  already booked as `deposit_recovery`/`revenue` at each buy-in; the void's `deposit_reclaim` credit is
  `+seed` (cancelling the seed debit), leaving house net = `Σ kept fees`. Booking `Σfees + seed`
  **double-counts the fees** — a money-critical bug. (§5 SEAM-2, §6 void.)
- **PF-5 · SEAM-1 seed is cross-store (Valkey pool field + Postgres house `TXN`), NOT one
  `Repo.transaction`.** Accept the cm.5-style cross-store coupling (option 1a) or defer-to-close (1b);
  state the determinism posture. Do **not** claim ACID atomicity across the two stores.
- **PF-6 · Two `TXN` mints per buy-in now** (the marker + the house credit) — the new same-ms contention
  surface; the ≥100 loop is mandatory and its posture statement must name this.
- **PF-7 · The reconciliation read is `SUM(delta) … WHERE player=house GROUP BY currency[, reason]`** —
  reuse the `from t in Transaction` shape of `buy_in_count` (`wallet.ex:330`); a pure read, no schema.
- **PF-8 · No migration under the recommended arms** (§8) — if the gate ladder expects a migration
  step, it is a **no-op** for schema; only the test-DB house-id fixture is new.

**Coordination note — the contracts Mars wires both sides of (the dual-architect convergence points).**
This design and the bank-architect design (`cm.6.design.b.md`) diverge chiefly on **F1** (sentinel `PLR`
vs a `revenue_ledger`/accounts table) and consequently **F2/F3**. Whichever the Operator rules, Mars
wires **the same five economic movements** (§5) and **the same balance invariant** (§6) — the forks
change the *representation*, not the *events*. The contracts that must hold **regardless of the F1
ruling**, so the two designs converge cleanly:

1. **The five movements + their keys amounts** (§5 table) are arm-invariant — `deposit_seed −V/10`,
   `deposit_recovery +fee`, first-mover `+ (fee − pool_keys)`, full `+fee`, `deposit_reclaim +seed`.
   Only *where the credit lands* (a house `PLR` vs a `revenue_ledger` row) differs.
2. **The keys-unit balance invariant** (§6) is the acceptance headline under either F1; if the Operator
   also rules F2-Arm2 (a normalized unit), the invariant restates at that unit but the *events* are the
   same.
3. **The seam `Wallet.house_account/0` + `house_balance/0..1`** (§4) is the convergence interface: under
   Arm1 it reads the sentinel's `TXN` sum; under Arm2 it reads the `revenue_ledger` — **the call sites
   (§5) and the reconciliation read (§7) bind to the seam, not the representation**, so a late F1 flip
   re-points two functions, not the five credit sites. *This seam is the single most valuable thing both
   designs should share* — it makes the Operator's F1 ruling cheap to honor either way.
4. **SEAM-1 / SEAM-2** (the cross-store seed + the Valkey-close reclaim) are arm-invariant architectural
   facts — they are properties of *where cm.5 put the seed and the void*, not of the house
   representation. Both designs must surface them; Mars wires them once.

**Grounding the Steward could not fully close (honest flags):**
- The **seed-vs-recovery calibration** (does `start_threshold × fee` exactly recover `V/10`, or leave a
  designed residual?) is a **configuration** relationship not asserted in the as-built code the prompt
  cited — the design states the seed/recovery cancel *as the same accounted keys*, not exact numeric
  equality; the Operator/Venus-Postgres should confirm the intended residual.
- The **exact reserved-id mechanism** (PF-2) is confirmed in *shape* but the literal mint is a build
  detail Mars verifies against `EchoData.BrandedId`.
- **SEAM-2's "kept fees" definition** under partial fills (a game that takes a few members then voids)
  — the design rules it as `Σ booked recovery/revenue` (cancel only the seed), but the precise void
  economics for a *partially* filled golden room should be Operator-confirmed (cm.5 D-7 says non-
  refundable; the platform keeps collected fees — the design follows that, but the seed/partial-fill
  interaction is the subtlest money point and is flagged for the ruling).
