# Codemojex — Program Progress Dashboard

**One-line state.** Codemojex is the live Telegram emoji-guessing game and the reference
implementation of the Branded Component System — the consumer app in the `echo` umbrella at
`echo/apps/codemojex`, riding `echo_wire` · `echo_data` · `echo_mq` · `echo_store`. The **engine is
whole**: a thin Phoenix surface (`CodemojexWeb`) over the `Codemojex` facade, guesses on fair
per-player lanes to one scorer, a Valkey leaderboard, a transactional Postgres wallet, the **two-mode
engine — classic (live) + golden (blind/sealed)** on one six-table schema, and an optional Graft
durable floor. The founding core (**cm.1**) and the blind Golden flow (**cm.3**) shipped via the `codemojex-game-rename`
rung; the **auth floor (cm.4)** then shipped via the `cm-4` rung — verified Telegram `initData` (the pure
`Codemojex.InitData` HMAC verifier) → a shared **`SES`-in-Valkey** session (the FIRST mutable
`EchoStore.Table`, `:tracking` coherence + immediate revocation), with `POST /api/players` (the free-money
mint) retired. The **one pre-launch auth gap is closed**. The **course chapter B7**
([`codemojex.roadmap.md`](./codemojex.roadmap.md), six modules B7.1–B7.6 of three dives each) is
**PLANNED** — the chapter landing is written; the dives follow. **Next on the build ladder:** the
`cm.5+` deferred systems (the `BNK` bank · `RMP` membership · commerce · growth ·
analytics — the [feature catalog](./codemojex.roadmap.md#the-feature-catalog)).

---

## Legend

| Symbol | State | Meaning |
|---|---|---|
| ✅ | **SHIPPED** | committed, gate-green on this machine |
| 🔨 | **IN FLIGHT** | building now — partial artifacts on disk, not yet committed |
| 📋 | **PLANNED** | abstract fixed on the confirmed ladder, page/triad not yet authored |
| 🅿️ | **DEFERRED** | parked behind another delivery, Operator-revisable |

A rung is one shippable increment.

---

## The runtime (as-built, `echo/apps/codemojex`)

```text
Codemojex · the Telegram Mini App on the BCS stack · gate: per-app (NOT the echo_mq v2 invariant)

Surface        ✅ real         Phoenix JSON API + Channels, privacy-safe views (CodemojexWeb)
Facade         ✅ real         the Codemojex module — delegates into the domain systems
Bus            ✅ real         EchoMQ on Valkey :6390 — fair lanes (guesses · settle · notify · commands)
Near-cache     ✅ real         EchoStore L1/ETS over L2/Valkey — the game + emoji set, coherence :none
Floor          ✅ real         Postgres (Ecto) — players · transactions · rooms · games · guesses · emoji_sets
Durable floor  ✅ optional     EchoStore.Graft committer — started only when :graft_volume is set
Identity       ✅ real         14-byte branded ids — nine brands GAM/ROM/PLR/GES/EMS/TXN/JOB/NOT/CMD
Engine         ✅ real         the Mastermind engine — classic (live) + golden (blind/sealed), one linear score
```

The binding design is [`codemojex.design.md`](./codemojex.design.md) (the engine, the systems, the
six-table model, the state machine, the pragmatic Valkey node, the open questions) — already truthful to
the `GAM`/`ROM`/`PLR` as-built surface. The delivery plan + the forward feature catalog is
[`codemojex.roadmap.md`](./codemojex.roadmap.md); the process that ships a rung is the **Codemojex
Program** ([`program/codemojex.program.md`](./program/codemojex.program.md)).

---

## Course chapter B7 — the complete game (PLANNED)

The single ladder is [`codemojex.roadmap.md`](./codemojex.roadmap.md); the feature catalog is folded into
it ([§ The feature catalog](./codemojex.roadmap.md#the-feature-catalog)). All six modules are PLANNED —
the chapter landing is written and the dives follow, each a landing plus three dives held to the A+ gates.

```text
B7 · the game as branded systems, taught on the running code

  B7.1  📋 PLANNED   the game as branded systems — ids are the keys · the four layers · the privacy boundary
  B7.2  📋 PLANNED   rooms, modes, and the secret — room as template+mode · the emoji set · the secret + commitment
  B7.3  📋 PLANNED   guesses on fair lanes — the guess + the lock · charged then enqueued · fair lanes + the worker
  B7.4  📋 PLANNED   scoring + settlement — distance + linear points · the total out of 600 · settlement strategies
  B7.5  📋 PLANNED   the economy and the bank — three currencies · the transactional wallet · the bank/pool/rake
  B7.6  📋 PLANNED   the live surface on Phoenix — the JSON API · channels + PubSub · production on Fly
```

> The course pages render under `/bcs/codemojex/**` (the BCS contract-sheet identity). The page
> tree exists on disk; the rendered HTML is the Operator's to author and is **not** an edit target
> of a code rung.

---

## Rungs

### `codemojex-game-rename` — the game-model redesign + the three brand re-bases ✅ SHIPPED

**State:** ✅ SHIPPED (Operator-committed). **Risk:** HIGH (three brand re-bases + a destructive at-rest
Postgres reinit + a schema redesign + an external-wire cutover). **Formation:** L2 **Squad** — Venus +
Venus-Postgres (the dual-architect data-model fan-out) + Mars(-1/-2) + Apollo + Director. **Boundary:**
`echo/apps/codemojex` (code + tests + `priv` + migrations) + the rung's `docs/codemojex/` artifacts.

The rung turned a token `round`→`game` rename into a from-scratch model redesign for a multi-game-type
engine, and re-based **three** entity brands to the forward canon — the brand **is** the type in BCS, so
a true rename re-bases the identity everywhere it travels:

| Surface | Delivered |
|---|---|
| Brands | `RND`→`GAM` (game, full entity drag) · `RMM`→`ROM` (room) · `USR`→`PLR` (player) — **0 residual** in `lib` + `test` (`Kernel.round` spared) |
| Schema | one **collapsed initial migration**, **six tables** (`players`/`transactions`/`emoji_sets`/`rooms`/`games`/`guesses`) + the `games_type` + `games_status` CHECKs + the non-negative wallet CHECK |
| Engine | the `type` discriminator + four policy columns; **linear scoring only** — the bonus-tier economy + the `ptier`/`bonus`/`tierfirst` keyspace removed |
| Blind Golden (cm.3) | commit-reveal **SHA-256(secret ‖ nonce)** · a per-game randomized **`cell_codes`** keyboard · in-flight feedback suppression · one fat **`revealed`** event · sealed top-K settlement (stored **`payout_split`** `[40,25,15,12,8]`, dust→rank-1, exactly-once via the status guard + `SET NX`) |
| Wire | the `/games` routes + the `game:<id>` channel/PubSub topic + the JSON keys cut over to `GAM`; the room/player wire words (`/rooms`, `/players`) and FK columns kept (the re-base moves the id value, not the column name) |

**Gate (green, from `echo/apps/codemojex` on Valkey 6390 + Postgres):** `compile --warnings-as-errors`
clean · `mix test --include valkey` 41/0 · residual `RND`/`RMM`/`USR` greps = **0** · the migration
up/down + the fresh-schema reinit · **150/150** determinism · a live-boot smoke (HTTP serves the renamed
entity; the secret never crosses the wire). **Apollo: BUILD-GRADE** — 6/6 mutation kill, defense-in-depth
exactly-once.

The rung's design-phase deliverable, the frozen audit ledger, the build brief, and the AAW registry are
archived under [`specs/progress/`](./specs/progress/) (records-freeze — the ledger history is never
rewritten). The settled spec triads are [`specs/cm.1.*`](./specs/cm.1.md) (the founding core) +
[`specs/cm.3.*`](./specs/cm.3.md) (the blind Golden flow) +
[`specs/cm.4.*`](./specs/cm.4.md) (the auth floor — verified `initData` + the shared `SES` session).

---

## Next

The engine is whole and the **auth floor (cm.4) has shipped** — verified Telegram `initData` → a shared
**`SES`-in-Valkey** session (the first mutable `EchoStore.Table`, immediate revocation), `POST /api/players`
retired; the one pre-launch auth gap is closed. The forward work is the **`cm.5+` deferred systems** named
in the roadmap's [feature catalog](./codemojex.roadmap.md#the-feature-catalog): the `BNK` bank + rake · the
`RMP` membership + the anonymized leaderboard · commerce (`PKG`/`ORD`/`OTX`/`WHK`) · growth (`SHR`) ·
analytics (`AEV`) · the LiveAdmin console. Each
lands as its own `cm.N` rung through the Codemojex Program — a new triad under `specs/` + a per-rung
ledger under `specs/progress/`.

---

*This dashboard rolls up the roadmap status; every status claim is grounded in
[`codemojex.design.md`](./codemojex.design.md) / [`codemojex.roadmap.md`](./codemojex.roadmap.md) / the
`echo/apps/codemojex` tree on disk. Unshipped work is stated forward-tense.*
