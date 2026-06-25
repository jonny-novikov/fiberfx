# bcs-writer — the canon digest (chapter map · figure inventory · door map · numbering)

The cross-course reference for grounding `/redis-patterns` and `/echomq` pages in the new BCS manuscript
(`docs/echo/bcs/bcs.N.md`). Read it after the [SKILL](../SKILL.md). The manuscript body is authoritative; this digest
maps where each figure lives and how the three numbering schemes line up.

## 1. The manuscript — B0–B8, all built (the figure homes)

| Ch | File | Course route | Grounds (cite figures from here) |
|---|---|---|---|
| B0 | `bcs.0.md` | `/bcs/overview` | the one relocation; **the branded-id vectors** (`placement("USR0KHTOWnGLuC")=234878118`); the stack + the floor |
| B1 | `bcs.1.md` | `/bcs/ideas` | the system substrate; the identity contract read as architecture; ECS → BCS |
| B2 | `bcs.2.md` | `/bcs/elixir-core` | the law on OTP: `EchoData.Bcs.{PropertyStore,Supervisor,EdgeStore,Archetypes,gate}`, the CHAMP forest, `application.ex` self-check (the **id vectors** again) |
| B3 | `bcs.3.md` | `/bcs/bus` | **EchoMQ** Valkey-native: the `emq:{q}:` keyspace, jobs + lanes, the Stream Tier |
| B4 | `bcs.4.md` | `/bcs/store` | **EchoStore**: the declared near-cache, one-fill-per-herd, coherence by mint time |
| B5 | `bcs.5.md` | `/bcs/persistence` | **the persistence floor**: the single-writer engine, the lazy reader, the portable remote (the `/echo-persistence` narrative) |
| B6 | `bcs.6.md` | `/bcs/together` | the four libraries as one umbrella; one write down, one read up |
| B7 | `bcs.7.md` | `/bcs/codemojex` | **codemojex**: branded systems, rooms + modes, fair-lane guesses, scoring + settlement, the economy, the Phoenix surface |
| B8 | `bcs.8.md` | `/bcs/fly` | production on Fly: the release image, Valkey on a Fly machine, EchoMQ setup, the fly.toml |

> **Numbering collision warning.** `/redis-reconcile` aliases `B<N> → R<N>` (the Operator may write a redis chapter
> as "B1"). In the **bcs-\*** family that alias does **not** apply: `B<N>` always means the **manuscript** chapter
> above (the source you ground IN); a redis chapter is **always** `R<N>`; an echomq chapter is **always** `E<N>`.
> `bcs-reconcile` / `bcs-author` target **R** and **E** only — `B` is the authority, never a reconcile target.

## 2. The branded-id contract (verbatim — the only id figures a page may cite)

A 14-character printable name: **3-char uppercase namespace + 11 Base62** over a 63-bit snowflake
`ts(41) | node(10) | seq(12)`, epoch **`1704067200000`** (2024-01-01). Four properties: **typed** (namespace on the
wire + in the type), **ordered** (text sorts as mint instant), **placed** (`hash32`), **conformant** (one canon
across Elixir · Node · Go · PostgreSQL · WASM). The runtime asserts these at boot (`self_check!`, `branded_id.ex`) —
they are **source truths, not benchmarks**:

```
placement("USR0KHTOWnGLuC")  →  234878118              (native and pure agree)
parse("USR0NgWEfAEJfs")      →  {:ok, "USR", 320636799581945856}
decode("USRzzzzzzzzzzz")     →  :error                 (an overflow is refused, not wrapped)
```

Example ids: `BCS0NtBpC9oGGW` · `USR0KHTOWnGLuC` · `CRS0KHTOWnGLuC`. **No number on an id page is a measurement.**

## 3. The persistence floor (delta 4 — the new tier + the new door)

The durable substrate beneath the volatile tiers (`bcs.5.md`, `bcs.preface.md` §"The floor beneath the boundary"):

- **The four-tier ladder:** ETS head cache (derived, droppable) → Valkey bus + warm L2 → a durable local **page tier
  built twice** (native Elixir **`EchoStore.Graft.*`** on **CubDB** — append-only immutable B-tree, MVCC snapshots;
  Rust twin **`echo_graft`** on **Fjall** — LSM) → **Tigris** remote object storage behind a create-only
  `If-None-Match` commit fence (exactly one writer claims a slot — the same first-claim the leaderboard uses).
- **Durability is a dial:** hold nothing · a bounded in-heap window + a checkpoint per K · commit-per-record +
  replicate off-box. The enqueue hot path touches only a small, mostly-idle **outbox** beside the bus — never a
  database on the path of every dequeue/ack.
- **The commit-LSN loop:** the engine's commit drives the bus; the archive fold drives the engine's commit.
- **Coherence:** `EchoStore.Coherence` is newer-wins where the version **is the 14-byte branded id** (greater id =
  newer) — a cache update is "a message about a name."
- **The comparison:** **Oban** keeps jobs in the same PostgreSQL as the data (a job + a row commit in one
  transaction). Echo separates the bus from the store and buys an in-memory hot path + the dial; it gives up the
  one-transaction coupling. State the trade beside the win — never claim Echo has Oban's coupling.
- **As-built surfaces (real, verified on disk):** `echo/apps/echo_store/lib/echo_store/graft.ex`,
  `graft_backend.ex`, `graft/{committer,divergence,epoch,reader,remote}.ex`; the Rust crate `echo/apps/echo_graft`.
- **The door:** `/echo-persistence` (`html/echo-persistence`, 14 modules) — gate mount
  `--routes-from /echo-persistence=html/echo-persistence`.

## 4. codemojex (delta 3 — the worked consumer)

