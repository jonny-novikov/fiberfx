---
name: codemojex-ship
description: >-
  Use this skill to ship ONE spec-driven rung of the Codemojex game engine — the Valkey + Postgres
  Telegram emoji game at echo/apps/codemojex, an app in the BCS umbrella above echo_mq / echo_store /
  echo_data / echo_wire / echo_bot — any rung whose slug matches cm.* (cm.1 … cm.N) OR a named scope
  (e.g. codemojex-game-rename), end to end through the x-mode Flat-L2 lead-team, Director-supervised, to
  one ratifying LAW-4 commit. It is /x-mode with the codemojex context pre-loaded: it adds nothing to the
  laws — it binds them to the codemojex app boundary, the BCS branded-id contract (the brand IS the type),
  the Postgres-floor + Valkey 6390 + EchoStore gate ladder, and — on a data-model rung — a SECOND architect
  (Venus-Postgres) fanned out over the relational redesign. The team is GENERIC (the venus / mars / apollo
  charters, no codemojex-* role skills); the "codemojex facts" block below is the pre-loaded context.
  The INPUT is the rung's docs/codemojex/specs/<rung>.{md,stories.md,llms.md} triad (+ a <rung>.prompt.md
  runbook or a named build brief like docs/codemojex/codemojex-game-rename.brief.md; else Venus authors the
  brief inline); the canon is docs/codemojex/codemojex.game-model.design.md + codemojex.roadmap.md.
  Triggers: "ship cm.1", "codemojex-ship <rung>", "run/launch the cm.N pipeline", "as Director fan out the
  codemojex lead-team". Do NOT use for the echo_mq bus (/echo-mq-ship), the echo_graft engine (/graft-ship),
  the static-HTML courses (the *-course-writer skills), or generic documents.
argument-hint: <rung> (cm.1 … cm.N, or a named scope like codemojex-game-rename) · empty (the next unshipped rung per the roadmap)
---

# CODEMOJEX-SHIP — ship a codemojex game-engine rung via the supervised lead-team

Ship ONE spec-driven rung of the **Codemojex game engine** — the founding core (`cm.1`), a deferred system
(`cm.4+`), or a named cross-cutting scope (`codemojex-game-rename`) — end to end through the x-mode Flat-L2
lead-team, Director-supervised, to one ratifying **LAW-4 commit**. It is **`/x-mode` with the codemojex context
pre-loaded**: it adds nothing to the laws — it binds them to the codemojex app so the run does not re-derive them.

**It is a binding layer, not a re-implementation.** Defer to the sources of truth:

1. **`.claude/commands/x.md` + the `/x-mode` skill** — the LAWS (CLAUDE_LAWS 1/1a/2/3/4), the pipeline (Venus
   reconcile/author + Arms → Director rules the Arms via `AskUserQuestion` → Mars-1 build + self-verify → Director
   verify → Mars-2 harden → Director ship; Apollo the dedicated evaluator on a high-risk rung, between Stage 4 and
   5; the §12 Design-Phase dual-architect formation when the deliverable IS a system spec), the §5 spawn protocol,
   the §6 audit tools, the §10 commit rules. **Read the `/x-mode` skill first** — everything in it applies; the
   deltas below are the codemojex binding.
2. **The umbrella build guide** — `echo/CLAUDE.md` (the per-app gate discipline, `TMPDIR=/tmp mix`, Valkey 6390,
   `asdf current` re-probe). The dual-architect method is `docs/aaw/aaw.architect-approach.md`.
3. **the rung's spec** — `docs/codemojex/specs/<rung>.{md,stories.md,llms.md}` (authoritative body) + its
   `.prompt.md` runbook **if it exists**, else a named build brief (`codemojex-game-rename.brief.md`) **or** Venus
   authors the build brief inline in Stage 1 — + the canon `docs/codemojex/codemojex.game-model.design.md` (the
   data-model redesign) + the single roadmap `docs/codemojex/codemojex.roadmap.md` (the `cm.N` ladder).

