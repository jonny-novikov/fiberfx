# BCS · content reference map — course page ↔ manuscript source

> The grounding bijection for the **B3 chapter** (`/bcs/bus`) and the **B4 chapter** (`/bcs/cache`): every course
> page (chapter landing · module hub · dive) mapped to its **manuscript chapter** under `content/`, the
> **committed rung record** it quotes, the exact
> **gate/figure lines** it carries verbatim, and the **vetted Sources** (numbered against
> [`content/bcs.references.md`](content/bcs.references.md), the consolidated bibliography). Built from the
> manuscript directly; every figure below was re-read in its named source. Pairs with the spec triad
> ([`specs/bcs.3.specs.md`](specs/bcs.3.specs.md) — the dive partition) and the verified grounding bank
> ([`specs/bcs.3.llms.md`](specs/bcs.3.llms.md) — the figures quoted whole). **Nothing here is invented; nothing
> under `content/` is editable by course authoring.**
>
> Convention — a page's grounding is exactly its row: it may quote only figures present in the named manuscript
> file or rung record, and it cites only the listed Sources. The rung record is quoted **verbatim** in a
> source-labelled `figure.frozen` block on each hub; dives quote the slice they teach.

## Reference families (the closed citation set, per `content/bcs.references.md`)

| # | Source | URL | Engine/topic |
|---|---|---|---|
| 25 | Valkey — Sorted sets | `https://valkey.io/topics/sorted-sets/` | same-score lex family as a generic index; the score-zero caveat |
| 26 | Valkey — ZRANGE | `https://valkey.io/commands/zrange/` | `REV` + `BYLEX`; equal-score lexicographic order |
| 27 | Valkey — Programmability | `https://valkey.io/topics/programmability/` | atomic script execution (effects all-or-nothing); declared keys |
| 15 | Kleppmann — How to do distributed locking | `https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html` | the fencing-token argument the `attempts` counter satisfies |
| 28 | Valkey — Replication | `https://valkey.io/topics/replication/` | scripts replicate by effects; time frozen during a script (`TIME` is sound) |

## B3 · The Bus — the page-to-source map

### Chapter landing — `/bcs/bus` (built)

| Page | Manuscript | Rung | Carries (verbatim) |
|---|---|---|---|
| `bus/index.html` | `content/bcs3.md` (Part III preface) | the seven records' headline counts | six laws of the part; the 7-module arc; the evidence table (`5/5 · 5/5 · 6/6 · 8/8 · 6/6 · 6/6` + `CONFORMANCE 14/14` + connector `PASS 8/8`) |

### B3.1 `fence-and-keyspace` — `/bcs/bus/fence-and-keyspace/*` (built)

Manuscript `content/bcs3.1.md`; rung `bcs_rung_3_1_check.out` (`PASS 5/5`, F1–F5). Sources: #23 Protocol spec,
#24 Cluster spec. (Recorded for completeness; built in the prior wave.)

### B3.2 `jobs-are-entities` — `/bcs/bus/jobs-are-entities/*` — manuscript `content/bcs3.2.md` · rung `bcs_rung_3_2_check.out` (`PASS 5/5`)

Sources for **every** B3.2 page: **#26 ZRANGE** · **#25 Sorted sets**. Related (internal): `/bcs/bus` (chapter
landing), `/bcs/elixir-core/property-stores` (stores), `/echomq` · `/redis-patterns` · `/elixir` (doors).