The live consumer of the same stack (EchoStore + EchoMQ + Postgres), `echo/apps/codemojex`, manuscript **B7**. Brands
the live app mints (verified via `EchoData.BrandedId.generate!` on disk 2026-06-25): **PLR** (player) · **ROM** (room) ·
**GAM** (game) · **GES** (guess) · **JOB** · **TXN** · **SES** · **CMD** · **NOT** · **EMS** — the cm.* GAM/ROM/PLR
re-base; `USR`/`RMM`/`RND` are pre-rename names and are NOT codemojex brands. Real surfaces (verify on disk before
citing — names below are the modules present, not a frozen API):

`Codemojex.{Guesses, Board, Scoring, Settle, Rooms, Ledger, Locks, RateLimiter, Store, CommandWorker,
NotificationWorker, Notifier, Telegram}` — the play/submit API is **`Codemojex.Guesses.submit/3`** (in `game.ex`),
**not** `Codemojex.Game` (no such module; verified on disk 2026-06-25) + the Phoenix web layer `codemojex_web` (`router.ex`, `channels/room_channel.ex`,
`controllers/game_controller.ex`). Keyspace `cm:*`; rides `emq:{q}:` for queues and `ecc:` / EchoStore for the cache.

> **Provenance:** `bcs.2.md` teaches with the brands `PLR` / `ROM` (player / room); after the **cm.\* rename** the
> **live app mints these same brands** — `PLR` / `ROM` / `GAM` (verified via `generate!` on disk) — so quoting a
> `bcs.2.md` figure and grounding a page-OWN example in `PLR`/`ROM` now **coincide** (they are not different brand
> sets). The real per-player-lane consumer call is `Codemojex.Guesses` → `EchoMQ.Lanes.enqueue(conn, "cm", player,
> job, payload)` (`game.ex`: the lane is named by the player's `PLR`, so the bus rotates service across players —
> the verbatim fair-lanes consumer for R6.02/R6.03). Do NOT invent a brand the app does not mint: `USR`/`RMM`/`RND`
> are pre-rename names and are **not** codemojex brands (this misled an R6.03 author once — verify `generate!` on disk).

## 5. The two consumer courses — numbering + door map

**Redis Patterns Applied (`/redis-patterns`), R0–R8** (dir slugs):
`r1=caching · r2=coordination · r3=queues · r4=time-delay-priority · r5=streams-events · r6=flow-control ·
r7=data-modeling · r8=production-operations` (R0 = `overview`). Identity: BCS contract-sheet, redis-red.

**EchoMQ, In Depth (`/echomq`), E0–E5** (three-pillar spine, the §-order in `echo-mq-writer/references/course-map.md`):
`E0=overview (/echomq + /echomq/overview) · E1=protocol · E2=queue · E3=bus · E4=cache · E5=proof`. Identity:
dark-editorial. **Built today: overview · protocol · queue; soon (non-anchor `soon` cards): bus · cache · proof.**
The old pre-pillar `core/` + `substrate/` trees (retired E0–E8 numbering, citing the **deleted** Go port
`apps/echomq-go` + the **frozen** `echo/apps/echomq`) were **retired/deleted 2026-06-25** — the routes
`/echomq/{core,substrate,groups,batches,lifecycle,production}` no longer exist; `html/echomq/bus` is not yet built,
so **E3 bus is build-to-target**. The retired **E0–E8** numbering does **not** apply here — `E<N>` is the
six-section spine above, and a **section name** (`bus`, `cache`, `protocol`) is always accepted unambiguously.
**Engine: Valkey 9 only — never Dragonfly; the as-built `@wire_version` is `echomq:3.0.0`** (`echo_wire/connector.ex`,
not the stale `2.0.0`/`2.4.2`) — see [SKILL §1a](../SKILL.md).

**The cross-course doors** (where the new direction adds or re-points an edge):

| From | To | Why |
|---|---|---|
| `/redis-patterns` R1 caching | `/echomq/cache` (E4) + `/bcs/store` (B4) | the near-cache in depth; EchoStore figures |
| `/redis-patterns` R2 coordination | `/echomq/protocol` (E1) | the claim script, the fencing token |
| `/redis-patterns` R3 queues, R4 time | `/echomq/queue` (E2) + `/bcs/bus` (B3) | the EchoMQ state machine, lanes, schedule set |
| `/redis-patterns` streams / durability | **`/echo-persistence`** + `/bcs/persistence` (B5) | the archive + the durability dial (delta 4) |
| `/echomq/bus` (E3) | **`/echo-persistence`** + `/bcs/persistence` (B5) | the Stream Tier archives into the page engine → Tigris |
| both courses | `/bcs` (B0–B8) + `/elixir` | the architecture law + the umbrella |

The canonical R↔E table is `docs/redis-patterns/redis-patterns.echomq-doors.md` (it wins on R↔E edges); this digest
adds the **B↔/echo-persistence** edges the new manuscript introduces. Door only to a **built** route; `<strong>`-name
an unbuilt one.

## 6. Quick-verify (the surfaces the deltas assert are real)

```bash
ls echo/apps/echo_store/lib/echo_store/{table,ring,journal,coherence,keyspace,graft}.ex   # EchoStore + the floor
ls echo/apps/echo_graft                                                                    # the Rust twin
ls echo/apps/codemojex/lib/codemojex/{game,board,scoring,locks,store,rooms}.ex             # codemojex
ls docs/echo/bcs/bcs.{0,2,4,5,7}.md                                                         # the figure homes
ls -d html/echo-persistence                                                                # the new door target
ls docs/echo/bcs/content 2>/dev/null || echo "content/ retired (cite bcs.N.md)"            # delta 1
```
