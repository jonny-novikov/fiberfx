# Mercury · The echo/ surface, envisioned
<show-structure depth="2"/>

Mercury is the Node and TypeScript surface over the same substrate the BEAM
umbrella already owns: Postgres as the system of record, ValKey as the live
tier, and one branded-identity contract under every record that crosses either.
It is not a second implementation of the umbrella. It is a typed surface that
reads and writes the stores the Elixir side writes, with the hot identity and
compute kernel pushed into Rust and compiled to wasm.

This document sets the shape of `mercury/echo/`: what the kernel is, the
packages above it, which Echo principles carry over intact, which are deferred,
and what is shipped versus proposed. The performance reasoning behind the wasm
seam — why the kernel is Rust rather than TypeScript — lives in the companion
piece `docs/effective-ts-fp-wasm.md`; this document points to it rather than
restating it.

## The thesis

A real-money game and a trading surface meet the same wall the umbrella was
built for: the moment two players act at once, ordering, fairness, and balance
correctness stop being incidental. Echo answers that wall on the BEAM. Mercury
does not relitigate the answer; it extends the reach of the same stores to a
Node surface — an admin console today, more product surface later — without
forking identity, without a second queue protocol, and without a second cache
of record.

Three commitments hold the surface together:

- **One identity contract.** Every entity is a fourteen-byte branded id: a
  three-letter uppercase namespace plus the width-11 base62 of a 63-bit
  Snowflake. `EchoData.BrandedId` owns the codec on the Elixir side; on the Node
  side `@echo/fx` mirrors it, and a self-check holds the two at parity rather
  than trusting them to agree.
- **One system of record.** Postgres holds wallets, games, guesses, and the
  ledgers. The Ecto migrations own the live schema; the Node read model
  (`@mercury/db`, Drizzle) mirrors it and is reconciled by introspection, never
  by a second source of truth.
- **One live tier.** ValKey carries the lanes and the board sorted sets. Mercury
  reads the board; it does not score. The scoring authority stays singular and
  stays on the consumer.

## The layering of mercury/echo

Read bottom to top. The kernel is Rust; everything above it is TypeScript.

```
codemojex-node ───────────────────────────────── the product surface
   admin            Fastify console: rooms, games, players, management
   (future)         bot gateway, web API, settlement views

@mercury/db ─────── Drizzle read-model mirror of the Ecto system of record

echo/ (TypeScript substrate — partly shipped, partly PROPOSED)
   @echo/fx         Rust → wasm: BrandedId codec, Snowflake minter, hash32
                    + the Cluster scheduler (TS over node:cluster)
   @echo/wire       (PROPOSED) RESP3 + connector parity for the Node side
   @echo/mq         (PROPOSED) lane client: enqueue on a player's lane
   @echo/store      (PROPOSED) declared near-cache over the shared ValKey
```

`@echo/fx` and `@mercury/db` are shipped. The `@echo/wire`, `@echo/mq`, and
`@echo/store` packages are named here as the intended shape of the Node
substrate, not as existing code; they are marked PROPOSED wherever they appear,
and Mercury does not pretend to carry them yet. The admin reaches Postgres
directly through `@mercury/db` and reads ValKey directly through a small client;
when the substrate packages land, the admin moves onto them without changing its
routes.

### @echo/fx — the kernel

`@echo/fx` is the one piece that is Rust. It carries the identity layer and the
per-isolate compute, and it compiles to wasm with `wasm-pack` so a Node isolate
can mint, decode, and route without a round trip to the BEAM:

- `encode` / `decode` — the fourteen-byte codec. `decode` returns the namespace,
  the 63-bit Snowflake (as a string, so the value survives the JS number
  boundary), the Unix-millisecond timestamp, the node, and the sequence.
- `Minter` — a per-isolate Snowflake minter. It is lock-free by isolation: a
  wasm instance is single-threaded, so no atomics are needed inside one isolate,
  and each Cluster worker constructs a minter with its own node id. That
  disjointness is what keeps ids unique across cores without a shared lock.
- `hash32` — the routing hash. It is MurmurHash3 x86_32 over the fourteen bytes
  today, and it is marked PARITY: it must be cross-checked against
  `EchoData.BrandedId.hash32/1` before it places a lane in production. Identity
  parity is a self-check, never an assumption.
- `fused_sum_of_squares` — a loop-fusion demonstration of the per-isolate
  primitive: a fused map-square, filter, fold in one pass over linear memory,
  with no intermediate array crossing the boundary. It is the seed of the
  Fusion-Tasks rung on the roadmap, not the scheduler.

The scheduler is deliberately not in this crate. A wasm instance is one isolate
with private linear memory, so cross-core work cannot share a Rust deque. The
cores are processes (`node:cluster`); each loads the same kernel and carries a
distinct node id. The scheduler that fans work across them lives in TypeScript
(`echo/fx/ts/cluster.ts`), and the runnable proof is
`echo/fx/examples/cluster-hcr.mjs`.

### @mercury/db — the read model

`@mercury/db` is a Drizzle schema over Postgres. The discipline is strict: the
Ecto migrations own the live schema, and this package is a mirror. The core
tables — players, rooms, games, guesses, emoji sets — are modeled from the
observed columns of a live game; the ledger and shop tables (`golden_rooms`,
`revenue_ledger`, `wallet_ledger`, `key_shop`) are scaffolded by their known
migration names with provisional columns and are marked as such. The reconciler
is `drizzle-kit pull` against the Ecto-migrated database; until it runs, the
provisional column lists are not treated as authoritative.