| Page | Manuscript §(s) | Rung lines | Figures / phrases quoted verbatim |
|---|---|---|---|
| **hub** `index.html` | the chapter's framing (Why · What intro · Decisions) | `boot` + `PASS 5/5` (whole record in the hub `figure.frozen`) | "the registry grows by one — JOB, work as a kind with identity and lifecycle"; the five J-gates named; the chapter thesis "idempotency … is *definitionally* identity" |
| **dive 1** `the-job-row` | What §"The row", §"The pending set" | `boot`, `J1` | the three-field hash `state` / `attempts` / `payload`, "deliberately nothing more. No `enqueued_at` field exists because the two-clocks law already placed that fact"; surface `enqueue, browse, pending_size` — "scripts and key shapes are nobody's business"; pending = score-zero zset, members are the ids, "the FIFO … the browse index … the time-range index" |
| **dive 2** `enqueue-one-script` | What §"Enqueue, one script", §"The wire class, discovered live"; How (Elixir) | `J2`, `J3` | the ten-line enqueue Lua **quoted whole**; "Policy before existence before write"; `J2` — "first call enqueued, second answered duplicate, the row untouched and pending holds 1"; `J3` — "an ORD id in the job position answers EMQKIND on the wire — the key let it pass, the law did not"; the client-side `{:error, {:server, "EMQKIND" <> _}} -> {:error, :kind}` match |
| **dive 3** `the-orders-dividend` | What §"The pending set" (J4), §"Idempotency and cargo" (J5) | `J4`, `J5` | `J4` — "the last five minted in reverse mint order; the very first job sits at the head; 301 pending, no second index anywhere"; `J5` — "the payload carries `ORD0Nt6z93U3dY` and a quantity, never a row — decoded and re-parsed on the far side of the wire" |

Decisions to teach (from `bcs3.2.md` §Decisions): **D-10** the registry grows by `JOB` · policy before existence
before write · `duplicate` is a success shape · refusals carry their own wire class · **pending stays score-zero
forever** — "3.3's schedule is a *separate* sorted set" (the pre-stated plan B3.3 inherits). Files cited:
`runtimes/elixir/lib/echo_mq/jobs.ex`.

### B3.3 `state-machine` — `/bcs/bus/state-machine/*` — manuscript `content/bcs3.3.md` · rung `bcs_rung_3_3_check.out` (`PASS 6/6`)

Sources for **every** B3.3 page: **#27 Programmability** · **#15 Kleppmann** · **#28 Replication**. Related
(internal): `/bcs/bus`, `/bcs/elixir-core/otp-application` (supervision/leases), the three doors.

