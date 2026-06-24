# Codemojex — Program Progress Dashboard

**One-line state.** Codemojex is the live Telegram emoji-guessing game and the reference
implementation of the Branded Component System — the consumer app in the `echo` umbrella at
`echo/apps/codemojex`, riding `echo_wire` · `echo_data` · `echo_mq` · `echo_store`. The **runtime
is real**: a thin Phoenix surface (`CodemojexWeb`) over the `Codemojex` facade, guesses on
fair per-player lanes to one scorer, a Valkey leaderboard, a transactional Postgres wallet, the
two-mode engine (live + Golden Rooms), and an optional Graft durable floor — all wired and
parse-verified, documented as **pre-launch** (the one open gap before launch is verified Telegram
`initData`, per the architecture). The **course chapter B7** (`codemojex.roadmap.md`, six modules
B7.1–B7.6 of three dives each) is **PLANNED** — the chapter landing is written; the dives follow.
The **active rung** is `codemojex-game-rename`: the per-play entity rename **`round`/`RND` →
`game`/`GAM`** — the roadmap and the as-built architecture/specs drafts already canonized
**`game`/`GAM`**, and this rung carries the **live code, the Postgres store, the cache kind, and
the external wire** the rest of the way.

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
Identity       ✅ real         14-byte branded ids; the per-play entity is the rename target this rung
```

The architecture is the as-built mirror in [`codemojex.architecture.md`](./codemojex.architecture.md)
(already `game`/`GAM`); the as-built design write-up is
[`codemojex.design.md`](./codemojex.design.md) (lags at `round`/`RND` — reconciled by this rung).

---

## Course chapter B7 — the complete game (PLANNED)

The single ladder is [`codemojex.roadmap.md`](./codemojex.roadmap.md); the feature list is
[`codemojex.specs.md`](./codemojex.specs.md). All six modules are PLANNED — the chapter landing is
written and the dives follow, each a landing plus three dives held to the A+ gates.

```text
B7 · the game as branded systems, taught on the running code

  B7.1  📋 PLANNED   the game as branded systems — ids are the keys · the four layers · the privacy boundary
  B7.2  📋 PLANNED   rooms, modes, and the secret — room as template+mode · the emoji set · the secret + commitment
  B7.3  📋 PLANNED   guesses on fair lanes — the guess + the lock · charged then enqueued · fair lanes + the worker
  B7.4  📋 PLANNED   scoring, tiers, settlement — distance + points · the total + thirty tiers · settlement strategies
  B7.5  📋 PLANNED   the economy and the bank — three currencies · the transactional wallet · the bank/pool/rake
  B7.6  📋 PLANNED   the live surface on Phoenix — the JSON API · channels + PubSub · production on Fly
```

> The course pages render under `/bcs/codemojex/**` (the BCS contract-sheet identity). The page
> tree exists on disk; the rendered HTML is the Operator's to author and is **not** an edit target
> of a code rung.

---

## Rungs

### `codemojex-game-rename` — the per-play entity rename (`round`/`RND` → `game`/`GAM`)

**State:** 🔨 IN FLIGHT. **Risk:** HIGH (a destructive at-rest Postgres operation + an external-wire
cutover). **Boundary:** `echo/apps/codemojex` (code + tests + `priv` + `docs/`) + this dashboard +
`codemojex.design.md` + `docs/echo/bcs/bcs.2.md` + `docs/echo/bcs/bcs.todo.md` (new). **No `html/bcs`
edit** — the Operator hand-edits the rendered pages from `bcs.todo.md`.

The brand **is** the type in BCS (it is what is checked at every boundary), so a true rename
re-bases `RND` → `GAM` everywhere the identity travels: the minted brand, the Postgres `games`
table and its foreign keys, the EchoStore cache `kind`, and the external surface (the `/games`
routes and the `game:<id>` channel/PubSub topic). The Operator ruled a **FULL cutover including
the wire, with the stored-data migration**.

| Surface | Shape | State |
|---|---|---|
| Code — brand · schema · API · wire | `RND`→`GAM`, `Schemas.Round`→`.Game`, `round_view`→`game_view`, `/rounds`→`/games`, `round:`→`game:`, `:no_round`→`:no_game` | 🔨 specced (the brief) |
| Postgres migration | Path A (in-place, pre-launch) **or** Path B (reversible rename+rebrand, live data) — Operator-ruled | 🔨 fork surfaced |
| `codemojex.design.md` | the as-built mirror made truthful to the renamed code | 🔨 specced |
| `docs/echo/bcs/bcs.2.md` | the six entity-`round` tokens → `game` (the English `round`/`round-trip` hits untouched) | 🔨 specced |
| `docs/echo/bcs/bcs.todo.md` (new) | the `html/bcs/**` lines enumerated for the Operator's hand-edit | 🔨 specced |

The roadmap (`codemojex.roadmap.md`), the architecture draft (`codemojex.architecture.md`), and the
feature list (`codemojex.specs.md`) are **already `game`/`GAM`** — this rung makes the live code,
the floor, and the design mirror catch up to them, so the canon and the running system agree.

---

## Known follow-up (OUT OF SCOPE here — a separate reconcile)

- **The `RMM` ↔ `ROM` + `RMP` room/membership namespace drift.** The as-built code and
  `codemojex.design.md` key the room template at **`RMM`** (player at `USR`), while the roadmap, the
  architecture draft, the feature list, and the `/bcs` manuscript key it at **`ROM`** (membership
  `RMP`, player `PLR`). That divergence is **not** part of the `round`→`game` rename and must not be
  folded into it — the rename touches the `round`/`game` token only and leaves the surrounding
  `RMM`/`ROM`/`RMP`/`USR`/`PLR` vocabulary exactly as found. A dedicated reconcile owns it.

---

*This dashboard rolls up the roadmap status and opens the rename rung; every status claim is
grounded in `codemojex.roadmap.md` / `codemojex.design.md` / the `echo/apps/codemojex` tree on disk.
Unshipped work is stated forward-tense.*
