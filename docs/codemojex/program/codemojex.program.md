# Codemojex — the program operating manual

> **The HOW-WE-SHIP-IT.** The *what* lives in the canon: [`../codemojex.design.md`](../codemojex.design.md)
> (the binding design — the engine, the systems, the six-table model, the state machine, the open
> questions), [`../codemojex.roadmap.md`](../codemojex.roadmap.md) (the delivery plan, the `cm.N` rung
> ladder, the forward feature catalog), [`../codemojex.progress.md`](../codemojex.progress.md) (the
> as-built dashboard). **This file is the program's OPERATING CONTRACT** — the AAW team, the pipeline, the
> topology router, the boundary, the gate ladder, the durable footguns, the live frontier — and the home
> of the per-agent calibrations ([`./codemojex.venus.md`](./codemojex.venus.md),
> [`./codemojex.mars.md`](./codemojex.mars.md), [`./codemojex.apollo.md`](./codemojex.apollo.md)). The ship
> loop that executes it is the **`codemojex-ship`** skill
> ([`../../../.claude/skills/codemojex-ship/SKILL.md`](../../../.claude/skills/codemojex-ship/SKILL.md)) —
> `/x-mode` with the codemojex context pre-loaded; this manual is the depth behind that skill's facts block.

## The program in one paragraph