| Page | Manuscript §(s) | Rung lines | Figures / phrases quoted verbatim |
|---|---|---|---|
| **hub** `index.html` | the chapter's framing (Why · What intro · Decisions) | `L1` + `PASS 6/6` (whole record in the hub `figure.frozen`) | the surface delta — "claim, complete, retry, promote, reap join enqueue, browse, pending_size — five new verbs, every transition one script"; four states / four transitions / two pumps; "`attempts` … is also the fencing token every other transition verifies" |
| **dive 1** `claim-the-token-mint` | What §"The keys, completing 3.1's map", §"Claim, the token mint"; `L1`, `L2` | `L1`, `L2` | the claim Lua **quoted whole** (`ZPOPMIN` / `HINCRBY` / `HSET` / `TIME` / `ZADD`, returns `{id, payload, att}`); `L2` — "claim hands out the oldest job with a server-clock lease and fencing token 1; complete with the right token retires the row — nothing remains"; the four sets + score semantics (pending score-zero · active by lease deadline · schedule by run-at · dead score-zero) |
| **dive 2** `the-fencing-token` | What §"The fence, performing", §"Two lives, one counter"; How (verification half) | `L3`, `L4` | `L3` — "a stale token is refused on the wire: EMQSTALE; the lease holder's work survives the zombie's complete" (token 99 vs token 1); `L4` — "retry parks the job in the schedule, promote moves the due back to pending, and the next claim hands token 2 — one job, two lives, one counter"; the verify Lua `EMQSTALE complete token mismatch` + `{:error, {:server, "EMQSTALE" <> _}} -> {:error, :stale}`; Kleppmann's monotonic-token argument |
| **dive 3** `the-morgue-and-the-reaper` | What §"The morgue and the reaper"; Decisions §"Completion deletes" | `L5`, `L6` | `L5` — "attempts 2 against max 2 is the morgue: state dead, last_error kept, and the dead set browses in mint order like everything else"; `L6` — "a 40 ms lease expires unanswered; reap returns the orphan to pending and the next claim holds token 2 — crash recovery is one zset scan on the server's clock"; completion deletes (the receipt is 3.5's business — pre-state, living status for 3.5) |

Decisions to teach (from `bcs3.3.md` §Decisions): the server clock owns leases · **`attempts` is the fencing
token** ("a second token field would be a second authority") · one constructed key, sanctioned by grammar ·
`EMQSTALE` joins `EMQKIND` · completion deletes. Boundaries to teach honestly: no lease extension yet; reap caps
at one hundred per call; backoff lives above the wire ("Lua is the wrong home for judgment"). Files:
`runtimes/elixir/lib/echo_mq/jobs.ex` (five `Script.new` constants).

### B3.4–B3.7 (module-level — not in this wave)

| Module | Slug | Manuscript | Rung | Sources (#) |
|---|---|---|---|---|
| B3.4 | `fair-lanes` | `bcs3.4.md` | `bcs_rung_3_4_check.out` `PASS 8/8` (G1–G8) | 34 LMOVE · 29 BLPOP · 7 Nagle · 31 DRR · 30 Modules-blocking |
| B3.5 | `bus-meets-stores` | `bcs3.5.md` | `bcs_rung_3_5_check.out` `PASS 6/6` (B1–B6) | 32 Helland · 17 OTP supervisor |
| B3.6 | `conformance` | `bcs3.6.md` | `bcs_rung_3_6_check.out` `PASS 6/6` + `CONFORMANCE 14/14` | 35 Oban · 36 PG async commit · 37 PG NOTIFY · **D-B3.3: asymmetry line travels with any rival figure** |
| B3.7 | `the-connector` | `bcsA.md` (Appendix A) | `emq_connector_check.out` `PASS 8/8` | 23 Protocol spec · 20 Valkey 8.1.0 GA |

## B4 · EchoCache — the page-to-source map (built: landing + B4.1–B4.4)

Reference families added for B4 (per `content/bcs.references.md`): **16** OTP `ets`
`https://www.erlang.org/doc/apps/stdlib/ets.html` · **38** Valkey SET `https://valkey.io/commands/set/` · **39**
Valkey EXPIRE `https://valkey.io/commands/expire/` · **40** Go `x/sync` singleflight
`https://pkg.go.dev/golang.org/x/sync/singleflight` · **41** Valkey Pub/Sub
`https://valkey.io/topics/pubsub/` · **42** Valkey client-side caching
`https://valkey.io/topics/client-side-caching/` · **4** Lamport 1978
`https://dl.acm.org/doi/10.1145/359545.359563` · **43** Fowler LMAX `https://martinfowler.com/articles/lmax.html`
· **44** Disruptor paper `https://lmax-exchange.github.io/disruptor/disruptor.html` · **45** OTP `atomics`
`https://www.erlang.org/doc/apps/erts/atomics.html` · **46** Richardson outbox
`https://microservices.io/patterns/data/transactional-outbox.html` · **47** SQLite WAL
`https://www.sqlite.org/wal.html` · **48** Litestream `https://litestream.io/how-it-works/`.

| Module · route | Manuscript | Rung | Dives (gates) | Sources (#) · priced pairs (D-B4.5) |
|---|---|---|---|---|
| landing `/bcs/cache` | `bcs4.md` (Part IV preface) | the four `PASS 6/6` records' counts | — | 16 · 42 · 4 |
| **B4.1** `cache-aside` | `bcs4.1.md` | `bcs_rung_4_1_check.out` `PASS 6/6` (E1–E6) | declared-not-discovered (E1–E2) · one-fill-per-herd (E3–E4) · the-jittered-clock (E5–E6) | 16 · 38 · 39 · 40 · **762 ns ↔ 31 µs (E4)** |
| **B4.2** `coherence-by-mint-time` | `bcs4.2.md` | `bcs_rung_4_2_check.out` `PASS 6/6` (F1–F6) | the-twenty-nine-bytes (F1–F2) · the-broadcast-lane (F3–F4) · the-job-lane (F5–F6) | 41 · 42 · 4 · **72 µs ↔ 148 µs (F6)** |
| **B4.3** `single-writer-ring` | `bcs4.3.md` | `bcs_rung_4_3_check.out` `PASS 6/6` (G1–G6) | two-sequences-one-table (G1–G2) · occupancy-and-the-bound (G3–G4) · the-storm-drill (G5–G6) | 43 · 44 · 45 |
| **B4.4** `the-lane-that-remembers` | `bcs4.4.md` | `bcs_rung_4_4_check.out` `PASS 6/6` (H1–H6) | two-memories-one-file (H1–H2) · the-bus-dies-the-lane-replays (H3–H4) · coverage-and-the-price (H5–H6) | 46 · 47 · 48 · **148 µs ↔ 524 µs (H6)** |
| **B4.5** `cache-referee` | *`bcs4.5.md` UNWRITTEN* | *none* | *fixed when the chapter ships* | *manuscript pending (D-B4.2) — no comparative figure exists; a `planned` card only, no hub, no dives* |

**B4 invariants honored:** the four rung records (incl. `header` + `derive` lines, D-B4.3) quoted whole on each
hub; the three priced pairs travel together (D-B4.5); B4.5 / Litestream / the comparison set (Nebulex · Cachex ·
Valkey-tracking) in living-status voice only — **no comparison-set measurement invented** (D-B4.2).

## B8 · The Trading System — the page-to-source map (built: landing + B8.1–B8.2)

**Two-layer grounding (the B8 rule, BCS.8-INV1/INV2).** The line is between the **substrate** and the **trading
consumer**. (1) The substrate is **real, shipped, actively-hardened source** — `EchoCache.{Ring, Table, Journal,
Coherence, Shadow, Litestream}` (`echo/apps/echo_cache/lib/echo_cache/`), the EchoMQ bus
(`echo/apps/echo_mq/lib/echo_mq/`: `Jobs · Lanes · Consumer · Conformance · …`), `EchoWire`, the canon `EchoData`
— carrying committed BCS records (quoted verbatim, source-labelled) AND a live rung-gated hardening program
(`docs/echo_mq/emq.roadmap.md`, three movements; `emq.0` shipped, `emq.1` ratified). Taught present-tense, with
the umbrella source path. (2) The **trading consumer** — `Exchange.*` / `Trading.Ledger` (no source yet) — is
**PROPOSED**, the roadmap's "named consumer standing on this tree," taught in living-status voice. **No platform
figure invented:** the only numbers are an as-built committed figure (source-labelled) or an attributed external
figure (LMAX). Design corpus `docs/exchange/`; spec of record: [`specs/bcs.8.specs.md`](specs/bcs.8.specs.md).

> **The Exchange Platform — now being built real (`docs/exchange/`).** The capstone's PROPOSED `Exchange.*` consumer is
> the spec of a system the [Exchange Platform](../../exchange/) (renamed from the trading corpus, `trd.*` codename kept)
> now ships rung by rung on this same as-built tree. The patterns B8 teaches as design are the patterns it builds:
> **parse-don't-validate at the edge** (`Exchange.Gateway`, rung `trd.1.1` — `docs/exchange/trd.1.1.specs.md`), the
> **Disruptor seat** on the as-built `EchoCache.Ring`, the pure **Decider**, money as `{units, nano}` integers (never a
> float), and the **branded id as the venue idempotency key**. As each rung lands, the matching B8 module's consumer can
> retire its living-status hedge for a built reference.

Sources (the closed set, all in the vetted registry): **43** Fowler LMAX `https://martinfowler.com/articles/lmax.html`
· **44** Disruptor paper `https://lmax-exchange.github.io/disruptor/disruptor.html` · **13** Chassaing Decider
`https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider` (B8.3 adds **31** DRR-adjacent
fairness and Bailey et al. on backtest overfitting when built).

| Module · route | Design grounding (PROPOSED) | As-built floor (committed, verbatim) | Dives | Sources (#) |
|---|---|---|---|---|
| landing `/bcs/trading` | `trading.md` (the three shapes, the master invariant), `trading.roadmap.md` (milestones A/B/C) | lanes `bcs3.4` `PASS 8/8` · cache/ring/journal `bcs4.1/4.3/4.4` `PASS 6/6` · `bcs_hash_audit.out` `PASS 4/4` | — | 43 · 44 · 13 |
| **B8.1** `engine` ✓ | `trading.patterns.md` (the Decider + the Disruptor), `trading.specs.md` (the Disruptor seat, the pure book) | `EchoCache.Ring` — **`echo/apps/echo_cache/lib/echo_cache/ring.ex`** (`publish/2`→`:ok`/`:dropped`, `occupancy/1`, `stats/1`, the moduledoc) + record `bcs4.3.md` / `bcs_rung_4_3_check.out` `PASS 6/6` (`64 accepted, 136 refused`, `600 of 4096`, `1005116 items/s`, `capacity 512`) | the-disruptor-seat · the-decider · price-time-by-mint-order | 43 · 44 · 13 |
| **B8.2** `log-and-ledger` ✓ | `trading.specs.md` (the log, the regulated ledger), `trading.roadmap.md` (TRD.3, TRD.5); PROPOSED `Trading.Ledger` + `Exchange.Projection` | `EchoCache.Journal` + `Shadow` + `Litestream` — **`echo/apps/echo_cache/lib/echo_cache/{journal,shadow,litestream}.ex`** + record `bcs4.4.md` / `bcs_rung_4_4_check.out` `PASS 6/6` (`143`/`524`/`148 µs`, `50 of 50`, `30 uncovered`, `:remembered_stale`) | the-journal-and-the-shadow · replay-equals-live · the-double-entry-ledger · **524 µs ↔ 148 µs (H6, D-B4.5)** | 46 · 47 · 48 |
| **B8.3** `strategies` | `trading.strategies.md` (the seven strategy patterns) | the lanes' kill switch `bcs3.4`; Tables `bcs4.1`; the claims bus `bcs4.2` + Appendix G | the-strategy-is-a-decider · risk-and-the-kill-switch · the-backtest-is-the-system-replayed | *built next* |
| **B8.4** `scale-out` | `trading.specs.md` (the bus/claims, placement & partitions), `trading.roadmap.md` (TRD.4/6/7/8) | `Coherence` `bcs4.2`; the claim check Appendix G (`bcsG.md`); `bcs_hash_audit.out`; the connector referee Appendix H (`bcsH.md`) | claims-only-on-the-bus · placement-by-the-audited-hash · cp-ap-on-partition | *built next* |

**B8.1–B8.2 honored:** the as-built records quoted verbatim (source-labelled; B8.1's G1 elided with a marked `…`;
B8.2's whole `bcs_rung_4_4_check.out` incl. `derive` lines on the hub); the substrate taught **present-tense with
the live umbrella source paths** (`echo/apps/echo_cache/lib/echo_cache/ring.ex`, `journal.ex`, `shadow.ex`,
`litestream.ex` — the `publish/2`/`occupancy/1`/`stats/1` surface + the Ring moduledoc verified verbatim) and the
EchoMQ hardening pledge (`docs/echo_mq/emq.roadmap.md`) named; the LMAX *"6 million orders per second on a single
thread"* carried with its Fowler attribution; B8.2's priced pair `524 µs ↔ 148 µs` travels together (D-B4.5).
Only the **trading consumer** (`Exchange.Book/Decider/OrderBook/Gateway/Projection`, `Trading.Ledger`) reads as
PROPOSED — **no platform latency/throughput/fill/posting number asserted** (BCS.8-INV2); those modules are design
objects, never linked as routes. (Recalibrated 2026-06-13 per the Operator: the substrate is as-built + hardened,
not "proposed" — the over-hedges on B8.1 were corrected and the grounding discipline sharpened.)

---

Index: [`bcs.md`](bcs.md) · TOC: [`bcs.toc.md`](bcs.toc.md) · Roadmap: [`bcs.roadmap.md`](bcs.roadmap.md) ·
Specs: [`specs/bcs.3.specs.md`](specs/bcs.3.specs.md) · [`specs/bcs.4.specs.md`](specs/bcs.4.specs.md) ·
[`specs/bcs.8.specs.md`](specs/bcs.8.specs.md) · Exchange Platform: [`../../exchange/`](../../exchange/) ·
Banks: [`specs/bcs.3.llms.md`](specs/bcs.3.llms.md) · [`specs/bcs.4.llms.md`](specs/bcs.4.llms.md) ·
Bibliography: [`content/bcs.references.md`](content/bcs.references.md)
