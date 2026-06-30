/**
 * TypeScript facade over the `echo-fx` wasm module.
 *
 * The seam the rest of Mercury imports. It keeps the wasm boundary coarse-grained
 * (one call per logical operation, no chatty per-field crossings) and re-applies
 * the branded type so callers carry the namespace. The brand is `@echo/core`'s
 * `BrandedId<NS>`, so an id minted here is the same nominal type the rest of the
 * surface uses. The codec is generic over the namespace — no product's set is
 * baked in here, matching `EchoData.BrandedId`, which takes the namespace as a
 * parameter.
 *
 * Build the wasm first: `pnpm --filter @echo/fx build` (wasm-pack, target nodejs).
 * The import below resolves to the generated `pkg/`.
 */
import * as wasm from "../pkg/echo_fx.js";
import type { BrandedId } from "@echo/core";

export type { BrandedId };

export interface DecodedId<N extends string = string> {
  readonly namespace: N;
  readonly snowflake: bigint;
  readonly timestampMs: bigint;
  readonly node: number;
  readonly seq: number;
}

export function encode<N extends string>(ns: N, snowflake: bigint): BrandedId<N> {
  return wasm.encode(ns, snowflake) as BrandedId<N>;
}

export function decode<N extends string = string>(id: string): DecodedId<N> {
  const d = wasm.decode(id);
  return {
    namespace: d.namespace as N,
    snowflake: d.snowflake,
    timestampMs: d.timestamp_ms,
    node: Number(d.node),
    seq: Number(d.seq),
  };
}

export function validate(id: string): boolean {
  return wasm.validate(id);
}

/** Routing hash. PARITY-pending vs EchoData.BrandedId.hash32/1. */
export function hash32(id: string): number {
  return wasm.hash32(id) >>> 0;
}

/**
 * A per-worker minter. Construct one per worker with a distinct `node` id
 * (0..1023) — that disjointness is what keeps ids unique across cores without a
 * shared lock.
 */
export class Minter {
  private readonly inner: wasm.Minter;
  constructor(node: number) {
    this.inner = new wasm.Minter(node);
  }
  snowflake(nowMs: number = Date.now()): bigint {
    return this.inner.mint_snowflake(nowMs);
  }
  mint<N extends string>(ns: N, nowMs: number = Date.now()): BrandedId<N> {
    return this.inner.mint(ns, nowMs) as BrandedId<N>;
  }
}

/** Per-isolate loop-fusion primitive (demonstration). */
export function fusedSumOfSquares(values: Uint32Array, threshold: number): bigint {
  return wasm.fused_sum_of_squares(values, threshold);
}