## Arguments & scope

```
$ARGUMENTS
```

- **A RUNG / NAMED SCOPE** — `cm.1` … `cm.N`, or a named scope like `codemojex-game-rename` → ship it. Internally
  the aaw `scope` is the **dashed** slug (`cm-1`, `codemojex-game-rename` — NO dots; `tool_x_*` / `TeamCreate`
  require `^[a-z0-9][a-z0-9-]*$`, and a dot split-brains the registry across its three namespaces). **The scope
  slug matches the on-disk ledger filename** — a wrong slug mints a NEW empty ledger and strands the hand-written
  one; for a CONTINUING scope, reuse the exact existing slug (`codemojex-game-rename`).
- **Empty** → read the roadmap §"The engine build ladder" + `docs/codemojex/codemojex.progress.md`, and ship the
  next **unshipped** rung in program order; if that is ambiguous, ask in plain text (do not guess a large scope).

## What is different from a generic /x-mode run (the codemojex binding)

- **The team is GENERIC, not project-specialized.** There are no `codemojex-*` role skills. Spawn each peer
  `subagent_type: "general-purpose"` (full toolset incl. `mcp__aaw__*`) and adopt its `.claude/agents/<role>.md`
  charter (`venus` = reconcile-or-author the spec + the build brief, edits ONLY the triad; `mars` = build to the
  brief, edits code+tests not the spec; `apollo` = the high-risk evaluator/reconciler/mentor). The peers
  self-register via `mcp__aaw__agent_register` from their own context (LAW-1; no narrated spawns). The
  "## The codemojex facts" block below is the pre-loaded context they would otherwise re-derive.
- **The boundary is `echo/apps/codemojex`.** The code (`lib/codemojex/**` + `lib/codemojex_web/**` +
  `priv/repo/migrations/**` + `test/**` + `mix/tasks/**`) + the rung's docs under `docs/codemojex/`. **Out of
  bounds by construction:** every OTHER umbrella app (`echo_mq` / `echo_store` / `echo_data` / `echo_wire` /
  `echo_bot` — codemojex is their CONSUMER; it depends on their public surface, never edits it), `mix.lock`
  (excluded unless a real dep moved), and the umbrella-level `config/` (read it; a codemojex rung does not own it).
  A change reaching a sibling app is a diff no one can review — STOP and re-scope.
- **The BCS brand law binds every rung — the brand IS the type.** A codemojex id is a 14-byte branded snowflake:
  `{3-letter uppercase brand}{11-char Base62 snowflake}`. `EchoData.BrandedId.generate!/1` validates by **shape**,
  not a registry — so a brand re-base (`RND`→`GAM`) is a real identity change at the **mint site**
  (`generate!("…")`) + the EchoStore cache `kind:` + the persisted-id prefix, NOT a lookup-table edit; the Base62
  body is preserved on a prefix-swap so creation-order sorting survives. On a **brand-rename rung** the acceptance
  is a **residual-grep to ZERO** of the retired brand across `lib` + `test` (and, when in scope, the docs) — an
  **external shell gate** (`/usr/bin/grep -rnoE '\bRND\b' …` → 0), not an in-suite assertion; carve the grep so it
  catches the *brand* + the *entity word* but spares `Kernel.round/1` / `Math.round` / the English "round-trip"
  (a blind `s/round/game/g` corrupts the scoring arithmetic in `scoring.ex` / `economy.ex`).
