# Codemojex persistence patterns (echo-persistence) — design-ahead KB

A **forward-vision** design-ahead of the pattern-selection across codemojex's *near-cache-in-memory* decisions,
authored on the Operator's forward directive (ledger **D-3**) for independent review. Method of record:
[`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) (four-part arms where a genuine
fork exists; a short ruling where the as-built or the framework settles it). Sibling pattern:
[`../auth-flow/`](../auth-flow/) — the `SES` durability fork (its synthesis §3.3) is the **anchor** this KB
generalizes into a reusable framework.

**The menu (four substrates, disjoint profiles, all grounded on disk):** the Valkey-backed **near-cache**
(`EchoStore.Table` — L1-ETS over L2-Valkey, coherence `:none`/`:broadcast`/`:tracking`), **Valkey-TTL ephemeral**
(a near-cache value rebuilt on loss — the session floor), in-memory persistent **CHAMP** (`EchoData.BrandedChamp`
— a structural-sharing *memory representation*, not durability), and the durable **Graft** floor
(`EchoStore.Graft` — OCC-fenced single-writer CubDB → Tigris). **CubDB is named and deferred** (it is Graft's
local store engine, not a standalone codemojex tier).

| Doc | What it is |
|---|---|
| [`persistence.design.md`](./persistence.design.md) | The pattern catalog (each substrate, grounded at its `file:method`, with its durability/memory/read-write profile) · the decision framework (the four axes — **reconstruct-cost decisive**) · the per-decision rulings & forks. |

**The decisive axis — reconstruct-cost.** A near-cache-in-memory decision is picked first by *what loss costs*:
cheap-to-rebuild state takes the **ephemeral** floor (persistence buys only machinery and failure modes);
expensive/only-copy state earns a **durable** tier. The `SES` is the canonical cheap-to-rebuild record
(re-handshake < persistence — the anchor).

**The per-decision verdicts (full argument in the design doc §3):**
- **`SES` durability** — **ephemeral** (re-handshake < persistence), with a forward dial fork surfaced
  (ephemeral / AOF / Graft — the auth-flow §3.3 fork, generalized; the Operator + VenusPG rule).
- **`:cm_games` / `:cm_emojisets`** — **near-cache, `coherence: :none`** (immutable, point-by-id, cheap rebuild) —
  the framework **confirms the as-built**; no fork.
- **The CHAMP leaderboard** — a **reconcile finding**: the live board is a Valkey **sorted set**
  (`Codemojex.Board`); the `EchoData.ChampServer` started under name `Codemojex.Leaderboard` is a
  **supervised-but-unfed** forward scaffold (no writer, no reader, rebuild source = optional Graft). The CHAMP fit
  is a **forward fork** (LB-ZSET today; LB-CHAMP waits on a structural/cross-runtime reader), plus a **cleanliness
  fork** for the Operator (mark the scaffold `[FORWARD]` or retire it).

**Status:** design-ahead, uncommitted, for review. **No code, no canon edit.** It **does not block the cm.4 floor**
— the session tier is already settled at Valkey-TTL ephemeral (auth-flow **D-2**); this KB records *why* (the
reconstruct-cost axis) and frames the forward forks the floor forecloses nothing of.
