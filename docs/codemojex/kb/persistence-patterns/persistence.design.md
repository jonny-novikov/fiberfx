# Codemojex persistence-pattern selection (the echo-persistence design-ahead)

> A **forward-vision** design-ahead (Operator directive D-3): the pattern-selection framework for codemojex's
> *near-cache-in-memory* decisions, grounded on the as-built `echo/apps/**` tree. Method of record:
> [`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) (four-part arms where a
> genuine fork exists; a short ruling where the as-built or the framework settles it). Pattern of the KB:
> [`../auth-flow/`](../auth-flow/) (the `SES` durability fork, §3.3 of its synthesis, is the **anchor** this
> document generalizes). This is a design-ahead — **it does not block the cm.4 floor**; the cm.4 session tier
> is already settled at Valkey-TTL ephemeral (auth-flow D-2). This document records *why* and the *forward
> pattern*, and frames the forward forks for the Operator. **No code, no canon edit.**

---

## §0 · The result in one line

The echo-persistence menu is **four substrates with disjoint profiles** — the Valkey-backed **near-cache**
(`EchoStore.Table`, the L1-ETS-over-L2-Valkey tier with three coherence modes), the in-memory persistent
**CHAMP** (`EchoData.BrandedChamp`, a structural-sharing memory representation, *not* durability), the durable
**Graft** floor (`EchoStore.Graft`, OCC-fenced single-writer CubDB → Tigris), and **Valkey-TTL ephemeral** (a
near-cache value that lives only on its TTL, rebuilt on loss) — and a *near-cache-in-memory* decision is picked
by **one decisive axis: reconstruct-cost.** Cheap-to-rebuild state takes the ephemeral floor; expensive-to-rebuild
state earns a durable tier. The session (`SES`) is the canonical cheap-to-rebuild record (re-handshake < persistence
— the anchor); the immutable game/emoji-set caches are cheap *and* coherence-free (`:none`); the CHAMP leaderboard
projection is, today, a **rebuildable-but-unfed** forward scaffold whose live truth is a Valkey sorted set.

---

## §1 · The pattern catalog

Each pattern, grounded at its source (`file:method`), with its durability / memory / read-write profile and the
shape of decision it fits. **CubDB is named and deferred** (§1.5) — it is Graft's *local store engine*, not a
standalone codemojex tier, so it is not a selectable pattern at the codemojex layer.

### §1.1 · The near-cache tier — `EchoStore.Table` (L1-ETS over L2-Valkey, cache-aside)

**What it is.** One declared L1 cache over L2 Valkey, cache-aside at ETS speed
([`echo/apps/echo_store/lib/echo_store/table.ex`](../../../../echo/apps/echo_store/lib/echo_store/table.ex)).
A read is a caller-side `:ets.lookup` against a public read-concurrent table (`fetch/3`); a hit never enters the
owner process. A miss coalesces onto a single in-flight fill (one fill per herd) that checks L2, falls through to
the declared `loader`, and writes both layers under a jittered TTL (`ttl ± ttl·jitter`, so a cohort filled together
does not expire together). A full table degrades to pass-through, never to failure. Every table declares its **kind**,
and the kind-gate runs before either layer is touched — a wrong-namespace id is refused at the door (`{:error, :kind}`),
the branded-id law riding into the cache unchanged.

**The three coherence modes** (declared per table; the load-bearing axis for a *mutable* near-cache):

| Mode | Mechanism | When it fits |
|---|---|---|
| `:none` | no invalidation; the row lives to its TTL | the entity is **immutable for the cache's life** — a wrong-version row is impossible because there is no second version |
| `:broadcast` | a versioned app-level pub/sub ring (`{:coh, name}`); a writer publishes a "message about a name", every peer applies it as a clean miss (`apply_coherence/4` drops L1 iff the message's version is newer) | a **mutable** entity where a BCS-idiomatic, app-level, writer-published invalidation is enough — accepts an at-most-once staleness bound (a lost message = one TTL of a stale row) |
| `:tracking` | RESP3 `CLIENT TRACKING` — Valkey itself pushes an invalidation for any write to the table's `ecc:{table}:` prefix (including a `DEL`); the owner evicts the L1 row | a **mutable** entity where the invalidation must be **server-pushed and writer-independent** — fires on the write itself, reaches every tracking client; the cost is cross-language (a non-BEAM edge with its own L1 is not auto-tracked) |

**Profile.** Durability: **none of its own** — the value is durable only insofar as the loader's system of record
is (Postgres, for the codemojex caches). Memory: a bounded ETS L1 per node + a shared Valkey L2. Read/write:
**point** reads (keyed by branded id), single-flight fills, best-effort writes. **Fit:** the read-hot path in front
of a slower system of record, where the access pattern is point-by-id and the value frame is a binary the loader
produces. The version frame (`put/3` mints the version of the table's kind; `put/4` carries the writer's) makes
coherence idempotent by comparison.

**As-built in codemojex.** `Codemojex.Tables`
([`echo/apps/codemojex/lib/codemojex/tables.ex`](../../../../echo/apps/codemojex/lib/codemojex/tables.ex))
declares two such tables — `:cm_games` (`GAM`) and `:cm_emojisets` (`EMS`) — both `coherence: :none`, both with
`:erlang.term_to_binary` loaders (BEAM-only — a non-BEAM reader could not decode them; the auth-flow synthesis §2
turns exactly on this, mandating a JSON loader for the cross-edge `SES`).

### §1.2 · Valkey-TTL ephemeral — a near-cache value that lives on its TTL alone

**What it is.** Not a separate module — a **usage discipline** on the near-cache / on Valkey: a value written with a
TTL and **rebuilt on loss** rather than persisted. The store of record is reconstruction itself (a re-handshake, a
re-fill from Postgres, a re-derivation), not a durable substrate. On a Valkey restart or an L1 eviction the value is
simply absent and is re-created on next demand.

**Profile.** Durability: **deliberately none** beyond the TTL window — loss is a *design-accepted* event, bounded by
the reconstruct path. Memory: a Valkey key (+ an optional L1 row). Read/write: point, with a re-create-on-miss
contract. **Fit:** state that is **cheap to rebuild** and where re-handshake / re-derivation costs less than the
machinery and failure modes of persistence — the decisive case being a record whose loss is recoverable by re-running
the path that created it.

**As-built / forward in codemojex.** The cm.4 session (`SES`) tier is settled at this pattern (auth-flow D-2 / its
synthesis §3.3): a session is *the* record where re-handshake < persistence, so the `SES` is a Valkey-TTL entity that
a holder re-mints by re-handshaking on loss. (The `SES`-in-Valkey surface is not yet wired — it is the post-ruling
cm.4 floor — so it is named here forward-tense.)

### §1.3 · CHAMP — `EchoData.BrandedChamp` (in-memory persistent HAMT forest)

**What it is.** A persistent (structurally-shared, immutable-update) branded-id map over a CHAMP forest — one trie per
3-byte namespace, snowflake-keyed
([`echo/apps/echo_data/lib/echo_data/branded_champ.ex`](../../../../echo/apps/echo_data/lib/echo_data/branded_champ.ex)).
Its moduledoc is explicit about *when* to reach for it: **`EchoData.BrandedMap` is the default** (it rides the BEAM's
native HAMTs and wins the general matrix);
[`BrandedChamp`](../../../../echo/apps/echo_data/lib/echo_data/branded_champ.ex) is for when **the in-trie placement
itself is part of a contract** (the same `hash32` positions a key here, in the native tables, and in a Go/Node
consumer) or when the tree shape must be instrumented, persisted, or mirrored across runtimes. `EchoData.ChampServer`
([`champ_server.ex`](../../../../echo/apps/echo_data/lib/echo_data/champ_server.ex)) wraps a `BrandedChamp` in a
GenServer for stateful shared access; `EchoData.ChampView`
([`champ_view.ex`](../../../../echo/apps/echo_data/lib/echo_data/champ_view.ex)) is the rebuild seam —
`rebuild_view/1` folds decoded entries into a fresh `BrandedChamp`, `from_volume/3` reads a **Graft** Volume's pages
at a snapshot and decodes each, and `rebuild_server/3` swaps a `ChampServer`'s whole map atomically.

**Profile.** Durability: **none — this is a memory representation, not a durability tier.** A CHAMP is an in-heap data
structure; it survives only as long as its holder process and is rebuilt from a durable source on restart (the
`ChampView` seam folds from **Graft**, per its moduledoc — "CHAMP is an L0 memory tier whose contents are *rebuildable
from L2 (Graft)*"). Memory: in-heap, structurally shared (an update shares unchanged subtrees with the prior version —
cheap persistence-of-structure, O(1)-ish per-namespace counts cached). Read/write: **structural** — point `fetch`,
per-namespace traversal (`get_namespace/2`), whole-forest folds, set merges; updates are pure (return a new map).
**Fit:** an in-memory projection / view that benefits from structural sharing and a placement contract, rebuilt from a
durable floor — **not** a place to *rest* state (that is the floor's job).

### §1.4 · Graft — `EchoStore.Graft` (the durable, replicated at-rest floor)

**What it is.** Native-BEAM Graft: lazy, partial, page-based, strongly-consistent replication, with no foreign engine
([`echo/apps/echo_store/lib/echo_store/graft.ex`](../../../../echo/apps/echo_store/lib/echo_store/graft.ex)). One
**single-writer process per Volume** (`VolumeServer`) whose mailbox *is* Graft's global write lock; an OCC-fenced
commit (`EchoStore.Graft.Committer.fenced_commit/5` stamps the writer's epoch and rejects a stale writer via
`Epoch.fence/2` rather than double-append — a conditional-write fence); a durable local page store on **CubDB**'s
append-only immutable B-tree (`EchoStore.Graft.Store.append/3` lands a commit row *and* its pages in **one CubDB
transaction**, so a crash never leaves a commit without its pages); lock-free reads off zero-cost immutable snapshots
(`Store.page_at/3` — one bounded reverse `select`); a real-time fold to **Tigris** object storage
(`EchoStore.Graft.Streamer`, the native Litestream replacement); and a **commit-log-as-outbox drain**
(`Committer.announce/4` re-publishes each commit's branded ids to the EchoMQ bus **at-least-once**, so a downstream
consumer reacts to durable state without polling — the cargo law: the bus carries the *names*, the bytes travel via
Tigris).

**Profile.** Durability: **the floor — durable, replicated, point-in-time-recoverable.** Local crash-safe (the
one-transaction commit), survives a node loss (the Tigris fold), and replays to any LSN
(`EchoStore.Graft.read_at/3` reads a page at a historical Snapshot). Memory: an L1 head-page ETS cache over the CubDB
store. Read/write: point page reads + the OCC single-writer commit; **no merge** — reconciliation is fast-forward or
a surfaced divergence (`Committer.reconcile/3` → `Divergence.check/3`). **Fit:** state that must **rest durably**,
survive restart and node loss, replicate cross-region, and/or feed an at-least-once downstream — the at-rest floor
beneath the volatile half.

**As-built in codemojex.** The Graft floor is **optional and off by default**: when `:graft_volume` is configured
`Codemojex.Application` starts the `Committer`
([`application.ex:103–124`](../../../../echo/apps/codemojex/lib/codemojex/application.ex)); absent the config, the
replicated floor is simply not in the tree and the app boots cleanly (`codemojex.design.md` §Storage tiers /
§Configuration). The durable system of record for codemojex today is **Postgres**; Graft is the durable *page* floor
beneath the cache/log, surfaced as a forward tier.

### §1.5 · CubDB — DEFERRED (named, not designed)

CubDB is the **local store engine inside Graft**
([`echo/apps/echo_store/lib/echo_store/graft/store.ex`](../../../../echo/apps/echo_store/lib/echo_store/graft/store.ex)
— "an append-only, immutable B-tree … read operations performed on zero-cost immutable snapshots," with MVCC and ACID
transactions). It is **not a standalone codemojex persistence tier**: codemojex reaches durability through Graft (which
*owns* CubDB) or through Postgres, never CubDB directly. Per the directive, CubDB is **named and deferred** — it is not
a selectable pattern at the codemojex layer, and this document designs no codemojex-direct CubDB usage. (Should a
future decision want an embedded ordered local store *outside* Graft — e.g. a per-node durable queue or index — that is
a forward fork to surface then, not a pattern in today's menu.)

---

## §2 · The decision framework — the axes that pick a pattern

A *near-cache-in-memory* decision is picked by four axes, in priority order. **Reconstruct-cost is decisive** — it is
the axis the auth-flow `SES` ruling turned on, generalized here.

### §2.1 · Axis 1 (decisive) — reconstruct-cost: cheap to rebuild → ephemeral; expensive → durable

The first question is **what does loss cost?** If the value can be re-derived by re-running the path that created it
(a re-handshake, a re-fill from the system of record, a re-projection), and that path is cheap and already exists, the
value takes the **ephemeral** floor (§1.2) — persistence buys nothing but machinery and failure modes. If loss is
expensive or unrecoverable (the only copy of a fact; a projection that is costly to rebuild and read-hot during the
rebuild), the value earns a **durable** tier (Graft, §1.4 — or Postgres, the relational SoR, outside this menu). This
is the auth-flow §3.3 ruling stated generally: *a session is the one record where re-handshake < persistence.*

### §2.2 · Axis 2 — mutability: immutable → `:none`; mutable → `:broadcast` | `:tracking`

If the decision lands on the near-cache tier (§1.1), the second axis is **does the value change after it is cached?**
An entity **immutable for the cache's life** takes `coherence: :none` — there is no second version, so there is nothing
to invalidate (the as-built `:cm_games` / `:cm_emojisets` rationale). A **mutable** entity must NOT take `:none` — a
stale L1 row is a correctness (for an auth row, a *security*) defect (auth-flow synthesis §3.1: a revoked `SES`
surviving in a holder's L1 keeps authenticating). A mutable near-cache picks between `:broadcast` (BCS-idiomatic,
app-level, writer-published; accepts a named one-TTL staleness bound on a lost message) and `:tracking` (server-pushed,
writer-independent, fires on the write itself; pays a cross-language cost). **The mode is a property of the data's
mutability and the staleness it can tolerate — surface it as a fork only when both modes are credible (a security
revocation is the case that pulls toward `:tracking`).**

### §2.3 · Axis 3 — durability need: ephemeral / restart-survive / cross-region

A refinement of Axis 1 once durability is wanted: **how durable?** Three tiers, increasing cost — **ephemeral**
(Valkey-TTL, re-create on loss; §1.2); **restart-survive** (a Valkey AOF, or a local durable store — the middle ground
the auth-flow synthesis §3.3 named for the `SES` between pure-ephemeral and full Graft); **cross-region / replicated /
recoverable** (Graft → Tigris; §1.4). The auth-flow synthesis kept this an **open Operator fork** for the session
precisely because it is a cost dial, not a code-forced choice — the same dial applies to any record where durability is
wanted but its degree is a trade.

### §2.4 · Axis 4 — size + access pattern: point vs range vs structural-share

The fourth axis matches the *shape* of access to the substrate. **Point** access by branded id → the near-cache
(`:ets.lookup`, §1.1) or a Valkey key. **Range / ordered** access (ranked, scanned, replayed) → a Valkey sorted set
(the as-built leaderboard) or Graft's ordered LSN keyspace (§1.4). **Structural** access (a whole-view projection that
benefits from structural sharing and cheap immutable updates, or a cross-runtime placement contract) → CHAMP (§1.3).
Size matters at the margins: the near-cache is bounded by its declaration (a full table degrades to pass-through); a
CHAMP is in-heap (bounded by the holder's memory); Graft is bounded by the durable store. **A point-by-id, bounded,
read-hot value over a slower SoR is the near-cache's home; a ranked view is a ZSET's; a rebuildable structural
projection is CHAMP's.**

### §2.5 · The framework as one table

| Axis | Question | → ephemeral / `:none` | → `:broadcast` \| `:tracking` | → CHAMP | → Graft (durable floor) |
|---|---|---|---|---|---|
| **1 reconstruct-cost** *(decisive)* | what does loss cost? | cheap to rebuild | (cheap, but mutable) | rebuildable projection | expensive / only copy |
| **2 mutability** | changes after cache? | immutable | **mutable** (the mode fork) | (a projection, re-derived) | — |
| **3 durability need** | how durable? | ephemeral | ephemeral L1 + coherence | in-heap, rebuilt from floor | restart-survive / cross-region |
| **4 size + access** | what shape of access? | point-by-id | point-by-id, mutable | structural / placement-contract | point + ordered LSN + outbox |

---

## §3 · Per-decision application

The framework applied to the known near-cache-in-memory decisions on disk. Each is a **short ruling** where the
as-built or the framework settles it, or a **four-part arm** where a genuine forward fork remains.

### §3.1 · The session (`SES`) — the ANCHOR (ruling + a forward fork surfaced)

**Ruling (settled — auth-flow D-2 / its synthesis §3.3, restated by the framework, not re-litigated here).**
Axis 1 settles it: a session is **the** record where re-handshake < persistence — loss is recoverable by re-running
the handshake that minted it, cheaply, by a path that exists. The cm.4 `SES` tier is therefore **Valkey-TTL
ephemeral** (§1.2): an `EchoStore` entity (kind `SES`) carried on a Valkey key with a TTL, re-minted on loss by
re-handshaking. The cm.4 floor is settled at ephemeral; **this design-ahead does not change it** — it records the
*why* (Axis 1) and frames the forward dial. (Note: by Axis 2 the `SES` is *mutable + revocable*, so its coherence mode
is **not** `:none` — that is the auth-flow §3.1 fork, owned by the cm.4 rung, out of scope here; this document owns
only the **durability** axis for the session.)

**The forward fork — does the `SES` ever warrant a durable tier (Axis 3)?** Surfaced, not resolved — the auth-flow
synthesis §3.3 left exactly this open.

- **Arm SES-EPH — stay ephemeral (the floor; the framework's answer).**
  - **Rationale.** Axis 1 is decisive and points one way: re-handshake < persistence is true for a session *for its
    whole life*, not just at the floor. Persisting it buys survival of a Valkey restart at the cost of the durable
    machinery — for a record whose loss is a cheap re-handshake.
  - **5W.** *Why:* loss is design-accepted and cheap. *What:* a Valkey-TTL `SES`, re-minted on loss. *Who:* the cm.4
    handshake (the sole mint — auth-flow synthesis §2) + every reader (Phoenix, the forward Go edges, LiveView).
    *When:* the cm.4 floor (now). *Where:* a Valkey key (`ecc:{sessions}:<SES>`) — no Graft Volume.
  - **Steelman.** A session has a short TTL anyway; a Valkey restart is rare; the worst case is a wave of
    re-handshakes, each cheap and already-built. Zero new durable surface to test or operate. This is the steward's
    own "do no harm" — the smallest mechanism that meets the need.
  - **Steward.** Costs nothing to keep — no Volume, no fold, no fence. Ages well: the cm.4 floor already is this. The
    only debt is the named loss event (a Valkey restart re-handshakes every live session at once) — bounded and
    cheap, but real under a thundering-herd at restart.
- **Arm SES-AOF — restart-survive via a Valkey AOF (the middle; auth-flow §3.3's middle tier).**
  - **Rationale.** If the re-handshake-storm-at-restart is judged too costly operationally, a Valkey AOF makes the
    `SES` survive a *Valkey* restart without any Graft machinery — the cheapest durability that removes the storm.
  - **5W.** *Why:* avoid the restart re-handshake storm. *What:* the same Valkey `SES`, with AOF on. *Who:* the same
    consumers, unchanged. *When:* a forward rung if the storm is observed. *Where:* a Valkey config (engine-level),
    not codemojex code.
  - **Steelman.** Survives the common failure (a Valkey bounce) with a config flag, no new code, no new tier in the
    tree. The session contract is byte-identical; only the engine's persistence changes.
  - **Steward.** An engine-level config the codemojex node already could carry — but it durabilizes *every* Valkey
    key (the bus, the board, the L2), not just the `SES`, so its cost lands on the whole hot half (write amplification
    on a volatile keyspace whose whole point is rebuildability). A blunt instrument for one record.
- **Arm SES-GRAFT — Graft-back the session (over-durable; auth-flow §3.3 explicitly flags this).**
  - **Rationale.** If "backed by echo-persistence" (the auth-flow G7 clause) is read *hard* — every session
    durably replicated — Graft is the substrate. Surfaced for completeness; the lens docs and the framework both
    rate it over-durable.
  - **5W.** *Why:* a hard durability mandate. *What:* a `SES` Graft Volume. *Who:* the handshake writer + a Graft
    reader. *When:* a forward rung, only if G7 is hard. *Where:* a Graft Volume + the Committer in the tree.
  - **Steelman.** Cross-region recoverable sessions; a session survives a total node loss. The fullest durability the
    menu offers, with the as-built engine.
  - **Steward.** **Over-durable for the data** (auth-flow §3.3, both lenses) — it pays the OCC-fence, the CubDB
    store, the Tigris fold, and a single-writer Volume to durabilize a record whose loss is a cheap re-handshake.
    The highest freeze + test + operate cost in the menu for the least-justified record. An anti-pattern *here*,
    valuable elsewhere.
  - **CHOSEN-AGAINST (recorded for the surface):** the framework's Axis 1 disqualifies Graft for a session before
    the arm is argued — re-handshake < persistence — so SES-GRAFT is on the table only to honor the G7-hard reading.

**Surface (advice, not a decision).** The framework's answer is **SES-EPH** (Axis 1 decisive: re-handshake <
persistence, for the session's whole life, not just at the floor). If the restart re-handshake storm is judged a
real operational cost, **SES-AOF** is the cheapest mitigation that removes it *without* a new code tier — but it
durabilizes the whole volatile keyspace, so its cost is broader than the `SES`. **SES-GRAFT is over-durable** and
on the table only if G7 is read hard. The Operator (with VenusPG, who owns the auth-flow §3.3 surface) rules.

### §3.2 · `:cm_games` (`GAM`) / `:cm_emojisets` (`EMS`) — CONFIRM the as-built pattern (ruling)

**Ruling (settled — the framework confirms the as-built).** Both are **near-cache (§1.1) with `coherence: :none`**,
TTL'd, Valkey-L2-backed, Postgres-loader — exactly as `Codemojex.Tables` declares them. The framework confirms each
axis: Axis 1 — cheap to rebuild (the loader re-reads Postgres); Axis 2 — **immutable for the cache's life** (a game
and its secret, an emoji set's layout, are fixed at game open and never rewritten), so `:none` is correct, not a
defect — there is no second version to invalidate (the design-doc §Storage-tiers rationale: "both entities are
immutable for the game's life, coherence is `:none` and the cache never goes stale"); Axis 3 — ephemeral L1 over a
durable Postgres SoR (no durability of its own needed); Axis 4 — point-by-id, read-hot on the scoring path, bounded
by the table declaration. **No fork** — the as-built is the framework's answer. (One forward note, not a fork: the
`:erlang.term_to_binary` loaders are BEAM-only; a cross-runtime reader of these caches would need a JSON loader, the
auth-flow §2 lesson — but no such reader is planned for the immutable game caches, so this stays a note.)

### §3.3 · The CHAMP leaderboard projection (`Codemojex.Leaderboard` / `EchoData.ChampServer`) — a forward fork, NOT a confirmed live fit

**Reconcile finding (the plan-map drifts — re-probe on disk).** The directive asked to *confirm the CHAMP fit* for
the leaderboard. On disk the picture is more precise, and the precision is the finding:

- The **live** leaderboard is `Codemojex.Board`
  ([`echo/apps/codemojex/lib/codemojex/board.ex`](../../../../echo/apps/codemojex/lib/codemojex/board.ex)) — a
  **Valkey sorted set** per game (`ZADD` on score in `record/3`, `ZREVRANGE … WITHSCORES` in `top/2`, keyed
  `cm:{game}:board`) plus a HASH best-of fold. This is the leaderboard the scoring hot path writes and reads.
- `EchoData.ChampServer` **is** supervised under the name `Codemojex.Leaderboard`
  ([`application.ex:46`](../../../../echo/apps/codemojex/lib/codemojex/application.ex)), and `EchoData.ChampView`
  ([`champ_view.ex`](../../../../echo/apps/echo_data/lib/echo_data/champ_view.ex)) is the hydrate seam
  (`rebuild_server/3` ← `from_volume/3`, folding a **Graft** Volume's pages).
- **But:** no `Codemojex.Leaderboard` *module* exists on disk; nothing *writes* the CHAMP projection; nothing *reads*
  it (the name `Codemojex.Leaderboard` appears **once** in the codemojex tree — the start spec at `application.ex:46`).

So the design-doc framing is *literally* accurate — "a separate in-memory CHAMP projection (`Codemojex.Leaderboard`)
is **available** as a rebuildable view" (`codemojex.design.md` §The systems / §Fault tolerance) — but the projection
is a **supervised-but-unfed forward scaffold**: the `ChampServer` process is up, the `ChampView` rebuild seam exists,
and its documented rebuild source is **Graft** (itself optional). It is *not* the live board, and the CHAMP fit is
therefore **not** something to "confirm" as as-built — it is a forward decision to surface.

**The forward fork — does the leaderboard ever warrant the CHAMP projection (i.e. feed and read it)?** A genuine
fork; surfaced, not resolved.

- **Arm LB-ZSET — the Valkey ZSET is the leaderboard, full stop (retire the unfed scaffold or leave it dormant).**
  - **Rationale.** The ZSET already *is* a ranked structure with server-side `ZADD`/`ZREVRANGE` — the exact range/ordered
    access the leaderboard needs (Axis 4). It is durable-enough (rebuildable from Postgres `guesses`), already wired,
    already read by `top/2`. A CHAMP projection that nothing feeds or reads is dead weight.
  - **5W.** *Why:* the ZSET meets every access need at server speed. *What:* the per-game sorted set, as built. *Who:*
    the scoring `ScoreWorker` (writes via `Board.record/3`), the view layer (reads via `Board.top/2`). *When:* now
    (live). *Where:* Valkey (`cm:{game}:board`).
  - **Steelman.** A sorted set is *the* canonical Redis/Valkey leaderboard — O(log N) insert, O(log N + K) top-K, all
    server-side, no read-modify-write beyond the best-of fold. It is rebuildable from the durable `guesses` table, so
    its volatility is design-accepted (Axis 1: cheap to rebuild). The CHAMP projection adds a second representation to
    keep coherent for no read it currently serves — pure liability.
  - **Steward.** Zero new surface; the ZSET is already frozen by use. The only debt is the **unfed scaffold** —
    `Codemojex.Leaderboard`/`ChampServer` is in the tree doing nothing, and the design doc *implies* a feature that is
    not wired. This is a **do-no-harm cleanliness fork to surface to the Operator**: either (a) retire the unfed
    `ChampServer` start + the design-doc "available" claim, or (b) keep it as an explicit forward scaffold with a
    `[FORWARD]` marker so the gap is honest. (Spec-hygiene call — Venus surfaces, the Operator rules.)
- **Arm LB-CHAMP — feed and read the CHAMP projection (an in-heap structural view beside the ZSET).**
  - **Rationale.** Axis 4's *structural* case: if the leaderboard grows a need for a **whole-view, cross-runtime, or
    instrumented** projection (e.g. a Go edge that must read the ranked view with the same trie placement, or a
    snapshot-and-diff of the whole board), CHAMP is the substrate the catalog points to — structurally shared, cheap
    immutable updates, a placement contract, rebuilt from Graft.
  - **5W.** *Why:* a structural/cross-runtime read the ZSET does not serve. *What:* a fed `ChampServer` projection,
    rebuilt via `ChampView.from_volume/3`. *Who:* a forward reader (a Go edge, a whole-board snapshot consumer) —
    **named, not invented** (no such reader exists today). *When:* a forward rung, only on a concrete structural need.
    *Where:* `Codemojex.Leaderboard` (the ChampServer) + a writer that mirrors `Board.record/3` + a Graft Volume to
    rebuild from.
  - **Steelman.** Structural sharing makes a whole-board snapshot cheap; the cross-runtime placement contract
    (`BrandedChamp`'s reason-for-being per its moduledoc) lets a non-BEAM consumer read the *same* trie shape; rebuild
    from Graft gives a durable rebuild source. For a *structural* leaderboard read, this is the catalog's right tier.
  - **Steward.** **A second representation to keep coherent** — every `Board.record/3` would have to also feed the
    CHAMP, or the projection drifts; and the documented rebuild source is **Graft**, which is optional (`:graft_volume`
    may be unset), so the rebuild path is conditional on a tier that may not be in the tree. High coherence + freeze
    cost for a read that **has no consumer today** (`BrandedMap` is even the default over `BrandedChamp` unless the
    placement contract is real — moduledoc). Pays for itself **only** when a concrete structural/cross-runtime reader
    exists.
  - **CHOSEN-AGAINST (recorded):** the catalog's Axis 4 routes *structural* reads to CHAMP, but the leaderboard's
    *current* access is **range/ordered** (top-K), which the ZSET already serves — so LB-CHAMP waits on a structural
    read that does not exist yet.

**Surface (advice, not a decision).** Today the framework's answer is **LB-ZSET** — the leaderboard's access is
range/ordered (top-K), which the Valkey sorted set serves at server speed, rebuildable from Postgres (Axis 1 + Axis 4
both point to the ZSET). **LB-CHAMP waits on a concrete structural / cross-runtime reader** that does not exist today;
until one does, `BrandedMap`-vs-`BrandedChamp` does not even arise. The **near-term action is the cleanliness fork in
LB-ZSET's Steward**: the `Codemojex.Leaderboard`/`ChampServer` scaffold is supervised-but-unfed and the design doc
reads as if it were a live feature — the Operator should rule whether to mark it `[FORWARD]` or retire it. The
Operator rules.

### §3.4 · Forward near-cache-in-memory decisions identified (scan)

A sweep of the codemojex tree for *other* in-memory-state holders that could become near-cache-in-memory decisions
(`grep` for `EchoStore.Table` / `BrandedChamp` / GenServer state / ETS): the only in-memory tiers are the two
EchoStore tables (§3.2), the (unfed) CHAMP leaderboard (§3.3), and the `Codemojex.Bus` connector
(`:persistent_term`-held — a connection, not a cache). `Codemojex.Store` is a thin Postgres facade (no cache);
`Codemojex.Cache` is the read wrapper over the EchoStore tables (§3.2). **No other selectable near-cache-in-memory
decision exists today.** Two forward candidates, named so the framework is ready for them (not designed):

- **A mutable near-cache table (the first one after the `SES`).** When a *mutable* entity wants a near-cache (a
  player profile/balance view, a room-state cache), Axis 2 forces the coherence-mode fork (`:broadcast` vs
  `:tracking` — §2.2) — the auth-flow §3.1 fork generalized. Surface the mode fork at that rung; the framework is
  ready.
- **A durable-page tier for codemojex state beyond Postgres.** If a future decision wants codemojex state to rest on
  the Graft floor (cross-region, replicated, at-least-once-fed) — e.g. the documented-but-optional `:graft_volume`
  becoming load-bearing — Axis 3 routes it to Graft (§1.4). This is the design doc's "optional durable floor" made
  load-bearing; a forward rung, surfaced when the cross-region/recoverable need is concrete.

---

## §4 · Consolidated rulings & forks (for the Operator)

| Decision | Framework verdict | Status |
|---|---|---|
| **`SES` durability** (§3.1) | **ephemeral** (Axis 1: re-handshake < persistence) | **ruling** + a forward dial fork (EPH / AOF / Graft) — Operator, with VenusPG (auth-flow §3.3) |
| **`:cm_games` / `:cm_emojisets`** (§3.2) | **near-cache, `coherence: :none`** (immutable, point-by-id, cheap rebuild) | **ruling — confirms the as-built**; no fork |
| **CHAMP leaderboard** (§3.3) | **LB-ZSET today** (range/ordered access → the live Valkey sorted set); LB-CHAMP waits on a structural reader | **forward fork** + a **cleanliness fork**: the `ChampServer` scaffold is supervised-but-unfed and the design doc reads as live — mark `[FORWARD]` or retire (Operator) |
| **Forward near-caches** (§3.4) | a mutable table forces the §2.2 mode fork; a durable-page need routes to Graft (§2.3) | **named, not designed** — the framework is ready |

**Two surfaced forks the Operator owns** (neither blocks the cm.4 floor):
1. **The `SES` durability dial** (§3.1) — EPH (the framework's answer) / AOF (cheapest restart-survive, but blunt) /
   Graft (over-durable; only if G7 is hard). This is the same fork the auth-flow synthesis §3.3 left open; this
   document frames it with the general reconstruct-cost axis.
2. **The CHAMP-leaderboard cleanliness fork** (§3.3) — the supervised-but-unfed `Codemojex.Leaderboard`/`ChampServer`
   and the design-doc "available as a rebuildable view" claim outrun the wiring (no writer, no reader, rebuild source
   = optional Graft). Mark it `[FORWARD]` or retire it — a spec-hygiene call, surfaced not decided.

---

*Persistence-pattern design-ahead (D-3), single-architect forward-vision. Grounded on the as-built `echo/apps/**`
tree (every pattern cites a `file:method`; the `SES`/Go-edge surfaces are forward-tense, the CHAMP-leaderboard gap is
a reconcile finding). The cm.4 session floor is settled at Valkey-TTL ephemeral (auth-flow D-2) — this document
records the why and frames the forward forks; it changes no floor. The architect surfaces; the Operator rules.*