- **The Postgres floor is the system of record.** `Codemojex.Repo` (`use Ecto.Repo, adapter:
  Ecto.Adapters.Postgres`) is started first; `Codemojex.Store` is the only Postgres I/O boundary (plain maps cross
  it; status atoms ⇄ text); **money moves only through `Codemojex.Wallet` inside a DB transaction** (the
  non-negative-balance CHECK + the append-only `transactions` ledger). The schemas live under
  `lib/codemojex/schemas/`; migrations under `priv/repo/migrations/`. A schema rung touches the schema module, the
  migration, AND `Store`/`Wallet` in one atomic change — a column declared but never read is a silent no-op (the
  config-key-never-consumed class). **Two caches sit in front on the hot path** (`Codemojex.Tables` /
  `Codemojex.Cache`: `:cm_rounds`, `:cm_emojisets`, `coherence: :none` — entities immutable for life) and the
  **live competitive state is Valkey** (the board ZSET, first-mover claims, NX payout locks, keyspace
  `cm:<game>:…` via `Codemojex.Wire`). **The privacy line:** the game's `secret` is server-side only — it never
  crosses the wire to a client (the `privacy` stories pin this).
- **The gate ladder is the codemojex app gate, run from `echo/apps/codemojex`** (NEVER umbrella-wide). Hold each
  stage against it:
  - re-probe `asdf current` / `.tool-versions` **from the app dir** (never hardcode — the umbrella pins
    elixir 1.18.4 / erlang 28.5.0.1) · `valkey-cli -p 6390 ping` → `PONG` (the engine is **Valkey on 6390**) ·
    Postgres up (`pg_isready`).
  - `TMPDIR=/tmp mix compile --warnings-as-errors` (`TMPDIR=/tmp` is **load-bearing** — the harness tmp overlay
    hits ENOSPC and surfaces as spurious mid-suite I/O failures unrelated to any logic error).
  - `TMPDIR=/tmp mix test` runs the **pure** stories (scoring / economy / emoji-codes — `ExUnit.start(exclude:
    [:valkey])`); the **integration** stories carry `@moduletag :valkey` and need `TMPDIR=/tmp mix test --include
    valkey`, which **boots the full supervision tree** and therefore needs **both Valkey 6390 AND Postgres** up.
  - **On a schema-landing rung: the fresh-schema reinitialization** — `MIX_ENV=test mix ecto.drop && ecto.create
    && ecto.migrate` (and the dev DB when ruled), proving the migration set comes up clean from zero. Scope the
    DROP to the Ecto-configured dev/test DB ONLY (read the name from `config/runtime.exs` / the umbrella config —
    it is **not** assumable; any `*_snapshot` DB is untouched), and surface the exact target before running it.
  - **The residual-grep proof** on a rename rung (above) → 0; the **docs-truthfulness grep** when the rung
    reconciles a doc.
  - `mix codemojex.stories` regenerates `docs/codemojex/stories/<feature>.stories.md` after any scenario edit.
  - **The ≥100 determinism loop** ONLY for an id-mint / process / lease / schema-mint suite (the same-ms
    branded-id mint hazard — codemojex mints on every room/game/guess/txn). A pure-read / docs-only rung runs a
    multi-seed sweep instead and states the determinism posture honestly.
- **The risk tier decides the verify depth + the formation** (the rung's declared tier): a rung with a
  **destructive at-rest operation** (an `ecto.drop` / a data migration), a **schema redesign**, a **new game-mode
  / process / lease surface** (blind commit-reveal, a settlement worker), an **external-wire cutover** (the HTTP
  routes / the Phoenix channel topics / the JSON keys), or a **brand re-base** is **HIGH-risk** → **L2 Squad,
  Apollo MANDATORY**, the Director's verify deepens (the ≥100 loop, the full mutation battery, the migration
  up/down proof), and a **data-model rung fans out a second architect** (Venus-Postgres — below). A pure-read /
  additive / docs-reconcile rung is NORMAL → **Trio** (or **Duo**); Apollo is then out of the pipeline (it mentors
  after the ship).
- **The Venus-Postgres fan-out (a data-model rung).** When a rung redesigns the relational model, Stage 1 runs
  **two architects in one message, no sibling reads until both land** (the §12 dual-architect discipline,
  `docs/aaw/aaw.architect-approach.md`): **Venus** owns the token/brand/wire/code surface + the build brief;
  **Venus-Postgres** (`VenusPG`, archetype `architect`) owns the **relational redesign** — every column
  type/null/default/CHECK, the indexes + FKs, the type/policy discriminator, the transactional wallet, the
  idempotent settlement, the ONE clean initial migration, and the reinitialization plan. Both author from an
  **identical locked-constraints brief**, distinct lenses; the Director synthesizes + rules the Arms each
  surfaces. (On a non-data rung, only Venus spawns.)