`echo/apps/codemojex` is **THE** Codemojex game — the Telegram emoji-guessing Mastermind, for money, and
the **worked consumer** of the BCS data stack. It sits **above** `echo_wire` (the owned wire), `echo_data`
(the branded ids + stores), `echo_mq` (the bus), and `echo_store` (the near-cache + durable floor), and it
**consumes their public surface — it never edits it** (a change reaching a sibling umbrella app is out of
bounds by construction). The engine is a **generic Mastermind**: the modes are policy on one `games` table
with a `type` discriminator — `classic` (live feedback, live settlement) and `golden` (the blind/sealed
mode: feedback `none`, sealed top-K settlement, a commit-reveal provably-fair secret). The founding core
(**cm.1**) and the blind Golden flow (**cm.3**) **shipped on one six-table schema** through the
`codemojex-game-rename` rung — which re-based the three entity brands to the forward canon (`RND`→`GAM`,
`RMM`→`ROM`, `USR`→`PLR`), collapsed the schema into one clean initial migration, removed the bonus-tier
economy for linear-only scoring, and landed the commit-reveal blind flow. The forward work is the
**`cm.4+` deferred systems** (the `BNK` bank · `RMP` membership · `SES` sessions / verified `initData` ·
commerce · growth · analytics — the roadmap's [feature catalog](../codemojex.roadmap.md#the-feature-catalog)).
The **planned second consumer** is `echo_bot` (the Telegram engine the notification lane already feeds).

## The AAW team + the pipeline (Flat-L2)

One rung per run through the aaw lead-team, **Director-orchestrated**, to one ratifying **LAW-4** commit.
The pipeline is `/x-mode` bound to codemojex (the skill `codemojex-ship`). The team is **GENERIC** — there
are no `codemojex-*` role skills; each peer is a real `general-purpose` `Agent` spawn that adopts its
`.claude/agents/<role>.md` charter and self-registers (`mcp__aaw__agent_register`, LAW-1, no narrated
spawns). The "codemojex facts" the peers would otherwise re-derive are pre-loaded in the
[`codemojex-ship`](../../../.claude/skills/codemojex-ship/SKILL.md) skill. The roster + the standing
calibration:

- **Venus — the architect / spec-steward** ([`./codemojex.venus.md`](./codemojex.venus.md)). Reconciles
  the rung's triad lag-1 against the as-built `echo/apps/codemojex` tree (or authors it), authors the
  build brief Mars builds from, and **frames seam / schema / game-mode forks as four-part Arms**
  (Rationale / 5W / Steelman / Steward — [`aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md))
  for the Director to rule. **On a data-model rung, Venus runs in PARALLEL with Venus-Postgres** (the
  dual-architect fan-out, below). Surfaces, never rules. Edits ONLY the spec triad + the canon docs;
  never code; no git.
- **Venus-Postgres (`VenusPG`) — the relational architect** (a data-model rung only). Owns the
  **relational redesign** — every column type / null / default / CHECK, the indexes + FKs, the type/policy
  discriminator, the transactional wallet, the idempotent settlement, the ONE clean initial migration, and
  the reinitialization plan. Authors from the **identical locked-constraints brief** as Venus, a distinct
  lens, **no sibling read until both land** (the §12 discipline). Edits ONLY its design doc + the
  relational half of the triad.
- **Director — the orchestrator + the verifier.** Triages the **topology tier** at bootstrap (a
  `tool_x_decision`); rules each Arm *with the Operator* via the **mandatory `AskUserQuestion`** (a fork is
  never decided silently); then **independently verifies code + invariants** (a real gate re-run on Valkey
  6390 + Postgres + the residual-brand grep + the migration up/down proof + an adversarial probe + a
  net-zero mutation spot-check); runs the REMEDIATE loop; **consolidates the rung's findings for Apollo**;
  lands the LAW-4 pathspec commit + the Stage-6 fold. Calls no Edit on production code except a net-zero
  mutation spot-check (LAW-1a).
- **Mars — the implementor + THE PRIMARY CODE-QUALITY GATE** ([`./codemojex.mars.md`](./codemojex.mars.md)).
  Builds the increment AND adversarially self-verifies (the full per-app gate ladder + the residual-brand
  grep + the migration up/down + the mutation kill-rate) **BEFORE reporting**, and ships the rung's
  **story-generation test** so `mix codemojex.stories` keeps `docs/codemojex/stories/` current. The
  schema, the migration, and `Store`/`Wallet` move in **one atomic change**. Edits code + tests; never the
  spec; no git.
- **Apollo — the high-risk evaluator AND the Mentor** ([`./codemojex.apollo.md`](./codemojex.apollo.md)).
  **MANDATORY on a HIGH-risk rung** (a Squad — a schema redesign · a destructive at-rest op · a brand
  re-base · a new game-mode/process/lease surface · a wire cutover): the dedicated evaluator with the
  §11.2 charter (the prompted-checks table + ≥1 un-prompted finding + ≥1 attack-that-held + a mutation
  kill-rate), who resolves every ambiguity with the Operator via `AskUserQuestion` and renders
  **BUILD-GRADE / BLOCKED** before the Director ships. On a NORMAL rung Apollo is **out of the pipeline** —
  it mentors after the ship (PROPOSE-ONLY, Director-ratified under an Operator grant). (This is the GENERIC
  x-mode Apollo, not the emq "mentor-only" recalibration — codemojex runs the generic charter.)

**The pipeline:** Venus (reconcile/author + Arms) *— on a data-model rung ∥ Venus-Postgres* → **Director
(rules the Arms via `AskUserQuestion`)** → **Mars-1 (build + self-verify + stories)** → **Director (verify
code + invariants + REMEDIATE)** → **Mars-2 (remediate + harden)** → **Apollo (HIGH-risk only: §11.2
evaluation → BUILD-GRADE)** → **Director (ship + consolidate findings + Stage-6 fold)**. The **verification
floor** = Mars's adversarial self-verification **+** the Director's independent verify; Apollo is the
high-risk escalation, not the default gate.

## The topology router — right-size the formation (rigor constant, ceremony scales)

**Rigor is constant; only ceremony scales.** The Director triages ONE of four Flat-L2 formations at
bootstrap from the rung's **risk tier × build-state**, records the chosen tier as the **formation
`tool_x_decision`**, and `mcp__aaw__status(scope)` must then show **exactly that tier's registered peers**
— no more (over-ceremony — the ewr.4.1 footgun: a ~200-line change ran the full team and shipped zero), no
fewer (under-staffing a HIGH rung skips the mandatory Apollo).

| Tier | Peers | Engage when | Roster |
|---|---|---|---|
| **Solo** | 1 | trivial / mechanical — a docs reconcile, a one-line fix, a re-pin, a version digit | Director + 1 builder (Mars) |
| **Duo** | 2 | a single-concern increment — a docs-only reconcile, an already-green rung needing only the verify, a pure spec author | Director + one peer (Venus *or* Mars) |
| **Trio** | 3 | the standard **NORMAL** additive build, the triad clean/existing | Venus + Mars *(two-pass)*; the Director's solo verify is the gate; Apollo folds async |
| **Squad** | 4+ | **HIGH-risk** — a schema redesign · a destructive at-rest op (an `ecto.drop` / a data migration) · a brand re-base · a new game-mode/process/lease surface · an external-wire cutover | Venus **(+ VenusPG on a data-model rung)** + Mars(-1/-2) + **Apollo** + the deepened verify (the ≥100 loop, the migration up/down proof, the full mutation battery) |

A tier can be **re-graded mid-build** — a surfaced destructive op bumps NORMAL→HIGH, Trio→Squad; ceremony
scales, **the gate ladder never**. The dual-architect *design-ahead* is the **Squad front** on a data-model
rung; once it has delivered (the ruled design + triad), the live build runs the **Squad back-half** (Mars +
Apollo). **Collapse by build-state:** an already-green increment re-spawns **no builder** — only the
remaining verify / harden / evaluate / ship legs (BDD-phase Mars enters at the blue refactor/harden pass).
**A generated bundle is WRITE-ONLY** — verify the GENERATOR (`mix codemojex.stories` is idempotent;
`grep -c` for the count; the running-server curl), never re-read the artifact.

**Cross-/compact reconnect:** the aaw tools defer after a compaction — re-`ToolSearch` the spine and re-run
`mcp__aaw__status` as the first act, BEFORE any ledger write or spawn (an `agents:null` with a populated
ledger is the FAKE-N *inverse*). The reconnect's FIRST act is the FULL bootstrap: re-`ToolSearch` →
`mcp__aaw__status` → `aaw_init` (idempotent re-open) + `agent_register(Director)` + `TeamCreate(scope)` +
per-peer `aaw_spawn`; **spawned MUST equal registered**.

## The boundary

`echo/apps/codemojex` — the code (`lib/codemojex/**` + `lib/codemojex_web/**` + `priv/repo/migrations/**` +
`test/**` + `mix/tasks/**`) + the rung's docs under `docs/codemojex/`. **Out of bounds by construction:**
every OTHER umbrella app (`echo_mq` · `echo_store` · `echo_data` · `echo_wire` · `echo_bot` — codemojex is
their CONSUMER; it depends on their public surface, never edits it), `echo/mix.lock` (excluded unless a real
dep moved), and the umbrella-level `config/` (read it; a codemojex rung does not own it). **The git posture:**
the Operator pre-stages + works out-of-band, so the tree is routinely entangled — the rung commit is the
rung's **measured surface ONLY**, a **pathspec** commit (`git commit -- <paths>`, **never `git add -A`,
never a bare commit**), and an entangled concern splits into separate scoped commits.

## The gate ladder (the operating procedure)

Run **from `echo/apps/codemojex`** — the gate is the codemojex app gate, **NEVER umbrella-wide**:

- `asdf current` / `.tool-versions` — **re-probe from the app dir, never hardcode** (the umbrella pins
  Elixir 1.18.4 / Erlang 28.5.0.1) · `valkey-cli -p 6390 ping` → `PONG` (the engine is **Valkey on 6390**)
  · `pg_isready` (Postgres up — the system of record).
- `TMPDIR=/tmp mix compile --warnings-as-errors` — clean. **`TMPDIR=/tmp` is load-bearing** (the harness
  tmp overlay hits ENOSPC and surfaces as spurious mid-suite I/O failures unrelated to any logic error).
- `TMPDIR=/tmp mix test` runs the **pure** stories (scoring / economy / emoji-codes); the **integration**
  stories carry `@moduletag :valkey` and need `TMPDIR=/tmp mix test --include valkey`, which **boots the
  full supervision tree** — so it needs **both Valkey 6390 AND Postgres** up.
- **On a schema-landing rung: the fresh-schema reinitialization** — `MIX_ENV=test mix ecto.drop && ecto.create
  && ecto.migrate` (the dev DB too when ruled), proving the migration set comes up clean from zero. Scope
  the DROP to the **Ecto-configured** dev/test DB ONLY (read the name from `config/dev.exs` /
  `config/test.exs` — it is `codemojex_dev` / `codemojex_test`, NOT assumable, and any `*_snapshot` DB is
  untouched), and surface the exact target before running it. **Plus the migration up/down proof.**
- **On a brand-rename rung: the residual-grep to ZERO** of the retired brand across `lib` + `test` (and the
  docs, with the forward-namespace carve-out) — an **external shell gate** (`/usr/bin/grep -rnoE '\bRND\b'`
  → 0), not an in-suite assertion. Carve the grep to catch the *brand* + the *entity word* but **spare
  `Kernel.round/1` / `Math.round` / the English "round-trip"** (a blind `s/round/game/g` corrupts the
  scoring arithmetic in `scoring.ex` / `economy.ex`).
- **The ≥100 determinism loop** — ONLY for an id-mint / process / lease / schema-mint suite (the same-ms
  branded-id mint hazard — codemojex mints on every room/game/guess/txn). A pure-read / docs-only rung runs
  a multi-seed sweep instead and states the determinism posture honestly.
- **The privacy line holds:** the game's `secret` is server-side only and never crosses the wire (the
  `privacy` stories pin this; a golden game also withholds the commitment's preimage until reveal).
- `mix codemojex.stories` regenerates `docs/codemojex/stories/<feature>.stories.md` after any scenario edit
  — idempotent, byte-for-byte from one command, never hand-edited.

## The durable footguns (the lessons that cost us)

1. **The brand IS the type — a re-base is an identity change at the mint, not a lookup edit.** `RND`→`GAM`
   re-bases the minted brand (`generate!("GAM")`), the EchoStore cache `kind:`, the persisted-id prefix,
   AND the external wire (the `/games` routes + the `game:<id>` channel/PubSub topic) — every place the
   identity travels. The acceptance is the residual-grep to 0, not a green suite (a green suite passes with
   the old brand still minted somewhere).
2. **A column declared but never read is a silent no-op** (the config-key-never-consumed class). A schema
   rung touches the schema module, the migration, AND `Store`/`Wallet` in **one atomic change** — a new
   column is wired end to end or it is dead weight the gate cannot catch.
3. **Re-probe ground truth on disk — the plan map drifts.** The rename rung's reconcile caught **six tables,
   not seven** (`notifications` is a Valkey bus lane, not a Postgres table) and the DB names
   **`codemojex_dev`/`codemojex_test`, not `codemoji_game`** — both were wrong in the pre-baked plan. A
   Mars building to the plan would have invented a table and dropped the wrong DB.
4. **`bonus_diamonds` is a wallet bucket, not a scoring tier.** "Remove the bonus tiers" targets the
   first-mover **scoring** economy (the `ptier`/`bonus`/`tierfirst` keyspace, the `guesses.tier`/`percentage`
   columns) — **not** `players.bonus_diamonds` (a promotional wallet balance). The word "bonus" is
   overloaded; over-removal corrupts the wallet.
5. **Measure the asset, don't trust the default.** The EMS `cell_size` code default (`144`) gives a
   non-integer grid on the real sprite sheets; the measured-true divisor is `72` (a `10×15` and a `10×21`
   sheet). A seed value is read off the asset on disk, surfaced as a fork, not assumed.
6. **A timer-bound test is clock-dependent — make the close explicit.** A golden game with a short
   `duration_ms` can yield `{:error, :expired}` under an unlucky isolation seed (a flake the 40/0 suite + a
   150× loop hid). Use a long timer + an explicit `close_now/1` that dispatches on `settlement`, so the
   sealed flow is deterministic, not clock-raced.
7. **The mutation-revert footgun.** Revert a mutation spot-check by an **inverse Edit** (or a `cp` backup),
   **never `git checkout`** — on a modified-uncommitted file `git checkout` restores HEAD and DESTROYS the
   in-flight work.
8. **The entangled-tree pathspec law.** The Operator stages/commits out-of-band (a pre-staged sibling file
   appears mid-close). ALWAYS a **guarded pathspec commit** — re-verify `git diff --cached --name-only` is
   purely the rung boundary immediately before `git commit`, ABORT on any foreign path; **never `git add
   -A`, never a bare commit**.
9. **Records-freeze.** Never rewrite a frozen `<scope>.progress.md` ledger's historical content; the
   run-ledgers + the design-phase deliverables live archived in `specs/progress/`.

## The spec home + the file convention

- `specs/` holds the **chapter triads** `cm.N.{md,stories.md,llms.md}` (the source of truth for each rung —
  the body is authoritative; the stories + llms brief derive from it).
- The **run-ledgers** (`<scope>.progress.md` + `.registry.json`) **and** the rung's design-phase
  deliverables (e.g. `codemojex-game-rename.game-model.design.md` + `.brief.md`) live archived in
  **`specs/progress/`** — out of the top level, frozen, never history-rewritten.
- The **forward feature catalog** (the systems still to build, by category) is folded into the roadmap
  ([`../codemojex.roadmap.md`](../codemojex.roadmap.md#the-feature-catalog), Part-C-equivalent).
- The **generated story catalog** is `docs/codemojex/stories/` — produced by `mix codemojex.stories` from
  `echo/apps/codemojex/test/stories/*_story_test.exs`; **generated, NEVER hand-edited** (it cannot drift
  from code), reproducing from one documented command byte-for-byte.
- The **per-agent calibrations** are `program/codemojex.{venus,mars,apollo}.md` (this folder).
- The top level holds **only** `codemojex.{design,roadmap,progress}.md` + this `program/` + the subdirs
  (`specs/` · `notifications/` · `stories/` · `emoji-sets/`).

## The live frontier (re-true at each rung close)

- **The engine is whole.** `cm.1` (the founding core — the six-table schema, the three brand re-bases, the
  type/policy discriminator, linear scoring, classic live mode) and `cm.3` (the blind/sealed Golden flow —
  commit-reveal, the per-game reduced keyboard, sealed top-K) **both SHIPPED** via the
  `codemojex-game-rename` rung (HIGH-risk Squad; Apollo BUILD-GRADE, 6/6 mutation kill; the gate green —
  `mix test --include valkey` 41/0, residual greps 0, the migration up/down, 150/150 determinism).
- **NEXT on the ladder — the `cm.4+` deferred systems** (the roadmap's
  [feature catalog](../codemojex.roadmap.md#the-feature-catalog)): the `BNK` bank + rake · the `RMP`
  membership + the anonymized leaderboard · `SES` sessions / **verified Telegram `initData`** (the one
  pre-launch gap named in the design) · commerce (`PKG`/`ORD`/`OTX`/`WHK`) · growth (`SHR`) · analytics
  (`AEV`) · the LiveAdmin console. Each lands as its own `cm.N` rung — a new triad under `specs/` + a
  per-rung ledger under `specs/progress/`.
- **The standalone `/codemojex` course** (canon `specs/course/`, nine chapters C0–C8 — the B7 arc
  reconciled + extended) teaches the running game; the landing is built, the chapter stubs are shipped,
  and per-chapter authoring follows. `/bcs/codemojex` remains the BCS course's B7 and doors into it
  (the Operator authors the rendered HTML — not a code-rung target).