Every id column is the phantom-typed `BrandedId<NS>`: a `varchar(14)` at
runtime, nominally typed at compile time so the checker refuses a `GAM` id where
a `PLR` id belongs. The branding is erased at runtime and costs nothing; it
exists to carry the namespace through the read model and the admin routes.

### codemojex-node/admin — the surface

The admin is a Fastify console for operators: list and inspect rooms, list games
with a status filter, inspect a game with its live board and recent guesses,
search players, and inspect a player's wallet and history, plus light management
(flip a room open or closed). Postgres is the system of record; ValKey is read
for the board. Two structural rules hold:

- **The surface withholds secrets by construction.** The game's secret and the
  keyboard snapshot are never in the selected columns of any game response. This
  mirrors `Codemojex.View`: integrity and privacy are structural, not enforced
  after the fact.
- **The surface never scores or settles.** It reads the board sorted set and the
  guess rows the scoring consumer wrote; it does not compute a score. The single
  scoring authority stays on the BEAM consumer.

Configuration is parsed once at boot into a frozen, typed `Env`; a missing or
malformed value fails the boot, not the first request. The dev bench points at
Postgres on `:5432` and ValKey on `:6390` with no auth.

## The principles, carried across the boundary

Echo's principles are not Elixir-specific; they are properties of the design.
Here is how each maps onto the Node surface, with a candid note on what is upheld
versus deferred.

- **Branded identity, owned by one module.** Upheld. `EchoData.BrandedId` owns
  the format; `@echo/fx` mirrors it; nothing else parses or re-derives. The
  phantom types carry the namespace through TypeScript.
- **Native or pure, with proved parity.** Upheld in shape, pending in fact. The
  Rust codec is the native path; the Elixir pure path is the reference. The
  parity self-check is specified; the `hash32` seed and input remain PARITY-
  pending until cross-checked against the canonical NIF.
- **Declared, not discovered.** Deferred to `@echo/store`. The admin's ValKey
  reads name their key prefix in one place; a full declared near-cache on the
  Node side is proposed, not built.
- **Fairness is constructed, not hashed.** Upheld in the scheduler. The Cluster
  pool rotates a ring of workers one step per dispatch; placement is the
  rotation, not a hash.
- **Park, don't poll.** Deferred. The admin is request-driven and does not run a
  consumer loop; a Node lane consumer (`@echo/mq`) would carry the park-on-wake
  rhythm.
- **One named wire.** Deferred to `@echo/wire`. Today the admin uses an
  off-the-shelf ValKey client; a Node connector at parity with `EchoMQ.RESP` is
  proposed.
- **Self-checks at the boot, not the first order.** Upheld. The admin parses and
  freezes its environment at boot; the identity codec self-check is specified at
  load.
- **A single scoring authority.** Upheld. Mercury reads results and never
  computes them.

## Boot order and deployment surface

The admin brings itself up in a fixed order: parse and freeze the environment,
construct the ValKey client, register the health probe and the route groups,
wire the graceful-shutdown path (close the server, quit ValKey, end the Postgres
pool), then listen. The health probe reports Postgres and ValKey independently,
so a degraded live tier is visible rather than fatal.

The surface runs on a small, legible set of services, the same shape the
umbrella uses: an always-on machine for the Fastify endpoint, Postgres as the
system of record, and ValKey as the live tier. In development ValKey is
passwordless on `:6390`; in production it dials a dedicated node over a private
network with a password from the environment.

## The horizon

The near-term work is the `@echo/fx` roadmap — Fusion Tasks, work-stealing,
Cluster parallel execution, and hot code replacement on more than one core — set
out rung by rung in `docs/effective-ts-fp-wasm.md`, with the runnable harness
already in `echo/fx/examples/cluster-hcr.mjs`. Beyond the kernel, the proposed
substrate packages (`@echo/wire`, `@echo/mq`, `@echo/store`) would let a Node
worker enqueue on a player's lane and read a declared near-cache at parity with
the BEAM side, so a Node surface could carry inbound product traffic and not
only operator reads. Ephemeral execution — a FLAME-style fan-out of short-lived
machines for a batch of compute — is a natural fit for the Cluster kernel and is
noted as a direction, not a commitment.

## What is real versus proposed

The NO-INVENT discipline applies to this document as much as to the code. The
table separates what exists in the tree from what is named as intended shape.

| Surface | State | Note |
|---|---|---|
| `@echo/fx` BrandedId codec + Snowflake minter | shipped | Rust → wasm; `cargo test` covers the core |
| `@echo/fx` `hash32` | shipped, PARITY-pending | MurmurHash3 x86_32; reconcile vs the NIF |
| `@echo/fx` Cluster scheduler + HCR | shipped (demo) | `cluster.ts` + runnable `.mjs` |
| `@echo/fx` Fusion Tasks | seed shipped | `fused_sum_of_squares`; pipeline tier proposed |
| `@echo/fx` work-stealing deque | proposed | needs worker_threads + SharedArrayBuffer |
| `@mercury/db` core tables | shipped | modeled from a live game |
| `@mercury/db` ledger/shop tables | shipped, provisional | reconcile via `drizzle-kit pull` |
| `codemojex-node/admin` | shipped | rooms, games, players, light management |
| `@echo/wire` / `@echo/mq` / `@echo/store` | proposed | named shape of the Node substrate |

## References

- Drizzle ORM, the read-model toolkit used by `@mercury/db`:
  `https://orm.drizzle.team`
- Node Cluster, the substrate for the per-core scheduler:
  `https://nodejs.org/api/cluster.html`
- The performance reasoning behind the wasm kernel:
  `docs/effective-ts-fp-wasm.md` (companion piece in this set)