- **The git posture & the entangled tree.** The Operator pre-stages and works out-of-band — the working tree is
  routinely entangled (sibling-course docs, infra files staged). The rung commit is the rung's **measured surface
  ONLY** — `echo/apps/codemojex/**` + the rung's `docs/codemojex/` triad/brief/reconcile + the
  `<scope>.progress.md` ledger / `.registry.json`. **NEVER `git add -A`, NEVER a bare commit**; pathspec only,
  re-verify `git diff --cached --name-only` is purely the rung before committing, and split an entangled concern
  into separate scoped commits.

## Topology router — right-size the formation (rigor constant, ceremony scales)

The formation is **routed, not habitual**. The rung's **risk tier** sets the floor; the **build-state** (unbuilt
vs already-green) collapses the ceremony. Three named Flat-L2 formations:

| Formation | Active roles | Use when |
|---|---|---|
| **L2 Duo** | Director + **one** peer | A single-concern increment — a docs-only reconcile (Director + Venus), an already-green rung needing only the independent verify, or a pure spec author. One peer, one concern. |
| **L2 Trio** | Director + Venus + Mars *(two-pass)* | The standard **NORMAL** build: Venus reconcile/author + Arms → Director rules → Mars build + self-verify → Director verify → Mars harden. No dedicated evaluator; the Director's solo verify is the gate. |
| **L2 Squad** | Director + Venus **(+ VenusPG on a data-model rung)** + Mars(-1/-2) + **Apollo** | The **HIGH-risk** formation (a destructive at-rest op, a schema redesign, a brand re-base, a new game-mode/process/lease surface, a wire cutover). Adds the dedicated Apollo evaluator (post-build reconcile + adversarial verify + BUILD-GRADE) + the deepened verify (the ≥100 loop, the migration up/down proof, the full mutation battery), and — on a data-model rung — the Venus-Postgres second architect. |

**Apply at Bootstrap (§0), before any spawn:** floor by risk (HIGH → Squad, Apollo mandatory); collapse by
build-state (a built-and-green increment re-spawns **no builder** — only the remaining verify / harden / evaluate /
ship legs); BDD-phase Mars red → green → **blue** (an already-green rung enters at the blue refactor/harden pass).
`mcp__aaw__status(scope)` must then show EXACTLY the chosen tier's registered peers — no more (over-ceremony), no
fewer (under-staffing a HIGH rung skips the mandatory Apollo).

## The codemojex facts (the pre-loaded context for the peers)

- **The game** (canon `codemojex.game-model.design.md` + `codemojex.roadmap.md`) — a Telegram emoji-guessing game
  on the BCS stack: a **room** (`ROM`, a long-lived template carrying duration / emoji-set / fee / pool / type) in
  which a **game** (`GAM`, one play with a server-side `secret`, a timer, a prize pool) is played; **players**
  (`PLR`) spend currencies (keys / clips / diamonds) tracked by an append-only `transactions` (`TXN`) ledger;
  **guesses** (`GES`) score linearly; **emoji sets** (`EMS`) expose the sprite grid + codes. The launch type set
  is `{classic, golden}` — `classic` = live feedback + live settlement; `golden` = the blind/sealed mode
  (feedback `none`, sealed top-K settlement, commit-reveal provably-fair secret).
