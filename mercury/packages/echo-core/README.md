# node — branded ids for TypeScript, and the BullMQ referee

## Layout

- `src/branded_id.ts` — the contract in TypeScript: branded string types, encode/decode, validation.
- `src/branded.wasm` + `src/wasm_loader.ts` — the Rust codec compiled to wasm; the committed comparison against the pure-TS path is `wasm_bench.out`.
- `src/plugin.ts`, `src/server.ts` — the Fastify plugin enforcing the kind law at the HTTP door, and a demo server.
- `test/` — the negative type-checks (`typecheck_negative.ts` must fail to compile; `typecheck.out` is the committed proof) and the benches.
- `queue_referee/` — the BullMQ harness Appendix E shells (`npm i && node bench.mjs`, Valkey on 6390).

## Build

```bash
npm i
npx tsc --noEmit                 # types hold
node test/bench.ts               # codec rates (committed: bench.out)
```

## Rebuilding the wasm (cargo)

The codec crate is the shared canon at `../../contract/branded-id-rs`:

```bash
cd ../../contract/branded-id-rs
cargo build --release --target wasm32-unknown-unknown
cp target/wasm32-unknown-unknown/release/branded_id.wasm ../../src/node/src/branded.wasm
```

The wasm ships prebuilt so the package needs no Rust toolchain; rebuild only when the contract crate changes, and re-run `wasm_bench.ts` so the committed record moves with it.
