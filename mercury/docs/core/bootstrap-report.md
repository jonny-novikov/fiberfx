# Mercury bench — bootstrap report

**Result: PASS** · scope: operator-approved verification of Postgres, ValKey,
Node 22, and Rust/wasm, plus the `mercury/` deliverables (the `@mercury/db`
Drizzle read model, the `@codemojex/admin` console, the `@echo/fx` Rust→wasm
kernel, and the Cluster + hot-code-replacement harness).

Host: Ubuntu 24.04.4, kernel 6.18.5. Generated from a live run.

## Toolchain

| tool | found | expected | status |
|---|---|---|---|
| valkey-server | 9.1.0 (from source) | >= 8 (prefer 9.x) | ok |
| valkey allocator | jemalloc-5.3.0 | bundled jemalloc | ok |
| postgres | 16.14 | any | ok |
| node | v22.22.2 | >= 22 | ok |
| rustc | 1.96.0 | stable | ok |
| wasm-pack | 0.13.1 | any | ok |
| pnpm | 9.15.0 | >= 9 | ok |

Out of scope by operator instruction this run (not verified): the BEAM
toolchain, Go, and the Elixir umbrella build.

## Services

- **ValKey** built from source at the 9.1.0 tag (`make BUILD_TLS=yes`), started
  on `:6390` with no auth; reports `mem_allocator: jemalloc-5.3.0`. Used live for
  the board sorted set.
- **PostgreSQL 16.14** on `:5432`; app role `codemojex` with the dev password,
  database `codemojex_dev`, TCP login verified.

## Database — @mercury/db (Drizzle read model)

- 9 tables present in `codemojex_dev`: `players`, `emoji_sets`, `rooms`,
  `games`, `guesses`, `golden_rooms`, `revenue_ledger`, `wallet_ledger`,
  `key_shop`.
- `drizzle-kit generate` reports 9 tables modeled (matching the live schema);
  migration emitted under `db/drizzle/`.
- Core tables modeled from a live game; ledger/shop tables provisional, to be
  reconciled with `drizzle-kit pull` against the Ecto-migrated database.
- Seeded for the console: 1 emoji set, 2 rooms, 2 players, 2 games, 3 guesses,
  all keyed by `@echo/fx`-minted branded ids; a board ZSET seeded in ValKey.

## Compute — @echo/fx (Rust → wasm)

- `cargo test`: 4 passed (codec roundtrip, shape validation, minter monotonicity
  and branding, fused-pipeline demonstration).
- `wasm-pack build --release --target nodejs`: pkg emitted; `echo_fx_bg.wasm` is
  39202 bytes.
- Load smoke (Node): minted a `GAM` id, decoded its namespace, node, sequence,
  and timestamp; `validate` true; `hash32` returned (PARITY-pending vs the NIF);
  the documented sample `GAM0ONWgLV5FCq` decoded structurally;
  `fused_sum_of_squares([1..5], 5) = 50`.

## Surface — @codemojex/admin (Fastify)

Booted against live Postgres + ValKey; every route returned correct live data.

- `GET /health` → `{ ok: true, postgres: true, valkey: true }`.
- `GET /rooms` → 2 rooms.
- `GET /games?status=active` → 2 games; the secret and keyboard snapshots are
  withheld from the response by construction.
- `GET /games/:id` → game detail with the live board read from ValKey
  (`ada 600`, `linus 300`) and 3 recent guesses; no secret in the payload.
- `GET /players` → 2 players with wallet balances.
- `GET /players/:id` → wallet, recent guesses, ledger.
- `PATCH /rooms/:id/status` → flipped a room to `closed`; confirmed in Postgres.
- A malformed id returns 400; a valid-shaped but unknown id returns 404.

TypeScript: `@mercury/db`, `@codemojex/admin`, and the `@echo/fx` facade all
typecheck clean under the strict base config.

## Parallel execution — Cluster + hot code replacement

`echo/fx/examples/cluster-hcr.mjs`, `CLUSTER_WORKERS=2 BATCH=12`:

- generation 0 online → batch 0: 12 jobs across worker nodes `[0,1]`.
- rolling reload: generation 1 online while generation 0 still served → batch 1:
  12 jobs across worker nodes `[2,3]`; generation 0 then drained.
- 24 ids minted, 0 collisions; disjoint node bands per generation.
- **HCR result: PASS.**

The sandbox reports a single core (`availableParallelism: 1`), so the two workers
time-share rather than run truly in parallel; the orchestration — disjoint node
ids, round-robin dispatch, and the zero-downtime rolling reload — is exercised in
full, and throughput parallelism follows on a host with two or more cores.

## Documents

- `docs/mercury-echo-architecture.md` — the `mercury/echo/` architecture vision.
- `docs/effective-ts-fp-wasm.md` — the functional-TypeScript and wasm research,
  the top-three library comparison, the Effect and V8 open problems, and the
  `@echo/fx` roadmap.

Both pass `sweep.py` (exit 0): voice gate, no exclamation marks in prose, no long
quotes, and the Writerside header shape.

## Result

PASS. The four operator-approved components are verified live, the read model is
materialized and seeded, the admin serves correct data with secrets withheld,
the Rust→wasm kernel is built and tested, and the Cluster + HCR harness passes.