- **The brands** (mint sites in `lib/codemojex/`): `GAM` (game — `rooms.ex` `start_game`) · `ROM` (room —
  `rooms.ex` create) · `PLR` (player — `wallet.ex`) · `TXN` (transaction — `wallet.ex`) · `GES` (guess —
  `game.ex`) · `EMS` (emoji set — `emoji_set.ex`) · `JOB` (bus job — `game.ex`) · `NOT` (notification —
  `notifier.ex` / `notification_worker.ex`) · `CMD` (inbound bot command — `echo_bot.ex`). *(Historical: the
  engine shipped with `RND`/`RMM`/`USR`; the `codemojex-game-rename` scope re-bases those to `GAM`/`ROM`/`PLR`.)*
  NO-INVENT: ground every brand / module / table / key in a real `lib/codemojex/**` file or a design §;
  forward-tense ("cm.N builds …") for an unshipped surface.
- **The persistence tiers** — (1) **Postgres** SoR via `Codemojex.Repo` + `Codemojex.Store`; tables `players` /
  `transactions` / `emoji_sets` / `rooms` / `games` / `guesses` (+ `notifications`); money only through
  `Codemojex.Wallet` in a transaction. (2) **EchoStore** L1-ETS-over-L2-Valkey near-cache (`Codemojex.Tables` /
  `Codemojex.Cache`, `coherence: :none`). (3) **Valkey** real-time competitive state (`Codemojex.Wire` over
  `EchoWire.Cmd`, keyspace `cm:<game>:board/base/players/attempts/closed`, `cm:total_won`).
- **The supervision tree** (`lib/codemojex/application.ex`, `:one_for_one`): `Repo` → `Phoenix.PubSub` → `Bus`
  (shared Valkey connector, 6390) → `Tables` → `RateLimiter` → `EchoBot` → four `EchoMQ.Consumer`s (`:cm_score`,
  `:cm_settle`, `:cm_notify`, `:cm_commands`) → `ChampServer` (the leaderboard) → `CodemojexWeb.Endpoint`.
- **The tests** — the `Codemojex.Story` BDD harness (`test/support/codemojex/story.ex`: `feature` / `scenario` /
  `given_` / `when_` / `then_`) emits real ExUnit tests AND registers story metadata; `mix codemojex.stories`
  generates the `.stories.md`. The suite is keyed by feature (scoring / economy / wallet / emoji-codes /
  rooms-and-games / privacy / settlement).

## 0. Bootstrap (Director, before any spawn)

Read the rung's spec triad (+ its `.prompt.md` or named brief, if present) + the canon
`codemojex.game-model.design.md` + the roadmap + `echo/CLAUDE.md` + **the `/x-mode` skill**. Declare the mode
(**Flat-L2**) and **triage the topology router** (Duo / Trio / Squad) from the rung's **risk tier × build-state**,
recording the chosen tier as the **formation `tool_x_decision`**. Deep-reason the rung (the `/x-mode` §0: the 5W,
the solution space incl. a do-nothing baseline, the invariants as runnable gates — the residual-grep, the
migration up/down, the privacy line — the smallest change that preserves correctness) → `tool_x_trace` (T-n).
**Confirm the Stage-1 gate is reachable** — the triad/brief exists (or Venus authors it) and any **open Operator
fork is resolvable** (a schema/redesign Arm, a destructive-treatment choice, a game-mode mechanic, a wire-cutover
sequencing). A fork that Venus must FRAME first is ruled in-pipeline (Stage 1 → the mandatory `AskUserQuestion`);
a fork that blocks Venus from even starting → **STOP and `AskUserQuestion`** now. Note the toolchain: `asdf
current` (re-probe), **Valkey 6390** (`valkey-cli -p 6390 ping`), **Postgres** (`pg_isready`).

## 1. Stand up the TRUE team & run the pipeline (x.md §5)

