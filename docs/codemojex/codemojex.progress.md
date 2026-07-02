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
mint) retired. The **one pre-launch auth gap is closed**. The **monetization core then shipped**: the
**Golden Room tournament (cm.5)** — `:gathering` + `Wallet.buy_in` (the buy-in exactly-once index) +
`close_split`/`close_void` (`22cb2cf9`); the **revenue ledger (cm.6)** — the `RVL` `revenue_ledger` +
`Wallet.house_post`/`house_balance` (`2de57202`, the `BNK` bank's first slice); and the **KeyShop (cm.7)**
— multi-rail key pay-in, Telegram Stars end-to-end, the `OTX (rail, external_id)` exactly-once gate that
closed the double-mint-on-replay hazard, gross purchase revenue booked to the same ledger (`0acba290`,
Apollo BUILD-GRADE). The **standalone `/codemojex` course**
([`specs/course/`](./specs/course/course.toc.md), nine chapters C0–C8 of three dives each — the B7 arc
reconciled + extended) is **SCAFFOLDED** — the landing is built, the nine chapter stubs are shipped,
per-chapter authoring follows; the `/bcs/codemojex` chapter doors into it. **Next on the build ladder:** **cm.8 —
cash-out / treasury** (withdrawals: diamonds → TON/USDT/RUB at floating rates, the negative-`delta` house
debit cm.7 designs-for, KYC/AML + the 21-day hold; `cm-7` `D-2`), then the remaining
`BNK`/`RMP`/growth/analytics systems in the [feature catalog](./codemojex.roadmap.md#the-feature-catalog).

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
Identity       ✅ real         14-byte branded ids — GAM/ROM/PLR/GES/EMS/TXN/JOB/NOT/CMD + SES/RVL/PKG/ORD/OTX/WHK (cm.4–cm.7)
Engine         ✅ real         the Mastermind engine — classic (live) + golden (blind/sealed), one linear score
```

The binding design is [`codemojex.design.md`](./codemojex.design.md) (the engine, the systems, the
six-table model, the state machine, the pragmatic Valkey node, the open questions) — already truthful to
the `GAM`/`ROM`/`PLR` as-built surface. The delivery plan + the forward feature catalog is
[`codemojex.roadmap.md`](./codemojex.roadmap.md); the process that ships a rung is the **Codemojex
Program** ([`program/codemojex.program.md`](./program/codemojex.program.md)).

---

## The course — /codemojex (SCAFFOLDED)

The course map is [`specs/course/course.toc.md`](./specs/course/course.toc.md); the fine-grained
dashboard is [`specs/course/course.progress.md`](./specs/course/course.progress.md). The B7 arc is
reconciled to the as-built engine (linear-only scoring; the shipped Golden Room) and extended with the
shipped cm.4/cm.6/cm.7 systems and a production chapter. The single build ladder remains
[`codemojex.roadmap.md`](./codemojex.roadmap.md) ([§ The feature catalog](./codemojex.roadmap.md#the-feature-catalog)).

```text
/codemojex · nine chapters over the shipped engine (specs/course/course.toc.md)

  landing   ✅ SHIPPED   the course home, built A+ — the guess-row figure · the C0–C8 map · doors · CMX stamp
  C0–C8     ✅ SHIPPED   as gated real-shell stubs — identity + thesis + dive gists; content authoring next
            C0 overview · C1 branded systems · C2 rooms/modes/secret · C3 fair lanes · C4 scoring+settlement
            C5 economy+bank · C6 ledger+KeyShop (cash-out forward) · C7 live surface · C8 production
  27 dives  📋 PLANNED   per-chapter authoring rungs, briefed by specs/course/course.N.md
```

> The course pages render under `/codemojex/**` (the CMX calibration of the contract-sheet identity —
> Telegram-blue lead). The built `/bcs/codemojex` chapter landing remains the BCS course's B7 and
> door-links into the standalone course. The rendered HTML is the Operator's to author and is **not**
> an edit target of a code rung.

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

The rung's design-phase deliverable, the frozen audit ledger, the build brief, and the AAW registry
were archived under `specs/progress/` through cm.7 and retired from the working tree in the docs reorg
(`7ffe0e29`) — records-freeze holds in git, where that history is never rewritten. The settled spec triads are [`specs/cm.1.*`](./specs/cm.1.md) (the founding core) +
[`specs/cm.3.*`](./specs/cm.3.md) (the blind Golden flow) +
[`specs/cm.4.*`](./specs/cm.4.md) (the auth floor — verified `initData` + the shared `SES` session).

---

## Next

The engine is whole, the **auth floor (cm.4)** shipped, and the **monetization core** now ships with it: the
**Golden Room tournament (cm.5)**, the **revenue ledger (cm.6 — the `BNK` bank's first slice)**, and the
**KeyShop (cm.7 — multi-rail key pay-in, commerce `PKG`/`ORD`/`OTX`/`WHK`, Telegram Stars end-to-end, the
exactly-once gate that closed the double-mint-on-replay hazard)**. The forward work is the remaining
**`cm.8+` deferred systems** named in the roadmap's
[feature catalog](./codemojex.roadmap.md#the-feature-catalog): **cm.8 — cash-out / treasury** (withdrawals,
the negative-`delta` house debit cm.7 designs-for, KYC/AML + the 21-day hold) · the rest of the `BNK` bank +
rake · the `RMP` membership + the anonymized leaderboard · growth (`SHR`) · analytics (`AEV`) · the LiveAdmin
console. Each
lands as its own `cm.N` rung through the Codemojex Program — a new triad under `specs/` (the rung's
ledger recorded with its triad; history in git).

---

*This dashboard rolls up the roadmap status; every status claim is grounded in
[`codemojex.design.md`](./codemojex.design.md) / [`codemojex.roadmap.md`](./codemojex.roadmap.md) / the
`echo/apps/codemojex` tree on disk. Unshipped work is stated forward-tense.*