`scope` = the dashed rung slug (`cm-1`, or the continuing `codemojex-game-rename`); `operator` = `jonny`;
`workspace` = `/Users/jonny/dev/jonnify`; `ledger_dir` = `docs/codemojex/specs/progress` for a `cm.N` rung (the
`<scope>.progress.md` lands there — create the dir if absent), OR the existing flat path for a continuing named
scope (`docs/codemojex/codemojex-game-rename.progress.md` — APPEND, never rewrite the frozen history). Sequence per
`/x-mode` §1: `mcp__aaw__init` → `aaw_spawn` + `agent_register` the `director` → `TeamCreate(scope)` →
`tool_x_trace(T-1)` opening/continuing the ledger. Create one Task per stage. **zsh does not word-split unquoted
vars** — iterate file lists with `find … -print0 | while IFS= read -r -d '' f`, never `for f in $files`.

Lift each stage's directive from the `.prompt.md` / the named brief (or the Stage-1 Venus brief); wrap it in the
`/x-mode` §3 per-spawn ceremony + "Read and operate by `.claude/agents/<role>.md`."

**Venus** (reconcile the triad lag-1 against the as-built `echo/apps/codemojex` tree, or author it; author the
build brief — agent stories, the brand/token map with every `file:line`, the declared schema/keys, the gate
ladder, the residual-grep acceptance, the smallest-change build order; frame seam/redesign/game-mode forks as
four-part Arms — Rationale/5W/Steelman/Steward) **— on a data-model rung, in PARALLEL with Venus-Postgres**
(`VenusPG` owns the relational redesign + the one clean migration + reinitialization, identical locked-constraints
brief, distinct lens, no sibling read until both land) → **Director rules the Arms** (the mandatory
`AskUserQuestion` — a fork is never decided silently; on the redesign rung this includes the schema-shape Arms +
any game-mode mechanic Arms) → **Mars-1** (build to the brief inside the boundary, cite the spec for every public
call, the real `Codemojex.*` / `EchoData.BrandedId` / `EchoStore` / `EchoWire` surface only — **no invented
signatures**; the schema + migration + `Store`/`Wallet` in one atomic change; compile `--warnings-as-errors`;
write the rung's stories; run the gate) → **Director verify** (a REAL pass: a fresh-gate reconcile + an
**independent gate re-run** — compile + `mix test --include valkey` on Valkey 6390 + Postgres + the residual-grep
+ (schema rung) the migration up/down proof + (mint/process rung) the ≥100 loop — + ≥1 adversarial probe + a
**mutation spot-check**: Edit-in → test-catches → revert → `git diff --stat` clean **net-zero**, LAW-1a) →
**Mars-2** (resume the Stage-1 Mars — one identity, two passes — remediate + harden + the full gate; REMEDIATE
loop MAX 3) → **Apollo** *(HIGH-risk only, between Stage 4 and 5)* (the §11.2 charter — the prompted-checks table
with `file:line` + ≥1 un-prompted finding + ≥1 attack-that-held + a mutation kill-rate; resolve every ambiguity
with the Operator via `AskUserQuestion`; spec-sync; **BUILD-GRADE / BLOCKED**) → **Director ship** (the solo
ship-gate + one LAW-4 commit + the Stage-6 fold). On a NORMAL rung Apollo is out of the pipeline — it mentors
after the ship (PROPOSE-ONLY, Director-ratified under an Operator grant).

## 2. LAW-4 — the single ratifying commit (Director-only, per x.md §10)

At `tool_x_complete` (Z-n), exactly once: the Director's verify clean + the codemojex gate green (+ on a HIGH
rung, Apollo BUILD-GRADE); **≥1 `tool_x_decision` (D-n)** + the **Z-n** written this turn; `git status --short`
AND `git diff --cached --name-only` reviewed; `.git/rebase-merge` / `rebase-apply` checked. Then a **pathspec**
commit — `git add <explicit rung paths>` then `git commit -F <msg> -- <those paths>`; **NEVER `git add -A`, NEVER
a bare commit** (the Operator pre-stages out-of-band). The rung commit is the rung's **measured surface ONLY** —
`echo/apps/codemojex/**` + the rung's `docs/codemojex/` triad/brief/reconcile + the `<scope>.progress.md` /
`.registry.json`; **when the tree is entangled** (a sibling-course reconcile, staged infra files), commit those as
**separate scoped commits per concern** so the LAW-4 commit stays a faithful record of exactly the rung. The
message cites the slug, the Z-n, the D-n decisions, and the Y-n report. Recover a botched bundle with `git reset
--soft HEAD~1` (guard on the expected HEAD first) then the pathspec. **Stage-6 fold:** flip the rung's status in
`docs/codemojex/codemojex.roadmap.md` (+ `codemojex.progress.md`), backward-reconcile the rung `.md` to the green
as-built surface, surface the next frontier, and — under an **explicit Operator grant only** — fold a recurring
finding into a role charter (one guardrail per finding). Do not push unless asked.

## 3. Quality gate (before Z-n, mirrors /x-mode §5)

- [ ] The triad (+ `.prompt.md` / named brief) + the canon + the roadmap + `echo/CLAUDE.md` + the `/x-mode` skill
      read; mode declared Flat-L2; the topology tier triaged + recorded as a `tool_x_decision`.
- [ ] T-n derivation, D-n per locked contract, L-n per surprise written to the `<scope>.progress.md` ledger.
- [ ] Every peer is a REAL self-registered `Agent` spawn (`general-purpose` + the venus/mars/apollo charter; the
      data-model rung's Venus-Postgres present; no FAKE-N); the Director called no Edit/Write on production code
      EXCEPT a mutation spot-check reverted **net-zero** (LAW-1a).
- [ ] Every design Arm was ruled via `AskUserQuestion` before the build (the schema shape, any game-mode mechanic,
      the destructive-treatment choice).
- [ ] The codemojex gate is green, run from `echo/apps/codemojex`: `mix compile --warnings-as-errors` +
      `mix test --include valkey` on **Valkey 6390 + Postgres** + (schema rung) the fresh-schema reinit + the
      migration up/down proof + (rename rung) the residual-grep to **0** + (mint/process rung) the ≥100 loop, all
      under `TMPDIR=/tmp`; the privacy line holds (the `secret` never crosses the wire); `mix codemojex.stories`
      regenerated.
- [ ] The boundary grep is empty: only `echo/apps/codemojex/**` + the rung's `docs/codemojex/` changed; every
      sibling umbrella app (`echo_mq` / `echo_store` / `echo_data` / `echo_wire` / `echo_bot`) untouched;
      `mix.lock` excluded unless a real dep moved.
- [ ] LAW-4: Z-n written → exactly one Director pathspec commit **per concern**; nothing foreign in `--cached`;
      the frozen ledger history untouched.
- [ ] `mcp__aaw__status(scope)` shows EXACTLY the chosen topology tier's registered peers (no FAKE-N).

## 4. Map

- The laws + pipeline: `.claude/commands/x.md` + the `/x-mode` skill. The charters the peers wrap:
  `.claude/agents/{venus,mars,apollo}.md`. The dual-architect method: `docs/aaw/aaw.architect-approach.md`.
- The umbrella build guide (the gate ladder, `TMPDIR=/tmp mix`, Valkey 6390, asdf re-probe): `echo/CLAUDE.md`.
- The canon + the single roadmap + the dashboards: `docs/codemojex/codemojex.game-model.design.md` ·
  `docs/codemojex/codemojex.roadmap.md` · `docs/codemojex/codemojex.design.md` ·
  `docs/codemojex/codemojex.architecture.md` · `docs/codemojex/codemojex.ops.md` ·
  `docs/codemojex/codemojex.progress.md`.
- The specs (source of truth): `docs/codemojex/specs/<rung>.{md,stories.md,llms.md}` (+ `<rung>.prompt.md` if
  present) + a named build brief (`docs/codemojex/codemojex-game-rename.brief.md`).
- The code (the boundary): `echo/apps/codemojex/` (`lib/` + `lib/codemojex_web/` + `priv/repo/migrations/` +
  `test/`).
- The run's audit trail: the rung's `<scope>.progress.md` (+ `.registry.json`) + `mcp__aaw__status`.
